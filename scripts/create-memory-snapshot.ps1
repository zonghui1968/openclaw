# 创建记忆完整快照
# 每周日执行，保留长期备份

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 配置
$mainMemory = "C:\Users\宗晖\clawd\workspace\memory"
$lanceDb = "C:\Users\宗晖\.openclaw\memorydb"
$snapshotDir = "C:\Users\宗晖\.openclaw\memory-snapshots"
$gitDir = "c:\ssh\.openclaw\workspace"
$logFile = "c:\ssh\.openclaw\logs\memory-snapshot.log"

# 确保目录存在
if (-not (Test-Path $snapshotDir)) {
    New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
}
if (-not (Test-Path "c:\ssh\.openclaw\logs")) {
    New-Item -ItemType Directory -Path "c:\ssh\.openclaw\logs" -Force | Out-Null
}

function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    $logMsg = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMsg
    Write-Host $logMsg -ForegroundColor $(switch($Level) {"ERROR"{"Red"};"WARN"{"Yellow"};default{"Green"}})
}

try {
    Log-Message "===== 开始创建记忆快照 ====="

    # 创建快照文件名
    $dateTag = Get-Date -Format "yyyy-MM-dd"
    $snapshotFile = "memory-snapshot-$dateTag.zip"
    $snapshotPath = Join-Path $snapshotDir $snapshotFile

    # 检查是否今日已创建
    if ((Test-Path $snapshotPath) -and -not $Force) {
        Log-Message "今日快照已存在，跳过创建（使用 -Force 强制重新创建）"
        exit 0
    }

    # 创建临时目录
    $tempDir = Join-Path $env:TEMP "memory-snapshot-$(Get-Date -Format 'yyyyMMddHHmmss')"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        # 步骤 1：备份记忆文件
        Log-Message "步骤 1/4: 备份记忆文件"
        $memoryBackup = Join-Path $tempDir "memory"
        Copy-Item -Path "$mainMemory\*" -Destination $memoryBackup -Recurse -Force
        $fileCount = (Get-ChildItem $memoryBackup -Recurse -File).Count
        Log-Message "备份了 $fileCount 个文件"

        # 步骤 2：备份 LanceDB 数据库
        Log-Message "步骤 2/4: 备份 LanceDB 数据库"
        if (Test-Path $lanceDb) {
            $lanceBackup = Join-Path $tempDir "lancedb"
            Copy-Item -Path "$lanceDb\*" -Destination $lanceBackup -Recurse -Force
            $lanceSize = (Get-ChildItem $lanceBackup -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
            Log-Message "备份了 LanceDB ($([math]::Round($lanceSize, 2)) MB)"
        } else {
            Log-Message "LanceDB 不存在，跳过" "WARN"
        }

        # 步骤 3：导出 Git 历史
        Log-Message "步骤 3/4: 导出 Git 历史"
        if (Test-Path "$gitDir\.git") {
            Push-Location $gitDir
            try {
                $gitExport = Join-Path $tempDir "git-info.txt"
                git log --oneline --graph --all -20 > $gitExport
                Log-Message "导出了最近的 Git 历史"
            } finally {
                Pop-Location
            }
        }

        # 步骤 4：创建压缩包
        Log-Message "步骤 4/4: 创建压缩包"
        Compress-Archive -Path "$tempDir\*" -DestinationPath $snapshotPath -Force
        $snapshotSize = (Get-Item $snapshotPath).Length / 1MB
        Log-Message "创建快照: $snapshotFile ($([math]::Round($snapshotSize, 2)) MB)"

        # 创建元数据文件
        $metaData = @"
记忆快照元数据

创建时间：$timestamp
快照文件：$snapshotFile
文件数量：$fileCount
快照大小：$([math]::Round($snapshotSize, 2)) MB
LanceDB 大小：$([math]::Round($lanceSize, 2)) MB
"@

        $metaFile = $snapshotPath -replace '\.zip$', '.txt'
        $metaData | Out-File -FilePath $metaFile -Encoding UTF8

        Log-Message "元数据已保存: $metaFile"

    } finally {
        # 清理临时目录
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # 清理旧快照（保留策略：最近 4 周 + 每月最后一个周日）
    Log-Message "清理旧快照..."
    $snapshots = Get-ChildItem $snapshotDir -Filter "memory-snapshot-*.zip" |
                 Sort-Object LastWriteTime -Descending

    # 保留最近 4 周
    $keepRecent = 28
    $cutoffDate = (Get-Date).AddDays(-$keepRecent)

    # 找出每月最后一个周日
    $monthlySnapshots = @()
    for ($i = 1; $i -le 12; $i++) {
        $lastDay = [DateTime]::DaysInMonth((Get-Date).Year, $i)
        $lastDate = Get-Date -Year (Get-Date).Year -Month $i -Day $lastDay
        while ($lastDate.DayOfWeek -ne "Sunday") {
            $lastDate = $lastDate.AddDays(-1)
        }
        $monthlySnapshots += $lastDate.ToString("yyyy-MM-dd")
    }

    # 删除不符合保留条件的快照
    foreach ($snapshot in $snapshots) {
        $dateStr = $snapshot.Name -replace 'memory-snapshot-(\d{4}-\d{2}-\d{2})\.zip', '$1'
        $snapshotDate = [DateTime]::Parse($dateStr)

        $shouldKeep = $false

        # 保留最近 4 周
        if ($snapshotDate -gt $cutoffDate) {
            $shouldKeep = $true
        }

        # 保留每月最后一个周日
        if ($monthlySnapshots -contains $dateStr) {
            $shouldKeep = $true
        }

        if (-not $shouldKeep) {
            Remove-Item $snapshot.FullName -Force
            Log-Message "删除旧快照: $($snapshot.Name)"
        }
    }

    Log-Message "===== 记忆快照创建完成 ====="

} catch {
    Log-Message "快照创建失败: $_" "ERROR"
    Log-Message "堆栈跟踪: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
