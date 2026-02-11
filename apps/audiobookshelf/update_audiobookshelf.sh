#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"

APP_NAME="audiobookshelf"
APP_DISPLAY_NAME="Audiobookshelf"
APP_VERSION_VAR="AUDIOBOOKSHELF_VERSION"
APP_VERSION="${AUDIOBOOKSHELF_VERSION:-latest}"
APP_DEPS=(curl tar)
APP_FPK_PREFIX="audiobookshelf"
APP_HELP_VERSION_EXAMPLE="2.19.4"

NODE_VERSION="20.18.1"

app_set_arch_vars() {
    case "$ARCH" in
        x86) DEB_ARCH="amd64"; NODE_ARCH="x64" ;;
        arm) DEB_ARCH="arm64"; NODE_ARCH="arm64" ;;
    esac
    info "Deb arch: $DEB_ARCH, Node arch: $NODE_ARCH"
}

app_show_help_examples() {
    cat << EOF
  $0 --arch x86 2.19.4       # 指定版本，x86 架构
  $0 2.19.4                   # 指定版本，自动检测架构
EOF
}

app_get_latest_version() {
    info "获取最新版本信息..."

    if [ "$APP_VERSION" = "latest" ]; then
        APP_VERSION=$(curl -sL "https://api.github.com/repos/advplyr/audiobookshelf/releases/latest" | \
            grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    fi

    [ -z "$APP_VERSION" ] && error "无法获取版本信息，请手动指定: $0 2.19.4"
    info "目标版本: $APP_VERSION"
}

app_download() {
    mkdir -p "$WORK_DIR"

    if [ "$DEB_ARCH" = "amd64" ]; then
        local deb_url="https://advplyr.github.io/audiobookshelf-ppa/audiobookshelf_${APP_VERSION}_amd64.deb"
        info "下载 .deb ($ARCH): $deb_url"
        curl -L -f -o "$WORK_DIR/audiobookshelf.deb" "$deb_url" || error "下载失败"
        info "下载完成: $(du -h "$WORK_DIR/audiobookshelf.deb" | cut -f1)"
    else
        local src_url="https://github.com/advplyr/audiobookshelf/archive/refs/tags/v${APP_VERSION}.tar.gz"
        info "下载源码 ($ARCH): $src_url"
        curl -L -f -o "$WORK_DIR/source.tar.gz" "$src_url" || error "源码下载失败"
        info "源码下载完成: $(du -h "$WORK_DIR/source.tar.gz" | cut -f1)"

        local node_url="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz"
        info "下载 Node.js ($NODE_ARCH): $node_url"
        curl -L -f -o "$WORK_DIR/node.tar.xz" "$node_url" || error "Node.js 下载失败"
        info "Node.js 下载完成: $(du -h "$WORK_DIR/node.tar.xz" | cut -f1)"
    fi
}

app_build_app_tgz() {
    cd "$WORK_DIR"
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst/bin" "$dst/ui/images"

    if [ "$DEB_ARCH" = "amd64" ]; then
        info "解压 deb 包..."
        ar -x audiobookshelf.deb
        mkdir -p extracted
        if [ -f data.tar.xz ]; then
            tar -xf data.tar.xz -C extracted
        elif [ -f data.tar.gz ]; then
            tar -xf data.tar.gz -C extracted
        elif [ -f data.tar.zst ]; then
            zstd -d data.tar.zst -o data.tar
            tar -xf data.tar -C extracted
        else
            error "deb 包格式异常"
        fi
        [ -d "extracted/usr/share/audiobookshelf" ] || error "deb 包结构异常"
        cp -a extracted/usr/share/audiobookshelf/* "$dst/"
    else
        info "解压源码..."
        tar -xzf source.tar.gz
        local srcdir="audiobookshelf-${APP_VERSION}"

        info "解压 Node.js..."
        mkdir -p node_extracted
        tar -xf node.tar.xz -C node_extracted --strip-components=1

        info "构建客户端..."
        cd "$WORK_DIR/$srcdir/client"
        npm ci
        npm run generate
        cd "$WORK_DIR"

        info "安装生产依赖..."
        cd "$WORK_DIR/$srcdir"
        npm ci --only=production
        cd "$WORK_DIR"

        mkdir -p "$dst/node/bin" "$dst/client"
        cp node_extracted/bin/node "$dst/node/bin/"
        cp "$srcdir/index.js" "$dst/"
        cp "$srcdir/package.json" "$dst/"
        cp -a "$srcdir/server" "$dst/"
        cp -a "$srcdir/client/dist" "$dst/client/"
        cp -a "$srcdir/node_modules" "$dst/"

        cat > "$dst/audiobookshelf" << 'WRAPPER'
#!/bin/sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/node/bin/node" "$SCRIPT_DIR/index.js"
WRAPPER
        chmod +x "$dst/audiobookshelf"
    fi

    cp "$PKG_DIR/bin/audiobookshelf-server" "$dst/bin/" 2>/dev/null || true
    chmod +x "$dst/bin/audiobookshelf-server" 2>/dev/null || true
    cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true

    info "构建 app.tgz..."
    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

source "$REPO_ROOT/scripts/lib/update-common.sh"
main_flow "$@"
