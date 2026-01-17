// 天选打工人 - 极简测试版
// 只显示菜单，不做任何修改操作
#import <UIKit/UIKit.h>

static UIButton *g_floatButton = nil;
static UIView *g_menuView = nil;

// 获取 keyWindow
static UIWindow* getKeyWindow(void) {
    // iOS 13+
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    }
    
    // 旧方法
    return [UIApplication sharedApplication].keyWindow ?: [UIApplication sharedApplication].windows.firstObject;
}

// 显示简单菜单
static void showMenu(void) {
    if (g_menuView) {
        [g_menuView removeFromSuperview];
        g_menuView = nil;
        return;
    }
    
    UIWindow *keyWindow = getKeyWindow();
    if (!keyWindow) return;
    
    // 创建半透明背景
    g_menuView = [[UIView alloc] initWithFrame:keyWindow.bounds];
    g_menuView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    g_menuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // 创建内容视图
    CGFloat w = 280, h = 200;
    UIView *content = [[UIView alloc] initWithFrame:CGRectMake(
        (keyWindow.bounds.size.width - w) / 2,
        (keyWindow.bounds.size.height - h) / 2,
        w, h
    )];
    content.backgroundColor = [UIColor whiteColor];
    content.layer.cornerRadius = 16;
    content.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    // 标题
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, w, 30)];
    title.text = @"🎯 测试菜单";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textAlignment = NSTextAlignmentCenter;
    [content addSubview:title];
    
    // 说明
    UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(20, 60, w - 40, 60)];
    desc.text = @"如果你能看到这个菜单\n说明基本功能正常\n\n点击外部关闭";
    desc.font = [UIFont systemFontOfSize:14];
    desc.textAlignment = NSTextAlignmentCenter;
    desc.numberOfLines = 0;
    desc.textColor = [UIColor darkGrayColor];
    [content addSubview:desc];
    
    // 关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(40, h - 60, w - 80, 44);
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeBtn addTarget:closeBtn action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:closeBtn];
    
    [g_menuView addSubview:content];
    
    // 点击背景关闭
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:g_menuView action:@selector(removeFromSuperview)];
    [g_menuView addGestureRecognizer:tap];
    
    [keyWindow addSubview:g_menuView];
}

// 创建悬浮按钮
static void setupFloatingButton(void) {
    if (g_floatButton) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = getKeyWindow();
        if (!keyWindow) return;
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(20, 100, 50, 50);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        
        [g_floatButton setTitle:@"✅" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:24];
        
        [g_floatButton addTarget:g_floatButton action:@selector(tx_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        [keyWindow addSubview:g_floatButton];
    });
}

@implementation UIButton (TXTest)
- (void)tx_showMenu {
    showMenu();
}
@end

__attribute__((constructor))
static void TXTestInit(void) {
    @autoreleasepool {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}
