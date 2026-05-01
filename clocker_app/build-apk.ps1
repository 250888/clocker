$ErrorActionPreference = "Stop"

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Clocker Android APK Build" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$flutter = "D:\flutter\bin\flutter.bat"

$sdkPath = $null

if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) {
    $sdkPath = $env:ANDROID_HOME
} elseif ($env:ANDROID_SDK_ROOT -and (Test-Path $env:ANDROID_SDK_ROOT)) {
    $sdkPath = $env:ANDROID_SDK_ROOT
} else {
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk",
        "$env:USERPROFILE\AppData\Local\Android\Sdk",
        "D:\Android\Sdk",
        "C:\Android\Sdk",
        "D:\Android"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) {
            $sdkPath = $c
            break
        }
    }
}

if (-not $sdkPath) {
    Write-Host "Android SDK not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Fix:" -ForegroundColor Yellow
    Write-Host "1. Install Android Studio (auto-downloads SDK)" -ForegroundColor Yellow
    Write-Host "   https://developer.android.com/studio" -ForegroundColor Yellow
    Write-Host "2. Launch Android Studio, Setup Wizard downloads SDK" -ForegroundColor Yellow
    Write-Host "3. Default SDK: C:\Users\<you>\AppData\Local\Android\Sdk" -ForegroundColor Yellow
    Write-Host "4. Then re-run this script" -ForegroundColor Yellow
    exit 1
}

Write-Host "Found Android SDK: $sdkPath" -ForegroundColor Green

$env:ANDROID_HOME = $sdkPath
$env:ANDROID_SDK_ROOT = $sdkPath
$env:PATH = "$sdkPath\cmdline-tools\bin;$sdkPath\platform-tools;$env:PATH"

& $flutter config --android-sdk $sdkPath

$localProps = "android\local.properties"
$sdkForward = $sdkPath -replace '\\', '/'
$flutterForward = "D:/flutter"
$content = "sdk.dir=$sdkForward`r`nflutter.sdk=$flutterForward"
Set-Content -Path $localProps -Value $content -NoNewline -Encoding UTF8
Write-Host "Generated $localProps" -ForegroundColor Green

Write-Host ""
Write-Host "Checking Flutter environment..." -ForegroundColor Yellow
& $flutter doctor -v 2>&1 | Select-Object -First 30
Write-Host ""

Write-Host "Accepting Android licenses..." -ForegroundColor Yellow
echo y | & $flutter doctor --android-licenses 2>$null
Write-Host ""

Write-Host "Cleaning old build..." -ForegroundColor Yellow
& $flutter clean
& $flutter pub get

Write-Host ""
Write-Host "Building release APK..." -ForegroundColor Green
& $flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "Build SUCCESS!" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host ""
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkPath) {
        Write-Host "APK: $apkPath" -ForegroundColor Cyan
        Write-Host "Size: $([math]::Round((Get-Item $apkPath).Length / 1MB, 2)) MB" -ForegroundColor Cyan
    }
} else {
    Write-Host ""
    Write-Host "Build FAILED!" -ForegroundColor Red
    Write-Host "Fix:" -ForegroundColor Yellow
    Write-Host "1. Open project in Android Studio to install SDK" -ForegroundColor Yellow
    Write-Host "2. Run: flutter doctor --android-licenses" -ForegroundColor Yellow
}
