# Sessions Monitor Task Setup
# 创建 Sessions 监控任务，当使用率达到 65% 时自动压缩

param(
    [double]$Threshold = 65,      # 触发压缩的阈值（百分比）
    [int]$CheckIntervalHours = 6, # 检查间隔（小时）
    [switch]$Force                # 强制重新创建任务
)

$ErrorActionPreference = "Stop"

# 配置
$taskName = "OpenClaw Sessions Monitor"
$scriptPath = "c:\ssh\.openclaw\scripts\sessions-monitor.ps1"
$taskDescription = "每 $CheckIntervalHours 小时检查一次 sessions 使用率，当达到 $Threshold% 时自动压缩备份，防止上下文记忆丢失"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Sessions 监控任务设置" -ForegroundColor Cyan
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
    Write-Host "❌ 错误: 找不到脚本: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 脚本文件: $scriptPath" -ForegroundColor Green
Write-Host "✅ 监控阈值: $Threshold%" -ForegroundColor Green
Write-Host "✅ 检查间隔: 每 $CheckIntervalHours 小时" -ForegroundColor Green

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
    Start-Sleep -Seconds 2
    Write-Host "✅ 旧任务已删除" -ForegroundColor Green
}

# 创建触发器（每 N 小时运行一次）
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $CheckIntervalHours) -RepetitionDuration ([TimeSpan]::MaxValue)
Write-Host "✅ 触发器: 每 $CheckIntervalHours 小时检查一次" -ForegroundColor Green

# 创建操作
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Threshold $Threshold"
Write-Host "✅ 操作: 运行 sessions 监控脚本" -ForegroundColor Green

# 设置任务主体
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -DontStopOnIdleEnd `
    -Compatibility Win8 `
    -Hidden

Write-Host "✅ 设置: 后台运行，电池可用时运行" -ForegroundColor Green

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
    Write-Host "  频率: 每 $CheckIntervalHours 小时检查一次" -ForegroundColor Gray
    Write-Host "  阈值: sessions 使用率达到 $Threshold% 时触发压缩" -ForegroundColor Gray
    Write-Host "  脚本: $scriptPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "工作流程:" -ForegroundColor Cyan
    Write-Host "  1. 每 $CheckIntervalHours 小时检查一次 sessions 使用率" -ForegroundColor Gray
    Write-Host "  2. 当使用率 ≥ $Threshold% 时，自动执行压缩" -ForegroundColor Gray
    Write-Host "  3. 压缩备份旧 sessions（保留最近 7 天）" -ForegroundColor Gray
    Write-Host "  4. 发送通知到用户" -ForegroundColor Gray
    Write-Host ""
    Write-Host "好处:" -ForegroundColor Cyan
    Write-Host "  ✅ 防止 sessions 增长过大导致性能问题" -ForegroundColor Gray
    Write-Host "  ✅ 保持上下文记忆连续性" -ForegroundColor Gray
    Write-Host "  ✅ 避免需要使用 /new 命令重启" -ForegroundColor Gray
    Write-Host "  ✅ 自动备份，数据安全" -ForegroundColor Gray
    Write-Host ""
    Write-Host "查看任务:" -ForegroundColor Yellow
    Write-Host "  Get-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "手动运行:" -ForegroundColor Yellow
    Write-Host "  Start-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
    Write-Host "  或直接运行: & `"$scriptPath`" -Threshold $Threshold" -ForegroundColor Gray
    Write-Host ""
    Write-Host "删除任务:" -ForegroundColor Yellow
    Write-Host "  Unregister-ScheduledTask -TaskName `"$taskName`" -Confirm:`$false" -ForegroundColor Gray
    Write-Host ""
    Write-Host "调整参数:" -ForegroundColor Yellow
    Write-Host "  .\setup-sessions-monitor-task.ps1 -Threshold 70 -CheckIntervalHours 4 -Force" -ForegroundColor Gray
}
catch {
    Write-Host ""
    Write-Host "❌ 创建任务失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
