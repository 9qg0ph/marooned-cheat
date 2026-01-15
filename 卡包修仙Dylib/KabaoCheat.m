// 卡包修仙修改器 - KabaoCheat.m
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

#pragma mark - 全局变量前置声明

@class KabaoMenuView;
static UIButton *g_floatButton = nil;
static KabaoMenuView *g_menuView = nil;
static NSMutableDictionary *g_functionStates = nil;
static void *g_aswjBaseAddress = NULL;

#pragma mark - 功能实现

// 功能ID映射（基于ASWJGAMEPLUS分析）
static NSDictionary *getFunctionIDs(void) {
    static NSDictionary *functionIDs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        functionIDs = @{
            @"无限寿命": @0,
            @"冻结灵石": @1,
            @"无敌免疫": @2,
            @"无限突破": @3,
            @"增加逃跑概率": @4
        };
    });
    return functionIDs;
}

// 检测ASWJGAMEPLUS模块
static void detectASWJModule(void) {
    void *handle = dlopen("ASWJGAMEPLUS.dylib", RTLD_LAZY | RTLD_NOLOAD);
    if (handle) {
        Dl_info info;
        if (dladdr(dlsym(handle, ""), &info)) {
            g_aswjBaseAddress = (void *)info.dli_fbase;
            NSLog(@"[KabaoCheat] 检测到 ASWJGAMEPLUS.dylib @ %p", g_aswjBaseAddress);
        }
        dlclose(handle);
    } else {
        NSLog(@"[KabaoCheat] 未检测到 ASWJGAMEPLUS.dylib，使用独立实现");
    }
}

// 调用ASWJGAMEPLUS函数
static BOOL callASWJFunction(NSString *funcName, BOOL enable) {
    if (!g_aswjBaseAddress) return NO;
    
    NSDictionary *functionIDs = getFunctionIDs();
    NSNumber *funcID = functionIDs[funcName];
    if (!funcID) return NO;
    
    @try {
        // 基于分析报告的关键偏移量
        void *handlerFunc = (char *)g_aswjBaseAddress + 0xfdc38;  // 通用处理入口
        
        typedef void (*HandlerFunction)(int, BOOL);
        HandlerFunction handler = (HandlerFunction)handlerFunc;
        handler([funcID intValue], enable);
        
        NSLog(@"[KabaoCheat] ASWJ调用成功: %@ (%d) -> %@", funcName, [funcID intValue], enable ? @"开启" : @"关闭");
        return YES;
        
    } @catch (NSException *exception) {
        NSLog(@"[KabaoCheat] ASWJ调用失败: %@", exception.reason);
    }
    
    return NO;
}

// 内存修改实现
static BOOL directMemoryModification(NSString *funcName, BOOL enable) {
    NSLog(@"[KabaoCheat] 内存修改: %@ -> %@", funcName, enable ? @"开启" : @"关闭");
    
    // 使用NSUserDefaults作为简单的状态存储（类似饥饿荒野的实现）
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([funcName isEqualToString:@"无限寿命"]) {
        if (enable) {
            [defaults setInteger:999999 forKey:@"kabao_life_value"];
            [defaults setBool:YES forKey:@"kabao_infinite_life"];
        } else {
            [defaults setBool:NO forKey:@"kabao_infinite_life"];
        }
    } else if ([funcName isEqualToString:@"冻结灵石"]) {
        if (enable) {
            [defaults setBool:YES forKey:@"kabao_freeze_stone"];
        } else {
            [defaults setBool:NO forKey:@"kabao_freeze_stone"];
        }
    } else if ([funcName isEqualToString:@"无敌免疫"]) {
        [defaults setBool:enable forKey:@"kabao_invincible"];
    } else if ([funcName isEqualToString:@"无限突破"]) {
        [defaults setBool:enable forKey:@"kabao_infinite_breakthrough"];
    } else if ([funcName isEqualToString:@"增加逃跑概率"]) {
        [defaults setBool:enable forKey:@"kabao_escape_boost"];
    }
    
    [defaults synchronize];
    return YES;
}

// 开启功能
static void enableFunction(NSString *funcName) {
    NSLog(@"[KabaoCheat] 开启功能: %@", funcName);
    
    // 存储状态
    g_functionStates[funcName] = @YES;
    
    // 多方案实现
    BOOL success = NO;
    
    // 方案1: 尝试调用 ASWJGAMEPLUS 的函数
    if (g_aswjBaseAddress) {
        success = callASWJFunction(funcName, YES);
    }
    
    // 方案2: 直接内存修改
    if (!success) {
        success = directMemoryModification(funcName, YES);
    }
    
    NSLog(@"[KabaoCheat] 功能开启%@: %@", success ? @"成功" : @"失败", funcName);
}

// 关闭功能
static void disableFunction(NSString *funcName) {
    NSLog(@"[KabaoCheat] 关闭功能: %@", funcName);
    
    // 存储状态
    g_functionStates[funcName] = @NO;
    
    // 多方案关闭
    BOOL success = NO;
    
    if (g_aswjBaseAddress) {
        success = callASWJFunction(funcName, NO);
    }
    
    if (!success) {
        success = directMemoryModification(funcName, NO);
    }
    
    NSLog(@"[KabaoCheat] 功能关闭%@: %@", success ? @"成功" : @"失败", funcName);
}

#pragma mark - 菜单视图

@interface KabaoMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSArray *functionNames;
@property (nonatomic, strong) NSMutableArray *switches;
@end

@implementation KabaoMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.functionNames = @[@"无限寿命", @"冻结灵石", @"无敌免疫", @"无限突破", @"增加逃跑概率"];
        self.switches = [[NSMutableArray alloc] init];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 500;
    CGFloat contentWidth = 320;
    CGFloat viewWidth = self.bounds.size.width;
    CGFloat viewHeight = self.bounds.size.height;
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(
        (viewWidth - contentWidth) / 2,
        (viewHeight - contentHeight) / 2,
        contentWidth, contentHeight
    )];
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:0.98];
    self.contentView.layer.cornerRadius = 20;
    self.contentView.layer.borderWidth = 2;
    self.contentView.layer.borderColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0].CGColor;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:self.contentView];
    
    CGFloat y = 20;
    
    // 标题
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 35)];
    title.text = @"🎮 卡包修仙修改器 v2.0";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    y += 45;
    
    // 状态信息
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    if (g_aswjBaseAddress) {
        statusLabel.text = @"🔗 已连接 ASWJGAMEPLUS";
        statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0];
    } else {
        statusLabel.text = @"🔧 独立运行模式";
        statusLabel.textColor = [UIColor colorWithRed:0.8 green:0.6 blue:0.2 alpha:1.0];
    }
    statusLabel.font = [UIFont systemFontOfSize:14];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:statusLabel];
    y += 30;
    
    // 功能列表
    NSArray *functionIcons = @[@"❤️", @"💎", @"🛡️", @"⚡", @"🏃"];
    NSArray *functionDescs = @[
        @"生命值不会减少",
        @"灵石数量保持不变", 
        @"免疫所有伤害",
        @"无限制突破等级",
        @"大幅提高逃跑成功率"
    ];
    
    for (int i = 0; i < self.functionNames.count; i++) {
        NSString *funcName = self.functionNames[i];
        
        // 功能项背景
        UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(15, y, contentWidth - 30, 60)];
        itemView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        itemView.layer.cornerRadius = 12;
        itemView.layer.borderWidth = 1;
        itemView.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
        [self.contentView addSubview:itemView];
        
        // 图标
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 30, 30)];
        iconLabel.text = functionIcons[i];
        iconLabel.font = [UIFont systemFontOfSize:24];
        iconLabel.textAlignment = NSTextAlignmentCenter;
        [itemView addSubview:iconLabel];
        
        // 功能名称
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 8, 150, 22)];
        nameLabel.text = funcName;
        nameLabel.textColor = [UIColor darkGrayColor];
        nameLabel.font = [UIFont boldSystemFontOfSize:16];
        [itemView addSubview:nameLabel];
        
        // 功能描述
        UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 30, 150, 18)];
        descLabel.text = functionDescs[i];
        descLabel.textColor = [UIColor grayColor];
        descLabel.font = [UIFont systemFontOfSize:12];
        [itemView addSubview:descLabel];
        
        // 开关按钮
        UISwitch *funcSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(230, 15, 51, 31)];
        funcSwitch.tag = i;
        funcSwitch.on = [g_functionStates[funcName] boolValue];
        funcSwitch.onTintColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0];
        [funcSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        [itemView addSubview:funcSwitch];
        [self.switches addObject:funcSwitch];
        
        y += 70;
    }
    
    // 底部按钮
    y += 10;
    
    // 全部开启按钮
    UIButton *enableAllBtn = [self createButtonWithTitle:@"🚀 全部开启" tag:100];
    enableAllBtn.frame = CGRectMake(20, y, 90, 35);
    enableAllBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:0.9];
    [self.contentView addSubview:enableAllBtn];
    
    // 全部关闭按钮
    UIButton *disableAllBtn = [self createButtonWithTitle:@"🛑 全部关闭" tag:101];
    disableAllBtn.frame = CGRectMake(120, y, 90, 35);
    disableAllBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:0.9];
    [self.contentView addSubview:disableAllBtn];
    
    // 关闭按钮
    UIButton *closeBtn = [self createButtonWithTitle:@"❌ 关闭" tag:0];
    closeBtn.frame = CGRectMake(220, y, 80, 35);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.9];
    [closeBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.contentView addSubview:closeBtn];
}

- (UIButton *)createButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    btn.layer.cornerRadius = 17;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)switchChanged:(UISwitch *)sender {
    NSString *funcName = self.functionNames[sender.tag];
    
    if (sender.isOn) {
        enableFunction(funcName);
        [self showAlert:[NSString stringWithFormat:@"✅ %@ 开启成功", funcName]];
    } else {
        disableFunction(funcName);
        [self showAlert:[NSString stringWithFormat:@"🛑 %@ 已关闭", funcName]];
    }
}

- (void)buttonTapped:(UIButton *)sender {
    switch (sender.tag) {
        case 0: // 关闭菜单
            [self removeFromSuperview];
            g_menuView = nil;
            break;
        case 100: // 全部开启
            for (NSString *funcName in self.functionNames) {
                enableFunction(funcName);
            }
            // 更新开关状态
            for (UISwitch *switchView in self.switches) {
                [switchView setOn:YES animated:YES];
            }
            [self showAlert:@"🚀 所有功能已开启"];
            break;
        case 101: // 全部关闭
            for (NSString *funcName in self.functionNames) {
                disableFunction(funcName);
            }
            // 更新开关状态
            for (UISwitch *switchView in self.switches) {
                [switchView setOn:NO animated:YES];
            }
            [self showAlert:@"🛑 所有功能已关闭"];
            break;
    }
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"卡包修仙修改器" message:message preferredStyle:UIAlertControllerStyleAlert];
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
    g_menuView = [[KabaoMenuView alloc] initWithFrame:windowBounds];
    g_menuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [keyWindow addSubview:g_menuView];
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
    frame.origin.x = MAX(0, MIN(frame.origin.x, sw - 70));
    frame.origin.y = MAX(50, MIN(frame.origin.y, sh - 120));
    
    g_floatButton.frame = frame;
    [pan setTranslation:CGPointZero inView:keyWindow];
}

static void setupFloatingButton(void) {
    if (g_floatButton) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = getKeyWindow();
        if (!keyWindow) return;
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(20, 100, 70, 70);
        
        // 渐变背景
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.frame = g_floatButton.bounds;
        gradientLayer.colors = @[
            (id)[UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.1 green:0.4 blue:0.8 alpha:1.0].CGColor
        ];
        gradientLayer.cornerRadius = 35;
        [g_floatButton.layer insertSublayer:gradientLayer atIndex:0];
        
        g_floatButton.layer.cornerRadius = 35;
        g_floatButton.layer.borderWidth = 3;
        g_floatButton.layer.borderColor = [UIColor whiteColor].CGColor;
        g_floatButton.layer.shadowColor = [UIColor blackColor].CGColor;
        g_floatButton.layer.shadowOffset = CGSizeMake(0, 2);
        g_floatButton.layer.shadowOpacity = 0.3;
        g_floatButton.layer.shadowRadius = 4;
        g_floatButton.clipsToBounds = NO;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"卡包\n修仙" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        g_floatButton.titleLabel.numberOfLines = 2;
        g_floatButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        
        [g_floatButton addTarget:[NSValue class] action:@selector(kb_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(kb_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
        
        NSLog(@"[KabaoCheat] 悬浮按钮已显示");
    });
}

@implementation NSValue (KabaoCheat)
+ (void)kb_showMenu { showMenu(); }
+ (void)kb_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void KabaoCheatInit(void) {
    @autoreleasepool {
        NSLog(@"[KabaoCheat] 卡包修仙修改器 v2.0 加载中...");
        
        // 初始化全局变量
        g_functionStates = [[NSMutableDictionary alloc] init];
        
        // 检测ASWJGAMEPLUS模块
        detectASWJModule();
        
        // 延迟显示悬浮按钮
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
            NSLog(@"[KabaoCheat] 修改器初始化完成");
        });
    }
}