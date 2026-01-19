// 修改器窃取器 - 专门窃取其他作者修改器的功能
// 只负责监控、记录、学习，不做任何修改
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - 简化日志系统

// 简化日志 - 只用NSLog避免文件操作崩溃
static void stealerLog(NSString *message) {
    NSLog(@"[CheatStealer] %@", message);
}

#pragma mark - 简化窃取数据存储

static NSMutableDictionary *g_stolenValues = nil;
static NSInteger g_operationCount = 0;

// 简化初始化
static void initializeStealer(void) {
    g_stolenValues = [[NSMutableDictionary alloc] init];
    g_operationCount = 0;
    stealerLog(@"🕵️ 窃取器已初始化");
}

// 简化保存 - 只记录到NSLog
static void saveStolenData(void) {
    stealerLog([NSString stringWithFormat:@"💾 已捕获 %ld 个操作，%lu 个重要数值", 
        (long)g_operationCount, (unsigned long)g_stolenValues.count]);
    
    // 输出捕获的重要数值
    for (NSString *key in g_stolenValues) {
        id value = g_stolenValues[key];
        stealerLog([NSString stringWithFormat:@"   %@ = %@", key, value]);
    }
}

// 简化代码生成 - 只输出到NSLog
static void generateStolenCheatCode(void) {
    if (g_stolenValues.count == 0) return;
    
    stealerLog(@"🎉 生成窃取到的修改器代码:");
    stealerLog(@"// Objective-C版本:");
    stealerLog(@"NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];");
    
    for (NSString *key in g_stolenValues) {
        id value = g_stolenValues[key];
        if ([value isKindOfClass:[NSNumber class]]) {
            NSInteger intValue = [value integerValue];
            stealerLog([NSString stringWithFormat:@"[defaults setInteger:%ld forKey:@\"%@\"];", (long)intValue, key]);
        }
    }
    
    stealerLog(@"[defaults synchronize];");
    stealerLog(@"");
    stealerLog(@"// Frida版本:");
    stealerLog(@"var defaults = ObjC.classes.NSUserDefaults.standardUserDefaults();");
    
    for (NSString *key in g_stolenValues) {
        id value = g_stolenValues[key];
        if ([value isKindOfClass:[NSNumber class]]) {
            NSInteger intValue = [value integerValue];
            stealerLog([NSString stringWithFormat:@"defaults.setInteger_forKey_(%ld, '%@');", (long)intValue, key]);
        }
    }
    
    stealerLog(@"defaults.synchronize();");
}

#pragma mark - 简化Hook实现（只监控，不修改）

// 原始方法指针
static void (*original_setInteger)(id self, SEL _cmd, NSInteger value, NSString *key);

// 简化Hook setInteger（只监控重要操作）
static void stealer_setInteger(id self, SEL _cmd, NSInteger value, NSString *key) {
    // 只记录重要的大数值修改
    if (value > 100000 || value == 999999999 || value == 21000000000) {
        stealerLog([NSString stringWithFormat:@"🎯 [窃取重要修改] %@ = %ld", key, (long)value]);
        g_stolenValues[key] = @(value);
        g_operationCount++;
        
        // 如果捕获到足够数据，生成代码
        if (g_stolenValues.count >= 3) {
            generateStolenCheatCode();
        }
    }
    
    // 调用原始方法，让其他修改器正常工作
    original_setInteger(self, _cmd, value, key);
}

// 简化安装Hook - 只Hook最重要的setInteger
static void installStealerHooks(void) {
    @try {
        Class nsUserDefaultsClass = [NSUserDefaults class];
        
        // 只Hook setInteger:forKey: - 最重要的修改方法
        Method setIntegerMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(setInteger:forKey:));
        if (setIntegerMethod) {
            original_setInteger = (void (*)(id, SEL, NSInteger, NSString *))method_getImplementation(setIntegerMethod);
            method_setImplementation(setIntegerMethod, (IMP)stealer_setInteger);
            stealerLog(@"✅ 已安装 setInteger:forKey 窃取Hook");
        }
        
        stealerLog(@"🎉 窃取Hook安装完成，开始监控其他修改器");
        
    } @catch (NSException *exception) {
        stealerLog([NSString stringWithFormat:@"❌ 窃取Hook安装失败: %@", exception.reason]);
    }
}

#pragma mark - 构造函数

__attribute__((constructor))
static void CheatStealerInit(void) {
    @autoreleasepool {
        @try {
            stealerLog(@"🕵️ 简化窃取器开始加载...");
            
            // 初始化窃取器
            initializeStealer();
            
            // 延迟安装Hook - 更长延迟避免崩溃
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @try {
                    installStealerHooks();
                    stealerLog(@"✅ 简化窃取器已启动，监控setInteger操作");
                    
                } @catch (NSException *exception) {
                    stealerLog([NSString stringWithFormat:@"❌ 窃取器启动失败: %@", exception.reason]);
                }
            });
            
        } @catch (NSException *exception) {
            NSLog(@"[CheatStealer] 构造函数异常: %@", exception.reason);
        }
    }
}