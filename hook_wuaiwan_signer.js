/**
 * Frida Hook脚本 - 专门针对 wuaiwan signer (com.wuaiwan.signer)
 * 用于拦截应用下载和签名流程，找到IPA真实下载地址
 * 
 * 使用方法：
 * frida -U -f com.wuaiwan.signer -l hook_wuaiwan_signer.js --no-pause
 * 或者附加到已运行的应用：
 * frida -U -n "wuaiwan" -l hook_wuaiwan_signer.js
 */

console.log("=".repeat(60));
console.log("[*] wuaiwan Signer Hook脚本已加载");
console.log("[*] 目标应用: com.wuaiwan.signer");
console.log("[*] 开始监控下载和签名流程...");
console.log("=".repeat(60) + "\n");

if (ObjC.available) {
    console.log("[+] Objective-C运行时可用\n");
    
    // ==================== 网络请求拦截 ====================
    
    // Hook NSURLRequest - 拦截所有网络请求
    var NSURLRequest = ObjC.classes.NSURLRequest;
    if (NSURLRequest) {
        console.log("[+] Hook NSURLRequest");
        
        Interceptor.attach(NSURLRequest['- URL'].implementation, {
            onLeave: function(retval) {
                if (retval && !retval.isNull()) {
                    var url = new ObjC.Object(retval).toString();
                    
                    // 过滤关键URL
                    if (url.indexOf('.ipa') !== -1 || 
                        url.indexOf('.plist') !== -1 || 
                        url.indexOf('manifest') !== -1 ||
                        url.indexOf('itms-services') !== -1 ||
                        url.indexOf('install') !== -1 ||
                        url.indexOf('download') !== -1 ||
                        url.indexOf('wuaiwan') !== -1 ||
                        url.indexOf('sign') !== -1) {
                        
                        console.log("\n" + "=".repeat(60));
                        console.log("[!!!] 发现关键URL:");
                        console.log("URL: " + url);
                        console.log("时间: " + new Date().toLocaleString());
                        console.log("=".repeat(60) + "\n");
                    }
                }
            }
        });
    }
    
    // Hook NSURLSession - 现代网络请求API
    var NSURLSession = ObjC.classes.NSURLSession;
    if (NSURLSession) {
        console.log("[+] Hook NSURLSession");
        
        // Hook dataTaskWithRequest
        Interceptor.attach(NSURLSession['- dataTaskWithRequest:completionHandler:'].implementation, {
            onEnter: function(args) {
                var request = new ObjC.Object(args[2]);
                var url = request.URL().toString();
                var method = request.HTTPMethod().toString();
                
                if (url.indexOf('.ipa') !== -1 || 
                    url.indexOf('.plist') !== -1 || 
                    url.indexOf('manifest') !== -1 ||
                    url.indexOf('install') !== -1 ||
                    url.indexOf('download') !== -1 ||
                    url.indexOf('wuaiwan') !== -1 ||
                    url.indexOf('sign') !== -1) {
                    
                    console.log("\n" + "=".repeat(60));
                    console.log("[!!!] NSURLSession数据任务:");
                    console.log("URL: " + url);
                    console.log("Method: " + method);
                    
                    // 打印请求体
                    var body = request.HTTPBody();
                    if (body && !body.isNull()) {
                        var bodyData = new ObjC.Object(body);
                        var bodyStr = bodyData.toString();
                        console.log("Body: " + bodyStr);
                    }
                    
                    // 打印请求头
                    var headers = request.allHTTPHeaderFields();
                    if (headers && !headers.isNull()) {
                        console.log("Headers:");
                        var headerDict = new ObjC.Object(headers);
                        var keys = headerDict.allKeys();
                        for (var i = 0; i < keys.count(); i++) {
                            var key = keys.objectAtIndex_(i).toString();
                            var value = headerDict.objectForKey_(key).toString();
                            console.log("  " + key + ": " + value);
                        }
                    }
                    console.log("=".repeat(60) + "\n");
                }
            }
        });
        
        // Hook downloadTaskWithRequest - 下载任务
        Interceptor.attach(NSURLSession['- downloadTaskWithRequest:completionHandler:'].implementation, {
            onEnter: function(args) {
                var request = new ObjC.Object(args[2]);
                var url = request.URL().toString();
                
                console.log("\n" + "=".repeat(60));
                console.log("[!!!] NSURLSession下载任务 (可能是IPA下载):");
                console.log("URL: " + url);
                console.log("Method: " + request.HTTPMethod().toString());
                console.log("=".repeat(60) + "\n");
            }
        });
        
        // Hook downloadTaskWithURL - 简化下载API
        if (NSURLSession['- downloadTaskWithURL:completionHandler:']) {
            Interceptor.attach(NSURLSession['- downloadTaskWithURL:completionHandler:'].implementation, {
                onEnter: function(args) {
                    var url = new ObjC.Object(args[2]).toString();
                    
                    console.log("\n" + "=".repeat(60));
                    console.log("[!!!] NSURLSession简化下载任务:");
                    console.log("URL: " + url);
                    console.log("=".repeat(60) + "\n");
                }
            });
        }
    }
    
    // ==================== 文件操作拦截 ====================
    
    // Hook NSFileManager - 拦截文件操作
    var NSFileManager = ObjC.classes.NSFileManager;
    if (NSFileManager) {
        console.log("[+] Hook NSFileManager");
        
        // Hook copyItemAtPath
        Interceptor.attach(NSFileManager['- copyItemAtPath:toPath:error:'].implementation, {
            onEnter: function(args) {
                var fromPath = new ObjC.Object(args[2]).toString();
                var toPath = new ObjC.Object(args[3]).toString();
                
                if (fromPath.indexOf('.ipa') !== -1 || toPath.indexOf('.ipa') !== -1) {
                    console.log("\n[!] 文件复制操作:");
                    console.log("从: " + fromPath);
                    console.log("到: " + toPath);
                }
            }
        });
        
        // Hook moveItemAtPath
        Interceptor.attach(NSFileManager['- moveItemAtPath:toPath:error:'].implementation, {
            onEnter: function(args) {
                var fromPath = new ObjC.Object(args[2]).toString();
                var toPath = new ObjC.Object(args[3]).toString();
                
                if (fromPath.indexOf('.ipa') !== -1 || toPath.indexOf('.ipa') !== -1) {
                    console.log("\n[!] 文件移动操作:");
                    console.log("从: " + fromPath);
                    console.log("到: " + toPath);
                }
            }
        });
    }
    
    // ==================== itms-services协议拦截 ====================
    
    // Hook UIApplication的openURL
    var UIApplication = ObjC.classes.UIApplication;
    if (UIApplication) {
        console.log("[+] Hook UIApplication openURL");
        
        // iOS 9及以下
        if (UIApplication['- openURL:']) {
            Interceptor.attach(UIApplication['- openURL:'].implementation, {
                onEnter: function(args) {
                    var url = new ObjC.Object(args[2]).toString();
                    
                    console.log("\n" + "=".repeat(60));
                    console.log("[!!!] UIApplication openURL:");
                    console.log("URL: " + url);
                    
                    if (url.indexOf('itms-services') !== -1) {
                        console.log("\n[!!!] 发现itms-services协议!");
                        
                        // 解析manifest URL
                        var manifestMatch = url.match(/url=([^&]+)/);
                        if (manifestMatch) {
                            var manifestUrl = decodeURIComponent(manifestMatch[1]);
                            console.log("Manifest URL: " + manifestUrl);
                            console.log("\n[*] 提示: 访问Manifest URL可以找到IPA下载地址");
                        }
                    }
                    console.log("=".repeat(60) + "\n");
                }
            });
        }
        
        // iOS 10+
        if (UIApplication['- openURL:options:completionHandler:']) {
            Interceptor.attach(UIApplication['- openURL:options:completionHandler:'].implementation, {
                onEnter: function(args) {
                    var url = new ObjC.Object(args[2]).toString();
                    
                    console.log("\n" + "=".repeat(60));
                    console.log("[!!!] UIApplication openURL (iOS 10+):");
                    console.log("URL: " + url);
                    
                    if (url.indexOf('itms-services') !== -1) {
                        console.log("\n[!!!] 发现itms-services协议!");
                        
                        var manifestMatch = url.match(/url=([^&]+)/);
                        if (manifestMatch) {
                            var manifestUrl = decodeURIComponent(manifestMatch[1]);
                            console.log("Manifest URL: " + manifestUrl);
                        }
                    }
                    console.log("=".repeat(60) + "\n");
                }
            });
        }
    }
    
    // ==================== WKWebView拦截 ====================
    
    var WKWebView = ObjC.classes.WKWebView;
    if (WKWebView) {
        console.log("[+] Hook WKWebView");
        
        // Hook loadRequest
        Interceptor.attach(WKWebView['- loadRequest:'].implementation, {
            onEnter: function(args) {
                var request = new ObjC.Object(args[2]);
                var url = request.URL().toString();
                
                if (url.indexOf('install') !== -1 || 
                    url.indexOf('download') !== -1 ||
                    url.indexOf('wuaiwan') !== -1) {
                    console.log("\n[!] WKWebView加载请求:");
                    console.log("URL: " + url);
                }
            }
        });
        
        // Hook evaluateJavaScript
        Interceptor.attach(WKWebView['- evaluateJavaScript:completionHandler:'].implementation, {
            onEnter: function(args) {
                var jsCode = new ObjC.Object(args[2]).toString();
                
                if (jsCode.indexOf('install') !== -1 || 
                    jsCode.indexOf('download') !== -1 ||
                    jsCode.indexOf('itms-services') !== -1 ||
                    jsCode.indexOf('window.location') !== -1) {
                    console.log("\n[!] WKWebView执行JavaScript:");
                    console.log(jsCode.substring(0, 500));
                }
            }
        });
    }
    
    // ==================== 字符串搜索 ====================
    
    // Hook NSString的stringWithFormat - 可能用于构建URL
    var NSString = ObjC.classes.NSString;
    if (NSString) {
        Interceptor.attach(NSString['+ stringWithFormat:'].implementation, {
            onLeave: function(retval) {
                if (retval && !retval.isNull()) {
                    var str = new ObjC.Object(retval).toString();
                    
                    if (str.indexOf('.ipa') !== -1 || 
                        str.indexOf('itms-services') !== -1 ||
                        str.indexOf('manifest') !== -1) {
                        console.log("\n[!] NSString格式化:");
                        console.log(str);
                    }
                }
            }
        });
    }
    
    console.log("\n" + "=".repeat(60));
    console.log("[*] Hook设置完成!");
    console.log("[*] 请在应用中执行下载操作");
    console.log("[*] 所有关键URL和文件路径将被拦截并显示");
    console.log("=".repeat(60) + "\n");
    
} else {
    console.log("[-] Objective-C运行时不可用");
}
