# OpenClaw Gateway 自动监控与修复脚本
# 用途：持续监控 Gateway 状态，发现异常自动修复或回滚

param(
    [int]$CheckInterval = 60,   # 检查间隔（秒）
    [int]$MaxRestarts = 5,      # 最大重启次数
    [switch]$Loop = $false      # 是否持续监控
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Gateway 自动监控与修复" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "配置:" -ForegroundColor Yellow
Write-Host "  检查间隔: $CheckInterval 秒" -ForegroundColor White
Write-Host "  最大重启: $MaxRestarts 次" -ForegroundColor White
Write-Host "  持续监控: $Loop" -ForegroundColor White
Write-Host ""

$restartCount = 0
$startTime = Get-Date
$scriptDir = Split-Path -Parent $PSCommandPath

# 创建监控日志目录
$logDir = "C:\Users\宗晖\.openclaw\logs\monitor"
New-Item -Path $logDir -ItemType Directory -Force | Out-Null
$logFile = "$logDir\auto-fix-$(Get-Date -Format 'yyyy-MM-dd').log"

function Log-Message {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

function Get-Uptime {
    $uptime = (Get-Date) - $startTime
    "{0:hh}小时{0:mm}分钟{0:ss}秒" -f $uptime
}

Log-Message "监控启动" "INFO"

do {
    try {
        # 运行健康检查
        Log-Message "运行健康检查..." "INFO"
        & "$scriptDir\health-check.ps1" -AutoFix

        if ($LASTEXITCODE -eq 0) {
            Log-Message "✓ 系统健康 (运行时间: $(Get-Uptime), 重启次数: $restartCount/$MaxRestarts)" "INFO"

            # 重置重启计数（连续健康后）
            if ($restartCount -gt 0) {
                Log-Message "系统已稳定，重置重启计数" "INFO"
                $restartCount = 0
            }
        } else {
            throw "健康检查失败"
        }

    } catch {
        $restartCount++
        Log-Message "✗ 发现异常 (重启次数: $restartCount/$MaxRestarts)" "ERROR"
        Log-Message "错误: $($_.Exception.Message)" "ERROR"

        if ($restartCount -lt $MaxRestarts) {
            Log-Message "  [修复] 尝试修复..." "WARN"

            # 尝试 1: 重启 Gateway
            try {
                openclaw gateway restart
                Start-Sleep -Seconds 5
                Log-Message "  Gateway 已重启" "INFO"
            } catch {
                Log-Message "  重启失败" "ERROR"

                # 尝试 2: 回滚
                Log-Message "  [回滚] 重启失败，执行回滚..." "ERROR"
                try {
                    & "$scriptDir\rollback-openclob.ps1"
                    Log-Message "  回滚完成" "INFO"
                    break
                } catch {
                    Log-Message "  回滚失败，停止监控" "CRITICAL"
                    break
                }
            }
        } else {
            Log-Message "  [停止] 达到最大重启次数，停止监控" "CRITICAL"
            Log-Message "  请人工检查系统" "CRITICAL"
            break
        }
    }

    # 如果不是持续监控，退出
    if (-not $Loop) {
        break
    }

    # 等待下次检查
    if ($Loop) {
        Log-Message "等待 $CheckInterval 秒..." "INFO"
        Start-Sleep -Seconds $CheckInterval
    }

} while ($Loop)

Log-Message "监控结束 (总运行时间: $(Get-Uptime))" "INFO"
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "监控结束" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "日志: $logFile" -ForegroundColor Cyan
