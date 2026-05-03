# Agent Team 监控 - 自动刷新脚本
# 定期刷新监控页面

param(
    [int]$RefreshSeconds = 10
)

$ErrorActionPreference = "Stop"
$monitorHtml = "c:\ssh\.openclaw\workspace\agent-monitor.html"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "小妖的 Agent Team - 监控面板" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $monitorHtml)) {
    Write-Host "❌ 监控页面不存在: $monitorHtml" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 监控页面已找到" -ForegroundColor Green
Write-Host "📍 文件位置: $monitorHtml" -ForegroundColor Yellow
Write-Host ""

# 获取子 agents 数据
Write-Host "正在获取 Agent 状态..." -ForegroundColor Gray

try {
    $result = & openclaw sessions list --json 2>&1 | Out-String
    
    if ($result) {
        $data = $result | ConvertFrom-Json
        
        if ($data.success -and $data.sessions) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host "Agent 状态概览" -ForegroundColor Cyan
            Write-Host "========================================" -ForegroundColor Cyan
            Write-Host ""
            
            foreach ($session in $data.sessions) {
                $status = if ($session.activeMinutes -gt 0) { "🚀 运行中" } else { "💤 空闲" }
                $color = if ($session.activeMinutes -gt 0) { "Green" } else { "Yellow" }
                
                Write-Host "Agent: $($session.agentId)" -ForegroundColor Cyan
                Write-Host "  状态: " -NoNewline
                Write-Host $status -ForegroundColor $color
                Write-Host "  模型: $($session.model)"
                Write-Host "  消息: $($session.messageCount)"
                Write-Host "  创建: $($session.createdAt)"
                Write-Host ""
            }
            
            Write-Host "总计: $($data.sessions.Count) 个 Agent" -ForegroundColor White
            Write-Host ""
        } else {
            Write-Host "⚠ 没有找到活跃的 Agent" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "❌ 获取 Agent 状态失败: $_" -ForegroundColor Red
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "打开监控面板..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 在默认浏览器中打开
Start-Process $monitorHtml

Write-Host "✅ 监控面板已在浏览器中打开" -ForegroundColor Green
Write-Host ""
Write-Host "注意：由于浏览器安全限制，无法直接从本地文件访问 OpenClaw API" -ForegroundColor Yellow
Write-Host "如需实时监控，请运行: .\start-agent-monitor.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
