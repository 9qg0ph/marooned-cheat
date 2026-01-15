# 卡包修仙 Hook 教程

## 第一步：准备工作

### 环境检查
- ✅ Windows 电脑 + Python + Frida
- ✅ 越狱 iOS 设备 + frida-server
- ✅ 卡包修仙游戏已安装 GameForFun.dylib 插件
- ✅ 有效的 VIP 账号（能正常显示功能菜单）
- ✅ 手机已连接

### 确认设备连接
```bash
python -m frida_tools.ps -U
```

## 第二步：获取卡包修仙包名

首先需要确定卡包修仙的 Bundle ID：

```bash
# 列出所有应用
python -m frida_tools.ps -U

# 或者查找包含"卡包"或"修仙"的应用
python -m frida_tools.ps -U | findstr "卡包\|修仙"
```

## 第三步：开始抓取参数

### 1. 启动 Frida Hook
```bash
# 替换 <卡包修仙包名> 为实际的 Bundle ID
python -m frida_tools.repl -U -f <卡包修仙包名> -l hook_kabao_setvalue.js
```

### 2. 操作游戏抓取数据
1. 等待 8 秒让 Hook 生效
2. 点击悬浮图标打开功能菜单
3. **逐个开启每个功能**（重要：一个一个开启，不要同时开启多个）
4. 记录控制台输出的参数

### 3. 预期输出示例
```
[卡包修仙 setValue]
  key: kabao_gold_coins
  value: 99999
  type: Number
  ==================

[卡包修仙 setValue]
  key: kabao_diamonds
  value: 99999
  type: Number
  ==================

[卡包修仙 setValue]
  key: kabao_card_packs
  value: 99999
  type: Number
  ==================

[卡包修仙 setValue]
  key: fanhan_AVP
  value: 1
  type: bool
  ==================
```

## 第四步：更新 Dylib 代码

根据抓取到的参数，更新 `卡包修仙Dylib/KaBaoXiuXianCheat.m` 文件中的参数：

### 找到 buttonTapped 方法，更新以下部分：

```objective-c
- (void)buttonTapped:(UIButton *)sender {
    switch (sender.tag) {
        case 0:
            [self removeFromSuperview];
            g_menuView = nil;
            break;
        case 1:
            // 更新为实际抓取的金币参数
            setGameValue(@"实际的金币key", @99999, @"Number");
            [self showAlert:@"💰 无限金币开启成功！"];
            break;
        case 2:
            // 更新为实际抓取的钻石参数
            setGameValue(@"实际的钻石key", @99999, @"Number");
            [self showAlert:@"💎 无限钻石开启成功！"];
            break;
        case 3:
            // 更新为实际抓取的卡包参数
            setGameValue(@"实际的卡包key", @99999, @"Number");
            [self showAlert:@"🎴 无限卡包开启成功！"];
            break;
        case 4:
            // 更新为实际抓取的广告跳过参数
            setGameValue(@"实际的广告key", @1, @"bool");
            [self showAlert:@"📺 广告跳过开启成功！"];
            break;
    }
}
```

## 第五步：编译 Dylib

### 方法1: GitHub Actions（推荐）
1. 将项目推送到 GitHub
2. 进入 Actions 页面
3. 运行 "Build KaBao XiuXian iOS Dylib" workflow
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

## 第六步：注入到游戏

### 使用注入工具
1. 准备卡包修仙 IPA 和编译好的 dylib
2. 使用 IPAPatcher / Sideloadly 等工具注入 dylib
3. 用 TrollStore 安装注入后的 IPA

## 第七步：测试功能

1. 打开注入后的卡包修仙游戏
2. 等待 2 秒后出现蓝色悬浮按钮 🎴
3. 点击悬浮按钮打开菜单
4. 测试各个功能是否正常工作

## 常见问题

### Q: Hook 脚本没有输出？
A: 
- 检查游戏是否安装了 GameForFun.dylib
- 确认 VIP 账号是否有效
- 尝试重新启动游戏和 Frida

### Q: 抓取到的参数无效？
A: 
- 确保逐个开启功能，不要同时开启
- 检查参数的 type 是否正确
- 某些功能可能使用内存搜索而非键值存储

### Q: 编译失败？
A: 
- 检查 Xcode 命令行工具是否安装
- 确认 macOS 版本兼容性
- 使用 GitHub Actions 自动编译

## 注意事项

1. **仅供学习研究使用**
2. 抓取的参数可能随游戏更新失效
3. 不同游戏的参数名称不同，需要单独抓取
4. 修改游戏可能违反服务条款，使用风险自负