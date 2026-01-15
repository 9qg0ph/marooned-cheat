// 简单的网络请求 Hook

console.log("[*] 简单网络 Hook");

// 延迟 5 秒后执行
setTimeout(function() {
    console.log("[*] 开始 Hook...");
    
    if (ObjC.available) {
        // 只 Hook NSURLSession
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
                                console.log("[URL] " + urlStr);
                                
                                // 只打印 fanhangame 相关
                                if (urlStr.indexOf('fanhan') !== -1) {
                                    console.log("  [!] 验证请求!");
                                    var body = request.HTTPBody();
                                    if (body) {
                                        var bodyStr = ObjC.classes.NSString.alloc().initWithData_encoding_(body, 4);
                                        console.log("  Body: " + bodyStr);
                                    }
                                }
                            }
                        } catch(e) {}
                    }
                });
                console.log("[+] Hooked NSURLSession");
            }
        }
    }
}, 5000);
