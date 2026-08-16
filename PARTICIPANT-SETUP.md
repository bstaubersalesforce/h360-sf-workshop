# Participant Org Setup — Headless 360 Workshop

Each participant self-provisions **their own org** from OrgFarm, then gets it build-ready in
~10 minutes. Step 1 claims the org (self-serve); step 2 verifies Agentforce; step 3 is one CLI
command; step 4 is a quick check.

> **Laptop prereqs** (from the pre-work email, installed *before* you arrive): **Salesforce CLI (`sf`)**,
> **Node.js**, **Claude Code**.

**Get the kit** — open a terminal, go to the folder where you keep code (e.g. `~/claude-projects`), and clone this
repo (do this before Step 3):

```bash
git clone https://github.com/bstaubersalesforce/h360-sf-workshop.git
cd h360-sf-workshop
```

---

## Step 1 — Claim your workshop org (OrgFarm, self-serve)

You provision your **own** pre-configured org from OrgFarm using the workshop event code — no
waiting on an assigned login.

1. Go to **https://orgfarm.salesforce.com/signup**.
2. Enter the **workshop event code** (provided by your facilitator / on the setup slide) — it
   dispenses the workshop template (**template 161**), pre-configured for Headless 360.
3. Complete the signup form. **Use your work email** as the admin email so you receive
   verification / reset mail, then **confirm** the verification email Salesforce sends.
4. **Log in** to your new org and note its My Domain URL.

> The event code is scoped to this workshop and time-boxed — claim your org close to the event
> and keep it active (OrgFarm/DE-style orgs deprovision after an idle period). This is the
> account you'll authenticate the CLI as in step 3.

## Step 2 — Verify Agentforce is on

Template 161 is pre-configured for the workshop, so Agentforce **should already be enabled**.
Verify it before you deploy — the kit's agent won't deploy otherwise (you'd get a cryptic "Not
available for deploy" error).

1. Setup → Quick Find **"Agentforce"** (Agentforce / Einstein Setup) → confirm **Agentforce is ON**.
2. **If it's off:** turn it on and **wait ~1–2 minutes** for provisioning to finish (the `Bot` /
   agent metadata materializes asynchronously — if you deploy too fast it won't be ready).

## Step 3 — Deploy the kit from the CLI

Authenticate the CLI to your org, then run the one-command onboarder.

```bash
sf org login web --alias myorg          # sign in as your (step-1) admin user
./scripts/06-org-onboard.sh --org myorg
```

`06-org-onboard.sh` does the scriptable half in order and is safe to re-run:
- **guards** that Agentforce is actually on (points you back to step 2 if not),
- **deploys** the reference build (`02`) — Order__c object + Apex Skill + LWC + CLT + agent bundle,
  then publishes + activates the agent,
- **assigns** the workshop permission set to you (`03`),
- **seeds** the 5 hero orders incl. **OR-1003** (`05`),
- **smoke-tests** (5 hero rows present, agent deployed).

> If you re-run it, you may see a `WARN: permset assign failed` line — that's just the permset
> being *already assigned*; it's non-fatal and the final "onboarded" line confirms success.

## Step 4 — Smoke test: "is my org ready to build?"

One command runs every mechanical check and prints the manual (browser) checklist:

```bash
./scripts/smoke.sh --org myorg              # add --with-tests for the full Apex suite
```

**Mechanical (auto):** org reachable · Agentforce enabled · hero data (5 orders) · permset
assigned · agent deployed · **the real `OrderStatusSkill` returns OR-1003** (Exception /
"Approve rebooking" + card) — this last one proves the agent's code path works *before* you
wire MCP, so if it's green the agent will answer once MCP/ECA is set up in Module 3.

**Manual (the command prints these to tick in the browser):** the Orders list view, Agent
Builder response, and the Module 3 MCP/ECA + Module 5 Slack steps.

✅ Green "MECHANICAL: all green" = you're build-ready. Re-run `smoke.sh` anytime.

---

## After setup — the Module 3 build (guided in-room, not scripted)

These are the workshop's teaching steps — you'll do them together during the build:
- **Activate Hosted MCP servers + create the MCP External Client App** — this prints an exact-values guided card:
  ```bash
  ./scripts/04-mcp-connect-setup.sh --org myorg       # add --verify after you create the ECA
  ```
  The JWT-token toggle is the one gotcha.
- **Smoke-test the agent:** in Agent Builder (or Slack once connected), ask
  **"status of order OR-1003"** → it should return the real record via the `OrderStatusSkill`.

Full detail: [GUIDE.md](./GUIDE.md) Modules 0–8b · troubleshooting in
[docs/credential-checklist-card.md](./docs/credential-checklist-card.md).
