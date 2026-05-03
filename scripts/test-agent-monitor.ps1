# Agent 监控系统 - 快速启动和测试

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "小妖的 Agent Team - 监控系统" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ 监控服务已启动！" -ForegroundColor Green
Write-Host ""
Write-Host "📍 访问地址：" -ForegroundColor Yellow
Write-Host "   http://localhost:8080" -ForegroundColor White
Write-Host ""

Write-Host "🔍 测试服务状态..." -ForegroundColor Gray

try {
    # 测试 API
    $response = Invoke-WebRequest -Uri "http://localhost:8080/api/health" -UseBasicParsing -TimeoutSec 5
    $data = $response.Content | ConvertFrom-Json
    
    Write-Host "✅ 服务状态: $($data.status)" -ForegroundColor Green
    Write-Host "   版本: $($data.version)" -ForegroundColor Gray
    Write-Host ""
    
    # 获取 sessions
    Write-Host "📊 获取 Agent 状态..." -ForegroundColor Gray
    $sessionsResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/sessions" -UseBasicParsing -TimeoutSec 5
    $sessionsData = $sessionsResponse.Content | ConvertFrom-Json
    
    Write-Host "✅ 找到 $($sessionsData.count) 个 Agent" -ForegroundColor Green
    Write-Host ""
    
    foreach ($session in $sessionsData.sessions) {
        $statusColor = switch ($session.status) {
            "running" { "Green" }
            "idle" { "Yellow" }
            "error" { "Red" }
            default { "Gray" }
        }
        
        Write-Host "$($session.emoji) $($session.name) - $($session.role)" -ForegroundColor Cyan
        Write-Host "   状态: " -NoNewline
        Write-Host "$($session.status)" -ForegroundColor $statusColor
        Write-Host "   模型: $($session.model)"
        Write-Host "   Token: $($session.tokens)"
        Write-Host ""
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "🎉 监控系统运行正常！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # 自动打开浏览器
    Write-Host "正在打开监控面板..." -ForegroundColor Gray
    Start-Process "http://localhost:8080"
    
    Write-Host "✅ 监控面板已在浏览器中打开" -ForegroundColor Green
    Write-Host ""
    Write-Host "提示：" -ForegroundColor Yellow
    Write-Host "  - 监控面板每 10 秒自动刷新" -ForegroundColor White
    Write-Host "  - 服务窗口保持打开以维持监控" -ForegroundColor White
    Write-Host "  - 按 Ctrl+C 停止监控服务" -ForegroundColor White
    Write-Host ""
    
} catch {
    Write-Host "❌ 服务测试失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "可能的原因：" -ForegroundColor Yellow
    Write-Host "  1. 服务尚未完全启动（等待几秒后重试）" -ForegroundColor White
    Write-Host "  2. 端口 8080 被占用" -ForegroundColor White
    Write-Host "  3. 防火墙阻止连接" -ForegroundColor White
    Write-Host ""
}
