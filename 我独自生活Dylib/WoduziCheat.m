// 持久化游戏修改器 - 解决重启后数值重置问题
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 日志系统
static void persistentLog(NSString *message) {
    NSLog(@"[PersistentCheat] %@", message);
}

// 全局变量
static NSMutableDictionary *g_targetValues = nil;
static NSTimer *g_persistentTimer = nil;
static BOOL g_cheatEnabled = NO;

// 原始方法指针
static void (*original_setInteger)(id self, SEL _cmd, NSInteger value, NSString *key);
static NSInteger (*original_integerForKey)(id self, SEL _cmd, NSString *key);
static void (*original_setObject)(id self, SEL _cmd, id value, NSString *key);
static id (*original_objectForKey)(id self, SEL _cmd, NSString *key);
static BOOL (*original_synchronize)(id self, SEL _cmd);

// 目标修改数值
static void initializeTargetValues(void) {
    g_targetValues = [[NSMutableDictionary alloc] init];
    
    // 金钱相关
    g_targetValues[@"cash"] = @999999999;
    g_targetValues[@"money"] = @999999999;
    g_targetValues[@"现金"] = @999999999;
    g_targetValues[@"金钱"] = @999999999;
    g_targetValues[@"Money"] = @999999999;
    g_targetValues[@"Cash"] = @999999999;
    
    // 体力相关
    g_targetValues[@"energy"] = @100;
    g_targetValues[@"体力"] = @100;
    g_targetValues[@"Energy"] = @100;
    g_targetValues[@"stamina"] = @100;
    
    // 健康相关
    g_targetValues[@"health"] = @100;
    g_targetValues[@"健康"] = @100;
    g_targetValues[@"Health"] = @100;
    g_targetValues[@"hp"] = @100;
    
    // 心情相关
    g_targetValues[@"mood"] = @100;
    g_targetValues[@"心情"] = @100;
    g_targetValues[@"Mood"] = @100;
    g_targetValues[@"happiness"] = @100;
    
    // 饥饿相关（设为0表示不饿）
    g_targetValues[@"hunger"] = @0;
    g_targetValues[@"饥饿"] = @0;
    g_targetValues[@"Hunger"] = @0;
    g_targetValues[@"thirst"] = @0;
    
    persistentLog(@"✅ 目标数值已初始化");
}

// 检查是否是目标键
static BOOL isTargetKey(NSString *key) {
    if (!key || key.length == 0) return NO;
    
    for (NSString *targetKey in g_targetValues) {
        if ([key containsString:targetKey] || [key isEqualToString:targetKey]) {
            return YES;
        }
    }
    return NO;
}

// 获取目标值
static NSInteger getTargetValue(NSString *key) {
    for (NSString *targetKey in g_targetValues) {
        if ([key containsString:targetKey] || [key isEqualToString:targetKey]) {
            return [g_targetValues[targetKey] integerValue];
        }
    }
    return 0;
}

// Hook setInteger - 拦截并修改保存的数值
static void persistent_setInteger(id self, SEL _cmd, NSInteger value, NSString *key) {
    if (g_cheatEnabled && isTargetKey(key)) {
        NSInteger targetValue = getTargetValue(key);
        if (targetValue != 0) {
            persistentLog([NSString stringWithFormat:@"🔄 [拦截修改] %@ : %ld -> %ld", key, (long)value, (long)targetValue]);
            value = targetValue;
        }
    }
    
    // 调用原始方法
    original_setInteger(self, _cmd, value, key);
}

// Hook integerForKey - 拦截读取，返回修改后的值
static NSInteger persistent_integerForKey(id self, SEL _cmd, NSString *key) {
    NSInteger result = original_integerForKey(self, _cmd, key);
    
    if (g_cheatEnabled && isTargetKey(key)) {
        NSInteger targetValue = getTargetValue(key);
        if (targetValue != 0) {
            persistentLog([NSString stringWithFormat:@"📖 [拦截读取] %@ : %ld -> %ld", key, (long)result, (long)targetValue]);
            return targetValue;
        }
    }
    
    return result;
}

// Hook setObject - 处理对象类型的存档
static void persistent_setObject(id self, SEL _cmd, id value, NSString *key) {
    if (g_cheatEnabled && key && [key.lowercaseString containsString:@"save"]) {
        persistentLog([NSString stringWithFormat:@"💾 [存档操作] %@", key]);
    }
    
    // 调用原始方法
    original_setObject(self, _cmd, value, key);
}

// Hook synchronize - 在同步时强制写入修改值
static BOOL persistent_synchronize(id self, SEL _cmd) {
    if (g_cheatEnabled) {
        persistentLog(@"🔄 [同步拦截] 强制写入修改数值");
        
        // 在同步前强制设置所有目标值
        for (NSString *key in g_targetValues) {
            NSInteger targetValue = [g_targetValues[key] integerValue];
            [self setInteger:targetValue forKey:key];
        }
    }
    
    // 调用原始方法
    BOOL result = original_synchronize(self, _cmd);
    
    if (g_cheatEnabled) {
        persistentLog(@"✅ [同步完成] 修改数值已保存到存档");
    }
    
    return result;
}

// 定期强制修改存档
static void forceModifyUserDefaults(void) {
    @autoreleasepool {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        persistentLog(@"🔧 [定期修改] 强制写入所有目标数值");
        
        for (NSString *key in g_targetValues) {
            NSInteger targetValue = [g_targetValues[key] integerValue];
            [defaults setInteger:targetValue forKey:key];
        }
        
        [defaults synchronize];
        persistentLog(@"✅ [定期修改] 完成");
    }
}

// 启动定期任务
static void startPersistentTimer(void) {
    // 每30秒强制修改一次存档
    g_persistentTimer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                        target:[NSBlockOperation blockOperationWithBlock:^{
                                                            forceModifyUserDefaults();
                                                        }]
                                                      selector:@selector(main)
                                                      userInfo:nil
                                                       repeats:YES];
    
    persistentLog(@"⏰ 定期修改任务已启动 (每30秒)");
}

// 安装所有Hook
static void installPersistentHooks(void) {
    @try {
        Class cls = [NSUserDefaults class];
        
        // Hook setInteger:forKey:
        Method setIntegerMethod = class_getInstanceMethod(cls, @selector(setInteger:forKey:));
        if (setIntegerMethod) {
            original_setInteger = (void (*)(id, SEL, NSInteger, NSString *))method_getImplementation(setIntegerMethod);
            method_setImplementation(setIntegerMethod, (IMP)persistent_setInteger);
            persistentLog(@"✅ setInteger Hook安装成功");
        }
        
        // Hook integerForKey:
        Method integerForKeyMethod = class_getInstanceMethod(cls, @selector(integerForKey:));
        if (integerForKeyMethod) {
            original_integerForKey = (NSInteger (*)(id, SEL, NSString *))method_getImplementation(integerForKeyMethod);
            method_setImplementation(integerForKeyMethod, (IMP)persistent_integerForKey);
            persistentLog(@"✅ integerForKey Hook安装成功");
        }
        
        // Hook setObject:forKey:
        Method setObjectMethod = class_getInstanceMethod(cls, @selector(setObject:forKey:));
        if (setObjectMethod) {
            original_setObject = (void (*)(id, SEL, id, NSString *))method_getImplementation(setObjectMethod);
            method_setImplementation(setObjectMethod, (IMP)persistent_setObject);
            persistentLog(@"✅ setObject Hook安装成功");
        }
        
        // Hook synchronize
        Method synchronizeMethod = class_getInstanceMethod(cls, @selector(synchronize));
        if (synchronizeMethod) {
            original_synchronize = (BOOL (*)(id, SEL))method_getImplementation(synchronizeMethod);
            method_setImplementation(synchronizeMethod, (IMP)persistent_synchronize);
            persistentLog(@"✅ synchronize Hook安装成功");
        }
        
        persistentLog(@"🎉 所有持久化Hook安装完成");
        
    } @catch (NSException *e) {
        persistentLog([NSString stringWithFormat:@"❌ Hook安装异常: %@", e.reason]);
    }
}

// 启用修改功能
static void enablePersistentCheat(void) {
    g_cheatEnabled = YES;
    persistentLog(@"🚀 持久化修改已启用！");
    
    // 立即执行一次修改
    forceModifyUserDefaults();
    
    // 启动定期任务
    startPersistentTimer();
    
    persistentLog(@"💡 现在游戏数值将被持久化修改，重启后也不会重置");
}

// 构造函数
__attribute__((constructor))
static void PersistentCheatInit(void) {
    @autoreleasepool {
        persistentLog(@"🎮 持久化游戏修改器启动");
        persistentLog(@"💡 专门解决重启后数值重置问题");
        
        // 初始化
        initializeTargetValues();
        g_cheatEnabled = NO;
        
        // 10秒后安装Hook
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            installPersistentHooks();
            
            // 20秒后启用修改
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                enablePersistentCheat();
            });
        });
    }
}