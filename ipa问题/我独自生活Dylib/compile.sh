#!/bin/bash

# 我独自生活修改器编译脚本
# 使用方法: ./compile.sh

echo "🔨 开始编译我独自生活修改器..."

# 检查Xcode命令行工具
if ! command -v clang &> /dev/null; then
    echo "❌ 错误: 未找到clang编译器，请安装Xcode命令行工具"
    echo "   运行: xcode-select --install"
    exit 1
fi

# 检查ldid
if ! command -v ldid &> /dev/null; then
    echo "⚠️  警告: 未找到ldid，将跳过签名步骤"
    echo "   可通过Homebrew安装: brew install ldid"
fi

# 编译参数
ARCH="arm64"
MIN_VERSION="14.0"
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
SOURCE_FILE="WoduziCheat.m"
OUTPUT_FILE="WoduziCheat.dylib"

# 清理旧文件
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
    echo "🗑️  已清理旧的dylib文件"
fi

# 编译
echo "📦 正在编译..."
clang -arch $ARCH \
  -isysroot "$SDK_PATH" \
  -miphoneos-version-min=$MIN_VERSION \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -fobjc-arc \
  -o "$OUTPUT_FILE" \
  "$SOURCE_FILE"

# 检查编译结果
if [ $? -eq 0 ]; then
    echo "✅ 编译成功: $OUTPUT_FILE"
    
    # 签名
    if command -v ldid &> /dev/null; then
        echo "🔐 正在签名..."
        ldid -S "$OUTPUT_FILE"
        if [ $? -eq 0 ]; then
            echo "✅ 签名成功"
        else
            echo "❌ 签名失败"
        fi
    fi
    
    # 显示文件信息
    echo ""
    echo "📊 文件信息:"
    ls -lh "$OUTPUT_FILE"
    echo ""
    echo "🎯 架构信息:"
    file "$OUTPUT_FILE"
    echo ""
    echo "🎉 编译完成！"
    echo ""
    echo "📝 使用说明:"
    echo "1. 将 $OUTPUT_FILE 注入到游戏"
    echo "2. 启动游戏，点击悬浮按钮"
    echo "3. 选择功能后游戏会自动重启"
    echo "4. 重新打开游戏查看效果"
    
else
    echo "❌ 编译失败"
    exit 1
fi