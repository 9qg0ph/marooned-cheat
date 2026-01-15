// 饥饿荒野修改器 - MaroonedCheat.m
// 独立 dylib，无需 Substrate

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 游戏数值修改

static void setGameValue(NSString *key, id value, NSString *type) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([type isEqualToString:@"Number"]) {
        [defaults setInteger:[value integerValue] forKey:key];
    } else if ([type isEqualToString:@"bool"]) {
        [defaults setBool:[value boolValue] forKey:key];
    } else if ([type isEqualToString:@"Float"]) {
        [defaults setFloat:[value floatValue] forKey:key];
    } else {
        [defaults setObject:value forKey:key];
    }
    [defaults synchronize];
}

#pragma mark - 菜单视图

@interface MaroonedMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation MaroonedMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 半透明背景
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    // 内容容器
    self.contentView = [[UIView alloc] init];
    self.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95];
    self.contentView.layer.cornerRadius = 16;
    self.contentView.layer.shadowColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:0.15].CGColor;
    self.contentView.layer.shadowOffset = CGSizeMake(0, 4);
    self.contentView.layer.shadowRadius = 20;
    self.contentView.layer.shadowOpacity = 1;
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.contentView];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.contentView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.contentView.widthAnchor constraintEqualToConstant:280]
    ]];
    
    CGFloat y = 20;
    
    // 标题
    UILabel *title = [self createLabelWithText:@"🏝️ 饥饿荒野" fontSize:22 bold:YES];
    title.textColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:1];
    title.frame = CGRectMake(20, y, 240, 30);
    [self.contentView addSubview:title];
    y += 35;
    
    // 副标题
    UILabel *info = [self createLabelWithText:@"🎮 资源仅供学习使用" fontSize:14 bold:NO];
    info.textColor = [UIColor grayColor];
    info.frame = CGRectMake(20, y, 240, 20);
    [self.contentView addSubview:info];
    y += 30;
    
    // 免责声明
    UITextView *disclaimer = [[UITextView alloc] initWithFrame:CGRectMake(20, y, 240, 60)];
    disclaimer.text = @"免责声明：本工具仅供技术研究与学习，严禁用于商业用途。使用本工具修改游戏可能违反服务条款，用户需自行承担风险。";
    disclaimer.font = [UIFont systemFontOfSize:12];
    disclaimer.textColor = [UIColor lightGrayColor];
    disclaimer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    disclaimer.layer.cornerRadius = 8;
    disclaimer.editable = NO;
    [self.contentView addSubview:disclaimer];
    y += 70;
    
    // 提示
    UILabel *tip = [self createLabelWithText:@"进入游戏后点击开启功能" fontSize:12 bold:NO];
    tip.textColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:1];
    tip.frame = CGRectMake(20, y, 240, 20);
    [self.contentView addSubview:tip];
    y += 28;
    
    // 按钮1 - 无限金萝卜
    UIButton *btn1 = [self createButtonWithTitle:@"🥕 无限金萝卜" tag:1];
    btn1.frame = CGRectMake(20, y, 240, 35);
    [self.contentView addSubview:btn1];
    y += 43;
    
    // 按钮2 - 广告跳过
    UIButton *btn2 = [self createButtonWithTitle:@"📺 广告跳过" tag:2];
    btn2.frame = CGRectMake(20, y, 240, 35);
    [self.contentView addSubview:btn2];
    y += 43;
    
    // 关闭按钮
    UIButton *closeBtn = [self createButtonWithTitle:@"❌ 关闭菜单" tag:0];
    closeBtn.frame = CGRectMake(20, y, 240, 35);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [closeBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.contentView addSubview:closeBtn];
    y += 43;
    
    // 版权
    UILabel *copyright = [self createLabelWithText:@"© 2025  𝐈𝐎𝐒𝐃𝐊 科技虎" fontSize:12 bold:NO];
    copyright.textColor = [UIColor lightGrayColor];
    copyright.frame = CGRectMake(20, y, 240, 20);
    [self.contentView addSubview:copyright];
    y += 30;
    
    // 设置内容高度
    CGRect contentFrame = self.contentView.frame;
    contentFrame.size.height = y;
    
    // 更新约束
    for (NSLayoutConstraint *c in self.contentView.constraints) {
        if (c.firstAttribute == NSLayoutAttributeHeight) {
            c.constant = y;
            break;
        }
    }
    [self.contentView.heightAnchor constraintEqualToConstant:y].active = YES;
}

- (UILabel *)createLabelWithText:(NSString *)text fontSize:(CGFloat)size bold:(BOOL)bold {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = bold ? [UIFont boldSystemFontOfSize:size] : [UIFont systemFontOfSize:size];
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

- (UIButton *)createButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    switch (sender.tag) {
        case 0: // 关闭
            [self removeFromSuperview];
            break;
        case 1: // 无限金萝卜
            setGameValue(@"marooned_gold_luobo_num", @99999, @"Number");
            [self showAlert:@"🥕 无限金萝卜开启成功！"];
            break;
        case 2: // 广告跳过
            setGameValue(@"fanhan_AVP", @1, @"bool");
            [self showAlert:@"📺 广告跳过开启成功！"];
            break;
    }
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" 
                                                                   message:message 
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    if (![self.contentView pointInside:[self.contentView convertPoint:location fromView:self] withEvent:event]) {
        [self removeFromSuperview];
    }
}

@end

#pragma mark - 悬浮按钮

static UIWindow *g_floatWindow = nil;
static UIButton *g_floatButton = nil;
static MaroonedMenuView *g_menuView = nil;

static void showMenu(void) {
    if (g_menuView && g_menuView.superview) {
        [g_menuView removeFromSuperview];
        g_menuView = nil;
        return;
    }
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    g_menuView = [[MaroonedMenuView alloc] initWithFrame:keyWindow.bounds];
    [keyWindow addSubview:g_menuView];
}

static void handlePan(UIPanGestureRecognizer *pan) {
    CGPoint translation = [pan translationInView:g_floatWindow];
    CGRect frame = g_floatWindow.frame;
    frame.origin.x += translation.x;
    frame.origin.y += translation.y;
    
    CGFloat sw = [UIScreen mainScreen].bounds.size.width;
    CGFloat sh = [UIScreen mainScreen].bounds.size.height;
    
    frame.origin.x = MAX(0, MIN(frame.origin.x, sw - 50));
    frame.origin.y = MAX(50, MIN(frame.origin.y, sh - 100));
    
    g_floatWindow.frame = frame;
    [pan setTranslation:CGPointZero inView:g_floatWindow];
}

static void setupFloatingButton(void) {
    if (g_floatWindow) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        g_floatWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 100, 50, 50)];
        g_floatWindow.windowLevel = UIWindowLevelAlert + 1;
        g_floatWindow.backgroundColor = [UIColor clearColor];
        g_floatWindow.rootViewController = [[UIViewController alloc] init];
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(0, 0, 50, 50);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.layer.shadowColor = [UIColor blackColor].CGColor;
        g_floatButton.layer.shadowOffset = CGSizeMake(0, 2);
        g_floatButton.layer.shadowRadius = 4;
        g_floatButton.layer.shadowOpacity = 0.3;
        [g_floatButton setTitle:@"🏝️" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:24];
        
        // 点击事件
        [g_floatButton addTarget:[NSValue class] action:@selector(mc_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        // 拖动手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(mc_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [g_floatWindow.rootViewController.view addSubview:g_floatButton];
        g_floatWindow.hidden = NO;
    });
}

#pragma mark - NSValue Category for Callbacks

@implementation NSValue (MaroonedCheat)

+ (void)mc_showMenu {
    showMenu();
}

+ (void)mc_handlePan:(UIPanGestureRecognizer *)pan {
    handlePan(pan);
}

@end

#pragma mark - Method Swizzling

static IMP g_originalDidFinishLaunching = NULL;

static BOOL swizzled_didFinishLaunchingWithOptions(id self, SEL _cmd, UIApplication *app, NSDictionary *options) {
    BOOL result = ((BOOL(*)(id, SEL, UIApplication *, NSDictionary *))g_originalDidFinishLaunching)(self, _cmd, app, options);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupFloatingButton();
    });
    
    return result;
}

#pragma mark - Constructor

__attribute__((constructor))
static void MaroonedCheatInit(void) {
    @autoreleasepool {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 查找 AppDelegate 类
            Class appDelegateClass = nil;
            
            // 尝试常见的 AppDelegate 类名
            NSArray *possibleNames = @[@"AppDelegate", @"UnityAppController", @"AppController"];
            for (NSString *name in possibleNames) {
                appDelegateClass = NSClassFromString(name);
                if (appDelegateClass) break;
            }
            
            if (!appDelegateClass) {
                // 从 UIApplication 获取
                id delegate = [[UIApplication sharedApplication] delegate];
                if (delegate) {
                    appDelegateClass = [delegate class];
                }
            }
            
            if (appDelegateClass) {
                Method method = class_getInstanceMethod(appDelegateClass, @selector(application:didFinishLaunchingWithOptions:));
                if (method) {
                    g_originalDidFinishLaunching = method_setImplementation(method, (IMP)swizzled_didFinishLaunchingWithOptions);
                }
            }
            
            // 直接设置悬浮按钮（备用方案）
            setupFloatingButton();
        });
    }
}
