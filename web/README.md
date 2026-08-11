# React Agent-API Sample Client (Surface #2)

A minimal reference React client that embeds the reference Employee Agent's Skill in a partner's own web app via the
**headless Agentforce Agent API** — the truest "Headless 360" story for an ISV with their own front-end.

> **Reference, not a product.** This is deliberately dependency-light: it shows the Agent API loop (start → send → receive
> → end) and renders the structured order-status Response as a card. Swap in your own Skill + styling to reskin.

## How it works

The Agent API is a REST API (no bundled UI):
1. **Start session** → get a session id.
2. **Send message** ("order status for <id>") → the agent runs the Skill.
3. **Receive** the structured Response.
4. **Render** it in React (this is where *you* own the UI — the API returns data, not markup).
5. **End session.**

### Architecture — a backend proxy holds the token (the real partner pattern)

The browser does **not** call the Agent API directly. Two reasons: (1) `api.salesforce.com` sends no browser
CORS headers, and (2) an access token must never live in browser JS. So the React app calls a tiny **backend
proxy** (`proxy.mjs`) that holds the token server-side and forwards to the Agent API — exactly what a partner
does in production. The browser sends no token.

```
browser (React)  ──►  proxy.mjs :8787  ──►  api.salesforce.com/einstein/ai-agent/v1
                       (injects Bearer token from .env, server-side)
```

## Prerequisites

- The agent is a **non-"Agentforce (Default)"** type (Employee qualifies).
- A **separate External Client App** for the Agent API (client_credentials + Run-As user; scopes `api`, `chatbot_api`,
  `sfap_api`). Do **not** reuse the MCP ECA. (403 without the scopes.)
- 🔴 **`bypassUser: false`** on session start for an Employee agent — the session runs as the token's Run-As user.
  `bypassUser: true` → HTTP 400 "Invalid user ID provided on start session". (Handled in `src/agentApi.js`.)
- Note the **120-second Agent API timeout** — keep actions fast.
- ✅ Validated end-to-end 2026-07-23 against agent `Headless360_Order_Assistant` (start → send → receive → end).

## Run (two terminals)

```bash
cp .env.example .env      # set the values below (incl. a fresh access token)
npm install               # first time only

# Terminal 1 — the backend proxy (holds the token, forwards to the Agent API)
node proxy.mjs            # → http://localhost:8787

# Terminal 2 — the React app
npm run dev               # → http://localhost:5173  → click "Ask the agent"
```

`.env.example`:
```
VITE_SF_MYDOMAIN=https://<your-domain>.my.salesforce.com
VITE_AGENT_ID=<your Employee Agent id>
VITE_CLIENT_ID=<External Client App consumer key>
# Token acquisition: use your OAuth flow. For the lab, mint a short-lived client_credentials
# token and paste it here — proxy.mjs reads it and injects it server-side (never sent to the browser):
#   curl -s -X POST "$VITE_SF_MYDOMAIN/services/oauth2/token" \
#     -d grant_type=client_credentials -d client_id=<key> -d client_secret=<secret>
VITE_ACCESS_TOKEN=<short-lived access token for the demo>
```

🔴 **Token expires** (client_credentials tokens are short-lived). On a `401`/empty response, mint a fresh one
into `.env` and **restart `node proxy.mjs`** (it reads `.env` at startup).

## Files

- `proxy.mjs` — dependency-free backend proxy; holds the token, forwards to the Agent API, handles CORS.
- `src/agentApi.js` — the Agent API helper (start/send/receive/end); calls the proxy, sends no token.
- `src/App.jsx` — a single component: input → send → render the order-status card.
- `vite.config.js` / `index.html` / `src/main.jsx` — standard Vite React scaffolding.

⚠️ **Auth/licensing** for the Agent API in a partner app requires confirmation against your Salesforce edition/licensing
before production use.
