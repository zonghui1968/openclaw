# Agent Team 监控服务 - 测试版本
# 包含模拟数据，验证前端显示

param(
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 模拟的 Agent Team 数据（用于测试）
$MOCK_DATA = @{
    sessions = @(
        @{
            id = "main"
            name = "小妖"
            emoji = "🦊"
            role = "行政助理"
            status = "running"
            tokens = "81k/205k (40%)"
            tokenPercent = 40
            model = "glm-4.7"
            age = "2m ago"
        },
        @{
            id = "workspace-strategy"
            name = "智囊"
            emoji = "💡"
            role = "战略顾问"
            status = "offline"
            tokens = "0/205k (0%)"
            tokenPercent = 0
            model = "glm-4.7"
            age = "离线"
        },
        @{
            id = "workspace-tech"
            name = "代码"
            emoji = "💻"
            role = "技术总监"
            status = "offline"
            tokens = "0/205k (0%)"
            tokenPercent = 0
            model = "glm-4.7"
            age = "离线"
        },
        @{
            id = "workspace-research"
            name = "探路"
            emoji = "🔍"
            role = "研究员"
            status = "offline"
            tokens = "0/205k (0%)"
            tokenPercent = 0
            model = "glm-4.7"
            age = "离线"
        },
        @{
            id = "workspace-qa"
            name = "镜鉴"
            emoji = "🔬"
            role = "质量官"
            status = "offline"
            tokens = "0/205k (0%)"
            tokenPercent = 0
            model = "glm-4.7"
            age = "离线"
        },
        @{
            id = "workspace-finance"
            name = "金库"
            emoji = "💰"
            role = "财务官"
            status = "offline"
            tokens = "0/205k (0%)"
            tokenPercent = 0
            model = "glm-4.7"
            age = "离线"
        }
    )
    success = $true
    count = 6
    timestamp = Get-Date -Format "o"
}

# 创建 HTTP 监听器
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "小妖的 Agent Team - 测试监控服务" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✅ 测试服务已启动" -ForegroundColor Green
    Write-Host "📍 访问地址: http://localhost:$Port" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "使用模拟数据（测试前端显示）" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "按 Ctrl+C 停止服务" -ForegroundColor Gray
    Write-Host ""

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        try {
            $path = $request.Url.AbsolutePath
            $method = $request.HttpMethod

            # CORS headers
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, OPTIONS")
            $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type")
            $response.ContentType = "application/json; charset=utf-8"

            if ($method -eq "OPTIONS") {
                $response.StatusCode = 200
                $response.Close()
                continue
            }

            if ($path -eq "/api/sessions") {
                # 返回模拟数据
                $responseData = $MOCK_DATA | ConvertTo-Json -Depth 10
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.StatusCode = 200

            } elseif ($path -eq "/api/health") {
                $healthData = @{
                    status = "healthy"
                    service = "Xiaoyao Agent Monitor"
                    version = "test-1.0.0"
                    mode = "mock-data"
                    timestamp = Get-Date -Format "o"
                } | ConvertTo-Json

                $buffer = [System.Text.Encoding]::UTF8.GetBytes($healthData)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.StatusCode = 200

            } elseif ($path -eq "/") {
                $htmlPath = "c:\ssh\.openclaw\workspace\agent-monitor-v2.html"
                if (Test-Path $htmlPath) {
                    $html = Get-Content $htmlPath -Raw -Encoding UTF8
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                    $response.ContentType = "text/html; charset=utf-8"
                    $response.ContentLength64 = $buffer.Length
                    $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    $response.StatusCode = 200
                } else {
                    $response.StatusCode = 404
                }
            } else {
                $response.StatusCode = 404
            }

        } catch {
            $response.StatusCode = 500
            Write-Host "错误: $_" -ForegroundColor Red
        } finally {
            $response.Close()
        }
    }

} catch {
    Write-Host "❌ 服务启动失败: $_" -ForegroundColor Red
} finally {
    $listener.Stop()
    Write-Host ""
    Write-Host "服务已停止" -ForegroundColor Yellow
}
