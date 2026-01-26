// 骷髅少女修改器 - SkullgirlsCheat.m
// 使用 GameForFun.dylib 的修改器
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 全局变量

@class SGMenuView;
static UIButton *g_floatButton = nil;
static SGMenuView *g_menuView = nil;

#pragma mark - 函数前向声明

static void showMenu(void);
static void writeLog(NSString *message);

#pragma mark - 版权保护

// 解密版权字符串（防止二进制修改）
static NSString* getCopyrightText(void) {
    NSString *part1 = @"©";
    NSString *part2 = @" 2026";
    NSString *part3 = @"  ";
    NSString *part4 = @"𝐈𝐎𝐒𝐃𝐊";
    NSString *part5 = @" 科技虎";
    
    return [NSString stringWithFormat:@"%@%@%@%@%@", part1, part2, part3, part4, part5];
}

#pragma mark - 免责声明管理

// 检查是否已同意免责声明
static BOOL hasAgreedToDisclaimer(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"SGCheat_DisclaimerAgreed"];
}

// 保存免责声明同意状态
static void setDisclaimerAgreed(BOOL agreed) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:agreed forKey:@"SGCheat_DisclaimerAgreed"];
    [defaults synchronize];
}

// 显示免责声明弹窗
static void showDisclaimerAlert(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"⚠️ 免责声明" 
        message:@"本工具仅供技术研究与学习，严禁用于商业用途及非法途径。\n\n使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。\n\n严禁倒卖、传播或用于牟利，否则后果自负。\n\n继续使用即表示您已阅读并同意本声明。\n\n是否同意并继续使用？" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"不同意" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        exit(0);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        setDisclaimerAgreed(YES);
        showMenu();
    }]];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 日志系统

static NSString* getLogFilePath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    return [documentsDirectory stringByAppendingPathComponent:@"SGCheat_Log.txt"];
}

static void writeLog(NSString *message) {
    NSLog(@"%@", message);
    @try {
        NSString *logPath = getLogFilePath();
        NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                             dateStyle:NSDateFormatterShortStyle
                                                             timeStyle:NSDateFormatterMediumStyle];
        NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        } else {
            [logMessage writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    } @catch (NSException *exception) {
        NSLog(@"[SGCheat] 写入日志失败: %@", exception);
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
        writeLog(@"[SGCheat] ❌ FanhanGGEngine 类不存在");
        return;
    }
    
    writeLog(@"[SGCheat] ✅ 找到 FanhanGGEngine 类，开始查找实例...");
    
    // 尝试常见的单例方法
    NSArray *singletonSelectors = @[@"sharedInstance", @"shared", @"defaultManager", @"instance", @"sharedEngine"];
    for (NSString *selectorName in singletonSelectors) {
        SEL selector = NSSelectorFromString(selectorName);
        if ([FanhanGGEngine respondsToSelector:selector]) {
            @try {
                id instance = [FanhanGGEngine performSelector:selector];
                if (instance) {
                    g_realEngine = instance;
                    writeLog([NSString stringWithFormat:@"[SGCheat] ✅ 通过 %@ 找到实例: %@", selectorName, instance]);
                    return;
                }
            } @catch (NSException *e) {
                writeLog([NSString stringWithFormat:@"[SGCheat] 尝试 %@ 失败: %@", selectorName, e]);
            }
        }
    }
    
    // 如果单例方法都失败，尝试创建新实例
    @try {
        g_realEngine = [[FanhanGGEngine alloc] init];
        if (g_realEngine) {
            writeLog([NSString stringWithFormat:@"[SGCheat] ✅ 创建新实例: %@", g_realEngine]);
        }
    } @catch (NSException *e) {
        writeLog([NSString stringWithFormat:@"[SGCheat] ❌ 创建实例失败: %@", e]);
    }
}

// Hook FanhanGGEngine 的 setValue 方法来捕获真实实例
static void hookFanhanGGEngine(void) {
    static BOOL hooked = NO;
    if (hooked) return;
    
    Class FanhanGGEngine = NSClassFromString(@"FanhanGGEngine");
    if (!FanhanGGEngine) {
        writeLog(@"[SGCheat] ❌ FanhanGGEngine 类不存在");
        return;
    }
    
    writeLog(@"[SGCheat] ✅ 找到 FanhanGGEngine 类");
    
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
                writeLog([NSString stringWithFormat:@"[SGCheat] ✅ 通过 hook 捕获到真实 engine 实例: %@", self]);
            }
            
            // 调用原始方法
            ((void (*)(id, SEL, id, NSString *, NSString *))originalIMP)(self, selector, value, key, type);
        });
        
        method_setImplementation(originalMethod, newIMP);
        writeLog(@"[SGCheat] ✅ 已 hook setValue:forKey:withType:");
        hooked = YES;
    } else {
        writeLog(@"[SGCheat] ❌ 未找到 setValue:forKey:withType: 方法");
    }
}

// 使用捕获到的真实 engine 实例调用 setValue
static void setGameValue(NSString *key, id value, NSString *type) {
    writeLog([NSString stringWithFormat:@"[SGCheat] 调用 setValue: key=%@ value=%@ type=%@", key, value, type]);
    
    // 确保已经 hook
    hookFanhanGGEngine();
    
    // 主动查找实例
    if (!g_realEngine) {
        writeLog(@"[SGCheat] 尚未获取到 engine 实例，主动查找...");
        findFanhanGGEngineInstance();
    }
    
    if (!g_realEngine) {
        writeLog(@"[SGCheat] ❌ 无法获取 engine 实例");
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
        
        writeLog(@"[SGCheat] ✅ setValue 调用成功");
    } else {
        writeLog(@"[SGCheat] ❌ engine 不响应 setValue:forKey:withType:");
    }
}

#pragma mark - 菜单视图

@interface SGMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation SGMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 280;
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
    title.text = @"💀 骷髅少女";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.4 alpha:1];
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
    disclaimer.text = @"免责声明：本工具仅供技术研究与学习，严禁用于商业用途及非法途径。使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。严禁倒卖、传播或用于牟利，否则后果自负。";
    disclaimer.font = [UIFont systemFontOfSize:12];
    disclaimer.textColor = [UIColor lightGrayColor];
    disclaimer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    disclaimer.layer.cornerRadius = 8;
    disclaimer.editable = NO;
    disclaimer.scrollEnabled = YES;
    disclaimer.showsVerticalScrollIndicator = YES;
    [self.contentView addSubview:disclaimer];
    y += 70;
    
    // 提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    tip.text = @"注意：无敌功能暂未捕获到参数";
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.4 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:tip];
    y += 28;
    
    // 功能开关
    [self addSwitchWithTitle:@"⚔️ 互秒" tag:1 y:y];
    y += 50;
    
    [self addSwitchWithTitle:@"🛡️ 无敌（未实现）" tag:2 y:y enabled:NO];
    y += 50;
    
    // 版权
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    copyright.text = @"© 2026 IOSDK 科技虎";
    copyright.font = [UIFont systemFontOfSize:12];
    copyright.textColor = [UIColor lightGrayColor];
    copyright.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:copyright];
}

- (void)closeMenu {
    [self removeFromSuperview];
    g_menuView = nil;
}

- (void)addSwitchWithTitle:(NSString *)title tag:(NSInteger)tag y:(CGFloat)y {
    [self addSwitchWithTitle:title tag:tag y:y enabled:YES];
}

- (void)addSwitchWithTitle:(NSString *)title tag:(NSInteger)tag y:(CGFloat)y enabled:(BOOL)enabled {
    CGFloat contentWidth = self.contentView.frame.size.width;
    
    // 标签
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 100, 40)];
    label.text = title;
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    label.textColor = [UIColor darkGrayColor];
    [self.contentView addSubview:label];
    
    // 开关
    UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(contentWidth - 70, y + 5, 50, 30)];
    switchControl.tag = tag;
    switchControl.enabled = enabled;
    switchControl.onTintColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.4 alpha:1];
    
    // 恢复保存的开关状态
    NSString *key = [NSString stringWithFormat:@"SGCheat_Switch_%ld", (long)tag];
    BOOL savedState = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    switchControl.on = savedState;
    
    [switchControl addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:switchControl];
}

- (void)switchChanged:(UISwitch *)sender {
    BOOL isOn = sender.isOn;
    
    writeLog([NSString stringWithFormat:@"[SGCheat] 开关切换 - tag:%ld 状态:%@", (long)sender.tag, isOn ? @"开启" : @"关闭"]);
    
    // 保存开关状态
    NSString *stateKey = [NSString stringWithFormat:@"SGCheat_Switch_%ld", (long)sender.tag];
    [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:stateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    switch (sender.tag) {
        case 1: // 互秒
            @try {
                if (isOn) {
                    writeLog(@"[SGCheat] 互秒开关 - 开启");
                    
                    // 使用 Frida 捕获到的参数
                    setGameValue(@"hook_int", @999999999, nil);
                    
                    [self showAlert:@"⚔️ 互秒已开启！\n使用参数: hook_int=999999999\n日志: Documents/SGCheat_Log.txt\n请进入战斗测试"];
                } else {
                    writeLog(@"[SGCheat] 互秒开关 - 关闭");
                    setGameValue(@"hook_int", @1, nil);
                    [self showAlert:@"⚔️ 互秒已关闭！"];
                }
            } @catch (NSException *exception) {
                writeLog([NSString stringWithFormat:@"[SGCheat] 互秒开关异常: %@", exception]);
                sender.on = !isOn;
                [[NSUserDefaults standardUserDefaults] setBool:!isOn forKey:stateKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self showAlert:[NSString stringWithFormat:@"❌ 操作失败: %@", exception.reason]];
            }
            break;
        case 2: // 无敌
            @try {
                if (isOn) {
                    writeLog(@"[SGCheat] 无敌开关 - 开启");
                    // 无敌功能的参数还未捕获
                    [self showAlert:@"🛡️ 无敌功能暂未实现\n需要用 Frida 捕获参数"];
                    sender.on = NO;
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:stateKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                } else {
                    writeLog(@"[SGCheat] 无敌开关 - 关闭");
                }
            } @catch (NSException *exception) {
                writeLog([NSString stringWithFormat:@"[SGCheat] 无敌开关异常: %@", exception]);
                sender.on = !isOn;
                [[NSUserDefaults standardUserDefaults] setBool:!isOn forKey:stateKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self showAlert:[NSString stringWithFormat:@"❌ 操作失败: %@", exception.reason]];
            }
            break;
    }
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
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
    g_menuView = [[SGMenuView alloc] initWithFrame:windowBounds];
    g_menuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [keyWindow addSubview:g_menuView];
}

// 处理悬浮按钮点击（首次检查免责声明）
static void handleFloatButtonTap(void) {
    if (!hasAgreedToDisclaimer()) {
        showDisclaimerAlert();
    } else {
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
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.4 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"💀" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:28];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(sg_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(sg_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
        
        loadIconImage();
    });
}

@implementation NSValue (SGCheat)
+ (void)sg_showMenu { handleFloatButtonTap(); }
+ (void)sg_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void SGCheatInit(void) {
    @autoreleasepool {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}
