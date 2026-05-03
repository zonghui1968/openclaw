# Agent Team 实时监控服务（更新版）
# 正确解析 OpenClaw sessions 输出

param(
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "小妖的 Agent Team - 实时监控服务" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 创建 HTTP 监听器
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
    Write-Host "✅ 监控服务已启动" -ForegroundColor Green
    Write-Host "📍 访问地址: http://localhost:$Port" -ForegroundColor Yellow
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
                # 获取 sessions 数据
                $sessionsOutput = & openclaw sessions 2>&1 | Out-String
                
                # 解析输出
                $lines = $sessionsOutput -split "`n"
                $sessions = @()
                $inDataSection = $false

                foreach ($line in $lines) {
                    if ($line -match "^Kind\s+Key") {
                        $inDataSection = $true
                        continue
                    }

                    if (-not $inDataSection) {
                        continue
                    }

                    if ($line -match "^(?<kind>\S+)\s+(?<key>.+?)\s+(?<age>.+?\s+ago)\s+(?<model>\S+)\s+(?<tokens>.+?)\s+(?<flags>.+)$") {
                        $keyClean = $matches.key -replace '\s+', ' '
                        
                        # 提取 agent ID
                        $agentId = "unknown"
                        if ($keyClean -match "agent:([^:]+):") {
                            $agentId = $matches[1]
                        }

                        # 解析 token 使用
                        $tokenUsage = 0
                        if ($matches.tokens -match "(\d+)k/\d+k") {
                            $tokenUsage = [int]$matches[1]
                        }

                        # 解析状态
                        $status = "idle"
                        if ($matches.flags -match "aborted") {
                            $status = "error"
                        } elseif ($tokenUsage -gt 0) {
                            $status = "running"
                        }

                        # Agent 信息
                        $agentInfo = switch ($agentId) {
                            "main" { @{ Name = "小妖"; Emoji = "🦊"; Role = "行政助理" } }
                            "workspace-admin" { @{ Name = "小妖"; Emoji = "🦊"; Role = "行政助理" } }
                            "workspace-strategy" { @{ Name = "智囊"; Emoji = "💡"; Role = "战略顾问" } }
                            "workspace-tech" { @{ Name = "代码"; Emoji = "💻"; Role = "技术总监" } }
                            "workspace-research" { @{ Name = "探路"; Emoji = "🔍"; Role = "研究员" } }
                            "workspace-qa" { @{ Name = "镜鉴"; Emoji = "🔬"; Role = "质量官" } }
                            "workspace-finance" { @{ Name = "金库"; Emoji = "💰"; Role = "财务官" } }
                            default { @{ Name = $agentId; Emoji = "🤖"; Role = "Agent" } }
                        }

                        $sessions += @{
                            id = $agentId
                            sessionKey = $keyClean
                            model = $matches.model
                            status = $status
                            tokenUsage = $tokenUsage
                            tokens = $matches.tokens
                            age = $matches.age
                            flags = $matches.flags
                            name = $agentInfo.Name
                            emoji = $agentInfo.Emoji
                            role = $agentInfo.Role
                        }
                    }
                }

                $responseData = @{
                    success = $true
                    sessions = $sessions
                    count = $sessions.Count
                    timestamp = Get-Date -Format "o"
                } | ConvertTo-Json -Depth 10

                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.StatusCode = 200

            } elseif ($path -eq "/api/health") {
                $healthData = @{
                    status = "healthy"
                    service = "Xiaoyao Agent Monitor"
                    version = "1.0.0"
                    timestamp = Get-Date -Format "o"
                } | ConvertTo-Json

                $buffer = [System.Text.Encoding]::UTF8.GetBytes($healthData)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.StatusCode = 200

            } elseif ($path -eq "/") {
                $htmlPath = "c:\ssh\.openclaw\workspace\agent-monitor.html"
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
