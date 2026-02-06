# qBittorrent for fnOS

每日自动同步 [qbittorrent-nox-static](https://github.com/userdocs/qbittorrent-nox-static/releases) 最新版本并构建 `.fpk` 安装包。

## 下载

从 [Releases](https://github.com/conversun/fnos-apps/releases?q=qbittorrent) 下载 `.fpk` 文件。

## 安装

1. 根据设备架构下载对应的 `.fpk` 文件
2. fnOS 应用管理 → 手动安装 → 上传

**默认账号**: `admin` / `adminadmin`
**访问地址**: `http://<NAS-IP>:8085`

### 从旧版迁移

与旧版 fpk (如矿神 SPK) 不兼容，**无法直接升级**，需先卸载旧版再安装。

**迁移前请备份**:
- 旧版配置目录 (通常在 `target/qBittorrent_conf/` 或 `var/config/`)
- 种子文件 (BT_backup 目录)
- 下载任务列表

## 预设配置

| 类别 | 配置 |
|------|------|
| 界面 | 中文、自动接受法律声明 |
| 端口 | WebUI `8085`、BT `63219` |
| 路径 | 下载目录 `shares/qBittorrent/Download`、日志 `var/logs` |
| WebUI | 禁用 CSRF/点击劫持/Host 验证 (适配 fnOS 反代) |
| 数据 | 自动下载最新 [DB-IP GeoDB](https://db-ip.com/db/lite.php) |

## 相对旧版 fpk 的修复

| 问题 | 修复 |
|------|------|
| 配置路径错误，升级丢失 | 改用标准 profile 路径 `var/qBittorrent/config/` |
| 日志写入 `/tmp`，重启丢失 | 改为 `var/logs/` 持久化 |
| 缺少用户名，每次生成临时密码 | 预设 `admin`/`adminadmin` |
| WebUI 仅管理员可见 | 改为所有用户可见 |
| 框架日志与应用日志同名混淆 | 框架日志改名为 `service.log` |
| 包含 50+ 无用搜索插件 | 精简移除 |

## 本地构建

```bash
./update_qbittorrent.sh                       # 最新版本，自动检测架构
./update_qbittorrent.sh --arch arm            # 指定架构
./update_qbittorrent.sh --arch arm 5.1.4      # 指定版本
./update_qbittorrent.sh --help                # 查看帮助
```

## 版本标签

- `qbittorrent/v5.1.4` — 首次发布
- `qbittorrent/v5.1.4-r2` — 同版本打包修订

## Credits

- [qBittorrent](https://www.qbittorrent.org/)
- [userdocs/qbittorrent-nox-static](https://github.com/userdocs/qbittorrent-nox-static)
- [DB-IP Lite](https://db-ip.com/db/lite.php)
