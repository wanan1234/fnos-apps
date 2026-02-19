#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="tinymediamanager"
APP_DISPLAY_NAME="tinyMediaManager"
APP_VERSION_VAR="TMM_VERSION"
APP_VERSION="${TMM_VERSION:-latest}"
APP_DEPS=(curl)
APP_FPK_PREFIX="tinymediamanager"
APP_HELP_VERSION_EXAMPLE="5.2.7"

app_set_arch_vars() {
    case "$ARCH" in
        x86) TAR_ARCH="amd64" ;;
        arm) TAR_ARCH="arm64" ;;
    esac
    info "Tar arch: $TAR_ARCH"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 5.2.7       # 指定版本，x86 架构
  $0 5.2.7                   # 指定版本，自动检测架构
EOF
}

app_get_latest_version() {
    info "获取最新版本信息..."

    if [ "$APP_VERSION" = "latest" ]; then
        local page
        page=$(curl -sL "https://release.tinymediamanager.org/" 2>/dev/null)
        APP_VERSION=$(echo "$page" | grep -oE 'tinyMediaManager-[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/tinyMediaManager-//')
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 5.2.7"

    info "目标版本: $APP_VERSION"
}

app_download() {
    info "Docker 镜像版本: tinymediamanager/tinymediamanager:${APP_VERSION}"
}

app_build_app_tgz() {
    info "构建 app.tgz (Docker-based)..."
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/docker" "$dst/ui"

    cp "$PKG_DIR/docker/docker-compose.yaml" "$dst/docker/"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
