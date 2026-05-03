# OpenClaw Sessions 定期清理任务设置脚本
# 自动压缩和删除超过指定天数的会话文件

param(
    [int]$DaysToKeep = 7,        # 保留最近 N 天的会话
    [int]$RunIntervalDays = 7,   # 每隔 N 天运行一次
    [switch]$Force               # 强制创建任务（如果已存在）
)

$ErrorActionPreference = "Stop"

# 配置
$taskName = "OpenClaw Sessions Cleanup"
$scriptPath = "c:\ssh\.openclaw\scripts\compress-sessions.ps1"
$taskDescription = "自动压缩和删除超过 $DaysToKeep 天的 OpenClaw 会话文件"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenClaw Sessions 定期清理任务设置" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否以管理员身份运行
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ 错误: 需要管理员权限来创建计划任务" -ForegroundColor Red
    Write-Host ""
    Write-Host "请以管理员身份运行此脚本：" -ForegroundColor Yellow
    Write-Host "  右键点击 PowerShell -> 以管理员身份运行" -ForegroundColor Gray
    exit 1
}

# 检查脚本是否存在
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ 错误: 找不到清理脚本: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "✓ 清理脚本: $scriptPath" -ForegroundColor Green

# 检查任务是否已存在
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask -and -not $Force) {
    Write-Host ""
    Write-Host "⚠️  任务已存在: $taskName" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "任务信息:" -ForegroundColor Cyan
    Write-Host "  名称: $($existingTask.TaskName)" -ForegroundColor Gray
    Write-Host "  状态: $($existingTask.State)" -ForegroundColor Gray
    Write-Host "  下次运行: $($existingTask.NextRunTime)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "如需重新创建，请使用 -Force 参数" -ForegroundColor Yellow
    exit 0
}

# 删除旧任务（如果存在）
if ($existingTask -and $Force) {
    Write-Host "删除旧任务..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "✓ 旧任务已删除" -ForegroundColor Green
}

# 创建触发器（每周运行一次）
$trigger = New-ScheduledTaskTrigger -Weekly -DaysInterval $RunIntervalDays -At "02:00"
Write-Host "✓ 触发器: 每 $RunIntervalDays 天运行一次（凌晨 2:00）" -ForegroundColor Green

# 创建操作
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -DaysToKeep $DaysToKeep -Compress -Delete"
Write-Host "✓ 操作: 运行清理脚本" -ForegroundColor Green

# 设置任务主体
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -DontStopOnIdleEnd `
    -Compatibility Win8 `
    -Hidden

Write-Host "✓ 设置: 电池可用时运行，网络可用时运行" -ForegroundColor Green

# 注册任务
try {
    Register-ScheduledTask `
        -TaskName $taskName `
        -Description $taskDescription `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -User "SYSTEM" `
        -RunLevel Highest | Out-Null

    Write-Host ""
    Write-Host "✅ 计划任务创建成功!" -ForegroundColor Green
    Write-Host ""
    Write-Host "任务详情:" -ForegroundColor Cyan
    Write-Host "  名称: $taskName" -ForegroundColor Gray
    Write-Host "  保留: 最近 $DaysToKeep 天的会话" -ForegroundColor Gray
    Write-Host "  频率: 每 $RunIntervalDays 天运行一次" -ForegroundColor Gray
    Write-Host "  时间: 凌晨 2:00" -ForegroundColor Gray
    Write-Host "  脚本: $scriptPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "查看任务:" -ForegroundColor Yellow
    Write-Host "  Get-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "手动运行:" -ForegroundColor Yellow
    Write-Host "  Start-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "删除任务:" -ForegroundColor Yellow
    Write-Host "  Unregister-ScheduledTask -TaskName `"$taskName`" -Confirm:`$false" -ForegroundColor Gray
}
catch {
    Write-Host ""
    Write-Host "❌ 创建任务失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
