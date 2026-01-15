// 隐蔽抓包脚本 - 绕过反调试

console.log("[*] 隐蔽模式启动...");

// 延迟 8 秒后再 Hook，避免被检测
setTimeout(function() {
    console.log("[*] 开始 Hook...\n");
    
    if (ObjC.available) {
        try {
            // 只 Hook 最关键的 NSURLSession
            var NSURLSession = ObjC.classes.NSURLSession;
            if (NSURLSession) {
                var method = NSURLSession['- dataTaskWithRequest:completionHandler:'];
                if (method) {
                    Interceptor.attach(method.implementation, {
                        onEnter: function(args) {
                            try {
                                var request = ObjC.Object(args[2]);
                                var url = request.URL();
                                if (url) {
                                    var urlStr = url.absoluteString().toString();
                                    
                                    // 只打印 fanhangame 相关的请求
                                    if (urlStr.indexOf('fanhan') !== -1) {
                                        console.log("\n========== 验证请求 ==========");
                                        console.log("URL: " + urlStr);
                                        console.log("Method: " + request.HTTPMethod());
                                        
                                        var body = request.HTTPBody();
                                        if (body) {
                                            var bodyStr = ObjC.classes.NSString.alloc().initWithData_encoding_(body, 4);
                                            console.log("Body: " + bodyStr);
                                        }
                                        
                                        var headers = request.allHTTPHeaderFields();
                                        if (headers) {
                                            console.log("Headers: " + headers);
                                        }
                                        console.log("==============================\n");
                                    }
                                }
                            } catch(e) {
                                // 静默失败
                            }
                        }
                    });
                    console.log("[+] Hook 成功\n");
                }
            }
            
            // Hook Keychain 读取
            var FanhanKeychain = ObjC.classes.FanhanKeychain;
            if (FanhanKeychain) {
                var getPassword = FanhanKeychain['+ passwordForService:account:'];
                if (getPassword) {
                    Interceptor.attach(getPassword.implementation, {
                        onEnter: function(args) {
                            this.service = ObjC.Object(args[2]);
                            this.account = ObjC.Object(args[3]);
                        },
                        onLeave: function(retval) {
                            try {
                                var result = ObjC.Object(retval);
                                console.log("\n[Keychain] Service: " + this.service + ", Account: " + this.account + ", Result: " + result);
                            } catch(e) {}
                        }
                    });
                    console.log("[+] Hook Keychain 成功\n");
                }
            }
            
            // Hook 弹窗
            var FanhanAlertView = ObjC.classes.FanhanAlertView;
            if (FanhanAlertView) {
                var showNotice = FanhanAlertView['- showNotice:title:subTitle:closeButtonTitle:duration:'];
                if (showNotice) {
                    Interceptor.attach(showNotice.implementation, {
                        onEnter: function(args) {
                            try {
                                console.log("\n[弹窗] title: " + ObjC.Object(args[3]) + ", subTitle: " + ObjC.Object(args[4]));
                            } catch(e) {}
                        }
                    });
                }
            }
            
            console.log("[*] 等待操作...\n");
            
        } catch(e) {
            console.log("[-] Error: " + e);
        }
    }
}, 8000);
