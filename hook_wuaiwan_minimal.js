// 最小化Hook脚本 - 避免触发反调试
console.log("[+] 最小化Hook脚本启动...");

// 延迟5秒再开始Hook，让应用完全启动
setTimeout(function() {
    console.log("[+] 开始轻量级Hook...");
    
    try {
        // 只Hook最关键的网络请求
        var NSURLSession = ObjC.classes.NSURLSession;
        if (NSURLSession) {
            console.log("[+] 找到NSURLSession，准备监控网络请求");
            
            var dataTaskWithRequest = NSURLSession['- dataTaskWithRequest:completionHandler:'];
            if (dataTaskWithRequest) {
                Interceptor.attach(dataTaskWithRequest.implementation, {
                    onEnter: function(args) {
                        try {
                            var request = new ObjC.Object(args[2]);
                            var url = request.URL().absoluteString().toString();
                            
                            console.log("[网络] 请求: " + url);
                            
                            // 只记录重要的URL
                            if (url.includes("ios80.com") || 
                                url.includes("activate") || 
                                url.includes("verify") ||
                                url.includes(".ipa")) {
                                console.log("[🎯] 重要请求: " + url);
                            }
                        } catch (e) {
                            // 忽略错误，避免崩溃
                        }
                    }
                });
                console.log("[+] 网络监控已设置");
            }
        }
        
        // 监控WebView加载
        var WKWebView = ObjC.classes.WKWebView;
        if (WKWebView) {
            console.log("[+] 找到WKWebView");
            
            var loadRequest = WKWebView['- loadRequest:'];
            if (loadRequest) {
                Interceptor.attach(loadRequest.implementation, {
                    onEnter: function(args) {
                        try {
                            var request = new ObjC.Object(args[2]);
                            var url = request.URL().absoluteString().toString();
                            
                            console.log("[WebView] 加载: " + url);
                            
                            if (url.includes("ios80.com")) {
                                console.log("[🎯] IPA下载页面: " + url);
                            }
                        } catch (e) {
                            // 忽略错误
                        }
                    }
                });
                console.log("[+] WebView监控已设置");
            }
        }
        
    } catch (e) {
        console.log("[-] Hook设置失败: " + e);
    }
    
}, 5000);

console.log("[+] 脚本加载完成，等待应用稳定运行...");