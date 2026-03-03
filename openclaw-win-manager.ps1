#requires -Version 5.1
<#
OpenClaw Windows 10/11 standalone manager (ASCII-safe for PowerShell 5.1)
Run:
  Set-ExecutionPolicy -Scope Process Bypass -Force
  .\openclaw-win-manager.ps1
#>

$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function OK($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Err($m){ Write-Host "[ERR ] $m" -ForegroundColor Red }
function PauseBack { ""; Read-Host "Press Enter to continue" | Out-Null }

function HasCmd($n){ return [bool](Get-Command $n -ErrorAction SilentlyContinue) }
function OC([string]$args){
  try { Invoke-Expression "openclaw $args" }
  catch { Err "openclaw $args failed"; Err $_.Exception.Message }
}

function ConfigPath { Join-Path $env:USERPROFILE ".openclaw\openclaw.json" }

function InstallStatus { if(HasCmd "openclaw"){"Installed"}else{"Not installed"} }
function RunningStatus {
  try {
    $out = & openclaw gateway status 2>$null | Out-String
    if($out -match 'running|online|active'){ return "Running" }
  } catch {}
  return "Stopped"
}

function LocalVersion {
  try {
    $t = (& npm list -g openclaw --depth=0 --no-update-notifier 2>$null | Out-String)
    $m = [regex]::Match($t,'openclaw@([0-9A-Za-z\.-]+)')
    if($m.Success){ return $m.Groups[1].Value }
  } catch {}
  return $null
}

function LatestVersion {
  try {
    $v = (& npm view openclaw version --no-update-notifier 2>$null).Trim()
    if($v){ return $v }
  } catch {}
  return $null
}

function ShowMenu {
  Clear-Host
  $ins = InstallStatus
  $run = RunningStatus
  $lv = LocalVersion
  $rv = LatestVersion
  $verMsg = "Version unknown"
  if($lv -and $rv){
    if($lv -ne $rv){ $verMsg = "Update available: $rv (current $lv)" }
    else { $verMsg = "Latest: $lv" }
  }

  Write-Host "==========================================="
  Write-Host "OpenClaw Windows Manager"
  Write-Host "Status: $ins | $run | $verMsg"
  Write-Host "==========================================="
  Write-Host "1. Install OpenClaw"
  Write-Host "2. Start OpenClaw"
  Write-Host "3. Stop OpenClaw"
  Write-Host "4. Restart OpenClaw"
  Write-Host "5. Status + Logs"
  Write-Host "6. Switch model"
  Write-Host "7. Add provider (auto models import)"
  Write-Host "8. Pairing (Telegram/Feishu/WhatsApp)"
  Write-Host "9. Install plugin"
  Write-Host "10. Install skill (clawhub)"
  Write-Host "11. Edit config file"
  Write-Host "12. Run onboard"
  Write-Host "13. Run doctor --fix"
  Write-Host "14. Show WebUI URL"
  Write-Host "15. Update OpenClaw"
  Write-Host "16. Uninstall OpenClaw"
  Write-Host "0. Exit"
  Write-Host "-------------------------------------------"
}

function InstallNodeIfNeeded {
  if(HasCmd "node"){ OK "Node.js found: $(& node -v)"; return }
  Info "Node.js not found, trying auto-install"

  if(HasCmd "winget"){
    & winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements
    return
  }
  if(HasCmd "choco"){ & choco install nodejs-lts -y; return }
  if(HasCmd "scoop"){ & scoop install nodejs-lts; return }

  throw "No winget/choco/scoop found. Install Node.js 20+ manually first."
}

function InstallOpenClaw {
  try {
    InstallNodeIfNeeded
    if(-not (HasCmd "npm")){ throw "npm not found after Node install" }
    Info "Installing openclaw..."
    & npm install -g openclaw@latest
    Info "Running onboard..."
    OC "onboard --install-daemon"
    OC "gateway restart"
    OK "Install done"
  } catch { Err $_.Exception.Message }
  PauseBack
}

function StartOpenClaw { OC "gateway start"; PauseBack }
function StopOpenClaw { OC "gateway stop"; PauseBack }
function RestartOpenClaw { OC "gateway restart"; PauseBack }

function ShowStatusLogs {
  Write-Host "`n=== openclaw status ===" -ForegroundColor Magenta
  OC "status"
  Write-Host "`n=== gateway status ===" -ForegroundColor Magenta
  OC "gateway status"
  Write-Host "`n=== openclaw logs ===" -ForegroundColor Magenta
  OC "logs"
  PauseBack
}

function SwitchModel {
  try {
    Write-Host "`n--- all models ---" -ForegroundColor Magenta
    OC "models list --all"
    Write-Host "`n--- current model ---" -ForegroundColor Magenta
    OC "models list"
    $m = Read-Host "Target model (provider/model), 0 to cancel"
    if(-not $m -or $m -eq '0'){ return }
    OC "models set $m"
    OK "Model switched: $m"
  } catch { Err $_.Exception.Message }
  PauseBack
}

function ModelCost([string]$id){
  $in=0.15; $out=0.60
  if($id -match 'opus|pro|preview|thinking|sonnet'){ $in=2.00; $out=12.00 }
  elseif($id -match 'gpt-5|codex'){ $in=1.25; $out=10.00 }
  elseif($id -match 'flash|lite|haiku|mini|nano'){ $in=0.10; $out=0.40 }
  return @{ input=$in; output=$out; cacheRead=0; cacheWrite=0 }
}

function AddProvider {
  try {
    $provider = Read-Host "Provider name"
    if(-not $provider){ throw "Provider name is required" }
    $base = Read-Host "Base URL (e.g. https://api.xxx.com/v1)"
    if(-not $base){ throw "Base URL is required" }
    $base = $base.TrimEnd('/')
    $key = Read-Host "API key"
    if(-not $key){ throw "API key is required" }

    Info "Fetching models from $base/models ..."
    $resp = Invoke-RestMethod -Uri "$base/models" -Headers @{Authorization="Bearer $key"} -TimeoutSec 30
    $ids = @($resp.data | ForEach-Object { $_.id } | Where-Object { $_ } | Sort-Object -Unique)
    if($ids.Count -eq 0){ throw "No models found" }

    for($i=0;$i -lt $ids.Count;$i++){ Write-Host "[$($i+1)] $($ids[$i])" }
    $pick = Read-Host "Default model (index or id, blank=first)"
    $default = $ids[0]
    if($pick){
      if($pick -match '^\d+$'){
        $ix=[int]$pick-1
        if($ix -ge 0 -and $ix -lt $ids.Count){ $default=$ids[$ix] }
      } else { $default = $pick }
    }

    $cfg = ConfigPath
    if(-not (Test-Path $cfg)){ throw "Config not found: $cfg. Run onboard first." }

    Copy-Item $cfg "$cfg.bak.$([DateTimeOffset]::Now.ToUnixTimeSeconds())" -Force
    $json = Get-Content $cfg -Raw | ConvertFrom-Json

    if(-not $json.models){ $json | Add-Member -NotePropertyName models -NotePropertyValue (@{}) }
    $json.models.mode = 'merge'
    if(-not $json.models.providers){ $json.models | Add-Member -NotePropertyName providers -NotePropertyValue (@{}) }

    $models = @()
    foreach($id in $ids){
      $models += [pscustomobject]@{
        id=$id
        name="$provider / $id"
        input=@('text','image')
        contextWindow=1048576
        maxTokens=128000
        cost=(ModelCost $id)
      }
    }

    $json.models.providers.$provider = [pscustomobject]@{
      baseUrl=$base
      apiKey=$key
      api='openai-completions'
      models=$models
    }

    $json | ConvertTo-Json -Depth 20 | Set-Content -Path $cfg -Encoding UTF8
    OC "models set $provider/$default"
    OC "gateway restart"
    OK "Provider added: $provider, default model: $provider/$default"
  } catch { Err $_.Exception.Message }
  PauseBack
}

function PairingMenu {
  while($true){
    Clear-Host
    Write-Host "=== Pairing ==="
    Write-Host "1. Telegram"
    Write-Host "2. Feishu/Lark"
    Write-Host "3. WhatsApp"
    Write-Host "0. Back"
    $c = Read-Host "Select"
    switch($c){
      '1' { $code=Read-Host "Telegram code"; if($code){ OC "pairing approve telegram $code"; PauseBack } }
      '2' { $code=Read-Host "Feishu code"; if($code){ OC "pairing approve feishu $code"; PauseBack } }
      '3' { $code=Read-Host "WhatsApp code"; if($code){ OC "pairing approve whatsapp $code"; PauseBack } }
      '0' { return }
      default { Warn "Invalid"; Start-Sleep -Milliseconds 600 }
    }
  }
}

function InstallPlugin {
  try {
    OC "plugins list"
    $p = Read-Host "Plugin id (e.g. telegram/feishu/@openclaw/discord), 0 cancel"
    if(-not $p -or $p -eq '0'){ return }
    $id = $p -replace '^@openclaw/',''
    OC "plugins enable $id"
    OC "plugins install $p"
    OC "plugins enable $id"
    OC "gateway restart"
    OK "Plugin processed: $p"
  } catch { Err $_.Exception.Message }
  PauseBack
}

function InstallSkill {
  try {
    OC "skills list"
    $s = Read-Host "Skill name, 0 cancel"
    if(-not $s -or $s -eq '0'){ return }
    if(-not (HasCmd "npx")){ throw "npx not found" }
    & npx clawhub install $s
    OC "gateway restart"
    OK "Skill installed: $s"
  } catch { Err $_.Exception.Message }
  PauseBack
}

function EditConfig {
  $p = ConfigPath
  if(-not (Test-Path $p)){ Warn "Config not found: $p"; PauseBack; return }
  notepad $p
  Info "Restart gateway to apply changes"
  PauseBack
}

function RunOnboard { OC "onboard --install-daemon"; PauseBack }
function RunDoctor { OC "doctor --fix"; PauseBack }

function ShowWebUI {
  try {
    $o = (& openclaw dashboard 2>$null | Out-String)
    $m = [regex]::Match($o,'#token=([a-f0-9]+)')
    if($m.Success){
      $t = $m.Groups[1].Value
      Write-Host "http://127.0.0.1:18789/#token=$t" -ForegroundColor Green
    } else {
      Write-Host $o
    }
  } catch { Err $_.Exception.Message }
  PauseBack
}

function UpdateOpenClaw {
  try {
    InstallNodeIfNeeded
    & npm install -g openclaw@latest
    OC "gateway restart"
    OK "Update done"
  } catch { Err $_.Exception.Message }
  PauseBack
}

function UninstallOpenClaw {
  try {
    OC "uninstall"
    if(HasCmd "npm"){ & npm uninstall -g openclaw }
    OK "Uninstalled"
  } catch { Err $_.Exception.Message }
  PauseBack
}

while($true){
  ShowMenu
  $c = Read-Host "Select"
  switch($c){
    '1' { InstallOpenClaw }
    '2' { StartOpenClaw }
    '3' { StopOpenClaw }
    '4' { RestartOpenClaw }
    '5' { ShowStatusLogs }
    '6' { SwitchModel }
    '7' { AddProvider }
    '8' { PairingMenu }
    '9' { InstallPlugin }
    '10' { InstallSkill }
    '11' { EditConfig }
    '12' { RunOnboard }
    '13' { RunDoctor }
    '14' { ShowWebUI }
    '15' { UpdateOpenClaw }
    '16' { UninstallOpenClaw }
    '0' { break }
    default { Warn "Invalid option"; Start-Sleep -Milliseconds 500 }
  }
}
