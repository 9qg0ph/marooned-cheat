// 饥饿荒野修改器 - Tweak.x
// 使用键值存储方式修改游戏数据

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 存储修改的键值
static void setGameValue(NSString *key, id value, NSString *type) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([type isEqualToString:@"Number"] || [type isEqualToString:@"I32"] || [type isEqualToString:@"I64"]) {
        [defaults setInteger:[value integerValue] forKey:key];
    } else if ([type isEqualToString:@"F32"] || [type isEqualToString:@"F64"] || [type isEqualToString:@"Float"]) {
        [defaults setFloat:[value floatValue] forKey:key];
    } else if ([type isEqualToString:@"bool"] || [type isEqualToString:@"Bool"]) {
        [defaults setBool:[value boolValue] forKey:key];
    } else if ([type isEqualToString:@"String"]) {
        [defaults setObject:value forKey:key];
    } else {
        [defaults setObject:value forKey:key];
    }
    
    [defaults synchronize];
}

// 菜单视图控制器
@interface MaroonedMenuViewController : UIViewController
@property (nonatomic, strong) UIView *menuView;
@end

@implementation MaroonedMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    // 半透明背景
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    // 菜单容器
    self.menuView = [[UIView alloc] init];
    self.menuView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95];
    self.menuView.layer.cornerRadius = 16;
    self.menuView.layer.shadowColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:0.15].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 4);
    self.menuView.layer.shadowRadius = 20;
    self.menuView.layer.shadowOpacity = 1;
    self.menuView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.menuView];
    
    // 菜单居中
    [NSLayoutConstraint activateConstraints:@[
        [self.menuView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.menuView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.menuView.widthAnchor constraintEqualToConstant:280]
    ]];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"🏝️ 饥饿荒野";
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    titleLabel.textColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:1];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menuView addSubview:titleLabel];
    
    // 副标题
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.text = @"🎮 资源仅供学习使用";
    infoLabel.font = [UIFont systemFontOfSize:14];
    infoLabel.textColor = [UIColor grayColor];
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menuView addSubview:infoLabel];
    
    // 免责声明
    UITextView *disclaimer = [[UITextView alloc] init];
    disclaimer.text = @"免责声明：本工具仅供技术研究与学习，严禁用于商业用途。使用本工具修改游戏可能违反服务条款，用户需自行承担风险。";
    disclaimer.font = [UIFont systemFontOfSize:12];
    disclaimer.textColor = [UIColor lightGrayColor];
    disclaimer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    disclaimer.layer.cornerRadius = 8;
    disclaimer.editable = NO;
    disclaimer.scrollEnabled = YES;
    disclaimer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menuView addSubview:disclaimer];
    
    // 提示文字
    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.text = @"进入游戏后点击开启功能";
    tipLabel.font = [UIFont systemFontOfSize:12];
    tipLabel.textColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:1];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menuView addSubview:tipLabel];
    
    // 功能按钮1 - 无限金萝卜
    UIButton *btn1 = [self createButtonWithTitle:@"🥕 无限金萝卜" action:@selector(onGoldCarrot)];
    [self.menuView addSubview:btn1];
    
    // 功能按钮2 - 广告跳过
    UIButton *btn2 = [self createButtonWithTitle:@"📺 广告跳过" action:@selector(onSkipAd)];
    [self.menuView addSubview:btn2];
    
    // 关闭按钮
    UIButton *closeBtn = [self createButtonWithTitle:@"❌ 关闭菜单" action:@selector(closeMenu)];
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [closeBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.menuView addSubview:closeBtn];
    
    // 版权
    UILabel *copyright = [[UILabel alloc] init];
    copyright.text = @"© 2025  𝐈𝐎𝐒𝐃𝐊 科技虎";
    copyright.font = [UIFont systemFontOfSize:12];
    copyright.textColor = [UIColor lightGrayColor];
    copyright.textAlignment = NSTextAlignmentCenter;
    copyright.translatesAutoresizingMaskIntoConstraints = NO;
    [self.menuView addSubview:copyright];
    
    // 布局
    [NSLayoutConstraint activateConstraints:@[
        [titleLabel.topAnchor constraintEqualToAnchor:self.menuView.topAnchor constant:20],
        [titleLabel.leadingAnchor constraintEqualToAnchor:self.menuView.leadingAnchor constant:20],
        [titleLabel.trailingAnchor constraintEqualToAnchor:self.menuView.trailingAnchor constant:-20],
        
        [infoLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:10],
        [infoLabel.leadingAnchor constraintEqualToAnchor:self.menuView.leadingAnchor constant:20],
        [infoLabel.trailingAnchor constraintEqualToAnchor:self.menuView.trailingAnchor constant:-20],
        
        [disclaimer.topAnchor constraintEqualToAnchor:infoLabel.bottomAnchor constant:10],
        [disclaimer.leadingAnchor constraintEqualToAnchor:self.menuView.leadingAnchor constant:20],
        [disclaimer.trailingAnchor constraintEqualToAnchor:self.menuView.trailingAnchor constant:-20],
        [disclaimer.heightAnchor constraintEqualToConstant:60],
        
        [tipLabel.topAnchor constraintEqualToAnchor:disclaimer.bottomAnchor constant:10],
        [tipLabel.leadingAnchor constraintEqualToAnchor:self.menuView.leadingAnchor constant:20],
        [tipLabel.trailingAnchor constraintEqualToAnchor:self.menuView.trailingAnchor constant:-20],
        
        [btn1.topAnchor constraintEqualToAnchor:tipLabel.bottomAnchor constant:10],
        [btn1.leadingAnchor constraintEqualToAnchor:self.menuView.leadingAnchor constant:20],
        [btn1.trailingAnchor constraintEqualToAnchor:self.menuView.trailingAnchor constant:-20],
        [btn1.heightAnchor constraintEqualToConstant:35],
        
        [btn2.topAnchor constraintEqualToAnchor:btn1.bottomAnchor constant:8],
        [btn2.leadingAnchor constraintEqualToAnchor:self.menuView.leadingAnchor constant:20],
        [btn2.trailingAnchor constraintEqualToAnchor:self.menuView.trailingAnchor constant:-20],
        [btn2.heightAnchor constraintEqualToConstant:35],
        
        [closeBtn.topAnchor constraintEqualToAnchor:btn2.bottomAnchor constant:8],
        [closeBtn.leadingAnchor constraintEqualToAnchor:self.menuView.leadingAnchor constant:20],
        [closeBtn.trailingAnchor constraintEqualToAnchor:self.menuView.trailingAnchor constant:-20],
        [closeBtn.heightAnchor constraintEqualToConstant:35],
        
        [copyright.topAnchor constraintEqualToAnchor:closeBtn.bottomAnchor constant:15],
        [copyright.leadingAnchor constraintEqualToAnchor:self.menuView.leadingAnchor constant:20],
        [copyright.trailingAnchor constraintEqualToAnchor:self.menuView.trailingAnchor constant:-20],
        [copyright.bottomAnchor constraintEqualToAnchor:self.menuView.bottomAnchor constant:-20]
    ]];
    
    // 点击背景关闭
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeMenu)];
    [self.view addGestureRecognizer:tap];
}

- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)onGoldCarrot {
    setGameValue(@"marooned_gold_luobo_num", @99999, @"Number");
    [self showAlert:@"🥕 无限金萝卜开启成功！"];
}

- (void)onSkipAd {
    setGameValue(@"fanhan_AVP", @1, @"bool");
    [self showAlert:@"📺 广告跳过开启成功！"];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)closeMenu {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (![self.menuView pointInside:[touch locationInView:self.menuView] withEvent:event]) {
        [self closeMenu];
    }
}

@end

// 悬浮按钮
static UIButton *floatingButton = nil;
static UIWindow *floatingWindow = nil;

static void showMenu() {
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    
    MaroonedMenuViewController *menuVC = [[MaroonedMenuViewController alloc] init];
    menuVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    menuVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [rootVC presentViewController:menuVC animated:YES completion:nil];
}

static void setupFloatingButton() {
    if (floatingWindow) return;
    
    // 创建悬浮窗口
    floatingWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 100, 50, 50)];
    floatingWindow.windowLevel = UIWindowLevelAlert + 1;
    floatingWindow.backgroundColor = [UIColor clearColor];
    floatingWindow.hidden = NO;
    
    // 创建悬浮按钮
    floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    floatingButton.frame = CGRectMake(0, 0, 50, 50);
    floatingButton.backgroundColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:0.9];
    floatingButton.layer.cornerRadius = 25;
    floatingButton.layer.shadowColor = [UIColor blackColor].CGColor;
    floatingButton.layer.shadowOffset = CGSizeMake(0, 2);
    floatingButton.layer.shadowRadius = 4;
    floatingButton.layer.shadowOpacity = 0.3;
    [floatingButton setTitle:@"🏝️" forState:UIControlStateNormal];
    floatingButton.titleLabel.font = [UIFont systemFontOfSize:24];
    [floatingButton addTarget:[NSClassFromString(@"MaroonedMenuViewController") class] action:@selector(showMenuAction) forControlEvents:UIControlEventTouchUpInside];
    
    // 添加拖动手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSClassFromString(@"MaroonedMenuViewController") class] action:@selector(handlePan:)];
    [floatingButton addGestureRecognizer:pan];
    
    floatingWindow.rootViewController = [[UIViewController alloc] init];
    [floatingWindow.rootViewController.view addSubview:floatingButton];
    [floatingWindow makeKeyAndVisible];
}

// 添加类方法
%hook UIViewController

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 添加显示菜单的类方法
        Class cls = NSClassFromString(@"MaroonedMenuViewController");
        if (cls) {
            class_addMethod(object_getClass(cls), @selector(showMenuAction), (IMP)showMenu, "v@:");
            class_addMethod(object_getClass(cls), @selector(handlePan:), (IMP)handlePanGesture, "v@:@");
        }
    });
}

%end

static void handlePanGesture(id self, SEL _cmd, UIPanGestureRecognizer *pan) {
    CGPoint translation = [pan translationInView:floatingWindow];
    CGRect frame = floatingWindow.frame;
    frame.origin.x += translation.x;
    frame.origin.y += translation.y;
    
    // 边界检查
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if (frame.origin.x < 0) frame.origin.x = 0;
    if (frame.origin.y < 50) frame.origin.y = 50;
    if (frame.origin.x > screenWidth - 50) frame.origin.x = screenWidth - 50;
    if (frame.origin.y > screenHeight - 100) frame.origin.y = screenHeight - 100;
    
    floatingWindow.frame = frame;
    [pan setTranslation:CGPointZero inView:floatingWindow];
}

// Hook 应用启动
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupFloatingButton();
    });
    
    return result;
}

%end

%ctor {
    %init;
}
