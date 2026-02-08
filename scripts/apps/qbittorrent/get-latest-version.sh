#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

UPSTREAM_TAG=$(curl -sL "https://api.github.com/repos/userdocs/qbittorrent-nox-static/releases/latest" | \
  jq -r '.tag_name')

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  VERSION=$(echo "$UPSTREAM_TAG" | sed -E 's/release-([0-9]+\.[0-9]+\.[0-9]+)_.*/\1/')
fi

[ -z "$VERSION" ] && { echo "Failed to resolve version for qbittorrent" >&2; exit 1; }

echo "VERSION=$VERSION"
echo "UPSTREAM_TAG=$UPSTREAM_TAG"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
  echo "upstream_tag=$UPSTREAM_TAG" >> "$GITHUB_OUTPUT"
fi
