# openclaw-gateway

No application source lives here — the `gateway` service builds by cloning a pinned
revision of [github.com/tomascupr/operant](https://github.com/tomascupr/operant),
building the `@operant/openclaw-plugin` package, and installing OpenClaw at runtime.
The long lifecycle logic lives in `utils/`, called from the `setup: gateway` block in
[`../zerops.yaml`](../zerops.yaml):

- `utils/build.sh` — clone + build the Operant plugin, then pack **all three** OpenClaw
  plugins (operant + slack + msteams) into `plugins/` as tarballs.
- `utils/run-prepare.sh` — runtime image setup (once): install OpenClaw + docker CLI,
  copy the plugin tarballs into the install dir.
- `utils/run-init.sh` — per-start init: secret-resolver wrapper, sandbox image build,
  plugin install, and the HTTP config fetch from the control plane.

The gateway's own runtime scripts (`operant-secret-resolver.mjs`,
`ensure-channel-plugins.sh`, `Dockerfile.sandbox-runtime`) ship inside the Operant
clone at `deploy/openclaw/`, so they're not duplicated here.
