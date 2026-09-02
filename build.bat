@echo off
chcp 65001 >nul
echo ============================================
echo    Shield Guardian - 快速编译脚本
echo ============================================
echo.

cd /d D:\shield-guardian

echo [1/5] 检查Flutter环境...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter未安装！
    echo.
    echo 请先安装Flutter SDK：
    echo 1. 访问 https://docs.flutter.dev/get-started/install/windows
    echo 2. 下载并解压到 D:\flutter
    echo 3. 将 D:\flutter\bin 添加到系统PATH
    echo 4. 重新运行此脚本
    pause
    exit /b 1
)
echo ✅ Flutter已安装

echo.
echo [2/5] 检查项目依赖...
if not exist "pubspec.yaml" (
    echo ❌ 未找到项目文件！
    echo 请确保在 D:\shield-guardian 目录运行此脚本
    pause
    exit /b 1
)
echo ✅ 项目文件正常

echo.
echo [3/5] 安装依赖包...
call flutter pub get
if %errorlevel% neq 0 (
    echo ❌ 依赖安装失败！
    pause
    exit /b 1
)
echo ✅ 依赖安装完成

echo.
echo [4/5] 清理旧编译...
call flutter clean

echo.
echo [5/5] 开始编译APK...
echo 这可能需要几分钟，请耐心等待...
call flutter build apk --release

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo    ✅ 编译成功！
    echo ============================================
    echo.
    echo APK位置:
    echo D:\shield-guardian\build\app\outputs\flutter-apk\app-release.apk
    echo.
    echo 您现在可以：
    echo 1. 将APK复制到手机安装
    echo 2. 使用 adb install 命令安装
    echo 3. 上传到GitHub Releases
    echo.
    start explorer "D:\shield-guardian\build\app\outputs\flutter-apk"
) else (
    echo.
    echo ============================================
    echo    ❌ 编译失败！
    echo ============================================
    echo.
    echo 常见问题解决：
    echo 1. 确保已安装Android SDK
    echo 2. 运行 flutter doctor 检查环境
    echo 3. 查看上方错误信息
    echo.
)

echo.
pause
