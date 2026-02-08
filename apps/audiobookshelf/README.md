# Emby Server for fnOS

每日自动同步 [Emby 官方 Releases](https://github.com/MediaBrowser/Emby.Releases/releases) 最新正式版并构建 `.fpk` 安装包。

## 下载

从 [Releases](https://github.com/conversun/fnos-apps/releases?q=emby) 下载最新的 `.fpk` 文件。

## 安装

1. 根据设备架构下载对应的 `.fpk` 文件
2. fnOS 应用管理 → 手动安装 → 上传

**访问地址**: `http://<NAS-IP>:8096`

## 本地构建

```bash
./update_emby.sh                      # 最新版本，自动检测架构
./update_emby.sh --arch arm           # 指定架构
./update_emby.sh --arch arm 4.9.3.0   # 指定版本
./update_emby.sh --help               # 查看帮助
```

## 版本标签

- `emby/v4.9.3.0` — 首次发布
- `emby/v4.9.3.0-r2` — 同版本打包修订

## Credits

- [Emby](https://emby.media/) - Media Server
- [FnDepot](https://github.com/Hxido-RXM/FnDepot) - Original fnOS package source
