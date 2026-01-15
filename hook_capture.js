// Frida 抓包脚本 - 捕获 GameForFun.dylib 所有网络请求和验证流程

console.log("========================================");
console.log("[*] GameForFun.dylib 抓包脚本已加载");
console.log("========================================\n");

if (ObjC.available) {
    
    // 1. Hook NSURLSession 所有请求
    var NSURLSession = ObjC.classes.NSURLSession;
    if (NSURLSession) {
        Interceptor.attach(NSURLSession['- dataTaskWithRequest:completionHandler:'].implementation, {
            onEnter: function(args) {
                var request = ObjC.Object(args[2]);
                var url = request.URL();
                if (url) {
                    var urlStr = url.absoluteString().toString();
                    console.log("\n[HTTP 请求] " + urlStr);
                    console.log("  Method: " + request.HTTPMethod());
                    var body = request.HTTPBody();
                    if (body) {
                        var bodyStr = ObjC.classes.NSString.alloc().initWithData_encoding_(body, 4);
                        console.log("  Body: " + bodyStr);
                    }
                    var headers = request.allHTTPHeaderFields();
                    if (headers) {
                        console.log("  Headers: " + headers);
                    }
                }
            }
        });
        console.log("[+] Hooked NSURLSession");
    }

    // 2. Hook FanhanKeychain - 监控 UDID 读写
    var FanhanKeychain = ObjC.classes.FanhanKeychain;
    if (FanhanKeychain) {
        // 读取密码
        var getPassword = FanhanKeychain['+ passwordForService:account:'];
        if (getPassword) {
            Interceptor.attach(getPassword.implementation, {
                onEnter: function(args) {
                    this.service = ObjC.Object(args[2]);
                    this.account = ObjC.Object(args[3]);
                },
                onLeave: function(retval) {
                    var result = ObjC.Object(retval);
                    console.log("\n[Keychain 读取]");
                    console.log("  Service: " + this.service);
                    console.log("  Account: " + this.account);
                    console.log("  Result: " + result);
                }
            });
        }
        
        // 写入密码
        var setPassword = FanhanKeychain['+ setPassword:forService:account:'];
        if (setPassword) {
            Interceptor.attach(setPassword.implementation, {
                onEnter: function(args) {
                    var password = ObjC.Object(args[2]);
                    var service = ObjC.Object(args[3]);
                    var account = ObjC.Object(args[4]);
                    console.log("\n[Keychain 写入]");
                    console.log("  Service: " + service);
                    console.log("  Account: " + account);
                    console.log("  Password: " + password);
                }
            });
        }
        console.log("[+] Hooked FanhanKeychain");
    }

    // 3. Hook FanhanAlertView - 监控弹窗
    var FanhanAlertView = ObjC.classes.FanhanAlertView;
    if (FanhanAlertView) {
        var showMethods = [
            '- showNotice:title:subTitle:closeButtonTitle:duration:',
            '- showInfo:title:subTitle:closeButtonTitle:duration:',
            '- showError:title:subTitle:closeButtonTitle:duration:',
            '- showWarning:title:subTitle:closeButtonTitle:duration:'
        ];
        
        showMethods.forEach(function(methodName) {
            var method = FanhanAlertView[methodName];
            if (method) {
                Interceptor.attach(method.implementation, {
                    onEnter: function(args) {
                        console.log("\n[弹窗] " + methodName);
                        if (args[3]) console.log("  title: " + ObjC.Object(args[3]));
                        if (args[4]) console.log("  subTitle: " + ObjC.Object(args[4]));
                    }
                });
            }
        });
        console.log("[+] Hooked FanhanAlertView");
    }

    // 4. Hook UIApplication openURL - 监控跳转
    var UIApplication = ObjC.classes.UIApplication;
    if (UIApplication) {
        var openURL = UIApplication['- openURL:options:completionHandler:'];
        if (openURL) {
            Interceptor.attach(openURL.implementation, {
                onEnter: function(args) {
                    var url = ObjC.Object(args[2]);
                    console.log("\n[打开 URL] " + url);
                }
            });
        }
        console.log("[+] Hooked UIApplication openURL");
    }

    // 5. Hook GCDWebServer - 监控本地服务器
    var GCDWebServer = ObjC.classes.GCDWebServer;
    if (GCDWebServer) {
        console.log("[+] 发现 GCDWebServer");
    }

    console.log("\n[*] 所有 Hook 已就绪，等待操作...\n");
    console.log("========================================\n");

} else {
    console.log("[-] Objective-C runtime 不可用");
}
