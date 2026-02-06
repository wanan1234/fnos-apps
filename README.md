# fnOS Apps

飞牛 fnOS 第三方应用集合，每日自动同步上游最新版本并构建 `.fpk` 安装包。

## 应用列表

| 应用 | 端口 | 说明 | 下载 |
|------|------|------|------|
| [Plex Media Server](apps/plex/) | 32400 | 媒体服务器，支持硬件转码 | [Releases](https://github.com/conversun/fnos-apps/releases?q=plex) |
| [Emby Server](apps/emby/) | 8096 | 媒体管理和流式传输 | [Releases](https://github.com/conversun/fnos-apps/releases?q=emby) |
| [qBittorrent](apps/qbittorrent/) | 8085 | 轻量级 BitTorrent 客户端 | [Releases](https://github.com/conversun/fnos-apps/releases?q=qbittorrent) |

## 安装

1. 从上方链接下载对应应用的 `.fpk` 文件（x86 或 arm）
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

## 本地构建

```bash
cd apps/plex && ./update_plex.sh
cd apps/emby && ./update_emby.sh
cd apps/qbittorrent && ./update_qbittorrent.sh
```

## 开源透明

本项目完全开源，仅从官方渠道下载原版软件并重新打包，**无任何后门或修改**。构建脚本和 CI 流程公开透明，欢迎审查。
