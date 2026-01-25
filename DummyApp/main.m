#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    UIViewController *vc = [[UIViewController alloc] init];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    label.text = @"Dummy App for Hook Testing";
    label.textAlignment = NSTextAlignmentCenter;
    label.center = self.window.center;
    [vc.view addSubview:label];
    
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}
@end

int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
