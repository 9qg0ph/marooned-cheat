// Frida 脚本 - Hook GameForFun.dylib 网络请求

console.log("[*] GameForFun.dylib 网络请求 Hook 脚本");

// Hook NSURLSession
if (ObjC.available) {
    try {
        // Hook NSURLSession dataTaskWithRequest:completionHandler:
        var NSURLSession = ObjC.classes.NSURLSession;
        if (NSURLSession) {
            var dataTaskWithRequest = NSURLSession['- dataTaskWithRequest:completionHandler:'];
            if (dataTaskWithRequest) {
                Interceptor.attach(dataTaskWithRequest.implementation, {
                    onEnter: function(args) {
                        var request = ObjC.Object(args[2]);
                        var url = request.URL();
                        if (url) {
                            var urlStr = url.absoluteString().toString();
                            if (urlStr.indexOf('fanhangame') !== -1 || urlStr.indexOf('fanhan') !== -1) {
                                console.log("\n[NSURLSession] 发现验证请求!");
                                console.log("  URL: " + urlStr);
                                console.log("  Method: " + request.HTTPMethod());
                                var body = request.HTTPBody();
                                if (body) {
                                    var bodyStr = ObjC.classes.NSString.alloc().initWithData_encoding_(body, 4);
                                    console.log("  Body: " + bodyStr);
                                }
                            }
                        }
                    }
                });
                console.log("[+] Hooked NSURLSession dataTaskWithRequest:completionHandler:");
            }
        }

        // Hook NSMutableURLRequest
        var NSMutableURLRequest = ObjC.classes.NSMutableURLRequest;
        if (NSMutableURLRequest) {
            Interceptor.attach(NSMutableURLRequest['- setURL:'].implementation, {
                onEnter: function(args) {
                    var url = ObjC.Object(args[2]);
                    if (url) {
                        var urlStr = url.absoluteString().toString();
                        if (urlStr.indexOf('fanhangame') !== -1) {
                            console.log("\n[NSMutableURLRequest] setURL: " + urlStr);
                        }
                    }
                }
            });
            console.log("[+] Hooked NSMutableURLRequest setURL:");
        }

        // Hook AFNetworking (如果存在)
        var AFHTTPSessionManager = ObjC.classes.AFHTTPSessionManager;
        if (AFHTTPSessionManager) {
            var postMethod = AFHTTPSessionManager['- POST:parameters:headers:progress:success:failure:'];
            if (postMethod) {
                Interceptor.attach(postMethod.implementation, {
                    onEnter: function(args) {
                        var url = ObjC.Object(args[2]);
                        console.log("\n[AFNetworking POST] " + url);
                        var params = ObjC.Object(args[3]);
                        if (params) {
                            console.log("  Params: " + params);
                        }
                    }
                });
                console.log("[+] Hooked AFHTTPSessionManager POST:");
            }
        }

        // Hook FanhanAlertView showNotice
        var FanhanAlertView = ObjC.classes.FanhanAlertView;
        if (FanhanAlertView) {
            var showNotice = FanhanAlertView['- showNotice:title:subTitle:closeButtonTitle:duration:'];
            if (showNotice) {
                Interceptor.attach(showNotice.implementation, {
                    onEnter: function(args) {
                        console.log("\n[FanhanAlertView] showNotice 被调用!");
                        console.log("  title: " + ObjC.Object(args[3]));
                        console.log("  subTitle: " + ObjC.Object(args[4]));
                        // 打印调用栈
                        console.log("  调用栈:");
                        console.log(Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress).join('\n'));
                    }
                });
                console.log("[+] Hooked FanhanAlertView showNotice:");
            }

            var showInfo = FanhanAlertView['- showInfo:title:subTitle:closeButtonTitle:duration:'];
            if (showInfo) {
                Interceptor.attach(showInfo.implementation, {
                    onEnter: function(args) {
                        console.log("\n[FanhanAlertView] showInfo 被调用!");
                        console.log("  title: " + ObjC.Object(args[3]));
                        console.log("  subTitle: " + ObjC.Object(args[4]));
                    }
                });
                console.log("[+] Hooked FanhanAlertView showInfo:");
            }
        }

        console.log("\n[*] Hook 完成，等待网络请求...\n");

    } catch (e) {
        console.log("[-] Error: " + e);
    }
} else {
    console.log("[-] Objective-C runtime not available");
}
