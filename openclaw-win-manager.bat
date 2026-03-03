@echo off
chcp 65001 >nul
setlocal

REM OpenClaw Windows Manager 一键启动器
REM 放在与 openclaw-win-manager.ps1 同目录

set "SCRIPT_DIR=%~dp0"
set "PS1=%SCRIPT_DIR%openclaw-win-manager.ps1"

if not exist "%PS1%" (
  echo [ERROR] 未找到脚本: %PS1%
  pause
  exit /b 1
)

where powershell >nul 2>nul
if errorlevel 1 (
  echo [ERROR] 未检测到 PowerShell
  pause
  exit /b 1
)

echo [INFO] 正在启动 OpenClaw Windows 管理脚本...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"

if errorlevel 1 (
  echo.
  echo [WARN] 脚本退出代码: %errorlevel%
)

pause
endlocal
