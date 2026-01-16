// 天选打工人修改器 - TianXuanDaGongRenCheat.m
// 通过内存搜索修改金钱、金条、体力
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <mach/mach.h>
#import <mach/vm_map.h>

#pragma mark - 全局变量

@class TXMenuView;
static UIButton *g_floatButton = nil;
static TXMenuView *g_menuView = nil;

#pragma mark - 内存搜索和修改

// 在指定内存范围搜索32位整数值
static NSMutableArray* searchMemoryForInt32(int32_t targetValue, vm_address_t startAddr, vm_address_t endAddr) {
    NSMutableArray *results = [NSMutableArray array];
    task_t task = mach_task_self();
    
    vm_address_t address = startAddr;
    vm_size_t size;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t infoCount = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t objectName;
    
    while (address < endAddr) {
        kern_return_t kr = vm_region_64(task, &address, &size, VM_REGION_BASIC_INFO_64, 
                                        (vm_region_info_t)&info, &infoCount, &objectName);
        if (kr != KERN_SUCCESS) break;
        
        // 只搜索可读写的内存区域
        if ((info.protection & VM_PROT_READ) && (info.protection & VM_PROT_WRITE)) {
            vm_size_t bytesRead;
            void *buffer = malloc(size);
            
            if (buffer && vm_read_overwrite(task, address, size, (vm_address_t)buffer, &bytesRead) == KERN_SUCCESS) {
                for (vm_size_t i = 0; i + sizeof(int32_t) <= bytesRead; i += sizeof(int32_t)) {
                    int32_t value = *(int32_t *)((char *)buffer + i);
                    if (value == targetValue) {
                        [results addObject:@(address + i)];
                        if (results.count > 10000) { // 限制结果数量
                            free(buffer);
                            return results;
                        }
                    }
                }
            }
            if (buffer) free(buffer);
        }
        address += size;
    }
    return results;
}

// 在指定地址附近搜索值
static NSMutableArray* searchNearbyForInt32(NSArray *baseAddresses, int32_t targetValue, int32_t range) {
    NSMutableArray *results = [NSMutableArray array];
    task_t task = mach_task_self();
    
    for (NSNumber *baseAddr in baseAddresses) {
        vm_address_t addr = [baseAddr unsignedLongLongValue];
        vm_address_t searchStart = addr - range;
        vm_address_t searchEnd = addr + range;
        
        for (vm_address_t searchAddr = searchStart; searchAddr < searchEnd; searchAddr += sizeof(int32_t)) {
            int32_t value = 0;
            vm_size_t bytesRead;
            if (vm_read_overwrite(task, searchAddr, sizeof(int32_t), (vm_address_t)&value, &bytesRead) == KERN_SUCCESS) {
                if (value == targetValue) {
                    [results addObject:@(searchAddr)];
                }
            }
        }
    }
    return results;
}

// 修改指定地址的值
static BOOL writeMemoryInt32(vm_address_t address, int32_t value) {
    task_t task = mach_task_self();
    kern_return_t kr = vm_write(task, address, (vm_offset_t)&value, sizeof(int32_t));
    return kr == KERN_SUCCESS;
}

// 通过爱心(100)找到金钱并修改
static BOOL modifyMoneyViaHeart(void) {
    // 搜索100（爱心满值）
    NSMutableArray *heart100Addrs = searchMemoryForInt32(100, 0x100000000, 0x300000000);
    
    if (heart100Addrs.count == 0) {
        NSLog(@"[TX] 未找到爱心值100");
        return NO;
    }
    
    NSLog(@"[TX] 找到 %lu 个值为100的地址", (unsigned long)heart100Addrs.count);
    
    int modified = 0;
    for (NSNumber *heartAddr in heart100Addrs) {
        vm_address_t addr = [heartAddr unsignedLongLongValue];
        
        // 金钱 = 爱心地址 - 0x18
        vm_address_t moneyAddr = addr - 0x18;
        
        // 验证：读取当前值，应该是一个合理的金钱数值（1-10000000）
        int32_t currentMoney = 0;
        vm_size_t bytesRead;
        if (vm_read_overwrite(mach_task_self(), moneyAddr, sizeof(int32_t), 
                              (vm_address_t)&currentMoney, &bytesRead) == KERN_SUCCESS) {
            if (currentMoney > 0 && currentMoney < 100000000) {
                // 修改金钱
                if (writeMemoryInt32(moneyAddr, 999999999)) {
                    modified++;
                    NSLog(@"[TX] 修改金钱成功: 0x%llx, 原值: %d", (unsigned long long)moneyAddr, currentMoney);
                }
            }
        }
    }
    
    return modified > 0;
}

// 通过爱心(100)找到金条并修改
static BOOL modifyGoldViaHeart(void) {
    NSMutableArray *heart100Addrs = searchMemoryForInt32(100, 0x100000000, 0x300000000);
    
    if (heart100Addrs.count == 0) {
        NSLog(@"[TX] 未找到爱心值100");
        return NO;
    }
    
    int modified = 0;
    for (NSNumber *heartAddr in heart100Addrs) {
        vm_address_t addr = [heartAddr unsignedLongLongValue];
        
        // 金条 = 爱心地址 - 0x14
        vm_address_t goldAddr = addr - 0x14;
        
        int32_t currentGold = 0;
        vm_size_t bytesRead;
        if (vm_read_overwrite(mach_task_self(), goldAddr, sizeof(int32_t), 
                              (vm_address_t)&currentGold, &bytesRead) == KERN_SUCCESS) {
            if (currentGold >= 0 && currentGold < 100000000) {
                if (writeMemoryInt32(goldAddr, 999999)) {
                    modified++;
                    NSLog(@"[TX] 修改金条成功: 0x%llx, 原值: %d", (unsigned long long)goldAddr, currentGold);
                }
            }
        }
    }
    
    return modified > 0;
}

// 一键全开
static BOOL modifyAll(void) {
    NSMutableArray *heart100Addrs = searchMemoryForInt32(100, 0x100000000, 0x300000000);
    
    if (heart100Addrs.count == 0) {
        NSLog(@"[TX] 未找到爱心值100");
        return NO;
    }
    
    int modified = 0;
    for (NSNumber *heartAddr in heart100Addrs) {
        vm_address_t addr = [heartAddr unsignedLongLongValue];
        
        // 金钱 = 爱心地址 - 0x18
        vm_address_t moneyAddr = addr - 0x18;
        // 金条 = 爱心地址 - 0x14
        vm_address_t goldAddr = addr - 0x14;
        
        int32_t currentMoney = 0;
        int32_t currentGold = 0;
        vm_size_t bytesRead;
        
        // 读取并验证金钱
        if (vm_read_overwrite(mach_task_self(), moneyAddr, sizeof(int32_t), 
                              (vm_address_t)&currentMoney, &bytesRead) == KERN_SUCCESS) {
            if (currentMoney > 0 && currentMoney < 100000000) {
                writeMemoryInt32(moneyAddr, 999999999);
                modified++;
            }
        }
        
        // 读取并验证金条
        if (vm_read_overwrite(mach_task_self(), goldAddr, sizeof(int32_t), 
                              (vm_address_t)&currentGold, &bytesRead) == KERN_SUCCESS) {
            if (currentGold >= 0 && currentGold < 100000000) {
                writeMemoryInt32(goldAddr, 999999);
                modified++;
            }
        }
    }
    
    return modified > 0;
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
    
    CGFloat contentHeight = 300;
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
    title.text = @"💼 天选打工人";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 50;
    
    // 提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 30)];
    tip.text = @"请确保爱心已满100再开启";
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:tip];
    y += 40;
    
    // 按钮
    UIButton *btn1 = [self createButtonWithTitle:@"💰 无限货币（满100爱心开启）" tag:1];
    btn1.frame = CGRectMake(20, y, 240, 40);
    [self.contentView addSubview:btn1];
    y += 50;
    
    UIButton *btn2 = [self createButtonWithTitle:@"🏆 无限金条（满100爱心开启）" tag:2];
    btn2.frame = CGRectMake(20, y, 240, 40);
    [self.contentView addSubview:btn2];
    y += 50;
    
    UIButton *btn3 = [self createButtonWithTitle:@"🎁 一键全开（满100爱心开启）" tag:3];
    btn3.frame = CGRectMake(20, y, 240, 40);
    [self.contentView addSubview:btn3];
    y += 60;
    
    // 版权
    UILabel *copyright = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 240, 20)];
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
    btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    BOOL success = NO;
    NSString *message = @"";
    
    switch (sender.tag) {
        case 1:
            success = modifyMoneyViaHeart();
            message = success ? @"💰 无限货币开启成功！" : @"❌ 未找到！请确保爱心已满100";
            break;
        case 2:
            success = modifyGoldViaHeart();
            message = success ? @"🏆 无限金条开启成功！" : @"❌ 未找到！请确保爱心已满100";
            break;
        case 3:
            success = modifyAll();
            message = success ? @"🎁 一键全开成功！\n💰 金钱: 999999999\n🏆 金条: 999999" : @"❌ 未找到！请确保爱心已满100";
            break;
    }
    
    [self showAlert:message];
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
        
        [g_floatButton setTitle:@"💼" forState:UIControlStateNormal];
        g_floatButton.titleLabel.font = [UIFont systemFontOfSize:24];
        
        [g_floatButton addTarget:[NSValue class] action:@selector(tx_showMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:[NSValue class] action:@selector(tx_handlePan:)];
        [g_floatButton addGestureRecognizer:pan];
        
        [keyWindow addSubview:g_floatButton];
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
