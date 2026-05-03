# 记忆完整性检查脚本
# 验证记忆系统的完整性

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 配置
$workspaceMemory = "c:\ssh\.openclaw\workspace\memory"
$mainMemory = "C:\Users\宗晖\clawd\workspace\memory"
$lanceDb = "C:\Users\宗晖\.openclaw\memorydb\memories.lance"
$logFile = "c:\ssh\.openclaw\logs\memory-integrity.log"
$emailScript = "c:\ssh\.openclaw\scripts\send-email.ps1"

# 告警配置
$alertEmail = "hizonghui@gmail.com"
$alertCc = "ruoli.jia@gmail.com"

$issues = @()

function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    $logMsg = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMsg
    if ($Verbose -or $Level -eq "ERROR") {
        Write-Host $logMsg -ForegroundColor $(switch($Level) {"ERROR"{"Red"};"WARN"{"Yellow"};default{"Green"}})
    }
}

function Add-Issue {
    param([string]$Issue, [string]$Severity = "WARN")
    $issues += @{Issue = $Issue; Severity = $Severity; Time = $timestamp}
    Log-Message $Issue $Severity
}

try {
    Log-Message "===== 开始记忆完整性检查 ====="

    # 检查 1：工作区目录存在
    Log-Message "检查 1/7: 工作区目录"
    if (-not (Test-Path $workspaceMemory)) {
        Add-Issue "工作区记忆目录不存在: $workspaceMemory" "ERROR"
    } else {
        Log-Message "工作区目录存在"
    }

    # 检查 2：主目录存在
    Log-Message "检查 2/7: 主目录"
    if (-not (Test-Path $mainMemory)) {
        Add-Issue "主记忆目录不存在: $mainMemory" "ERROR"
    } else {
        Log-Message "主目录存在"
    }

    # 检查 3：MEMORY.md 存在
    Log-Message "检查 3/7: MEMORY.md"
    $memoryMd = Join-Path $mainMemory "MEMORY.md"
    if (-not (Test-Path $memoryMd)) {
        Add-Issue "MEMORY.md 不存在: $memoryMd" "ERROR"
    } else {
        $size = (Get-Item $memoryMd).Length
        Log-Message "MEMORY.md 存在 ($size 字节)"
    }

    # 检查 4：记忆文件数量
    Log-Message "检查 4/7: 记忆文件数量"
    if (Test-Path $mainMemory) {
        $memoryFiles = Get-ChildItem $mainMemory -Filter "*.md" -File
        $count = $memoryFiles.Count
        Log-Message "发现 $count 个记忆文件"

        if ($count -lt 10) {
            Add-Issue "记忆文件数量异常少: $count" "WARN"
        }
    }

    # 检查 5：最近 7 天的记忆
    Log-Message "检查 5/7: 最近 7 天的记忆"
    if (Test-Path $mainMemory) {
        $cutoffDate = (Get-Date).AddDays(-7)
        $recentFiles = Get-ChildItem $mainMemory -Filter "202*.md" -File |
                      Where-Object { $_.LastWriteTime -gt $cutoffDate }
        Log-Message "最近 7 天有 $($recentFiles.Count) 个记忆文件"

        if ($recentFiles.Count -eq 0) {
            Add-Issue "最近 7 天没有新的记忆文件" "WARN"
        }
    }

    # 检查 6：LanceDB 数据库
    Log-Message "检查 6/7: LanceDB 数据库"
    if (-not (Test-Path $lanceDb)) {
        Add-Issue "LanceDB 数据库不存在: $lanceDb" "ERROR"
    } else {
        $dbSize = (Get-ChildItem $lanceDb -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
        Log-Message "LanceDB 数据库存在 ($([math]::Round($dbSize, 2)) MB)"
    }

    # 检查 7：Git 版本控制
    Log-Message "检查 7/7: Git 版本控制"
    $gitDir = "c:\ssh\.openclaw\.git"
    if (-not (Test-Path $gitDir)) {
        Add-Issue "Git 仓库未初始化" "WARN"
    } else {
        Push-Location "c:\ssh\.openclaw\workspace"
        try {
            $status = git status --short
            if ($status) {
                Log-Message "Git 有未提交的更改"
            } else {
                Log-Message "Git 工作区干净"
            }
        } finally {
            Pop-Location
        }
    }

    Log-Message "===== 记忆完整性检查完成 ====="

    # 汇总报告
    Log-Message "发现问题: $($issues.Count) 个"

    if ($issues.Count -gt 0) {
        $errorIssues = $issues | Where-Object { $_.Severity -eq "ERROR" }
        $warnIssues = $issues | Where-Object { $_.Severity -eq "WARN" }

        Log-Message "错误: $($errorIssues.Count) 个"
        Log-Message "警告: $($warnIssues.Count) 个"

        # 发送告警邮件
        $emailBody = @"
记忆完整性检查报告

时间：$timestamp
状态：发现 $($issues.Count) 个问题

错误 ($($errorIssues.Count) 个):
$($errorIssues | ForEach-Object { "[$($_.Severity)] $($_.Issue)" } | Out-String)

警告 ($($warnIssues.Count) 个):
$($warnIssues | ForEach-Object { "[$($_.Severity)] $($_.Issue)" } | Out-String)

请立即检查并修复问题。

日志文件：$logFile
"@

        if ((Test-Path $emailScript) -and $errorIssues.Count -gt 0) {
            & $emailScript -Subject "【告警】记忆完整性检查发现问题" -Body $emailBody
            Log-Message "已发送告警邮件"
        }

        exit 1
    } else {
        Log-Message "所有检查通过，记忆系统健康"
        exit 0
    }

} catch {
    Log-Message "检查失败: $_" "ERROR"
    Log-Message "堆栈跟踪: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
