# 飞牛 fnOS 应用开发完整指南

> **来源**: https://developer.fnnas.com/docs/  
> **整理日期**: 2026-02-14  
> **用途**: 供本项目开发维护参考（人工 + AI Agent）

---

## 目录

- [一、快速开始](#一快速开始)
- [二、架构概述](#二架构概述)
- [三、Manifest 配置](#三manifest-配置)
- [四、环境变量](#四环境变量)
- [五、应用权限](#五应用权限)
- [六、应用资源](#六应用资源)
- [七、应用入口](#七应用入口)
- [八、用户向导](#八用户向导)
- [九、应用依赖关系](#九应用依赖关系)
- [十、运行时环境](#十运行时环境)
- [十一、中间件服务](#十一中间件服务)
- [十二、Docker 应用构建](#十二docker-应用构建)
- [十三、Native 应用构建](#十三native-应用构建)
- [十四、图标规范](#十四图标规范)
- [十五、CLI 开发工具](#十五cli-开发工具)
- [附录：本项目专用约定](#附录本项目-fnos-apps-专用约定)

---

## 一、快速开始

飞牛应用开放平台面向开发者提供一站式工作台，助力开发和发布飞牛应用。

### 前置条件

- 安装 `fnpack` CLI 工具（官方打包工具）
- 飞牛 fnOS 设备或虚拟机（用于实机测试）
- 基本的 Linux/Bash 知识

### 开发流程概览

1. **创建应用** — 使用 `fnpack create <appname>` 生成应用骨架
2. **配置应用** — 编辑 manifest、cmd 脚本、config 权限/资源、wizard 向导
3. **打包应用** — 使用 `fnpack build` 生成 `.fpk` 文件
4. **测试应用** — 在 fnOS 设备上通过应用中心手动安装 `.fpk` 进行测试
5. **发布应用** — 注册开发者账号，提交应用到飞牛应用中心

---

## 二、架构概述

### 应用目录结构

当应用安装到飞牛 fnOS 系统后，会在系统中创建如下目录结构：

```
/var/apps/[appname]
├── cmd/                              # 应用生命周期管理脚本
│   ├── install_callback
│   ├── install_init
│   ├── main
│   ├── uninstall_callback
│   ├── uninstall_init
│   ├── upgrade_init
│   ├── upgrade_callback
│   ├── config_init
│   └── config_callback
├── config/
│   ├── privilege                     # 应用权限配置
│   └── resource                      # 应用资源配置
├── ICON_256.PNG                      # 大图标 (256x256)
├── ICON.PNG                          # 小图标 (64x64)
├── LICENSE                           # 隐私协议（可选）
├── manifest                          # 应用身份证
├── etc -> /vol[x]/@appconf/[appname]   # 静态配置文件
├── home -> /vol[x]/@apphome/[appname]  # 用户数据文件
├── target -> /vol[x]/@appcenter/[appname] # 可执行文件
├── tmp -> /vol[x]/@apptemp/[appname]   # 临时文件
├── var -> /vol[x]/@appdata/[appname]   # 运行时动态数据
├── shares/                           # 数据共享目录
│   ├── datashare1 -> /vol[x]/@appshare/datashare1
│   └── datashare2 -> /vol[x]/@appshare/datashare2
└── wizard/                           # 用户交互向导
    ├── install
    ├── uninstall
    ├── upgrade
    └── config
```

### 核心文件说明

**应用标识文件：**

| 文件 | 说明 |
|------|------|
| `manifest` | 应用的"身份证"，定义基本信息和运行属性 |
| `config/privilege` | 应用的"权限清单"，声明需要的系统权限 |
| `config/resource` | 应用的"能力声明"，定义可以使用的扩展功能 |

**界面资源：**

| 文件 | 说明 |
|------|------|
| `ICON.PNG` | 应用中心显示的小图标（64x64 像素） |
| `ICON_256.PNG` | 应用详情页显示的大图标（256x256 像素） |
| `LICENSE` | 用户安装前需要同意的隐私协议（可选） |

### 目录功能说明

**开发者定义目录：**

| 目录 | 说明 |
|------|------|
| `cmd/` | 存放应用生命周期管理的脚本文件 |
| `wizard/` | 存放用户交互向导的配置文件 |

**系统自动创建目录：**

| 目录 | 说明 |
|------|------|
| `target` | 应用可执行文件的存放位置 |
| `etc` | 静态配置文件存放位置 |
| `var` | 运行时动态数据存放位置 |
| `tmp` | 临时文件存放位置 |
| `home` | 用户数据文件存放位置 |
| `meta` | 应用元数据存放位置 |
| `shares` | 数据共享目录（根据 resource 配置自动创建） |

### 应用生命周期管理

飞牛 fnOS 系统通过调用 `cmd/` 目录中的脚本来管理应用。

#### 应用安装流程

安装过程分为三个阶段：安装前准备、文件解压、安装后处理。

- **`install_init`** — 安装前执行，可进行环境检查、依赖安装等
- **`install_callback`** — 安装后执行，可进行初始化配置等
- 如果配置了 `wizard/install` 向导，可获取用户的配置输入

#### 应用卸载流程

卸载应用时，系统会：
- **删除**：`target`、`tmp`、`home`、`etc` 目录
- **保留**：`var` 和 `shares` 目录（保护用户数据）

如果希望提供完全删除选项，可在 `wizard/uninstall` 向导中让用户选择是否保留数据，然后在 `cmd/uninstall_callback` 中清理。

> 如果卸载时应用仍在运行，系统会先停止应用，然后再执行卸载流程。

#### 应用更新流程

更新流程与安装流程类似：

- **`upgrade_init`** — 更新前执行，可处理数据库升级、配置迁移等
- **`upgrade_callback`** — 更新后执行
- 如果配置了 `wizard/upgrade` 向导，可获取用户的更新配置

> 如果更新时应用正在运行，系统会先停止应用，执行更新，然后重新启动应用。

#### 应用配置流程

用户可以在 **系统设置 → 应用设置** 中查看和修改应用配置。可配置范围由 `wizard/config` 文件定义。

当用户修改配置并保存后，系统会更新环境变量，然后调用：
- **`config_init`** — 配置变更前
- **`config_callback`** — 配置变更后

### 应用运行状态管理

`cmd/main` 是应用运行状态管理的核心脚本：

```bash
#!/bin/bash
case $1 in
start)
    # 启动应用的命令，成功返回 0，失败返回 1
    exit 0
    ;;
stop)
    # 停止应用的命令，成功返回 0，失败返回 1
    exit 0
    ;;
status)
    # 检查应用运行状态，运行中返回 0，未运行返回 3
    exit 0
    ;;
*)
    exit 1
    ;;
esac
```

#### 应用状态监控

系统会定期调用 `cmd/main status` 来检查应用状态：
- 脚本返回 `exit 0` 表示应用正在运行
- 脚本返回 `exit 3` 表示应用未运行

系统会在以下时机调用状态检查：
- 应用启动前检查一次
- 应用运行期间定期轮询检查

### 应用错误异常展示处理 (V1.1.8+)

通过向 `TRIM_TEMP_LOGFILE` 环境变量（用户可见系统日志文件路径）写入应用错误日志信息并返回错误代码时，系统会自动将错误日志在前端展示为用户可见的 Dialog 对话框。

```bash
#!/bin/bash
case $1 in
start)
    # 检查配置文件是否存在
    if [ ! -f "$TRIM_PKGETC/config.conf" ]; then
        echo "配置文件不存在, 应用启动失败！" > "${TRIM_TEMP_LOGFILE}"
        exit 1
    fi

    # 启动应用
    cd "$TRIM_APPDEST"
    ./myapp --config "$TRIM_PKGETC/config.conf" \
            --data "$TRIM_PKGVAR" \
            --port "$TRIM_SERVICE_PORT" \
            --user "$TRIM_USERNAME" \
            --log "$TRIM_TEMP_LOGFILE" &

    echo "应用启动完成"
    exit 0
    ;;
stop)
    echo "停止应用..."
    pkill -f "myapp.*$TRIM_SERVICE_PORT"
    exit 0
    ;;
status)
    if pgrep -f "myapp.*$TRIM_SERVICE_PORT" > /dev/null; then
        echo "应用正在运行"
        exit 0
    else
        echo "应用未运行"
        exit 3
    fi
    ;;
*)
    exit 1
    ;;
esac
```

**注意事项：**
- 错误信息写入 `TRIM_TEMP_LOGFILE` 文件，不要直接用 `echo` 输出
- 写入后通过 `exit 1` 返回错误码
- 如果不写入 `TRIM_TEMP_LOGFILE` 直接 `exit 1`，系统将展示标准错误信息："执行XX脚本出错且原因未知"
- `TRIM_TEMP_LOGFILE` 在 `cmd/main`、`cmd/install_*`、`cmd/upgrade_*` 中有效；`cmd/config_*` 和 `cmd/uninstall_*` 暂不支持

---

## 三、Manifest 配置

manifest 文件是应用的"身份证"，定义应用基本信息和运行属性。文件名为 `manifest`（无扩展名），放在应用包根目录。

### 应用标识

| 字段 | 必填 | 说明 |
|------|------|------|
| `appname` | 是 | 应用唯一标识符，系统范围内唯一 |
| `version` | 是 | 版本号，格式 `x[.y[.z]][-build]`，如 `1.0.0`、`2.1.3-beta` |
| `display_name` | 是 | 应用中心和应用设置中显示的名称 |
| `desc` | 是 | 应用详细介绍，支持 HTML 格式 |

### 系统要求

| 字段 | 必填 | 说明 |
|------|------|------|
| `arch` | 否 | **已废弃**，原固定为 `x86_64` |
| `platform` | 否 | V1.1.8+ 新增，默认 `x86`。可选值：`x86`、`arm`、`loongarch`（暂未支持）、`risc-v`（暂未支持）、`all`（即将支持，如 Docker 应用）。**不支持多个值** |
| `source` | 是 | 固定为 `thirdparty` |

### 开发者信息

| 字段 | 必填 | 说明 |
|------|------|------|
| `maintainer` | 否 | 应用开发者或开发团队名称 |
| `maintainer_url` | 否 | 开发者网站或联系方式 |
| `distributor` | 否 | 应用发布者 |
| `distributor_url` | 否 | 发布者网站 |

### 安装和运行控制

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `os_min_version` | — | 支持的最低系统版本，如 `0.9.0` |
| `os_max_version` | — | 支持的最高系统版本，如 `0.9.100` |
| `ctl_stop` | `true` | 是否显示启动/停止功能。`false` 时隐藏按钮和运行状态 |
| `install_type` | 空 | 空 = 用户选择存储位置 `/vol${x}/@appcenter/`；`root` = 安装到系统分区 `/usr/local/apps/@appcenter/` |
| `install_dep_apps` | — | 依赖应用列表，格式 `app1>2.2.2:app2:app3`，系统按列表顺序自动安装 |

### 用户界面

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `desktop_uidir` | `ui` | UI 组件目录路径（相对于应用根目录） |
| `desktop_applaunchname` | — | 应用中心启动入口，对应 `{desktop_uidir}/config` 中的 entry ID |

### 端口管理

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `service_port` | — | 应用监听端口号，系统启动前检查占用（仅支持单个端口） |
| `checkport` | `true` | 是否启用端口检查，`false` 时不检查占用 |

### 权限控制

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `disable_authorization_path` | `false` | `true` 时应用设置页面不显示授权目录操作 |

### 应用更新

| 字段 | 说明 |
|------|------|
| `changelog` | 应用更新日志，升级时展示，应用详情页显示为"新功能"介绍 |

### 完整示例

```ini
appname         = myapp
version         = 1.0.0
display_name    = 我的应用
desc            = 这是一个示例应用，展示了 manifest 文件的基本用法
arch            = x86_64
source          = thirdparty
maintainer      = 张三
maintainer_url  = https://example.com
distributor     = 示例公司
distributor_url = https://company.com
os_min_version  = 0.9.0
desktop_uidir   = ui
desktop_applaunchname = myapp.APPLICATION
service_port    = 8080
checkport       = true
install_dep_apps = mariaDB:redis
```

---

## 四、环境变量

环境变量是应用运行时的"工具箱"，系统自动提供。来源有两处：manifest 文件中的字段自动转换，以及用户向导中的选择。

### 应用相关变量

#### 基本信息

| 变量 | 说明 |
|------|------|
| `TRIM_APPNAME` | 应用名称（来自 manifest `appname`） |
| `TRIM_APPVER` | 应用版本号（来自 manifest `version`） |
| `TRIM_OLD_APPVER` | 升级前版本号（仅升级时可用） |

#### 路径信息

| 变量 | 说明 |
|------|------|
| `TRIM_APPDEST` | 应用可执行文件目录路径（`target` 文件夹） |
| `TRIM_PKGETC` | 配置文件目录路径（`etc` 文件夹） |
| `TRIM_PKGVAR` | 动态数据目录路径（`var` 文件夹） |
| `TRIM_PKGTMP` | 临时文件目录路径（`tmp` 文件夹） |
| `TRIM_PKGHOME` | 用户数据目录路径（`home` 文件夹） |
| `TRIM_PKGMETA` | 元数据目录路径（`meta` 文件夹） |
| `TRIM_APPDEST_VOL` | 应用安装的存储空间路径 |

#### 网络和端口

| 变量 | 说明 |
|------|------|
| `TRIM_SERVICE_PORT` | 应用监听端口号（来自 manifest `service_port`） |

#### 用户和权限

| 变量 | 说明 |
|------|------|
| `TRIM_USERNAME` | 应用专用用户名 |
| `TRIM_GROUPNAME` | 应用专用用户组名 |
| `TRIM_UID` | 应用用户 ID |
| `TRIM_GID` | 应用用户组 ID |
| `TRIM_RUN_USERNAME` | 当前执行脚本的用户名（可能是 root 或应用用户） |
| `TRIM_RUN_GROUPNAME` | 当前执行脚本的用户组名 |
| `TRIM_RUN_UID` | 当前执行脚本的用户 ID |
| `TRIM_RUN_GID` | 当前执行脚本的用户组 ID |

#### 数据共享

| 变量 | 说明 |
|------|------|
| `TRIM_DATA_SHARE_PATHS` | 数据共享路径列表，多个路径用冒号分隔 |

#### 临时日志

| 变量 | 说明 |
|------|------|
| `TRIM_TEMP_LOGFILE` | 系统日志文件路径（用户可见），在 `cmd/main`、`cmd/install_*`、`cmd/upgrade_*` 中有效。V1.1.8+ 支持写入错误信息后 exit 1 展示 Dialog |
| `TRIM_TEMP_UPGRADE_FOLDER` | 升级过程的临时目录 |
| `TRIM_PKGINST_TEMP_DIR` | 安装包解压的临时目录 |
| `TRIM_TEMP_TPKFILE` | fpk 包解压目录 |

#### 状态信息

| 变量 | 说明 |
|------|------|
| `TRIM_APP_STATUS` | 当前状态：`INSTALL`、`START`、`UPGRADE`、`UNINSTALL`、`STOP`、`CONFIG` 等 |

#### 授权目录 (V1.1.8+)

| 变量 | 说明 |
|------|------|
| `TRIM_DATA_ACCESSIBLE_PATHS` | 可访问路径列表，多个路径用冒号分隔，仅返回读写/只读目录。变更时通过 `cmd/config_init` 和 `cmd/config_callback` 通知。**系统最低版本 V1.1.8**。应用仍需自行判断子目录和文件的读写权限 |

### 系统相关变量

#### 版本信息

| 变量 | 说明 |
|------|------|
| `TRIM_SYS_VERSION` | 完整系统版本号 |
| `TRIM_SYS_VERSION_MAJOR` | 系统主版本号 |
| `TRIM_SYS_VERSION_MINOR` | 系统次版本号 |
| `TRIM_SYS_VERSION_BUILD` | 系统构建版本号 |

#### 系统特征

| 变量 | 说明 |
|------|------|
| `TRIM_SYS_ARCH` | 系统 CPU 架构（如 x86_64） |
| `TRIM_KERNEL_VERSION` | 系统内核版本号 |
| `TRIM_SYS_MACHINE_ID` | 设备唯一标识符 |
| `TRIM_SYS_LANGUAGE` | 系统语言设置 |

### 向导相关变量

用户在安装向导、配置向导等的选择会变成环境变量。这些变量 **没有** `TRIM_` 前缀，完全由向导配置决定。

例如，向导定义了字段 `db_port`、`admin_password`、`install_path`，则可在脚本中直接使用 `$db_port`、`$admin_password`、`$install_path`。

### 使用示例

```bash
#!/bin/bash
case $1 in
start)
    echo "启动应用: $TRIM_APPNAME 版本: $TRIM_APPVER"
    echo "应用目录: $TRIM_APPDEST"
    echo "配置文件目录: $TRIM_PKGETC"
    echo "数据目录: $TRIM_PKGVAR"
    echo "服务端口: $TRIM_SERVICE_PORT"

    # 检查配置文件是否存在
    if [ ! -f "$TRIM_PKGETC/config.conf" ]; then
        echo "配置文件不存在，创建默认配置..."
        cp "$TRIM_APPDEST/config.conf.example" "$TRIM_PKGETC/config.conf"
    fi

    # 启动应用
    cd "$TRIM_APPDEST"
    ./myapp --config "$TRIM_PKGETC/config.conf" \
            --data "$TRIM_PKGVAR" \
            --port "$TRIM_SERVICE_PORT" \
            --user "$TRIM_USERNAME" \
            --log "$TRIM_TEMP_LOGFILE" &

    echo "应用启动完成"
    exit 0
    ;;
status)
    if pgrep -f "myapp.*$TRIM_SERVICE_PORT" > /dev/null; then
        exit 0
    else
        exit 3
    fi
    ;;
stop)
    pkill -f "myapp.*$TRIM_SERVICE_PORT"
    exit 0
    ;;
*)
    exit 1
    ;;
esac
```

### 注意事项

1. **变量命名**：系统变量以 `TRIM_` 开头，自定义向导变量不要使用此前缀
2. **路径安全**：使用路径变量时，建议先检查目录是否存在
3. **权限区分**：`TRIM_RUN_USERNAME`（执行脚本的用户）和 `TRIM_USERNAME`（应用专用用户）不同
4. **版本兼容**：使用系统版本变量时注意检查版本兼容性

---

## 五、应用权限

权限配置在 `config/privilege` 文件中，决定应用在系统中的权限级别和用户身份。

### 默认权限模式（应用用户运行）

系统为应用创建专用用户和用户组，所有进程以此身份运行。

```json
{
    "defaults": {
        "run-as": "package"
    },
    "username": "myapp_user",
    "groupname": "myapp_group"
}
```

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `run-as` | `package` | 运行身份 |
| `username` | manifest 中的 `appname` | 应用专用用户名 |
| `groupname` | manifest 中的 `appname` | 应用专用用户组名 |

### Root 权限模式

> **重要**：Root 权限模式仅适用于飞牛官方合作的企业开发者。第三方应用默认无法发布需要 root 权限的应用。

```json
{
    "defaults": {
        "run-as": "root"
    },
    "username": "myapp_user",
    "groupname": "myapp_group"
}
```

启用 root 权限后：
- 应用脚本以 root 身份执行
- 应用文件所有者变为 root
- 系统仍会创建应用专用用户和用户组

### 额外用户组

可通过 `extra-groups` 字段将应用用户加入额外的系统组（如硬件转码需要 `video` 和 `render` 组）：

```json
{
    "defaults": {
        "run-as": "package"
    },
    "username": "plex",
    "groupname": "plex",
    "extra-groups": ["video", "render"]
}
```

### 外部文件访问权限

出于安全考虑，应用默认无法访问用户的个人文件。用户需在 **应用设置** 中明确授权：

- **读写权限** — 应用可读取和修改文件
- **只读权限** — 应用只能读取文件
- **禁止访问** — 应用无法访问该路径

也可通过 `config/resource` 的 `data-share` 设置默认共享目录。

### 权限检查示例

```bash
#!/bin/bash
echo "当前运行用户: $TRIM_RUN_USERNAME"
echo "应用专用用户: $TRIM_USERNAME"

if [ "$TRIM_RUN_USERNAME" = "root" ]; then
    echo "应用以 root 权限运行"
else
    echo "应用以应用用户权限运行"
fi
```

---

## 六、应用资源

资源配置在 `config/resource` 文件中，声明应用需要的扩展能力。

### 数据共享 (data-share)

允许应用与用户共享特定数据目录，用户可在文件管理器的"应用文件"中访问。

```json
{
    "data-share": {
        "shares": [
            {
                "name": "documents",
                "permission": {
                    "rw": ["myapp_user"]
                }
            },
            {
                "name": "documents/backups",
                "permission": {
                    "ro": ["myapp_user"]
                }
            }
        ]
    }
}
```

权限类型：
- `rw` — 读写权限
- `ro` — 只读权限

共享目录仅在系统管理员的 **文件管理 → 应用文件** 中可见。

### 系统集成 (usr-local-linker)

应用启动时自动创建软链接到系统目录，停止时自动移除。

```json
{
    "usr-local-linker": {
        "bin": [
            "bin/myapp-cli",
            "bin/myapp-server"
        ],
        "lib": [
            "lib/mylib.so",
            "lib/mylib.a"
        ],
        "etc": [
            "etc/myapp.conf",
            "etc/myapp.d/default.conf"
        ]
    }
}
```

| 类型 | 链接目标 |
|------|----------|
| `bin` | `/usr/local/bin/` |
| `lib` | `/usr/local/lib/` |
| `etc` | `/usr/local/etc/` |

### Docker 项目支持 (docker-project)

支持 Docker Compose 应用的容器编排。

```json
{
    "docker-project": {
        "projects": [
            {
                "name": "myapp-stack",
                "path": "docker"
            }
        ]
    }
}
```

| 字段 | 说明 |
|------|------|
| `name` | Docker Compose 项目名称 |
| `path` | 相对于 `app` 目录的路径，指向 `docker-compose.yaml` 所在文件夹 |

---

## 七、应用入口

应用入口定义在 `{desktop_uidir}/config` 文件中。一个应用可以定义多个入口。

### 入口类型

#### 桌面图标入口

用户点击图标直接访问应用。

```json
{
    ".url": {
        "myapp.main": {
            "title": "我的应用",
            "icon": "images/icon-{0}.png",
            "type": "url",
            "protocol": "http",
            "port": "8080",
            "url": "/",
            "allUsers": true
        },
        "myapp.admin": {
            "title": "管理后台",
            "icon": "images/admin-icon-{0}.png",
            "type": "url",
            "protocol": "http",
            "port": "8080",
            "url": "/admin",
            "allUsers": false
        }
    }
}
```

#### 文件右键入口

用户右键点击文件时使用应用打开。

```json
{
    ".url": {
        "myapp.editor": {
            "title": "文本编辑器",
            "icon": "images/editor-{0}.png",
            "type": "url",
            "protocol": "http",
            "port": "8080",
            "url": "/edit",
            "allUsers": true,
            "fileTypes": ["txt", "md", "json", "xml"],
            "noDisplay": true
        }
    }
}
```

当用户通过右键菜单打开文件时，系统自动在 URL 后添加 `path` 参数：
```
http://localhost:8080/edit?path=/vol1/Users/admin/Documents/example.txt
```

### 基础字段说明

| 字段 | 说明 |
|------|------|
| `title` | 入口显示标题（桌面图标名称或右键菜单名称） |
| `icon` | 图标文件路径（相对于 UI 目录），`{0}` 替换为 64 或 256 |
| `type` | `url` = 浏览器新标签页打开；`iframe` = 桌面窗口 iframe 加载 |
| `protocol` | `http`、`https`，或空字符串 `""` 为自适应协议。**注意：不声明 `protocol` 字段默认为 http，不是自适应** |
| `port` | 应用端口。CGI 方案不需要。支持 `${wizard_port}` 占位符 (V1.1.8+) |
| `url` | 访问路径（应用内相对路径）。支持 `${wizard_url}` 占位符 (V1.1.8+) |
| `allUsers` | `true` = 所有用户可见；`false` = 仅管理员可见 |

### 文件相关字段

| 字段 | 说明 |
|------|------|
| `fileTypes` | 关联文件类型数组，如 `["txt", "md", "json"]` |
| `noDisplay` | `true` = 不在桌面显示，仅在右键菜单；`false` = 同时显示 |

### 控制字段

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `accessPerm` | `readonly` | 桌面访问权限：`editable`、`readonly`、`hidden` |
| `portPerm` | `readonly` | **已废弃** (V1.1.8+) |
| `pathPerm` | `readonly` | **已废弃** (V1.1.8+) |

控制字段通过 `control` 对象设置：

```json
{
    ".url": {
        "myapp.advanced": {
            "title": "高级功能",
            "icon": "images/advanced-{0}.png",
            "type": "iframe",
            "protocol": "http",
            "port": "8080",
            "url": "/advanced",
            "allUsers": false,
            "control": {
                "accessPerm": "readonly"
            }
        }
    }
}
```

---

## 八、用户向导

向导帮助用户完成安装、配置和卸载。配置文件放在 `wizard/` 目录下。

### 向导类型

| 文件 | 用途 |
|------|------|
| `wizard/install` | 安装时的配置界面 |
| `wizard/uninstall` | 卸载时的确认界面 |
| `wizard/upgrade` | 更新时的配置界面 |
| `wizard/config` | 应用设置时的配置界面 |

### 文件结构

每个向导文件是一个 JSON 数组，包含多个步骤页面：

```json
[
    {
        "stepTitle": "第一步标题",
        "items": [
            // 表单项列表
        ]
    },
    {
        "stepTitle": "第二步标题",
        "items": [
            // 表单项列表
        ]
    }
]
```

### 表单项类型

#### 文本输入框 (text)

```json
{
    "type": "text",
    "field": "wizard_username",
    "label": "用户名",
    "initValue": "admin",
    "rules": [
        { "required": true, "message": "请输入用户名" },
        { "min": 3, "max": 20, "message": "用户名长度应在3-20个字符之间" }
    ]
}
```

#### 密码输入框 (password)

```json
{
    "type": "password",
    "field": "wizard_password",
    "label": "管理员密码",
    "rules": [
        { "required": true, "message": "请输入密码" },
        { "min": 6, "message": "密码长度不能少于6位" }
    ]
}
```

#### 单选按钮 (radio)

```json
{
    "type": "radio",
    "field": "wizard_install_type",
    "label": "安装类型",
    "initValue": "standard",
    "options": [
        { "label": "标准安装", "value": "standard" },
        { "label": "自定义安装", "value": "custom" }
    ],
    "rules": [
        { "required": true, "message": "请选择安装类型" }
    ]
}
```

#### 多选框 (checkbox)

```json
{
    "type": "checkbox",
    "field": "wizard_modules",
    "label": "安装模块",
    "initValue": ["web", "api"],
    "options": [
        { "label": "Web界面", "value": "web" },
        { "label": "API接口", "value": "api" },
        { "label": "数据库", "value": "database" }
    ],
    "rules": [
        { "required": true, "message": "请至少选择一个模块" }
    ]
}
```

#### 下拉选择框 (select)

```json
{
    "type": "select",
    "field": "wizard_database_type",
    "label": "数据库类型",
    "initValue": "sqlite",
    "options": [
        { "label": "SQLite (推荐)", "value": "sqlite" },
        { "label": "MySQL", "value": "mysql" },
        { "label": "PostgreSQL", "value": "postgresql" }
    ],
    "rules": [
        { "required": true, "message": "请选择数据库类型" }
    ]
}
```

#### 开关 (switch)

```json
{
    "type": "switch",
    "field": "wizard_enable_backup",
    "label": "启用自动备份",
    "initValue": "true"
}
```

#### 提示文本 (tips)

```json
{
    "type": "tips",
    "helpText": "请阅读 <a target=\"_blank\" href=\"https://example.com/privacy\">隐私政策</a>"
}
```

### 验证规则

| 规则 | 示例 | 说明 |
|------|------|------|
| 必填 | `{ "required": true, "message": "..." }` | 字段不能为空 |
| 长度限制 | `{ "min": 3, "max": 50, "message": "..." }` | 字符长度范围 |
| 精确长度 | `{ "len": 6, "message": "..." }` | 固定长度 |
| 正则表达式 | `{ "pattern": "^[a-zA-Z0-9_]+$", "message": "..." }` | 正则匹配 |

### 安装向导完整示例

```json
[
    {
        "stepTitle": "欢迎安装",
        "items": [
            {
                "type": "tips",
                "helpText": "欢迎使用我们的应用！"
            },
            {
                "type": "switch",
                "field": "wizard_agree_terms",
                "label": "我已阅读并同意服务条款",
                "rules": [
                    { "required": true, "message": "请同意服务条款" }
                ]
            }
        ]
    },
    {
        "stepTitle": "创建管理员账号",
        "items": [
            {
                "type": "text",
                "field": "wizard_admin_username",
                "label": "管理员用户名",
                "initValue": "admin",
                "rules": [
                    { "required": true, "message": "请输入管理员用户名" },
                    { "pattern": "^[a-zA-Z0-9_]+$", "message": "只能包含字母、数字和下划线" }
                ]
            },
            {
                "type": "password",
                "field": "wizard_admin_password",
                "label": "管理员密码",
                "rules": [
                    { "required": true, "message": "请输入管理员密码" },
                    { "min": 8, "message": "密码长度不能少于8位" }
                ]
            }
        ]
    }
]
```

### 卸载向导示例

```json
[
    {
        "stepTitle": "确认卸载",
        "items": [
            {
                "type": "tips",
                "helpText": "您即将卸载此应用。请选择如何处理应用数据："
            },
            {
                "type": "radio",
                "field": "wizard_data_action",
                "label": "数据保留选项",
                "initValue": "keep",
                "options": [
                    { "label": "保留数据（推荐）- 将来重新安装时可恢复", "value": "keep" },
                    { "label": "删除所有数据 - 此操作不可恢复！", "value": "delete" }
                ],
                "rules": [
                    { "required": true, "message": "请选择数据保留选项" }
                ]
            }
        ]
    }
]
```

### 获取用户输入

向导中字段名直接作为环境变量名使用：

```bash
#!/bin/bash
ADMIN_USERNAME="$wizard_admin_username"
ADMIN_PASSWORD="$wizard_admin_password"
DATABASE_TYPE="$wizard_database_type"

if [ "$DATABASE_TYPE" = "mysql" ]; then
    echo "配置MySQL数据库..."
else
    echo "使用SQLite数据库..."
fi
```

---

## 九、应用依赖关系

### 声明依赖

在 `manifest` 的 `install_dep_apps` 字段声明依赖：

```ini
install_dep_apps = dep2:dep1
```

### 依赖检查逻辑

应用中心在安装、启用、停用、卸载、更新等流程中自动检查：

- **安装和启用**：检查依赖应用是否已安装和已启用，未安装则自动安装，未启用则自动启用
- **停用和卸载**：检查是否有其他应用依赖当前应用，有则提示自动停用
- **更新**：检查是否有其他应用依赖当前应用，有则提示更新期间自动停用

### 依赖顺序

执行自动安装和启用的顺序是 **从后往前**（从右到左）：

```ini
# 安装时先安装 dep1，后安装 dep2
install_dep_apps = dep2:dep1
```

### 版本要求

使用 `>` 指定最低版本：

```ini
install_dep_apps = mylib>2.2.2:redis
```

### 嵌套依赖

应用中心仅对 **一层依赖** 进行检查，不做递归检查。如果应用A依赖应用B，应用B又依赖应用C，则需要在应用A中同时声明：

```ini
# 嵌套依赖必须平铺声明
install_dep_apps = depB:depC
```

---

## 十、运行时环境

fnOS 提供系统级运行时环境，应用通过 `install_dep_apps` 声明依赖即可使用。

### Python 环境

**可用版本**：`python312`、`python311`、`python310`、`python39`、`python38`

```ini
# manifest
install_dep_apps = python312
```

在 cmd 脚本中配置环境：

```bash
# 将 Python 加入 PATH
export PATH=/var/apps/python312/target/bin:$PATH

# 创建虚拟环境（推荐，隔离依赖）
python3 -m venv .venv
source .venv/bin/activate

# 安装依赖
pip install -r requirements.txt
```

### Node.js 环境

**可用版本**：`nodejs_v22`、`nodejs_v20`、`nodejs_v18`、`nodejs_v16`、`nodejs_v14`

```ini
# manifest
install_dep_apps = nodejs_v22
```

```bash
export PATH=/var/apps/nodejs_v22/target/bin:$PATH
node -v
npm -v
```

### Java 环境

**可用版本**：`java-21-openjdk`、`java-17-openjdk`、`java-11-openjdk`

```ini
# manifest
install_dep_apps = java-21-openjdk
```

```bash
export PATH=/var/apps/java-21-openjdk/target/bin:$PATH
java --version
```

### 运行时路径约定

所有运行时安装到 `/var/apps/{runtime-name}/target/bin/`：

| 运行时 | 路径 |
|--------|------|
| Python 3.12 | `/var/apps/python312/target/bin` |
| Node.js 22 | `/var/apps/nodejs_v22/target/bin` |
| Java 17 | `/var/apps/java-17-openjdk/target/bin` |

---

## 十一、中间件服务

fnOS 提供中间件服务，通过 `install_dep_apps` 声明即可自动管理。

### Redis

```ini
install_dep_apps = redis
```

默认连接：`127.0.0.1:6379`

```python
import redis

pool = redis.ConnectionPool(
    host='127.0.0.1', port=6379, db=1,
    decode_responses=True, max_connections=10
)
client = redis.Redis(connection_pool=pool)
client.lpush('my_list', 'item1', 'item2')
items = client.lrange('my_list', 0, -1)
print(items)  # ['item2', 'item1']
```

### MinIO

```ini
install_dep_apps = minio
```

默认连接：`127.0.0.1:9000`

```python
from minio import Minio

client = Minio(
    endpoint="127.0.0.1:9000",
    access_key="your_access_key",
    secret_key="your_secret_key",
    secure=False
)

bucket_name = "my-bucket"
if not client.bucket_exists(bucket_name):
    client.make_bucket(bucket_name)
```

### RabbitMQ

```ini
install_dep_apps = rabbitmq
```

默认连接：`127.0.0.1:5672`，用户 `guest/guest`

```python
import pika

credentials = pika.PlainCredentials("guest", "guest")
connection = pika.BlockingConnection(
    pika.ConnectionParameters(
        host="127.0.0.1", port=5672,
        virtual_host="/", credentials=credentials
    )
)
channel = connection.channel()
channel.queue_declare(queue="my_queue", durable=False, auto_delete=True)
channel.basic_publish(exchange="", routing_key="my_queue", body="Hello")
```

### MariaDB

> 即将上线...

---

## 十二、Docker 应用构建

### 创建应用

```bash
fnpack create my-app -t docker
```

生成的目录结构：

```
my-app/
├── app/
│   ├── docker/
│   │   └── docker-compose.yaml
│   ├── ui/
│   │   ├── images/
│   │   └── config
├── manifest
├── cmd/
│   ├── main
│   ├── install_init
│   ├── install_callback
│   ├── uninstall_init
│   ├── uninstall_callback
│   ├── upgrade_init
│   ├── upgrade_callback
│   ├── config_init
│   └── config_callback
├── config/
│   ├── privilege
│   └── resource
├── wizard/
├── LICENSE
├── ICON.PNG
└── ICON_256.PNG
```

### 构建步骤

1. **编辑 manifest** — 定义 appname、version、display_name、desc 等
2. **编辑 docker-compose.yaml** — 支持使用 TRIM_* 环境变量
3. **编辑 cmd/main** — 定义状态检查逻辑
4. **定义用户入口** — 编辑 ui/config
5. **打包** — `fnpack build`

### Docker 应用的 cmd/main 模板

```bash
#!/bin/bash

FILE_PATH="${TRIM_APPDEST}/docker/docker-compose.yaml"

is_docker_running () {
    DOCKER_NAME=""
    if [ -f "$FILE_PATH" ]; then
        DOCKER_NAME=$(cat $FILE_PATH | grep "container_name" | awk -F ':' '{print $2}' | xargs)
    fi
    if [ -n "$DOCKER_NAME" ]; then
        docker inspect $DOCKER_NAME | grep -q "\"Status\": \"running\"," || exit 1
        return
    fi
}

case $1 in
start)
    # Docker 应用由应用中心通过 compose 管理启动
    exit 0
    ;;
stop)
    # Docker 应用由应用中心通过 compose 管理停止
    exit 0
    ;;
status)
    # 默认检查第一个容器的状态
    if is_docker_running; then
        exit 0
    else
        exit 3
    fi
    ;;
*)
    exit 1
    ;;
esac
```

> Docker 应用的启停由应用中心执行 compose 管理，无需在 cmd/main 中定义启停逻辑。

---

## 十三、Native 应用构建

### 示例：Notepad 应用

技术栈：后端 Node.js + Express，前端 React + Vite。

#### 代码结构

```
notepad/
├── backend/
│   ├── server.js
│   └── package.json
├── frontend/
│   ├── src/main.jsx
│   ├── index.html
│   ├── package.json
│   └── vite.config.mjs
├── scripts/
│   └── build-combined.js
├── package.json
└── README.md
```

#### 本地开发

```bash
npm install --workspaces
npm run start
# 访问 http://localhost:5001
```

#### 构建编译产物

```bash
npm run build
# 产物在 dist/ 目录
```

#### 创建 fnOS 应用打包目录

```bash
cd notepad/
fnpack create fnnas.notepad
```

#### 编辑 manifest

```ini
appname         = fnnas.notepad
version         = 0.0.1
desc            = A simple notepad
arch            = x86_64
display_name    = Notepad
maintainer      = someone
distributor     = someone
desktop_uidir   = ui
desktop_applaunchname = fnnas.notepad.Application
source          = thirdparty
```

#### 编辑权限配置

```json
{
    "defaults": {
        "run-as": "package"
    },
    "username": "fnnas.notepad",
    "groupname": "fnnas.notepad"
}
```

#### 编辑资源配置

```json
{
    "data-share": {
        "shares": [
            {
                "name": "fnnas.notepad",
                "permission": {
                    "rw": ["fnnas.notepad"]
                }
            }
        ]
    }
}
```

#### 编辑启停脚本 (cmd/main)

```bash
#!/bin/bash

LOG_FILE="${TRIM_PKGVAR}/info.log"
PID_FILE="${TRIM_PKGVAR}/app.pid"

export PATH=/var/apps/nodejs_v22/target/bin:$PATH

# 数据目录
DATA_DIR="${TRIM_DATA_SHARE_PATHS%%:*}"

CMD="DATA_DIR=${DATA_DIR} PORT=5001 node ${TRIM_APPDEST}/server/server.js"

log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> ${LOG_FILE}
}

start_process() {
    if status; then
        return 0
    fi
    log_msg "Starting process ..."
    bash -c "${CMD}" >> ${LOG_FILE} 2>&1 &
    printf "%s" "$!" > ${PID_FILE}
    return 0
}

stop_process() {
    log_msg "Stopping process ..."
    if [ -r "${PID_FILE}" ]; then
        pid=$(head -n 1 "${PID_FILE}" | tr -d '[:space:]')
        if ! check_process "${pid}"; then
            rm -f "${PID_FILE}"
            return
        fi
        kill -TERM ${pid} >> ${LOG_FILE} 2>&1
        local count=0
        while check_process "${pid}" && [ $count -lt 10 ]; do
            sleep 1
            count=$((count + 1))
        done
        if check_process "${pid}"; then
            kill -KILL "${pid}"
            sleep 1
            rm -f "${PID_FILE}"
        fi
    fi
    return 0
}

check_process() {
    local pid=$1
    if kill -0 "${pid}" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

status() {
    if [ -f "${PID_FILE}" ]; then
        pid=$(head -n 1 "${PID_FILE}" | tr -d '[:space:]')
        if check_process "${pid}"; then
            return 0
        else
            rm -f "${PID_FILE}"
        fi
    fi
    return 1
}

case $1 in
start)
    start_process
    ;;
stop)
    stop_process
    ;;
status)
    if status; then
        exit 0
    else
        exit 3
    fi
    ;;
*)
    exit 1
    ;;
esac
```

#### 编辑桌面入口 (ui/config)

```json
{
    ".url": {
        "fnnas.notepad.Application": {
            "title": "Notepad",
            "icon": "images/icon_{0}.png",
            "type": "url",
            "protocol": "http",
            "port": "5001"
        }
    }
}
```

#### 打包

```bash
cd fnnas.notepad
fnpack build
```

生成 `fnnas.notepad.fpk` 文件，可在 fnOS 上测试。

#### CI 集成

在构建脚本末尾添加 fnpack 打包逻辑：

```javascript
const packDir = path.join(root, 'fnnas.notepad')
const packServerDir = path.join(packDir, 'app', 'server');
run(`rm -rf ${packServerDir}`)
run(`mkdir ${packServerDir}`)
run(`cp -r ${outDir}/* ${packServerDir}/`)
run(`fnpack build -d ${packDir}`)
```

---

## 十四、图标规范

### 标准设计规范

| 规格 | 要求 |
|------|------|
| 尺寸 | 256x256 像素、64x64 像素 |
| 格式 | PNG、JPG |
| 颜色空间 | sRGB |
| 文件大小 | ≤ 1024 KB |
| 形状 | 完整正方形直角图标 |

### 文件命名

| 文件 | 用途 |
|------|------|
| `ICON.PNG` | 应用包小图标 (64x64) |
| `ICON_256.PNG` | 应用包大图标 (256x256) |
| `ui/images/icon-64.png` | 桌面入口小图标 |
| `ui/images/icon-256.png` | 桌面入口大图标 |

> 含圆角矩形背景图层图标 PSD 源文件可从官方下载：  
> https://static.fnnas.com/appcenter-marketing/fnpack_ICON_256.zip

---

## 十五、CLI 开发工具

### fnpack

官方应用打包工具，主要命令：

| 命令 | 说明 |
|------|------|
| `fnpack create <appname>` | 创建新应用骨架（Native 类型） |
| `fnpack create <appname> -t docker` | 创建 Docker 应用骨架 |
| `fnpack build` | 在当前目录打包生成 `.fpk` 文件 |
| `fnpack build -d <dir>` | 指定目录打包 |

### appcenter-cli

应用中心管理工具，用于应用的发布和管理。

> 详细文档待补充（CLI 页面为 SPA 渲染，无法静态获取）。

---

## 附录：本项目 (fnos-apps) 专用约定

本项目是一个 monorepo，将 8 个第三方应用打包为 `.fpk` 安装包。以下是项目特有的约定和规范。

### 基本原则

1. **语言**：100% bash，无包管理器，无编译语言
2. **透明性**：仅下载并重打包官方发布内容，**绝不修改上游业务逻辑**
3. **安全性**：所有应用均按非 root 用户运行

### Manifest 格式

固定宽度对齐，值在第 16 列：

```ini
appname         = myapp
version         = 1.0.0
display_name    = My App
```

### fpk 包结构

fpk 本质上是 tar.gz 文件，包含：

```
├── app.tgz              # 应用可执行文件压缩包
├── cmd/                  # 生命周期脚本
├── config/               # 权限和资源配置
├── wizard/               # 用户向导
├── manifest              # 应用元数据（含 app.tgz 的 md5 校验和）
├── ICON.PNG              # 小图标
├── ICON_256.PNG          # 大图标
└── ui/                   # 桌面入口配置和图标
```

### 覆盖模式 (Overlay Pattern)

构建 fpk 时：
1. 先复制 `shared/cmd/*`（共享框架）
2. 再复制 `apps/*/fnos/cmd/*`（应用特定）覆盖

**应用特定文件优先**。只覆盖需要不同的文件，不要重复共享逻辑。

### 架构支持

- 所有应用双架构构建：x86 + arm
- 使用 `uname -m` 检测架构，**绝不硬编码**
- manifest 使用 `platform` 字段（`x86` 或 `arm`）

### 版本标签

命名空间化标签：

```
plex/v1.42.2.10156
qbittorrent/v5.1.4-r2
emby/v4.9.0.50
```

同版本重新发布使用 `-r2`、`-r3` 递增后缀。

### 构建命令

```bash
# 脚手架新应用
./scripts/new-app.sh <name> <display> <port>

# 本地构建（各应用独立）
cd apps/plex && ./update_plex.sh              # 自动检测架构
cd apps/plex && ./update_plex.sh --arch arm   # 强制 ARM

# 通用 fpk 打包器（CI 使用）
./scripts/build-fpk.sh apps/plex app.tgz [version] [platform]
```

### 消息语言

- **用户可见消息**（info/warn/error）：中文
- **代码注释**：英文
- **颜色输出**：`info()` 绿色、`warn()` 黄色、`error()` 红色+退出

### 禁止事项

| 规则 | 说明 |
|------|------|
| 不修改上游二进制 | 仅下载重打包 |
| 不硬编码架构 | 使用 `uname -m` 检测 |
| 不重复共享逻辑 | 应用 cmd/ 中只覆盖差异部分 |
| 不跳过校验和 | app.tgz 的 md5 必须写入 manifest |
| 不在 scripts/ci/ 创建应用构建脚本 | 使用 `scripts/apps/<app>/build.sh` |

### fnOS 运行时路径

```
/var/apps/{appname}/           # 应用根目录
/var/apps/{appname}/target/    # 可执行文件 (TRIM_APPDEST)
/var/apps/{appname}/var/       # 运行时数据 (TRIM_PKGVAR)
/var/apps/{appname}/etc/       # 配置文件 (TRIM_PKGETC)
/var/apps/{appname}/home/      # 用户数据 (TRIM_PKGHOME)
```
