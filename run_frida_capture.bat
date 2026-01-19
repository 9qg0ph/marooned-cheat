@echo off
chcp 65001 >nul
echo ========================================
echo 🎯 Frida修改器捕获系统
echo ========================================
echo.

set FRIDA_PATH=C:\Users\Administrator\AppData\Roaming\Python\Python38\Scripts\frida.exe

echo 📱 请确保手机已连接并且Frida服务正在运行
echo 💡 然后在手机上操作其他修改器，我们将实时捕获
echo.

echo 🚀 启动实时捕获脚本...
echo.

"%FRIDA_PATH%" -U -l frida_realtime_capture.js "我独自生活"

pause