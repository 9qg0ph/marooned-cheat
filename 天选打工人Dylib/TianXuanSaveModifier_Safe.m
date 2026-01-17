// 天选打工人存档修改器 - 安全测试版
// 先测试UI和基本功能，确保不会闪退
#import <UIKit/UIKit.h>
#import <sqlite3.h>

#pragma mark - 全局变量

@class TXSaveMenuView;
static UIButton *g_floatButton = nil;
static TXSaveMenuView *g_menuView = nil;

#pragma mark - 存档修改（安全版本）

// 获取存档路径
static NSString* getSavePath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"jsb.sqlite"];
}

// 检查存档文件
static BOOL checkSaveFile(void) {
    NSString *dbPath = getSavePath();
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:dbPath];
    NSLog(@"[TX] 存档路径: %@", dbPath);
    NSLog(@"[TX] 存档存在: %@", exists ? @"是" : @"否");
    return exists;
}

// 读取存档信息（只读，不修改）
static NSDictionary* readSaveInfo(void) {
    NSString *dbPath = getSavePath();
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        NSLog(@"[TX] 存档文件不存在");
        return nil;
    }
    
    sqlite3 *db = NULL;
    if (sqlite3_open([dbPath UTF8String], &db) != SQLITE_OK) {
        NSLog(@"[TX] 打开数据库失败");
        if (db) sqlite3_close(db);
        return nil;
    }
    
    const char *selectSQL = "SELECT value FROM data WHERE key='ssx45sss'";
    sqlite3_stmt *stmt = NULL;
    NSString *jsonString = nil;
    
    if (sqlite3_prepare_v2(db, selectSQL, -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            const char *jsonText = (const char *)sqlite3_column_text(stmt, 0);
            if (jsonText) {
                jsonString = [NSString stringWithUTF8String:jsonText];
            }
        }
        sqlite3_finalize(stmt);
    }
    
    sqlite3_close(db);
    
    if (!jsonString) {
        NSLog(@"[TX] 未找到存档数据");
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *saveDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error) {
        NSLog(@"[TX] JSON解析失败: %@", error);
        return nil;
    }
    
    NSDictionary *info = saveDict[@"info"];
    NSLog(@"[TX] 当前存档数据: %@", info);
    
    return info;
}

#pragma mark - 菜单视图

@interface TXSaveMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation TXSaveMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 400;
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
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, contentWidth - 60, 30)];
    title.text = @"💾 存档修改器（测试版）";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 50;
    
    // 状态显示
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 80)];
    self.statusLabel.text = @"正在检测存档...";
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = [UIColor darkGrayColor];
    self.statusLabel.textAlignment = NSTextAlignmentLeft;
    self.statusLabel.numberOfLines = 0;
    [self.contentView addSubview:self.statusLabel];
    y += 90;
    
    // 按钮
    UIButton *btn1 = [self createButtonWithTitle:@"🔍 检测存档文件" tag:1];
    btn1.frame = CGRectMake(20, y, contentWidth - 40, 44);
    [self.contentView addSubview:btn1];
    y += 54;
    
    UIButton *btn2 = [self createButtonWithTitle:@"📖 读取当前数据" tag:2];
    btn2.frame = CGRectMake(20, y, contentWidth - 40, 44);
    [self.contentView addSubview:btn2];
    y += 54;
    
    UIButton *btn3 = [self createButtonWithTitle:@"📝 显示存档路径" tag:3];
    btn3.frame = CGRectMake(20, y, contentWidth - 40, 44);
    [self.contentView addSubview:btn3];
    y += 60;
    
    // 版权
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    copyright.text = @"© 2025  𝐈𝐎𝐒𝐃𝐊 科技虎";
    copyright.font = [UIFont systemFontOfSize:12];
    copyright.textColor = [UIColor lightGrayColor];
    copyright.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:copyright];
    
    // 自动检测
    [self performSelector:@selector(autoCheck) withObject:nil afterDelay:0.5];
}

- (void)autoCheck {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL exists = checkSaveFile();
        NSDictionary *info = readSaveInfo();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exists && info) {
                self.statusLabel.text = [NSString stringWithFormat:@"✅ 存档检测成功\n\n💰 金钱: %@\n🏆 金条: %@\n⚡ 体力: %@\n😊 心情: %@\n🎯 积分: %@",
                    info[@"money"] ?: @"未知",
                    info[@"mine"] ?: @"未知",
                    info[@"power"] ?: @"未知",
                    info[@"mood"] ?: @"未知",
                    info[@"integral"] ?: @"未知"];
            } else if (exists) {
                self.statusLabel.text = @"⚠️ 存档文件存在\n但读取数据失败";
            } else {
                self.statusLabel.text = @"❌ 未找到存档文件\n请先启动游戏";
            }
        });
    });
}

- (void)closeMenu {
    [self removeFromSuperview];
    g_menuView = nil;
}

- (UIButton *)createButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    switch (sender.tag) {
        case 1: {
            BOOL exists = checkSaveFile();
            [self showAlert:exists ? @"✅ 存档文件存在" : @"❌ 存档文件不存在"];
            break;
        }
        case 2: {
            NSDictionary *info = readSaveInfo();
            if (info) {
                NSString *msg = [NSString stringWithFormat:@"📖 当前数据：\n\n💰 金钱: %@\n🏆 金条: %@\n⚡ 体力: %@\n😊 心情: %@\n🎯 积分: %@",
                    info[@"money"], info[@"mine"], info[@"power"], info[@"mood"], info[@"integral"]];
                [self showAlert:msg];
            } else {
                [self showAlert:@"❌ 读取失败"];
            }
            break;
        }
        case 3: {
            NSString *path = getSavePath();
            UIPasteboard.generalPasteboard.string = path;
            [self showAlert:[NSString stringWithFormat:@"📝 存档路径：\n\n%@\n\n已复制到剪贴板", path]];
            break;
        }
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
    g_menuView = [[TXSaveMenuView alloc] initWithFrame:windowBounds];
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
    frame.origin.x = MAX(0, MIN(frame.origin.x, sw - 50));
    frame.origin.y = MAX(50, MIN(frame.origin.y, sh - 100));
    
    g_floatButton.frame = frame;
    [pan setTranslation:CGPointMake(0, 0) inView:keyWindow];
}

static void setupFloatingButton(void) {
    if (g_floatButton) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = getKeyWindow();
        if (!keyWindow) {
            NSLog(@"[TX] 无法获取keyWindow");
            return;
        }
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(20, 100, 50, 50);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.9 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"🧪" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:24];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(tx_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(tx_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
        NSLog(@"[TX] 悬浮按钮创建成功");
    });
}

@implementation NSValue (TXSaveCheat)
+ (void)tx_showMenu { showMenu(); }
+ (void)tx_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void TXSaveCheatInit(void) {
    @autoreleasepool {
        NSLog(@"[TX] 天选打工人存档修改器（测试版）初始化...");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @try {
                setupFloatingButton();
            } @catch (NSException *exception) {
                NSLog(@"[TX] 初始化失败: %@", exception);
            }
        });
    }
}
