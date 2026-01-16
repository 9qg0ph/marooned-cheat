// 天选打工人修改器 - TianXuanDaGongRenCheat.m
// 通过内存搜索修改金钱、金条
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <mach/mach.h>

#pragma mark - 全局变量

@class TXMenuView;
static UIButton *g_floatButton = nil;
static TXMenuView *g_menuView = nil;
static NSMutableArray *g_foundAddresses = nil;  // 存储找到的地址

#pragma mark - 安全的内存操作

// 安全读取内存
static BOOL safeReadMemory(vm_address_t address, void *buffer, vm_size_t size) {
    vm_size_t bytesRead = 0;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), address, size, (vm_address_t)buffer, &bytesRead);
    return (kr == KERN_SUCCESS && bytesRead == size);
}

// 安全写入内存
static BOOL safeWriteMemory(vm_address_t address, void *buffer, vm_size_t size) {
    kern_return_t kr = vm_write(mach_task_self(), address, (vm_offset_t)buffer, (mach_msg_type_number_t)size);
    return (kr == KERN_SUCCESS);
}

// 搜索内存中的32位整数值（限制结果数量）
static NSMutableArray* searchInt32InMemory(int32_t targetValue, int maxResults) {
    NSMutableArray *results = [NSMutableArray array];
    task_t task = mach_task_self();
    
    vm_address_t address = 0;
    vm_size_t size = 0;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t infoCount;
    mach_port_t objectName;
    
    while (results.count < maxResults) {
        infoCount = VM_REGION_BASIC_INFO_COUNT_64;
        kern_return_t kr = vm_region_64(task, &address, &size, VM_REGION_BASIC_INFO_64,
                                        (vm_region_info_t)&info, &infoCount, &objectName);
        if (kr != KERN_SUCCESS) break;
        
        // 只搜索可读写的堆内存区域
        if ((info.protection & VM_PROT_READ) && (info.protection & VM_PROT_WRITE)) {
            // 限制单次读取大小，避免内存问题
            vm_size_t chunkSize = MIN(size, 0x100000);  // 最大1MB
            void *buffer = malloc(chunkSize);
            
            if (buffer) {
                vm_size_t bytesRead = 0;
                if (vm_read_overwrite(task, address, chunkSize, (vm_address_t)buffer, &bytesRead) == KERN_SUCCESS) {
                    for (vm_size_t i = 0; i + sizeof(int32_t) <= bytesRead; i += sizeof(int32_t)) {
                        int32_t value = *(int32_t *)((char *)buffer + i);
                        if (value == targetValue) {
                            [results addObject:@(address + i)];
                            if (results.count >= maxResults) {
                                free(buffer);
                                return results;
                            }
                        }
                    }
                }
                free(buffer);
            }
        }
        address += size;
    }
    return results;
}

// 通过爱心值(100)定位并修改金钱和金条
static int modifyGameValues(int32_t moneyValue, int32_t goldValue) {
    // 搜索值为100的地址（爱心满值）
    NSMutableArray *heart100Addrs = searchInt32InMemory(100, 5000);
    
    if (heart100Addrs.count == 0) {
        NSLog(@"[TX] 未找到爱心值100");
        return 0;
    }
    
    NSLog(@"[TX] 找到 %lu 个值为100的地址", (unsigned long)heart100Addrs.count);
    
    int modifiedCount = 0;
    
    for (NSNumber *heartAddrNum in heart100Addrs) {
        vm_address_t heartAddr = [heartAddrNum unsignedLongLongValue];
        
        // 根据偏移计算金钱和金条地址
        // 金钱 = 爱心地址 - 0x18
        // 金条 = 爱心地址 - 0x14
        vm_address_t moneyAddr = heartAddr - 0x18;
        vm_address_t goldAddr = heartAddr - 0x14;
        
        int32_t currentMoney = 0;
        int32_t currentGold = 0;
        
        // 读取当前值进行验证
        if (!safeReadMemory(moneyAddr, &currentMoney, sizeof(int32_t))) continue;
        if (!safeReadMemory(goldAddr, &currentGold, sizeof(int32_t))) continue;
        
        // 验证：金钱应该是正数且在合理范围内
        if (currentMoney > 0 && currentMoney < 100000000) {
            // 修改金钱
            if (moneyValue > 0) {
                if (safeWriteMemory(moneyAddr, &moneyValue, sizeof(int32_t))) {
                    NSLog(@"[TX] 修改金钱: 0x%llx, %d -> %d", (unsigned long long)moneyAddr, currentMoney, moneyValue);
                    modifiedCount++;
                }
            }
            
            // 修改金条
            if (goldValue > 0 && currentGold >= 0 && currentGold < 100000000) {
                if (safeWriteMemory(goldAddr, &goldValue, sizeof(int32_t))) {
                    NSLog(@"[TX] 修改金条: 0x%llx, %d -> %d", (unsigned long long)goldAddr, currentGold, goldValue);
                    modifiedCount++;
                }
            }
        }
    }
    
    return modifiedCount;
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
    tip.text = @"⚠️ 请确保爱心已满100再开启";
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithRed:1.0 green:0.4 blue:0 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:tip];
    y += 40;
    
    // 按钮
    UIButton *btn1 = [self createButtonWithTitle:@"💰 无限金钱 (999999999)" tag:1];
    btn1.frame = CGRectMake(20, y, 240, 44);
    [self.contentView addSubview:btn1];
    y += 54;
    
    UIButton *btn2 = [self createButtonWithTitle:@"🏆 无限金条 (999999)" tag:2];
    btn2.frame = CGRectMake(20, y, 240, 44);
    [self.contentView addSubview:btn2];
    y += 54;
    
    UIButton *btn3 = [self createButtonWithTitle:@"🎁 一键全开" tag:3];
    btn3.frame = CGRectMake(20, y, 240, 44);
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
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    btn.backgroundColor = [UIColor colorWithRed:1.0 green:0.6 blue:0 alpha:1];
    btn.layer.cornerRadius = 12;
    btn.tag = tag;
    [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)buttonTapped:(UIButton *)sender {
    // 在后台线程执行内存搜索，避免阻塞UI
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int result = 0;
        NSString *message = @"";
        
        switch (sender.tag) {
            case 1:
                result = modifyGameValues(999999999, 0);
                message = result > 0 ? @"💰 无限金钱开启成功！" : @"❌ 未找到！请确保爱心已满100";
                break;
            case 2:
                result = modifyGameValues(0, 999999);
                message = result > 0 ? @"🏆 无限金条开启成功！" : @"❌ 未找到！请确保爱心已满100";
                break;
            case 3:
                result = modifyGameValues(999999999, 999999);
                message = result > 0 ? [NSString stringWithFormat:@"🎁 一键全开成功！\n修改了 %d 处", result] : @"❌ 未找到！请确保爱心已满100";
                break;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlert:message];
        });
    });
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
    [pan setTranslation:CGPointMake(0, 0) inView:keyWindow];
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
