/**
 * Frida Hook脚本 - 拦截应用下载链接
 * 用于分析应用分发平台的下载流程
 * 
 * 使用方法：
 * frida -U -f com.apple.mobilesafari -l hook_app_download.js --no-pause
 * 或者附加到已运行的Safari：
 * frida -U Safari -l hook_app_download.js
 */

console.log("[*] 应用下载Hook脚本已加载");
console.log("[*] 开始监控下载链接...\n");

// Hook NSURLRequest - 拦截所有网络请求
if (ObjC.available) {
    console.log("[+] Objective-C运行时可用");
    
    // Hook NSURLRequest的URL属性
    var NSURLRequest = ObjC.classes.NSURLRequest;
    if (NSURLRequest) {
        Interceptor.attach(NSURLRequest['- URL'].implementation, {
            onEnter: function(args) {
                // args[0] = self
            },
            onLeave: function(retval) {
                if (retval && !retval.isNull()) {
                    var url = new ObjC.Object(retval).toString();
                    
                    // 过滤关键URL
                    if (url.indexOf('.ipa') !== -1 || 
                        url.indexOf('.plist') !== -1 || 
                        url.indexOf('manifest') !== -1 ||
                        url.indexOf('itms-services') !== -1 ||
                        url.indexOf('install') !== -1 ||
                        url.indexOf('download') !== -1) {
                        
                        console.log("\n[!] 发现关键URL:");
                        console.log("    " + url);
                        console.log("    时间: " + new Date().toLocaleString());
                    }
                }
            }
        });
    }
    
    // Hook NSURLConnection - 拦截网络连接
    var NSURLConnection = ObjC.classes.NSURLConnection;
    if (NSURLConnection) {
        Interceptor.attach(NSURLConnection['+ sendSynchronousRequest:returningResponse:error:'].implementation, {
            onEnter: function(args) {
                var request = new ObjC.Object(args[2]);
                var url = request.URL().toString();
                
                if (url.indexOf('.ipa') !== -1 || 
                    url.indexOf('.plist') !== -1 || 
                    url.indexOf('manifest') !== -1) {
                    console.log("\n[!] NSURLConnection同步请求:");
                    console.log("    URL: " + url);
                    console.log("    Method: " + request.HTTPMethod().toString());
                }
            }
        });
    }
    
    // Hook NSURLSession - 现代网络请求
    var NSURLSession = ObjC.classes.NSURLSession;
    if (NSURLSession) {
        // Hook dataTaskWithRequest
        Interceptor.attach(NSURLSession['- dataTaskWithRequest:completionHandler:'].implementation, {
            onEnter: function(args) {
                var request = new ObjC.Object(args[2]);
                var url = request.URL().toString();
                
                if (url.indexOf('.ipa') !== -1 || 
                    url.indexOf('.plist') !== -1 || 
                    url.indexOf('manifest') !== -1 ||
                    url.indexOf('install') !== -1) {
                    console.log("\n[!] NSURLSession数据任务:");
                    console.log("    URL: " + url);
                    console.log("    Method: " + request.HTTPMethod().toString());
                    
                    // 打印请求头
                    var headers = request.allHTTPHeaderFields();
                    if (headers) {
                        console.log("    Headers:");
                        var headerDict = new ObjC.Object(headers);
                        var keys = headerDict.allKeys();
                        for (var i = 0; i < keys.count(); i++) {
                            var key = keys.objectAtIndex_(i).toString();
                            var value = headerDict.objectForKey_(key).toString();
                            console.log("      " + key + ": " + value);
                        }
                    }
                }
            }
        });
        
        // Hook downloadTaskWithRequest
        Interceptor.attach(NSURLSession['- downloadTaskWithRequest:completionHandler:'].implementation, {
            onEnter: function(args) {
                var request = new ObjC.Object(args[2]);
                var url = request.URL().toString();
                
                console.log("\n[!!!] NSURLSession下载任务:");
                console.log("    URL: " + url);
                console.log("    Method: " + request.HTTPMethod().toString());
                console.log("    这可能是IPA下载链接！");
            }
        });
    }
    
    // Hook UIApplication的openURL - 拦截itms-services协议
    var UIApplication = ObjC.classes.UIApplication;
    if (UIApplication) {
        Interceptor.attach(UIApplication['- openURL:'].implementation, {
            onEnter: function(args) {
                var url = new ObjC.Object(args[2]).toString();
                
                if (url.indexOf('itms-services') !== -1) {
                    console.log("\n[!!!] 发现itms-services协议:");
                    console.log("    " + url);
                    
                    // 解析manifest URL
                    var manifestMatch = url.match(/url=([^&]+)/);
                    if (manifestMatch) {
                        var manifestUrl = decodeURIComponent(manifestMatch[1]);
                        console.log("    Manifest URL: " + manifestUrl);
                        console.log("\n[*] 提示: 访问Manifest URL可以找到IPA下载地址");
                    }
                }
            }
        });
        
        // iOS 10+ 的新API
        if (UIApplication['- openURL:options:completionHandler:']) {
            Interceptor.attach(UIApplication['- openURL:options:completionHandler:'].implementation, {
                onEnter: function(args) {
                    var url = new ObjC.Object(args[2]).toString();
                    
                    if (url.indexOf('itms-services') !== -1) {
                        console.log("\n[!!!] 发现itms-services协议 (新API):");
                        console.log("    " + url);
                        
                        var manifestMatch = url.match(/url=([^&]+)/);
                        if (manifestMatch) {
                            var manifestUrl = decodeURIComponent(manifestMatch[1]);
                            console.log("    Manifest URL: " + manifestUrl);
                        }
                    }
                }
            });
        }
    }
    
    // Hook WKWebView的JavaScript执行
    var WKWebView = ObjC.classes.WKWebView;
    if (WKWebView) {
        Interceptor.attach(WKWebView['- evaluateJavaScript:completionHandler:'].implementation, {
            onEnter: function(args) {
                var jsCode = new ObjC.Object(args[2]).toString();
                
                if (jsCode.indexOf('install') !== -1 || 
                    jsCode.indexOf('download') !== -1 ||
                    jsCode.indexOf('itms-services') !== -1) {
                    console.log("\n[!] WKWebView执行JavaScript:");
                    console.log("    " + jsCode.substring(0, 200));
                }
            }
        });
    }
    
    // Hook XMLHttpRequest (通过JavaScriptCore)
    console.log("\n[*] 尝试Hook JavaScript XMLHttpRequest...");
    
} else {
    console.log("[-] Objective-C运行时不可用");
}

// Hook C函数 - 拦截底层网络调用
console.log("\n[*] Hook底层网络函数...");

// Hook CFURLCreateWithString
var CFURLCreateWithString = Module.findExportByName('CoreFoundation', 'CFURLCreateWithString');
if (CFURLCreateWithString) {
    Interceptor.attach(CFURLCreateWithString, {
        onEnter: function(args) {
            // args[1] = CFStringRef URLString
            if (args[1]) {
                var urlString = ObjC.Object(args[1]).toString();
                
                if (urlString.indexOf('.ipa') !== -1 || 
                    urlString.indexOf('.plist') !== -1 || 
                    urlString.indexOf('manifest') !== -1) {
                    console.log("\n[!] CFURLCreateWithString:");
                    console.log("    " + urlString);
                }
            }
        }
    });
}

console.log("\n[*] Hook设置完成，等待下载操作...");
console.log("[*] 请在Safari中点击应用下载按钮\n");
