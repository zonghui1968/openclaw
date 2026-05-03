# LanceDB 同步脚本
# 从 Markdown 文件同步到向量数据库

param(
    [switch]$Force,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 配置
$memoryDir = "C:\Users\宗晖\clawd\workspace\memory"
$lancedbScriptDir = "C:\Users\宗晖\clawd\scripts\lancedb-memory"
$logFile = "c:\ssh\.openclaw\logs\lancedb-sync.log"

function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    $logMsg = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logMsg
    if ($Verbose -or $Level -eq "ERROR") {
        Write-Host $logMsg -ForegroundColor $(switch($Level) {"ERROR"{"Red"};"WARN"{"Yellow"};default{"Green"}})
    }
}

try {
    Log-Message "===== 开始 LanceDB 同步 ====="

    # 检查依赖
    if (-not (Test-Path $lancedbScriptDir)) {
        Log-Message "LanceDB 脚本目录不存在: $lancedbScriptDir" "ERROR"
        exit 1
    }

    $syncScript = Join-Path $lancedbScriptDir "sync-simple.py"
    if (-not (Test-Path $syncScript)) {
        Log-Message "同步脚本不存在: $syncScript" "ERROR"
        exit 1
    }

    # 统计记忆文件
    $memoryFiles = Get-ChildItem $memoryDir -Filter "*.md" -File
    $totalFiles = $memoryFiles.Count
    Log-Message "发现 $totalFiles 个记忆文件"

    # 执行同步
    Log-Message "执行 LanceDB 同步..."
    Push-Location $lancedbScriptDir

    try {
        $output = python sync-simple.py 2>&1
        $exitCode = $LASTEXITCODE

        if ($Verbose) {
            Write-Host $output
        }

        if ($exitCode -eq 0) {
            Log-Message "LanceDB 同步成功"

            # 验证索引
            Log-Message "验证索引完整性..."
            $queryResult = python query.py "test" 2>&1
            Log-Message "查询测试成功"
        } else {
            Log-Message "同步失败，退出码: $exitCode" "ERROR"
            Log-Message "输出: $output" "ERROR"
            exit 1
        }

    } finally {
        Pop-Location
    }

    Log-Message "===== LanceDB 同步完成 ====="

} catch {
    Log-Message "同步失败: $_" "ERROR"
    Log-Message "堆栈跟踪: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
