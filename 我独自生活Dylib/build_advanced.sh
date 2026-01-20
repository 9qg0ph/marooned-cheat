#!/bin/bash

# 我独自生活修改器 v16.0 高级版编译脚本
# 基于PlayGearLib.dylib技术分析

echo "🚀 开始编译 WoduziCheat v16.0 高级版..."

# 检查Xcode工具链
if ! command -v clang &> /dev/null; then
    echo "❌ 错误: 未找到clang编译器"
    echo "请安装Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

# 设置编译参数
ARCH="arm64"
MIN_IOS_VERSION="14.0"
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
SOURCE_FILE="WoduziCheat_Advanced.m"
OUTPUT_FILE="WoduziCheat_Advanced.dylib"

echo "📋 编译配置:"
echo "   架构: $ARCH"
echo "   最低iOS版本: $MIN_IOS_VERSION"
echo "   SDK路径: $SDK_PATH"
echo "   源文件: $SOURCE_FILE"
echo "   输出文件: $OUTPUT_FILE"

# 编译dylib
echo "🔨 正在编译..."
clang -arch $ARCH \
  -isysroot "$SDK_PATH" \
  -miphoneos-version-min=$MIN_IOS_VERSION \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -fobjc-arc \
  -O2 \
  -o "$OUTPUT_FILE" \
  "$SOURCE_FILE"

# 检查编译结果
if [ $? -eq 0 ]; then
    echo "✅ 编译成功!"
    
    # 显示文件信息
    echo "📊 文件信息:"
    ls -lh "$OUTPUT_FILE"
    
    # 代码签名 (如果有ldid)
    if command -v ldid &> /dev/null; then
        echo "🔐 正在进行代码签名..."
        ldid -S "$OUTPUT_FILE"
        echo "✅ 代码签名完成"
    else
        echo "⚠️  警告: 未找到ldid，跳过代码签名"
        echo "   可以手动安装: brew install ldid"
    fi
    
    echo ""
    echo "🎉 编译完成!"
    echo "📁 输出文件: $(pwd)/$OUTPUT_FILE"
    echo ""
    echo "📋 使用说明:"
    echo "1. 将 $OUTPUT_FILE 注入到游戏中"
    echo "2. 启动游戏，看到红色'高级'悬浮按钮"
    echo "3. 点击按钮打开高级功能菜单"
    echo "4. 先启用Hook，再设置数值"
    echo "5. 在游戏中操作触发拦截"
    echo ""
    echo "🔧 技术特性:"
    echo "• 多层Hook架构 (NSUserDefaults + 内存操作)"
    echo "• 智能数值识别系统"
    echo "• PlayGearLib标准数值 (21亿/10万)"
    echo "• 实时拦截统计"
    echo "• 完整日志记录"
    
else
    echo "❌ 编译失败!"
    echo "请检查:"
    echo "1. Xcode Command Line Tools是否已安装"
    echo "2. iOS SDK是否可用"
    echo "3. 源文件是否存在语法错误"
    exit 1
fi