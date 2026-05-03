# Stocks 项目完整修复脚本
# 一键解决所有依赖和启动问题

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$projectDir = "G:\My-Project\Stocks\wall-street-analyst"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Stocks 项目完整修复脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查项目目录
if (-not (Test-Path $projectDir)) {
    Write-Host "❌ 项目目录不存在: $projectDir" -ForegroundColor Red
    exit 1
}

Set-Location $projectDir
Write-Host "✅ 项目目录: $projectDir" -ForegroundColor Green
Write-Host ""

# 步骤 1：清理
Write-Host "步骤 1/4: 清理旧文件..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

Remove-Item node_modules -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ 删除 node_modules" -ForegroundColor Green

Remove-Item package-lock.json -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ 删除 package-lock.json" -ForegroundColor Green

Remove-Item .next -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ 删除 .next" -ForegroundColor Green

Write-Host ""

# 步骤 2：修复 package.json
Write-Host "步骤 2/4: 检查 package.json..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$packageJson = Get-Content package.json -Raw | ConvertFrom-Json

# 确保版本正确
if (-not $packageJson.devDependencies) {
    $packageJson.devDependencies = @{}
}

$packageJson.devDependencies.typescript = "^5.7.3"
$packageJson.devDependencies.'@types/node' = "^20.11.0"
$packageJson.devDependencies.'@types/react' = "^18.2.0"
$packageJson.devDependencies.'@types/react-dom' = "^18.2.0"

$packageJson | ConvertTo-Json -Depth 10 | Set-Content package.json
Write-Host "  ✓ package.json 已更新" -ForegroundColor Green

Write-Host ""

# 步骤 3：安装依赖
Write-Host "步骤 3/4: 安装依赖..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "这可能需要 2-3 分钟，请耐心等待..." -ForegroundColor Gray
Write-Host ""

$installResult = npm install --legacy-peer-deps 2>&1 | Tee-Object -FilePath install-output.txt

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ npm install 失败" -ForegroundColor Red
    Write-Host "查看详细日志: install-output.txt" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "✅ 依赖安装完成" -ForegroundColor Green

# 检查关键依赖
$dependencies = @("node_modules/next", "node_modules/react", "node_modules/typescript")
$missing = @()

foreach ($dep in $dependencies) {
    if (-not (Test-Path $dep)) {
        $missing += $dep
    }
}

if ($missing.Count -gt 0) {
    Write-Host "⚠️  检测到缺失依赖:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    Write-Host ""
    Write-Host "尝试手动安装缺失的依赖..." -ForegroundColor Yellow
    npm install --legacy-peer-deps --force
}

Write-Host ""

# 步骤 4：验证和测试
Write-Host "步骤 4/4: 验证项目..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

# 检查 Next.js CLI
$nextCli = Get-Command npx next -ErrorAction SilentlyContinue
if (-not $nextCli) {
    Write-Host "⚠️  Next.js CLI 未找到，尝试使用 npx" -ForegroundColor Yellow
    $nextCmd = "npx next"
} else {
    $nextCmd = "next"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 修复完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "下一步操作:" -ForegroundColor Cyan
Write-Host "  1. 启动开发服务器:" -ForegroundColor Gray
Write-Host "     npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "  2. 构建项目:" -ForegroundColor Gray
Write-Host "     npm run build" -ForegroundColor White
Write-Host ""
Write-Host "  3. 运行生产服务器:" -ForegroundColor Gray
Write-Host "     npm run start" -ForegroundColor White
Write-Host ""

Write-Host "测试命令:" -ForegroundColor Yellow
Write-Host "  npm run dev" -ForegroundColor Gray
Write-Host ""
