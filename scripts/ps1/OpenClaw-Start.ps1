$ErrorActionPreference = "Stop"

$root = "E:\openclaw"
$scriptPath = Join-Path $root "scripts\ps1\OpenClaw-Debug.ps1"
$logsDir = Join-Path $root "logs"
$stateDir = Join-Path $root "state\launcher"
$stdoutLogPath = Join-Path $logsDir "gateway.out.log"
$stderrLogPath = Join-Path $logsDir "gateway.err.log"
$pidPath = Join-Path $stateDir "launcher-process.json"

New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null

$proc = Start-Process powershell -ArgumentList @(
  "-NoProfile",
  "-ExecutionPolicy", "Bypass",
  "-File", $scriptPath
) -WindowStyle Hidden -RedirectStandardOutput $stdoutLogPath -RedirectStandardError $stderrLogPath -PassThru

$payload = [ordered]@{
  pid = $proc.Id
  startedAt = (Get-Date).ToString("s")
  script = $scriptPath
} | ConvertTo-Json

Set-Content -Path $pidPath -Value $payload -Encoding UTF8
