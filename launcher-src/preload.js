const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("openclawApi", {
  getStatus: () => ipcRenderer.invoke("status:get"),
  startNormal: () => ipcRenderer.invoke("launch:start-normal"),
  startDebug: () => ipcRenderer.invoke("launch:start-debug"),
  stopCurrent: () => ipcRenderer.invoke("launch:stop-current"),
  openDashboard: () => ipcRenderer.invoke("open:dashboard"),
  openLogs: () => ipcRenderer.invoke("open:logs"),
  openDocs: () => ipcRenderer.invoke("open:docs"),
  openCli: () => ipcRenderer.invoke("open:cli"),
  getApiConfig: () => ipcRenderer.invoke("config:get-api"),
  saveApiConfig: (payload) => ipcRenderer.invoke("config:save-api", payload),
  getIntegrationSettings: () => ipcRenderer.invoke("settings:get"),
  saveIntegrationSettings: (payload) => ipcRenderer.invoke("settings:save", payload),
  detectInstallations: () => ipcRenderer.invoke("settings:detect"),
  onProgress: (handler) => {
    const wrapped = (_event, payload) => handler(payload);
    ipcRenderer.on("launch:progress", wrapped);
    return () => ipcRenderer.removeListener("launch:progress", wrapped);
  }
});
