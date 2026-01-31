#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 日志文件路径
#define LOG_FILE @"Documents/DragonCheat_Log.txt"

// 写入日志
static void writeLog(NSString *message) {
    NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:LOG_FILE];
    NSString *timestamp = [[NSDateFormatter new] stringFromDate:[NSDate date]];
    NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        [logMessage writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

// 修改游戏数据
static void modifyGameData(NSString *key, id value) {
    @try {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:value forKey:key];
        [defaults synchronize];
        writeLog([NSString stringWithFormat:@"修改成功 - Key: %@, Value: %@", key, value]);
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"修改失败 - %@", exception]);
    }
}

// 菜单视图
@interface DragonCheatView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation DragonCheatView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        writeLog(@"[DragonCheat] 菜单初始化成功");
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 450;
    CGFloat contentWidth = 300;
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
    title.text = @"🐉 不服来通关";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 提示信息
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"🎮 仅供学习研究使用";
    info.font = [UIFont systemFontOfSize:14];
    info.textColor = [UIColor grayColor];
    info.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:info];
    y += 30;
    
    // 免责声明
    UITextView *disclaimer = [[UITextView alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 80)];
    disclaimer.text = @"免责声明：本工具仅供技术研究与学习，严禁用于商业用途及非法途径。使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。继续使用即表示您已阅读并同意本声明。";
    disclaimer.font = [UIFont systemFontOfSize:11];
    disclaimer.textColor = [UIColor lightGrayColor];
    disclaimer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    disclaimer.layer.cornerRadius = 8;
    disclaimer.editable = NO;
    disclaimer.scrollEnabled = YES;
    [self.contentView addSubview:disclaimer];
    y += 90;
    
    // 功能提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    tip.text = @"修改后重启游戏生效";
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:tip];
    y += 28;
    
    // 功能按钮
    NSArray *features = @[
        @"🌟 解锁所有关卡",
        @"💎 无限分数",
        @"⭐ 三星通关",
        @"🎯 一键全开"
    ];
    
    for (int i = 0; i < features.count; i++) {
        UIButton *btn = [self createButtonWithTitle:features[i] tag:i + 1];
        btn.frame = CGRectMake(20, y, contentWidth - 40, 35);
        [self.contentView addSubview:btn];
        y += 43;
    }
    
    y += 5;
    
    // 版权信息
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    copyright.text = @"Made with ❤️ by AI Assistant";
    copyright.font = [UIFont systemFontOfSize:11];
    copyright.textColor = [UIColor lightGrayColor];
    copyright.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:copyright];
}

- (UIButton *)createButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = tag;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    button.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    button.layer.cornerRadius = 8;
    [button addTarget:self action:@selector(featureButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)featureButtonTapped:(UIButton *)sender {
    writeLog([NSString stringWithFormat:@"[DragonCheat] 功能按钮点击 - tag:%ld", (long)sender.tag]);
    
    switch (sender.tag) {
        case 1: // 解锁所有关卡
            [self unlockAllLevels];
            [self showAlert:@"🌟 已解锁所有关卡！\n请重启游戏查看效果"];
            break;
        case 2: // 无限分数
            [self setUnlimitedScore];
            [self showAlert:@"💎 已设置无限分数！\n请重启游戏查看效果"];
            break;
        case 3: // 三星通关
            [self setThreeStars];
            [self showAlert:@"⭐ 已设置三星通关！\n请重启游戏查看效果"];
            break;
        case 4: // 一键全开
            [self unlockAllLevels];
            [self setUnlimitedScore];
            [self setThreeStars];
            [self showAlert:@"🎯 已开启所有功能！\n请重启游戏查看效果"];
            break;
    }
}

- (void)unlockAllLevels {
    // 修改 rcrr 键，解锁所有关卡
    NSMutableDictionary *rcrr = [NSMutableDictionary dictionary];
    for (int i = 1; i <= 100; i++) {
        rcrr[@(i).stringValue] = @{
            @"5": @999,
            @"trtc": @999,
            @"rrd": [NSDate date]
        };
    }
    modifyGameData(@"rcrr", rcrr);
    writeLog(@"[DragonCheat] 已解锁所有关卡");
}

- (void)setUnlimitedScore {
    // 设置高分数
    NSMutableDictionary *rcrr = [[NSUserDefaults standardUserDefaults] objectForKey:@"rcrr"];
    if (!rcrr) rcrr = [NSMutableDictionary dictionary];
    
    for (NSString *key in rcrr.allKeys) {
        NSMutableDictionary *level = [rcrr[key] mutableCopy];
        level[@"5"] = @999999;
        level[@"trtc"] = @999999;
        rcrr[key] = level;
    }
    
    modifyGameData(@"rcrr", rcrr);
    writeLog(@"[DragonCheat] 已设置无限分数");
}

- (void)setThreeStars {
    // 设置三星通关
    NSMutableDictionary *rcrr = [[NSUserDefaults standardUserDefaults] objectForKey:@"rcrr"];
    if (!rcrr) rcrr = [NSMutableDictionary dictionary];
    
    for (NSString *key in rcrr.allKeys) {
        NSMutableDictionary *level = [rcrr[key] mutableCopy];
        level[@"5"] = @3;  // 假设5代表星星数
        rcrr[key] = level;
    }
    
    modifyGameData(@"rcrr", rcrr);
    writeLog(@"[DragonCheat] 已设置三星通关");
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"不服来通关" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (void)closeMenu {
    writeLog(@"[DragonCheat] 关闭菜单");
    [self removeFromSuperview];
}

@end

// 悬浮按钮
@interface DragonFloatingButton : UIButton
@end

@implementation DragonFloatingButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setTitle:@"🐉" forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:30];
        self.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.8];
        self.layer.cornerRadius = 30;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowRadius = 4;
        
        [self addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
        
        writeLog(@"[DragonCheat] 悬浮按钮初始化成功");
    }
    return self;
}

- (void)buttonTapped {
    writeLog(@"[DragonCheat] 悬浮按钮点击");
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    DragonCheatView *menuView = [[DragonCheatView alloc] initWithFrame:window.bounds];
    [window addSubview:menuView];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [gesture setTranslation:CGPointZero inView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateEnded) {
        CGRect bounds = self.superview.bounds;
        CGFloat x = self.center.x < bounds.size.width / 2 ? 40 : bounds.size.width - 40;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.center = CGPointMake(x, self.center.y);
        }];
    }
}

@end

// 入口函数
__attribute__((constructor)) static void initialize() {
    writeLog(@"[DragonCheat] Dylib 加载成功");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            DragonFloatingButton *floatingButton = [[DragonFloatingButton alloc] initWithFrame:CGRectMake(window.bounds.size.width - 80, 200, 60, 60)];
            [window addSubview:floatingButton];
            writeLog(@"[DragonCheat] 悬浮按钮已添加");
        }
    });
}
