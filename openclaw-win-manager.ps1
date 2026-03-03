#requires -Version 5.1
<#!
.SYNOPSIS
  OpenClaw Windows 10/11 独立管理脚本
.DESCRIPTION
  参考 kejilion.sh 中 OpenClaw 管理设计理念，提供 Windows 版交互式管理：
  - 安装/启动/停止/状态日志
  - 模型切换/Provider 注入
  - 插件与技能安装
  - 机器人配对
  - 配置文件编辑、健康修复、更新、卸载

  推荐在 PowerShell（管理员）运行：
  Set-ExecutionPolicy -Scope Process Bypass
  .\openclaw-win-manager.ps1
#>

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-OK($msg)   { Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[ERR ] $msg" -ForegroundColor Red }

function Pause-Return {
  Write-Host ""
  Read-Host "按回车继续"
}

function Test-Command($name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Invoke-OpenClaw {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Args
  )
  try {
    Invoke-Expression "openclaw $Args"
  } catch {
    Write-Err "命令执行失败: openclaw $Args"
    Write-Err $_.Exception.Message
  }
}

function Get-ConfigPath {
  return Join-Path $env:USERPROFILE ".openclaw\openclaw.json"
}

function Get-InstallStatus {
  if (Test-Command "openclaw") { return "已安装" }
  return "未安装"
}

function Get-RunningStatus {
  try {
    $out = & openclaw gateway status 2>$null | Out-String
    if ($out -match 'running|online|active|运行') { return "运行中" }
  } catch {}
  return "未运行"
}

function Get-OpenClawVersion {
  try {
    $local = (& npm list -g openclaw --depth=0 --no-update-notifier 2>$null | Out-String)
    $m = [regex]::Match($local, 'openclaw@([0-9A-Za-z\.-]+)')
    if ($m.Success) { return $m.Groups[1].Value }
  } catch {}
  return $null
}

function Get-OpenClawLatestVersion {
  try {
    $remote = (& npm view openclaw version --no-update-notifier 2>$null).Trim()
    if ($remote) { return $remote }
  } catch {}
  return $null
}

function Show-Banner {
  Clear-Host
  $install = Get-InstallStatus
  $running = Get-RunningStatus
  $local = Get-OpenClawVersion
  $latest = Get-OpenClawLatestVersion

  $updateMsg = "版本信息未知"
  if ($local -and $latest) {
    if ($local -ne $latest) { $updateMsg = "检测到新版本: $latest (当前: $local)" }
    else { $updateMsg = "当前已是最新: $local" }
  }

  Write-Host "==========================================="
  Write-Host "ClawdBot > MoltBot > OpenClaw 管理 (Win)"
  Write-Host "状态: $install | $running | $updateMsg"
  Write-Host "==========================================="
  Write-Host "1.  安装 OpenClaw"
  Write-Host "2.  启动 OpenClaw"
  Write-Host "3.  停止 OpenClaw"
  Write-Host "4.  重启 OpenClaw"
  Write-Host "---------------------------"
  Write-Host "5.  状态与日志"
  Write-Host "6.  切换模型"
  Write-Host "7.  添加 Provider（自动注入模型）"
  Write-Host "8.  机器人连接对接"
  Write-Host "9.  安装插件"
  Write-Host "10. 安装技能（clawhub）"
  Write-Host "11. 编辑主配置 openclaw.json"
  Write-Host "12. 配置向导 (onboard)"
  Write-Host "13. 健康检测与修复"
  Write-Host "14. 查看 WebUI 地址"
  Write-Host "---------------------------"
  Write-Host "15. 更新 OpenClaw"
  Write-Host "16. 卸载 OpenClaw"
  Write-Host "0.  退出"
  Write-Host "---------------------------"
}

function Install-NodeIfNeeded {
  if (Test-Command "node") {
    Write-OK "Node.js 已存在: $(& node -v)"
    return
  }

  Write-Info "未检测到 Node.js，尝试自动安装..."
  if (Test-Command "winget") {
    Write-Info "使用 winget 安装 Node.js (LTS)"
    & winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements
    return
  }

  if (Test-Command "choco") {
    Write-Info "使用 Chocolatey 安装 Node.js"
    & choco install nodejs-lts -y
    return
  }

  if (Test-Command "scoop") {
    Write-Info "使用 Scoop 安装 Node.js"
    & scoop install nodejs-lts
    return
  }

  throw "未找到 winget/choco/scoop，无法自动安装 Node.js，请先手动安装 Node.js 20+"
}

function Install-OpenClaw {
  try {
    Install-NodeIfNeeded

    if (-not (Test-Command "npm")) {
      throw "npm 不可用，请确认 Node.js 安装成功。"
    }

    Write-Info "安装 OpenClaw..."
    & npm install -g openclaw@latest

    Write-Info "运行初始化向导（安装守护进程）..."
    Invoke-OpenClaw "onboard --install-daemon"

    Write-Info "启动网关..."
    Invoke-OpenClaw "gateway restart"

    Write-OK "安装完成。"
  }
  catch {
    Write-Err $_.Exception.Message
  }
  Pause-Return
}

function Start-OpenClaw {
  Invoke-OpenClaw "gateway start"
  Pause-Return
}

function Stop-OpenClaw {
  Invoke-OpenClaw "gateway stop"
  Pause-Return
}

function Restart-OpenClaw {
  Invoke-OpenClaw "gateway restart"
  Pause-Return
}

function Show-StatusLogs {
  Write-Host "\n===== openclaw status =====" -ForegroundColor Magenta
  Invoke-OpenClaw "status"
  Write-Host "\n===== gateway status =====" -ForegroundColor Magenta
  Invoke-OpenClaw "gateway status"
  Write-Host "\n===== openclaw logs =====" -ForegroundColor Magenta
  Invoke-OpenClaw "logs"
  Pause-Return
}

function Change-Model {
  try {
    Write-Host "\n--- 所有可用模型 ---" -ForegroundColor Magenta
    Invoke-OpenClaw "models list --all"
    Write-Host "\n--- 当前模型 ---" -ForegroundColor Magenta
    Invoke-OpenClaw "models list"

    $model = Read-Host "请输入目标模型（示例: provider/model，输入 0 取消）"
    if ($model -eq '0' -or [string]::IsNullOrWhiteSpace($model)) { return }

    Invoke-OpenClaw "models set $model"
    Write-OK "已切换模型: $model"
  }
  catch {
    Write-Err $_.Exception.Message
  }
  Pause-Return
}

function Build-ModelCost {
  param([string]$modelId)

  $input = 0.15
  $output = 0.60

  if ($modelId -match 'opus|pro|preview|thinking|sonnet') {
    $input = 2.00; $output = 12.00
  }
  elseif ($modelId -match 'gpt-5|codex') {
    $input = 1.25; $output = 10.00
  }
  elseif ($modelId -match 'flash|lite|haiku|mini|nano') {
    $input = 0.10; $output = 0.40
  }

  return @{ input = $input; output = $output; cacheRead = 0; cacheWrite = 0 }
}

function Add-ProviderInteractive {
  try {
    $provider = Read-Host "请输入 Provider 名称（例如 deepseek）"
    if ([string]::IsNullOrWhiteSpace($provider)) { throw "Provider 名称不能为空" }

    $baseUrl = Read-Host "请输入 Base URL（例如 https://api.xxx.com/v1）"
    if ([string]::IsNullOrWhiteSpace($baseUrl)) { throw "Base URL 不能为空" }
    $baseUrl = $baseUrl.TrimEnd('/')

    $apiKey = Read-Host "请输入 API Key"
    if ([string]::IsNullOrWhiteSpace($apiKey)) { throw "API Key 不能为空" }

    Write-Info "正在获取模型列表: $baseUrl/models"
    $headers = @{ Authorization = "Bearer $apiKey" }
    $resp = Invoke-RestMethod -Uri "$baseUrl/models" -Headers $headers -Method Get -TimeoutSec 30

    if (-not $resp.data) { throw "未获取到模型列表。" }

    $modelIds = @($resp.data | ForEach-Object { $_.id } | Where-Object { $_ } | Sort-Object -Unique)
    if ($modelIds.Count -eq 0) { throw "模型列表为空。" }

    Write-OK "发现 $($modelIds.Count) 个模型："
    for ($i = 0; $i -lt $modelIds.Count; $i++) {
      Write-Host "[$($i+1)] $($modelIds[$i])"
    }

    $defaultInput = Read-Host "请输入默认模型（序号或ID，留空默认第一个）"
    $defaultModel = $modelIds[0]
    if (-not [string]::IsNullOrWhiteSpace($defaultInput)) {
      if ($defaultInput -match '^\d+$') {
        $idx = [int]$defaultInput - 1
        if ($idx -ge 0 -and $idx -lt $modelIds.Count) { $defaultModel = $modelIds[$idx] }
      } else {
        $defaultModel = $defaultInput
      }
    }

    $configPath = Get-ConfigPath
    if (-not (Test-Path $configPath)) {
      throw "配置文件不存在: $configPath，请先执行一次 openclaw onboard --install-daemon"
    }

    $backup = "$configPath.bak.$([DateTimeOffset]::Now.ToUnixTimeSeconds())"
    Copy-Item $configPath $backup -Force
    Write-Info "已备份配置: $backup"

    $json = Get-Content $configPath -Raw | ConvertFrom-Json

    if (-not $json.models) {
      $json | Add-Member -MemberType NoteProperty -Name models -Value (@{})
    }

    $json.models.mode = 'merge'
    if (-not $json.models.providers) {
      $json.models | Add-Member -MemberType NoteProperty -Name providers -Value (@{})
    }

    $models = @()
    foreach ($m in $modelIds) {
      $models += [PSCustomObject]@{
        id = $m
        name = "$provider / $m"
        input = @('text', 'image')
        contextWindow = 1048576
        maxTokens = 128000
        cost = (Build-ModelCost -modelId $m)
      }
    }

    $json.models.providers.$provider = [PSCustomObject]@{
      baseUrl = $baseUrl
      apiKey = $apiKey
      api = 'openai-completions'
      models = $models
    }

    $json | ConvertTo-Json -Depth 20 | Set-Content -Path $configPath -Encoding UTF8
    Write-OK "Provider [$provider] 已注入，模型数量: $($modelIds.Count)"

    Invoke-OpenClaw "models set $provider/$defaultModel"
    Invoke-OpenClaw "gateway restart"
    Write-OK "默认模型已设置为: $provider/$defaultModel"
  }
  catch {
    Write-Err $_.Exception.Message
  }
  Pause-Return
}

function Pairing-Menu {
  while ($true) {
    Clear-Host
    Write-Host "=== 机器人连接对接 ==="
    Write-Host "1. Telegram"
    Write-Host "2. 飞书 (Feishu/Lark)"
    Write-Host "3. WhatsApp"
    Write-Host "0. 返回"
    $c = Read-Host "请选择"

    switch ($c) {
      '1' {
        $code = Read-Host "请输入 Telegram 连接码"
        if ($code) { Invoke-OpenClaw "pairing approve telegram $code"; Pause-Return }
      }
      '2' {
        $code = Read-Host "请输入 Feishu 连接码"
        if ($code) { Invoke-OpenClaw "pairing approve feishu $code"; Pause-Return }
      }
      '3' {
        $code = Read-Host "请输入 WhatsApp 连接码"
        if ($code) { Invoke-OpenClaw "pairing approve whatsapp $code"; Pause-Return }
      }
      '0' { return }
      default { Write-Warn "无效选项"; Start-Sleep -Milliseconds 700 }
    }
  }
}

function Install-Plugin {
  try {
    Write-Host "\n--- 当前插件 ---" -ForegroundColor Magenta
    Invoke-OpenClaw "plugins list"
    $plugin = Read-Host "请输入插件 ID（例如 telegram / feishu / @openclaw/discord，输入0取消）"
    if (-not $plugin -or $plugin -eq '0') { return }

    $pluginId = $plugin -replace '^@openclaw/', ''

    Write-Info "尝试直接启用已安装插件: $pluginId"
    Invoke-OpenClaw "plugins enable $pluginId"

    Write-Info "若未安装则执行安装: $plugin"
    Invoke-OpenClaw "plugins install $plugin"
    Invoke-OpenClaw "plugins enable $pluginId"

    Invoke-OpenClaw "gateway restart"
    Write-OK "插件处理完成: $plugin"
  }
  catch {
    Write-Err $_.Exception.Message
  }
  Pause-Return
}

function Install-Skill {
  try {
    Write-Host "\n--- 当前技能 ---" -ForegroundColor Magenta
    Invoke-OpenClaw "skills list"

    $skill = Read-Host "请输入技能名（例如 weather / youtube-transcript，输入0取消）"
    if (-not $skill -or $skill -eq '0') { return }

    if (-not (Test-Command "npx")) { throw "npx 不可用，请先安装 Node.js" }

    Write-Info "正在安装技能: $skill"
    & npx clawhub install $skill

    Invoke-OpenClaw "gateway restart"
    Write-OK "技能安装完成: $skill"
  }
  catch {
    Write-Err $_.Exception.Message
  }
  Pause-Return
}

function Edit-Config {
  $path = Get-ConfigPath
  if (-not (Test-Path $path)) {
    Write-Warn "配置不存在: $path"
    Pause-Return
    return
  }
  notepad $path
  Write-Info "若已修改配置，建议重启网关生效。"
  Pause-Return
}

function Run-Onboard {
  Invoke-OpenClaw "onboard --install-daemon"
  Pause-Return
}

function Run-Doctor {
  Invoke-OpenClaw "doctor --fix"
  Pause-Return
}

function Show-WebUI {
  try {
    $out = (& openclaw dashboard 2>$null | Out-String)
    if (-not $out) {
      Write-Warn "未读取到 dashboard 输出，请先确保网关已启动。"
      Pause-Return
      return
    }

    $tokenMatch = [regex]::Match($out, '#token=([a-f0-9]+)')
    if ($tokenMatch.Success) {
      $token = $tokenMatch.Groups[1].Value
      Write-Host "本机访问地址：" -ForegroundColor Green
      Write-Host "http://127.0.0.1:18789/#token=$token"
      Write-Host ""
      Write-Host "若需局域网访问，请自行在防火墙放行 18789 并配置 allowedOrigins。" -ForegroundColor Yellow
    } else {
      Write-Host $out
    }
  }
  catch {
    Write-Err $_.Exception.Message
  }
  Pause-Return
}

function Update-OpenClaw {
  try {
    Install-NodeIfNeeded
    & npm install -g openclaw@latest
    Invoke-OpenClaw "gateway restart"
    Write-OK "更新完成。"
  }
  catch {
    Write-Err $_.Exception.Message
  }
  Pause-Return
}

function Uninstall-OpenClaw {
  try {
    Invoke-OpenClaw "uninstall"
    if (Test-Command "npm") {
      & npm uninstall -g openclaw
    }
    Write-OK "已卸载 OpenClaw。"
  }
  catch {
    Write-Err $_.Exception.Message
  }
  Pause-Return
}

while ($true) {
  Show-Banner
  $choice = Read-Host "请输入选项并回车"

  switch ($choice) {
    '1'  { Install-OpenClaw }
    '2'  { Start-OpenClaw }
    '3'  { Stop-OpenClaw }
    '4'  { Restart-OpenClaw }
    '5'  { Show-StatusLogs }
    '6'  { Change-Model }
    '7'  { Add-ProviderInteractive }
    '8'  { Pairing-Menu }
    '9'  { Install-Plugin }
    '10' { Install-Skill }
    '11' { Edit-Config }
    '12' { Run-Onboard }
    '13' { Run-Doctor }
    '14' { Show-WebUI }
    '15' { Update-OpenClaw }
    '16' { Uninstall-OpenClaw }
    '0'  {
      Write-Host "已退出。" -ForegroundColor Green
      break
    }
    default {
      Write-Warn "无效选项，请重试。"
      Start-Sleep -Milliseconds 600
    }
  }
}
