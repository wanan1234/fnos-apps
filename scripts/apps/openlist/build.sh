#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
ZIP_ARCH="${ZIP_ARCH:-${DEB_ARCH:-amd64}}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

echo "==> Building OpenList ${VERSION} for ${ZIP_ARCH}"

DOWNLOAD_URL="https://github.com/OpenListTeam/OpenList/releases/download/v${VERSION}/openlist-linux-${ZIP_ARCH}.tar.gz"
curl -fL -o openlist.tar.gz "$DOWNLOAD_URL"

tar -xzf openlist.tar.gz

mkdir -p app_root
OPENLIST_BIN=$(find . -name "openlist" -type f | head -1)
[ -z "$OPENLIST_BIN" ] && { echo "openlist binary not found in tarball" >&2; exit 1; }

cp "$OPENLIST_BIN" app_root/openlist
chmod +x app_root/openlist

cd app_root
tar -czf ../app.tgz .
