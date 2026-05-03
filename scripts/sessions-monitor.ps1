# Sessions Monitor - 会话存储监控脚本
# 监控 sessions 使用率，达到阈值时自动压缩备份

param(
    [double]$Threshold = 65,      # 触发压缩的阈值（百分比）
    [int]$DaysToKeep = 7,         # 保留最近 N 天的会话
    [switch]$Force                # 强制执行压缩
)

$ErrorActionPreference = "Stop"

# 配置
$sessionsDir = "C:\Users\宗晖\.openclaw\agents\main\sessions"
$maxSessionsSize = 20MB           # 假设最大 sessions 大小为 20MB
$compressScript = "c:\ssh\.openclaw\scripts\compress-sessions.ps1"

$separator = "=" * 60
Write-Host "🦊 Sessions 存储监控" -ForegroundColor Cyan
Write-Host $separator
Write-Host ""

# 检查 sessions 目录
if (-not (Test-Path $sessionsDir)) {
    Write-Host "❌ Sessions 目录不存在: $sessionsDir" -ForegroundColor Red
    exit 1
}

# 计算 sessions 总大小
Write-Host "📊 正在计算 sessions 存储使用率..." -ForegroundColor Yellow
$sessions = Get-ChildItem -Path $sessionsDir -Recurse -File -Filter "*.jsonl"
$totalSize = ($sessions | Measure-Object -Property Length -Sum).Sum
$usagePercent = ($totalSize / $maxSessionsSize) * 100

$totalSizeMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "  当前大小: $totalSizeMB MB" -ForegroundColor Cyan
Write-Host "  使用率: $([math]::Round($usagePercent, 1))%" -ForegroundColor Cyan
Write-Host ""

# 判断是否需要压缩
if ($usagePercent -ge $Threshold -or $Force) {
    Write-Host "⚠️  Sessions 使用率已达到阈值 ($([math]::Round($usagePercent, 1))% >= $Threshold%)" -ForegroundColor Yellow
    Write-Host "🔧 正在执行自动压缩..." -ForegroundColor Yellow
    Write-Host ""

    # 检查压缩脚本
    if (-not (Test-Path $compressScript)) {
        Write-Host "❌ 压缩脚本不存在: $compressScript" -ForegroundColor Red
        exit 1
    }

    # 执行压缩
    try {
        & $compressScript -DaysToKeep $DaysToKeep -Compress -Delete

        # 发送通知
        Write-Host ""
        Write-Host "📧 发送通知..." -ForegroundColor Yellow
        $notification = "✅ Sessions 自动压缩完成`n`n" +
                       "压缩前: $totalSizeMB MB ($([math]::Round($usagePercent, 1))%)`n" +
                       "压缩时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n`n" +
                       "详细报告请查看 OpenClaw 日志"

        # 保存通知到文件
        $notifyFile = "$env:USERPROFILE\.openclaw\cache\sessions-notify.txt"
        $notifyFile | Split-Path | New-Item -ItemType Directory -Force | Out-Null
        $notification | Out-File -FilePath $notifyFile -Encoding UTF8

        Write-Host "✅ 通知已保存: $notifyFile" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ 压缩失败: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    $remainingPercent = $Threshold - $usagePercent
    Write-Host "✅ Sessions 使用率正常" -ForegroundColor Green
    Write-Host "  当前: $([math]::Round($usagePercent, 1))% / 阈值: $Threshold%" -ForegroundColor Gray
    Write-Host "  剩余: $([math]::Round($remainingPercent, 1))%" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 提示: 当使用率达到 $Threshold% 时，将自动执行压缩" -ForegroundColor Yellow
}

Write-Host ""
Write-Host $separator
Write-Host "✅ Sessions 监控完成" -ForegroundColor Green
Write-Host $separator
