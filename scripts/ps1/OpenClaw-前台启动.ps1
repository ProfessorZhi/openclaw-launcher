$ErrorActionPreference = "Stop"

$repo = "F:\funny_project_from_github\openclaw-edited"
$env:OPENCLAW_STATE_DIR = "E:\openclaw\state"
$env:OPENCLAW_CONFIG_PATH = "E:\openclaw\state\openclaw.json"
$port = 18789

function Test-ClawXRunning {
  $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue
  return @($procs | Where-Object {
    $_.Name -match 'ClawX|clawx|electron' -or $_.CommandLine -match 'ClawX|clawx\.com|ValueCell-ai\\ClawX'
  }).Count -gt 0
}

if (Test-ClawXRunning) {
  throw "ClawX is running. Please close ClawX before starting OpenClaw gateway."
}

$listener = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
if ($listener) {
  throw "Port $port is already in use by PID $($listener[0].OwningProcess)."
}

Set-Location $repo
pnpm openclaw gateway --port $port --verbose @args
