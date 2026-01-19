// 游戏分析器 + 修改器 - 既能分析又能修改
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 日志系统
static void gameLog(NSString *message) {
    NSLog(@"[GameAnalyzer] %@", message);
}

// 全局变量
static NSInteger g_analysisCount = 0;
static NSMutableDictionary *g_gameData = nil;
static BOOL g_modificationEnabled = NO;

// 原始方法指针
static void (*original_setInteger)(id self, SEL _cmd, NSInteger value, NSString *key);
static NSInteger (*original_integerForKey)(id self, SEL _cmd, NSString *key);

// Hook setInteger - 分析和修改
static void analyzer_setInteger(id self, SEL _cmd, NSInteger value, NSString *key) {
    // 分析阶段 - 记录所有游戏数据操作
    if (key && key.length > 0) {
        g_analysisCount++;
        
        // 记录重要的游戏数据
        if ([key containsString:@"cash"] || [key containsString:@"money"] || 
            [key containsString:@"现金"] || [key containsString:@"金钱"] || 
            [key containsString:@"体力"] || [key containsString:@"energy"] ||
            [key containsString:@"健康"] || [key containsString:@"心情"] ||
            [key containsString:@"饥饿"] || [key containsString:@"thirst"] ||
            value > 10000) {
            
            gameLog([NSString stringWithFormat:@"🔍 [游戏数据] %@ = %ld", key, (long)value]);
            g_gameData[key] = @(value);
            
            // 如果是修改模式，直接修改为大数值
            if (g_modificationEnabled) {
                if ([key containsString:@"cash"] || [key containsString:@"money"] || [key containsString:@"现金"] || [key containsString:@"金钱"]) {
                    value = 999999999; // 修改金钱
                    gameLog([NSString stringWithFormat:@"💰 [修改金钱] %@ -> %ld", key, (long)value]);
                } else if ([key containsString:@"体力"] || [key containsString:@"energy"]) {
                    value = 100; // 修改体力
                    gameLog([NSString stringWithFormat:@"⚡ [修改体力] %@ -> %ld", key, (long)value]);
                } else if ([key containsString:@"健康"] || [key containsString:@"health"]) {
                    value = 100; // 修改健康
                    gameLog([NSString stringWithFormat:@"❤️ [修改健康] %@ -> %ld", key, (long)value]);
                } else if ([key containsString:@"心情"] || [key containsString:@"mood"]) {
                    value = 100; // 修改心情
                    gameLog([NSString stringWithFormat:@"😊 [修改心情] %@ -> %ld", key, (long)value]);
                }
            }
        }
    }
    
    // 调用原始方法
    original_setInteger(self, _cmd, value, key);
}

// Hook integerForKey - 分析读取操作
static NSInteger analyzer_integerForKey(id self, SEL _cmd, NSString *key) {
    NSInteger result = original_integerForKey(self, _cmd, key);
    
    // 记录重要数据的读取
    if (key && key.length > 0 && result > 0) {
        if ([key containsString:@"cash"] || [key containsString:@"money"] || 
            [key containsString:@"现金"] || [key containsString:@"金钱"] || 
            [key containsString:@"体力"] || [key containsString:@"energy"] ||
            [key containsString:@"健康"] || [key containsString:@"心情"] ||
            result > 10000) {
            
            gameLog([NSString stringWithFormat:@"📖 [读取数据] %@ = %ld", key, (long)result]);
            g_gameData[key] = @(result);
        }
    }
    
    return result;
}

// 启用修改模式
static void enableModificationMode(void) {
    g_modificationEnabled = YES;
    gameLog(@"🚀 修改模式已启用！");
    gameLog(@"💡 现在所有重要数值都会被自动修改");
    
    // 输出已发现的游戏数据
    gameLog(@"📊 已发现的游戏数据:");
    for (NSString *key in g_gameData) {
        NSNumber *value = g_gameData[key];
        gameLog([NSString stringWithFormat:@"   %@ = %@", key, value]);
    }
}

// 手动修改存档数据
static void modifyGameSaveData(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    gameLog(@"🔧 开始手动修改存档数据...");
    
    // 基于之前的分析，尝试修改常见的游戏数据键
    NSArray *moneyKeys = @[@"cash", @"money", @"现金", @"金钱", @"Money", @"Cash"];
    NSArray *energyKeys = @[@"energy", @"体力", @"Energy", @"stamina"];
    NSArray *healthKeys = @[@"health", @"健康", @"Health", @"hp"];
    NSArray *moodKeys = @[@"mood", @"心情", @"Mood", @"happiness"];
    
    // 修改金钱
    for (NSString *key in moneyKeys) {
        [defaults setInteger:999999999 forKey:key];
        gameLog([NSString stringWithFormat:@"💰 设置 %@ = 999999999", key]);
    }
    
    // 修改体力
    for (NSString *key in energyKeys) {
        [defaults setInteger:100 forKey:key];
        gameLog([NSString stringWithFormat:@"⚡ 设置 %@ = 100", key]);
    }
    
    // 修改健康
    for (NSString *key in healthKeys) {
        [defaults setInteger:100 forKey:key];
        gameLog([NSString stringWithFormat:@"❤️ 设置 %@ = 100", key]);
    }
    
    // 修改心情
    for (NSString *key in moodKeys) {
        [defaults setInteger:100 forKey:key];
        gameLog([NSString stringWithFormat:@"😊 设置 %@ = 100", key]);
    }
    
    [defaults synchronize];
    gameLog(@"✅ 存档数据修改完成！");
}

// 安装Hook
static void installAnalyzerHooks(void) {
    @try {
        Class cls = [NSUserDefaults class];
        
        // Hook setInteger:forKey:
        Method setMethod = class_getInstanceMethod(cls, @selector(setInteger:forKey:));
        if (setMethod) {
            original_setInteger = (void (*)(id, SEL, NSInteger, NSString *))method_getImplementation(setMethod);
            method_setImplementation(setMethod, (IMP)analyzer_setInteger);
            gameLog(@"✅ setInteger Hook安装成功");
        }
        
        // Hook integerForKey:
        Method getMethod = class_getInstanceMethod(cls, @selector(integerForKey:));
        if (getMethod) {
            original_integerForKey = (NSInteger (*)(id, SEL, NSString *))method_getImplementation(getMethod);
            method_setImplementation(getMethod, (IMP)analyzer_integerForKey);
            gameLog(@"✅ integerForKey Hook安装成功");
        }
        
        gameLog(@"🎉 游戏分析器Hook安装完成");
        
    } @catch (NSException *e) {
        gameLog([NSString stringWithFormat:@"❌ Hook安装异常: %@", e.reason]);
    }
}

// 定时任务
static void startPeriodicTasks(void) {
    // 30秒后启用修改模式
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        enableModificationMode();
    });
    
    // 60秒后执行手动修改
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        modifyGameSaveData();
    });
    
    // 每2分钟报告一次状态
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            sleep(120);
            gameLog([NSString stringWithFormat:@"📊 [状态报告] 已分析 %ld 次操作，发现 %lu 个游戏数据", 
                (long)g_analysisCount, (unsigned long)g_gameData.count]);
        }
    });
}

// 构造函数
__attribute__((constructor))
static void GameAnalyzerInit(void) {
    @autoreleasepool {
        gameLog(@"🎮 游戏分析器 + 修改器启动");
        
        // 初始化
        g_gameData = [[NSMutableDictionary alloc] init];
        g_analysisCount = 0;
        g_modificationEnabled = NO;
        
        // 10秒后安装Hook
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            installAnalyzerHooks();
            startPeriodicTasks();
            gameLog(@"🔍 分析模式启动，正在学习游戏数据结构...");
            gameLog(@"💡 30秒后将自动启用修改模式");
        });
    }
}