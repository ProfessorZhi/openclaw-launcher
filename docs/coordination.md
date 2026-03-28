# OpenClaw / ClawX / Launcher 协同说明

## 中文说明

### 目标

这个项目要解决的是一个非常具体的问题：

- `OpenClaw` 源码仓库可能放在一个位置
- `ClawX` 安装版客户端可能放在另一个位置
- 但它们最好共用同一套运行数据

这套运行数据主要包括：

- `state`
- `logs`
- `workspace`

`OpenClaw Launcher` 的职责，就是把这三者协调起来。

### 三者分别是什么

#### OpenClaw

`OpenClaw` 本体更接近：

- 一个命令行程序
- 一个本地 Gateway 服务
- 一个本地网页控制台

常见交互方式有两种：

- 命令行
- 本地网页前端

#### ClawX

`ClawX` 是桌面客户端。

它的体验更像传统桌面软件，但底层仍然依赖 OpenClaw 相关能力。对终端用户来说，ClawX 更像图形化入口。

#### OpenClaw Launcher

`OpenClaw Launcher` 是额外的管理外壳，用来：

- 启动 OpenClaw
- 打开网页控制台
- 配置模型 API
- 管理共享数据目录
- 自动发现 OpenClaw 仓库路径和 ClawX 可执行文件

### 共享数据目录是什么

真正需要共享的，不是程序安装目录，而是共享数据目录。

共享数据目录里通常会有：

- `state`
- `logs`
- `workspace`

其中最关键的是 `state`，因为大量配置和运行状态都会放在这里。

### 默认共享目录策略

新版默认策略是：

- 程序目录只是程序目录
- 共享数据根目录默认跟着安装所在盘走

例如：

- Launcher 在 `E:` 盘时，默认共享数据根目录是 `E:\OpenClaw Shared Data`
- Launcher 在 `F:` 盘时，默认共享数据根目录是 `F:\OpenClaw Shared Data`

不管你使用的是：

- 安装版 launcher
- portable launcher

只要它们最终都指向同一个 `dataRoot`，它们就可以共用同一套 `state / logs / workspace`。

### C 盘链接的作用

为了兼容依赖默认 `.openclaw` 路径的程序，Launcher 会维护这个 Windows junction：

- `C:\Users\Administrator\.openclaw`

它会被指向：

- `当前共享数据根目录\state`

因此即使你移动了共享数据目录，只要这个链接同步更新，OpenClaw 和 ClawX 仍然有机会继续读取同一套 `state`。

### 移动共享目录时会发生什么

当你在 Launcher 里修改共享数据根目录时，当前设计目标是：

1. 保存新的 `dataRoot`
2. 迁移现有目录：
   - `state`
   - `logs`
   - `workspace`
3. 重新更新：
   - `C:\Users\Administrator\.openclaw`

也就是说，这不是只改一个路径字符串，而是尽量把当前共享数据一起搬到新位置。

### 自动发现的原理

Launcher 的自动发现会处理三类信息。

#### 1. 共享数据根目录

优先级如下：

1. 读取用户级 launcher 配置里的 `dataRoot`
2. 如果没有，再检查 `C:\Users\Administrator\.openclaw`
3. 如果这个链接指向某个 `...\state`
4. 就从它反推出共享数据根目录
5. 如果前面都没有，再回退到默认共享目录

启动器自己的配置文件位置是：

- `%USERPROFILE%\.openclaw-launcher\config\launcher-settings.json`

所以安装版和 portable 版都可以通过这份用户级配置共享当前保存的路径信息。

#### 2. OpenClaw 仓库目录

优先级如下：

1. 当前已保存的仓库路径
2. 常见固定路径
3. 在磁盘里递归查找 `openclaw.mjs`

#### 3. ClawX 客户端 EXE

优先级如下：

1. 当前已保存的 `clawxExePath`
2. 常见安装路径
3. 在 `E:\` 和 `F:\` 下递归查找 `ClawX*.exe`

### 会不会分叉成两套数据

会有这个风险，所以重点要看两件事：

1. 两边是否真的指向同一个共享数据根目录
2. `C:\Users\Administrator\.openclaw` 是否仍然指向正确的 `state`

如果这个链接失效，或者被重建成别的目录，ClawX 确实可能重新创建一套新的数据。

所以最稳的做法是：

- 认准一个共享数据根目录
- 保持 `.openclaw` 始终指向它
- 不要让多个 launcher 来回切换到不同位置

### 推荐使用方式

最稳的方式通常是：

- OpenClaw 仓库放在你自己的开发目录
- ClawX 保持正常安装
- 共享数据固定在一个你认准的位置
- 通过 Launcher 统一管理 `dataRoot`、OpenClaw 路径和 ClawX 路径

这样无论你后面使用源码版 launcher，还是安装版 launcher，都不容易把数据弄成两条分支。

## English

### Goal

This project solves a very specific problem:

- the `OpenClaw` source repo may live in one location
- the installed `ClawX` desktop client may live somewhere else
- both should still share one runtime data set

That shared runtime data mainly includes:

- `state`
- `logs`
- `workspace`

The role of `OpenClaw Launcher` is to coordinate those three pieces.

### What each part is

#### OpenClaw

`OpenClaw` itself is closer to:

- a command-line program
- a local Gateway service
- a local web control UI

Its common interaction styles are:

- command line
- local web frontend

#### ClawX

`ClawX` is the desktop client.

Its UX feels more like a traditional desktop app, while still depending on OpenClaw-related capabilities underneath.

#### OpenClaw Launcher

`OpenClaw Launcher` is the extra management shell used to:

- start OpenClaw
- open the web console
- configure model APIs
- manage the shared data directory
- auto-discover the OpenClaw repo path and the ClawX executable path

### What the shared data directory is

The thing that really needs to be shared is not the install directory, but the shared data directory.

That directory usually contains:

- `state`
- `logs`
- `workspace`

The most important part is `state`, because that is where much of the configuration and runtime state lives.

### Default shared-directory strategy

The current default strategy is:

- the program directory is only the program directory
- the shared data root follows the install drive

For example:

- if Launcher is on `E:`, the default shared data root is `E:\OpenClaw Shared Data`
- if Launcher is on `F:`, the default shared data root is `F:\OpenClaw Shared Data`

Whether you use:

- the installed launcher
- the portable launcher

they can share the same `state / logs / workspace` as long as they point to the same `dataRoot`.

### Why the `C:` junction exists

To stay compatible with programs that expect the default `.openclaw` path, Launcher maintains this Windows junction:

- `C:\Users\Administrator\.openclaw`

It points to:

- `current shared data root\state`

That means even if you move the shared data directory, OpenClaw and ClawX can still keep reading the same `state` as long as this link is updated.

### What happens when the shared directory moves

When you change the shared data root in Launcher, the intended flow is:

1. save the new `dataRoot`
2. migrate the existing directories:
   - `state`
   - `logs`
   - `workspace`
3. update:
   - `C:\Users\Administrator\.openclaw`

So this is not only changing a string path; it tries to move the active shared data with it.

### How auto-discovery works

Launcher auto-discovery handles three kinds of data.

#### 1. Shared data root

Priority order:

1. read `dataRoot` from the launcher's user-level config
2. if missing, inspect `C:\Users\Administrator\.openclaw`
3. if that link points to some `...\state`
4. infer the shared root from it
5. otherwise fall back to the default shared root

The launcher's own config file lives at:

- `%USERPROFILE%\.openclaw-launcher\config\launcher-settings.json`

That lets installed and portable builds share the same saved path information.

#### 2. OpenClaw repo directory

Priority order:

1. currently saved repo path
2. common fixed paths
3. recursive search for `openclaw.mjs`

#### 3. ClawX executable

Priority order:

1. currently saved `clawxExePath`
2. common install paths
3. recursive search for `ClawX*.exe` under `E:\` and `F:\`

### Can the data split into two branches

Yes, that risk exists, so the two most important checks are:

1. whether both sides really point to the same shared data root
2. whether `C:\Users\Administrator\.openclaw` still points to the correct `state`

If that link breaks or gets recreated to some other directory, ClawX may create a second data set.

The safest pattern is:

- decide on one shared data root
- keep `.openclaw` pointing there
- avoid switching multiple launchers back and forth between different locations

### Recommended setup

The most stable setup is usually:

- keep the OpenClaw repo in your development directory
- keep ClawX installed normally
- keep shared data fixed in one trusted location
- manage `dataRoot`, the OpenClaw path, and the ClawX path through Launcher

That way, whether you later use a source-based launcher or an installed launcher, you are much less likely to split the data into two branches.
