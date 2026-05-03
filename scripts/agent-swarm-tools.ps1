# Agent Swarm Tools - PowerShell Helper Module
# Version: 1.0.0
# Created: 2026-03-21
# Author: 小妖🦊

function Get-TeamState {
    <#
    .SYNOPSIS
    Get the current state of an agent team

    .EXAMPLE
    Get-TeamState -TeamName "webapp-dev"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TeamName
    )

    $statePath = "~/.openclaw/workspace/teams/$TeamName/team.json"

    if (-not (Test-Path $statePath)) {
        Write-Error "Team not found: $TeamName"
        return
    }

    $state = Get-Content $statePath | ConvertFrom-Json
    return $state
}

function New-Team {
    <#
    .SYNOPSIS
    Create a new agent team

    .EXAMPLE
    New-Team -Name "webapp-dev" -Description "Build full-stack todo app" -LeaderSession "main"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Description,

        [Parameter(Mandatory=$true)]
        [string]$LeaderSession
    )

    $teamDir = "~/.openclaw/workspace/teams/$Name"
    New-Item -ItemType Directory -Force -Path $teamDir | Out-Null

    $teamConfig = @{
        name = $Name
        description = $Description
        leader_session = $LeaderSession
        created_at = (Get-Date).ToString("o")
        status = "initializing"
        agents = @()
        tasks = @()
    }

    $teamPath = "$teamDir/team.json"
    $teamConfig | ConvertTo-Json -Depth 10 | Set-Content $teamPath

    # Initialize tasks.json
    @{
        tasks = @()
    } | ConvertTo-Json | Set-Content "$teamDir/tasks.json"

    # Initialize agents.json
    @{
        agents = @()
    } | ConvertTo-Json | Set-Content "$teamDir/agents.json"

    Write-Host "✅ Team created: $Name" -ForegroundColor Green
    Write-Host "   Path: $teamPath"

    return $teamConfig
}

function Add-TeamAgent {
    <#
    .SYNOPSIS
    Add an agent to a team

    .EXAMPLE
    Add-TeamAgent -TeamName "webapp-dev" -Name "architect" -Role "API Design" -Task "Design REST API schema"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TeamName,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Role,

        [Parameter(Mandatory=$true)]
        [string]$Task,

        [string[]]$BlockedBy = @(),

        [string]$Runtime = "subagent",

        [ValidateSet("run", "session")]
        [string]$Mode = "run",

        [ValidateSet("keep", "delete")]
        [string]$Cleanup = "keep"
    )

    $team = Get-TeamState $TeamName

    # Prepare coordination prompt
    $coordPrompt = @"
You are part of an agent swarm team: $TeamName
Your role: $Role
Your task: $Task

**IMPORTANT: Coordination Protocol**
1. Report progress by sending messages to the leader session
2. Use sessions_send to communicate with other team members
3. When blocked, wait for dependencies to complete
4. When done, report completion and results

Your unique agent name: $Name
Team leader: $($team.leader_session)

Begin working on your assigned task now.
"@

    # Spawn the agent via sessions_spawn (call as external command)
    # Note: This requires OpenClaw to be available in PATH
    $spawnArgs = @(
        "--task", $coordPrompt
        "--label", $Name
        "--runtime", $Runtime
        "--mode", $Mode
        "--cleanup", $Cleanup
    )

    # In a real implementation, you would call:
    # sessions_spawn @spawnArgs
    # For now, we'll just log it

    Write-Host "🚀 Spawning agent: $Name" -ForegroundColor Cyan
    Write-Host "   Role: $Role"
    Write-Host "   Task: $Task"

    if ($BlockedBy.Count -gt 0) {
        Write-Host "   Blocked by: $($BlockedBy -join ', ')"
    }

    # Add to team config
    $agentInfo = @{
        name = $Name
        role = $Role
        task = $Task
        blocked_by = $BlockedBy
        runtime = $Runtime
        mode = $Mode
        status = "spawned"
        spawned_at = (Get-Date).ToString("o")
    }

    # Update team.json
    $team.agents += $agentInfo
    $team | ConvertTo-Json -Depth 10 | Set-Content "~/.openclaw/workspace/teams/$TeamName/team.json"

    return $agentInfo
}

function Update-TeamTask {
    <#
    .SYNOPSIS
    Update task status

    .EXAMPLE
    Update-TeamTask -TeamName "webapp-dev" -TaskId "task-1" -Status "completed"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TeamName,

        [Parameter(Mandatory=$true)]
        [string]$TaskId,

        [Parameter(Mandatory=$true)]
        [ValidateSet("pending", "in_progress", "completed", "blocked", "failed")]
        [string]$Status
    )

    $team = Get-TeamState $TeamName
    $task = $team.tasks | Where-Object { $_.id -eq $TaskId }

    if ($null -eq $task) {
        Write-Error "Task not found: $TaskId"
        return
    }

    $task.status = $Status
    $task.updated_at = (Get-Date).ToString("o")

    $team | ConvertTo-Json -Depth 10 | Set-Content "~/.openclaw/workspace/teams/$TeamName/team.json"

    Write-Host "✅ Task updated: $TaskId → $Status" -ForegroundColor Green

    # Check if any tasks are now unblocked
    if ($Status -eq "completed") {
        foreach ($t in $team.tasks) {
            if ($t.status -eq "blocked" -and $t.blocked_by -contains $TaskId) {
                $t.status = "pending"
                Write-Host "   🔓 Unblocked: $($t.id)" -ForegroundColor Yellow
            }
        }

        $team | ConvertTo-Json -Depth 10 | Set-Content "~/.openclaw/workspace/teams/$TeamName/team.json"
    }
}

function Show-TeamStatus {
    <#
    .SYNOPSIS
    Display team status in human-readable format

    .EXAMPLE
    Show-TeamStatus -TeamName "webapp-dev"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TeamName
    )

    $team = Get-TeamState $TeamName

    $output = @"

📊 Agent Swarm Team: $($team.name)
==========================================

Description: $($team.description)
Status: $($team.status)
Leader: $($team.leader_session)
Created: $($team.created_at)

🤖 Agents ($($team.agents.Count))
==========================================
"@

    foreach ($agent in $team.agents) {
        $statusIcon = switch ($agent.status) {
            "running" { "🟢" }
            "completed" { "✅" }
            "failed" { "❌" }
            "spawned" { "🔄" }
            default { "⏳" }
        }

        $output += "`n$statusIcon $($agent.name) - $($agent.role)"
        $output += "`n   Task: $($agent.task)"
        $output += "`n   Status: $($agent.status)"

        if ($agent.blocked_by -and $agent.blocked_by.Count -gt 0) {
            $output += "`n   Blocked by: $($agent.blocked_by -join ', ')"
        }

        $output += "`n"
    }

    $output += @"

📋 Tasks ($($team.tasks.Count))
==========================================
"@

    foreach ($task in $team.tasks) {
        $taskIcon = switch ($task.status) {
            "completed" { "✅" }
            "in_progress" { "🔄" }
            "pending" { "⏳" }
            "blocked" { "🚫" }
            "failed" { "❌" }
        }

        $output += "`n$taskIcon [$($task.id)] $($task.title)"
        $output += "`n   Assigned to: $($task.assigned_to)"
        $output += "`n   Status: $($task.status)"

        if ($task.blocked_by -and $task.blocked_by.Count -gt 0) {
            $output += "`n   Blocked by: $($task.blocked_by -join ', ')"
        }

        $output += "`n"
    }

    Write-Host $output
}

function Test-TaskReady {
    <#
    .SYNOPSIS
    Check if a task is ready to start (all dependencies complete)

    .EXAMPLE
    Test-TaskReady -TeamName "webapp-dev" -TaskId "task-2"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TeamName,

        [Parameter(Mandatory=$true)]
        [string]$TaskId
    )

    $team = Get-TeamState $TeamName
    $task = $team.tasks | Where-Object { $_.id -eq $TaskId }

    if ($null -eq $task) {
        Write-Error "Task not found: $TaskId"
        return $false
    }

    if (-not $task.blocked_by -or $task.blocked_by.Count -eq 0) {
        return $true
    }

    foreach ($blockerId in $task.blocked_by) {
        $blocker = $team.tasks | Where-Object { $_.id -eq $blockerId }
        if ($null -eq $blocker -or $blocker.status -ne "completed") {
            return $false
        }
    }

    return $true
}

function Remove-Team {
    <#
    .SYNOPSIS
    Delete a team and all its state

    .EXAMPLE
    Remove-Team -TeamName "webapp-dev" -Force
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TeamName,

        [switch]$Force
    )

    $teamDir = "~/.openclaw/workspace/teams/$TeamName"

    if (-not (Test-Path $teamDir)) {
        Write-Error "Team not found: $TeamName"
        return
    }

    if (-not $Force) {
        $confirmation = Read-Host "Delete team '$TeamName' and all state? (y/N)"
        if ($confirmation -ne "y") {
            Write-Host "Cancelled."
            return
        }
    }

    Remove-Item -Recurse -Force $teamDir
    Write-Host "✅ Team deleted: $TeamName" -ForegroundColor Green
}

function Get-TeamTemplate {
    <#
    .SYNOPSIS
    Get predefined team templates

    .EXAMPLE
    Get-TeamTemplate -Name "webapp"
    #>
    param(
        [string]$Name = "list"
    )

    $templates = @{
        "webapp" = @{
            name = "webapp"
            description = "Full-stack web development team"
            agents = @(
                @{ name = "architect"; role = "System design & API"; priority = 1 }
                @{ name = "backend"; role = "Server implementation"; blocked_by = @("architect") }
                @{ name = "frontend"; role = "UI/UX implementation"; blocked_by = @("architect") }
                @{ name = "devops"; role = "CI/CD & deployment"; blocked_by = @("backend", "frontend") }
                @{ name = "qa"; role = "Testing & QA"; blocked_by = @("backend", "frontend") }
            )
        }
        "research" = @{
            name = "research"
            description = "Parallel research team for experiments"
            agents = @(
                @{ name = "lead"; role = "Design experiments" }
            )
        }
        "content" = @{
            name = "content"
            description = "Content production studio"
            agents = @(
                @{ name = "researcher"; role = "Gather data & sources" }
                @{ name = "writer"; role = "Draft content"; blocked_by = @("researcher") }
                @{ name = "editor"; role = "Review & polish"; blocked_by = @("writer") }
                @{ name = "publisher"; role = "Publish & distribute"; blocked_by = @("editor") }
            )
        }
    }

    if ($Name -eq "list") {
        Write-Host "`n📚 Available Team Templates:`n" -ForegroundColor Cyan
        foreach ($key in $templates.Keys) {
            $t = $templates[$key]
            Write-Host "  • $key - $($t.description)" -ForegroundColor Yellow
        }
        Write-Host ""
    } else {
        if ($templates.ContainsKey($Name)) {
            return $templates[$Name]
        } else {
            Write-Error "Template not found: $Name"
            Write-Host "Available templates: $($templates.Keys -join ', ')"
        }
    }
}

# Export functions (disabled - dot-sourced .ps1 files don't use Export-ModuleMember)
# If you convert this to a .psm1 module, uncomment the Export-ModuleMember block below
# Export-ModuleMember -Function @(
#     "Get-TeamState",
#     "New-Team",
#     "Add-TeamAgent",
#     "Update-TeamTask",
#     "Show-TeamStatus",
#     "Test-TaskReady",
#     "Remove-Team",
#     "Get-TeamTemplate"
# )
