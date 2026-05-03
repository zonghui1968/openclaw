# Enhanced Daily Learning Summary Task Setup
# 创建每天晚上 11:00 的学习简报任务

param(
    [switch]$Force               # 强制重新创建任务
)

$ErrorActionPreference = "Stop"

# 配置
$taskName = "OpenClaw Daily Learning Summary"
$scriptPath = "c:\ssh\.openclaw\scripts\daily-learning-summary-enhanced.ps1"
$taskDescription = "每天晚上 11:00 生成学习简报，包含网页浏览、技能学习、经验增长、编码能力等内容，并发送邮件到 hizonghui@gmail.com，同时保存到 Obsidian"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "每日学习简报任务设置 (增强版)" -ForegroundColor Cyan
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

# 创建触发器（每天晚上 11:00）
$trigger = New-ScheduledTaskTrigger -Daily -At "23:00"
Write-Host "✅ 触发器: 每天 23:00（晚上 11:00）" -ForegroundColor Green

# 创建操作
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
Write-Host "✅ 操作: 运行增强版学习简报脚本" -ForegroundColor Green

# 设置任务主体
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -DontStopOnIdleEnd `
    -Compatibility Win8

Write-Host "✅ 设置: 电池可用时运行，网络可用时运行" -ForegroundColor Green

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
    Write-Host "  时间: 每天晚上 11:00（23:00）" -ForegroundColor Gray
    Write-Host "  脚本: $scriptPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "简报内容包含:" -ForegroundColor Cyan
    Write-Host "  🌐 浏览的网页" -ForegroundColor Gray
    Write-Host "  🎓 学习的技能" -ForegroundColor Gray
    Write-Host "  🛠️ 使用的工具" -ForegroundColor Gray
    Write-Host "  💻 编码能力进展" -ForegroundColor Gray
    Write-Host "  💡 决策经验" -ForegroundColor Gray
    Write-Host "  🎓 经验教训" -ForegroundColor Gray
    Write-Host ""
    Write-Host "发送到:" -ForegroundColor Cyan
    Write-Host "  📧 hizonghui@gmail.com" -ForegroundColor Gray
    Write-Host "  📧 ruoli.jia@gmail.com (抄送)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "保存到:" -ForegroundColor Cyan
    Write-Host "  📁 Obsidian: 📚 学习笔记/每日学习简报/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "查看任务:" -ForegroundColor Yellow
    Write-Host "  Get-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "手动运行:" -ForegroundColor Yellow
    Write-Host "  Start-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor Gray
    Write-Host "  或直接运行: $scriptPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "删除任务:" -ForegroundColor Yellow
    Write-Host "  Unregister-ScheduledTask -TaskName `"$taskName`" -Confirm:`$false" -ForegroundColor Gray
}
catch {
    Write-Host ""
    Write-Host "❌ 创建任务失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
