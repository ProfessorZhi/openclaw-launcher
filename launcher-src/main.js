const { app, BrowserWindow, ipcMain, shell } = require("electron");
const { execFile, spawn } = require("child_process");
const fs = require("fs");
const http = require("http");
const path = require("path");

const PORT = 18789;
const USER_OPENCLAW_LINK = "C:\\Users\\Administrator\\.openclaw";

function detectRoot() {
  const normalized = path.normalize(__dirname);
  const current = path.basename(normalized);
  const parent = path.basename(path.dirname(normalized));

  if (current === "launcher-src") {
    return path.resolve(normalized, "..");
  }
  if (current === "app" && parent === "resources") {
    return path.resolve(normalized, "..", "..", "..");
  }
  return path.resolve(normalized, "..");
}

const ROOT = detectRoot();
const DASHBOARD_URL = `http://127.0.0.1:${PORT}/`;
const ICON_PATH = path.join(__dirname, "assets", "openclaw-lobster.ico");
const APP_HOME = path.join(process.env.USERPROFILE || ROOT, ".openclaw-launcher");
const CONFIG_DIR = path.join(APP_HOME, "config");
const SETTINGS_PATH = path.join(CONFIG_DIR, "launcher-settings.json");
const LEGACY_SETTINGS_PATH = path.join(ROOT, "config", "launcher-settings.json");
const DOCS_DIR = path.join(ROOT, "docs");
const DEBUG_SCRIPT = path.join(ROOT, "scripts", "ps1", "OpenClaw-Debug.ps1");

let mainWindow = null;
let launchInFlight = false;
let launchToken = 0;

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function emitProgress(payload) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send("launch:progress", payload);
  }
}

function readJsonSafe(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return null;
  }
}

function writeJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

function escapePs(value) {
  return String(value).replace(/'/g, "''");
}

function runPowerShell(script) {
  return new Promise((resolve, reject) => {
    execFile(
      "powershell",
      ["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", script],
      { windowsHide: true, maxBuffer: 1024 * 1024 * 10 },
      (error, stdout, stderr) => {
        if (error) {
          reject(new Error((stderr || stdout || error.message).trim()));
          return;
        }
        resolve((stdout || "").trim());
      }
    );
  });
}

async function runPowerShellJson(script) {
  const raw = await runPowerShell(script);
  if (!raw) {
    return null;
  }
  return JSON.parse(raw);
}

function defaultSettings() {
  return {
    dataRoot: getDefaultDataRoot(),
    openclawRepoPath: "F:\\funny_project_from_github\\openclaw-edited",
    clawxExePath: ""
  };
}

function getInstallDriveRoot() {
  const basePath = app.isPackaged ? process.execPath : ROOT;
  return path.parse(basePath).root || path.parse(ROOT).root || "C:\\";
}

function getDefaultDataRoot() {
  return path.join(getInstallDriveRoot(), "OpenClaw Shared Data");
}

function loadSettings() {
  const saved = readJsonSafe(SETTINGS_PATH);
  if (saved) {
    return {
      ...defaultSettings(),
      ...saved
    };
  }

  const legacy = readJsonSafe(LEGACY_SETTINGS_PATH);
  if (legacy) {
    const migrated = {
      ...defaultSettings(),
      ...legacy
    };
    saveSettings(migrated);
    return migrated;
  }

  const legacyHasData = ["state", "logs", "workspace"].some((name) =>
    fs.existsSync(path.join(ROOT, name))
  );
  if (legacyHasData) {
    const migrated = {
      ...defaultSettings(),
      dataRoot: ROOT
    };
    saveSettings(migrated);
    return migrated;
  }

  return defaultSettings();
}

function saveSettings(settings) {
  writeJson(SETTINGS_PATH, settings);
}

function getRuntimePaths(settings = loadSettings()) {
  const dataRoot = settings.dataRoot || ROOT;
  const stateDir = path.join(dataRoot, "state");
  const logsDir = path.join(dataRoot, "logs");
  const workspaceDir = path.join(dataRoot, "workspace");
  const configPath = path.join(stateDir, "openclaw.json");
  const pidPath = path.join(stateDir, "launcher", "launcher-process.json");

  return {
    root: ROOT,
    dataRoot,
    stateDir,
    logsDir,
    workspaceDir,
    configPath,
    pidPath,
    outLog: path.join(logsDir, "gateway.out.log"),
    errLog: path.join(logsDir, "gateway.err.log")
  };
}

function ensureDataDirs(settings = loadSettings()) {
  const runtime = getRuntimePaths(settings);
  fs.mkdirSync(runtime.stateDir, { recursive: true });
  fs.mkdirSync(runtime.logsDir, { recursive: true });
  fs.mkdirSync(runtime.workspaceDir, { recursive: true });
  fs.mkdirSync(path.dirname(runtime.pidPath), { recursive: true });
  return runtime;
}

function moveDirIfNeeded(oldDir, newDir) {
  if (path.resolve(oldDir) === path.resolve(newDir)) {
    fs.mkdirSync(newDir, { recursive: true });
    return;
  }
  if (!fs.existsSync(oldDir)) {
    fs.mkdirSync(newDir, { recursive: true });
    return;
  }
  if (!fs.existsSync(newDir)) {
    fs.mkdirSync(path.dirname(newDir), { recursive: true });
    fs.renameSync(oldDir, newDir);
    return;
  }
  fs.cpSync(oldDir, newDir, { recursive: true, force: true });
  fs.rmSync(oldDir, { recursive: true, force: true });
}

async function ensureUserOpenClawJunction(stateDir) {
  await runPowerShell(`
    if (Test-Path '${escapePs(USER_OPENCLAW_LINK)}') {
      Remove-Item '${escapePs(USER_OPENCLAW_LINK)}' -Force
    }
    New-Item -ItemType Junction -Path '${escapePs(USER_OPENCLAW_LINK)}' -Target '${escapePs(stateDir)}' | Out-Null
  `);
}

async function migrateDataRoot(oldSettings, newSettings) {
  const oldPaths = getRuntimePaths(oldSettings);
  const newPaths = ensureDataDirs(newSettings);

  moveDirIfNeeded(oldPaths.stateDir, newPaths.stateDir);
  moveDirIfNeeded(oldPaths.logsDir, newPaths.logsDir);
  moveDirIfNeeded(oldPaths.workspaceDir, newPaths.workspaceDir);
  await ensureUserOpenClawJunction(newPaths.stateDir);
}

async function saveIntegrationSettings(payload) {
  const oldSettings = loadSettings();
  const nextSettings = {
    dataRoot: payload.dataRoot || ROOT,
    openclawRepoPath: payload.openclawRepoPath || oldSettings.openclawRepoPath,
    clawxExePath: payload.clawxExePath || ""
  };

  const dataRootChanged =
    path.resolve(oldSettings.dataRoot || ROOT) !== path.resolve(nextSettings.dataRoot);

  if (dataRootChanged) {
    await migrateDataRoot(oldSettings, nextSettings);
  } else {
    ensureDataDirs(nextSettings);
    await ensureUserOpenClawJunction(getRuntimePaths(nextSettings).stateDir);
  }

  saveSettings(nextSettings);
  return { ok: true, message: "Integration settings saved." };
}

async function detectInstallations() {
  const settings = loadSettings();
  const linkTarget = await runPowerShell(`
    $item = Get-Item '${escapePs(USER_OPENCLAW_LINK)}' -ErrorAction SilentlyContinue
    if ($item -and $item.LinkType -eq 'Junction' -and $item.Target) {
      $target = $item.Target
      if ($target -is [array]) { $target = $target[0] }
      $target
    }
  `).catch(() => "");

  let detectedDataRoot = settings.dataRoot || "";
  if (!detectedDataRoot && linkTarget) {
    const normalized = String(linkTarget).trim();
    if (normalized.toLowerCase().endsWith("\\state")) {
      detectedDataRoot = normalized.slice(0, -6);
    }
  }
  if (!detectedDataRoot) {
    detectedDataRoot = getDefaultDataRoot();
  }

  const repo = await runPowerShell(`
    $candidates = @(
      '${escapePs(settings.openclawRepoPath)}',
      'F:\\funny_project_from_github\\openclaw-edited',
      '${escapePs(path.join(ROOT, "..", "openclaw-edited"))}'
    )
    $found = $null
    foreach ($candidate in $candidates) {
      if ($candidate -and (Test-Path (Join-Path $candidate 'openclaw.mjs'))) {
        $found = $candidate
        break
      }
    }
    if (-not $found) {
      $hit = Get-ChildItem -Path 'F:\\' -Filter 'openclaw.mjs' -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty DirectoryName
      if ($hit) { $found = $hit }
    }
    $found
  `).catch(() => "");

  const clawx = await runPowerShell(`
    $candidates = @(
      '${escapePs(settings.clawxExePath)}',
      'E:\\ClawX\\ClawX.exe',
      'E:\\ClawX\\ClawX\\ClawX.exe',
      'E:\\Program Files\\ClawX\\ClawX.exe',
      'C:\\Users\\Administrator\\AppData\\Local\\Programs\\ClawX\\ClawX.exe'
    )
    $found = $null
    foreach ($candidate in $candidates) {
      if ($candidate -and (Test-Path $candidate)) {
        $found = $candidate
        break
      }
    }
    if (-not $found) {
      $hit = Get-ChildItem -Path 'E:\\','F:\\' -Filter 'ClawX*.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
      if ($hit) { $found = $hit }
    }
    $found
  `).catch(() => "");

  return {
    dataRoot: detectedDataRoot,
    openclawRepoPath: repo || settings.openclawRepoPath || "",
    clawxExePath: clawx || settings.clawxExePath || ""
  };
}

async function isPortListening() {
  return runPowerShellJson(`
    $listener = Get-NetTCPConnection -State Listen -LocalPort ${PORT} -ErrorAction SilentlyContinue |
      Select-Object -First 1 LocalAddress, LocalPort, OwningProcess
    if ($listener) { $listener | ConvertTo-Json -Compress } else { "" }
  `).catch(() => null);
}

function fetchDashboardReady() {
  return new Promise((resolve) => {
    const req = http.get(DASHBOARD_URL, (res) => {
      res.resume();
      resolve(res.statusCode >= 200 && res.statusCode < 500);
    });
    req.on("error", () => resolve(false));
    req.setTimeout(1800, () => {
      req.destroy();
      resolve(false);
    });
  });
}

async function isClawXRunning(settings = loadSettings()) {
  if (settings.clawxExePath && fs.existsSync(settings.clawxExePath)) {
    const fullPath = settings.clawxExePath.toLowerCase();
    const byPath = await runPowerShellJson(`
      $item = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ExecutablePath -and $_.ExecutablePath.ToLower() -eq '${escapePs(fullPath)}' } |
        Select-Object -First 1 ProcessId, Name, ExecutablePath
      if ($item) { $item | ConvertTo-Json -Compress } else { "" }
    `).catch(() => null);
    if (byPath) {
      return byPath;
    }
  }

  return runPowerShellJson(`
    $item = Get-Process -Name 'ClawX' -ErrorAction SilentlyContinue | Select-Object -First 1 Id, ProcessName
    if ($item) {
      [PSCustomObject]@{
        ProcessId = $item.Id
        Name = $item.ProcessName
      } | ConvertTo-Json -Compress
    } else { "" }
  `).catch(() => null);
}

function readPidRecord(runtime = getRuntimePaths()) {
  return readJsonSafe(runtime.pidPath);
}

function clearPidRecord(runtime = getRuntimePaths()) {
  try {
    fs.rmSync(runtime.pidPath, { force: true });
  } catch {}
}

async function getStatusSnapshot() {
  const settings = loadSettings();
  const runtime = ensureDataDirs(settings);
  const listener = await isPortListening();
  const dashboardReady = listener ? await fetchDashboardReady() : false;
  const pidRecord = readPidRecord(runtime);
  const clawxRunning = await isClawXRunning(settings);

  if (listener) {
    const ownedByLauncher = pidRecord && Number(pidRecord.pid) === Number(listener.OwningProcess);
    if (ownedByLauncher) {
      return {
        kind: "launcher",
        label: "Running (launcher-managed)",
        color: "green",
        closable: true,
        listenerPid: listener.OwningProcess,
        dashboardReady,
        dashboardUrl: DASHBOARD_URL,
        clawxRunning: Boolean(clawxRunning)
      };
    }

    if (clawxRunning) {
      return {
        kind: "external",
        label: "Running (possibly started by ClawX)",
        color: "yellow",
        closable: false,
        listenerPid: listener.OwningProcess,
        dashboardReady,
        dashboardUrl: DASHBOARD_URL,
        clawxRunning: true
      };
    }

    return {
      kind: "orphan",
      label: "Running (external instance, can stop)",
      color: "green",
      closable: true,
      listenerPid: listener.OwningProcess,
      dashboardReady,
      dashboardUrl: DASHBOARD_URL,
      clawxRunning: false
    };
  }

  return {
    kind: clawxRunning ? "clawx" : "idle",
    label: clawxRunning ? "ClawX is running" : "Not running",
    color: clawxRunning ? "yellow" : "gray",
    closable: false,
    listenerPid: null,
    dashboardReady: false,
    dashboardUrl: DASHBOARD_URL,
    clawxRunning: Boolean(clawxRunning)
  };
}

async function spawnManagedGateway() {
  const settings = loadSettings();
  const runtime = ensureDataDirs(settings);
  const repo = settings.openclawRepoPath;

  if (!repo || !fs.existsSync(path.join(repo, "openclaw.mjs"))) {
    throw new Error("OpenClaw repo path is invalid. Expected to find openclaw.mjs there.");
  }

  clearPidRecord(runtime);

  const script = `
    Set-Location '${escapePs(repo)}'
    $env:OPENCLAW_STATE_DIR='${escapePs(runtime.stateDir)}'
    $env:OPENCLAW_CONFIG_PATH='${escapePs(runtime.configPath)}'
    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    node .\\openclaw.mjs gateway --port ${PORT} --verbose *>> '${escapePs(runtime.outLog)}' 2>> '${escapePs(runtime.errLog)}'
  `;
  const encoded = Buffer.from(script, "utf16le").toString("base64");

  await runPowerShell(`
    Start-Process powershell -WindowStyle Hidden -ArgumentList @(
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-EncodedCommand', '${escapePs(encoded)}'
    ) | Out-Null
  `);
}

function computeProgress(elapsedMs) {
  if (elapsedMs < 2500) {
    return {
      percent: Math.min(26, 8 + Math.floor(elapsedMs / 160)),
      label: "Starting OpenClaw..."
    };
  }
  if (elapsedMs < 15000) {
    return {
      percent: Math.min(74, 28 + Math.floor((elapsedMs - 2500) / 320)),
      label: "Loading plugins and connections..."
    };
  }
  return {
    percent: Math.min(88, 74 + Math.floor((elapsedMs - 15000) / 2200)),
    label: "Waiting for web console..."
  };
}

async function monitorLaunchLifecycle(openBrowser, token) {
  const startedAt = Date.now();
  const runtime = getRuntimePaths();
  let browserOpened = false;
  let firstOnlineAt = null;

  try {
    while (token === launchToken) {
      const elapsed = Date.now() - startedAt;
      const listener = await isPortListening();

      if (!listener) {
        if (elapsed > 90000) {
          emitProgress({
            stage: "timeout",
            percent: 68,
            label: "Startup timed out before the OpenClaw web console responded.",
            statusText: "Not running",
            statusColor: "gray",
            busy: false
          });
          return;
        }

        const progress = computeProgress(elapsed);
        emitProgress({
          stage: "launching",
          percent: progress.percent,
          label: progress.label,
          statusText: "Starting",
          statusColor: "blue",
          busy: true
        });
        await delay(900);
        continue;
      }

      if (!firstOnlineAt) {
        firstOnlineAt = Date.now();
      }

      writeJson(runtime.pidPath, {
        pid: listener.OwningProcess,
        startedAt: new Date().toISOString(),
        source: "launcher"
      });

      const dashboardReady = await fetchDashboardReady();
      if (dashboardReady) {
        emitProgress({
          stage: "browser",
          percent: 92,
          label: "Web console is responding, opening browser...",
          statusText: "Running",
          statusColor: "green",
          busy: false
        });

        if (openBrowser && !browserOpened) {
          browserOpened = true;
          await shell.openExternal(DASHBOARD_URL);
        }

        emitProgress({
          stage: "done",
          percent: 100,
          label: "Startup complete",
          statusText: "Running",
          statusColor: "green",
          busy: false
        });
        return;
      }

      if (Date.now() - firstOnlineAt > 18000) {
        emitProgress({
          stage: "warning",
          percent: 92,
          label: "OpenClaw is running, but the web console is still responding slowly. You can open it manually later.",
          statusText: "Running",
          statusColor: "green",
          busy: false
        });
        return;
      }

      emitProgress({
        stage: "online",
        percent: 90,
        label: "OpenClaw is running. The web console may still need a moment to fully render.",
        statusText: "Running",
        statusColor: "green",
        busy: false
      });
      await delay(1200);
    }
  } finally {
    if (token === launchToken) {
      launchInFlight = false;
    }
  }
}

async function startNormalLaunch() {
  if (launchInFlight) {
    return { ok: false, message: "Launch already in progress." };
  }

  const snapshot = await getStatusSnapshot();
  if (snapshot.clawxRunning) {
    return { ok: false, message: "ClawX is running. Close ClawX before starting OpenClaw." };
  }

  if (snapshot.kind === "launcher" || snapshot.kind === "orphan") {
    await shell.openExternal(DASHBOARD_URL);
    return { ok: true, message: "OpenClaw is already running. Opening the dashboard instead." };
  }

  launchInFlight = true;
  const token = ++launchToken;
  emitProgress({
    stage: "checking",
    percent: 8,
    label: "Checking environment...",
    statusText: "Starting",
    statusColor: "blue",
    busy: true
  });

  try {
    await spawnManagedGateway();
  } catch (error) {
    launchInFlight = false;
    emitProgress({
      stage: "timeout",
      percent: 0,
      label: `Startup failed: ${error.message || error}`,
      statusText: "Not running",
      statusColor: "gray",
      busy: false
    });
    return { ok: false, message: error.message || String(error) };
  }

  emitProgress({
    stage: "boot",
    percent: 16,
    label: "Starting OpenClaw...",
    statusText: "Starting",
    statusColor: "blue",
    busy: true
  });

  monitorLaunchLifecycle(true, token).catch((error) => {
    if (token !== launchToken) {
      return;
    }
    launchInFlight = false;
    emitProgress({
      stage: "timeout",
      percent: 0,
      label: `Launch monitor failed: ${error.message || error}`,
      statusText: "Not running",
      statusColor: "gray",
      busy: false
    });
  });

  return { ok: true };
}

async function spawnPowerShellFile(filePath) {
  await runPowerShell(`
    Start-Process powershell -WindowStyle Normal -ArgumentList @(
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-File', '${escapePs(filePath)}'
    ) | Out-Null
  `);
}

async function startDebugLaunch() {
  const snapshot = await getStatusSnapshot();
  if (snapshot.clawxRunning) {
    return { ok: false, message: "ClawX is running. Close ClawX before starting debug mode." };
  }
  if (snapshot.listenerPid) {
    return { ok: false, message: "Another OpenClaw instance is already running. Stop it before debug start." };
  }

  await spawnPowerShellFile(DEBUG_SCRIPT);
  emitProgress({
    stage: "debug",
    percent: 100,
    label: "Debug mode started. A foreground console window was opened for logs.",
    statusText: "Debug mode",
    statusColor: "blue",
    busy: false
  });
  return { ok: true, message: "Debug mode started." };
}

async function stopCurrentInstance() {
  launchToken += 1;
  launchInFlight = false;

  const settings = loadSettings();
  const runtime = getRuntimePaths(settings);
  const snapshot = await getStatusSnapshot();
  const pidRecord = readPidRecord(runtime);
  const targetPid =
    snapshot.kind === "launcher"
      ? Number(pidRecord?.pid || snapshot.listenerPid)
      : snapshot.kind === "orphan"
        ? Number(snapshot.listenerPid)
        : null;

  if (!targetPid) {
    emitProgress({
      stage: "stopped",
      percent: 0,
      label: "No running OpenClaw instance was found to stop.",
      statusText: "Not running",
      statusColor: "gray",
      busy: false
    });
    return { ok: false, message: "No running OpenClaw instance was found to stop." };
  }

  await runPowerShell(`
    if (Get-Process -Id ${targetPid} -ErrorAction SilentlyContinue) {
      Stop-Process -Id ${targetPid} -Force
    }
  `).catch(() => {});

  clearPidRecord(runtime);
  emitProgress({
    stage: "stopped",
    percent: 0,
    label: "OpenClaw stopped.",
    statusText: "Not running",
    statusColor: "gray",
    busy: false
  });
  return { ok: true, message: "OpenClaw stopped." };
}

function loadApiConfig() {
  const runtime = getRuntimePaths();
  const config = readJsonSafe(runtime.configPath) || {};
  const providers = config.models?.providers || {};
  const portal = providers["minimax-portal"] || {};
  const minimax = providers.minimax || {};

  return {
    provider: portal.apiKey ? "minimax-portal" : "minimax",
    minimaxPortalModelId: portal.models?.[0]?.id || "MiniMax-M2.5",
    minimaxPortalApiKey: portal.apiKey || "",
    minimaxModelId: minimax.models?.[0]?.id || "MiniMax-M2.5",
    minimaxApiKey: minimax.apiKey || ""
  };
}

async function saveApiConfig(payload) {
  const runtime = ensureDataDirs();
  const config = readJsonSafe(runtime.configPath) || {};
  config.models = config.models || {};
  config.models.providers = config.models.providers || {};

  if (payload.provider === "minimax-portal") {
    config.models.providers["minimax-portal"] = {
      baseUrl: "https://api.minimaxi.com/anthropic",
      api: "anthropic-messages",
      apiKey: payload.apiKey,
      models: [{ id: payload.modelId, name: payload.modelId }]
    };
    await runPowerShell(`
      [Environment]::SetEnvironmentVariable('MINIMAX_OAUTH_TOKEN', '${escapePs(payload.apiKey)}', 'User')
      [Environment]::SetEnvironmentVariable('MINIMAX_API_KEY', '${escapePs(payload.apiKey)}', 'User')
    `);
  } else {
    config.models.providers.minimax = {
      baseUrl: "https://api.minimaxi.com/v1",
      apiKey: payload.apiKey,
      models: [{ id: payload.modelId, name: payload.modelId }]
    };
    await runPowerShell(`
      [Environment]::SetEnvironmentVariable('MINIMAX_API_KEY', '${escapePs(payload.apiKey)}', 'User')
    `);
  }

  writeJson(runtime.configPath, config);
  return { ok: true };
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1220,
    height: 820,
    minWidth: 1024,
    minHeight: 720,
    backgroundColor: "#f7f4ef",
    icon: ICON_PATH,
    show: false,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  const showWindow = () => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.show();
      mainWindow.focus();
    }
  };

  mainWindow.loadFile(path.join(__dirname, "index.html"));
  mainWindow.once("ready-to-show", showWindow);
  mainWindow.webContents.once("did-finish-load", showWindow);
  setTimeout(showWindow, 1500);
}

app.whenReady().then(async () => {
  ensureDataDirs();
  createWindow();
  ensureUserOpenClawJunction(getRuntimePaths().stateDir).catch(() => {});

  ipcMain.handle("status:get", async () => getStatusSnapshot());
  ipcMain.handle("launch:start-normal", async () => startNormalLaunch());
  ipcMain.handle("launch:start-debug", async () => startDebugLaunch());
  ipcMain.handle("launch:stop-current", async () => stopCurrentInstance());
  ipcMain.handle("open:dashboard", async () => {
    await shell.openExternal(DASHBOARD_URL);
    return { ok: true };
  });
  ipcMain.handle("open:logs", async () => {
    await shell.openPath(getRuntimePaths().logsDir);
    return { ok: true };
  });
  ipcMain.handle("open:docs", async () => {
    const preferred = path.join(DOCS_DIR, "coordination.md");
    const fallback = path.join(ROOT, "README.md");
    await shell.openPath(fs.existsSync(preferred) ? preferred : fallback);
    return { ok: true };
  });
  ipcMain.handle("open:cli", async () => {
    const repo = loadSettings().openclawRepoPath;
    const cliScript = `
$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
Set-Location '${escapePs(repo)}'
function openclaw { node .\\openclaw.mjs @args }
Write-Host 'OpenClaw 闂佸憡绋掗崹婵嬪箮閵堝洦鍋橀悘鐐舵閸ゆ帡鎮樿箛姘惈闁告閰ｆ俊?
Write-Host ''
Write-Host '闁荤姴娲ˉ鎾趁洪崸妤€绠抽柕澶堝劜闊剟鏌熺紒妯哄闁靛洦姘ㄧ划顓㈡晝閳ь剟骞冨Δ浣圭秶闁规儳鍟垮鎶芥煕濞戞瑥鐏婇柟韬插€濋弫宥囦沪閼测晙绱ｆ繝纰樷偓鍐蹭喊缂?
Write-Host '  openclaw --version'
Write-Host '  openclaw gateway probe'
Write-Host '  openclaw dashboard'
Write-Host '  openclaw gateway run'
`;
    const encoded = Buffer.from(cliScript, "utf16le").toString("base64");
    spawn(
      "powershell",
      ["-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", encoded],
      { detached: true, windowsHide: false, stdio: "ignore" }
    ).unref();
    return { ok: true };
  });
  ipcMain.handle("config:get-api", async () => loadApiConfig());
  ipcMain.handle("config:save-api", async (_event, payload) => saveApiConfig(payload));
  ipcMain.handle("settings:get", async () => loadSettings());
  ipcMain.handle("settings:save", async (_event, payload) => saveIntegrationSettings(payload));
  ipcMain.handle("settings:detect", async () => detectInstallations());
});

app.on("window-all-closed", () => {
  app.quit();
});
