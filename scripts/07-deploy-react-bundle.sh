#!/usr/bin/env bash
# Module 4b — deploy the native IN-ORG React app (Multi-Framework UI Bundle).
#
# This is a SUBSEQUENT/optional deploy step, deliberately NOT part of 02-deploy.sh
# (base capability): the UI Bundle needs an `npm` build first and pulls a large
# node_modules (the deploy footgun) — node_modules is .forceignore'd (repo root +
# bundle level) so the scoped deploy below stays clean.
#
# Usage:
#   ./scripts/07-deploy-react-bundle.sh --org <alias>              # npm install + build + deploy
#   ./scripts/07-deploy-react-bundle.sh --org <alias> --no-build   # deploy only (dist/ already built)
#
# Validated build + scoped deploy on a clean trial-EE org 2026-08-15.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT/scripts/lib/common.sh"
ORG="$(resolve_org "$@")"
[ -n "$ORG" ] || { fail "no org (pass --org <alias> or set ORG_ALIAS)"; exit 1; }
BUNDLE="force-app/main/default/uiBundles/Headless360_OrderStatus"
APP="force-app/main/default/applications/Headless360_OrderStatus.app-meta.xml"
REACT_PERMSET="force-app/main/default/permissionsets/Headless360_React_App.permissionset-meta.xml"
DO_BUILD=1
for a in "$@"; do [ "$a" = "--no-build" ] && DO_BUILD=0; done

cd "$ROOT/sfdx"
[ -d "$BUNDLE" ] || { fail "UI bundle not found: $BUNDLE"; exit 1; }

if [ "$DO_BUILD" -eq 1 ]; then
  echo "→ 1/2 building the React bundle (npm install + build)…"
  ( cd "$BUNDLE" && npm install && npm run build ) \
    && pass "React bundle built (dist/)" \
    || { fail "npm build failed — run 'npm install && npm run build' in sfdx/$BUNDLE"; exit 1; }
else
  echo "  (--no-build) skipping npm build"
fi

echo "→ 2/3 deploying UI Bundle + surfacing app + permset → $ORG (node_modules .forceignore'd)…"
#   The CustomApplication (uiBundle-backed) is what puts the React app in the App Launcher — the
#   bundle alone is invisible. The app + permset deploy AFTER the bundle so the uiBundle reference resolves.
sf project deploy start -d "$BUNDLE" "$APP" "$REACT_PERMSET" --target-org "$ORG" \
  && pass "in-org React app deployed (UIBundle + CustomApplication + permset)" \
  || { fail "UIBundle/app deploy failed"; exit 1; }

echo "→ 3/3 assigning app-visibility permset…"
sf org assign permset --name Headless360_React_App --target-org "$ORG" >/dev/null 2>&1 \
  && pass "app visibility granted (Headless360_React_App assigned)" \
  || warn "permset assign failed (likely already assigned) — non-fatal"

echo "→ Open it: App Launcher → 'Headless360 Order Status' (the native React app)."
echo "   Details: sfdx/$BUNDLE/README.md"
