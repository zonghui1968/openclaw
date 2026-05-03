# OpenClaw Sessions 压缩和清理脚本
# 用于压缩和删除旧的会话文件

param(
    [int]$DaysToKeep = 7,  # 保留最近 N 天的会话
    [switch]$Compress,     # 是否压缩备份
    [switch]$Delete        # 是否删除旧文件
)

$ErrorActionPreference = "Stop"

# 配置
$sessionsDir = "C:\Users\宗晖\.openclaw\agents\main\sessions"
$backupDir = "C:\Users\宗晖\.openclaw\sessions-archive"
$timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "OpenClaw Sessions 清理工具" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 创建备份目录
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "✓ 创建备份目录: $backupDir" -ForegroundColor Green
}

# 查找旧的会话文件
Write-Host "正在扫描旧会话文件..." -ForegroundColor Yellow
$oldSessions = Get-ChildItem -Path $sessionsDir -Recurse -File -Filter "*.jsonl" |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysToKeep) }

if ($oldSessions.Count -eq 0) {
    Write-Host "✓ 没有找到超过 $DaysToKeep 天的旧会话" -ForegroundColor Green
    exit 0
}

# 显示统计信息
$totalSize = ($oldSessions | Measure-Object -Property Length -Sum).Sum
$totalSizeMB = [math]::Round($totalSize/1MB, 2)
Write-Host "找到 $($oldSessions.Count) 个旧会话文件" -ForegroundColor Cyan
Write-Host "总大小: $totalSizeMB MB" -ForegroundColor Cyan
Write-Host ""

# 显示将要删除的文件
Write-Host "将被清理的文件:" -ForegroundColor Yellow
$oldSessions | Sort-Object LastWriteTime -Descending | Format-Table Name, LastWriteTime, Length -AutoSize

# 压缩备份
if ($Compress) {
    Write-Host ""
    Write-Host "正在压缩备份..." -ForegroundColor Yellow

    $zipFile = Join-Path $backupDir "sessions-backup-$timestamp.zip"
    $tempDir = Join-Path $env:TEMP "sessions-backup-$timestamp"

    # 创建临时目录
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        # 复制文件到临时目录（保持目录结构）
        foreach ($file in $oldSessions) {
            $relativePath = $file.FullName.Substring($sessionsDir.Length)
            $destPath = Join-Path $tempDir $relativePath
            $destDir = Split-Path $destPath -Parent

            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }

            Copy-Item $file.FullName $destPath -Force
        }

        # 创建 ZIP 文件
        Compress-Archive -Path "$tempDir\*" -DestinationPath $zipFile -CompressionLevel Optimal -Force

        $zipSize = (Get-Item $zipFile).Length / 1MB
        Write-Host "✓ 备份已创建: $zipFile ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor Green
        Write-Host "  压缩率: $([math]::Round((1 - $zipSize / $totalSizeMB) * 100, 1))%" -ForegroundColor Gray
    }
    finally {
        # 清理临时目录
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 删除旧文件
if ($Delete) {
    Write-Host ""
    Write-Host "正在删除旧会话..." -ForegroundColor Yellow

    $deletedCount = 0
    foreach ($file in $oldSessions) {
        try {
            Remove-Item $file.FullName -Force
            $deletedCount++
            Write-Host "  ✓ 删除: $($file.Name)" -ForegroundColor Gray
        }
        catch {
            Write-Host "  ✗ 删除失败: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "✓ 已删除 $deletedCount 个文件" -ForegroundColor Green
    Write-Host "✓ 释放空间: $totalSizeMB MB" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "提示: 使用 -Delete 参数来实际删除文件" -ForegroundColor Yellow
    Write-Host "示例: .\compress-sessions.ps1 -DaysToKeep 7 -Compress -Delete" -ForegroundColor Gray
}

# 显示当前会话统计
Write-Host ""
Write-Host "当前会话统计:" -ForegroundColor Cyan
$currentSessions = Get-ChildItem -Path $sessionsDir -Recurse -File -Filter "*.jsonl"
$currentSize = ($currentSessions | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "  文件数: $($currentSessions.Count)" -ForegroundColor Gray
Write-Host "  总大小: $([math]::Round($currentSize, 2)) MB" -ForegroundColor Gray

Write-Host ""
Write-Host "完成!" -ForegroundColor Green
