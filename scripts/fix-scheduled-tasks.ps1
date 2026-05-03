# 快速修复：一键创建所有定时任务
# 需要以管理员身份运行

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "小妖自动化系统 - 快速修复" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ 此脚本需要管理员权限" -ForegroundColor Red
    Write-Host ""
    Write-Host "请按以下步骤操作：" -ForegroundColor Yellow
    Write-Host "1. 右键点击 PowerShell" -ForegroundColor White
    Write-Host "2. 选择'以管理员身份运行'" -ForegroundColor White
    Write-Host "3. 重新运行此脚本" -ForegroundColor White
    Write-Host ""
    Write-Host "按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Host "✅ 管理员权限已确认" -ForegroundColor Green
Write-Host ""

$scriptDir = "c:\ssh\.openclaw\scripts"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 5)

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
    Register-ScheduledTask -TaskName "小妖-学习简报" -Description "每天23:00生成学习简报并发送邮件" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -Force | Out-Null
    Write-Host "  ✓ 学习简报任务已创建" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 创建失败: $_" -ForegroundColor Red
}

# 任务 2：记忆自动备份
Write-Host "[2/5] 创建记忆自动备份任务..." -ForegroundColor Gray
try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDir\backup-memory.ps1`""
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6)
    $task = Get-ScheduledTask -TaskName "小妖-记忆自动备份" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "小妖-记忆自动备份" -Confirm:$false
    }
    Register-ScheduledTask -TaskName "小妖-记忆自动备份" -Description "每6小时备份记忆文件" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -Force | Out-Null
    Write-Host "  ✓ 记忆自动备份任务已创建" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 创建失败: $_" -ForegroundColor Red
}

# 任务 3：LanceDB 同步
Write-Host "[3/5] 创建 LanceDB 同步任务..." -ForegroundColor Gray
try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDir\sync-lancedb.ps1`""
    $trigger = New-ScheduledTaskTrigger -Daily -At "23:30"
    $task = Get-ScheduledTask -TaskName "小妖-LanceDB同步" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "小妖-LanceDB同步" -Confirm:$false
    }
    Register-ScheduledTask -TaskName "小妖-LanceDB同步" -Description "每天23:30同步LanceDB数据库" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -Force | Out-Null
    Write-Host "  ✓ LanceDB 同步任务已创建" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 创建失败: $_" -ForegroundColor Red
}

# 任务 4：完整性检查
Write-Host "[4/5] 创建完整性检查任务..." -ForegroundColor Gray
try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDir\check-memory-integrity.ps1`""
    $trigger = New-ScheduledTaskTrigger -Daily -At "12:00"
    $task = Get-ScheduledTask -TaskName "小妖-记忆完整性检查" -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName "小妖-记忆完整性检查" -Confirm:$false
    }
    Register-ScheduledTask -TaskName "小妖-记忆完整性检查" -Description "每天12:00检查记忆完整性" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -Force | Out-Null
    Write-Host "  ✓ 完整性检查任务已创建" -ForegroundColor Green
} catch {
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
    Register-ScheduledTask -TaskName "小妖-每周快照" -Description "每周日02:00创建完整快照" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -Force | Out-Null
    Write-Host "  ✓ 每周快照任务已创建" -ForegroundColor Green
} catch {
    Write-Host "  ✗ 创建失败: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "验证任务创建状态" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tasks = Get-ScheduledTask -TaskName "小妖-*" -ErrorAction SilentlyContinue
if ($tasks) {
    Write-Host "已创建的任务：" -ForegroundColor Green
    $tasks | Format-Table TaskName, State, Description -AutoSize
    Write-Host ""
    Write-Host "下次运行时间：" -ForegroundColor Yellow
    $tasks | Select-Object TaskName, @{Name="NextRun";Expression={$_.NextRunTime}} | Format-Table -AutoSize
} else {
    Write-Host "⚠ 没有找到任何任务" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 修复完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步操作：" -ForegroundColor Cyan
Write-Host "1. 查看任务计划程序确认任务已创建" -ForegroundColor White
Write-Host "2. 等待任务自动运行，或手动测试" -ForegroundColor White
Write-Host "3. 查看日志文件确认执行状态" -ForegroundColor White
Write-Host ""
Write-Host "日志位置：c:\ssh\.openclaw\logs\" -ForegroundColor Gray
Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
