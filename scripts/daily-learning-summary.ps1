# Daily Learning Summary - PowerShell Wrapper
# 调用 Python 脚本生成简报，并发送邮件

$ErrorActionPreference = "Stop"

$separator = "=" * 60
Write-Host "🦊 每日学习简报系统" -ForegroundColor Cyan
Write-Host $separator

# 设置 Python 编码为 UTF-8
$env:PYTHONIOENCODING = 'utf-8'

# 调用 Python 脚本
Write-Host "`n📝 生成学习简报..." -ForegroundColor Yellow
$pythonOutput = python c:\ssh\.openclaw\scripts\daily-learning-summary.py 2>&1

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
Write-Host "`n📧 发送邮件..." -ForegroundColor Yellow

# 注意：这里需要通过 OpenClaw 的 message 工具发送
# 在 cron 任务中，会调用 openclaw message send 命令

Write-Host "`n$separator"
Write-Host "✅ 学习简报系统执行完成！" -ForegroundColor Green
Write-Host $separator
