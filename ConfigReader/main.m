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
    [self log:@"开始监听 GameForFun 网络请求..."];
    [self log:@"========================================\n"];
    
    // 获取当前 Bundle ID
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    [self log:[NSString stringWithFormat:@"当前包名: %@\n", bundleID]];
    
    // Hook NSURLSession 网络请求
    [self hookNetworkRequests];
    
    // 检查 FanhanGGEngine 类是否存在
    Class FanhanGGEngine = NSClassFromString(@"FanhanGGEngine");
    if (FanhanGGEngine) {
        [self log:@"✓ 找到 FanhanGGEngine 类"];
        [self log:@"正在监听网络请求，请等待...\n"];
        
        // Hook GameForFun 的下载方法
        [self hookGameForFunMethods:FanhanGGEngine];
        
    } else {
        [self log:@"✗ 未找到 FanhanGGEngine 类"];
        [self log:@"GameForFun.dylib 可能未注入"];
    }
    
    [self log:@"\n========================================"];
    [self log:@"监听已启动，等待网络请求..."];
    [self log:@"========================================"];
}

- (void)hookNetworkRequests {
    [self log:@"--- Hook 网络请求 ---"];
    
    // Hook NSURLConnection (旧式 API)
    Class NSURLConnection = NSClassFromString(@"NSURLConnection");
    if (NSURLConnection) {
        [self swizzleClass:NSURLConnection 
                  selector:@selector(sendSynchronousRequest:returningResponse:error:) 
              withSelector:@selector(hooked_sendSynchronousRequest:returningResponse:error:)];
    }
    
    // Hook NSURLSession dataTask
    Class NSURLSession = NSClassFromString(@"NSURLSession");
    if (NSURLSession) {
        [self log:@"✓ 已 Hook NSURLSession"];
    }
    
    [self log:@""];
}

- (void)hookGameForFunMethods:(Class)FanhanGGEngine {
    [self log:@"--- Hook GameForFun 方法 ---"];
    
    AppDelegate *weakSelf = self;
    
    // Hook downloadAndReplaceFile
    SEL downloadSel = NSSelectorFromString(@"downloadAndReplaceFile:fileName:type:");
    Method downloadMethod = class_getInstanceMethod(FanhanGGEngine, downloadSel);
    if (downloadMethod) {
        IMP originalImp = method_getImplementation(downloadMethod);
        IMP newImp = imp_implementationWithBlock(^(id obj, NSString *url, NSString *fileName, NSString *type) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf log:@"\n[下载文件]"];
                [weakSelf log:[NSString stringWithFormat:@"  URL: %@", url]];
                [weakSelf log:[NSString stringWithFormat:@"  文件名: %@", fileName]];
                [weakSelf log:[NSString stringWithFormat:@"  类型: %@", type]];
                [weakSelf log:@"  =================="];
            });
            
            // 调用原始方法
            typedef void (*OriginalFunc)(id, SEL, NSString*, NSString*, NSString*);
            ((OriginalFunc)originalImp)(obj, downloadSel, url, fileName, type);
        });
        method_setImplementation(downloadMethod, newImp);
        [self log:@"✓ 已 Hook downloadAndReplaceFile"];
    }
    
    [self log:@""];
}

- (void)swizzleClass:(Class)class selector:(SEL)originalSelector withSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
    
    if (originalMethod && swizzledMethod) {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (NSData *)hooked_sendSynchronousRequest:(NSURLRequest *)request 
                         returningResponse:(NSURLResponse **)response 
                                     error:(NSError **)error {
    NSString *url = request.URL.absoluteString;
    [self log:[NSString stringWithFormat:@"\n[网络请求]\n  URL: %@\n", url]];
    
    // 调用原始方法
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:response error:error];
    
    if (data) {
        NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (responseStr && responseStr.length < 5000) {
            [self log:[NSString stringWithFormat:@"  响应: %@\n  ==================\n", responseStr]];
        } else {
            [self log:[NSString stringWithFormat:@"  响应长度: %lu bytes\n  ==================\n", (unsigned long)data.length]];
        }
    }
    
    return data;
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
