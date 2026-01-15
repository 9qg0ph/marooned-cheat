// 卡包修仙修改器 - KaBaoXiuXianCheat.m
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#pragma mark - 全局变量前置声明

@class KaBaoMenuView;
static UIButton *g_floatButton = nil;
static KaBaoMenuView *g_menuView = nil;

#pragma mark - 游戏数值修改

// 延时关闭游戏
static void exitGameAfterDelay(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

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

// 修改卡包修仙游戏数据的专用函数
static void modifyKaBaoGameData(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 获取当前的roleInfo数据
    NSString *roleInfoStr = [defaults objectForKey:@"roleInfo"];
    if (!roleInfoStr) {
        NSLog(@"[KaBao] 未找到roleInfo数据");
        return;
    }
    
    // 解析JSON
    NSData *jsonData = [roleInfoStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSMutableDictionary *roleInfo = [[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error] mutableCopy];
    
    if (error || !roleInfo) {
        NSLog(@"[KaBao] JSON解析失败: %@", error);
        return;
    }
    
    // 修改游戏数值
    roleInfo[@"currency"] = @99999999;      // 金币
    roleInfo[@"hp"] = @99999999;            // 生命值
    roleInfo[@"maxHp"] = @99999999;         // 最大生命值
    roleInfo[@"lingzhi"] = @99999;          // 灵芝
    roleInfo[@"lingkuang"] = @99999;        // 灵矿
    roleInfo[@"danyao"] = @99999;           // 丹药
    roleInfo[@"faqi"] = @99999;             // 法器
    roleInfo[@"gongfa"] = @99999;           // 功法
    roleInfo[@"exp"] = @99999999;           // 经验值
    roleInfo[@"power"] = @99999;            // 战力
    
    // 转换回JSON字符串
    NSData *modifiedJsonData = [NSJSONSerialization dataWithJSONObject:roleInfo options:0 error:&error];
    if (error) {
        NSLog(@"[KaBao] JSON序列化失败: %@", error);
        return;
    }
    
    NSString *modifiedRoleInfoStr = [[NSString alloc] initWithData:modifiedJsonData encoding:NSUTF8StringEncoding];
    
    // 保存修改后的数据
    [defaults setObject:modifiedRoleInfoStr forKey:@"roleInfo"];
    [defaults synchronize];
    
    NSLog(@"[KaBao] 游戏数据修改成功");
}

// 无限灵石功能 - 锁定数值不减少
static void enableInfiniteLingshi(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *roleInfoStr = [defaults objectForKey:@"roleInfo"];
    if (!roleInfoStr) return;
    
    NSData *jsonData = [roleInfoStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSMutableDictionary *roleInfo = [[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error] mutableCopy];
    if (error || !roleInfo) return;
    
    // 修改灵石相关资源并锁定
    roleInfo[@"currency"] = @99999999;      // 主货币（灵石）
    roleInfo[@"currencyAdd"] = @99999999;   // 货币增加量
    roleInfo[@"lingzhi"] = @99999999;       // 灵芝
    roleInfo[@"lingkuang"] = @99999999;     // 灵矿
    roleInfo[@"danyao"] = @99999999;        // 丹药
    roleInfo[@"faqi"] = @99999999;          // 法器
    roleInfo[@"gongfa"] = @99999999;        // 功法
    
    // 锁定资源变化量，确保不减反增
    roleInfo[@"linzhiChange"] = @99999;     // 灵芝变化量为正值
    roleInfo[@"lingkuangChange"] = @99999;  // 灵矿变化量为正值
    roleInfo[@"danyaoChange"] = @99999;     // 丹药变化量为正值
    roleInfo[@"faqiChange"] = @99999;       // 法器变化量为正值
    roleInfo[@"gongfaChange"] = @99999;     // 功法变化量为正值
    
    // 尝试锁定可能的消耗相关字段
    roleInfo[@"currencyReduce"] = @0;       // 货币减少量设为0
    roleInfo[@"currencyCost"] = @0;         // 货币消耗设为0
    
    NSData *modifiedJsonData = [NSJSONSerialization dataWithJSONObject:roleInfo options:0 error:&error];
    if (error) return;
    NSString *modifiedRoleInfoStr = [[NSString alloc] initWithData:modifiedJsonData encoding:NSUTF8StringEncoding];
    [defaults setObject:modifiedRoleInfoStr forKey:@"roleInfo"];
    [defaults synchronize];
}

// 无限灵气功能 - 锁定数值不减少
static void enableInfiniteLingqi(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *roleInfoStr = [defaults objectForKey:@"roleInfo"];
    if (!roleInfoStr) return;
    
    NSData *jsonData = [roleInfoStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSMutableDictionary *roleInfo = [[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error] mutableCopy];
    if (error || !roleInfo) return;
    
    // 修改灵气相关数值并锁定
    roleInfo[@"power"] = @99999999;         // 战力/灵气设置为超大值
    roleInfo[@"powerAdd"] = @99999999;      // 灵气增加量设置为超大值
    roleInfo[@"powerAdd2"] = @99999999;     // 额外灵气增加量
    roleInfo[@"exp"] = @99999999;           // 经验值
    roleInfo[@"expAdd2"] = @99999999;       // 经验增加量
    roleInfo[@"expReduce"] = @0;            // 经验减少量设为0
    
    // 尝试锁定可能的灵气消耗相关字段
    roleInfo[@"powerReduce"] = @0;          // 灵气减少量设为0
    roleInfo[@"powerCost"] = @0;            // 灵气消耗设为0
    roleInfo[@"energyCost"] = @0;           // 能量消耗设为0
    roleInfo[@"spiritCost"] = @0;           // 精神消耗设为0
    
    // 修改可能的灵气相关变化量，确保不减反增
    roleInfo[@"powerChange"] = @99999;      // 灵气变化量为正值
    roleInfo[@"expChange"] = @99999;        // 经验变化量为正值
    
    NSData *modifiedJsonData = [NSJSONSerialization dataWithJSONObject:roleInfo options:0 error:&error];
    if (error) return;
    NSString *modifiedRoleInfoStr = [[NSString alloc] initWithData:modifiedJsonData encoding:NSUTF8StringEncoding];
    [defaults setObject:modifiedRoleInfoStr forKey:@"roleInfo"];
    [defaults synchronize];
}

// 无限血量功能
static void enableInfiniteHP(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *roleInfoStr = [defaults objectForKey:@"roleInfo"];
    if (!roleInfoStr) return;
    
    NSData *jsonData = [roleInfoStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSMutableDictionary *roleInfo = [[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error] mutableCopy];
    if (error || !roleInfo) return;
    
    // 修改血量
    roleInfo[@"hp"] = @99999999;        // 当前血量
    roleInfo[@"maxHp"] = @99999999;     // 最大血量
    roleInfo[@"saveHp"] = @99999999;    // 保存血量
    
    NSData *modifiedJsonData = [NSJSONSerialization dataWithJSONObject:roleInfo options:0 error:&error];
    if (error) return;
    NSString *modifiedRoleInfoStr = [[NSString alloc] initWithData:modifiedJsonData encoding:NSUTF8StringEncoding];
    [defaults setObject:modifiedRoleInfoStr forKey:@"roleInfo"];
    [defaults synchronize];
}

// 增加20年寿命功能
static void addLifespan(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *roleInfoStr = [defaults objectForKey:@"roleInfo"];
    if (!roleInfoStr) return;
    
    NSData *jsonData = [roleInfoStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSMutableDictionary *roleInfo = [[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error] mutableCopy];
    if (error || !roleInfo) return;
    
    // 增加寿命
    NSNumber *currentLifeSpan = roleInfo[@"lifeSpan"];
    if (currentLifeSpan) {
        roleInfo[@"lifeSpan"] = @([currentLifeSpan intValue] + 20);  // 增加20年寿命
    } else {
        roleInfo[@"lifeSpan"] = @500;  // 如果没有寿命数据，设置为500
    }
    
    NSData *modifiedJsonData = [NSJSONSerialization dataWithJSONObject:roleInfo options:0 error:&error];
    if (error) return;
    NSString *modifiedRoleInfoStr = [[NSString alloc] initWithData:modifiedJsonData encoding:NSUTF8StringEncoding];
    [defaults setObject:modifiedRoleInfoStr forKey:@"roleInfo"];
    [defaults synchronize];
}

#pragma mark - 菜单视图

@interface KaBaoMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation KaBaoMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 350;
    CGFloat contentWidth = 280;
    // 使用自身尺寸（即父视图尺寸），自动适配横竖屏
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
    
    // 添加右上角关闭按钮
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(contentWidth - 40, 0, 40, 40);  // 增大可点击区域
    closeButton.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    closeButton.layer.cornerRadius = 20;
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];  // 增大字体
    [closeButton addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    closeButton.layer.zPosition = 1000;  // 确保按钮在最上层
    [self.contentView addSubview:closeButton];
    
    // 添加标题到和关闭按钮同一行
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, contentWidth - 60, 30)];
    title.text = @"🎴 卡包修仙";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    // 创建滚动视图 - 为右上角关闭按钮留出空间
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, contentWidth, contentHeight - 40)];
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.bounces = YES;
    [self.contentView addSubview:self.scrollView];
    
    CGFloat y = 10;  // 滚动视图内的相对位置，减少顶部空间
    
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 20)];
    info.text = @"� 资源包仅供学习使用";
    info.font = [UIFont systemFontOfSize:14];
    info.textColor = [UIColor grayColor];
    info.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:info];
    y += 30;

    UITextView *disclaimer = [[UITextView alloc] initWithFrame:CGRectMake(20, y, 240, 60)];
    disclaimer.text = @"免责声明：本工具仅供技术研究与学习，严禁用于商业用途。";
    disclaimer.font = [UIFont systemFontOfSize:12];
    disclaimer.textColor = [UIColor lightGrayColor];
    disclaimer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    disclaimer.layer.cornerRadius = 8;
    disclaimer.editable = NO;
    disclaimer.scrollEnabled = NO;
    [self.scrollView addSubview:disclaimer];
    y += 70;
    
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 20)];
    tip.text = @"功能开启后重启游戏生效";
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:tip];
    y += 28;
    
    // 卡包修仙的四个主要功能
    UIButton *btn1 = [self createButtonWithTitle:@"�  无限灵石" tag:1];
    btn1.frame = CGRectMake(20, y, 240, 35);
    [self.scrollView addSubview:btn1];
    y += 43;
    
    UIButton *btn2 = [self createButtonWithTitle:@"⚡ 无限灵气" tag:2];
    btn2.frame = CGRectMake(20, y, 240, 35);
    [self.scrollView addSubview:btn2];
    y += 43;
    
    UIButton *btn3 = [self createButtonWithTitle:@"❤️ 无限血量" tag:3];
    btn3.frame = CGRectMake(20, y, 240, 35);
    [self.scrollView addSubview:btn3];
    y += 43;
    
    UIButton *btn4 = [self createButtonWithTitle:@"⏰ 增加20年寿命" tag:4];
    btn4.frame = CGRectMake(20, y, 240, 35);
    [self.scrollView addSubview:btn4];
    y += 43;
    
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 20)];
    copyright.text = @"© 2025  𝐈𝐎𝐒𝐃𝐊 科技虎";
    copyright.font = [UIFont systemFontOfSize:12];
    copyright.textColor = [UIColor lightGrayColor];
    copyright.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:copyright];
    y += 30;
    
    // 设置滚动视图的内容大小
    self.scrollView.contentSize = CGSizeMake(contentWidth, y);
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
    btn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    switch (sender.tag) {
        case 1:
            // 无限灵石
            enableInfiniteLingshi();
            [self showAlert:@"� 无限灵石开启成启功！游戏将自动重启生效"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                exit(0);
            });
            break;
        case 2:
            // 无限灵气
            enableInfiniteLingqi();
            [self showAlert:@"⚡ 无限灵气锁定成功！使用后不会减少，游戏将自动重启生效"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                exit(0);
            });
            break;
        case 3:
            // 无限血量
            enableInfiniteHP();
            [self showAlert:@"❤️ 无限血量开启成功！游戏将自动重启生效"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                exit(0);
            });
            break;
        case 4:
            // 增加20年寿命
            addLifespan();
            [self showAlert:@"⏰ 增加20年寿命成功！游戏将自动重启生效"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                exit(0);
            });
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
    
    // 使用当前窗口的实际尺寸（自动适配横竖屏）
    CGRect windowBounds = keyWindow.bounds;
    g_menuView = [[KaBaoMenuView alloc] initWithFrame:windowBounds];
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
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"虎" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(kb_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(kb_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
        
        loadIconImage();
    });
}

@implementation NSValue (KaBaoCheat)
+ (void)kb_showMenu { showMenu(); }
+ (void)kb_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void KaBaoCheatInit(void) {
    @autoreleasepool {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}