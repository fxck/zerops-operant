# zerops-operant

Zerops recipe for [Operant](https://github.com/tomascupr/operant) — the self-hosted,
MIT-licensed control plane for AI agents in Slack and Microsoft Teams.

This repo is **not** a fork of Operant. It packages Operant as installable Zerops
software: the build clones a pinned revision of the Operant source, builds it, and ships
it. You run and operate it — you don't push code into it. Upgrade by bumping the pinned
ref in `operant/utils/build.sh` and redeploying.

The control plane and the OpenClaw gateway run as **two processes in one container**, so
they share a filesystem — the control plane writes the generated `openclaw.json` and the
gateway reads it from the same path (no cross-container config handoff).

## Layout

```
zerops.yaml                  Lifecycle — wires the utils/ scripts into build/run
operant/
  utils/build.sh             One clone, build both packages, pack operant+slack+msteams plugins
  utils/run-prepare.sh       Install OpenClaw + docker CLI, copy plugin tarballs into place
  utils/run-init.sh          Secret resolver, sandbox image, plugin install (no config fetch)
dockerhost/daemon.json       Sandbox Docker host: mutual-TLS dockerd config
.zerops-recipe/
  README.md                  Recipe page content (metadata + fragments)
  1 — Production/            Single-node tier      (README intro + import.yaml)
  2 — Highly-available Production/   HA-database tier (README intro + import.yaml)
```

Topology lives **per-environment** in `.zerops-recipe/<n> — <Name>/import.yaml`; there
is no root-level `import.yaml`.

## Services

| Service | Type | Role |
|---|---|---|
| `operant` | nodejs@24 | Two processes: control plane (dashboard + API, public) + OpenClaw gateway (Slack/Teams, internal). Singleton. |
| `dockerhost` | docker@26.1.5 | Isolated sandbox host for agent tool calls. Internal. |
| `db` | postgresql | All state; migrates on control-plane boot. |

## Forking

The built services point `buildFromGit` at `github.com/fxck/zerops-operant` (this
repo), not at the Operant source. If you fork, update the `buildFromGit` URLs in each
`.zerops-recipe/*/import.yaml`.
