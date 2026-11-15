@echo off
title Monitor de Hardware em Tempo Real
cd /d "%~dp0"
where pwsh >nul 2>nul
if %errorlevel% equ 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0Monitor_Hardware.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Monitor_Hardware.ps1"
)
