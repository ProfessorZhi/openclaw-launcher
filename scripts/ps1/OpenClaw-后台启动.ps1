$ErrorActionPreference = "Stop"

$scriptPath = "E:\openclaw\OpenClaw-前台启动.ps1"
$stdoutLogPath = "E:\openclaw\gateway.out.log"
$stderrLogPath = "E:\openclaw\gateway.err.log"

Start-Process powershell -ArgumentList @(
  "-NoProfile",
  "-ExecutionPolicy", "Bypass",
  "-File", $scriptPath
) -WindowStyle Normal -RedirectStandardOutput $stdoutLogPath -RedirectStandardError $stderrLogPath

Write-Output "Started OpenClaw gateway. Logs: $stdoutLogPath ; $stderrLogPath"
