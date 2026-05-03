# 记忆零丢失系统 - 一键设置脚本
# 自动配置所有定时任务和监控

param(
    [switch]$Force,
    [switch]$Test
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "记忆零丢失系统 - 一键设置" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "❌ 此脚本需要管理员权限" -ForegroundColor Red
    Write-Host "请右键点击 PowerShell，选择'以管理员身份运行'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "或者按任意键尝试提升权限..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    # 重新以管理员身份运行
    $scriptPath = $PSCommandPath
    $psiArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

    if ($Force) {
        $psiArgs += " -Force"
    }
    if ($Test) {
        $psiArgs += " -Test"
    }

    Start-Process powershell -ArgumentList $psiArgs -Verb RunAs
    exit
}

Write-Host "✅ 管理员权限已获取" -ForegroundColor Green
Write-Host ""

# 脚本目录
$scriptDir = "c:\ssh\.openclaw\scripts"
$workspaceDir = "c:\ssh\.openclaw\workspace"

# 确保 logs 目录存在
$logDir = "c:\ssh\.openclaw\logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    Write-Host "✅ 创建日志目录: $logDir" -ForegroundColor Green
}

# 步骤 1：初始化 Git 仓库
Write-Host "步骤 1/7: 初始化 Git 版本控制" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$gitDir = "$workspaceDir\.git"
if (-not (Test-Path $gitDir)) {
    Push-Location $workspaceDir
    try {
        git init
        git config user.name "小妖"
        git config user.email "xiaoyao@openclaw.local"
        git add .
        git commit -m "Initial commit: Memory zero-loss system setup"

        # 创建 .gitignore
        @"
node_modules/
.next/
.vercel/
*.log
.DS_Store
Thumbs.db
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8

        Write-Host "  ✓ Git 仓库初始化完成" -ForegroundColor Green
    } finally {
        Pop-Location
    }
} else {
    Write-Host "  ✓ Git 仓库已存在" -ForegroundColor Green
}

Write-Host ""

# 步骤 2：验证脚本文件
Write-Host "步骤 2/7: 验证脚本文件" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$scripts = @(
    "backup-memory.ps1",
    "sync-lancedb.ps1",
    "check-memory-integrity.ps1",
    "create-memory-snapshot.ps1"
)

$missingScripts = @()

foreach ($script in $scripts) {
    $scriptPath = Join-Path $scriptDir $script
    if (Test-Path $scriptPath) {
        Write-Host "  ✓ $script" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $script (缺失)" -ForegroundColor Red
        $missingScripts += $script
    }
}

if ($missingScripts.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ 缺少必要的脚本文件，无法继续" -ForegroundColor Red
    $scriptDirStr = $scriptDir
    Write-Host "请确保以下文件存在于 $scriptDirStr :" -ForegroundColor Yellow
    $missingScripts | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    exit 1
}

Write-Host ""

# 步骤 3：测试脚本
Write-Host "步骤 3/7: 测试脚本功能" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

if ($Test) {
    Write-Host "运行完整性检查测试..." -ForegroundColor Gray
    $testResult = & "$scriptDir\check-memory-integrity.ps1" -Verbose 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ 完整性检查通过" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ 完整性检查发现问题（可能需要初始化）" -ForegroundColor Yellow
    }
} else {
    Write-Host "  跳过测试（使用 -Test 参数进行测试）" -ForegroundColor Gray
}

Write-Host ""

# 步骤 4：创建任务执行器
Write-Host "步骤 4/7: 创建任务执行器" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$taskRunner = @"
# 任务执行器包装脚本
param(`$TaskName)

`$scriptDir = "c:\ssh\.openclaw\scripts"
`$logFile = "c:\ssh\.openclaw\logs\task-runner.log"

function Log-Message {
    param([string]`$Message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logMsg = "[`$timestamp] [`$TaskName] `$Message"
    Add-Content -Path `$logFile -Value `$logMsg
}

try {
    Log-Message "开始执行任务: `$TaskName"

    switch (`$TaskName) {
        "backup" {
            & "`$scriptDir\backup-memory.ps1"
        }
        "sync" {
            & "`$scriptDir\sync-lancedb.ps1" -Verbose
        }
        "integrity" {
            & "`$scriptDir\check-memory-integrity.ps1" -Verbose
        }
        "snapshot" {
            & "`$scriptDir\create-memory-snapshot.ps1"
        }
        default {
            throw "未知任务: `$TaskName"
        }
    }

    if (`$LASTEXITCODE -eq 0) {
        Log-Message "任务完成成功"
    } else {
        Log-Message "任务完成失败 (退出码: `$LASTEXITCODE)"
    }

    exit `$LASTEXITCODE

} catch {
    Log-Message "任务执行失败: `$_"
    exit 1
}
"@

$taskRunnerPath = "$scriptDir\run-task.ps1"
$taskRunner | Out-File -FilePath $taskRunnerPath -Encoding UTF8
Write-Host "  ✓ 任务执行器已创建" -ForegroundColor Green

Write-Host ""

# 步骤 5：配置定时任务
Write-Host "步骤 5/7: 配置 Windows 定时任务" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$tasks = @(
    @{
        Name = "小妖-记忆自动备份"
        Description = "每 6 小时备份一次记忆文件"
        Command = "powershell.exe"
        Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$taskRunnerPath`" -TaskName backup"
    },
    @{
        Name = "小妖-LanceDB同步"
        Description = "每天 23:30 同步 LanceDB"
        Command = "powershell.exe"
        Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$taskRunnerPath`" -TaskName sync"
    },
    @{
        Name = "小妖-记忆完整性检查"
        Description = "每天 12:00 检查记忆完整性"
        Command = "powershell.exe"
        Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$taskRunnerPath`" -TaskName integrity"
    },
    @{
        Name = "小妖-每周快照"
        Description = "每周日 02:00 创建完整快照"
        Command = "powershell.exe"
        Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$taskRunnerPath`" -TaskName snapshot"
    }
)

foreach ($task in $tasks) {
    $taskExists = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue

    if ($taskExists -and -not $Force) {
        Write-Host "  ○ $($task.Name) (已存在)" -ForegroundColor Yellow
        continue
    }

    try {
        # 删除旧任务（如果存在）
        if ($taskExists) {
            Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false -ErrorAction SilentlyContinue
        }

        # 创建触发器
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6)

        # 创建动作
        $action = New-ScheduledTaskAction -Execute $task.Command -Argument $task.Arguments

        # 创建设置
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -RestartCount 3 `
            -RestartInterval (New-TimeSpan -Minutes 5)

        # 注册任务
        Register-ScheduledTask `
            -TaskName $task.Name `
            -Description $task.Description `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -User "SYSTEM" `
            -Force | Out-Null

        Write-Host "  ✓ $($task.Name) (已创建)" -ForegroundColor Green

    } catch {
        Write-Host "  ✗ $($task.Name) (创建失败: $($_.Exception.Message))" -ForegroundColor Red
    }
}

Write-Host ""

# 步骤 6：配置日志轮转
Write-Host "步骤 6/7: 配置日志轮转" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$logCleanupScript = @"
# 日志清理脚本
# 保留最近 30 天的日志

`$logDir = "c:\ssh\.openclaw\logs"
`$cutoffDate = (Get-Date).AddDays(-30)

`$oldLogs = Get-ChildItem `$logDir -Filter "*.log" -File |
            Where-Object { `$_.LastWriteTime -lt `$cutoffDate }

if (`$oldLogs) {
    `$oldLogs | Remove-Item -Force
    Write-Host "已删除 `$(`$oldLogs.Count) 个旧日志文件"
} else {
    Write-Host "没有需要清理的旧日志"
}
"@

$logCleanupPath = "$scriptDir\cleanup-logs.ps1"
$logCleanupScript | Out-File -FilePath $logCleanupPath -Encoding UTF8

# 创建每周日志清理任务
$cleanupTaskName = "小妖-日志清理"
$cleanupTaskExists = Get-ScheduledTask -TaskName $cleanupTaskName -ErrorAction SilentlyContinue

if (-not $cleanupTaskExists -or $Force) {
    if ($cleanupTaskExists) {
        Unregister-ScheduledTask -TaskName $cleanupTaskName -Confirm:$false -ErrorAction SilentlyContinue
    }

    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 03:00
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$logCleanupPath`""
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    Register-ScheduledTask -TaskName $cleanupTaskName -Description "每周清理旧日志" -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -Force | Out-Null
    Write-Host "  ✓ 日志清理任务已创建" -ForegroundColor Green
} else {
    Write-Host "  ○ 日志清理任务已存在" -ForegroundColor Yellow
}

Write-Host ""

# 步骤 7：创建监控面板
Write-Host "步骤 7/7: 创建监控面板" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$dashboardScript = @"
# 记忆系统监控面板

`$workspaceDir = "c:\ssh\.openclaw\workspace"
`$mainMemory = "C:\Users\宗晖\clawd\workspace\memory"
`$lanceDb = "C:\Users\宗晖\.openclaw\memorydb\memories.lance"
`$backupDir = "C:\Users\宗晖\.openclaw\memory-backups"
`$snapshotDir = "C:\Users\宗晖\.openclaw\memory-snapshots"
`$logDir = "c:\ssh\.openclaw\logs"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "记忆系统监控面板" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 统计信息
`$memoryFiles = Get-ChildItem `$mainMemory -Filter "*.md" -File -ErrorAction SilentlyContinue
`$MEMORY_Exists = Test-Path "`$mainMemory\MEMORY.md"
`$lanceDbExists = Test-Path `$lanceDb
`$backupCount = (Get-ChildItem `$backupDir -Filter "*.zip" -File -ErrorAction SilentlyContinue).Count
`$snapshotCount = (Get-ChildItem `$snapshotDir -Filter "*.zip" -File -ErrorAction SilentlyContinue).Count
`$gitStatus = git -C `$workspaceDir status --short 2>&1

Write-Host "📊 记忆文件统计" -ForegroundColor Yellow
Write-Host "  总数: `$(`$memoryFiles.Count) 个" -ForegroundColor White
Write-Host "  MEMORY.md: `$(if (`$MEMORY_Exists) { "✓ 存在" } else { "✗ 不存在" })" -ForegroundColor `$(if (`$MEMORY_Exists) { "Green" } else { "Red" })
Write-Host ""

Write-Host "🔍 LanceDB 数据库" -ForegroundColor Yellow
Write-Host "  状态: `$(if (`$lanceDbExists) { "✓ 存在" } else { "✗ 不存在" })" -ForegroundColor `$(if (`$lanceDbExists) { "Green" } else { "Red" })
if (`$lanceDbExists) {
    `$dbSize = (Get-ChildItem `$lanceDb -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "  大小: `$([math]::Round(`$dbSize, 2)) MB" -ForegroundColor White
}
Write-Host ""

Write-Host "💾 备份统计" -ForegroundColor Yellow
Write-Host "  自动备份: `$backupCount 个" -ForegroundColor White
Write-Host "  完整快照: `$snapshotCount 个" -ForegroundColor White
Write-Host ""

Write-Host "📋 Git 状态" -ForegroundColor Yellow
if (`$gitStatus) {
    Write-Host "  ⚠ 有未提交的更改" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ 工作区干净" -ForegroundColor Green
}
Write-Host ""

Write-Host "📝 定时任务" -ForegroundColor Yellow
`$tasks = Get-ScheduledTask -TaskName "小妖-*" -ErrorAction SilentlyContinue
if (`$tasks) {
    foreach (`$task in `$tasks) {
        `$state = `$task.State
        `$lastRun = `$task.LastRunTime
        `$nextRun = `$task.NextRunTime
        Write-Host "  [`$state] `$(`$task.TaskName)" -ForegroundColor White
        if (`$lastRun -ne `$null) {
            Write-Host "    上次运行: `$(`$lastRun.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
        }
        if (`$nextRun -ne `$null) {
            Write-Host "    下次运行: `$(`$nextRun.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  ✗ 没有找到定时任务" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "按任意键退出..." -ForegroundColor Gray
`$null = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
"@

$dashboardPath = "$scriptDir\memory-dashboard.ps1"
$dashboardScript | Out-File -FilePath $dashboardPath -Encoding UTF8
Write-Host "  ✓ 监控面板已创建" -ForegroundColor Green

Write-Host ""

# 完成
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 记忆零丢失系统配置完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "下一步操作:" -ForegroundColor Cyan
Write-Host "  1. 查看监控面板:" -ForegroundColor Gray
Write-Host "     & `"$scriptDir\memory-dashboard.ps1`"" -ForegroundColor White
Write-Host ""
Write-Host "  2. 手动测试备份:" -ForegroundColor Gray
Write-Host "     & `"$scriptDir\backup-memory.ps1`"" -ForegroundColor White
Write-Host ""
Write-Host "  3. 检查定时任务:" -ForegroundColor Gray
Write-Host "     Get-ScheduledTask -TaskName '小妖-*'" -ForegroundColor White
Write-Host ""
Write-Host "  4. 查看日志:" -ForegroundColor Gray
Write-Host "     Get-Content `"$logDir\memory-backup.log`" -Tail 50" -ForegroundColor White
Write-Host ""

Write-Host "配置文件位置:" -ForegroundColor Cyan
Write-Host "  - 主配置: `"$workspaceDir\MEMORY-ZERO-LOSS-CONFIG.md`"" -ForegroundColor Gray
Write-Host "  - 备份目录: `"$backupDir`"" -ForegroundColor Gray
Write-Host "  - 快照目录: `"$snapshotDir`"" -ForegroundColor Gray
Write-Host "  - 日志目录: `"$logDir`"" -ForegroundColor Gray
Write-Host ""

Write-Host "🎉 记忆零丢失系统已准备就绪！" -ForegroundColor Green
Write-Host ""
