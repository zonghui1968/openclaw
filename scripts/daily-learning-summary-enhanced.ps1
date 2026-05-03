# Daily Learning Summary - PowerShell Wrapper (Enhanced)
# 调用增强版 Python 脚本生成简报，并发送邮件

$ErrorActionPreference = "Stop"

$separator = "=" * 60
Write-Host "🦊 每日学习简报系统 (增强版)" -ForegroundColor Cyan
Write-Host $separator

# 设置 Python 编码为 UTF-8
$env:PYTHONIOENCODING = 'utf-8'

# 脚本路径
$pythonScript = "c:\ssh\.openclaw\scripts\daily-learning-summary-enhanced.py"

# 检查 Python 脚本
if (-not (Test-Path $pythonScript)) {
    Write-Host "❌ Python 脚本不存在: $pythonScript" -ForegroundColor Red
    exit 1
}

# 调用 Python 脚本
Write-Host "`n📝 生成学习简报..." -ForegroundColor Yellow
$pythonOutput = python $pythonScript 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Python 脚本执行失败" -ForegroundColor Red
    Write-Host $pythonOutput
    exit 1
}

Write-Host $pythonOutput

# 读取生成的简报
$summaryFile = "$env:USERPROFILE\.openclaw\cache\daily-summary.md"
if (-not (Test-Path $summaryFile)) {
    Write-Host "❌ 简报文件未生成" -ForegroundColor Red
    exit 1
}

$summaryContent = Get-Content $summaryFile -Raw -Encoding UTF8

# 发送邮件（通过 OpenClaw message 系统）
Write-Host "`n📧 发送邮件到 hizonghui@gmail.com..." -ForegroundColor Yellow

try {
    # 使用 openclaw message 命令发送
    $mailResult = & openclaw message send --to hizonghui@gmail.com --subject "📚 每日学习简报 - $(Get-Date -Format 'yyyy-MM-dd')" --body $summaryContent --cc ruoli.jia@gmail.com 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 邮件发送成功" -ForegroundColor Green
    } else {
        Write-Host "⚠️  邮件发送可能失败: $mailResult" -ForegroundColor Yellow
        Write-Host "简报已保存到 Obsidian，请手动查看" -ForegroundColor Gray
    }
}
catch {
    Write-Host "⚠️  邮件发送异常: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "简报已保存到 Obsidian，请手动查看" -ForegroundColor Gray
}

Write-Host "`n$separator"
Write-Host "✅ 学习简报系统执行完成！" -ForegroundColor Green
Write-Host $separator
