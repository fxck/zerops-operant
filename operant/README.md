# operant (control plane + OpenClaw gateway)

No application source lives here — the `operant` service builds by cloning a pinned
revision of [github.com/tomascupr/operant](https://github.com/tomascupr/operant) and
building both the `@operant/control-plane` and `@operant/openclaw-plugin` packages.

It runs **two processes in one container** (`zerops.yaml` `run.startCommands`): the
control plane (`node …/server.js`, port 8080) and the OpenClaw gateway
(`openclaw gateway run`, ports 18789/3978). Co-locating them means they share a
filesystem, so the generated `openclaw.json` the control plane writes is read directly
by the gateway — no cross-container config delivery.

The long lifecycle logic lives in `utils/`, called from the `setup: operant` block in
[`../zerops.yaml`](../zerops.yaml):

- `utils/build.sh` — one clone, build both packages, pack all three OpenClaw plugins.
- `utils/run-prepare.sh` — runtime setup: install OpenClaw + docker CLI, copy plugin tarballs into place.
- `utils/run-init.sh` — per-start init: secret-resolver wrapper, sandbox image build, plugin install. (No config fetch — the control-plane process writes the config to the shared local path.)

The gateway's own runtime scripts (`operant-secret-resolver.mjs`,
`ensure-channel-plugins.sh`, `Dockerfile.sandbox-runtime`) ship inside the Operant clone
at `deploy/openclaw/`, so they're not duplicated here.
