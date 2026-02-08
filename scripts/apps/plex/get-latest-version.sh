#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

API_RESPONSE=$(curl -sL "https://plex.tv/api/downloads/5.json")

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  VERSION=$(echo "$API_RESPONSE" | jq -r '.computer.Linux.version' | cut -d'-' -f1)
fi

FULL_VERSION=$(echo "$API_RESPONSE" | jq -r '.computer.Linux.version')

[ -z "$VERSION" ] && { echo "Failed to resolve version for plex" >&2; exit 1; }

echo "VERSION=$VERSION"
echo "FULL_VERSION=$FULL_VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
  echo "full_version=$FULL_VERSION" >> "$GITHUB_OUTPUT"
fi
