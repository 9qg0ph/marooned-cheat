// Gear Defenders 修改器 - GearDefendersCheat.m
// 使用 GameForFun.dylib 的修改器
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 全局变量

@class GDMenuView;
static UIButton *g_floatButton = nil;
static GDMenuView *g_menuView = nil;

#pragma mark - 函数前向声明

static void showMenu(void);
static void hideMenu(void);

#pragma mark - 日志功能

static void writeLog(NSString *message) {
    NSLog(@"%@", message);
    
    @try {
        NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *logPath = [docPath stringByAppendingPathComponent:@"GDCheat_Log.txt"];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
        NSString *timestamp = [formatter stringFromDate:[NSDate date]];
        
        NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:logPath]) {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        } else {
            [logMessage writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    } @catch (NSException *exception) {
        NSLog(@"[GDCheat] 写入日志失败: %@", exception);
    }
}

#pragma mark - GameForFun 引擎接口

// 保存捕获到的真实 engine 实例
static id g_realEngine = nil;

// 主动查找 FanhanGGEngine 实例
static void findFanhanGGEngineInstance(void) {
    if (g_realEngine) return;
    
    Class FanhanGGEngine = NSClassFromString(@"FanhanGGEngine");
    if (!FanhanGGEngine) {
        writeLog(@"[GDCheat] ❌ FanhanGGEngine 类不存在");
        return;
    }
    
    writeLog(@"[GDCheat] ✅ 找到 FanhanGGEngine 类，开始查找实例...");
    
    // 尝试常见的单例方法
    NSArray *singletonSelectors = @[@"sharedInstance", @"shared", @"defaultManager", @"instance", @"sharedEngine"];
    for (NSString *selectorName in singletonSelectors) {
        SEL selector = NSSelectorFromString(selectorName);
        if ([FanhanGGEngine respondsToSelector:selector]) {
            @try {
                id instance = [FanhanGGEngine performSelector:selector];
                if (instance) {
                    g_realEngine = instance;
                    writeLog([NSString stringWithFormat:@"[GDCheat] ✅ 通过 %@ 找到实例: %@", selectorName, instance]);
                    return;
                }
            } @catch (NSException *e) {
                writeLog([NSString stringWithFormat:@"[GDCheat] 尝试 %@ 失败: %@", selectorName, e]);
            }
        }
    }
    
    // 如果单例方法都失败，尝试创建新实例
    @try {
        g_realEngine = [[FanhanGGEngine alloc] init];
        if (g_realEngine) {
            writeLog([NSString stringWithFormat:@"[GDCheat] ✅ 创建新实例: %@", g_realEngine]);
        }
    } @catch (NSException *e) {
        writeLog([NSString stringWithFormat:@"[GDCheat] ❌ 创建实例失败: %@", e]);
    }
}

// Hook FanhanGGEngine 的 setValue 方法来捕获真实实例
static void hookFanhanGGEngine(void) {
    static BOOL hooked = NO;
    if (hooked) return;
    
    Class FanhanGGEngine = NSClassFromString(@"FanhanGGEngine");
    if (!FanhanGGEngine) {
        writeLog(@"[GDCheat] ❌ FanhanGGEngine 类不存在");
        return;
    }
    
    writeLog(@"[GDCheat] ✅ 找到 FanhanGGEngine 类");
    
    // Hook setValue:forKey:withType: 方法来捕获实例
    SEL selector = NSSelectorFromString(@"setValue:forKey:withType:");
    Method originalMethod = class_getInstanceMethod(FanhanGGEngine, selector);
    
    if (originalMethod) {
        IMP originalIMP = method_getImplementation(originalMethod);
        
        // 创建新的实现
        IMP newIMP = imp_implementationWithBlock(^(id self, id value, NSString *key, NSString *type) {
            // 保存真实的 engine 实例
            if (!g_realEngine) {
                g_realEngine = self;
                writeLog([NSString stringWithFormat:@"[GDCheat] ✅ 通过 hook 捕获到真实 engine 实例: %@", self]);
            }
            
            // 调用原始方法
            ((void (*)(id, SEL, id, NSString *, NSString *))originalIMP)(self, selector, value, key, type);
        });
        
        method_setImplementation(originalMethod, newIMP);
        writeLog(@"[GDCheat] ✅ 已 hook setValue:forKey:withType:");
        hooked = YES;
    } else {
        writeLog(@"[GDCheat] ❌ 未找到 setValue:forKey:withType: 方法");
    }
}

// 使用捕获到的真实 engine 实例调用 setValue
static void setGameValue(NSString *key, id value, NSString *type) {
    writeLog([NSString stringWithFormat:@"[GDCheat] 调用 setValue: key=%@ value=%@ type=%@", key, value, type]);
    
    // 确保已经 hook
    hookFanhanGGEngine();
    
    // 主动查找实例
    if (!g_realEngine) {
        writeLog(@"[GDCheat] 尚未获取到 engine 实例，主动查找...");
        findFanhanGGEngineInstance();
    }
    
    if (!g_realEngine) {
        writeLog(@"[GDCheat] ❌ 无法获取 engine 实例");
        return;
    }
    
    // 使用真实实例调用 setValue
    SEL selector = NSSelectorFromString(@"setValue:forKey:withType:");
    if ([g_realEngine respondsToSelector:selector]) {
        NSMethodSignature *signature = [g_realEngine methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:g_realEngine];
        [invocation setSelector:selector];
        [invocation setArgument:&value atIndex:2];
        [invocation setArgument:&key atIndex:3];
        [invocation setArgument:&type atIndex:4];
        [invocation invoke];
        
        writeLog(@"[GDCheat] ✅ setValue 调用成功");
    } else {
        writeLog(@"[GDCheat] ❌ engine 不响应 setValue:forKey:withType:");
    }
}

#pragma mark - 菜单视图

@interface GDMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation GDMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        
        // 点击背景关闭
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)];
        [self addGestureRecognizer:tap];
        
        [self setupContentView];
    }
    return self;
}

- (void)setupContentView {
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 400)];
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.contentView.layer.cornerRadius = 15;
    self.contentView.center = self.center;
    [self addSubview:self.contentView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 300, 30)];
    titleLabel.text = @"⚙️ Gear Defenders 修改器";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.contentView addSubview:titleLabel];
    
    // 功能开关
    CGFloat yOffset = 70;
    [self addSwitchWithTitle:@"💰 无限货币" tag:1 yOffset:yOffset];
    yOffset += 60;
    [self addSwitchWithTitle:@"🛡️ 无敌-开局前开启" tag:2 yOffset:yOffset];
    yOffset += 60;
    [self addSwitchWithTitle:@"💎 无限银币-开局前开启" tag:3 yOffset:yOffset];
    yOffset += 60;
    [self addSwitchWithTitle:@"⚔️ 英雄互秒" tag:4 yOffset:yOffset];
    
    // 关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.frame = CGRectMake(100, 350, 100, 40);
    [closeButton setTitle:@"关闭" forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:closeButton];
}

- (void)addSwitchWithTitle:(NSString *)title tag:(NSInteger)tag yOffset:(CGFloat)yOffset {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, yOffset, 200, 30)];
    label.text = title;
    label.font = [UIFont systemFontOfSize:16];
    [self.contentView addSubview:label];
    
    UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(220, yOffset, 60, 30)];
    switchControl.tag = tag;
    [switchControl addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    // 恢复开关状态
    NSString *stateKey = [NSString stringWithFormat:@"GDCheat_Switch_%ld", (long)tag];
    BOOL savedState = [[NSUserDefaults standardUserDefaults] boolForKey:stateKey];
    switchControl.on = savedState;
    
    [self.contentView addSubview:switchControl];
}

- (void)switchChanged:(UISwitch *)sender {
    BOOL isOn = sender.isOn;
    writeLog([NSString stringWithFormat:@"[GDCheat] 开关切换 - tag:%ld 状态:%@", (long)sender.tag, isOn ? @"开启" : @"关闭"]);
    
    // 保存开关状态
    NSString *stateKey = [NSString stringWithFormat:@"GDCheat_Switch_%ld", (long)sender.tag];
    [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:stateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    switch (sender.tag) {
        case 1: // 无限货币
            @try {
                if (isOn) {
                    writeLog(@"[GDCheat] 无限货币 - 开启");
                    setGameValue(@"hook_int", @999999999, nil);
                    [self showAlert:@"💰 无限货币已开启！\n日志: Documents/GDCheat_Log.txt"];
                } else {
                    writeLog(@"[GDCheat] 无限货币 - 关闭");
                    setGameValue(@"hook_int", @0, nil);
                    [self showAlert:@"💰 无限货币已关闭！"];
                }
            } @catch (NSException *exception) {
                writeLog([NSString stringWithFormat:@"[GDCheat] 无限货币异常: %@", exception]);
                sender.on = !isOn;
                [[NSUserDefaults standardUserDefaults] setBool:!isOn forKey:stateKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self showAlert:[NSString stringWithFormat:@"❌ 操作失败: %@", exception.reason]];
            }
            break;
        case 2: // 无敌
            @try {
                if (isOn) {
                    writeLog(@"[GDCheat] 无敌 - 开启");
                    setGameValue(@"hook_int", @999999999, nil);
                    [self showAlert:@"🛡️ 无敌已开启！\n请在开局前开启"];
                } else {
                    writeLog(@"[GDCheat] 无敌 - 关闭");
                    setGameValue(@"hook_int", @0, nil);
                    [self showAlert:@"🛡️ 无敌已关闭！"];
                }
            } @catch (NSException *exception) {
                writeLog([NSString stringWithFormat:@"[GDCheat] 无敌异常: %@", exception]);
                sender.on = !isOn;
                [[NSUserDefaults standardUserDefaults] setBool:!isOn forKey:stateKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self showAlert:[NSString stringWithFormat:@"❌ 操作失败: %@", exception.reason]];
            }
            break;
        case 3: // 无限银币
            @try {
                if (isOn) {
                    writeLog(@"[GDCheat] 无限银币 - 开启");
                    setGameValue(@"hook_int", @999999999, nil);
                    [self showAlert:@"💎 无限银币已开启！\n请在开局前开启"];
                } else {
                    writeLog(@"[GDCheat] 无限银币 - 关闭");
                    setGameValue(@"hook_int", @0, nil);
                    [self showAlert:@"💎 无限银币已关闭！"];
                }
            } @catch (NSException *exception) {
                writeLog([NSString stringWithFormat:@"[GDCheat] 无限银币异常: %@", exception]);
                sender.on = !isOn;
                [[NSUserDefaults standardUserDefaults] setBool:!isOn forKey:stateKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self showAlert:[NSString stringWithFormat:@"❌ 操作失败: %@", exception.reason]];
            }
            break;
        case 4: // 英雄互秒
            @try {
                if (isOn) {
                    writeLog(@"[GDCheat] 英雄互秒 - 开启");
                    setGameValue(@"hook_float", @9000000000, nil);
                    [self showAlert:@"⚔️ 英雄互秒已开启！"];
                } else {
                    writeLog(@"[GDCheat] 英雄互秒 - 关闭");
                    setGameValue(@"hook_float", @1, nil);
                    [self showAlert:@"⚔️ 英雄互秒已关闭！"];
                }
            } @catch (NSException *exception) {
                writeLog([NSString stringWithFormat:@"[GDCheat] 英雄互秒异常: %@", exception]);
                sender.on = !isOn;
                [[NSUserDefaults standardUserDefaults] setBool:!isOn forKey:stateKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self showAlert:[NSString stringWithFormat:@"❌ 操作失败: %@", exception.reason]];
            }
            break;
    }
}

- (void)showAlert:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Gear Defenders 修改器"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }
        [rootVC presentViewController:alert animated:YES completion:nil];
    });
}

- (void)show {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.frame = window.bounds;
    [window addSubview:self];
    self.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end

#pragma mark - 悬浮按钮

static void showMenu(void) {
    if (!g_menuView) {
        g_menuView = [[GDMenuView alloc] initWithFrame:CGRectZero];
    }
    [g_menuView show];
}

static void hideMenu(void) {
    if (g_menuView) {
        [g_menuView hide];
    }
}

static void createFloatButton(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_floatButton) return;
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(window.bounds.size.width - 70, 100, 60, 60);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
        g_floatButton.layer.cornerRadius = 30;
        g_floatButton.layer.shadowColor = [UIColor blackColor].CGColor;
        g_floatButton.layer.shadowOffset = CGSizeMake(0, 2);
        g_floatButton.layer.shadowOpacity = 0.5;
        g_floatButton.layer.shadowRadius = 4;
        
        [g_floatButton setTitle:@"⚙️" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:30];
        
        [g_floatButton addTarget:g_floatButton action:@selector(buttonClicked) forControlEvents:UIControlEventTouchUpInside];
        
        // 添加拖动手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:g_floatButton action:@selector(handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [window addSubview:g_floatButton];
        
        writeLog(@"[GDCheat] ✅ 悬浮按钮已创建");
    });
}

@implementation UIButton (GDCheat)

- (void)buttonClicked {
    showMenu();
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGRect bounds = self.superview.bounds;
        CGPoint center = self.center;
        
        if (center.x < bounds.size.width / 2) {
            center.x = 40;
        } else {
            center.x = bounds.size.width - 40;
        }
        
        center.y = MAX(40, MIN(center.y, bounds.size.height - 40));
        
        [UIView animateWithDuration:0.3 animations:^{
            self.center = center;
        }];
    }
}

@end

#pragma mark - 初始化

__attribute__((constructor)) static void initialize(void) {
    writeLog(@"[GDCheat] ========================================");
    writeLog(@"[GDCheat] Gear Defenders 修改器已加载");
    writeLog(@"[GDCheat] ========================================");
    
    // Hook FanhanGGEngine
    hookFanhanGGEngine();
    
    // 延迟创建悬浮按钮
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        createFloatButton();
    });
}
