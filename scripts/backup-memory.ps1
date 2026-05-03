# 记忆自动备份脚本
# 每天 4 次，确保零丢失

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 配置
$workspaceMemory = "c:\ssh\.openclaw\workspace\memory"
$mainMemory = "C:\Users\宗晖\clawd\workspace\memory"
$backupDir = "C:\Users\宗晖\.openclaw\memory-backups"
$logFile = "c:\ssh\.openclaw\logs\memory-backup.log"

# 确保目录存在
$dirs = @($workspaceMemory, $mainMemory, $backupDir, "c:\ssh\.openclaw\logs")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    $logMsg = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMsg
    Write-Host $logMsg -ForegroundColor $(switch($Level) {"ERROR"{"Red"};"WARN"{"Yellow"};default{"Green"}})
}

try {
    Log-Message "===== 开始记忆备份 ====="

    # 步骤 1：同步工作区到主目录
    Log-Message "步骤 1/5: 同步工作区到主目录"
    if (Test-Path $workspaceMemory) {
        Copy-Item -Path "$workspaceMemory\*" -Destination $mainMemory -Recurse -Force
        $fileCount = (Get-ChildItem $mainMemory -File).Count
        Log-Message "已同步 $fileCount 个文件"
    } else {
        Log-Message "工作区记忆目录不存在" "WARN"
    }

    # 步骤 2：创建备份快照
    Log-Message "步骤 2/5: 创建备份快照"
    $snapshotName = "memory-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
    $snapshotPath = Join-Path $backupDir $snapshotName
    Compress-Archive -Path "$mainMemory\*" -DestinationPath $snapshotPath -Force
    $snapshotSize = (Get-Item $snapshotPath).Length / 1KB
    Log-Message "创建快照: $snapshotName ($([math]::Round($snapshotSize, 2)) KB)"

    # 步骤 3：清理旧备份（保留最近 7 天）
    Log-Message "步骤 3/5: 清理旧备份"
    $cutoffDate = (Get-Date).AddDays(-7)
    $oldBackups = Get-ChildItem $backupDir -Filter "memory-backup-*.zip" |
                  Where-Object { $_.LastWriteTime -lt $cutoffDate }
    if ($oldBackups) {
        $oldBackups | Remove-Item -Force
        Log-Message "已删除 $($oldBackups.Count) 个旧备份"
    } else {
        Log-Message "没有需要清理的旧备份"
    }

    # 步骤 4：Git 自动提交
    Log-Message "步骤 4/5: Git 自动提交"
    $gitDir = "c:\ssh\.openclaw\workspace"
    if (Test-Path "$gitDir\.git") {
        Push-Location $gitDir
        try {
            # 检查是否有更改
            $status = git status --short
            if ($status) {
                git add memory/
                git commit -m "Memory backup: $timestamp"
                Log-Message "Git 提交成功"
            } else {
                Log-Message "没有新的更改需要提交"
            }
        } finally {
            Pop-Location
        }
    } else {
        Log-Message "Git 仓库未初始化，跳过提交" "WARN"
    }

    # 步骤 5：验证备份完整性
    Log-Message "步骤 5/5: 验证备份完整性"
    $memoryFiles = Get-ChildItem $mainMemory -Filter "*.md" -File
    $MEMORY_Exists = Test-Path "$mainMemory\MEMORY.md"
    Log-Message "发现 $($memoryFiles.Count) 个记忆文件"
    Log-Message "MEMORY.md 存在: $MEMORY_Exists"

    if (-not $MEMORY_Exists) {
        Log-Message "警告：MEMORY.md 不存在！" "ERROR"
    }

    Log-Message "===== 记忆备份完成 ====="

    # 发送邮件报告
    $emailBody = @"
记忆备份报告

时间：$timestamp
状态：成功

详细信息：
- 同步文件：$fileCount 个
- 备份大小：$([math]::Round($snapshotSize, 2)) KB
- 备份文件：$snapshotName
- 记忆文件：$($memoryFiles.Count) 个
- MEMORY.md：$($MEMORY_Exists ? "存在" : "不存在")

所有操作已记录到：$logFile
"@

    # 发送邮件（使用现有的邮件发送脚本）
    $emailScript = "c:\ssh\.openclaw\scripts\send-email.ps1"
    if (Test-Path $emailScript) {
        & $emailScript -Subject "记忆备份成功" -Body $emailBody
    }

} catch {
    Log-Message "备份失败: $_" "ERROR"
    Log-Message "堆栈跟踪: $($_.ScriptStackTrace)" "ERROR"

    # 发送错误报告
    $errorBody = @"
记忆备份报告

时间：$timestamp
状态：失败

错误信息：$_
堆栈跟踪：$($_.ScriptStackTrace)

请立即检查日志：$logFile
"@

    $emailScript = "c:\ssh\.openclaw\scripts\send-email.ps1"
    if (Test-Path $emailScript) {
        & $emailScript -Subject "【紧急】记忆备份失败！" -Body $errorBody
    }

    exit 1
}
