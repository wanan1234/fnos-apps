# Gopeed for fnOS

每日自动同步 [Gopeed 官方](https://gopeed.com/) 最新版本并构建 `.fpk` 安装包。

## 下载

从 [Releases](https://github.com/conversun/fnos-apps/releases?q=gopeed) 下载最新的 `.fpk` 文件。

## 安装

1. 根据设备架构下载对应的 `.fpk` 文件
2. fnOS 应用管理 → 手动安装 → 上传

**访问地址**: `http://<NAS-IP>:9999`

## 说明

- Gopeed 是一款高速下载器，支持 HTTP、BitTorrent、Magnet 等协议
- 内置 Web UI，支持浏览器扩展
- 支持插件系统，可扩展下载功能
- 数据存储在应用数据目录中

## 本地构建

```bash
./update_gopeed.sh                        # 最新版本，自动检测架构
./update_gopeed.sh --arch arm             # 指定架构
./update_gopeed.sh --arch arm 1.9.1       # 指定版本
./update_gopeed.sh --help                 # 查看帮助
```

## 版本标签

- `gopeed/v1.9.1` — 首次发布
- `gopeed/v1.9.1-r2` — 同版本打包修订

## Credits

- [Gopeed](https://gopeed.com/) - A Modern Download Manager
