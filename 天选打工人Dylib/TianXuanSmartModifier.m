// 天选打工人智能修改器
// 只修改金钱/金条等数值，保留游戏进度
#import <UIKit/UIKit.h>
#import <sqlite3.h>

#pragma mark - 全局变量

@class TXSmartMenuView;
static UIButton *g_floatButton = nil;
static TXSmartMenuView *g_menuView = nil;

#pragma mark - 智能修改

// 获取存档路径
static NSString* getSavePath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"jsb.sqlite"];
}

// 智能修改：只改info字段，保留其他数据
static BOOL smartModify(int32_t money, int32_t mine, int32_t power, int32_t mood, int32_t integral) {
    NSString *dbPath = getSavePath();
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        NSLog(@"[TX] 存档文件不存在");
        return NO;
    }
    
    // 备份
    NSString *backupPath = [dbPath stringByAppendingString:@".backup"];
    [[NSFileManager defaultManager] removeItemAtPath:backupPath error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:dbPath toPath:backupPath error:nil];
    
    sqlite3 *db = NULL;
    if (sqlite3_open([dbPath UTF8String], &db) != SQLITE_OK) {
        NSLog(@"[TX] 打开数据库失败");
        if (db) sqlite3_close(db);
        return NO;
    }
    
    // 读取当前存档
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
    
    if (!jsonString) {
        NSLog(@"[TX] 未找到存档数据");
        sqlite3_close(db);
        return NO;
    }
    
    // 解析JSON
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSMutableDictionary *saveDict = [NSJSONSerialization JSONObjectWithData:jsonData 
        options:NSJSONReadingMutableContainers error:&error];
    
    if (error || !saveDict) {
        NSLog(@"[TX] JSON解析失败: %@", error);
        sqlite3_close(db);
        return NO;
    }
    
    // 只修改info字段
    NSMutableDictionary *info = saveDict[@"info"];
    if (!info) {
        NSLog(@"[TX] 未找到info字段");
        sqlite3_close(db);
        return NO;
    }
    
    // 修改数值（只修改传入的非零值）
    if (money > 0) info[@"money"] = @(money);
    if (mine > 0) info[@"mine"] = @(mine);
    if (power > 0) info[@"power"] = @(power);
    if (mood > 0) info[@"mood"] = @(mood);
    if (integral > 0) info[@"integral"] = @(integral);
    
    NSLog(@"[TX] 修改后的info: %@", info);
    
    // 转回JSON
    NSData *newJsonData = [NSJSONSerialization dataWithJSONObject:saveDict options:0 error:&error];
    if (error || !newJsonData) {
        NSLog(@"[TX] JSON序列化失败: %@", error);
        sqlite3_close(db);
        return NO;
    }
    
    NSString *newJsonString = [[NSString alloc] initWithData:newJsonData encoding:NSUTF8StringEncoding];
    
    // 更新数据库
    const char *updateSQL = "UPDATE data SET value=? WHERE key='ssx45sss'";
    sqlite3_stmt *updateStmt = NULL;
    
    BOOL success = NO;
    if (sqlite3_prepare_v2(db, updateSQL, -1, &updateStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(updateStmt, 1, [newJsonString UTF8String], -1, SQLITE_TRANSIENT);
        if (sqlite3_step(updateStmt) == SQLITE_DONE) {
            success = YES;
            NSLog(@"[TX] 智能修改成功");
        }
        sqlite3_finalize(updateStmt);
    }
    
    sqlite3_close(db);
    return success;
}

// 退出游戏
static void exitGame(void) {
    NSLog(@"[TX] 正在退出游戏...");
    exit(0);
}

#pragma mark - 菜单视图

@interface TXSmartMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation TXSmartMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 420;
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
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, contentWidth - 60, 30)];
    title.text = @"🎯 智能修改器";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 50;
    
    // 说明
    UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 50)];
    desc.text = @"✨ 只修改数值，保留游戏进度\n✅ 自动备份原存档";
    desc.font = [UIFont systemFontOfSize:12];
    desc.textColor = [UIColor darkGrayColor];
    desc.textAlignment = NSTextAlignmentCenter;
    desc.numberOfLines = 2;
    [self.contentView addSubview:desc];
    y += 60;
    
    // 按钮
    UIButton *btn1 = [self createButtonWithTitle:@"💰 无限金钱" tag:1];
    btn1.frame = CGRectMake(20, y, contentWidth - 40, 44);
    [self.contentView addSubview:btn1];
    y += 54;
    
    UIButton *btn2 = [self createButtonWithTitle:@"🏆 无限金条" tag:2];
    btn2.frame = CGRectMake(20, y, contentWidth - 40, 44);
    [self.contentView addSubview:btn2];
    y += 54;
    
    UIButton *btn3 = [self createButtonWithTitle:@"⚡ 无限体力" tag:3];
    btn3.frame = CGRectMake(20, y, contentWidth - 40, 44);
    [self.contentView addSubview:btn3];
    y += 54;
    
    UIButton *btn4 = [self createButtonWithTitle:@"🎯 无限积分" tag:4];
    btn4.frame = CGRectMake(20, y, contentWidth - 40, 44);
    [self.contentView addSubview:btn4];
    y += 54;
    
    UIButton *btn5 = [self createButtonWithTitle:@"🎁 一键全开" tag:5];
    btn5.frame = CGRectMake(20, y, contentWidth - 40, 44);
    btn5.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    [self.contentView addSubview:btn5];
    y += 54;
    
    // 提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 30)];
    tip.text = @"⚠️ 修改后会自动退出游戏\n重新打开即可生效";
    tip.font = [UIFont systemFontOfSize:10];
    tip.textColor = [UIColor colorWithRed:1.0 green:0.4 blue:0 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    tip.numberOfLines = 2;
    [self.contentView addSubview:tip];
    y += 40;
    
    // 版权
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    copyright.text = @"© 2025  𝐈𝐎𝐒𝐃𝐊 科技虎";
    copyright.font = [UIFont systemFontOfSize:12];
    copyright.textColor = [UIColor lightGrayColor];
    copyright.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:copyright];
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
    btn.backgroundColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    NSString *title = @"";
    NSString *message = @"";
    
    switch (sender.tag) {
        case 1:
            title = @"💰 无限金钱";
            message = @"修改后游戏会自动退出\n重新打开即可看到效果\n\n确认修改？";
            break;
        case 2:
            title = @"🏆 无限金条";
            message = @"修改后游戏会自动退出\n重新打开即可看到效果\n\n确认修改？";
            break;
        case 3:
            title = @"⚡ 无限体力";
            message = @"修改后游戏会自动退出\n重新打开即可看到效果\n\n确认修改？";
            break;
        case 4:
            title = @"🎯 无限积分";
            message = @"修改后游戏会自动退出\n重新打开即可看到效果\n\n确认修改？";
            break;
        case 5:
            title = @"🎁 一键全开";
            message = @"将修改所有数值为最大\n修改后游戏会自动退出\n\n确认修改？";
            break;
    }
    
    UIAlertController *confirm = [UIAlertController alertControllerWithTitle:title 
        message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [confirm addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [confirm addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL success = NO;
            
            switch (sender.tag) {
                case 1:
                    success = smartModify(999999999, 0, 0, 0, 0);
                    break;
                case 2:
                    success = smartModify(0, 999999999, 0, 0, 0);
                    break;
                case 3:
                    success = smartModify(0, 0, 999999999, 0, 0);
                    break;
                case 4:
                    success = smartModify(0, 0, 0, 0, 999999999);
                    break;
                case 5:
                    success = smartModify(999999999, 999999999, 999999999, 100, 999999999);
                    break;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"✅ 修改成功" 
                        message:@"游戏将在2秒后自动退出\n重新打开即可看到效果" 
                        preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
                    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
                    [rootVC presentViewController:alert animated:YES completion:^{
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            exitGame();
                        });
                    }];
                } else {
                    [self showAlert:@"❌ 修改失败\n请查看日志"];
                }
            });
        });
    }]];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:confirm animated:YES completion:nil];
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
    g_menuView = [[TXSmartMenuView alloc] initWithFrame:windowBounds];
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
        if (!keyWindow) return;
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(20, 100, 50, 50);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"🎯" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:24];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(tx_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(tx_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
        NSLog(@"[TX] 智能修改器初始化成功");
    });
}

@implementation NSValue (TXSmart)
+ (void)tx_showMenu { showMenu(); }
+ (void)tx_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void TXSmartInit(void) {
    @autoreleasepool {
        NSLog(@"[TX] 天选打工人智能修改器初始化...");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}
