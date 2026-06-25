#!/bin/sh
# operant — per-start init (runs EVERY container start, before the startCommands
# processes). Referenced from zerops.yaml run.initCommands. Several steps are
# intentionally non-fatal (|| true), so no `set -e`. The OpenClaw deploy scripts
# (secret resolver, sandbox Dockerfile, ensure-channel-plugins.sh) come from the
# Operant clone at /var/www/deploy/openclaw/.

mkdir -p /var/www/.openclaw-state /var/www/.docker-certs

# /operant/openclaw is OpenClaw's hardcoded secrets-provider trustedDir AND where the
# control-plane process writes openclaw.json. The gateway process reads it from here —
# same container, same disk, so no cross-service config delivery is needed.
sudo mkdir -p /operant/openclaw && sudo chown zerops:zerops /operant/openclaw

# Secret resolver (from the Operant clone) + its node wrapper (what the generated config
# execs; it passes the .mjs as the arg).
install -m 0755 /var/www/deploy/openclaw/operant-secret-resolver.mjs /operant/openclaw/operant-secret-resolver.mjs
printf '#!/bin/sh\nexec /usr/local/bin/node "$@"\n' > /operant/openclaw/operant-secret-resolver && chmod 0755 /operant/openclaw/operant-secret-resolver

# Docker mutual-TLS client creds (docker CLI convention: ca/cert/key.pem). Non-fatal.
(cp /etc/zerops-zembed/ca.crt /var/www/.docker-certs/ca.pem && cp /etc/zerops-zembed/cert.crt /var/www/.docker-certs/cert.pem && cp /etc/zerops-zembed/cert.key /var/www/.docker-certs/key.pem) || true

# Build the openclaw sandbox image ON dockerhost once (no-op when present). Non-fatal.
docker image inspect openclaw-sandbox:bookworm-slim >/dev/null 2>&1 || docker build -t openclaw-sandbox:bookworm-slim -f /var/www/deploy/openclaw/Dockerfile.sandbox-runtime /var/www/deploy/openclaw || true

# Clean-slate plugin state before install: openclaw's install registry resets on a fresh
# container, so a leftover extensions dir makes the installer abort mid-extract
# (crash-loop). Wiping forces a clean reinstall from the local tarballs every boot.
rm -rf "$OPENCLAW_STATE_DIR/extensions"/* "$OPENCLAW_STATE_DIR/plugins/installs.json" 2>/dev/null || true
sh /var/www/deploy/openclaw/ensure-channel-plugins.sh || true

# NO config fetch. The control-plane process writes /operant/openclaw/openclaw.json to
# this same disk when an admin generates config, and signals the gateway to reload over
# localhost — there is no separate gateway container to deliver it to.
