// 天选打工人修改器 - TianXuanCheat.m
// 参考卡包修仙的成功实现
#import <UIKit/UIKit.h>
#import <sqlite3.h>

#pragma mark - 全局变量

@class TXMenuView;
static UIButton *g_floatButton = nil;
static TXMenuView *g_menuView = nil;

#pragma mark - 版权保护

// 解密版权字符串（防止二进制修改）
static NSString* getCopyrightText(void) {
    // Base64编码: "© 2026  𝐈𝐎𝐒𝐃𝐊 科技虎"
    const char *encoded = "wqkgMjAyNiAg8JCIiPCQjojwnIyD8JCMiiDnp5bmioDomY4=";
    NSData *data = [[NSData alloc] initWithBase64EncodedString:[NSString stringWithUTF8String:encoded] options:0];
    NSString *decoded = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // 动态拼接（增加混淆）
    NSString *part1 = @"©";
    NSString *part2 = @" 2026";
    NSString *part3 = @"  𝐈𝐎𝐒𝐃𝐊";
    NSString *part4 = @" 科技虎";
    
    // 验证解码是否成功，失败则使用拼接
    if (decoded && decoded.length > 0) {
        return decoded;
    }
    return [NSString stringWithFormat:@"%@%@%@%@", part1, part2, part3, part4];
}

#pragma mark - 存档修改

// 获取存档路径
static NSString* getSavePath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"jsb.sqlite"];
}

// 获取日志路径
static NSString* getLogPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"tianxuan_cheat.log"];
}

// 写日志到文件
static void writeLog(NSString *message) {
    NSString *logPath = getLogPath();
    NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date] 
        dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
    NSString *logMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logPath];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        [logMessage writeToFile:logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    
    NSLog(@"[TX] %@", message);
}

// 智能修改存档（只修改数值，保留进度）
static BOOL modifyGameData(int32_t money, int32_t mine, int32_t power, int32_t mood, int32_t integral) {
    NSString *dbPath = getSavePath();
    
    writeLog([NSString stringWithFormat:@"存档路径: %@", dbPath]);
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        writeLog(@"❌ 存档文件不存在");
        return NO;
    }
    
    writeLog(@"✅ 存档文件存在，开始修改");
    
    // 备份
    NSString *backupPath = [dbPath stringByAppendingString:@".backup"];
    [[NSFileManager defaultManager] removeItemAtPath:backupPath error:nil];
    [[NSFileManager defaultManager] copyItemAtPath:dbPath toPath:backupPath error:nil];
    writeLog([NSString stringWithFormat:@"✅ 已备份到: %@", backupPath]);
    
    // 复制数据库到临时文件进行修改（避免锁定问题）
    NSString *tempPath = [dbPath stringByAppendingString:@".temp"];
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    NSError *copyError = nil;
    [[NSFileManager defaultManager] copyItemAtPath:dbPath toPath:tempPath error:&copyError];
    if (copyError) {
        writeLog([NSString stringWithFormat:@"❌ 复制到临时文件失败: %@", copyError]);
        return NO;
    }
    writeLog(@"✅ 已复制到临时文件");
    
    sqlite3 *db = NULL;
    if (sqlite3_open([tempPath UTF8String], &db) != SQLITE_OK) {
        writeLog([NSString stringWithFormat:@"❌ 打开数据库失败: %s", sqlite3_errmsg(db)]);
        if (db) sqlite3_close(db);
        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
        return NO;
    }
    
    writeLog(@"✅ 数据库打开成功");
    
    // 先查看数据库中有哪些表
    const char *tablesSQL = "SELECT name FROM sqlite_master WHERE type='table'";
    sqlite3_stmt *tablesStmt = NULL;
    if (sqlite3_prepare_v2(db, tablesSQL, -1, &tablesStmt, NULL) == SQLITE_OK) {
        writeLog(@"数据库中的表：");
        while (sqlite3_step(tablesStmt) == SQLITE_ROW) {
            const char *tableName = (const char *)sqlite3_column_text(tablesStmt, 0);
            if (tableName) {
                writeLog([NSString stringWithFormat:@"  - %s", tableName]);
            }
        }
        sqlite3_finalize(tablesStmt);
    }
    
    // 查看data表中有哪些key
    const char *keysSQL = "SELECT key FROM data LIMIT 10";
    sqlite3_stmt *keysStmt = NULL;
    if (sqlite3_prepare_v2(db, keysSQL, -1, &keysStmt, NULL) == SQLITE_OK) {
        writeLog(@"data表中的key（前10个）：");
        while (sqlite3_step(keysStmt) == SQLITE_ROW) {
            const char *keyName = (const char *)sqlite3_column_text(keysStmt, 0);
            if (keyName) {
                writeLog([NSString stringWithFormat:@"  - %s", keyName]);
            }
        }
        sqlite3_finalize(keysStmt);
    }
    
    // 读取存档
    const char *selectSQL = "SELECT value FROM data WHERE key='012345678ssx45sss'";
    sqlite3_stmt *stmt = NULL;
    NSString *jsonString = nil;
    
    if (sqlite3_prepare_v2(db, selectSQL, -1, &stmt, NULL) == SQLITE_OK) {
        if (sqlite3_step(stmt) == SQLITE_ROW) {
            const char *jsonText = (const char *)sqlite3_column_text(stmt, 0);
            if (jsonText) {
                jsonString = [NSString stringWithUTF8String:jsonText];
                writeLog([NSString stringWithFormat:@"✅ 读取到存档数据，长度: %lu", (unsigned long)jsonString.length]);
            }
        }
        sqlite3_finalize(stmt);
    } else {
        writeLog([NSString stringWithFormat:@"❌ SQL准备失败: %s", sqlite3_errmsg(db)]);
    }
    
    if (!jsonString) {
        writeLog(@"❌ 未找到存档数据");
        sqlite3_close(db);
        return NO;
    }
    
    // 解析JSON
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSMutableDictionary *saveDict = [NSJSONSerialization JSONObjectWithData:jsonData 
        options:NSJSONReadingMutableContainers error:&error];
    
    if (error || !saveDict) {
        writeLog([NSString stringWithFormat:@"❌ JSON解析失败: %@", error]);
        sqlite3_close(db);
        return NO;
    }
    
    writeLog(@"✅ JSON解析成功");
    
    // 只修改info字段
    NSMutableDictionary *info = saveDict[@"info"];
    if (!info) {
        writeLog(@"❌ 未找到info字段");
        sqlite3_close(db);
        return NO;
    }
    
    writeLog([NSString stringWithFormat:@"修改前: money=%@, mine=%@, power=%@, mood=%@, integral=%@", 
        info[@"money"], info[@"mine"], info[@"power"], info[@"mood"], info[@"integral"]]);
    
    // 修改数值
    if (money > 0) info[@"money"] = @(money);
    if (mine > 0) info[@"mine"] = @(mine);
    if (power > 0) info[@"power"] = @(power);
    if (mood > 0) info[@"mood"] = @(mood);
    if (integral > 0) info[@"integral"] = @(integral);
    
    writeLog([NSString stringWithFormat:@"修改后: money=%@, mine=%@, power=%@, mood=%@, integral=%@", 
        info[@"money"], info[@"mine"], info[@"power"], info[@"mood"], info[@"integral"]]);
    
    // 转回JSON
    NSData *newJsonData = [NSJSONSerialization dataWithJSONObject:saveDict options:0 error:&error];
    if (error || !newJsonData) {
        writeLog([NSString stringWithFormat:@"❌ JSON序列化失败: %@", error]);
        sqlite3_close(db);
        return NO;
    }
    
    NSString *newJsonString = [[NSString alloc] initWithData:newJsonData encoding:NSUTF8StringEncoding];
    writeLog([NSString stringWithFormat:@"✅ 新JSON长度: %lu", (unsigned long)newJsonString.length]);
    
    // 开始事务
    sqlite3_exec(db, "BEGIN TRANSACTION", NULL, NULL, NULL);
    
    // 更新数据库
    const char *updateSQL = "UPDATE data SET value=? WHERE key='012345678ssx45sss'";
    sqlite3_stmt *updateStmt = NULL;
    
    BOOL success = NO;
    if (sqlite3_prepare_v2(db, updateSQL, -1, &updateStmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(updateStmt, 1, [newJsonString UTF8String], -1, SQLITE_TRANSIENT);
        int result = sqlite3_step(updateStmt);
        if (result == SQLITE_DONE) {
            // 提交事务
            sqlite3_exec(db, "COMMIT", NULL, NULL, NULL);
            success = YES;
            writeLog(@"✅ 数据库更新成功");
        } else {
            // 回滚事务
            sqlite3_exec(db, "ROLLBACK", NULL, NULL, NULL);
            writeLog([NSString stringWithFormat:@"❌ 数据库更新失败: %s", sqlite3_errmsg(db)]);
        }
        sqlite3_finalize(updateStmt);
    } else {
        sqlite3_exec(db, "ROLLBACK", NULL, NULL, NULL);
        writeLog([NSString stringWithFormat:@"❌ 更新SQL准备失败: %s", sqlite3_errmsg(db)]);
    }
    
    sqlite3_close(db);
    
    if (success) {
        // 替换原文件
        [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
        NSError *replaceError = nil;
        [[NSFileManager defaultManager] moveItemAtPath:tempPath toPath:dbPath error:&replaceError];
        if (replaceError) {
            writeLog([NSString stringWithFormat:@"❌ 替换原文件失败: %@", replaceError]);
            // 恢复备份
            [[NSFileManager defaultManager] copyItemAtPath:backupPath toPath:dbPath error:nil];
            return NO;
        }
        writeLog(@"✅ 已替换原文件");
        writeLog(@"🎉 修改完成！");
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    }
    
    return success;
}

#pragma mark - 菜单视图

@interface TXMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation TXMenuView

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
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, contentWidth - 60, 30)];
    title.text = @"💼 天选打工人";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 学习提示
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"🎮 资源仅供学习使用";
    info.font = [UIFont systemFontOfSize:14];
    info.textColor = [UIColor grayColor];
    info.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:info];
    y += 30;
    
    // 免责声明
    UITextView *disclaimer = [[UITextView alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 60)];
    disclaimer.text = @"免责声明：本工具仅供技术研究与学习，严禁用于商业用途及非法途径。使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。严禁倒卖、传播或用于牟利，否则后果自负。继续使用即表示您已阅读并同意本声明。";
    disclaimer.font = [UIFont systemFontOfSize:12];
    disclaimer.textColor = [UIColor lightGrayColor];
    disclaimer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    disclaimer.layer.cornerRadius = 8;
    disclaimer.editable = NO;
    disclaimer.scrollEnabled = NO;
    [self.contentView addSubview:disclaimer];
    y += 70;
    
    // 提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    tip.text = @"功能开启后重启游戏生效";
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:tip];
    y += 28;
    
    // 按钮
    UIButton *btn1 = [self createButtonWithTitle:@"💰 无限金钱" tag:1];
    btn1.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn1];
    y += 43;
    
    UIButton *btn2 = [self createButtonWithTitle:@"🏆 无限金条" tag:2];
    btn2.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn2];
    y += 43;
    
    UIButton *btn3 = [self createButtonWithTitle:@"⚡ 无限体力" tag:3];
    btn3.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn3];
    y += 43;
    
    UIButton *btn5 = [self createButtonWithTitle:@"🎁 一键全开" tag:5];
    btn5.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn5];
    y += 48;
    
    // 版权
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    copyright.text = getCopyrightText();
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
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    // 确认提示
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"⚠️ 确认修改" 
        message:@"点击确定后：\n1. 游戏会立即关闭\n2. 后台自动修改存档\n3. 请手动重新打开游戏查看效果\n\n确认继续？" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performModification:sender.tag];
    }]];
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:confirmAlert animated:YES completion:nil];
}

- (void)performModification:(NSInteger)tag {
    
    BOOL success = NO;
    NSString *message = @"";
    
    writeLog(@"========== 开始修改 ==========");
    
    switch (tag) {
        case 1:
            writeLog(@"功能：无限金钱");
            success = modifyGameData(999999999, 0, 0, 0, 0);
            message = success ? @"💰 无限金钱开启成功！游戏将自动重启生效" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 2:
            writeLog(@"功能：无限金条");
            success = modifyGameData(0, 999999999, 0, 0, 0);
            message = success ? @"🏆 无限金条开启成功！游戏将自动重启生效" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 3:
            writeLog(@"功能：无限体力");
            success = modifyGameData(0, 0, 999999999, 0, 0);
            message = success ? @"⚡ 无限体力开启成功！游戏将自动重启生效" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 4:
            writeLog(@"功能：无限积分");
            success = modifyGameData(0, 0, 0, 0, 999999999);
            message = success ? @"🎯 无限积分开启成功！游戏将自动重启生效" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 5:
            writeLog(@"功能：一键全开");
            success = modifyGameData(999999999, 999999999, 999999999, 100, 999999999);
            message = success ? @"🎁 一键全开成功！\n💰 金钱: 999999999\n🏆 金条: 999999999\n⚡ 体力: 999999999\n😊 心情: 100\n🎯 积分: 999999999\n\n游戏将自动重启生效" : @"❌ 修改失败，请用Filza查看日志";
            break;
    }
    
    writeLog(@"========== 修改结束 ==========\n");
    
    if (success) {
        // 修改成功，延迟0.5秒后退出游戏
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            writeLog(@"🎉 修改成功！游戏即将关闭，请重新打开查看效果");
            exit(0);
        });
    } else {
        [self showAlert:message];
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
    g_menuView = [[TXMenuView alloc] initWithFrame:windowBounds];
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
    [pan setTranslation:CGPointZero inView:keyWindow];
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
        
        [g_floatButton setTitle:@"虎" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(tx_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(tx_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
        
        loadIconImage();
    });
}

@implementation NSValue (TXCheat)
+ (void)tx_showMenu { showMenu(); }
+ (void)tx_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void TXCheatInit(void) {
    @autoreleasepool {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}
