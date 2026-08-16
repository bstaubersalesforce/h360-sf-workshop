# Credential Setup Cookbook — the three OAuth setups, step by step

The workshop has **three separate credential setups**, each with gotchas that silently fail. This is the careful,
click-by-click guide — do each in order, run the ✅ verify before moving on. Every 🔴 is a real failure we hit; the fix is
right there. Pairs with [build-and-deploy.md](./build-and-deploy.md) (the surrounding build).

> **What's already done for you** (via the onboarder `./scripts/06-org-onboard.sh` — or a facilitator ran it on your
> workshop org): the reference build is deployed — Apex, the `Order__c` object (+ **All Orders** list view), the
> **`Slack_API` Named/External Credential**, and the **`Headless360_Workshop_Access`** permission set (assigned to you) —
> plus the **5 hero records** (OR-1001..OR-1005) seeded by `05-seed-hero-data.sh`. You do **not** create those.
> _(Prereq for all of this: Agentforce was enabled on the org first — see [PARTICIPANT-SETUP.md](../PARTICIPANT-SETUP.md).)_
>
> **What YOU do** (this cookbook): create **two External Client Apps** (MCP + Agent API), create **one Slack app**, and
> **paste three secret values** into the org (secrets are never pre-baked). That's it.

## The credential map — what feeds what

| # | You create | Holds the secret | Powers |
|---|-----------|------------------|--------|
| **A** | ECA `Headless360_MCP_Client` | Consumer Key (used by Claude) | **M3 MCP** — Claude reads the org |
| **B** | ECA `Headless360_Agent_API` | Consumer Key + Secret → a token | **M4 Agent API** — the React web app |
| **C** | Slack app | Bot token (`xoxb-…`) → pasted into the `Slack_API` credential | **M5 Slack** — the Block Kit card |

**⚠️ A and B are DIFFERENT apps with DIFFERENT scopes and DIFFERENT OAuth flows. Do not merge them** — the flows
conflict (one is per-user, one is server-to-server). Two ECAs, always.

> ✅ **Confirmed by the official Salesforce MCP & Agent Orchestration Technical Guide** (Thaxter, 2026-07-28): the scope split (`mcp_api`-only for MCP;
> `api`+`chatbot_api`+`sfap_api` for Agent API), the JWT-token toggle, and PKCE-for-Auth-Code are all correct.
> **Two clarifications from that guide:** (1) **Salesforce-hosted MCP supports ONLY the Auth Code + Client Credentials
> flows — NOT JWT Bearer Flow**; (2) the **"Issue JWT-based access tokens" toggle is unrelated to JWT Bearer Flow** — it's
> its own setting (the A/B gotcha here), on for reasons like named-user token issuance.

---

# A. MCP External Client App (Module 3)

**Where:** Setup → **External Client App Manager** → **New External Client App**.

1. **Basic Information**
   - Name / API Name: **`Headless360 MCP Client`** / `Headless360_MCP_Client`
   - Contact email: yours.
2. **API (Enable OAuth Settings) → turn ON**, then set:
   - **Flow Enablement — CHECK "Enable Authorization Code and Credentials Flow." 🔴 NONE are enabled by default.**
     Miss this and the connect has no OAuth grant type — Claude can't complete auth (and the consumer-details page can
     misbehave). MCP uses **authorization_code + PKCE** (per-user); do **NOT** enable JWT Bearer / Device / Token Exchange.
   - **Callback URL — enter BOTH, one per line** (this is the exact-match list the redirect is checked against):
     ```
     https://claude.ai/api/mcp/auth_callback
     http://localhost:8765/callback
     ```
     🔴 **Miss the second line → the Claude Code CLI fails with `redirect_uri_mismatch`.** The CLI redirects to its
     local loopback (`localhost:8765`); claude.ai web uses the first. Both must be present. Exact match — no trailing
     slash, `http` (not `https`) on the loopback, lowercase `localhost` (not `127.0.0.1`).
   - **OAuth Scopes — add EXACTLY these two** (move to Selected):
     - `Access Salesforce hosted MCP Servers (mcp_api)` *(older UI labelled this just "Access MCP Servers" — same `mcp_api` scope)*
     - `Perform requests at any time (refresh_token, offline_access)`
     🔴 **Do NOT add `api`, `openid`, or anything else.** MCP wants `mcp_api` only — adding extra scopes (especially
     `openid`) can **break the connection**. More is not safer here.
   - **PKCE is ON and locked.** In the current UI, **"Require Proof Key for Code Exchange (PKCE)…" is checked and
     cannot be unchecked** — leave it (PKCE is exactly what the CLI loopback flow needs). *(Nothing to flip.)*
   - **Confirm "Require secret for Web Server Flow" is UNchecked.** *(Usually already unchecked — a confirm step, not a
     change. Current UI may show only the Web Server Flow box; if a "Refresh Token Flow" secret box is present, leave it unchecked too.)*
   - **CHECK "Issue JSON Web Token (JWT)-based access tokens for named users." 🔴 THE #1 SILENT GOTCHA.**
     - **What it does:** makes the org mint the access token as a **signed JWT** instead of an opaque token. The Hosted
       MCP endpoint **requires a JWT-format bearer token** — so with this OFF, the OAuth handshake *succeeds* (you get a
       token, the consent screen works, the connection looks green) but **every MCP tool call fails** with
       `INVALID_AUTH_HEADER` / `INVALID_JWT_FORMAT`. It fails *after* connect, which is why it's so easy to miss.
     - **Why you keep hitting it:** it is **frequently OFF by default**, and nothing in the connect flow warns you.
     - **⚠️ This is NOT "JWT Bearer Flow."** Two unrelated things that both say "JWT." This toggle only controls the
       *token format*; **JWT Bearer is an OAuth grant type you do NOT enable for MCP** (per the official guide, Hosted
       MCP supports only **Auth Code + Client Credentials** flows). Enabling JWT *Bearer Flow* here is wrong; enabling
       the JWT *token* toggle is required. Don't conflate them.
     - **Metadata name (for reference):** `<isNamedUserJwtEnabled>true</isNamedUserJwtEnabled>` in
       `ExtlClntAppGlobalOauthSettings`. The workshop path is this **manual card** — the kit's ECA metadata bundle is
       org-scoped and its committed org Id is a placeholder (see the
       [ECA bundle README](../sfdx/force-app/main/default/externalClientApps/README.md) for the metadata-path caveats).
     - **Verify before saving. If MCP calls fail `INVALID_JWT_FORMAT` after connecting, this toggle is the first thing
       to check** (fix: turn it on → reconnect Claude with a fresh token).
3. **Create/Save.** The new-app flow may show only a **"Create"** button (no "Save") — that's the same action.
   **If** a **"Confirm and Lock Security Controls"** dialog appears with **PKCE toggled ON/Lock**, that's fine for
   MCP (PKCE is wanted here) — confirm. *(The dialog does not appear in every org/UI version — if you don't get it,
   nothing is wrong.)*
4. **Copy the Consumer Key** (Settings → OAuth Settings after save). This is the OAuth Client ID Claude uses.
   - 🔴 **For MCP you need only the Consumer KEY (Client ID) — NOT the secret** (PKCE public client; "Require secret for
     Web Server Flow" is off, so no secret is exchanged).
   - 🔴 Revealing consumer details may trigger an identity-verification challenge, or fail with **"insufficient
     privileges"** (seen on trial 161 orgs). Fixes: complete the emailed verification code; retry from a fresh
     `sf org open --target-org <alias>` session; confirm your user has **"Manage Connected Apps."** If it persists on a
     locked-down trial, flag a facilitator — you only need the **Key**, so this doesn't block the MCP connect.

### ✅ Verify A
- `./scripts/04-mcp-connect-setup.sh --org <alias> --verify` reports the ECA present, **or** connect Claude and run a
  real read (`read order OR-1003 from Salesforce`). A green "connected" dot is **not** proof — run the read.
- 🔴 If `/mcp` shows **no Salesforce server at all**: you launched Claude Code from the wrong directory. The h360 MCP
  servers are **project-scoped** — launch from the `headless360-workshop` project directory.

---

# B. Agent API External Client App (Module 4)

**A SEPARATE app from A.** Setup → **External Client App Manager** → **New External Client App**.

1. **Basic Information**
   - Name / API Name: **`Headless360 Agent API`** / `Headless360_Agent_API`
2. **API (Enable OAuth Settings) → ON**:
   - **Callback URL** (required even though client_credentials never uses it — the field is mandatory):
     ```
     https://<your-org>.my.salesforce.com/services/oauth2/callback
     ```
     (your org's My Domain + `/services/oauth2/callback`.)
   - **OAuth Scopes — add EXACTLY these** (different from A):
     - `Manage user data via APIs (api)`
     - `Access chatbot services (chatbot_api)`
     - `Access the Salesforce API Platform (sfap_api)`
     - `Perform requests at any time (refresh_token, offline_access)`
     🔴 **These are the Agent-API scopes, NOT `mcp_api`.** `chatbot_api` is the current name (not renamed). Again, do
     not add `openid`.
   - **UNcheck** "Require secret for Web Server Flow" + "Require secret for Refresh Token Flow".
   - **CHECK "Issue JWT-based access tokens for named users."**
3. **PKCE is locked ON — leave it (harmless here).** In the current UI, "Require Proof Key for Code Exchange (PKCE)" is
   **checked and can't be unchecked** ("To change this required setting, contact Support"). That's fine: PKCE only applies
   to the browser **authorization_code** flow — the **client_credentials** flow (no browser) ignores it. *(Earlier guidance
   to disable PKCE is obsolete — the UI no longer allows it, and client_credentials doesn't need it turned off.)*
4. **Set the flow + Run-As user.** 🔴 **This is on the finished app's Policies tab — NOT in the creation wizard.**
   After the app is created: open the app → **Policies** tab → **OAuth Policies** → **Edit**. (The "Enable Client
   Credentials Flow" toggle is here too — Run-As is set on this same Policies screen, *not* where you added scopes.)
   - **Enable Client Credentials Flow: ON.**
   - **Run As:** a user who can call the API **and** is authorized to run the Agentforce agent. Current org labels
     (verified against an OrgFarm org 2026-07-28; names drift across releases — re-confirm in Setup):
     - **API access** → the **Salesforce API Integration** permission-set **license** (this is what the old
       "API Enabled" guidance meant).
     - **Agent use** → **"Access Agentforce Default Agent"** (formerly labelled "Use Agentforce Default Agent").
     - ⚠️ The old **"Access Service Einstein"** reference is unconfirmed — could not map it to a current perm; treat
       as **needs-verification / possibly obsolete**, not a hard requirement, until confirmed.
     🔴 **Known conflict to resolve before the workshop — the Run-As user's LICENSE, not just its perms.** A pure
     **API-Only integration user** (the "clean pattern" earlier guidance recommended) **may not support the
     Agentforce agent-use permission** — in the OrgFarm org, the integration-only license did **not** offer
     "Agentforce Service Agent User." So the Run-As user likely needs a license that supports *both* API integration
     *and* Agentforce agent use (e.g. a standard/Agentforce-licensed user with the API Integration PSL + Access
     Agentforce Default Agent), **not** a bare API-Only user. **Confirm the working license+permset combination on
     the target org and record it here** before locking the flow. Using an **admin** works but can hit MFA on a
     stale session and gack the token request (fallback, not the pattern). Confirm the user is active.
5. **Copy the Consumer Key + Consumer Secret** (fresh session — same verification caveat as A).

### ✅ Verify B (mint a token — local terminal, keeps the secret off any transcript)
```bash
curl -s -X POST "https://<your-org>.my.salesforce.com/services/oauth2/token" \
  -d "grant_type=client_credentials" -d "client_id=<CONSUMER_KEY>" -d "client_secret=<CONSUMER_SECRET>" | python3 -m json.tool
```
Expect `access_token`, `token_type: Bearer`, and `scope: sfap_api chatbot_api api`.
- `invalid_client` → key/secret wrong, or the app hasn't propagated (wait 2–5 min).
- `invalid_grant` / "user hasn't approved" → Client Credentials Flow not enabled or Run-As not set (step 4).
- Verification/MFA error → the Run-As user is your admin on a stale session → switch to a dedicated integration user
  (one whose license supports Agentforce agent use — see step 4's license caveat, not a bare API-Only user).

---

# C. Slack app + bot token (Module 5)

The org side (`Slack_API` Custom External Credential + Named Credential) is **already deployed**. You create the Slack app,
then paste its bot token into the credential. **It is NOT an OAuth/OIDC Auth Provider** — it's a bearer bot token.

### C1 — Create + install the Slack app
1. **api.slack.com/apps → Create New App → Blank app** → name the app and pick **your** workshop Slack workspace.
2. **OAuth & Permissions → Bot Token Scopes** → add:
   - `chat:write`
   - `channels:read`
   - `chat:write.public` *(lets the bot post to any public channel without being invited — recommended)*
3. **Install to [Name of Your Selected Workspace] under OAuth Tokens** → Allow. Copy the **Bot User OAuth Token** (starts **`xoxb-`**).
   - 🔴 It must be the **Bot User OAuth Token** (`xoxb-`), not the App-Level token (`xapp-`), Client Secret, or a config
     token (`xoxe-`). Use the **Copy** button (avoids trailing-newline corruption).

### C2 — 🔴 Validate the token BEFORE touching Salesforce (the fast bisector)
```bash
curl -s -H "Authorization: Bearer <xoxb-…>" https://slack.com/api/auth.test
```
- **`{"ok":true, …}`** → good; note the `team`/`url` match your workspace. Proceed to C3.
- **`{"ok":false,"error":"invalid_auth"}`** → the token is being rejected. Two documented causes:
  1. **Disallowed source IP** — the app's **OAuth & Permissions → "Restrict API Token Usage"** IP allowlist. If it has
     any entries, they block calls from other IPs (managed/demo Grid orgs sometimes pre-seed this). **Clear the list.**
     🔴 Even after clearing it for *your* laptop, the **org's callout egresses from Salesforce IPs, not yours** — so an
     allowlist scoped to your IP will still block the org. For the workshop: **leave the allowlist empty.**
  2. **Bad/stale token** — reinstall the app, re-copy. A **phone hotspot** test isolates IP-block vs. token (hotspot
     bypasses a corporate proxy like Zscaler).
  - This is **not** a Grid admin-approval gate (that hypothesis was disproven). It's the IP allowlist / the token.

### C3 — Paste the token into the org
Setup → **Named Credentials → External Credentials → Slack API → Principals** → edit **`Slack_Bot_Principal`** →
**Authentication Parameters** → add:
- **Name:** `BotToken`  *(exact, case-sensitive — the merge field looks it up by this name)*
- **Value:** the `xoxb-…` token  *(no `Bearer ` prefix, no quotes, no trailing space)*
- **Save.**

🔴 **Naming rule that cost us an hour:** the **principal** is `Slack_Bot_Principal` and the **secret parameter** is
`BotToken` — they must be **different names**. (If you ever rebuild this credential, never reuse one name for both, or
the merge field `{!$Credential.Slack_API.BotToken}` resolves to empty → `invalid_auth`.)

### ✅ Verify C (through the org — proves the whole chain)
```bash
sf apex run --target-org <alias> --file /dev/stdin <<'APEX'
HttpRequest h = new HttpRequest();
h.setEndpoint('callout:Slack_API/auth.test'); h.setMethod('POST');
h.setHeader('Content-Type','application/x-www-form-urlencoded');
Map<String,Object> b = (Map<String,Object>) JSON.deserializeUntyped(new Http().send(h).getBody());
System.debug('ok=' + b.get('ok') + ' err=' + b.get('error') + ' team=' + b.get('team'));
APEX
```
Expect `ok=true … team=<your workspace>`. If `ok=false invalid_auth` here but the curl in C2 was fine → the org's stored
value is wrong (re-paste cleanly), or the org's egress IP is blocked by the allowlist (C2 cause #1).

Then fire a real card (see [build-and-deploy.md](./build-and-deploy.md) §4 for the snippet) → expect
`posted (HTTP 200, ok:true)` and a card in the channel. `not_in_channel` → `/invite` the bot or use `chat:write.public`.

---

## Troubleshooting quick-reference

| Symptom | Which setup | Cause → fix |
|---------|-------------|-------------|
| `redirect_uri_mismatch` | A (MCP) | Missing the `localhost:8765/callback` line — add both callbacks. |
| `/mcp` shows no server | A (MCP) | Launched Claude Code from the wrong dir — use the project directory. |
| `INVALID_JWT_FORMAT` / `INVALID_AUTH_HEADER` | A (MCP) | "Issue JWT-based access tokens" unchecked — check it, re-auth. |
| Connection breaks after adding a scope | A or B | Removed-then-re-add: use ONLY the listed scopes; drop `openid`/extras. |
| Can't undo PKCE / locked | B (Agent API) | Locked with PKCE on — Cancel the lock dialog, turn PKCE off first. |
| Token mints but `invalid_grant` | B (Agent API) | Client Credentials Flow off, or Run-As user not set (Policies tab). |
| "Invalid user ID on start session" (HTTP 400) | B (Agent API) | `bypassUser:true` on an employee agent → set **`bypassUser:false`**. |
| Consumer Secret reveal "verification timed out" | A or B | Stale session — `sf org open` fresh, retry. |
| Slack `invalid_auth` from curl | C (Slack) | Token, OR the app's "Restrict API Token Usage" IP allowlist — clear it. |
| Slack `invalid_auth` from org but curl OK | C (Slack) | Stored `BotToken` wrong/mistyped, or org egress IP blocked by allowlist. |
| Slack `not_in_channel` | C (Slack) | `/invite` the bot, or add `chat:write.public` (reinstall for a fresh token). |
| Record-link button gacks "Looks like there's a problem" | any | Browser logged into a different org — log into the demo org first. |

> **Facilitator tip:** a floating MCP/OAuth specialist during Module 3 + the credential setups saves the room (the
> data360 lesson). These three setups are the highest-friction ~30 minutes of the day — pre-verify each participant org
> if you can, and have this cookbook open per table.
>
> **Printable tick-off card:** [credential-checklist-card.md](./credential-checklist-card.md) — one page of just the ✅
> verify commands, per participant/table.
