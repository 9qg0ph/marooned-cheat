// 我独自生活修改器 - 安全版本
// 避免闪退，延迟初始化，安全Hook
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

#pragma mark - 日志系统

// 获取日志路径
static NSString* getLogPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"woduzishenghua_safe.log"];
}

// 安全的日志写入
static void writeLog(NSString *message) {
    @try {
        NSString *logPath = getLogPath();
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
        
        NSLog(@"[WDZ-Safe] %@", message);
    } @catch (NSException *exception) {
        NSLog(@"[WDZ-Safe] 日志写入失败: %@", exception.reason);
    }
}

#pragma mark - 安全的Hook实现

// 全局开关
static BOOL g_hookEnabled = NO;
static BOOL g_initialized = NO;

// Hook NSUserDefaults的integerForKey方法
static NSInteger (*original_integerForKey)(id self, SEL _cmd, NSString *key);
static NSInteger hooked_integerForKey(id self, SEL _cmd, NSString *key) {
    @try {
        NSInteger originalValue = original_integerForKey(self, _cmd, key);
        
        if (!g_hookEnabled) return originalValue;
        
        // 检查是否是我们要修改的字段
        NSString *lowerKey = [key lowercaseString];
        
        if ([lowerKey containsString:@"cash"] || [lowerKey containsString:@"money"] || 
            [lowerKey containsString:@"现金"] || [lowerKey containsString:@"金钱"] || 
            [lowerKey containsString:@"coin"]) {
            if (originalValue > 1000 && originalValue < 100000000000) {
                writeLog([NSString stringWithFormat:@"🎯 Hook现金字段: %@ (原值: %ld → 新值: 21000000000)", key, (long)originalValue]);
                return 21000000000;
            }
        }
        
        if ([lowerKey containsString:@"energy"] || [lowerKey containsString:@"stamina"] || 
            [lowerKey containsString:@"体力"] || [lowerKey containsString:@"power"]) {
            if (originalValue > 10 && originalValue < 100000000) {
                writeLog([NSString stringWithFormat:@"🎯 Hook体力字段: %@ (原值: %ld → 新值: 21000000000)", key, (long)originalValue]);
                return 21000000000;
            }
        }
        
        return originalValue;
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ Hook异常: %@", exception.reason]);
        return original_integerForKey(self, _cmd, key);
    }
}

// Hook NSUserDefaults的objectForKey方法
static id (*original_objectForKey)(id self, SEL _cmd, NSString *key);
static id hooked_objectForKey(id self, SEL _cmd, NSString *key) {
    @try {
        id originalValue = original_objectForKey(self, _cmd, key);
        
        if (!g_hookEnabled || !originalValue) return originalValue;
        
        // 如果返回的是NSNumber，进行数值检查
        if ([originalValue isKindOfClass:[NSNumber class]]) {
            NSString *lowerKey = [key lowercaseString];
            NSInteger intValue = [originalValue integerValue];
            
            if ([lowerKey containsString:@"cash"] || [lowerKey containsString:@"money"] || 
                [lowerKey containsString:@"现金"] || [lowerKey containsString:@"金钱"] || 
                [lowerKey containsString:@"coin"]) {
                if (intValue > 1000 && intValue < 100000000000) {
                    writeLog([NSString stringWithFormat:@"🎯 Hook现金对象: %@ (原值: %@ → 新值: 21000000000)", key, originalValue]);
                    return @21000000000;
                }
            }
            
            if ([lowerKey containsString:@"energy"] || [lowerKey containsString:@"stamina"] || 
                [lowerKey containsString:@"体力"] || [lowerKey containsString:@"power"]) {
                if (intValue > 10 && intValue < 100000000) {
                    writeLog([NSString stringWithFormat:@"🎯 Hook体力对象: %@ (原值: %@ → 新值: 21000000000)", key, originalValue]);
                    return @21000000000;
                }
            }
        }
        
        return originalValue;
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ Hook异常: %@", exception.reason]);
        return original_objectForKey(self, _cmd, key);
    }
}

#pragma mark - 安全的初始化

// 安全的Hook安装
static void installHooksSafely(void) {
    @try {
        Class nsUserDefaultsClass = [NSUserDefaults class];
        
        // Hook integerForKey:
        Method integerMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(integerForKey:));
        if (integerMethod) {
            original_integerForKey = (NSInteger (*)(id, SEL, NSString *))method_getImplementation(integerMethod);
            method_setImplementation(integerMethod, (IMP)hooked_integerForKey);
            writeLog(@"✅ 已安装 integerForKey Hook");
        }
        
        // Hook objectForKey:
        Method objectMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(objectForKey:));
        if (objectMethod) {
            original_objectForKey = (id (*)(id, SEL, NSString *))method_getImplementation(objectMethod);
            method_setImplementation(objectMethod, (IMP)hooked_objectForKey);
            writeLog(@"✅ 已安装 objectForKey Hook");
        }
        
        g_hookEnabled = YES;
        writeLog(@"🎉 Hook安装完成，修改器已激活");
        
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ Hook安装失败: %@", exception.reason]);
    }
}

// 延迟初始化
static void delayedInitialization(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            if (!g_initialized) {
                writeLog(@"🚀 开始延迟初始化...");
                installHooksSafely();
                g_initialized = YES;
                writeLog(@"✅ 延迟初始化完成");
            }
        } @catch (NSException *exception) {
            writeLog([NSString stringWithFormat:@"❌ 延迟初始化失败: %@", exception.reason]);
        }
    });
}

#pragma mark - ES3存档修改（安全版本）

// 安全的ES3存档修改
static void modifyES3SaveDataSafely(void) {
    @try {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        writeLog(@"========== 开始安全ES3存档修改 ==========");
        
        // 尝试修改 data1.es3 存档
        NSString *es3Data = [defaults objectForKey:@"data1.es3"];
        if (es3Data && es3Data.length > 1000) {
            writeLog(@"✅ 找到 data1.es3 存档数据");
            writeLog([NSString stringWithFormat:@"ES3存档长度: %lu", (unsigned long)es3Data.length]);
            
            // 简单的数值修改，不进行复杂的JSON解析
            [defaults setInteger:21000000000 forKey:@"现金"];
            [defaults setInteger:21000000000 forKey:@"金钱"];
            [defaults setInteger:21000000000 forKey:@"cash"];
            [defaults setInteger:21000000000 forKey:@"money"];
            [defaults setInteger:21000000000 forKey:@"体力"];
            [defaults setInteger:21000000000 forKey:@"energy"];
            
            [defaults synchronize];
            writeLog(@"🎉 ES3存档相关数值修改完成");
        }
        
        // 同时尝试 data0.es3
        es3Data = [defaults objectForKey:@"data0.es3"];
        if (es3Data && es3Data.length > 1000) {
            writeLog(@"✅ 找到 data0.es3 存档数据");
            // 同样的简单修改
            [defaults synchronize];
        }
        
        writeLog(@"========== ES3存档修改完成 ==========");
        
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ ES3存档修改失败: %@", exception.reason]);
    }
}

// 安全的修改功能
static void enableInfiniteCashSafely(void) {
    @try {
        writeLog(@"🎯 启用无限现金（安全模式）");
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // 修改常见的现金字段
        [defaults setInteger:21000000000 forKey:@"cash"];
        [defaults setInteger:21000000000 forKey:@"money"];
        [defaults setInteger:21000000000 forKey:@"现金"];
        [defaults setInteger:21000000000 forKey:@"金钱"];
        [defaults setInteger:21000000000 forKey:@"金币"];
        [defaults setInteger:21000000000 forKey:@"coin"];
        [defaults setInteger:21000000000 forKey:@"coins"];
        
        [defaults synchronize];
        
        // 尝试ES3存档修改
        modifyES3SaveDataSafely();
        
        writeLog(@"✅ 无限现金已启用（安全模式）");
        
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ 无限现金启用失败: %@", exception.reason]);
    }
}

#pragma mark - 构造函数

__attribute__((constructor))
static void WDZSafeCheatInit(void) {
    @try {
        writeLog(@"🚀 我独自生活修改器（安全版本）开始加载...");
        
        // 不在构造函数中进行复杂操作，只做基本初始化
        writeLog(@"💡 使用安全模式，延迟5秒后初始化Hook");
        
        // 延迟初始化，避免过早Hook导致闪退
        delayedInitialization();
        
        // 延迟10秒后尝试修改数值
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            enableInfiniteCashSafely();
        });
        
        writeLog(@"✅ 安全版本修改器加载完成");
        
    } @catch (NSException *exception) {
        NSLog(@"[WDZ-Safe] 构造函数异常: %@", exception.reason);
    }
}