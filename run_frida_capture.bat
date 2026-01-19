@echo off
chcp 65001 >nul
echo ========================================
echo 🎯 Frida修改器捕获系统
echo ========================================
echo.

set FRIDA_PATH=C:\Users\Administrator\AppData\Roaming\Python\Python38\Scripts\frida.exe

echo 📱 请确保手机已连接并且Frida服务正在运行
echo.

echo 🔍 首先查找应用包名...
echo.
"%FRIDA_PATH%" -U -l find_app_bundle.js --no-pause

echo.
echo 💡 请从上面的列表中找到"我独自生活"的包名
echo 📝 然后手动运行: 
echo    %FRIDA_PATH% -U -l frida_realtime_capture.js ^<包名^>
echo.
echo 🎯 常见的包名格式示例:
echo    com.company.game
echo    com.developer.lifesimulator
echo    等等...
echo.

pause