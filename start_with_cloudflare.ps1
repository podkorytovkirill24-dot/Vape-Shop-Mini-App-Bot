param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
Set-Location $ProjectRoot

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor Cyan
}

function Write-LinesNoBom {
    param(
        [string]$Path,
        [string[]]$Lines
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($Path, $Lines, $utf8NoBom)
}

function Stop-OldMainProcesses {
    param([string]$Root)
    $normalizedRoot = $Root.ToLowerInvariant()
    $py = Get-CimInstance Win32_Process -Filter "name='python.exe'" -ErrorAction SilentlyContinue
    foreach ($p in $py) {
        $cmd = [string]$p.CommandLine
        if (-not $cmd) { continue }
        $cmdL = $cmd.ToLowerInvariant()
        if ($cmdL -like "*main.py*" -and $cmdL -like "*$normalizedRoot*") {
            try {
                Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
                Write-Host "Stopped old python process: $($p.ProcessId)" -ForegroundColor Yellow
            }
            catch {
                # Ignore stop errors and continue.
            }
        }
    }
}

function Upsert-EnvLine {
    param(
        [string]$Path,
        [string]$Key,
        [string]$Value
    )

    if (-not (Test-Path $Path)) {
        Write-LinesNoBom -Path $Path -Lines @("$Key=$Value")
        return
    }

    $lines = @(Get-Content -Path $Path)
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\s*$Key=") {
            $lines[$i] = "$Key=$Value"
            $found = $true
        }
    }
    if (-not $found) {
        $lines += "$Key=$Value"
    }
    Write-LinesNoBom -Path $Path -Lines $lines
}

Write-Step "Preparing virtual environment"
Stop-OldMainProcesses -Root $ProjectRoot

$pythonExe = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
$pipExe = Join-Path $ProjectRoot ".venv\Scripts\pip.exe"

if (-not (Test-Path $pythonExe)) {
    python -m venv .venv
}

if (-not (Test-Path $pipExe)) {
    throw "pip executable not found in .venv"
}

& $pipExe install -r requirements.txt

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
}

Write-Step "Locating cloudflared"
$cloudflaredCandidates = @(
    (Join-Path ${env:ProgramFiles(x86)} "cloudflared\cloudflared.exe"),
    (Join-Path $env:ProgramFiles "cloudflared\cloudflared.exe")
)
$cloudflared = $cloudflaredCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $cloudflared) {
    $cmd = Get-Command cloudflared -ErrorAction SilentlyContinue
    if ($cmd) {
        $cloudflared = $cmd.Source
    }
}
if (-not $cloudflared) {
    throw "cloudflared is not installed. Install cloudflared and run again."
}

Write-Step "Starting Cloudflare tunnel"
$logFile = Join-Path $env:TEMP ("ozon_cf_" + [Guid]::NewGuid().ToString("N") + ".log")
$errFile = Join-Path $env:TEMP ("ozon_cf_" + [Guid]::NewGuid().ToString("N") + ".err")
$tunnel = Start-Process `
    -FilePath $cloudflared `
    -ArgumentList @("tunnel", "--url", "http://127.0.0.1:8000", "--no-autoupdate") `
    -RedirectStandardOutput $logFile `
    -RedirectStandardError $errFile `
    -PassThru `
    -WindowStyle Hidden

$webAppUrl = $null
for ($attempt = 0; $attempt -lt 90; $attempt++) {
    Start-Sleep -Seconds 1
    $combined = ""
    if (Test-Path $logFile) {
        $combined += (Get-Content -Path $logFile -Raw -ErrorAction SilentlyContinue)
    }
    if (Test-Path $errFile) {
        $combined += "`n" + (Get-Content -Path $errFile -Raw -ErrorAction SilentlyContinue)
    }
    if ($combined -match "https://[-a-z0-9]+\.trycloudflare\.com") {
        $webAppUrl = $Matches[0]
        break
    }
}

if (-not $webAppUrl) {
    if (Test-Path $errFile) {
        Write-Host (Get-Content -Path $errFile -Raw)
    }
    if ($tunnel -and -not $tunnel.HasExited) {
        Stop-Process -Id $tunnel.Id -Force
    }
    throw "Could not receive trycloudflare URL."
}

Write-Step "Updating .env and runtime variables"
Upsert-EnvLine -Path ".env" -Key "WEBAPP_URL" -Value $webAppUrl
Upsert-EnvLine -Path ".env" -Key "DEV_MODE" -Value "false"
$env:WEBAPP_URL = $webAppUrl
$env:DEV_MODE = "false"

$listener = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($listener) {
    $pid = $listener.OwningProcess
    if ($tunnel -and -not $tunnel.HasExited) {
        Stop-Process -Id $tunnel.Id -Force
    }
    throw "Port 8000 is already in use by PID $pid. Stop that process and run again."
}

Write-Host ""
Write-Host "Mini App URL: $webAppUrl" -ForegroundColor Green
Write-Host "Send /start to bot and press: Open catalog" -ForegroundColor Green
Write-Host ""

try {
    & $pythonExe "main.py"
}
finally {
    if ($tunnel -and -not $tunnel.HasExited) {
        Stop-Process -Id $tunnel.Id -Force
    }
}
