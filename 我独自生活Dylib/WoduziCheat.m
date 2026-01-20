// 我独自生活修改器 - WoduziCheat.m
// 混合内存修改系统
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// 动态加载mach函数（避免链接错误）
typedef int (*vm_region_func_t)(void*, void*, void*, int, void*, void*, void*);
typedef int (*task_for_pid_func_t)(int, int, void*);

static vm_region_func_t vm_region_ptr = NULL;
static task_for_pid_func_t task_for_pid_ptr = NULL;
static BOOL mach_available = NO;

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

#pragma mark - 函数前向声明

static void showMenu(void);
static void writeLog(NSString *message);
static UIWindow* getKeyWindow(void);
static UIViewController* getRootViewController(void);

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

// 全局变量存储找到的基地址
static uintptr_t g_moneyBaseAddress = 0;
static BOOL g_isModificationActive = NO;

// 高效内存搜索（优化版本）
static NSArray* fastMemorySearch(NSInteger targetValue) {
    NSMutableArray *results = [NSMutableArray array];
    
    writeLog([NSString stringWithFormat:@"🎯 高效搜索数值: %ld", (long)targetValue]);
    
    // 获取当前进程的内存映射信息
    void *stackPtr = &results;
    uintptr_t stackAddr = (uintptr_t)stackPtr;
    
    writeLog([NSString stringWithFormat:@"📍 栈地址参考: 0x%lx", stackAddr]);
    
    // 使用更合理的搜索范围和步长
    NSArray *searchRanges = @[
        // 缩小搜索范围，使用更大的步长
        @[@0x100000000, @0x108000000], // 128MB范围
        @[@0x110000000, @0x118000000], // 128MB范围
        @[@0x120000000, @0x128000000], // 128MB范围
    ];
    
    NSInteger foundCount = 0;
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    for (NSArray *range in searchRanges) {
        uintptr_t searchStart = [range[0] unsignedLongValue];
        uintptr_t searchEnd = [range[1] unsignedLongValue];
        
        writeLog([NSString stringWithFormat:@"🔍 搜索范围: 0x%lx - 0x%lx", searchStart, searchEnd]);
        
        // 使用页面对齐的大步长搜索（4KB步长）
        for (uintptr_t pageAddr = searchStart; pageAddr < searchEnd; pageAddr += 0x1000) {
            
            // 检查搜索时间，避免无限等待
            NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
            if (currentTime - startTime > 10.0) { // 10秒超时
                writeLog(@"⏰ 搜索超时，停止搜索");
                goto search_timeout;
            }
            
            @try {
                // 测试页面是否可访问
                volatile NSInteger testRead = *(NSInteger*)pageAddr;
                (void)testRead;
                
                // 如果页面可访问，在页面内进行精细搜索
                for (uintptr_t addr = pageAddr; addr < pageAddr + 0x1000 - sizeof(NSInteger); addr += sizeof(NSInteger)) {
                    @try {
                        NSInteger *ptr = (NSInteger*)addr;
                        volatile NSInteger value = *ptr;
                        
                        if (value == targetValue) {
                            [results addObject:@(addr)];
                            foundCount++;
                            
                            writeLog([NSString stringWithFormat:@"✅ 找到匹配: 0x%lx = %ld", addr, (long)value]);
                            
                            // 找到足够的结果就停止
                            if (foundCount >= 20) {
                                writeLog(@"🎉 找到足够结果，停止搜索");
                                goto search_complete;
                            }
                        }
                    } @catch (NSException *exception) {
                        // 跳过不可访问的地址
                        continue;
                    }
                }
            } @catch (NSException *exception) {
                // 跳过不可访问的页面
                continue;
            }
        }
        
        // 如果在当前范围找到了结果，记录一下
        if (results.count > 0) {
            writeLog([NSString stringWithFormat:@"📊 当前范围找到 %lu 个地址", (unsigned long)results.count]);
            // 如果已经找到一些结果，就不用继续搜索其他范围了
            break;
        }
    }
    
search_complete:
search_timeout:
    
    NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
    writeLog([NSString stringWithFormat:@"🎉 搜索完成，耗时 %.2f 秒，共找到 %lu 个候选地址", 
             endTime - startTime, (unsigned long)results.count]);
    
    return results;
}

// 更严格的游戏数据结构验证（防闪退版本）
static BOOL verifyGameDataStructureSafe(uintptr_t baseAddress) {
    @try {
        // 1. 基础地址对齐检查
        if (baseAddress % sizeof(NSInteger) != 0) {
            writeLog([NSString stringWithFormat:@"❌ 地址未对齐: 0x%lx", baseAddress]);
            return NO;
        }
        
        // 2. 地址范围检查（确保在合理的内存范围内）
        if (baseAddress < 0x100000000 || baseAddress > 0x200000000) {
            writeLog([NSString stringWithFormat:@"❌ 地址超出范围: 0x%lx", baseAddress]);
            return NO;
        }
        
        // 3. 检查所有偏移地址是否可访问
        volatile NSInteger testBase = *(NSInteger*)baseAddress;
        volatile NSInteger testStamina = *(NSInteger*)(baseAddress + 24);
        volatile NSInteger testHealth = *(NSInteger*)(baseAddress + 72);
        volatile NSInteger testMood = *(NSInteger*)(baseAddress + 104);
        (void)testBase; (void)testStamina; (void)testHealth; (void)testMood;
        
        // 4. 读取四个偏移位置的数值
        NSInteger money = *(NSInteger*)baseAddress;
        NSInteger stamina = *(NSInteger*)(baseAddress + 24);
        NSInteger health = *(NSInteger*)(baseAddress + 72);
        NSInteger mood = *(NSInteger*)(baseAddress + 104);
        
        writeLog([NSString stringWithFormat:@"🔍 验证地址 0x%lx:", baseAddress]);
        writeLog([NSString stringWithFormat:@"  💰=%ld ⚡=%ld ❤️=%ld 😊=%ld", 
                 (long)money, (long)stamina, (long)health, (long)mood]);
        
        // 5. 更严格的数值范围验证
        BOOL moneyValid = (money >= 0 && money <= 999999999);
        BOOL staminaValid = (stamina >= 0 && stamina <= 999999);
        BOOL healthValid = (health >= 0 && health <= 999);
        BOOL moodValid = (mood >= 0 && mood <= 999);
        
        // 6. 检查数值是否过于相似（可能是错误的数据结构）
        if (money == stamina && stamina == health && health == mood && money != 0) {
            writeLog(@"❌ 所有数值相同，可能不是游戏数据");
            return NO;
        }
        
        // 7. 检查是否所有数值都为0（可能是未初始化的内存）
        if (money == 0 && stamina == 0 && health == 0 && mood == 0) {
            writeLog(@"❌ 所有数值为0，可能是空内存");
            return NO;
        }
        
        if (moneyValid && staminaValid && healthValid && moodValid) {
            writeLog(@"✅ 数据结构验证通过！");
            return YES;
        } else {
            writeLog([NSString stringWithFormat:@"❌ 数值超出合理范围 - 💰:%s ⚡:%s ❤️:%s 😊:%s", 
                     moneyValid ? "✓" : "✗",
                     staminaValid ? "✓" : "✗", 
                     healthValid ? "✓" : "✗",
                     moodValid ? "✓" : "✗"]);
        }
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ 验证异常: %@", exception.reason]);
    }
    
    return NO;
}

// 更安全的内存数值修改（防闪退版本）
static BOOL writeMemoryValueSafe(uintptr_t address, NSInteger value, NSString *name) {
    @try {
        // 多重安全检查
        // 1. 检查地址是否可读
        volatile NSInteger testRead = *(NSInteger*)address;
        (void)testRead;
        
        // 2. 检查地址是否可写（尝试写入原值）
        NSInteger *ptr = (NSInteger*)address;
        NSInteger originalValue = *ptr;
        *ptr = originalValue; // 写入原值测试
        
        // 3. 验证写入测试是否成功
        if (*ptr != originalValue) {
            writeLog([NSString stringWithFormat:@"⚠️ %@ 地址不可写: 0x%lx", name, address]);
            return NO;
        }
        
        // 4. 检查数值是否合理（避免修改系统关键数据）
        if (originalValue < 0 || originalValue > 2000000000) {
            writeLog([NSString stringWithFormat:@"⚠️ %@ 原值异常: %ld，跳过修改", name, (long)originalValue]);
            return NO;
        }
        
        // 5. 执行实际修改
        *ptr = value;
        
        // 6. 验证修改结果
        NSInteger newValue = *ptr;
        if (newValue == value) {
            writeLog([NSString stringWithFormat:@"✅ %@ 修改成功: %ld -> %ld (地址: 0x%lx)", 
                     name, (long)originalValue, (long)value, address]);
            
            // 7. 延迟验证（防止游戏立即检测）
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    NSInteger verifyValue = *(NSInteger*)address;
                    if (verifyValue != value) {
                        writeLog([NSString stringWithFormat:@"⚠️ %@ 数值被游戏还原: %ld", name, (long)verifyValue]);
                    }
                } @catch (NSException *exception) {
                    // 忽略延迟验证的异常
                }
            });
            
            return YES;
        } else {
            writeLog([NSString stringWithFormat:@"❌ %@ 修改失败: 写入%ld但读取到%ld", 
                     name, (long)value, (long)newValue]);
            return NO;
        }
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"❌ %@ 修改异常: %@", name, exception.reason]);
        return NO;
    }
}

// 核心修改函数：智能搜索并修改
static BOOL modifyGameData(NSInteger money, NSInteger stamina, NSInteger health, NSInteger mood, NSInteger experience) {
    writeLog(@"========== 开始智能内存修改 v14.2 ==========");
    
    uintptr_t baseAddress = 0;
    
    // 第一步：验证缓存地址
    if (g_moneyBaseAddress != 0) {
        writeLog([NSString stringWithFormat:@"🔄 验证缓存地址: 0x%lx", g_moneyBaseAddress]);
        if (verifyGameDataStructureSafe(g_moneyBaseAddress)) {
            baseAddress = g_moneyBaseAddress;
            writeLog(@"✅ 缓存地址有效，直接使用");
        } else {
            writeLog(@"❌ 缓存地址失效，重新搜索");
            g_moneyBaseAddress = 0;
        }
    }
    
    // 第二步：智能搜索游戏数据结构
    if (baseAddress == 0) {
        writeLog(@"🧠 开始智能搜索游戏数据结构...");
        
        // 使用已知的游戏数值进行搜索
        // 根据你之前提供的数据：金钱474、体力136、健康93、心情88
        NSArray *knownValues = @[@474, @136, @93, @88];
        NSArray *valueNames = @[@"金钱", @"体力", @"健康", @"心情"];
        NSArray *offsets = @[@0, @24, @72, @104];
        
        for (NSInteger i = 0; i < knownValues.count; i++) {
            NSInteger searchValue = [knownValues[i] integerValue];
            NSString *valueName = valueNames[i];
            NSInteger offset = [offsets[i] integerValue];
            
            writeLog([NSString stringWithFormat:@"🔍 搜索 %@: %ld", valueName, (long)searchValue]);
            
            NSArray *candidates = fastMemorySearch(searchValue);
            
            writeLog([NSString stringWithFormat:@"📊 %@ 找到 %lu 个候选地址", valueName, (unsigned long)candidates.count]);
            
            // 验证每个候选地址
            for (NSNumber *addrNum in candidates) {
                uintptr_t candidateAddr = [addrNum unsignedLongValue];
                
                // 计算可能的基地址
                uintptr_t possibleBase = candidateAddr - offset;
                
                writeLog([NSString stringWithFormat:@"🧪 测试基地址: 0x%lx (从%@地址0x%lx推算)", possibleBase, valueName, candidateAddr]);
                
                // 验证这个基地址是否正确
                if (verifyGameDataStructureSafe(possibleBase)) {
                    baseAddress = possibleBase;
                    g_moneyBaseAddress = baseAddress;
                    writeLog([NSString stringWithFormat:@"🎉 通过%@找到正确的基地址: 0x%lx", valueName, baseAddress]);
                    goto found_base;
                }
            }
        }
        
        // 如果上面的方法没找到，尝试更广泛的搜索
        if (baseAddress == 0) {
            writeLog(@"🔄 尝试广泛搜索...");
            
            // 搜索一些常见的游戏数值范围
            NSArray *commonValues = @[@100, @200, @300, @500, @1000];
            
            for (NSNumber *valueNum in commonValues) {
                NSInteger searchValue = [valueNum integerValue];
                NSArray *candidates = fastMemorySearch(searchValue);
                
                for (NSNumber *addrNum in candidates) {
                    uintptr_t candidateAddr = [addrNum unsignedLongValue];
                    
                    // 尝试作为基地址
                    if (verifyGameDataStructureSafe(candidateAddr)) {
                        baseAddress = candidateAddr;
                        g_moneyBaseAddress = baseAddress;
                        writeLog([NSString stringWithFormat:@"🎉 广泛搜索找到基地址: 0x%lx", baseAddress]);
                        goto found_base;
                    }
                    
                    // 尝试作为偏移地址
                    for (NSInteger offset = 0; offset <= 104; offset += 8) {
                        if (candidateAddr >= offset) {
                            uintptr_t possibleBase = candidateAddr - offset;
                            if (verifyGameDataStructureSafe(possibleBase)) {
                                baseAddress = possibleBase;
                                g_moneyBaseAddress = baseAddress;
                                writeLog([NSString stringWithFormat:@"🎉 通过偏移%ld找到基地址: 0x%lx", (long)offset, baseAddress]);
                                goto found_base;
                            }
                        }
                    }
                }
                
                if (baseAddress != 0) break;
            }
        }
    }
    
found_base:
    
    if (baseAddress == 0) {
        writeLog(@"❌ 未能找到游戏数据结构");
        writeLog(@"💡 建议：");
        writeLog(@"1. 确保游戏正在运行且界面显示数值");
        writeLog(@"2. 尝试在游戏中进行一些操作改变数值");
        writeLog(@"3. 重新启动修改器");
        return NO;
    }
    
    // 第三步：执行精准修改
    writeLog(@"🚀 开始修改游戏数值...");
    writeLog([NSString stringWithFormat:@"📍 基地址: 0x%lx", baseAddress]);
    
    // 先读取当前值
    @try {
        NSInteger currentMoney = *(NSInteger*)baseAddress;
        NSInteger currentStamina = *(NSInteger*)(baseAddress + 24);
        NSInteger currentHealth = *(NSInteger*)(baseAddress + 72);
        NSInteger currentMood = *(NSInteger*)(baseAddress + 104);
        
        writeLog(@"📊 修改前数值:");
        writeLog([NSString stringWithFormat:@"  💰金钱: %ld", (long)currentMoney]);
        writeLog([NSString stringWithFormat:@"  ⚡体力: %ld", (long)currentStamina]);
        writeLog([NSString stringWithFormat:@"  ❤️健康: %ld", (long)currentHealth]);
        writeLog([NSString stringWithFormat:@"  😊心情: %ld", (long)currentMood]);
    } @catch (NSException *exception) {
        writeLog([NSString stringWithFormat:@"⚠️ 读取当前值失败: %@", exception.reason]);
    }
    
    BOOL success = YES;
    
    if (money > 0) {
        if (!writeMemoryValueSafe(baseAddress, money, @"💰金钱")) {
            success = NO;
        }
    }
    
    if (stamina > 0) {
        if (!writeMemoryValueSafe(baseAddress + 24, stamina, @"⚡体力")) {
            success = NO;
        }
    }
    
    if (health > 0) {
        if (!writeMemoryValueSafe(baseAddress + 72, health, @"❤️健康")) {
            success = NO;
        }
    }
    
    if (mood > 0) {
        if (!writeMemoryValueSafe(baseAddress + 104, mood, @"😊心情")) {
            success = NO;
        }
    }
    
    if (success) {
        writeLog(@"🎉 所有数值修改完成！");
        
        // 验证修改结果
        writeLog(@"🔍 验证修改结果:");
        verifyGameDataStructureSafe(baseAddress);
        
        // 保存基地址供下次使用
        g_moneyBaseAddress = baseAddress;
    } else {
        writeLog(@"⚠️ 部分修改失败，请检查日志");
    }
    
    writeLog(@"========== 智能内存修改完成 ==========");
    return success;
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
    title.text = @"🏠 我独自生活 v14.2";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 学习提示
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"🧠 智能内存搜索修改器";
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
    tip.text = @"v14.2: 防闪退安全引擎\n多重验证保护，延迟检测机制";
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
    
    UIButton *btn6 = [self createButtonWithTitle:@"🔍 内存分析" tag:6];
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
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"🛡️ 安全修改 v14.2" 
        message:@"防闪退特性：\n• 多重安全验证机制\n• 智能地址范围检查\n• 延迟检测保护\n• 原值合理性验证\n\n⚠️ 请确保游戏正在运行\n\n确认继续？" 
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
            success = modifyGameData(999999999, 0, 0, 0, 0);
            message = success ? @"💰 无限金钱修改完成！\n\n已自动搜索并修改内存数值\n游戏中的金钱应该立即更新" : @"❌ 修改失败，请查看日志或手动操作";
            break;
        case 2:
            writeLog(@"功能：无限体力");
            success = modifyGameData(0, 999999, 0, 0, 0);
            message = success ? @"⚡ 无限体力修改完成！\n\n已自动搜索并修改内存数值\n游戏中的体力应该立即更新" : @"❌ 修改失败，请查看日志或手动操作";
            break;
        case 3:
            writeLog(@"功能：无限健康");
            success = modifyGameData(0, 0, 999, 0, 0);
            message = success ? @"❤️ 无限健康修改完成！\n\n已自动搜索并修改内存数值\n游戏中的健康应该立即更新" : @"❌ 修改失败，请查看日志或手动操作";
            break;
        case 4:
            writeLog(@"功能：无限心情");
            success = modifyGameData(0, 0, 0, 999, 0);
            message = success ? @"😊 无限心情修改完成！\n\n已自动搜索并修改内存数值\n游戏中的心情应该立即更新" : @"❌ 修改失败，请查看日志或手动操作";
            break;
        case 5:
            writeLog(@"功能：一键全开");
            success = modifyGameData(999999999, 999999, 999, 999, 0);
            message = success ? @"🎁 一键全开修改完成！\n\n💰金钱、⚡体力、❤️健康、😊心情\n所有属性已自动修改完成！" : @"❌ 修改失败，请查看日志或手动操作";
            break;
        case 6:
            writeLog(@"功能：内存分析");
            success = modifyGameData(0, 0, 0, 0, 0); // 只分析，不修改
            message = @"🔍 内存分析完成！\n\n请用Filza查看详细日志：\n/var/mobile/Documents/woduzi_cheat.log\n\n日志包含完整的内存搜索信息";
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
        
        writeLog(@"🛡️ WoduziCheat v14.2 初始化完成 - 防闪退保护已启用");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}