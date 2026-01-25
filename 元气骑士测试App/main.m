#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor colorWithRed:0.2 green:0.3 blue:0.5 alpha:1.0];
    
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor colorWithRed:0.2 green:0.3 blue:0.5 alpha:1.0];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
    label.text = @"元气骑士测试\n\nHook Test App\n\nBundle ID:\ncom.ChillyRoom.DungeonShooter";
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:18];
    label.center = vc.view.center;
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
