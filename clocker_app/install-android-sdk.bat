@echo off
echo ====================================
echo Clocker Android SDK 一键安装
echo ====================================
echo.
echo 注意：由于网络限制，需要手动下载以下文件：
echo 1. Android SDK Command Line Tools
echo 2. Android SDK Platform
echo 3. Android SDK Build-Tools
echo.
echo 下载地址（任选其一）：
echo 1. 官方地址：https://developer.android.com/studio#command-line-tools-only
echo 2. 国内镜像：https://mirrors.cloud.tencent.com/android/repository/
echo.
echo 下载后：
echo 1. 解压到 D:\Android\Sdk\cmdline-tools
echo 2. 运行: flutter doctor --android-licenses
echo 3. 运行: flutter build apk --release
echo.
pause
