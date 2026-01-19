// 我独自生活修改器 - 安全版本
// 专门解决注入后闪退问题
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

#pragma mark - 安全日志系统

// 安全的日志写入
static void safeWriteLog(NSString *message) {
    @try {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths firstObject];
        NSString *logPath = [documentsPath stringByAppendingPathComponent:@"safe_cheat.log"];
        
        NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date] 
            dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
        NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        } else {
            [logMessage writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        
        NSLog(@"[SafeCheat] %@", message);
    } @catch (NSException *exception) {
        NSLog(@"[SafeCheat] 日志异常: %@", exception.reason);
    }
}

#pragma mark - 全局变量

static BOOL g_safeMode = YES;
static BOOL g_initialized = NO;
static NSTimer *g_delayTimer = nil;

#pragma mark - 安全的修改功能

// 安全的数值修改
static void safeModifyValues(void) {
    @try {
        safeWriteLog(@"🚀 开始安全修改数值...");
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // 修改常见的数值字段
        NSArray *cashKeys = @[@"cash", @"money", @"现金", @"金钱", @"coin", @"coins"];
        NSArray *energyKeys = @[@"energy", @"stamina", @"体力", @"power"];
        NSArray *healthKeys = @[@"health", @"hp", @"健康", @"life"];
        NSArray *moodKeys = @[@"mood", @"happiness", @"心情", @"spirit"];
        
        // 修改现金
        for (NSString *key in cashKeys) {
            [defaults setInteger:21000000000 forKey:key];
        }
        
        // 修改体力
        for (NSString *key in energyKeys) {
            [defaults setInteger:21000000000 forKey:key];
        }
        
        // 修改健康
        for (NSString *key in healthKeys) {
            [defaults setInteger:1000000 forKey:key];
        }
        
        // 修改心情
        for (NSString *key in moodKeys) {
            [defaults setInteger:1000000 forKey:key];
        }
        
        [defaults synchronize];
        safeWriteLog(@"✅ 安全修改完成");
        
    } @catch (NSException *exception) {
        safeWriteLog([NSString stringWithFormat:@"❌ 修改异常: %@", exception.reason]);
    }
}

// 显示安全提示
static void showSafeAlert(void) {
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🛡️ 安全修改器" 
                message:@"修改器已安全启动\n\n已修改：\n💰 现金 = 210亿\n⚡ 体力 = 210亿\n❤️ 健康 = 100万\n😊 心情 = 100万\n\n请进行一次游戏操作来刷新数值" 
                preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            
            UIViewController *rootVC = nil;
            for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    rootVC = window.rootViewController;
                    break;
                }
            }
            
            if (!rootVC) {
                rootVC = [UIApplication sharedApplication].windows.firstObject.rootViewController;
            }
            
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            
            if (rootVC) {
                [rootVC presentViewController:alert animated:YES completion:nil];
            }
        });
    } @catch (NSException *exception) {
        safeWriteLog([NSString stringWithFormat:@"❌ 提示异常: %@", exception.reason]);
    }
}

#pragma mark - 延迟初始化

// 延迟执行修改
static void delayedExecution(void) {
    @try {
        safeWriteLog(@"⏰ 开始延迟执行...");
        
        // 等待应用完全启动
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @try {
                safeModifyValues();
                
                // 再延迟5秒显示提示
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    showSafeAlert();
                });
                
            } @catch (NSException *exception) {
                safeWriteLog([NSString stringWithFormat:@"❌ 延迟执行异常: %@", exception.reason]);
            }
        });
        
    } @catch (NSException *exception) {
        safeWriteLog([NSString stringWithFormat:@"❌ 延迟初始化异常: %@", exception.reason]);
    }
}

#pragma mark - 应用生命周期监听

// 监听应用状态
static void setupAppStateMonitoring(void) {
    @try {
        // 监听应用变为活跃状态
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification 
            object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            
            if (!g_initialized) {
                g_initialized = YES;
                safeWriteLog(@"📱 应用已激活，开始安全初始化");
                delayedExecution();
            }
        }];
        
        safeWriteLog(@"✅ 应用状态监听已设置");
        
    } @catch (NSException *exception) {
        safeWriteLog([NSString stringWithFormat:@"❌ 状态监听设置失败: %@", exception.reason]);
    }
}

#pragma mark - 最小化Hook（避免闪退）

// 原始方法指针
static NSInteger (*original_integerForKey)(id self, SEL _cmd, NSString *key);

// 最小化的Hook实现
static NSInteger safe_integerForKey(id self, SEL _cmd, NSString *key) {
    @try {
        NSInteger originalValue = original_integerForKey(self, _cmd, key);
        
        // 只在安全模式下进行最小化的修改
        if (g_safeMode && key && key.length > 0) {
            NSString *lowerKey = [key lowercaseString];
            
            // 只修改明确的游戏数值字段
            if ([lowerKey isEqualToString:@"cash"] || [lowerKey isEqualToString:@"money"] || 
                [lowerKey isEqualToString:@"现金"] || [lowerKey isEqualToString:@"金钱"]) {
                if (originalValue > 0 && originalValue < 100000000000) {
                    return 21000000000;
                }
            }
            
            if ([lowerKey isEqualToString:@"energy"] || [lowerKey isEqualToString:@"stamina"] || 
                [lowerKey isEqualToString:@"体力"]) {
                if (originalValue > 0 && originalValue < 100000000) {
                    return 21000000000;
                }
            }
        }
        
        return originalValue;
    } @catch (NSException *exception) {
        // 发生异常时返回原始值，避免崩溃
        return original_integerForKey(self, _cmd, key);
    }
}

// 安全的Hook安装
static void installSafeHooks(void) {
    @try {
        Class nsUserDefaultsClass = [NSUserDefaults class];
        
        // 只Hook最关键的方法
        Method integerMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(integerForKey:));
        if (integerMethod) {
            original_integerForKey = (NSInteger (*)(id, SEL, NSString *))method_getImplementation(integerMethod);
            method_setImplementation(integerMethod, (IMP)safe_integerForKey);
            safeWriteLog(@"✅ 安全Hook已安装");
        }
        
    } @catch (NSException *exception) {
        safeWriteLog([NSString stringWithFormat:@"❌ Hook安装失败: %@", exception.reason]);
    }
}

#pragma mark - 构造函数

__attribute__((constructor))
static void SafeCheatInit(void) {
    @autoreleasepool {
        @try {
            safeWriteLog(@"🛡️ 安全修改器开始加载...");
            safeWriteLog(@"💡 使用最小化Hook，避免闪退");
            
            // 设置应用状态监听
            setupAppStateMonitoring();
            
            // 延迟安装Hook，避免过早Hook导致闪退
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @try {
                    installSafeHooks();
                    safeWriteLog(@"✅ 安全修改器加载完成");
                } @catch (NSException *exception) {
                    safeWriteLog([NSString stringWithFormat:@"❌ Hook安装异常: %@", exception.reason]);
                }
            });
            
        } @catch (NSException *exception) {
            NSLog(@"[SafeCheat] 构造函数异常: %@", exception.reason);
        }
    }
}