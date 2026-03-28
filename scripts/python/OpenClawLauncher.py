import base64
import json
import os
import socket
import subprocess
import threading
import time
import tkinter as tk
import webbrowser
from pathlib import Path
from tkinter import messagebox, ttk


ROOT = Path(r"E:\openclaw")
DOCS_DIR = ROOT / "docs"
LAUNCHER_DIR = ROOT / "launcher"
LOGS_DIR = ROOT / "logs"
SCRIPTS_DIR = ROOT / "scripts" / "ps1"
START_PS = SCRIPTS_DIR / "OpenClaw-Start.ps1"
DEBUG_PS = SCRIPTS_DIR / "OpenClaw-Debug.ps1"
PID_PATH = ROOT / "state" / "launcher" / "launcher-process.json"
REPO_DIR = Path(r"F:\funny_project_from_github\openclaw-edited")
CONTROL_URL = "http://127.0.0.1:18789/"
PORT = 18789
CREATE_NO_WINDOW = 0x08000000


def powershell_cim(query: str) -> str:
    cmd = [
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        query,
    ]
    return subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="ignore").stdout


def is_clawx_running() -> bool:
    query = (
        "$procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | "
        "Where-Object { $_.Name -match 'ClawX|clawx|electron' -or "
        "$_.CommandLine -match 'ClawX|clawx\\.com|ValueCell-ai\\\\ClawX' }; "
        "if ($procs) { '1' }"
    )
    return powershell_cim(query).strip() == "1"


def get_listener_pid() -> int | None:
    query = (
        f"$l = Get-NetTCPConnection -State Listen -LocalPort {PORT} -ErrorAction SilentlyContinue | "
        "Select-Object -First 1; if ($l) { $l.OwningProcess }"
    )
    out = powershell_cim(query).strip()
    return int(out) if out.isdigit() else None


def can_connect_dashboard() -> bool:
    try:
        with socket.create_connection(("127.0.0.1", PORT), timeout=1.5):
            return True
    except OSError:
        return False


def write_pid_record(pid: int, script: Path) -> None:
    PID_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "pid": pid,
        "startedAt": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "script": str(script),
    }
    PID_PATH.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def read_pid_record() -> dict | None:
    if not PID_PATH.exists():
        return None
    try:
        return json.loads(PID_PATH.read_text(encoding="utf-8"))
    except Exception:
        return None


def process_alive(pid: int) -> bool:
    result = subprocess.run(
        ["tasklist", "/FI", f"PID eq {pid}"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore",
    )
    return str(pid) in result.stdout


def kill_process_tree(pid: int) -> None:
    subprocess.run(
        ["taskkill", "/PID", str(pid), "/T", "/F"],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore",
    )


def get_snapshot() -> dict:
    listener_pid = get_listener_pid()
    clawx_running = is_clawx_running()
    record = read_pid_record()
    launcher_alive = bool(record and isinstance(record.get("pid"), int) and process_alive(record["pid"]))

    if listener_pid and launcher_alive and record and record.get("pid") == listener_pid:
        return {"status": "已由启动器启动", "can_stop": True, "mode": "launcher", "listener_pid": listener_pid}
    if listener_pid and clawx_running:
        return {"status": "已运行（可能来自 ClawX）", "can_stop": False, "mode": "clawx", "listener_pid": listener_pid}
    if listener_pid:
        return {"status": "已运行（孤儿实例，可关闭）", "can_stop": True, "mode": "orphan", "listener_pid": listener_pid}
    if clawx_running:
        return {"status": "ClawX 正在运行", "can_stop": False, "mode": "clawx_only", "listener_pid": None}
    if record and not launcher_alive:
        return {"status": "启动器记录存在，但进程已结束", "can_stop": False, "mode": "stale", "listener_pid": None}
    return {"status": "未运行", "can_stop": False, "mode": "none", "listener_pid": None}


def launch_script(path: Path, hidden: bool) -> subprocess.Popen:
    kwargs = {}
    if hidden:
        kwargs["creationflags"] = CREATE_NO_WINDOW
    return subprocess.Popen(
        [
            "powershell",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(path),
        ],
        **kwargs,
    )


def open_docs() -> None:
    docs = sorted(DOCS_DIR.glob("*.md"), key=lambda p: (p.name == "OpenClaw-Guide.md", -p.stat().st_size))
    if not docs:
        messagebox.showinfo("OpenClaw 启动器", "说明文档不存在。")
        return
    os.startfile(str(docs[0]))


def open_logs() -> None:
    os.startfile(str(LOGS_DIR))


def open_dashboard() -> None:
    webbrowser.open(CONTROL_URL)


def open_command_window() -> None:
    ps_script = f"""
$Host.UI.RawUI.WindowTitle = 'OpenClaw CLI'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$OutputEncoding = [Console]::OutputEncoding
Set-Location '{REPO_DIR}'
function openclaw {{ pnpm openclaw @args }}
Write-Host 'OpenClaw 命令行已就绪。'
Write-Host ''
Write-Host '请直接在提示符后输入命令，不要输入 1、2 这类序号。'
Write-Host ''
Write-Host '常见命令：'
Write-Host '  openclaw --version           查看 OpenClaw 版本'
Write-Host '  openclaw --help              查看全部命令'
Write-Host '  openclaw gateway probe       检查 Gateway 是否正在运行'
Write-Host '  openclaw gateway run         在当前窗口启动 Gateway'
Write-Host '  openclaw dashboard           打开本地网页控制台'
Write-Host '  openclaw doctor              执行本地诊断'
Write-Host ''
"""
    encoded = base64.b64encode(ps_script.encode("utf-16le")).decode("ascii")
    subprocess.Popen(
        [
            "powershell",
            "-NoExit",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-EncodedCommand",
            encoded,
        ]
    )


class LauncherApp:
    def __init__(self) -> None:
        self.root = tk.Tk()
        self.root.title("OpenClaw 启动器")
        self.root.geometry("760x620")
        self.root.resizable(False, False)
        self.root.configure(bg="#f7f8fa")

        self.running_action = False

        title = tk.Label(self.root, text="OpenClaw", font=("Segoe UI", 28, "bold"), bg="#f7f8fa")
        title.place(x=36, y=26)

        subtitle = tk.Label(
            self.root,
            text="启动本地 Gateway，并打开网页控制台。",
            font=("Segoe UI", 12),
            fg="#556268",
            bg="#f7f8fa",
        )
        subtitle.place(x=38, y=84)

        self.status_var = tk.StringVar(value="当前状态：未运行")
        self.status_label = tk.Label(
            self.root,
            textvariable=self.status_var,
            font=("Segoe UI", 13, "bold"),
            fg="#233755",
            bg="#f7f8fa",
        )
        self.status_label.place(x=38, y=122)

        url_label = tk.Label(
            self.root,
            text=f"控制台地址：  {CONTROL_URL}",
            font=("Consolas", 12),
            fg="#323c50",
            bg="#f7f8fa",
        )
        url_label.place(x=38, y=158)

        self.progress_var = tk.IntVar(value=0)
        self.progress = ttk.Progressbar(self.root, maximum=100, variable=self.progress_var, length=670)
        self.progress.place(x=38, y=196)

        self.phase_var = tk.StringVar(value="等待启动")
        self.phase_label = tk.Label(
            self.root,
            textvariable=self.phase_var,
            font=("Segoe UI", 10),
            fg="#406080",
            bg="#f7f8fa",
        )
        self.phase_label.place(x=38, y=222)

        self.btn_start = self._button("启动并打开网页", 38, 258, 670, 56, self.start_normal, big=True)
        self._button("打开命令行窗口", 38, 330, 670, 56, open_command_window, big=True)
        self._button("前台调试启动", 38, 402, 300, 52, self.start_debug)
        self._button("打开网页控制台", 408, 402, 300, 52, open_dashboard)
        self.btn_stop = self._button("关闭当前 OpenClaw", 38, 470, 300, 52, self.stop_current)
        self._button("打开日志文件夹", 408, 470, 300, 52, open_logs)
        self._button("查看说明文档", 38, 538, 670, 46, open_docs)

        tip = tk.Label(
            self.root,
            text="提示：OpenClaw 与 ClawX 共享数据，但不要同时运行。",
            font=("Segoe UI", 10),
            fg="#785028",
            bg="#f7f8fa",
        )
        tip.place(x=38, y=588)

        self.refresh_status()
        self.schedule_refresh()

    def _button(self, text: str, x: int, y: int, w: int, h: int, command, big: bool = False):
        font = ("Segoe UI", 15, "bold") if big else ("Segoe UI", 12)
        btn = tk.Button(
            self.root,
            text=text,
            command=command,
            font=font,
            bg="white",
            activebackground="#f0f0f0",
            relief="solid",
            bd=1,
        )
        btn.place(x=x, y=y, width=w, height=h)
        return btn

    def set_status(self, text: str, color: str = "#233755") -> None:
        self.status_var.set(f"当前状态：{text}")
        self.status_label.configure(fg=color)
        self.root.update_idletasks()

    def set_phase(self, text: str, progress: int | None = None) -> None:
        self.phase_var.set(text)
        if progress is not None:
            self.progress_var.set(max(0, min(100, progress)))
        self.root.update_idletasks()

    def set_busy(self, busy: bool) -> None:
        self.running_action = busy
        self.btn_start.configure(state=("disabled" if busy else "normal"))
        self.btn_start.configure(text=("正在启动..." if busy else "启动并打开网页"))
        self.root.update_idletasks()

    def refresh_status(self) -> None:
        if self.running_action:
            return
        snapshot = get_snapshot()
        if snapshot["mode"] in {"launcher", "orphan"}:
            color = "#1c8046"
        elif snapshot["mode"] in {"clawx", "clawx_only"}:
            color = "#a0781e"
        else:
            color = "#233755"
        self.set_status(snapshot["status"], color)
        self.btn_stop.configure(state=("normal" if snapshot["can_stop"] else "disabled"))
        if snapshot["mode"] == "none":
            self.set_phase("等待启动", 0)
        elif snapshot["mode"] in {"launcher", "orphan"}:
            self.set_phase("已就绪", 100)

    def schedule_refresh(self) -> None:
        self.refresh_status()
        self.root.after(2000, self.schedule_refresh)

    def start_normal(self) -> None:
        snapshot = get_snapshot()
        if snapshot["mode"] == "clawx" or snapshot["mode"] == "clawx_only":
            messagebox.showwarning("OpenClaw 启动器", "检测到 ClawX 正在运行。请先关闭 ClawX，再启动 OpenClaw。")
            return
        if snapshot["listener_pid"]:
            self.set_status("已运行（直接打开网页）", "#1c8046")
            self.set_phase("发现已有实例，正在打开网页...", 100)
            open_dashboard()
            messagebox.showinfo("OpenClaw 启动器", "检测到已有 OpenClaw 在运行，已直接打开网页控制台。")
            return

        self.set_busy(True)
        thread = threading.Thread(target=self._run_normal_start, daemon=True)
        thread.start()

    def _run_normal_start(self) -> None:
        try:
            self.root.after(0, lambda: self.set_status("正在启动...", "#285fb4"))
            self.root.after(0, lambda: self.set_phase("正在启动核心...", 8))
            launch_script(START_PS, hidden=True)

            total_steps = 30
            listener_ready = False
            for step in range(total_steps):
                if step == 5:
                    self.root.after(0, lambda: self.set_phase("正在加载插件与连接...", 28))
                elif step == 15:
                    self.root.after(0, lambda: self.set_phase("正在检测控制台端口...", 56))
                time.sleep(1)
                if get_listener_pid():
                    listener_ready = True
                    break

            if not listener_ready:
                self.root.after(0, lambda: self.set_status("未运行", "#233755"))
                self.root.after(0, lambda: self.set_phase("启动超时", 0))
                self.root.after(0, lambda: messagebox.showwarning("OpenClaw 启动器", "启动后未检测到控制台端口。你可以稍后手动点击“打开网页控制台”。"))
                return

            write_pid_record(get_listener_pid(), START_PS)
            self.root.after(0, lambda: self.set_phase("正在准备网页控制台...", 76))

            dashboard_ready = False
            for step in range(24):
                if step == 8:
                    self.root.after(0, lambda: self.set_phase("正在准备网页控制台...", 86))
                elif step == 16:
                    self.root.after(0, lambda: self.set_phase("正在打开网页控制台...", 95))
                time.sleep(1)
                if can_connect_dashboard():
                    dashboard_ready = True
                    break

            if dashboard_ready:
                self.root.after(0, lambda: self.set_status("已由启动器启动", "#1c8046"))
                self.root.after(0, lambda: self.set_phase("启动成功", 100))
                self.root.after(0, open_dashboard)
                self.root.after(0, lambda: messagebox.showinfo("OpenClaw 启动器", "OpenClaw 已启动，网页控制台已准备好。"))
            else:
                self.root.after(0, lambda: self.set_status("已由启动器启动", "#1c8046"))
                self.root.after(0, lambda: self.set_phase("后端已启动，网页可稍后打开", 90))
                self.root.after(0, lambda: messagebox.showinfo("OpenClaw 启动器", "OpenClaw 后端已启动，但网页控制台还在准备中。你可以稍后手动点击“打开网页控制台”。"))
        finally:
            self.root.after(0, lambda: self.set_busy(False))

    def start_debug(self) -> None:
        snapshot = get_snapshot()
        if snapshot["mode"] == "clawx" or snapshot["mode"] == "clawx_only":
            messagebox.showwarning("OpenClaw 启动器", "检测到 ClawX 正在运行。请先关闭 ClawX，再启动 OpenClaw。")
            return
        if snapshot["listener_pid"]:
            messagebox.showwarning("OpenClaw 启动器", "当前已有 OpenClaw 在运行。请先关闭当前实例，再使用前台调试启动。")
            return

        self.set_busy(True)
        thread = threading.Thread(target=self._run_debug_start, daemon=True)
        thread.start()

    def _run_debug_start(self) -> None:
        try:
            self.root.after(0, lambda: self.set_status("正在启动...", "#285fb4"))
            self.root.after(0, lambda: self.set_phase("正在启动前台调试窗口...", 10))
            launch_script(DEBUG_PS, hidden=False)

            total_steps = 30
            listener_ready = False
            for step in range(total_steps):
                if step == 5:
                    self.root.after(0, lambda: self.set_phase("正在加载插件与连接...", 30))
                elif step == 15:
                    self.root.after(0, lambda: self.set_phase("正在检测控制台端口...", 60))
                time.sleep(1)
                if get_listener_pid():
                    listener_ready = True
                    break

            if not listener_ready:
                self.root.after(0, lambda: self.set_status("未运行", "#233755"))
                self.root.after(0, lambda: self.set_phase("启动超时", 0))
                self.root.after(0, lambda: messagebox.showwarning("OpenClaw 启动器", "调试窗口已打开，但仍未检测到控制台端口。"))
                return

            write_pid_record(get_listener_pid(), DEBUG_PS)
            self.root.after(0, lambda: self.set_status("已由启动器启动", "#1c8046"))
            self.root.after(0, lambda: self.set_phase("前台调试已启动", 100))
        finally:
            self.root.after(0, lambda: self.set_busy(False))

    def stop_current(self) -> None:
        snapshot = get_snapshot()
        if snapshot["mode"] == "clawx":
            messagebox.showinfo("OpenClaw 启动器", "检测到 ClawX 正在运行，启动器不会帮你关闭这个实例。")
            return
        if snapshot["mode"] not in {"launcher", "orphan"} or not snapshot["listener_pid"]:
            messagebox.showinfo("OpenClaw 启动器", "当前没有可由启动器关闭的 OpenClaw。")
            return

        kill_process_tree(snapshot["listener_pid"])
        if PID_PATH.exists():
            PID_PATH.unlink(missing_ok=True)
        self.refresh_status()
        messagebox.showinfo("OpenClaw 启动器", "当前 OpenClaw 已关闭。")

    def run(self) -> None:
        self.root.mainloop()


if __name__ == "__main__":
    LauncherApp().run()
