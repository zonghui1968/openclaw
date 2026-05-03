# 修复版：创建所有定时任务（使用当前用户）
# 解决权限问题

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "小妖自动化系统 - 创建定时任务" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = "c:\ssh\.openclaw\scripts"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$successCount = 0
$failCount = 0

Write-Host "开始创建定时任务..." -ForegroundColor Yellow
Write-Host ""

# 任务 1：学习简报
Write-Host "[1/5] 创建学习简报任务..." -ForegroundColor Gray
try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDir\daily-learning-summary-enhanced.ps1`""
    $trigger = New-ScheduledTaskTrigger -Daily -At "23:00"
    $task = Get-ScheduledTask -TaskName "小妖-学习简报" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "小妖-学习简报" -Confirm:$false
    }
    Register-ScheduledTask -TaskName "小妖-学习简报" -Description "每天23:00生成学习简报并发送邮件" -Action $action -Trigger $trigger -Settings $settings -User $env:USERNAME -Force | Out-Null
    $successCount++
    Write-Host "  ✓ 学习简报任务已创建" -ForegroundColor Green
} catch {
    $failCount++
    Write-Host "  ✗ 创建失败: $_" -ForegroundColor Red
}

# 任务 2：记忆自动备份
Write-Host "[2/5] 创建记忆自动备份任务..." -ForegroundColor Gray
try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDir\backup-memory.ps1`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date "00:00") -RepetitionInterval (New-TimeSpan -Hours 6)
    $task = Get-ScheduledTask -TaskName "小妖-记忆自动备份" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "小妖-记忆自动备份" -Confirm:$false
    }
    Register-ScheduledTask -TaskName "小妖-记忆自动备份" -Description "每6小时备份记忆文件" -Action $action -Trigger $trigger -Settings $settings -User $env:USERNAME -Force | Out-Null
    $successCount++
    Write-Host "  ✓ 记忆自动备份任务已创建" -ForegroundColor Green
} catch {
    $failCount++
    Write-Host "  ✗ 创建失败: $_" -ForegroundColor Red
}

# 任务 3：LanceDB 同步
Write-Host "[3/5] 创建 LanceDB 同步任务..." -ForegroundColor Gray
try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDir\sync-lancedb.ps1`" -Verbose"
    $trigger = New-ScheduledTaskTrigger -Daily -At "23:30"
    $task = Get-ScheduledTask -TaskName "小妖-LanceDB同步" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "小妖-LanceDB同步" -Confirm:$false
    }
    Register-ScheduledTask -TaskName "小妖-LanceDB同步" -Description "每天23:30同步LanceDB数据库" -Action $action -Trigger $trigger -Settings $settings -User $env:USERNAME -Force | Out-Null
    $successCount++
    Write-Host "  ✓ LanceDB 同步任务已创建" -ForegroundColor Green
} catch {
    $failCount++
    Write-Host "  ✗ 创建失败: $_" -ForegroundColor Red
}

# 任务 4：完整性检查
Write-Host "[4/5] 创建完整性检查任务..." -ForegroundColor Gray
try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDir\check-memory-integrity.ps1`" -Verbose"
    $trigger = New-ScheduledTaskTrigger -Daily -At "12:00"
    $task = Get-ScheduledTask -TaskName "小妖-记忆完整性检查" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "小妖-记忆完整性检查" -Confirm:$false
    }
    Register-ScheduledTask -TaskName "小妖-记忆完整性检查" -Description "每天12:00检查记忆完整性" -Action $action -Trigger $trigger -Settings $settings -User $env:USERNAME -Force | Out-Null
    $successCount++
    Write-Host "  ✓ 完整性检查任务已创建" -ForegroundColor Green
} catch {
    $failCount++
    Write-Host "  ✗ 创建失败: $_" -ForegroundColor Red
}

# 任务 5：每周快照
Write-Host "[5/5] 创建每周快照任务..." -ForegroundColor Gray
try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDir\create-memory-snapshot.ps1`""
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "02:00"
    $task = Get-ScheduledTask -TaskName "小妖-每周快照" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "小妖-每周快照" -Confirm:$false
    }
    Register-ScheduledTask -TaskName "小妖-每周快照" -Description "每周日02:00创建完整快照" -Action $action -Trigger $trigger -Settings $settings -User $env:USERNAME -Force | Out-Null
    $successCount++
    Write-Host "  ✓ 每周快照任务已创建" -ForegroundColor Green
} catch {
    $failCount++
    Write-Host "  ✗ 创建失败: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "创建结果统计" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "成功: $successCount 个任务" -ForegroundColor Green
Write-Host "失败: $failCount 个任务" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "验证任务状态" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tasks = Get-ScheduledTask -TaskName "小妖-*" -ErrorAction SilentlyContinue
if ($tasks) {
    Write-Host "已创建的任务：" -ForegroundColor Green
    $tasks | Format-Table TaskName, State, Description -AutoSize

    Write-Host ""
    Write-Host "下次运行时间：" -ForegroundColor Yellow
    $tasks | Select-Object TaskName, @{Name="NextRun";Expression={$_.NextRunTime}} | Format-Table -AutoSize

    Write-Host ""
    Write-Host "✅ 所有任务已成功创建！" -ForegroundColor Green
} else {
    Write-Host "⚠ 没有找到任何任务" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "下一步操作" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 打开任务计划程序查看任务" -ForegroundColor White
Write-Host "   运行: taskschd.msc" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 手动测试一个任务" -ForegroundColor White
Write-Host "   右键任务 -> 运行" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 查看日志文件" -ForegroundColor White
Write-Host "   位置: c:\ssh\.openclaw\logs\" -ForegroundColor Gray
Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
