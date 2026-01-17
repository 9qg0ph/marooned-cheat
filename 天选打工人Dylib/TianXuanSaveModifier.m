// 天选打工人存档修改器 - TianXuanSaveModifier.m
// 直接修改 jsb.sqlite 存档数据库
#import <UIKit/UIKit.h>
#import <sqlite3.h>

#pragma mark - 全局变量

@class TXSaveMenuView;
static UIButton *g_floatButton = nil;
static TXSaveMenuView *g_menuView = nil;

#pragma mark - 存档修改

// 获取存档路径
static NSString* getSavePath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"jsb.sqlite"];
}

// 修改存档数据
static BOOL modifySaveData(int32_t money, int32_t mine, int32_t power, int32_t mood, int32_t integral) {
    @try {
        NSString *dbPath = getSavePath();
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
            NSLog(@"[TX] 存档文件不存在: %@", dbPath);
            return NO;
        }
        
        sqlite3 *db = NULL;
        if (sqlite3_open([dbPath UTF8String], &db) != SQLITE_OK) {
            NSLog(@"[TX] 打开数据库失败: %@", [NSString stringWithUTF8String:sqlite3_errmsg(db)]);
            if (db) sqlite3_close(db);
            return NO;
        }
        
        // 读取当前存档JSON
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
        } else {
            NSLog(@"[TX] SQL准备失败: %@", [NSString stringWithUTF8String:sqlite3_errmsg(db)]);
            sqlite3_close(db);
            return NO;
        }
        
        if (!jsonString || jsonString.length == 0) {
            NSLog(@"[TX] 未找到存档数据");
            sqlite3_close(db);
            return NO;
        }
        
        // 解析JSON
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        if (!jsonData) {
            NSLog(@"[TX] JSON数据转换失败");
            sqlite3_close(db);
            return NO;
        }
        
        NSError *error = nil;
        NSMutableDictionary *saveDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        
        if (error || !saveDict || ![saveDict isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[TX] JSON解析失败: %@", error);
            sqlite3_close(db);
            return NO;
        }
        
        // 修改数据
        NSMutableDictionary *info = saveDict[@"info"];
        if (!info || ![info isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[TX] 未找到info字段或格式错误");
            sqlite3_close(db);
            return NO;
        }
        
        // 只修改传入的非零值
        if (money > 0) info[@"money"] = @(money);
        if (mine > 0) info[@"mine"] = @(mine);
        if (power > 0) info[@"power"] = @(power);
        if (mood > 0) info[@"mood"] = @(mood);
        if (integral > 0) info[@"integral"] = @(integral);
        
        // 转回JSON
        NSData *newJsonData = [NSJSONSerialization dataWithJSONObject:saveDict options:0 error:&error];
        if (error || !newJsonData) {
            NSLog(@"[TX] JSON序列化失败: %@", error);
            sqlite3_close(db);
            return NO;
        }
        
        NSString *newJsonString = [[NSString alloc] initWithData:newJsonData encoding:NSUTF8StringEncoding];
        if (!newJsonString) {
            NSLog(@"[TX] JSON字符串转换失败");
            sqlite3_close(db);
            return NO;
        }
        
        // 更新数据库
        const char *updateSQL = "UPDATE data SET value=? WHERE key='ssx45sss'";
        sqlite3_stmt *updateStmt = NULL;
        
        BOOL success = NO;
        if (sqlite3_prepare_v2(db, updateSQL, -1, &updateStmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(updateStmt, 1, [newJsonString UTF8String], -1, SQLITE_TRANSIENT);
            int result = sqlite3_step(updateStmt);
            if (result == SQLITE_DONE) {
                success = YES;
                NSLog(@"[TX] 存档修改成功");
            } else {
                NSLog(@"[TX] 更新失败: %@", [NSString stringWithUTF8String:sqlite3_errmsg(db)]);
            }
            sqlite3_finalize(updateStmt);
        } else {
            NSLog(@"[TX] 更新SQL准备失败: %@", [NSString stringWithUTF8String:sqlite3_errmsg(db)]);
        }
        
        sqlite3_close(db);
        return success;
        
    } @catch (NSException *exception) {
        NSLog(@"[TX] 异常: %@", exception);
        return NO;
    }
}

#pragma mark - 菜单视图

@interface TXSaveMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation TXSaveMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 380;
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
    title.text = @"💾 存档修改器";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 50;
    
    // 提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 40)];
    tip.text = @"⚠️ 直接修改存档数据库\n修改后需重启游戏生效";
    tip.font = [UIFont systemFontOfSize:11];
    tip.textColor = [UIColor colorWithRed:1.0 green:0.4 blue:0 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    tip.numberOfLines = 2;
    [self.contentView addSubview:tip];
    y += 50;
    
    // 按钮
    UIButton *btn1 = [self createButtonWithTitle:@"💰 无限金钱" tag:1];
    btn1.frame = CGRectMake(20, y, 240, 44);
    [self.contentView addSubview:btn1];
    y += 54;
    
    UIButton *btn2 = [self createButtonWithTitle:@"🏆 无限金条" tag:2];
    btn2.frame = CGRectMake(20, y, 240, 44);
    [self.contentView addSubview:btn2];
    y += 54;
    
    UIButton *btn3 = [self createButtonWithTitle:@"⚡ 无限体力" tag:3];
    btn3.frame = CGRectMake(20, y, 240, 44);
    [self.contentView addSubview:btn3];
    y += 54;
    
    UIButton *btn4 = [self createButtonWithTitle:@"🎯 无限积分" tag:4];
    btn4.frame = CGRectMake(20, y, 240, 44);
    [self.contentView addSubview:btn4];
    y += 54;
    
    UIButton *btn5 = [self createButtonWithTitle:@"🎁 一键满级" tag:5];
    btn5.frame = CGRectMake(20, y, 240, 44);
    btn5.backgroundColor = [UIColor colorWithRed:0.3 green:0.8 blue:0.3 alpha:1];
    [self.contentView addSubview:btn5];
    y += 60;
    
    // 版权
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 20)];
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
    // 先检查存档文件是否存在
    NSString *dbPath = getSavePath();
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        [self showAlert:@"❌ 存档文件不存在！\n\n请先启动游戏并进入主界面"];
        return;
    }
    
    // 在后台线程执行，避免阻塞UI
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL success = NO;
        NSString *message = @"";
        
        @try {
            switch (sender.tag) {
                case 1:
                    success = modifySaveData(999999999, 0, 0, 0, 0);
                    message = success ? @"💰 无限金钱设置成功！\n请重启游戏生效" : @"❌ 修改失败！\n请查看日志或联系作者";
                    break;
                case 2:
                    success = modifySaveData(0, 999999999, 0, 0, 0);
                    message = success ? @"🏆 无限金条设置成功！\n请重启游戏生效" : @"❌ 修改失败！\n请查看日志或联系作者";
                    break;
                case 3:
                    success = modifySaveData(0, 0, 999999999, 0, 0);
                    message = success ? @"⚡ 无限体力设置成功！\n请重启游戏生效" : @"❌ 修改失败！\n请查看日志或联系作者";
                    break;
                case 4:
                    success = modifySaveData(0, 0, 0, 0, 999999999);
                    message = success ? @"🎯 无限积分设置成功！\n请重启游戏生效" : @"❌ 修改失败！\n请查看日志或联系作者";
                    break;
                case 5:
                    success = modifySaveData(999999999, 999999999, 999999999, 100, 999999999);
                    message = success ? @"🎁 一键满级成功！\n💰 金钱: 999999999\n🏆 金条: 999999999\n⚡ 体力: 999999999\n😊 心情: 100\n🎯 积分: 999999999\n\n请重启游戏生效" : @"❌ 修改失败！\n请查看日志或联系作者";
                    break;
            }
        } @catch (NSException *exception) {
            NSLog(@"[TX] 按钮处理异常: %@", exception);
            message = [NSString stringWithFormat:@"❌ 发生异常: %@", exception.reason];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlert:message];
        });
    });
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
        if (!keyWindow) return;
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(20, 100, 50, 50);
        g_floatButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"💾" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:24];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(tx_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(tx_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
    });
}

@implementation NSValue (TXSaveCheat)
+ (void)tx_showMenu { showMenu(); }
+ (void)tx_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void TXSaveCheatInit(void) {
    @autoreleasepool {
        @try {
            NSLog(@"[TX] 天选打工人存档修改器初始化...");
            
            // 延迟2秒后显示悬浮按钮，确保游戏已完全启动
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    setupFloatingButton();
                    NSLog(@"[TX] 悬浮按钮创建成功");
                } @catch (NSException *exception) {
                    NSLog(@"[TX] 悬浮按钮创建失败: %@", exception);
                }
            });
        } @catch (NSException *exception) {
            NSLog(@"[TX] 初始化失败: %@", exception);
        }
    }
}
