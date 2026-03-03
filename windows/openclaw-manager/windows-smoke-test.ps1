# Windows 本机快速冒烟测试（管理员 PowerShell）
$ErrorActionPreference = 'Stop'

$root = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$files = @(
  (Join-Path $root 'openclaw-win-manager.ps1'),
  (Join-Path $root 'openclaw-win-manager.bat'),
  (Join-Path $root 'openclaw-win-distribute.bat'),
  (Join-Path $root 'install.ps1')
)

Write-Host "[1/4] 检查文件存在..." -ForegroundColor Cyan
foreach ($f in $files) {
  if (!(Test-Path $f)) { throw "缺少文件: $f" }
  Write-Host "  OK $f"
}

Write-Host "[2/4] 校验 PS1 语法..." -ForegroundColor Cyan
$null = [System.Management.Automation.Language.Parser]::ParseFile(
  (Join-Path $root 'openclaw-win-manager.ps1'),
  [ref]$null,
  [ref]$null
)
Write-Host "  OK openclaw-win-manager.ps1 语法通过"

Write-Host "[3/4] 校验 install.ps1 语法..." -ForegroundColor Cyan
$null = [System.Management.Automation.Language.Parser]::ParseFile(
  (Join-Path $root 'install.ps1'),
  [ref]$null,
  [ref]$null
)
Write-Host "  OK install.ps1 语法通过"

Write-Host "[4/4] 检查关键命令片段..." -ForegroundColor Cyan
$manager = Get-Content (Join-Path $root 'openclaw-win-manager.ps1') -Raw
$install = Get-Content (Join-Path $root 'install.ps1') -Raw

if ($manager -notmatch 'openclaw gateway start') { throw '缺少 gateway start' }
if ($manager -notmatch 'openclaw gateway stop') { throw '缺少 gateway stop' }
if ($manager -notmatch 'openclaw models set') { throw '缺少 models set' }
if ($install -notmatch 'openclaw-win-manager.ps1') { throw 'install.ps1 未引用主管理脚本' }

Write-Host "  OK 关键命令片段通过"
Write-Host "\n✅ Windows 冒烟测试通过" -ForegroundColor Green
