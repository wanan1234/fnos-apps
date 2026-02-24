#!/bin/bash
set -euo pipefail

VERSION="${VERSION:-}"
DEB_ARCH="${DEB_ARCH:-amd64}"
CODENAME="${CODENAME:-bookworm}"

[ -z "$VERSION" ] && { echo "VERSION is required" >&2; exit 1; }

echo "==> Building Nginx UI ${VERSION} (${DEB_ARCH})"

# Map DEB_ARCH to nginx-ui release asset suffix
case "$DEB_ARCH" in
  amd64)  NGINX_UI_ARCH="64" ;;
  arm64)  NGINX_UI_ARCH="arm64-v8a" ;;
  *)      echo "Unsupported architecture: $DEB_ARCH" >&2; exit 1 ;;
esac

# --- 1. Download nginx-ui binary ---
NGINX_UI_URL="https://github.com/0xJacky/nginx-ui/releases/download/v${VERSION}/nginx-ui-linux-${NGINX_UI_ARCH}.tar.gz"
echo "Downloading nginx-ui: $NGINX_UI_URL"
curl -fL -o nginx-ui.tar.gz "$NGINX_UI_URL"

# --- 2. Download nginx (latest stable) from nginx.org ---
NGINX_VERSION=$(curl -sL "https://nginx.org/packages/debian/pool/nginx/n/nginx/" | \
  grep -oE "nginx_[0-9]+\.[0-9]+\.[0-9]+-[0-9]+~${CODENAME}_amd64\.deb" | \
  sed -E 's/nginx_([0-9]+\.[0-9]+\.[0-9]+)-.*/\1/' | sort -V | tail -1)
[ -z "$NGINX_VERSION" ] && { echo "Failed to resolve nginx version" >&2; exit 1; }
echo "Bundling nginx ${NGINX_VERSION}"

NGINX_URL="https://nginx.org/packages/debian/pool/nginx/n/nginx/nginx_${NGINX_VERSION}-1~${CODENAME}_${DEB_ARCH}.deb"
echo "Downloading nginx: $NGINX_URL"
curl -fL -o nginx.deb "$NGINX_URL"

# --- 3. Extract nginx deb ---
ar -x nginx.deb
mkdir -p nginx_extracted

if [ -f data.tar.zst ]; then
  apt-get update -qq && apt-get install -y -qq zstd >/dev/null 2>&1
  tar --zstd -xf data.tar.zst -C nginx_extracted
elif [ -f data.tar.xz ]; then
  tar -xf data.tar.xz -C nginx_extracted
elif [ -f data.tar.gz ]; then
  tar -xf data.tar.gz -C nginx_extracted
else
  echo "Unsupported nginx package format" >&2
  exit 1
fi

# --- 4. Extract nginx-ui ---
mkdir -p nginx_ui_extracted
tar -xzf nginx-ui.tar.gz -C nginx_ui_extracted

# --- 5. Assemble app_root ---
dst=app_root
mkdir -p "$dst/sbin" "$dst/conf" "$dst/html" "$dst/lib" "$dst/bin" "$dst/ui/images"

# Nginx binary + assets
cp nginx_extracted/usr/sbin/nginx "$dst/sbin/"
chmod +x "$dst/sbin/nginx"
cp -a nginx_extracted/etc/nginx/* "$dst/conf/" 2>/dev/null || true
find "$dst/conf/" -type l -delete
sed -i 's/^user[[:space:]]\+nginx;/#user  nginx;/' "$dst/conf/nginx.conf" 2>/dev/null || true
cp -a nginx_extracted/usr/share/nginx/html/* "$dst/html/" 2>/dev/null || true
[ -d nginx_extracted/usr/lib ] && cp -a nginx_extracted/usr/lib/* "$dst/lib/" 2>/dev/null || true

# Nginx UI binary
NGINX_UI_BIN=$(find nginx_ui_extracted -name "nginx-ui" -type f | head -1)
[ -z "$NGINX_UI_BIN" ] && { echo "nginx-ui binary not found in tarball" >&2; exit 1; }
cp "$NGINX_UI_BIN" "$dst/nginx-ui"
chmod +x "$dst/nginx-ui"

# Startup wrapper + UI assets from fnos/
cp apps/nginx-ui/fnos/bin/nginx-ui-server "$dst/bin/nginx-ui-server"
chmod +x "$dst/bin/nginx-ui-server"
cp -a apps/nginx-ui/fnos/ui/* "$dst/ui/" 2>/dev/null || true

# --- 6. Package ---
cd app_root
tar -czf ../app.tgz .
