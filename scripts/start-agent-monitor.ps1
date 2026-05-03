# Agent Team 实时监控脚本
# 提供 JSON API 供 HTML 面板使用

param(
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

# 导入必要的模块
Import-Module WebAdministration -ErrorAction SilentlyContinue

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

    # Agent 角色映射
    $AGENT_ROLES = @{
        'main' = @{ Name = '小妖'; Emoji = '🦊'; Role = '行政助理' }
        'workspace-admin' = @{ Name = '小妖'; Emoji = '🦊'; Role = '行政助理' }
        'workspace-strategy' = @{ Name = '智囊'; Emoji = '💡'; Role = '战略顾问' }
        'workspace-tech' = @{ Name = '代码'; Emoji = '💻'; Role = '技术总监' }
        'workspace-research' = @{ Name = '探路'; Emoji = '🔍'; Role = '研究员' }
        'workspace-qa' = @{ Name = '镜鉴'; Emoji = '🔬'; Role = '质量官' }
        'workspace-finance' = @{ Name = '金库'; Emoji = '💰'; Role = '财务官' }
    }

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

            if ($path -eq "/api/subagents/list") {
                # 获取子 agents 列表
                $result = & openclaw sessions list --json 2>&1
                $agents = @()

                if ($result -is [string]) {
                    try {
                        $data = $result | ConvertFrom-Json
                        if ($data.success -and $data.sessions) {
                            foreach ($session in $data.sessions) {
                                $agentId = $session.agentId
                                $roleInfo = $AGENT_ROLES[$agentId]

                                $agents += @{
                                    id = $agentId
                                    sessionKey = $session.sessionKey
                                    model = $session.model
                                    status = if ($session.activeMinutes -gt 0) { "running" } else { "idle" }
                                    messageCount = $session.messageCount
                                    startedAt = $session.createdAt
                                }
                            }
                        }
                    } catch {
                        # JSON 解析失败，返回空列表
                    }
                }

                $responseData = @{
                    success = $true
                    subagents = $agents
                    timestamp = Get-Date -Format "o"
                } | ConvertTo-Json -Depth 10

                $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseData)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
                $response.StatusCode = 200

            } elseif ($path -eq "/api/health") {
                # 健康检查
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
                # 返回 HTML 页面
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
