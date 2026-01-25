# GameForFun.dylib 脚本抓取与 Dylib 制作教程

## 概述

GameForFun.dylib 是一个 iOS 游戏修改插件，功能脚本从云端加载。本教程介绍如何使用 Frida 抓取云端脚本参数，并制作自己的 dylib 插件。

---

## 一、准备工作

### 环境要求
- Windows 电脑 + Python + Frida
- 越狱 iOS 设备 + frida-server
- 目标游戏已安装 GameForFun.dylib 插件
- 有效的 VIP 账号（能正常显示功能菜单）
- GitHub 账号（用于编译 dylib）

Frida已安装到这个路径"C:\Users\Administrator\AppData\Roaming\Python\Python38\Scripts\frida.exe" 

### 连接设备
```bash
python -m frida_tools.ps -U
```

---

## 二、抓取脚本参数

### 步骤 1：创建 Hook 脚本

创建 `hook_setvalue.js`：

```javascript
console.log("[*] 等待...");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                onEnter: function(args) {
                    var value = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]);
                    var type = ObjC.Object(args[4]);
                    console.log("\n[setValue]");
                    console.log("  key: " + key);
                    console.log("  value: " + value);
                    console.log("  type: " + type);
                }
            });
            console.log("[+] Hook 成功，请开启功能");
        }
    }
}, 8000);
```

### 步骤 2：启动 Frida 并注入

```bash
python -m frida_tools.repl -U -f <包名> -l hook_setvalue.js
```

### 步骤 3：操作游戏抓取数据

1. 等待 8 秒让 Hook 生效
2. 点击悬浮图标打开功能菜单
3. **逐个开启功能**
4. 记录控制台输出的 key、value、type

### 示例输出

```
[setValue]
  key: marooned_gold_luobo_num
  value: 99999
  type: Number

[setValue]
  key: fanhan_AVP
  value: 1
  type: bool
```

---

## 三、制作 Dylib 插件

### 项目结构

```
项目文件夹/
├── .github/workflows/build-dylib.yml   # GitHub Actions 编译配置
└── 饥饿荒野Dylib/
    ├── MaroonedCheat.m                  # 源代码
    └── README.md
```

### 核心代码模板

```objective-c
// 设置游戏数值
static void setGameValue(NSString *key, id value, NSString *type) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([type isEqualToString:@"Number"]) {
        [defaults setInteger:[value integerValue] forKey:key];
    } else if ([type isEqualToString:@"bool"]) {
        [defaults setBool:[value boolValue] forKey:key];
    }
    [defaults synchronize];
}

// 使用示例
setGameValue(@"marooned_gold_luobo_num", @99999, @"Number");
setGameValue(@"fanhan_AVP", @1, @"bool");
```

### GitHub Actions 编译配置

`.github/workflows/build-dylib.yml`:

```yaml
name: Build iOS Dylib

on:
  push:
    paths:
      - '饥饿荒野Dylib/**'
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    - name: Build dylib
      run: |
        cd 饥饿荒野Dylib
        clang -arch arm64 \
          -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
          -miphoneos-version-min=14.0 \
          -dynamiclib \
          -framework UIKit \
          -framework Foundation \
          -framework CoreGraphics \
          -fobjc-arc \
          -Wno-deprecated-declarations \
          -o MaroonedCheat.dylib \
          MaroonedCheat.m
        ldid -S MaroonedCheat.dylib || codesign -f -s - MaroonedCheat.dylib
    - uses: actions/upload-artifact@v4
      with:
        name: MaroonedCheat-dylib
        path: 饥饿荒野Dylib/MaroonedCheat.dylib
```

### 编译步骤

1. 推送代码到 GitHub
2. 进入 Actions 页面
3. 点击 **Build iOS Dylib** → **Run workflow**
4. 下载生成的 dylib

---

## 四、注入到游戏

### 方法：使用注入工具

1. 准备游戏 IPA 和编译好的 dylib
2. 使用 IPAPatcher / Sideloadly 等工具注入 dylib
3. 用 TrollStore 安装注入后的 IPA

---

## 五、实战案例：饥饿荒野

### 游戏信息
- Bundle ID: `com.fastfly.marooned`
- 游戏名称: 饥饿荒野 / 挨饿荒野

### 抓取结果

| 功能 | Key | Value | Type |
|------|-----|-------|------|
| 无限金萝卜 | `marooned_gold_luobo_num` | `99999` | `Number` |
| 广告跳过 | `fanhan_AVP` | `1` | `bool` |

### Dylib 功能
- 悬浮图标（可拖动，从网络加载图标）
- 点击弹出菜单（屏幕居中显示）
- 一键开启功能

---

## 六、注意事项

1. **仅供学习研究**，请勿用于商业用途
2. 抓取的参数可能随游戏更新失效
3. 不同游戏的 key 名称不同，需要单独抓取
4. 某些复杂功能可能使用内存搜索而非键值存储
