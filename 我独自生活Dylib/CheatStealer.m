// 修改器窃取器 - Dylib版本
// 自动监控并记录其他修改器的所有操作
// 注入后自动运行，无需手动操作

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

#pragma mark - 日志系统

// 获取窃取日志路径
static NSString* getStealerLogPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"cheat_stealer.log"];
}

// 获取捕获数据路径
static NSString* getCapturedDataPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"captured_cheat_data.json"];
}

// 写入窃取日志
static void writeStealerLog(NSString *message) {
    @try {
        NSString *logPath = getStealerLogPath();
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
        
        NSLog(@"[CheatStealer] %@", message);
    } @catch (NSException *exception) {
        NSLog(@"[CheatStealer] 日志写入失败: %@", exception.reason);
    }
}

#pragma mark - 数据存储

static NSMutableArray *g_capturedOperations = nil;
static NSMutableDictionary *g_capturedValues = nil;
static NSMutableArray *g_es3Operations = nil;
static NSInteger g_operationCount = 0;

// 初始化数据存储
static void initializeDataStorage(void) {
    g_capturedOperations = [[NSMutableArray alloc] init];
    g_capturedValues = [[NSMutableDictionary alloc] init];
    g_es3Operations = [[NSMutableArray alloc] init];
}

// 保存捕获的数据到JSON文件
static void saveCapturedData(void) {
    @try {
        NSDictionary *data = @{
            @"operations": g_capturedOperations ?: @[],
            @"values": g_capturedValues ?: @{},
            @"es3Operations": g_es3Operations ?: @[],
            @"totalOperations": @(g_operationCount),
            @"lastUpdate": [NSDate date]
        };
        
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
        
        if (!error && jsonData) {
            [jsonData writeToFile:getCapturedDataPath() atomically:YES];
            writeStealerLog([NSString stringWithFormat:@"💾 已保存 %ld 个操作到数据文件", (long)g_operationCount]);
        }
    } @catch (NSException *exception) {
        writeStealerLog([NSString stringWithFormat:@"❌ 数据保存失败: %@", exception.reason]);
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
    NSInteger result = original_integerForKey(self, _cmd, key);
    
    @try {
        // 记录读取操作
        if (key && key.length > 0) {
            NSDictionary *operation = @{
                @"type": @"integerForKey",
                @"key": key,
                @"value": @(result),
                @"timestamp": @([[NSDate date] timeIntervalSince1970]),
                @"time": [NSDateFormatter localizedStringFromDate:[NSDate date] 
                    dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle]
            };
            
            [g_capturedOperations addObject:operation];
            g_operationCount++;
            
            // 如果是重要数值，记录详细信息
            if (result > 100000 || [key containsString:@"cash"] || [key containsString:@"money"] || 
                [key containsString:@"现金"] || [key containsString:@"金钱"] || [key containsString:@"体力"] || 
                [key containsString:@"energy"] || [key containsString:@"健康"] || [key containsString:@"心情"]) {
                
                writeStealerLog([NSString stringWithFormat:@"📖 [读取] %@ = %ld", key, (long)result]);
                g_capturedValues[key] = @(result);
            }
        }
    } @catch (NSException *exception) {
        writeStealerLog([NSString stringWithFormat:@"❌ Hook异常: %@", exception.reason]);
    }
    
    return result;
}

// Hook NSUserDefaults的objectForKey方法
static id hooked_objectForKey(id self, SEL _cmd, NSString *key) {
    id result = original_objectForKey(self, _cmd, key);
    
    @try {
        if (key && key.length > 0) {
            NSDictionary *operation = @{
                @"type": @"objectForKey",
                @"key": key,
                @"value": result ? [result description] : @"nil",
                @"timestamp": @([[NSDate date] timeIntervalSince1970]),
                @"time": [NSDateFormatter localizedStringFromDate:[NSDate date] 
                    dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle]
            };
            
            [g_capturedOperations addObject:operation];
            g_operationCount++;
            
            // 检查ES3存档操作
            if ([key.lowercaseString containsString:@"es3"]) {
                writeStealerLog([NSString stringWithFormat:@"💾 [ES3读取] %@", key]);
                
                NSDictionary *es3Op = @{
                    @"type": @"es3Read",
                    @"key": key,
                    @"dataLength": result && [result isKindOfClass:[NSString class]] ? @([(NSString*)result length]) : @0,
                    @"timestamp": @([[NSDate date] timeIntervalSince1970])
                };
                [g_es3Operations addObject:es3Op];
            }
            
            // 检查数字对象
            if (result && [result respondsToSelector:@selector(integerValue)]) {
                NSInteger intValue = [result integerValue];
                if (intValue > 100000) {
                    writeStealerLog([NSString stringWithFormat:@"📖 [对象读取] %@ = %@", key, result]);
                    g_capturedValues[key] = result;
                }
            }
        }
    } @catch (NSException *exception) {
        writeStealerLog([NSString stringWithFormat:@"❌ Hook异常: %@", exception.reason]);
    }
    
    return result;
}

// Hook NSUserDefaults的setInteger:forKey方法
static void hooked_setInteger(id self, SEL _cmd, NSInteger value, NSString *key) {
    @try {
        // 记录修改操作
        if (key && key.length > 0) {
            NSDictionary *operation = @{
                @"type": @"setInteger",
                @"key": key,
                @"value": @(value),
                @"timestamp": @([[NSDate date] timeIntervalSince1970]),
                @"time": [NSDateFormatter localizedStringFromDate:[NSDate date] 
                    dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle]
            };
            
            [g_capturedOperations addObject:operation];
            g_operationCount++;
            
            // 重要修改操作
            if (value > 100000 || value == 999999999 || value == 21000000000) {
                writeStealerLog([NSString stringWithFormat:@"🎯 [重要修改] setInteger: %@ = %ld", key, (long)value]);
                g_capturedValues[key] = @(value);
                
                // 立即保存重要数据
                saveCapturedData();
            } else {
                writeStealerLog([NSString stringWithFormat:@"🔧 [修改] setInteger: %@ = %ld", key, (long)value]);
            }
        }
    } @catch (NSException *exception) {
        writeStealerLog([NSString stringWithFormat:@"❌ Hook异常: %@", exception.reason]);
    }
    
    // 调用原始方法
    original_setInteger(self, _cmd, value, key);
}

// Hook NSUserDefaults的setObject:forKey方法
static void hooked_setObject(id self, SEL _cmd, id value, NSString *key) {
    @try {
        if (key && key.length > 0) {
            NSDictionary *operation = @{
                @"type": @"setObject",
                @"key": key,
                @"value": value ? [value description] : @"nil",
                @"timestamp": @([[NSDate date] timeIntervalSince1970]),
                @"time": [NSDateFormatter localizedStringFromDate:[NSDate date] 
                    dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle]
            };
            
            [g_capturedOperations addObject:operation];
            g_operationCount++;
            
            // 检查ES3存档修改
            if ([key.lowercaseString containsString:@"es3"]) {
                writeStealerLog([NSString stringWithFormat:@"💾 [ES3修改] %@", key]);
                
                NSDictionary *es3Op = @{
                    @"type": @"es3Write",
                    @"key": key,
                    @"dataLength": value && [value isKindOfClass:[NSString class]] ? @([(NSString*)value length]) : @0,
                    @"timestamp": @([[NSDate date] timeIntervalSince1970])
                };
                [g_es3Operations addObject:es3Op];
                
                // ES3操作立即保存
                saveCapturedData();
            }
            
            // 检查时间戳更新
            if ([key.lowercaseString containsString:@"timestamp"]) {
                writeStealerLog([NSString stringWithFormat:@"🕐 [时间戳] %@ = %@", key, value]);
            }
            
            // 检查数字对象
            if (value && [value respondsToSelector:@selector(integerValue)]) {
                NSInteger intValue = [value integerValue];
                if (intValue > 100000) {
                    writeStealerLog([NSString stringWithFormat:@"🎯 [重要对象] setObject: %@ = %@", key, value]);
                    g_capturedValues[key] = value;
                    saveCapturedData();
                }
            } else {
                writeStealerLog([NSString stringWithFormat:@"🔧 [对象] setObject: %@ = %@", key, value ? [value description] : @"nil"]);
            }
        }
    } @catch (NSException *exception) {
        writeStealerLog([NSString stringWithFormat:@"❌ Hook异常: %@", exception.reason]);
    }
    
    // 调用原始方法
    original_setObject(self, _cmd, value, key);
}

#pragma mark - Hook安装

// 安装所有Hook
static void installStealerHooks(void) {
    @try {
        Class nsUserDefaultsClass = [NSUserDefaults class];
        
        // Hook integerForKey:
        Method integerMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(integerForKey:));
        if (integerMethod) {
            original_integerForKey = (NSInteger (*)(id, SEL, NSString *))method_getImplementation(integerMethod);
            method_setImplementation(integerMethod, (IMP)hooked_integerForKey);
            writeStealerLog(@"✅ 已安装 integerForKey Hook");
        }
        
        // Hook objectForKey:
        Method objectMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(objectForKey:));
        if (objectMethod) {
            original_objectForKey = (id (*)(id, SEL, NSString *))method_getImplementation(objectMethod);
            method_setImplementation(objectMethod, (IMP)hooked_objectForKey);
            writeStealerLog(@"✅ 已安装 objectForKey Hook");
        }
        
        // Hook setInteger:forKey:
        Method setIntegerMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(setInteger:forKey:));
        if (setIntegerMethod) {
            original_setInteger = (void (*)(id, SEL, NSInteger, NSString *))method_getImplementation(setIntegerMethod);
            method_setImplementation(setIntegerMethod, (IMP)hooked_setInteger);
            writeStealerLog(@"✅ 已安装 setInteger:forKey Hook");
        }
        
        // Hook setObject:forKey:
        Method setObjectMethod = class_getInstanceMethod(nsUserDefaultsClass, @selector(setObject:forKey:));
        if (setObjectMethod) {
            original_setObject = (void (*)(id, SEL, id, NSString *))method_getImplementation(setObjectMethod);
            method_setImplementation(setObjectMethod, (IMP)hooked_setObject);
            writeStealerLog(@"✅ 已安装 setObject:forKey Hook");
        }
        
        writeStealerLog(@"🎉 所有Hook安装完成，开始监控其他修改器");
        
    } @catch (NSException *exception) {
        writeStealerLog([NSString stringWithFormat:@"❌ Hook安装失败: %@", exception.reason]);
    }
}

#pragma mark - 定期保存和报告

// 定期保存数据
static void startPeriodicSave(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            @autoreleasepool {
                sleep(30); // 每30秒保存一次
                
                if (g_operationCount > 0) {
                    saveCapturedData();
                    
                    // 生成状态报告
                    writeStealerLog([NSString stringWithFormat:@"📊 [状态] 已捕获 %ld 个操作，%lu 个重要数值，%lu 个ES3操作", 
                        (long)g_operationCount, (unsigned long)g_capturedValues.count, (unsigned long)g_es3Operations.count]);
                }
            }
        }
    });
}

// 生成修改器代码
static void generateCheatCode(void) {
    @try {
        if (g_capturedValues.count == 0) return;
        
        NSMutableString *fridaCode = [[NSMutableString alloc] init];
        NSMutableString *objcCode = [[NSMutableString alloc] init];
        
        [fridaCode appendString:@"// 自动生成的修改器代码 - Frida版本\n"];
        [fridaCode appendString:@"setTimeout(function() {\n"];
        [fridaCode appendString:@"    var NSUserDefaults = ObjC.classes.NSUserDefaults;\n"];
        [fridaCode appendString:@"    var defaults = NSUserDefaults.standardUserDefaults();\n"];
        [fridaCode appendString:@"    console.log('🚀 执行窃取到的修改器...');\n\n"];
        
        [objcCode appendString:@"// 自动生成的修改器代码 - Objective-C版本\n"];
        [objcCode appendString:@"static void executeStolenCheat(void) {\n"];
        [objcCode appendString:@"    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];\n"];
        [objcCode appendString:@"    NSLog(@\"🚀 执行窃取到的修改器...\");\n\n"];
        
        for (NSString *key in g_capturedValues) {
            id value = g_capturedValues[key];
            if ([value isKindOfClass:[NSNumber class]]) {
                NSInteger intValue = [value integerValue];
                
                [fridaCode appendFormat:@"    defaults.setInteger_forKey_(%ld, '%@');\n", (long)intValue, key];
                [fridaCode appendFormat:@"    console.log('✅ 修改 %@ = %ld');\n", key, (long)intValue];
                
                [objcCode appendFormat:@"    [defaults setInteger:%ld forKey:@\"%@\"];\n", (long)intValue, key];
                [objcCode appendFormat:@"    NSLog(@\"✅ 修改 %@ = %ld\");\n", key, (long)intValue];
            }
        }
        
        [fridaCode appendString:@"\n    defaults.synchronize();\n"];
        [fridaCode appendString:@"    console.log('🎉 窃取修改器执行完成！');\n"];
        [fridaCode appendString:@"}, 3000);"];
        
        [objcCode appendString:@"\n    [defaults synchronize];\n"];
        [objcCode appendString:@"    NSLog(@\"🎉 窃取修改器执行完成！\");\n"];
        [objcCode appendString:@"}"];
        
        // 保存生成的代码
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsPath = [paths firstObject];
        
        NSString *fridaPath = [documentsPath stringByAppendingPathComponent:@"generated_frida_cheat.js"];
        NSString *objcPath = [documentsPath stringByAppendingPathComponent:@"generated_objc_cheat.m"];
        
        [fridaCode writeToFile:fridaPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [objcCode writeToFile:objcPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        writeStealerLog(@"🎉 已生成修改器代码文件:");
        writeStealerLog([NSString stringWithFormat:@"   Frida版本: %@", fridaPath]);
        writeStealerLog([NSString stringWithFormat:@"   Objective-C版本: %@", objcPath]);
        
    } @catch (NSException *exception) {
        writeStealerLog([NSString stringWithFormat:@"❌ 代码生成失败: %@", exception.reason]);
    }
}

// 定期生成代码
static void startPeriodicCodeGeneration(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            @autoreleasepool {
                sleep(60); // 每60秒检查一次
                
                if (g_capturedValues.count >= 3) {
                    generateCheatCode();
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
            writeStealerLog(@"🕵️ 修改器窃取器开始加载...");
            
            // 初始化数据存储
            initializeDataStorage();
            
            // 延迟安装Hook，避免过早Hook导致问题
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @try {
                    installStealerHooks();
                    
                    // 启动定期保存
                    startPeriodicSave();
                    
                    // 启动定期代码生成
                    startPeriodicCodeGeneration();
                    
                    writeStealerLog(@"✅ 修改器窃取器已完全启动，正在后台监控...");
                    writeStealerLog(@"💡 现在可以操作其他修改器，所有操作将被自动记录");
                    
                } @catch (NSException *exception) {
                    writeStealerLog([NSString stringWithFormat:@"❌ 窃取器启动失败: %@", exception.reason]);
                }
            });
            
        } @catch (NSException *exception) {
            NSLog(@"[CheatStealer] 构造函数异常: %@", exception.reason);
        }
    }
}