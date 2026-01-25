#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITextView *logView;
@end

@implementation AppDelegate

- (void)log:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logView.text = [self.logView.text stringByAppendingFormat:@"%@\n", message];
        NSRange range = NSMakeRange(self.logView.text.length - 1, 1);
        [self.logView scrollRangeToVisible:range];
    });
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor blackColor];
    
    // 创建日志显示区域
    self.logView = [[UITextView alloc] initWithFrame:CGRectMake(10, 50, 
        self.window.bounds.size.width - 20, 
        self.window.bounds.size.height - 100)];
    self.logView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.logView.textColor = [UIColor greenColor];
    self.logView.font = [UIFont fontWithName:@"Courier" size:12];
    self.logView.editable = NO;
    [vc.view addSubview:self.logView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.window.bounds.size.width, 30)];
    titleLabel.text = @"GameForFun Config Reader";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [vc.view addSubview:titleLabel];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    // 延迟执行配置读取
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self readGameForFunConfig];
    });
    
    return YES;
}

- (void)readGameForFunConfig {
    [self log:@"========================================"];
    [self log:@"开始读取 GameForFun 配置..."];
    [self log:@"========================================\n"];
    
    // 获取当前 Bundle ID
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    [self log:[NSString stringWithFormat:@"当前包名: %@\n", bundleID]];
    
    // 检查 FanhanGGEngine 类是否存在
    Class FanhanGGEngine = NSClassFromString(@"FanhanGGEngine");
    if (FanhanGGEngine) {
        [self log:@"✓ 找到 FanhanGGEngine 类"];
        
        // 列出所有方法
        [self log:@"\n--- FanhanGGEngine 方法列表 ---"];
        unsigned int methodCount;
        Method *methods = class_copyMethodList(FanhanGGEngine, &methodCount);
        for (unsigned int i = 0; i < methodCount; i++) {
            SEL selector = method_getName(methods[i]);
            NSString *methodName = NSStringFromSelector(selector);
            if ([methodName containsString:@"get"] || 
                [methodName containsString:@"load"] || 
                [methodName containsString:@"config"] ||
                [methodName containsString:@"script"]) {
                [self log:[NSString stringWithFormat:@"  %@", methodName]];
            }
        }
        free(methods);
        
        // 尝试调用 getLocalScripts
        if ([FanhanGGEngine instancesRespondToSelector:@selector(getLocalScripts)]) {
            [self log:@"\n--- 尝试获取本地脚本 ---"];
            id engine = [[FanhanGGEngine alloc] init];
            @try {
                id scripts = [engine performSelector:@selector(getLocalScripts)];
                [self log:[NSString stringWithFormat:@"脚本内容: %@", scripts]];
            } @catch (NSException *e) {
                [self log:[NSString stringWithFormat:@"错误: %@", e.reason]];
            }
        }
        
        // 搜索配置文件
        [self log:@"\n--- 搜索配置文件 ---"];
        [self searchConfigFiles];
        
    } else {
        [self log:@"✗ 未找到 FanhanGGEngine 类"];
        [self log:@"GameForFun.dylib 可能未注入"];
    }
    
    [self log:@"\n========================================"];
    [self log:@"配置读取完成"];
    [self log:@"========================================"];
}

- (void)searchConfigFiles {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 搜索可能的配置文件位置
    NSArray *searchPaths = @[
        NSHomeDirectory(),
        [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"],
        [NSHomeDirectory() stringByAppendingPathComponent:@"Library"],
        [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"],
        @"/var/mobile/Library",
        @"/var/mobile/Documents"
    ];
    
    for (NSString *basePath in searchPaths) {
        if (![fm fileExistsAtPath:basePath]) continue;
        
        NSError *error;
        NSArray *contents = [fm contentsOfDirectoryAtPath:basePath error:&error];
        if (error) continue;
        
        for (NSString *file in contents) {
            NSString *fullPath = [basePath stringByAppendingPathComponent:file];
            
            // 查找可能的配置文件
            if ([file containsString:@"fanhan"] || 
                [file containsString:@"game"] || 
                [file containsString:@"config"] ||
                [file containsString:@"script"] ||
                [file hasSuffix:@".plist"] ||
                [file hasSuffix:@".json"] ||
                [file hasSuffix:@".lua"]) {
                
                [self log:[NSString stringWithFormat:@"发现文件: %@", fullPath]];
                
                // 尝试读取文件内容
                NSData *data = [NSData dataWithContentsOfFile:fullPath];
                if (data && data.length < 10000) {
                    NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    if (content) {
                        [self log:[NSString stringWithFormat:@"  内容: %@", content]];
                    }
                }
            }
        }
    }
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
