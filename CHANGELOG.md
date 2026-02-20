# Changelog

All notable changes to this project are documented in this file.

## [2026-02-20]

### Added

- **8 new apps** — Gotify, DDNS-GO, WolGoWeb, KodBox, AdGuardHome, Transmission, Firefox, Chromium.
  - Native apps: Gotify (port 8070), DDNS-GO (port 9876), WolGoWeb (port 9090).
  - Docker apps: KodBox (port 8500), AdGuardHome (port 3080 + DNS 53), Transmission (port 9091 + 51413), Firefox (port 5801), Chromium (port 5802).
  - Firefox / Chromium 默认启用中文字体支持 (`ENABLE_CJK_FONT=1`, `LANG=zh_CN.UTF-8`).
- Docker 镜像代理：所有容器应用添加 docker mirror proxy 支持。
- CI: `apps.json` 新增 `download_count` 字段，统计各应用 Release 下载次数。
- CI: `apps.json` 新增 `app_type` 字段，自动识别 Docker / Native 应用类型。
- 新增文档 `docs/release-new-app.md`：完整的新应用发布流程指南。

### Fixed

- **Navidrome** (closes #14):
  - 首次启动自动生成 `navidrome.toml` 配置文件，包含默认音乐文件夹路径。
  - 移除硬编码的 `--musicfolder` 参数，用户可通过 navidrome.toml 自定义 `MusicFolder`。
  - 将系统 ffmpeg (`/usr/bin/ffmpeg`) 加入 PATH，转码功能可正常使用。
- Docker 应用镜像 tag 格式：AdGuardHome / Firefox / Chromium 使用 `v` 前缀 tag（如 `v0.107.72`）。

### Changed

- README 更新：应用数量 18 → 26，新增「浏览器」分类。

## [2026-02-14]

### Added

- **9 new apps** — Navidrome, Kavita, tinyMediaManager, Syncthing, OpenList, MoviePilot, Sun-Panel, Certimate, Vaultwarden.
  - 应用总数从 9 增至 18。
  - 涵盖音乐流媒体、漫画阅读、影视元数据、文件同步、SSL 证书管理、密码管理等场景。
- **fnOS Apps Store** 集成：将应用中心打包纳入 fnos-apps 构建体系。
- **apps.json** 自动生成：CI 在每次 Release 后自动更新应用注册表，供 fnOS Apps Store 发现应用。
- **安装向导**：为 5 个 Docker 应用添加安装向导和目录配置。
- **fnOS 开发指南** (`docs/fnos-developer-guide.md`)：1680 行完整开发文档。

### Changed

- 5 个应用从原生二进制转为 Docker 容器打包：ANI-RSS、Audiobookshelf、Kavita、MoviePilot、tinyMediaManager。
- ANI-RSS 改用 fnOS 系统自带的 Java 17 运行时，不再捆绑 JRE。
- Vaultwarden 转为 Docker 容器打包。
- tinyMediaManager 版本号正则修复。

### Fixed

- 进程终止机制：所有应用在停用/卸载时通过 `pkill` + `pkill -9` 兜底确保进程完全清理。
- Docker 应用构建：`app.tgz` 中包含 `ui/` 目录，修复桌面图标缺失问题。
- CI: 构建 workflow 添加 `actions:write` 权限，修复 `apps.json` 更新触发失败。

## [2026-02-10]

### Added

- Added new apps: Jellyfin, Gopeed, ANI-RSS.
- Added dedicated workflows: `build-jellyfin.yml`, `build-gopeed.yml`, `build-ani-rss.yml`.

### Changed

- Unified display names: `Plex`, `Emby`, `Jellyfin`, `Gopeed`, `ANI-RSS`.
- Updated reusable CI app allowlist to include the three new apps.
- Refined `README.md` with a cleaner structure and modernized copy.
- Added GitHub issue templates for app requests and bug reports.

### Fixed

- Jellyfin startup compatibility:
  - Switched to `network.xml` for HTTP port configuration (`8097`).
  - Bundled `jellyfin-ffmpeg` and set runtime `LD_LIBRARY_PATH`.
- Gopeed packaging/runtime:
  - Switched from desktop `.deb` package to headless `gopeed-web` binary package.
  - Included `bin/gopeed-server` in package payload.
  - Corrected startup flags to `-A/-P/-d`.
