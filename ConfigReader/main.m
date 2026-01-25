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
    
    [self log:@"[*] 监听已启动"];
    [self log:@"[*] 等待网络请求...\n"];
    
    return YES;
}

- (void)hookNetworkRequests {
    AppDelegate *weakSelf = self;
    
    // Hook NSURLConnection
    Class NSURLConnection = NSClassFromString(@"NSURLConnection");
    if (NSURLConnection) {
        Method method = class_getClassMethod(NSURLConnection, @selector(sendSynchronousRequest:returningResponse:error:));
        if (method) {
            IMP originalImp = method_getImplementation(method);
            IMP newImp = imp_implementationWithBlock(^NSData*(id request, NSURLResponse **response, NSError **error) {
                NSString *url = [[request URL] absoluteString];
                [weakSelf log:[NSString stringWithFormat:@"\n[网络请求]"]];
                [weakSelf log:[NSString stringWithFormat:@"URL: %@", url]];
                [weakSelf log:[NSString stringWithFormat:@"==================\n"]];
                
                // 调用原始方法
                typedef NSData* (*OriginalFunc)(id, SEL, id, NSURLResponse**, NSError**);
                NSData *data = ((OriginalFunc)originalImp)(NSURLConnection, @selector(sendSynchronousRequest:returningResponse:error:), request, response, error);
                
                if (data && data.length < 5000) {
                    NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    if (responseStr) {
                        [weakSelf log:[NSString stringWithFormat:@"响应: %@\n", responseStr]];
                    }
                }
                
                return data;
            });
            method_setImplementation(method, newImp);
            [self log:@"[+] Hook NSURLConnection 成功"];
        }
    }
    
    // Hook NSString stringWithContentsOfURL
    Class NSString = NSClassFromString(@"NSString");
    if (NSString) {
        Method method = class_getClassMethod(NSString, @selector(stringWithContentsOfURL:encoding:error:));
        if (method) {
            IMP originalImp = method_getImplementation(method);
            IMP newImp = imp_implementationWithBlock(^NSString*(NSURL *url, NSStringEncoding enc, NSError **error) {
                [weakSelf log:[NSString stringWithFormat:@"\n[加载远程字符串]"]];
                [weakSelf log:[NSString stringWithFormat:@"URL: %@", url.absoluteString]];
                
                // 调用原始方法
                typedef NSString* (*OriginalFunc)(id, SEL, NSURL*, NSStringEncoding, NSError**);
                NSString *content = ((OriginalFunc)originalImp)(NSString, @selector(stringWithContentsOfURL:encoding:error:), url, enc, error);
                
                if (content && content.length < 5000) {
                    [weakSelf log:[NSString stringWithFormat:@"内容: %@", content]];
                }
                [weakSelf log:@"==================\n"];
                
                return content;
            });
            method_setImplementation(method, newImp);
            [self log:@"[+] Hook NSString 成功"];
        }
    }
    
    [self log:@""];
}

@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
