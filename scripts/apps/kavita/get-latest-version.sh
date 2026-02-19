#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

TAG=$(curl -sL "https://api.github.com/repos/Kareadita/Kavita/releases/latest" | \
  jq -r '.tag_name')

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  # Docker tags use 3-segment versions (e.g. 0.8.9), GitHub uses 4-segment (e.g. v0.8.9.1)
  VERSION=$(echo "$TAG" | sed 's/^v//' | sed 's/\.[0-9]*$//')
fi

[ -z "$VERSION" ] && { echo "Failed to resolve version for kavita" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
