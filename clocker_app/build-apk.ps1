# Clocker Android APK 构建脚本
# 前提条件：
# 1. 已安装Android SDK到 D:\Android\Sdk
# 2. 已接受Android licenses

$ErrorActionPreference = "Stop"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Clocker Android APK 构建脚本" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 设置环境变量
$env:ANDROID_HOME = "D:\Android\Sdk"
$env:ANDROID_SDK_ROOT = "D:\Android\Sdk"
$env:PATH = "$env:ANDROID_HOME\cmdline-tools\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"

# 检查Flutter
Write-Host "检查Flutter环境..." -ForegroundColor Yellow
flutter doctor -v
Write-Host ""

# 接受licenses（如果需要）
Write-Host "接受Android licenses..." -ForegroundColor Yellow
flutter doctor --android-licenses 2>$null
Write-Host ""

# 清理并构建
Write-Host "清理旧构建..." -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host ""
Write-Host "开始构建 release APK..." -ForegroundColor Green
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "构建成功！" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host ""
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    Write-Host "APK位置: $apkPath" -ForegroundColor Cyan
    Write-Host "文件大小: $((Get-Item $apkPath).Length / 1MB) MB" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "构建失败！请检查上面的错误信息。" -ForegroundColor Red
    Write-Host ""
    Write-Host "常见问题：" -ForegroundColor Yellow
    Write-Host "1. Android SDK未安装或不完整" -ForegroundColor Yellow
    Write-Host "2. 未接受Android licenses" -ForegroundColor Yellow
    Write-Host "3. 网络问题导致SDK下载失败" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "解决方案：" -ForegroundColor Green
    Write-Host "1. 确保 D:\Android\Sdk 目录存在且包含：platforms, build-tools, platform-tools" -ForegroundColor Green
    Write-Host "2. 运行: flutter doctor --android-licenses" -ForegroundColor Green
    Write-Host "3. 使用国内镜像下载SDK" -ForegroundColor Green
}
