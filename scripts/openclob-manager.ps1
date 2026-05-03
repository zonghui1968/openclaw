# OpenClaw 更新与回滚 - 一键启动脚本
# 用途：安全更新 v2026.2.26，完整备份，失败自动回滚

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("update", "rollback", "health", "monitor", "status")]
    [string]$Action = "status"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "OpenClaw 更新与回滚系统" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    "update" {
        Write-Host "[操作] 安全更新到 v2026.2.26" -ForegroundColor Green
        Write-Host ""
        & "$PSScriptRoot\update-openclob-safe.ps1"
    }

    "rollback" {
        Write-Host "[操作] 回滚到备份版本" -ForegroundColor Yellow
        Write-Host ""
        & "$PSScriptRoot\rollback-openclob.ps1"
    }

    "health" {
        Write-Host "[操作] 健康检查" -ForegroundColor Cyan
        Write-Host ""
        & "$PSScriptRoot\health-check.ps1" -AutoFix
    }

    "monitor" {
        Write-Host "[操作] 启动自动监控" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "监控配置:" -ForegroundColor Yellow
        Write-Host "  检查间隔: 60 秒" -ForegroundColor White
        Write-Host "  最大重启: 5 次" -ForegroundColor White
        Write-Host "  按 Ctrl+C 停止监控" -ForegroundColor Yellow
        Write-Host ""
        & "$PSScriptRoot\auto-fix.ps1" -Loop
    }

    "status" {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "当前状态" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""

        # 检查版本
        Write-Host "[版本信息]" -ForegroundColor Yellow
        try {
            $version = openclaw --version
            Write-Host "  当前版本: $version" -ForegroundColor White
            Write-Host "  最新版本: v2026.2.26" -ForegroundColor Gray
        } catch {
            Write-Host "  ✗ 无法获取版本" -ForegroundColor Red
        }

        # 检查备份
        Write-Host ""
        Write-Host "[备份状态]" -ForegroundColor Yellow
        $backupDir = "C:\Users\宗晖\.openclaw\backups"
        if (Test-Path $backupDir) {
            $backups = Get-ChildItem $backupDir -Directory | Sort-Object LastWriteTime -Descending
            if ($backups.Count -gt 0) {
                Write-Host "  备份数量: $($backups.Count)" -ForegroundColor White
                Write-Host "  最新备份: $($backups[0].Name)" -ForegroundColor White
                Write-Host "  备份时间: $($backups[0].LastWriteTime)" -ForegroundColor White
            } else {
                Write-Host "  ℹ 无备份" -ForegroundColor Gray
            }
        } else {
            Write-Host "  ℹ 备份目录不存在" -ForegroundColor Gray
        }

        # 检查 Gateway
        Write-Host ""
        Write-Host "[Gateway 状态]" -ForegroundColor Yellow
        $gatewayStatus = openclaw gateway status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ Gateway 运行正常" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Gateway 未运行" -ForegroundColor Red
        }

        # 快速健康检查
        Write-Host ""
        Write-Host "[快速检查]" -ForegroundColor Yellow
        & "$PSScriptRoot\health-check.ps1"

        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "可用操作" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "安全更新:" -ForegroundColor White
        Write-Host "  .\openclob-manager.ps1 update" -ForegroundColor Gray
        Write-Host ""
        Write-Host "回滚版本:" -ForegroundColor White
        Write-Host "  .\openclob-manager.ps1 rollback" -ForegroundColor Gray
        Write-Host ""
        Write-Host "健康检查:" -ForegroundColor White
        Write-Host "  .\openclob-manager.ps1 health" -ForegroundColor Gray
        Write-Host ""
        Write-Host "启动监控:" -ForegroundColor White
        Write-Host "  .\openclob-manager.ps1 monitor" -ForegroundColor Gray
    }
}
