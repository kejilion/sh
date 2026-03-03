# OpenClaw Windows bootstrap (ASCII-safe)
# Usage:
#   Set-ExecutionPolicy -Scope Process Bypass -Force; iwr -useb https://raw.githubusercontent.com/kejilion/sh/main/windows/openclaw-manager/install.ps1 | iex

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$managerUrl = 'https://raw.githubusercontent.com/kejilion/sh/main/windows/openclaw-manager/openclaw-win-manager.ps1'
$managerUrl = "$managerUrl?ts=$([DateTimeOffset]::Now.ToUnixTimeSeconds())"
$targetDir  = Join-Path $env:ProgramData 'kejilion\openclaw'
$targetFile = Join-Path $targetDir 'openclaw-win-manager.ps1'

Write-Host '[INFO] Preparing directories...' -ForegroundColor Cyan
New-Item -ItemType Directory -Path $targetDir -Force | Out-Null

Write-Host '[INFO] Downloading latest manager script...' -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Headers @{ 'Cache-Control'='no-cache' } -Uri $managerUrl -OutFile $targetFile

if ((Get-Item $targetFile).Length -lt 2000) {
  throw 'Downloaded file is too small, abort.'
}

$raw = Get-Content -Path $targetFile -Raw
if ($raw -notmatch 'OpenClaw Windows 管理') {
  throw 'Downloaded manager is not the latest Chinese build, abort.'
}

Write-Host '[INFO] Starting OpenClaw Windows Manager...' -ForegroundColor Cyan
powershell -NoProfile -ExecutionPolicy Bypass -File $targetFile
