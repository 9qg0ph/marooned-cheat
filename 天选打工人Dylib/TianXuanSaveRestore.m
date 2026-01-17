// 天选打工人存档恢复器
// 内置满级存档，点击恢复后自动退出游戏
#import <UIKit/UIKit.h>
#import <sqlite3.h>

#pragma mark - 全局变量

@class TXRestoreMenuView;
static UIButton *g_floatButton = nil;
static TXRestoreMenuView *g_menuView = nil;

// 满级存档数据（从你的存档中提取）
static NSString* getFullSaveData(void) {
    // 这里放入你修改好的完整存档 JSON
    // 从 jsb.sqlite 的 data 表中 key='ssx45sss' 的 value
    return @"{\"info\":{\"money\":999999999,\"mine\":999999999,\"power\":999999999,\"mood\":100,\"integral\":999999999},\"cards\":[{\"id\":1001,\"count\":1,\"exp\":0,\"level\":1},{\"id\":1002,\"count\":1,\"exp\":0,\"level\":1},{\"id\":1003,\"count\":1,\"exp\":0,\"level\":1},{\"id\":2004,\"count\":1,\"exp\":0,\"level\":1},{\"id\":2103,\"count\":1,\"exp\":0,\"level\":1},{\"id\":2106,\"count\":1,\"exp\":0,\"level\":1},{\"id\":3001,\"count\":1,\"exp\":0,\"level\":1},{\"id\":3101,\"count\":1,\"exp\":0,\"level\":1},{\"id\":3201,\"count\":1,\"exp\":0,\"level\":1}],\"calendar\":{\"date\":1,\"giveCardDate\":1,\"time\":0,\"speedUpCount\":10,\"status\":1,\"weather\":1,\"currentOrder\":0,\"pauseTime\":1768678522.761,\"speedDuration\":0,\"cardList\":[],\"emergency\":null,\"speedUpMultiplier\":1,\"curSpeedUpTime\":-1,\"dialogue\":{\"max\":3,\"count\":0}},\"dialogueOptionData\":{},\"drawCardRecord\":{\"freeCount\":0,\"freeTenCount\":0,\"cards\":[],\"recordText\":\"\",\"skipAniStatus\":false},\"houseData\":{\"houses\":[{\"id\":1,\"serviceLife\":1675180800000,\"isForever\":0}],\"furnitures\":{}},\"boxData\":{\"current\":0,\"received\":[]},\"houseUnlockCardData\":[],\"everyDayUsedCards\":[],\"giftData\":[],\"todayGiftData\":[],\"dateTargetData\":{},\"interactionData\":[],\"newestDateTargetId\":0,\"isAddTodayIntimacy\":0,\"chatRecordOpen\":0,\"recordData\":[],\"taskRecordData\":[],\"todayTaskData\":{\"todayEndTime\":1768751999999,\"curLifeStage\":1,\"taskIdList\":[1001,2001,3001,4001]},\"dayRewardRecordData\":[{\"id\":1001,\"isGet\":0,\"type\":0},{\"id\":2001,\"isGet\":0,\"type\":0},{\"id\":3001,\"isGet\":0,\"type\":0},{\"id\":4001,\"isGet\":0,\"type\":0}],\"weekRewardRecordData\":[{\"id\":1,\"isGet\":0,\"type\":1},{\"id\":2,\"isGet\":0,\"type\":1},{\"id\":3,\"isGet\":0,\"type\":1},{\"id\":4,\"isGet\":0,\"type\":1},{\"id\":5,\"isGet\":0,\"type\":1}],\"sumRewardRecordData\":[],\"sumLifeStageRewardRecordData\":[],\"curWeekRewardCount\":0,\"weekEndTime\":1769356799999,\"stageLife\":1,\"newRecordData\":[{\"type\":2,\"record\":{\"1\":3000,\"2\":0,\"3\":100,\"4\":0,\"5\":0},\"todayRecord\":{\"1\":-2000}},{\"type\":23,\"record\":{\"1\":5000},\"todayRecord\":{}},{\"type\":11,\"record\":{\"1\":1},\"todayRecord\":{\"1\":1}},{\"type\":1,\"record\":{\"0\":0},\"todayRecord\":{\"0\":0}}],\"lookVideo\":{},\"guideLifeStepData\":[108,109,110],\"isGuideCard\":1,\"currentLifePageMenu\":\"\",\"isGuide\":0,\"jobSkillExamData\":{},\"examRecordOpen\":0,\"recordPraise\":{\"perfect\":0,\"engagementTask\":0,\"buyHouse\":0,\"praise\":0,\"lastPopTime\":0},\"exchangeCardList\":[],\"weekRefreshExchangeCount\":1,\"todyRefreshExchangeCount\":0,\"fortuneCatEarningsCount\":30,\"fortuneCatEarningsTime\":11.641000000000004,\"lastCatTime\":1768678523919,\"autoCatEarningsCount\":0,\"houseRubbish\":{\"indexPos\":3,\"initTime\":1,\"startTime\":2,\"prgress\":0,\"finish\":0,\"interval\":1},\"fundData\":{\"fundId\":0,\"initTime\":0,\"startTime\":0,\"state\":1,\"interval\":0,\"continuousFailCout\":0,\"fundCount\":0,\"theRead\":0},\"decisionFundData\":{\"name\":\"\",\"dialogue\":0,\"unit_price\":0,\"random_days\":0,\"success_add_percentage\":0,\"success_dialogue\":0,\"fail_reduce_percentage\":0,\"fail_dialogue\":0,\"success_rate\":0,\"show_rate\":0,\"curCount\":0,\"successCount\":0,\"failCount\":0},\"speedUpDay\":0,\"stockData\":{\"levelId\":1,\"buyStock\":[{\"id\":1,\"buyData\":[],\"unlock\":1},{\"id\":2,\"buyData\":[],\"unlock\":1},{\"id\":3,\"buyData\":[],\"unlock\":0},{\"id\":4,\"buyData\":[],\"unlock\":0},{\"id\":5,\"buyData\":[],\"unlock\":0},{\"id\":6,\"buyData\":[],\"unlock\":0},{\"id\":7,\"buyData\":[],\"unlock\":0},{\"id\":8,\"buyData\":[],\"unlock\":0},{\"id\":9,\"buyData\":[],\"unlock\":0},{\"id\":10,\"buyData\":[],\"unlock\":0},{\"id\":11,\"buyData\":[],\"unlock\":0},{\"id\":12,\"buyData\":[],\"unlock\":0}],\"recordOpen\":0},\"stockQuotation\":[{\"id\":1,\"todayRefreshCount\":0,\"priceList\":[10],\"lastRefreshTime\":1768678497071},{\"id\":2,\"todayRefreshCount\":0,\"priceList\":[12],\"lastRefreshTime\":1768678497071},{\"id\":3,\"todayRefreshCount\":0,\"priceList\":[],\"lastRefreshTime\":0},{\"id\":4,\"todayRefreshCount\":0,\"priceList\":[],\"lastRefreshTime\":0},{\"id\":5,\"todayRefreshCount\":0,\"priceList\":[],\"lastRefreshTime\":0},{\"id\":6,\"todayRefreshCount\":0,\"priceList\":[],\"lastRefreshTime\":0},{\"id\":7,\"todayRefreshCount\":0,\"priceList\":[],\"lastRefreshTime\":0},{\"id\":8,\"todayRefreshCount\":0,\"priceList\":[],\"lastRefreshTime\":0},{\"id\":9,\"todayRefreshCount\":0,\"priceList\":[],\"lastRefreshTime\":0},{\"id\":10,\"todayRefreshCount\":0,\"priceList\":[],\"lastRefreshTime\":0},{\"id\":11,\"todayRefreshCount\":0,\"priceList\":[],\"lastRefreshTime\":0},{\"id\":12,\"todayRefreshCount\":0,\"priceList\":[],\"lastRefreshTime\":0}],\"musicEnable\":1,\"soundEnable\":1}";
}

#pragma mark - 存档恢复

// 获取存档路径
static NSString* getSavePath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"jsb.sqlite"];
}

// 恢复存档
static BOOL restoreSave(void) {
    NSString *dbPath = getSavePath();
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        NSLog(@"[TX] 存档文件不存在: %@", dbPath);
        return NO;
    }
    
    // 备份原存档
    NSString *backupPath = [dbPath stringByAppendingString:@".backup"];
    [[NSFileManager defaultManager] copyItemAtPath:dbPath toPath:backupPath error:nil];
    NSLog(@"[TX] 已备份原存档到: %@", backupPath);
    
    sqlite3 *db = NULL;
    if (sqlite3_open([dbPath UTF8String], &db) != SQLITE_OK) {
        NSLog(@"[TX] 打开数据库失败");
        if (db) sqlite3_close(db);
        return NO;
    }
    
    // 获取满级存档数据
    NSString *fullSaveData = getFullSaveData();
    
    // 更新数据库
    const char *updateSQL = "UPDATE data SET value=? WHERE key='ssx45sss'";
    sqlite3_stmt *stmt = NULL;
    
    BOOL success = NO;
    if (sqlite3_prepare_v2(db, updateSQL, -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_text(stmt, 1, [fullSaveData UTF8String], -1, SQLITE_TRANSIENT);
        if (sqlite3_step(stmt) == SQLITE_DONE) {
            success = YES;
            NSLog(@"[TX] 存档恢复成功");
        }
        sqlite3_finalize(stmt);
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

@interface TXRestoreMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation TXRestoreMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 320;
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
    title.text = @"💾 存档恢复器";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 50;
    
    // 说明
    UILabel *desc = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 80)];
    desc.text = @"内置满级存档数据：\n💰 金钱: 999999999\n🏆 金条: 999999999\n⚡ 体力: 999999999\n😊 心情: 100\n🎯 积分: 999999999";
    desc.font = [UIFont systemFontOfSize:12];
    desc.textColor = [UIColor darkGrayColor];
    desc.textAlignment = NSTextAlignmentLeft;
    desc.numberOfLines = 0;
    [self.contentView addSubview:desc];
    y += 90;
    
    // 提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 40)];
    tip.text = @"⚠️ 点击后会自动退出游戏\n重新打开即可生效";
    tip.font = [UIFont systemFontOfSize:11];
    tip.textColor = [UIColor colorWithRed:1.0 green:0.4 blue:0 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    tip.numberOfLines = 2;
    [self.contentView addSubview:tip];
    y += 50;
    
    // 恢复按钮
    UIButton *restoreBtn = [self createButtonWithTitle:@"🎁 恢复满级存档" tag:1];
    restoreBtn.frame = CGRectMake(20, y, contentWidth - 40, 44);
    restoreBtn.backgroundColor = [UIColor colorWithRed:0.3 green:0.8 blue:0.3 alpha:1];
    [self.contentView addSubview:restoreBtn];
    y += 60;
    
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
    // 二次确认
    UIAlertController *confirm = [UIAlertController alertControllerWithTitle:@"⚠️ 确认恢复" 
        message:@"恢复后游戏会自动退出\n重新打开即可看到满级数据\n\n原存档会自动备份" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [confirm addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [confirm addAction:[UIAlertAction actionWithTitle:@"确认恢复" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        // 在后台线程执行
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL success = restoreSave();
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    // 显示成功提示，2秒后退出
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"✅ 恢复成功" 
                        message:@"游戏将在2秒后自动退出\n重新打开即可看到满级数据" 
                        preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
                    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
                    [rootVC presentViewController:alert animated:YES completion:^{
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            exitGame();
                        });
                    }];
                } else {
                    [self showAlert:@"❌ 恢复失败\n请查看日志"];
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
    g_menuView = [[TXRestoreMenuView alloc] initWithFrame:windowBounds];
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
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.3 green:0.8 blue:0.3 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"💾" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:24];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(tx_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(tx_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
        NSLog(@"[TX] 存档恢复器初始化成功");
    });
}

@implementation NSValue (TXRestore)
+ (void)tx_showMenu { showMenu(); }
+ (void)tx_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void TXRestoreInit(void) {
    @autoreleasepool {
        NSLog(@"[TX] 天选打工人存档恢复器初始化...");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}
