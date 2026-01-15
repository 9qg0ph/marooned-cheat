# 饥饿荒野修改器

## 功能
- 🥕 无限金萝卜 (99999)
- 📺 广告跳过

## 编译方法

### 方法1: GitHub Actions (推荐)
1. 将此项目推送到 GitHub
2. 进入 Actions 页面
3. 运行 "Build iOS Dylib" workflow
4. 下载生成的 `MaroonedCheat.dylib`

### 方法2: Mac 本地编译
```bash
cd 饥饿荒野Dylib

clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -fobjc-arc \
  -o MaroonedCheat.dylib \
  MaroonedCheat.m

# 签名
ldid -S MaroonedCheat.dylib
```

## 安装方法

### TrollStore 注入
1. 用 TrollStore 安装饥饿荒野 IPA
2. 将 `MaroonedCheat.dylib` 复制到设备
3. 用注入工具（如 Sideloadly、IPAPatcher）将 dylib 注入到 IPA
4. 重新安装注入后的 IPA

### 越狱设备
1. 将 `MaroonedCheat.dylib` 复制到 `/Library/MobileSubstrate/DynamicLibraries/`
2. 创建 plist 文件指定目标 bundle: `com.fastfly.marooned`
3. 重启 SpringBoard

## 使用方法
1. 打开游戏
2. 等待 2 秒后出现红色悬浮按钮 🏝️
3. 点击悬浮按钮打开菜单
4. 选择需要的功能
5. 悬浮按钮可拖动

## 目标游戏
- Bundle ID: `com.fastfly.marooned`
- 游戏名称: 饥饿荒野 / 挨饿荒野

## 注意事项
- 仅供学习研究使用
- 修改游戏可能违反服务条款
- 使用风险自负
