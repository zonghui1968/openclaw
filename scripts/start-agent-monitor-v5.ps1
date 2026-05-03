# Agent Team 监控 - 简化启动脚本
# 包含错误处理和日志记录

param(
    [int]$Port = 8082
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Agent Team 监控服务 v5" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 模拟数据
$MOCK_DATA = @{
    sessions = @(
        @{ id = "main"; name = "小妖"; emoji = "🦊"; role = "行政助理"; status = "running"; tokens = "81k/205k (40%)"; tokenPercent = 40; model = "glm-4.7"; age = "2m ago" }
        @{ id = "workspace-strategy"; name = "智囊"; emoji = "💡"; role = "战略顾问"; status = "offline"; tokens = "0/205k (0%)"; tokenPercent = 0; model = "glm-4.7"; age = "离线" }
        @{ id = "workspace-tech"; name = "代码"; emoji = "💻"; role = "技术总监"; status = "offline"; tokens = "0/205k (0%)"; tokenPercent = 0; model = "glm-4.7"; age = "离线" }
        @{ id = "workspace-research"; name = "探路"; emoji = "🔍"; role = "研究员"; status = "offline"; tokens = "0/205k (0%)"; tokenPercent = 0; model = "glm-4.7"; age = "离线" }
        @{ id = "workspace-qa"; name = "镜鉴"; emoji = "🔬"; role = "质量官"; status = "offline"; tokens = "0/205k (0%)"; tokenPercent = 0; model = "glm-4.7"; age = "离线" }
        @{ id = "workspace-finance"; name = "金库"; emoji = "💰"; role = "财务官"; status = "offline"; tokens = "0/205k (0%)"; tokenPercent = 0; model = "glm-4.7"; age = "离线" }
    )
    success = $true
    count = 6
    timestamp = Get-Date -Format "o"
}

try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$Port/")

    Write-Host "尝试启动服务..." -ForegroundColor Yellow
    $listener.Start()
    Write-Host "✅ 服务启动成功！" -ForegroundColor Green
    Write-Host "📍 端口: $Port" -ForegroundColor Yellow
    Write-Host "🌐 访问: http://localhost:$Port" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "按 Ctrl+C 停止服务" -ForegroundColor Gray
    Write-Host ""

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        try {
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.ContentType = "application/json; charset=utf-8"

            if ($request.HttpMethod -eq "OPTIONS") {
                $response.StatusCode = 200
                $response.Close()
                continue
            }

            if ($request.Url.AbsolutePath -eq "/api/sessions") {
                $json = $MOCK_DATA | ConvertTo-Json -Depth 10
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.StatusCode = 200
            } elseif ($request.Url.AbsolutePath -eq "/api/health") {
                $health = @{ status = "healthy"; port = $Port; version = "5.0.0" } | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($health)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.StatusCode = 200
            } elseif ($request.Url.AbsolutePath -eq "/") {
                $html = Get-Content "c:\ssh\.openclaw\workspace\agent-monitor-v2.html" -Raw -Encoding UTF8
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $response.ContentType = "text/html; charset=utf-8"
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.StatusCode = 200
            } else {
                $response.StatusCode = 404
            }

        } catch {
            $response.StatusCode = 500
            Write-Host "请求错误: $_" -ForegroundColor Red
        } finally {
            $response.Close()
        }
    }

} catch {
    Write-Host "❌ 启动失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "可能的原因:" -ForegroundColor Yellow
    Write-Host "  1. 端口 $Port 被占用" -ForegroundColor White
    Write-Host "  2. 权限不足" -ForegroundColor White
    Write-Host "  3. 防火墙阻止" -ForegroundColor White
    Write-Host ""
    Write-Host "尝试其他端口:" -ForegroundColor Yellow
    Write-Host "  .\start-agent-monitor-v5.ps1 -Port 8083" -ForegroundColor White
} finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
}
