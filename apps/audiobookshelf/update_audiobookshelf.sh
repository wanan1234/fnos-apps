#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_DIR="$SCRIPT_DIR/fnos"
WORK_DIR="/tmp/audiobookshelf_update_$$"
AUDIOBOOKSHELF_VERSION="${AUDIOBOOKSHELF_VERSION:-latest}"
ARCH="${ARCH:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

detect_arch() {
    if [ -z "$ARCH" ]; then
        local machine=$(uname -m)
        case "$machine" in
            x86_64|amd64)
                ARCH=x86
                ;;
            aarch64|arm64)
                ARCH=arm
                ;;
            *)
                error "Unsupported architecture: $machine. Use --arch to specify x86 or arm."
                ;;
        esac
        info "Auto-detected architecture: $ARCH"
    fi
    
    case "$ARCH" in
        x86)
            TARGET_ARCH="x64"
            DOWNLOAD_ARCH="linux-x64"
            MANIFEST_PLATFORM="x86"
            ;;
        arm)
            TARGET_ARCH="arm64"
            DOWNLOAD_ARCH="linux-arm64"
            MANIFEST_PLATFORM="arm"
            ;;
        *)
            error "Invalid architecture: $ARCH. Must be x86 or arm."
            ;;
    esac
    
    info "Target arch: $TARGET_ARCH"
    info "Download arch: $DOWNLOAD_ARCH"
    info "Manifest platform: $MANIFEST_PLATFORM"
}

get_latest_version() {
    info "获取最新版本信息..."
    
    if [ "$AUDIOBOOKSHELF_VERSION" = "latest" ]; then
        # 使用 GitHub API 获取最新稳定版本
        local releases_json=$(curl -sL "https://api.github.com/repos/advplyr/audiobookshelf/releases" 2>/dev/null)
        if [ -z "$releases_json" ]; then
            error "无法获取版本信息，请检查网络连接"
        fi
        
        AUDIOBOOKSHELF_VERSION=$(echo "$releases_json" | \
            jq -r '.[] | select(.prerelease == false and .draft == false) | .tag_name' | \
            head -1 | sed 's/^v//')
    fi
    
    [ -z "$AUDIOBOOKSHELF_VERSION" ] && error "无法获取版本信息，请手动指定: $0 2.4.0"
    
    info "目标版本: v$AUDIOBOOKSHELF_VERSION"
}

download_tar_gz() {
    local version="v$AUDIOBOOKSHELF_VERSION"
    local tar_gz_url="https://github.com/advplyr/audiobookshelf/releases/download/${version}/audiobookshelf-${AUDIOBOOKSHELF_VERSION}-${DOWNLOAD_ARCH}.tar.gz"
    
    info "下载 ($ARCH): $tar_gz_url"
    mkdir -p "$WORK_DIR"
    
    curl -L -f -o "$WORK_DIR/audiobookshelf.tar.gz" "$tar_gz_url" || error "下载失败"
    info "下载完成: $(du -h "$WORK_DIR/audiobookshelf.tar.gz" | cut -f1)"
}

extract_tar_gz() {
    info "解压 tar.gz 包..."
    cd "$WORK_DIR"
    tar -xzf audiobookshelf.tar.gz
    [ -f "audiobookshelf" ] || error "解压后找不到 audiobookshelf 可执行文件"
    info "解压完成"
}

build_app_tgz() {
    info "构建 app.tgz..."
    
    local dst="$WORK_DIR/app_root"
    mkdir -p "$dst"
    
    # 复制 audiobookshelf 二进制文件
    cp "$WORK_DIR/audiobookshelf" "$dst/"
    chmod +x "$dst/audiobookshelf"
    
    # 创建目录结构
    mkdir -p "$dst/bin" "$dst/config" "$dst/data" "$dst/metadata" "$dst/cache" "$dst/logs" "$dst/ui/images"
    
    # 创建启动脚本
    cat > "$dst/bin/audiobookshelf" << 'EOF'
#!/bin/sh
export NODE_ENV=production
export AUDIOBOOKSHELF_CONFIG_DIR=/config
export AUDIOBOOKSHELF_DATA_DIR=/data
export AUDIOBOOKSHELF_METADATA_PATH=/metadata
export AUDIOBOOKSHELF_CACHE_PATH=/cache
export AUDIOBOOKSHELF_PORT=13378

cd "$(dirname "$0")/.."
exec ./audiobookshelf
EOF
    chmod +x "$dst/bin/audiobookshelf"
    
    # 复制配置文件
    if [ -d "$PKG_DIR/config" ]; then
        cp -a "$PKG_DIR/config"/* "$dst/config/" 2>/dev/null || true
    fi
    
    # 复制 UI 文件
    if [ -d "$PKG_DIR/ui" ]; then
        cp -a "$PKG_DIR/ui"/* "$dst/ui/" 2>/dev/null || true
    fi
    
    # 复制服务控制脚本
    if [ -f "$PKG_DIR/Audiobookshelf.sc" ]; then
        cp "$PKG_DIR/Audiobookshelf.sc" "$dst/" 2>/dev/null || true
    fi
    
    # 创建默认配置文件
    if [ ! -f "$dst/config/settings.json" ]; then
        cat > "$dst/config/settings.json" << 'JSON'
{
  "port": 13378,
  "verbose": false,
  "enableCors": false,
  "paths": {
    "config": "/config",
    "metadata": "/metadata",
    "audiobooks": "/data/audiobooks",
    "podcasts": "/data/podcasts",
    "cache": "/cache"
  },
  "users": [],
  "libraries": [],
  "scanner": {
    "cronExpression": "0 0 */6 * * *"
  }
}
JSON
    fi
    
    cd "$dst"
    tar -czf "$WORK_DIR/app.tgz" .
    info "app.tgz: $(du -h "$WORK_DIR/app.tgz" | cut -f1)"
}

update_manifest() {
    info "更新 manifest..."
    
    # 计算校验和
    local checksum=$(md5 -q "$WORK_DIR/app.tgz" 2>/dev/null || md5sum "$WORK_DIR/app.tgz" | cut -d' ' -f1)
    
    # 检查是否存在 manifest 文件，如果不存在则创建
    if [ ! -f "$PKG_DIR/manifest" ]; then
        cat > "$PKG_DIR/manifest" << MANIFEST
name            = audiobookshelf
description     = Self-hosted audiobook and podcast server
version         = ${AUDIOBOOKSHELF_VERSION}
appid           = audiobookshelf
author          = advplyr
maintainer      = fnOS Community
checksum        = ${checksum}
platform        = ${MANIFEST_PLATFORM}
min_os_version  = 1.0.0
category        = media
tag             = audiobook,podcast,media,streaming
MANIFEST
        info "已创建新的 manifest 文件"
        return
    fi
    
    # 更新现有 manifest
    sed -i.tmp "s/^version.*=.*/version         = ${AUDIOBOOKSHELF_VERSION}/" "$PKG_DIR/manifest"
    sed -i.tmp "s/^checksum.*=.*/checksum        = ${checksum}/" "$PKG_DIR/manifest"
    
    if ! grep -q "^platform" "$PKG_DIR/manifest"; then
        echo "platform        = ${MANIFEST_PLATFORM}" >> "$PKG_DIR/manifest"
    else
        sed -i.tmp "s/^platform.*=.*/platform        = ${MANIFEST_PLATFORM}/" "$PKG_DIR/manifest"
    fi
    
    rm -f "$PKG_DIR/manifest.tmp"
}

build_fpk() {
    local fpk_name="audiobookshelf_${AUDIOBOOKSHELF_VERSION}_${ARCH}.fpk"
    info "打包 $fpk_name..."
    
    local shared_dir="$SCRIPT_DIR/../../shared"
    
    mkdir -p "$WORK_DIR/package/cmd"
    
    # 复制 app.tgz
    cp "$WORK_DIR/app.tgz" "$WORK_DIR/package/"
    
    # 复制共享的命令脚本
    if [ -d "$shared_dir/cmd" ]; then
        for f in "$shared_dir"/cmd/*; do
            case "$(basename "$f")" in
                *.md|*.MD) continue ;;
            esac
            cp "$f" "$WORK_DIR/package/cmd/" 2>/dev/null || true
        done
    fi
    
    # 复制应用特定的命令脚本
    [ -d "$PKG_DIR/cmd" ] && cp -a "$PKG_DIR"/cmd/* "$WORK_DIR/package/cmd/" 2>/dev/null || true
    
    # 复制配置文件
    cp -a "$PKG_DIR/config" "$WORK_DIR/package/" 2>/dev/null || true
    
    # 复制向导文件
    if [ -d "$PKG_DIR/wizard" ]; then
        cp -a "$PKG_DIR/wizard" "$WORK_DIR/package/"
    elif [ -d "$shared_dir/wizard" ]; then
        cp -a "$shared_dir/wizard" "$WORK_DIR/package/"
    fi
    
    # 复制图标
    cp "$PKG_DIR"/ICON*.PNG "$WORK_DIR/package/" 2>/dev/null || true
    cp "$PKG_DIR"/*.sc "$WORK_DIR/package/" 2>/dev/null || true
    
    # 复制 manifest
    cp "$PKG_DIR/manifest" "$WORK_DIR/package/"
    
    cd "$WORK_DIR/package"
    tar -czf "$SCRIPT_DIR/$fpk_name" *
    
    info "生成: $SCRIPT_DIR/$fpk_name ($(du -h "$SCRIPT_DIR/$fpk_name" | cut -f1))"
}

show_help() {
    cat << EOF
用法: $0 [选项] [版本号|latest]

选项:
  --arch ARCH       指定目标架构 (x86 或 arm)，默认自动检测
  -h, --help        显示此帮助信息

示例:
  $0                        # 最新稳定版，自动检测架构
  $0 --arch arm             # 最新版本，ARM 架构
  $0 --arch x86 2.4.0       # 指定版本，x86 架构

环境变量:
  ARCH                  目标架构 (x86 或 arm)
  AUDIOBOOKSHELF_VERSION  Audiobookshelf 版本号

支持的架构:
  x86 (x86_64)          Intel/AMD 64位处理器
  arm (aarch64)         ARM 64位处理器

注意:
  - 版本号可以指定为 "latest" 或具体的版本号（如 2.4.0）
  - 版本号前不需要加 "v"，脚本会自动处理
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --arch)
                ARCH="$2"
                shift 2
                ;;
            --arch=*)
                ARCH="${1#*=}"
                shift
                ;;
            -*)
                error "未知选项: $1"
                ;;
            *)
                AUDIOBOOKSHELF_VERSION="$1"
                shift
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    
    echo "========================================"
    echo "  Audiobookshelf fnOS Package Builder"
    echo "========================================"
    echo
    
    # 检查依赖
    for cmd in curl tar sed; do
        command -v $cmd &>/dev/null || error "缺少依赖: $cmd"
    done
    
    # 检查 jq
    if ! command -v jq &>/dev/null; then
        info "正在安装 jq..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y jq || error "安装 jq 失败"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install jq || error "安装 jq 失败"
        else
            error "请手动安装 jq：https://stedolan.github.io/jq/download/"
        fi
    fi
    
    detect_arch
    
    local current_version=""
    if [ -f "$PKG_DIR/manifest" ]; then
        current_version=$(grep "^version" "$PKG_DIR/manifest" | awk -F'=' '{print $2}' | tr -d ' ')
        if [ -n "$current_version" ]; then
            info "当前版本: $current_version"
        fi
    fi
    
    get_latest_version
    
    if [ -n "$current_version" ] && [ "$current_version" = "$AUDIOBOOKSHELF_VERSION" ]; then
        warn "已是最新版本"
        read -p "强制重新构建? [y/N] " -n 1 -r; echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    download_tar_gz
    extract_tar_gz
    build_app_tgz
    update_manifest
    build_fpk
    
    echo
    info "完成: ${current_version:-"N/A"} -> $AUDIOBOOKSHELF_VERSION ($ARCH)"
    echo
    info "安装包已生成: $(ls "$SCRIPT_DIR"/audiobookshelf_*.fpk 2>/dev/null | head -1)"
}

main "$@"