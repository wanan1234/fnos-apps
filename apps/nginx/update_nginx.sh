#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="nginx"
APP_DISPLAY_NAME="Nginx"
APP_VERSION_VAR="NGINX_VERSION"
APP_VERSION="${NGINX_VERSION:-latest}"
APP_DEPS=(curl ar tar sed)
APP_FPK_PREFIX="nginxserver"
APP_HELP_VERSION_EXAMPLE="1.28.2"

CODENAME="bookworm"

app_set_arch_vars() {
    case "$ARCH" in
        x86) DEB_ARCH="amd64" ;;
        arm) DEB_ARCH="arm64" ;;
    esac
    info "Deb arch: $DEB_ARCH"
}

app_get_latest_version() {
    info "获取最新版本信息..."

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION=$(curl -sL "https://nginx.org/packages/debian/pool/nginx/n/nginx/" 2>/dev/null | \
            grep -oE "nginx_[0-9]+\.[0-9]+\.[0-9]+-[0-9]+~${CODENAME}_amd64\.deb" | \
            sed -E 's/nginx_([0-9]+\.[0-9]+\.[0-9]+)-.*/\1/' | \
            sort -V | tail -1)
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 1.28.2"
    info "目标版本: $APP_VERSION"
}

app_download() {
    local deb_url="https://nginx.org/packages/debian/pool/nginx/n/nginx/nginx_${APP_VERSION}-1~${CODENAME}_${DEB_ARCH}.deb"

    info "下载 ($ARCH): $deb_url"
    mkdir -p "$WORK_DIR"
    curl -L -f -o "$WORK_DIR/nginx.deb" "$deb_url" || error "下载失败"
    info "下载完成: $(du -h "$WORK_DIR/nginx.deb" | cut -f1)"
}

app_build_app_tgz() {
    info "解压 deb 包..."
    cd "$WORK_DIR"
    ar -x nginx.deb
    mkdir -p extracted

    if [ -f data.tar.zst ]; then
        tar --zstd -xf data.tar.zst -C extracted
    elif [ -f data.tar.xz ]; then
        tar -xf data.tar.xz -C extracted
    elif [ -f data.tar.gz ]; then
        tar -xf data.tar.gz -C extracted
    else
        error "deb 包结构异常：找不到 data.tar.*"
    fi

    [ -d "extracted/usr/sbin" ] || error "deb 包结构异常：找不到 /usr/sbin"

    info "构建 app.tgz..."
    local src="$WORK_DIR/extracted"
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/sbin" "$dst/conf" "$dst/html" "$dst/lib" "$dst/ui/images"

    cp "$src/usr/sbin/nginx" "$dst/sbin/"
    chmod +x "$dst/sbin/nginx"

    cp -a "$src/etc/nginx"/* "$dst/conf/" 2>/dev/null || true
    find "$dst/conf/" -type l -delete
    # 'user nginx;' → fnOS uses privilege config, not system nginx user
    sed -i.bak 's/^user[[:space:]]\+nginx;/#user  nginx;/' "$dst/conf/nginx.conf" 2>/dev/null || true
    rm -f "$dst/conf/nginx.conf.bak"

    cp -a "$src/usr/share/nginx/html"/* "$dst/html/" 2>/dev/null || true
    [ -d "$src/usr/lib" ] && cp -a "$src/usr/lib"/* "$dst/lib/" 2>/dev/null || true

    cp "$PKG_DIR/bin/nginx-server" "$dst/bin/" 2>/dev/null || {
        mkdir -p "$dst/bin"
        cp "$PKG_DIR/bin/nginx-server" "$dst/bin/"
    }
    chmod +x "$dst/bin/nginx-server"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
