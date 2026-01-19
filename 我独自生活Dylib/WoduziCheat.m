// 修改器窃取器 - 专门窃取其他作者修改器的功能
// 只负责监控、记录、学习，不做任何修改
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 窃取器日志系统

// 窃取器日志
static void stealerLog(NSString *message) {
    @try {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths firstObject];
        NSString *logPath = [documentsPath stringByAppendingPathComponent:@"cheat_stealer.log"];
        
        NSString *timestamp = [[NSDateFormatter alloc] init];
        timestamp.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        NSString *timeStr = [timestamp stringFromDate:[NSDate date]];
        NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timeStr, message];
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        } else {
            [logMessage writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        
        NSLog(@"[CheatStealer] %@", message);
    } @catch (NSException *exception) {
        NSLog(@"[CheatStealer] 日志异常: %@", exception.reason);
    }
}

#pragma mark - 窃取数据存储

static NSMutableArray *g_stolenOperations = nil;
static NSMutableDictionary *g_stolenValues = nil;
static NSMutableArray *g_stolenMethods = nil;
static NSInteger g_operationCount = 0;

// 初始化窃取器
static void initializeStealer(void) {
    g_stolenOperations = [[NSMutableArray alloc] init];
    g_stolenValues = [[NSMutableDictionary alloc] init];
    g_stolenMethods = [[NSMutableArray alloc] init];
    g_operationCount = 0;
    stealerLog(@"🕵️ 窃取器已初始化");
}

// 保存窃取的数据
static void saveStolenData(void) {
    @try {
        NSDictionary *data = @{
            @"operations": g_stolenOperations ?: @[],
            @"values": g_stolenValues ?: @{},
            @"methods": g_stolenMethods ?: @[],
            @"totalOperations": @(g_operationCount),
            @"captureTime": [NSDate date]
        };
        
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
        
        if (!error && jsonData) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsPath = [paths firstObject];
            NSString *dataPath = [documentsPath stringByAppendingPathComponent:@"stolen_cheat_data.json"];
            [jsonData writeToFile:dataPath atomically:YES];
            
            stealerLog([NSString stringWithFormat:@"💾 已保存 %ld 个窃取操作到文件", (long)g_operationCount]);
        }
    } @catch (NSException *exception) {
        stealerLog([NSString stringWithFormat:@"❌ 数据保存失败: %@", exception.reason]);
    }
}

// 生成窃取到的修改器代码
static void generateStolenCheatCode(void) {
    @try {
        if (g_stolenValues.count == 0) return;
        
        NSMutableString *objcCode = [[NSMutableString alloc] init];
        NSMutableString *fridaCode = [[NSMutableString alloc] init];
        
        // 生成Objective-C版本
        [objcCode appendString:@"// 窃取到的修改器代码 - Objective-C版本\n"];
        [objcCode appendString:@"// 基于对其他修改器的完全分析生成\n\n"];
        [objcCode appendString:@"#import <Foundation/Foundation.h>\n\n"];
        [objcCode appendString:@"static void executeStolenCheat(void) {\n"];
        [objcCode appendString:@"    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];\n"];
        [objcCode appendString:@"    NSLog(@\"🚀 执行窃取到的修改器...\");\n\n"];
        
        for (NSString *key in g_stolenValues) {
            id value = g_stolenValues[key];
            if ([value isKindOfClass:[NSNumber class]]) {
                NSInteger intValue = [value integerValue];
                [objcCode appendFormat:@"    [defaults setInteger:%ld forKey:@\"%@\"];\n", (long)intValue, key];
                [objcCode appendFormat:@"    NSLog(@\"✅ 窃取修改 %@ = %ld\");\n", key, (long)intValue];
            }
        }
        
        [objcCode appendString:@"\n    [defaults synchronize];\n"];
        [objcCode appendString:@"    NSLog(@\"🎉 窃取修改器执行完成！\");\n"];
        [objcCode appendString:@"}\n\n"];
        [objcCode appendString:@"__attribute__((constructor))\n"];
        [objcCode appendString:@"static void StolenCheatInit(void) {\n"];
        [objcCode appendString:@"    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{\n"];
        [objcCode appendString:@"        executeStolenCheat();\n"];
        [objcCode appendString:@"    });\n"];
        [objcCode appendString:@"}"];
        
        // 生成Frida版本
        [fridaCode appendString:@"// 窃取到的修改器代码 - Frida版本\n"];
        [fridaCode appendString:@"// 基于对其他修改器的完全分析生成\n\n"];
        [fridaCode appendString:@"setTimeout(function() {\n"];
        [fridaCode appendString:@"    console.log('🚀 执行窃取到的修改器...');\n"];
        [fridaCode appendString:@"    \n"];
        [fridaCode appendString:@"    var NSUserDefaults = ObjC.classes.NSUserDefaults;\n"];
        [fridaCode appendString:@"    var defaults = NSUserDefaults.standardUserDefaults();\n\n"];
        
        for (NSString *key in g_stolenValues) {
            id value = g_stolenValues[key];
            if ([value isKindOfClass:[NSNumber class]]) {
                NSInteger intValue = [value integerValue];
                [fridaCode appendFormat:@"    defaults.setInteger_forKey_(%ld, '%@');\n", (long)intValue, key];
                [fridaCode appendFormat:@"    console.log('✅ 窃取修改 %@ = %ld');\n", key, (long)intValue];
            }
        }
        
        [fridaCode appendString:@"\n    defaults.synchronize();\n"];
        [fridaCode appendString:@"    console.log('🎉 窃取修改器执行完成！');\n"];
        [fridaCode appendString:@"}, 5000);"];
        
        // 保存生成的代码
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths firstObject];
        
        NSString *objcPath = [documentsPath stringByAppendingPathComponent:@"stolen_cheat.m"];
        NSString *fridaPath = [documentsPath stringByAppendingPathComponent:@"stolen_cheat.js"];
        
        [objcCode writeToFile:objcPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [fridaCode writeToFile:fridaPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        stealerLog(@"🎉 已生成窃取修改器代码:");
        stealerLog([NSString stringWithFormat:@"   Objective-C: %@", objcPath]);
        stealerLog([NSString stringWithFormat:@"   Frida: %@", fridaPath]);
        
    } @catch (NSException *exception) {
        stealerLog([NSString stringWithFormat:@"❌ 代码生成失败: %@", exception.reason]);
    }
}

#pragma mark - Hook实现（只监控，不修改）

// 原始方法指针
static NSInteger (*original_integerForKey)(id self, SEL _cmd, NSString *key);
static id (*original_objectForKey)(id self, SEL _cmd, NSString *key);
static void (*original_setInteger)(id self, SEL _cmd, NSInteger value, NSString *key);
static void (*original_setObject)(id self, SEL _cmd, id value, NSString *key);

// Hook integerForKey（只监控）
static NSInteger stealer_integerForKey(id self, SEL _cmd, NSString *key) {
    NSInteger result = original_integerForKey(self, _cmd, key);
    
    @try {
        if (key && key.length > 0) {
            // 记录读取操作
            NSDictionary *operation = @{
                @"type": @"integerForKey",
                @"key": key,
                @"value": @(result),
                @"timestamp": @([[NSDate date] timeIntervalSince1970])
            };
            [g_stolenOperations addObject:operation];
            g_operationCount++;
            
            // 记录重要数值
            if (result > 100000 || [key containsString:@"cash"] || [key containsString:@"money"] || 
                [key containsString:@"现金"] || [key containsString:@"金钱"] || [key containsString:@"体力"] || 
                [key containsString:@"energy"] || [key containsString:@"健康"] || [key containsString:@"心情"]) {
                stealerLog([NSString stringWithFormat:@"🕵️ [窃取读取] %@ = %ld", key, (long)result]);
                g_stolenValues[key] = @(result);
            }
        }
    } @catch (NSException *exception) {
        stealerLog([NSString stringWithFormat:@"❌ 读取监控异常: %@", exception.reason]);
    }
    
    return result; // 不修改，直接返回原值
}

// Hook setInteger（只监控）
static void stealer_setInteger(id self, SEL _cmd, NSInteger value, NSString *key) {
    @try {
        if (key && key.length > 0) {
            // 记录修改操作
            NSDictionary *operation = @{
                @"type": @"setInteger",
                @"key": key,
                @"value": @(value),
                @"timestamp": @([[NSDate date] timeIntervalSince1970])
            };
            [g_stolenOperations addObject:operation];
            g_operationCount++;
            
            // 重要修改操作
            if (value > 100000 || value == 999999999 || value == 21000000000) {
                stealerLog([NSString stringWithFormat:@"🎯 [窃取重要修改] setInteger: %@ = %ld", key, (long)value]);
                g_stolenValues[key] = @(value);
                
                // 立即保存重要数据
                saveStolenData();
                
                // 如果捕获到足够数据，生成代码
                if (g_stolenValues.count >= 3) {
                    generateStolenCheatCode();
                }
            } else {
                stealerLog([NSString stringWithFormat:@"🕵️ [窃取修改] setInteger: %@ = %ld", key, (long)value]);
            }
        }
    } @catch (NSException *exception) {
        stealerLog([NSString stringWithFormat:@"❌ 修改监控异常: %@", exception.reason]);
    }
    
    // 调用原始方法，让其他修改器正常工作
    original_setInteger(self, _cmd, value, key);
}

// Hook setObject（只监控）
static void stealer_setObject(id self, SEL _cmd, id value, NSString *key) {
    @try {
        if (key && key.length > 0) {
            // 检查ES3存档修改
            if ([key.lowercaseString containsString:@"es3"]) {
                stealerLog([NSString stringWithFormat:@"🕵️ [窃取ES3] %@", key]);
                
                NSDictionary *es3Op = @{
                    @"type": @"es3Write",
                    @"key": key,
                    @"dataLength": value && [value isKindOfClass:[NSString class]] ? @([(NSString*)value length]) : @0,
                    @"timestamp": @([[NSDate date] timeIntervalSince1970])
                };
                [g_stolenOperations addObject:es3Op];
                g_operationCount++;
                
                // ES3操作立即保存
                saveStolenData();
            }
            
            // 检查数字对象
            if (value && [value respondsToSelector:@selector(integerValue)]) {
                NSInteger intValue = [value integerValue];
                if (intValue > 100000) {
                    stealerLog([NSString stringWithFormat:@"🕵️ [窃取重要对象] setObject: %@ = %@", key, value]);
                    g_stolenValues[key] = value;
                    saveStolenData();
                }
            }
        }
    } @catch (NSException *exception) {
        stealerLog([NSString stringWithFormat:@"❌ 对象监控异常: %@", exception.reason]);
    }
    
    // 调用原始方法，让其他修改器正常工作
    original_setObject(self, _cmd, value, key);
}

// 安装窃取Hook
static void installStealerHooks(void) {
    @try {
        Class nsUserDefaultsClass = [NSUserDefaults class];
        
        // Hook integerForKey:
        Method integerMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(integerForKey:));
        if (integerMethod) {
            original_integerForKey = (NSInteger (*)(id, SEL, NSString *))method_getImplementation(integerMethod);
            method_setImplementation(integerMethod, (IMP)stealer_integerForKey);
            stealerLog(@"✅ 已安装 integerForKey 窃取Hook");
        }
        
        // Hook setInteger:forKey:
        Method setIntegerMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(setInteger:forKey:));
        if (setIntegerMethod) {
            original_setInteger = (void (*)(id, SEL, NSInteger, NSString *))method_getImplementation(setIntegerMethod);
            method_setImplementation(setIntegerMethod, (IMP)stealer_setInteger);
            stealerLog(@"✅ 已安装 setInteger:forKey 窃取Hook");
        }
        
        // Hook setObject:forKey:
        Method setObjectMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(setObject:forKey:));
        if (setObjectMethod) {
            original_setObject = (void (*)(id, SEL, id, NSString *))method_getImplementation(setObjectMethod);
            method_setImplementation(setObjectMethod, (IMP)stealer_setObject);
            stealerLog(@"✅ 已安装 setObject:forKey 窃取Hook");
        }
        
        stealerLog(@"🎉 所有窃取Hook安装完成，开始监控其他修改器");
        
    } @catch (NSException *exception) {
        stealerLog([NSString stringWithFormat:@"❌ 窃取Hook安装失败: %@", exception.reason]);
    }
}

#pragma mark - 定期任务

// 定期保存和生成代码
static void startPeriodicTasks(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            @autoreleasepool {
                sleep(30); // 每30秒执行一次
                
                if (g_operationCount > 0) {
                    saveStolenData();
                    
                    // 状态报告
                    stealerLog([NSString stringWithFormat:@"📊 [窃取状态] 已捕获 %ld 个操作，%lu 个重要数值", 
                        (long)g_operationCount, (unsigned long)g_stolenValues.count]);
                    
                    // 如果捕获到足够数据，生成代码
                    if (g_stolenValues.count >= 3) {
                        generateStolenCheatCode();
                    }
                }
            }
        }
    });
}

#pragma mark - 构造函数

__attribute__((constructor))
static void CheatStealerInit(void) {
    @autoreleasepool {
        @try {
            stealerLog(@"🕵️ 修改器窃取器开始加载...");
            stealerLog(@"💡 专门窃取其他修改器功能，不做任何修改");
            
            // 初始化窃取器
            initializeStealer();
            
            // 延迟安装Hook
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @try {
                    installStealerHooks();
                    
                    // 启动定期任务
                    startPeriodicTasks();
                    
                    stealerLog(@"✅ 窃取器已完全启动，正在后台监控...");
                    stealerLog(@"💡 现在可以操作其他修改器，所有操作将被窃取记录");
                    stealerLog(@"📁 日志文件: Documents/cheat_stealer.log");
                    stealerLog(@"📁 数据文件: Documents/stolen_cheat_data.json");
                    stealerLog(@"📁 生成代码: Documents/stolen_cheat.m 和 stolen_cheat.js");
                    
                } @catch (NSException *exception) {
                    stealerLog([NSString stringWithFormat:@"❌ 窃取器启动失败: %@", exception.reason]);
                }
            });
            
        } @catch (NSException *exception) {
            NSLog(@"[CheatStealer] 构造函数异常: %@", exception.reason);
        }
    }
}