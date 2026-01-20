// 我独自生活修改器 - 简单直接版本 v18.0
// 回到最基础的Hook方法
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 简单的全局变量
static BOOL g_hookEnabled = NO;
static NSInteger g_interceptCount = 0;

// 原始函数指针
static NSInteger (*original_integerForKey)(id, SEL, NSString*) = NULL;
static void (*original_setInteger)(id, SEL, NSInteger, NSString*) = NULL;
static float (*original_floatForKey)(id, SEL, NSString*) = NULL;
static void (*original_setFloat)(id, SEL, float, NSString*) = NULL;

// 简单日志
static void simpleLog(NSString *message) {
    NSLog(@"[SimpleCheat] %@", message);
}

// 最基础的Hook函数
static NSInteger hooked_integerForKey(id self, SEL _cmd, NSString* key) {
    NSInteger originalValue = original_integerForKey(self, _cmd, key);
    
    if (g_hookEnabled) {
        g_interceptCount++;
        simpleLog([NSString stringWithFormat:@"读取: %@ = %ld", key, (long)originalValue]);
        
        // 最简单的判断逻辑
        NSString *lowerKey = [key lowercaseString];
        
        // 如果包含金钱相关关键词，返回大数值
        if ([lowerKey containsString:@"money"] || [lowerKey containsString:@"cash"] || 
            [lowerKey containsString:@"coin"] || [lowerKey containsString:@"gold"] ||
            [lowerKey rangeOfString:@"钱"].location != NSNotFound) {
            simpleLog([NSString stringWithFormat:@"拦截金钱: %@ -> 999999999", key]);
            return 999999999;
        }
        
        // 如果包含体力相关关键词
        if ([lowerKey containsString:@"stamina"] || [lowerKey containsString:@"energy"] ||
            [lowerKey rangeOfString:@"体力"].location != NSNotFound || 
            [lowerKey rangeOfString:@"精力"].location != NSNotFound) {
            simpleLog([NSString stringWithFormat:@"拦截体力: %@ -> 999999", key]);
            return 999999;
        }
        
        // 如果是大数值（可能是金钱）
        if (originalValue >= 100 && originalValue <= 100000000) {
            simpleLog([NSString stringWithFormat:@"拦截大数值: %@ -> 999999999", key]);
            return 999999999;
        }
        
        // 如果是中等数值（可能是体力/健康/心情）
        if (originalValue >= 1 && originalValue <= 1000) {
            simpleLog([NSString stringWithFormat:@"拦截中等数值: %@ -> 999", key]);
            return 999;
        }
    }
    
    return originalValue;
}

static void hooked_setInteger(id self, SEL _cmd, NSInteger value, NSString* key) {
    if (g_hookEnabled) {
        simpleLog([NSString stringWithFormat:@"设置: %@ = %ld", key, (long)value]);
        
        NSString *lowerKey = [key lowercaseString];
        
        // 拦截设置操作
        if ([lowerKey containsString:@"money"] || [lowerKey containsString:@"cash"] ||
            [lowerKey rangeOfString:@"钱"].location != NSNotFound) {
            value = 999999999;
            simpleLog([NSString stringWithFormat:@"拦截设置金钱: %@ -> %ld", key, (long)value]);
        }
        else if ([lowerKey containsString:@"stamina"] || [lowerKey containsString:@"energy"] ||
                 [lowerKey rangeOfString:@"体力"].location != NSNotFound) {
            value = 999999;
            simpleLog([NSString stringWithFormat:@"拦截设置体力: %@ -> %ld", key, (long)value]);
        }
        else if (value >= 100 && value <= 100000000) {
            value = 999999999;  // 大数值改为更大
            simpleLog([NSString stringWithFormat:@"拦截设置大数值: %@ -> %ld", key, (long)value]);
        }
        else if (value >= 1 && value <= 1000) {
            value = 999;  // 小数值改为999
            simpleLog([NSString stringWithFormat:@"拦截设置小数值: %@ -> %ld", key, (long)value]);
        }
    }
    
    original_setInteger(self, _cmd, value, key);
}

// 启用Hook
static void enableSimpleHook(void) {
    if (g_hookEnabled) {
        simpleLog(@"Hook已经启用");
        return;
    }
    
    Method getMethod = class_getInstanceMethod([NSUserDefaults class], @selector(integerForKey:));
    Method setMethod = class_getInstanceMethod([NSUserDefaults class], @selector(setInteger:forKey:));
    
    if (getMethod && setMethod) {
        original_integerForKey = (NSInteger (*)(id, SEL, NSString*))method_getImplementation(getMethod);
        original_setInteger = (void (*)(id, SEL, NSInteger, NSString*))method_getImplementation(setMethod);
        
        method_setImplementation(getMethod, (IMP)hooked_integerForKey);
        method_setImplementation(setMethod, (IMP)hooked_setInteger);
        
        g_hookEnabled = YES;
        simpleLog(@"✅ 简单Hook启用成功");
    } else {
        simpleLog(@"❌ Hook启用失败");
    }
}

// 显示状态
static void showSimpleStatus(void) {
    simpleLog([NSString stringWithFormat:@"Hook状态: %@", g_hookEnabled ? @"启用" : @"禁用"]);
    simpleLog([NSString stringWithFormat:@"拦截次数: %ld", (long)g_interceptCount]);
}

// 简单菜单
static void showSimpleMenu(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"简单修改器 v18.0" 
        message:@"最基础的NSUserDefaults Hook\n\n选择操作：" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"启用Hook" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        enableSimpleHook();
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"查看状态" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        showSimpleStatus();
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    [rootVC presentViewController:alert animated:YES completion:nil];
}

// 悬浮按钮
static UIButton *g_simpleButton = nil;

static void setupSimpleButton(void) {
    if (g_simpleButton) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) return;
        
        g_simpleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_simpleButton.frame = CGRectMake(20, 100, 60, 40);
        g_simpleButton.backgroundColor = [UIColor redColor];
        g_simpleButton.layer.cornerRadius = 8;
        [g_simpleButton setTitle:@"Simple" forState:UIControlStateNormal];
        g_simpleButton.titleLabel.font = [UIFont systemFontOfSize:12];
        
        [g_simpleButton addTarget:g_simpleButton action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        
        [keyWindow addSubview:g_simpleButton];
    });
}

@implementation UIButton (SimpleCheat)
- (void)buttonTapped {
    showSimpleMenu();
}
@end

__attribute__((constructor))
static void SimpleCheatInit(void) {
    @autoreleasepool {
        simpleLog(@"🔧 SimpleCheat v18.0 初始化 - 最基础Hook方法");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupSimpleButton();
        });
    }
}