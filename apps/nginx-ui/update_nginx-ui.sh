#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="nginx-ui"
APP_DISPLAY_NAME="Nginx UI"
APP_VERSION_VAR="NGINX_UI_VERSION"
APP_VERSION="${NGINX_UI_VERSION:-latest}"
APP_DEPS=(curl ar tar jq)
APP_FPK_PREFIX="nginx-ui"
APP_HELP_VERSION_EXAMPLE="2.3.3"

CODENAME="bookworm"

app_set_arch_vars() {
    case "$ARCH" in
        x86) DEB_ARCH="amd64"; NGINX_UI_ARCH="64" ;;
        arm) DEB_ARCH="arm64"; NGINX_UI_ARCH="arm64-v8a" ;;
    esac
    info "Deb arch: $DEB_ARCH, Nginx UI arch: $NGINX_UI_ARCH"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 2.3.3      # 指定版本，x86 架构
  $0 2.3.3                 # 指定版本，自动检测架构
EOF
}

app_get_latest_version() {
    info "获取 Nginx UI 最新版本信息..."

    if [ "$APP_VERSION" = "latest" ]; then
        local tag
        # Try stable release first
        tag=$(curl -sL "https://api.github.com/repos/0xJacky/nginx-ui/releases/latest" 2>/dev/null | \
            jq -r '.tag_name // empty' 2>/dev/null)
        # Fall back to most recent release
        if [ -z "$tag" ]; then
            tag=$(curl -sL "https://api.github.com/repos/0xJacky/nginx-ui/releases" 2>/dev/null | \
                jq -r '.[0].tag_name // empty' 2>/dev/null)
        fi
        APP_VERSION=$(echo "$tag" | sed 's/^v//')
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 2.3.3"

    # Resolve nginx version
    NGINX_VERSION=$(curl -sL "https://nginx.org/packages/debian/pool/nginx/n/nginx/" 2>/dev/null | \
        grep -oE "nginx_[0-9]+\.[0-9]+\.[0-9]+-[0-9]+~${CODENAME}_amd64\.deb" | \
        sed -E 's/nginx_([0-9]+\.[0-9]+\.[0-9]+)-.*/\1/' | \
        sort -V | tail -1)

    [ -z "$NGINX_VERSION" ] && error "无法获取 Nginx 版本信息"

    info "Nginx UI 版本: $APP_VERSION"
    info "内置 Nginx 版本: $NGINX_VERSION"
}

app_download() {
    mkdir -p "$WORK_DIR"

    # Download nginx-ui
    local nginx_ui_url="https://github.com/0xJacky/nginx-ui/releases/download/v${APP_VERSION}/nginx-ui-linux-${NGINX_UI_ARCH}.tar.gz"
    info "下载 Nginx UI ($ARCH): $nginx_ui_url"
    curl -L -f -o "$WORK_DIR/nginx-ui.tar.gz" "$nginx_ui_url" || error "Nginx UI 下载失败"
    info "Nginx UI 下载完成: $(du -h "$WORK_DIR/nginx-ui.tar.gz" | cut -f1)"

    # Download nginx
    local nginx_url="https://nginx.org/packages/debian/pool/nginx/n/nginx/nginx_${NGINX_VERSION}-1~${CODENAME}_${DEB_ARCH}.deb"
    info "下载 Nginx ($ARCH): $nginx_url"
    curl -L -f -o "$WORK_DIR/nginx.deb" "$nginx_url" || error "Nginx 下载失败"
    info "Nginx 下载完成: $(du -h "$WORK_DIR/nginx.deb" | cut -f1)"
}

app_build_app_tgz() {
    cd "$WORK_DIR"

    # Extract nginx deb
    info "解压 Nginx deb 包..."
    ar -x nginx.deb
    mkdir -p nginx_extracted

    if [ -f data.tar.zst ]; then
        tar --zstd -xf data.tar.zst -C nginx_extracted
    elif [ -f data.tar.xz ]; then
        tar -xf data.tar.xz -C nginx_extracted
    elif [ -f data.tar.gz ]; then
        tar -xf data.tar.gz -C nginx_extracted
    else
        error "deb 包结构异常：找不到 data.tar.*"
    fi

    [ -d "nginx_extracted/usr/sbin" ] || error "deb 包结构异常：找不到 /usr/sbin"

    # Extract nginx-ui
    info "解压 Nginx UI..."
    mkdir -p nginx_ui_extracted
    tar -xzf nginx-ui.tar.gz -C nginx_ui_extracted

    # Assemble app_root
    info "构建 app.tgz..."
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/sbin" "$dst/conf" "$dst/html" "$dst/lib" "$dst/bin" "$dst/ui/images"

    # Nginx binary + assets
    cp nginx_extracted/usr/sbin/nginx "$dst/sbin/"
    chmod +x "$dst/sbin/nginx"
    cp -a nginx_extracted/etc/nginx/* "$dst/conf/" 2>/dev/null || true
    find "$dst/conf/" -type l -delete
    sed -i.bak 's/^user[[:space:]]\+nginx;/#user  nginx;/' "$dst/conf/nginx.conf" 2>/dev/null || true
    rm -f "$dst/conf/nginx.conf.bak"
    cp -a nginx_extracted/usr/share/nginx/html/* "$dst/html/" 2>/dev/null || true
    [ -d nginx_extracted/usr/lib ] && cp -a nginx_extracted/usr/lib/* "$dst/lib/" 2>/dev/null || true

    # Nginx UI binary
    local nginx_ui_bin
    nginx_ui_bin=$(find nginx_ui_extracted -name "nginx-ui" -type f | head -1)
    [ -z "$nginx_ui_bin" ] && error "在压缩包中找不到 nginx-ui 二进制文件"
    cp "$nginx_ui_bin" "$dst/nginx-ui"
    chmod +x "$dst/nginx-ui"

    # Startup wrapper + UI
    cp "$PKG_DIR/bin/nginx-ui-server" "$dst/bin/nginx-ui-server"
    chmod +x "$dst/bin/nginx-ui-server"
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
