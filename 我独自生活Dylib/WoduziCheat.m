// 最简化窃取器 - 测试版本
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 最简单的日志
static void simpleLog(NSString *message) {
    NSLog(@"[SimpleThief] %@", message);
}

// 全局变量
static NSInteger g_captureCount = 0;

// 原始方法指针
static void (*original_setInteger)(id self, SEL _cmd, NSInteger value, NSString *key);

// 最简单的Hook
static void simple_setInteger(id self, SEL _cmd, NSInteger value, NSString *key) {
    // 只记录大数值
    if (value > 1000000) {
        g_captureCount++;
        simpleLog([NSString stringWithFormat:@"捕获到大数值修改: %@ = %ld (第%ld次)", key, (long)value, (long)g_captureCount]);
    }
    
    // 调用原始方法
    original_setInteger(self, _cmd, value, key);
}

// 安装Hook
static void installSimpleHook(void) {
    @try {
        Class cls = [NSUserDefaults class];
        Method method = class_getInstanceMethod(cls, @selector(setInteger:forKey:));
        
        if (method) {
            original_setInteger = (void (*)(id, SEL, NSInteger, NSString *))method_getImplementation(method);
            method_setImplementation(method, (IMP)simple_setInteger);
            simpleLog(@"Hook安装成功");
        } else {
            simpleLog(@"Hook安装失败 - 找不到方法");
        }
    } @catch (NSException *e) {
        simpleLog([NSString stringWithFormat:@"Hook异常: %@", e.reason]);
    }
}

// 构造函数
__attribute__((constructor))
static void SimpleThiefInit(void) {
    simpleLog(@"最简化窃取器启动");
    
    // 10秒后安装Hook
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        installSimpleHook();
        simpleLog(@"窃取器就绪，等待其他修改器操作...");
    });
}