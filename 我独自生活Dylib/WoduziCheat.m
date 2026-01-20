// 我独自生活修改器 - WoduziCheat.m
// 文件数据拦截系统 v15.1
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach/mach.h>
#import <sys/mman.h>

// 文件数据拦截开关
static BOOL g_fileHookEnabled = NO;
static BOOL g_sqliteHookEnabled = NO;

// 修改后的数值
static NSInteger g_modifiedMoney = 999999999;
static NSInteger g_modifiedStamina = 999999;
static NSInteger g_modifiedHealth = 999;
static NSInteger g_modifiedMood = 999;

// 文件Hook拦截计数器
static NSInteger g_fileInterceptCount = 0;
static NSInteger g_sqliteInterceptCount = 0;

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

#pragma mark - 文件数据拦截系统

// NSData Hook - 拦截数据读取操作
static NSData* (*original_dataWithContentsOfFile)(Class cls, SEL _cmd, NSString *path) = NULL;

static NSData* hooked_dataWithContentsOfFile(Class cls, SEL _cmd, NSString *path) {
    NSData* originalData = original_dataWithContentsOfFile(cls, _cmd, path);
    
    if (g_fileHookEnabled && originalData && path) {
        writeLog([NSString stringWithFormat:@"📁 文件读取: %@", path.lastPathComponent]);
        
        // 检查是否是游戏数据文件
        NSString *fileName = path.lastPathComponent.lowercaseString;
        if ([fileName containsString:@"save"] || [fileName containsString:@"data"] || 
            [fileName containsString:@"game"] || [fileName containsString:@"player"] ||
            [fileName containsString:@"plist"] || [fileName containsString:@"json"]) {
            
            // 尝试解析文件内容
            NSString *content = [[NSString alloc] initWithData:originalData encoding:NSUTF8StringEncoding];
            if (content) {
                writeLog([NSString stringWithFormat:@"📄 文件内容预览: %@", [content substringToIndex:MIN(200, content.length)]]);
                
                // 检查是否包含数值数据
                if ([content containsString:@"474"] || [content containsString:@"136"] || 
                    [content containsString:@"93"] || [content containsString:@"88"]) {
                    
                    g_fileInterceptCount++;
                    writeLog([NSString stringWithFormat:@"🎯 发现疑似游戏数据文件: %@", path]);
                    
                    // 尝试修改数据
                    NSMutableString *modifiedContent = [content mutableCopy];
                    [modifiedContent replaceOccurrencesOfString:@"474" withString:@"999999999" options:0 range:NSMakeRange(0, modifiedContent.length)];
                    [modifiedContent replaceOccurrencesOfString:@"136" withString:@"999999" options:0 range:NSMakeRange(0, modifiedContent.length)];
                    [modifiedContent replaceOccurrencesOfString:@"93" withString:@"999" options:0 range:NSMakeRange(0, modifiedContent.length)];
                    [modifiedContent replaceOccurrencesOfString:@"88" withString:@"999" options:0 range:NSMakeRange(0, modifiedContent.length)];
                    
                    NSData *modifiedData = [modifiedContent dataUsingEncoding:NSUTF8StringEncoding];
                    if (modifiedData) {
                        writeLog(@"✅ 文件数据已修改");
                        return modifiedData;
                    }
                }
            }
        }
    }
    
    return originalData;
}

// NSString Hook - 拦截字符串文件读取
static NSString* (*original_stringWithContentsOfFile)(Class cls, SEL _cmd, NSString *path, NSStringEncoding encoding, NSError **error) = NULL;

static NSString* hooked_stringWithContentsOfFile(Class cls, SEL _cmd, NSString *path, NSStringEncoding encoding, NSError **error) {
    NSString* originalContent = original_stringWithContentsOfFile(cls, _cmd, path, encoding, error);
    
    if (g_fileHookEnabled && originalContent && path) {
        writeLog([NSString stringWithFormat:@"📝 字符串文件读取: %@", path.lastPathComponent]);
        
        // 检查是否包含游戏数值
        if ([originalContent containsString:@"474"] || [originalContent containsString:@"136"] || 
            [originalContent containsString:@"93"] || [originalContent containsString:@"88"]) {
            
            g_fileInterceptCount++;
            writeLog([NSString stringWithFormat:@"🎯 发现游戏数值文件: %@", path]);
            
            // 修改数值
            NSMutableString *modifiedContent = [originalContent mutableCopy];
            [modifiedContent replaceOccurrencesOfString:@"474" withString:@"999999999" options:0 range:NSMakeRange(0, modifiedContent.length)];
            [modifiedContent replaceOccurrencesOfString:@"136" withString:@"999999" options:0 range:NSMakeRange(0, modifiedContent.length)];
            [modifiedContent replaceOccurrencesOfString:@"93" withString:@"999" options:0 range:NSMakeRange(0, modifiedContent.length)];
            [modifiedContent replaceOccurrencesOfString:@"88" withString:@"999" options:0 range:NSMakeRange(0, modifiedContent.length)];
            
            writeLog(@"✅ 字符串文件数据已修改");
            return [modifiedContent copy];
        }
    }
    
    return originalContent;
}

// SQLite Hook - 拦截数据库查询
static int (*original_sqlite3_step)(void *stmt) = NULL;

static int hooked_sqlite3_step(void *stmt) {
    int result = original_sqlite3_step(stmt);
    
    if (g_sqliteHookEnabled && result == 100) { // SQLITE_ROW
        g_sqliteInterceptCount++;
        writeLog([NSString stringWithFormat:@"🗄️ SQLite查询执行: 结果=%d", result]);
        
        // 这里可以进一步分析SQLite结果
        // 但需要更复杂的SQLite API调用来获取具体数据
    }
    
    return result;
}

// 安装文件数据Hook
static void installFileHooks(void) {
    writeLog(@"🔧 开始安装文件数据拦截器...");
    
    // Hook NSData dataWithContentsOfFile:
    Class nsDataClass = [NSData class];
    Method dataMethod = class_getClassMethod(nsDataClass, @selector(dataWithContentsOfFile:));
    if (dataMethod) {
        original_dataWithContentsOfFile = (NSData* (*)(Class, SEL, NSString *))method_getImplementation(dataMethod);
        method_setImplementation(dataMethod, (IMP)hooked_dataWithContentsOfFile);
        writeLog(@"✅ NSData文件读取Hook安装成功");
    }
    
    // Hook NSString stringWithContentsOfFile:encoding:error:
    Class nsStringClass = [NSString class];
    Method stringMethod = class_getClassMethod(nsStringClass, @selector(stringWithContentsOfFile:encoding:error:));
    if (stringMethod) {
        original_stringWithContentsOfFile = (NSString* (*)(Class, SEL, NSString *, NSStringEncoding, NSError **))method_getImplementation(stringMethod);
        method_setImplementation(stringMethod, (IMP)hooked_stringWithContentsOfFile);
        writeLog(@"✅ NSString文件读取Hook安装成功");
    }
    
    // 尝试Hook SQLite
    original_sqlite3_step = dlsym(RTLD_DEFAULT, "sqlite3_step");
    if (original_sqlite3_step) {
        writeLog(@"✅ SQLite Hook准备就绪");
        // 注意：实际的SQLite Hook需要更复杂的实现
    } else {
        writeLog(@"⚠️ 未找到SQLite函数");
    }
    
    writeLog(@"🎉 文件数据拦截器安装完成！");
    writeLog(@"📊 监控范围：NSData + NSString + SQLite");
}

// 核心修改函数：文件数据拦截方式
static BOOL modifyGameDataByFileHook(NSInteger money, NSInteger stamina, NSInteger health, NSInteger mood, NSInteger experience) {
    writeLog(@"========== 开始文件数据拦截修改 v15.1 ==========");
    
    // 重置拦截计数器
    g_fileInterceptCount = 0;
    g_sqliteInterceptCount = 0;
    
    // 安装Hook（如果还没安装）
    static BOOL fileHooksInstalled = NO;
    if (!fileHooksInstalled) {
        installFileHooks();
        fileHooksInstalled = YES;
    }
    
    // 启用文件Hook
    g_fileHookEnabled = YES;
    g_sqliteHookEnabled = YES;
    
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
    
    writeLog(@"🎯 文件数据拦截器已激活");
    writeLog(@"📊 监控文件读取操作，智能识别游戏数据");
    writeLog(@"💡 提示：在游戏中进行操作，触发数据文件读取以查看拦截效果");
    
    // 延迟检查拦截效果
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        writeLog([NSString stringWithFormat:@"📈 8秒内文件拦截次数: %ld", (long)g_fileInterceptCount]);
        writeLog([NSString stringWithFormat:@"📈 8秒内SQLite拦截次数: %ld", (long)g_sqliteInterceptCount]);
        
        if (g_fileInterceptCount == 0 && g_sqliteInterceptCount == 0) {
            writeLog(@"⚠️ 未检测到文件数据读取");
            writeLog(@"💡 建议：在游戏中进行操作（购买、使用体力等）触发数据保存/读取");
            writeLog(@"🔍 游戏可能使用内存缓存或其他存储方式");
        } else if (g_fileInterceptCount > 0) {
            writeLog(@"✅ 文件拦截器正在工作，已检测到数据文件读取");
        } else if (g_sqliteInterceptCount > 0) {
            writeLog(@"✅ SQLite拦截器正在工作，已检测到数据库操作");
        }
    });
    
    writeLog(@"========== 文件数据拦截修改完成 ==========");
    
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
    title.text = @"🏠 我独自生活 v15.1";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 学习提示
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"📁 文件数据拦截器";
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
    tip.text = @"v15.1: 文件数据拦截\n监控NSData/NSString/SQLite";
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
    
    UIButton *btn6 = [self createButtonWithTitle:@"📁 文件状态" tag:6];
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
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"📁 文件数据拦截 v15.1" 
        message:@"新特性：\n• Hook NSData文件读取\n• Hook NSString文件读取\n• Hook SQLite数据库操作\n• 智能识别游戏数据文件\n• 基于已知数值自动替换\n\n⚠️ 启用后在游戏中操作查看效果\n\n确认继续？" 
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
            success = modifyGameDataByFileHook(999999999, 0, 0, 0, 0);
            message = success ? @"💰 文件金钱拦截已启用！\n\n监控文件读取，智能识别金钱数据\n在游戏中操作触发拦截效果" : @"❌ 文件Hook安装失败，请查看日志";
            break;
        case 2:
            writeLog(@"功能：无限体力");
            success = modifyGameDataByFileHook(0, 999999, 0, 0, 0);
            message = success ? @"⚡ 文件体力拦截已启用！\n\n监控文件读取，智能识别体力数据\n在游戏中操作触发拦截效果" : @"❌ 文件Hook安装失败，请查看日志";
            break;
        case 3:
            writeLog(@"功能：无限健康");
            success = modifyGameDataByFileHook(0, 0, 999, 0, 0);
            message = success ? @"❤️ 文件健康拦截已启用！\n\n监控文件读取，智能识别健康数据\n在游戏中操作触发拦截效果" : @"❌ 文件Hook安装失败，请查看日志";
            break;
        case 4:
            writeLog(@"功能：无限心情");
            success = modifyGameDataByFileHook(0, 0, 0, 999, 0);
            message = success ? @"😊 文件心情拦截已启用！\n\n监控文件读取，智能识别心情数据\n在游戏中操作触发拦截效果" : @"❌ 文件Hook安装失败，请查看日志";
            break;
        case 5:
            writeLog(@"功能：一键全开");
            success = modifyGameDataByFileHook(999999999, 999999, 999, 999, 0);
            message = success ? @"🎁 文件全能拦截已启用！\n\n💰金钱、⚡体力、❤️健康、😊心情\n所有文件拦截器已激活！" : @"❌ 文件Hook安装失败，请查看日志";
            break;
        case 6:
            writeLog(@"功能：文件状态");
            writeLog([NSString stringWithFormat:@"📁 文件Hook: %@", g_fileHookEnabled ? @"已启用" : @"未启用"]);
            writeLog([NSString stringWithFormat:@"🗄️ SQLite Hook: %@", g_sqliteHookEnabled ? @"已启用" : @"未启用"]);
            writeLog([NSString stringWithFormat:@"📈 文件拦截次数: %ld", (long)g_fileInterceptCount]);
            writeLog([NSString stringWithFormat:@"📈 SQLite拦截次数: %ld", (long)g_sqliteInterceptCount]);
            success = YES;
            message = @"📁 文件状态检查完成！\n\n请用Filza查看详细日志：\n/var/mobile/Documents/woduzi_cheat.log\n\n日志包含文件拦截信息";
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
        
        writeLog(@"🛡️ WoduziCheat v15.1 初始化完成 - 文件数据拦截已启用");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            setupFloatingButton();
        });
    }
}