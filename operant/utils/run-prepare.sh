#!/bin/sh
# operant — runtime image customization (runs ONCE, before deploy files arrive; cached).
# Installs OpenClaw + the docker CLI (for the gateway process), then copies the three
# plugin tarballs (packed at build time, shipped to /home/zerops/plugins) into the dir
# ensure-channel-plugins.sh installs from. The control-plane process needs nothing extra
# here — Node is already in the base image.
#
# Keep OPENCLAW_VERSION in sync with operant/utils/build.sh.
set -e
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.5.18}"

sudo apk add --no-cache libstdc++ python3 make g++ docker-cli
sudo npm install -g "openclaw@$OPENCLAW_VERSION"
sudo mkdir -p /usr/local/share/operant/openclaw/plugins
sudo cp /home/zerops/plugins/*.tgz /usr/local/share/operant/openclaw/plugins/
