# Operant — Zerops recipe

See the [root README](../README.md) · source: **[github.com/tomascupr/operant](https://github.com/tomascupr/operant)**

## Recipe metadata

- **Name:** <!-- #ZEROPS_EXTRACT_START:name# -->Operant<!-- #ZEROPS_EXTRACT_END:name# -->
- **Shape:** <!-- #ZEROPS_EXTRACT_START:shape# -->software<!-- #ZEROPS_EXTRACT_END:shape# --> — you run and operate it, you don't fork its source
- **Environments:** `Production` · `HA Production` — single-node for evaluation and steady traffic, or a 3-node HA Postgres cluster for data durability (the app is a singleton either way)

## Tagline

<!-- #ZEROPS_EXTRACT_START:intro# -->
A self-hosted, MIT-licensed control plane for AI agents in Slack and Microsoft Teams — every action runs as the human who asked, not a shared bot, with per-user OAuth to 3,000+ tools.
<!-- #ZEROPS_EXTRACT_END:intro# -->

## Overview

<!-- #ZEROPS_EXTRACT_START:description# -->
Operant puts a governed AI agent in your Slack and Microsoft Teams channels and makes every action attributable to a real person. Instead of one shared bot acting for the whole workspace, each user connects their own Gmail, Notion, GitHub, Linear, HubSpot, or other Pipedream account, and the agent calls tools under that human's own OAuth connection. Every session, policy decision, and tool call names the person who triggered it.

It wraps [OpenClaw](https://docs.openclaw.ai) — a permissively-licensed agent runtime that owns chat ingress, sessions, the browser/cloud-computer, and tool execution — and adds the enterprise control plane around it: BYOK credentials encrypted AES-256-GCM in your own Postgres, six built-in roles plus arbitrary `(action, resource)` grants, named-approver gates for risky work, full audit/usage/cost tracking, retention export and wipe, governed team memory and skills, governed scheduled workflows, and a strict-CSP admin dashboard. Slack and Teams are dual-identity: one person carries one policy and audit trail across both. Bring your own model key — any provider, not just one vendor.

Two topologies ship as one recipe: a single-node **Production** for evaluation and steady traffic, and a **Highly-available Production** with a 3-node Postgres cluster for data durability. Both run the whole stack natively on Zerops — one Operant service (the control plane and the OpenClaw gateway run as two processes in a single container, sharing a filesystem), a managed PostgreSQL for all state, and a dedicated Docker host that runs every agent tool call in an isolated, throwaway sandbox container.
<!-- #ZEROPS_EXTRACT_END:description# -->

## Features

<!-- #ZEROPS_EXTRACT_START:features# -->
- **Acts as the human, not a shared bot** — each tool call runs under the requesting user's own per-user OAuth, keyed on their Slack member ID or Teams AAD ID.
- **3,000+ tools, self-serve** — an Integrations marketplace backed by Pipedream Connect; users connect, preview, and revoke their own SaaS accounts from the dashboard or by asking the agent.
- **Per-person audit of everything** — sessions, jobs, policy decisions, credential resolutions, and usage/cost are durable and named to a real person, with token-shaped secrets redacted before persistence.
- **RBAC + named-approver gates** — six built-in roles plus arbitrary custom `(action, resource)` grants; admins gate risky apps/actions with minimum-approval rules before work runs.
- **Your credentials, your trust boundary** — Slack/Teams tokens and model keys live AES-256-GCM encrypted in your own Postgres; plaintext never leaves the control plane.
- **One identity across Slack and Teams** — run either platform alone or both side by side on one control plane, with a single policy and audit trail.
- **Governed memory, skills, and scheduled workflows** — team/private-isolated knowledge, admin-curated skill definitions, and recurring agent runs that Operant authors, RBAC-gates, and audits.
- **Sandboxed tool execution** — every agent tool call runs in an isolated, throwaway container on a dedicated Docker host, so risky work never touches the gateway itself.
- **Bring your own model** — any provider's key, configured from the dashboard; you're not locked to a single vendor.
<!-- #ZEROPS_EXTRACT_END:features# -->

## First-run setup

<!-- #ZEROPS_EXTRACT_START:takeover-guide# -->
**Sign in to the dashboard.** Open the control-plane service's public subdomain (the `operant` service), then sign in with the `OPERANT_ADMIN_LOGIN_TOKEN` from your environment plus your own Slack member ID (`U…`) or Microsoft Teams AAD user ID. That first signed-in admin becomes the workspace owner. If the token is wrong or missing you can't reach any dashboard view — read it from the `operant` service's env variables.

**Walk the Setup tab.** Setup collects everything Operant needs at runtime and stores it encrypted in Postgres — not in env: your Slack app + bot tokens and/or Microsoft Teams app credentials, and your model API key (any provider). Create the Slack app from the bundled `deploy/slack/manifest.yaml` and enable Socket Mode; for Teams, wire an Azure Bot to the OpenClaw `msteams` channel. Either platform stands alone, or run both. Until a platform's credentials are saved, that channel stays disabled and the agent won't respond there.

**Approve the gateway device for scheduled workflows.** Governed scheduled workflows and secret reloads materialize into the OpenClaw gateway, which requires the control-plane device to be approved for the gateway's operator scopes (`operator.read`, `operator.approvals`, `operator.talk.secrets`). Workflow authoring, RBAC, and audit all work without it — only the push into OpenClaw cron needs the pairing, and unmaterialized workflows are saved as `error` and re-applied once the device is approved.

**Connect your tools.** Once a platform is live, each user opens the Integrations marketplace (or asks the agent in chat for a connect link) and OAuths their own SaaS accounts via Pipedream Connect. Tool calls then run under that person's connection. Pipedream is configured by setting the project OAuth client env vars; with them unset, the agent still runs but only the built-in tools register.
<!-- #ZEROPS_EXTRACT_END:takeover-guide# -->

## Knowledge base

<!-- #ZEROPS_EXTRACT_START:knowledge-base# -->
### Architecture

This recipe deploys Operant as three Zerops services — `operant` (built from a pinned Operant clone), managed `db`, and a `dockerhost`:

- **`operant` (Node.js)** — runs two processes in one container:
  - **control plane** (port `8080`) — the entire HTTP API and the static admin dashboard. Exposes `/healthz`/`/readyz`, runs all SQL migrations transactionally on boot, encrypts BYOK credentials, and enforces RBAC, policy, approvals, audit, and retention. Its subdomain is your dashboard URL (the only public surface).
  - **OpenClaw gateway** (port `18789`, Teams webhook `3978`) — chat ingress for Slack (Socket Mode) and Teams (Azure Bot webhook), agent sessions, and tool execution.

  They share the container's filesystem, so the control plane writes the generated `openclaw.json` to `/operant/openclaw/` and the gateway reads it from the same path — no cross-container config handoff. The service is a **singleton** (`maxContainers: 1`): the gateway owns one Slack connection plus OpenClaw's session/cron state and can't be replicated. Scale it vertically.
- **`db` (managed PostgreSQL)** — the single source of truth for all state: workspaces, roles, encrypted credentials, audit/usage rows, memory, skills, and scheduled-workflow definitions. Single-node in Production, a 3-node HA cluster in HA Production.
- **`dockerhost` (Docker host)** — a dedicated Docker daemon exposed to the `operant` service over mutual-TLS on the private network. The gateway process runs each agent tool call in an isolated `openclaw-sandbox` container here (`OPERANT_OPENCLAW_SANDBOX_MODE=docker`), keeping tool execution off the gateway itself.

The control plane **observes** OpenClaw sessions/tasks and **authors** governed workflows it materializes into OpenClaw cron — it owns the definition, RBAC, and audit while OpenClaw stays the executor.

### Environment variables

Auto-wired by the recipe (don't change unless you know why):

- `DATABASE_URL` — composed from the managed `db` service connection variables.
- `OPENCLAW_GATEWAY_URL` / `OPERANT_CONTROL_PLANE_URL` — loopback (`http://localhost:…`); the two processes talk over localhost inside the one container.
- `OPENCLAW_CONFIG_PATH` — the shared on-disk path (`/operant/openclaw/openclaw.json`); the control-plane process writes it, the gateway process reads it — same container, same disk.
- `OPERANT_HOST` / `OPERANT_PORT` — bind address and port (`0.0.0.0:8080`).

Generated once at import (random secrets; rotating them invalidates existing sessions/encrypted data):

- `OPERANT_INTERNAL_TOKEN` *(project-level, shared)* — bearer the gateway uses to fetch config, resolve secrets, and check policy against the control plane.
- `OPENCLAW_GATEWAY_TOKEN` *(project-level, shared)* — the gateway's auth token; the control plane also uses it to run OpenClaw checks against the gateway.
- `OPERANT_SECRET_KEY` *(`operant` service)* — must decode to exactly 32 bytes. The AES-256-GCM key for all stored credentials; the control plane refuses to encrypt without it.
- `OPERANT_ADMIN_LOGIN_TOKEN` *(`operant` service)* — the shared dashboard login secret for admin sign-in and first-time setup.

Configured later through the dashboard Setup tab (stored encrypted in Postgres, **not** env): Slack app/bot tokens, Teams app credentials, and your model API key. Pipedream Connect uses the `PIPEDREAM_PROJECT_*` + `OPERANT_MCP_SOURCE_PIPEDREAM_URL` env vars; set all of them to enable per-user SaaS tools, or leave them unset to run with built-in tools only.

### Troubleshooting

- **Can't sign in to the dashboard** — the `OPERANT_ADMIN_LOGIN_TOKEN` env value must match what you type, and you must supply a real Slack member ID (`U…`) or Teams AAD ID, not a placeholder.
- **Agent doesn't respond in a channel** — that platform's credentials aren't saved yet (Setup tab), the channel isn't allowlisted in Policy, or the user isn't permitted. Check the Health and Activity views.
- **Scheduled workflows stuck in `error`** — the control-plane device isn't approved for the gateway's cron/operator scopes. Approve the explicit device request (not `--latest`, which is only a preview) and re-apply the workflow.
- **Tools missing / only built-ins available** — the four `PIPEDREAM_PROJECT_*` vars (plus the MCP source URL) must all be set; if any is missing the Pipedream tool set is skipped with a warning rather than failing the gateway.
- **Boot fails on credential encryption** — `OPERANT_SECRET_KEY` doesn't decode to exactly 32 bytes.
<!-- #ZEROPS_EXTRACT_END:knowledge-base# -->
