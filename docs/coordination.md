# OpenClaw / ClawX / Launcher 协同说明

## 目标

这个项目要解决的是一个很具体的问题：

- `OpenClaw` 源码仓库可能放在一个位置
- `ClawX` 安装版客户端可能放在另一个位置
- 但它们最好共用同一套运行数据

这套运行数据主要包括：

- `state`
- `logs`
- `workspace`

`OpenClaw Launcher` 的职责，就是把这三者协调起来。

## 三者分别是什么

### OpenClaw

`OpenClaw` 本体更接近：

- 一个命令行程序
- 一个本地 Gateway 服务
- 一个本地网页控制台

常见交互方式有两种：

- 命令行
- 本地网页前端

### ClawX

`ClawX` 是桌面客户端。

它的使用体验更像传统桌面软件，但底层仍然依赖 OpenClaw 相关能力。对用户来说，ClawX 更像图形化入口。

### OpenClaw Launcher

`OpenClaw Launcher` 是额外的管理外壳，用来：

- 启动 OpenClaw
- 打开网页控制台
- 配置模型 API
- 管理共享数据目录
- 自动发现 OpenClaw 仓库路径和 ClawX 可执行文件

## 共享数据目录是什么

真正需要共享的，不是程序安装目录，而是共享数据目录。

共享数据目录里通常会有：

- `state`
- `logs`
- `workspace`

其中最关键的是 `state`，因为很多配置和运行状态都会放在这里。

## 默认共享目录策略

新版默认策略是：

- 程序目录只是程序目录
- 共享数据根目录默认跟着安装所在盘走

例如：

- Launcher 在 `E:` 盘时，默认共享数据根目录是 `E:\OpenClaw Shared Data`
- Launcher 在 `F:` 盘时，默认共享数据根目录是 `F:\OpenClaw Shared Data`

这样做的好处是：

- 程序文件和运行数据分开
- 对本地自用来说也比较容易管理

## C 盘链接的作用

为了兼容依赖默认 `.openclaw` 路径的程序，Launcher 会维护这个 Windows junction：

- `C:\Users\Administrator\.openclaw`

它会被指向：

- `当前共享数据根目录\state`

所以即使你移动了共享数据目录，只要这个链接同步更新，OpenClaw 和 ClawX 仍然有机会继续读取同一套 `state`。

## 移动共享目录时会发生什么

当你在 Launcher 里修改共享数据根目录时，当前设计目标是：

1. 保存新的 `dataRoot`
2. 迁移现有目录：
   - `state`
   - `logs`
   - `workspace`
3. 重新更新：
   - `C:\Users\Administrator\.openclaw`

也就是说，这不是只改一个路径字符串，而是尽量把当前共享数据一起搬到新位置。

## 自动发现的原理

Launcher 的自动发现会处理三类信息。

### 1. 共享数据根目录

优先级如下：

1. 读取用户级 launcher 配置里的 `dataRoot`
2. 如果没有，再检查 `C:\Users\Administrator\.openclaw`
3. 如果这个链接指向某个 `...\state`
4. 就从它反推出共享数据根目录
5. 如果前面都没有，再回退到默认共享目录

### 2. OpenClaw 仓库目录

优先级如下：

1. 当前已保存的仓库路径
2. 常见固定路径
3. 在磁盘里递归查找 `openclaw.mjs`

### 3. ClawX 客户端 EXE

优先级如下：

1. 当前已保存的 `clawxExePath`
2. 常见安装路径
3. 在 `E:\` 和 `F:\` 下递归查找 `ClawX*.exe`

## 会不会分叉成两套数据

会有这个风险，所以重点要看两件事：

1. 两边是否真的指向同一个共享数据根目录
2. `C:\Users\Administrator\.openclaw` 是否仍然指向正确的 `state`

如果这个链接失效，或者被重建成别的目录，ClawX 确实可能重新创建一套新的数据。

所以最稳的做法是：

- 认准一个共享数据根目录
- 保持 `.openclaw` 始终指向它
- 不要让多个 launcher 来回切换到不同位置

## 推荐使用方式

最稳的方式通常是：

- OpenClaw 仓库放在你自己的开发目录
- ClawX 保持正常安装
- 共享数据固定在一个你认准的位置
- 通过 Launcher 统一管理 `dataRoot`、OpenClaw 路径和 ClawX 路径

这样无论你后面用源码版 launcher，还是安装版 launcher，都不容易把数据弄成两条分支。
