# OpenClaw Launcher

OpenClaw Launcher is a Windows Electron launcher for people who use OpenClaw and ClawX together and want one place to manage startup, shared data, logs, and model configuration.

It is designed for a setup where:

- the OpenClaw source repo lives in one folder
- the ClawX desktop app lives somewhere else
- both should reuse one shared data root for `state`, `logs`, and `workspace`

## What the launcher does

- starts OpenClaw and opens the local web console
- stops the current OpenClaw instance
- offers a foreground debug start with visible logs
- edits model provider settings for local use
- discovers the OpenClaw repo path and the ClawX executable path
- manages the shared data root and migrates `state`, `logs`, and `workspace`

## Release formats

Releases are intended to ship two Windows assets:

- installer build
  standard setup flow for normal users
- portable build
  one-file executable for local testing or manual distribution

Both builds read the same user-level launcher settings and can share the same OpenClaw data root.

## Shared data model

The launcher separates program files from runtime data.

By default, the shared data root follows the drive where the launcher is installed:

- installed on `E:` -> default shared data root is `E:\OpenClaw Shared Data`
- installed on `F:` -> default shared data root is `F:\OpenClaw Shared Data`

Inside that shared root, the launcher manages:

- `state`
- `logs`
- `workspace`

It also keeps this Windows junction aligned with the active shared state folder:

- `C:\Users\Administrator\.openclaw`

That means OpenClaw and ClawX can share the same underlying state as long as they both resolve through the same `.openclaw` entry and shared root.

Launcher settings are stored per user under:

- `%USERPROFILE%\.openclaw-launcher\config\launcher-settings.json`

That allows installed and portable builds to discover the same saved paths.

## Auto-discovery

The launcher can auto-discover:

- the OpenClaw repo directory
- the ClawX executable path
- the current shared data root

Shared data root discovery works in this order:

1. read the launcher's saved `dataRoot`
2. inspect `C:\Users\Administrator\.openclaw`
3. if that junction points to `...\state`, infer the shared root from it
4. fall back to the default shared data root for the install drive

## Project layout

- `launcher-src/`
  Electron source code that should be tracked in Git
- `docs/`
  public documentation and coordination notes
- `scripts/`
  helper scripts for local packaging or maintenance
- `launcher/`
  unpacked local runtime folder for the current portable build
- `state/`
  local shared state for this machine
- `logs/`
  local runtime logs
- `workspace/`
  local agent workspaces

## What should go to GitHub

Recommended to commit:

- `launcher-src/`
- `docs/`
- `scripts/`
- `README.md`
- `.gitignore`
- `test-launcher.bat`

Recommended to keep out of Git:

- `launcher/`
- `launcher-src/dist/`
- `launcher-src/node_modules/`
- `state/`
- `logs/`
- `workspace/`
- personal settings under `%USERPROFILE%\.openclaw-launcher`

## Build output

Generated artifacts live under:

- `launcher-src/dist/`

Useful build commands:

- `npm run dist:portable`
- `npm run dist:installer`
- `npm run dist:win`

The generated installer and portable executables should usually stay out of Git because they are rebuildable artifacts.

## Documentation

- `docs/coordination.md` explains how OpenClaw, ClawX, the shared `state`, and the launcher work together.
