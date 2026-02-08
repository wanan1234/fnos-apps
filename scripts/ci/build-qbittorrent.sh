#!/bin/bash
set -euo pipefail

UPSTREAM_TAG="${1:-}"
QB_BINARY_PREFIX="${2:-}"

[ -z "${UPSTREAM_TAG}" ] && { echo "UPSTREAM_TAG is required" >&2; exit 1; }
[ -z "${QB_BINARY_PREFIX}" ] && { echo "QB_BINARY_PREFIX is required" >&2; exit 1; }

echo "==> Building qBittorrent (${QB_BINARY_PREFIX}) from ${UPSTREAM_TAG}"
DOWNLOAD_URL="https://github.com/userdocs/qbittorrent-nox-static/releases/download/${UPSTREAM_TAG}/${QB_BINARY_PREFIX}-qbittorrent-nox"
curl -L -o qbittorrent-nox "$DOWNLOAD_URL"
chmod +x qbittorrent-nox

YEAR_MONTH=$(date +%Y-%m)
mkdir -p GeoDB
GEODB_URL="https://download.db-ip.com/free/dbip-country-lite-${YEAR_MONTH}.mmdb.gz"
if ! curl -L -f -o GeoDB/dbip-country-lite.mmdb.gz "$GEODB_URL"; then
  YEAR_MONTH=$(date -d "1 month ago" +%Y-%m)
  GEODB_URL="https://download.db-ip.com/free/dbip-country-lite-${YEAR_MONTH}.mmdb.gz"
  curl -L -f -o GeoDB/dbip-country-lite.mmdb.gz "$GEODB_URL" || true
fi
[ -f GeoDB/dbip-country-lite.mmdb.gz ] && gunzip -f GeoDB/dbip-country-lite.mmdb.gz

mkdir -p app_root/bin app_root/ui/images app_root/var/qBittorrent/config app_root/var/qBittorrent/data/GeoDB
cp qbittorrent-nox app_root/bin/qbittorrent-nox
chmod +x app_root/bin/qbittorrent-nox
cp -a apps/qbittorrent/fnos/ui/* app_root/ui/ 2>/dev/null || true
cp -a GeoDB/* app_root/var/qBittorrent/data/GeoDB/ 2>/dev/null || true

cp apps/qbittorrent/fnos/defaults/qBittorrent.conf app_root/var/qBittorrent/config/qBittorrent.conf

cd app_root
tar -czf ../app.tgz .
