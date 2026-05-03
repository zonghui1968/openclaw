# OpenClaw Gateway 健康检查脚本
# 用途：检查 Gateway 状态，发现异常自动修复

param(
    [switch]$AutoFix = $false
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Gateway 健康检查" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()

# 检查 1: Gateway 状态
Write-Host "[检查 1/6] Gateway 进程..." -ForegroundColor Yellow
$gatewayStatus = openclaw gateway status 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Gateway 运行正常" -ForegroundColor Green
} else {
    Write-Host "  ✗ Gateway 未运行" -ForegroundColor Red
    $issues += "gateway_not_running"
}

# 检查 2: 通道状态
Write-Host "[检查 2/6] 通道状态..." -ForegroundColor Yellow
try {
    $channelStatus = openclaw status 2>&1
    $okCount = ([regex]::Matches($channelStatus, "OK")).Count
    $totalChannels = ([regex]::Matches($channelStatus, "│ (Telegram|WhatsApp|Feishu) ")).Count

    if ($okCount -eq $totalChannels -and $totalChannels -gt 0) {
        Write-Host "  ✓ 所有通道 ($okCount/$totalChannels) 正常" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ 部分通道异常 ($okCount/$totalChannels)" -ForegroundColor Yellow
        $issues += "channel_warning"
    }
} catch {
    Write-Host "  ✗ 无法检查通道状态" -ForegroundColor Red
    $issues += "channel_check_failed"
}

# 检查 3: 版本信息
Write-Host "[检查 3/6] 版本信息..." -ForegroundColor Yellow
try {
    $version = openclaw --version
    Write-Host "  当前版本: $version" -ForegroundColor White
} catch {
    Write-Host "  ✗ 无法获取版本" -ForegroundColor Red
    $issues += "version_check_failed"
}

# 检查 4: 配置文件
Write-Host "[检查 4/6] 配置文件..." -ForegroundColor Yellow
$configs = @(
    "C:\Users\宗晖\.openclaw\openclaw.json",
    "c:\ssh\.openclaw\openclaw.json"
)
$configsExist = 0
foreach ($config in $configs) {
    if (Test-Path $config) {
        $configsExist++
    }
}
if ($configsExist -eq $configs.Count) {
    Write-Host "  ✓ 所有配置文件存在" -ForegroundColor Green
} else {
    Write-Host "  ⚠ 配置文件缺失 ($configsExist/$($configs.Count))" -ForegroundColor Yellow
    $issues += "config_missing"
}

# 检查 5: 日志错误（最近 10 行）
Write-Host "[检查 5/6] 最近的错误..." -ForegroundColor Yellow
try {
    $logs = openclaw logs --tail 10 2>&1
    $errorCount = ([regex]::Matches($logs, "(ERROR|FAIL|error:|failed)")).Count
    if ($errorCount -eq 0) {
        Write-Host "  ✓ 未发现明显错误" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ 发现 $errorCount 个错误（需人工检查）" -ForegroundColor Yellow
        # 不将此加入 $issues，因为可能不是致命问题
    }
} catch {
    Write-Host "  ℹ 无法检查日志" -ForegroundColor Gray
}

# 检查 6: 会话状态
Write-Host "[检查 6/6] 会话状态..." -ForegroundColor Yellow
try {
    $sessions = openclaw sessions list 2>&1
    Write-Host "  会话数量: $($sessions.Count)" -ForegroundColor White
} catch {
    Write-Host "  ℹ 无法检查会话" -ForegroundColor Gray
}

# 结果汇总
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "检查结果" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($issues.Count -eq 0) {
    Write-Host "✅ 所有检查通过！系统健康。" -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠ 发现 $($issues.Count) 个问题：" -ForegroundColor Yellow
    foreach ($issue in $issues) {
        Write-Host "  • $issue" -ForegroundColor White
    }

    if ($AutoFix) {
        Write-Host ""
        Write-Host "[自动修复] 尝试修复..." -ForegroundColor Yellow

        # Gateway 未运行 - 尝试启动
        if ($issues -contains "gateway_not_running") {
            Write-Host "  [修复] 启动 Gateway..." -ForegroundColor Gray
            openclaw gateway start
            Start-Sleep -Seconds 3
        }

        # 重新检查
        Write-Host "  [验证] 重新检查..." -ForegroundColor Gray
        & $PSCommandPath -File $PSCommandPath
    } else {
        Write-Host ""
        Write-Host "提示: 使用 -AutoFix 参数尝试自动修复" -ForegroundColor Cyan
    }
    exit 1
}
