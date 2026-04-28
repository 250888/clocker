#!/bin/bash
# GitHub Pages 自动部署脚本
# 使用方法：
# 1. 将build/web目录的内容push到GitHub Pages分支
# 2. 或者使用GitHub Actions自动部署

# 设置变量
GITHUB_USER="your-github-username"  # 替换为你的GitHub用户名
REPO_NAME="clocker"                # 仓库名
DEPLOY_BRANCH="gh-pages"           # 部署分支

# 进入构建目录
cd build/web

# 初始化git（如果还没有）
git init
git checkout -b $DEPLOY_BRANCH 2>/dev/null || git checkout $DEPLOY_BRANCH

# 添加所有文件
git add -A

# 提交
git commit -m "Deploy Clocker Web - $(date '+%Y-%m-%d %H:%M:%S')"

# 设置远程仓库（如果还没有）
git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git" 2>/dev/null

# 推送到GitHub Pages分支
git push origin $DEPLOY_BRANCH --force

echo "✅ 部署成功！访问 https://$GITHUB_USER.github.io/$REPO_NAME"
