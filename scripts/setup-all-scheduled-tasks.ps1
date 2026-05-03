# OpenClaw Scheduled Tasks - All-in-One Setup
# 一键设置所有定时任务：学习简报 + Sessions 监控

param(
    [switch]$Force               # 强制重新创建所有任务
)

$ErrorActionPreference = "Stop"

$separator = "=" * 70
Write-Host ""
Write-Host $separator -ForegroundColor Cyan
Write-Host "  OpenClaw 定时任务一键设置" -ForegroundColor Cyan
Write-Host $separator -ForegroundColor Cyan
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

Write-Host "将创建以下任务：" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣  每日学习简报任务" -ForegroundColor Green
Write-Host "   - 时间: 每天晚上 11:00（23:00）" -ForegroundColor Gray
Write-Host "   - 内容: 网页浏览、技能学习、经验增长、编码能力" -ForegroundColor Gray
Write-Host "   - 发送: hizonghui@gmail.com (抄送 ruoli.jia@gmail.com)" -ForegroundColor Gray
Write-Host "   - 保存: Obsidian (📚 学习笔记/每日学习简报/)" -ForegroundColor Gray
Write-Host ""

Write-Host "2️⃣  Sessions 监控任务" -ForegroundColor Green
Write-Host "   - 频率: 每 6 小时检查一次" -ForegroundColor Gray
Write-Host "   - 阈值: 使用率达到 65% 时触发压缩" -ForegroundColor Gray
Write-Host "   - 保留: 最近 7 天的 sessions" -ForegroundColor Gray
Write-Host "   - 好处: 防止上下文记忆丢失" -ForegroundColor Gray
Write-Host ""

Write-Host $separator -ForegroundColor Cyan
Write-Host ""

# 确认
if (-not $Force) {
    $confirm = Read-Host "是否继续创建这些任务？(Y/N)"
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host "❌ 操作已取消" -ForegroundColor Yellow
        exit 0
    }
}

# 任务 1: 每日学习简报
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "任务 1/2: 每日学习简报" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    & "c:\ssh\.openclaw\scripts\setup-daily-learning-task-enhanced.ps1" -Force:$Force
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 每日学习简报任务创建成功" -ForegroundColor Green
    } else {
        Write-Host "⚠️  每日学习简报任务创建可能失败" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ 每日学习简报任务创建失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host ""

# 任务 2: Sessions 监控
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "任务 2/2: Sessions 监控" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    & "c:\ssh\.openclaw\scripts\setup-sessions-monitor-task.ps1" -Force:$Force
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Sessions 监控任务创建成功" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Sessions 监控任务创建可能失败" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "❌ Sessions 监控任务创建失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host $separator -ForegroundColor Cyan
Write-Host "  所有任务设置完成！" -ForegroundColor Green
Write-Host $separator -ForegroundColor Cyan
Write-Host ""

# 显示任务列表
Write-Host "已创建的任务：" -ForegroundColor Cyan
Write-Host ""

$tasks = @(
    "OpenClaw Daily Learning Summary",
    "OpenClaw Sessions Monitor"
)

foreach ($taskName in $tasks) {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "✅ $($task.TaskName)" -ForegroundColor Green
        Write-Host "   状态: $($task.State)" -ForegroundColor Gray
        Write-Host "   下次运行: $($task.NextRunTime)" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "查看所有任务：" -ForegroundColor Yellow
Write-Host "  Get-ScheduledTask | Where-Object {$_.TaskName -like 'OpenClaw*'} | Format-Table TaskName, State, NextRunTime" -ForegroundColor Gray
Write-Host ""

Write-Host "手动运行任务：" -ForegroundColor Yellow
Write-Host "  Start-ScheduledTask -TaskName 'OpenClaw Daily Learning Summary'" -ForegroundColor Gray
Write-Host "  Start-ScheduledTask -TaskName 'OpenClaw Sessions Monitor'" -ForegroundColor Gray
Write-Host ""

Write-Host "测试学习简报：" -ForegroundColor Yellow
Write-Host "  c:\ssh\.openclaw\scripts\daily-learning-summary-enhanced.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "测试 Sessions 监控：" -ForegroundColor Yellow
Write-Host "  c:\ssh\.openclaw\scripts\sessions-monitor.ps1" -ForegroundColor Gray
Write-Host ""

Write-Host "删除所有任务：" -ForegroundColor Yellow
Write-Host "  Unregister-ScheduledTask -TaskName 'OpenClaw Daily Learning Summary' -Confirm:`$false" -ForegroundColor Gray
Write-Host "  Unregister-ScheduledTask -TaskName 'OpenClaw Sessions Monitor' -Confirm:`$false" -ForegroundColor Gray
Write-Host ""
