# GameForFun 完整抓取与独立 Dylib 制作教程

## 目录
1. [环境准备](#环境准备)
2. [连接设备与基础测试](#连接设备与基础测试)
3. [抓取 GameForFun 参数](#抓取-gameforfun-参数)
4. [深度分析与问题排查](#深度分析与问题排查)
5. [制作独立 Dylib](#制作独立-dylib)
6. [常见问题与解决方案](#常见问题与解决方案)
7. [实战案例](#实战案例)

---

## 环境准备

### 必需工具
- **Windows 电脑**：运行 Frida 和 Python
- **Python 3.8+**：安装 Frida
- **越狱 iOS 设备**：安装 frida-server
- **目标游戏**：已安装 GameForFun.dylib 插件
- **GitHub 账号**：用于编译 dylib

### 安装 Frida

```bash
# 安装 Frida
pip install frida-tools

# 验证安装
python -m frida_tools.ps -U
```

Frida 通常安装在：
```
C:\Users\Administrator\AppData\Roaming\Python\Python38\Scripts\frida.exe
```

### iOS 设备准备

1. 越狱设备
2. 安装 frida-server（通过 Cydia/Sileo）
3. 确保设备和电脑在同一网络，或通过 USB 连接

---

## 连接设备与基础测试

### 1. 检查设备连接

```bash
# 列出所有进程
python -m frida_tools.ps -U

# 查找特定游戏
python -m frida_tools.ps -U | findstr -i "游戏名"
```

### 2. 获取游戏信息

- **Bundle ID**：在 Filza 中查看游戏的 Info.plist
- **进程名**：通过 `ps -U` 命令查看
- **进程 ID**：动态变化，每次启动游戏都不同

---

## 抓取 GameForFun 参数

### 方法 1：基础 Hook 脚本（推荐用于初步测试）

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

### 方法 2：深度 Hook 脚本（推荐用于问题排查）

创建 `hook_deep.js`：

```javascript
console.log("[*] 等待...");

setTimeout(function() {
    if (ObjC.available) {
        console.log("[+] 开始深度 hook GameForFun...\n");
        
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] 找到 FanhanGGEngine 类");
            
            // 列出所有方法
            console.log("\n=== FanhanGGEngine 的所有方法 ===");
            var methods = ObjC.classes.FanhanGGEngine.$ownMethods;
            methods.forEach(function(method) {
                console.log("  " + method);
            });
            
            // Hook setValue
            Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                onEnter: function(args) {
                    var value = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]);
                    var type = args[4];
                    
                    var typeStr = "undefined";
                    try {
                        if (type && !type.isNull()) {
                            typeStr = ObjC.Object(type).toString();
                        }
                    } catch(e) {}
                    
                    console.log("\n[setValue]");
                    console.log("  key: " + key);
                    console.log("  value: " + value);
                    console.log("  type: " + typeStr);
                }
            });
            
            console.log("[+] Hook 完成");
        }
        
        // Hook NSUserDefaults 看看有没有写入
        console.log("\n=== 监控 NSUserDefaults ===");
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        Interceptor.attach(NSUserDefaults['- setInteger:forKey:'].implementation, {
            onEnter: function(args) {
                var value = args[2];
                var key = ObjC.Object(args[3]);
                console.log("\n[NSUserDefaults setInteger] " + key + " = " + value);
            }
        });
        
        Interceptor.attach(NSUserDefaults['- setObject:forKey:'].implementation, {
            onEnter: function(args) {
                var value = ObjC.Object(args[2]);
                var key = ObjC.Object(args[3]);
                console.log("\n[NSUserDefaults setObject] " + key + " = " + value);
            }
        });
        
        console.log("\n[*] 请在游戏中开启 GameForFun 的功能");
    }
}, 8000);
```

### 运行 Hook 脚本

#### 方式 1：Spawn 模式（重启游戏）

```bash
python -m frida_tools.repl -U -f <包名> -l hook_setvalue.js
```

**优点**：可以从游戏启动开始 hook
**缺点**：可能触发反调试，游戏闪退

#### 方式 2：Attach 模式（附加到运行中的游戏）- **推荐**

```bash
# 1. 先启动游戏
# 2. 查找进程 ID
python -m frida_tools.ps -U | findstr -i "游戏名"

# 3. 附加到进程
python -m frida_tools.repl -U <进程ID> -l hook_setvalue.js
```

**优点**：不会触发反调试，稳定
**缺点**：需要手动查找进程 ID

### 抓取步骤

1. 运行 hook 脚本
2. 等待 8 秒让 hook 生效
3. 在游戏中打开 GameForFun 菜单
4. **逐个开启功能**（重要！）
5. 记录控制台输出的 key、value、type

---

## 深度分析与问题排查

### 问题 1：捕获到的 key 是什么？

#### 情况 A：游戏真实的 key（推荐）

**示例**：
```
[setValue]
  key: marooned_gold_luobo_num
  value: 99999
  type: Number
```

**特征**：
- key 包含游戏名称或功能描述
- 可以直接用 NSUserDefaults 修改
- **可以制作独立 dylib**

**实现方式**：
```objective-c
static void setGameValue(NSString *key, id value, NSString *type) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([type isEqualToString:@"Number"]) {
        [defaults setInteger:[value integerValue] forKey:key];
    } else if ([type isEqualToString:@"bool"]) {
        [defaults setBool:[value boolValue] forKey:key];
    }
    [defaults synchronize];
}
```

#### 情况 B：GameForFun 内部 key（需要深度分析）

**示例**：
```
[setValue]
  key: hook_int
  value: 999999999
  type: undefined
```

**特征**：
- key 是通用名称（hook_int、hook_float 等）
- 不包含游戏特定信息
- **需要深度 hook 找到实际存储方式**

**解决方案**：使用深度 hook 脚本，查看 NSUserDefaults 的写入：

```
[NSUserDefaults setObject] hook_int = 999999999
[NSUserDefaults setObject] hook_float = 9e9
```

**关键发现**：GameForFun 直接将 `hook_int` 和 `hook_float` 写入 NSUserDefaults！

**实现方式**：
```objective-c
- (void)setValue:(id)value forKey:(NSString *)key withType:(NSString *)type {
    // 直接使用 NSUserDefaults 存储，key 就是 hook_int 或 hook_float
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}
```

### 问题 2：如何判断游戏的数据存储方式？

使用深度 hook 脚本，观察：

1. **NSUserDefaults 写入**：游戏使用 NSUserDefaults 存储
2. **文件操作**：游戏使用文件存储（需要 hook 文件 API）
3. **内存操作**：游戏数据在内存中（需要内存搜索）
4. **Unity PlayerPrefs**：Unity 游戏可能使用 PlayerPrefs

### 问题 3：type 参数是什么？

- `Number`：整数
- `bool`：布尔值
- `undefined` 或 `nil`：未指定类型，通常用 `setObject:forKey:`

---

## 制作独立 Dylib

### 项目结构

```
项目文件夹/
├── .github/workflows/
│   └── build-游戏名-dylib.yml
└── 游戏名Dylib/
    └── 游戏名Cheat.m
```

### 核心代码模板

#### 方式 1：游戏真实 key（如饥饿荒野）

```objective-c
// 游戏名修改器 - 游戏名Cheat.m
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 游戏数值修改

static void setGameValue(NSString *key, id value, NSString *type) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([type isEqualToString:@"Number"]) {
        [defaults setInteger:[value integerValue] forKey:key];
    } else if ([type isEqualToString:@"bool"]) {
        [defaults setBool:[value boolValue] forKey:key];
    } else {
        [defaults setObject:value forKey:key];
    }
    [defaults synchronize];
}

// 使用示例
setGameValue(@"marooned_gold_luobo_num", @99999, @"Number");
```

#### 方式 2：GameForFun 内部 key（如 Gear Defenders）

```objective-c
// 游戏名修改器 - 游戏名Cheat.m
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 实现 FanhanGGEngine（替代 GameForFun.dylib）

@interface FanhanGGEngine : NSObject
+ (instancetype)sharedInstance;
- (void)setValue:(id)value forKey:(NSString *)key withType:(NSString *)type;
@end

@implementation FanhanGGEngine

static FanhanGGEngine *_sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)setValue:(id)value forKey:(NSString *)key withType:(NSString *)type {
    // 直接使用 NSUserDefaults 存储，key 就是 hook_int 或 hook_float
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

@end

// 简化的接口函数
static void setGameValue(NSString *key, id value, NSString *type) {
    [[FanhanGGEngine sharedInstance] setValue:value forKey:key withType:type];
}

// 使用示例
setGameValue(@"hook_int", @999999999, nil);
setGameValue(@"hook_float", @9000000000, nil);
```

### UI 代码（悬浮按钮 + 菜单）

**推荐参考**：天选打工人 Dylib 的 UI 样式

**关键要点**：
1. 使用 `autoresizingMask` 自动适配横竖屏
2. 菜单居中显示，半透明背景
3. 右上角圆形关闭按钮
4. 统一的主题色和圆角样式
5. 免责声明使用可滚动的 TextView

```objective-c
#pragma mark - 菜单视图

@interface GameMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation GameMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        // 点击背景关闭
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
        [self addGestureRecognizer:tap];
        
        [self setupContentView];
    }
    return self;
}

- (void)setupContentView {
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 15;
    self.contentView.center = self.center;
    [self addSubview:self.contentView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 300, 30)];
    titleLabel.text = @"⚙️ 游戏修改器";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.contentView addSubview:titleLabel];
    
    // 功能开关
    CGFloat yOffset = 70;
    [self addSwitchWithTitle:@"💰 无限金币" tag:1 yOffset:yOffset];
    yOffset += 60;
    [self addSwitchWithTitle:@"🛡️ 无敌模式" tag:2 yOffset:yOffset];
    
    // 关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.frame = CGRectMake(100, 350, 100, 40);
    [closeButton setTitle:@"关闭" forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:closeButton];
}

- (void)addSwitchWithTitle:(NSString *)title tag:(NSInteger)tag yOffset:(CGFloat)yOffset {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 200, 30)];
    label.text = title;
    label.font = [UIFont systemFontOfSize:16];
    [self.contentView addSubview:label];
    
    UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(220, yOffset, 60, 30)];
    switchControl.tag = tag;
    [switchControl addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:switchControl];
}

- (void)switchChanged:(UISwitch *)sender {
    BOOL isOn = sender.isOn;
    
    switch (sender.tag) {
        case 1: // 无限金币
            if (isOn) {
                setGameValue(@"游戏的key", @999999, @"Number");
            }
            break;
        case 2: // 无敌模式
            if (isOn) {
                setGameValue(@"游戏的key", @YES, @"bool");
            }
            break;
    }
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.frame = window.bounds;
    [window addSubview:self];
}

- (void)hide {
    [self removeFromSuperview];
}

@end

#pragma mark - 悬浮按钮

static UIButton *g_floatButton = nil;
static GameMenuView *g_menuView = nil;

static void createFloatButton(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(window.bounds.size.width - 70, 100, 60, 60);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
        g_floatButton.layer.cornerRadius = 30;
        
        [g_floatButton setTitle:@"⚙️" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:30];
        
        [g_floatButton addTarget:g_floatButton action:@selector(buttonClicked) forControlEvents:UIControlEventTouchUpInside];
        
        // 添加拖动手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:g_floatButton action:@selector(handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [window addSubview:g_floatButton];
    });
}

@implementation UIButton (GameCheat)

- (void)buttonClicked {
    if (!g_menuView) {
        g_menuView = [[GameMenuView alloc] initWithFrame:CGRectZero];
    }
    [g_menuView show];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGRect bounds = self.superview.bounds;
        CGPoint center = self.center;
        
        // 自动吸附到边缘
        if (center.x < bounds.size.width / 2) {
            center.x = 40;
        } else {
            center.x = bounds.size.width - 40;
        }
        
        center.y = MAX(40, MIN(center.y, bounds.size.height - 40));
        
        [UIView animateWithDuration:0.3 animations:^{
            self.center = center;
        }];
    }
}

@end

#pragma mark - 初始化

__attribute__((constructor)) static void initialize(void) {
    NSLog(@"[GameCheat] 修改器已加载");
    
    // 延迟创建悬浮按钮
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        createFloatButton();
    });
}
```

### GitHub Actions 编译配置

`.github/workflows/build-游戏名-dylib.yml`：

```yaml
name: Build 游戏名 Dylib

on:
  push:
    paths:
      - '游戏名Dylib/**'
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Build dylib
      run: |
        cd 游戏名Dylib
        clang -arch arm64 \
          -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
          -miphoneos-version-min=14.0 \
          -dynamiclib \
          -framework UIKit \
          -framework Foundation \
          -framework CoreGraphics \
          -fobjc-arc \
          -Wno-deprecated-declarations \
          -o 游戏名Cheat.dylib \
          游戏名Cheat.m
        
        # 签名
        ldid -S 游戏名Cheat.dylib || codesign -f -s - 游戏名Cheat.dylib
    
    - name: Upload artifact
      uses: actions/upload-artifact@v4
      with:
        name: 游戏名Cheat-dylib
        path: 游戏名Dylib/游戏名Cheat.dylib
```

---

## 常见问题与解决方案

### 问题 1：Frida 附加失败

**错误信息**：
```
Failed to attach: unable to find process with pid XXXX
```

**原因**：游戏进程已结束或 PID 变化

**解决方案**：
1. 重新查找进程 ID：`python -m frida_tools.ps -U | findstr -i "游戏名"`
2. 使用进程名而不是 PID：`python -m frida_tools.repl -U "游戏名" -l hook.js`

### 问题 2：游戏有反调试

**错误信息**：
```
Process terminated
```

**原因**：游戏检测到调试器并退出

**解决方案**：
1. 使用 Attach 模式而不是 Spawn 模式
2. 游戏启动后再附加 Frida
3. 使用反反调试工具（如 Liberty Lite）

### 问题 3：ObjC 运行时不可用

**错误信息**：
```
ReferenceError: 'ObjC' is not defined
```

**原因**：ObjC 运行时还未加载

**解决方案**：
在脚本中添加等待逻辑：

```javascript
function waitForObjC() {
    if (typeof ObjC === 'undefined' || !ObjC.available) {
        setTimeout(waitForObjC, 500);
        return;
    }
    console.log("[+] ObjC 已加载");
    startHooking();
}

setTimeout(waitForObjC, 1000);
```

### 问题 4：捕获到的 key 是通用名称

**示例**：`hook_int`、`hook_float`

**解决方案**：
1. 使用深度 hook 脚本
2. 监控 NSUserDefaults 的写入
3. 查看 GameForFun 实际写入的 key
4. 在 dylib 中实现 `FanhanGGEngine` 类

### 问题 5：dylib 功能不生效

**可能原因**：
1. key 不正确
2. 数据存储方式不是 NSUserDefaults
3. 游戏读取数据的时机不对
4. 游戏需要触发特定事件才读取数值

**排查步骤**：

#### 步骤 1：验证 NSUserDefaults 是否写入成功

使用 Frida 验证：

```javascript
var NSUserDefaults = ObjC.classes.NSUserDefaults;
var defaults = NSUserDefaults.standardUserDefaults();

// 读取我们写入的值
var hook_int = defaults.objectForKey_("hook_int");
var hook_float = defaults.objectForKey_("hook_float");

console.log("hook_int = " + hook_int);
console.log("hook_float = " + hook_float);
```

#### 步骤 2：监控游戏何时读取 NSUserDefaults

```javascript
var NSUserDefaults = ObjC.classes.NSUserDefaults;

Interceptor.attach(NSUserDefaults['- objectForKey:'].implementation, {
    onEnter: function(args) {
        var key = ObjC.Object(args[2]);
        if (key.toString().indexOf("hook") !== -1) {
            console.log("[NSUserDefaults READ] " + key);
            console.log("调用栈:");
            console.log(Thread.backtrace(this.context, Backtracer.ACCURATE)
                .map(DebugSymbol.fromAddress).join('\n'));
        }
    }
});
```

#### 步骤 3：检查游戏读取时机

**关键发现**：

GameForFun 开启后**立即生效**，说明游戏会**实时读取** NSUserDefaults。

但我们的 dylib 可能需要：
1. **触发特定事件**：进入商店、获得货币、开始战斗等
2. **重启游戏**：某些游戏只在启动时读取一次
3. **切换场景**：进入/退出某个界面

**解决方案**：

在提示中告知用户需要触发事件：

```objective-c
[self showAlert:@"💰 无限货币已开启！\n\n⚠️ 重要提示：\n1. 已写入 NSUserDefaults\n2. 进入商店或获得货币时生效\n3. 如不生效请查看日志\n\n日志: Documents/GameCheat_Log.txt"];
```

#### 步骤 4：对比 GameForFun 的实现

如果我们的 dylib 不生效，但 GameForFun 生效，说明：

1. **写入方式相同**：都是 `[defaults setObject:value forKey:@"hook_int"]`
2. **读取时机不同**：GameForFun 可能有额外的触发机制

**深度分析**：

使用 Frida hook GameForFun 的所有方法调用，找到它是如何触发游戏读取数值的：

```javascript
var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
var methods = FanhanGGEngine.$ownMethods;

methods.forEach(function(methodName) {
    try {
        var method = FanhanGGEngine[methodName];
        if (method && method.implementation) {
            Interceptor.attach(method.implementation, {
                onEnter: function(args) {
                    console.log("[FanhanGGEngine] " + methodName + " 被调用");
                }
            });
        }
    } catch(e) {}
});
```

#### 步骤 5：添加详细日志

在 dylib 中添加日志功能，记录每一步操作：

```objective-c
static void writeLog(NSString *message) {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logPath = [docPath stringByAppendingPathComponent:@"GameCheat_Log.txt"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSString *timestamp = [formatter stringFromDate:[NSDate date]];
    
    NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        [logMessage writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    NSLog(@"%@", message);
}
```

然后在每个关键步骤添加日志：

```objective-c
- (void)setValue:(id)value forKey:(NSString *)key withType:(NSString *)type {
    writeLog([NSString stringWithFormat:@"setValue 被调用: key=%@ value=%@ type=%@", key, value, type]);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
    
    writeLog([NSString stringWithFormat:@"✅ 已写入 NSUserDefaults: %@ = %@", key, value]);
    
    // 验证写入
    id readValue = [defaults objectForKey:key];
    writeLog([NSString stringWithFormat:@"验证读取: %@ = %@", key, readValue]);
}
```

通过日志可以确认：
- dylib 是否被加载
- setValue 是否被调用
- NSUserDefaults 是否写入成功
- 写入的值是否正确

---

## 实战案例

### 案例 1：饥饿荒野（游戏真实 key）

**捕获结果**：
```
[setValue]
  key: marooned_gold_luobo_num
  value: 99999
  type: Number
```

**实现方式**：
```objective-c
static void setGameValue(NSString *key, id value, NSString *type) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([type isEqualToString:@"Number"]) {
        [defaults setInteger:[value integerValue] forKey:key];
    }
    [defaults synchronize];
}

// 使用
setGameValue(@"marooned_gold_luobo_num", @99999, @"Number");
```

**特点**：
- ✅ 完全独立，不需要 GameForFun.dylib
- ✅ 实现简单
- ✅ 稳定可靠

### 案例 2：Gear Defenders（GameForFun 内部 key）

**初步捕获**：
```
[setValue]
  key: hook_int
  value: 999999999
  type: undefined
```

**深度分析**：
```
[NSUserDefaults setObject] hook_int = 999999999
[NSUserDefaults setObject] hook_float = 9e9
```

**关键发现**：GameForFun 直接将 `hook_int` 和 `hook_float` 写入 NSUserDefaults！

**实现方式**：
```objective-c
@interface FanhanGGEngine : NSObject
+ (instancetype)sharedInstance;
- (void)setValue:(id)value forKey:(NSString *)key withType:(NSString *)type;
@end

@implementation FanhanGGEngine

static FanhanGGEngine *_sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)setValue:(id)value forKey:(NSString *)key withType:(NSString *)type {
    // 直接使用 NSUserDefaults 存储
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];  // key 就是 hook_int 或 hook_float
    [defaults synchronize];
}

@end

// 使用
[[FanhanGGEngine sharedInstance] setValue:@999999999 forKey:@"hook_int" withType:nil];
[[FanhanGGEngine sharedInstance] setValue:@9000000000 forKey:@"hook_float" withType:nil];
```

**特点**：
- ✅ 完全独立，不需要 GameForFun.dylib
- ✅ 需要实现 `FanhanGGEngine` 类
- ✅ 通过深度 hook 找到实现方式

### 案例 3：Skullgirls（Unity 游戏，内存修改）

**捕获结果**：
```
[setValue]
  key: hook_int
  value: 999999999
  type: undefined
```

**深度分析**：
- 游戏是 Unity 游戏（找到 UnityFramework 模块）
- 不使用 NSUserDefaults 存储数据
- 需要内存修改或 hook Unity 函数

**实现方式**：
1. 和 GameForFun 一起注入使用
2. 或使用内存搜索和修改（复杂）

---

## 总结

### 判断流程图

```
捕获到 GameForFun 参数
    ↓
key 是什么？
    ↓
├─ 游戏真实 key（如 marooned_gold_luobo_num）
│   ↓
│   使用 NSUserDefaults 直接修改
│   ✅ 可以制作独立 dylib
│
└─ 通用 key（如 hook_int、hook_float）
    ↓
    使用深度 hook 查看 NSUserDefaults 写入
    ↓
    ├─ 有写入 hook_int/hook_float
    │   ↓
    │   实现 FanhanGGEngine 类
    │   ✅ 可以制作独立 dylib
    │
    └─ 没有写入
        ↓
        游戏使用其他存储方式
        ❌ 需要内存修改或 hook Unity 函数
        或和 GameForFun 一起注入
```

### 关键要点

1. **先用基础 hook 脚本**测试，看能否捕获到参数
2. **如果捕获到通用 key**（hook_int 等），使用深度 hook 脚本
3. **观察 NSUserDefaults 的写入**，这是关键！
4. **根据发现的存储方式**选择实现方案
5. **添加日志功能**，方便调试
6. **测试验证**，确保功能生效

### 推荐工具

- **Frida**：动态分析和 hook
- **Filza**：查看游戏文件和日志
- **GitHub Actions**：自动编译 dylib
- **IPAPatcher/Sideloadly**：注入 dylib
- **TrollStore**：安装修改后的 IPA

---

## 附录

### A. Frida 常用命令

```bash
# 列出所有进程
python -m frida_tools.ps -U

# 附加到进程（使用 PID）
python -m frida_tools.repl -U <PID> -l script.js

# 附加到进程（使用进程名）
python -m frida_tools.repl -U "进程名" -l script.js

# Spawn 模式（重启应用）
python -m frida_tools.repl -U -f <Bundle ID> -l script.js
```

### B. 文件路径处理

Windows 路径中有中文字符时，Frida 可能无法读取脚本文件。

**解决方案**：
1. 将脚本放在无中文路径（如 `C:\Users\Administrator\hook.js`）
2. 使用绝对路径

### C. 日志功能实现

```objective-c
static void writeLog(NSString *message) {
    NSLog(@"%@", message);
    
    @try {
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *logPath = [docPath stringByAppendingPathComponent:@"GameCheat_Log.txt"];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
        NSString *timestamp = [formatter stringFromDate:[NSDate date]];
        
        NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        } else {
            [logMessage writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    } @catch (NSException *exception) {
        NSLog(@"写入日志失败: %@", exception);
    }
}
```

日志文件位置：`/var/mobile/Containers/Data/Application/<UUID>/Documents/GameCheat_Log.txt`

可以通过 Filza 导出查看。

---

**教程完成！**

如有问题，请参考常见问题部分或查看实战案例。

祝你成功制作出自己的游戏修改器！🎮
