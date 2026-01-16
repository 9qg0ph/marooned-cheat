/**
 * AutoTranslate.dylib - 自动将英文翻译成中文的插件
 * 
 * 功能：
 * 1. Hook UILabel、UIButton、UITextField等控件的文本设置方法
 * 2. 内置常用游戏/应用词汇翻译字典
 * 3. 支持在线翻译API (Google/百度) - 可翻译任意英文
 * 4. 翻译缓存，避免重复请求
 * 
 * 编译命令 (需要theos环境):
 * make package
 */

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// ============== 翻译字典 ==============
static NSDictionary *translationDict = nil;

// 初始化翻译字典
static void initTranslationDict() {
    translationDict = @{
        // 通用UI
        @"OK": @"确定",
        @"Cancel": @"取消",
        @"Done": @"完成",
        @"Back": @"返回",
        @"Next": @"下一步",
        @"Previous": @"上一步",
        @"Close": @"关闭",
        @"Open": @"打开",
        @"Save": @"保存",
        @"Delete": @"删除",
        @"Edit": @"编辑",
        @"Add": @"添加",
        @"Remove": @"移除",
        @"Yes": @"是",
        @"No": @"否",
        @"Confirm": @"确认",
        @"Submit": @"提交",
        @"Continue": @"继续",
        @"Skip": @"跳过",
        @"Retry": @"重试",
        @"Refresh": @"刷新",
        @"Loading": @"加载中",
        @"Loading...": @"加载中...",
        @"Please wait": @"请稍候",
        @"Please wait...": @"请稍候...",
        
        // 设置相关
        @"Settings": @"设置",
        @"Options": @"选项",
        @"Preferences": @"偏好设置",
        @"General": @"通用",
        @"Account": @"账户",
        @"Privacy": @"隐私",
        @"Security": @"安全",
        @"Notifications": @"通知",
        @"Sound": @"声音",
        @"Music": @"音乐",
        @"Volume": @"音量",
        @"Language": @"语言",
        @"About": @"关于",
        @"Help": @"帮助",
        @"Support": @"支持",
        @"Feedback": @"反馈",
        @"Rate": @"评分",
        @"Share": @"分享",
        @"Restore": @"恢复",
        @"Reset": @"重置",
        @"Clear": @"清除",
        @"On": @"开",
        @"Off": @"关",
        @"Enable": @"启用",
        @"Disable": @"禁用",
        @"Enabled": @"已启用",
        @"Disabled": @"已禁用",
        
        // 游戏通用
        @"Play": @"开始游戏",
        @"Start": @"开始",
        @"Pause": @"暂停",
        @"Resume": @"继续",
        @"Stop": @"停止",
        @"Quit": @"退出",
        @"Exit": @"退出",
        @"Menu": @"菜单",
        @"Main Menu": @"主菜单",
        @"New Game": @"新游戏",
        @"Continue Game": @"继续游戏",
        @"Load Game": @"加载游戏",
        @"Save Game": @"保存游戏",
        @"Level": @"关卡",
        @"Stage": @"阶段",
        @"Chapter": @"章节",
        @"Mission": @"任务",
        @"Quest": @"任务",
        @"Challenge": @"挑战",
        @"Achievement": @"成就",
        @"Achievements": @"成就",
        @"Reward": @"奖励",
        @"Rewards": @"奖励",
        @"Bonus": @"奖励",
        @"Prize": @"奖品",
        @"Gift": @"礼物",
        @"Free": @"免费",
        @"Buy": @"购买",
        @"Purchase": @"购买",
        @"Shop": @"商店",
        @"Store": @"商店",
        @"Inventory": @"背包",
        @"Items": @"物品",
        @"Equipment": @"装备",
        @"Weapon": @"武器",
        @"Weapons": @"武器",
        @"Armor": @"护甲",
        @"Skill": @"技能",
        @"Skills": @"技能",
        @"Ability": @"能力",
        @"Abilities": @"能力",
        @"Power": @"力量",
        @"Speed": @"速度",
        @"Health": @"生命",
        @"HP": @"生命值",
        @"MP": @"魔法值",
        @"Energy": @"能量",
        @"Stamina": @"体力",
        @"Attack": @"攻击",
        @"Defense": @"防御",
        @"Damage": @"伤害",
        @"Critical": @"暴击",
        @"Score": @"分数",
        @"High Score": @"最高分",
        @"Best Score": @"最佳分数",
        @"Rank": @"排名",
        @"Ranking": @"排行榜",
        @"Leaderboard": @"排行榜",
        @"Player": @"玩家",
        @"Players": @"玩家",
        @"Team": @"队伍",
        @"Friend": @"好友",
        @"Friends": @"好友",
        @"Invite": @"邀请",
        @"Join": @"加入",
        @"Leave": @"离开",
        @"Win": @"胜利",
        @"Lose": @"失败",
        @"Victory": @"胜利",
        @"Defeat": @"失败",
        @"Draw": @"平局",
        @"Game Over": @"游戏结束",
        @"You Win": @"你赢了",
        @"You Lose": @"你输了",
        @"Congratulations": @"恭喜",
        @"Try Again": @"再试一次",
        @"Unlock": @"解锁",
        @"Unlocked": @"已解锁",
        @"Locked": @"已锁定",
        @"Upgrade": @"升级",
        @"Level Up": @"升级",
        @"Max Level": @"满级",
        @"Experience": @"经验",
        @"EXP": @"经验",
        @"XP": @"经验",
        @"Coin": @"金币",
        @"Coins": @"金币",
        @"Gold": @"金币",
        @"Gem": @"宝石",
        @"Gems": @"宝石",
        @"Diamond": @"钻石",
        @"Diamonds": @"钻石",
        @"Crystal": @"水晶",
        @"Crystals": @"水晶",
        @"Token": @"代币",
        @"Tokens": @"代币",
        @"Life": @"生命",
        @"Lives": @"生命",
        @"Heart": @"爱心",
        @"Hearts": @"爱心",
        @"Star": @"星星",
        @"Stars": @"星星",
        @"Key": @"钥匙",
        @"Keys": @"钥匙",
        @"Chest": @"宝箱",
        @"Treasure": @"宝藏",
        @"Collect": @"收集",
        @"Collected": @"已收集",
        @"Complete": @"完成",
        @"Completed": @"已完成",
        @"Failed": @"失败",
        @"Success": @"成功",
        @"Perfect": @"完美",
        @"Excellent": @"优秀",
        @"Good": @"好",
        @"Great": @"很好",
        @"Amazing": @"惊人",
        @"Awesome": @"太棒了",
        @"Cool": @"酷",
        @"Nice": @"不错",
        @"Wow": @"哇",
        
        // 时间相关
        @"Today": @"今天",
        @"Yesterday": @"昨天",
        @"Tomorrow": @"明天",
        @"Daily": @"每日",
        @"Weekly": @"每周",
        @"Monthly": @"每月",
        @"Day": @"天",
        @"Days": @"天",
        @"Hour": @"小时",
        @"Hours": @"小时",
        @"Minute": @"分钟",
        @"Minutes": @"分钟",
        @"Second": @"秒",
        @"Seconds": @"秒",
        @"Time": @"时间",
        @"Timer": @"计时器",
        @"Countdown": @"倒计时",
        @"Remaining": @"剩余",
        @"Left": @"剩余",
        
        // 社交/账户
        @"Login": @"登录",
        @"Log In": @"登录",
        @"Sign In": @"登录",
        @"Logout": @"退出登录",
        @"Log Out": @"退出登录",
        @"Sign Out": @"退出登录",
        @"Register": @"注册",
        @"Sign Up": @"注册",
        @"Username": @"用户名",
        @"Password": @"密码",
        @"Email": @"邮箱",
        @"Phone": @"手机",
        @"Profile": @"个人资料",
        @"Avatar": @"头像",
        @"Name": @"名字",
        @"Nickname": @"昵称",
        @"Age": @"年龄",
        @"Gender": @"性别",
        @"Male": @"男",
        @"Female": @"女",
        @"Birthday": @"生日",
        @"Country": @"国家",
        @"City": @"城市",
        @"Address": @"地址",
        @"Message": @"消息",
        @"Messages": @"消息",
        @"Chat": @"聊天",
        @"Send": @"发送",
        @"Receive": @"接收",
        @"Accept": @"接受",
        @"Decline": @"拒绝",
        @"Block": @"屏蔽",
        @"Report": @"举报",
        @"Follow": @"关注",
        @"Unfollow": @"取消关注",
        @"Following": @"正在关注",
        @"Followers": @"粉丝",
        @"Like": @"喜欢",
        @"Likes": @"喜欢",
        @"Comment": @"评论",
        @"Comments": @"评论",
        @"Post": @"发布",
        @"Reply": @"回复",
        
        // 网络/状态
        @"Online": @"在线",
        @"Offline": @"离线",
        @"Connecting": @"连接中",
        @"Connected": @"已连接",
        @"Disconnected": @"已断开",
        @"Connection Error": @"连接错误",
        @"Network Error": @"网络错误",
        @"No Internet": @"无网络",
        @"No Connection": @"无连接",
        @"Server Error": @"服务器错误",
        @"Error": @"错误",
        @"Warning": @"警告",
        @"Notice": @"通知",
        @"Alert": @"提醒",
        @"Update": @"更新",
        @"Update Available": @"有可用更新",
        @"Download": @"下载",
        @"Downloading": @"下载中",
        @"Install": @"安装",
        @"Installing": @"安装中",
        @"Version": @"版本",
        @"New Version": @"新版本",
        
        // 广告相关
        @"Watch Ad": @"观看广告",
        @"Watch Video": @"观看视频",
        @"Free Reward": @"免费奖励",
        @"Claim": @"领取",
        @"Claim Reward": @"领取奖励",
        @"No Thanks": @"不用了",
        @"Not Now": @"以后再说",
        @"Later": @"稍后",
        @"Remind Me Later": @"稍后提醒",
        @"Don't Show Again": @"不再显示",
        @"Remove Ads": @"移除广告",
        @"Go Premium": @"升级高级版",
        @"Subscribe": @"订阅",
        @"Subscription": @"订阅",
        @"Premium": @"高级版",
        @"VIP": @"VIP",
        @"Pro": @"专业版",
        
        // 其他常用
        @"Search": @"搜索",
        @"Filter": @"筛选",
        @"Sort": @"排序",
        @"All": @"全部",
        @"None": @"无",
        @"More": @"更多",
        @"Less": @"更少",
        @"Show": @"显示",
        @"Hide": @"隐藏",
        @"View": @"查看",
        @"Details": @"详情",
        @"Info": @"信息",
        @"Information": @"信息",
        @"Description": @"描述",
        @"Title": @"标题",
        @"Content": @"内容",
        @"Category": @"分类",
        @"Type": @"类型",
        @"Status": @"状态",
        @"Progress": @"进度",
        @"Total": @"总计",
        @"Count": @"数量",
        @"Amount": @"数量",
        @"Price": @"价格",
        @"Cost": @"花费",
        @"Value": @"价值",
        @"Size": @"大小",
        @"Color": @"颜色",
        @"Red": @"红色",
        @"Blue": @"蓝色",
        @"Green": @"绿色",
        @"Yellow": @"黄色",
        @"Orange": @"橙色",
        @"Purple": @"紫色",
        @"Pink": @"粉色",
        @"Black": @"黑色",
        @"White": @"白色",
        @"Gray": @"灰色",
        @"Grey": @"灰色",
        @"Brown": @"棕色",
        
        // 方向/位置
        @"Up": @"上",
        @"Down": @"下",
        @"Right": @"右",
        @"Top": @"顶部",
        @"Bottom": @"底部",
        @"Center": @"中心",
        @"Middle": @"中间",
        @"Front": @"前",
        @"North": @"北",
        @"South": @"南",
        @"East": @"东",
        @"West": @"西",
        @"Here": @"这里",
        @"There": @"那里",
        @"Home": @"主页",
        @"Map": @"地图",
        @"Location": @"位置",
        @"World": @"世界",
        @"Zone": @"区域",
        @"Area": @"区域",
        @"Region": @"地区",
        @"Land": @"土地",
        @"Island": @"岛屿",
        @"Forest": @"森林",
        @"Mountain": @"山",
        @"River": @"河流",
        @"Ocean": @"海洋",
        @"Sea": @"海",
        @"Sky": @"天空",
        @"Space": @"太空",
        @"Castle": @"城堡",
        @"Village": @"村庄",
        @"Town": @"城镇",
        @"Kingdom": @"王国",
        @"Empire": @"帝国",
        @"Dungeon": @"地牢",
        @"Cave": @"洞穴",
        @"Temple": @"神殿",
        @"Tower": @"塔",
        @"Gate": @"门",
        @"Door": @"门",
        @"Bridge": @"桥",
        @"Road": @"道路",
        @"Path": @"路径",
    };
}


// ============== 翻译缓存 ==============
static NSMutableDictionary *translationCache = nil;

// ============== Hook UILabel ==============

static void (*orig_UILabel_setText)(UILabel *self, SEL _cmd, NSString *text);
static void hook_UILabel_setText(UILabel *self, SEL _cmd, NSString *text) {
    @try {
        if (!text || text.length == 0) {
            orig_UILabel_setText(self, _cmd, text);
            return;
        }
        
        // 只使用本地字典快速翻译
        if (!translationDict) initTranslationDict();
        NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        // 检查本地字典
        NSString *localTranslated = translationDict[trimmed];
        if (localTranslated) {
            orig_UILabel_setText(self, _cmd, localTranslated);
            return;
        }
        
        // 检查缓存
        if (translationCache && translationCache[trimmed]) {
            orig_UILabel_setText(self, _cmd, translationCache[trimmed]);
            return;
        }
        
        // 尝试忽略大小写匹配
        for (NSString *key in translationDict) {
            if ([key caseInsensitiveCompare:trimmed] == NSOrderedSame) {
                orig_UILabel_setText(self, _cmd, translationDict[key]);
                return;
            }
        }
        
        orig_UILabel_setText(self, _cmd, text);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UILabel Hook异常: %@", e);
        orig_UILabel_setText(self, _cmd, text);
    }
}

static void (*orig_UILabel_setAttributedText)(UILabel *self, SEL _cmd, NSAttributedString *text);
static void hook_UILabel_setAttributedText(UILabel *self, SEL _cmd, NSAttributedString *text) {
    @try {
        if (text && text.string.length > 0) {
            if (!translationDict) initTranslationDict();
            NSString *trimmed = [text.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *translated = translationDict[trimmed];
            if (translated && ![translated isEqualToString:text.string]) {
                NSMutableAttributedString *newText = [[NSMutableAttributedString alloc] initWithAttributedString:text];
                [newText replaceCharactersInRange:NSMakeRange(0, newText.length) withString:translated];
                orig_UILabel_setAttributedText(self, _cmd, newText);
                return;
            }
        }
        orig_UILabel_setAttributedText(self, _cmd, text);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UILabel AttributedText Hook异常: %@", e);
        orig_UILabel_setAttributedText(self, _cmd, text);
    }
}

// ============== Hook UIButton ==============

static void (*orig_UIButton_setTitle)(UIButton *self, SEL _cmd, NSString *title, UIControlState state);
static void hook_UIButton_setTitle(UIButton *self, SEL _cmd, NSString *title, UIControlState state) {
    @try {
        if (title && title.length > 0) {
            if (!translationDict) initTranslationDict();
            NSString *trimmed = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *translated = translationDict[trimmed];
            if (translated) {
                orig_UIButton_setTitle(self, _cmd, translated, state);
                return;
            }
        }
        orig_UIButton_setTitle(self, _cmd, title, state);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UIButton Hook异常: %@", e);
        orig_UIButton_setTitle(self, _cmd, title, state);
    }
}

// ============== Hook UITextField ==============

static void (*orig_UITextField_setText)(UITextField *self, SEL _cmd, NSString *text);
static void hook_UITextField_setText(UITextField *self, SEL _cmd, NSString *text) {
    @try {
        if (text && text.length > 0) {
            if (!translationDict) initTranslationDict();
            NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *translated = translationDict[trimmed];
            if (translated) {
                orig_UITextField_setText(self, _cmd, translated);
                return;
            }
        }
        orig_UITextField_setText(self, _cmd, text);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UITextField Hook异常: %@", e);
        orig_UITextField_setText(self, _cmd, text);
    }
}

static void (*orig_UITextField_setPlaceholder)(UITextField *self, SEL _cmd, NSString *placeholder);
static void hook_UITextField_setPlaceholder(UITextField *self, SEL _cmd, NSString *placeholder) {
    @try {
        if (placeholder && placeholder.length > 0) {
            if (!translationDict) initTranslationDict();
            NSString *trimmed = [placeholder stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *translated = translationDict[trimmed];
            if (translated) {
                orig_UITextField_setPlaceholder(self, _cmd, translated);
                return;
            }
        }
        orig_UITextField_setPlaceholder(self, _cmd, placeholder);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UITextField Placeholder Hook异常: %@", e);
        orig_UITextField_setPlaceholder(self, _cmd, placeholder);
    }
}

// ============== Hook UITextView ==============

static void (*orig_UITextView_setText)(UITextView *self, SEL _cmd, NSString *text);
static void hook_UITextView_setText(UITextView *self, SEL _cmd, NSString *text) {
    @try {
        if (text && text.length > 0) {
            if (!translationDict) initTranslationDict();
            NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *translated = translationDict[trimmed];
            if (translated) {
                orig_UITextView_setText(self, _cmd, translated);
                return;
            }
        }
        orig_UITextView_setText(self, _cmd, text);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UITextView Hook异常: %@", e);
        orig_UITextView_setText(self, _cmd, text);
    }
}

// ============== Hook UIAlertController ==============

static UIAlertController* (*orig_UIAlertController_alertControllerWithTitle)(Class self, SEL _cmd, NSString *title, NSString *message, UIAlertControllerStyle style);
static UIAlertController* hook_UIAlertController_alertControllerWithTitle(Class self, SEL _cmd, NSString *title, NSString *message, UIAlertControllerStyle style) {
    @try {
        if (!translationDict) initTranslationDict();
        NSString *translatedTitle = title;
        NSString *translatedMessage = message;
        
        if (title && title.length > 0) {
            NSString *trimmed = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (translationDict[trimmed]) {
                translatedTitle = translationDict[trimmed];
            }
        }
        if (message && message.length > 0) {
            NSString *trimmed = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (translationDict[trimmed]) {
                translatedMessage = translationDict[trimmed];
            }
        }
        return orig_UIAlertController_alertControllerWithTitle(self, _cmd, translatedTitle, translatedMessage, style);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UIAlertController Hook异常: %@", e);
        return orig_UIAlertController_alertControllerWithTitle(self, _cmd, title, message, style);
    }
}

// ============== Hook UIAlertAction ==============

static UIAlertAction* (*orig_UIAlertAction_actionWithTitle)(Class self, SEL _cmd, NSString *title, UIAlertActionStyle style, void (^handler)(UIAlertAction *));
static UIAlertAction* hook_UIAlertAction_actionWithTitle(Class self, SEL _cmd, NSString *title, UIAlertActionStyle style, void (^handler)(UIAlertAction *)) {
    @try {
        if (title && title.length > 0) {
            if (!translationDict) initTranslationDict();
            NSString *trimmed = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *translated = translationDict[trimmed];
            if (translated) {
                return orig_UIAlertAction_actionWithTitle(self, _cmd, translated, style, handler);
            }
        }
        return orig_UIAlertAction_actionWithTitle(self, _cmd, title, style, handler);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UIAlertAction Hook异常: %@", e);
        return orig_UIAlertAction_actionWithTitle(self, _cmd, title, style, handler);
    }
}

// ============== Hook UINavigationItem ==============

static void (*orig_UINavigationItem_setTitle)(UINavigationItem *self, SEL _cmd, NSString *title);
static void hook_UINavigationItem_setTitle(UINavigationItem *self, SEL _cmd, NSString *title) {
    @try {
        if (title && title.length > 0) {
            if (!translationDict) initTranslationDict();
            NSString *trimmed = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *translated = translationDict[trimmed];
            if (translated) {
                orig_UINavigationItem_setTitle(self, _cmd, translated);
                return;
            }
        }
        orig_UINavigationItem_setTitle(self, _cmd, title);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UINavigationItem Hook异常: %@", e);
        orig_UINavigationItem_setTitle(self, _cmd, title);
    }
}

// ============== Hook UITabBarItem ==============

static void (*orig_UITabBarItem_setTitle)(UITabBarItem *self, SEL _cmd, NSString *title);
static void hook_UITabBarItem_setTitle(UITabBarItem *self, SEL _cmd, NSString *title) {
    @try {
        if (title && title.length > 0) {
            if (!translationDict) initTranslationDict();
            NSString *trimmed = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *translated = translationDict[trimmed];
            if (translated) {
                orig_UITabBarItem_setTitle(self, _cmd, translated);
                return;
            }
        }
        orig_UITabBarItem_setTitle(self, _cmd, title);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UITabBarItem Hook异常: %@", e);
        orig_UITabBarItem_setTitle(self, _cmd, title);
    }
}

// ============== Hook UIBarButtonItem ==============

static void (*orig_UIBarButtonItem_setTitle)(UIBarButtonItem *self, SEL _cmd, NSString *title);
static void hook_UIBarButtonItem_setTitle(UIBarButtonItem *self, SEL _cmd, NSString *title) {
    @try {
        if (title && title.length > 0) {
            if (!translationDict) initTranslationDict();
            NSString *trimmed = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *translated = translationDict[trimmed];
            if (translated) {
                orig_UIBarButtonItem_setTitle(self, _cmd, translated);
                return;
            }
        }
        orig_UIBarButtonItem_setTitle(self, _cmd, title);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UIBarButtonItem Hook异常: %@", e);
        orig_UIBarButtonItem_setTitle(self, _cmd, title);
    }
}

// ============== Hook UISegmentedControl ==============

static void (*orig_UISegmentedControl_setTitle)(UISegmentedControl *self, SEL _cmd, NSString *title, NSUInteger segment);
static void hook_UISegmentedControl_setTitle(UISegmentedControl *self, SEL _cmd, NSString *title, NSUInteger segment) {
    @try {
        if (title && title.length > 0) {
            if (!translationDict) initTranslationDict();
            NSString *trimmed = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *translated = translationDict[trimmed];
            if (translated) {
                orig_UISegmentedControl_setTitle(self, _cmd, translated, segment);
                return;
            }
        }
        orig_UISegmentedControl_setTitle(self, _cmd, title, segment);
    } @catch (NSException *e) {
        NSLog(@"[AutoTranslate] UISegmentedControl Hook异常: %@", e);
        orig_UISegmentedControl_setTitle(self, _cmd, title, segment);
    }
}

// ============== 初始化 ==============

static void __attribute__((constructor)) initialize() {
    @autoreleasepool {
        // 初始化翻译字典和缓存
        initTranslationDict();
        translationCache = [NSMutableDictionary dictionary];
        
        NSLog(@"[AutoTranslate] 自动翻译插件已加载");
        NSLog(@"[AutoTranslate] 本地词库: %lu 个词条", (unsigned long)translationDict.count);
        
        // Hook UILabel
        MSHookMessageEx(
            objc_getClass("UILabel"),
            @selector(setText:),
            (IMP)hook_UILabel_setText,
            (IMP*)&orig_UILabel_setText
        );
        
        MSHookMessageEx(
            objc_getClass("UILabel"),
            @selector(setAttributedText:),
            (IMP)hook_UILabel_setAttributedText,
            (IMP*)&orig_UILabel_setAttributedText
        );
        
        // Hook UIButton
        MSHookMessageEx(
            objc_getClass("UIButton"),
            @selector(setTitle:forState:),
            (IMP)hook_UIButton_setTitle,
            (IMP*)&orig_UIButton_setTitle
        );
        
        // Hook UITextField
        MSHookMessageEx(
            objc_getClass("UITextField"),
            @selector(setText:),
            (IMP)hook_UITextField_setText,
            (IMP*)&orig_UITextField_setText
        );
        
        MSHookMessageEx(
            objc_getClass("UITextField"),
            @selector(setPlaceholder:),
            (IMP)hook_UITextField_setPlaceholder,
            (IMP*)&orig_UITextField_setPlaceholder
        );
        
        // Hook UITextView
        MSHookMessageEx(
            objc_getClass("UITextView"),
            @selector(setText:),
            (IMP)hook_UITextView_setText,
            (IMP*)&orig_UITextView_setText
        );
        
        // Hook UIAlertController
        MSHookMessageEx(
            object_getClass(objc_getClass("UIAlertController")),
            @selector(alertControllerWithTitle:message:preferredStyle:),
            (IMP)hook_UIAlertController_alertControllerWithTitle,
            (IMP*)&orig_UIAlertController_alertControllerWithTitle
        );
        
        // Hook UIAlertAction
        MSHookMessageEx(
            object_getClass(objc_getClass("UIAlertAction")),
            @selector(actionWithTitle:style:handler:),
            (IMP)hook_UIAlertAction_actionWithTitle,
            (IMP*)&orig_UIAlertAction_actionWithTitle
        );
        
        // Hook UINavigationItem
        MSHookMessageEx(
            objc_getClass("UINavigationItem"),
            @selector(setTitle:),
            (IMP)hook_UINavigationItem_setTitle,
            (IMP*)&orig_UINavigationItem_setTitle
        );
        
        // Hook UITabBarItem
        MSHookMessageEx(
            objc_getClass("UITabBarItem"),
            @selector(setTitle:),
            (IMP)hook_UITabBarItem_setTitle,
            (IMP*)&orig_UITabBarItem_setTitle
        );
        
        // Hook UIBarButtonItem
        MSHookMessageEx(
            objc_getClass("UIBarButtonItem"),
            @selector(setTitle:),
            (IMP)hook_UIBarButtonItem_setTitle,
            (IMP*)&orig_UIBarButtonItem_setTitle
        );
        
        // Hook UISegmentedControl
        MSHookMessageEx(
            objc_getClass("UISegmentedControl"),
            @selector(setTitle:forSegmentAtIndex:),
            (IMP)hook_UISegmentedControl_setTitle,
            (IMP*)&orig_UISegmentedControl_setTitle
        );
        
        NSLog(@"[AutoTranslate] 所有Hook已完成");
    }
}
