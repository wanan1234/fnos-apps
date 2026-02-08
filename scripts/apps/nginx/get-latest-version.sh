#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"
CODENAME="bookworm"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  VERSION=$(curl -sL "https://nginx.org/packages/debian/pool/nginx/n/nginx/" | \
    grep -oE "nginx_[0-9]+\.[0-9]+\.[0-9]+-[0-9]+~${CODENAME}_amd64\.deb" | \
    sed -E 's/nginx_([0-9]+\.[0-9]+\.[0-9]+)-.*/\1/' | sort -V | tail -1)
fi

[ -z "$VERSION" ] && { echo "Failed to resolve version for nginx" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
