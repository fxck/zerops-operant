#!/bin/sh
# operant — build step (Zerops build container, /build/source). ONE clone of pinned
# Operant source builds BOTH workspace packages (the control plane runs as one process,
# the OpenClaw plugin is bundled into the gateway process — same container), and packs
# all three OpenClaw plugins (operant + slack + msteams) into plugins/ as tarballs.
#
# Upgrade Operant:  bump OPERANT_REF.
# Upgrade OpenClaw: bump OPENCLAW_VERSION (also in run-prepare.sh).
set -e
OPERANT_REF="${OPERANT_REF:-v0.6.0}"
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.5.18}"

git clone --depth 1 --branch "$OPERANT_REF" https://github.com/tomascupr/operant src
cd src
corepack enable
# Keep the pnpm store outside src/ so the cache never collides with the fresh clone.
pnpm config set store-dir /build/source/.pnpm-store
pnpm install --filter @operant/control-plane --filter @operant/openclaw-plugin --frozen-lockfile
pnpm --filter @operant/control-plane build
pnpm --filter @operant/openclaw-plugin build

cd /build/source
mkdir -p plugins
# 1) the Operant plugin — built from the clone, version-matched to the source
( cd src/apps/openclaw-plugin && npm pack --pack-destination /build/source/plugins )
# 2) the pinned OpenClaw channel plugins (Slack + Teams)
npm pack --pack-destination /build/source/plugins "@openclaw/slack@$OPENCLAW_VERSION"
npm pack --pack-destination /build/source/plugins "@openclaw/msteams@$OPENCLAW_VERSION"

# Stage run-prepare.sh next to the tarballs so it ships to /home/zerops/plugins too
# (a known-good addToRunPrepare path).
cp operant/utils/run-prepare.sh /build/source/plugins/
