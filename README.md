# OpenClaw Launcher

## 中文说明

OpenClaw Launcher 是一个面向 Windows 的 Electron 启动器，适合同时使用 OpenClaw 和 ClawX，并希望统一管理启动流程、共享数据、日志和模型配置的人。

它适合这样的使用场景：

- OpenClaw 源码仓库放在一个目录
- ClawX 桌面客户端安装在另一个目录
- 两者共用同一套 `state`、`logs`、`workspace`

### 主要功能

- 启动 OpenClaw 并打开本地网页控制台
- 停止当前 OpenClaw 实例
- 提供前台调试启动
- 在启动器里配置模型 API
- 自动发现 OpenClaw 仓库路径和 ClawX 可执行文件
- 管理共享数据根目录，并迁移 `state`、`logs`、`workspace`

### Release 形态

发布时建议提供两种 Windows 资产：

- 安装版
  适合普通用户，走标准 Setup 安装流程
- 便携版
  单文件 exe，适合本地测试或手动分发

这两种形态都读取同一份用户级 launcher 配置，因此可以共用同一套共享数据目录。

### 共享数据模型

启动器会把程序文件和运行数据分开。

默认情况下，共享数据根目录会跟着安装所在盘走：

- 安装在 `E:` 盘时，默认共享根目录是 `E:\OpenClaw Shared Data`
- 安装在 `F:` 盘时，默认共享根目录是 `F:\OpenClaw Shared Data`

共享根目录里主要包含：

- `state`
- `logs`
- `workspace`

启动器还会维护这个 Windows junction：

- `C:\Users\Administrator\.openclaw`

它会始终指向当前生效的共享 `state` 目录。只要 OpenClaw 和 ClawX 都依赖同一个 `.openclaw` 入口，它们就能共用同一套底层状态。

Launcher 自己的用户级配置文件在：

- `%USERPROFILE%\.openclaw-launcher\config\launcher-settings.json`

因此安装版和便携版可以共享同一份路径配置。

### 自动发现

启动器可以自动发现：

- OpenClaw 仓库目录
- ClawX 可执行文件路径
- 当前共享数据根目录

共享根目录的发现顺序是：

1. 读取已保存的 `dataRoot`
2. 检查 `C:\Users\Administrator\.openclaw`
3. 如果它指向 `...\state`，则反推出共享根目录
4. 否则回退到安装盘默认共享目录

### 哪些文件适合上传 GitHub

建议提交：

- `launcher-src/`
- `docs/`
- `scripts/`
- `README.md`
- `.gitignore`
- `test-launcher.bat`

建议不要提交：

- `launcher-src/dist/`
- `launcher-src/node_modules/`
- `state/`
- `logs/`
- `workspace/`
- `%USERPROFILE%\.openclaw-launcher` 下的个人配置

### 构建产物

构建输出目录：

- `launcher-src/dist/`

常用命令：

- `npm run dist:portable`
- `npm run dist:installer`
- `npm run dist:win`

通常不建议把生成的 exe 直接提交进 Git，因为它们属于可重建产物。

### 相关文档

- `docs/coordination.md`

## English

OpenClaw Launcher is a Windows Electron launcher for people who use OpenClaw and ClawX together and want one place to manage startup, shared data, logs, and model configuration.

It is designed for a setup where:

- the OpenClaw source repo lives in one folder
- the ClawX desktop app lives somewhere else
- both should reuse one shared data root for `state`, `logs`, and `workspace`

### Main features

- start OpenClaw and open the local web console
- stop the current OpenClaw instance
- offer a foreground debug start
- edit model API settings inside the launcher
- auto-discover the OpenClaw repo path and the ClawX executable path
- manage the shared data root and migrate `state`, `logs`, and `workspace`

### Release formats

Two Windows release assets are recommended:

- installer build
  for standard end-user setup
- portable build
  for local testing or manual distribution

Both builds read the same user-level launcher settings, so they can reuse the same OpenClaw shared data root.

### Shared data model

The launcher separates program files from runtime data.

By default, the shared data root follows the drive where the launcher is installed:

- installed on `E:` -> `E:\OpenClaw Shared Data`
- installed on `F:` -> `F:\OpenClaw Shared Data`

Inside that shared root, the launcher manages:

- `state`
- `logs`
- `workspace`

It also keeps this Windows junction aligned with the active shared state folder:

- `C:\Users\Administrator\.openclaw`

As long as OpenClaw and ClawX both resolve through that same `.openclaw` entry, they can share the same underlying state.

The launcher's own user-level settings file lives at:

- `%USERPROFILE%\.openclaw-launcher\config\launcher-settings.json`

That allows installed and portable builds to share the same saved path settings.

### Auto-discovery

The launcher can auto-discover:

- the OpenClaw repo directory
- the ClawX executable path
- the current shared data root

Shared root discovery works in this order:

1. read the saved `dataRoot`
2. inspect `C:\Users\Administrator\.openclaw`
3. if it points to `...\state`, infer the shared root from it
4. otherwise fall back to the default shared root for the install drive

### What should go to GitHub

Recommended to commit:

- `launcher-src/`
- `docs/`
- `scripts/`
- `README.md`
- `.gitignore`
- `test-launcher.bat`

Recommended to keep out of Git:

- `launcher-src/dist/`
- `launcher-src/node_modules/`
- `state/`
- `logs/`
- `workspace/`
- personal settings under `%USERPROFILE%\.openclaw-launcher`

### Build output

Generated artifacts live under:

- `launcher-src/dist/`

Useful commands:

- `npm run dist:portable`
- `npm run dist:installer`
- `npm run dist:win`

The generated executables should usually stay out of Git because they are rebuildable artifacts.

### Related documentation

- `docs/coordination.md`
