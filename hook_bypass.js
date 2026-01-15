// Frida 脚本 - 绕过反调试 + Hook 网络请求

console.log("[*] 绕过反调试 + Hook 网络请求");

// 延迟执行，等待 dylib 加载
setTimeout(function() {
    if (ObjC.available) {
        try {
            // Hook NSURLSession
            var NSURLSession = ObjC.classes.NSURLSession;
            if (NSURLSession) {
                var methods = ['- dataTaskWithRequest:completionHandler:', '- dataTaskWithURL:completionHandler:'];
                methods.forEach(function(methodName) {
                    var method = NSURLSession[methodName];
                    if (method) {
                        Interceptor.attach(method.implementation, {
                            onEnter: function(args) {
                                var request = ObjC.Object(args[2]);
                                var url;
                                if (methodName.indexOf('URL:') !== -1) {
                                    url = request;
                                } else {
                                    url = request.URL();
                                }
                                if (url) {
                                    var urlStr = url.absoluteString ? url.absoluteString().toString() : url.toString();
                                    if (urlStr.indexOf('fanhan') !== -1 || urlStr.indexOf('game') !== -1) {
                                        console.log("\n========== 网络请求 ==========");
                                        console.log("URL: " + urlStr);
                                        if (request.HTTPMethod) {
                                            console.log("Method: " + request.HTTPMethod());
                                        }
                                        if (request.HTTPBody) {
                                            var body = request.HTTPBody();
                                            if (body) {
                                                var bodyStr = ObjC.classes.NSString.alloc().initWithData_encoding_(body, 4);
                                                console.log("Body: " + bodyStr);
                                            }
                                        }
                                        if (request.allHTTPHeaderFields) {
                                            console.log("Headers: " + request.allHTTPHeaderFields());
                                        }
                                        console.log("==============================\n");
                                    }
                                }
                            }
                        });
                        console.log("[+] Hooked " + methodName);
                    }
                });
            }

            // Hook FanhanAlertView
            var FanhanAlertView = ObjC.classes.FanhanAlertView;
            if (FanhanAlertView) {
                console.log("[+] 找到 FanhanAlertView 类");
                
                // Hook 所有 show 方法
                var showMethods = [
                    '- showNotice:title:subTitle:closeButtonTitle:duration:',
                    '- showInfo:title:subTitle:closeButtonTitle:duration:',
                    '- showError:title:subTitle:closeButtonTitle:duration:',
                    '- showWarning:title:subTitle:closeButtonTitle:duration:',
                    '- showTitle:image:color:title:subTitle:duration:completeText:style:'
                ];
                
                showMethods.forEach(function(methodName) {
                    var method = FanhanAlertView[methodName];
                    if (method) {
                        Interceptor.attach(method.implementation, {
                            onEnter: function(args) {
                                console.log("\n========== 弹窗调用 ==========");
                                console.log("方法: " + methodName);
                                if (args[3]) console.log("title: " + ObjC.Object(args[3]));
                                if (args[4]) console.log("subTitle: " + ObjC.Object(args[4]));
                                console.log("调用栈:");
                                var bt = Thread.backtrace(this.context, Backtracer.FUZZY);
                                for (var i = 0; i < Math.min(bt.length, 10); i++) {
                                    console.log("  " + DebugSymbol.fromAddress(bt[i]));
                                }
                                console.log("==============================\n");
                            }
                        });
                        console.log("[+] Hooked " + methodName);
                    }
                });
            } else {
                console.log("[-] FanhanAlertView 类未找到，可能 dylib 未加载");
            }

            console.log("\n[*] Hook 完成，等待触发...\n");

        } catch (e) {
            console.log("[-] Error: " + e);
        }
    }
}, 3000);  // 延迟 3 秒
