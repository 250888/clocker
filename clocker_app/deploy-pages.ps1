# GitHub Pages 部署脚本 (Windows PowerShell)
# 使用方法:
# 1. 修改 $GITHUB_USER 为你的GitHub用户名
# 2. 运行: .\deploy-pages.ps1

$GITHUB_USER = "your-github-username"  # 替换为你的GitHub用户名
$REPO_NAME = "clocker"
$DEPLOY_BRANCH = "gh-pages"

# 进入web构建目录
Set-Location "build\web"

# 初始化git
if (-not (Test-Path ".git")) {
    git init
}

# 创建或切换到gh-pages分支
$branches = git branch --list $DEPLOY_BRANCH
if ($branches -eq $null -or $branches -eq "") {
    git checkout -b $DEPLOY_BRANCH
} else {
    git checkout $DEPLOY_BRANCH
}

# 添加所有文件
git add -A

# 提交
git commit -m "Deploy Clocker Web - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# 设置远程仓库
$remotes = git remote
if ($remotes -notcontains "origin") {
    git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
}

# 推送
git push origin $DEPLOY_BRANCH --force

Write-Host "✅ 部署成功！" -ForegroundColor Green
Write-Host "访问地址: https://$GITHUB_USER.github.io/$REPO_NAME" -ForegroundColor Cyan
