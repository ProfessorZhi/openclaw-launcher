const statusText = document.getElementById("status-text");
const statusDot = document.getElementById("status-dot");
const progressLabel = document.getElementById("progress-label");
const progressPercent = document.getElementById("progress-percent");
const progressBar = document.getElementById("progress-bar");
const dashboardLink = document.getElementById("dashboard-link");
const startBtn = document.getElementById("start-btn");
const cliBtn = document.getElementById("cli-btn");
const debugBtn = document.getElementById("debug-btn");
const stopBtn = document.getElementById("stop-btn");
const logsBtn = document.getElementById("logs-btn");
const docsBtn = document.getElementById("docs-btn");
const apiBtn = document.getElementById("api-btn");
const settingsBtn = document.getElementById("settings-btn");

const apiDialog = document.getElementById("api-dialog");
const apiForm = document.getElementById("api-form");
const providerEl = document.getElementById("provider");
const modelIdEl = document.getElementById("model-id");
const apiKeyEl = document.getElementById("api-key");
const apiCancel = document.getElementById("api-cancel");
const apiSave = document.getElementById("api-save");

const settingsDialog = document.getElementById("settings-dialog");
const settingsForm = document.getElementById("settings-form");
const dataRootEl = document.getElementById("data-root");
const openclawRepoEl = document.getElementById("openclaw-repo");
const clawxExeEl = document.getElementById("clawx-exe");
const settingsCancel = document.getElementById("settings-cancel");
const settingsDetect = document.getElementById("settings-detect");
const settingsSave = document.getElementById("settings-save");

let refreshTimer = null;
let uiBusy = false;
let statusOverrideText = "";
let statusOverrideColor = "";

function setProgress(percent, label) {
  progressPercent.textContent = `${percent}%`;
  progressLabel.textContent = label;
  progressBar.style.width = `${percent}%`;
}

function setBusy(busy) {
  uiBusy = busy;
  startBtn.disabled = busy;
  debugBtn.disabled = busy;
}

function paintStatus(snapshot) {
  statusText.textContent = statusOverrideText || snapshot.label;
  statusDot.className = `status-dot ${statusOverrideColor || snapshot.color || "gray"}`;
  stopBtn.disabled = !snapshot.closable;
  dashboardLink.textContent = snapshot.dashboardUrl;
}

async function refreshStatus() {
  const snapshot = await window.openclawApi.getStatus();

  if (snapshot.listenerPid) {
    statusOverrideText = "";
    statusOverrideColor = "";
    setBusy(false);
    setProgress(
      snapshot.dashboardReady ? 100 : 92,
      snapshot.dashboardReady ? "启动成功" : "OpenClaw 已运行，网页控制台还在准备..."
    );
  } else if (!uiBusy) {
    statusOverrideText = "";
    statusOverrideColor = "";
    setProgress(0, "空闲");
  }

  paintStatus(snapshot);
}

function bindProgress() {
  window.openclawApi.onProgress((payload) => {
    if (typeof payload.busy === "boolean") {
      setBusy(payload.busy);
    }

    if (payload.statusText) {
      statusOverrideText = payload.statusText;
    }
    if (payload.statusColor) {
      statusOverrideColor = payload.statusColor;
    }

    setProgress(payload.percent || 0, payload.label || "处理中...");

    if (["online", "browser", "done", "warning", "timeout", "stopped"].includes(payload.stage)) {
      refreshStatus();
      return;
    }

    paintStatus({
      label: "未运行",
      color: "gray",
      closable: false,
      dashboardUrl: dashboardLink.textContent || "http://127.0.0.1:18789/"
    });
  });
}

async function runAction(action) {
  try {
    const result = await action();
    if (result && result.message) {
      window.alert(result.message);
    }
  } catch (error) {
    window.alert(error.message || String(error));
  } finally {
    if (!uiBusy) {
      setBusy(false);
    }
    refreshStatus();
  }
}

async function openApiDialog() {
  const config = await window.openclawApi.getApiConfig();
  providerEl.value = config.provider || "minimax-portal";

  if (providerEl.value === "minimax-portal") {
    modelIdEl.value = config.minimaxPortalModelId || "MiniMax-M2.5";
    apiKeyEl.value = config.minimaxPortalApiKey || "";
  } else {
    modelIdEl.value = config.minimaxModelId || "MiniMax-M2.5";
    apiKeyEl.value = config.minimaxApiKey || "";
  }

  apiDialog.showModal();
}

async function fillSettingsDialog() {
  const settings = await window.openclawApi.getIntegrationSettings();
  dataRootEl.value = settings.dataRoot || "";
  openclawRepoEl.value = settings.openclawRepoPath || "";
  clawxExeEl.value = settings.clawxExePath || "";
}

async function openSettingsDialog() {
  await fillSettingsDialog();
  settingsDialog.showModal();
}

async function autoDetectSettings() {
  const result = await window.openclawApi.detectInstallations();
  if (result.dataRoot) {
    dataRootEl.value = result.dataRoot;
  }
  if (result.openclawRepoPath) {
    openclawRepoEl.value = result.openclawRepoPath;
  }
  if (result.clawxExePath) {
    clawxExeEl.value = result.clawxExePath;
  }
}

providerEl.addEventListener("change", async () => {
  const config = await window.openclawApi.getApiConfig();
  if (providerEl.value === "minimax-portal") {
    modelIdEl.value = config.minimaxPortalModelId || "MiniMax-M2.5";
    apiKeyEl.value = config.minimaxPortalApiKey || "";
  } else {
    modelIdEl.value = config.minimaxModelId || "MiniMax-M2.5";
    apiKeyEl.value = config.minimaxApiKey || "";
  }
});

apiCancel.addEventListener("click", () => apiDialog.close());
settingsCancel.addEventListener("click", () => settingsDialog.close());
settingsDetect.addEventListener("click", () => runAction(() => autoDetectSettings()));

async function saveApiDialog() {
  const payload = {
    provider: providerEl.value,
    modelId: modelIdEl.value.trim(),
    apiKey: apiKeyEl.value.trim()
  };

  if (!payload.modelId || !payload.apiKey) {
    window.alert("请填写模型 ID 和 API Key / Token。");
    return;
  }

  await window.openclawApi.saveApiConfig(payload);
  apiDialog.close();
  window.alert("模型配置已保存，重启 OpenClaw 后会生效。");
}

async function saveSettingsDialog() {
  const payload = {
    dataRoot: dataRootEl.value.trim(),
    openclawRepoPath: openclawRepoEl.value.trim(),
    clawxExePath: clawxExeEl.value.trim()
  };

  if (!payload.dataRoot || !payload.openclawRepoPath) {
    window.alert("请至少填写共享数据根目录和 OpenClaw 仓库目录。");
    return;
  }

  const result = await window.openclawApi.saveIntegrationSettings(payload);
  settingsDialog.close();
  if (result && result.message) {
    window.alert(result.message);
  }
  refreshStatus();
}

apiForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  await saveApiDialog();
});

settingsForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  await saveSettingsDialog();
});

apiSave.addEventListener("click", () => runAction(() => saveApiDialog()));
settingsSave.addEventListener("click", () => runAction(() => saveSettingsDialog()));

dashboardLink.addEventListener("click", () => runAction(() => window.openclawApi.openDashboard()));
startBtn.addEventListener("click", () => runAction(() => window.openclawApi.startNormal()));
cliBtn.addEventListener("click", () => runAction(() => window.openclawApi.openCli()));
debugBtn.addEventListener("click", () => runAction(() => window.openclawApi.startDebug()));
stopBtn.addEventListener("click", () => runAction(() => window.openclawApi.stopCurrent()));
logsBtn.addEventListener("click", () => runAction(() => window.openclawApi.openLogs()));
docsBtn.addEventListener("click", () => runAction(() => window.openclawApi.openDocs()));
apiBtn.addEventListener("click", () => openApiDialog());
settingsBtn.addEventListener("click", () => openSettingsDialog());

bindProgress();
refreshStatus();
setProgress(0, "空闲");
refreshTimer = setInterval(refreshStatus, 2500);

window.addEventListener("beforeunload", () => {
  if (refreshTimer) {
    clearInterval(refreshTimer);
  }
});
