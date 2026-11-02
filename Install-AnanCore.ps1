#Requires -Version 5.1
<#
.SYNOPSIS
    AnanCore Windows Portable Installer
.DESCRIPTION
    Cloned ChasingCoffee/AnanCore, bouwt de .NET backend en de Vite frontend,
    en pakt alles in als een portable Windows distributie in de 'dist\' map
    naast dit script.

    Vereisten: Git, .NET 10 SDK, Node.js 20+

.PARAMETER Branch
    Git branch om te clonen (default: freedv-in-core)
.PARAMETER SkipBuild
    Sla het bouwen over (alleen clonen)
.PARAMETER SkipDependencyCheck
    Sla de controle op vereisten over
.EXAMPLE
    .\Install-AnanCore.ps1
    .\Install-AnanCore.ps1 -Branch main
#>
[CmdletBinding()]
param(
    [string]$Branch = "freedv-in-core",
    [switch]$SkipBuild,
    [switch]$SkipDependencyCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Helpers ──────────────────────────────────────────────────────────────────
function Write-Header  { param($msg) Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok      { param($msg) Write-Host "  OK  $msg" -ForegroundColor Green }
function Write-Warn    { param($msg) Write-Host " WARN $msg" -ForegroundColor Yellow }
function Write-Fail    { param($msg) Write-Host "`n FAIL $msg`n" -ForegroundColor Red; exit 1 }

Write-Host @"

  ╔══════════════════════════════════════════════════════╗
  ║    AnanCore  —  Windows Portable Installer           ║
  ║    https://github.com/ChasingCoffee/AnanCore         ║
  ╚══════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ── Paden — alles relatief aan de scriptmap ───────────────────────────────────
$scriptDir = $PSScriptRoot
$srcDir    = Join-Path $scriptDir "src"
$distDir   = Join-Path $scriptDir "dist"

# ── Vereisten controleren ────────────────────────────────────────────────────
if (-not $SkipDependencyCheck) {
    Write-Header "Vereisten controleren"

    $gitVer = git --version 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Fail "Git niet gevonden. Download: https://git-scm.com/download/win" }
    Write-Ok "Git: $gitVer"

    $dotnetVer = dotnet --version 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Fail ".NET SDK niet gevonden. Download: https://dotnet.microsoft.com/download/dotnet/10.0" }
    if (([int]($dotnetVer -split '\.')[0]) -lt 10) {
        Write-Warn ".NET $dotnetVer gevonden — AnanCore vereist .NET 10. Download: https://dotnet.microsoft.com/download/dotnet/10.0"
        if ((Read-Host "  Toch doorgaan? (j/n)") -notmatch '^[jJ]') { exit 1 }
    } else {
        Write-Ok ".NET SDK: $dotnetVer"
    }

    $nodeVer = node --version 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Fail "Node.js niet gevonden. Download: https://nodejs.org/" }
    if (([int](($nodeVer -replace 'v','') -split '\.')[0]) -lt 20) {
        Write-Warn "Node.js $nodeVer gevonden — versie 20+ aanbevolen"
    } else {
        Write-Ok "Node.js: $nodeVer"
    }

    $npmVer = npm --version 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Fail "npm niet gevonden (hoort bij Node.js)" }
    Write-Ok "npm: $npmVer"
}

# ── Clone of update AnanCore broncode ────────────────────────────────────────
Write-Header "AnanCore broncode ophalen (branch: $Branch)"

if (Test-Path (Join-Path $srcDir ".git")) {
    Write-Host "  Bestaande repo updaten..."
    Push-Location $srcDir
    try {
        git fetch --all --prune 2>&1 | Out-Null
        git checkout $Branch 2>&1 | Out-Null
        git pull --rebase 2>&1 | Out-Null
        Write-Ok "Broncode bijgewerkt"
    } finally { Pop-Location }
} else {
    if (Test-Path $srcDir) { Remove-Item $srcDir -Recurse -Force }
    Write-Host "  Cloning https://github.com/ChasingCoffee/AnanCore ..."
    git clone --branch $Branch --recurse-submodules --depth 1 `
        "https://github.com/ChasingCoffee/AnanCore.git" $srcDir
    if ($LASTEXITCODE -ne 0) { Write-Fail "Clone mislukt" }
    Write-Ok "Broncode gecloned naar: src\"
}

if ($SkipBuild) {
    Write-Warn "Build overgeslagen (-SkipBuild). Broncode staat in: src\"
    exit 0
}

# ── dist\ opschonen ───────────────────────────────────────────────────────────
Write-Header "dist\ voorbereiden"
if (Test-Path $distDir) {
    Remove-Item $distDir -Recurse -Force
    Write-Ok "Vorige dist\ verwijderd"
}
New-Item -ItemType Directory -Path $distDir | Out-Null

# ── .NET backend bouwen ──────────────────────────────────────────────────────
Write-Header ".NET backend bouwen (win-x64, self-contained)"
Push-Location $srcDir
try {
    Write-Host "  dotnet restore..."
    dotnet restore Zeus.slnx --verbosity quiet
    if ($LASTEXITCODE -ne 0) { Write-Fail "dotnet restore mislukt" }

    Write-Host "  dotnet publish..."
    dotnet publish OpenhpsdrZeus `
        --configuration Release `
        --runtime win-x64 `
        --self-contained true `
        --output $distDir `
        -p:PublishSingleFile=false `
        -p:PublishReadyToRun=true `
        --verbosity quiet
    if ($LASTEXITCODE -ne 0) { Write-Fail "dotnet publish mislukt" }
    Write-Ok "Backend gepubliceerd"
} finally { Pop-Location }

# ── Vite frontend bouwen ─────────────────────────────────────────────────────
Write-Header "Vite frontend bouwen"
$webSrc = Join-Path $srcDir "zeus-web"
Push-Location $webSrc
try {
    Write-Host "  npm install..."
    npm install --prefer-offline --silent
    if ($LASTEXITCODE -ne 0) { Write-Fail "npm install mislukt" }

    Write-Host "  npm run build..."
    $env:VITE_API_BASE = ""
    npm run build --silent
    if ($LASTEXITCODE -ne 0) { Write-Fail "npm run build mislukt" }

    # dist/ → naast de backend in dist\wwwroot\
    $wwwroot = Join-Path $distDir "wwwroot"
    New-Item -ItemType Directory -Path $wwwroot -Force | Out-Null
    Copy-Item -Path (Join-Path $webSrc "dist\*") -Destination $wwwroot -Recurse -Force
    Write-Ok "Frontend gebouwd en gekopieerd naar dist\wwwroot\"
} finally { Pop-Location }

# ── Versie info opslaan ──────────────────────────────────────────────────────
$commitHash = git -C $srcDir rev-parse --short HEAD 2>&1
$commitDate = git -C $srcDir log -1 --format="%ci" 2>&1
@{
    built_at       = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    branch         = $Branch
    commit         = "$commitHash"
    commit_date    = "$commitDate"
    dotnet_version = "$(dotnet --version 2>&1)"
    node_version   = "$(node --version 2>&1)"
} | ConvertTo-Json | Set-Content (Join-Path $distDir "version.json") -Encoding UTF8

# ── Start script in dist\ ─────────────────────────────────────────────────────
Write-Header "Start script aanmaken"

@"
@echo off
title AnanCore
cd /d "%~dp0"
echo.
echo  AnanCore starten op http://localhost:6060
echo  Open je browser: http://localhost:6060
echo  Sluit dit venster om te stoppen.
echo.
OpenhpsdrZeus.exe
"@ | Set-Content (Join-Path $distDir "Start-AnanCore.bat") -Encoding UTF8
Write-Ok "dist\Start-AnanCore.bat aangemaakt"

# ── Klaar ─────────────────────────────────────────────────────────────────────
Write-Host @"

  ╔══════════════════════════════════════════════════════╗
  ║    Build voltooid!                                   ║
  ╚══════════════════════════════════════════════════════╝

  Distributie map : dist\
  Commit          : $commitHash  ($Branch)

  Starten         : dist\Start-AnanCore.bat
  Interface       : http://localhost:6060

  Distribueren    : zip de volledige dist\ map en stuur door.

"@ -ForegroundColor Green
