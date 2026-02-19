# tinyMediaManager for fnOS

影视文件元数据管理工具，支持刮削、重命名和整理电影及电视剧。

## 功能特点

- 从 TheMovieDB.org、IMDb.com 等获取电影和电视剧元数据
- 为 Kodi、Emby、Jellyfin、Plex 创建 NFO 文件
- 自动重命名和整理文件
- 支持 CLI 模式和 HTTP API

## 运行模式

tinyMediaManager 是 JavaFX GUI 应用，在 fnOS 上通过 Xvfb 虚拟显示运行。

### 前提条件

系统需安装 Xvfb：

```bash
apt-get install -y xvfb
```

### CLI 命令示例

```bash
# 扫描并刮削新电影
tinyMediaManager movie -u -n -r

# 扫描并刮削新电视剧
tinyMediaManager tvshow -u -n -r
```

### HTTP API

启用后可通过 REST API 远程控制，详见 https://www.tinymediamanager.org/docs/http-api

## Local Build

```bash
cd apps/tinymediamanager && bash ../../scripts/build-fpk.sh . app.tgz
```
