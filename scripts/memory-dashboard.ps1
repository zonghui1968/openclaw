# 记忆系统监控面板

$workspaceDir = "c:\ssh\.openclaw\workspace"
$mainMemory = "C:\Users\宗晖\clawd\workspace\memory"
$lanceDb = "C:\Users\宗晖\.openclaw\memorydb\memories.lance"
$backupDir = "C:\Users\宗晖\.openclaw\memory-backups"
$snapshotDir = "C:\Users\宗晖\.openclaw\memory-snapshots"
$logDir = "c:\ssh\.openclaw\logs"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "记忆系统监控面板" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 统计信息
$memoryFiles = Get-ChildItem $mainMemory -Filter "*.md" -File -ErrorAction SilentlyContinue
$MEMORY_Exists = Test-Path "$mainMemory\MEMORY.md"
$lanceDbExists = Test-Path $lanceDb
$backupCount = (Get-ChildItem $backupDir -Filter "*.zip" -File -ErrorAction SilentlyContinue).Count
$snapshotCount = (Get-ChildItem $snapshotDir -Filter "*.zip" -File -ErrorAction SilentlyContinue).Count
$gitStatus = git -C $workspaceDir status --short 2>$null

Write-Host "📊 记忆文件统计" -ForegroundColor Yellow
Write-Host "  总数: $($memoryFiles.Count) 个" -ForegroundColor White
if ($MEMORY_Exists) {
    Write-Host "  MEMORY.md: ✓ 存在" -ForegroundColor Green
} else {
    Write-Host "  MEMORY.md: ✗ 不存在" -ForegroundColor Red
}
Write-Host ""

Write-Host "🔍 LanceDB 数据库" -ForegroundColor Yellow
if ($lanceDbExists) {
    Write-Host "  状态: ✓ 存在" -ForegroundColor Green
    $dbSize = (Get-ChildItem $lanceDb -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "  大小: $([math]::Round($dbSize, 2)) MB" -ForegroundColor White
} else {
    Write-Host "  状态: ✗ 不存在" -ForegroundColor Red
}
Write-Host ""

Write-Host "💾 备份统计" -ForegroundColor Yellow
Write-Host "  自动备份: $backupCount 个" -ForegroundColor White
Write-Host "  完整快照: $snapshotCount 个" -ForegroundColor White
Write-Host ""

Write-Host "📋 Git 状态" -ForegroundColor Yellow
if ($gitStatus) {
    Write-Host "  ⚠ 有未提交的更改" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ 工作区干净" -ForegroundColor Green
}
Write-Host ""

Write-Host "📝 定时任务" -ForegroundColor Yellow
$tasks = Get-ScheduledTask -TaskName "小妖-*" -ErrorAction SilentlyContinue
if ($tasks) {
    foreach ($task in $tasks) {
        $state = $task.State
        $lastRun = $task.LastRunTime
        $nextRun = $task.NextRunTime
        Write-Host "  [$state] $($task.TaskName)" -ForegroundColor White
        if ($lastRun -ne $null) {
            Write-Host "    上次运行: $($lastRun.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
        }
        if ($nextRun -ne $null) {
            Write-Host "    下次运行: $($nextRun.ToString('yyyy-MM-dd HH:mm'))" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  ✗ 没有找到定时任务（需要管理员权限配置）" -ForegroundColor Red
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
