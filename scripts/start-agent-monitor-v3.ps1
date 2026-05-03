# Agent Team 实时监控服务（完整修复版）
# 显示所有 Agent Team 成员 + 正确解析 Token 百分比

param(
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "小妖的 Agent Team - 实时监控服务 v2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 定义所有 Agent Team 成员
$AGENT_TEAM = @{
    'main' = @{ Name = '小妖'; Emoji = '🦊'; Role = '行政助理'; Workspace = 'workspace-admin' }
    'workspace-admin' = @{ Name = '小妖'; Emoji = '🦊'; Role = '行政助理'; Workspace = 'workspace-admin' }
    'workspace-strategy' = @{ Name = '智囊'; Emoji = '💡'; Role = '战略顾问'; Workspace = 'workspace-strategy' }
    'workspace-tech' = @{ Name = '代码'; Emoji = '💻'; Role = '技术总监'; Workspace = 'workspace-tech' }
    'workspace-research' = @{ Name = '探路'; Emoji = '🔍'; Role = '研究员'; Workspace = 'workspace-research' }
    'workspace-qa' = @{ Name = '镜鉴'; Emoji = '🔬'; Role = '质量官'; Workspace = 'workspace-qa' }
    'workspace-finance' = @{ Name = '金库'; Emoji = '💰'; Role = '财务官'; Workspace = 'workspace-finance' }
}

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

                # 创建所有 Agent Team 成员的初始状态
                $agentStatus = @{}
                foreach ($agentId in $AGENT_TEAM.Keys) {
                    $agentStatus[$agentId] = @{
                        id = $agentId
                        sessionKey = $null
                        model = $null
                        status = "offline"
                        tokenUsed = 0
                        tokenTotal = 205000
                        tokenPercent = 0
                        tokens = "0/205k (0%)"
                        age = "未运行"
                        flags = ""
                        name = $AGENT_TEAM[$agentId].Name
                        emoji = $AGENT_TEAM[$agentId].Emoji
                        role = $AGENT_TEAM[$agentId].Role
                        workspace = $AGENT_TEAM[$agentId].Workspace
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

                        # 提取 agent ID（格式：agent:main:xxx 或 agent:workspace-xxx:xxx）
                        $agentId = "unknown"
                        $workspaceId = $null

                        if ($keyClean -match "agent:(main:[^:]+|workspace-[^:]+)") {
                            $agentId = $matches[1]

                            # 映射到标准 ID
                            if ($agentId -eq "main:main" -or $agentId -eq "main") {
                                $workspaceId = "main"
                            } elseif ($agentId -match "^workspace-") {
                                $workspaceId = $agentId
                            } else {
                                $workspaceId = "main"
                            }
                        }

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
                            $status = "error"
                        } elseif ($matches.flags -match "system") {
                            $status = "running"
                        } elseif ($tokenPercent -gt 0) {
                            $status = "running"
                        }

                        # 更新 agent 状态
                        if ($workspaceId -and $agentStatus.ContainsKey($workspaceId)) {
                            $agentStatus[$workspaceId].sessionKey = $keyClean
                            $agentStatus[$workspaceId].model = $matches.model
                            $agentStatus[$workspaceId].status = $status
                            $agentStatus[$workspaceId].tokenUsed = $tokenUsed
                            $agentStatus[$workspaceId].tokenTotal = $tokenTotal
                            $agentStatus[$workspaceId].tokenPercent = $tokenPercent
                            $agentStatus[$workspaceId].tokens = $matches.tokens
                            $agentStatus[$workspaceId].age = $matches.age
                            $agentStatus[$workspaceId].flags = $matches.flags
                        }
                    }
                }

                # 转换为数组并添加其他运行的 sessions（不在 Agent Team 中的）
                $sessions = @()
                $sessions += $agentStatus.Values | Where-Object { $_.status -ne "offline" -or $_.id -eq "main" }

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
                    version = "2.0.0"
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
