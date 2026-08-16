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

## Full setup — step by step (end to end)

**Two terminals + a two-part ECA.** Full ECA click-by-click is in
[docs/credential-setup-cookbook.md §B](../docs/credential-setup-cookbook.md#b-agent-api-external-client-app-module-4);
the essential path:

### 1. Create the Agent-API External Client App (SEPARATE from the MCP one)
Setup → **External Client App Manager → New External Client App**.
- **Basic Info:** Name `Headless360 Agent API`; **Contact email** (required).
- **API (Enable OAuth Settings) → ON:**
  - **Callback URL:** `https://<your-domain>.my.salesforce.com/services/oauth2/callback` (required field even though
    client_credentials never uses it)
  - **OAuth scopes** (exact UI labels — **NOT** `mcp_api`):
    - Manage user data via APIs **(api)**
    - Access chatbot services **(chatbot_api)**
    - Access the Salesforce API Platform **(sfap_api)**
    - Perform requests at any time **(refresh_token, offline_access)**
  - **CHECK** "Issue JSON Web Token (JWT)-based access tokens for named users"
  - PKCE is locked ON — **leave it** (it only affects the browser auth-code flow, not client_credentials)
- **Create.**

### 2. 🔴 Enable the flow + set Run-As — ONLY after the app is created (Policies tab)
The **Run As** field doesn't exist in the creation wizard — it appears only after the app is saved. Open the finished
app → **Policies → OAuth Policies → Edit**:
- **Enable Client Credentials Flow:** ON
- **Run As (Username):** a user that can call the API **and** run the agent — your admin user works (it holds
  `Headless360_Workshop_Access` → agent access). **Save.**

### 3. Copy the Consumer Key + Secret (🔴 you'll likely have to re-login)
App → **Settings → OAuth Settings**. Revealing the Key/Secret usually forces a **re-login / identity verification**
(on trial orgs it can surface as "insufficient privileges") — complete the emailed code, or reopen fresh with
`sf org open --target-org <alias>`. **Client_credentials needs the secret.**

### 4. Mint a short-lived access token (client_credentials)
Run this as **one line** (no `\` continuation — it breaks on copy-paste in some terminals):
```bash
curl -s -X POST "https://<your-domain>.my.salesforce.com/services/oauth2/token" -d grant_type=client_credentials -d client_id=<CONSUMER_KEY> -d client_secret=<CONSUMER_SECRET>
```
Copy the `access_token` from the JSON.

### 5. Configure `web/.env`
```bash
cp .env.example .env      # then set:
#   VITE_SF_MYDOMAIN=https://<your-domain>.my.salesforce.com
#   VITE_AGENT_ID=<Employee Agent BotDefinition Id, 0Xx…>
#   VITE_CLIENT_ID=<CONSUMER_KEY>
#   VITE_ACCESS_TOKEN=<access_token from step 4>
#   SF_CLIENT_SECRET=<CONSUMER_SECRET>
```

### 6. Run — TWO terminals (both from `web/`)
```bash
npm install               # first time only

# Terminal 1 — backend proxy (holds the token, forwards to the Agent API). LEAVE RUNNING.
node proxy.mjs            # → http://localhost:8787

# Terminal 2 — the React app
npm run dev               # → http://localhost:5173
```
Open **http://localhost:5173** → ask for **OR-1003** → the status card renders.

🔴 **Token expires** (client_credentials tokens are short-lived). On a `401`/empty response, **re-mint** (step 4) into
`web/.env` and **restart `node proxy.mjs`** (it reads `.env` at startup). `412` on session start → the Run-As user lacks
agent access; `400 "Invalid user ID"` → `bypassUser` (handled in `src/agentApi.js`).

## Files

- `proxy.mjs` — dependency-free backend proxy; holds the token, forwards to the Agent API, handles CORS.
- `src/agentApi.js` — the Agent API helper (start/send/receive/end); calls the proxy, sends no token.
- `src/App.jsx` — a single component: input → send → render the order-status card.
- `vite.config.js` / `index.html` / `src/main.jsx` — standard Vite React scaffolding.

⚠️ **Auth/licensing** for the Agent API in a partner app requires confirmation against your Salesforce edition/licensing
before production use.
