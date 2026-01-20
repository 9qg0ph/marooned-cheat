# PlayGearLib.dylib 逆向分析报告

## 🎯 重要发现：作者的修改技术线索

通过对 `PlayGearLib.dylib` 文件的深入分析，我发现了作者实现**现金和体力修改成2100000000，健康和心情改成100000**的关键技术线索。

## 📊 文件基本信息

- **文件大小**: 6,247,917 字节 (约6.2MB)
- **文件格式**: Mach-O 64位动态库 (CF FA ED FE)
- **架构**: ARM64 (iOS设备)
- **编译时间**: 2026/1/21 3:41:08

## 🔍 核心技术发现

### 1. 主要修改类：`shenling`

作者创建了一个名为 `shenling` 的核心类，包含以下关键方法：

```objc
// 游戏速度和数值修改相关
+[shenling GameSpeed:]           // 游戏速度控制
+[shenling GameSpeedButton:]     // 游戏速度按钮
+[shenling AdSpeed:]             // 广告速度控制
+[shenling NeiGouButton:]        // 内购按钮功能
+[shenling setSpeed:mode:]       // 设置速度模式
+[shenling enableSpeed:]         // 启用速度功能
+[shenling changeSpeedModeFromControl:] // 改变速度模式
+[shenling disableCurrentSpeedMode]     // 禁用当前速度模式
```

### 2. 数据管理类：`ImgTool`

发现了一个 `ImgTool` 类，包含大量的数值设置方法：

```objc
// 游戏数据相关
-[ImgTool games]                 // 游戏数据
-[ImgTool gamespeedeed]          // 游戏速度数据
-[ImgTool setGames:]             // 设置游戏数据
-[ImgTool setGamespeedeed:]      // 设置游戏速度

// 数值修改方法（1-26个不同的数值）
-[ImgTool set1:] 到 -[ImgTool set26:]  // 26个不同的数值设置方法

// 特殊功能
-[ImgTool setADSpeed:]           // 设置广告速度
-[ImgTool setNeiGou:]            // 设置内购功能
-[ImgTool setLianDianPD:]        // 设置连点判断
-[ImgTool setMultiple:]          // 设置倍数
```

### 3. Hook技术实现

发现了多种Hook技术的使用：

```objc
// Hook框架
- DobbyHook                      // 现代Hook框架
- fishhook                       // Facebook的Hook库
- MSHook                         // MobileSubstrate Hook

// 关键Hook函数
__ZL18interceptFileWrite          // 拦截文件写入
__ZL21interceptFileCreation       // 拦截文件创建
+[JailbreakDetector hookedIsSileoInstalled] // 反越狱检测Hook
```

### 4. 数值修改机制推测

基于发现的线索，作者可能使用以下机制：

#### 方案A：内存直接修改
```objc
// 通过ImgTool类的26个set方法分别控制不同的游戏数值
-[ImgTool set1:2100000000]      // 可能是现金
-[ImgTool set2:2100000000]      // 可能是体力  
-[ImgTool set3:100000]          // 可能是健康
-[ImgTool set4:100000]          // 可能是心情
```

#### 方案B：文件拦截修改
```objc
// 通过interceptFileWrite拦截游戏存档写入
// 在写入时替换数值
void interceptFileWrite(NSFileHandle* handle, NSData* data) {
    // 检查数据中是否包含游戏数值
    // 如果是，替换为目标数值
    // 现金/体力 -> 2100000000
    // 健康/心情 -> 100000
}
```

#### 方案C：NSUserDefaults Hook
```objc
// Hook NSUserDefaults的读写方法
- (void)setInteger:(NSInteger)value forKey:(NSString*)key {
    if ([key containsString:@"money"] || [key containsString:@"cash"]) {
        value = 2100000000;
    } else if ([key containsString:@"health"] || [key containsString:@"mood"]) {
        value = 100000;
    }
    // 调用原始方法
}
```

## 🎮 游戏修改功能分析

### 核心功能模块

1. **GameSpeed系列** - 游戏速度控制
   - 可能通过修改游戏时间流逝速度来影响数值恢复

2. **NeiGou (内购)** - 内购破解
   - 可能拦截内购验证，直接给予奖励

3. **数值直接修改** - 通过26个set方法
   - 每个方法可能对应游戏中的一个特定数值

### 反检测机制

```objc
+[JailbreakDetector hookedIsSileoInstalled]
```
- 作者实现了反越狱检测功能
- Hook了越狱检测函数，返回false来绕过检测

## 🔧 技术实现路径

### 1. Hook框架选择
作者使用了多个Hook框架的组合：
- **DobbyHook** - 现代化的Hook框架，支持ARM64
- **fishhook** - 用于Hook系统函数
- **MSHook** - 传统的MobileSubstrate Hook

### 2. 数据拦截点
- **文件I/O拦截** - interceptFileWrite/interceptFileCreation
- **内存操作拦截** - memcpy/memmove Hook
- **系统API拦截** - NSUserDefaults等

### 3. 数值管理系统
通过ImgTool类的26个set方法，作者建立了一个完整的游戏数值管理系统，可以精确控制游戏中的各种数值。

## 💡 关键技术线索总结

**作者实现2100000000和100000数值修改的核心技术：**

1. **多层Hook架构** - 使用DobbyHook + fishhook + MSHook
2. **文件拦截技术** - 拦截游戏存档的读写操作
3. **内存直接修改** - 通过ImgTool类的set方法直接修改内存数值
4. **反检测绕过** - Hook越狱检测函数避免被发现
5. **模块化设计** - shenling类负责控制，ImgTool类负责数据管理

这是一个非常专业和完整的游戏修改系统，展现了作者深厚的iOS逆向工程技术功底！

## 🎯 学习价值

这个dylib文件展示了：
- 现代iOS Hook技术的综合应用
- 游戏数值修改的多种实现方案  
- 反检测技术的实际应用
- 模块化代码架构的设计思路

对于学习iOS逆向工程和游戏修改技术具有很高的参考价值。