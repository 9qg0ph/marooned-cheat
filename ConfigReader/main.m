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
    self.logView.font = [UIFont fontWithName:@"Courier" size:11];
    self.logView.editable = NO;
    [vc.view addSubview:self.logView];
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.window.bounds.size.width, 30)];
    titleLabel.text = @"网络请求监听器";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [vc.view addSubview:titleLabel];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    // 立即开始监听
    [self log:@"========================================"];
    [self log:@"网络请求监听器"];
    [self log:@"========================================\n"];
    
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    [self log:[NSString stringWithFormat:@"当前包名: %@\n", bundleID]];
    
    // Hook 网络请求
    [self hookNetworkRequests];
    
    // Hook GameForFun 方法
    [self hookGameForFunMethods];
    
    [self log:@"[*] 监听已启动"];
    [self log:@"[*] 等待网络请求...\n"];
    
    return YES;
}

- (void)hookNetworkRequests {
    AppDelegate *weakSelf = self;
    
    [self log:@"--- Hook 网络请求 ---"];
    
    // Hook NSURLSession dataTaskWithURL
    Class NSURLSession = NSClassFromString(@"NSURLSession");
    if (NSURLSession) {
        // Hook dataTaskWithURL:
        Method method1 = class_getInstanceMethod(NSURLSession, @selector(dataTaskWithURL:));
        if (method1) {
            IMP originalImp = method_getImplementation(method1);
            IMP newImp = imp_implementationWithBlock(^id(id session, NSURL *url) {
                [weakSelf log:[NSString stringWithFormat:@"\n[NSURLSession dataTask]"]];
                [weakSelf log:[NSString stringWithFormat:@"URL: %@", url.absoluteString]];
                [weakSelf log:@"==================\n"];
                
                typedef id (*OriginalFunc)(id, SEL, NSURL*);
                return ((OriginalFunc)originalImp)(session, @selector(dataTaskWithURL:), url);
            });
            method_setImplementation(method1, newImp);
            [self log:@"✓ 已 Hook NSURLSession dataTaskWithURL"];
        }
        
        // Hook dataTaskWithRequest:
        Method method2 = class_getInstanceMethod(NSURLSession, @selector(dataTaskWithRequest:));
        if (method2) {
            IMP originalImp = method_getImplementation(method2);
            IMP newImp = imp_implementationWithBlock(^id(id session, id request) {
                NSString *url = [[request URL] absoluteString];
                [weakSelf log:[NSString stringWithFormat:@"\n[NSURLSession dataTaskWithRequest]"]];
                [weakSelf log:[NSString stringWithFormat:@"URL: %@", url]];
                [weakSelf log:@"==================\n"];
                
                typedef id (*OriginalFunc)(id, SEL, id);
                return ((OriginalFunc)originalImp)(session, @selector(dataTaskWithRequest:), request);
            });
            method_setImplementation(method2, newImp);
            [self log:@"✓ 已 Hook NSURLSession dataTaskWithRequest"];
        }
    }
    
    // Hook NSURLConnection
    Class NSURLConnection = NSClassFromString(@"NSURLConnection");
    if (NSURLConnection) {
        Method method = class_getClassMethod(NSURLConnection, @selector(sendSynchronousRequest:returningResponse:error:));
        if (method) {
            IMP originalImp = method_getImplementation(method);
            IMP newImp = imp_implementationWithBlock(^NSData*(id request, NSURLResponse **response, NSError **error) {
                NSString *url = [[request URL] absoluteString];
                [weakSelf log:[NSString stringWithFormat:@"\n[NSURLConnection 同步]"]];
                [weakSelf log:[NSString stringWithFormat:@"URL: %@", url]];
                
                typedef NSData* (*OriginalFunc)(id, SEL, id, NSURLResponse**, NSError**);
                NSData *data = ((OriginalFunc)originalImp)(NSURLConnection, @selector(sendSynchronousRequest:returningResponse:error:), request, response, error);
                
                if (data && data.length < 5000) {
                    NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    if (responseStr) {
                        [weakSelf log:[NSString stringWithFormat:@"响应: %@", responseStr]];
                    }
                }
                [weakSelf log:@"==================\n"];
                
                return data;
            });
            method_setImplementation(method, newImp);
            [self log:@"✓ 已 Hook NSURLConnection"];
        }
    }
    
    // Hook NSData dataWithContentsOfURL
    Class NSDataClass = NSClassFromString(@"NSData");
    if (NSDataClass) {
        Method method = class_getClassMethod(NSDataClass, @selector(dataWithContentsOfURL:));
        if (method) {
            IMP originalImp = method_getImplementation(method);
            IMP newImp = imp_implementationWithBlock(^id(NSURL *url) {
                [weakSelf log:[NSString stringWithFormat:@"\n[NSData 加载]"]];
                [weakSelf log:[NSString stringWithFormat:@"URL: %@", url.absoluteString]];
                
                typedef id (*OriginalFunc)(id, SEL, NSURL*);
                id result = ((OriginalFunc)originalImp)(NSDataClass, @selector(dataWithContentsOfURL:), url);
                
                if (result && [result length] < 5000) {
                    NSString *str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                    if (str) {
                        [weakSelf log:[NSString stringWithFormat:@"内容: %@", str]];
                    }
                }
                [weakSelf log:@"==================\n"];
                
                return result;
            });
            method_setImplementation(method, newImp);
            [self log:@"✓ 已 Hook NSData dataWithContentsOfURL"];
        }
    }
    
    // Hook NSString stringWithContentsOfURL
    Class NSStringClass = NSClassFromString(@"NSString");
    if (NSStringClass) {
        Method method = class_getClassMethod(NSStringClass, @selector(stringWithContentsOfURL:encoding:error:));
        if (method) {
            IMP originalImp = method_getImplementation(method);
            IMP newImp = imp_implementationWithBlock(^id(NSURL *url, NSStringEncoding enc, NSError **error) {
                [weakSelf log:[NSString stringWithFormat:@"\n[NSString 加载]"]];
                [weakSelf log:[NSString stringWithFormat:@"URL: %@", url.absoluteString]];
                
                typedef id (*OriginalFunc)(id, SEL, NSURL*, NSStringEncoding, NSError**);
                id result = ((OriginalFunc)originalImp)(NSStringClass, @selector(stringWithContentsOfURL:encoding:error:), url, enc, error);
                
                if (result && [result length] < 5000) {
                    [weakSelf log:[NSString stringWithFormat:@"内容: %@", result]];
                }
                [weakSelf log:@"==================\n"];
                
                return result;
            });
            method_setImplementation(method, newImp);
            [self log:@"✓ 已 Hook NSString stringWithContentsOfURL"];
        }
    }
    
    [self log:@""];
}

- (void)hookGameForFunMethods {
    AppDelegate *weakSelf = self;
    
    [self log:@"--- Hook GameForFun 方法 ---"];
    
    Class FanhanGGEngine = NSClassFromString(@"FanhanGGEngine");
    if (FanhanGGEngine) {
        [self log:@"✓ 找到 FanhanGGEngine 类"];
        
        // Hook setValue:forKey:withType: - 最重要的方法！
        SEL setValueSel = NSSelectorFromString(@"setValue:forKey:withType:");
        Method setValueMethod = class_getInstanceMethod(FanhanGGEngine, setValueSel);
        if (setValueMethod) {
            IMP originalImp = method_getImplementation(setValueMethod);
            IMP newImp = imp_implementationWithBlock(^void(id obj, id value, id key, id type) {
                @try {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf log:@"\n========== 捕获参数 =========="];
                        [weakSelf log:[NSString stringWithFormat:@"key: %@", key ?: @"(null)"]];
                        [weakSelf log:[NSString stringWithFormat:@"value: %@", value ?: @"(null)"]];
                        [weakSelf log:[NSString stringWithFormat:@"type: %@", type ?: @"(null)"]];
                        [weakSelf log:@"==============================\n"];
                    });
                } @catch (NSException *e) {
                    NSLog(@"Hook setValue 异常: %@", e);
                }
                
                // 调用原始方法
                typedef void (*OriginalFunc)(id, SEL, id, id, id);
                ((OriginalFunc)originalImp)(obj, setValueSel, value, key, type);
            });
            method_setImplementation(setValueMethod, newImp);
            [self log:@"✓ 已 Hook setValue:forKey:withType:"];
        }
        
        // Hook downloadAndReplaceFile
        SEL downloadSel = NSSelectorFromString(@"downloadAndReplaceFile:fileName:type:");
        Method downloadMethod = class_getInstanceMethod(FanhanGGEngine, downloadSel);
        if (downloadMethod) {
            IMP originalImp = method_getImplementation(downloadMethod);
            IMP newImp = imp_implementationWithBlock(^(id obj, NSString *url, NSString *fileName, NSString *type) {
                [weakSelf log:@"\n========== 发现下载请求 =========="];
                [weakSelf log:[NSString stringWithFormat:@"URL: %@", url]];
                [weakSelf log:[NSString stringWithFormat:@"文件名: %@", fileName]];
                [weakSelf log:[NSString stringWithFormat:@"类型: %@", type]];
                [weakSelf log:@"==================================\n"];
                
                // 调用原始方法
                typedef void (*OriginalFunc)(id, SEL, NSString*, NSString*, NSString*);
                ((OriginalFunc)originalImp)(obj, downloadSel, url, fileName, type);
            });
            method_setImplementation(downloadMethod, newImp);
            [self log:@"✓ 已 Hook downloadAndReplaceFile"];
        }
        
        [self log:@"\n[*] 所有 Hook 已设置"];
        [self log:@"[*] 请开启游戏功能，参数会显示在这里\n"];
    } else {
        [self log:@"✗ 未找到 FanhanGGEngine 类"];
        [self log:@"GameForFun.dylib 可能未注入\n"];
    }
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
