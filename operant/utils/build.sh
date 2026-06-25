#!/bin/sh
# operant (control plane) — build step. Runs in the Zerops build container at
# /build/source. Clones a pinned revision of the Operant source (a build input — never
# edited in place) and builds the @operant/control-plane package.
#
# Upgrade Operant: bump OPERANT_REF here and in openclaw-gateway/utils/build.sh.
set -e
OPERANT_REF="${OPERANT_REF:-v0.6.0}"

git clone --depth 1 --branch "$OPERANT_REF" https://github.com/tomascupr/operant src
cd src
corepack enable
# Keep the pnpm store outside src/ so the cache never collides with the fresh clone.
pnpm config set store-dir /build/source/.pnpm-store
pnpm install --filter @operant/control-plane --frozen-lockfile
pnpm --filter @operant/control-plane build
