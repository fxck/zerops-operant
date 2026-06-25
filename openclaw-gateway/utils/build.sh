#!/bin/sh
# gateway — build step (Zerops build container, /build/source). Clones pinned Operant
# source, builds the Operant OpenClaw plugin, and packs ALL THREE OpenClaw plugins
# (operant + slack + msteams) into plugins/ as tarballs — so plugin assembly happens
# once at build time, not over the network at runtime. build.addToRunPrepare ships
# plugins/ to /home/zerops/plugins; run-prepare.sh copies the tarballs into place.
#
# Upgrade Operant:  bump OPERANT_REF (also in operant/utils/build.sh).
# Upgrade OpenClaw: bump OPENCLAW_VERSION (also in run-prepare.sh).
set -e
OPERANT_REF="${OPERANT_REF:-v0.6.0}"
OPENCLAW_VERSION="${OPENCLAW_VERSION:-2026.5.18}"

git clone --depth 1 --branch "$OPERANT_REF" https://github.com/tomascupr/operant src
cd src
corepack enable
# Keep the pnpm store outside src/ so the cache never collides with the fresh clone.
pnpm config set store-dir /build/source/.pnpm-store
pnpm install --filter @operant/openclaw-plugin --frozen-lockfile
pnpm --filter @operant/openclaw-plugin build

cd /build/source
mkdir -p plugins
# 1) the Operant plugin — built from the clone, version-matched to the source
( cd src/apps/openclaw-plugin && npm pack --pack-destination /build/source/plugins )
# 2) the pinned OpenClaw channel plugins (Slack + Teams)
npm pack --pack-destination /build/source/plugins "@openclaw/slack@$OPENCLAW_VERSION"
npm pack --pack-destination /build/source/plugins "@openclaw/msteams@$OPENCLAW_VERSION"

# Stage run-prepare.sh next to the tarballs so it ships to /home/zerops/plugins too
# (a known-good addToRunPrepare path — avoids guessing nested-path semantics).
cp openclaw-gateway/utils/run-prepare.sh /build/source/plugins/
