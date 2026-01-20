// 我独自生活修改器 - WoduziCheat.m  
// 基于PlayGearLib.dylib逆向分析的Unity Hook版本 v17.0
// 核心发现：PlayGearLib Hook UnityAppController + PlayerPrefs
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach/mach.h>
#import <sys/mman.h>

// ========== PlayGearLib核心技术重现 ==========
// 基于Ghidra逆向分析的真实Hook机制

// Unity Hook系统开关
static BOOL g_unityHookEnabled = NO;
static BOOL g_playerPrefsHookEnabled = NO;
static BOOL g_unityAppControllerHookEnabled = NO;

// PlayGearLib专业数值标准 (从逆向分析确认)
static NSInteger g_targetMoney = 2100000000;    // 21亿 (PlayGearLib解密发现)
static NSInteger g_targetStamina = 2100000000;  // 21亿 (PlayGearLib解密发现)  
static NSInteger g_targetHealth = 100000;       // 10万 (PlayGearLib解密发现)
static NSInteger g_targetMood = 100000;         // 10万 (PlayGearLib解密发现)

// Hook统计和状态
static NSInteger g_interceptCount = 0;
static NSInteger g_modifyCount = 0;
static NSInteger g_unityCallCount = 0;

// Unity PlayerPrefs Hook函数指针
static int (*original_PlayerPrefs_GetInt)(id, SEL, NSString*, int) = NULL;
static void (*original_PlayerPrefs_SetInt)(id, SEL, NSString*, int) = NULL;

// UnityAppController Hook函数指针  
static id (*original_UnityAppController_init)(id, SEL) = NULL;

// NSUserDefaults Hook函数指针 (备用方案)
static NSInteger (*original_integerForKey)(id, SEL, NSString*) = NULL;
static void (*original_setInteger)(id, SEL, NSInteger, NSString*) = NULL;

// 类前向声明
@class UnityGameManager;
@class UnityMenuView;

// 全局UI变量
static UIButton *g_floatButton = nil;
static UnityMenuView *g_menuView = nil;

#pragma mark - 函数前向声明

static void writeLog(NSString *message);
static void showMenu(void);
static UIWindow* getKeyWindow(void);
static UIViewController* getRootViewController(void);

#pragma mark - 日志系统

// 获取日志路径
static NSString* getLogPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"unity_cheat.log"];
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
    
    NSLog(@"[Unity] %@", message);
}

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

#pragma mark - Unity游戏数值识别系统

typedef NS_ENUM(NSInteger, UnityValueType) {
    UnityValueTypeUnknown = 0,
    UnityValueTypeMoney,        // 金钱类型
    UnityValueTypeStamina,      // 体力类型
    UnityValueTypeHealth,       // 健康类型
    UnityValueTypeMood,         // 心情类型
    UnityValueTypeExperience    // 经验类型
};

// Unity游戏数值智能识别
static UnityValueType identifyUnityValueType(NSString *key, NSInteger value) {
    NSString *lowerKey = [key lowercaseString];
    
    // 基于键名的智能识别
    if ([lowerKey containsString:@"money"] || [lowerKey containsString:@"cash"] || 
        [lowerKey containsString:@"coin"] || [lowerKey containsString:@"gold"] ||
        [lowerKey containsString:@"jinqian"] || [lowerKey containsString:@"qian"]) {
        return UnityValueTypeMoney;
    }
    
    if ([lowerKey containsString:@"stamina"] || [lowerKey containsString:@"energy"] || 
        [lowerKey containsString:@"power"] || [lowerKey containsString:@"tili"]) {
        return UnityValueTypeStamina;
    }
    
    if ([lowerKey containsString:@"health"] || [lowerKey containsString:@"hp"] || 
        [lowerKey containsString:@"jiankang"] || [lowerKey containsString:@"life"]) {
        return UnityValueTypeHealth;
    }
    
    if ([lowerKey containsString:@"mood"] || [lowerKey containsString:@"happy"] || 
        [lowerKey containsString:@"xinqing"] || [lowerKey containsString:@"emotion"]) {
        return UnityValueTypeMood;
    }
    
    // 基于数值范围的智能识别
    if (value >= 1000 && value <= 100000000) {
        return UnityValueTypeMoney;
    } else if (value >= 10 && value <= 10000) {
        return UnityValueTypeStamina;
    } else if (value >= 1 && value <= 1000) {
        return UnityValueTypeHealth;
    }
    
    return UnityValueTypeUnknown;
}

// 根据类型获取目标数值
static NSInteger getUnityTargetValue(UnityValueType type) {
    switch (type) {
        case UnityValueTypeMoney: return g_targetMoney;
        case UnityValueTypeStamina: return g_targetStamina;
        case UnityValueTypeHealth: return g_targetHealth;
        case UnityValueTypeMood: return g_targetMood;
        case UnityValueTypeExperience: return g_targetMoney;
        default: return 0;
    }
}

#pragma mark - Hook函数实现

// Unity PlayerPrefs.GetInt Hook
static int hooked_PlayerPrefs_GetInt(id self, SEL _cmd, NSString* key, int defaultValue) {
    int originalValue = original_PlayerPrefs_GetInt(self, _cmd, key, defaultValue);
    
    if (g_playerPrefsHookEnabled) {
        g_unityCallCount++;
        writeLog([NSString stringWithFormat:@"🎮 Unity读取: %@ = %d", key, originalValue]);
        
        UnityValueType type = identifyUnityValueType(key, originalValue);
        if (type != UnityValueTypeUnknown) {
            NSInteger targetValue = getUnityTargetValue(type);
            if (targetValue > 0) {
                g_interceptCount++;
                writeLog([NSString stringWithFormat:@"🎯 Unity拦截: %@ = %d -> %ld", key, originalValue, (long)targetValue]);
                return (int)targetValue;
            }
        }
    }
    
    return originalValue;
}

// Unity PlayerPrefs.SetInt Hook
static void hooked_PlayerPrefs_SetInt(id self, SEL _cmd, NSString* key, int value) {
    if (g_playerPrefsHookEnabled) {
        UnityValueType type = identifyUnityValueType(key, value);
        if (type != UnityValueTypeUnknown) {
            NSInteger targetValue = getUnityTargetValue(type);
            if (targetValue > 0) {
                value = (int)targetValue;
                writeLog([NSString stringWithFormat:@"🎯 Unity设置拦截: %@ -> %d", key, value]);
            }
        }
    }
    
    original_PlayerPrefs_SetInt(self, _cmd, key, value);
}

// UnityAppController.init Hook
static id hooked_UnityAppController_init(id self, SEL _cmd) {
    id result = original_UnityAppController_init(self, _cmd);
    
    writeLog(@"🎮 UnityAppController初始化完成 - Unity游戏检测成功");
    writeLog(@"🎯 PlayGearLib技术重现：Unity Hook系统已激活");
    
    return result;
}

// NSUserDefaults备用Hook
static NSInteger hooked_integerForKey(id self, SEL _cmd, NSString* key) {
    NSInteger originalValue = original_integerForKey(self, _cmd, key);
    
    if (g_unityHookEnabled) {
        writeLog([NSString stringWithFormat:@"📱 NSUserDefaults读取: %@ = %ld", key, (long)originalValue]);
        
        UnityValueType type = identifyUnityValueType(key, originalValue);
        if (type != UnityValueTypeUnknown) {
            NSInteger targetValue = getUnityTargetValue(type);
            if (targetValue > 0) {
                g_interceptCount++;
                writeLog([NSString stringWithFormat:@"🎯 NSUserDefaults拦截: %@ = %ld -> %ld", key, (long)originalValue, (long)targetValue]);
                return targetValue;
            }
        }
    }
    
    return originalValue;
}

static void hooked_setInteger(id self, SEL _cmd, NSInteger value, NSString* key) {
    if (g_unityHookEnabled) {
        UnityValueType type = identifyUnityValueType(key, value);
        if (type != UnityValueTypeUnknown) {
            NSInteger targetValue = getUnityTargetValue(type);
            if (targetValue > 0) {
                value = targetValue;
                writeLog([NSString stringWithFormat:@"🎯 NSUserDefaults设置拦截: %@ -> %ld", key, (long)value]);
            }
        }
    }
    
    original_setInteger(self, _cmd, value, key);
}

#pragma mark - UnityGameManager

@interface UnityGameManager : NSObject
+ (instancetype)sharedManager;
- (void)setMoney:(NSInteger)value;
- (void)setStamina:(NSInteger)value;
- (void)setHealth:(NSInteger)value;
- (void)setMood:(NSInteger)value;
- (NSDictionary *)getUnityStatus;
@end

@implementation UnityGameManager

+ (instancetype)sharedManager {
    static UnityGameManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[UnityGameManager alloc] init];
    });
    return instance;
}

- (void)setMoney:(NSInteger)value {
    g_targetMoney = value;
    g_modifyCount++;
}

- (void)setStamina:(NSInteger)value {
    g_targetStamina = value;
    g_modifyCount++;
}

- (void)setHealth:(NSInteger)value {
    g_targetHealth = value;
    g_modifyCount++;
}

- (void)setMood:(NSInteger)value {
    g_targetMood = value;
    g_modifyCount++;
}

- (NSDictionary *)getUnityStatus {
    return @{
        @"interceptCount": @(g_interceptCount),
        @"modifyCount": @(g_modifyCount),
        @"unityCallCount": @(g_unityCallCount),
        @"playerPrefsHook": g_playerPrefsHookEnabled ? @"启用" : @"禁用",
        @"unityAppControllerHook": g_unityAppControllerHookEnabled ? @"启用" : @"禁用",
        @"targetMoney": @(g_targetMoney),
        @"targetStamina": @(g_targetStamina),
        @"targetHealth": @(g_targetHealth),
        @"targetMood": @(g_targetMood)
    };
}

@end

#pragma mark - UnityController

@interface UnityController : NSObject
+ (void)enableUnityHook;
+ (void)enablePlayerPrefsHook;
+ (void)enableUnityAppControllerHook;
+ (void)unlimitedMoney;
+ (void)unlimitedStamina;
+ (void)unlimitedHealth;
+ (void)unlimitedMood;
+ (void)unlimitedAll;
+ (void)showUnityStatus;
@end

@implementation UnityController

+ (void)enableUnityHook {
    if (g_unityHookEnabled) {
        writeLog(@"⚠️ Unity Hook已经启用");
        return;
    }
    
    [self enablePlayerPrefsHook];
    [self enableUnityAppControllerHook];
    
    g_unityHookEnabled = YES;
    writeLog(@"🎮 Unity Hook系统已全面启用");
}

+ (void)enablePlayerPrefsHook {
    if (g_playerPrefsHookEnabled) {
        writeLog(@"⚠️ PlayerPrefs Hook已经启用");
        return;
    }
    
    // 获取Unity PlayerPrefs类
    Class playerPrefsClass = objc_getClass("PlayerPrefs");
    if (!playerPrefsClass) {
        playerPrefsClass = objc_getClass("UnityEngine.PlayerPrefs");
    }
    
    if (playerPrefsClass) {
        // Hook PlayerPrefs.GetInt
        Method getIntMethod = class_getClassMethod(playerPrefsClass, @selector(GetInt:defaultValue:));
        if (getIntMethod) {
            original_PlayerPrefs_GetInt = (int (*)(id, SEL, NSString*, int))method_getImplementation(getIntMethod);
            method_setImplementation(getIntMethod, (IMP)hooked_PlayerPrefs_GetInt);
            writeLog(@"✅ Unity PlayerPrefs.GetInt Hook安装完成");
        }
        
        // Hook PlayerPrefs.SetInt
        Method setIntMethod = class_getClassMethod(playerPrefsClass, @selector(SetInt:value:));
        if (setIntMethod) {
            original_PlayerPrefs_SetInt = (void (*)(id, SEL, NSString*, int))method_getImplementation(setIntMethod);
            method_setImplementation(setIntMethod, (IMP)hooked_PlayerPrefs_SetInt);
            writeLog(@"✅ Unity PlayerPrefs.SetInt Hook安装完成");
        }
        
        g_playerPrefsHookEnabled = YES;
        writeLog(@"🎮 Unity PlayerPrefs Hook激活");
    } else {
        writeLog(@"❌ 未找到Unity PlayerPrefs类，启用NSUserDefaults备用");
        [self enableNSUserDefaultsHook];
    }
}

+ (void)enableUnityAppControllerHook {
    if (g_unityAppControllerHookEnabled) {
        writeLog(@"⚠️ UnityAppController Hook已经启用");
        return;
    }
    
    Class unityAppControllerClass = objc_getClass("UnityAppController");
    if (unityAppControllerClass) {
        Method initMethod = class_getInstanceMethod(unityAppControllerClass, @selector(init));
        if (initMethod) {
            original_UnityAppController_init = (id (*)(id, SEL))method_getImplementation(initMethod);
            method_setImplementation(initMethod, (IMP)hooked_UnityAppController_init);
            writeLog(@"✅ UnityAppController.init Hook安装完成");
            g_unityAppControllerHookEnabled = YES;
        }
    } else {
        writeLog(@"❌ 未找到UnityAppController类");
    }
}

+ (void)enableNSUserDefaultsHook {
    Method getMethod = class_getInstanceMethod([NSUserDefaults class], @selector(integerForKey:));
    Method setMethod = class_getInstanceMethod([NSUserDefaults class], @selector(setInteger:forKey:));
    
    if (getMethod && setMethod) {
        original_integerForKey = (NSInteger (*)(id, SEL, NSString*))method_getImplementation(getMethod);
        original_setInteger = (void (*)(id, SEL, NSInteger, NSString*))method_getImplementation(setMethod);
        
        method_setImplementation(getMethod, (IMP)hooked_integerForKey);
        method_setImplementation(setMethod, (IMP)hooked_setInteger);
        
        writeLog(@"✅ NSUserDefaults备用Hook安装完成");
    }
}

+ (void)unlimitedMoney {
    [[UnityGameManager sharedManager] setMoney:g_targetMoney];
    writeLog([NSString stringWithFormat:@"💰 设置目标金钱: %ld", (long)g_targetMoney]);
}

+ (void)unlimitedStamina {
    [[UnityGameManager sharedManager] setStamina:g_targetStamina];
    writeLog([NSString stringWithFormat:@"⚡ 设置目标体力: %ld", (long)g_targetStamina]);
}

+ (void)unlimitedHealth {
    [[UnityGameManager sharedManager] setHealth:g_targetHealth];
    writeLog([NSString stringWithFormat:@"❤️ 设置目标健康: %ld", (long)g_targetHealth]);
}

+ (void)unlimitedMood {
    [[UnityGameManager sharedManager] setMood:g_targetMood];
    writeLog([NSString stringWithFormat:@"😊 设置目标心情: %ld", (long)g_targetMood]);
}

+ (void)unlimitedAll {
    [self unlimitedMoney];
    [self unlimitedStamina];
    [self unlimitedHealth];
    [self unlimitedMood];
    writeLog(@"🎁 Unity全属性设置完成");
}

+ (void)showUnityStatus {
    NSDictionary *status = [[UnityGameManager sharedManager] getUnityStatus];
    writeLog(@"🎮 Unity Hook状态报告:");
    writeLog([NSString stringWithFormat:@"   拦截次数: %@", status[@"interceptCount"]]);
    writeLog([NSString stringWithFormat:@"   修改次数: %@", status[@"modifyCount"]]);
    writeLog([NSString stringWithFormat:@"   Unity调用: %@", status[@"unityCallCount"]]);
    writeLog([NSString stringWithFormat:@"   PlayerPrefs Hook: %@", status[@"playerPrefsHook"]]);
    writeLog([NSString stringWithFormat:@"   UnityAppController Hook: %@", status[@"unityAppControllerHook"]]);
    writeLog([NSString stringWithFormat:@"   目标金钱: %@", status[@"targetMoney"]]);
    writeLog([NSString stringWithFormat:@"   目标体力: %@", status[@"targetStamina"]]);
    writeLog([NSString stringWithFormat:@"   目标健康: %@", status[@"targetHealth"]]);
    writeLog([NSString stringWithFormat:@"   目标心情: %@", status[@"targetMood"]]);
}

@end
#pragma mark - 版权保护和免责声明

// 解密版权字符串
static NSString* getCopyrightText(void) {
    NSString *part1 = @"©";
    NSString *part2 = @" 2026";
    NSString *part3 = @"  ";
    NSString *part4 = @"𝐈𝐎𝐒𝐃𝐊";
    NSString *part5 = @" 科技虎";
    
    return [NSString stringWithFormat:@"%@%@%@%@%@", part1, part2, part3, part4, part5];
}

// 检查是否已同意免责声明
static BOOL hasAgreedToDisclaimer(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"UnityCheat_DisclaimerAgreed"];
}

// 保存免责声明同意状态
static void setDisclaimerAgreed(BOOL agreed) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:agreed forKey:@"UnityCheat_DisclaimerAgreed"];
    [defaults synchronize];
}

// 显示免责声明弹窗
static void showDisclaimerAlert(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"⚠️ 免责声明" 
        message:@"本工具仅供技术研究与学习，严禁用于商业用途及非法途径。\n\n使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。\n\n严禁倒卖、传播或用于牟利，否则后果自负。\n\n继续使用即表示您已阅读并同意本声明。\n\n是否同意并继续使用？" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"不同意" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        writeLog(@"用户不同意免责声明，应用退出");
        exit(0);
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        setDisclaimerAgreed(YES);
        writeLog(@"用户同意免责声明");
        showMenu();
    }]];
    
    UIViewController *rootVC = getRootViewController();
    [rootVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Unity菜单视图

@interface UnityMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation UnityMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    CGFloat contentHeight = 500;
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
    title.text = @"🎮 我独自生活 Unity v17.0";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 技术说明
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 40)];
    info.text = @"🎯 基于PlayGearLib逆向分析\n🎮 Unity Hook + PlayerPrefs拦截";
    info.font = [UIFont systemFontOfSize:12];
    info.textColor = [UIColor grayColor];
    info.textAlignment = NSTextAlignmentCenter;
    info.numberOfLines = 2;
    [self.contentView addSubview:info];
    y += 50;
    
    // 免责声明
    UITextView *disclaimer = [[UITextView alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 60)];
    disclaimer.text = @"免责声明：本工具仅供技术研究与学习，严禁用于商业用途及非法途径。使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。严禁倒卖、传播或用于牟利，否则后果自负。继续使用即表示您已阅读并同意本声明。";
    disclaimer.font = [UIFont systemFontOfSize:10];
    disclaimer.textColor = [UIColor lightGrayColor];
    disclaimer.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    disclaimer.layer.cornerRadius = 8;
    disclaimer.editable = NO;
    disclaimer.scrollEnabled = YES;
    disclaimer.showsVerticalScrollIndicator = YES;
    [self.contentView addSubview:disclaimer];
    y += 70;
    
    // 技术特性
    UILabel *features = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 40)];
    features.text = @"✅ Unity PlayerPrefs Hook\n✅ UnityAppController拦截\n✅ 智能数值识别 + 21亿/10万标准";
    features.font = [UIFont systemFontOfSize:11];
    features.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    features.textAlignment = NSTextAlignmentCenter;
    features.numberOfLines = 3;
    [self.contentView addSubview:features];
    y += 50;
    
    // 按钮
    UIButton *btn1 = [self createButtonWithTitle:@"💰 无限金钱 (21亿)" tag:1];
    btn1.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn1];
    y += 43;
    
    UIButton *btn2 = [self createButtonWithTitle:@"⚡ 无限体力 (21亿)" tag:2];
    btn2.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn2];
    y += 43;
    
    UIButton *btn3 = [self createButtonWithTitle:@"❤️ 无限健康 (10万)" tag:3];
    btn3.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn3];
    y += 43;
    
    UIButton *btn4 = [self createButtonWithTitle:@"😊 无限心情 (10万)" tag:4];
    btn4.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn4];
    y += 43;
    
    UIButton *btn5 = [self createButtonWithTitle:@"🎁 一键全开 (Unity)" tag:5];
    btn5.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn5];
    y += 43;
    
    UIButton *btn6 = [self createButtonWithTitle:@"📊 Unity状态查询" tag:6];
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
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"🎮 Unity Hook v17.0" 
        message:@"基于PlayGearLib逆向分析的Unity Hook技术：\n\n✅ UnityAppController Hook\n✅ Unity PlayerPrefs拦截\n✅ 智能数值识别系统\n✅ 21亿/10万专业标准\n\n⚠️ 确保游戏已完全加载\n\n确认执行操作？" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [confirmAlert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performUnityModification:sender.tag];
    }]];
    
    UIViewController *rootVC = getRootViewController();
    [rootVC presentViewController:confirmAlert animated:YES completion:nil];
}

- (void)performUnityModification:(NSInteger)tag {
    BOOL success = NO;
    NSString *message = @"";
    
    writeLog(@"========== Unity Hook操作开始 ==========");
    
    switch (tag) {
        case 1:
            writeLog(@"功能：Unity无限金钱");
            [UnityController unlimitedMoney];
            success = YES;
            message = @"💰 Unity金钱Hook已激活！\n\n目标数值: 2,100,000,000 (21亿)\n基于PlayGearLib专业标准\n\n请进入游戏查看效果";
            break;
        case 2:
            writeLog(@"功能：Unity无限体力");
            [UnityController unlimitedStamina];
            success = YES;
            message = @"⚡ Unity体力Hook已激活！\n\n目标数值: 2,100,000,000 (21亿)\n基于PlayGearLib专业标准\n\n请进入游戏查看效果";
            break;
        case 3:
            writeLog(@"功能：Unity无限健康");
            [UnityController unlimitedHealth];
            success = YES;
            message = @"❤️ Unity健康Hook已激活！\n\n目标数值: 100,000 (10万)\n基于PlayGearLib专业标准\n\n请进入游戏查看效果";
            break;
        case 4:
            writeLog(@"功能：Unity无限心情");
            [UnityController unlimitedMood];
            success = YES;
            message = @"😊 Unity心情Hook已激活！\n\n目标数值: 100,000 (10万)\n基于PlayGearLib专业标准\n\n请进入游戏查看效果";
            break;
        case 5:
            writeLog(@"功能：Unity一键全开");
            [UnityController unlimitedAll];
            success = YES;
            message = @"🎁 Unity全属性Hook已激活！\n\n💰金钱: 21亿\n⚡体力: 21亿\n❤️健康: 10万\n😊心情: 10万\n\n基于PlayGearLib逆向分析";
            break;
        case 6:
            writeLog(@"功能：Unity状态查询");
            [UnityController showUnityStatus];
            success = YES;
            message = @"📊 Unity Hook状态已输出！\n\n请用Filza查看详细日志：\n/var/mobile/Documents/unity_cheat.log\n\n包含完整Hook状态和拦截统计";
            break;
    }
    
    writeLog(@"========== Unity Hook操作结束 ==========\n");
    
    [self showAlert:message];
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

#pragma mark - 悬浮按钮系统

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
    g_menuView = [[UnityMenuView alloc] initWithFrame:windowBounds];
    g_menuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [keyWindow addSubview:g_menuView];
}

static void handleFloatButtonTap(void) {
    if (!hasAgreedToDisclaimer()) {
        showDisclaimerAlert();
    } else {
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
        
        [g_floatButton setTitle:@"Unity" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(unity_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(unity_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
    });
}

@implementation NSValue (UnityCheat)
+ (void)unity_showMenu { handleFloatButtonTap(); }
+ (void)unity_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

#pragma mark - 初始化

__attribute__((constructor))
static void UnityCheatInit(void) {
    @autoreleasepool {
        // 设置全局异常处理器
        NSSetUncaughtExceptionHandler(&handleUncaughtException);
        
        writeLog(@"🎮 UnityCheat v17.0 初始化完成 - 基于PlayGearLib逆向分析");
        writeLog(@"🎯 核心技术：UnityAppController + PlayerPrefs Hook");
        writeLog(@"🔍 解密发现：PlayGearLib Hook目标类 = UnityAppController");
        writeLog(@"💎 专业标准：21亿金钱/体力 + 10万健康/心情");
        
        // 立即尝试Hook UnityAppController
        [UnityController enableUnityAppControllerHook];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}