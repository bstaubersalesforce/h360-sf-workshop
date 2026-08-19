# Module 4 — React app on the capability (in-org primary · Agent API secondary)

**Phase:** 2 · Reference Build · **Goal:** the same capability rendered in a custom React app — "your product, headless" · **Time:** ~45 min · **Done when:** the React card shows the OR-1003 status (in-org app **and** the external Agent-API client).

Two React surfaces, both reaching the agent published in Module 2 (needs it **published + activated**). We lead with the **in-org (on-platform) React app** — lowest-friction, no token juggling — and treat the external Agent-API client as a working second surface for the fully-headless, off-platform story.

> **React is GA on-platform (Multi-Framework).** Native React runs on Hyperforce orgs; each app gets a dedicated **`salesforce.app`** origin; Data SDK (GraphQL) is GA. The two surfaces render the same agent differently: (a) the **in-org app** embeds the **Agentforce Conversation Client** (Lightning Out over `my.salesforce.com`) — no tokens; (b) the **external `web/` app** calls the raw **Agent API** and renders the Response as **your own card**. Rendering one card across Slack/Claude/mobile from a single definition is the HXL "render everywhere" vision — a facilitator demo, not built here. Docs: [Multi-Framework guide](https://developer.salesforce.com/docs/platform/multiframework/guide/).

## 4a — Primary: the in-org React app (native Multi-Framework)

The kit ships the **`Headless360_OrderStatus` UI Bundle** — a native React app running *on* the platform, embedding the Order Assistant chat. It's a subsequent deploy step (not in base onboarding — it needs an `npm` build + a large `node_modules`, which is `.forceignore`d). Run it **after** the agent is published:

```bash
./scripts/07-deploy-react-bundle.sh --org <alias>
```

It queries the org's `BotDefinition` Id → bakes **`VITE_AGENT_ID`** at build time → `npm run build` → scoped-deploys the UI Bundle + its surfacing **CustomApplication** + the **`Headless360_React_App`** permset (and assigns it). Then **App Launcher → "Headless360 Order Status"** → the React app renders with the embedded **Order Assistant** chat; ask "status of order OR-1003" → the same Exception / "Approve rebooking" from Module 2, now in a custom React shell in the org.

### 🔴 Checkpoint 4a
The app appears in App Launcher and the embedded chat answers on OR-1003. ⏳ Expect a **cold start** — the first load *and* the agent's first reply can take several seconds; wait, it's not a failure, and later calls are fast. A **persistent blank chat / "Order Assistant unavailable"** (not just slow) → `VITE_AGENT_ID` was built for a different org (or not set) — re-run `07-deploy-react-bundle.sh` against **this** org (it re-bakes the id). No tokens involved — the in-org client runs as you.

## 4b — Secondary (working): the external Agent-API client — "fully headless"

The `web/` app calls the raw Agent API and renders the structured Response as **your own card** — the true off-platform "your product, headless" surface.

### Set up the Agent-API ECA (a SEPARATE app from the MCP one)

Setup → **External Client App Manager** → **New External Client App**.

- **Name / API Name:** `Headless360 Agent API` / `Headless360_Agent_API`
- **Enable OAuth: ON.**
- **Callback URL** (required even though client_credentials never uses it):
  ```
  https://<your-org>.my.salesforce.com/services/oauth2/callback
  ```
- **OAuth Scopes — add EXACTLY these** (different from the MCP ECA): `Manage user data via APIs (api)`, `Access chatbot services (chatbot_api)`, `Access the Salesforce API Platform (sfap_api)`, `Perform requests at any time (refresh_token, offline_access)`. 🔴 **NOT `mcp_api`**, and do not add `openid`.
- **UNcheck** "Require secret for Web Server Flow" and "Require secret for Refresh Token Flow".
- **CHECK "Issue JWT-based access tokens for named users."**
- **PKCE is locked ON — leave it** (client_credentials ignores it).

Then set the flow + Run-As user. 🔴 **This is on the finished app's Policies tab — NOT the creation wizard.** Open the app → **Policies** → **OAuth Policies** → **Edit**:
- **Enable Client Credentials Flow: ON.**
- **Run As:** a user who can call the API **and** run the Agentforce agent. 🔴 **A bare API-Only integration user may lack Agentforce agent-use** — use a user whose license supports **both** (API Integration PSL + "Access Agentforce Default Agent"), not a pure API-Only user. Using an admin works but can hit MFA on a stale session.

**Copy the Consumer Key + Consumer Secret** (client_credentials **needs the secret**).

> 🔒 **If revealing the Key/Secret loops on identity-verification or "insufficient privileges"** (common on trial orgs) — **open the org in an incognito/private window and reveal from there.** A clean session resolves it; or complete the emailed code / retry from a fresh `sf org open --target-org <alias>` session.

### Verify the token mint (local terminal — keeps the secret off any transcript)

```bash
curl -s -X POST "https://<your-org>.my.salesforce.com/services/oauth2/token" -d "grant_type=client_credentials" -d "client_id=<CONSUMER_KEY>" -d "client_secret=<CONSUMER_SECRET>" | python3 -m json.tool
```
Expect `access_token`, `token_type: Bearer`, `scope: sfap_api chatbot_api api`. `invalid_client` → key/secret wrong or app not propagated (wait 2–5 min). `invalid_grant` → Client Credentials Flow not enabled or Run-As not set.

### Run the client

1. The agent must be a **non-"Agentforce (Default)"** type (Employee qualifies) — the Agent API doesn't support Default.
2. **Save your creds into `web/.env`.** You'll have the ECA **Consumer Key + a fresh Consumer Secret**. Put them in `web/.env`, then run **two processes** (the browser can't call `api.salesforce.com` directly — no CORS, and the token must never live in browser JS — so `proxy.mjs` holds the token and forwards):
   ```bash
   cd web && cp .env.example .env
   ```
   Set `VITE_SF_MYDOMAIN`, `VITE_AGENT_ID`, `VITE_CLIENT_ID`, `SF_CLIENT_SECRET` + a fresh access token in `web/.env`, then:
   ```bash
   npm install
   ```
   ```bash
   node proxy.mjs
   ```
   ```bash
   npm run dev
   ```
   `proxy.mjs` (Terminal 1, → :8787) holds the token and forwards to the Agent API; `npm run dev` (Terminal 2, → :5173) serves the React app → "Ask the agent". `web/.env` is **gitignored** — keep creds off git. Full walk-through: [`web/README.md`](../../web/README.md).

### 🔴 Checkpoint 4b — it's the token, not the network
The web card shows the same OR-1003 status.
- `401` / empty → **expired/wrong token**: mint a fresh one into `web/.env` and **restart `node proxy.mjs`** (it reads `.env` at startup).
- session-start **412** → assign the **agent-access permset** to the Run-As user (an Employee agent is invisible to a user without agent access); confirm the agent is **published + activated**.
- **400 "Invalid user ID"** → `bypassUser` wrong for an Employee agent.
- First call may show a timeout-style delay (session start + the 120s Agent-API ceiling) — wait for the card; check the **proxy log** (Terminal 1) for the real status, not just the browser. More → [ISSUES.md](../ISSUES.md).

---

[← Module 3a](./03a-custom-mcp-server.md) · [Overview](../../OVERVIEW.md) · [Module 5 →](./05-slack.md)
