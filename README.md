# OpenClaw Launcher

Windows Electron launcher for running local OpenClaw with a safer data layout when ClawX is also installed.

## 中文说明

OpenClaw Launcher 是一个面向 Windows 的 Electron 启动器，用来启动本地 OpenClaw，并尽量减少它对 ClawX 主环境的干扰。

这版 launcher 重点解决了两个实际问题：

- 控制台网页打开时会自动带上 gateway token，不会再落到“缺少网关令牌”页面
- launcher 不再强依赖 `C:\Users\Administrator\.openclaw` 这类全局入口，而是在自己的数据根目录下维护独立的 `launcher-profile`

### 当前推荐的数据布局

推荐把运行时数据放到单独的数据根目录，而不是混在安装目录里。

例如：

- `F:\ClawXData`
  ClawX 主环境，优先保留原有工作空间、memory、agent 状态
- `F:\OpenClawData`
  OpenClaw Launcher 侧环境，出现冲突时优先牺牲这一侧

launcher 会在 `dataRoot` 下维护这些目录：

- `state`
- `logs`
- `workspace`
- `launcher-profile`

其中：

- `state` 是 OpenClaw 运行状态目录
- `workspace` 可以放 agent 工作区和你自己扩展出来的内容
- `launcher-profile\.openclaw` 会被自动创建为指向 `state` 的 junction

这样 launcher 调起 OpenClaw CLI 时，会优先使用自己的 profile，不再默认和 ClawX 共用同一套用户主目录。

### 主要能力

- 启动 OpenClaw 并打开本地控制台
- 自动为控制台 URL 拼接 `#token=...`
- 打开命令行窗口并注入 launcher 专属环境变量
- 自动发现 OpenClaw 仓库路径与 ClawX 可执行文件路径
- 管理并迁移 `state`、`logs`、`workspace`

### 关键配置

用户级 launcher 配置：

- `%USERPROFILE%\.openclaw-launcher\config\launcher-settings.json`

常见字段：

- `dataRoot`
- `openclawRepoPath`
- `clawxExePath`

### 适合提交到 GitHub 的内容

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
- 用户自己的本地配置和运行数据

### 构建

在 `launcher-src` 下执行：

- `npm run dist:portable`
- `npm run dist:installer`
- `npm run dist:win`

构建产物输出到：

- `launcher-src/dist/`

## English

OpenClaw Launcher is a Windows Electron launcher for local OpenClaw setups that need a cleaner separation from ClawX.

This version focuses on two practical fixes:

- the dashboard URL now opens with the gateway token attached
- the launcher now keeps its own `launcher-profile` under the configured `dataRoot` instead of depending on a shared global `.openclaw` entry

### Recommended data layout

Use separate runtime roots instead of mixing app files and runtime state.

Example:

- `F:\ClawXData`
  primary ClawX environment
- `F:\OpenClawData`
  launcher-side environment that can be treated as disposable if conflicts happen

The launcher manages these directories under `dataRoot`:

- `state`
- `logs`
- `workspace`
- `launcher-profile`

`launcher-profile\.openclaw` is maintained as a junction to `state`, so launcher-driven OpenClaw commands resolve through a launcher-owned profile instead of the main ClawX profile.

### Main capabilities

- start OpenClaw and open the local dashboard
- open the dashboard with `#token=...`
- open a CLI window with launcher-specific environment variables
- auto-detect the OpenClaw repo path and ClawX executable path
- manage and migrate `state`, `logs`, and `workspace`

### Configuration

User-level launcher settings live at:

- `%USERPROFILE%\.openclaw-launcher\config\launcher-settings.json`

Common fields:

- `dataRoot`
- `openclawRepoPath`
- `clawxExePath`

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
- local user settings and runtime data

### Build

Run inside `launcher-src`:

- `npm run dist:portable`
- `npm run dist:installer`
- `npm run dist:win`

Build output goes to:

- `launcher-src/dist/`
