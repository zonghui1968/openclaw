# OpenClaw 回滚脚本
# 用途：回滚到备份的版本和配置

param(
    [string]$BackupDir = $null
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "OpenClaw 回滚" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

# 查找最新备份
if (-not $BackupDir) {
    $backups = Get-ChildItem "C:\Users\宗晖\.openclaw\backups" -Directory | Sort-Object LastWriteTime -Descending
    if ($backups.Count -eq 0) {
        Write-Host "✗ 未找到备份目录" -ForegroundColor Red
        exit 1
    }
    $BackupDir = $backups[0].FullName
    Write-Host "[使用] 最新备份: $BackupDir" -ForegroundColor Cyan
    Write-Host ""
}

try {
    # 读取备份版本
    if (Test-Path "$BackupDir\version-before.txt") {
        $oldVersion = Get-Content "$BackupDir\version-before.txt"
        Write-Host "[目标] 回滚到版本: $oldVersion" -ForegroundColor Cyan
    }

    # 确认
    $response = Read-Host "  确认回滚？(Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "  [取消] 用户取消回滚" -ForegroundColor Yellow
        exit 0
    }

    # 停止 Gateway
    Write-Host ""
    Write-Host "[步骤 1/5] 停止 Gateway..." -ForegroundColor Yellow
    openclaw gateway stop
    Write-Host "  ✓ Gateway 已停止" -ForegroundColor Green

    # 恢复配置
    Write-Host ""
    Write-Host "[步骤 2/5] 恢复配置文件..." -ForegroundColor Yellow
    if (Test-Path "$BackupDir\openclaw.json") {
        Copy-Item "$BackupDir\openclaw.json" -Destination "C:\Users\宗晖\.openclaw\" -Force
        Write-Host "  ✓ 用户配置已恢复" -ForegroundColor Green
    }

    if (Test-Path "$BackupDir\gateway-openclaw.json") {
        Copy-Item "$BackupDir\gateway-openclaw.json" -Destination "c:\ssh\.openclaw\" -Force
        Write-Host "  ✓ Gateway 配置已恢复" -ForegroundColor Green
    }

    # 恢复凭证
    if (Test-Path "$BackupDir\credentials") {
        Copy-Item "$BackupDir\credentials" -Destination "C:\Users\宗晖\.openclaw\" -Recurse -Force
        Write-Host "  ✓ 凭证已恢复" -ForegroundColor Green
    }

    # 回滚版本
    Write-Host ""
    Write-Host "[步骤 3/5] 回滚版本..." -ForegroundColor Yellow
    if (Test-Path "$BackupDir\version-before.txt") {
        $oldVersion = Get-Content "$BackupDir\version-before.txt"
        npm install -g @openclaw/cli@$oldVersion
        Write-Host "  ✓ 已回滚到 $oldVersion" -ForegroundColor Green
    }

    # 重启 Gateway
    Write-Host ""
    Write-Host "[步骤 4/5] 重启 Gateway..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    openclaw gateway restart

    # 等待启动
    Write-Host "  等待 Gateway 启动..." -ForegroundColor Gray
    Start-Sleep -Seconds 5

    # 验证
    Write-Host ""
    Write-Host "[步骤 5/5] 验证状态..." -ForegroundColor Yellow
    $version = openclaw --version
    Write-Host "  当前版本: $version" -ForegroundColor White

    $gatewayStatus = openclaw gateway status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Gateway 运行正常" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Gateway 异常" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "✅ 回滚完成！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "✗ 回滚失败！" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "请手动检查系统状态" -ForegroundColor Yellow
    exit 1
}
