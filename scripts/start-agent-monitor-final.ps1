# Agent Team 完整监控服务
# 显示所有 7 个 Team 成员（即使离线）

param(
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

# 定义 Agent Team（所有成员）
$AGENT_TEAM = @(
    @{ Id = 'main'; Name = '小妖'; Emoji = '🦊'; Role = '行政助理'; Workspace = 'main' }
    @{ Id = 'workspace-strategy'; Name = '智囊'; Emoji = '💡'; Role = '战略顾问'; Workspace = 'workspace-strategy' }
    @{ Id = 'workspace-tech'; Name = '代码'; Emoji = '💻'; Role = '技术总监'; Workspace = 'workspace-tech' }
    @{ Id = 'workspace-research'; Name = '探路'; Emoji = '🔍'; Role = '研究员'; Workspace = 'workspace-research' }
    @{ Id = 'workspace-qa'; Name = '镜鉴'; Emoji = '🔬'; Role = '质量官'; Workspace = 'workspace-qa' }
    @{ Id = 'workspace-finance'; Name = '金库'; Emoji = '💰'; Role = '财务官'; Workspace = 'workspace-finance' }
)

# 创建 HTTP 监听器
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "小妖的 Agent Team - 完整监控服务" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✅ 监控服务已启动" -ForegroundColor Green
    Write-Host "📍 访问地址: http://localhost:$Port" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "监控成员:" -ForegroundColor Cyan
    foreach ($agent in $AGENT_TEAM) {
        Write-Host "  $($agent.Emoji) $($agent.Name) - $($agent.Role)" -ForegroundColor White
    }
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

                # 初始化所有 Agent Team 成员状态
                $agentStatus = @{}
                foreach ($agent in $AGENT_TEAM) {
                    $agentStatus[$agent.Id] = @{
                        id = $agent.Id
                        sessionKey = $null
                        model = "glm-4.7"
                        status = "offline"
                        tokenUsed = 0
                        tokenTotal = 205000
                        tokenPercent = 0
                        tokens = "0/205k (0%)"
                        age = "离线"
                        flags = ""
                        name = $agent.Name
                        emoji = $agent.Emoji
                        role = $agent.Role
                    }
                }

                # 解析实际运行的 sessions
                $lines = $sessionsOutput -split "`n"
                $inDataSection = $false

                foreach ($line in $lines) {
                    if ($line -match "^Kind\s+Key") {
                        $inDataSection = $true
                        continue
                    }

                    if (-not $inDataSection) {
                        continue
                    }

                    # 解析每一行
                    if ($line -match "^(?<kind>\S+)\s+(?<key>.+?)\s+(?<age>.+?\s+ago)\s+(?<model>\S+)\s+(?<tokens>.+?)\s+(?<flags>.+)$") {
                        $keyClean = $matches.key -replace '\s+', ' '

                        # 提取 agent ID
                        $agentId = $null
                        if ($keyClean -match "agent:main:main") {
                            $agentId = "main"
                        }

                        # 只更新 main agent 的状态（其他 workspace agents 未运行）
                        if ($agentId -and $agentStatus.ContainsKey($agentId)) {
                            # 解析 token 使用（格式：81k/205k (40%)）
                            $tokenUsed = 0
                            $tokenTotal = 205000
                            $tokenPercent = 0

                            if ($matches.tokens -match "(\d+)k/(\d+)k\s+\((\d+)%\)") {
                                $tokenUsed = [int]$matches[1] * 1000
                                $tokenTotal = [int]$matches[2] * 1000
                                $tokenPercent = [int]$matches[3]
                            }

                            # 解析状态
                            $status = "idle"
                            if ($matches.flags -match "aborted") {
                                $status = "offline"
                            } elseif ($matches.flags -match "system") {
                                $status = "running"
                            } elseif ($tokenPercent -gt 0) {
                                $status = "running"
                            }

                            $agentStatus[$agentId].sessionKey = $keyClean
                            $agentStatus[$agentId].model = $matches.model
                            $agentStatus[$agentId].status = $status
                            $agentStatus[$agentId].tokenUsed = $tokenUsed
                            $agentStatus[$agentId].tokenTotal = $tokenTotal
                            $agentStatus[$agentId].tokenPercent = $tokenPercent
                            $agentStatus[$agentId].tokens = $matches.tokens
                            $agentStatus[$agentId].age = $matches.age
                            $agentStatus[$agentId].flags = $matches.flags
                        }
                    }
                }

                # 转换为数组
                $sessions = @($agentStatus.Values)

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
                    version = "3.0.0"
                    team = $AGENT_TEAM.Count
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
