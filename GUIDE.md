# Headless 360 Workshop — Build Guide

Follow this guide top to bottom. 🔴 marks the checkpoints where silent failures happen most — do not skip the verification.

**The technical arc — three phases, in order:** **Educate → Reference Build → Apply-to-POC.** This is the tech track's
spine and it determines the shape of the day. The modules below are
grouped under those three phases:
- **Phase 1 · Educate** (Modules 0–1) — build the shared language.
- **Phase 2 · Reference Build** (Modules 2–6) — prove the pattern on one shared, guided capability.
- **Phase 3 · Apply to Partner POC** (Modules 7–8 + Showcase) — turn it into the partner's own Dreamforce POC.

**The thesis, made literal by the flow:** *build the capability once, reach it from every surface.* So Phase 2 is
**capability-first** — the reference **capability** (one Employee Agent + one Apex Skill + its in-conversation card) is
**pre-deployed and toured** in Module 2, and the hands-on time goes where the transferable skill actually is: **wiring
that one governed capability to surface after surface** (Claude over MCP, a React app over the Agent API, Slack, ChatGPT).
Phase 3 then **forks it into the partner's own** — the differentiated IP each partner takes to Dreamforce.

**What you'll actually do:** you are not rebuilding a throwaway agent live — the capability is already standing. Your
hands-on work is **reaching it from external surfaces** (ECAs, MCP, Agent API, Slack) and **forking your own capability**
for the Dreamforce showcase. That's the reusable skill partners take home.

> **New to Headless 360?** Read [docs/three-tier-framework.md](./docs/three-tier-framework.md) first — Module 1 teaches from it.

> **Capability-first flow.** The workshop is ordered: Educate → **tour the pre-built Capability** → then the
> surfaces (Connect/Claude, React, Slack, ChatGPT) → take-home (Fork, Package). The Capability tour front-loads the one
> real ordering gate (agent **deployed + published + activated**), so every surface after it is satisfied.

---

# Phase 1 · Educate — build the shared language

*Joint. Goal: a common mental model before anyone builds.*

## Module 0 — Prereqs & Comprehend

**Goal:** workshop org claimed & reachable, tooling installed, repo cloned.

> **Participant one-org setup:** if you're getting your own workshop org ready end-to-end, follow
> **[PARTICIPANT-SETUP.md](./PARTICIPANT-SETUP.md)** — (1) claim your org via OrgFarm (event code from
> your facilitator, template 161), (2) verify Agentforce is on, (3) `./scripts/06-org-onboard.sh --org <alias>`
> (deploy + permset + hero data + smoke test), (4) verify. The steps below are the underlying detail.

1. Claim your **workshop org** via OrgFarm — [orgfarm.salesforce.com/signup](https://orgfarm.salesforce.com/signup),
   **event code from your facilitator** (template 161) — then `sf org login web --alias <your-alias>`.
2. Install **Claude Code** + the **`agentforce-adlc`** and **`sf-mcp-partner-toolkit`** plugins.
   - `agentforce-adlc` — build/preview/test/deploy the agent and its actions.
   - `sf-mcp-partner-toolkit` — scaffold/deploy/diagnose MCP integration (used in Module 3, Connect).
3. Clone this repo, then:
   ```bash
   cp .env.example .env          # set ORG_ALIAS
   ./scripts/00-preflight.sh --org <alias>
   ```
   Expected: `sf` present, org reachable, prereq reminders printed.

> **Workshop tech attendees: bring your laptop.** Install these **before** you arrive
> (do not configure on-site): the **Salesforce CLI (`sf`)**, **Node.js**, and **Claude Code**.
> **Claude Code is the prescribed AI tool** for this lab; **Agentforce Vibes** is a supported
> alternative and the "what's next" showcase. **If you can't get the Claude Code happy path working, use
> Agentforce Vibes (GA) as your optional alternate build tool** — same stack (MCP tools, Skills, CLI, governance),
> just a different driver. It's an alternate path, **not a required module**.

### Tool reference (install once, verify before the lab)

Every tool the lab uses, in one place. `00-preflight.sh` checks `sf` + org reachability; verify the rest yourself.

Commands below are macOS "easy buttons" (Homebrew / npm / install script); the link is the cross-platform fallback.
**Install Node first** — the `npm -g` installs depend on it.

| Tool | Min version | Install (easy button) | Verify | Used in |
|------|-------------|-----------------------|--------|---------|
| **Node.js + npm** | Node ≥18 LTS | `brew install node` — or [nodejs.org](https://nodejs.org) installer | `node --version` | M4 (React `web/` client); prereq for npm installs below |
| **Salesforce CLI** (`sf`) | latest | `npm install --global @salesforce/cli` — [docs](https://developer.salesforce.com/tools/salesforcecli) | `sf --version` | all modules |
| **Claude Code** | latest | `npm install --global @anthropic-ai/claude-code` — or [claude.com/claude-code](https://claude.com/claude-code) | `claude --version` | M2 (capability tour) + M3 (Connect) + take-homes |
| ↳ plugin **`agentforce-adlc`** | latest | `/plugin` in Claude Code → install from marketplace | `/plugin` list | M2 (deploy/publish/activate the agent) + M7 fork |
| ↳ plugin **`sf-mcp-partner-toolkit`** | latest (`create-sf-mcp-client-metadata` ≥1.1.0) | `/plugin` in Claude Code → install from marketplace | `/plugin` list | M3 (scaffold/deploy/diagnose MCP) |
| **MCP Workbench** | latest | **not on AppExchange / not publicly listed** — install from the repo (see note below) | open `/lightning/n/MCP_Workbench` | M3 (connection **troubleshooting** — validates a client can reach the Hosted MCP server; keep for this) |
| **`sf agent mcp`** (CLI, **preview**) | ships with `sf` | included in the Salesforce CLI — no extra install | `sf agent mcp list` | M3 (optional CLI-native **retrieval/verify** — `list` / `fetch` advertised tools; complements Workbench, does **not** replace Setup activation or the run-as smoke test) |
| **`sf-flex-estimator`** (skill) | — | already available as a Claude Code skill — invoke `/sf-flex-estimator` | `/sf-flex-estimator` runs | M2 (profile action Flex-credit cost) |

- **Org side** isn't a CLI install — your workshop org (**OrgFarm template 161**) ships pre-provisioned
  (Agentforce + Employee Agent, Hosted MCP + External Client App, Agent API, LEX for the CLT; **Slack connection optional — on request**).
- **Platform capability versions** (API 64.0+ for CLTs, etc.) move release-to-release — re-check them at workshop time.

> **Installing MCP Workbench (not publicly discoverable).** MCP Workbench is a Salesforce Lightning app that tests MCP
> connections from *inside* the org (like Postman for in-org MCP callouts — same Named Credential, auth, and network path
> as Agentforce). It is **not on AppExchange and not publicly listed** — it ships from the repo
> **[github.com/mvogelgesang/MCP-Workbench](https://github.com/mvogelgesang/MCP-Workbench)**. The `sf-mcp-partner-toolkit`
> plugin's **`diagnose-connection`** skill installs it for you; to do it by hand:
> 1. **Get the current package version ID** (`04t…`) from the repo's install instructions (the README).
> 2. **Install:** `sf package install -p <04t…> -o <org-alias> --wait 5`
>    *(Namespaced org where package install fails? Source-deploy instead: `git clone https://github.com/mvogelgesang/MCP-Workbench.git`, then `sf project deploy start --source-dir force-app/main/default -o <org-alias>`.)*
> 3. **Assign the permset:** `sf org assign permset --name MCP_Workbench -o <org-alias>`
> 4. **Open it:** `sf org open -o <org-alias> --path "/lightning/n/MCP_Workbench"`
>
> Your workshop org (template 161) may already ship MCP Workbench; if it doesn't, install it during setup so it's
> ready before you need it. *(Verify the repo + version ID are current at workshop time — it's a community tool, not a
> Salesforce product.)*

### Pre-read (complete before Day 1)

| Resource | Why |
|----------|-----|
| [Introduction to Salesforce Headless 360](https://trailhead.salesforce.com/content/learn/modules/salesforce-headless-360-quick-look) | Trailhead quick-look — shared vocabulary before the room starts |
| [Headless 360 MCP Server Guide](https://developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/headless-360-mcp.html) | The `headless-360` server you activate in Module 3 (Connect) — the four-tool interface |
| [Headless 360 Decoded Ep. 1](https://www.youtube.com/watch?v=a3sD9YUsk9c&list=PLgIMQe2PKPSLvBYUfZpg5M0eO0jiAKpAu&index=1) | Parker Harris's "why should you ever log in again?" — the executive narrative |

---

## Module 1 — Educate: the Headless 360 mental model

**Goal:** shared language before you build. (Instructor-led; ~45–60 min.)

- **The architecture:** four layers — Data 360 (context) · Business Logic (Apex/Flows as MCP tools) · Orchestration
  (Agentforce/ReAct) · the **Engagement Layer (HXL/AXL)** that targets any surface. The five systems: Data 360, Customer
  360, Agentforce, Tableau, **Slack (System of Engagement)**.
- **The north star:** the Engagement Layer's "define once, render everywhere" vision — author a **Widget** in JSON
  (with **Mosaic**) and render it across Agentforce, ChatGPT, and Slackbot. Learn its vocabulary
  (**Widget / Mosaic / Block / rendition**) so you recognize it when it reaches you. This is a **forward-looking vision,
  not partner-buildable today** — which is *exactly why* this lab builds each surface by hand.
- **The canonical partner path:** **Connect** (AF action via MCP/API) → **Extend** (Topics + Actions as certified IP) →
  **Scale** (full agent / A2A). The consumption test: the one objective is to drive Agentforce consumption.
- **Agentforce Vibes** — the agentic dev experience that connects Claude Code to the full Headless 360 stack (MCP tools,
  Skills, CLI, platform governance). Describe a capability in natural language; Vibes plans + executes using your org's
  metadata. Frame it as "where this goes" for partners who want idea-to-production without leaving the terminal.
  Docs: https://developer.salesforce.com/docs/platform/agentforcevibes/overview
- **The [Three-Tier UX framework](./docs/three-tier-framework.md):** Conversational · Rich Conversational · Full Rich UI.
- **Honest buildability:** what's GA today vs. the HXL/AXL vision; the agent-type gates; the `@AuraEnabled` caveat.
- **Distribution:** how partner IP reaches a customer's org. **Headless is available today, at no packaging cost, and it
  puts the customer in control.** Your **take-home Skill (Module 7)** is distributed via the **AI-assisted (Skills)** path.
  The key reframe: because the **customer assembles** the server definition, it's **version-independent — a feature, not a
  limitation**. Two personas drive it — the **admin** (builds the definition using partner Skills from Agent Exchange) and
  the **end customer** (consumes via Claude/OpenAI through an External Client App). See a partner's timecard capability as
  a worked example.

**Interactive:** each partner maps **2–3 of their own workflows** to a tier (Tier 1/2/3) and notes the surface each would
live on. This mapping is the **Phase-3 ideation seed** — it becomes the spec for the capability you fork and take to Dreamforce.

> **Name the reframe here (so it's a feature, not a gap).** The reference agent is **pre-deployed** — you won't build it
> live. That's deliberate: the transferable skill is **reaching one governed capability from every surface** and
> **forking your own**, not rebuilding a throwaway sample. The build shifts (to surface-wiring + your fork), it doesn't
> vanish — and you leave with a cross-surface capability that's yours, not a demo you'll never reuse.

---

# Phase 2 · Reference Build — prove the pattern (shared, guided)

*On pre-provisioned orgs. Goal: one shared, pre-deployed capability, toured then wired to surface after surface.*

## Module 2 — The Capability: deploy + guided tour

**Goal:** **tour** the one reference capability every surface will reach — an
Employee Agent + an Apex `@InvocableMethod` Skill over `Order__c` + its in-conversation rich card (CLT). This is
"build the capability once" made concrete on screen, and it front-loads the one true ordering gate: the agent is
**deployed + published + activated** here, so Connect/React/Slack later just plug in.

> **Your org ships pre-deployed** — the metadata + permset are deployed, the agent is published + activated, the 5 hero
> records are seeded, and the CLT renders. Steps 1–3 below are that pre-deployment (reference detail); if you
> self-provision, run `./scripts/06-org-onboard.sh`. In-room, this module is a **guided tour + one hands-on query**
> (step 4), not a live build.

1. **Deploy the metadata:** `./scripts/02-deploy.sh --org <alias>` then `./scripts/03-assign-perms.sh --org <alias>`.
   `02-deploy.sh` runs a **3-phase sequence** (metadata → `sf agent publish`+`activate` → permset last — see step 2 for why
   order matters) and deploys the `Order__c` object, the **Order tab + page layout** (all 5 fields — so the record is
   viewable in the UI; these were manual clicks in the reference org, now in metadata), the `OrderStatusSkill`
   `@InvocableMethod` (queries `Order__c` `WITH USER_MODE` → real status + next action + record Id, CLT-eligible), the
   Slack action, and the permset (Order__c object + field FLS **and** Order-tab visibility).
   ⚠️ **Deploying the permset does NOT assign it** — `03-assign-perms.sh` assigns it to the running user (assign it to each
   participant / Run-As user too). The Order__c FLS lives in the permset, so an unassigned user sees no fields / no tab.
   **Seed the 5 hero records** (OR-1001..OR-1005): `./scripts/05-seed-hero-data.sh --org <alias>` (idempotent; run after `03-assign-perms.sh` so the permset FLS is in place — an unseeded org makes the agent answer "No order matches OR-1003"). The `Order__c` object ships an **All Orders** list view, so the rows appear on the tab immediately.
2. **Deploy + publish + activate the Employee Agent** — **`02-deploy.sh` already does this** (it's a 3-phase script:
   deploy metadata incl. the `.agent` bundle → `sf agent publish` + `sf agent activate` → deploy the permset last). The
   commands below are **what the script runs under the hood / how to do it by hand**. The agent ships as an **Agent Script
   bundle**, not UI-authored (`agentforce-adlc`): `sf project deploy start --metadata AiAuthoringBundle:Headless360_Order_Assistant`
   → `sf agent publish authoring-bundle --api-name Headless360_Order_Assistant` → `sf agent activate …`. **The compiled
   Bot + planner are NOT in source** — `publish` generates them; a `.forceignore` keeps them out. Agent type =
   **Employee** (`AgentforceEmployeeAgent`) — required for Slack + CLT + Agent API; no `default_agent_user`.
   🔴 **This is the one ordering gate:** everything downstream (Slack, React/Agent-API, the CLT render) needs the agent
   **published + activated**, not just deployed. The Agent API errors against an unpublished/inactive agent.
3. **The in-conversation rich card (CLT) is part of the capability.** The `OrderStatusCard` **`LightningTypeBundle`**
   (in the same package) is bound to the Skill's Apex output so the agent renders a rich card *inside* the conversation
   (LEX) — the **native/in-platform surface**, and the on-ramp to the HXL "render everywhere" vision (shown as a demo,
   not built live). How the binding works + the silent-text-fallback gotcha are in the **Capability internals** below.
4. **Tour it + run one query (the hands-on beat).** Walk the pieces on screen — the **Order tab** (list view + a record with
   all fields on the page — status, summary, next action), the `OrderStatusSkill`
   class, the agent's Topic/action wiring, the CLT — then **each participant runs one query** against the live agent:
   `sf agent preview start --use-live-actions --authoring-bundle Headless360_Order_Assistant`, ask *"what's the status of
   order OR-1003?"* → the agent invokes Get Order Status, returns the **real** record ("carrier exception… Approve
   rebooking"), and renders the **rich card** in LEX. Now everyone has touched the capability before wiring surfaces to it.
5. **Profile the cost** with `sf-flex-estimator` — estimate the Flex-credit weight of the action before scaling
   (shift-left consumption discipline).

### 🔴 Checkpoint 2 — activate + smoke-test + the card renders
- **Agent fires:** the OR-1003 query returns the real record. If the action doesn't fire, check the Topic/action wiring;
  if it returns "not found," the hero records aren't seeded. Full commands: [docs/build-and-deploy.md](./docs/build-and-deploy.md) §3.
- **Card renders (not plain text):** two things must BOTH be true — the CLT is **bound** (single displayable object output
  typed to `c__OrderStatusCard`; renderer LWC meta declares `<sourceType>`; `schema.json` references the Apex inner class)
  **AND** the agent calls **`show_command`** on that output (not "compose as text"). After any `.agent` change: deploy →
  publish → activate → **fresh conversation**. (Verified 2026-07-23.)

### Capability internals (for the tour narrative + reskin)

- The CLT `schema.json` references the Skill's Apex inner class (`@apexClassType/c__OrderStatusSkill$Card`) + a
  `renderer.json` + renderer LWC (styled card + action button, meta declaring `<sourceType name="c__OrderStatusCard" />`).
- **The binding is metadata, not a manual click.** The action exposes a single displayable object output
  (`card: object`, `complex_data_type_name: "c__OrderStatusCard"`, `is_displayable: True`) — a CLT binds to ONE typed
  object output, never to flat primitive fields. (Reskin pattern: Salesforce's `trailheadapps/agent-script-recipes`.)
- **Reach:** as of the 2026-07-15 re-verification, Apex-based CLTs render across **four** channels — LEX desktop, Enhanced
  Chat v2 (Service agents), Mobile, Experience Builder. This lab uses Employee-Agent-in-LEX; the same bundle carries to
  Service/Mobile. Still not the HXL "one widget auto-renders on Slack/ChatGPT" vision — those stay per-surface builds.

---

## Module 3 — Surface #1: Connect — Claude over Hosted MCP 🔴

**Goal:** reach the capability's org from an external LLM (Claude) — the headline Headless 360 "connectivity" surface,
running as the signed-in user (sharing/FLS enforced). **Standalone: this reaches the object/Apex directly over MCP and
does not require the agent** (MCP and the agent are parallel paths to the same Skill).

> **Helper:** `./scripts/04-mcp-connect-setup.sh --org <alias>` does the deterministic prep (deploy + permset + edition/LEX
> check) and prints an **exact-values card** for the External Client App step below. After you create the ECA, `--verify`
> confirms the org is Connect-ready. The ECA itself stays a guided manual step — it's the M3 (Connect) teaching moment.

1. **Activate MCP servers:** Setup → Quick Find `MCP Servers` (under **API Catalog**) → **Salesforce Servers** → activate
   **`headless-360`**. The Headless 360 MCP Server (`platform/headless-360`, Beta) exposes **four tools —
   Discover → Describe → Dispatch / Dispatch-Read-Only** — over a single stable connection.
   Requires **API v67.0+**, an **External Client App** with the `mcp_api` scope, and per-user
   OAuth (every action runs as the authenticated user; FLS/sharing enforced). Activate via
   Setup → MCP Servers → `headless-360`. Also activate: `sobject-reads`,
   `sobject-all`, `salesforce-api-context`, `metadata-experts`.
2. **Create the External Client App** (Setup → **External Client App Manager** → New). Each setting below prevents a
   specific failure — do all of them. *(Full click-by-click with every gotcha: [credential-setup-cookbook.md §A](./docs/credential-setup-cookbook.md#a-mcp-external-client-app-module-3).)*
   1. **Enable OAuth: ON.**
   2. **Callback URLs — enter BOTH, one per line** (this is the exact-match list the OAuth redirect is checked against):
      - `https://claude.ai/api/mcp/auth_callback`  — claude.ai web / desktop
      - `http://localhost:8765/callback`  — Claude Code CLI loopback
      → *Skip the CLI line and CLI connection fails `redirect_uri_mismatch`.* Register both and one ECA serves both clients.
   3. **OAuth scopes:** `mcp_api` (labelled **"Access Salesforce hosted MCP Servers"** — older UI: just "Access MCP
      Servers"), `refresh_token`, `offline_access`. → *Missing `mcp_api` and the MCP server rejects the token.*
   4. **Confirm** both "Require secret for … Flow" boxes are **unchecked** (often already are — confirm, don't assume a change). → *Left checked, PKCE-only clients can't complete auth.*
   5. **Confirm PKCE is ON** (may be on by default / not a separate toggle in your org — confirm).
   6. **CHECK "Issue JWT-based access tokens for named users."** → *Unchecked, OAuth "succeeds" but every call fails
      `INVALID_AUTH_HEADER` / `INVALID_JWT_FORMAT`.* This is the #1 gotcha — verify it before moving on.
3. **Copy the Consumer Key** (= OAuth Client ID). The app takes a few minutes to propagate — if the next step reports
   `invalid_client_id`, that's propagation, not a mistake: wait and retry the same steps.
4. **Connect Claude and confirm with a real read** (not the green dot):
   1. **Pick your client path** — both work because step 2 registered both callbacks:
      - **Claude Code CLI** (loopback, `localhost:8765/callback`) — no Claude-side admin toggle needed.
        Use this local MCP path if your Claude instance blocks web connectors.
        🔴 **Launch Claude Code from the workshop project directory** (`headless360-workshop/`), not a parent folder.
        The `h360-*` MCP servers are **project-scoped** in `~/.claude.json` — start from the wrong directory and `/mcp`
        shows no Salesforce server at all (it isn't broken, it's just not in scope). `cd` into the project first.
      - **claude.ai web / desktop** (`.../auth_callback`) — for participants on an unmanaged instance that allows connectors.
   2. Add the server and authenticate. If auth doesn't complete on the first try, **re-run it after a short wait** before
      assuming a config error — propagation lag makes the first attempt fail and the retry succeed.
   3. **Run one real read** (e.g. `getUserInfo`, or ask Claude to read a record via `sobject-reads`). It should return
      your identity/data governed by your FLS/sharing. A "connected" indicator alone does **not** prove the flow works.
5. **Try the `headless-360` four-tool workflow** — the Connect payoff moment:
   - **`discover`** — semantic search: "what can I do with accounts?" → returns matching operations
   - **`describe`** → pick one → full spec: APIs, params, dependencies, execution steps
   - **`dispatch_readonly`** → run it → data from your org, governed by your FLS/sharing
   - **`dispatch`** → take an action (e.g. create a record); use sandbox — every action is attributed to you in the audit trail
   This four-step sequence is the same pattern your agent will use at runtime.
6. **(Optional) CLI-native verification —** `sf agent mcp` **(preview).**
   🔴 **Expect an EMPTY result here — that is NOT a failure.** `sf agent mcp list` shows only **externally-registered**
   MCP servers (ones added *into* the API Catalog via `sf agent mcp create --server-url …`, the inbound/registry path).
   It does **NOT** list the **Salesforce-Hosted** `headless-360` server this workshop uses — that server is activated in
   **Setup → API Catalog → MCP Servers** (step 1) and lives on a different path, so `list` returns an empty table unless
   you've separately registered an external server. **Don't chase the empty table.** This step is a *bonus* for teams who
   also want the external-registration path; the workshop's connection is already proven by the Claude smoke test above.
   - **`sf agent mcp list`** — lists **externally-registered** API-Catalog servers (empty here by design — see above).
   - **`sf agent mcp fetch --mcp-server-id <id>`** — for a server you *did* register, fetch the live assets (tools,
     prompts, resources) it advertises — a scriptable "does this server expose the tools I expect?" check.
   - **`sf agent mcp create --server-url …`** — registers an **external** MCP server into the API Catalog.
   ⚠️ **Preview** (label/behavior may change). Bottom line: use this group only if you're exploring the **external**
   MCP-registration path — it does **not** replace the Setup activation (step 1) or the run-as smoke test that already
   proved your `headless-360` connection.

### 🔴 Checkpoint 3 — the JWT gotcha
If MCP calls fail with `INVALID_AUTH_HEADER` or `INVALID_JWT_FORMAT`, the External Client App is missing **"Issue
JWT-based access tokens for named users."** OAuth appears to succeed but calls fail. Fix and retry. If `invalid_client_id`,
the app hasn't propagated — wait and retry. **Verify:** use `discover` on the `headless-360` server, then `dispatch_readonly` an operation — it should return
data governed by your FLS/sharing. Fallback: ask Claude to read a record via `sobject-reads` if `headless-360`
hasn't propagated yet.

---

## Module 3a — Assemble a Custom MCP Server (Setup-composed) 🟡 optional

> **Optional / time-permitting.** Module 3 connected you to the Salesforce-provided **`headless-360`** server.
> This beat flips it around: you **compose your own** MCP server in Setup from your org's building blocks — no
> server code shipped. It's the **"admin assembles the server"** distribution path, sitting between *use the
> standard server* (M3) and *package a full solution* (M8).

**Goal:** build a custom MCP server from a custom Apex `@InvocableMethod` + a Flow + standard tools, then reach it
from Claude exactly as you reached `headless-360` in Module 3.

> This is the **Setup-composed** server (built from actions your org already has) — distinct from *registering an
> external* MCP server via `sf agent mcp create --server-url …` (Module 3, step 6). Different path, different purpose.

1. **Create the server:** Setup → Quick Find `MCP Servers` (under **API Catalog**) → **Custom Servers** → **New**
   (this is an `McpServerDefinition`). Name it e.g. `Order_Concierge`. *(Custom MCP Servers are Beta — verify the exact
   tab/label in Setup at workshop time; UI drifts release-to-release.)*
2. **Add your Apex action:** include the **`OrderStatusSkill`** `@InvocableMethod` you deployed in Module 2 — the same
   code path the agent uses, now exposed as an MCP tool.
3. **Add a Flow + standard tools:** include a simple autolaunched Flow (e.g. status-lookup / "approve rebooking") and a
   standard tool (e.g. `sobject-reads`) so the server genuinely mixes **Flow + Apex + standard tools** — the composed-server pattern.
4. **Activate** it. It's reachable over the **same ECA / `mcp_api` OAuth** you configured in Module 3 — **no new
   credential** and the same JWT toggle applies.
5. **Test from Claude** the same four-tool way as M3, but the tools are now **yours**: `discover` on `Order_Concierge`
   → `describe` → `dispatch_readonly` → `dispatch`.

### 🔴 Checkpoint 3a — your own server answers
From Claude, `discover` on your custom server should list your composed tools (the `OrderStatusSkill` / Flow); then
`dispatch_readonly` **OR-1003** → returns the real record **via your Apex**, governed by your FLS/sharing. Same run-as /
JWT rules as Module 3 — if calls fail `INVALID_AUTH_HEADER`, it's the JWT toggle (Checkpoint 3), not the server.

> ⚠️ **Not packageable (today).** A Setup-composed custom MCP server (`McpServerDefinition`) is created **per-org in
> Setup** and is **not** included in a managed/unlocked package — so this is an admin-assembly path, not a shippable
> artifact. If you need a distributable capability, that's the packaging take-home (Module 8). *(Re-verify at workshop
> time — Beta.)*

---

## Module 4 — Surface #2: React app over the Agent API

**Goal:** the same capability embedded in a partner's own web app via the headless Agent API — "your product, headless."
**Invokes the agent published in Module 2** (needs it published + activated).

> **React on the Agent API is available today (Multi-Framework).** Native React runs on-platform — each app gets a dedicated **`salesforce.app`** origin — and the **Data SDK (GraphQL)** and **Vibes 2.0** are validated with React. Two ways to surface the Skill in a web UI: (a) the **external Agent-API client** in `web/` (below), or (b) a **native on-platform React app** using Multi-Framework. Both render the *same* Skill. (Rendering that same Skill's card across Slack/Claude/mobile from one definition is the HXL "render everywhere" vision — shown as a demo, not built here.) Docs: [Multi-Framework developer guide](https://developer.salesforce.com/docs/platform/multiframework/guide/).

1. Confirm the agent is a **non-"Agentforce (Default)"** type (Employee qualifies) — the Agent API doesn't support Default.
2. Configure the **Agent API** access (External Client App + OAuth scopes; note the **120-second timeout**).
   *(Full click-by-click, incl. the PKCE-lock trap + Run-As perms: [credential-setup-cookbook.md §B](./docs/credential-setup-cookbook.md#b-agent-api-external-client-app-module-4).)*
   🔴 Use a **SEPARATE ECA from the MCP one** (resolved 2026-07-23): scopes `api`, `chatbot_api`, `sfap_api`,
   `refresh_token`, `offline_access` (**not** `mcp_api`); **client_credentials** flow with a **Run-As user** licensed for
   **both API integration AND Agentforce agent use** (🔴 a bare API-Only integration user may lack agent-use — see the
   cookbook §B license caveat), JWT tokens ON, "Require secret for Web Server/Refresh Token Flow" deselected. It can't share the MCP ECA
   because that one is per-user authorization_code.
3. Run the sample client. 🔴 **Follow [`web/README.md`](./web/README.md) in full — this is TWO processes, not one.**
   The browser can't call the Agent API directly (`api.salesforce.com` sends no CORS headers, and the token must never
   live in browser JS), so you run a small backend **proxy** that holds the token AND the React app:
   ```bash
   cd web && cp .env.example .env   # set VITE_SF_MYDOMAIN, VITE_AGENT_ID, VITE_CLIENT_ID + a FRESH access token
   npm install                      # first time only

   # Terminal 1 — backend proxy (holds the token, forwards to the Agent API)
   node proxy.mjs                   # → http://localhost:8787

   # Terminal 2 — the React app
   npm run dev                      # → http://localhost:5173  → click "Ask the agent"
   ```
   The client **starts a session → sends a message → renders the structured order-status Response** as a card — the
   Agent API returning structured data your React front-end renders (no bundled UI).
   ⚠️ **First call may look like it hangs / show a timeout-style delay** (session start + the 120s Agent-API ceiling) —
   that is **not necessarily a failure.** Wait for the card; if nothing renders, check the **proxy log** (Terminal 1) for
   the real status, not just the browser. A `401`/empty response = expired token → mint a fresh one into `.env` and
   **restart `node proxy.mjs`** (it reads `.env` at startup).

### 🔴 Checkpoint 4 — the separate-ECA + Run-As gate
The Agent API needs its **own** ECA (not the MCP one) on the **client_credentials** flow with a Run-As user licensed for
API + Agentforce agent use (see the cookbook §B license caveat). **Verify:** the web widget shows the same order status the
agent query returned in Module 2 — one capability, another surface. Empty/401 response → token expired or Run-As
misconfigured; 400 "Invalid user ID" → `bypassUser` wrong for an Employee agent.

🔴 **`startSession 412` — FIX CONFIRMED: assign the agent-access permission to the Run-As / agent user.**
**Field-verified 2026-07-31:** the 412 on `POST /agents/{id}/sessions` cleared once the **Run-As user was granted
the agent's access permission set** — i.e. it *was* a permission problem, resolved by giving the agent user access to the
agent. **Fix first:** assign the **agent-access permset** to the Run-As user (an employee agent is invisible to a user
who doesn't hold agent access), confirm the agent is **published + activated**, and re-test. *(This supersedes an earlier
docs-inferred read that 412 was purely a wrong-endpoint issue — the observed fix was the permission grant. If the perm
grant doesn't clear it, then check the endpoint: the kit's `web/proxy.mjs` uses the canonical
`…/einstein/ai-agent/v1/agents/{botId}/sessions`; a hand-built `v6.0.0/…/sessions` caller with a `"mode"` field is a
different, non-Agent-API surface and can also misbehave.)*

---

## Module 5 — Surface #3: Slack 🔴 (Block Kit card) — optional

**Goal:** the same Skill, rendered as a Block Kit card in Slack. **Uses the agent published in Module 2** + the
`SendSlackCardAction` (both already deployed).

1. **Create + install a Slack app** in your workspace with bot scopes `chat:write`, `channels:read` (+ `chat:write.public`
   to post without inviting the bot to each channel). Copy the **Bot User OAuth Token** (`xoxb-…`).
   *(Full click-by-click, incl. the `auth.test` pre-check + IP-allowlist gotcha: [credential-setup-cookbook.md §C](./docs/credential-setup-cookbook.md#c-slack-app--bot-token-module-5).)*
   🔴 **Validate the token FIRST:** `curl -s -H "Authorization: Bearer <xoxb-…>" https://slack.com/api/auth.test` → must
   return `{"ok":true}`. `invalid_auth` = bad token OR a **disallowed source IP** (the app's OAuth&Permissions → "Restrict
   API Token Usage" allowlist vs. your egress IP — clear it; note the *org* callout egresses from Salesforce IPs).
2. **Store the token in the org** (Setup → Named Credentials → External Credentials → `Slack API` → Principals → edit
   `Slack_Bot_Principal` → Authentication Parameters → Name=`BotToken`, Value=`xoxb-…`, no `Bearer` prefix). The reference
   build ships a **Custom** External Credential + bearer AuthHeader — **not** an OAuth/OIDC Auth Provider (Slack's v2 bot
   flow has no `id_token`, so OIDC fails "We can't log you in"). Secrets are org-config, not in the repo.
3. **Add the `SendSlackCardAction`** (deployed in Module 2) to the agent's Topic — an Apex `@InvocableMethod` that posts a
   **Block Kit card** of the order status via `callout:Slack_API/chat.postMessage`, with a `url` button linking to the real
   `Order__c` record. (Block Kit is built explicitly by the action — not auto-rendered.)

### 🔴 Checkpoint 5 — the Slack callout
**Verify:** run the agent (or fire the action) with a seeded order (`OR-1003`) → a Block Kit card posts to the channel with
the correct status + a working "view record" button. If `not_in_channel`, `/invite` the bot (or use `chat:write.public`).
If the record button gacks ("Looks like there's a problem"), your browser is logged into a different org — the button uses
the browser's active Salesforce session.

---

## Module 6 — Surface #4: ChatGPT over MCP (optional)

> **Optional / time-permitting.** This surface reuses the **same Hosted MCP surface as Module 3's Claude connection** —
> ChatGPT is simply a second **MCP client**, running as the signed-in user. This is a **CONNECT-level (text/data)**
> surface — it is **not** the (pre-release, gated) HXL rich-widget-in-ChatGPT render.

**Goal:** reach the same org + Skill from **ChatGPT** exactly as Module 3 reached it from Claude — an external LLM calling
a **Salesforce Hosted MCP server** over the MCP protocol (not REST, not a generic connector), governed by the signed-in
user's FLS/sharing. This makes ChatGPT the 4th external surface and directly serves the Dreamforce goal ("expose Apex/
Flows via a hosted MCP server, reach it from a surface — Slack, CLI, Web-React, **ChatGPT**").

**Why no bridge / no Ngrok:** the ChatGPT connector runs **server-to-server (OpenAI cloud → `api.salesforce.com`)**; only
the OAuth login redirect touches the browser. So a constrained presenter network (e.g. CloudFlare blocking Slack) does
**not** affect this path, and no tunnel is needed. *(A local MCP bridge over Ngrok is the fallback only if the direct
OAuth handshake fails.)*

1. **Pre-flight (do the day before — not live):**
   - ChatGPT account is **Plus / Pro / Business / Enterprise / Education** (developer mode is **not** on Free). Prefer a
     **personal Plus** account — Business/Enterprise workspaces can admin-gate connectors.
   - The org's **`sobject-reads`** standard MCP server is activated (Module 3 already does this). Read-only → its tools
     carry `readOnlyHint`, so ChatGPT won't prompt per-call write confirmations. Smoother live.
2. **Create an External Client App** for the ChatGPT connect (same recipe family as Module 3's ECA):
   OAuth ON; scopes **`mcp_api` + `refresh_token`**; **PKCE ON**; issue JWT-based tokens. Copy the **Consumer Key**
   (= OAuth Client ID). *(⚠️ confirm on your org whether ChatGPT's static-client path also needs the consumer **secret**, or
   just the key.)*
3. **In ChatGPT:** enable **developer mode** (Settings → Connectors/Apps), then **create a new app/connector**.
4. **Endpoint:** `https://api.salesforce.com/platform/mcp/v1/sobject-reads` (sandbox/scratch: `.../v1/sandbox/sobject-reads`).
   *(⚠️ confirm the exact path on your org — Salesforce's ChatGPT setup page is authoritative over blog posts.)*
5. **Auth:** Advanced → Registration Method = **User-defined OAuth client** → paste the ECA **Consumer Key** as the OAuth
   Client ID. (Salesforce does **not** support Dynamic Client Registration; ChatGPT's user-defined static client is what
   makes the two compatible — PKCE lines up on both sides.)
6. **Wire the callback:** copy ChatGPT's generated callback URL (form `https://chatgpt.com/connector/oauth/{callback_id}`)
   into the ECA's **Callback URL**; save. **Allow ~30 min for propagation** — another reason to stage this the day before.
7. **Authorize:** enable the connector → ChatGPT redirects to the org login → sign in as the workshop user → approve.
8. **Demo the read:** in the composer, select the Salesforce connector under **+**, and ask a read prompt
   (e.g. *"what's the status of order OR-1003?"* or *"list my open high-value accounts"*). It returns **real org data,
   governed by that user's FLS/sharing** — the same Skill/data reachable from Claude in Module 3, now from ChatGPT.

### 🔴 Checkpoint 6 — confirm the connection returns real data
Things to confirm as you wire this up:
- **The OAuth handshake end-to-end**: does the static client need the consumer **secret** or just the key?
  Does ChatGPT's metadata discovery (`/.well-known/oauth-protected-resource`, `/.well-known/oauth-authorization-server`,
  `WWW-Authenticate` on 401, RFC 8707 `resource` echo) succeed against `api.salesforce.com`?
- **Account tier + workspace policy** (Free fails; managed workspaces may gate connectors).
- **The exact endpoint path** and **server naming** on the live org (the org shows `sobject-reads` activated — use that).
Salesforce's authoritative setup page:
`developer.salesforce.com/docs/platform/hosted-mcp-servers/guide/chatgpt.html`.

---

# Phase 3 · Apply to Partner POC — ideation → the partner's own capability

*Joint (reunified across personas), late Day-1 → Day-2. Goal: turn the proven pattern into the partner's own capability and Dreamforce POC — the differentiated IP. Ideation started in Phase 1 (the workflow→tier mapping) pays off here.*

> **This phase is where the workshop pays off** — it's the third act every partner drives toward.
> Ideate first (which capability, which tier, which surfaces, which distribution path — from your
> Phase-1 tier mapping), then fork, then package. Modules 7–8 are labeled *optional/take-home* — the
> round-tables and the fork carry the work forward.

## Module 7 — Fork your own capability

Reskin the reference Skill to **your own capability**: swap `OrderStatusSkill` for your product's equivalent (a status +
one action), retarget the surfaces. Swap `config/kit.json` `partner_overlay`. **This is the DF payoff** — your own
cross-surface capability, ready for the Dreamforce showcase. (Do this before Package — you package what you've forked.)

---

## Module 8 — Take it home: Package your solution (optional)

**Not a required lab step — a directional wrap-up** so you can package *your own* forked Skill (Module 7) when you get
home. We proved the reference build itself packages as a **2GP unlocked package** (the `.agent` bundle, all planner
versions, and the CLT all made it in) — so the path is real; here's the shape to take back:

1. **Sort your metadata into three buckets** — the packageable **capability** (Apex + object + CLT/LWC + perm set),
   the **agent** (ships as an Agent Template + per-org activation; the `.agent` authoring layer has a managed-ISV gap),
   and the **not-packageable org config** — 🔑 **all credentials + connections (Slack token, the two External Client
   Apps, the MCP server definition) are post-install configuration**, never packaged.
2. **Deliver the org config as a post-install Skill** (the PIE `partner-package-post-install` / `sf-package-post-install`
   pattern) — package the capability, wire the creds + agent activation after install. This is the
   software-plus-services motion.
3. **Generate the package** — `sf package create` → `sf package version create` (both require a Dev Hub enabled first).

📦 That three-bucket split + these two commands are the whole shape: package the capability, deliver the org config as a post-install Skill, activate the agent per org.

---

## Showcase

Each partner demos their forked cross-surface capability: **one capability, reached from every surface** — Claude over
MCP, a React app over the Agent API, Slack, and the in-conversation card (+ ChatGPT if built). This is the Dreamforce
story — "build the capability once, meet the user on every surface."

