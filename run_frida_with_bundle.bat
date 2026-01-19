@echo off
chcp 65001 >nul
echo ========================================
echo 🎯 Frida修改器捕获系统
echo ========================================
echo.

set FRIDA_PATH=C:\Users\Administrator\AppData\Roaming\Python\Python38\Scripts\frida.exe

if "%1"=="" (
    echo ❌ 错误: 请提供应用包名
    echo.
    echo 💡 使用方法:
    echo    %0 ^<应用包名^>
    echo.
    echo 📝 示例:
    echo    %0 com.example.game
    echo.
    echo 🔍 要查找包名，请先运行: find_running_apps.bat
    echo.
    pause
    exit /b 1
)

set BUNDLE_ID=%1

echo 📱 目标应用: %BUNDLE_ID%
echo 🚀 启动实时捕获脚本...
echo.
echo 💡 请在手机上操作其他修改器，我们将实时捕获
echo ⚠️  按 Ctrl+C 停止捕获
echo.

"%FRIDA_PATH%" -U -l frida_realtime_capture.js "%BUNDLE_ID%"

pause