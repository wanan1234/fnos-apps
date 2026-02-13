#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
TARBALL_ARCH="${TARBALL_ARCH:-${DEB_ARCH:-amd64}}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

echo "==> Building fnos-apps-store ${VERSION} for ${TARBALL_ARCH}"

DOWNLOAD_URL="https://github.com/conversun/fnos-store/releases/download/v${VERSION}/store-server-linux-${TARBALL_ARCH}"
curl -L -o store-server "$DOWNLOAD_URL"
chmod +x store-server

mkdir -p app_root
mv store-server app_root/store-server

cd app_root
tar -czf ../app.tgz .
