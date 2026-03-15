// 潜水员戴夫修改器 - DaveCheat.m v2
// 无授权验证，直接通过IL2CPP API hook游戏方法
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>

#define LOG(fmt, ...) NSLog(@"[DaveCheat] " fmt, ##__VA_ARGS__)

#pragma mark - IL2CPP Types & API

typedef void  Il2CppDomain;
typedef void  Il2CppAssembly;
typedef void  Il2CppImage;
typedef void  Il2CppClass;
typedef void  Il2CppMethodInfo;

static Il2CppDomain*          (*il2cpp_domain_get)(void);
static Il2CppAssembly**       (*il2cpp_domain_get_assemblies)(Il2CppDomain*, size_t*);
static Il2CppImage*           (*il2cpp_assembly_get_image)(Il2CppAssembly*);
static const char*            (*il2cpp_image_get_name)(Il2CppImage*);
static Il2CppClass*           (*il2cpp_class_from_name)(Il2CppImage*, const char*, const char*);
static Il2CppMethodInfo*      (*il2cpp_class_get_method_from_name)(Il2CppClass*, const char*, int);

static BOOL g_apiLoaded = NO;

static BOOL loadIL2CPPAPI(void) {
    if (g_apiLoaded) return YES;

    // Try multiple approaches to find IL2CPP symbols
    // 1. RTLD_DEFAULT searches all loaded images
    il2cpp_domain_get = dlsym(RTLD_DEFAULT, "il2cpp_domain_get");
    if (il2cpp_domain_get) {
        LOG(@"Found il2cpp via RTLD_DEFAULT");
    } else {
        // 2. Try opening UnityFramework explicitly
        void *handle = dlopen("Frameworks/UnityFramework.framework/UnityFramework", RTLD_LAZY | RTLD_NOLOAD);
        if (!handle) handle = dlopen("Frameworks/UnityFramework.framework/UnityFramework", RTLD_LAZY);
        if (!handle) handle = dlopen(NULL, RTLD_LAZY);
        if (!handle) {
            LOG(@"ERROR: Cannot find UnityFramework handle");
            return NO;
        }
        il2cpp_domain_get = dlsym(handle, "il2cpp_domain_get");
    }

    if (!il2cpp_domain_get) {
        LOG(@"ERROR: il2cpp_domain_get not found");
        return NO;
    }

    il2cpp_domain_get_assemblies       = dlsym(RTLD_DEFAULT, "il2cpp_domain_get_assemblies");
    il2cpp_assembly_get_image          = dlsym(RTLD_DEFAULT, "il2cpp_assembly_get_image");
    il2cpp_image_get_name              = dlsym(RTLD_DEFAULT, "il2cpp_image_get_name");
    il2cpp_class_from_name             = dlsym(RTLD_DEFAULT, "il2cpp_class_from_name");
    il2cpp_class_get_method_from_name  = dlsym(RTLD_DEFAULT, "il2cpp_class_get_method_from_name");

    LOG(@"API ptrs: domain_get=%p assemblies=%p get_image=%p get_name=%p class_from_name=%p get_method=%p",
        il2cpp_domain_get, il2cpp_domain_get_assemblies,
        il2cpp_assembly_get_image, il2cpp_image_get_name,
        il2cpp_class_from_name, il2cpp_class_get_method_from_name);

    g_apiLoaded = (il2cpp_domain_get && il2cpp_domain_get_assemblies &&
                   il2cpp_assembly_get_image && il2cpp_image_get_name &&
                   il2cpp_class_from_name && il2cpp_class_get_method_from_name);

    if (!g_apiLoaded) {
        LOG(@"ERROR: Some IL2CPP APIs not found");
    }
    return g_apiLoaded;
}

#pragma mark - Memory Patching

static BOOL patchMemory(void *addr, const void *patchBytes, size_t size) {
    if (!addr || size == 0) return NO;

    mach_port_t task = mach_task_self();
    vm_address_t page = (vm_address_t)addr & ~(vm_page_size - 1);
    vm_size_t pageSize = vm_page_size * 2;

    kern_return_t kr = vm_protect(task, page, pageSize, false,
                                  VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    if (kr != KERN_SUCCESS) {
        kr = vm_protect(task, page, pageSize, false, VM_PROT_READ | VM_PROT_WRITE);
        if (kr != KERN_SUCCESS) return NO;
    }

    memcpy(addr, patchBytes, size);

    vm_protect(task, page, pageSize, false, VM_PROT_READ | VM_PROT_EXECUTE);
    return YES;
}

#pragma mark - IL2CPP Method Resolution

static Il2CppImage* g_csharpImage = NULL;

static Il2CppImage* findImage(const char *imageName) {
    if (g_csharpImage) return g_csharpImage;
    if (!il2cpp_domain_get) return NULL;

    @try {
        Il2CppDomain *domain = il2cpp_domain_get();
        if (!domain) { LOG(@"domain_get returned NULL"); return NULL; }
        LOG(@"Got domain: %p", domain);

        size_t count = 0;
        Il2CppAssembly **assemblies = il2cpp_domain_get_assemblies(domain, &count);
        if (!assemblies) { LOG(@"get_assemblies returned NULL"); return NULL; }
        // Sanity check: count should be reasonable (< 1000)
        if (count > 500) {
            LOG(@"WARNING: assembly count=%zu looks wrong, capping at 500", count);
            count = 500;
        }
        LOG(@"Got %zu assemblies", count);

        for (size_t i = 0; i < count; i++) {
            if (!assemblies[i]) continue;
            Il2CppImage *img = il2cpp_assembly_get_image(assemblies[i]);
            if (img) {
                const char *name = il2cpp_image_get_name(img);
                if (name && strcmp(name, imageName) == 0) {
                    LOG(@"Found image: %s", name);
                    g_csharpImage = img;
                    return img;
                }
            }
        }
        LOG(@"Image '%s' not found", imageName);
    } @catch (NSException *e) {
        LOG(@"EXCEPTION in findImage: %@", e);
    }
    return NULL;
}

static void* resolveMethod(const char *imageName, const char *namespaceName,
                           const char *className, const char *methodName, int paramCount) {
    @try {
        Il2CppImage *image = findImage(imageName);
        if (!image) { LOG(@"Image not found for %s.%s", className, methodName); return NULL; }

        Il2CppClass *klass = il2cpp_class_from_name(image, namespaceName, className);
        if (!klass) { LOG(@"Class not found: ns='%s' class='%s'", namespaceName, className); return NULL; }

        Il2CppMethodInfo *method = il2cpp_class_get_method_from_name(klass, methodName, paramCount);
        if (!method) { LOG(@"Method not found: %s.%s(%d)", className, methodName, paramCount); return NULL; }

        // MethodInfo->methodPointer is at offset 0
        void *funcPtr = *(void **)method;
        if (!funcPtr || (uintptr_t)funcPtr < 0x1000) {
            LOG(@"Invalid funcPtr %p for %s.%s", funcPtr, className, methodName);
            return NULL;
        }
        LOG(@"Resolved %s.%s -> %p", className, methodName, funcPtr);
        return funcPtr;
    } @catch (NSException *e) {
        LOG(@"EXCEPTION resolving %s.%s: %@", className, methodName, e);
        return NULL;
    }
}

#pragma mark - Feature Definitions

typedef struct {
    const char *name;
    const char *namespaceName;
    const char *className;
    const char *methodName;
    int paramCount;
    const uint8_t *patchBytes;
    int patchSize;
    BOOL enabled;
    void *funcAddr;
    uint8_t origBytes[24];
} CheatPatch;

typedef struct {
    NSString *displayName;
    int patchStartIdx;
    int patchCount;
    BOOL enabled;
} CheatFeature;

// Patch bytes
static const uint8_t PATCH_RET[] = {0xC0, 0x03, 0x5F, 0xD6};
static const uint8_t PATCH_FMOV_S0_10_RET[] = {0x00, 0x90, 0x24, 0x1E, 0xC0, 0x03, 0x5F, 0xD6};
static const uint8_t PATCH_FMOV_S0_9_RET[] = {0x00, 0x90, 0x22, 0x1E, 0xC0, 0x03, 0x5F, 0xD6};
static const uint8_t PATCH_PRICE_99M[] = {0xE0, 0xE1, 0x84, 0x52, 0x00, 0x7C, 0x00, 0x1B, 0xC0, 0x03, 0x5F, 0xD6};

// All individual patches (some features have multiple patches)
#define MAX_PATCHES 12
static CheatPatch g_patches[MAX_PATCHES] = {
    // 0: 冻结物品
    {"IngredientsStorage.Decrease", "", "IngredientsStorage", "Decrease", 3, PATCH_RET, 4, NO, NULL, {0}},
    // 1: 冻结金币
    {"PlayerInfoSave.set_gold", "", "PlayerInfoSave", "set_gold", 1, PATCH_RET, 4, NO, NULL, {0}},
    // 2: 无敌锁血
    {"PlayerBreathHandler.ExhaleUpdate", "", "PlayerBreathHandler", "ExhaleUpdate", 0, PATCH_RET, 4, NO, NULL, {0}},
    // 3: 无限氧气
    {"PlayerBreathHandler.set_HP", "", "PlayerBreathHandler", "set_HP", 1, PATCH_RET, 4, NO, NULL, {0}},
    // 4-5: 敌我免疫攻击 (2 patches)
    {"Damager.CheckDamagerAttack", "", "Damager", "CheckDamagerAttack", 0, PATCH_RET, 4, NO, NULL, {0}},
    {"PlayerBreathHandler.HPUpdate", "", "PlayerBreathHandler", "HPUpdate", 0, PATCH_RET, 4, NO, NULL, {0}},
    // 6: 潜水加速
    {"PlayerCharacter.DetermineMoveSpeed", "", "PlayerCharacter", "DetermineMoveSpeed", 0, PATCH_FMOV_S0_10_RET, 8, NO, NULL, {0}},
    // 7: 餐厅移动加速
    {"DaveMoveValue.get_speedMultiplier", "Common.Contents", "DaveMoveValue", "get_speedMultiplier", 0, PATCH_FMOV_S0_9_RET, 8, NO, NULL, {0}},
    // 8: 无限子弹
    {"GunWeaponHandler.DecreaseBullet", "", "GunWeaponHandler", "DecreaseBullet", 0, PATCH_RET, 4, NO, NULL, {0}},
    // 9: 无限金币
    {"IngredientsData.get_Price", "", "IngredientsData", "get_Price", 0, PATCH_PRICE_99M, 12, NO, NULL, {0}},
    // 10: 物品堆叠不重置
    {"InventoryItemSlotSave.set_TotalCount", "", "InventoryItemSlotSave", "set_TotalCount", 1, PATCH_RET, 4, NO, NULL, {0}},
};

// Feature -> patch mapping
#define MAX_FEATURES 10
static CheatFeature g_features[MAX_FEATURES] = {
    {@"冻结物品（不用请勿开启）",   0, 1, NO},
    {@"冻结金币（不用请勿开启）",   1, 1, NO},
    {@"无敌锁血",                   2, 1, NO},
    {@"无限氧气",                   3, 1, NO},
    {@"敌我免疫攻击",               4, 2, NO},  // 2 patches
    {@"潜水加速",                   6, 1, NO},
    {@"餐厅移动加速",               7, 1, NO},
    {@"无限子弹",                   8, 1, NO},
    {@"无限金币（出售一次食材即可）", 9, 1, NO},
    {@"物品堆叠不重置",             10, 1, NO},
};

static BOOL g_resolved = NO;

static void resolveAllMethods(void) {
    if (g_resolved) return;
    if (!loadIL2CPPAPI()) {
        LOG(@"Cannot resolve - IL2CPP API not available");
        return;
    }
    LOG(@"Resolving all methods...");
    @try {
        for (int i = 0; i < MAX_PATCHES; i++) {
            CheatPatch *p = &g_patches[i];
            p->funcAddr = resolveMethod("Assembly-CSharp.dll", p->namespaceName,
                                         p->className, p->methodName, p->paramCount);
            if (p->funcAddr) {
                memcpy(p->origBytes, p->funcAddr, p->patchSize);
            }
        }
    } @catch (NSException *e) {
        LOG(@"EXCEPTION in resolveAllMethods: %@", e);
    }
    g_resolved = YES;
    LOG(@"Resolution complete");
}

static void toggleFeature(int featureIdx, BOOL enable) {
    if (featureIdx < 0 || featureIdx >= MAX_FEATURES) return;
    if (!g_resolved) resolveAllMethods();

    CheatFeature *feat = &g_features[featureIdx];
    feat->enabled = enable;

    for (int i = feat->patchStartIdx; i < feat->patchStartIdx + feat->patchCount; i++) {
        if (i >= MAX_PATCHES) break;
        CheatPatch *p = &g_patches[i];
        if (!p->funcAddr) continue;

        if (enable) {
            p->enabled = patchMemory(p->funcAddr, p->patchBytes, p->patchSize);
        } else {
            p->enabled = NO;
            patchMemory(p->funcAddr, p->origBytes, p->patchSize);
        }
    }
}

#pragma mark - Menu UI

@class DaveMenuView;
static UIButton *g_floatButton = nil;
static DaveMenuView *g_menuView = nil;

@interface DaveMenuView : UIView
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIScrollView *scrollView;
@end

@implementation DaveMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) { [self setupUI]; }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    CGFloat cw = 320, ch = 520;
    CGFloat vw = self.bounds.size.width;
    CGFloat vh = self.bounds.size.height;

    self.contentView = [[UIView alloc] initWithFrame:CGRectMake((vw-cw)/2, (vh-ch)/2, cw, ch)];
    self.contentView.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:0.97];
    self.contentView.layer.cornerRadius = 20;
    self.contentView.clipsToBounds = YES;
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin;
    [self addSubview:self.contentView];

    // Header
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cw, 56)];
    header.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.18 alpha:1];
    [self.contentView addSubview:header];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, cw-80, 32)];
    title.text = @"潜水员戴夫";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor whiteColor];
    [header addSubview:title];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(cw-50, 10, 36, 36);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:22];
    closeBtn.tag = 999;
    [closeBtn addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:closeBtn];

    // Tab bar
    UIView *tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, 56, cw, 44)];
    tabBar.backgroundColor = [UIColor colorWithRed:0.14 green:0.14 blue:0.16 alpha:1];
    [self.contentView addSubview:tabBar];

    UIButton *tab1 = [UIButton buttonWithType:UIButtonTypeCustom];
    tab1.frame = CGRectMake(0, 0, cw/2, 44);
    [tab1 setTitle:@"功能列表" forState:UIControlStateNormal];
    [tab1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    tab1.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    tab1.backgroundColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.24 alpha:1];
    tab1.layer.cornerRadius = 8;
    [tabBar addSubview:tab1];

    UIButton *tab2 = [UIButton buttonWithType:UIButtonTypeCustom];
    tab2.frame = CGRectMake(cw/2, 0, cw/2, 44);
    [tab2 setTitle:@"工具箱" forState:UIControlStateNormal];
    [tab2 setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    tab2.titleLabel.font = [UIFont systemFontOfSize:15];
    [tabBar addSubview:tab2];

    // ScrollView for features
    CGFloat scrollY = 100;
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, scrollY, cw, ch - scrollY)];
    self.scrollView.showsVerticalScrollIndicator = YES;
    [self.contentView addSubview:self.scrollView];

    CGFloat y = 8;
    for (int i = 0; i < MAX_FEATURES; i++) {
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, y, cw, 56)];

        // Separator
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(16, 55, cw-32, 0.5)];
        sep.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
        [row addSubview:sep];

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, cw-90, 40)];
        label.text = g_features[i].displayName;
        label.font = [UIFont systemFontOfSize:15];
        label.textColor = [UIColor whiteColor];
        label.numberOfLines = 2;
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.8;
        [row addSubview:label];

        UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectMake(cw-70, 12, 0, 0)];
        toggle.on = g_features[i].enabled;
        toggle.onTintColor = [UIColor colorWithRed:0.3 green:0.8 blue:0.4 alpha:1];
        toggle.tag = i;
        [toggle addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
        [row addSubview:toggle];

        [self.scrollView addSubview:row];
        y += 56;
    }
    self.scrollView.contentSize = CGSizeMake(cw, y + 20);
}

- (void)switchToggled:(UISwitch *)sender {
    int idx = (int)sender.tag;
    toggleFeature(idx, sender.on);

    // Check if patch was successful
    CheatFeature *feat = &g_features[idx];
    BOOL allOK = YES;
    for (int i = feat->patchStartIdx; i < feat->patchStartIdx + feat->patchCount; i++) {
        if (i < MAX_PATCHES && !g_patches[i].funcAddr) {
            allOK = NO;
            break;
        }
    }

    if (sender.on && !allOK) {
        sender.on = NO;
        feat->enabled = NO;
        [self showAlert:@"方法未找到，请确认游戏版本是否匹配"];
    }
}

- (void)closeTapped {
    [self removeFromSuperview];
    g_menuView = nil;
}

- (void)showAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                  message:message
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint loc = [touch locationInView:self];
    if (![self.contentView pointInside:[self.contentView convertPoint:loc fromView:self] withEvent:event]) {
        [self closeTapped];
    }
}

@end

#pragma mark - Floating Button

static UIWindow* getKeyWindow(void) {
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (w.isKeyWindow) return w;
    }
    return [UIApplication sharedApplication].windows.firstObject;
}

static void showMenu(void) {
    if (g_menuView) {
        [g_menuView removeFromSuperview];
        g_menuView = nil;
        return;
    }
    UIWindow *kw = getKeyWindow();
    if (!kw) return;
    g_menuView = [[DaveMenuView alloc] initWithFrame:kw.bounds];
    g_menuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [kw addSubview:g_menuView];
}

static void handlePan(UIPanGestureRecognizer *pan) {
    UIWindow *kw = getKeyWindow();
    if (!kw || !g_floatButton) return;
    CGPoint t = [pan translationInView:kw];
    CGRect f = g_floatButton.frame;
    f.origin.x = MAX(0, MIN(f.origin.x + t.x, kw.bounds.size.width - 50));
    f.origin.y = MAX(50, MIN(f.origin.y + t.y, kw.bounds.size.height - 100));
    g_floatButton.frame = f;
    [pan setTranslation:CGPointZero inView:kw];
}

static int g_retryCount = 0;

static void setupFloatingButton(void) {
    if (g_floatButton) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *kw = getKeyWindow();
        if (!kw) {
            if (g_retryCount < 10) {
                g_retryCount++;
                LOG(@"No key window yet, retry %d/10...", g_retryCount);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{ setupFloatingButton(); });
            }
            return;
        }

        g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        g_floatButton.frame = CGRectMake(20, 120, 50, 50);
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        g_floatButton.layer.borderWidth = 2;
        g_floatButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;

        [g_floatButton setTitle:@"DV" forState:UIControlStateNormal];
        [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];

        [g_floatButton addTarget:[NSValue class] action:@selector(dc_showMenu)
                forControlEvents:UIControlEventTouchUpInside];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:[NSValue class] action:@selector(dc_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];

        [kw addSubview:g_floatButton];
    });
}

@implementation NSValue (DaveCheat)
+ (void)dc_showMenu { showMenu(); }
+ (void)dc_handlePan:(UIPanGestureRecognizer *)pan { handlePan(pan); }
@end

#pragma mark - Constructor

__attribute__((constructor))
static void DaveCheatInit(void) {
    @autoreleasepool {
        LOG(@"DaveCheat v2 loaded!");
        // Only setup UI - DO NOT touch IL2CPP here
        // IL2CPP methods will be resolved lazily when user toggles a feature
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            LOG(@"Setting up floating button...");
            setupFloatingButton();
        });
    }
}
