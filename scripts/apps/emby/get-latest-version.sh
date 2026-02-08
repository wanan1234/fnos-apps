#!/bin/bash
set -euo pipefail

INPUT_VERSION="${1:-}"

if [ -n "$INPUT_VERSION" ]; then
  VERSION="$INPUT_VERSION"
else
  VERSION=$(curl -sL "https://github.com/MediaBrowser/Emby.Releases/releases" | \
    grep -oE '(releases/tag/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[^"]*|Latest)' | \
    grep -B1 "^Latest$" | head -1 | sed 's|releases/tag/||')
fi

[ -z "$VERSION" ] && { echo "Failed to resolve version for emby" >&2; exit 1; }

echo "VERSION=$VERSION"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
fi
