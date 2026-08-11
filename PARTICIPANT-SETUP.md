# Participant Org Setup — Headless 360 Workshop

Each participant gets **their own org**. Get it workshop-ready in ~10 minutes with these
steps. Steps 1–2 are clicks in Setup; step 3 is one CLI command; step 4 is a quick check.

> Prereqs on your laptop (from the pre-work email): **Salesforce CLI (`sf`)**, **Node.js**,
> **Claude Code**. Clone this repo and `cd` into it before step 3.

---

## Step 1 — Make the org yours: change the admin email

Your org ships with a placeholder admin email (`noreply@example.com`). Change it to your own
so you get verification / reset emails.

1. **Log in** to your org (link provided separately).
2. Setup → Quick Find **"My Personal Information"** → **Personal Information** → edit **Email**
   → your work email → **Save**.
3. **Confirm** the verification email Salesforce sends to that address.

_(This is also the account you'll authenticate the CLI as in step 3.)_

## Step 2 — Turn on Agentforce

The kit's agent won't deploy until Agentforce is enabled on the org (you'll get a cryptic
"Not available for deploy" error otherwise).

1. Setup → Quick Find **"Agentforce"** (Agentforce / Einstein Setup) → **turn Agentforce ON**.
2. **Wait ~1–2 minutes** for it to finish provisioning (the `Bot` / agent metadata materializes
   asynchronously — if you deploy too fast it won't be ready).

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
wire MCP, so if it's green the agent will answer once MCP/ECA is set up in Module 2/3.

**Manual (the command prints these to tick in the browser):** the Orders list view, Agent
Builder response, and the Module 2/3 MCP/ECA + Module 4 Slack steps.

✅ Green "MECHANICAL: all green" = you're build-ready. Re-run `smoke.sh` anytime.

---

## After setup — the Module 2/3 build (guided in-room, not scripted)

These are the workshop's teaching steps — you'll do them together during the build:
- **Activate Hosted MCP servers + create the MCP External Client App:**
  `./scripts/04-mcp-connect-setup.sh --org myorg` prints an exact-values guided card
  (`--verify` confirms). The JWT-token toggle is the one gotcha.
- **Smoke-test the agent:** in Agent Builder (or Slack once connected), ask
  **"status of order OR-1003"** → it should return the real record via the `OrderStatusSkill`.

Full detail: [GUIDE.md](./GUIDE.md) Modules 0–6 · troubleshooting in
[docs/credential-checklist-card.md](./docs/credential-checklist-card.md).
