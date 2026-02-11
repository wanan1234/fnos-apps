#!/bin/bash
set -euo pipefail

# Audiobookshelf build script for fnOS CI
#
# For x86 (amd64): downloads pre-built .deb from the official PPA
# For arm (arm64): builds from source with bundled Node.js runtime
#
# Env vars (from CI matrix):
#   VERSION     - Audiobookshelf version (e.g. 2.19.4)
#   DEB_ARCH    - amd64 or arm64
#   TARBALL_ARCH - amd64 or arm64 (same as DEB_ARCH for this app)

VERSION="${1:-${VERSION:-}}"
DEB_ARCH="${2:-${DEB_ARCH:-}}"
TARBALL_ARCH="${TARBALL_ARCH:-$DEB_ARCH}"

[ -z "${VERSION}" ] && { echo "VERSION is required" >&2; exit 1; }
[ -z "${DEB_ARCH}" ] && { echo "DEB_ARCH is required" >&2; exit 1; }

NODE_VERSION="20.18.1"

echo "==> Building Audiobookshelf ${VERSION} (${DEB_ARCH})"

dst=app_root

if [ "$DEB_ARCH" = "amd64" ]; then
  # ---------- x86: download .deb from official PPA ----------
  DEB_URL="https://advplyr.github.io/audiobookshelf-ppa/audiobookshelf_${VERSION}_amd64.deb"
  echo "Downloading .deb: $DEB_URL"
  curl -L -f -o audiobookshelf.deb "$DEB_URL"

  ar -x audiobookshelf.deb
  mkdir -p extracted
  # Handle both data.tar.xz and data.tar.gz
  if [ -f data.tar.xz ]; then
    tar -xf data.tar.xz -C extracted
  elif [ -f data.tar.gz ]; then
    tar -xf data.tar.gz -C extracted
  elif [ -f data.tar.zst ]; then
    zstd -d data.tar.zst -o data.tar
    tar -xf data.tar -C extracted
  else
    echo "Unknown data archive format in .deb" >&2; exit 1
  fi

  [ -d "extracted/usr/share/audiobookshelf" ] || { echo "Unexpected .deb structure" >&2; exit 1; }

  mkdir -p "$dst/bin" "$dst/ui/images"
  # The .deb contains a single pkg-compiled binary at /usr/share/audiobookshelf/audiobookshelf
  cp -a extracted/usr/share/audiobookshelf/* "$dst/"

else
  # ---------- arm64: build from source with bundled Node.js ----------
  echo "ARM64: building from source"

  # Map arch for Node.js download
  NODE_ARCH="arm64"

  # Download Node.js runtime for target
  NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
  echo "Downloading Node.js: $NODE_URL"
  curl -L -f -o node.tar.xz "$NODE_URL"
  mkdir -p node_extracted
  tar -xf node.tar.xz -C node_extracted --strip-components=1

  # Download Audiobookshelf source
  SRC_URL="https://github.com/advplyr/audiobookshelf/archive/refs/tags/v${VERSION}.tar.gz"
  echo "Downloading source: $SRC_URL"
  curl -L -f -o source.tar.gz "$SRC_URL"
  tar -xzf source.tar.gz

  SRCDIR="audiobookshelf-${VERSION}"

  # Build client
  echo "Building client..."
  cd "$SRCDIR/client"
  npm ci
  npm run generate
  cd ../..

  # Install production server dependencies
  echo "Installing server dependencies..."
  cd "$SRCDIR"
  npm ci --only=production
  cd ..

  # Assemble app_root
  mkdir -p "$dst/bin" "$dst/node/bin" "$dst/client" "$dst/ui/images"

  # Node.js runtime (only the binary to save space)
  cp node_extracted/bin/node "$dst/node/bin/"

  # Application files
  cp "$SRCDIR/index.js" "$dst/"
  cp "$SRCDIR/package.json" "$dst/"
  cp -a "$SRCDIR/server" "$dst/"
  cp -a "$SRCDIR/client/dist" "$dst/client/"
  cp -a "$SRCDIR/node_modules" "$dst/"

  # Create wrapper that uses bundled Node.js
  cat > "$dst/audiobookshelf" << 'WRAPPER'
#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/node/bin/node" "$SCRIPT_DIR/index.js"
WRAPPER
  chmod +x "$dst/audiobookshelf"
fi

# Copy fnOS-specific files
cp apps/audiobookshelf/fnos/bin/audiobookshelf-server "$dst/bin/"
chmod +x "$dst/bin/audiobookshelf-server"
cp -a apps/audiobookshelf/fnos/ui/* "$dst/ui/" 2>/dev/null || true

cd app_root
tar -czf ../app.tgz .
