#!/bin/sh
# gateway — runtime image customization (runs ONCE, before deploy files arrive; cached).
# Installs OpenClaw + the docker CLI, then copies the three plugin tarballs (packed at
# build time, shipped to /home/zerops/plugins via build.addToRunPrepare) into the dir
# that ensure-channel-plugins.sh installs from. No /var/www/ access here by design.
#
# Keep OPENCLAW_VERSION in sync with openclaw-gateway/utils/build.sh.
set -e
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.5.18}"

sudo apk add --no-cache libstdc++ python3 make g++ docker-cli
sudo npm install -g "openclaw@$OPENCLAW_VERSION"
sudo mkdir -p /usr/local/share/operant/openclaw/plugins
sudo cp /home/zerops/plugins/*.tgz /usr/local/share/operant/openclaw/plugins/
