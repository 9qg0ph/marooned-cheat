// 超级隐蔽模式 - 延迟 15 秒，最小化 Hook

console.log("[*] 等待中...");

// 延迟 15 秒
setTimeout(function() {
    console.log("[*] 开始监控\n");
    
    if (ObjC.available) {
        try {
            // 只 Hook NSURLSession 的一个方法
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
                                    
                                    // 只打印 fanhangame 相关
                                    if (urlStr.indexOf('fanhan') !== -1) {
                                        console.log("\n[URL] " + urlStr);
                                        
                                        var body = request.HTTPBody();
                                        if (body) {
                                            var bodyStr = ObjC.classes.NSString.alloc().initWithData_encoding_(body, 4);
                                            console.log("[Body] " + bodyStr);
                                        }
                                    }
                                }
                            } catch(e) {}
                        }
                    });
                    console.log("[+] 监控已启动\n");
                }
            }
        } catch(e) {}
    }
}, 15000);
