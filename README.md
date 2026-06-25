# zerops-operant

Zerops recipe for [Operant](https://github.com/tomascupr/operant) — the self-hosted,
MIT-licensed control plane for AI agents in Slack and Microsoft Teams.

This repo is **not** a fork of Operant. It packages Operant as installable Zerops
software: each service's build clones a pinned revision of the Operant source, builds
it, and ships it. You run and operate it — you don't push code into it. Upgrade by
bumping the pinned ref in the `utils/build.sh` scripts and redeploying.

## Layout

```
zerops.yaml                  Lifecycle — wires the per-service utils/ scripts into build/run
operant/
  utils/build.sh             Control-plane: clone + build @operant/control-plane
openclaw-gateway/
  utils/build.sh             Gateway: clone + build plugin, pack operant+slack+msteams
  utils/run-prepare.sh       Gateway: install OpenClaw, copy plugin tarballs into place
  utils/run-init.sh          Gateway: secret resolver, sandbox image, config fetch
dockerhost/daemon.json       Sandbox Docker host: mutual-TLS dockerd config
.zerops-recipe/
  README.md                  Recipe page content (metadata + fragments)
  1 — Production/            Single-node tier      (README intro + import.yaml)
  2 — Highly-available Production/   HA tier        (README intro + import.yaml)
```

Topology lives **per-environment** in `.zerops-recipe/<n> — <Name>/import.yaml`; there
is no root-level `import.yaml`.

## Services

| Service | Type | Role |
|---|---|---|
| `operant` | nodejs@24 | Control plane: dashboard + API. The only public service. |
| `gateway` | nodejs@24 | OpenClaw: Slack/Teams ingress, sessions, tool execution. Internal singleton. |
| `dockerhost` | docker@26.1.5 | Isolated sandbox host for agent tool calls. Internal. |
| `db` | postgresql | All state; migrates on control-plane boot. |

## Forking

The built services point `buildFromGit` at `github.com/fxck/zerops-operant` (this
repo), not at the Operant source. If you fork, update the `buildFromGit` URLs in each
`.zerops-recipe/*/import.yaml`.
