# 天选打工人修改器 Dylib

## 功能

- 💰 无限货币（满100爱心开启）
- 🏆 无限金条（满100爱心开启）
- 🎁 一键全开

## 使用方法

1. 确保游戏中**爱心已满100**
2. 点击悬浮按钮打开菜单
3. 点击对应功能按钮

## 原理

通过内存搜索找到爱心值(100)的地址，然后通过固定偏移量找到金钱和金条：
- 金钱 = 爱心地址 - 0x18
- 金条 = 爱心地址 - 0x14

## 编译

使用 GitHub Actions 自动编译，或在 Mac 上手动编译：

```bash
clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -fobjc-arc \
  -o TianXuanDaGongRenCheat.dylib \
  TianXuanDaGongRenCheat.m

ldid -S TianXuanDaGongRenCheat.dylib
```

## 注入

使用 IPAPatcher 或其他工具将 dylib 注入到游戏 IPA 中。

## 免责声明

本工具仅供技术研究与学习，严禁用于商业用途。
