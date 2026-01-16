// 云端加载版卡包修仙修改器 - CloudBasedCheat.m
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 全局变量

@class CloudMenuView;
static UIButton *g_floatButton = nil;
static CloudMenuView *g_menuView = nil;
static NSArray *g_cloudFeatures = nil;  // 云端功能列表

#pragma mark - 云端配置结构

@interface CloudFeature : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *successMessage;
@property (nonatomic, strong) NSDictionary *modifications;
@property (nonatomic, assign) BOOL autoRestart;
@end

@implementation CloudFeature
@end

#pragma mark - 云端数据加载

static void loadCloudFeatures(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 云端配置URL - 可以动态更新功能
        NSURL *configURL = [NSURL URLWithString:@"https://your-server.com/api/kabao-features.json"];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:configURL 
                                                 cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                             timeoutInterval:10.0];
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request 
                                                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error || !data) {
                // 如果云端加载失败，使用本地默认配置
                dispatch_async(dispatch_get_main_queue(), ^{
                    loadDefaultFeatures();
                });
                return;
            }
            
            NSError *jsonError;
            NSDictionary *cloudConfig = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            
            if (jsonError || !cloudConfig) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    loadDefaultFeatures();
                });
                return;
            }
            
            // 解析云端配置
            NSMutableArray *features = [NSMutableArray array];
            NSArray *featuresArray = cloudConfig[@"features"];
            
            for (NSDictionary *featureDict in featuresArray) {
                CloudFeature *feature = [[CloudFeature alloc] init];
                feature.title = featureDict[@"title"];
                feature.icon = featureDict[@"icon"];
                feature.successMessage = featureDict[@"successMessage"];
                feature.modifications = featureDict[@"modifications"];
                feature.autoRestart = [featureDict[@"autoRestart"] boolValue];
                [features addObject:feature];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                g_cloudFeatures = [features copy];
                NSLog(@"[CloudCheat] 云端功能加载成功，共%lu个功能", (unsigned long)features.count);
            });
        }];
        
        [task resume];
    });
}

static void loadDefaultFeatures(void) {
    // 本地默认配置，作为云端加载失败时的备用
    NSMutableArray *features = [NSMutableArray array];
    
    // 无限灵石
    CloudFeature *lingshi = [[CloudFeature alloc] init];
    lingshi.title = @"💎 无限灵石";
    lingshi.successMessage = @"💎 无限灵石锁定成功！使用后不会减少";
    lingshi.autoRestart = YES;
    lingshi.modifications = @{
        @"currency": @99999999,
        @"currencyAdd": @99999999,
        @"lingzhi": @99999999,
        @"lingkuang": @99999999,
        @"danyao": @99999999,
        @"faqi": @99999999,
        @"gongfa": @99999999,
        @"linzhiChange": @99999,
        @"lingkuangChange": @99999,
        @"danyaoChange": @99999,
        @"faqiChange": @99999,
        @"gongfaChange": @99999,
        @"currencyReduce": @0,
        @"currencyCost": @0
    };
    [features addObject:lingshi];
    
    // 无限灵气
    CloudFeature *lingqi = [[CloudFeature alloc] init];
    lingqi.title = @"⚡ 无限灵气";
    lingqi.successMessage = @"⚡ 无限灵气锁定成功！使用后不会减少";
    lingqi.autoRestart = YES;
    lingqi.modifications = @{
        @"power": @99999999,
        @"powerAdd": @99999999,
        @"powerAdd2": @99999999,
        @"exp": @99999999,
        @"expAdd2": @99999999,
        @"expReduce": @0,
        @"powerReduce": @0,
        @"powerCost": @0,
        @"energyCost": @0,
        @"spiritCost": @0,
        @"powerChange": @99999,
        @"expChange": @99999
    };
    [features addObject:lingqi];
    
    // 无限血量
    CloudFeature *hp = [[CloudFeature alloc] init];
    hp.title = @"❤️ 无限血量";
    hp.successMessage = @"❤️ 无限血量开启成功！";
    hp.autoRestart = YES;
    hp.modifications = @{
        @"hp": @99999999,
        @"maxHp": @99999999,
        @"saveHp": @99999999
    };
    [features addObject:hp];
    
    // 增加寿命
    CloudFeature *lifespan = [[CloudFeature alloc] init];
    lifespan.title = @"⏰ 增加20年寿命";
    lifespan.successMessage = @"⏰ 增加20年寿命成功！";
    lifespan.autoRestart = YES;
    lifespan.modifications = @{
        @"lifeSpan": @"ADD:20"  // 特殊标记：在当前值基础上增加20
    };
    [features addObject:lifespan];
    
    g_cloudFeatures = [features copy];
    NSLog(@"[CloudCheat] 使用本地默认配置，共%lu个功能", (unsigned long)features.count);
}

#pragma mark - 云端功能执行

static void executeCloudFeature(CloudFeature *feature) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *roleInfoStr = [defaults objectForKey:@"roleInfo"];
    if (!roleInfoStr) return;
    
    NSData *jsonData = [roleInfoStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSMutableDictionary *roleInfo = [[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error] mutableCopy];
    if (error || !roleInfo) return;
    
    // 应用云端配置的修改
    for (NSString *key in feature.modifications) {
        id value = feature.modifications[key];
        
        // 处理特殊操作
        if ([value isKindOfClass:[NSString class]] && [value hasPrefix:@"ADD:"]) {
            // 增加操作
            NSString *addValueStr = [value substringFromIndex:4];
            NSInteger addValue = [addValueStr integerValue];
            NSNumber *currentValue = roleInfo[key];
            if (currentValue) {
                roleInfo[key] = @([currentValue integerValue] + addValue);
            } else {
                roleInfo[key] = @(addValue + 500);  // 默认基础值
            }
        } else {
            // 直接设置
            roleInfo[key] = value;
        }
    }
    
    // 保存修改
    NSData *modifiedJsonData = [NSJSONSerialization dataWithJSONObject:roleInfo options:0 error:&error];
    if (error) return;
    NSString *modifiedRoleInfoStr = [[NSString alloc] initWithData:modifiedJsonData encoding:NSUTF8StringEncoding];
    [defaults setObject:modifiedRoleInfoStr forKey:@"roleInfo"];
    [defaults synchronize];
    
    NSLog(@"[CloudCheat] 功能执行成功: %@", feature.title);
}

#pragma mark - 菜单视图

@interface CloudMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation CloudMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 400;
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
    
    // 右上角关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(contentWidth - 40, 0, 40, 40);
    closeButton.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    closeButton.layer.cornerRadius = 20;
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [closeButton addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    closeButton.layer.zPosition = 1000;
    [self.contentView addSubview:closeButton];
    
    // 标题
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, contentWidth - 60, 30)];
    title.text = @"🎴 卡包修仙 (云端版)";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    // 滚动视图
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, contentWidth, contentHeight - 40)];
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.bounces = YES;
    [self.contentView addSubview:self.scrollView];
    
    [self refreshFeatures];
}

- (void)refreshFeatures {
    // 清除现有内容
    for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }
    
    CGFloat y = 10;
    
    // 云端状态指示
    UILabel *cloudStatus = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 20)];
    cloudStatus.text = g_cloudFeatures ? @"☁️ 云端功能已加载" : @"📱 使用本地配置";
    cloudStatus.font = [UIFont systemFontOfSize:12];
    cloudStatus.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    cloudStatus.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:cloudStatus];
    y += 30;
    
    UITextView *disclaimer = [[UITextView alloc] initWithFrame:CGRectMake(20, y, 240, 50)];
    disclaimer.text = @"云端版本：功能可远程更新，无需重新安装dylib";
    disclaimer.font = [UIFont systemFontOfSize:11];
    disclaimer.textColor = [UIColor lightGrayColor];
    disclaimer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    disclaimer.layer.cornerRadius = 8;
    disclaimer.editable = NO;
    disclaimer.scrollEnabled = NO;
    [self.scrollView addSubview:disclaimer];
    y += 60;
    
    // 动态生成功能按钮
    if (g_cloudFeatures) {
        for (NSInteger i = 0; i < g_cloudFeatures.count; i++) {
            CloudFeature *feature = g_cloudFeatures[i];
            UIButton *btn = [self createButtonWithTitle:feature.title tag:i + 1];
            btn.frame = CGRectMake(20, y, 240, 35);
            [self.scrollView addSubview:btn];
            y += 43;
        }
    }
    
    // 刷新按钮
    UIButton *refreshBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    refreshBtn.frame = CGRectMake(20, y, 240, 30);
    [refreshBtn setTitle:@"🔄 刷新云端配置" forState:UIControlStateNormal];
    [refreshBtn setTitleColor:[UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1] forState:UIControlStateNormal];
    refreshBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    refreshBtn.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    refreshBtn.layer.cornerRadius = 8;
    [refreshBtn addTarget:self action:@selector(refreshCloudConfig) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:refreshBtn];
    y += 40;
    
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 20)];
    copyright.text = @"© 2025 云端版 科技虎";
    copyright.font = [UIFont systemFontOfSize:12];
    copyright.textColor = [UIColor lightGrayColor];
    copyright.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:copyright];
    y += 30;
    
    self.scrollView.contentSize = CGSizeMake(280, y);
}

- (void)refreshCloudConfig {
    UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 240, 20)];
    statusLabel.text = @"🔄 正在刷新云端配置...";
    statusLabel.font = [UIFont systemFontOfSize:12];
    statusLabel.textColor = [UIColor orangeColor];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    statusLabel.tag = 9999;
    [self.scrollView addSubview:statusLabel];
    
    loadCloudFeatures();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIView *oldStatus = [self.scrollView viewWithTag:9999];
        [oldStatus removeFromSuperview];
        [self refreshFeatures];
    });
}

- (UIButton *)createButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    if (sender.tag <= 0 || sender.tag > g_cloudFeatures.count) return;
    
    CloudFeature *feature = g_cloudFeatures[sender.tag - 1];
    executeCloudFeature(feature);
    
    [self showAlert:feature.successMessage];
    
    if (feature.autoRestart) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            exit(0);
        });
    }
}

- (void)closeMenu {
    [self removeFromSuperview];
    g_menuView = nil;
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

#pragma mark - 悬浮按钮 (与原版相同)

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
    g_menuView = [[CloudMenuView alloc] initWithFrame:windowBounds];
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

static void setupFloatingButton(void) {
    if (g_floatButton) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = getKeyWindow();
        if (!keyWindow) return;
        
        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(20, 100, 50, 50);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"虎" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(cloud_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(cloud_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
    });
}

@implementation NSValue (CloudCheat)
+ (void)cloud_showMenu { showMenu(); }
+ (void)cloud_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void CloudCheatInit(void) {
    @autoreleasepool {
        // 启动时加载云端配置
        loadCloudFeatures();
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}