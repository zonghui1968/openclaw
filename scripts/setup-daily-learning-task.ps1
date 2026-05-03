# 设置每日学习简报定时任务
# 需要管理员权限运行

# 检查是否以管理员身份运行
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ 此脚本需要管理员权限运行" -ForegroundColor Red
    Write-Host "请右键点击 PowerShell，选择'以管理员身份运行'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "或者按以下步骤操作：" -ForegroundColor Cyan
    Write-Host "1. 右键点击开始菜单" -ForegroundColor White
    Write-Host "2. 选择 'Windows PowerShell (管理员)'" -ForegroundColor White
    Write-Host "3. 运行此脚本" -ForegroundColor White
    pause
    exit 1
}

Write-Host "✅ 检测到管理员权限" -ForegroundColor Green
Write-Host ""

# 定义任务参数
$taskName = "OpenClaw-DailyLearning"
$scriptPath = "c:\ssh\.openclaw\scripts\daily-learning-summary.ps1"

# 检查脚本是否存在
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ 找不到脚本文件: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "📋 创建定时任务..." -ForegroundColor Cyan
Write-Host "任务名称: $taskName" -ForegroundColor White
Write-Host "执行时间: 每天 23:00" -ForegroundColor White
Write-Host "脚本路径: $scriptPath" -ForegroundColor White
Write-Host ""

try {
    # 创建任务动作
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

    # 创建任务触发器（每天 23:00）
    $trigger = New-ScheduledTaskTrigger -Daily -At "23:00"

    # 创建任务主体（使用 SYSTEM 账户）
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # 创建任务设置
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    # 注册任务
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "每天23:00生成学习简报并发送邮件" -ErrorAction Stop

    Write-Host "✅ 定时任务创建成功！" -ForegroundColor Green
    Write-Host ""
    Write-Host "任务详情：" -ForegroundColor Cyan
    Get-ScheduledTask -TaskName $taskName | Format-List TaskName, State, Description
    Write-Host ""
    Write-Host "下次运行时间：" -ForegroundColor Cyan
    Get-ScheduledTaskInfo -TaskName $taskName | Select-Object -ExpandProperty NextRunTime
    Write-Host ""
    Write-Host "如需手动测试，请运行：" -ForegroundColor Yellow
    Write-Host "Start-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor White
    Write-Host ""
    Write-Host "如需删除任务，请运行：" -ForegroundColor Yellow
    Write-Host "Unregister-ScheduledTask -TaskName `"$taskName`"" -ForegroundColor White

} catch {
    Write-Host "❌ 创建任务失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
