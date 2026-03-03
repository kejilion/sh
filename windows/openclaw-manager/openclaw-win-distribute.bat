@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

REM OpenClaw Windows 一键分发版（单文件）
REM 用法：双击即可，自动拉取最新版 openclaw-win-manager.ps1 再启动

set "RAW_URL=https://raw.githubusercontent.com/kejilion/sh/main/windows/openclaw-manager/openclaw-win-manager.ps1"
set "TARGET=%TEMP%\openclaw-win-manager.ps1"

where powershell >nul 2>nul
if errorlevel 1 (
  echo [ERROR] 未检测到 PowerShell
  pause
  exit /b 1
)

echo [INFO] 正在下载最新版管理脚本...
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { iwr -UseBasicParsing '%RAW_URL%' -OutFile '%TARGET%'; if ((Get-Item '%TARGET%').Length -lt 2000) { throw 'download too small' } } catch { Write-Host '[ERROR] 下载失败:' $_.Exception.Message; exit 1 }"
if errorlevel 1 (
  echo [ERROR] 下载失败，请检查网络或 RAW_URL。
  pause
  exit /b 1
)

echo [INFO] 启动 OpenClaw Windows Manager...
powershell -NoProfile -ExecutionPolicy Bypass -File "%TARGET%"

if errorlevel 1 (
  echo.
  echo [WARN] 脚本退出代码: %errorlevel%
)

pause
endlocal
