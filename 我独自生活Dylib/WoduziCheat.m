// 我独自生活修改器 - WoduziCheat.m
// 参考卡包修仙和天选打工人的成功实现
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

#pragma mark - 日志系统

// 获取日志路径
static NSString* getLogPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"woduzishenghua_cheat.log"];
}

// 写日志到文件
static void writeLog(NSString *message) {
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
    
    NSLog(@"[WDZ] %@", message);
}

#pragma mark - 实时Hook功能

// 全局开关
static BOOL g_infiniteCashEnabled = NO;
static BOOL g_infiniteEnergyEnabled = NO;
static BOOL g_infiniteHealthEnabled = NO;
static BOOL g_infiniteMoodEnabled = NO;

// Hook NSUserDefaults的integerForKey方法
static NSInteger (*original_integerForKey)(id self, SEL _cmd, NSString *key);
static NSInteger hooked_integerForKey(id self, SEL _cmd, NSString *key) {
    NSInteger originalValue = original_integerForKey(self, _cmd, key);
    
    // 检查是否是我们要修改的字段
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
    
    return originalValue;
}

// Hook NSUserDefaults的objectForKey方法
static id (*original_objectForKey)(id self, SEL _cmd, NSString *key);
static id hooked_objectForKey(id self, SEL _cmd, NSString *key) {
    id originalValue = original_objectForKey(self, _cmd, key);
    
    // 如果返回的是NSNumber，进行数值检查
    if ([originalValue isKindOfClass:[NSNumber class]]) {
        NSString *lowerKey = [key lowercaseString];
        
        if (g_infiniteCashEnabled && ([lowerKey containsString:@"cash"] || [lowerKey containsString:@"money"] || 
            [lowerKey containsString:@"现金"] || [lowerKey containsString:@"金钱"] || [lowerKey containsString:@"coin"])) {
            writeLog([NSString stringWithFormat:@"🎯 Hook拦截现金对象: %@ (原值: %@ → 新值: 21000000000)", key, originalValue]);
            return @21000000000;
        }
        
        if (g_infiniteEnergyEnabled && ([lowerKey containsString:@"energy"] || [lowerKey containsString:@"stamina"] || 
            [lowerKey containsString:@"体力"] || [lowerKey containsString:@"power"])) {
            writeLog([NSString stringWithFormat:@"🎯 Hook拦截体力对象: %@ (原值: %@ → 新值: 21000000000)", key, originalValue]);
            return @21000000000;
        }
        
        if (g_infiniteHealthEnabled && ([lowerKey containsString:@"health"] || [lowerKey containsString:@"hp"] || 
            [lowerKey containsString:@"健康"] || [lowerKey containsString:@"life"])) {
            writeLog([NSString stringWithFormat:@"🎯 Hook拦截健康对象: %@ (原值: %@ → 新值: 1000000)", key, originalValue]);
            return @1000000;
        }
        
        if (g_infiniteMoodEnabled && ([lowerKey containsString:@"mood"] || [lowerKey containsString:@"happiness"] || 
            [lowerKey containsString:@"心情"] || [lowerKey containsString:@"spirit"])) {
            writeLog([NSString stringWithFormat:@"🎯 Hook拦截心情对象: %@ (原值: %@ → 新值: 1000000)", key, originalValue]);
            return @1000000;
        }
    }
    
    return originalValue;
}

// 安装Hook
static void installHooks(void) {
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
}

#pragma mark - 全局变量

@class WDZMenuView;
static UIButton *g_floatButton = nil;
static WDZMenuView *g_menuView = nil;

#pragma mark - 函数前向声明

static void showMenu(void);
static UIWindow* getKeyWindow(void);
static BOOL searchAndModifyES3Data(NSMutableDictionary *es3Dict, NSUserDefaults *defaults);
static BOOL searchDictionaryRecursively(NSMutableDictionary *dict, BOOL searchAttributes);

#pragma mark - 版权保护

// 解密版权字符串（防止二进制修改）
static NSString* getCopyrightText(void) {
    // 动态拼接（防止Base64编码问题）
    NSString *part1 = @"©";
    NSString *part2 = @" 2026";
    NSString *part3 = @"  ";
    NSString *part4 = @"𝐈𝐎𝐒𝐃𝐊";
    NSString *part5 = @" 科技虎";
    
    return [NSString stringWithFormat:@"%@%@%@%@%@", part1, part2, part3, part4, part5];
}

// 解密图片URL（防止二进制修改）
static NSString* getIconURL(void) {
    // Base64编码: "https://iosdk.cn/tu/2023/04/17/p9CjtUg1.png"
    const char *encoded = "aHR0cHM6Ly9pb3Nkay5jbi90dS8yMDIzLzA0LzE3L3A5Q2p0VWcxLnBuZw==";
    NSData *data = [[NSData alloc] initWithBase64EncodedString:[NSString stringWithUTF8String:encoded] options:0];
    NSString *decoded = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // 动态拼接备份（增加混淆）
    NSString *protocol = @"https://";
    NSString *domain = @"iosdk.cn";
    NSString *path1 = @"/tu/2023";
    NSString *path2 = @"/04/17/";
    NSString *filename = @"p9CjtUg1.png";
    
    // 验证解码是否成功，失败则使用拼接
    if (decoded && decoded.length > 0) {
        return decoded;
    }
    return [NSString stringWithFormat:@"%@%@%@%@%@", protocol, domain, path1, path2, filename];
}

#pragma mark - 免责声明管理

// 检查是否已同意免责声明
static BOOL hasAgreedToDisclaimer(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"WDZCheat_DisclaimerAgreed"];
}

// 保存免责声明同意状态
static void setDisclaimerAgreed(BOOL agreed) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:agreed forKey:@"WDZCheat_DisclaimerAgreed"];
    [defaults synchronize];
}

// 显示免责声明弹窗
static void showDisclaimerAlert(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"⚠️ 免责声明" 
        message:@"本工具仅供技术研究与学习，严禁用于商业用途及非法途径。\n\n使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。\n\n严禁倒卖、传播或用于牟利，否则后果自负。\n\n继续使用即表示您已阅读并同意本声明。\n\n是否同意并继续使用？" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"不同意" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // 用户不同意，直接退出应用
        writeLog(@"用户不同意免责声明，应用退出");
        exit(0);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 用户同意，保存状态并显示功能菜单
        setDisclaimerAgreed(YES);
        writeLog(@"用户同意免责声明");
        showMenu();
    }]];
    
    UIViewController *rootVC = getKeyWindow().rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 游戏数据修改

// 修改游戏存档数据 - 基于其他修改器的ES3存档修改方式
static void modifyGameSaveData(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 基于分析结果，其他修改器使用 data1.es3 而不是 data0.es3
    writeLog(@"========== 使用ES3存档修改方式 ==========");
    
    // 尝试修改 data1.es3 存档（其他修改器使用的）
    NSString *es3Data = [defaults objectForKey:@"data1.es3"];
    if (es3Data) {
        writeLog(@"✅ 找到 data1.es3 存档数据");
        writeLog([NSString stringWithFormat:@"ES3存档长度: %lu", (unsigned long)es3Data.length]);
        
        if (modifyES3SaveData(es3Data, @"data1.es3", defaults)) {
            writeLog(@"🎉 data1.es3 存档修改完成！");
        }
    }
    
    // 同时尝试 data0.es3（你原来的方法）
    es3Data = [defaults objectForKey:@"data0.es3"];
    if (es3Data) {
        writeLog(@"✅ 找到 data0.es3 存档数据");
        writeLog([NSString stringWithFormat:@"ES3存档长度: %lu", (unsigned long)es3Data.length]);
        
        if (modifyES3SaveData(es3Data, @"data0.es3", defaults)) {
            writeLog(@"🎉 data0.es3 存档修改完成！");
        }
    }
    
    // 如果都没找到，尝试搜索所有可能的ES3存档
    if (!es3Data) {
        writeLog(@"========== 搜索所有ES3存档 ==========");
        NSDictionary *allDefaults = [defaults dictionaryRepresentation];
        for (NSString *key in allDefaults) {
            if ([key containsString:@"es3"] || [key containsString:@"ES3"]) {
                id value = allDefaults[key];
                if ([value isKindOfClass:[NSString class]]) {
                    NSString *dataStr = (NSString *)value;
                    if (dataStr.length > 1000) {
                        writeLog([NSString stringWithFormat:@"发现ES3存档: %@ (长度: %lu)", key, (unsigned long)dataStr.length]);
                        if (modifyES3SaveData(dataStr, key, defaults)) {
                            writeLog([NSString stringWithFormat:@"🎉 %@ 存档修改完成！", key]);
                        }
                    }
                }
            }
        }
    }
    
    // 然后尝试修改JSON存档
    writeLog(@"========== 尝试修改JSON存档 ==========");
    
    NSString *gameDataKey = @"0";
    id gameData = [defaults objectForKey:gameDataKey];
    
    if (!gameData) {
        writeLog(@"❌ 未找到游戏存档数据");
        return;
    }
    
    writeLog(@"✅ 找到游戏存档数据");
    
    // 如果是字符串，尝试解析JSON
    if ([gameData isKindOfClass:[NSString class]]) {
        NSString *jsonString = (NSString *)gameData;
        writeLog([NSString stringWithFormat:@"存档数据长度: %lu", (unsigned long)jsonString.length]);
        
        NSError *error = nil;
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *saveDict = [NSJSONSerialization JSONObjectWithData:jsonData 
            options:NSJSONReadingMutableContainers error:&error];
        
        if (error || !saveDict) {
            writeLog([NSString stringWithFormat:@"❌ JSON解析失败: %@", error.localizedDescription]);
            return;
        }
        
        writeLog(@"✅ JSON解析成功");
        
        // 添加详细的调试信息，列出所有键
        writeLog(@"========== 调试：JSON中的所有键 ==========");
        for (NSString *key in [saveDict allKeys]) {
            id value = saveDict[key];
            NSString *valueStr = [NSString stringWithFormat:@"%@", value];
            if (valueStr.length > 200) {
                valueStr = [[valueStr substringToIndex:200] stringByAppendingString:@"..."];
            }
            writeLog([NSString stringWithFormat:@"Key: %@ = %@", key, valueStr]);
        }
        writeLog(@"========== 调试结束 ==========");
        
        // 修改游戏数据
        BOOL modified = NO;
        
        // 查找并修改可能的现金字段
        NSArray *cashKeys = @[@"现金", @"金钱", @"cash", @"money", @"当前现金", @"玩家现金", @"存档数据_现金"];
        for (NSString *key in cashKeys) {
            if (saveDict[key]) {
                saveDict[key] = @21000000000;
                modified = YES;
                writeLog([NSString stringWithFormat:@"✅ 修改 %@ = 21000000000", key]);
            }
        }
        
        // 查找并修改可能的体力字段
        NSArray *energyKeys = @[@"体力", @"当前体力", @"玩家体力", @"存档数据_体力", @"体力值"];
        for (NSString *key in energyKeys) {
            if (saveDict[key]) {
                saveDict[key] = @21000000000;
                modified = YES;
                writeLog([NSString stringWithFormat:@"✅ 修改 %@ = 21000000000", key]);
            }
        }
        
        // 查找并修改可能的健康字段
        NSArray *healthKeys = @[@"健康", @"当前健康", @"玩家健康", @"存档数据_健康", @"健康值"];
        for (NSString *key in healthKeys) {
            if (saveDict[key]) {
                saveDict[key] = @1000000;
                modified = YES;
                writeLog([NSString stringWithFormat:@"✅ 修改 %@ = 1000000", key]);
            }
        }
        
        // 查找并修改可能的心情字段
        NSArray *moodKeys = @[@"心情", @"当前心情", @"玩家心情", @"存档数据_心情", @"心情值"];
        for (NSString *key in moodKeys) {
            if (saveDict[key]) {
                saveDict[key] = @1000000;
                modified = YES;
                writeLog([NSString stringWithFormat:@"✅ 修改 %@ = 1000000", key]);
            }
        }
        
        // 遍历所有键，寻找可能的数值字段
        for (NSString *key in [saveDict allKeys]) {
            id value = saveDict[key];
            if ([value isKindOfClass:[NSNumber class]]) {
                NSNumber *numValue = (NSNumber *)value;
                // 如果是较大的数值，可能是游戏资源
                if ([numValue integerValue] > 1000 && [numValue integerValue] < 100000000) {
                    if ([key containsString:@"现金"] || [key containsString:@"金钱"] || [key containsString:@"cash"] || [key containsString:@"money"]) {
                        saveDict[key] = @21000000000;
                        modified = YES;
                        writeLog([NSString stringWithFormat:@"✅ 修改现金字段 %@ = 21000000000", key]);
                    } else if ([key containsString:@"体力"] || [key containsString:@"energy"] || [key containsString:@"stamina"]) {
                        saveDict[key] = @21000000000;
                        modified = YES;
                        writeLog([NSString stringWithFormat:@"✅ 修改体力字段 %@ = 21000000000", key]);
                    } else if ([key containsString:@"健康"] || [key containsString:@"health"] || [key containsString:@"hp"]) {
                        saveDict[key] = @1000000;
                        modified = YES;
                        writeLog([NSString stringWithFormat:@"✅ 修改健康字段 %@ = 1000000", key]);
                    } else if ([key containsString:@"心情"] || [key containsString:@"mood"] || [key containsString:@"happiness"]) {
                        saveDict[key] = @1000000;
                        modified = YES;
                        writeLog([NSString stringWithFormat:@"✅ 修改心情字段 %@ = 1000000", key]);
                    }
                }
            }
        }
        
        if (modified) {
            // 重新序列化为JSON字符串
            NSError *serializeError = nil;
            NSData *newJsonData = [NSJSONSerialization dataWithJSONObject:saveDict options:0 error:&serializeError];
            
            if (serializeError || !newJsonData) {
                writeLog([NSString stringWithFormat:@"❌ JSON序列化失败: %@", serializeError.localizedDescription]);
                return;
            }
            
            NSString *newJsonString = [[NSString alloc] initWithData:newJsonData encoding:NSUTF8StringEncoding];
            
            // 保存回NSUserDefaults
            [defaults setObject:newJsonString forKey:gameDataKey];
            [defaults synchronize];
            
            writeLog(@"🎉 游戏存档修改完成！");
        } else {
            writeLog(@"❌ 未找到可修改的游戏数据字段");
        }
    }
    
    // 最后，搜索NSUserDefaults中所有可能的大数值字段
    writeLog(@"========== 搜索NSUserDefaults中的所有大数值 ==========");
    NSDictionary *allDefaults = [defaults dictionaryRepresentation];
    BOOL foundAnyValue = NO;
    
    for (NSString *key in allDefaults) {
        id value = allDefaults[key];
        if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            NSInteger intVal = [numValue integerValue];
            if (intVal >= 100 && intVal <= 50000000000) {  // 搜索可能的游戏数值
                writeLog([NSString stringWithFormat:@"发现数值字段: %@ = %ld", key, (long)intVal]);
                
                // 如果数值在合理范围内，尝试修改
                if (intVal >= 100 && intVal <= 1000000000) {
                    if ([key containsString:@"现金"] || [key containsString:@"金钱"] || [key containsString:@"cash"] || [key containsString:@"money"] || [key containsString:@"Cash"] || [key containsString:@"Money"]) {
                        [defaults setInteger:21000000000 forKey:key];
                        writeLog([NSString stringWithFormat:@"✅ 修改现金字段 %@ = 21000000000", key]);
                        foundAnyValue = YES;
                    } else if ([key containsString:@"体力"] || [key containsString:@"energy"] || [key containsString:@"stamina"] || [key containsString:@"Energy"] || [key containsString:@"Stamina"]) {
                        [defaults setInteger:21000000000 forKey:key];
                        writeLog([NSString stringWithFormat:@"✅ 修改体力字段 %@ = 21000000000", key]);
                        foundAnyValue = YES;
                    } else if ([key containsString:@"健康"] || [key containsString:@"health"] || [key containsString:@"hp"] || [key containsString:@"Health"] || [key containsString:@"HP"]) {
                        [defaults setInteger:1000000 forKey:key];
                        writeLog([NSString stringWithFormat:@"✅ 修改健康字段 %@ = 1000000", key]);
                        foundAnyValue = YES;
                    } else if ([key containsString:@"心情"] || [key containsString:@"mood"] || [key containsString:@"happiness"] || [key containsString:@"Mood"] || [key containsString:@"Happiness"]) {
                        [defaults setInteger:1000000 forKey:key];
                        writeLog([NSString stringWithFormat:@"✅ 修改心情字段 %@ = 1000000", key]);
                        foundAnyValue = YES;
                    }
                }
            }
        }
    }
    
    // 如果没有找到明确的字段，尝试修改一些通用的可能字段
    if (!foundAnyValue) {
        writeLog(@"========== 尝试修改通用字段 ==========");
        
        // 尝试一些可能的字段名
        NSArray *possibleCashKeys = @[@"playerCash", @"gameCash", @"userMoney", @"currentCash", @"totalCash", @"coin", @"coins"];
        NSArray *possibleEnergyKeys = @[@"playerEnergy", @"gameEnergy", @"userEnergy", @"currentEnergy", @"totalEnergy", @"power"];
        NSArray *possibleHealthKeys = @[@"playerHealth", @"gameHealth", @"userHealth", @"currentHealth", @"totalHealth", @"life"];
        NSArray *possibleMoodKeys = @[@"playerMood", @"gameMood", @"userMood", @"currentMood", @"totalMood", @"spirit"];
        
        for (NSString *key in possibleCashKeys) {
            [defaults setInteger:21000000000 forKey:key];
            writeLog([NSString stringWithFormat:@"✅ 尝试设置现金字段 %@ = 21000000000", key]);
        }
        
        for (NSString *key in possibleEnergyKeys) {
            [defaults setInteger:21000000000 forKey:key];
            writeLog([NSString stringWithFormat:@"✅ 尝试设置体力字段 %@ = 21000000000", key]);
        }
        
        for (NSString *key in possibleHealthKeys) {
            [defaults setInteger:1000000 forKey:key];
            writeLog([NSString stringWithFormat:@"✅ 尝试设置健康字段 %@ = 1000000", key]);
        }
        
        for (NSString *key in possibleMoodKeys) {
            [defaults setInteger:1000000 forKey:key];
            writeLog([NSString stringWithFormat:@"✅ 尝试设置心情字段 %@ = 1000000", key]);
        }
    }
    
    [defaults synchronize];
    writeLog(@"========== NSUserDefaults搜索完成 ==========");
}

// 修改ES3存档数据 - 基于其他修改器的实现方式
static BOOL modifyES3SaveData(NSString *es3Data, NSString *key, NSUserDefaults *defaults) {
    writeLog([NSString stringWithFormat:@"开始修改ES3存档: %@", key]);
    
    // ES3数据是Base64编码的JSON
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:es3Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!decodedData) {
        writeLog(@"❌ Base64解码失败");
        return NO;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    if (!jsonString) {
        writeLog(@"❌ UTF8字符串转换失败");
        return NO;
    }
    
    writeLog([NSString stringWithFormat:@"✅ ES3 JSON解码成功，长度: %lu", (unsigned long)jsonString.length]);
    writeLog([NSString stringWithFormat:@"ES3内容预览: %@", [jsonString substringToIndex:MIN(200, jsonString.length)]]);
    
    NSError *error = nil;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    if (error || ![jsonObject isKindOfClass:[NSDictionary class]]) {
        writeLog([NSString stringWithFormat:@"❌ JSON解析失败: %@", error.localizedDescription]);
        return NO;
    }
    
    NSMutableDictionary *es3Dict = [jsonObject mutableCopy];
    writeLog(@"✅ ES3 JSON解析成功");
    writeLog([NSString stringWithFormat:@"ES3存档包含 %lu 个对象", (unsigned long)[es3Dict count]]);
    
    // 显示ES3存档的结构
    for (NSString *objKey in es3Dict) {
        id value = es3Dict[objKey];
        NSString *valueStr = [NSString stringWithFormat:@"%@", value];
        if (valueStr.length > 200) {
            valueStr = [[valueStr substringToIndex:200] stringByAppendingString:@"..."];
        }
        writeLog([NSString stringWithFormat:@"ES3 Key: %@ = %@", objKey, valueStr]);
    }
    
    // 在ES3存档中搜索并修改玩家属性
    BOOL es3Modified = searchAndModifyES3Data(es3Dict, defaults);
    
    if (es3Modified) {
        // 重新保存ES3存档
        NSData *newJsonData = [NSJSONSerialization dataWithJSONObject:es3Dict options:0 error:&error];
        if (error || !newJsonData) {
            writeLog([NSString stringWithFormat:@"❌ JSON序列化失败: %@", error.localizedDescription]);
            return NO;
        }
        
        NSString *newJsonString = [[NSString alloc] initWithData:newJsonData encoding:NSUTF8StringEncoding];
        NSData *encodedData = [newJsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSString *newES3Data = [encodedData base64EncodedStringWithOptions:0];
        
        // 保存修改后的ES3存档
        [defaults setObject:newES3Data forKey:key];
        
        // 更新时间戳（模仿其他修改器的做法）
        NSString *timestampKey = [NSString stringWithFormat:@"timestamp_%@", key];
        NSNumber *timestamp = @([[NSDate date] timeIntervalSince1970] * 1000000);
        [defaults setObject:timestamp forKey:timestampKey];
        
        [defaults synchronize];
        
        writeLog([NSString stringWithFormat:@"🎉 %@ 存档修改并保存完成！", key]);
        writeLog([NSString stringWithFormat:@"🕐 时间戳已更新: %@", timestampKey]);
        return YES;
    } else {
        writeLog(@"❌ 未找到可修改的游戏数据字段");
        return NO;
    }
}

// 搜索并修改ES3数据中的玩家属性
static BOOL searchAndModifyES3Data(NSMutableDictionary *es3Dict, NSUserDefaults *defaults) {
    BOOL modified = NO;
    
    writeLog([NSString stringWithFormat:@"ES3存档包含 %lu 个对象", (unsigned long)[es3Dict count]]);
    
    // 遍历ES3存档中的所有对象
    for (NSString *key in es3Dict) {
        id value = es3Dict[key];
        writeLog([NSString stringWithFormat:@"ES3 Key: %@ = %@", key, [value class]]);
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *objDict = [value mutableCopy];
            
            // 检查是否有value数组（GameObject数组）
            if (objDict[@"value"] && [objDict[@"value"] isKindOfClass:[NSArray class]]) {
                NSMutableArray *valueArray = [objDict[@"value"] mutableCopy];
                writeLog([NSString stringWithFormat:@"找到value数组，包含 %lu 个GameObject", (unsigned long)valueArray.count]);
                
                for (int i = 0; i < valueArray.count; i++) {
                    id item = valueArray[i];
                    if ([item isKindOfClass:[NSDictionary class]]) {
                        NSMutableDictionary *itemDict = [item mutableCopy];
                        
                        // 递归搜索所有字段
                        BOOL itemModified = searchDictionaryRecursively(itemDict, YES);
                        if (itemModified) {
                            modified = YES;
                            valueArray[i] = itemDict;
                        }
                    }
                }
                
                if (modified) {
                    objDict[@"value"] = valueArray;
                    es3Dict[key] = objDict;
                }
            } else {
                // 直接搜索字典
                BOOL objModified = searchDictionaryRecursively(objDict, YES);
                if (objModified) {
                    modified = YES;
                    es3Dict[key] = objDict;
                }
            }
        }
    }
    
    return modified;
}

// 递归搜索字典中的玩家属性
static BOOL searchDictionaryRecursively(NSMutableDictionary *dict, BOOL searchAttributes) {
    BOOL modified = NO;
    
    for (NSString *key in [dict allKeys]) {
        id value = dict[key];
        
        // 如果是字典，递归搜索
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *subDict = [value mutableCopy];
            BOOL subModified = searchDictionaryRecursively(subDict, searchAttributes);
            if (subModified) {
                dict[key] = subDict;
                modified = YES;
            }
        }
        // 如果是数组，遍历数组元素
        else if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *array = [value mutableCopy];
            BOOL arrayModified = NO;
            
            for (int i = 0; i < array.count; i++) {
                id arrayItem = array[i];
                if ([arrayItem isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *arrayDict = [arrayItem mutableCopy];
                    BOOL itemModified = searchDictionaryRecursively(arrayDict, searchAttributes);
                    if (itemModified) {
                        array[i] = arrayDict;
                        arrayModified = YES;
                    }
                }
            }
            
            if (arrayModified) {
                dict[key] = array;
                modified = YES;
            }
        }
        // 如果是数值，检查是否是玩家属性
        else if ([value isKindOfClass:[NSNumber class]] && searchAttributes) {
            NSNumber *numValue = (NSNumber *)value;
            NSInteger intVal = [numValue integerValue];
            
            // 检查数值范围和键名，判断是否是玩家属性
            if (intVal >= 100 && intVal <= 1000000000) {
                NSString *lowerKey = [key lowercaseString];
                
                if ([lowerKey containsString:@"cash"] || [lowerKey containsString:@"money"] || 
                    [lowerKey containsString:@"现金"] || [lowerKey containsString:@"金钱"] ||
                    [lowerKey containsString:@"coin"]) {
                    dict[key] = @21000000000;
                    writeLog([NSString stringWithFormat:@"✅ ES3修改现金字段 %@ = 21000000000 (原值: %ld)", key, (long)intVal]);
                    modified = YES;
                } else if ([lowerKey containsString:@"energy"] || [lowerKey containsString:@"stamina"] || 
                          [lowerKey containsString:@"体力"] || [lowerKey containsString:@"power"]) {
                    dict[key] = @21000000000;
                    writeLog([NSString stringWithFormat:@"✅ ES3修改体力字段 %@ = 21000000000 (原值: %ld)", key, (long)intVal]);
                    modified = YES;
                } else if ([lowerKey containsString:@"health"] || [lowerKey containsString:@"hp"] || 
                          [lowerKey containsString:@"健康"] || [lowerKey containsString:@"life"]) {
                    dict[key] = @1000000;
                    writeLog([NSString stringWithFormat:@"✅ ES3修改健康字段 %@ = 1000000 (原值: %ld)", key, (long)intVal]);
                    modified = YES;
                } else if ([lowerKey containsString:@"mood"] || [lowerKey containsString:@"happiness"] || 
                          [lowerKey containsString:@"心情"] || [lowerKey containsString:@"spirit"]) {
                    dict[key] = @1000000;
                    writeLog([NSString stringWithFormat:@"✅ ES3修改心情字段 %@ = 1000000 (原值: %ld)", key, (long)intVal]);
                    modified = YES;
                }
                // 如果数值在特定范围内，可能是玩家属性，记录下来
                else if (intVal >= 1000 && intVal <= 100000000) {
                    writeLog([NSString stringWithFormat:@"🔍 发现可疑数值字段: %@ = %ld", key, (long)intVal]);
                }
            }
        }
    }
    
    return modified;
}

// 无限现金功能 - 改进版，支持ES3存档修改
static void enableInfiniteCash(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 启用实时Hook
    g_infiniteCashEnabled = YES;
    writeLog(@"🎯 启用现金实时Hook");
    
    // 1. 修改ES3存档（主要方法，模仿其他修改器）
    modifyGameSaveData();
    
    // 2. 修改NSUserDefaults中的字段（备用方法）
    [defaults setInteger:21000000000 forKey:@"cash"];
    [defaults setInteger:21000000000 forKey:@"money"];
    [defaults setInteger:21000000000 forKey:@"现金"];
    [defaults setInteger:21000000000 forKey:@"金钱"];
    [defaults setInteger:21000000000 forKey:@"金币"];
    [defaults setInteger:21000000000 forKey:@"coin"];
    [defaults setInteger:21000000000 forKey:@"coins"];
    [defaults setInteger:21000000000 forKey:@"货币"];
    [defaults setInteger:21000000000 forKey:@"currency"];
    
    // 尝试一些可能的字段名
    [defaults setInteger:21000000000 forKey:@"Cash"];
    [defaults setInteger:21000000000 forKey:@"Money"];
    [defaults setInteger:21000000000 forKey:@"userCash"];
    [defaults setInteger:21000000000 forKey:@"playerCash"];
    [defaults setInteger:21000000000 forKey:@"gameCash"];
    [defaults setInteger:21000000000 forKey:@"当前现金"];
    [defaults setInteger:21000000000 forKey:@"玩家现金"];
    
    [defaults synchronize];
    writeLog(@"无限现金已开启");
}

// 无限健康功能
static void enableInfiniteHealth(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 启用实时Hook
    g_infiniteHealthEnabled = YES;
    writeLog(@"🎯 启用健康实时Hook");
    
    // 游戏存档已在现金函数中处理，这里只处理NSUserDefaults
    [defaults setInteger:1000000 forKey:@"health"];
    [defaults setInteger:1000000 forKey:@"hp"];
    [defaults setInteger:1000000 forKey:@"健康"];
    
    // 尝试一些可能的字段名
    [defaults setInteger:1000000 forKey:@"Health"];
    [defaults setInteger:1000000 forKey:@"HP"];
    [defaults setInteger:1000000 forKey:@"userHealth"];
    [defaults setInteger:1000000 forKey:@"playerHealth"];
    [defaults setInteger:1000000 forKey:@"gameHealth"];
    [defaults setInteger:1000000 forKey:@"当前健康"];
    [defaults setInteger:1000000 forKey:@"玩家健康"];
    
    [defaults synchronize];
    writeLog(@"无限健康已开启");
}

// 无限体力功能 - 改进版，支持ES3存档修改
static void enableInfiniteEnergy(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 启用实时Hook
    g_infiniteEnergyEnabled = YES;
    writeLog(@"🎯 启用体力实时Hook");
    
    // ES3存档修改已在现金函数中处理，这里只处理NSUserDefaults
    [defaults setInteger:21000000000 forKey:@"energy"];
    [defaults setInteger:21000000000 forKey:@"stamina"];
    [defaults setInteger:21000000000 forKey:@"体力"];
    [defaults setInteger:21000000000 forKey:@"power"];
    [defaults setInteger:21000000000 forKey:@"能量"];
    
    // 尝试一些可能的字段名
    [defaults setInteger:21000000000 forKey:@"Energy"];
    [defaults setInteger:21000000000 forKey:@"Stamina"];
    [defaults setInteger:21000000000 forKey:@"userEnergy"];
    [defaults setInteger:21000000000 forKey:@"playerEnergy"];
    [defaults setInteger:21000000000 forKey:@"gameEnergy"];
    [defaults setInteger:21000000000 forKey:@"当前体力"];
    [defaults setInteger:21000000000 forKey:@"玩家体力"];
    
    [defaults synchronize];
    writeLog(@"无限体力已开启");
}

// 无限心情功能
static void enableInfiniteMood(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 启用实时Hook
    g_infiniteMoodEnabled = YES;
    writeLog(@"🎯 启用心情实时Hook");
    
    // 游戏存档已在现金函数中处理，这里只处理NSUserDefaults
    [defaults setInteger:1000000 forKey:@"mood"];
    [defaults setInteger:1000000 forKey:@"happiness"];
    [defaults setInteger:1000000 forKey:@"心情"];
    
    // 尝试一些可能的字段名
    [defaults setInteger:1000000 forKey:@"Mood"];
    [defaults setInteger:1000000 forKey:@"Happiness"];
    [defaults setInteger:1000000 forKey:@"userMood"];
    [defaults setInteger:1000000 forKey:@"playerMood"];
    [defaults setInteger:1000000 forKey:@"gameMood"];
    [defaults setInteger:1000000 forKey:@"当前心情"];
    [defaults setInteger:1000000 forKey:@"玩家心情"];
    
    [defaults synchronize];
    writeLog(@"无限心情已开启");
}

// 一键全开功能
static void enableAllFeatures(void) {
    enableInfiniteCash();
    enableInfiniteEnergy();
    enableInfiniteHealth();
    enableInfiniteMood();
    
    // 额外的通用字段
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 经验和等级
    [defaults setInteger:999999999 forKey:@"exp"];
    [defaults setInteger:999999999 forKey:@"experience"];
    [defaults setInteger:100 forKey:@"level"];
    [defaults setInteger:100 forKey:@"等级"];
    
    // 积分和声望
    [defaults setInteger:999999999 forKey:@"score"];
    [defaults setInteger:999999999 forKey:@"point"];
    [defaults setInteger:999999999 forKey:@"points"];
    [defaults setInteger:999999999 forKey:@"积分"];
    
    [defaults synchronize];
    writeLog(@"一键全开已启用");
}
#pragma mark - 菜单视图

@interface WDZMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation WDZMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 420;
    CGFloat contentWidth = 280;
    CGFloat viewWidth = self.bounds.size.width;
    CGFloat viewHeight = self.bounds.size.height;
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(
        (viewWidth - contentWidth) / 2,
        (viewHeight - contentHeight) / 2,
        contentWidth, contentHeight
    )];
    self.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95];
    self.contentView.layer.cornerRadius = 16;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:self.contentView];
    
    // 关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(contentWidth - 40, 0, 40, 40);
    closeButton.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    closeButton.layer.cornerRadius = 20;
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [closeButton addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:closeButton];
    
    // 标题
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, contentWidth - 60, 30)];
    title.text = @"🏠 我独自生活";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 学习提示
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"🎮 资源仅供学习使用";
    info.font = [UIFont systemFontOfSize:14];
    info.textColor = [UIColor grayColor];
    info.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:info];
    y += 30;
    
    // 免责声明
    UITextView *disclaimer = [[UITextView alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 60)];
    disclaimer.text = @"免责声明：本工具仅供技术研究与学习，严禁用于商业用途及非法途径。使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。严禁倒卖、传播或用于牟利，否则后果自负。继续使用即表示您已阅读并同意本声明。";
    disclaimer.font = [UIFont systemFontOfSize:12];
    disclaimer.textColor = [UIColor lightGrayColor];
    disclaimer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    disclaimer.layer.cornerRadius = 8;
    disclaimer.editable = NO;
    disclaimer.scrollEnabled = YES;  // 启用滚动
    disclaimer.showsVerticalScrollIndicator = YES;  // 显示滚动条
    [self.contentView addSubview:disclaimer];
    y += 70;
    
    // 提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 40)];
    tip.text = @"修改后进行一次消费来刷新数值\n⚠️ 请勿关闭游戏，否则修改失效";
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    tip.numberOfLines = 2;
    [self.contentView addSubview:tip];
    y += 48;
    
    // 按钮
    UIButton *btn1 = [self createButtonWithTitle:@"💰 无限现金" tag:1];
    btn1.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn1];
    y += 43;
    
    UIButton *btn2 = [self createButtonWithTitle:@"⚡ 无限体力" tag:2];
    btn2.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn2];
    y += 43;
    
    UIButton *btn3 = [self createButtonWithTitle:@"❤️ 无限健康" tag:3];
    btn3.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn3];
    y += 43;
    
    UIButton *btn4 = [self createButtonWithTitle:@"😊 无限心情" tag:4];
    btn4.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn4];
    y += 43;
    
    UIButton *btn5 = [self createButtonWithTitle:@"🎁 一键全开" tag:5];
    btn5.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn5];
    y += 48;
    
    // 版权
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    copyright.text = getCopyrightText();
    copyright.font = [UIFont systemFontOfSize:12];
    copyright.textColor = [UIColor lightGrayColor];
    copyright.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:copyright];
}

- (void)closeMenu {
    [self removeFromSuperview];
    g_menuView = nil;
}

- (UIButton *)createButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    // 确认提示
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"⚠️ 确认修改" 
        message:@"修改后请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效\n\n确认继续？" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performModification:sender.tag];
    }]];
    
    UIViewController *rootVC = getKeyWindow().rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:confirmAlert animated:YES completion:nil];
}

- (void)performModification:(NSInteger)tag {
    
    BOOL success = YES;
    NSString *message = @"";
    
    writeLog(@"========== 开始修改 ==========");
    
    switch (tag) {
        case 1:
            writeLog(@"功能：无限现金");
            enableInfiniteCash();
            message = @"💰 无限现金开启成功！\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效";
            break;
        case 2:
            writeLog(@"功能：无限体力");
            enableInfiniteEnergy();
            message = @"⚡ 无限体力开启成功！\n\n请进行一次消费操作来刷新数值\n（如使用体力、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效";
            break;
        case 3:
            writeLog(@"功能：无限健康");
            enableInfiniteHealth();
            message = @"❤️ 无限健康开启成功！\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效";
            break;
        case 4:
            writeLog(@"功能：无限心情");
            enableInfiniteMood();
            message = @"😊 无限心情开启成功！\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效";
            break;
        case 5:
            writeLog(@"功能：一键全开");
            enableAllFeatures();
            message = @"🎁 一键全开成功！\n💰 现金、⚡ 体力、❤️ 健康、😊 心情已修改\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效";
            break;
    }
    
    writeLog(@"========== 修改结束 ==========\n");
    
    // 显示成功提示，不关闭游戏
    [self showAlert:message];
    
    // 关闭菜单
    [self closeMenu];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *rootVC = getKeyWindow().rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint loc = [touch locationInView:self];
    if (![self.contentView pointInside:[self.contentView convertPoint:loc fromView:self] withEvent:event]) {
        [self removeFromSuperview];
        g_menuView = nil;
    }
}
@end

#pragma mark - 悬浮按钮

static UIWindow* getKeyWindow(void) {
    UIWindow *keyWindow = nil;
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    return keyWindow;
}

static void showMenu(void) {
    if (g_menuView) {
        [g_menuView removeFromSuperview];
        g_menuView = nil;
        return;
    }
    
    UIWindow *keyWindow = getKeyWindow();
    if (!keyWindow) return;
    
    CGRect windowBounds = keyWindow.bounds;
    g_menuView = [[WDZMenuView alloc] initWithFrame:windowBounds];
    g_menuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [keyWindow addSubview:g_menuView];
}

// 处理悬浮按钮点击（首次检查免责声明）
static void handleFloatButtonTap(void) {
    if (!hasAgreedToDisclaimer()) {
        // 首次使用，显示免责声明
        showDisclaimerAlert();
    } else {
        // 已同意，直接显示功能菜单
        showMenu();
    }
}

static void handlePan(UIPanGestureRecognizer *pan) {
    UIWindow *keyWindow = getKeyWindow();
    if (!keyWindow || !g_floatButton) return;
    
    CGPoint translation = [pan translationInView:keyWindow];
    CGRect frame = g_floatButton.frame;
    frame.origin.x += translation.x;
    frame.origin.y += translation.y;
    
    CGFloat sw = keyWindow.bounds.size.width;
    CGFloat sh = keyWindow.bounds.size.height;
    frame.origin.x = MAX(0, MIN(frame.origin.x, sw - 50));
    frame.origin.y = MAX(50, MIN(frame.origin.y, sh - 100));
    
    g_floatButton.frame = frame;
    [pan setTranslation:CGPointZero inView:keyWindow];
}

static void loadIconImage(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:getIconURL()];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:data];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (image && g_floatButton) {
                [g_floatButton setTitle:@"" forState:UIControlStateNormal];
                [g_floatButton setBackgroundImage:image forState:UIControlStateNormal];
                g_floatButton.clipsToBounds = YES;
            }
        });
    });
}

static void setupFloatingButton(void) {
    if (g_floatButton) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = getKeyWindow();
        if (!keyWindow) return;
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(20, 100, 50, 50);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"虎" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(wdz_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(wdz_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
        
        loadIconImage();
    });
}

@implementation NSValue (WDZCheat)
+ (void)wdz_showMenu { handleFloatButtonTap(); }
+ (void)wdz_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void WDZCheatInit(void) {
    @autoreleasepool {
        @try {
            writeLog(@"🚀 我独自生活修改器开始加载...");
            
            // 延迟安装Hook，避免过早Hook导致闪退
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @try {
                    installHooks();
                    writeLog(@"✅ Hook已延迟安装");
                } @catch (NSException *exception) {
                    writeLog([NSString stringWithFormat:@"❌ Hook安装失败: %@", exception.reason]);
                }
            });
            
            // 延迟设置悬浮按钮
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    setupFloatingButton();
                } @catch (NSException *exception) {
                    writeLog([NSString stringWithFormat:@"❌ 悬浮按钮设置失败: %@", exception.reason]);
                }
            });
            
            writeLog(@"✅ 修改器加载完成（延迟初始化模式）");
            
        } @catch (NSException *exception) {
            NSLog(@"[WDZ] 构造函数异常: %@", exception.reason);
        }
    }
}