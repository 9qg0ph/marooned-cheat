// 我独自生活修改器 - WoduziCheat.m
// 专注于Unity游戏真实存档检测和修改
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

// Unity游戏存档检测和修改
static BOOL modifyGameData(NSInteger money, NSInteger stamina, NSInteger health, NSInteger mood, NSInteger experience) {
    writeLog(@"========== Unity游戏存档分析开始 ==========");
    
    BOOL fileSuccess = NO;
    BOOL playerPrefsSuccess = NO;
    
    // 第一步：全面扫描Documents目录
    writeLog(@"🔍 开始全面扫描Documents目录");
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:documentsPath error:nil];
    
    writeLog([NSString stringWithFormat:@"📁 Documents目录: %@", documentsPath]);
    writeLog([NSString stringWithFormat:@"📄 文件总数: %lu", (unsigned long)files.count]);
    
    // 列出所有文件
    for (NSString *file in files) {
        NSString *filePath = [documentsPath stringByAppendingPathComponent:file];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:nil];
        NSNumber *fileSize = [attributes objectForKey:NSFileSize];
        BOOL isDirectory = [[attributes objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory];
        
        writeLog([NSString stringWithFormat:@"📋 %@%@ - %@ bytes", 
                file, isDirectory ? @"/" : @"", fileSize ?: @"0"]);
        
        // 检查每个文件
        if (!isDirectory && [fileSize longLongValue] > 0) {
            NSData *fileData = [NSData dataWithContentsOfFile:filePath];
            if (fileData) {
                // 尝试读取为文本
                NSString *textContent = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
                if (textContent && textContent.length > 0) {
                    writeLog([NSString stringWithFormat:@"📝 %@ 是文本文件，长度: %lu", file, (unsigned long)textContent.length]);
                    
                    // 检查是否包含游戏数据
                    BOOL hasGameData = NO;
                    NSArray *gameKeywords = @[@"money", @"cash", @"coin", @"gold", @"level", @"score", @"player", 
                                            @"金钱", @"现金", @"金币", @"等级", @"分数", @"玩家"];
                    
                    for (NSString *keyword in gameKeywords) {
                        if ([textContent.lowercaseString containsString:keyword.lowercaseString]) {
                            hasGameData = YES;
                            writeLog([NSString stringWithFormat:@"🎯 %@ 包含关键词: %@", file, keyword]);
                        }
                    }
                    
                    // 检查是否包含大数值（可能是游戏数据）
                    NSRegularExpression *numberRegex = [NSRegularExpression regularExpressionWithPattern:@"\\b\\d{4,}\\b" options:0 error:nil];
                    NSArray *matches = [numberRegex matchesInString:textContent options:0 range:NSMakeRange(0, textContent.length)];
                    if (matches.count > 0) {
                        hasGameData = YES;
                        writeLog([NSString stringWithFormat:@"🔢 %@ 包含 %lu 个大数值", file, (unsigned long)matches.count]);
                        
                        // 显示前几个数值
                        for (int i = 0; i < MIN(5, matches.count); i++) {
                            NSTextCheckingResult *match = matches[i];
                            NSString *number = [textContent substringWithRange:match.range];
                            writeLog([NSString stringWithFormat:@"   数值: %@", number]);
                        }
                    }
                    
                    if (hasGameData && money > 0) {
                        writeLog([NSString stringWithFormat:@"🛠️ 尝试修改文件: %@", file]);
                        
                        // 备份原文件
                        NSString *backupPath = [filePath stringByAppendingString:@".backup"];
                        [fileData writeToFile:backupPath atomically:YES];
                        writeLog([NSString stringWithFormat:@"💾 已备份到: %@", backupPath]);
                        
                        // 替换大数值
                        NSString *modifiedContent = textContent;
                        NSString *replacement = [NSString stringWithFormat:@"%ld", (long)money];
                        
                        modifiedContent = [numberRegex stringByReplacingMatchesInString:modifiedContent 
                            options:0 range:NSMakeRange(0, modifiedContent.length) withTemplate:replacement];
                        
                        // 写回文件
                        NSData *modifiedData = [modifiedContent dataUsingEncoding:NSUTF8StringEncoding];
                        if ([modifiedData writeToFile:filePath atomically:YES]) {
                            writeLog([NSString stringWithFormat:@"✅ 成功修改文件: %@", file]);
                            fileSuccess = YES;
                        } else {
                            writeLog([NSString stringWithFormat:@"❌ 修改文件失败: %@", file]);
                        }
                    }
                } else {
                    // 二进制文件
                    writeLog([NSString stringWithFormat:@"🔒 %@ 是二进制文件", file]);
                    
                    // 显示文件头
                    if (fileData.length >= 16) {
                        const unsigned char *bytes = (const unsigned char *)[fileData bytes];
                        NSMutableString *hexString = [NSMutableString string];
                        for (int i = 0; i < 16; i++) {
                            [hexString appendFormat:@"%02X ", bytes[i]];
                        }
                        writeLog([NSString stringWithFormat:@"🔢 文件头: %@", hexString]);
                    }
                }
            }
        }
    }
    
    // 第二步：检查Unity PlayerPrefs（NSUserDefaults）
    writeLog(@"🔍 开始检查Unity PlayerPrefs");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *allDefaults = [defaults dictionaryRepresentation];
    
    writeLog([NSString stringWithFormat:@"📊 NSUserDefaults总键数: %lu", (unsigned long)allDefaults.count]);
    
    // 查找所有可能相关的键
    NSMutableArray *suspiciousKeys = [NSMutableArray array];
    
    for (NSString *key in allDefaults.allKeys) {
        id value = [allDefaults objectForKey:key];
        
        // 检查键名
        BOOL keyMatch = NO;
        NSArray *keyKeywords = @[@"unity", @"Unity", @"hezi", @"Hezi", @"project", @"Project", 
                               @"money", @"cash", @"coin", @"gold", @"level", @"score", @"player",
                               @"金钱", @"现金", @"金币", @"等级", @"分数", @"玩家"];
        
        for (NSString *keyword in keyKeywords) {
            if ([key containsString:keyword]) {
                keyMatch = YES;
                break;
            }
        }
        
        // 检查数值
        BOOL valueMatch = NO;
        if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber *numValue = (NSNumber *)value;
            if ([numValue longLongValue] >= 1000) {
                valueMatch = YES;
            }
        }
        
        if (keyMatch || valueMatch) {
            [suspiciousKeys addObject:key];
            writeLog([NSString stringWithFormat:@"🔑 疑似游戏键: %@ = %@", key, value]);
        }
    }
    
    // 修改疑似的游戏数据
    if (money > 0 && suspiciousKeys.count > 0) {
        writeLog(@"🛠️ 开始修改疑似游戏数据");
        
        for (NSString *key in suspiciousKeys) {
            id value = [allDefaults objectForKey:key];
            
            if ([value isKindOfClass:[NSNumber class]]) {
                NSNumber *oldValue = (NSNumber *)value;
                [defaults setObject:@(money) forKey:key];
                writeLog([NSString stringWithFormat:@"✅ 修改: %@ = %@ -> %ld", key, oldValue, (long)money]);
                playerPrefsSuccess = YES;
            }
        }
        
        if (playerPrefsSuccess) {
            [defaults synchronize];
            writeLog(@"💾 NSUserDefaults同步完成");
        }
    }
    
    // 第三步：总结和建议
    BOOL overallSuccess = fileSuccess || playerPrefsSuccess;
    
    writeLog(@"========== 修改结果总结 ==========");
    if (overallSuccess) {
        writeLog(@"🎉 找到并修改了疑似游戏数据！");
        if (fileSuccess) writeLog(@"✅ 文件修改成功");
        if (playerPrefsSuccess) writeLog(@"✅ PlayerPrefs修改成功");
        
        writeLog(@"💡 重要提示：");
        writeLog(@"1. 请完全关闭游戏后重新打开");
        writeLog(@"2. 进行一次游戏操作（如购买、升级）来刷新数据");
        writeLog(@"3. 如果仍无效果，游戏可能使用服务器存档");
        
    } else {
        writeLog(@"❌ 未找到明确的游戏存档数据");
        writeLog(@"💡 可能的原因：");
        writeLog(@"1. 游戏使用加密存档");
        writeLog(@"2. 数据完全存储在服务器端");
        writeLog(@"3. 使用特殊的存储格式");
        writeLog(@"4. 建议使用内存修改工具（如GameGem）");
    }
    
    writeLog(@"========== 分析结束 ==========");
    return overallSuccess;
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
    title.text = @"🏠 我独自生活 v6.0";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 学习提示
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"🎮 Unity存档检测：文件+PlayerPrefs";
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
    tip.text = @"修改后请完全关闭游戏重新打开\n然后进行一次消费操作来刷新数值";
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
    
    UIButton *btn5 = [self createButtonWithTitle:@"🎯 无限经验" tag:5];
    btn5.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn5];
    y += 43;
    
    UIButton *btn6 = [self createButtonWithTitle:@"🔍 存档分析" tag:6];
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
    UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:@"⚠️ 确认修改" 
        message:@"修改后请完全关闭游戏重新打开\n然后进行一次消费操作来刷新数值\n\n⚠️ 请勿在修改过程中关闭游戏\n\n确认继续？" 
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
            success = modifyGameData(21000000000, 0, 0, 0, 0);
            message = success ? @"💰 无限金钱修改完成！\n\n请完全关闭游戏重新打开\n然后进行一次消费操作来刷新数值\n\n⚠️ 如仍无效果，请查看日志分析" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 2:
            writeLog(@"功能：无限体力");
            success = modifyGameData(0, 21000000000, 0, 0, 0);
            message = success ? @"⚡ 无限体力修改完成！\n\n请完全关闭游戏重新打开\n然后进行一次消费操作来刷新数值\n\n⚠️ 如仍无效果，请查看日志分析" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 3:
            writeLog(@"功能：无限健康");
            success = modifyGameData(0, 0, 1000000, 0, 0);
            message = success ? @"❤️ 无限健康修改完成！\n\n请完全关闭游戏重新打开\n然后进行一次消费操作来刷新数值\n\n⚠️ 如仍无效果，请查看日志分析" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 4:
            writeLog(@"功能：无限心情");
            success = modifyGameData(0, 0, 0, 1000000, 0);
            message = success ? @"😊 无限心情修改完成！\n\n请完全关闭游戏重新打开\n然后进行一次消费操作来刷新数值\n\n⚠️ 如仍无效果，请查看日志分析" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 5:
            writeLog(@"功能：无限经验");
            success = modifyGameData(0, 0, 0, 0, 999999999);
            message = success ? @"🎯 无限经验修改完成！\n\n请完全关闭游戏重新打开\n然后进行一次消费操作来刷新数值\n\n⚠️ 如仍无效果，请查看日志分析" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 6:
            writeLog(@"功能：存档分析");
            success = modifyGameData(0, 0, 0, 0, 0); // 只分析，不修改
            message = @"🔍 存档分析完成！\n\n请用Filza查看详细日志：\n/var/mobile/Documents/woduzi_cheat.log\n\n日志包含所有发现的文件和数据";
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