#!/bin/bash
set -euo pipefail

VERSION="${1:-${VERSION:-}}"
JRE_ARCH="${2:-${JRE_ARCH:-}}"

[ -z "${VERSION}" ] && { echo "VERSION is required" >&2; exit 1; }
[ -z "${JRE_ARCH}" ] && { echo "JRE_ARCH is required" >&2; exit 1; }

echo "==> Building ani-rss ${VERSION} (JRE arch: ${JRE_ARCH})"

# Download fat JAR (platform-independent)
JAR_URL="https://github.com/wushuo894/ani-rss/releases/download/v${VERSION}/ani-rss-jar-with-dependencies.jar"
curl -L -o ani-rss.jar "$JAR_URL"

# Download Temurin JRE 17 headless
JRE_URL="https://api.adoptium.net/v3/binary/latest/17/ga/linux/${JRE_ARCH}/jre/hotspot/normal/eclipse"
curl -L -o jre.tar.gz "$JRE_URL"
mkdir -p jre_extracted
tar -xzf jre.tar.gz -C jre_extracted --strip-components=1

# Assemble app_root
dst=app_root
mkdir -p "$dst/bin" "$dst/jre" "$dst/config" "$dst/ui/images"

cp ani-rss.jar "$dst/ani-rss-jar-with-dependencies.jar"
cp -a jre_extracted/* "$dst/jre/"

cp apps/ani-rss/fnos/bin/ani-rss-server "$dst/bin/ani-rss-server"
chmod +x "$dst/bin/ani-rss-server"

cp -a apps/ani-rss/fnos/ui/* "$dst/ui/" 2>/dev/null || true

cd app_root
tar -czf ../app.tgz .
