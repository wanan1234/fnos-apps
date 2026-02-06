# Plex Media Server for fnOS

每日自动同步 [Plex 官方下载](https://www.plex.tv/media-server-downloads/) 最新版本并构建 `.fpk` 安装包。

## 下载

从 [Releases](https://github.com/conversun/fnos-apps/releases?q=plex) 下载最新的 `.fpk` 文件。

## 安装

1. 根据设备架构下载对应的 `.fpk` 文件
2. fnOS 应用管理 → 手动安装 → 上传

**访问地址**: `http://<NAS-IP>:32400/web`

## 本地构建

```bash
./update_plex.sh                          # 最新版本，自动检测架构
./update_plex.sh --arch arm               # 指定架构
./update_plex.sh --arch arm 1.42.2.10156  # 指定版本
./update_plex.sh --help                   # 查看帮助
```

## 版本标签

- `plex/v1.42.2.10156` — 首次发布
- `plex/v1.42.2.10156-r2` — 同版本打包修订

## Credits

- [Plex](https://www.plex.tv/) - Media Server
