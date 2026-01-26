// Gear Defenders 修改器 - GearDefendersCheat.m
// 完全独立的修改器，不依赖 GameForFun.dylib
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

#pragma mark - 实现 FanhanGGEngine（替代 GameForFun.dylib）

// 创建我们自己的 FanhanGGEngine 类，完全替代 GameForFun
@interface FanhanGGEngine : NSObject
+ (instancetype)sharedInstance;
- (void)setValue:(id)value forKey:(NSString *)key withType:(NSString *)type;
@end

@implementation FanhanGGEngine

static FanhanGGEngine *_sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
        writeLog(@"[GDCheat] ✅ FanhanGGEngine 单例已创建");
    });
    return _sharedInstance;
}

- (void)setValue:(id)value forKey:(NSString *)key withType:(NSString *)type {
    writeLog([NSString stringWithFormat:@"[GDCheat] setValue 被调用: key=%@ value=%@ type=%@", key, value, type]);
    
    // 直接使用 NSUserDefaults 存储，key 就是 hook_int 或 hook_float
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
    
    writeLog([NSString stringWithFormat:@"[GDCheat] ✅ 已设置 NSUserDefaults: %@ = %@", key, value]);
}

@end

// 简化的接口函数
static void setGameValue(NSString *key, id value, NSString *type) {
    [[FanhanGGEngine sharedInstance] setValue:value forKey:key withType:type];
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
    
    // 延迟创建悬浮按钮
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        createFloatButton();
    });
}
