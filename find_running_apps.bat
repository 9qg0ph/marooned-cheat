@echo off
chcp 65001 >nul
echo ========================================
echo 🔍 查找正在运行的应用
echo ========================================
echo.

set FRIDA_PATH=C:\Users\Administrator\AppData\Roaming\Python\Python38\Scripts\frida.exe

echo 📱 正在查找连接的设备和运行的应用...
echo.

echo 🔍 连接的设备:
"%FRIDA_PATH%" -U --list-devices

echo.
echo 🎮 正在运行的应用:
"%FRIDA_PATH%" -U --list-applications

echo.
echo 💡 使用方法:
echo 1. 在手机上打开"我独自生活"游戏
echo 2. 从上面的列表中找到对应的包名
echo 3. 运行: %FRIDA_PATH% -U -l frida_realtime_capture.js ^<包名^>
echo.

pause