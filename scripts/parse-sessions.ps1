# 解析 OpenClaw sessions 输出
# 将纯文本转换为结构化数据

param(
    [string]$SessionsOutput
)

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

function Parse-SessionsOutput {
    param([string]$Output)

    $lines = $Output -split "`n"
    $sessions = @()
    $inDataSection = $false

    foreach ($line in $lines) {
        # 跳过表头
        if ($line -match "^Kind\s+Key") {
            $inDataSection = $true
            continue
        }

        if (-not $inDataSection) {
            continue
        }

        # 解析数据行
        if ($line -match "^(?<kind>\S+)\s+(?<key>[^\s]+(?:\s+[^\s]+)*)\s+(?<age>.+?\s+ago)\s+(?<model>\S+)\s+(?<tokens>.+?)\s+(?<flags>.+)$") {
            $matches.key = $matches.key -replace '\s+', ' '
            
            # 解析 token 使用
            $tokens = $matches.tokens -replace '\s+', ''
            $tokenUsage = 0
            if ($tokens -match "(\d+)k/\d+k") {
                $tokenUsage = [int]$matches[1]
            }

            # 解析状态
            $status = "idle"
            if ($matches.flags -match "aborted") {
                $status = "error"
            } elseif ($matches.kind -eq "running") {
                $status = "running"
            }

            # 提取 agent ID
            $agentId = "unknown"
            if ($matches.key -match "agent:([^:]+):") {
                $agentId = $matches[1]
            }

            $roleInfo = $AGENT_ROLES[$agentId]
            
            $sessions += @{
                id = $agentId
                name = if ($roleInfo) { $roleInfo.Name } else { $agentId }
                emoji = if ($roleInfo) { $roleInfo.Emoji } else { "🤖" }
                role = if ($roleInfo) { $roleInfo.Role } else { "Agent" }
                kind = $matches.kind
                sessionKey = $matches.key
                age = $matches.age
                model = $matches.model
                tokenUsage = $tokenUsage
                tokens = $matches.tokens
                status = $status
                flags = $matches.flags
            }
        }
    }

    return $sessions
}

# 主逻辑
if ($SessionsOutput) {
    $sessions = Parse-SessionsOutput -Output $SessionsOutput
    
    $result = @{
        success = $true
        sessions = $sessions
        count = $sessions.Count
        timestamp = Get-Date -Format "o"
    }

    $result | ConvertTo-Json -Depth 10
} else {
    @{ success = $false; error = "No output provided" } | ConvertTo-Json
}
