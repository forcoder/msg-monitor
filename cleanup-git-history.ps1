# Git History Cleanup Script
# 用于清除 Git 历史中的敏感信息

# ⚠️ 警告：这是一个危险操作！
# 在执行之前，请确保：
# 1. 已备份仓库
# 2. 已将所有敏感信息提取到环境变量或 GitHub Secrets
# 3. 理解 git filter-branch 会重写所有历史

# 需要清除的敏感模式（这些是字符串字面值，会被替换为空字符串）
# 请根据实际情况修改这些值
$patternsToRemove = @(
    "REMOVED_AKID",   # 阿里云 Access Key ID
    "REMOVED_AKSK"  # 阿里云 Access Key Secret
    # 添加更多需要清除的敏感字符串
)

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Git History Sensitive Data Cleanup" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

# 检查是否已安装 git-filter-repo
$filterRepoAvailable = $null -ne (Get-Command git-filter-repo -ErrorAction SilentlyContinue)

if (-not $filterRepoAvailable) {
    Write-Host "推荐使用 git-filter-repo 工具来清除敏感信息" -ForegroundColor Cyan
    Write-Host "安装方式: pip install git-filter-repo" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "或者使用 git filter-branch（较慢）" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "将清除以下敏感信息:" -ForegroundColor Red
foreach ($pattern in $patternsToRemove) {
    Write-Host "  - $pattern" -ForegroundColor Red
}
Write-Host ""

# 确认操作
$confirm = Read-Host "是否继续？(输入 'yes' 确认)"
if ($confirm -ne "yes") {
    Write-Host "操作已取消" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "开始清除敏感信息..." -ForegroundColor Yellow

# 使用 git filter-branch 清除敏感信息
$filterCmd = "git filter-branch --force --index-filter "
$filterCmd += '"git filter-branch --tree-filter ''"
foreach ($pattern in $patternsToRemove) {
    $filterCmd += "find . -type f -exec sed -i 's/$pattern//g' {} \;; "
}
$filterCmd += "'' --tag-name-filter cat -- --all"

Write-Host "执行: $filterCmd" -ForegroundColor Gray

# 备份 refs
if (Test-Path ".git/refs/original") {
    Write-Host "发现旧的 original refs，先删除..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force ".git/refs/original"
}

# 执行 filter-branch
Invoke-Expression $filterCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "敏感信息已从本地 Git 历史中清除" -ForegroundColor Green
    Write-Host ""
    Write-Host "下一步操作:" -ForegroundColor Cyan
    Write-Host "1. 验证敏感信息已被清除:"
    Write-Host "   git log --all --full-history --source --remotes --format='%H %s' | head -20"
    Write-Host ""
    Write-Host "2. 强制推送以更新远程仓库:"
    Write-Host "   git push origin --force --all"
    Write-Host "   git push origin --force --tags"
    Write-Host ""
    Write-Host "⚠️ 注意：这会重写远程仓库的历史！" -ForegroundColor Red
    Write-Host "   如果其他人在使用这个仓库，需要他们重新克隆。" -ForegroundColor Red
} else {
    Write-Host "清除失败，错误代码: $LASTEXITCODE" -ForegroundColor Red
}
