# AutoTranslate - 自动翻译插件

自动将iOS应用中的英文界面翻译成中文，支持**全量在线翻译**！

## 功能特点

- 🔤 自动翻译所有UI控件的英文文本
- 📚 内置400+常用词汇本地字典（秒翻译）
- 🌐 **在线翻译API支持** - 可翻译任意英文！
- 🚀 异步翻译，不阻塞UI
- 💾 翻译缓存，避免重复请求
- 🎮 覆盖游戏、应用、社交等多种场景

## 翻译流程

```
英文文本 → 本地字典匹配 → 缓存查找 → 在线翻译API → 显示中文
```

1. 优先使用本地字典（最快）
2. 查找翻译缓存
3. 调用在线API翻译（Google/百度）
4. 结果存入缓存

## 支持的UI控件

- UILabel (setText:, setAttributedText:)
- UIButton (setTitle:forState:)
- UITextField (setText:, setPlaceholder:)
- UITextView (setText:)
- UIAlertController (标题和消息)
- UIAlertAction (按钮标题)
- UINavigationItem (导航栏标题)
- UITabBarItem (标签栏标题)
- UIBarButtonItem (导航按钮)
- UISegmentedControl (分段控件)

## 编译方法

### 方法1: 使用Theos编译

1. 安装Theos环境
2. 进入插件目录
3. 执行编译命令:

```bash
cd 自动翻译插件
make package
```

### 方法2: 使用MonkeyDev编译

1. 在Xcode中创建MonkeyDev项目
2. 将AutoTranslate.m添加到项目中
3. 编译生成dylib

### 方法3: 使用命令行编译

```bash
clang -arch arm64 -arch arm64e \
    -isysroot /path/to/iPhoneOS.sdk \
    -framework UIKit -framework Foundation \
    -lsubstrate \
    -dynamiclib \
    -o AutoTranslate.dylib \
    AutoTranslate.m
```

## 使用方法

### 注入到IPA

1. 解压IPA文件
2. 将AutoTranslate.dylib复制到Payload/App.app/目录
3. 使用insert_dylib或optool注入:

```bash
# 使用insert_dylib
insert_dylib @executable_path/AutoTranslate.dylib Payload/App.app/AppBinary --all-yes

# 或使用optool
optool install -c load -p @executable_path/AutoTranslate.dylib -t Payload/App.app/AppBinary
```

4. 重新签名并打包IPA

### 越狱设备

1. 将.deb包安装到设备
2. 重启SpringBoard

## 自定义词库

修改`AutoTranslate.m`中的`initTranslationDict`函数，添加自定义翻译:

```objc
translationDict = @{
    // 添加自定义翻译
    @"Custom Word": @"自定义词汇",
    @"Another Word": @"另一个词汇",
    // ...
};
```

## 云端词库 (可选)

可以修改代码从服务器加载词库:

```objc
// 从URL加载JSON词库
NSURL *url = [NSURL URLWithString:@"https://your-server.com/translations.json"];
NSData *data = [NSData dataWithContentsOfURL:url];
if (data) {
    translationDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}
```

## 词库分类

当前内置词库包含以下分类:

| 分类 | 词条数 | 示例 |
|------|--------|------|
| 通用UI | 50+ | OK→确定, Cancel→取消 |
| 设置相关 | 40+ | Settings→设置, Sound→声音 |
| 游戏通用 | 150+ | Play→开始游戏, Level→关卡 |
| 时间相关 | 20+ | Today→今天, Hour→小时 |
| 社交账户 | 50+ | Login→登录, Profile→个人资料 |
| 网络状态 | 30+ | Online→在线, Error→错误 |
| 广告相关 | 20+ | Watch Ad→观看广告, Premium→高级版 |
| 颜色方向 | 40+ | Red→红色, North→北 |

## 在线翻译配置

### 方式1: Google翻译 (默认，免费)

无需配置，开箱即用。但有以下限制：
- 请求频率限制
- 可能被封IP

### 方式2: 百度翻译API (推荐，更稳定)

1. 访问 https://fanyi-api.baidu.com/ 注册账号
2. 创建应用获取 AppID 和 密钥
3. 修改代码中的配置：

```objc
static NSString *const BAIDU_APP_ID = @"你的AppID";
static NSString *const BAIDU_SECRET = @"你的密钥";
```

百度翻译API每月有免费额度，足够个人使用。

### 关闭在线翻译

如果只想使用本地字典，修改：

```objc
static BOOL enableOnlineTranslation = NO;
```

## 注意事项

1. 某些应用可能使用自定义渲染，无法被Hook
2. 图片中的文字无法翻译
3. 部分应用可能有反Hook检测
4. 建议配合其他插件使用以获得最佳效果

## 更新日志

### v1.0.0
- 初始版本
- 支持主要UI控件翻译
- 内置400+词汇翻译字典

## License

MIT License
