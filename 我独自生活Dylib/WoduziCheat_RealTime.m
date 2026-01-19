//
//  WoduziCheat_RealTime.m
//  我独自生活实时Hook修改器
//  基于发现：必须保持开启状态才有效 = 实时拦截方式
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
// #import <substrate.h>  // 注释掉，使用标准的 runtime 方法

// 目标数值
static const NSInteger TARGET_CASH = 21000000000;
static const NSInteger TARGET_ENERGY = 21000000000;
static const NSInteger TARGET_HEALTH = 1000000;
static const NSInteger TARGET_MOOD = 1000000;

// 当前已知数值
static const NSInteger CURRENT_CASH = 2099999100;

// Hook状态
static BOOL isHookEnabled = YES;

// 获取主窗口的兼容方法
static UIWindow* getKeyWindow(void) {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *connectedScenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
    }
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    return keyWindow;
}

// 创建重复字符串的辅助函数
static NSString* repeatString(NSString *str, NSInteger count) {
    NSMutableString *result = [NSMutableString string];
    for (NSInteger i = 0; i < count; i++) {
        [result appendString:str];
    }
    return result;
}
static NSString* getLogPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"woduzishenghua_realtime.log"];
}

static void writeLog(NSString *message) {
    NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", 
                           [[NSDateFormatter new] stringFromDate:[NSDate date]], message];
    [logMessage writeToFile:getLogPath() 
                 atomically:YES 
                   encoding:NSUTF8StringEncoding 
                      error:nil];
    NSLog(@"%@", logMessage);
}

// 原始函数指针
static NSInteger (*original_integerForKey)(id self, SEL _cmd, NSString *key);
static id (*original_objectForKey)(id self, SEL _cmd, NSString *key);
static NSInteger (*original_intValue)(id self, SEL _cmd);
static long long (*original_longLongValue)(id self, SEL _cmd);

// Hook NSUserDefaults integerForKey
static NSInteger hooked_integerForKey(id self, SEL _cmd, NSString *key) {
    NSInteger originalValue = original_integerForKey(self, _cmd, key);
    
    if (!isHookEnabled) return originalValue;
    
    // 精确匹配当前现金数值
    if (originalValue == CURRENT_CASH) {
        writeLog([NSString stringWithFormat:@"🎯 实时拦截现金读取: %@ (原值: %ld → 新值: %ld)", 
                 key, (long)originalValue, (long)TARGET_CASH]);
        return TARGET_CASH;
    }
    
    // 范围匹配其他数值
    if (originalValue >= 1000000 && originalValue <= 10000000000) {
        writeLog([NSString stringWithFormat:@"🎯 实时拦截大数值: %@ (原值: %ld → 新值: %ld)", 
                 key, (long)originalValue, (long)TARGET_CASH]);
        return TARGET_CASH;
    }
    
    if (originalValue >= 100 && originalValue <= 1000000) {
        writeLog([NSString stringWithFormat:@"🎯 实时拦截中数值: %@ (原值: %ld → 新值: %ld)", 
                 key, (long)originalValue, (long)TARGET_HEALTH]);
        return TARGET_HEALTH;
    }
    
    return originalValue;
}

// Hook NSUserDefaults objectForKey
static id hooked_objectForKey(id self, SEL _cmd, NSString *key) {
    id originalValue = original_objectForKey(self, _cmd, key);
    
    if (!isHookEnabled || !originalValue) return originalValue;
    
    // 检查是否是NSNumber
    if ([originalValue isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)originalValue;
        NSInteger intValue = [number integerValue];
        
        // 精确匹配当前现金数值
        if (intValue == CURRENT_CASH) {
            writeLog([NSString stringWithFormat:@"🎯 实时拦截现金对象: %@ (原值: %@ → 新值: %ld)", 
                     key, originalValue, (long)TARGET_CASH]);
            return @(TARGET_CASH);
        }
        
        // 范围匹配其他数值
        if (intValue >= 1000000 && intValue <= 10000000000) {
            writeLog([NSString stringWithFormat:@"🎯 实时拦截大数值对象: %@ (原值: %@ → 新值: %ld)", 
                     key, originalValue, (long)TARGET_CASH]);
            return @(TARGET_CASH);
        }
        
        if (intValue >= 100 && intValue <= 1000000) {
            writeLog([NSString stringWithFormat:@"🎯 实时拦截中数值对象: %@ (原值: %@ → 新值: %ld)", 
                     key, originalValue, (long)TARGET_HEALTH]);
            return @(TARGET_HEALTH);
        }
    }
    
    // 检查是否是包含数值的字符串
    if ([originalValue isKindOfClass:[NSString class]]) {
        NSString *str = (NSString *)originalValue;
        if ([str containsString:@"2099999100"] || [str containsString:[NSString stringWithFormat:@"%ld", CURRENT_CASH]]) {
            NSString *newStr = [str stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%ld", CURRENT_CASH] 
                                                              withString:[NSString stringWithFormat:@"%ld", TARGET_CASH]];
            writeLog([NSString stringWithFormat:@"🎯 实时拦截字符串: %@ (原值: %@ → 新值: %@)", 
                     key, originalValue, newStr]);
            return newStr;
        }
    }
    
    return originalValue;
}

// Hook NSNumber intValue
static NSInteger hooked_intValue(id self, SEL _cmd) {
    NSInteger originalValue = original_intValue(self, _cmd);
    
    if (!isHookEnabled) return originalValue;
    
    // 精确匹配当前现金数值
    if (originalValue == CURRENT_CASH) {
        writeLog([NSString stringWithFormat:@"🎯 实时拦截NSNumber现金: %ld → %ld", 
                 (long)originalValue, (long)TARGET_CASH]);
        return TARGET_CASH;
    }
    
    // 范围匹配
    if (originalValue >= 1000000 && originalValue <= 10000000000) {
        writeLog([NSString stringWithFormat:@"🎯 实时拦截NSNumber大数值: %ld → %ld", 
                 (long)originalValue, (long)TARGET_CASH]);
        return TARGET_CASH;
    }
    
    if (originalValue >= 100 && originalValue <= 1000000) {
        writeLog([NSString stringWithFormat:@"🎯 实时拦截NSNumber中数值: %ld → %ld", 
                 (long)originalValue, (long)TARGET_HEALTH]);
        return TARGET_HEALTH;
    }
    
    return originalValue;
}

// Hook NSNumber longLongValue
static long long hooked_longLongValue(id self, SEL _cmd) {
    long long originalValue = original_longLongValue(self, _cmd);
    
    if (!isHookEnabled) return originalValue;
    
    // 精确匹配当前现金数值
    if (originalValue == CURRENT_CASH) {
        writeLog([NSString stringWithFormat:@"🎯 实时拦截NSNumber longLong现金: %lld → %ld", 
                 originalValue, (long)TARGET_CASH]);
        return TARGET_CASH;
    }
    
    // 范围匹配
    if (originalValue >= 1000000 && originalValue <= 10000000000) {
        writeLog([NSString stringWithFormat:@"🎯 实时拦截NSNumber longLong大数值: %lld → %ld", 
                 originalValue, (long)TARGET_CASH]);
        return TARGET_CASH;
    }
    
    return originalValue;
}

// 显示控制界面
static void showControlPanel() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🎮 我独自生活实时修改器"
                                                                       message:@"基于发现：必须保持开启状态才有效\n\n实时拦截所有数值读取操作\n保持dylib加载状态即可生效"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        // 开启/关闭Hook
        NSString *toggleTitle = isHookEnabled ? @"🔴 关闭Hook" : @"🟢 开启Hook";
        UIAlertAction *toggleAction = [UIAlertAction actionWithTitle:toggleTitle
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
            isHookEnabled = !isHookEnabled;
            NSString *status = isHookEnabled ? @"开启" : @"关闭";
            writeLog([NSString stringWithFormat:@"🔄 Hook状态切换为: %@", status]);
            
            UIAlertController *statusAlert = [UIAlertController alertControllerWithTitle:@"状态更新"
                                                                                 message:[NSString stringWithFormat:@"Hook已%@", status]
                                                                          preferredStyle:UIAlertControllerStyleAlert];
            [statusAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            
            UIViewController *rootVC = getKeyWindow().rootViewController;
            [rootVC presentViewController:statusAlert animated:YES completion:nil];
        }];
        
        // 查看日志
        UIAlertAction *logAction = [UIAlertAction actionWithTitle:@"📋 查看日志"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
            NSString *logContent = [NSString stringWithContentsOfFile:getLogPath() 
                                                              encoding:NSUTF8StringEncoding 
                                                                 error:nil];
            if (!logContent) logContent = @"暂无日志";
            
            // 只显示最后10行
            NSArray *lines = [logContent componentsSeparatedByString:@"\n"];
            NSInteger startIndex = MAX(0, lines.count - 10);
            NSArray *lastLines = [lines subarrayWithRange:NSMakeRange(startIndex, lines.count - startIndex)];
            NSString *recentLog = [lastLines componentsJoinedByString:@"\n"];
            
            UIAlertController *logAlert = [UIAlertController alertControllerWithTitle:@"最近日志"
                                                                              message:recentLog
                                                                       preferredStyle:UIAlertControllerStyleAlert];
            [logAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            
            UIViewController *rootVC = getKeyWindow().rootViewController;
            [rootVC presentViewController:logAlert animated:YES completion:nil];
        }];
        
        // 关闭
        UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"关闭"
                                                              style:UIAlertActionStyleCancel
                                                            handler:nil];
        
        [alert addAction:toggleAction];
        [alert addAction:logAction];
        [alert addAction:closeAction];
        
        UIViewController *rootVC = getKeyWindow().rootViewController;
        [rootVC presentViewController:alert animated:YES completion:nil];
    });
}

// 添加手势控制
static void addGestureControl() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = getKeyWindow();
        if (keyWindow) {
            // 添加三指长按手势
            UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] 
                                                    initWithTarget:nil action:nil];
            gesture.numberOfTouchesRequired = 3;
            gesture.minimumPressDuration = 2.0;
            
            // 使用block处理手势
            objc_setAssociatedObject(gesture, "handler", ^{
                showControlPanel();
            }, OBJC_ASSOCIATION_COPY_NONATOMIC);
            
            // Hook手势识别
            Method originalMethod = class_getInstanceMethod([UILongPressGestureRecognizer class], 
                                                          @selector(setState:));
            IMP originalIMP = method_getImplementation(originalMethod);
            
            IMP newIMP = imp_implementationWithBlock(^(UILongPressGestureRecognizer *self, UIGestureRecognizerState state) {
                ((void(*)(id, SEL, UIGestureRecognizerState))originalIMP)(self, @selector(setState:), state);
                
                if (state == UIGestureRecognizerStateBegan && self.numberOfTouchesRequired == 3) {
                    void (^handler)(void) = objc_getAssociatedObject(self, "handler");
                    if (handler) handler();
                }
            });
            
            method_setImplementation(originalMethod, newIMP);
            [keyWindow addGestureRecognizer:gesture];
            
            writeLog(@"✅ 手势控制已添加 (三指长按2秒打开控制面板)");
        }
    });
}

// 构造函数
__attribute__((constructor))
static void initialize() {
    writeLog(repeatString(@"=", 60));
    writeLog(@"🚀 我独自生活实时Hook修改器已加载");
    writeLog(@"💡 基于发现：必须保持开启状态才有效 = 实时拦截方式");
    writeLog(@"🎯 目标现金数值: 2099999100");
    writeLog(repeatString(@"=", 60));
    
    // Hook NSUserDefaults
    Class userDefaultsClass = [NSUserDefaults class];
    
    // Hook integerForKey:
    Method integerMethod = class_getInstanceMethod(userDefaultsClass, @selector(integerForKey:));
    if (integerMethod) {
        original_integerForKey = (NSInteger(*)(id, SEL, NSString*))method_getImplementation(integerMethod);
        method_setImplementation(integerMethod, (IMP)hooked_integerForKey);
        writeLog(@"✅ integerForKey Hook已安装");
    }
    
    // Hook objectForKey:
    Method objectMethod = class_getInstanceMethod(userDefaultsClass, @selector(objectForKey:));
    if (objectMethod) {
        original_objectForKey = (id(*)(id, SEL, NSString*))method_getImplementation(objectMethod);
        method_setImplementation(objectMethod, (IMP)hooked_objectForKey);
        writeLog(@"✅ objectForKey Hook已安装");
    }
    
    // Hook NSNumber
    Class numberClass = [NSNumber class];
    
    // Hook intValue
    Method intValueMethod = class_getInstanceMethod(numberClass, @selector(intValue));
    if (intValueMethod) {
        original_intValue = (NSInteger(*)(id, SEL))method_getImplementation(intValueMethod);
        method_setImplementation(intValueMethod, (IMP)hooked_intValue);
        writeLog(@"✅ NSNumber intValue Hook已安装");
    }
    
    // Hook longLongValue
    Method longLongMethod = class_getInstanceMethod(numberClass, @selector(longLongValue));
    if (longLongMethod) {
        original_longLongValue = (long long(*)(id, SEL))method_getImplementation(longLongMethod);
        method_setImplementation(longLongMethod, (IMP)hooked_longLongValue);
        writeLog(@"✅ NSNumber longLongValue Hook已安装");
    }
    
    // 延迟添加手势控制
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        addGestureControl();
    });
    
    // 显示启动提示
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🎮 实时修改器已启动"
                                                                       message:@"✅ 所有Hook已安装完成\n💡 现在游戏中读取数值时会被实时拦截\n🎯 三指长按2秒打开控制面板\n🔄 保持dylib加载状态即可持续生效"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"开始游戏" style:UIAlertActionStyleDefault handler:nil]];
        
        UIViewController *rootVC = getKeyWindow().rootViewController;
        [rootVC presentViewController:alert animated:YES completion:nil];
    });
    
    writeLog(@"🎉 实时Hook修改器初始化完成！");
    writeLog(@"💡 现在游戏中的数值读取都会被拦截和修改");
    writeLog(@"🔄 保持此dylib加载状态，关闭后修改失效");
}