$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$root = "E:\openclaw"
$docsDir = Join-Path $root "docs"
$startPs = Join-Path $root "scripts\ps1\OpenClaw-Start.ps1"
$debugPs = Join-Path $root "scripts\ps1\OpenClaw-Debug.ps1"
$logsPath = Join-Path $root "logs"
$configPath = Join-Path $root "state\openclaw.json"
$iconPath = Join-Path $root "launcher\assets\openclaw-lobster.ico"
$controlUrl = "http://127.0.0.1:18789/"
$repoDir = "F:\funny_project_from_github\openclaw-edited"
$launcherStateDir = Join-Path $root "state\launcher"
$pidPath = Join-Path $launcherStateDir "launcher-process.json"
$port = 18789

function T([int[]]$codes) {
  -join ($codes | ForEach-Object { [char]$_ })
}

$txtTitle = "OpenClaw " + (T @(21551,21160,22120))
$txtSubtitle = T @(21551,21160,26412,22320,32,71,97,116,101,119,97,121,65292,24182,25171,24320,32593,39029,25511,21046,21488,12290)
$txtControlUrl = (T @(25511,21046,21488,22320,22336,65306,32)) + $controlUrl
$txtStatePrefix = T @(24403,21069,29366,24577,65306,32)
$txtStart = T @(21551,21160,24182,25171,24320,32593,39029)
$txtCmd = T @(25171,24320,21629,20196,34892,31383,21475)
$txtDebug = T @(21069,21488,35843,35797,21551,21160)
$txtOpenUi = T @(25171,24320,32593,39029,25511,21046,21488)
$txtStop = T @(20851,38381,24403,21069,32,79,112,101,110,67,108,97,119)
$txtLogs = T @(25171,24320,26085,24535,25991,20214,22841)
$txtReadme = T @(26597,30475,35828,26126,25991,26723)
$txtApiConfig = T @(37197,32622,27169,22411,32,65,80,73)
$txtSaveConfig = T @(20445,23384,37197,32622)
$txtCancel = T @(21462,28040)
$txtProvider = T @(24403,21069,27169,22411,25552,20379,21830)
$txtModelId = T @(27169,22411,32,73,68)
$txtApiKeyLabel = T @(65,80,73,32,75,101,121,32,47,32,84,111,107,101,110)
$txtApiConfigTitle = T @(27169,22411,32,65,80,73,32,37197,32622)
$txtApiSaved = T @(37197,32622,24050,20445,23384,12290,33509,32,79,112,101,110,67,108,97,119,32,27491,22312,36816,34892,65292,24314,35758,20851,38381,21518,37325,26032,21551,21160,12290)
$txtApiMissing = T @(35831,22635,20889,32,65,80,73,32,75,101,121,32,25110,32,84,111,107,101,110,12290)
$txtWarnClawX = T @(26816,27979,21040,32,67,108,97,119,88,32,27491,22312,36816,34892,12290,35831,20808,20851,38381,32,67,108,97,119,88,65292,20877,21551,21160,32,79,112,101,110,67,108,97,119,12290)
$txtWarnPortBusy = T @(31471,21475,24050,34987,21344,29992,65292,24403,21069,21487,33021,24050,26377,32,79,112,101,110,67,108,97,119,32,22312,36816,34892,12290)
$txtMissing = T @(35828,26126,25991,26723,19981,23384,22312,12290)
$txtStopMissing = T @(26410,26816,27979,21040,24403,21069,21487,20851,38381,30340,32,79,112,101,110,67,108,97,119,12290)
$txtStopExternal = T @(24403,21069,36816,34892,30340,32,79,112,101,110,67,108,97,119,32,19981,26159,30001,21551,21160,22120,25289,36215,30340,65292,26412,25353,38062,19981,20250,22788,29702,23427,12290)
$txtStopBlockedByClawX = T @(26816,27979,21040,32,67,108,97,119,88,32,27491,22312,36816,34892,65292,24403,21069,32,79,112,101,110,67,108,97,119,32,21487,33021,26159,29983,30001,20110,32,67,108,97,119,88,30340,23454,20363,65292,21551,21160,22120,19981,20250,24110,20320,20851,38381,12290)
$txtStopped = T @(24050,20851,38381,21551,21160,22120,25289,36215,30340,32,79,112,101,110,67,108,97,119,12290)
$txtStoppedOrphan = T @(24050,20851,38381,24403,21069,23396,20799,32,79,112,101,110,67,108,97,119,32,23454,20363,12290)
$txtStarted = T @(24050,21551,21160,32,79,112,101,110,67,108,97,119,65292,27491,22312,25171,24320,32593,39029,25511,21046,21488,12290)
$txtStartFailed = T @(21551,21160,21518,26410,26816,27979,21040,25511,21046,21488,31471,21475,65292,20320,21487,20197,31245,21518,25163,21160,28857,20987,8220,25171,24320,32593,39029,25511,21046,21488,8221,12290)
$txtAlreadyRunningOpenUi = T @(26816,27979,21040,24050,26377,32,79,112,101,110,67,108,97,119,32,22312,36816,34892,65292,27491,22312,30452,25509,25171,24320,32593,39029,25511,21046,21488,12290)
$txtStartedBackend = T @(24050,21551,21160,32,79,112,101,110,67,108,97,119,32,21518,31471,65292,32593,39029,25511,21046,21488,21487,20197,31245,21518,25163,21160,25171,24320,12290)
$txtTip = T @(25552,31034,65306,32,79,112,101,110,67,108,97,119,32,19982,32,67,108,97,119,88,32,20849,29992,25968,25454,65292,20294,19981,35201,21516,26102,36816,34892,12290)
$txtStatusStopped = T @(26410,36816,34892)
$txtStatusLauncher = T @(24050,30001,21551,21160,22120,21551,21160)
$txtStatusExternalClawX = T @(24050,36816,34892,65288,38750,26412,21551,21160,22120,21551,21160,65292,21487,33021,26469,33258,32,67,108,97,119,88,65289)
$txtStatusOrphan = T @(24050,36816,34892,65288,23396,20799,23454,20363,65292,21487,20851,38381,65289)
$txtStatusClawXOnly = T @(67,108,97,119,88,32,27491,22312,36816,34892)
$txtStatusLauncherDown = T @(21551,21160,22120,35760,24405,23384,22312,65292,20294,36827,31243,24050,32467,26463)
$txtStatusPidMissing = T @(26410,21457,29616,21551,21160,22120,35760,24405)
$txtStatusStarting = T @(27491,22312,21551,21160,46,46,46)
$txtStatusCore = T @(27491,22312,21551,21160,26680,24515,46,46,46)
$txtStatusPlugins = T @(27491,22312,21152,36733,25554,20214,19982,36830,25509,46,46,46)
$txtStatusLoading = T @(27491,22312,21152,36733,46,46,46)
$txtStatusChecking = T @(27491,22312,26816,27979,25511,21046,21488,46,46,46)
$txtStatusDashboard = T @(27491,22312,20934,22791,32593,39029,25511,21046,21488,46,46,46)
$txtStatusOpeningUi = T @(21518,31471,24050,21551,21160,65292,27491,22312,25171,24320,32593,39029,46,46,46)
$txtStatusStartOk = T @(21551,21160,25104,21151)
$txtOpeningUi = T @(27491,22312,25171,24320,32593,39029,25511,21046,21488,46,46,46)
$txtStartButtonBusy = T @(27491,22312,21551,21160,46,46,46)
$txtCliReady = "OpenClaw " + (T @(21629,20196,34892)) + (T @(24050,23601,32490,12290))
$txtCliDirect = T @(35831,30452,25509,22312,25552,31034,31526,21518,36755,20837,21629,20196,65292,19981,35201,36755,20837,32,49,12289,50,32,36825,31867,24207,21495,12290)
$txtCliCommon = T @(24120,35265,21629,20196,65306)
$txtCliVersion = T @(26597,30475,32,79,112,101,110,67,108,97,119,32,29256,26412)
$txtCliHelp = T @(26597,30475,20840,37096,21629,20196)
$txtCliProbe = T @(26816,26597,32,71,97,116,101,119,97,121,32,26159,21542,27491,22312,36816,34892)
$txtCliRun = T @(22312,24403,21069,31383,21475,21551,21160,32,71,97,116,101,119,97,121)
$txtCliDashboard = T @(25171,24320,26412,22320,32593,39029,25511,21046,21488)
$txtCliDoctor = T @(25191,34892,26412,22320,35786,26029)

function Show-Info([string]$text) {
  [System.Windows.Forms.MessageBox]::Show(
    $text,
    $txtTitle,
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
  ) | Out-Null
}

function Show-Warn([string]$text) {
  [System.Windows.Forms.MessageBox]::Show(
    $text,
    $txtTitle,
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Warning
  ) | Out-Null
}

function Ensure-NoteProperty($obj, [string]$name, $defaultValue) {
  if ($null -eq $obj.PSObject.Properties[$name]) {
    $obj | Add-Member -NotePropertyName $name -NotePropertyValue $defaultValue
  }
  return $obj.$name
}

function Load-LauncherConfig {
  if (-not (Test-Path $configPath)) {
    return [pscustomobject]@{}
  }

  return Get-Content -Raw $configPath | ConvertFrom-Json
}

function Save-LauncherConfig($configObject) {
  $json = $configObject | ConvertTo-Json -Depth 20
  Set-Content -Path $configPath -Value $json -Encoding UTF8
}

function Set-UserEnvVar([string]$name, [string]$value) {
  [Environment]::SetEnvironmentVariable($name, $value, "User")
  Set-Item -Path ("Env:" + $name) -Value $value
}

function Show-ApiConfigDialog {
  $cfg = Load-LauncherConfig
  $modelsNode = Ensure-NoteProperty $cfg "models" ([pscustomobject]@{})
  $providersNode = Ensure-NoteProperty $modelsNode "providers" ([pscustomobject]@{})
  $agentsNode = Ensure-NoteProperty $cfg "agents" ([pscustomobject]@{})
  $defaultsNode = Ensure-NoteProperty $agentsNode "defaults" ([pscustomobject]@{})
  $defaultModelNode = Ensure-NoteProperty $defaultsNode "model" ([pscustomobject]@{})

  $dialog = New-Object System.Windows.Forms.Form
  $dialog.Text = $txtApiConfigTitle
  $dialog.StartPosition = "CenterParent"
  $dialog.Size = New-Object System.Drawing.Size(560, 320)
  $dialog.FormBorderStyle = "FixedDialog"
  $dialog.MaximizeBox = $false
  $dialog.MinimizeBox = $false
  $dialog.BackColor = [System.Drawing.Color]::White
  if (Test-Path $iconPath) {
    try {
      $dialog.Icon = New-Object System.Drawing.Icon($iconPath)
    } catch {
    }
  }

  $lblProvider = New-Object System.Windows.Forms.Label
  $lblProvider.Text = $txtProvider
  $lblProvider.AutoSize = $true
  $lblProvider.Location = New-Object System.Drawing.Point(24, 24)
  $dialog.Controls.Add($lblProvider)

  $cmbProvider = New-Object System.Windows.Forms.ComboBox
  $cmbProvider.DropDownStyle = "DropDownList"
  $cmbProvider.Location = New-Object System.Drawing.Point(24, 48)
  $cmbProvider.Size = New-Object System.Drawing.Size(220, 28)
  [void]$cmbProvider.Items.Add("minimax-portal")
  [void]$cmbProvider.Items.Add("minimax")
  $dialog.Controls.Add($cmbProvider)

  $lblModel = New-Object System.Windows.Forms.Label
  $lblModel.Text = $txtModelId
  $lblModel.AutoSize = $true
  $lblModel.Location = New-Object System.Drawing.Point(270, 24)
  $dialog.Controls.Add($lblModel)

  $txtModel = New-Object System.Windows.Forms.TextBox
  $txtModel.Location = New-Object System.Drawing.Point(270, 48)
  $txtModel.Size = New-Object System.Drawing.Size(240, 28)
  $dialog.Controls.Add($txtModel)

  $lblKey = New-Object System.Windows.Forms.Label
  $lblKey.Text = $txtApiKeyLabel
  $lblKey.AutoSize = $true
  $lblKey.Location = New-Object System.Drawing.Point(24, 92)
  $dialog.Controls.Add($lblKey)

  $txtKey = New-Object System.Windows.Forms.TextBox
  $txtKey.Location = New-Object System.Drawing.Point(24, 116)
  $txtKey.Size = New-Object System.Drawing.Size(486, 92)
  $txtKey.Multiline = $true
  $txtKey.ScrollBars = "Vertical"
  $dialog.Controls.Add($txtKey)

  $btnSaveConfig = New-UiButton $txtSaveConfig 214 226 140 40
  $btnCancelConfig = New-UiButton $txtCancel 370 226 140 40

  $fillForm = {
    $providerId = [string]$cmbProvider.SelectedItem
    if (-not $providerId) {
      return
    }

    $providerNode = $providersNode.PSObject.Properties[$providerId].Value
    if ($providerNode -and $providerNode.apiKey) {
      $txtKey.Text = [string]$providerNode.apiKey
    } else {
      $txtKey.Text = ""
    }

    $primary = [string]$defaultModelNode.primary
    if ($primary -like "$providerId/*") {
      $txtModel.Text = $primary.Split("/", 2)[1]
    } elseif ($providerNode -and $providerNode.models -and $providerNode.models.Count -gt 0) {
      $txtModel.Text = [string]$providerNode.models[0].id
    } elseif ($providerId -eq "minimax-portal") {
      $txtModel.Text = "MiniMax-M2.5"
    } else {
      $txtModel.Text = "MiniMax-M2.7"
    }
  }

  $defaultProvider = if ([string]$defaultModelNode.primary -like "minimax/*") { "minimax" } else { "minimax-portal" }
  $cmbProvider.SelectedItem = $defaultProvider
  & $fillForm
  $cmbProvider.Add_SelectedIndexChanged($fillForm)

  $btnSaveConfig.Add_Click({
    $providerId = [string]$cmbProvider.SelectedItem
    $apiKey = $txtKey.Text.Trim()
    $modelId = $txtModel.Text.Trim()
    if (-not $apiKey) {
      Show-Warn $txtApiMissing
      return
    }
    if (-not $modelId) {
      $modelId = if ($providerId -eq "minimax-portal") { "MiniMax-M2.5" } else { "MiniMax-M2.7" }
    }

    $providerNode = $providersNode.PSObject.Properties[$providerId].Value
    if (-not $providerNode) {
      $providerNode = [pscustomobject]@{}
      $providersNode | Add-Member -NotePropertyName $providerId -NotePropertyValue $providerNode
    }

    $providerNode | Add-Member -Force -NotePropertyName "baseUrl" -NotePropertyValue (if ($providerId -eq "minimax-portal") { "https://api.minimaxi.com/anthropic" } else { "https://api.minimax.io/anthropic" })
    $providerNode | Add-Member -Force -NotePropertyName "api" -NotePropertyValue "anthropic-messages"
    $providerNode | Add-Member -Force -NotePropertyName "authHeader" -NotePropertyValue $true
    $providerNode | Add-Member -Force -NotePropertyName "apiKey" -NotePropertyValue $apiKey
    $providerNode | Add-Member -Force -NotePropertyName "models" -NotePropertyValue @(
      [pscustomobject]@{
        id = $modelId
        name = $modelId
      }
    )

    $defaultModelNode | Add-Member -Force -NotePropertyName "primary" -NotePropertyValue "$providerId/$modelId"
    Save-LauncherConfig $cfg

    if ($providerId -eq "minimax-portal") {
      Set-UserEnvVar "MINIMAX_OAUTH_TOKEN" $apiKey
      Set-UserEnvVar "MINIMAX_API_KEY" $apiKey
    } elseif ($providerId -eq "minimax") {
      Set-UserEnvVar "MINIMAX_API_KEY" $apiKey
    }

    $dialog.Tag = "saved"
    $dialog.Close()
  })

  $btnCancelConfig.Add_Click({
    $dialog.Close()
  })

  $dialog.Controls.Add($btnSaveConfig)
  $dialog.Controls.Add($btnCancelConfig)
  [void]$dialog.ShowDialog($form)

  if ($dialog.Tag -eq "saved") {
    Show-Info $txtApiSaved
    Update-StatusUi
  }
}

function Test-ClawXRunning {
  if (Get-Process -Name "ClawX" -ErrorAction SilentlyContinue) {
    return $true
  }

  $electron = Get-Process -Name "electron" -ErrorAction SilentlyContinue
  if (-not $electron) {
    return $false
  }

  foreach ($proc in $electron) {
    try {
      $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
      if ($cmd -match 'ClawX|clawx\.com|ValueCell-ai\\ClawX') {
        return $true
      }
    } catch {
    }
  }

  return $false
}

function Start-HiddenPs([string]$path) {
  Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $path
  ) -WindowStyle Hidden -PassThru
}

function Start-VisiblePs([string]$path) {
  Start-Process powershell -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $path
  ) -WindowStyle Normal -PassThru
}

function Save-LauncherRecord([int]$processId, [string]$scriptPath) {
  New-Item -ItemType Directory -Force -Path $launcherStateDir | Out-Null
  $payload = [ordered]@{
    pid = $processId
    startedAt = (Get-Date).ToString("s")
    script = $scriptPath
  } | ConvertTo-Json
  Set-Content -Path $pidPath -Value $payload -Encoding UTF8
}

function Save-ListenerRecord([string]$scriptPath) {
  $listener = Get-Listener
  if ($listener) {
    Save-LauncherRecord -processId ([int]$listener.OwningProcess) -scriptPath $scriptPath
  }
}

function Test-DashboardReady {
  try {
    $response = Invoke-WebRequest -Uri $controlUrl -UseBasicParsing -TimeoutSec 1
    return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
  } catch {
    return $false
  }
}

function New-UiButton([string]$text, [int]$x, [int]$y, [int]$w = 232, [int]$h = 46) {
  $button = New-Object System.Windows.Forms.Button
  $button.Text = $text
  $button.Size = New-Object System.Drawing.Size($w, $h)
  $button.Location = New-Object System.Drawing.Point($x, $y)
  $button.Font = New-Object System.Drawing.Font("Segoe UI", 10)
  $button.BackColor = [System.Drawing.Color]::White
  $button.FlatStyle = "Flat"
  $button.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
  return $button
}

function Get-Listener {
  Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Get-LauncherRecord {
  if (-not (Test-Path $pidPath)) {
    return $null
  }

  try {
    return Get-Content -Raw $pidPath | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Test-ProcessAlive([int]$processId) {
  return $null -ne (Get-Process -Id $processId -ErrorAction SilentlyContinue)
}

function Get-StatusSnapshot {
  if (
    -not $script:launchState.Active -and
    $script:statusCache.Snapshot -and
    (((Get-Date) - $script:statusCache.LastRefresh).TotalSeconds -lt 4)
  ) {
    return $script:statusCache.Snapshot
  }

  $listener = Get-Listener
  $clawXRunning = Test-ClawXRunning
  $record = Get-LauncherRecord
  $launcherAlive = $false

  if ($record -and $record.pid) {
    $launcherAlive = Test-ProcessAlive ([int]$record.pid)
  }

  $statusText = $txtStatusStopped
  $canStop = $false
  $stopMode = "none"

  if ($listener -and $launcherAlive) {
    $statusText = $txtStatusLauncher
    $canStop = $true
    $stopMode = "launcher"
  } elseif ($listener -and $clawXRunning) {
    $statusText = $txtStatusExternalClawX
  } elseif ($listener) {
    $statusText = $txtStatusOrphan
    $canStop = $true
    $stopMode = "orphan"
  } elseif ($clawXRunning) {
    $statusText = $txtStatusClawXOnly
  } elseif ($record -and -not $launcherAlive) {
    $statusText = $txtStatusLauncherDown
  } elseif (-not $record) {
    $statusText = $txtStatusPidMissing
  }

  $snapshot = [pscustomobject]@{
    Listener = $listener
    ClawXRunning = $clawXRunning
    LauncherRecord = $record
    LauncherAlive = $launcherAlive
    CanStop = $canStop
    StopMode = $stopMode
    StatusText = $statusText
  }

  if (-not $script:launchState.Active) {
    $script:statusCache.LastRefresh = Get-Date
    $script:statusCache.Snapshot = $snapshot
  }

  return $snapshot
}

function Stop-ProcessTree([int]$processId) {
  $children = Get-CimInstance Win32_Process -Filter "ParentProcessId = $processId" -ErrorAction SilentlyContinue
  foreach ($child in $children) {
    Stop-ProcessTree -processId $child.ProcessId
  }

  $proc = Get-Process -Id $processId -ErrorAction SilentlyContinue
  if ($proc) {
    Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
  }
}

function Update-StatusUi {
  $snapshot = Get-StatusSnapshot
  $statusValue.Text = $txtStatePrefix + $snapshot.StatusText
  if ($snapshot.StatusText -eq $txtStatusLauncher -or $snapshot.StatusText -eq $txtStatusOrphan) {
    $statusValue.ForeColor = [System.Drawing.Color]::FromArgb(28, 128, 70)
  } elseif ($snapshot.StatusText -eq $txtStatusExternalClawX -or $snapshot.StatusText -eq $txtStatusClawXOnly) {
    $statusValue.ForeColor = [System.Drawing.Color]::FromArgb(160, 120, 30)
  } else {
    $statusValue.ForeColor = [System.Drawing.Color]::FromArgb(35, 55, 85)
  }
  $portValue.Text = $txtControlUrl
  $btnStop.Enabled = $snapshot.CanStop
}

function Set-LaunchProgress([string]$statusText, [bool]$busy, [int]$progress = -1) {
  $statusValue.Text = $txtStatePrefix + $statusText
  if ($statusText -eq $txtStatusStartOk) {
    $statusValue.ForeColor = [System.Drawing.Color]::FromArgb(28, 128, 70)
  } elseif (
    $statusText -eq $txtStatusStarting -or
    $statusText -eq $txtStatusCore -or
    $statusText -eq $txtStatusPlugins -or
    $statusText -eq $txtStatusLoading -or
    $statusText -eq $txtStatusChecking -or
    $statusText -eq $txtStatusDashboard -or
    $statusText -eq $txtStatusOpeningUi
  ) {
    $statusValue.ForeColor = [System.Drawing.Color]::FromArgb(40, 95, 180)
  } else {
    $statusValue.ForeColor = [System.Drawing.Color]::FromArgb(35, 55, 85)
  }
  $btnStart.Enabled = -not $busy
  if ($busy) {
    $btnStart.Text = $txtStartButtonBusy
  } else {
    $btnStart.Text = $txtStart
  }
  if ($progress -ge 0) {
    $progressBar.Value = [Math]::Max($progressBar.Minimum, [Math]::Min($progressBar.Maximum, $progress))
  }
  $form.Refresh()
  [System.Windows.Forms.Application]::DoEvents()
}

$script:launchState = [ordered]@{
  Active = $false
  Mode = ""
  ScriptPath = ""
  ListenerTicks = 0
  DashboardTicks = 0
  BrowserOpened = $false
}
$script:statusCache = [ordered]@{
  LastRefresh = [datetime]::MinValue
  Snapshot = $null
}

function Reset-LaunchState {
  $script:launchState.Active = $false
  $script:launchState.Mode = ""
  $script:launchState.ScriptPath = ""
  $script:launchState.ListenerTicks = 0
  $script:launchState.DashboardTicks = 0
  $script:launchState.BrowserOpened = $false
}

function Reset-StatusCache {
  $script:statusCache.LastRefresh = [datetime]::MinValue
  $script:statusCache.Snapshot = $null
}

function Complete-Launch([string]$statusText, [int]$progress, [string]$message) {
  Set-LaunchProgress -statusText $statusText -busy $false -progress $progress
  Reset-StatusCache
  Update-StatusUi
  Reset-LaunchState
  if ($message) {
    Show-Info $message
  }
}

function Fail-Launch([string]$message) {
  Set-LaunchProgress -statusText $txtStatusStopped -busy $false -progress 0
  Reset-StatusCache
  Update-StatusUi
  Reset-LaunchState
  Show-Warn $message
}

function Start-LaunchFlow([string]$mode) {
  Reset-StatusCache
  $snapshot = Get-StatusSnapshot
  if ($snapshot.ClawXRunning) {
    Show-Warn $txtWarnClawX
    return
  }
  if ($snapshot.Listener -and -not $snapshot.CanStop) {
    Show-Warn $txtWarnPortBusy
    return
  }
  if ($script:launchState.Active) {
    return
  }

  $scriptPath = if ($mode -eq "debug") { $debugPs } else { $startPs }
  $proc =
    if ($mode -eq "debug") {
      Start-VisiblePs $scriptPath
    } else {
      Start-HiddenPs $scriptPath
    }

  Save-LauncherRecord -processId $proc.Id -scriptPath $scriptPath
  $script:launchState.Active = $true
  $script:launchState.Mode = $mode
  $script:launchState.ScriptPath = $scriptPath
  $script:launchState.ListenerTicks = 0
  $script:launchState.DashboardTicks = 0
  $script:launchState.BrowserOpened = $false
  Set-LaunchProgress -statusText $txtStatusStarting -busy $true -progress 5
}

function Handle-LaunchTick {
  if (-not $script:launchState.Active) {
    return
  }

  $listener = Get-Listener
  if (-not $listener) {
    $script:launchState.ListenerTicks += 1
    if ($script:launchState.ListenerTicks -le 3) {
      Set-LaunchProgress -statusText $txtStatusCore -busy $true -progress 15
    } elseif ($script:launchState.ListenerTicks -le 10) {
      Set-LaunchProgress -statusText $txtStatusPlugins -busy $true -progress 35
    } else {
      Set-LaunchProgress -statusText $txtStatusChecking -busy $true -progress 55
    }
    if ($script:launchState.ListenerTicks -ge 60) {
      Fail-Launch $txtStartFailed
    }
    return
  }

  Save-ListenerRecord -scriptPath $script:launchState.ScriptPath
  if ($script:launchState.Mode -eq "debug") {
    Complete-Launch -statusText $txtStatusStartOk -progress 100 -message ""
    return
  }

  $script:launchState.DashboardTicks += 1
  if ($script:launchState.DashboardTicks -le 4) {
    Set-LaunchProgress -statusText $txtStatusDashboard -busy $true -progress 72
  } elseif ($script:launchState.DashboardTicks -le 10) {
    Set-LaunchProgress -statusText $txtStatusDashboard -busy $true -progress 84
  } else {
    Set-LaunchProgress -statusText $txtStatusOpeningUi -busy $true -progress 94
  }

  if (Test-DashboardReady) {
    if (-not $script:launchState.BrowserOpened) {
      try {
        Start-Process $controlUrl | Out-Null
      } catch {
        # The backend is already healthy even if the browser launch fails.
      }
      $script:launchState.BrowserOpened = $true
    }
    Complete-Launch -statusText $txtStatusStartOk -progress 100 -message $txtStarted
    return
  }

  if ($script:launchState.DashboardTicks -ge 80) {
    Complete-Launch -statusText $txtStatusLauncher -progress 90 -message $txtStartedBackend
  }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = $txtTitle
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(580, 620)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(247, 248, 250)
$form.ShowInTaskbar = $true
if (Test-Path $iconPath) {
  try {
    $form.Icon = New-Object System.Drawing.Icon($iconPath)
  } catch {
  }
}
try {
  $form.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($form, $true, $null)
} catch {
}

$title = New-Object System.Windows.Forms.Label
$title.Text = "OpenClaw"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(24, 18)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = $txtSubtitle
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$subtitle.AutoSize = $true
$subtitle.Location = New-Object System.Drawing.Point(26, 60)
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(85, 90, 98)
$form.Controls.Add($subtitle)

$statusValue = New-Object System.Windows.Forms.Label
$statusValue.Text = $txtStatePrefix + $txtStatusStopped
$statusValue.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$statusValue.AutoSize = $true
$statusValue.Location = New-Object System.Drawing.Point(26, 92)
$statusValue.ForeColor = [System.Drawing.Color]::FromArgb(35, 55, 85)
$form.Controls.Add($statusValue)

$portValue = New-Object System.Windows.Forms.Label
$portValue.Text = $txtControlUrl
$portValue.Font = New-Object System.Drawing.Font("Consolas", 10)
$portValue.AutoSize = $true
$portValue.Location = New-Object System.Drawing.Point(26, 118)
$portValue.ForeColor = [System.Drawing.Color]::FromArgb(50, 60, 80)
$form.Controls.Add($portValue)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$progressBar.Size = New-Object System.Drawing.Size(506, 18)
$progressBar.Location = New-Object System.Drawing.Point(24, 146)
$form.Controls.Add($progressBar)

$btnStart = New-UiButton $txtStart 24 176 506 54
$btnCmd = New-UiButton $txtCmd 24 242 506 54
$btnDebug = New-UiButton $txtDebug 24 308
$btnOpenUi = New-UiButton $txtOpenUi 270 308
$btnStop = New-UiButton $txtStop 24 364
$btnLogs = New-UiButton $txtLogs 270 364
$btnApi = New-UiButton $txtApiConfig 24 420 232 46
$btnReadme = New-UiButton $txtReadme 270 420 260 46

$btnStart.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$btnCmd.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

$btnStart.Add_Click({
  Start-LaunchFlow "start"
  $form.BringToFront()
  $form.Activate()
})

$btnCmd.Add_Click({
  $psCommand = @"
`$Host.UI.RawUI.WindowTitle = 'OpenClaw CLI'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding(`$false)
`$OutputEncoding = [Console]::OutputEncoding
Set-Location '$repoDir'
function openclaw { pnpm openclaw @args }
Write-Host '$txtCliReady'
Write-Host ''
Write-Host '$txtCliDirect'
Write-Host ''
Write-Host '$txtCliCommon'
Write-Host '  openclaw --version           $txtCliVersion'
Write-Host '  openclaw --help              $txtCliHelp'
Write-Host '  openclaw gateway probe       $txtCliProbe'
Write-Host '  openclaw gateway run         $txtCliRun'
Write-Host '  openclaw dashboard           $txtCliDashboard'
Write-Host '  openclaw doctor              $txtCliDoctor'
Write-Host ''
"@
  $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($psCommand))
  Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-EncodedCommand", $encoded
  ) | Out-Null
  $form.BringToFront()
  $form.Activate()
})

$btnDebug.Add_Click({
  Start-LaunchFlow "debug"
  $form.BringToFront()
  $form.Activate()
})

$btnOpenUi.Add_Click({
  Start-Process $controlUrl | Out-Null
  $form.BringToFront()
  $form.Activate()
})

$btnStop.Add_Click({
  $snapshot = Get-StatusSnapshot
  if (-not $snapshot.Listener -and -not $snapshot.LauncherRecord) {
    Show-Info $txtStopMissing
    return
  }
  if ($snapshot.ClawXRunning -and $snapshot.StopMode -ne "launcher") {
    Show-Info $txtStopBlockedByClawX
    return
  }
  if (-not $snapshot.CanStop) {
    Show-Info $txtStopExternal
    return
  }

  if ($snapshot.StopMode -eq "launcher" -and $snapshot.LauncherRecord) {
    Stop-ProcessTree ([int]$snapshot.LauncherRecord.pid)
    Remove-Item $pidPath -Force -ErrorAction SilentlyContinue
    Update-StatusUi
    Show-Info $txtStopped
    $form.BringToFront()
    $form.Activate()
    return
  }

  if ($snapshot.StopMode -eq "orphan" -and $snapshot.Listener) {
    Stop-ProcessTree ([int]$snapshot.Listener.OwningProcess)
    Remove-Item $pidPath -Force -ErrorAction SilentlyContinue
    Update-StatusUi
    Show-Info $txtStoppedOrphan
    $form.BringToFront()
    $form.Activate()
    return
  }

  Remove-Item $pidPath -Force -ErrorAction SilentlyContinue
  Show-Info $txtStopExternal
  $form.BringToFront()
  $form.Activate()
})

$btnLogs.Add_Click({
  Start-Process explorer.exe $logsPath | Out-Null
  $form.BringToFront()
  $form.Activate()
})

$btnApi.Add_Click({
  Show-ApiConfigDialog
  $form.BringToFront()
  $form.Activate()
})

$btnReadme.Add_Click({
  $doc = Get-ChildItem $docsDir -Filter *.md -File -ErrorAction SilentlyContinue |
    Sort-Object `
      @{ Expression = { $_.BaseName -notlike "*OpenClaw*" } }, `
      @{ Expression = { $_.Name -eq "OpenClaw-Guide.md" } }, `
      @{ Expression = { $_.Length }; Descending = $true } |
    Select-Object -First 1

  if ($doc) {
    Start-Process $doc.FullName | Out-Null
  } else {
    Show-Info $txtMissing
  }

  $form.BringToFront()
  $form.Activate()
})

$tip = New-Object System.Windows.Forms.Label
$tip.Text = $txtTip
$tip.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$tip.AutoSize = $true
$tip.Location = New-Object System.Drawing.Point(24, 536)
$tip.ForeColor = [System.Drawing.Color]::FromArgb(120, 80, 40)
$form.Controls.Add($tip)

$script:statusTick = 0
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 400
$timer.Add_Tick({
  if ($script:launchState.Active) {
    Handle-LaunchTick
    return
  }

  $script:statusTick += 1
  if ($script:statusTick -ge 3) {
    $script:statusTick = 0
    Update-StatusUi
  }
})
$timer.Start()

@($btnStart, $btnCmd, $btnDebug, $btnOpenUi, $btnStop, $btnLogs, $btnApi, $btnReadme) | ForEach-Object {
  $form.Controls.Add($_)
}

Update-StatusUi
[void]$form.ShowDialog()
