# fnOS Apps

飞牛 fnOS 第三方应用集合，每日自动同步上游最新版本并构建 `.fpk` 安装包。

## 应用列表

| 应用 | 端口 | 说明 |
|------|------|------|
| [Plex Media Server](apps/plex/) | 32400 | 媒体服务器，支持硬件转码 |
| [Emby Server](apps/emby/) | 8096 | 媒体管理和流式传输 |
| [qBittorrent](apps/qbittorrent/) | 8085 | 轻量级 BitTorrent 客户端 |

## 下载

从 [Releases](https://github.com/conversun/fnos-apps/releases) 下载对应应用的 `.fpk` 文件。

按应用筛选：
- Plex: 标签以 `plex/v` 开头
- Emby: 标签以 `emby/v` 开头
- qBittorrent: 标签以 `qbittorrent/v` 开头

## 安装

1. 根据设备架构下载对应的 `.fpk` 文件（x86 或 arm）
2. 在 fnOS 应用管理中选择「手动安装」
3. 上传 fpk 文件完成安装

## 项目结构

```
fnos-apps/
├── shared/              # 共享框架（所有应用复用）
│   ├── cmd/             # 通用生命周期脚本和守护进程管理
│   └── wizard/          # 通用向导模板
├── apps/
│   ├── plex/            # Plex 应用特有文件
│   ├── emby/            # Emby 应用特有文件
│   └── qbittorrent/     # qBittorrent 应用特有文件
├── scripts/
│   ├── build-fpk.sh     # 通用 fpk 打包脚本
│   └── new-app.sh       # 新应用脚手架
└── .github/workflows/   # 每个应用独立 CI/CD
```

## 新增应用

```bash
./scripts/new-app.sh jellyfin "Jellyfin Media Server" 8096
```

脚手架会生成应用模板，只需填写应用特有的启动脚本和构建逻辑。

## 本地构建

```bash
# 构建单个应用（以 Plex 为例）
cd apps/plex
./update_plex.sh

# 使用共享脚本打包 fpk
./scripts/build-fpk.sh apps/plex app.tgz "1.42.2.10156" "x86"
```

## 开源透明

本项目完全开源，仅从官方渠道下载原版软件并重新打包，**无任何后门或修改**。构建脚本和 CI 流程公开透明，欢迎审查。
