@echo off
echo 🚀 开始编译 WoduziCheat v16.0 高级版...

REM 检查是否在正确目录
if not exist "WoduziCheat_Advanced.m" (
    echo ❌ 错误: 未找到 WoduziCheat_Advanced.m 文件
    echo 请确保在正确的目录中运行此脚本
    pause
    exit /b 1
)

REM 设置编译参数
set ARCH=arm64
set MIN_IOS_VERSION=14.0
set SOURCE_FILE=WoduziCheat_Advanced.m
set OUTPUT_FILE=WoduziCheat_Advanced.dylib

echo 📋 编译配置:
echo    架构: %ARCH%
echo    最低iOS版本: %MIN_IOS_VERSION%
echo    源文件: %SOURCE_FILE%
echo    输出文件: %OUTPUT_FILE%
echo.

REM 获取SDK路径
for /f "tokens=*" %%i in ('xcrun --sdk iphoneos --show-sdk-path 2^>nul') do set SDK_PATH=%%i

if "%SDK_PATH%"=="" (
    echo ❌ 错误: 无法获取iOS SDK路径
    echo 请确保已安装Xcode Command Line Tools
    echo 运行: xcode-select --install
    pause
    exit /b 1
)

echo SDK路径: %SDK_PATH%
echo.

REM 编译dylib
echo 🔨 正在编译高级版...
clang -arch %ARCH% ^
  -isysroot "%SDK_PATH%" ^
  -miphoneos-version-min=%MIN_IOS_VERSION% ^
  -dynamiclib ^
  -framework UIKit ^
  -framework Foundation ^
  -fobjc-arc ^
  -O2 ^
  -o "%OUTPUT_FILE%" ^
  "%SOURCE_FILE%"

if %errorlevel% neq 0 (
    echo ❌ 编译失败!
    echo 请检查:
    echo 1. Xcode Command Line Tools是否已安装
    echo 2. iOS SDK是否可用
    echo 3. 源文件是否存在语法错误
    pause
    exit /b 1
)

echo ✅ 编译成功!
echo.

REM 显示文件信息
if exist "%OUTPUT_FILE%" (
    echo 📊 文件信息:
    dir "%OUTPUT_FILE%" | findstr "%OUTPUT_FILE%"
    echo.
    
    REM 代码签名 (如果有ldid)
    where ldid >nul 2>&1
    if %errorlevel% equ 0 (
        echo 🔐 正在进行代码签名...
        ldid -S "%OUTPUT_FILE%"
        echo ✅ 代码签名完成
    ) else (
        echo ⚠️  警告: 未找到ldid，跳过代码签名
        echo    可以手动安装: brew install ldid
    )
    
    echo.
    echo 🎉 编译完成!
    echo 📁 输出文件: %CD%\%OUTPUT_FILE%
    echo.
    echo 📋 使用说明:
    echo 1. 将 %OUTPUT_FILE% 注入到游戏中
    echo 2. 启动游戏，看到红色'高级'悬浮按钮
    echo 3. 点击按钮打开高级功能菜单
    echo 4. 先启用Hook，再设置数值
    echo 5. 在游戏中操作触发拦截
    echo.
    echo 🔧 技术特性:
    echo • 多层Hook架构 (NSUserDefaults + 内存操作)
    echo • 智能数值识别系统
    echo • PlayGearLib标准数值 (21亿/10万)
    echo • 实时拦截统计
    echo • 完整日志记录
    echo.
    echo ⚠️  重要: 这是v16.0高级版，不同于v15.3稳定版!
    
) else (
    echo ❌ 错误: 未找到输出文件
)

echo.
echo 按任意键退出...
pause >nul