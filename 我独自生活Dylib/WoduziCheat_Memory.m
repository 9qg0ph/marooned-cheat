// 我独自生活修改器 - 内存搜索版本
// 直接搜索和修改内存中的数值
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <mach/vm_map.h>

// 全局变量
static UIButton *g_floatButton = nil;

// 简单日志
static void memLog(NSString *msg) {
    NSLog(@"[MemCheat] %@", msg);
}

// 获取主窗口
static UIWindow* getMainWindow(void) {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) return window;
    }
    return [UIApplication sharedApplication].windows.firstObject;
}

// 内存搜索结构
typedef struct {
    vm_address_t address;
    vm_size_t size;
} MemoryRegion;

// 搜索内存中的数值
static NSMutableArray* searchMemoryForValue(int targetValue) {
    NSMutableArray *results = [NSMutableArray array];
    
    task_t task = mach_task_self();
    vm_address_t address = 0;
    vm_size_t size = 0;
    vm_region_basic_info_data_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT;
    mach_port_t object_name;
    
    memLog([NSString stringWithFormat:@"开始搜索数值: %d", targetValue]);
    
    while (vm_region(task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS) {
        
        // 只搜索可读写的内存区域
        if ((info.protection & VM_PROT_READ) && (info.protection & VM_PROT_WRITE)) {
            
            // 读取内存数据
            vm_size_t dataSize = size;
            void *data = malloc(dataSize);
            
            if (vm_read_overwrite(task, address, size, (vm_address_t)data, &dataSize) == KERN_SUCCESS) {
                
                // 搜索目标数值
                int *intPtr = (int*)data;
                size_t intCount = dataSize / sizeof(int);
                
                for (size_t i = 0; i < intCount; i++) {
                    if (intPtr[i] == targetValue) {
                        NSNumber *addr = @(address + i * sizeof(int));
                        [results addObject:addr];
                        
                        if (results.count > 100) break; // 限制结果数量
                    }
                }
            }
            
            free(data);
        }
        
        address += size;
        
        if (results.count > 100) break; // 限制结果数量
    }
    
    memLog([NSString stringWithFormat:@"搜索完成，找到 %lu 个结果", (unsigned long)results.count]);
    return results;
}

// 修改内存中的数值
static BOOL modifyMemoryValue(vm_address_t address, int newValue) {
    task_t task = mach_task_self();
    
    // 修改内存保护
    if (vm_protect(task, address, sizeof(int), FALSE, VM_PROT_READ | VM_PROT_WRITE) != KERN_SUCCESS) {
        return NO;
    }
    
    // 写入新数值
    if (vm_write(task, address, (vm_offset_t)&newValue, sizeof(int)) != KERN_SUCCESS) {
        return NO;
    }
    
    return YES;
}

// 智能搜索和修改玩家数据
static void smartModifyPlayerData(void) {
    memLog(@"开始智能搜索玩家数据...");
    
    // 常见的游戏数值范围（含大额货币数值）
    NSArray *commonValues = @[@100, @200, @500, @1000, @2000, @5000, @10000, @20000, @50000,
                              // 常见的大额货币：几千万 / 上亿 / 几十亿
                              @1000000, @5000000, @10000000, @50000000,
                              @100000000, @500000000,
                              @1000000000, @1500000000, @2000000000, @2100000000];
    
    for (NSNumber *value in commonValues) {
        int targetValue = [value intValue];
        NSMutableArray *addresses = searchMemoryForValue(targetValue);
        
        if (addresses.count > 0 && addresses.count < 20) { // 结果数量合理
            memLog([NSString stringWithFormat:@"找到可能的玩家数据: %d (地址数量: %lu)", targetValue, (unsigned long)addresses.count]);
            
            // 尝试修改这些地址
            for (NSNumber *addrNum in addresses) {
                vm_address_t addr = [addrNum unsignedLongValue];
                
                // 根据原值判断修改目标
                int newValue;
                if (targetValue < 1000) {
                    newValue = 1000000; // 健康/心情类
                } else {
                    newValue = 21000000000; // 现金/体力类
                }
                
                if (modifyMemoryValue(addr, newValue)) {
                    memLog([NSString stringWithFormat:@"✅ 修改成功: 0x%lx (%d → %d)", addr, targetValue, newValue]);
                }
            }
        }
    }
    
    memLog(@"智能修改完成");
}

// 暴力修改 - 搜索所有可能的数值并修改
static void bruteForceModify(void) {
    memLog(@"开始暴力修改模式...");
    
    // 第一轮：搜索中小数值（例如血量、体力、部分货币）
    for (int value = 50; value <= 100000; value += 50) {
        NSMutableArray *addresses = searchMemoryForValue(value);
        
        if (addresses.count > 0 && addresses.count <= 5) { // 只修改结果较少的
            for (NSNumber *addrNum in addresses) {
                vm_address_t addr = [addrNum unsignedLongValue];
                
                int newValue;
                if (value < 1000) {
                    newValue = 1000000;          // 认为是血量/心情类
                } else {
                    newValue = 2100000000;       // 认为是货币/体力类（使用 21 亿，避免溢出）
                }
                
                modifyMemoryValue(addr, newValue);
            }
        }
    }
    
    // 第二轮：专门搜索超大货币数值（例如 20 亿左右）
    for (int big = 1500000000; big <= 2200000000; big += 5000000) {
        NSMutableArray *addresses = searchMemoryForValue(big);
        
        if (addresses.count > 0 && addresses.count <= 20) { // 大额结果一般较少
            for (NSNumber *addrNum in addresses) {
                vm_address_t addr = [addrNum unsignedLongValue];
                
                int newValue = 2100000000;       // 统一改成约 21 亿
                modifyMemoryValue(addr, newValue);
                memLog([NSString stringWithFormat:@"💰 大额货币暴力修改: 0x%lx (%d → %d)", addr, big, newValue]);
            }
        }
    }
    
    memLog(@"暴力修改完成");
}

// 显示简单菜单
static void showMemoryMenu(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🧠 内存修改器" 
        message:@"选择修改方式：\n\n智能搜索：搜索常见数值范围\n暴力修改：搜索所有可能数值" 
        preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"🎯 智能搜索" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        smartModifyPlayerData();
        
        UIAlertController *result = [UIAlertController alertControllerWithTitle:@"完成" message:@"智能搜索修改完成！请查看游戏数值是否变化。" preferredStyle:UIAlertControllerStyleAlert];
        [result addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        
        UIViewController *vc = getMainWindow().rootViewController;
        while (vc.presentedViewController) vc = vc.presentedViewController;
        [vc presentViewController:result animated:YES completion:nil];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"💥 暴力修改" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        bruteForceModify();
        
        UIAlertController *result = [UIAlertController alertControllerWithTitle:@"完成" message:@"暴力修改完成！请查看游戏数值是否变化。" preferredStyle:UIAlertControllerStyleAlert];
        [result addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        
        UIViewController *vc = getMainWindow().rootViewController;
        while (vc.presentedViewController) vc = vc.presentedViewController;
        [vc presentViewController:result animated:YES completion:nil];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"❌ 取消" style:UIAlertActionStyleCancel handler:nil]];
    
    UIViewController *vc = getMainWindow().rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    [vc presentViewController:alert animated:YES completion:nil];
}

// 创建悬浮按钮
static void createMemoryButton(void) {
    UIWindow *window = getMainWindow();
    if (!window || g_floatButton) return;
    
    g_floatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    g_floatButton.frame = CGRectMake(20, 100, 60, 60);
    g_floatButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:0.9];
    g_floatButton.layer.cornerRadius = 30;
    [g_floatButton setTitle:@"内存" forState:UIControlStateNormal];
    [g_floatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    g_floatButton.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    
    [g_floatButton addTarget:g_floatButton action:@selector(showMemoryMenu) forControlEvents:UIControlEventTouchUpInside];
    
    // 添加拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:g_floatButton action:@selector(handlePan:)];
    [g_floatButton addGestureRecognizer:pan];
    
    [window addSubview:g_floatButton];
    memLog(@"内存修改器按钮已创建");
}

@interface UIButton (MemoryCheat)
- (void)showMemoryMenu;
- (void)handlePan:(UIPanGestureRecognizer *)pan;
@end

@implementation UIButton (MemoryCheat)
- (void)showMemoryMenu {
    showMemoryMenu();
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIWindow *window = getMainWindow();
    if (!window) return;
    
    CGPoint translation = [pan translationInView:window];
    CGRect frame = self.frame;
    frame.origin.x += translation.x;
    frame.origin.y += translation.y;
    
    // 限制在屏幕范围内
    frame.origin.x = MAX(0, MIN(frame.origin.x, window.bounds.size.width - 60));
    frame.origin.y = MAX(50, MIN(frame.origin.y, window.bounds.size.height - 110));
    
    self.frame = frame;
    [pan setTranslation:CGPointZero inView:window];
}
@end

// 初始化
__attribute__((constructor))
static void MemoryCheatInit(void) {
    memLog(@"🧠 内存修改器已加载");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        createMemoryButton();
    });
}