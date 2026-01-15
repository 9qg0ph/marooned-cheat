# 卡包修仙修改器

## 功能
- 💰 货币不减反增（包含所有灵石资源）
- ❤️ 无限血量
- ⏰ 增加240年寿命

## 编译方法

### 方法1: GitHub Actions (推荐)
1. 将此项目推送到 GitHub
2. 进入 Actions 页面
3. 运行 "Build iOS Dylib" workflow
4. 下载生成的 `KaBaoXiuXianCheat.dylib`

### 方法2: Mac 本地编译
```bash
cd 卡包修仙Dylib

clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -fobjc-arc \
  -o KaBaoXiuXianCheat.dylib \
  KaBaoXiuXianCheat.m

# 签名
ldid -S KaBaoXiuXianCheat.dylib
```

## 安装方法

### TrollStore 注入
1. 用 TrollStore 安装卡包修仙 IPA
2. 将 `KaBaoXiuXianCheat.dylib` 复制到设备
3. 用注入工具（如 Sideloadly、IPAPatcher）将 dylib 注入到 IPA
4. 重新安装注入后的 IPA

### 越狱设备
1. 将 `KaBaoXiuXianCheat.dylib` 复制到 `/Library/MobileSubstrate/DynamicLibraries/`
2. 创建 plist 文件指定目标 bundle
3. 重启 SpringBoard

## 使用方法
1. 打开游戏
2. 等待 2 秒后出现蓝色悬浮按钮 🎴
3. 点击悬浮按钮打开菜单
4. 选择需要的功能
5. 悬浮按钮可拖动

## 目标游戏
- 游戏名称: 卡包修仙
- Bundle ID: game.taptap.lantern.kbxx

## 抓取参数步骤
1. 确保手机已连接并安装了 frida-server
2. 运行命令：`python -m frida_tools.repl -U -f <卡包修仙包名> -l hook_kabao_setvalue.js`
3. 在游戏中逐个开启功能
4. 记录控制台输出的参数
5. 更新 KaBaoXiuXianCheat.m 中的参数

## 需要更新的参数
根据抓取结果，卡包修仙使用 `roleInfo` 键存储JSON格式的游戏数据，包含：
- currency: 货币
- hp/maxHp: 血量
- lingzhi/lingkuang/danyao/faqi/gongfa: 灵石相关资源
- lifeSpan: 寿命

## 游戏特性
- 修改功能后游戏会自动闪退重启，这是正常现象
- 重新进入游戏后修改的数值会生效

## 注意事项
- 仅供学习研究使用
- 修改游戏可能违反服务条款
- 使用风险自负
- 参数需要根据实际抓取结果进行调整