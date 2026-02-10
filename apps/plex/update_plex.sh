#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

# ============================================================================
# App-specific config
# ============================================================================
APP_NAME="plex"
APP_DISPLAY_NAME="Plex"
APP_VERSION_VAR="PLEX_VERSION"
APP_VERSION="${PLEX_VERSION:-latest}"
APP_DEPS=(curl ar tar sed)
APP_FPK_PREFIX="plexmediaserver"
APP_HELP_VERSION_EXAMPLE="1.42.2.10156"

# ============================================================================
# App-specific arch mapping
# ============================================================================
app_set_arch_vars() {
    case "$ARCH" in
        x86) PLEX_BUILD="linux-x86_64" ;;
        arm) PLEX_BUILD="linux-aarch64" ;;
    esac
    info "Plex build type: $PLEX_BUILD"
}

# ============================================================================
# App-specific callbacks
# ============================================================================
app_get_latest_version() {
    info "获取最新版本信息..."
    local api_response
    api_response=$(curl -sL "https://plex.tv/api/downloads/5.json" 2>/dev/null)

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION=$(echo "$api_response" | grep -o '"version":"[^"]*"' | head -1 | sed 's/"version":"//;s/"//' | cut -d'-' -f1)
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 1.42.2.10156"
    info "目标版本: $APP_VERSION"
}

app_download() {
    local api_response
    api_response=$(curl -sL "https://plex.tv/api/downloads/5.json" 2>/dev/null)

    local download_url
    if command -v jq &>/dev/null; then
        download_url=$(echo "$api_response" | jq -r ".computer.Linux.releases[] | select(.build == \"$PLEX_BUILD\" and .distro == \"debian\") | .url")
    else
        case "$PLEX_BUILD" in
            linux-x86_64)
                download_url=$(echo "$api_response" | grep -o '"build":"linux-x86_64","distro":"debian","url":"[^"]*"' | head -1 | sed 's/.*"url":"//;s/"$//')
                ;;
            linux-aarch64)
                download_url=$(echo "$api_response" | grep -o '"build":"linux-aarch64","distro":"debian","url":"[^"]*"' | head -1 | sed 's/.*"url":"//;s/"$//')
                ;;
        esac
    fi

    [ -z "$download_url" ] && error "无法获取 $ARCH 架构的下载链接"
    info "下载链接: $download_url"

    info "下载 Plex Media Server ($ARCH)..."
    mkdir -p "$WORK_DIR"
    curl -L -f -o "$WORK_DIR/plex.deb" "$download_url" || error "下载失败"
    info "下载完成: $(du -h "$WORK_DIR/plex.deb" | cut -f1)"
}

app_build_app_tgz() {
    info "解压 deb 包..."
    cd "$WORK_DIR"
    ar -x plex.deb
    mkdir -p extracted
    tar -xf data.tar.xz -C extracted
    [ -d "extracted/usr/lib/plexmediaserver" ] || error "deb 包结构异常"

    info "构建 app.tgz..."
    local src="$WORK_DIR/extracted/usr/lib/plexmediaserver"
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/lib" "$dst/ui/images"

    cp -a "$src"/* "$dst/"
    cp "$PKG_DIR/bin/plex-server" "$dst/bin/"
    chmod +x "$dst/bin/plex-server"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/"

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

# ============================================================================
# Source shared library and run
# ============================================================================
source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
