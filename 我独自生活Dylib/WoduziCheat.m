// 我独自生活修改器 - WoduziCheat.m
// 参考卡包修仙和天选打工人的成功实现
#import <UIKit/UIKit.h>

#pragma mark - 全局变量

@class WDZMenuView;
static UIButton *g_floatButton = nil;
static WDZMenuView *g_menuView = nil;

#pragma mark - 函数前向声明

static void showMenu(void);
static void writeLog(NSString *message);
static UIWindow* getKeyWindow(void);

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
    
    UIViewController *rootVC = getKeyWindow().rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 日志系统

// 获取日志路径
static NSString* getLogPath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths firstObject];
    return [documentsPath stringByAppendingPathComponent:@"woduzishenghua_cheat.log"];
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

#pragma mark - 游戏数据修改

// ES3存档修改 - 针对Unity Easy Save 3系统
static void modifyES3SaveData(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 获取ES3存档数据
    NSString *es3Data = [defaults objectForKey:@"data0.es3"];
    if (!es3Data) {
        writeLog(@"❌ 未找到ES3存档数据 (data0.es3)");
        
        // 尝试其他可能的ES3键名
        NSArray *possibleKeys = @[@"data.es3", @"save.es3", @"gamedata.es3", @"es3data", @"savedata"];
        for (NSString *key in possibleKeys) {
            es3Data = [defaults objectForKey:key];
            if (es3Data) {
                writeLog([NSString stringWithFormat:@"✅ 找到ES3存档: %@", key]);
                break;
            }
        }
        
        if (!es3Data) {
            writeLog(@"❌ 未找到任何ES3存档数据");
            return;
        }
    } else {
        writeLog(@"✅ 找到ES3存档数据 (data0.es3)");
    }
    
    writeLog([NSString stringWithFormat:@"ES3存档长度: %lu", (unsigned long)es3Data.length]);
    writeLog([NSString stringWithFormat:@"ES3数据预览: %@", [es3Data substringToIndex:MIN(100, es3Data.length)]]);
    
    // ES3数据是Base64编码的JSON
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:es3Data options:NSDataBase64DecodingIgnoreUnknownCharacters];
    if (!decodedData) {
        writeLog(@"❌ ES3数据Base64解码失败，尝试直接解析JSON");
        // 可能不是Base64编码，直接尝试JSON解析
        decodedData = [es3Data dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if (!decodedData) {
        writeLog(@"❌ ES3数据处理失败");
        return;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    if (!jsonString) {
        writeLog(@"❌ ES3数据转换为字符串失败");
        return;
    }
    
    writeLog([NSString stringWithFormat:@"✅ ES3 JSON解码成功，长度: %lu", (unsigned long)jsonString.length]);
    writeLog([NSString stringWithFormat:@"ES3内容预览: %@", [jsonString substringToIndex:MIN(200, jsonString.length)]]);
    
    // 解析JSON
    NSError *error = nil;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    
    if (error || !jsonObject) {
        writeLog([NSString stringWithFormat:@"❌ ES3 JSON解析失败: %@", error.localizedDescription]);
        return;
    }
    
    writeLog(@"✅ ES3 JSON解析成功");
    
    NSMutableDictionary *saveDict = nil;
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        saveDict = [jsonObject mutableCopy];
        writeLog([NSString stringWithFormat:@"ES3存档包含 %lu 个对象", (unsigned long)saveDict.count]);
    } else if ([jsonObject isKindOfClass:[NSArray class]]) {
        writeLog(@"ES3存档是数组格式，尝试处理");
        // 如果是数组，可能需要特殊处理
        return;
    } else {
        writeLog(@"❌ ES3存档格式不支持");
        return;
    }
    
    // 列出所有键，寻找游戏数据
    for (NSString *key in saveDict) {
        id value = saveDict[key];
        NSString *valueStr = [NSString stringWithFormat:@"%@", value];
        if (valueStr.length > 100) {
            valueStr = [[valueStr substringToIndex:100] stringByAppendingString:@"..."];
        }
        writeLog([NSString stringWithFormat:@"ES3 Key: %@ = %@", key, valueStr]);
    }
    
    // 尝试修改可能的游戏数据字段
    BOOL modified = NO;
    
    // 直接修改顶级字段
    NSArray *moneyKeys = @[@"money", @"coin", @"coins", @"gold", @"currency", @"cash", @"金币", @"金钱", @"货币", @"Money", @"Coin", @"Gold"];
    NSArray *diamondKeys = @[@"diamond", @"diamonds", @"gem", @"gems", @"crystal", @"premium", @"钻石", @"宝石", @"水晶", @"Diamond", @"Gem"];
    NSArray *energyKeys = @[@"energy", @"stamina", @"power", @"hp", @"health", @"体力", @"能量", @"血量", @"Energy", @"Power", @"HP"];
    
    for (NSString *moneyKey in moneyKeys) {
        if (saveDict[moneyKey]) {
            saveDict[moneyKey] = @999999999;
            modified = YES;
            writeLog([NSString stringWithFormat:@"✅ 修改顶级字段 %@ = 999999999", moneyKey]);
        }
    }
    
    for (NSString *diamondKey in diamondKeys) {
        if (saveDict[diamondKey]) {
            saveDict[diamondKey] = @999999999;
            modified = YES;
            writeLog([NSString stringWithFormat:@"✅ 修改顶级字段 %@ = 999999999", diamondKey]);
        }
    }
    
    for (NSString *energyKey in energyKeys) {
        if (saveDict[energyKey]) {
            saveDict[energyKey] = @999999999;
            modified = YES;
            writeLog([NSString stringWithFormat:@"✅ 修改顶级字段 %@ = 999999999", energyKey]);
        }
    }
    
    // 递归修改嵌套对象
    for (NSString *key in saveDict) {
        id value = saveDict[key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *objDict = [value mutableCopy];
            
            for (NSString *moneyKey in moneyKeys) {
                if (objDict[moneyKey]) {
                    objDict[moneyKey] = @999999999;
                    modified = YES;
                    writeLog([NSString stringWithFormat:@"✅ 修改嵌套字段 %@.%@ = 999999999", key, moneyKey]);
                }
            }
            
            for (NSString *diamondKey in diamondKeys) {
                if (objDict[diamondKey]) {
                    objDict[diamondKey] = @999999999;
                    modified = YES;
                    writeLog([NSString stringWithFormat:@"✅ 修改嵌套字段 %@.%@ = 999999999", key, diamondKey]);
                }
            }
            
            for (NSString *energyKey in energyKeys) {
                if (objDict[energyKey]) {
                    objDict[energyKey] = @999999999;
                    modified = YES;
                    writeLog([NSString stringWithFormat:@"✅ 修改嵌套字段 %@.%@ = 999999999", key, energyKey]);
                }
            }
            
            saveDict[key] = objDict;
        }
    }
    
    if (!modified) {
        writeLog(@"❌ 未找到可修改的游戏数据字段");
        return;
    }
    
    // 重新编码为JSON
    NSData *newJsonData = [NSJSONSerialization dataWithJSONObject:saveDict options:0 error:&error];
    if (error || !newJsonData) {
        writeLog([NSString stringWithFormat:@"❌ ES3 JSON序列化失败: %@", error.localizedDescription]);
        return;
    }
    
    NSString *newJsonString = [[NSString alloc] initWithData:newJsonData encoding:NSUTF8StringEncoding];
    
    // Base64编码
    NSData *encodedData = [newJsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *newES3Data = [encodedData base64EncodedStringWithOptions:0];
    
    // 保存回NSUserDefaults
    [defaults setObject:newES3Data forKey:@"data0.es3"];
    [defaults synchronize];
    
    writeLog(@"🎉 ES3存档修改完成！");
}

// 无限金币功能
static void enableInfiniteMoney(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 先尝试修改ES3存档
    modifyES3SaveData();
    
    // 同时修改NSUserDefaults中的字段（作为备用）
    [defaults setInteger:999999999 forKey:@"money"];
    [defaults setInteger:999999999 forKey:@"coin"];
    [defaults setInteger:999999999 forKey:@"coins"];
    [defaults setInteger:999999999 forKey:@"gold"];
    [defaults setInteger:999999999 forKey:@"currency"];
    [defaults setInteger:999999999 forKey:@"cash"];
    
    // 可能的中文字段
    [defaults setInteger:999999999 forKey:@"金币"];
    [defaults setInteger:999999999 forKey:@"金钱"];
    [defaults setInteger:999999999 forKey:@"货币"];
    
    // 尝试一些可能的字段名
    [defaults setInteger:999999999 forKey:@"Money"];
    [defaults setInteger:999999999 forKey:@"Coin"];
    [defaults setInteger:999999999 forKey:@"Gold"];
    [defaults setInteger:999999999 forKey:@"userMoney"];
    [defaults setInteger:999999999 forKey:@"playerMoney"];
    [defaults setInteger:999999999 forKey:@"gameMoney"];
    
    [defaults synchronize];
    writeLog(@"无限金币已开启");
}

// 无限钻石功能
static void enableInfiniteDiamond(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // ES3存档已在金币函数中处理，这里只处理NSUserDefaults
    [defaults setInteger:999999999 forKey:@"diamond"];
    [defaults setInteger:999999999 forKey:@"diamonds"];
    [defaults setInteger:999999999 forKey:@"gem"];
    [defaults setInteger:999999999 forKey:@"gems"];
    [defaults setInteger:999999999 forKey:@"crystal"];
    [defaults setInteger:999999999 forKey:@"premium"];
    
    // 可能的中文字段
    [defaults setInteger:999999999 forKey:@"钻石"];
    [defaults setInteger:999999999 forKey:@"宝石"];
    [defaults setInteger:999999999 forKey:@"水晶"];
    
    // 尝试一些可能的字段名
    [defaults setInteger:999999999 forKey:@"Diamond"];
    [defaults setInteger:999999999 forKey:@"Gem"];
    [defaults setInteger:999999999 forKey:@"userDiamond"];
    [defaults setInteger:999999999 forKey:@"playerDiamond"];
    [defaults setInteger:999999999 forKey:@"gameDiamond"];
    
    [defaults synchronize];
    writeLog(@"无限钻石已开启");
}

// 无限体力功能
static void enableInfiniteEnergy(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // ES3存档已在金币函数中处理，这里只处理NSUserDefaults
    [defaults setInteger:999999999 forKey:@"energy"];
    [defaults setInteger:999999999 forKey:@"stamina"];
    [defaults setInteger:999999999 forKey:@"power"];
    [defaults setInteger:999999999 forKey:@"hp"];
    [defaults setInteger:999999999 forKey:@"health"];
    
    // 可能的中文字段
    [defaults setInteger:999999999 forKey:@"体力"];
    [defaults setInteger:999999999 forKey:@"能量"];
    [defaults setInteger:999999999 forKey:@"血量"];
    
    // 尝试一些可能的字段名
    [defaults setInteger:999999999 forKey:@"Energy"];
    [defaults setInteger:999999999 forKey:@"Power"];
    [defaults setInteger:999999999 forKey:@"userEnergy"];
    [defaults setInteger:999999999 forKey:@"playerEnergy"];
    [defaults setInteger:999999999 forKey:@"gameEnergy"];
    
    [defaults synchronize];
    writeLog(@"无限体力已开启");
}

// 一键全开功能
static void enableAllFeatures(void) {
    enableInfiniteMoney();
    enableInfiniteDiamond();
    enableInfiniteEnergy();
    
    // 额外的通用字段
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 经验和等级
    [defaults setInteger:999999999 forKey:@"exp"];
    [defaults setInteger:999999999 forKey:@"experience"];
    [defaults setInteger:100 forKey:@"level"];
    [defaults setInteger:100 forKey:@"等级"];
    
    // 积分和声望
    [defaults setInteger:999999999 forKey:@"score"];
    [defaults setInteger:999999999 forKey:@"point"];
    [defaults setInteger:999999999 forKey:@"points"];
    [defaults setInteger:999999999 forKey:@"积分"];
    
    [defaults synchronize];
    writeLog(@"一键全开已启用");
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
    
    CGFloat contentHeight = 380;
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
    title.text = @"🏠 我独自生活";
    title.font = [UIFont boldSystemFontOfSize:20];
    title.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];
    
    CGFloat y = 45;
    
    // 学习提示
    UILabel *info = [[UILabel alloc] initWithFrame:CGRectMake(20, y, contentWidth - 40, 20)];
    info.text = @"🎮 资源仅供学习使用";
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
    tip.text = @"修改后进行一次消费来刷新数值\n⚠️ 请勿关闭游戏，否则修改失效";
    tip.font = [UIFont systemFontOfSize:12];
    tip.textColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
    tip.textAlignment = NSTextAlignmentCenter;
    tip.numberOfLines = 2;
    [self.contentView addSubview:tip];
    y += 48;
    
    // 按钮
    UIButton *btn1 = [self createButtonWithTitle:@"💰 无限金币" tag:1];
    btn1.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn1];
    y += 43;
    
    UIButton *btn2 = [self createButtonWithTitle:@"💎 无限钻石" tag:2];
    btn2.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn2];
    y += 43;
    
    UIButton *btn3 = [self createButtonWithTitle:@"⚡ 无限体力" tag:3];
    btn3.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn3];
    y += 43;
    
    UIButton *btn4 = [self createButtonWithTitle:@"🎁 一键全开" tag:4];
    btn4.frame = CGRectMake(20, y, contentWidth - 40, 35);
    [self.contentView addSubview:btn4];
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
    btn.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:1];
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
    
    UIViewController *rootVC = getKeyWindow().rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    [rootVC presentViewController:confirmAlert animated:YES completion:nil];
}

- (void)performModification:(NSInteger)tag {
    
    BOOL success = YES;
    NSString *message = @"";
    
    writeLog(@"========== 开始修改 ==========");
    
    switch (tag) {
        case 1:
            writeLog(@"功能：无限金币");
            enableInfiniteMoney();
            message = @"💰 无限金币开启成功！\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效";
            break;
        case 2:
            writeLog(@"功能：无限钻石");
            enableInfiniteDiamond();
            message = @"💎 无限钻石开启成功！\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效";
            break;
        case 3:
            writeLog(@"功能：无限体力");
            enableInfiniteEnergy();
            message = @"⚡ 无限体力开启成功！\n\n请进行一次消费操作来刷新数值\n（如使用体力、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效";
            break;
        case 4:
            writeLog(@"功能：一键全开");
            enableAllFeatures();
            message = @"🎁 一键全开成功！\n💰 金币、💎 钻石、⚡ 体力已修改\n\n请进行一次消费操作来刷新数值\n（如购买物品、升级等）\n\n⚠️ 请勿关闭游戏，否则修改会失效";
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
    UIViewController *rootVC = getKeyWindow().rootViewController;
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
        g_floatButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.6 blue:0.86 alpha:0.9];
        g_floatButton.layer.cornerRadius = 25;
        g_floatButton.clipsToBounds = YES;
        g_floatButton.layer.zPosition = 9999;
        
        [g_floatButton setTitle:@"虎" forState:UIControlStateNormal];
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