$ErrorActionPreference = "Stop"

$repo = "F:\funny_project_from_github\openclaw-edited"
$env:OPENCLAW_STATE_DIR = "E:\openclaw\state"
$env:OPENCLAW_CONFIG_PATH = "E:\openclaw\state\openclaw.json"
$port = 18789
$agentAuthProfilesPath = Join-Path $env:OPENCLAW_STATE_DIR "agents\main\agent\auth-profiles.json"

function Get-MinimaxPortalTokenFromAuthProfiles {
  param(
    [string]$AuthProfilesPath
  )

  if (-not (Test-Path $AuthProfilesPath)) {
    return $null
  }

  try {
    $store = Get-Content -Raw $AuthProfilesPath | ConvertFrom-Json
    $defaultProfileId = $store.lastGood.'minimax-portal'
    if (-not ($defaultProfileId -is [string] -and $defaultProfileId.Trim())) {
      $ordered = $store.order.'minimax-portal'
      if ($ordered -is [System.Array] -and $ordered.Count -gt 0) {
        $defaultProfileId = $ordered[0]
      }
    }
    if ($defaultProfileId -is [string] -and $defaultProfileId.Trim()) {
      $profile = $store.profiles.$defaultProfileId
      if ($profile.type -eq 'api_key' -and $profile.key -is [string] -and $profile.key.Trim()) {
        return $profile.key.Trim()
      }
      if ($profile.type -eq 'token' -and $profile.token -is [string] -and $profile.token.Trim()) {
        return $profile.token.Trim()
      }
      if ($profile.type -eq 'oauth' -and $profile.access -is [string] -and $profile.access.Trim()) {
        return $profile.access.Trim()
      }
    }
  } catch {
    Write-Warning "Failed to read minimax auth profile: $($_.Exception.Message)"
  }

  return $null
}

if ((-not $env:MINIMAX_OAUTH_TOKEN -or -not $env:MINIMAX_API_KEY) -and (Test-Path $env:OPENCLAW_CONFIG_PATH)) {
  try {
    $cfg = Get-Content -Raw $env:OPENCLAW_CONFIG_PATH | ConvertFrom-Json
    $portalToken = $cfg.models.providers.'minimax-portal'.apiKey
    if ($portalToken -is [string] -and $portalToken.Trim()) {
      $resolvedToken = $portalToken.Trim()
      if ($resolvedToken -eq 'MINIMAX_OAUTH_TOKEN') {
        $resolvedToken = Get-MinimaxPortalTokenFromAuthProfiles -AuthProfilesPath $agentAuthProfilesPath
      }
      if ($resolvedToken -is [string] -and $resolvedToken.Trim()) {
        # Feed both compatibility paths so portal auth works regardless of which
        # resolver branch the current runtime takes.
        if (-not $env:MINIMAX_OAUTH_TOKEN) {
          $env:MINIMAX_OAUTH_TOKEN = $resolvedToken
        }
        if (-not $env:MINIMAX_API_KEY) {
          $env:MINIMAX_API_KEY = $resolvedToken
        }
      }
    }
  } catch {
    Write-Warning "Failed to hydrate MINIMAX_OAUTH_TOKEN from openclaw.json: $($_.Exception.Message)"
  }
}

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
node .\openclaw.mjs gateway --port $port --verbose @args
