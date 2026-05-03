# OpenClaw Workspace

Personal workspace for agent orchestration, memory management, and Obsidian integration.

## Obsidian CLI Integration

The Obsidian CLI helper is loaded automatically when the PowerShell profile starts. It provides command-line access to Obsidian vault operations.

### Setup

The `obsidian` and `obs` functions are defined by dot-sourced scripts in the PowerShell profile. The loader auto-discovers the Obsidian executable:

- **Target path**: `%LOCALAPPDATA%\Programs\Obsidian\Obsidian.com`
- **Minimum version**: Obsidian 1.12.4+ (CLI feature required)
- **Alias**: `obs` → `obsidian`

Enable CLI in Obsidian: `Settings → General → Advanced → Enable CLI`

### Usage

```powershell
# Quick daily note
obs daily

# Search vault
obs search query='keyword'

# List tasks
obs tasks

# Get help
obs help
```

### Common Commands

| Command | Description |
|---------|-------------|
| `obs daily` | Open today's daily note |
| `obs search query='text'` | Search notes for text |
| `obs tasks` | List all tasks across vault |
| `obs backlinks` | Show backlinks |
| `obs bookmarks` | List bookmarks |
| `obs plugins` | Manage plugins |
| `obs dev:console` | Open developer console |
| `obs --version` | Show Obsidian version |

### Examples

```powershell
# Open daily note
obs daily

# Search for "test"
obs search query='test'

# List all pending tasks
obs tasks
```

### Troubleshooting

- **"Obsidian CLI not found"**: Ensure Obsidian is installed at the default path and CLI is enabled in settings.
- **Commands not recognized**: Reload the PowerShell profile with `. $PROFILE`.

## Agent Tools

### Agent Swarm Tools (`agent-swarm-tools.ps1`)

Functions for managing multi-agent teams:

- `Get-TeamState` — Get team configuration
- `New-Team` — Create a new agent team
- `Add-TeamAgent` — Add an agent to a team
- `Update-TeamTask` — Update task status
- `Show-TeamStatus` — Display team overview
- `Test-TaskReady` — Check if task dependencies are met
- `Remove-Team` — Delete a team
- `Get-TeamTemplate` — List predefined team templates

### Agent Ecosystem Tools (`agent-ecosystem-tools.ps1`)

Evolutionary intelligence functions:

- `New-Ecosystem` — Create an agent ecosystem
- `Initialize-Population` — Spawn initial organisms
- `Invoke-Evolution` — Run evolutionary generations
- `Get-Ecosystem` — Load ecosystem state
- `Remove-Ecosystem` — Delete an ecosystem
- `Show-EvolutionReport` — Display evolution summary
- `Show-EcosystemStatus` — Show population status

## Memory & Session Management

Additional utilities in `scripts/`:

- `backup-memory.ps1` — Backup memory state
- `compress-sessions.ps1` — Compress old sessions
- `health-check.ps1` — System health check
- `sync-lancedb.ps1` — Sync vector database

## Scheduled Tasks

Setup scripts for Windows Task Scheduler automation:

- `setup-daily-learning-task.ps1`
- `setup-sessions-cleanup-task.ps1`
- `setup-sessions-monitor-task.ps1`

---

*Workspace maintained by 小妖🦊*
