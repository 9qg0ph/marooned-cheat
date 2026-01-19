// 我独自生活修改器 - 集成版本
// 包含修改功能 + 窃取功能，一个dylib搞定所有
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

#pragma mark - 日志系统

// 获取日志路径
static NSString* getLogPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"woduzishenghua_integrated.log"];
}

// 写日志到文件
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
        
        NSLog(@"[WDZ-Integrated] %@", message);
    } @catch (NSException *exception) {
        NSLog(@"[WDZ-Integrated] 日志写入失败: %@", exception.reason);
    }
}

#pragma mark - 全局变量

// 修改器开关
static BOOL g_infiniteCashEnabled = NO;
static BOOL g_infiniteEnergyEnabled = NO;
static BOOL g_infiniteHealthEnabled = NO;
static BOOL g_infiniteMoodEnabled = NO;

// 窃取器开关和数据
static BOOL g_stealerEnabled = YES;
static NSMutableArray *g_stealerOperations = nil;
static NSMutableDictionary *g_stealerValues = nil;
static NSInteger g_stealerCount = 0;

// UI组件
@class WDZMenuView;
static UIButton *g_floatButton = nil;
static WDZMenuView *g_menuView = nil;

#pragma mark - 窃取器功能

// 初始化窃取器
static void initializeStealer(void) {
    g_stealerOperations = [[NSMutableArray alloc] init];
    g_stealerValues = [[NSMutableDictionary alloc] init];
    g_stealerCount = 0;
    writeLog(@"🕵️ 窃取器已初始化");
}

// 保存窃取的数据
static void saveStealerData(void) {
    @try {
        if (g_stealerCount == 0) return;
        
        NSDictionary *data = @{
            @"operations": g_stealerOperations ?: @[],
            @"values": g_stealerValues ?: @{},
            @"totalOperations": @(g_stealerCount),
            @"lastUpdate": [NSDate date]
        };
        
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
        
        if (!error && jsonData) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths firstObject];
            NSString *dataPath = [documentsPath stringByAppendingPathComponent:@"stealer_data.json"];
            [jsonData writeToFile:dataPath atomically:YES];
            
            writeLog([NSString stringWithFormat:@"💾 已保存 %ld 个窃取操作", (long)g_stealerCount]);
        }
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ 窃取数据保存失败: %@", exception.reason]);
    }
}

// 生成窃取到的修改器代码
static void generateStealerCode(void) {
    @try {
        if (g_stealerValues.count == 0) return;
        
        NSMutableString *code = [[NSMutableString alloc] init];
        [code appendString:@"// 窃取到的修改器代码\n"];
        [code appendString:@"static void executeStolenCheat(void) {\n"];
        [code appendString:@"    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];\n"];
        [code appendString:@"    writeLog(@\"🚀 执行窃取到的修改器...\");\n\n"];
        
        for (NSString *key in g_stealerValues) {
            id value = g_stealerValues[key];
            if ([value isKindOfClass:[NSNumber class]]) {
                NSInteger intValue = [value integerValue];
                [code appendFormat:@"    [defaults setInteger:%ld forKey:@\"%@\"];\n", (long)intValue, key];
                [code appendFormat:@"    writeLog(@\"✅ 窃取修改 %@ = %ld\");\n", key, (long)intValue];
            }
        }
        
        [code appendString:@"\n    [defaults synchronize];\n"];
        [code appendString:@"    writeLog(@\"🎉 窃取修改器执行完成！\");\n"];
        [code appendString:@"}"];
        
        // 保存代码
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths firstObject];
        NSString *codePath = [documentsPath stringByAppendingPathComponent:@"stolen_cheat.m"];
        [code writeToFile:codePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        writeLog(@"🎉 已生成窃取修改器代码");
        writeLog([NSString stringWithFormat:@"   文件路径: %@", codePath]);
        
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ 窃取代码生成失败: %@", exception.reason]);
    }
}

#pragma mark - Hook实现

// 原始方法指针
static NSInteger (*original_integerForKey)(id self, SEL _cmd, NSString *key);
static id (*original_objectForKey)(id self, SEL _cmd, NSString *key);
static void (*original_setInteger)(id self, SEL _cmd, NSInteger value, NSString *key);
static void (*original_setObject)(id self, SEL _cmd, id value, NSString *key);

// Hook NSUserDefaults的integerForKey方法
static NSInteger hooked_integerForKey(id self, SEL _cmd, NSString *key) {
    NSInteger originalValue = original_integerForKey(self, _cmd, key);
    
    @try {
        // 窃取器记录
        if (g_stealerEnabled && key && key.length > 0) {
            NSDictionary *operation = @{
                @"type": @"integerForKey",
                @"key": key,
                @"value": @(originalValue),
                @"timestamp": @([[NSDate date] timeIntervalSince1970])
            };
            [g_stealerOperations addObject:operation];
            g_stealerCount++;
            
            // 记录重要数值
            if (originalValue > 100000 || [key containsString:@"cash"] || [key containsString:@"money"] || 
                [key containsString:@"现金"] || [key containsString:@"金钱"] || [key containsString:@"体力"] || 
                [key containsString:@"energy"]) {
                writeLog([NSString stringWithFormat:@"🕵️ [窃取读取] %@ = %ld", key, (long)originalValue]);
                g_stealerValues[key] = @(originalValue);
            }
        }
        
        // 修改器功能
        NSString *lowerKey = [key lowercaseString];
        
        if (g_infiniteCashEnabled && ([lowerKey containsString:@"cash"] || [lowerKey containsString:@"money"] || 
            [lowerKey containsString:@"现金"] || [lowerKey containsString:@"金钱"] || [lowerKey containsString:@"coin"])) {
            writeLog([NSString stringWithFormat:@"🎯 Hook拦截现金字段: %@ (原值: %ld → 新值: 21000000000)", key, (long)originalValue]);
            return 21000000000;
        }
        
        if (g_infiniteEnergyEnabled && ([lowerKey containsString:@"energy"] || [lowerKey containsString:@"stamina"] || 
            [lowerKey containsString:@"体力"] || [lowerKey containsString:@"power"])) {
            writeLog([NSString stringWithFormat:@"🎯 Hook拦截体力字段: %@ (原值: %ld → 新值: 21000000000)", key, (long)originalValue]);
            return 21000000000;
        }
        
        if (g_infiniteHealthEnabled && ([lowerKey containsString:@"health"] || [lowerKey containsString:@"hp"] || 
            [lowerKey containsString:@"健康"] || [lowerKey containsString:@"life"])) {
            writeLog([NSString stringWithFormat:@"🎯 Hook拦截健康字段: %@ (原值: %ld → 新值: 1000000)", key, (long)originalValue]);
            return 1000000;
        }
        
        if (g_infiniteMoodEnabled && ([lowerKey containsString:@"mood"] || [lowerKey containsString:@"happiness"] || 
            [lowerKey containsString:@"心情"] || [lowerKey containsString:@"spirit"])) {
            writeLog([NSString stringWithFormat:@"🎯 Hook拦截心情字段: %@ (原值: %ld → 新值: 1000000)", key, (long)originalValue]);
            return 1000000;
        }
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ Hook异常: %@", exception.reason]);
    }
    
    return originalValue;
}

// Hook NSUserDefaults的setInteger:forKey方法
static void hooked_setInteger(id self, SEL _cmd, NSInteger value, NSString *key) {
    @try {
        // 窃取器记录
        if (g_stealerEnabled && key && key.length > 0) {
            NSDictionary *operation = @{
                @"type": @"setInteger",
                @"key": key,
                @"value": @(value),
                @"timestamp": @([[NSDate date] timeIntervalSince1970])
            };
            [g_stealerOperations addObject:operation];
            g_stealerCount++;
            
            // 重要修改操作
            if (value > 100000 || value == 999999999 || value == 21000000000) {
                writeLog([NSString stringWithFormat:@"🕵️ [窃取重要修改] setInteger: %@ = %ld", key, (long)value]);
                g_stealerValues[key] = @(value);
                
                // 立即保存重要数据
                saveStealerData();
                
                // 如果捕获到足够数据，生成代码
                if (g_stealerValues.count >= 3) {
                    generateStealerCode();
                }
            } else {
                writeLog([NSString stringWithFormat:@"🕵️ [窃取修改] setInteger: %@ = %ld", key, (long)value]);
            }
        }
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ Hook异常: %@", exception.reason]);
    }
    
    // 调用原始方法
    original_setInteger(self, _cmd, value, key);
}

// Hook NSUserDefaults的setObject:forKey方法
static void hooked_setObject(id self, SEL _cmd, id value, NSString *key) {
    @try {
        if (g_stealerEnabled && key && key.length > 0) {
            // 检查ES3存档修改
            if ([key.lowercaseString containsString:@"es3"]) {
                writeLog([NSString stringWithFormat:@"🕵️ [窃取ES3] %@", key]);
                
                NSDictionary *es3Op = @{
                    @"type": @"es3Write",
                    @"key": key,
                    @"dataLength": value && [value isKindOfClass:[NSString class]] ? @([(NSString*)value length]) : @0,
                    @"timestamp": @([[NSDate date] timeIntervalSince1970])
                };
                [g_stealerOperations addObject:es3Op];
                g_stealerCount++;
                
                // ES3操作立即保存
                saveStealerData();
            }
            
            // 检查数字对象
            if (value && [value respondsToSelector:@selector(integerValue)]) {
                NSInteger intValue = [value integerValue];
                if (intValue > 100000) {
                    writeLog([NSString stringWithFormat:@"🕵️ [窃取重要对象] setObject: %@ = %@", key, value]);
                    g_stealerValues[key] = value;
                    saveStealerData();
                }
            }
        }
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ Hook异常: %@", exception.reason]);
    }
    
    // 调用原始方法
    original_setObject(self, _cmd, value, key);
}

// 安装Hook
static void installHooks(void) {
    @try {
        Class nsUserDefaultsClass = [NSUserDefaults class];
        
        // Hook integerForKey:
        Method integerMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(integerForKey:));
        if (integerMethod) {
            original_integerForKey = (NSInteger (*)(id, SEL, NSString *))method_getImplementation(integerMethod);
            method_setImplementation(integerMethod, (IMP)hooked_integerForKey);
            writeLog(@"✅ 已安装 integerForKey Hook");
        }
        
        // Hook setInteger:forKey:
        Method setIntegerMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(setInteger:forKey:));
        if (setIntegerMethod) {
            original_setInteger = (void (*)(id, SEL, NSInteger, NSString *))method_getImplementation(setIntegerMethod);
            method_setImplementation(setIntegerMethod, (IMP)hooked_setInteger);
            writeLog(@"✅ 已安装 setInteger:forKey Hook");
        }
        
        // Hook setObject:forKey:
        Method setObjectMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(setObject:forKey:));
        if (setObjectMethod) {
            original_setObject = (void (*)(id, SEL, id, NSString *))method_getImplementation(setObjectMethod);
            method_setImplementation(setObjectMethod, (IMP)hooked_setObject);
            writeLog(@"✅ 已安装 setObject:forKey Hook");
        }
        
        writeLog(@"🎉 所有Hook安装完成，修改器+窃取器已启动");
        
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ Hook安装失败: %@", exception.reason]);
    }
}

#pragma mark - 修改器功能

// 无限现金功能
static void enableInfiniteCash(void) {
    g_infiniteCashEnabled = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:21000000000 forKey:@"cash"];
    [defaults setInteger:21000000000 forKey:@"money"];
    [defaults setInteger:21000000000 forKey:@"现金"];
    [defaults setInteger:21000000000 forKey:@"金钱"];
    [defaults synchronize];
    
    writeLog(@"💰 无限现金已开启");
}

// 无限体力功能
static void enableInfiniteEnergy(void) {
    g_infiniteEnergyEnabled = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:21000000000 forKey:@"energy"];
    [defaults setInteger:21000000000 forKey:@"stamina"];
    [defaults setInteger:21000000000 forKey:@"体力"];
    [defaults synchronize];
    
    writeLog(@"⚡ 无限体力已开启");
}

// 无限健康功能
static void enableInfiniteHealth(void) {
    g_infiniteHealthEnabled = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:1000000 forKey:@"health"];
    [defaults setInteger:1000000 forKey:@"hp"];
    [defaults setInteger:1000000 forKey:@"健康"];
    [defaults synchronize];
    
    writeLog(@"❤️ 无限健康已开启");
}

// 无限心情功能
static void enableInfiniteMood(void) {
    g_infiniteMoodEnabled = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:1000000 forKey:@"mood"];
    [defaults setInteger:1000000 forKey:@"happiness"];
    [defaults setInteger:1000000 forKey:@"心情"];
    [defaults synchronize];
    
    writeLog(@"😊 无限心情已开启");
}

// 一键全开功能
static void enableAllFeatures(void) {
    enableInfiniteCash();
    enableInfiniteEnergy();
    enableInfiniteHealth();
    enableInfiniteMood();
    writeLog(@"🎁 一键全开已启用");
}

#pragma mark - 简化UI

// 显示简单的修改器菜单
static void showSimpleMenu(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🏠 我独自生活修改器" 
        message:@"集成版本：修改器 + 窃取器\n\n窃取器正在后台自动运行\n捕获其他修改器操作并生成代码" 
        preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"💰 无限现金" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        enableInfiniteCash();
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"⚡ 无限体力" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        enableInfiniteEnergy();
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"❤️ 无限健康" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        enableInfiniteHealth();
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"😊 无限心情" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        enableInfiniteMood();
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"🎁 一键全开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        enableAllFeatures();
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"🕵️ 查看窃取状态" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *status = [NSString stringWithFormat:@"窃取器状态：%@\n已捕获操作：%ld 个\n重要数值：%lu 个\n\n日志文件：Documents/woduzishenghua_integrated.log\n数据文件：Documents/stealer_data.json\n生成代码：Documents/stolen_cheat.m", 
            g_stealerEnabled ? @"运行中" : @"已停止", (long)g_stealerCount, (unsigned long)g_stealerValues.count];
        
        UIAlertController *statusAlert = [UIAlertController alertControllerWithTitle:@"🕵️ 窃取器状态" message:status preferredStyle:UIAlertControllerStyleAlert];
        [statusAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        
        UIViewController *rootVC = [UIApplication sharedApplication].windows.firstObject.rootViewController;
        while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
        [rootVC presentViewController:statusAlert animated:YES completion:nil];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    UIViewController *rootVC = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

// 创建悬浮按钮
static void createFloatButton(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].windows.firstObject;
        if (!keyWindow) return;
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(20, 100, 50, 50);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        [g_floatButton setTitle:@"🏠" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:20];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(wdz_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        [keyWindow addSubview:g_floatButton];
    });
}

@implementation NSValue (WDZIntegrated)
+ (void)wdz_showMenu { showSimpleMenu(); }
@end

#pragma mark - 定期任务

// 定期保存和生成代码
static void startPeriodicTasks(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            @autoreleasepool {
                sleep(30); // 每30秒执行一次
                
                if (g_stealerCount > 0) {
                    saveStealerData();
                    
                    // 状态报告
                    writeLog([NSString stringWithFormat:@"📊 [状态] 已捕获 %ld 个操作，%lu 个重要数值", 
                        (long)g_stealerCount, (unsigned long)g_stealerValues.count]);
                    
                    // 如果捕获到足够数据，生成代码
                    if (g_stealerValues.count >= 3) {
                        generateStealerCode();
                    }
                }
            }
        }
    });
}

#pragma mark - 构造函数

__attribute__((constructor))
static void WDZIntegratedInit(void) {
    @autoreleasepool {
        @try {
            writeLog(@"🚀 我独自生活修改器（集成版）开始加载...");
            writeLog(@"💡 包含功能：修改器 + 窃取器，一个dylib搞定所有");
            
            // 初始化窃取器
            initializeStealer();
            
            // 延迟安装Hook
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @try {
                    installHooks();
                    
                    // 启动定期任务
                    startPeriodicTasks();
                    
                    writeLog(@"✅ 集成修改器已完全启动");
                    writeLog(@"🕵️ 窃取器正在后台监控其他修改器");
                    writeLog(@"💡 现在可以操作其他修改器，所有操作将被自动记录");
                    
                } @catch (NSException *exception) {
                    writeLog([NSString stringWithFormat:@"❌ 集成修改器启动失败: %@", exception.reason]);
                }
            });
            
            // 延迟创建悬浮按钮
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    createFloatButton();
                } @catch (NSException *exception) {
                    writeLog([NSString stringWithFormat:@"❌ 悬浮按钮创建失败: %@", exception.reason]);
                }
            });
            
        } @catch (NSException *exception) {
            NSLog(@"[WDZ-Integrated] 构造函数异常: %@", exception.reason);
        }
    }
}