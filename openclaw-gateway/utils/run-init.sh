#!/bin/sh
# gateway — per-start init (runs EVERY container start, after deploy files are at
# /var/www). Referenced from zerops.yaml run.initCommands. Several steps are
# intentionally non-fatal (|| true), so no `set -e` here. The OpenClaw deploy scripts
# (secret resolver, sandbox Dockerfile, ensure-channel-plugins.sh) come from the
# Operant clone at /var/www/deploy/openclaw/.

mkdir -p /var/www/.openclaw-state /var/www/.docker-certs

# /operant/openclaw is OpenClaw's hardcoded secrets-provider trustedDir.
sudo mkdir -p /operant/openclaw && sudo chown zerops:zerops /operant/openclaw

# Secret resolver (from the Operant clone) + its node wrapper (what the generated
# config execs; it passes the .mjs as the arg).
install -m 0755 /var/www/deploy/openclaw/operant-secret-resolver.mjs /operant/openclaw/operant-secret-resolver.mjs
printf '#!/bin/sh\nexec /usr/local/bin/node "$@"\n' > /operant/openclaw/operant-secret-resolver && chmod 0755 /operant/openclaw/operant-secret-resolver

# Docker mutual-TLS client creds (docker CLI convention: ca/cert/key.pem). Non-fatal.
(cp /etc/zerops-zembed/ca.crt /var/www/.docker-certs/ca.pem && cp /etc/zerops-zembed/cert.crt /var/www/.docker-certs/cert.pem && cp /etc/zerops-zembed/cert.key /var/www/.docker-certs/key.pem) || true

# Build the openclaw sandbox image ON dockerhost once (no-op when present). Non-fatal.
docker image inspect openclaw-sandbox:bookworm-slim >/dev/null 2>&1 || docker build -t openclaw-sandbox:bookworm-slim -f /var/www/deploy/openclaw/Dockerfile.sandbox-runtime /var/www/deploy/openclaw || true

# Clean-slate plugin state before install: openclaw's install registry resets on a
# fresh container, so a leftover extensions dir makes the installer abort mid-extract
# (crash-loop). Wiping forces a clean reinstall from the local tarballs every boot.
rm -rf "$OPENCLAW_STATE_DIR/extensions"/* "$OPENCLAW_STATE_DIR/plugins/installs.json" 2>/dev/null || true
sh /var/www/deploy/openclaw/ensure-channel-plugins.sh || true

# Fetch the generated config from the control plane over the private network
# (HTTP handoff — replaces the Compose shared-volume model). Non-fatal: no config
# exists until an admin generates one in the dashboard.
node -e "fetch(process.env.OPERANT_CONTROL_PLANE_URL+'/internal/openclaw/config',{headers:{Authorization:'Bearer '+process.env.OPERANT_INTERNAL_TOKEN}}).then(r=>r.ok?r.text():Promise.reject(r.status)).then(t=>require('fs').writeFileSync(process.env.OPENCLAW_CONFIG_PATH,t)).then(()=>console.log('config fetched')).catch(e=>console.log('no config yet:',e))" || true
