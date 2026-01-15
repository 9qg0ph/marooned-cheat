// 饥饿荒野修改器 - MaroonedCheat.m
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 游戏数值修改

static void setGameValue(NSString *key, id value, NSString *type) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([type isEqualToString:@"Number"]) {
        [defaults setInteger:[value integerValue] forKey:key];
    } else if ([type isEqualToString:@"bool"]) {
        [defaults setBool:[value boolValue] forKey:key];
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
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 350;
    CGFloat contentWidth = 280;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(
        (screenWidth - contentWidth) / 2,
        (screenHeight - contentHeight) / 2,
        contentWidth, contentHeight
    )];
    self.contentView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.95];
    self.contentView.layer.cornerRadius = 16;
    [self addSubview:self.contentView];
    
    CGFloat y = 20;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 30)];
    title.text = @"🏝️ 饥饿荒野";
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    y += 35;
    
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 20)];
    info.text = @"🎮 资源仅供学习使用";
    info.font = [UIFont systemFontOfSize:14];
    info.textColor = [UIColor grayColor];
    info.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:info];
    y += 30;

    UITextView *disclaimer = [[UITextView alloc] initWithFrame:CGRectMake(20, y, 240, 60)];
    disclaimer.text = @"免责声明：本工具仅供技术研究与学习，严禁用于商业用途。";
    disclaimer.font = [UIFont systemFontOfSize:12];
    disclaimer.textColor = [UIColor lightGrayColor];
    disclaimer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    disclaimer.layer.cornerRadius = 8;
    disclaimer.editable = NO;
    [self.contentView addSubview:disclaimer];
    y += 70;
    
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 20)];
    tip.text = @"进入游戏后点击开启功能";
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:tip];
    y += 28;
    
    UIButton *btn1 = [self createButtonWithTitle:@"🥕 无限金萝卜" tag:1];
    btn1.frame = CGRectMake(20, y, 240, 35);
    [self.contentView addSubview:btn1];
    y += 43;
    
    UIButton *btn2 = [self createButtonWithTitle:@"📺 广告跳过" tag:2];
    btn2.frame = CGRectMake(20, y, 240, 35);
    [self.contentView addSubview:btn2];
    y += 43;
    
    UIButton *closeBtn = [self createButtonWithTitle:@"❌ 关闭菜单" tag:0];
    closeBtn.frame = CGRectMake(20, y, 240, 35);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    [closeBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.contentView addSubview:closeBtn];
    y += 43;
    
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 20)];
    copyright.text = @"© 2025  𝐈𝐎𝐒𝐃𝐊 科技虎";
    copyright.font = [UIFont systemFontOfSize:12];
    copyright.textColor = [UIColor lightGrayColor];
    copyright.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:copyright];
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
        case 0:
            [self.superview removeFromSuperview];
            break;
        case 1:
            setGameValue(@"marooned_gold_luobo_num", @99999, @"Number");
            [self showAlert:@"🥕 无限金萝卜开启成功！"];
            break;
        case 2:
            setGameValue(@"fanhan_AVP", @1, @"bool");
            [self showAlert:@"📺 广告跳过开启成功！"];
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
        [self.superview removeFromSuperview];
    }
}
@end


#pragma mark - 悬浮按钮

static UIWindow *g_floatWindow = nil;
static UIButton *g_floatButton = nil;
static UIWindow *g_menuWindow = nil;

static void showMenu(void) {
    if (g_menuWindow) {
        g_menuWindow.hidden = YES;
        g_menuWindow = nil;
        return;
    }
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    g_menuWindow = [[UIWindow alloc] initWithFrame:screenBounds];
    g_menuWindow.windowLevel = UIWindowLevelAlert + 2;
    g_menuWindow.backgroundColor = [UIColor clearColor];
    g_menuWindow.rootViewController = [[UIViewController alloc] init];
    
    MaroonedMenuView *menuView = [[MaroonedMenuView alloc] initWithFrame:screenBounds];
    [g_menuWindow.rootViewController.view addSubview:menuView];
    g_menuWindow.hidden = NO;
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

static void loadIconImage(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:@"https://iosdk.cn/tu/2023/04/17/p9CjtUg1.png"];
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
        g_floatButton.clipsToBounds = YES;
        
        [g_floatButton setTitle:@"虎" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(mc_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(mc_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [g_floatWindow.rootViewController.view addSubview:g_floatButton];
        g_floatWindow.hidden = NO;
        
        loadIconImage();
    });
}

@implementation NSValue (MaroonedCheat)
+ (void)mc_showMenu { showMenu(); }
+ (void)mc_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void MaroonedCheatInit(void) {
    @autoreleasepool {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}
