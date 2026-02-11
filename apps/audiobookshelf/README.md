# Audiobookshelf for fnOS

每日自动同步 [Audiobookshelf](https://github.com/advplyr/audiobookshelf) 最新版本并构建 `.fpk` 安装包。

## 下载

从 [Releases](https://github.com/conversun/fnos-apps/releases?q=audiobookshelf) 下载最新的 `.fpk` 文件。

## 安装

1. 根据设备架构下载对应的 `.fpk` 文件
2. fnOS 应用管理 → 手动安装 → 上传

**访问地址**: `http://<NAS-IP>:13378`

## 说明

- 自托管的有声书和播客服务器
- 支持多用户管理和收听进度同步
- 首次访问会引导创建管理员账户
- x86 版本使用官方 PPA 预编译二进制
- ARM 版本从源码构建并内置 Node.js 运行环境

## 本地构建

```bash
./update_audiobookshelf.sh                       # 最新版本，自动检测架构
./update_audiobookshelf.sh --arch arm            # 指定架构
./update_audiobookshelf.sh --arch arm 2.19.4     # 指定版本
./update_audiobookshelf.sh --help                # 查看帮助
```

## 版本标签

- `audiobookshelf/v2.19.4` — 首次发布
- `audiobookshelf/v2.19.4-r2` — 同版本打包修订

## Credits

- [Audiobookshelf](https://www.audiobookshelf.org/) - Self-hosted audiobook and podcast server
- [Node.js](https://nodejs.org/) - Runtime (bundled for ARM)
