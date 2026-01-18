// 我独自生活修改器 - 简化版本
// 专注核心功能，去除复杂Hook
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 全局变量
static UIButton *g_floatButton = nil;
static UIView *g_menuView = nil;

// 简单日志
static void simpleLog(NSString *msg) {
    NSLog(@"[WDZ] %@", msg);
}

// 获取主窗口
static UIWindow* getMainWindow(void) {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) return window;
    }
    return [UIApplication sharedApplication].windows.firstObject;
}

// 核心修改功能 - 直接修改NSUserDefaults
static void modifyPlayerData(void) {
    simpleLog(@"开始修改玩家数据...");
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    // 修改所有可能的现金字段
    NSArray *cashKeys = @[@"cash", @"money", @"现金", @"金钱", @"playerCash", @"userCash", @"gameCash"];
    for (NSString *key in cashKeys) {
        [ud setObject:@21000000000 forKey:key];
        [ud setInteger:21000000000 forKey:key];
    }
    
    // 修改所有可能的体力字段
    NSArray *energyKeys = @[@"energy", @"stamina", @"体力", @"playerEnergy", @"userEnergy", @"gameEnergy"];
    for (NSString *key in energyKeys) {
        [ud setObject:@21000000000 forKey:key];
        [ud setInteger:21000000000 forKey:key];
    }
    
    // 修改所有可能的健康字段
    NSArray *healthKeys = @[@"health", @"hp", @"健康", @"playerHealth", @"userHealth", @"gameHealth"];
    for (NSString *key in healthKeys) {
        [ud setObject:@1000000 forKey:key];
        [ud setInteger:1000000 forKey:key];
    }
    
    // 修改所有可能的心情字段
    NSArray *moodKeys = @[@"mood", @"happiness", @"心情", @"playerMood", @"userMood", @"gameMood"];
    for (NSString *key in moodKeys) {
        [ud setObject:@1000000 forKey:key];
        [ud setInteger:1000000 forKey:key];
    }
    
    [ud synchronize];
    simpleLog(@"数据修改完成！");
}

// 定时器修改 - 每秒强制修改一次
static NSTimer *g_timer = nil;
static void startContinuousModify(void) {
    if (g_timer) {
        [g_timer invalidate];
        g_timer = nil;
    }
    
    g_timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *timer) {
        modifyPlayerData();
    }];
    
    simpleLog(@"已启动持续修改模式");
}

static void stopContinuousModify(void) {
    if (g_timer) {
        [g_timer invalidate];
        g_timer = nil;
        simpleLog(@"已停止持续修改模式");
    }
}

// 显示简单菜单
static void showSimpleMenu(void) {
    if (g_menuView) {
        [g_menuView removeFromSuperview];
        g_menuView = nil;
        return;
    }
    
    UIWindow *window = getMainWindow();
    if (!window) return;
    
    // 创建半透明背景
    g_menuView = [[UIView alloc] initWithFrame:window.bounds];
    g_menuView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    // 创建菜单容器
    UIView *menu = [[UIView alloc] initWithFrame:CGRectMake(50, 200, 280, 300)];
    menu.backgroundColor = [UIColor whiteColor];
    menu.layer.cornerRadius = 15;
    [g_menuView addSubview:menu];
    
    // 标题
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 280, 30)];
    title.text = @"🏠 我独自生活修改器";
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:18];
    [menu addSubview:title];
    
    // 按钮1：一次性修改
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeSystem];
    btn1.frame = CGRectMake(40, 70, 200, 40);
    [btn1 setTitle:@"💰 一次性修改全部" forState:UIControlStateNormal];
    btn1.backgroundColor = [UIColor systemBlueColor];
    [btn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn1.layer.cornerRadius = 8;
    [btn1 addTarget:btn1 action:@selector(onceModify) forControlEvents:UIControlEventTouchUpInside];
    [menu addSubview:btn1];
    
    // 按钮2：持续修改
    UIButton *btn2 = [UIButton buttonWithType:UIButtonTypeSystem];
    btn2.frame = CGRectMake(40, 120, 200, 40);
    [btn2 setTitle:@"🔄 开启持续修改" forState:UIControlStateNormal];
    btn2.backgroundColor = [UIColor systemGreenColor];
    [btn2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn2.layer.cornerRadius = 8;
    [btn2 addTarget:btn2 action:@selector(startModify) forControlEvents:UIControlEventTouchUpInside];
    [menu addSubview:btn2];
    
    // 按钮3：停止修改
    UIButton *btn3 = [UIButton buttonWithType:UIButtonTypeSystem];
    btn3.frame = CGRectMake(40, 170, 200, 40);
    [btn3 setTitle:@"⏹️ 停止持续修改" forState:UIControlStateNormal];
    btn3.backgroundColor = [UIColor systemOrangeColor];
    [btn3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn3.layer.cornerRadius = 8;
    [btn3 addTarget:btn3 action:@selector(stopModify) forControlEvents:UIControlEventTouchUpInside];
    [menu addSubview:btn3];
    
    // 关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(40, 220, 200, 40);
    [closeBtn setTitle:@"❌ 关闭" forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor systemRedColor];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.layer.cornerRadius = 8;
    [closeBtn addTarget:closeBtn action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [menu addSubview:closeBtn];
    
    [window addSubview:g_menuView];
}

// 按钮响应方法
@interface NSObject (WDZActions)
- (void)onceModify;
- (void)startModify;
- (void)stopModify;
- (void)closeMenu;
@end

@implementation NSObject (WDZActions)
- (void)onceModify {
    modifyPlayerData();
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"完成" message:@"数据修改完成！" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *vc = getMainWindow().rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    [vc presentViewController:alert animated:YES completion:nil];
}

- (void)startModify {
    startContinuousModify();
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"启动" message:@"持续修改已启动！每秒自动修改一次数据。" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *vc = getMainWindow().rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    [vc presentViewController:alert animated:YES completion:nil];
}

- (void)stopModify {
    stopContinuousModify();
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"停止" message:@"持续修改已停止。" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *vc = getMainWindow().rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    [vc presentViewController:alert animated:YES completion:nil];
}

- (void)closeMenu {
    if (g_menuView) {
        [g_menuView removeFromSuperview];
        g_menuView = nil;
    }
}
@end

// 创建悬浮按钮
static void createFloatButton(void) {
    UIWindow *window = getMainWindow();
    if (!window || g_floatButton) return;
    
    g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    g_floatButton.frame = CGRectMake(20, 100, 60, 60);
    g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:0.9];
    g_floatButton.layer.cornerRadius = 30;
    [g_floatButton setTitle:@"修改" forState:UIControlStateNormal];
    [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    
    [g_floatButton addTarget:g_floatButton action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    
    // 添加拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:g_floatButton action:@selector(handlePan:)];
    [g_floatButton addGestureRecognizer:pan];
    
    [window addSubview:g_floatButton];
    simpleLog(@"悬浮按钮已创建");
}

@interface UIButton (WDZFloat)
- (void)showMenu;
- (void)handlePan:(UIPanGestureRecognizer *)pan;
@end

@implementation UIButton (WDZFloat)
- (void)showMenu {
    showSimpleMenu();
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIWindow *window = getMainWindow();
    if (!window) return;
    
    CGPoint translation = [pan translationInView:window];
    CGRect frame = self.frame;
    frame.origin.x += translation.x;
    frame.origin.y += translation.y;
    
    // 限制在屏幕范围内
    frame.origin.x = MAX(0, MIN(frame.origin.x, window.bounds.size.width - 60));
    frame.origin.y = MAX(50, MIN(frame.origin.y, window.bounds.size.height - 110));
    
    self.frame = frame;
    [pan setTranslation:CGPointZero inView:window];
}
@end

// 初始化
__attribute__((constructor))
static void WDZSimpleInit(void) {
    simpleLog(@"🚀 我独自生活修改器(简化版)已加载");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        createFloatButton();
    });
}