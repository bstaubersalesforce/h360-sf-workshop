#!/usr/bin/env bash
# Diagnostic: mint a fresh token, write it to .env, and test Agent API session-start
# directly (prints real HTTP status + body). Run from web/ on YOUR machine.
set -uo pipefail
cd "$(dirname "$0")"

ORG=h360-orgfarm-test
MYD=$(SF_TEMP_SHOW_SECRETS=true sf org display --target-org "$ORG" --json 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"]["instanceUrl"])')
TOK=$(SF_TEMP_SHOW_SECRETS=true sf org display --target-org "$ORG" --json 2>/dev/null | python3 -c 'import sys,json;print(json.load(sys.stdin)["result"]["accessToken"])')

echo "MyDomain: $MYD"
echo "Token length: ${#TOK}  (should be ~112, shape 00D...!...)"
echo

# Write token into .env (portable python edit — no sed quoting hell)
python3 - "$TOK" <<'PY'
import re,sys
tok=sys.argv[1]
s=open(".env").read()
s=re.sub(r'^VITE_ACCESS_TOKEN=.*$', f'VITE_ACCESS_TOKEN={tok}', s, flags=re.M)
open(".env","w").write(s)
print("wrote VITE_ACCESS_TOKEN to .env")
PY
echo

# Does the token authenticate at all? (normal REST)
echo "== token sanity (REST /limits) =="
curl -s -o /dev/null -w "  /limits -> HTTP %{http_code}\n" -H "Authorization: Bearer $TOK" "$MYD/services/data/v62.0/limits"
echo

# Try Agent API session-start with the two candidate agent ids, print status + body
BODY="{\"externalSessionKey\":\"diag-1\",\"instanceConfig\":{\"endpoint\":\"$MYD\"},\"streamingCapabilities\":{\"chunkTypes\":[\"Text\"]},\"bypassUser\":false}"
for AID in 0Xxbm000002uEVNCA2 0X9bm000004S6hhCAC; do
  echo "== session-start agentId=$AID =="
  curl -s -w "\n  -> HTTP %{http_code} (remote_ip %{remote_ip})\n" \
    -X POST "https://api.salesforce.com/einstein/ai-agent/v1/agents/$AID/sessions" \
    -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" \
    -d "$BODY" | sed 's/^/  /'
  echo
done

echo "NOTE: if remote_ip is 100.64.x.x you're inside a sandbox (can't reach the real API)."
echo "On your Mac it should be a public Salesforce IP."
