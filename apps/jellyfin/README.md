# Jellyfin Media Server for fnOS

每日自动同步 [Jellyfin 官方](https://jellyfin.org/) 最新稳定版并构建 `.fpk` 安装包。

## 下载

从 [Releases](https://github.com/conversun/fnos-apps/releases?q=jellyfin) 下载最新的 `.fpk` 文件。

## 安装

1. 根据设备架构下载对应的 `.fpk` 文件
2. fnOS 应用管理 → 手动安装 → 上传

**访问地址**: `http://<NAS-IP>:8097`

## 说明

- Jellyfin 是 Emby 的开源分支，完全免费
- 支持电影、电视剧、音乐等多种媒体类型
- 硬件转码需要设备支持且安装系统 ffmpeg
- 数据目录包含配置、缓存、日志等

## 本地构建

```bash
./update_jellyfin.sh                        # 最新版本，自动检测架构
./update_jellyfin.sh --arch arm             # 指定架构
./update_jellyfin.sh --arch arm 10.11.6     # 指定版本
./update_jellyfin.sh --help                 # 查看帮助
```

## 版本标签

- `jellyfin/v10.11.6` — 首次发布
- `jellyfin/v10.11.6-r2` — 同版本打包修订

## Credits

- [Jellyfin](https://jellyfin.org/) - The Free Software Media System
