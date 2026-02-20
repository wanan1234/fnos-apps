#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
ZIP_ARCH="${ZIP_ARCH:-${DEB_ARCH:-amd64}}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

echo "==> Building Gopeed ${VERSION} for ${ZIP_ARCH}"

DOWNLOAD_URL="https://github.com/GopeedLab/gopeed/releases/download/v${VERSION}/gopeed-web-v${VERSION}-linux-${ZIP_ARCH}.zip"
curl -fL -o gopeed-web.zip "$DOWNLOAD_URL"

unzip -o gopeed-web.zip

mkdir -p app_root/bin app_root/ui
GOPEED_BIN=$(find . -path "*/gopeed-web-*/gopeed" -type f | head -1)
[ -z "$GOPEED_BIN" ] && { echo "gopeed binary not found in zip" >&2; exit 1; }

cp "$GOPEED_BIN" app_root/gopeed
chmod +x app_root/gopeed

cp apps/gopeed/fnos/bin/gopeed-server app_root/bin/gopeed-server
chmod +x app_root/bin/gopeed-server
cp -a apps/gopeed/fnos/ui/* app_root/ui/ 2>/dev/null || true

cd app_root
tar -czf ../app.tgz .
