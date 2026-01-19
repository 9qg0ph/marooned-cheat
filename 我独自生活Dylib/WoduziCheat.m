// 我独自生活修改器 - WoduziCheat.m
// 智能内存修改指导助手
#import <UIKit/UIKit.h>

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

#import <mach/mach.h>
#import <mach/vm_map.h>

// 全局变量存储找到的基地址
static uintptr_t g_moneyBaseAddress = 0;
static NSInteger g_lastKnownMoney = 0;

// 内存搜索结构体
typedef struct {
    uintptr_t address;
    NSInteger value;
} MemoryResult;

// 搜索内存中的特定数值
static NSArray<NSValue*>* searchMemoryForValue(NSInteger targetValue) {
    NSMutableArray *results = [NSMutableArray array];
    
    task_t task = mach_task_self();
    vm_address_t address = 0;
    vm_size_t size = 0;
    vm_region_basic_info_data_t info;
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT;
    mach_port_t object_name;
    
    writeLog([NSString stringWithFormat:@"🔍 开始搜索数值: %ld", (long)targetValue]);
    
    while (vm_region(task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object_name) == KERN_SUCCESS) {
        
        // 只搜索可读写的内存区域
        if ((info.protection & VM_PROT_READ) && (info.protection & VM_PROT_WRITE)) {
            
            // 读取内存数据
            vm_offset_t data;
            mach_msg_type_number_t dataCount;
            
            if (vm_read(task, address, size, &data, &dataCount) == KERN_SUCCESS) {
                
                // 搜索目标数值
                NSInteger *buffer = (NSInteger*)data;
                NSInteger count = dataCount / sizeof(NSInteger);
                
                for (NSInteger i = 0; i < count; i++) {
                    if (buffer[i] == targetValue) {
                        uintptr_t foundAddress = address + (i * sizeof(NSInteger));
                        
                        MemoryResult result;
                        result.address = foundAddress;
                        result.value = targetValue;
                        
                        [results addObject:[NSValue valueWithBytes:&result objCType:@encode(MemoryResult)]];
                        
                        writeLog([NSString stringWithFormat:@"✅ 找到匹配地址: 0x%lx = %ld", foundAddress, (long)targetValue]);
                        
                        // 限制结果数量，避免过多
                        if (results.count >= 50) {
                            vm_deallocate(mach_task_self(), data, dataCount);
                            goto search_complete;
                        }
                    }
                }
                
                vm_deallocate(mach_task_self(), data, dataCount);
            }
        }
        
        address += size;
    }
    
search_complete:
    writeLog([NSString stringWithFormat:@"🎯 搜索完成，找到 %lu 个匹配地址", (unsigned long)results.count]);
    return results;
}

// 验证地址是否为游戏数据结构
static BOOL verifyGameDataStructure(uintptr_t baseAddress) {
    task_t task = mach_task_self();
    
    // 读取各个偏移位置的数值
    NSInteger money = 0, stamina = 0, health = 0, mood = 0;
    
    vm_size_t size = sizeof(NSInteger);
    vm_offset_t data;
    mach_msg_type_number_t dataCount;
    
    // 读取金钱 (基地址)
    if (vm_read(task, baseAddress, size, &data, &dataCount) == KERN_SUCCESS) {
        money = *(NSInteger*)data;
        vm_deallocate(task, data, dataCount);
    } else {
        return NO;
    }
    
    // 读取体力 (基地址 + 24)
    if (vm_read(task, baseAddress + 24, size, &data, &dataCount) == KERN_SUCCESS) {
        stamina = *(NSInteger*)data;
        vm_deallocate(task, data, dataCount);
    } else {
        return NO;
    }
    
    // 读取健康 (基地址 + 72)
    if (vm_read(task, baseAddress + 72, size, &data, &dataCount) == KERN_SUCCESS) {
        health = *(NSInteger*)data;
        vm_deallocate(task, data, dataCount);
    } else {
        return NO;
    }
    
    // 读取心情 (基地址 + 104)
    if (vm_read(task, baseAddress + 104, size, &data, &dataCount) == KERN_SUCCESS) {
        mood = *(NSInteger*)data;
        vm_deallocate(task, data, dataCount);
    } else {
        return NO;
    }
    
    writeLog([NSString stringWithFormat:@"📊 验证地址 0x%lx:", baseAddress]);
    writeLog([NSString stringWithFormat:@"   💰 金钱: %ld", (long)money]);
    writeLog([NSString stringWithFormat:@"   ⚡ 体力: %ld", (long)stamina]);
    writeLog([NSString stringWithFormat:@"   ❤️ 健康: %ld", (long)health]);
    writeLog([NSString stringWithFormat:@"   😊 心情: %ld", (long)mood]);
    
    // 验证数值是否合理 (游戏数值通常在合理范围内)
    if (money >= 0 && money <= 999999999 && 
        stamina >= 0 && stamina <= 999999 && 
        health >= 0 && health <= 999 && 
        mood >= 0 && mood <= 999) {
        
        writeLog(@"✅ 数据结构验证通过！");
        return YES;
    }
    
    writeLog(@"❌ 数据结构验证失败");
    return NO;
}

// 修改内存中的数值
static BOOL writeMemoryValue(uintptr_t address, NSInteger value) {
    task_t task = mach_task_self();
    
    kern_return_t result = vm_write(task, address, (vm_offset_t)&value, sizeof(NSInteger));
    
    if (result == KERN_SUCCESS) {
        writeLog([NSString stringWithFormat:@"✅ 成功修改地址 0x%lx = %ld", address, (long)value]);
        return YES;
    } else {
        writeLog([NSString stringWithFormat:@"❌ 修改失败 0x%lx, 错误码: %d", address, result]);
        return NO;
    }
}

// 动态搜索并修改游戏数据
static BOOL modifyGameData(NSInteger money, NSInteger stamina, NSInteger health, NSInteger mood, NSInteger experience) {
    writeLog(@"========== 开始智能内存搜索和修改 ==========");
    
    BOOL success = NO;
    uintptr_t baseAddress = 0;
    
    // 如果有缓存的基地址，先尝试验证
    if (g_moneyBaseAddress != 0) {
        writeLog([NSString stringWithFormat:@"🔄 验证缓存的基地址: 0x%lx", g_moneyBaseAddress]);
        
        if (verifyGameDataStructure(g_moneyBaseAddress)) {
            baseAddress = g_moneyBaseAddress;
            writeLog(@"✅ 缓存地址仍然有效");
        } else {
            writeLog(@"❌ 缓存地址已失效，需要重新搜索");
            g_moneyBaseAddress = 0;
        }
    }
    
    // 如果没有有效的基地址，进行搜索
    if (baseAddress == 0) {
        writeLog(@"🔍 开始搜索游戏数据结构...");
        
        // 首先尝试搜索一些常见的游戏数值
        NSArray *searchValues = @[@474, @136, @93, @88, @100, @200, @500, @1000];
        
        for (NSNumber *valueNum in searchValues) {
            NSInteger searchValue = [valueNum integerValue];
            writeLog([NSString stringWithFormat:@"🎯 搜索数值: %ld", (long)searchValue]);
            
            NSArray *results = searchMemoryForValue(searchValue);
            
            // 验证每个找到的地址
            for (NSValue *resultValue in results) {
                MemoryResult result;
                [resultValue getValue:&result];
                
                // 尝试将此地址作为基地址验证
                if (verifyGameDataStructure(result.address)) {
                    baseAddress = result.address;
                    g_moneyBaseAddress = baseAddress;
                    writeLog([NSString stringWithFormat:@"🎉 找到有效的游戏数据结构！基地址: 0x%lx", baseAddress]);
                    goto found_base;
                }
                
                // 也尝试将此地址作为偏移地址反推基地址
                uintptr_t possibleBase;
                
                // 如果是体力地址 (基地址 + 24)
                possibleBase = result.address - 24;
                if (verifyGameDataStructure(possibleBase)) {
                    baseAddress = possibleBase;
                    g_moneyBaseAddress = baseAddress;
                    writeLog([NSString stringWithFormat:@"🎉 通过体力地址找到基地址: 0x%lx", baseAddress]);
                    goto found_base;
                }
                
                // 如果是健康地址 (基地址 + 72)
                possibleBase = result.address - 72;
                if (verifyGameDataStructure(possibleBase)) {
                    baseAddress = possibleBase;
                    g_moneyBaseAddress = baseAddress;
                    writeLog([NSString stringWithFormat:@"🎉 通过健康地址找到基地址: 0x%lx", baseAddress]);
                    goto found_base;
                }
                
                // 如果是心情地址 (基地址 + 104)
                possibleBase = result.address - 104;
                if (verifyGameDataStructure(possibleBase)) {
                    baseAddress = possibleBase;
                    g_moneyBaseAddress = baseAddress;
                    writeLog([NSString stringWithFormat:@"🎉 通过心情地址找到基地址: 0x%lx", baseAddress]);
                    goto found_base;
                }
            }
        }
    }
    
found_base:
    
    if (baseAddress == 0) {
        writeLog(@"❌ 未能找到游戏数据结构");
        writeLog(@"💡 请确保游戏正在运行，并且已经进入游戏界面");
        writeLog(@"💡 建议手动操作：");
        writeLog(@"1. 使用iGameGod搜索当前金钱数值");
        writeLog(@"2. 根据偏移关系修改其他属性");
        return NO;
    }
    
    // 开始修改数值
    writeLog(@"🚀 开始修改游戏数值...");
    
    BOOL allSuccess = YES;
    
    if (money > 0) {
        if (writeMemoryValue(baseAddress, money)) {
            writeLog([NSString stringWithFormat:@"💰 金钱修改成功: %ld", (long)money]);
        } else {
            allSuccess = NO;
        }
    }
    
    if (stamina > 0) {
        if (writeMemoryValue(baseAddress + 24, stamina)) {
            writeLog([NSString stringWithFormat:@"⚡ 体力修改成功: %ld", (long)stamina]);
        } else {
            allSuccess = NO;
        }
    }
    
    if (health > 0) {
        if (writeMemoryValue(baseAddress + 72, health)) {
            writeLog([NSString stringWithFormat:@"❤️ 健康修改成功: %ld", (long)health]);
        } else {
            allSuccess = NO;
        }
    }
    
    if (mood > 0) {
        if (writeMemoryValue(baseAddress + 104, mood)) {
            writeLog([NSString stringWithFormat:@"😊 心情修改成功: %ld", (long)mood]);
        } else {
            allSuccess = NO;
        }
    }
    
    if (allSuccess) {
        writeLog(@"🎉 所有数值修改完成！");
        
        // 验证修改结果
        writeLog(@"🔍 验证修改结果...");
        verifyGameDataStructure(baseAddress);
        
        success = YES;
    } else {
        writeLog(@"⚠️ 部分修改失败，请检查权限");
    }
    
    writeLog(@"========== 内存修改结束 ==========");
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
    title.text = @"🏠 我独自生活 v8.0";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 学习提示
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"� 智能内存自动修搜索修改器";
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
    tip.text = @"智能搜索内存中的游戏数据结构\n自动定位并修改所有属性数值";
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
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"🤖 智能修改" 
        message:@"将自动搜索游戏内存数据结构\n并直接修改相应数值\n\n⚠️ 请确保游戏正在运行\n\n确认继续？" 
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}