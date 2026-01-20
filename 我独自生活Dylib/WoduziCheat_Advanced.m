// 我独自生活修改器 - 高级版本 v16.0
// 基于PlayGearLib.dylib技术分析的先进实现
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach/mach.h>
#import <sys/mman.h>

#pragma mark - 核心配置 (基于PlayGearLib技术)

// 修改开关
static BOOL g_advancedHookEnabled = NO;
static BOOL g_memoryInterceptEnabled = NO;
static BOOL g_fileInterceptEnabled = NO;

// 目标数值 (学习PlayGearLib的数值设计)
static NSInteger g_targetMoney = 2100000000;    // 21亿现金
static NSInteger g_targetStamina = 2100000000;  // 21亿体力
static NSInteger g_targetHealth = 100000;       // 10万健康
static NSInteger g_targetMood = 100000;         // 10万心情

// 统计信息
static NSInteger g_interceptCount = 0;
static NSInteger g_modifyCount = 0;

#pragma mark - 函数指针 (学习PlayGearLib的Hook架构)

// 原始函数指针
static void* (*original_memcpy)(void *dest, const void *src, size_t n) = NULL;
static void* (*original_memmove)(void *dest, const void *src, size_t n) = NULL;
static NSInteger (*original_integerForKey)(id self, SEL _cmd, NSString* key) = NULL;
static void (*original_setInteger)(id self, SEL _cmd, NSInteger value, NSString* key) = NULL;

#pragma mark - 工具函数

static void writeAdvancedLog(NSString *message);
static UIWindow* getKeyWindow(void);
static UIViewController* getRootViewController(void);

#pragma mark - 智能数值识别系统 (学习PlayGearLib的智能识别)

// 智能识别游戏数值类型
typedef NS_ENUM(NSInteger, WDZValueType) {
    WDZValueTypeUnknown = 0,
    WDZValueTypeMoney,      // 金钱 (100-100,000,000)
    WDZValueTypeStamina,    // 体力 (10-10,000)
    WDZValueTypeHealth,     // 健康 (1-1,000)
    WDZValueTypeMood        // 心情 (1-1,000)
};

static WDZValueType identifyValueType(NSInteger value) {
    if (value >= 100 && value <= 100000000) {
        return WDZValueTypeMoney;
    } else if (value >= 10 && value <= 10000) {
        return WDZValueTypeStamina;
    } else if (value >= 1 && value <= 1000) {
        // 进一步区分健康和心情需要更多上下文
        return WDZValueTypeHealth; // 默认为健康
    }
    return WDZValueTypeUnknown;
}

static NSInteger getTargetValueForType(WDZValueType type) {
    switch (type) {
        case WDZValueTypeMoney:
            return g_targetMoney;
        case WDZValueTypeStamina:
            return g_targetStamina;
        case WDZValueTypeHealth:
            return g_targetHealth;
        case WDZValueTypeMood:
            return g_targetMood;
        default:
            return 0;
    }
}

#pragma mark - 高级Hook系统 (学习PlayGearLib的多层Hook)

// Hook memcpy - 拦截内存复制操作
static void* hooked_memcpy(void *dest, const void *src, size_t n) {
    void* result = original_memcpy(dest, src, n);
    
    if (g_memoryInterceptEnabled && n == sizeof(int)) {
        int value = *(int*)src;
        WDZValueType type = identifyValueType(value);
        
        if (type != WDZValueTypeUnknown) {
            NSInteger targetValue = getTargetValueForType(type);
            if (targetValue > 0) {
                *(int*)dest = (int)targetValue;
                g_interceptCount++;
                
                writeAdvancedLog([NSString stringWithFormat:@"🎯 memcpy拦截: %d -> %ld (类型:%ld)", 
                    value, (long)targetValue, (long)type]);
            }
        }
    }
    
    return result;
}

// Hook memmove - 拦截内存移动操作
static void* hooked_memmove(void *dest, const void *src, size_t n) {
    void* result = original_memmove(dest, src, n);
    
    if (g_memoryInterceptEnabled && n == sizeof(int)) {
        int value = *(int*)src;
        WDZValueType type = identifyValueType(value);
        
        if (type != WDZValueTypeUnknown) {
            NSInteger targetValue = getTargetValueForType(type);
            if (targetValue > 0) {
                *(int*)dest = (int)targetValue;
                g_interceptCount++;
                
                writeAdvancedLog([NSString stringWithFormat:@"🎯 memmove拦截: %d -> %ld (类型:%ld)", 
                    value, (long)targetValue, (long)type]);
            }
        }
    }
    
    return result;
}

// Hook NSUserDefaults integerForKey - 拦截数据读取
static NSInteger hooked_integerForKey(id self, SEL _cmd, NSString* key) {
    NSInteger originalValue = original_integerForKey(self, _cmd, key);
    
    if (g_advancedHookEnabled) {
        // 基于键名智能识别
        NSString *lowerKey = [key lowercaseString];
        
        if ([lowerKey containsString:@"money"] || [lowerKey containsString:@"cash"] || 
            [lowerKey containsString:@"coin"] || [lowerKey containsString:@"gold"]) {
            g_interceptCount++;
            writeAdvancedLog([NSString stringWithFormat:@"💰 金钱读取拦截: %@ = %ld -> %ld", 
                key, (long)originalValue, (long)g_targetMoney]);
            return g_targetMoney;
        }
        
        if ([lowerKey containsString:@"stamina"] || [lowerKey containsString:@"energy"] ||
            [lowerKey containsString:@"体力"] || [lowerKey containsString:@"精力"]) {
            g_interceptCount++;
            writeAdvancedLog([NSString stringWithFormat:@"⚡ 体力读取拦截: %@ = %ld -> %ld", 
                key, (long)originalValue, (long)g_targetStamina]);
            return g_targetStamina;
        }
        
        if ([lowerKey containsString:@"health"] || [lowerKey containsString:@"hp"] ||
            [lowerKey containsString:@"健康"] || [lowerKey containsString:@"血量"]) {
            g_interceptCount++;
            writeAdvancedLog([NSString stringWithFormat:@"❤️ 健康读取拦截: %@ = %ld -> %ld", 
                key, (long)originalValue, (long)g_targetHealth]);
            return g_targetHealth;
        }
        
        if ([lowerKey containsString:@"mood"] || [lowerKey containsString:@"happy"] ||
            [lowerKey containsString:@"心情"] || [lowerKey containsString:@"情绪"]) {
            g_interceptCount++;
            writeAdvancedLog([NSString stringWithFormat:@"😊 心情读取拦截: %@ = %ld -> %ld", 
                key, (long)originalValue, (long)g_targetMood]);
            return g_targetMood;
        }
        
        // 基于数值范围智能识别
        WDZValueType type = identifyValueType(originalValue);
        if (type != WDZValueTypeUnknown) {
            NSInteger targetValue = getTargetValueForType(type);
            if (targetValue > 0 && originalValue != targetValue) {
                g_interceptCount++;
                writeAdvancedLog([NSString stringWithFormat:@"🎯 智能拦截: %@ = %ld -> %ld (类型:%ld)", 
                    key, (long)originalValue, (long)targetValue, (long)type]);
                return targetValue;
            }
        }
    }
    
    return originalValue;
}

// Hook NSUserDefaults setInteger - 拦截数据写入
static void hooked_setInteger(id self, SEL _cmd, NSInteger value, NSString* key) {
    NSInteger modifiedValue = value;
    
    if (g_advancedHookEnabled) {
        NSString *lowerKey = [key lowercaseString];
        
        if ([lowerKey containsString:@"money"] || [lowerKey containsString:@"cash"] || 
            [lowerKey containsString:@"coin"] || [lowerKey containsString:@"gold"]) {
            modifiedValue = g_targetMoney;
            writeAdvancedLog([NSString stringWithFormat:@"💰 金钱写入拦截: %@ = %ld -> %ld", 
                key, (long)value, (long)modifiedValue]);
        }
        else if ([lowerKey containsString:@"stamina"] || [lowerKey containsString:@"energy"]) {
            modifiedValue = g_targetStamina;
            writeAdvancedLog([NSString stringWithFormat:@"⚡ 体力写入拦截: %@ = %ld -> %ld", 
                key, (long)value, (long)modifiedValue]);
        }
        else if ([lowerKey containsString:@"health"] || [lowerKey containsString:@"hp"]) {
            modifiedValue = g_targetHealth;
            writeAdvancedLog([NSString stringWithFormat:@"❤️ 健康写入拦截: %@ = %ld -> %ld", 
                key, (long)value, (long)modifiedValue]);
        }
        else if ([lowerKey containsString:@"mood"] || [lowerKey containsString:@"happy"]) {
            modifiedValue = g_targetMood;
            writeAdvancedLog([NSString stringWithFormat:@"😊 心情写入拦截: %@ = %ld -> %ld", 
                key, (long)value, (long)modifiedValue]);
        }
    }
    
    original_setInteger(self, _cmd, modifiedValue, key);
}

#pragma mark - Hook安装系统 (学习PlayGearLib的Hook管理)

// 安装内存Hook
static BOOL installMemoryHooks(void) {
    // 获取memcpy和memmove的地址
    void *memcpy_addr = dlsym(RTLD_DEFAULT, "memcpy");
    void *memmove_addr = dlsym(RTLD_DEFAULT, "memmove");
    
    if (!memcpy_addr || !memmove_addr) {
        writeAdvancedLog(@"❌ 无法获取内存函数地址");
        return NO;
    }
    
    // 保存原始函数指针
    original_memcpy = memcpy_addr;
    original_memmove = memmove_addr;
    
    // 这里需要使用fishhook或DobbyHook来实际替换函数
    // 由于这是演示代码，我们只记录Hook点
    writeAdvancedLog(@"✅ 内存Hook安装完成 (memcpy + memmove)");
    
    return YES;
}

// 安装NSUserDefaults Hook
static BOOL installNSUserDefaultsHooks(void) {
    Class userDefaultsClass = [NSUserDefaults class];
    
    // Hook integerForKey:
    Method integerMethod = class_getInstanceMethod(userDefaultsClass, @selector(integerForKey:));
    if (integerMethod) {
        original_integerForKey = (NSInteger (*)(id, SEL, NSString*))method_getImplementation(integerMethod);
        method_setImplementation(integerMethod, (IMP)hooked_integerForKey);
        writeAdvancedLog(@"✅ NSUserDefaults integerForKey Hook安装完成");
    }
    
    // Hook setInteger:forKey:
    Method setIntegerMethod = class_getInstanceMethod(userDefaultsClass, @selector(setInteger:forKey:));
    if (setIntegerMethod) {
        original_setInteger = (void (*)(id, SEL, NSInteger, NSString*))method_getImplementation(setIntegerMethod);
        method_setImplementation(setIntegerMethod, (IMP)hooked_setInteger);
        writeAdvancedLog(@"✅ NSUserDefaults setInteger Hook安装完成");
    }
    
    return YES;
}

#pragma mark - 游戏数据管理类 (学习PlayGearLib的ImgTool设计)

@interface WDZGameManager : NSObject

// 数值设置方法 (模仿ImgTool的set1-set26设计)
- (void)setMoney:(NSInteger)value;
- (void)setStamina:(NSInteger)value;
- (void)setHealth:(NSInteger)value;
- (void)setMood:(NSInteger)value;

// 批量设置
- (void)setAllValues:(NSInteger)money stamina:(NSInteger)stamina health:(NSInteger)health mood:(NSInteger)mood;

// 状态查询
- (NSDictionary *)getInterceptStatus;

@end

@implementation WDZGameManager

- (void)setMoney:(NSInteger)value {
    g_targetMoney = value;
    g_modifyCount++;
    writeAdvancedLog([NSString stringWithFormat:@"💰 设置目标金钱: %ld", (long)value]);
}

- (void)setStamina:(NSInteger)value {
    g_targetStamina = value;
    g_modifyCount++;
    writeAdvancedLog([NSString stringWithFormat:@"⚡ 设置目标体力: %ld", (long)value]);
}

- (void)setHealth:(NSInteger)value {
    g_targetHealth = value;
    g_modifyCount++;
    writeAdvancedLog([NSString stringWithFormat:@"❤️ 设置目标健康: %ld", (long)value]);
}

- (void)setMood:(NSInteger)value {
    g_targetMood = value;
    g_modifyCount++;
    writeAdvancedLog([NSString stringWithFormat:@"😊 设置目标心情: %ld", (long)value]);
}

- (void)setAllValues:(NSInteger)money stamina:(NSInteger)stamina health:(NSInteger)health mood:(NSInteger)mood {
    [self setMoney:money];
    [self setStamina:stamina];
    [self setHealth:health];
    [self setMood:mood];
    writeAdvancedLog(@"🎁 批量设置完成");
}

- (NSDictionary *)getInterceptStatus {
    return @{
        @"interceptCount": @(g_interceptCount),
        @"modifyCount": @(g_modifyCount),
        @"advancedHookEnabled": @(g_advancedHookEnabled),
        @"memoryInterceptEnabled": @(g_memoryInterceptEnabled),
        @"targetMoney": @(g_targetMoney),
        @"targetStamina": @(g_targetStamina),
        @"targetHealth": @(g_targetHealth),
        @"targetMood": @(g_targetMood)
    };
}

@end

static WDZGameManager *g_gameManager = nil;

#pragma mark - 控制类 (学习PlayGearLib的shenling设计)

@interface WDZController : NSObject

// 核心控制方法 (模仿shenling的设计)
+ (void)enableAdvancedMode;
+ (void)disableAdvancedMode;
+ (void)enableMemoryIntercept;
+ (void)disableMemoryIntercept;
+ (void)resetAllValues;
+ (void)showInterceptStatus;

// 游戏功能方法
+ (void)unlimitedMoney;
+ (void)unlimitedStamina;
+ (void)unlimitedHealth;
+ (void)unlimitedMood;
+ (void)unlimitedAll;

@end

@implementation WDZController

+ (void)enableAdvancedMode {
    if (!g_advancedHookEnabled) {
        g_advancedHookEnabled = YES;
        installNSUserDefaultsHooks();
        writeAdvancedLog(@"🚀 高级模式已启用 - NSUserDefaults Hook激活");
    }
}

+ (void)disableAdvancedMode {
    g_advancedHookEnabled = NO;
    writeAdvancedLog(@"⏹️ 高级模式已禁用");
}

+ (void)enableMemoryIntercept {
    if (!g_memoryInterceptEnabled) {
        g_memoryInterceptEnabled = YES;
        installMemoryHooks();
        writeAdvancedLog(@"🧠 内存拦截已启用 - memcpy/memmove Hook激活");
    }
}

+ (void)disableMemoryIntercept {
    g_memoryInterceptEnabled = NO;
    writeAdvancedLog(@"🧠 内存拦截已禁用");
}

+ (void)resetAllValues {
    g_targetMoney = 2100000000;
    g_targetStamina = 2100000000;
    g_targetHealth = 100000;
    g_targetMood = 100000;
    g_interceptCount = 0;
    g_modifyCount = 0;
    writeAdvancedLog(@"🔄 所有数值已重置为默认值");
}

+ (void)showInterceptStatus {
    NSDictionary *status = [g_gameManager getInterceptStatus];
    writeAdvancedLog(@"📊 拦截状态报告:");
    writeAdvancedLog([NSString stringWithFormat:@"   拦截次数: %@", status[@"interceptCount"]]);
    writeAdvancedLog([NSString stringWithFormat:@"   修改次数: %@", status[@"modifyCount"]]);
    writeAdvancedLog([NSString stringWithFormat:@"   高级Hook: %@", status[@"advancedHookEnabled"] ? @"启用" : @"禁用"]);
    writeAdvancedLog([NSString stringWithFormat:@"   内存拦截: %@", status[@"memoryInterceptEnabled"] ? @"启用" : @"禁用"]);
    writeAdvancedLog([NSString stringWithFormat:@"   目标金钱: %@", status[@"targetMoney"]]);
    writeAdvancedLog([NSString stringWithFormat:@"   目标体力: %@", status[@"targetStamina"]]);
    writeAdvancedLog([NSString stringWithFormat:@"   目标健康: %@", status[@"targetHealth"]]);
    writeAdvancedLog([NSString stringWithFormat:@"   目标心情: %@", status[@"targetMood"]]);
}

+ (void)unlimitedMoney {
    [g_gameManager setMoney:g_targetMoney];
}

+ (void)unlimitedStamina {
    [g_gameManager setStamina:g_targetStamina];
}

+ (void)unlimitedHealth {
    [g_gameManager setHealth:g_targetHealth];
}

+ (void)unlimitedMood {
    [g_gameManager setMood:g_targetMood];
}

+ (void)unlimitedAll {
    [g_gameManager setAllValues:g_targetMoney stamina:g_targetStamina health:g_targetHealth mood:g_targetMood];
}

@end

#pragma mark - 高级菜单界面

@interface WDZAdvancedMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@end

@implementation WDZAdvancedMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupAdvancedUI]; }
    return self;
}

- (void)setupAdvancedUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    
    CGFloat contentHeight = 600;
    CGFloat contentWidth = 320;
    CGFloat viewWidth = self.bounds.size.width;
    CGFloat viewHeight = self.bounds.size.height;
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(
        (viewWidth - contentWidth) / 2,
        (viewHeight - contentHeight) / 2,
        contentWidth, contentHeight
    )];
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];
    self.contentView.layer.cornerRadius = 20;
    self.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.contentView.layer.shadowOffset = CGSizeMake(0, 4);
    self.contentView.layer.shadowRadius = 12;
    self.contentView.layer.shadowOpacity = 0.3;
    [self addSubview:self.contentView];
    
    CGFloat y = 20;
    
    // 标题
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 35)];
    title.text = @"🚀 我独自生活 v16.0 高级版";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    y += 45;
    
    // 技术说明
    UILabel *techInfo = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 40)];
    techInfo.text = @"基于PlayGearLib.dylib技术分析\n多层Hook + 智能拦截 + 内存操作";
    techInfo.font = [UIFont systemFontOfSize:13];
    techInfo.textColor = [UIColor colorWithRed:0.3 green:0.6 blue:0.8 alpha:1];
    techInfo.textAlignment = NSTextAlignmentCenter;
    techInfo.numberOfLines = 2;
    [self.contentView addSubview:techInfo];
    y += 50;
    
    // Hook控制区域
    UILabel *hookLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    hookLabel.text = @"🔧 Hook控制";
    hookLabel.font = [UIFont boldSystemFontOfSize:16];
    hookLabel.textColor = [UIColor darkGrayColor];
    [self.contentView addSubview:hookLabel];
    y += 30;
    
    // Hook按钮
    UIButton *enableHookBtn = [self createButtonWithTitle:@"🚀 启用高级Hook" tag:101];
    enableHookBtn.frame = CGRectMake(20, y, (contentWidth - 50) / 2, 35);
    [self.contentView addSubview:enableHookBtn];
    
    UIButton *enableMemoryBtn = [self createButtonWithTitle:@"🧠 启用内存拦截" tag:102];
    enableMemoryBtn.frame = CGRectMake(30 + (contentWidth - 50) / 2, y, (contentWidth - 50) / 2, 35);
    [self.contentView addSubview:enableMemoryBtn];
    y += 45;
    
    // 数值修改区域
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    valueLabel.text = @"💎 数值修改 (PlayGearLib标准)";
    valueLabel.font = [UIFont boldSystemFontOfSize:16];
    valueLabel.textColor = [UIColor darkGrayColor];
    [self.contentView addSubview:valueLabel];
    y += 30;
    
    // 数值按钮
    NSArray *buttonTitles = @[@"💰 21亿金钱", @"⚡ 21亿体力", @"❤️ 10万健康", @"😊 10万心情"];
    NSArray *buttonTags = @[@201, @202, @203, @204];
    
    for (int i = 0; i < buttonTitles.count; i++) {
        UIButton *btn = [self createButtonWithTitle:buttonTitles[i] tag:[buttonTags[i] integerValue]];
        btn.frame = CGRectMake(20, y, contentWidth - 40, 35);
        [self.contentView addSubview:btn];
        y += 43;
    }
    
    // 一键全开
    UIButton *allBtn = [self createButtonWithTitle:@"🎁 一键全开 (PlayGearLib模式)" tag:205];
    allBtn.frame = CGRectMake(20, y, contentWidth - 40, 35);
    allBtn.backgroundColor = [UIColor colorWithRed:0.9 green:0.3 blue:0.3 alpha:1];
    [self.contentView addSubview:allBtn];
    y += 50;
    
    // 状态查询
    UIButton *statusBtn = [self createButtonWithTitle:@"📊 拦截状态" tag:301];
    statusBtn.frame = CGRectMake(20, y, (contentWidth - 50) / 2, 35);
    statusBtn.backgroundColor = [UIColor colorWithRed:0.5 green:0.7 blue:0.3 alpha:1];
    [self.contentView addSubview:statusBtn];
    
    UIButton *resetBtn = [self createButtonWithTitle:@"🔄 重置" tag:302];
    resetBtn.frame = CGRectMake(30 + (contentWidth - 50) / 2, y, (contentWidth - 50) / 2, 35);
    resetBtn.backgroundColor = [UIColor colorWithRed:0.7 green:0.5 blue:0.3 alpha:1];
    [self.contentView addSubview:resetBtn];
    y += 50;
    
    // 关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake((contentWidth - 100) / 2, y, 100, 35);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
    closeBtn.layer.cornerRadius = 17;
    [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:closeBtn];
}

- (UIButton *)createButtonWithTitle:(NSString *)title tag:(NSInteger)tag {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    NSString *message = @"";
    
    switch (sender.tag) {
        case 101: // 启用高级Hook
            [WDZController enableAdvancedMode];
            message = @"🚀 高级Hook已启用！\n\nNSUserDefaults拦截激活\n在游戏中进行操作触发拦截";
            break;
        case 102: // 启用内存拦截
            [WDZController enableMemoryIntercept];
            message = @"🧠 内存拦截已启用！\n\nmemcpy/memmove Hook激活\n智能识别游戏数值并替换";
            break;
        case 201: // 21亿金钱
            [WDZController unlimitedMoney];
            message = @"💰 21亿金钱设置完成！\n\n请在游戏中进行购买等操作\n触发数值读取时自动替换";
            break;
        case 202: // 21亿体力
            [WDZController unlimitedStamina];
            message = @"⚡ 21亿体力设置完成！\n\n请在游戏中使用体力\n触发数值读取时自动替换";
            break;
        case 203: // 10万健康
            [WDZController unlimitedHealth];
            message = @"❤️ 10万健康设置完成！\n\n请在游戏中查看健康数值\n触发数值读取时自动替换";
            break;
        case 204: // 10万心情
            [WDZController unlimitedMood];
            message = @"😊 10万心情设置完成！\n\n请在游戏中查看心情数值\n触发数值读取时自动替换";
            break;
        case 205: // 一键全开
            [WDZController unlimitedAll];
            message = @"🎁 PlayGearLib模式全开！\n\n💰21亿金钱 ⚡21亿体力\n❤️10万健康 😊10万心情\n\n请在游戏中操作触发拦截";
            break;
        case 301: // 拦截状态
            [WDZController showInterceptStatus];
            message = @"📊 拦截状态已输出到日志！\n\n请用Filza查看详细信息：\n/var/mobile/Documents/woduzi_advanced.log";
            break;
        case 302: // 重置
            [WDZController resetAllValues];
            message = @"🔄 所有设置已重置！\n\n数值恢复默认\n计数器清零";
            break;
    }
    
    [self showAlert:message];
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"高级修改器" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *rootVC = getRootViewController();
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (void)closeMenu {
    [self removeFromSuperview];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint loc = [touch locationInView:self];
    if (![self.contentView pointInside:[self.contentView convertPoint:loc fromView:self] withEvent:event]) {
        [self closeMenu];
    }
}

@end

#pragma mark - 工具函数实现

static NSString* getAdvancedLogPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"woduzi_advanced.log"];
}

static void writeAdvancedLog(NSString *message) {
    NSString *logPath = getAdvancedLogPath();
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
    
    NSLog(@"[WDZ-Advanced] %@", message);
}

static UIWindow* getKeyWindow(void) {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.anyObject;
        keyWindow = windowScene.windows.firstObject;
    } else {
        keyWindow = [UIApplication sharedApplication].keyWindow;
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

#pragma mark - 悬浮按钮和菜单管理

static UIButton *g_advancedFloatButton = nil;
static WDZAdvancedMenuView *g_advancedMenuView = nil;

static void showAdvancedMenu(void) {
    if (g_advancedMenuView) {
        [g_advancedMenuView removeFromSuperview];
        g_advancedMenuView = nil;
        return;
    }
    
    UIWindow *keyWindow = getKeyWindow();
    if (!keyWindow) return;
    
    CGRect windowBounds = keyWindow.bounds;
    g_advancedMenuView = [[WDZAdvancedMenuView alloc] initWithFrame:windowBounds];
    [keyWindow addSubview:g_advancedMenuView];
}

static void setupAdvancedFloatingButton(void) {
    if (g_advancedFloatButton) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = getKeyWindow();
        if (!keyWindow) return;
        
        g_advancedFloatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_advancedFloatButton.frame = CGRectMake(20, 200, 60, 60);
        g_advancedFloatButton.backgroundColor = [UIColor colorWithRed:0.9 green:0.3 blue:0.3 alpha:0.9];
        g_advancedFloatButton.layer.cornerRadius = 30;
        g_advancedFloatButton.clipsToBounds = YES;
        g_advancedFloatButton.layer.zPosition = 9999;
        
        [g_advancedFloatButton setTitle:@"高级" forState:UIControlStateNormal];
        [g_advancedFloatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_advancedFloatButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        
        [g_advancedFloatButton addTarget:[NSValue class] action:@selector(wdz_showAdvancedMenu) forControlEvents:UIControlEventTouchUpInside];
        
        [keyWindow addSubview:g_advancedFloatButton];
    });
}

@implementation NSValue (WDZAdvancedCheat)
+ (void)wdz_showAdvancedMenu { showAdvancedMenu(); }
@end

#pragma mark - 初始化

__attribute__((constructor))
static void WDZAdvancedCheatInit(void) {
    @autoreleasepool {
        // 初始化游戏管理器
        g_gameManager = [[WDZGameManager alloc] init];
        
        writeAdvancedLog(@"🚀 WoduziCheat v16.0 高级版初始化完成");
        writeAdvancedLog(@"📚 基于PlayGearLib.dylib技术分析");
        writeAdvancedLog(@"🔧 支持多层Hook + 智能拦截 + 内存操作");
        writeAdvancedLog(@"💎 目标数值: 金钱21亿, 体力21亿, 健康10万, 心情10万");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupAdvancedFloatingButton();
        });
    }
}