#!/bin/bash
set -euo pipefail

VERSION="${1:-${VERSION:-}}"
TARBALL_ARCH="${2:-${TARBALL_ARCH:-}}"

[ -z "${VERSION}" ] && { echo "VERSION is required" >&2; exit 1; }
[ -z "${TARBALL_ARCH}" ] && { echo "TARBALL_ARCH is required" >&2; exit 1; }

echo "==> Building Jellyfin ${VERSION} (${TARBALL_ARCH})"

TARBALL_URL="https://repo.jellyfin.org/files/server/linux/latest-stable/${TARBALL_ARCH}/jellyfin_${VERSION}-${TARBALL_ARCH}.tar.gz"
FFMPEG_BASE="https://repo.jellyfin.org/files/ffmpeg/debian/latest-7.x/${TARBALL_ARCH}"
FFMPEG_DEB=$(curl -sL "$FFMPEG_BASE/" | grep -oP 'jellyfin-ffmpeg7_[^"]*-bookworm_'"${TARBALL_ARCH}"'\.deb' | head -1)
[ -z "$FFMPEG_DEB" ] && { echo "Failed to resolve ffmpeg deb from $FFMPEG_BASE/" >&2; exit 1; }
FFMPEG_URL="${FFMPEG_BASE}/${FFMPEG_DEB}"
echo "==> FFmpeg: $FFMPEG_DEB"

curl -fL -o jellyfin.tar.gz "$TARBALL_URL"
curl -fL -o jellyfin-ffmpeg7.deb "$FFMPEG_URL"

tar -xzf jellyfin.tar.gz

mkdir -p ffmpeg_extract
cd ffmpeg_extract
ar x ../jellyfin-ffmpeg7.deb
tar xf data.tar* 2>/dev/null || tar xf data.tar.xz 2>/dev/null || tar xf data.tar.gz 2>/dev/null
cd ..

dst=app_root
mkdir -p "$dst/bin" "$dst/config" "$dst/ui/images" "$dst/jellyfin-ffmpeg"

cp -a jellyfin/* "$dst/"
cp -a ffmpeg_extract/usr/lib/jellyfin-ffmpeg/* "$dst/jellyfin-ffmpeg/" 2>/dev/null || true

cp apps/jellyfin/fnos/bin/jellyfin-server "$dst/bin/jellyfin-server"
chmod +x "$dst/bin/jellyfin-server"

cp -a apps/jellyfin/fnos/ui/* "$dst/ui/" 2>/dev/null || true

cd app_root
tar -czf ../app.tgz .
