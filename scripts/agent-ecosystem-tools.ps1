# Agent Ecosystem Tools - PowerShell Module
# Version: 1.0.0
# Philosophy: Evolutionary Intelligence

function New-Ecosystem {
    <#
    .SYNOPSIS
    Create a new agent ecosystem
    
    .EXAMPLE
    New-Ecosystem -Name "webapp-dev" -Type "development" -Task "Build a todo app"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [string]$Task,
        
        [int]$MaxGenerations = 5,
        [int]$MaxPopulation = 10
    )
    
    $ecoDir = "~/.openclaw/workspace/ecosystems/$Name"
    New-Item -ItemType Directory -Force -Path $ecoDir | Out-Null
    
    # 设计生态系统
    $ecosystem = Design-EcosystemType -Type $Type -Task $Task
    $ecosystem.name = $Name
    $ecosystem.task = $Task
    $ecosystem.max_generations = $MaxGenerations
    $ecosystem.max_population = $MaxPopulation
    $ecosystem.created_at = (Get-Date).ToString("o")
    $ecosystem.current_generation = 0
    $ecosystem.best_fitness = 0.0
    $ecosystem.stagnation_count = 0
    $ecosystem.organisms = @()
    
    # 保存生态系统配置
    $ecosystem | ConvertTo-Json -Depth 10 | Set-Content "$ecoDir/ecosystem.json"
    
    Write-Host "🌱 Ecosystem created: $Name" -ForegroundColor Green
    Write-Host "   Type: $Type"
    Write-Host "   Task: $Task"
    Write-Host "   Species: $($ecosystem.species.Count)"
    
    return $ecosystem
}

function Design-EcosystemType {
    param(
        [string]$Type,
        [string]$Task
    )
    
    $ecosystem = @{
        type = $Type
        species = @()
    }
    
    switch ($Type) {
        "development" {
            $ecosystem.species = @(
                @{ type = "architect"; population = 2; mutation_rate = 0.3; fitness_function = "quality + speed" },
                @{ type = "developer"; population = 4; mutation_rate = 0.4; fitness_function = "complete + bugs" },
                @{ type = "tester"; population = 2; mutation_rate = 0.2; fitness_function = "coverage + issues_found" }
            )
        }
        "research" {
            $ecosystem.species = @(
                @{ type = "experimenter"; population = 8; mutation_rate = 0.5; fitness_function = "result_quality + innovation" }
            )
        }
        "creative" {
            $ecosystem.species = @(
                @{ type = "researcher"; population = 2; mutation_rate = 0.3 },
                @{ type = "creator"; population = 3; mutation_rate = 0.5 },
                @{ type = "reviewer"; population = 2; mutation_rate = 0.2 }
            )
        }
        default {
            Write-Warning "Unknown ecosystem type: $Type. Using default."
            $ecosystem.species = @(
                @{ type = "worker"; population = 5; mutation_rate = 0.4 }
            )
        }
    }
    
    return $ecosystem
}

function New-Genome {
    param(
        [string]$Species,
        [int]$Generation,
        [hashtable]$ParentGenomes = $null
    )
    
    # 基因池
    $strategyPool = @{
        architect = @("microservices", "monolith", "serverless", "modular-monolith")
        developer = @("tdd", "bdd", "agile", "spiral", "prototyping")
        tester = @("unit-first", "integration-first", "e2e-first", "property-based")
        experimenter = @("grid-search", "random-search", "bayesian", "gradual", "aggressive")
        researcher = @("deep-dive", "broad-survey", "comparative", "historical")
        creator = @("iterative", "outline-first", "organic", "structured")
        reviewer = @("critical", "constructive", "minimal", "thorough")
        worker = @("systematic", "creative", "pragmatic", "agile")
    }
    
    $toolsPool = @{
        architect = @("diagrams", "api-design", "docs", "swagger", "graphql")
        developer = @("typescript", "python", "rust", "react", "vue", "testing")
        tester = @("jest", "cypress", "playwright", "pytest", "selenium")
        experimenter = @("tensorboard", "wandb", "mlflow", "custom-logging")
        researcher = @("web-search", "scholar", "documentation", "interviews")
        creator = @("markdown", "html", "slides", "video", "interactive")
        reviewer = @("checklist", "rubric", "peer-review", "automated")
        worker = @("automation", "manual", "hybrid", "ai-assisted")
    }
    
    # 生成基因
    $genome = @{
        id = "$Species-gen$Generation-$(Get-Random -Maximum 9999)"
        species = $Species
        generation = $Generation
        
        # 遗传或随机
        strategy = if ($ParentGenomes) {
            $ParentGenomes[(Get-Random -Maximum $ParentGenomes.Count)].strategy
        } else {
            $strategyPool[$Species] | Get-Random
        }
        
        # 工具组合
        tools = if ($ParentGenomes) {
            $parentTools = $ParentGenomes | ForEach-Object { $_.tools }
            ($parentTools | Select-Object -Unique) + (($toolsPool[$Species] | Get-Random -Count 1))
        } else {
            $toolsPool[$Species] | Get-Random -Count (Get-Random -Minimum 1 -Maximum 3)
        }
        
        # 其他基因
        thinking_style = @("analytical", "creative", "pragmatic") | Get-Random
        innovation_level = [Math]::Round((Get-Random -Maximum 100) / 100, 2)
        collaboration_style = @("leader", "follower", "peer") | Get-Random
        mutation_count = 0
    }
    
    return $genome
}

function Initialize-Population {
    param(
        [hashtable]$Ecosystem
    )
    
    Write-Host "`n🧬 Initializing population..." -ForegroundColor Cyan
    
    foreach ($species in $Ecosystem.species) {
        Write-Host "`n  Species: $($species.type)" -ForegroundColor Yellow
        
        for ($i = 0; $i -lt $species.population; $i++) {
            # 生成基因
            $genome = New-Genome -Species $species.type -Generation 0
            
            # 构建任务
            $taskPrompt = Build-TaskPrompt -Genome $genome -EcosystemTask $Ecosystem.task
            
            # Spawn agent (模拟)
            $organism = @{
                id = "$($species.type)-gen0-$i"
                species = $species.type
                genome = $genome
                fitness = 0.0
                generation = 0
                status = "alive"
                spawned_at = (Get-Date).ToString("o")
                task = $taskPrompt
            }
            
            $Ecosystem.organisms += $organism
            
            Write-Host "    🦋 Spawned: $($organism.id)" -ForegroundColor Green
            Write-Host "       Strategy: $($genome.strategy)"
            Write-Host "       Tools: $($genome.tools -join ', ')"
        }
    }
    
    Write-Host "`n  ✅ Total organisms: $($Ecosystem.organisms.Count)" -ForegroundColor Green
    
    return $Ecosystem
}

function Build-TaskPrompt {
    param(
        [hashtable]$Genome,
        [string]$EcosystemTask
    )
    
    $prompt = @"

You are part of an EVOLVING ECOSYSTEM of agents.

🧬 Your Genome:
- Species: $($Genome.species)
- Strategy: $($Genome.strategy)
- Tools: $($Genome.tools -join ', ')
- Thinking: $($Genome.thinking_style)
- Innovation: $($Genome.innovation_level)

🎯 Ecosystem Task:
$EcosystemTask

⚡ Your Mission:
Work on this task using your UNIQUE strategy. You are ONE of MANY agents exploring different approaches.

Your goal is not just to complete the task, but to find the BEST approach based on your genome.

Be innovative! Your approach will be evaluated and the best strategies will be passed to the next generation.

Report your work quality, speed, and any innovations you discovered.
"@
    
    return $prompt
}

function Invoke-Evolution {
    param(
        [hashtable]$Ecosystem,
        [int]$Generations = 5
    )
    
    Write-Host "`n🧬 Starting evolution..." -ForegroundColor Cyan
    
    for ($gen = 0; $gen -lt $Generations; $gen++) {
        Write-Host @"

========================================
🧬 GENERATION $gen
========================================
"@ -ForegroundColor Magenta
        
        $Ecosystem.current_generation = $gen
        
        # 1. 评估适应度
        Write-Host "`n📊 Evaluating fitness..." -ForegroundColor Yellow
        foreach ($org in $Ecosystem.organisms | Where-Object { $_.status -eq "alive" -and $_.generation -eq $gen }) {
            $org = Measure-Fitness -Organism $org -Ecosystem $Ecosystem
        }
        
        # 2. 展示当前状态
        Show-EcosystemStatus -Ecosystem $Ecosystem
        
        # 3. 选择精英
        $elites = Select-Elites -Ecosystem $Ecosystem -Species "developer" -Count 2
        
        if ($elites.Count -gt 0) {
            $bestFitness = ($elites | Select-Object -First 1).fitness
            
            Write-Host "`n🏆 Elite organisms:" -ForegroundColor Green
            foreach ($elite in $elites) {
                Write-Host "  [$($elite.fitness | ToString('0.00'))] $($elite.id)" -ForegroundColor Cyan
                Write-Host "    Strategy: $($elite.genome.strategy)"
            }
            
            # 检测停滞
            if ($bestFitness -le $Ecosystem.best_fitness) {
                $Ecosystem.stagnation_count++
            } else {
                $Ecosystem.stagnation_count = 0
                $Ecosystem.best_fitness = $bestFitness
            }
            
            # 4. 生成下一代（如果不是最后一代）
            if ($gen -lt $Generations - 1 -and $Ecosystem.stagnation_count -lt 2) {
                Write-Host "`n🧬 Reproducing next generation..." -ForegroundColor Yellow
                Reproduce-NextGeneration -Ecosystem $Ecosystem -Elites $elites
            }
        }
        
        # 5. 淘汰低适应度个体
        Cull-WeakOrganisms -Ecosystem $Ecosystem -Generation $gen
        
        # 6. 保存状态
        Save-Ecosystem -Ecosystem $Ecosystem
        
        # 7. 检查收敛
        if ($Ecosystem.stagnation_count -ge 2) {
            Write-Host "`n✋ Evolution stagnated. Stopping early." -ForegroundColor Yellow
            break
        }
        
        if ($Ecosystem.best_fitness -ge 0.95) {
            Write-Host "`n🎯 Target fitness reached!" -ForegroundColor Green
            break
        }
    }
    
    # 提取最优解
    $best = $Ecosystem.organisms | Sort-Object fitness -Descending | Select-Object -First 1
    
    Write-Host @"

========================================
🎯 EVOLUTION COMPLETE
========================================

Generations: $($Ecosystem.current_generation + 1)
Best Fitness: $($Ecosystem.best_fitness | ToString('0.00'))
Total Organisms: $($Ecosystem.organisms.Count)

🏆 CHAMPION:
  ID: $($best.id)
  Species: $($best.species)
  Strategy: $($best.genome.strategy)
  Tools: $($best.genome.tools -join ', ')
  Fitness: $($best.fitness | ToString('0.00'))

🧬 Genetic Legacy:
  Innovation Level: $($best.genome.innovation_level | ToString('0.0'))
  Thinking Style: $($best.genome.thinking_style)
  Mutations: $($best.genome.mutation_count)
"@
    
    return $Ecosystem
}

function Measure-Fitness {
    param(
        [hashtable]$Organism,
        [hashtable]$Ecosystem
    )
    
    # 模拟适应度评估（实际应用中需要真实评估）
    # 这里使用随机值 + 基因优势
    
    $baseFitness = Get-Random -Minimum 0.2 -Maximum 0.7
    
    # 基因优势
    $strategyBonus = switch ($Organism.genome.strategy) {
        { $_ -in @("tdd", "microservices", "typescript") } { 0.15 }
        { $_ -in @("agile", "modular-monolith", "python") } { 0.10 }
        { $_ -in @("prototyping", "monolith", "manual") } { 0.05 }
        default { 0.0 }
    }
    
    # 创新奖励
    $innovationBonus = $Organism.genome.innovation_level * 0.1
    
    # 世代进步（模拟学习）
    $generationBonus = $Organism.generation * 0.05
    
    $Organism.fitness = [Math]::Min(1.0, $baseFitness + $strategyBonus + $innovationBonus + $generationBonus)
    
    return $Organism
}

function Select-Elites {
    param(
        [hashtable]$Ecosystem,
        [string]$Species = "all",
        [int]$Count = 2
    )
    
    $population = if ($Species -eq "all") {
        $Ecosystem.organisms
    } else {
        $Ecosystem.organisms | Where-Object { $_.species -eq $Species }
    }
    
    $elites = $population `
        | Where-Object { $_.status -eq "alive" } `
        | Sort-Object fitness -Descending `
        | Select-Object -First $Count
    
    return $elites
}

function Reproduce-NextGeneration {
    param(
        [hashtable]$Ecosystem,
        [array]$Elites
    )
    
    foreach ($species in $Ecosystem.species) {
        # 选择该物种的父代
        $parents = $Ecosystem.organisms `
            | Where-Object { $_.species -eq $species.type -and $_.status -eq "alive" } `
            | Sort-Object fitness -Descending `
            | Select-Object -First 2
        
        if ($parents.Count -lt 2) {
            Write-Host "  ⚠️ Not enough parents for $($species.type)" -ForegroundColor Yellow
            continue
        }
        
        # 生成 2-3 个后代
        $offspringCount = Get-Random -Minimum 2 -Maximum 4
        
        for ($i = 0; $i -lt $offspringCount; $i++) {
            # 交叉
            $childGenome = Crossover-Genomes -Parent1 $parents[0].genome -Parent2 $parents[1].genome
            
            # 突变
            if ((Get-Random -Maximum 100) / 100 -lt $species.mutation_rate) {
                $childGenome = Mutate-Genome -Genome $childGenome
            }
            
            # 构建任务
            $taskPrompt = Build-TaskPrompt -Genome $childGenome -EcosystemTask $Ecosystem.task
            
            # 创建后代个体
            $child = @{
                id = "$($species.type)-gen$($Ecosystem.current_generation + 1)-$i"
                species = $species.type
                genome = $childGenome
                fitness = 0.0
                generation = $Ecosystem.current_generation + 1
                status = "alive"
                spawned_at = (Get-Date).ToString("o")
                parents = @($parents[0].id, $parents[1].id)
                task = $taskPrompt
            }
            
            $Ecosystem.organisms += $child
            
            Write-Host "    🐣 Born: $($child.id)" -ForegroundColor Green
            Write-Host "       From: $($parents[0].id) × $($parents[1].id)"
        }
    }
}

function Crossover-Genomes {
    param(
        [hashtable]$Parent1,
        [hashtable]$Parent2
    )
    
    $child = $Parent1.Clone()
    
    # 50% 概率继承每个基因
    if ((Get-Random -Maximum 2) -eq 1) {
        $child.strategy = $Parent2.strategy
    }
    
    if ((Get-Random -Maximum 2) -eq 1) {
        $child.thinking_style = $Parent2.thinking_style
    }
    
    # 工具合并
    $child.tools = ($Parent1.tools + $Parent2.tools) | Select-Object -Unique
    
    # 创新性平均 + 随机波动
    $child.innovation_level = [Math]::Min(1.0, ($Parent1.innovation_level + $Parent2.innovation_level) / 2 + (Get-Random -Minimum -0.1 -Maximum 0.1))
    
    return $child
}

function Mutate-Genome {
    param(
        [hashtable]$Genome
    )
    
    $mutationTypes = @("strategy", "tools", "thinking", "innovation")
    $mutation = $mutationTypes | Get-Random
    
    switch ($mutation) {
        "strategy" {
            # 尝试全新策略
            $newStrategies = @("tdd", "bdd", "agile", "spiral", "prototyping", "microservices", "serverless", "modular-monolith")
            $Genome.strategy = $newStrategies | Get-Random
            Write-Host "      ✨ Strategy mutation: $($Genome.strategy)" -ForegroundColor Yellow
        }
        "tools" {
            # 添加新工具
            $newTools = @("typescript", "rust", "graphql", "kubernetes", "react", "vue", "testing", "ci-cd")
            $newTool = $newTools | Get-Random
            if ($Genome.tools -notcontains $newTool) {
                $Genome.tools += $newTool
                Write-Host "      ✨ Tool mutation: +$newTool" -ForegroundColor Yellow
            }
        }
        "thinking" {
            # 改变思维模式
            $Genome.thinking_style = @("analytical", "creative", "pragmatic") | Get-Random
            Write-Host "      ✨ Thinking mutation: $($Genome.thinking_style)" -ForegroundColor Yellow
        }
        "innovation" {
            # 增加创新性
            $Genome.innovation_level = [Math]::Min(1.0, $Genome.innovation_level + 0.2)
            Write-Host "      ✨ Innovation boost: $($Genome.innovation_level | ToString('0.0'))" -ForegroundColor Yellow
        }
    }
    
    $Genome.mutation_count++
    
    return $Genome
}

function Cull-WeakOrganisms {
    param(
        [hashtable]$Ecosystem,
        [int]$Generation
    )
    
    $threshold = 0.3
    $culled = 0
    
    foreach ($org in $Ecosystem.organisms | Where-Object { 
        $_.generation -eq $Generation -and $_.fitness -lt $threshold 
    }) {
        $org.status = "extinct"
        $culled++
    }
    
    if ($culled -gt 0) {
        Write-Host "`n✂️ Culled $culled weak organisms (fitness < $threshold)" -ForegroundColor Yellow
    }
}

function Show-EcosystemStatus {
    param(
        [hashtable]$Ecosystem
    )
    
    Write-Host @"

📊 ECOSYSTEM STATUS
========================================
Generation: $($Ecosystem.current_generation)
Best Fitness: $($Ecosystem.best_fitness | ToString('0.00'))
Stagnation: $($Ecosystem.stagnation_count)/2

📈 Population by Species
"@
    
    foreach ($species in $Ecosystem.species) {
        $alive = ($Ecosystem.organisms | Where-Object { 
            $_.species -eq $species.type -and $_.status -eq "alive" 
        }).Count
        
        $extinct = ($Ecosystem.organisms | Where-Object { 
            $_.species -eq $species.type -and $_.status -eq "extinct" 
        }).Count
        
        $bar = "█" * $alive + "░" * $extinct
        Write-Host "  $($species.type): $bar ($alive alive, $extinct extinct)"
    }
    
    Write-Host "`n🏆 Top 5 Organisms`n"
    
    $top5 = $Ecosystem.organisms `
        | Where-Object { $_.status -eq "alive" } `
        | Sort-Object fitness -Descending `
        | Select-Object -First 5
    
    foreach ($org in $top5) {
        Write-Host "  [$($org.fitness | ToString('0.00'))] $($org.id)" -ForegroundColor Cyan
        Write-Host "    Strategy: $($org.genome.strategy)" -ForegroundColor Gray
        Write-Host "    Innovation: $($org.genome.innovation_level | ToString('0.0'))`n"
    }
}

function Save-Ecosystem {
    param(
        [hashtable]$Ecosystem
    )
    
    $ecoDir = "~/.openclaw/workspace/ecosystems/$($Ecosystem.name)"
    $Ecosystem | ConvertTo-Json -Depth 10 | Set-Content "$ecoDir/ecosystem.json"
}

function Get-Ecosystem {
    param(
        [string]$Name
    )
    
    $ecoPath = "~/.openclaw/workspace/ecosystems/$Name/ecosystem.json"
    
    if (-not (Test-Path $ecoPath)) {
        Write-Error "Ecosystem not found: $Name"
        return $null
    }
    
    $ecosystem = Get-Content $ecoPath | ConvertFrom-Json
    return $ecosystem
}

function Remove-Ecosystem {
    param(
        [string]$Name,
        [switch]$Force
    )
    
    $ecoDir = "~/.openclaw/workspace/ecosystems/$Name"
    
    if (-not (Test-Path $ecoDir)) {
        Write-Error "Ecosystem not found: $Name"
        return
    }
    
    if (-not $Force) {
        $confirmation = Read-Host "Delete ecosystem '$Name' and all history? (y/N)"
        if ($confirmation -ne "y") {
            Write-Host "Cancelled."
            return
        }
    }
    
    Remove-Item -Recurse -Force $ecoDir
    Write-Host "✅ Ecosystem deleted: $Name" -ForegroundColor Green
}

function Show-EvolutionReport {
    param(
        [string]$Name
    )
    
    $ecosystem = Get-Ecosystem -Name $Name
    
    if ($null -eq $ecosystem) {
        return
    }
    
    Write-Host @"

🧬 EVOLUTION REPORT: $Name
========================================

Created: $($ecosystem.created_at)
Generations: $($ecosystem.current_generation + 1)
Best Fitness: $($ecosystem.best_fitness | ToString('0.00'))

Total Organisms: $($ecosystem.organisms.Count)
Extinct: $(($ecosystem.organisms | Where-Object { $_.status -eq 'extinct' }).Count)
Surviving: $(($ecosystem.organisms | Where-Object { $_.status -eq 'alive' }).Count)

🏆 CHAMPION LINEAGE:
"@
    
    $best = $ecosystem.organisms | Sort-Object fitness -Descending | Select-Object -First 1
    
    Write-Host "  $($best.id)"
    Write-Host "  Species: $($best.species)"
    Write-Host "  Fitness: $($best.fitness | ToString('0.00'))"
    Write-Host "  Strategy: $($best.genome.strategy)"
    Write-Host "  Tools: $($best.genome.tools -join ', ')"
    
    if ($best.parents) {
        Write-Host "`n  🧬 Ancestry:"
        Write-Host "     Parents: $($best.parents -join ', ')"
    }
    
    Write-Host "`n  🧬 Genetic Traits:"
    Write-Host "     Thinking: $($best.genome.thinking_style)"
    Write-Host "     Innovation: $($best.genome.innovation_level | ToString('0.0'))"
    Write-Host "     Mutations: $($best.genome.mutation_count)"
}

# Export functions (disabled - dot-sourced .ps1 files don't use Export-ModuleMember)
# If you convert this to a .psm1 module, uncomment the Export-ModuleMember block below
# Export-ModuleMember -Function @(
#     "New-Ecosystem",
#     "Initialize-Population",
#     "Invoke-Evolution",
#     "Get-Ecosystem",
#     "Remove-Ecosystem",
#     "Show-EvolutionReport",
#     "Show-EcosystemStatus"
# )
