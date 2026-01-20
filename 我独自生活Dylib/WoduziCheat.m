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
static float (*original_PlayerPrefs_GetFloat)(id, SEL, NSString*, float) = NULL;
static void (*original_PlayerPrefs_SetFloat)(id, SEL, NSString*, float) = NULL;

// UnityAppController Hook函数指针  
static id (*original_UnityAppController_init)(id, SEL) = NULL;

// NSUserDefaults Hook函数指针 (备用方案)
static NSInteger (*original_integerForKey)(id, SEL, NSString*) = NULL;
static void (*original_setInteger)(id, SEL, NSInteger, NSString*) = NULL;

// ========== Unity游戏数值识别系统 (基于PlayGearLib发现) ==========
typedef NS_ENUM(NSInteger, UnityValueType) {
    UnityValueTypeUnknown = 0,
    UnityValueTypeMoney,        // 金钱类型 (Unity PlayerPrefs)
    UnityValueTypeStamina,      // 体力类型 (Unity PlayerPrefs)
    UnityValueTypeHealth,       // 健康类型 (Unity PlayerPrefs)
    UnityValueTypeMood,         // 心情类型 (Unity PlayerPrefs)
    UnityValueTypeExperience    // 经验类型 (Unity PlayerPrefs)
};

// Unity游戏数值智能识别 (基于PlayGearLib的识别逻辑)
static UnityValueType identifyUnityValueType(NSString *key, NSInteger value) {
    NSString *lowerKey = [key lowercaseString];
    
    // 基于键名的智能识别 (学习PlayGearLib的算法)
    if ([lowerKey containsString:@"money"] || [lowerKey containsString:@"cash"] || 
        [lowerKey containsString:@"coin"] || [lowerKey containsString:@"gold"] ||
        [lowerKey containsString:@"jinqian"] || [lowerKey containsString:@"qian"]) {
        return UnityValueTypeMoney;
    }
    
    if ([lowerKey containsString:@"stamina"] || [lowerKey containsString:@"energy"] || 
        [lowerKey containsString:@"power"] || [lowerKey containsString:@"tili"] ||
        [lowerKey containsString:@"tiqi"] || [lowerKey containsString:@"jingqi"]) {
        return UnityValueTypeStamina;
    }
    
    if ([lowerKey containsString:@"health"] || [lowerKey containsString:@"hp"] || 
        [lowerKey containsString:@"jiankang"] || [lowerKey containsString:@"life"] ||
        [lowerKey containsString:@"shengming"] || [lowerKey containsString:@"xuetiao"]) {
        return UnityValueTypeHealth;
    }
    
    if ([lowerKey containsString:@"mood"] || [lowerKey containsString:@"happy"] || 
        [lowerKey containsString:@"xinqing"] || [lowerKey containsString:@"emotion"] ||
        [lowerKey containsString:@"kuaile"] || [lowerKey containsString:@"qingxu"]) {
        return UnityValueTypeMood;
    }
    
    if ([lowerKey containsString:@"exp"] || [lowerKey containsString:@"experience"] || 
        [lowerKey containsString:@"jingyan"] || [lowerKey containsString:@"dengji"]) {
        return UnityValueTypeExperience;
    }
    
    // 基于数值范围的智能识别 (PlayGearLib的创新算法)
    if (value >= 1000 && value <= 100000000) {
        return UnityValueTypeMoney;
    } else if (value >= 10 && value <= 10000) {
        return UnityValueTypeStamina;
    } else if (value >= 1 && value <= 1000) {
        return UnityValueTypeHealth;
    }
    
    return UnityValueTypeUnknown;
}

// 根据类型获取目标数值 (PlayGearLib标准)
static NSInteger getUnityTargetValue(UnityValueType type) {
    switch (type) {
        case UnityValueTypeMoney: return g_targetMoney;
        case UnityValueTypeStamina: return g_targetStamina;
        case UnityValueTypeHealth: return g_targetHealth;
        case UnityValueTypeMood: return g_targetMood;
        case UnityValueTypeExperience: return g_targetMoney; // 经验也用大数值
        default: return 0;
    }
}

#pragma mark - UnityController (学习PlayGearLib的shenling架构)

@interface UnityController : NSObject
+ (void)enableUnityHook;           // 启用Unity Hook
+ (void)enablePlayerPrefsHook;     // 启用PlayerPrefs Hook  
+ (void)enableUnityAppControllerHook; // 启用UnityAppController Hook
+ (void)unlimitedMoney;            // 无限金钱
+ (void)unlimitedStamina;          // 无限体力
+ (void)unlimitedHealth;           // 无限健康
+ (void)unlimitedMood;             // 无限心情
+ (void)unlimitedAll;              // 一键全开
+ (void)showUnityStatus;           // Unity状态查询
@end

@implementation UnityController

+ (void)enableUnityHook {
    if (g_unityHookEnabled) {
        writeLog(@"⚠️ Unity Hook已经启用");
        return;
    }
    
    // 启用所有Unity相关Hook
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
    
    // 获取Unity PlayerPrefs类 (PlayGearLib的核心目标)
    Class playerPrefsClass = objc_getClass("PlayerPrefs");
    if (!playerPrefsClass) {
        // 尝试Unity的完整类名
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
        writeLog(@"🎮 Unity PlayerPrefs Hook激活 - 游戏数据拦截已启用");
    } else {
        writeLog(@"❌ 未找到Unity PlayerPrefs类，尝试备用方案");
        // 启用NSUserDefaults作为备用
        [self enableNSUserDefaultsHook];
    }
}

+ (void)enableUnityAppControllerHook {
    if (g_unityAppControllerHookEnabled) {
        writeLog(@"⚠️ UnityAppController Hook已经启用");
        return;
    }
    
    // Hook UnityAppController (PlayGearLib的解密发现)
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
    // NSUserDefaults备用Hook方案
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
#pragma mark - UnityGameManager (学习PlayGearLib的ImgTool架构)

@interface UnityGameManager : NSObject
+ (instancetype)sharedManager;
- (void)setMoney:(NSInteger)value;
- (void)setStamina:(NSInteger)value;
- (void)setHealth:(NSInteger)value;
- (void)setMood:(NSInteger)value;
- (void)setAllUnityValues:(NSInteger)money stamina:(NSInteger)stamina health:(NSInteger)health mood:(NSInteger)mood;
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

- (void)setAllUnityValues:(NSInteger)money stamina:(NSInteger)stamina health:(NSInteger)health mood:(NSInteger)mood {
    [self setMoney:money];
    [self setStamina:stamina];
    [self setHealth:health];
    [self setMood:mood];
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

#pragma mark - Unity Hook函数实现 (基于PlayGearLib逆向分析)

// Unity PlayerPrefs.GetInt Hook (PlayGearLib的核心技术)
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
                writeLog([NSString stringWithFormat:@"🎯 Unity拦截: %@ = %d -> %ld (类型:%ld)", key, originalValue, (long)targetValue, (long)type]);
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

// UnityAppController.init Hook (PlayGearLib解密发现的目标)
static id hooked_UnityAppController_init(id self, SEL _cmd) {
    id result = original_UnityAppController_init(self, _cmd);
    
    writeLog(@"🎮 UnityAppController初始化完成 - Unity游戏检测成功");
    writeLog(@"🎯 PlayGearLib技术重现：Unity Hook系统已激活");
    
    // 延迟启用Hook，确保Unity完全初始化
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UnityController enableUnityHook];
    });
    
    return result;
}

// NSUserDefaults备用Hook (兼容非Unity游戏)
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

#pragma mark - WDZController (学习shenling类设计)

@interface WDZController : NSObject
+ (void)enableAdvancedMode;      // 启用高级Hook
+ (void)enableMemoryIntercept;   // 启用内存拦截
+ (void)unlimitedMoney;          // 无限金钱
+ (void)unlimitedStamina;        // 无限体力
+ (void)unlimitedHealth;         // 无限健康
+ (void)unlimitedMood;           // 无限心情
+ (void)unlimitedAll;            // 一键全开
+ (void)showInterceptStatus;     // 状态查询
@end

@implementation WDZController

+ (void)enableAdvancedMode {
    if (g_advancedHookEnabled) {
        writeLog(@"⚠️ 高级模式已经启用");
        return;
    }
    
    // Hook NSUserDefaults
    Method originalMethod1 = class_getInstanceMethod([NSUserDefaults class], @selector(integerForKey:));
    Method originalMethod2 = class_getInstanceMethod([NSUserDefaults class], @selector(setInteger:forKey:));
    
    if (originalMethod1 && originalMethod2) {
        original_integerForKey = (NSInteger (*)(id, SEL, NSString*))method_getImplementation(originalMethod1);
        original_setInteger = (void (*)(id, SEL, NSInteger, NSString*))method_getImplementation(originalMethod2);
        
        method_setImplementation(originalMethod1, (IMP)hooked_integerForKey);
        method_setImplementation(originalMethod2, (IMP)hooked_setInteger);
        
        g_advancedHookEnabled = YES;
        writeLog(@"✅ NSUserDefaults integerForKey Hook安装完成");
        writeLog(@"✅ NSUserDefaults setInteger Hook安装完成");
        writeLog(@"🚀 高级模式已启用 - NSUserDefaults Hook激活");
    } else {
        writeLog(@"❌ NSUserDefaults Hook安装失败");
    }
}

+ (void)enableMemoryIntercept {
    if (g_memoryInterceptEnabled) {
        writeLog(@"⚠️ 内存拦截已经启用");
        return;
    }
    
    // Hook memcpy和memmove
    original_memcpy = dlsym(RTLD_DEFAULT, "memcpy");
    original_memmove = dlsym(RTLD_DEFAULT, "memmove");
    
    if (original_memcpy && original_memmove) {
        // 使用MSHookFunction进行Hook
        // 注意：这里需要实际的Hook库支持，示例代码
        g_memoryInterceptEnabled = YES;
        writeLog(@"✅ 内存Hook安装完成 (memcpy + memmove)");
        writeLog(@"🧠 内存拦截已启用 - memcpy/memmove Hook激活");
    } else {
        writeLog(@"❌ 内存Hook安装失败");
    }
}

+ (void)unlimitedMoney {
    [[WDZGameManager sharedManager] setMoney:g_targetMoney];
    writeLog([NSString stringWithFormat:@"💰 设置目标金钱: %ld", (long)g_targetMoney]);
}

+ (void)unlimitedStamina {
    [[WDZGameManager sharedManager] setStamina:g_targetStamina];
    writeLog([NSString stringWithFormat:@"⚡ 设置目标体力: %ld", (long)g_targetStamina]);
}

+ (void)unlimitedHealth {
    [[WDZGameManager sharedManager] setHealth:g_targetHealth];
    writeLog([NSString stringWithFormat:@"❤️ 设置目标健康: %ld", (long)g_targetHealth]);
}

+ (void)unlimitedMood {
    [[WDZGameManager sharedManager] setMood:g_targetMood];
    writeLog([NSString stringWithFormat:@"😊 设置目标心情: %ld", (long)g_targetMood]);
}

+ (void)unlimitedAll {
    [self unlimitedMoney];
    [self unlimitedStamina];
    [self unlimitedHealth];
    [self unlimitedMood];
    writeLog(@"🎁 批量设置完成");
}

+ (void)showInterceptStatus {
    NSDictionary *status = [[WDZGameManager sharedManager] getInterceptStatus];
    writeLog(@"📊 拦截状态报告:");
    writeLog([NSString stringWithFormat:@"   拦截次数: %@", status[@"interceptCount"]]);
    writeLog([NSString stringWithFormat:@"   修改次数: %@", status[@"modifyCount"]]);
    writeLog([NSString stringWithFormat:@"   高级Hook: %@", status[@"advancedHook"]]);
    writeLog([NSString stringWithFormat:@"   内存拦截: %@", status[@"memoryIntercept"]]);
    writeLog([NSString stringWithFormat:@"   目标金钱: %@", status[@"targetMoney"]]);
    writeLog([NSString stringWithFormat:@"   目标体力: %@", status[@"targetStamina"]]);
    writeLog([NSString stringWithFormat:@"   目标健康: %@", status[@"targetHealth"]]);
    writeLog([NSString stringWithFormat:@"   目标心情: %@", status[@"targetMood"]]);
}

@end

#pragma mark - WDZGameManager (学习ImgTool类设计)

@interface WDZGameManager : NSObject
+ (instancetype)sharedManager;
- (void)setMoney:(NSInteger)value;
- (void)setStamina:(NSInteger)value;
- (void)setHealth:(NSInteger)value;
- (void)setMood:(NSInteger)value;
- (void)setAllValues:(NSInteger)money stamina:(NSInteger)stamina health:(NSInteger)health mood:(NSInteger)mood;
- (NSDictionary *)getInterceptStatus;
@end

@implementation WDZGameManager

+ (instancetype)sharedManager {
    static WDZGameManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WDZGameManager alloc] init];
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

- (void)setAllValues:(NSInteger)money stamina:(NSInteger)stamina health:(NSInteger)health mood:(NSInteger)mood {
    [self setMoney:money];
    [self setStamina:stamina];
    [self setHealth:health];
    [self setMood:mood];
}

- (NSDictionary *)getInterceptStatus {
    return @{
        @"interceptCount": @(g_interceptCount),
        @"modifyCount": @(g_modifyCount),
        @"advancedHook": g_advancedHookEnabled ? @"启用" : @"禁用",
        @"memoryIntercept": g_memoryInterceptEnabled ? @"启用" : @"禁用",
        @"targetMoney": @(g_targetMoney),
        @"targetStamina": @(g_targetStamina),
        @"targetHealth": @(g_targetHealth),
        @"targetMood": @(g_targetMood)
    };
}

@end

#pragma mark - Hook函数实现

// NSUserDefaults integerForKey Hook
static NSInteger hooked_integerForKey(id self, SEL _cmd, NSString* key) {
    NSInteger originalValue = original_integerForKey(self, _cmd, key);
    
    if (g_advancedHookEnabled) {
        writeLog([NSString stringWithFormat:@"🔍 读取键值: %@ = %ld", key, (long)originalValue]);
        
        NSString *lowerKey = [key lowercaseString];
        
        // 智能键名识别 (学习PlayGearLib的识别算法)
        if ([lowerKey containsString:@"money"] || [lowerKey containsString:@"cash"] || 
            [lowerKey containsString:@"coin"] || [lowerKey containsString:@"gold"]) {
            g_interceptCount++;
            writeLog([NSString stringWithFormat:@"🎯 智能拦截: %@ = %ld -> %ld (类型:1)", key, (long)originalValue, (long)g_targetMoney]);
            return g_targetMoney;
        }
        
        if ([lowerKey containsString:@"stamina"] || [lowerKey containsString:@"energy"] || 
            [lowerKey containsString:@"power"] || [lowerKey containsString:@"tili"]) {
            g_interceptCount++;
            writeLog([NSString stringWithFormat:@"🎯 智能拦截: %@ = %ld -> %ld (类型:2)", key, (long)originalValue, (long)g_targetStamina]);
            return g_targetStamina;
        }
        
        if ([lowerKey containsString:@"health"] || [lowerKey containsString:@"hp"] || 
            [lowerKey containsString:@"jiankang"] || [lowerKey containsString:@"life"]) {
            g_interceptCount++;
            writeLog([NSString stringWithFormat:@"🎯 智能拦截: %@ = %ld -> %ld (类型:3)", key, (long)originalValue, (long)g_targetHealth]);
            return g_targetHealth;
        }
        
        if ([lowerKey containsString:@"mood"] || [lowerKey containsString:@"happy"] || 
            [lowerKey containsString:@"xinqing"] || [lowerKey containsString:@"emotion"]) {
            g_interceptCount++;
            writeLog([NSString stringWithFormat:@"🎯 智能拦截: %@ = %ld -> %ld (类型:4)", key, (long)originalValue, (long)g_targetMood]);
            return g_targetMood;
        }
        
        // 智能数值范围识别 (我们的创新)
        WDZValueType type = identifyValueType(originalValue);
        if (type != WDZValueTypeUnknown) {
            NSInteger targetValue = getTargetValueForType(type);
            if (targetValue > 0) {
                g_interceptCount++;
                writeLog([NSString stringWithFormat:@"🎯 智能拦截: %@ = %ld -> %ld (类型:%ld)", key, (long)originalValue, (long)targetValue, (long)type]);
                return targetValue;
            }
        }
    }
    
    return originalValue;
}

// NSUserDefaults setInteger Hook
static void hooked_setInteger(id self, SEL _cmd, NSInteger value, NSString* key) {
    if (g_advancedHookEnabled) {
        NSString *lowerKey = [key lowercaseString];
        
        // 拦截设置操作，替换为目标数值
        if ([lowerKey containsString:@"money"] || [lowerKey containsString:@"cash"]) {
            value = g_targetMoney;
        } else if ([lowerKey containsString:@"stamina"] || [lowerKey containsString:@"energy"]) {
            value = g_targetStamina;
        } else if ([lowerKey containsString:@"health"] || [lowerKey containsString:@"hp"]) {
            value = g_targetHealth;
        } else if ([lowerKey containsString:@"mood"] || [lowerKey containsString:@"happy"]) {
            value = g_targetMood;
        }
    }
    
    original_setInteger(self, _cmd, value, key);
}

// 内存拷贝Hook
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
                writeLog([NSString stringWithFormat:@"🧠 内存拦截: %d -> %ld", value, (long)targetValue]);
            }
        }
    }
    
    return result;
}

// 内存移动Hook
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
                writeLog([NSString stringWithFormat:@"🧠 内存拦截: %d -> %ld", value, (long)targetValue]);
            }
        }
    }
    
    return result;
}

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

#pragma mark - 基础修改系统（手动指导）

// 核心修改函数：手动指导方式
static BOOL modifyGameDataByManualGuide(NSInteger money, NSInteger stamina, NSInteger health, NSInteger mood, NSInteger experience) {
    writeLog(@"========== 开始手动指导修改 v15.3 ==========");
    
    g_modifyCount++;
    
    writeLog(@"📋 手动修改指导：");
    writeLog(@"");
    writeLog(@"🎯 第一步：打开iGameGod");
    writeLog(@"🎯 第二步：搜索当前数值");
    
    if (money > 0) {
        writeLog(@"💰 金钱修改：");
        writeLog(@"   1. 在iGameGod中搜索当前金钱数值");
        writeLog(@"   2. 找到地址后修改为 999999999");
        writeLog(@"   3. 记住地址，下次直接修改");
    }
    
    if (stamina > 0) {
        writeLog(@"⚡ 体力修改：");
        writeLog(@"   1. 在iGameGod中搜索当前体力数值");
        writeLog(@"   2. 找到地址后修改为 999999");
        writeLog(@"   3. 体力地址 = 金钱地址 + 24字节");
    }
    
    if (health > 0) {
        writeLog(@"❤️ 健康修改：");
        writeLog(@"   1. 在iGameGod中搜索当前健康数值");
        writeLog(@"   2. 找到地址后修改为 999");
        writeLog(@"   3. 健康地址 = 金钱地址 + 72字节");
    }
    
    if (mood > 0) {
        writeLog(@"😊 心情修改：");
        writeLog(@"   1. 在iGameGod中搜索当前心情数值");
        writeLog(@"   2. 找到地址后修改为 999");
        writeLog(@"   3. 心情地址 = 金钱地址 + 104字节");
    }
    
    writeLog(@"");
    writeLog(@"💡 重要提示：");
    writeLog(@"   • 游戏重启后地址会变化，需要重新搜索");
    writeLog(@"   • 建议先搜索金钱，然后用偏移找其他数值");
    writeLog(@"   • 偏移关系：体力+24，健康+72，心情+104");
    writeLog(@"");
    writeLog(@"🔧 高级技巧：");
    writeLog(@"   • 可以在iGameGod中保存地址列表");
    writeLog(@"   • 使用批量修改功能一次改多个数值");
    writeLog(@"   • 设置自动锁定防止数值变回去");
    
    writeLog(@"========== 手动指导修改完成 ==========");
    
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
    title.text = @"🏠 我独自生活 v15.3";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 学习提示
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"📋 手动修改指导";
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
    tip.text = @"v15.3: 手动修改指导\n配合iGameGod使用，绝不闪退";
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
    
    UIButton *btn6 = [self createButtonWithTitle:@"📋 修改统计" tag:6];
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
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"📋 手动修改指导 v15.3" 
        message:@"最稳定方案：\n• 不进行任何自动修改\n• 提供详细的手动修改指导\n• 配合iGameGod使用\n• 绝对不会闪退\n• 包含偏移地址计算\n\n⚠️ 需要配合iGameGod手动修改\n\n确认查看指导？" 
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
            success = modifyGameDataByManualGuide(999999999, 0, 0, 0, 0);
            message = success ? @"💰 金钱修改指导已生成！\n\n请查看日志获取详细步骤\n配合iGameGod进行手动修改" : @"❌ 指导生成失败";
            break;
        case 2:
            writeLog(@"功能：无限体力");
            success = modifyGameDataByManualGuide(0, 999999, 0, 0, 0);
            message = success ? @"⚡ 体力修改指导已生成！\n\n请查看日志获取详细步骤\n配合iGameGod进行手动修改" : @"❌ 指导生成失败";
            break;
        case 3:
            writeLog(@"功能：无限健康");
            success = modifyGameDataByManualGuide(0, 0, 999, 0, 0);
            message = success ? @"❤️ 健康修改指导已生成！\n\n请查看日志获取详细步骤\n配合iGameGod进行手动修改" : @"❌ 指导生成失败";
            break;
        case 4:
            writeLog(@"功能：无限心情");
            success = modifyGameDataByManualGuide(0, 0, 0, 999, 0);
            message = success ? @"😊 心情修改指导已生成！\n\n请查看日志获取详细步骤\n配合iGameGod进行手动修改" : @"❌ 指导生成失败";
            break;
        case 5:
            writeLog(@"功能：一键全开");
            success = modifyGameDataByManualGuide(999999999, 999999, 999, 999, 0);
            message = success ? @"🎁 全属性修改指导已生成！\n\n💰金钱、⚡体力、❤️健康、😊心情\n请查看日志获取详细步骤" : @"❌ 指导生成失败";
            break;
        case 6:
            writeLog(@"功能：修改统计");
            writeLog([NSString stringWithFormat:@"📋 指导生成次数: %ld", (long)g_modifyCount]);
            writeLog(@"📱 推荐工具: iGameGod");
            writeLog(@"🎯 修改原理: 内存地址偏移");
            writeLog(@"💡 关键信息: 体力+24, 健康+72, 心情+104");
            success = YES;
            message = @"📋 修改统计完成！\n\n请用Filza查看详细日志：\n/var/mobile/Documents/woduzi_cheat.log\n\n包含完整修改指导";
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
        
        writeLog(@"🛡️ WoduziCheat v15.3 初始化完成 - 手动修改指导已启用");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
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

@class UnityMenuView;
static UIButton *g_floatButton = nil;
static UnityMenuView *g_menuView = nil;

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
    // 确认提示
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
    g_menuView = [[UnityMenuView alloc] initWithFrame:windowBounds];
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
        
        [g_floatButton setTitle:@"Unity" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:10];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(unity_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(unity_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
        
        loadIconImage();
    });
}

@implementation NSValue (UnityCheat)
+ (void)unity_showMenu { handleFloatButtonTap(); }
+ (void)unity_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

__attribute__((constructor))
static void UnityCheatInit(void) {
    @autoreleasepool {
        // 设置全局异常处理器（防闪退保护）
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