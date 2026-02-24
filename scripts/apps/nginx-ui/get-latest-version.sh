#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  # Try latest stable release first
  TAG=$(curl -sL "https://api.github.com/repos/0xJacky/nginx-ui/releases/latest" | \
    jq -r '.tag_name // empty' 2>/dev/null)

  # Fall back to most recent release (including pre-releases)
  if [ -z "$TAG" ]; then
    TAG=$(curl -sL "https://api.github.com/repos/0xJacky/nginx-ui/releases" | \
      jq -r '.[0].tag_name // empty' 2>/dev/null)
  fi

  VERSION=$(echo "$TAG" | sed 's/^v//')
fi

[ -z "$VERSION" ] && { echo "Failed to resolve version for nginx-ui" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
