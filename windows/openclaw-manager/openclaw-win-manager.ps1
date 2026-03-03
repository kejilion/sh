#requires -Version 5.1
<#
OpenClaw Windows 10/11 独立管理脚本（中文版）
运行：
  Set-ExecutionPolicy -Scope Process Bypass -Force
  .\openclaw-win-manager.ps1
#>

$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "[信息] $m" -ForegroundColor Cyan }
function OK($m){ Write-Host "[完成] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[警告] $m" -ForegroundColor Yellow }
function Err($m){ Write-Host "[错误] $m" -ForegroundColor Red }
function PauseBack { ""; Read-Host "按回车继续" | Out-Null }

function HasCmd($n){ return [bool](Get-Command $n -ErrorAction SilentlyContinue) }
function OC([string]$args){
  try { Invoke-Expression "openclaw $args" }
  catch { Err "openclaw $args 执行失败"; Err $_.Exception.Message }
}

function ConfigPath { Join-Path $env:USERPROFILE ".openclaw\openclaw.json" }

function InstallStatus { if(HasCmd "openclaw"){"已安装"}else{"未安装"} }
function RunningStatus {
  try {
    $out = & openclaw gateway status 2>$null | Out-String
    if($out -match 'running|online|active|运行'){ return "运行中" }
  } catch {}
  return "未运行"
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
  $verMsg = "版本未知"
  if($lv -and $rv){
    if($lv -ne $rv){ $verMsg = "可更新: $rv (当前 $lv)" }
    else { $verMsg = "已是最新: $lv" }
  }

  Write-Host "==========================================="
  Write-Host "OpenClaw Windows 管理"
  Write-Host "状态: $ins | $run | $verMsg"
  Write-Host "==========================================="
  Write-Host "1. 安装 OpenClaw"
  Write-Host "2. 启动 OpenClaw"
  Write-Host "3. 停止 OpenClaw"
  Write-Host "4. 重启 OpenClaw"
  Write-Host "5. 状态与日志"
  Write-Host "6. 切换模型"
  Write-Host "7. 添加 Provider（自动导入模型）"
  Write-Host "8. 机器人配对（Telegram/飞书/WhatsApp）"
  Write-Host "9. 安装插件"
  Write-Host "10. 安装技能（clawhub）"
  Write-Host "11. 编辑配置文件"
  Write-Host "12. 执行 onboard"
  Write-Host "13. 执行 doctor --fix"
  Write-Host "14. 查看 WebUI 地址"
  Write-Host "15. 更新 OpenClaw"
  Write-Host "16. 卸载 OpenClaw"
  Write-Host "0. 退出"
  Write-Host "-------------------------------------------"
}

function InstallNodeIfNeeded {
  if(HasCmd "node"){ OK "检测到 Node.js: $(& node -v)"; return }
  Info "未检测到 Node.js，尝试自动安装"

  if(HasCmd "winget"){
    & winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements
    return
  }
  if(HasCmd "choco"){ & choco install nodejs-lts -y; return }
  if(HasCmd "scoop"){ & scoop install nodejs-lts; return }

  throw "未检测到 winget/choco/scoop，请先手动安装 Node.js 20+"
}

function InstallOpenClaw {
  try {
    InstallNodeIfNeeded
    if(-not (HasCmd "npm")){ throw "npm 不可用" }
    Info "正在安装 openclaw..."
    & npm install -g openclaw@latest
    Info "正在执行 onboard..."
    OC "onboard --install-daemon"
    OC "gateway restart"
    OK "安装完成"
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
    Write-Host "`n--- 所有模型 ---" -ForegroundColor Magenta
    OC "models list --all"
    Write-Host "`n--- 当前模型 ---" -ForegroundColor Magenta
    OC "models list"
    $m = Read-Host "输入目标模型(provider/model)，输入0取消"
    if(-not $m -or $m -eq '0'){ return }
    OC "models set $m"
    OK "模型已切换: $m"
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
    $provider = Read-Host "输入 Provider 名称"
    if(-not $provider){ throw "Provider 不能为空" }
    $base = Read-Host "输入 Base URL（如 https://api.xxx.com/v1）"
    if(-not $base){ throw "Base URL 不能为空" }
    $base = $base.TrimEnd('/')
    $key = Read-Host "输入 API Key"
    if(-not $key){ throw "API Key 不能为空" }

    Info "正在获取模型列表: $base/models"
    $resp = Invoke-RestMethod -Uri "$base/models" -Headers @{Authorization="Bearer $key"} -TimeoutSec 30
    $ids = @($resp.data | ForEach-Object { $_.id } | Where-Object { $_ } | Sort-Object -Unique)
    if($ids.Count -eq 0){ throw "未获取到模型" }

    for($i=0;$i -lt $ids.Count;$i++){ Write-Host "[$($i+1)] $($ids[$i])" }
    $pick = Read-Host "输入默认模型（序号或ID，留空=第一个）"
    $default = $ids[0]
    if($pick){
      if($pick -match '^\d+$'){
        $ix=[int]$pick-1
        if($ix -ge 0 -and $ix -lt $ids.Count){ $default=$ids[$ix] }
      } else { $default = $pick }
    }

    $cfg = ConfigPath
    if(-not (Test-Path $cfg)){ throw "配置不存在: $cfg，请先执行 onboard" }

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
    OK "Provider 添加完成，默认模型: $provider/$default"
  } catch { Err $_.Exception.Message }
  PauseBack
}

function PairingMenu {
  while($true){
    Clear-Host
    Write-Host "=== 机器人配对 ==="
    Write-Host "1. Telegram"
    Write-Host "2. 飞书"
    Write-Host "3. WhatsApp"
    Write-Host "0. 返回"
    $c = Read-Host "请选择"
    switch($c){
      '1' { $code=Read-Host "输入 Telegram 连接码"; if($code){ OC "pairing approve telegram $code"; PauseBack } }
      '2' { $code=Read-Host "输入飞书连接码"; if($code){ OC "pairing approve feishu $code"; PauseBack } }
      '3' { $code=Read-Host "输入 WhatsApp 连接码"; if($code){ OC "pairing approve whatsapp $code"; PauseBack } }
      '0' { return }
      default { Warn "无效选项"; Start-Sleep -Milliseconds 600 }
    }
  }
}

function InstallPlugin {
  try {
    OC "plugins list"
    $p = Read-Host "输入插件ID（如 telegram/feishu/@openclaw/discord），0取消"
    if(-not $p -or $p -eq '0'){ return }
    $id = $p -replace '^@openclaw/',''
    OC "plugins enable $id"
    OC "plugins install $p"
    OC "plugins enable $id"
    OC "gateway restart"
    OK "插件处理完成: $p"
  } catch { Err $_.Exception.Message }
  PauseBack
}

function InstallSkill {
  try {
    OC "skills list"
    $s = Read-Host "输入技能名，0取消"
    if(-not $s -or $s -eq '0'){ return }
    if(-not (HasCmd "npx")){ throw "npx 不可用" }
    & npx clawhub install $s
    OC "gateway restart"
    OK "技能安装完成: $s"
  } catch { Err $_.Exception.Message }
  PauseBack
}

function EditConfig {
  $p = ConfigPath
  if(-not (Test-Path $p)){ Warn "配置不存在: $p"; PauseBack; return }
  notepad $p
  Info "如已修改配置，请重启网关生效"
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
    OK "更新完成"
  } catch { Err $_.Exception.Message }
  PauseBack
}

function UninstallOpenClaw {
  try {
    OC "uninstall"
    if(HasCmd "npm"){ & npm uninstall -g openclaw }
    OK "卸载完成"
  } catch { Err $_.Exception.Message }
  PauseBack
}

while($true){
  ShowMenu
  $c = Read-Host "请选择"
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
    default { Warn "无效选项"; Start-Sleep -Milliseconds 500 }
  }
}
