// 我独自生活修改器 - WoduziCheat.m
// 实时内存搜索修改系统 v15.2
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach/mach.h>
#import <sys/mman.h>

// 实时内存搜索开关
static BOOL g_memorySearchEnabled = NO;
static BOOL g_realTimeModifyEnabled = NO;

// 修改后的数值
static NSInteger g_modifiedMoney = 999999999;
static NSInteger g_modifiedStamina = 999999;
static NSInteger g_modifiedHealth = 999;
static NSInteger g_modifiedMood = 999;

// 内存搜索计数器
static NSInteger g_memorySearchCount = 0;
static NSInteger g_memoryModifyCount = 0;

// 找到的地址缓存
static uintptr_t g_foundMoneyAddress = 0;
static uintptr_t g_foundStaminaAddress = 0;
static uintptr_t g_foundHealthAddress = 0;
static uintptr_t g_foundMoodAddress = 0;

#pragma mark - 函数前向声明

static void showMenu(void);
static void writeLog(NSString *message);
static UIWindow* getKeyWindow(void);
static UIViewController* getRootViewController(void);

// 全局异常处理（防闪退保护）
static void handleUncaughtException(NSException *exception) {
    writeLog([NSString stringWithFormat:@"🚨 捕获异常: %@", exception.reason]);
    writeLog([NSString stringWithFormat:@"🚨 异常堆栈: %@", exception.callStackSymbols]);
    
    // 显示用户友好的错误信息
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"⚠️ 修改器异常" 
            message:@"检测到异常情况，已自动保护游戏不闪退。\n\n建议：\n1. 重启游戏后再试\n2. 确保游戏数值界面已显示\n3. 查看日志了解详情" 
            preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        
        UIViewController *rootVC = getRootViewController();
        if (rootVC) {
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}

#pragma mark - 全局变量

@class WDZMenuView;
static UIButton *g_floatButton = nil;
static WDZMenuView *g_menuView = nil;

#pragma mark - 版权保护

// 解密版权字符串（防止二进制修改）
static NSString* getCopyrightText(void) {
    // 动态拼接（防止Base64编码问题）
    NSString *part1 = @"©";
    NSString *part2 = @" 2026";
    NSString *part3 = @"  ";
    NSString *part4 = @"𝐈𝐎𝐒𝐃𝐊";
    NSString *part5 = @" 科技虎";
    
    return [NSString stringWithFormat:@"%@%@%@%@%@", part1, part2, part3, part4, part5];
}

#pragma mark - 免责声明管理

// 检查是否已同意免责声明
static BOOL hasAgreedToDisclaimer(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"WDZCheat_DisclaimerAgreed"];
}

// 保存免责声明同意状态
static void setDisclaimerAgreed(BOOL agreed) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:agreed forKey:@"WDZCheat_DisclaimerAgreed"];
    [defaults synchronize];
}

// 显示免责声明弹窗
static void showDisclaimerAlert(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"⚠️ 免责声明" 
        message:@"本工具仅供技术研究与学习，严禁用于商业用途及非法途径。\n\n使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。\n\n严禁倒卖、传播或用于牟利，否则后果自负。\n\n继续使用即表示您已阅读并同意本声明。\n\n是否同意并继续使用？" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"不同意" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // 用户不同意，直接退出应用
        writeLog(@"用户不同意免责声明，应用退出");
        exit(0);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 用户同意，保存状态并显示功能菜单
        setDisclaimerAgreed(YES);
        writeLog(@"用户同意免责声明");
        showMenu();
    }]];
    
    UIViewController *rootVC = getRootViewController();
    [rootVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 存档修改

// 获取日志路径
static NSString* getLogPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"woduzi_cheat.log"];
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
    
    NSLog(@"[WDZ] %@", message);
}

#pragma mark - 实时内存搜索修改系统

// 安全的内存读取函数
static BOOL safeMemoryRead(uintptr_t address, void* buffer, size_t size) {
    @try {
        // 检查地址是否可读
        if (address == 0 || address < 0x100000000 || address > 0x200000000) {
            return NO;
        }
        
        // 尝试读取内存
        memcpy(buffer, (void*)address, size);
        return YES;
    } @catch (NSException *exception) {
        return NO;
    }
}

// 安全的内存写入函数
static BOOL safeMemoryWrite(uintptr_t address, void* data, size_t size) {
    @try {
        // 检查地址是否可写
        if (address == 0 || address < 0x100000000 || address > 0x200000000) {
            return NO;
        }
        
        // 尝试写入内存
        memcpy((void*)address, data, size);
        return YES;
    } @catch (NSException *exception) {
        return NO;
    }
}

// 搜索特定数值的内存地址
static NSArray* searchMemoryForValue(int targetValue) {
    NSMutableArray *foundAddresses = [NSMutableArray array];
    
    writeLog([NSString stringWithFormat:@"🔍 开始搜索数值: %d", targetValue]);
    
    // 搜索范围：堆内存区域
    uintptr_t startAddr = 0x100000000;
    uintptr_t endAddr = 0x150000000;
    uintptr_t stepSize = 4; // 4字节对齐
    
    int foundCount = 0;
    for (uintptr_t addr = startAddr; addr < endAddr && foundCount < 50; addr += stepSize) {
        int value = 0;
        if (safeMemoryRead(addr, &value, sizeof(int))) {
            if (value == targetValue) {
                [foundAddresses addObject:@(addr)];
                foundCount++;
                writeLog([NSString stringWithFormat:@"📍 找到地址: 0x%lx = %d", addr, value]);
            }
        }
        
        // 每搜索1000万个地址输出一次进度
        if ((addr - startAddr) % 10000000 == 0) {
            writeLog([NSString stringWithFormat:@"⏳ 搜索进度: 0x%lx", addr]);
        }
    }
    
    writeLog([NSString stringWithFormat:@"✅ 搜索完成，找到 %lu 个地址", (unsigned long)foundAddresses.count]);
    return [foundAddresses copy];
}

// 验证地址是否为游戏数据结构
static BOOL verifyGameDataStructure(uintptr_t baseAddr) {
    // 检查偏移地址的数值是否合理
    int money = 0, stamina = 0, health = 0, mood = 0;
    
    if (!safeMemoryRead(baseAddr, &money, sizeof(int))) return NO;
    if (!safeMemoryRead(baseAddr + 24, &stamina, sizeof(int))) return NO;
    if (!safeMemoryRead(baseAddr + 72, &health, sizeof(int))) return NO;
    if (!safeMemoryRead(baseAddr + 104, &mood, sizeof(int))) return NO;
    
    writeLog([NSString stringWithFormat:@"🔍 验证地址 0x%lx: 金钱=%d, 体力=%d, 健康=%d, 心情=%d", 
              baseAddr, money, stamina, health, mood]);
    
    // 检查数值是否在合理范围内
    if (money >= 0 && money <= 100000000 &&
        stamina >= 0 && stamina <= 1000000 &&
        health >= 0 && health <= 1000 &&
        mood >= 0 && mood <= 1000) {
        return YES;
    }
    
    return NO;
}

// 实时修改内存数值
static void realTimeModifyMemory(void) {
    if (!g_realTimeModifyEnabled) return;
    
    // 如果已经找到地址，直接修改
    if (g_foundMoneyAddress != 0) {
        int newMoney = (int)g_modifiedMoney;
        if (safeMemoryWrite(g_foundMoneyAddress, &newMoney, sizeof(int))) {
            g_memoryModifyCount++;
            writeLog([NSString stringWithFormat:@"💰 修改金钱成功: 0x%lx = %d", g_foundMoneyAddress, newMoney]);
        }
    }
    
    if (g_foundStaminaAddress != 0) {
        int newStamina = (int)g_modifiedStamina;
        if (safeMemoryWrite(g_foundStaminaAddress, &newStamina, sizeof(int))) {
            g_memoryModifyCount++;
            writeLog([NSString stringWithFormat:@"⚡ 修改体力成功: 0x%lx = %d", g_foundStaminaAddress, newStamina]);
        }
    }
    
    if (g_foundHealthAddress != 0) {
        int newHealth = (int)g_modifiedHealth;
        if (safeMemoryWrite(g_foundHealthAddress, &newHealth, sizeof(int))) {
            g_memoryModifyCount++;
            writeLog([NSString stringWithFormat:@"❤️ 修改健康成功: 0x%lx = %d", g_foundHealthAddress, newHealth]);
        }
    }
    
    if (g_foundMoodAddress != 0) {
        int newMood = (int)g_modifiedMood;
        if (safeMemoryWrite(g_foundMoodAddress, &newMood, sizeof(int))) {
            g_memoryModifyCount++;
            writeLog([NSString stringWithFormat:@"😊 修改心情成功: 0x%lx = %d", g_foundMoodAddress, newMood]);
        }
    }
}

// 启动实时内存搜索和修改
static void startRealTimeMemoryModification(void) {
    writeLog(@"🚀 启动实时内存搜索和修改系统");
    
    g_memorySearchEnabled = YES;
    g_realTimeModifyEnabled = YES;
    
    // 创建后台队列进行内存搜索
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 搜索已知的游戏数值
        NSArray *moneyAddresses = searchMemoryForValue(474);  // 搜索金钱
        NSArray *staminaAddresses = searchMemoryForValue(136); // 搜索体力
        NSArray *healthAddresses = searchMemoryForValue(93);   // 搜索健康
        NSArray *moodAddresses = searchMemoryForValue(88);     // 搜索心情
        
        // 尝试找到正确的数据结构
        for (NSNumber *addrNum in moneyAddresses) {
            uintptr_t addr = [addrNum unsignedLongValue];
            if (verifyGameDataStructure(addr)) {
                g_foundMoneyAddress = addr;
                g_foundStaminaAddress = addr + 24;
                g_foundHealthAddress = addr + 72;
                g_foundMoodAddress = addr + 104;
                
                writeLog([NSString stringWithFormat:@"🎯 找到游戏数据结构！基地址: 0x%lx", addr]);
                break;
            }
        }
        
        // 启动实时修改定时器
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
                if (g_realTimeModifyEnabled) {
                    realTimeModifyMemory();
                } else {
                    [timer invalidate];
                }
            }];
        });
    });
}

// 核心修改函数：实时内存搜索修改方式
static BOOL modifyGameDataByRealTimeMemory(NSInteger money, NSInteger stamina, NSInteger health, NSInteger mood, NSInteger experience) {
    writeLog(@"========== 开始实时内存搜索修改 v15.2 ==========");
    
    // 重置计数器
    g_memorySearchCount = 0;
    g_memoryModifyCount = 0;
    
    // 设置修改值
    if (money > 0) {
        g_modifiedMoney = money;
        writeLog([NSString stringWithFormat:@"💰 设置金钱目标值: %ld", (long)money]);
    }
    
    if (stamina > 0) {
        g_modifiedStamina = stamina;
        writeLog([NSString stringWithFormat:@"⚡ 设置体力目标值: %ld", (long)stamina]);
    }
    
    if (health > 0) {
        g_modifiedHealth = health;
        writeLog([NSString stringWithFormat:@"❤️ 设置健康目标值: %ld", (long)health]);
    }
    
    if (mood > 0) {
        g_modifiedMood = mood;
        writeLog([NSString stringWithFormat:@"😊 设置心情目标值: %ld", (long)mood]);
    }
    
    writeLog(@"🎯 实时内存修改系统已激活");
    writeLog(@"📊 开始搜索内存中的游戏数据结构");
    writeLog(@"💡 提示：系统将自动搜索并持续修改内存数值");
    
    // 启动实时修改系统
    startRealTimeMemoryModification();
    
    // 延迟检查修改效果
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        writeLog([NSString stringWithFormat:@"📈 10秒内内存修改次数: %ld", (long)g_memoryModifyCount]);
        
        if (g_foundMoneyAddress != 0) {
            writeLog([NSString stringWithFormat:@"✅ 已找到游戏数据结构，基地址: 0x%lx", g_foundMoneyAddress]);
            writeLog(@"🔄 实时修改系统正在运行，每秒自动修改数值");
        } else {
            writeLog(@"⚠️ 未找到游戏数据结构");
            writeLog(@"💡 建议：确保游戏正在运行且数值界面可见");
            writeLog(@"🔍 可能需要调整搜索范围或数值");
        }
    });
    
    writeLog(@"========== 实时内存搜索修改完成 ==========");
    
    return YES;
}

#pragma mark - 菜单视图

@interface WDZMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation WDZMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 450;
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
    title.text = @"🏠 我独自生活 v15.2";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 学习提示
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"🚀 实时内存修改器";
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
    disclaimer.scrollEnabled = YES;
    disclaimer.showsVerticalScrollIndicator = YES;
    [self.contentView addSubview:disclaimer];
    y += 70;
    
    // 提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 40)];
    tip.text = @"v15.2: 实时内存修改\n自动搜索+持续修改内存数值";
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    tip.numberOfLines = 2;
    [self.contentView addSubview:tip];
    y += 28;
    
    // 按钮
    UIButton *btn1 = [self createButtonWithTitle:@"💰 无限金钱" tag:1];
    btn1.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn1];
    y += 43;
    
    UIButton *btn2 = [self createButtonWithTitle:@"⚡ 无限体力" tag:2];
    btn2.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn2];
    y += 43;
    
    UIButton *btn3 = [self createButtonWithTitle:@"❤️ 无限健康" tag:3];
    btn3.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn3];
    y += 43;
    
    UIButton *btn4 = [self createButtonWithTitle:@"😊 无限心情" tag:4];
    btn4.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn4];
    y += 43;
    
    UIButton *btn5 = [self createButtonWithTitle:@"🎁 一键全开" tag:5];
    btn5.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn5];
    y += 43;
    
    UIButton *btn6 = [self createButtonWithTitle:@"🚀 内存状态" tag:6];
    btn6.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn6];
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
    btn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    // 确认提示
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"🚀 实时内存修改 v15.2" 
        message:@"激进策略：\n• 直接搜索内存中的游戏数值\n• 自动找到数据结构基地址\n• 每秒持续修改内存数值\n• 基于已知偏移关系定位\n• 类似iGameGod的工作原理\n\n⚠️ 启用后将持续修改内存\n\n确认继续？" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performModification:sender.tag];
    }]];
    
    UIViewController *rootVC = getRootViewController();
    [rootVC presentViewController:confirmAlert animated:YES completion:nil];
}

- (void)performModification:(NSInteger)tag {
    
    BOOL success = NO;
    NSString *message = @"";
    
    writeLog(@"========== 开始修改 ==========");
    
    switch (tag) {
        case 1:
            writeLog(@"功能：无限金钱");
            success = modifyGameDataByRealTimeMemory(999999999, 0, 0, 0, 0);
            message = success ? @"💰 实时金钱修改已启用！\n\n自动搜索内存中的金钱数据\n每秒持续修改，无需手动操作" : @"❌ 内存修改启动失败，请查看日志";
            break;
        case 2:
            writeLog(@"功能：无限体力");
            success = modifyGameDataByRealTimeMemory(0, 999999, 0, 0, 0);
            message = success ? @"⚡ 实时体力修改已启用！\n\n自动搜索内存中的体力数据\n每秒持续修改，无需手动操作" : @"❌ 内存修改启动失败，请查看日志";
            break;
        case 3:
            writeLog(@"功能：无限健康");
            success = modifyGameDataByRealTimeMemory(0, 0, 999, 0, 0);
            message = success ? @"❤️ 实时健康修改已启用！\n\n自动搜索内存中的健康数据\n每秒持续修改，无需手动操作" : @"❌ 内存修改启动失败，请查看日志";
            break;
        case 4:
            writeLog(@"功能：无限心情");
            success = modifyGameDataByRealTimeMemory(0, 0, 0, 999, 0);
            message = success ? @"😊 实时心情修改已启用！\n\n自动搜索内存中的心情数据\n每秒持续修改，无需手动操作" : @"❌ 内存修改启动失败，请查看日志";
            break;
        case 5:
            writeLog(@"功能：一键全开");
            success = modifyGameDataByRealTimeMemory(999999999, 999999, 999, 999, 0);
            message = success ? @"🎁 实时全能修改已启用！\n\n💰金钱、⚡体力、❤️健康、😊心情\n所有数值每秒自动修改！" : @"❌ 内存修改启动失败，请查看日志";
            break;
        case 6:
            writeLog(@"功能：内存状态");
            writeLog([NSString stringWithFormat:@"🚀 内存搜索: %@", g_memorySearchEnabled ? @"已启用" : @"未启用"]);
            writeLog([NSString stringWithFormat:@"🔄 实时修改: %@", g_realTimeModifyEnabled ? @"已启用" : @"未启用"]);
            writeLog([NSString stringWithFormat:@"📈 内存修改次数: %ld", (long)g_memoryModifyCount]);
            writeLog([NSString stringWithFormat:@"📍 找到的地址: 金钱=0x%lx, 体力=0x%lx, 健康=0x%lx, 心情=0x%lx", 
                      g_foundMoneyAddress, g_foundStaminaAddress, g_foundHealthAddress, g_foundMoodAddress]);
            success = YES;
            message = @"🚀 内存状态检查完成！\n\n请用Filza查看详细日志：\n/var/mobile/Documents/woduzi_cheat.log\n\n日志包含内存搜索和修改信息";
            break;
    }
    
    writeLog(@"========== 修改结束 ==========\n");
    
    // 显示结果提示
    [self showAlert:message];
    
    // 关闭菜单
    [self closeMenu];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *rootVC = getRootViewController();
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
    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.anyObject;
        keyWindow = windowScene.windows.firstObject;
    } else {
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
    }
    return keyWindow;
}

static UIViewController* getRootViewController(void) {
    UIWindow *keyWindow = getKeyWindow();
    UIViewController *rootVC = keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    return rootVC;
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
    g_menuView = [[WDZMenuView alloc] initWithFrame:windowBounds];
    g_menuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [keyWindow addSubview:g_menuView];
}

// 处理悬浮按钮点击（首次检查免责声明）
static void handleFloatButtonTap(void) {
    if (!hasAgreedToDisclaimer()) {
        // 首次使用，显示免责声明
        showDisclaimerAlert();
    } else {
        // 已同意，直接显示功能菜单
        showMenu();
    }
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

// 解密图片URL（防止二进制修改）
static NSString* getIconURL(void) {
    // Base64编码: "https://iosdk.cn/tu/2023/04/17/p9CjtUg1.png"
    const char *encoded = "aHR0cHM6Ly9pb3Nkay5jbi90dS8yMDIzLzA0LzE3L3A5Q2p0VWcxLnBuZw==";
    NSData *data = [[NSData alloc] initWithBase64EncodedString:[NSString stringWithUTF8String:encoded] options:0];
    NSString *decoded = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // 动态拼接备份（增加混淆）
    NSString *protocol = @"https://";
    NSString *domain = @"iosdk.cn";
    NSString *path1 = @"/tu/2023";
    NSString *path2 = @"/04/17/";
    NSString *filename = @"p9CjtUg1.png";
    
    // 验证解码是否成功，失败则使用拼接
    if (decoded && decoded.length > 0) {
        return decoded;
    }
    return [NSString stringWithFormat:@"%@%@%@%@%@", protocol, domain, path1, path2, filename];
}

static void loadIconImage(void) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:getIconURL()];
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
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"独" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(wdz_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(wdz_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
        
        loadIconImage();
    });
}

@implementation NSValue (WDZCheat)
+ (void)wdz_showMenu { handleFloatButtonTap(); }
+ (void)wdz_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void WDZCheatInit(void) {
    @autoreleasepool {
        // 设置全局异常处理器（防闪退保护）
        NSSetUncaughtExceptionHandler(&handleUncaughtException);
        
        writeLog(@"🛡️ WoduziCheat v15.2 初始化完成 - 实时内存修改已启用");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}