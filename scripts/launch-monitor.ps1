# Agent Team 监控服务 - 快速启动脚本

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "小妖的 Agent Team - 监控服务" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 停止旧服务
Write-Host "停止旧服务..." -ForegroundColor Yellow
Get-Process | Where-Object {
    $_.MainWindowTitle -eq "" -and
    $_.ProcessName -eq "powershell" -and
    $_.Id -ne $PID
} | Stop-Process -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

# 启动新服务
Write-Host "启动 Final 版本..." -ForegroundColor Green

$scriptPath = "c:\ssh\.openclaw\scripts\start-agent-monitor-final.ps1"

if (Test-Path $scriptPath) {
    & $scriptPath
} else {
    Write-Host "❌ 脚本不存在: $scriptPath" -ForegroundColor Red
    exit 1
}
