# operant (control plane)

No application source lives here — the `operant` service builds by cloning a pinned
revision of [github.com/tomascupr/operant](https://github.com/tomascupr/operant) and
building the `@operant/control-plane` package.

- `utils/build.sh` — the build step (clone + `pnpm build`), called from the
  `setup: operant` block in [`../zerops.yaml`](../zerops.yaml).

The control-plane init is a single line (create the OpenClaw config dir), kept inline
in `zerops.yaml`.
