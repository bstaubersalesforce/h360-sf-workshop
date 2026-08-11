#!/usr/bin/env bash
# Per-org MCP / Connect (Module 2) setup helper — run ONCE per participant org.
#
# Automates the deterministic parts of getting an org ready for the Connect module
# (reachability, edition/LEX sanity, deploy, permset) and gives an exact-values,
# copy-paste guided walk for the ONE step no org type auto-provisions: the
# External Client App (mcp_api + PKCE + JWT tokens). Use --verify after the manual
# ECA step to confirm it landed. No deletes; safe to re-run (idempotent).
#
# Usage:
#   ./scripts/04-mcp-connect-setup.sh --org <alias>            # run the setup + print the guided ECA card
#   ./scripts/04-mcp-connect-setup.sh --org <alias> --verify   # verify the org is Connect-ready (post-ECA)
#   ./scripts/04-mcp-connect-setup.sh --org <alias> --no-deploy # skip the metadata deploy (already deployed)
#
# See docs/org-shape-and-provisioning.md (§2) and GUIDE.md Module 2 for the why.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/lib/common.sh"

# --- Connect-module constants (single source of truth for the guided values) ---
# Two callback paths — register BOTH (one per line in the ECA):
#   • claude.ai web / desktop app  → https://claude.ai/api/mcp/auth_callback
#   • Claude Code CLI (loopback)   → http://localhost:8765/callback  (from oauth.callbackPort in ~/.claude.json)
# The CLI does exact-match on localhost:<port>/callback; omitting it → redirect_uri_mismatch.
MCP_CALLBACK_URL_WEB="https://claude.ai/api/mcp/auth_callback"
MCP_CALLBACK_URL_CLI="http://localhost:8765/callback"
MCP_OAUTH_SCOPES="mcp_api, refresh_token, offline_access"
MCP_SERVERS="sobject-reads sobject-all salesforce-api-context metadata-experts"
ECA_LABEL="Headless360 MCP Client"      # suggested label; participants may rename
PERMSET="Headless360_Workshop_Access"

# --- flags (resolve_org handles --org; parse the rest) ---
ORG="$(resolve_org "$@")"
VERIFY=0; DO_DEPLOY=1
while [ $# -gt 0 ]; do
  case "$1" in
    --verify) VERIFY=1; shift;;
    --no-deploy) DO_DEPLOY=0; shift;;
    --org) shift 2;;
    *) shift;;
  esac
done
[ -n "$ORG" ] || { fail "no org (pass --org <alias> or set ORG_ALIAS in .env)"; exit 1; }
command -v sf >/dev/null 2>&1 || { fail "sf CLI not found — https://developer.salesforce.com/tools/salesforcecli"; exit 1; }

# --- reachability (shared gate for both modes) ---
sf org display --target-org "$ORG" >/dev/null 2>&1 \
  || { fail "org '$ORG' not reachable — run: sf org login web --alias $ORG"; exit 1; }
pass "org '$ORG' reachable"

# --- edition / LEX sanity (best-effort; warn-only, never blocks) ---
EDITION="$(sf org display --target-org "$ORG" --json 2>/dev/null | grep -o '"edition"[^,]*' | head -1)"
[ -n "$EDITION" ] && echo "  org $EDITION"
case "$EDITION" in
  *Developer*|*Enterprise*|*Partner*) pass "edition supports Agentforce/Einstein (Einstein1AIPlatform-eligible)";;
  "") warn "edition not reported — confirm Developer/Enterprise (Agentforce requires it)";;
  *) warn "edition '$EDITION' may not support Agentforce — see docs/org-provisioning-options.md";;
esac

# ============================ VERIFY MODE ============================
if [ "$VERIFY" -eq 1 ]; then
  echo "--- Verify: is '$ORG' Connect-ready? ---"
  RC=0
  # External Client App present? (the ECA is the load-bearing MCP artifact)
  if sf org list metadata --metadata-type ExternalClientApplication --target-org "$ORG" >/dev/null 2>&1; then
    ECAS="$(sf org list metadata --metadata-type ExternalClientApplication --target-org "$ORG" --json 2>/dev/null | grep -c '"fullName"')"
    if [ "${ECAS:-0}" -ge 1 ]; then pass "External Client App present (count: $ECAS)"
    else fail "no External Client App found — create it (re-run without --verify for the guided card)"; RC=1; fi
  else
    warn "could not query ExternalClientApplication metadata — confirm the ECA in Setup → External Client App Manager"
  fi
  # Permset assigned? (read-only query — do NOT re-assign here: an already-assigned
  # permset makes `sf org assign permset` exit non-zero with "Duplicate
  # PermissionSetAssignment", which would misreport a correctly-configured org.)
  ASSIGNED="$(sf data query --target-org "$ORG" \
    --query "SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSet.Name='$PERMSET'" \
    --json 2>/dev/null | grep -o '"totalSize"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$')"
  if [ "${ASSIGNED:-0}" -ge 1 ]; then
    pass "permset '$PERMSET' assigned (assignments: $ASSIGNED)"
  else
    warn "permset '$PERMSET' not assigned yet — deploy the reference build + assign (02-deploy.sh / 03-assign-perms.sh)"
  fi
  echo "  ⓘ MCP server activation + the JWT-token toggle can't be read via CLI — confirm in the UI:"
  echo "    • Setup → API Catalog → MCP Servers → Salesforce Servers: $MCP_SERVERS active"
  echo "    • ECA → OAuth: 'Issue JWT-based access tokens for named users' is CHECKED (the INVALID_JWT_FORMAT gotcha)"
  echo "    • Smoke-test: ask Claude to read a record via sobject-reads (don't trust the green dot — run the flow)"
  exit $RC
fi

# ============================ SETUP MODE ============================
# 1) Deploy the reference build (idempotent) unless told to skip.
#    Delegates to 02-deploy.sh — the 3-phase sequence (metadata → agent publish+activate →
#    permset last). A wholesale `sf project deploy start --source-dir force-app` would FAIL here:
#    the permset's <agentAccesses> only resolves after the agent is published (KNOWN-GAPS T11),
#    and this helper doesn't publish. Always go through 02-deploy.sh so the order is correct.
if [ "$DO_DEPLOY" -eq 1 ]; then
  if [ -d "$ROOT/sfdx/force-app" ]; then
    echo "--- Deploy reference build (3-phase via 02-deploy.sh) → $ORG ---"
    "$ROOT/scripts/02-deploy.sh" --org "$ORG" \
      && pass "reference build deployed" \
      || warn "deploy failed — check output; if a prior deploy was interrupted, run: sf org list metadata -m AiAuthoringBundle (orphan-bundle gotcha)"
  else
    warn "sfdx/force-app not found — skipping deploy"
  fi
else
  echo "  (--no-deploy) skipping metadata deploy"
fi

# 2) Assign the workshop permset (idempotent).
sf org assign permset --name "$PERMSET" --target-org "$ORG" >/dev/null 2>&1 \
  && pass "permset '$PERMSET' assigned" \
  || warn "permset '$PERMSET' assign failed — deploy the reference build first, then re-run"

# 3) Guided External Client App card (the manual walk / Option-3 fallback).
#    UPDATE 2026-08-06: the ECA IS deployable metadata — the gated TODO is CLOSED.
#    The full family (ExternalClientApplication + ExtlClntAppGlobalOauthSettings +
#    ExtlClntAppOauthSettings + ExtlClntAppOauthConfigurablePolicies) is captured in
#    sfdx/force-app/main/default/{externalClientApps,extlClntApp*}/ — including the
#    JWT toggle (isNamedUserJwtEnabled), PKCE, secret-optional, and the MCP scope.
#    CROSS-ORG deploy PROVEN (deployed into a different-
#    lineage org: 4/4 created, JWT/PKCE/scope survived, fresh consumer key minted,
#    org IDs auto-re-resolved). So the FAST PATH (Option 1) is:
#        sf project deploy start -d force-app/main/default/externalClientApps \
#          force-app/main/default/extlClntAppGlobalOauthSets \
#          force-app/main/default/extlClntAppOauthSettings \
#          force-app/main/default/extlClntAppOauthPolicies --target-org <org>
#    (Loop over the org list for bulk provisioning.) Portability fix already baked in:
#    ExtlClntAppOauthSettings has NO <oauthLink> (org-scoped; deploy fails otherwise),
#    and consumerKey is stripped (each org mints its own). See the ECA README.
#    STILL MANUAL per org: MCP-server activation (API Catalog — not metadata) + the
#    consumer SECRET for the Agent-API client-credentials flow + the e2e smoke-test.
#    This guided card = the Option-3 fallback + the Module-2/3 teaching moment.
cat <<EOF

──────────────────────────────────────────────────────────────────────────────
 Connect module (M2) — External Client App  ·  org: $ORG
──────────────────────────────────────────────────────────────────────────────
 First, activate the Hosted MCP servers:
   Setup → Quick Find "MCP Servers" (under API Catalog) → Salesforce Servers →
   activate:  $MCP_SERVERS

 Then create the External Client App:
   Setup → External Client App Manager → New
   • Label / API name:  $ECA_LABEL
   • Enable OAuth:      ON
   • Callback URLs:     $MCP_CALLBACK_URL_WEB   (claude.ai web / desktop)
                        $MCP_CALLBACK_URL_CLI        (Claude Code CLI — loopback; one per line)
   • OAuth scopes:      $MCP_OAUTH_SCOPES
   • UNcheck both "Require secret for … Flow" boxes
   • CHECK  "Enable PKCE"  (Proof Key for Code Exchange — the current Hosted-MCP ECA doc omits this,
                            but the Claude Code CLI loopback flow uses PKCE; empirically required, validated 2026-07-22)
   • CHECK  "Issue JWT-based access tokens for named users"   ← the gotcha
   Save, then copy the Consumer Key (= OAuth Client ID).

 🔴 If MCP calls fail INVALID_AUTH_HEADER / INVALID_JWT_FORMAT → the JWT-token
    box is unchecked. If invalid_client_id → the app hasn't propagated; wait.
    If OAuth fails redirect_uri_mismatch → the callback you connected from isn't
    in the app's list; add BOTH URLs above (CLI needs the localhost:8765 one).

 Verify when done:  ./scripts/04-mcp-connect-setup.sh --org $ORG --verify
──────────────────────────────────────────────────────────────────────────────
EOF
