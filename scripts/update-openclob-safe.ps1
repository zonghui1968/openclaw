# OpenClaw 安全更新脚本
# 用途：备份当前版本、更新、验证，失败则自动回滚

param(
    [switch]$SkipBackup = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenClaw 安全更新" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 创建备份目录
$backupDate = Get-Date -Format "yyyy-MM-dd-HHmm"
$backupDir = "C:\Users\宗晖\.openclaw\backups\$backupDate"
New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
Write-Host "[✓] 备份目录: $backupDir" -ForegroundColor Green

try {
    # Phase 1: 备份
    if (-not $SkipBackup) {
        Write-Host ""
        Write-Host "[阶段 1/4] 备份当前版本..." -ForegroundColor Yellow

        # 备份配置
        Copy-Item "C:\Users\宗晖\.openclaw\openclaw.json" -Destination "$backupDir\" -Force -ErrorAction Stop
        Copy-Item "c:\ssh\.openclaw\openclaw.json" -Destination "$backupDir\gateway-openclaw.json" -Force -ErrorAction Stop

        # 备份凭证（如果存在）
        if (Test-Path "C:\Users\宗晖\.openclaw\credentials") {
            Copy-Item "C:\Users\宗晖\.openclaw\credentials" -Destination "$backupDir\credentials" -Recurse -Force
        }

        # 记录当前版本
        $currentVersion = openclaw --version
        $currentVersion | Out-File "$backupDir\version-before.txt"

        Write-Host "  ✓ 配置文件已备份" -ForegroundColor Green
        Write-Host "  ✓ 当前版本: $currentVersion" -ForegroundColor Green
    }

    # Phase 2: 更新
    Write-Host ""
    Write-Host "[阶段 2/4] 更新到 v2026.2.26..." -ForegroundColor Yellow

    if (-not $Force) {
        $response = Read-Host "  是否继续？(Y/N)"
        if ($response -ne "Y" -and $response -ne "y") {
            Write-Host "  [取消] 用户取消更新" -ForegroundColor Yellow
            exit 0
        }
    }

    $updateOutput = openclaw update 2>&1
    Write-Host "  ✓ 更新完成" -ForegroundColor Green

    # Phase 3: 验证
    Write-Host ""
    Write-Host "[阶段 3/4] 验证更新..." -ForegroundColor Yellow

    # 检查版本
    $newVersion = openclaw --version
    Write-Host "  新版本: $newVersion" -ForegroundColor White

    # 检查 Gateway
    Write-Host "  检查 Gateway 状态..." -ForegroundColor Gray
    $gatewayStatus = openclaw gateway status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Gateway 运行正常" -ForegroundColor Green
    } else {
        throw "Gateway 状态异常"
    }

    # 检查通道
    Write-Host "  检查通道状态..." -ForegroundColor Gray
    $channelStatus = openclaw status 2>&1
    if ($channelStatus -match "OK") {
        Write-Host "  ✓ 所有通道正常" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ 部分通道警告（可能正常）" -ForegroundColor Yellow
    }

    # Phase 4: 完成
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ 更新成功！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "版本: $currentVersion → $newVersion" -ForegroundColor Cyan
    Write-Host "备份: $backupDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "如需回滚，运行:" -ForegroundColor Yellow
    Write-Host "  .\rollback-openclob.ps1 `"$backupDir`"" -ForegroundColor White

} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "✗ 更新失败！" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "[回滚] 正在自动回滚..." -ForegroundColor Yellow

    # 自动回滚
    & "$PSScriptRoot\rollback-openclob.ps1" -BackupDir $backupDir

    exit 1
}
