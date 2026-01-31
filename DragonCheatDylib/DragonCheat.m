#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sqlite3.h>

 @class DragonCheatView;
 static UIButton *g_floatButton = nil;
 static DragonCheatView *g_menuView = nil;
 
 static UIWindow* getKeyWindow(void);
 static void showMenu(void);
 static void handlePan(UIPanGestureRecognizer *pan);

// 日志文件路径
#define LOG_FILE @"Documents/DragonCheat_Log.txt"

// 写入日志
static void writeLog(NSString *message) {
    NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:LOG_FILE];
    NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
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

// 修改游戏数据 - 操作 SQLite 数据库
static void modifyGameData(NSDictionary *propMap) {
    @try {
        // 获取数据库路径
        NSString *dbPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/jsb.sqlite"];
        
        // 打开数据库
        sqlite3 *db;
        if (sqlite3_open([dbPath UTF8String], &db) != SQLITE_OK) {
            writeLog(@"无法打开数据库");
            return;
        }
        
        // 读取当前的 playerData
        const char *selectSQL = "SELECT value FROM data WHERE key='playerData-release-global'";
        sqlite3_stmt *stmt;
        NSMutableDictionary *playerData = nil;
        
        if (sqlite3_prepare_v2(db, selectSQL, -1, &stmt, NULL) == SQLITE_OK) {
            if (sqlite3_step(stmt) == SQLITE_ROW) {
                const char *jsonStr = (const char *)sqlite3_column_text(stmt, 0);
                NSData *jsonData = [[NSString stringWithUTF8String:jsonStr] dataUsingEncoding:NSUTF8StringEncoding];
                playerData = [[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil] mutableCopy];
            }
        }
        sqlite3_finalize(stmt);
        
        if (!playerData) {
            writeLog(@"无法读取玩家数据");
            sqlite3_close(db);
            return;
        }
        
        // 修改 propMap
        NSMutableDictionary *currentPropMap = [playerData[@"propMap"] mutableCopy];
        [currentPropMap addEntriesFromDictionary:propMap];
        playerData[@"propMap"] = currentPropMap;
        
        // 转换为 JSON
        NSData *newJsonData = [NSJSONSerialization dataWithJSONObject:playerData options:0 error:nil];
        NSString *newJsonStr = [[NSString alloc] initWithData:newJsonData encoding:NSUTF8StringEncoding];
        
        // 更新数据库
        const char *updateSQL = "UPDATE data SET value=? WHERE key='playerData-release-global'";
        if (sqlite3_prepare_v2(db, updateSQL, -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, [newJsonStr UTF8String], -1, SQLITE_TRANSIENT);
            if (sqlite3_step(stmt) == SQLITE_DONE) {
                writeLog(@"数据库修改成功");
            } else {
                writeLog(@"数据库修改失败");
            }
        }
        sqlite3_finalize(stmt);
        sqlite3_close(db);
        
        writeLog([NSString stringWithFormat:@"修改成功 - propMap: %@", propMap]);
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
    // 修改所有货币为最大值
    NSDictionary *propMap = @{
        @"1001": @999999999,  // 金币
        @"1002": @999999999,  // 星星
        @"1003": @999999999,  // 金券
        @"1004": @999999999,  // 其他货币
        @"1006": @999999999   // 体力
    };
    modifyGameData(propMap);
    writeLog(@"[DragonCheat] 已设置无限货币");
}

- (void)setUnlimitedScore {
    // 设置金币和星星
    NSDictionary *propMap = @{
        @"1001": @999999999,  // 金币
        @"1002": @999999999   // 星星
    };
    modifyGameData(propMap);
    writeLog(@"[DragonCheat] 已设置无限金币和星星");
}

- (void)setThreeStars {
    // 设置体力和金券
    NSDictionary *propMap = @{
        @"1003": @999999999,  // 金券
        @"1006": @999999999   // 体力
    };
    modifyGameData(propMap);
    writeLog(@"[DragonCheat] 已设置无限体力和金券");
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"不服来通关" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    
    UIWindow *window = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) {
            window = w;
            break;
        }
    }
    UIViewController *rootVC = window.rootViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (void)closeMenu {
    writeLog(@"[DragonCheat] 关闭菜单");
    [self removeFromSuperview];
    g_menuView = nil;
}

@end

// 悬浮按钮
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
    g_menuView = [[DragonCheatView alloc] initWithFrame:windowBounds];
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
    frame.origin.x = MAX(0, MIN(frame.origin.x, sw - 60));
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
        g_floatButton.frame = CGRectMake(keyWindow.bounds.size.width - 80, 200, 60, 60);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.8];
        g_floatButton.layer.cornerRadius = 30;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;

        [g_floatButton setTitle:@"🐉" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:30];

        [g_floatButton addTarget:[NSValue class] action:@selector(dc_showMenu) forControlEvents:UIControlEventTouchUpInside];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(dc_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];

        [keyWindow addSubview:g_floatButton];
        writeLog(@"[DragonCheat] 悬浮按钮已添加");
    });
}

@implementation NSValue (DragonCheat)
+ (void)dc_showMenu { showMenu(); }
+ (void)dc_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

// 入口函数
__attribute__((constructor)) static void initialize() {
    @autoreleasepool {
        writeLog(@"[DragonCheat] Dylib 加载成功");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}
