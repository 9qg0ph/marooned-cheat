#!/bin/bash

# 卡包修仙 Dylib 编译脚本
# 使用 Xcode 命令行工具编译

echo "🔨 开始编译卡包修仙修改器 Dylib..."

# 检查 Xcode 命令行工具
if ! command -v clang &> /dev/null; then
    echo "❌ 错误: 未找到 clang 编译器"
    echo "请安装 Xcode 命令行工具: xcode-select --install"
    exit 1
fi

# 设置编译参数
ARCH="arm64"
MIN_IOS_VERSION="12.0"
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
OUTPUT_NAME="KabaoCheat.dylib"

# 编译命令
clang -arch $ARCH \
      -isysroot $SDK_PATH \
      -miphoneos-version-min=$MIN_IOS_VERSION \
      -dynamiclib \
      -install_name @rpath/$OUTPUT_NAME \
      -framework Foundation \
      -framework UIKit \
      -framework CoreGraphics \
      -framework QuartzCore \
      -fobjc-arc \
      -O2 \
      -o $OUTPUT_NAME \
      KabaoCheat.m

# 检查编译结果
if [ $? -eq 0 ]; then
    echo "✅ 编译成功!"
    echo "📦 输出文件: $OUTPUT_NAME"
    
    # 显示文件信息
    ls -lh $OUTPUT_NAME
    file $OUTPUT_NAME
    
    # 代码签名 (可选)
    if command -v codesign &> /dev/null; then
        echo "🔐 正在进行代码签名..."
        codesign -f -s - $OUTPUT_NAME
        echo "✅ 代码签名完成"
    fi
    
    echo ""
    echo "🎉 编译完成! 使用方法:"
    echo "1. 将 $OUTPUT_NAME 注入到游戏 IPA 中"
    echo "2. 使用 TrollStore 安装修改后的 IPA"
    echo "3. 启动游戏，会自动显示悬浮按钮"
    
else
    echo "❌ 编译失败!"
    exit 1
fi