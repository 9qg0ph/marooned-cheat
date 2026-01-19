// 我独自生活修改器 - WoduziCheat.m
// 基于天选打工人修改器改进，适配plist格式存档
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

// 双重修改：NSUserDefaults直接字段 + ES3Save存档格式
static BOOL modifyGameData(NSInteger money, NSInteger stamina, NSInteger health, NSInteger mood, NSInteger experience) {
    writeLog(@"========== 开始修改 ==========");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL directSuccess = NO;
    BOOL es3Success = NO;
    
    // 第一步：修改NSUserDefaults直接字段
    writeLog(@"开始修改NSUserDefaults直接字段");
    
    // 根据存档文件的实际字段名修改
    NSArray *moneyKeys = @[@"userCash", @"金钱", @"玩家现金", @"现金"];
    NSArray *staminaKeys = @[@"Stamina"];
    NSArray *healthKeys = @[@"当前健康"];
    
    int directModified = 0;
    
    // 修改金钱相关字段
    if (money > 0) {
        for (NSString *key in moneyKeys) {
            id value = [defaults objectForKey:key];
            if (value) {
                [defaults setInteger:money forKey:key];
                writeLog([NSString stringWithFormat:@"✅ 修改直接字段 %@: %ld", key, (long)money]);
                directModified++;
            }
        }
    }
    
    // 修改体力相关字段
    if (stamina > 0) {
        for (NSString *key in staminaKeys) {
            id value = [defaults objectForKey:key];
            if (value) {
                [defaults setInteger:stamina forKey:key];
                writeLog([NSString stringWithFormat:@"✅ 修改直接字段 %@: %ld", key, (long)stamina]);
                directModified++;
            }
        }
    }
    
    // 修改健康相关字段
    if (health > 0) {
        for (NSString *key in healthKeys) {
            id value = [defaults objectForKey:key];
            if (value) {
                [defaults setInteger:health forKey:key];
                writeLog([NSString stringWithFormat:@"✅ 修改直接字段 %@: %ld", key, (long)health]);
                directModified++;
            }
        }
    }
    
    if (directModified > 0) {
        directSuccess = [defaults synchronize];
        writeLog(directSuccess ? @"✅ NSUserDefaults直接字段修改完成" : @"❌ NSUserDefaults同步失败");
    } else {
        writeLog(@"⚠️ 未找到可修改的直接字段");
    }
    
    // 第二步：修改ES3Save存档数据
    writeLog(@"开始修改ES3Save存档数据");
    
    NSString *es3Data = [defaults stringForKey:@"data1.es3"];
    if (!es3Data) {
        writeLog(@"❌ 未找到data1.es3存档数据");
    } else {
        writeLog([NSString stringWithFormat:@"✅ 找到ES3存档数据，长度: %lu", (unsigned long)es3Data.length]);
        
        // Base64解码
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:es3Data options:0];
        if (!decodedData) {
            writeLog(@"❌ Base64解码失败");
        } else {
            writeLog(@"✅ Base64解码成功");
            
            // 直接进行字符串替换修改（跳过JSON解析）
            NSString *jsonString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
            if (!jsonString) {
                writeLog(@"❌ JSON字符串转换失败");
            } else {
                writeLog(@"🔍 开始字符串替换修改ES3数据");
                writeLog([NSString stringWithFormat:@"JSON字符串长度: %lu", (unsigned long)jsonString.length]);
                
                // 输出JSON前1000个字符用于调试
                NSString *jsonPreview = jsonString.length > 1000 ? [jsonString substringToIndex:1000] : jsonString;
                writeLog([NSString stringWithFormat:@"📝 JSON前1000字符: %@", jsonPreview]);
                
                // 搜索包含"金钱"、"现金"等关键词的位置
                NSRange moneyRange = [jsonString rangeOfString:@"金钱"];
                NSRange cashRange = [jsonString rangeOfString:@"现金"];
                if (moneyRange.location != NSNotFound) {
                    NSInteger start = MAX(0, (NSInteger)moneyRange.location - 100);
                    NSInteger length = MIN(200, (NSInteger)jsonString.length - start);
                    NSString *moneyContext = [jsonString substringWithRange:NSMakeRange(start, length)];
                    writeLog([NSString stringWithFormat:@"💰 找到'金钱'字段上下文: %@", moneyContext]);
                }
                if (cashRange.location != NSNotFound) {
                    NSInteger start = MAX(0, (NSInteger)cashRange.location - 100);
                    NSInteger length = MIN(200, (NSInteger)jsonString.length - start);
                    NSString *cashContext = [jsonString substringWithRange:NSMakeRange(start, length)];
                    writeLog([NSString stringWithFormat:@"💰 找到'现金'字段上下文: %@", cashContext]);
                }
                
                NSString *modifiedJsonString = jsonString;
                BOOL stringModified = NO;
                int replaceCount = 0;
                
                if (money > 0) {
                    writeLog(@"🔍 开始查找金钱相关字段");
                    // 使用更宽泛的模式匹配包含金钱关键词的字段
                    NSArray *moneyPatterns = @[
                        @"\"[^\"]*金钱[^\"]*\"\\s*:\\s*\\d+",  // 匹配任何包含"金钱"的字段
                        @"\"[^\"]*现金[^\"]*\"\\s*:\\s*\\d+",  // 匹配任何包含"现金"的字段
                        @"\"[^\"]*钱[^\"]*\"\\s*:\\s*\\d+",    // 匹配任何包含"钱"的字段
                        @"\"[^\"]*金额[^\"]*\"\\s*:\\s*\\d+",  // 匹配任何包含"金额"的字段
                        @"\"userCash\"\\s*:\\s*\\d+",
                        @"\"Cash\"\\s*:\\s*\\d+",
                        @"\"money\"\\s*:\\s*\\d+",
                        @"\"Money\"\\s*:\\s*\\d+",
                        @"\"coin\"\\s*:\\s*\\d+",
                        @"\"Coin\"\\s*:\\s*\\d+"
                    ];
                    
                    // 先搜索是否包含任何金钱相关的中文字符
                    if ([modifiedJsonString containsString:@"金钱"] || 
                        [modifiedJsonString containsString:@"现金"] || 
                        [modifiedJsonString containsString:@"金额"] ||
                        [modifiedJsonString containsString:@"钱"]) {
                        writeLog(@"✅ JSON中包含金钱相关字符");
                    } else {
                        writeLog(@"❌ JSON中未找到金钱相关字符");
                    }
                    
                    for (NSString *pattern in moneyPatterns) {
                        NSError *regexError = nil;
                        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regexError];
                        if (regexError) {
                            writeLog([NSString stringWithFormat:@"❌ 正则表达式创建失败: %@", regexError]);
                            continue;
                        }
                        
                        // 检查匹配数量
                        NSUInteger matchCount = [regex numberOfMatchesInString:modifiedJsonString options:0 range:NSMakeRange(0, modifiedJsonString.length)];
                        writeLog([NSString stringWithFormat:@"🔍 模式 %@ 找到 %lu 个匹配", pattern, (unsigned long)matchCount]);
                        
                        if (matchCount > 0) {
                            // 获取所有匹配并替换
                            NSArray *matches = [regex matchesInString:modifiedJsonString options:0 range:NSMakeRange(0, modifiedJsonString.length)];
                            
                            // 从后往前替换，避免位置偏移
                            for (NSInteger i = matches.count - 1; i >= 0; i--) {
                                NSTextCheckingResult *match = [matches objectAtIndex:i];
                                NSString *matchedString = [modifiedJsonString substringWithRange:match.range];
                                writeLog([NSString stringWithFormat:@"🎯 找到匹配: %@", matchedString]);
                                
                                // 提取字段名
                                NSRange colonRange = [matchedString rangeOfString:@":"];
                                if (colonRange.location != NSNotFound) {
                                    NSString *fieldPart = [matchedString substringToIndex:colonRange.location];
                                    NSString *replacement = [NSString stringWithFormat:@"%@ : %ld", fieldPart, (long)money];
                                    
                                    modifiedJsonString = [modifiedJsonString stringByReplacingCharactersInRange:match.range withString:replacement];
                                    stringModified = YES;
                                    replaceCount++;
                                    writeLog([NSString stringWithFormat:@"✅ 替换字段: %@ -> %ld", fieldPart, (long)money]);
                                }
                            }
                        }
                    }
                }
                
                if (stamina > 0) {
                    writeLog(@"🔍 开始查找体力相关字段");
                    NSArray *staminaPatterns = @[
                        @"\"Stamina\"\\s*:\\s*\\d+",
                        @"\"体力\"\\s*:\\s*\\d+",
                        @"\"玩家体力\"\\s*:\\s*\\d+",
                        @"\"当前体力\"\\s*:\\s*\\d+"
                    ];
                    
                    for (NSString *pattern in staminaPatterns) {
                        NSError *regexError = nil;
                        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regexError];
                        if (regex) {
                            NSUInteger matchCount = [regex numberOfMatchesInString:modifiedJsonString options:0 range:NSMakeRange(0, modifiedJsonString.length)];
                            writeLog([NSString stringWithFormat:@"🔍 模式 %@ 找到 %lu 个匹配", pattern, (unsigned long)matchCount]);
                            
                            if (matchCount > 0) {
                                NSArray *components = [pattern componentsSeparatedByString:@"\""];
                                if (components.count > 1) {
                                    NSString *fieldName = [components objectAtIndex:1];
                                    NSString *replacement = [NSString stringWithFormat:@"\"%@\" : %ld", fieldName, (long)stamina];
                                    NSString *newString = [regex stringByReplacingMatchesInString:modifiedJsonString 
                                        options:0 range:NSMakeRange(0, modifiedJsonString.length) withTemplate:replacement];
                                    if (![newString isEqualToString:modifiedJsonString]) {
                                        modifiedJsonString = newString;
                                        stringModified = YES;
                                        replaceCount++;
                                        writeLog([NSString stringWithFormat:@"✅ 替换体力字段 %@: %ld (%lu处)", fieldName, (long)stamina, (unsigned long)matchCount]);
                                    }
                                }
                            }
                        }
                    }
                }
                
                if (health > 0) {
                    writeLog(@"🔍 开始查找健康相关字段");
                    NSArray *healthPatterns = @[
                        @"\"当前健康\"\\s*:\\s*\\d+",
                        @"\"健康\"\\s*:\\s*\\d+",
                        @"\"Health\"\\s*:\\s*\\d+"
                    ];
                    
                    for (NSString *pattern in healthPatterns) {
                        NSError *regexError = nil;
                        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regexError];
                        if (regex) {
                            NSUInteger matchCount = [regex numberOfMatchesInString:modifiedJsonString options:0 range:NSMakeRange(0, modifiedJsonString.length)];
                            writeLog([NSString stringWithFormat:@"🔍 模式 %@ 找到 %lu 个匹配", pattern, (unsigned long)matchCount]);
                            
                            if (matchCount > 0) {
                                NSArray *components = [pattern componentsSeparatedByString:@"\""];
                                if (components.count > 1) {
                                    NSString *fieldName = [components objectAtIndex:1];
                                    NSString *replacement = [NSString stringWithFormat:@"\"%@\" : %ld", fieldName, (long)health];
                                    NSString *newString = [regex stringByReplacingMatchesInString:modifiedJsonString 
                                        options:0 range:NSMakeRange(0, modifiedJsonString.length) withTemplate:replacement];
                                    if (![newString isEqualToString:modifiedJsonString]) {
                                        modifiedJsonString = newString;
                                        stringModified = YES;
                                        replaceCount++;
                                        writeLog([NSString stringWithFormat:@"✅ 替换健康字段 %@: %ld (%lu处)", fieldName, (long)health, (unsigned long)matchCount]);
                                    }
                                }
                            }
                        }
                    }
                }
                
                writeLog([NSString stringWithFormat:@"📊 总共完成 %d 个字段替换", replaceCount]);
                
                if (stringModified) {
                    // 重新Base64编码
                    NSData *modifiedData = [modifiedJsonString dataUsingEncoding:NSUTF8StringEncoding];
                    NSString *newES3Data = [modifiedData base64EncodedStringWithOptions:0];
                    
                    // 写回NSUserDefaults
                    [defaults setObject:newES3Data forKey:@"data1.es3"];
                    es3Success = [defaults synchronize];
                    
                    if (es3Success) {
                        writeLog(@"✅ 字符串替换修改ES3存档成功！");
                    } else {
                        writeLog(@"❌ 字符串替换修改ES3存档失败");
                    }
                } else {
                    writeLog(@"⚠️ 未找到可替换的ES3字段");
                }
            }
        }
    }
    
    BOOL overallSuccess = directSuccess || es3Success;
    
    if (overallSuccess) {
        writeLog(@"🎉 双重修改完成！");
        if (directSuccess && es3Success) {
            writeLog(@"✅ 直接字段和ES3存档都修改成功");
        } else if (directSuccess) {
            writeLog(@"✅ 直接字段修改成功，ES3存档修改失败");
        } else if (es3Success) {
            writeLog(@"✅ ES3存档修改成功，直接字段修改失败");
        }
    } else {
        writeLog(@"❌ 双重修改都失败");
    }
    
    writeLog(@"========== 修改结束 ==========");
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
    title.text = @"🏠 我独自生活 v5.0";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 学习提示
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"🎮 双重修改：直接字段+ES3Save";
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
    disclaimer.scrollEnabled = YES;  // 启用滚动
    disclaimer.showsVerticalScrollIndicator = YES;  // 显示滚动条
    [self.contentView addSubview:disclaimer];
    y += 70;
    
    // 提示
    UILabel *tip = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 40)];
    tip.text = @"修改成功后请进行一次消费操作来刷新数值\n（如购买物品、升级等）";
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
    
    UIButton *btn6 = [self createButtonWithTitle:@"🎁 一键全开" tag:6];
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
        message:@"修改后请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效\n\n确认继续？" 
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
            message = success ? @"💰 无限金钱开启成功！\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 2:
            writeLog(@"功能：无限体力");
            success = modifyGameData(0, 21000000000, 0, 0, 0);
            message = success ? @"⚡ 无限体力开启成功！\n\n请进行一次消费操作来刷新数值\n（如使用体力、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 3:
            writeLog(@"功能：无限健康");
            success = modifyGameData(0, 0, 1000000, 0, 0);
            message = success ? @"❤️ 无限健康开启成功！\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 4:
            writeLog(@"功能：无限心情");
            success = modifyGameData(0, 0, 0, 1000000, 0);
            message = success ? @"😊 无限心情开启成功！\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 5:
            writeLog(@"功能：无限经验");
            success = modifyGameData(0, 0, 0, 0, 999999999);
            message = success ? @"🎯 无限经验开启成功！\n\n请进行一次消费操作来刷新数值\n（如升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效" : @"❌ 修改失败，请用Filza查看日志";
            break;
        case 6:
            writeLog(@"功能：一键全开");
            success = modifyGameData(21000000000, 21000000000, 1000000, 1000000, 999999999);
            message = success ? @"🎁 一键全开成功！\n💰 现金、⚡ 体力、❤️ 健康、😊 心情已修改\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效" : @"❌ 修改失败，请用Filza查看日志";
            break;
    }
    
    writeLog(@"========== 修改结束 ==========\n");
    
    // 显示成功提示，不关闭游戏
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