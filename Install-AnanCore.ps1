#Requires -Version 5.1
<#
.SYNOPSIS
    AnanCore Windows Portable Installer
.DESCRIPTION
    Clones ChasingCoffee/AnanCore, bouwt de .NET backend en de Vite frontend,
    en pakt alles in als een portable Windows installatie.
    Vereisten: Git, .NET 10 SDK, Node.js 20+
.PARAMETER InstallDir
    Doelmap voor de portable installatie (default: .\AnanCore)
.PARAMETER Branch
    Git branch om te clonen (default: freedv-in-core)
.PARAMETER SkipBuild
    Sla het bouwen over (handig als je alleen wil clonen)
.PARAMETER SkipDependencyCheck
    Sla de controle op vereisten over
.EXAMPLE
    .\Install-AnanCore.ps1
    .\Install-AnanCore.ps1 -InstallDir "C:\Radio\AnanCore"
    .\Install-AnanCore.ps1 -Branch main
#>
[CmdletBinding()]
param(
    [string]$InstallDir  = ".\AnanCore",
    [string]$Branch      = "freedv-in-core",
    [switch]$SkipBuild,
    [switch]$SkipDependencyCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Kleuren helpers ──────────────────────────────────────────────────────────
function Write-Header  { param($msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "  OK  $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host " WARN $msg" -ForegroundColor Yellow }
function Write-Fail    { param($msg) Write-Host " FAIL $msg" -ForegroundColor Red; exit 1 }

# ── Versie banner ────────────────────────────────────────────────────────────
Write-Host @"

  ╔══════════════════════════════════════════════════════╗
  ║    AnanCore  —  Windows Portable Installer           ║
  ║    https://github.com/ChasingCoffee/AnanCore         ║
  ╚══════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ── Vereisten controleren ────────────────────────────────────────────────────
if (-not $SkipDependencyCheck) {
    Write-Header "Vereisten controleren"

    # Git
    $gitVer = git --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Git niet gevonden. Installeer via https://git-scm.com/download/win"
    }
    Write-Success "Git: $gitVer"

    # .NET 10
    $dotnetVer = dotnet --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail ".NET SDK niet gevonden. Installeer .NET 10 SDK via https://dotnet.microsoft.com/download"
    }
    $majorVer = [int]($dotnetVer -split '\.')[0]
    if ($majorVer -lt 10) {
        Write-Warn ".NET $dotnetVer gevonden — AnanCore vereist .NET 10. Download: https://dotnet.microsoft.com/download/dotnet/10.0"
        $continue = Read-Host "  Toch doorgaan? (j/n)"
        if ($continue -notmatch '^[jJ]') { exit 1 }
    } else {
        Write-Success ".NET SDK: $dotnetVer"
    }

    # Node.js
    $nodeVer = node --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Node.js niet gevonden. Installeer Node.js 20+ via https://nodejs.org/"
    }
    $nodeMajor = [int](($nodeVer -replace 'v','') -split '\.')[0]
    if ($nodeMajor -lt 20) {
        Write-Warn "Node.js $nodeVer gevonden — versie 20+ aanbevolen"
    } else {
        Write-Success "Node.js: $nodeVer"
    }

    # npm
    $npmVer = npm --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "npm niet gevonden (hoort bij Node.js)"
    }
    Write-Success "npm: $npmVer"
}

# ── Installatiemap instellen ─────────────────────────────────────────────────
Write-Header "Installatiemap: $InstallDir"
$InstallDir = [System.IO.Path]::GetFullPath($InstallDir)
$srcDir     = Join-Path $InstallDir "src"
$releaseDir = Join-Path $InstallDir "release"

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
    Write-Success "Map aangemaakt: $InstallDir"
} else {
    Write-Warn "Map bestaat al: $InstallDir"
}

# ── Clone of update AnanCore ─────────────────────────────────────────────────
Write-Header "AnanCore repository ophalen (branch: $Branch)"

if (Test-Path (Join-Path $srcDir ".git")) {
    Write-Host "  Repository al aanwezig, updaten..."
    Push-Location $srcDir
    try {
        git fetch --all --prune 2>&1 | Out-Null
        git checkout $Branch 2>&1 | Out-Null
        git pull --rebase 2>&1 | Out-Null
        Write-Success "Repository bijgewerkt"
    } finally {
        Pop-Location
    }
} else {
    if (Test-Path $srcDir) { Remove-Item $srcDir -Recurse -Force }
    Write-Host "  Cloning https://github.com/ChasingCoffee/AnanCore ..."
    git clone `
        --branch $Branch `
        --recurse-submodules `
        --depth 1 `
        "https://github.com/ChasingCoffee/AnanCore.git" `
        $srcDir
    if ($LASTEXITCODE -ne 0) { Write-Fail "Clone mislukt" }
    Write-Success "Repository gecloned naar: $srcDir"
}

if ($SkipBuild) {
    Write-Warn "Build overgeslagen (-SkipBuild)"
    Write-Host "`nBron staat in: $srcDir" -ForegroundColor Green
    exit 0
}

# ── .NET backend bouwen ──────────────────────────────────────────────────────
Write-Header ".NET backend bouwen"
Push-Location $srcDir
try {
    # NuGet restore
    Write-Host "  NuGet restore..."
    dotnet restore Zeus.slnx 2>&1 | Select-String -Pattern 'error|warning|Restored' | ForEach-Object { "  $_" }
    if ($LASTEXITCODE -ne 0) { Write-Fail "dotnet restore mislukt" }

    # Publish als self-contained Windows x64
    $backendOut = Join-Path $releaseDir "backend"
    Write-Host "  Publishing backend (win-x64, self-contained)..."
    dotnet publish OpenhpsdrZeus `
        --configuration Release `
        --runtime win-x64 `
        --self-contained true `
        --output $backendOut `
        -p:PublishSingleFile=false `
        -p:PublishReadyToRun=true `
        2>&1 | Select-String -Pattern 'error|warning|-> ' | ForEach-Object { "  $_" }

    if ($LASTEXITCODE -ne 0) { Write-Fail "dotnet publish mislukt" }
    Write-Success "Backend gepubliceerd naar: $backendOut"
} finally {
    Pop-Location
}

# ── Vite frontend bouwen ─────────────────────────────────────────────────────
Write-Header "Vite frontend bouwen"
$webSrc = Join-Path $srcDir "zeus-web"
$webOut = Join-Path $releaseDir "backend" "wwwroot"

Push-Location $webSrc
try {
    Write-Host "  npm install..."
    npm install --prefer-offline 2>&1 | Select-String -Pattern 'error|warn|added' | ForEach-Object { "  $_" }
    if ($LASTEXITCODE -ne 0) { Write-Fail "npm install mislukt" }

    Write-Host "  npm run build..."
    # VITE_API_BASE leeg laten: frontend en backend draaien op dezelfde poort
    $env:VITE_API_BASE = ""
    npm run build 2>&1 | Select-String -Pattern 'error|warn|built in|dist/' | ForEach-Object { "  $_" }
    if ($LASTEXITCODE -ne 0) { Write-Fail "npm run build mislukt" }

    # Kopieer dist/ naar wwwroot/ van de backend
    $viteDist = Join-Path $webSrc "dist"
    if (-not (Test-Path $webOut)) { New-Item -ItemType Directory -Path $webOut | Out-Null }
    Copy-Item -Path "$viteDist\*" -Destination $webOut -Recurse -Force
    Write-Success "Frontend gebouwd en gekopieerd naar: $webOut"
} finally {
    Pop-Location
}

# ── Launcher scripts aanmaken ────────────────────────────────────────────────
Write-Header "Launcher scripts aanmaken"

# AnanCore.bat — eenvoudige dubbelklik launcher
$batContent = @"
@echo off
title AnanCore — ANAN SDR Console
cd /d "%~dp0release\backend"
echo.
echo  AnanCore starten op http://localhost:6060
echo  Open je browser en ga naar: http://localhost:6060
echo  Sluit dit venster om AnanCore te stoppen.
echo.
OpenhpsdrZeus.exe
pause
"@
$batContent | Set-Content (Join-Path $InstallDir "AnanCore.bat") -Encoding UTF8

# AnanCore-OpenBrowser.bat — start en opent automatisch de browser
$batWithBrowser = @"
@echo off
title AnanCore — ANAN SDR Console
cd /d "%~dp0release\backend"
echo  AnanCore starten...
start "" /B OpenhpsdrZeus.exe
timeout /t 3 /nobreak > nul
start "" "http://localhost:6060"
echo  Browser geopend op http://localhost:6060
echo  Sluit dit venster om AnanCore te stoppen.
pause
"@
$batWithBrowser | Set-Content (Join-Path $InstallDir "AnanCore-OpenBrowser.bat") -Encoding UTF8

# Update.ps1 — later updaten
$updateScript = @'
#Requires -Version 5.1
# Update AnanCore naar de laatste versie
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& "$scriptDir\Install-AnanCore.ps1" -InstallDir $scriptDir @args
'@
$updateScript | Set-Content (Join-Path $InstallDir "Update-AnanCore.ps1") -Encoding UTF8

Write-Success "Launcher scripts aangemaakt"

# ── Versie info opslaan ──────────────────────────────────────────────────────
Push-Location $srcDir
$commitHash = git rev-parse --short HEAD 2>&1
$commitDate = git log -1 --format="%ci" 2>&1
Pop-Location

$versionInfo = @{
    installed_at    = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    branch          = $Branch
    commit          = "$commitHash"
    commit_date     = "$commitDate"
    dotnet_version  = "$(dotnet --version 2>&1)"
    node_version    = "$(node --version 2>&1)"
    install_dir     = $InstallDir
} | ConvertTo-Json

$versionInfo | Set-Content (Join-Path $InstallDir "version.json") -Encoding UTF8

# ── Klaar ────────────────────────────────────────────────────────────────────
Write-Host @"

  ╔══════════════════════════════════════════════════════╗
  ║    Installatie voltooid!                             ║
  ╚══════════════════════════════════════════════════════╝

  Installatiemap : $InstallDir
  Branch         : $Branch
  Commit         : $commitHash

  Starten:
    Dubbelklik   : AnanCore.bat
    Met browser  : AnanCore-OpenBrowser.bat
    Handmatig    : $releaseDir\backend\OpenhpsdrZeus.exe

  Interface: http://localhost:6060

  Updaten:
    .\Update-AnanCore.ps1

"@ -ForegroundColor Green
