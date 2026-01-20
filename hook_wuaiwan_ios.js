// Frida脚本 - iOS版本 wuaiwan signer绕过
// Bundle ID: com.wuaiwan.signer
// 目标: 绕过激活码验证，拦截IPA下载链接

console.log("[+] iOS wuaiwan signer 绕过脚本启动...");

// 等待应用完全加载
setTimeout(function() {
    console.log("[+] 开始Hook iOS应用...");
    
    // 1. Hook网络请求
    hookNSURLSession();
    hookNSURLConnection();
    
    // 2. Hook WebView
    hookWKWebView();
    hookUIWebView();
    
    // 3. Hook可能的验证方法
    hookVerificationMethods();
    
    // 4. Hook字符串比较
    hookNSStringMethods();
    
    // 5. Hook用户默认设置
    hookNSUserDefaults();
    
    // 6. Hook Alert弹窗
    hookUIAlertController();
    
}, 2000);

// Hook NSURLSession
function hookNSURLSession() {
    console.log("[+] Hook NSURLSession...");
    
    try {
        var NSURLSession = ObjC.classes.NSURLSession;
        if (NSURLSession) {
            var dataTaskWithRequest = NSURLSession['- dataTaskWithRequest:completionHandler:'];
            
            Interceptor.attach(dataTaskWithRequest.implementation, {
                onEnter: function(args) {
                    var request = new ObjC.Object(args[2]);
                    var url = request.URL().absoluteString().toString();
                    
                    console.log("[网络] NSURLSession请求: " + url);
                    
                    // 检查激活相关请求
                    if (url.includes("activate") || url.includes("verify") || url.includes("check")) {
                        console.log("[🎯] 检测到激活验证请求: " + url);
                    }
                    
                    // 检查下载相关请求
                    if (url.includes("download") || url.includes("install") || url.includes(".ipa")) {
                        console.log("[📥] 检测到下载相关请求: " + url);
                    }
                },
                onLeave: function(retval) {
                    // 可以在这里修改返回值
                }
            });
        }
    } catch (e) {
        console.log("[-] NSURLSession Hook失败: " + e);
    }
}

// Hook NSURLConnection (旧版API)
function hookNSURLConnection() {
    console.log("[+] Hook NSURLConnection...");
    
    try {
        var NSURLConnection = ObjC.classes.NSURLConnection;
        if (NSURLConnection) {
            var sendSynchronousRequest = NSURLConnection['+ sendSynchronousRequest:returningResponse:error:'];
            
            Interceptor.attach(sendSynchronousRequest.implementation, {
                onEnter: function(args) {
                    var request = new ObjC.Object(args[2]);
                    var url = request.URL().absoluteString().toString();
                    
                    console.log("[网络] NSURLConnection请求: " + url);
                    
                    if (url.includes("activate") || url.includes("verify")) {
                        console.log("[🎯] 拦截激活验证请求");
                    }
                }
            });
        }
    } catch (e) {
        console.log("[-] NSURLConnection Hook失败: " + e);
    }
}

// Hook WKWebView
function hookWKWebView() {
    console.log("[+] Hook WKWebView...");
    
    try {
        var WKWebView = ObjC.classes.WKWebView;
        if (WKWebView) {
            // Hook loadRequest
            var loadRequest = WKWebView['- loadRequest:'];
            Interceptor.attach(loadRequest.implementation, {
                onEnter: function(args) {
                    var request = new ObjC.Object(args[2]);
                    var url = request.URL().absoluteString().toString();
                    
                    console.log("[WebView] WKWebView加载: " + url);
                    
                    if (url.includes("ios80.com") || url.includes("ipa")) {
                        console.log("[🎯] 检测到IPA下载页面");
                    }
                }
            });
            
            // Hook evaluateJavaScript
            var evaluateJavaScript = WKWebView['- evaluateJavaScript:completionHandler:'];
            Interceptor.attach(evaluateJavaScript.implementation, {
                onEnter: function(args) {
                    var script = new ObjC.Object(args[2]).toString();
                    
                    console.log("[WebView] 执行JavaScript: " + script.substring(0, 200) + "...");
                    
                    // 检查是否是激活相关的JavaScript
                    if (script.includes("appInstall") || script.includes("activate") || script.includes("verify")) {
                        console.log("[🎯] 检测到激活相关JavaScript");
                        
                        // 替换为绕过脚本
                        var bypassScript = ObjC.classes.NSString.stringWithString_(
                            "console.log('Frida: 绕过激活验证'); " +
                            "if (typeof window.install === 'function') { window.install(); } " +
                            "if (typeof window.appInstall !== 'undefined') { " +
                            "  window.appInstall.postMessage = function(shortLink) { " +
                            "    console.log('Frida: 拦截appInstall.postMessage', shortLink); " +
                            "    window.location.href = 'https://app.ios80.com/download/' + shortLink + '.ipa'; " +
                            "    return false; " +
                            "  }; " +
                            "}"
                        );
                        
                        args[2] = bypassScript;
                        console.log("[✅] 已替换为绕过脚本");
                    }
                }
            });
        }
    } catch (e) {
        console.log("[-] WKWebView Hook失败: " + e);
    }
}

// Hook UIWebView (旧版)
function hookUIWebView() {
    console.log("[+] Hook UIWebView...");
    
    try {
        var UIWebView = ObjC.classes.UIWebView;
        if (UIWebView) {
            var loadRequest = UIWebView['- loadRequest:'];
            Interceptor.attach(loadRequest.implementation, {
                onEnter: function(args) {
                    var request = new ObjC.Object(args[2]);
                    var url = request.URL().absoluteString().toString();
                    
                    console.log("[WebView] UIWebView加载: " + url);
                }
            });
            
            var stringByEvaluatingJavaScriptFromString = UIWebView['- stringByEvaluatingJavaScriptFromString:'];
            Interceptor.attach(stringByEvaluatingJavaScriptFromString.implementation, {
                onEnter: function(args) {
                    var script = new ObjC.Object(args[2]).toString();
                    
                    console.log("[WebView] UIWebView JavaScript: " + script.substring(0, 100) + "...");
                    
                    if (script.includes("appInstall") || script.includes("activate")) {
                        console.log("[🎯] 拦截UIWebView激活脚本");
                    }
                }
            });
        }
    } catch (e) {
        console.log("[-] UIWebView Hook失败: " + e);
    }
}

// Hook可能的验证方法
function hookVerificationMethods() {
    console.log("[+] Hook验证方法...");
    
    // 枚举所有已加载的类
    for (var className in ObjC.classes) {
        if (className.includes("wuaiwan") || 
            className.includes("Verify") || 
            className.includes("Activate") ||
            className.includes("License")) {
            
            console.log("[验证] 找到可能的验证类: " + className);
            
            try {
                var clazz = ObjC.classes[className];
                var methods = clazz.$ownMethods;
                
                methods.forEach(function(methodName) {
                    if (methodName.includes("verify") || 
                        methodName.includes("check") || 
                        methodName.includes("validate") ||
                        methodName.includes("activate")) {
                        
                        console.log("[验证] Hook方法: " + className + "." + methodName);
                        
                        try {
                            var method = clazz[methodName];
                            Interceptor.attach(method.implementation, {
                                onEnter: function(args) {
                                    console.log("[🎯] 拦截验证方法: " + methodName);
                                },
                                onLeave: function(retval) {
                                    console.log("[✅] 强制验证成功");
                                    retval.replace(ptr(1)); // 返回true/success
                                }
                            });
                        } catch (e) {
                            // 忽略Hook失败的方法
                        }
                    }
                });
            } catch (e) {
                // 忽略无法处理的类
            }
        }
    }
}

// Hook NSString方法
function hookNSStringMethods() {
    console.log("[+] Hook NSString方法...");
    
    try {
        var NSString = ObjC.classes.NSString;
        
        // Hook isEqualToString
        var isEqualToString = NSString['- isEqualToString:'];
        Interceptor.attach(isEqualToString.implementation, {
            onEnter: function(args) {
                var str1 = new ObjC.Object(args[0]).toString();
                var str2 = new ObjC.Object(args[2]).toString();
                
                // 只记录可能的激活码比较
                if ((str1.length > 5 && str1.length < 50) || (str2.length > 5 && str2.length < 50)) {
                    if (str1.includes("activate") || str2.includes("activate") ||
                        str1.match(/^[A-Z0-9]{8,}$/) || str2.match(/^[A-Z0-9]{8,}$/)) {
                        
                        console.log("[🔤] 字符串比较: '" + str1 + "' == '" + str2 + "'");
                        
                        // 如果看起来像激活码比较，强制返回YES
                        if (str1.match(/^[A-Z0-9]{8,}$/) || str2.match(/^[A-Z0-9]{8,}$/)) {
                            console.log("[✅] 强制激活码比较成功");
                        }
                    }
                }
            },
            onLeave: function(retval) {
                // 可以在这里修改返回值
                // retval.replace(ptr(1)); // 强制返回YES
            }
        });
        
        // Hook containsString
        var containsString = NSString['- containsString:'];
        if (containsString) {
            Interceptor.attach(containsString.implementation, {
                onEnter: function(args) {
                    var str1 = new ObjC.Object(args[0]).toString();
                    var str2 = new ObjC.Object(args[2]).toString();
                    
                    if (str1.length > 10 && str2.length > 3) {
                        console.log("[🔤] 包含检查: '" + str1 + "'.contains('" + str2 + "')");
                    }
                }
            });
        }
    } catch (e) {
        console.log("[-] NSString Hook失败: " + e);
    }
}

// Hook NSUserDefaults
function hookNSUserDefaults() {
    console.log("[+] Hook NSUserDefaults...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        // Hook boolForKey
        var boolForKey = NSUserDefaults['- boolForKey:'];
        Interceptor.attach(boolForKey.implementation, {
            onEnter: function(args) {
                var key = new ObjC.Object(args[2]).toString();
                console.log("[存储] 读取布尔值: " + key);
                
                // 如果是激活相关的键，强制返回YES
                if (key.includes("activate") || 
                    key.includes("verified") || 
                    key.includes("licensed") ||
                    key.includes("premium")) {
                    
                    console.log("[✅] 强制激活状态为YES: " + key);
                }
            },
            onLeave: function(retval) {
                // 可以强制返回YES
                // retval.replace(ptr(1));
            }
        });
        
        // Hook objectForKey
        var objectForKey = NSUserDefaults['- objectForKey:'];
        Interceptor.attach(objectForKey.implementation, {
            onEnter: function(args) {
                var key = new ObjC.Object(args[2]).toString();
                console.log("[存储] 读取对象: " + key);
                
                if (key.includes("code") || key.includes("key") || key.includes("token")) {
                    console.log("[🎯] 检测到激活码相关键: " + key);
                }
            }
        });
    } catch (e) {
        console.log("[-] NSUserDefaults Hook失败: " + e);
    }
}

// Hook UIAlertController
function hookUIAlertController() {
    console.log("[+] Hook UIAlertController...");
    
    try {
        var UIAlertController = ObjC.classes.UIAlertController;
        if (UIAlertController) {
            var alertControllerWithTitle = UIAlertController['+ alertControllerWithTitle:message:preferredStyle:'];
            
            Interceptor.attach(alertControllerWithTitle.implementation, {
                onEnter: function(args) {
                    var title = new ObjC.Object(args[2]);
                    var message = new ObjC.Object(args[3]);
                    
                    var titleStr = title ? title.toString() : "";
                    var messageStr = message ? message.toString() : "";
                    
                    console.log("[UI] Alert弹窗: " + titleStr + " - " + messageStr);
                    
                    // 如果是激活相关的弹窗，阻止显示
                    if (titleStr.includes("激活") || titleStr.includes("验证") ||
                        messageStr.includes("激活") || messageStr.includes("验证") ||
                        titleStr.includes("activate") || messageStr.includes("activate")) {
                        
                        console.log("[🚫] 阻止激活弹窗显示");
                        // 返回nil来阻止弹窗
                        // retval.replace(ptr(0));
                    }
                }
            });
        }
    } catch (e) {
        console.log("[-] UIAlertController Hook失败: " + e);
    }
}

// 监听应用生命周期
function hookApplicationLifecycle() {
    console.log("[+] Hook应用生命周期...");
    
    try {
        var UIApplication = ObjC.classes.UIApplication;
        if (UIApplication) {
            var openURL = UIApplication['- openURL:'];
            
            Interceptor.attach(openURL.implementation, {
                onEnter: function(args) {
                    var url = new ObjC.Object(args[2]);
                    var urlStr = url.absoluteString().toString();
                    
                    console.log("[应用] 打开URL: " + urlStr);
                    
                    // 如果是IPA下载链接，记录下来
                    if (urlStr.includes(".ipa") || urlStr.includes("itms-services")) {
                        console.log("[🎉] 找到IPA下载链接: " + urlStr);
                        
                        // 发送到控制台
                        send({
                            type: "ipa_url_found",
                            url: urlStr,
                            timestamp: new Date().toISOString()
                        });
                    }
                }
            });
        }
    } catch (e) {
        console.log("[-] 应用生命周期Hook失败: " + e);
    }
}

// 延迟执行更深层的Hook
setTimeout(function() {
    console.log("[+] 执行深层Hook...");
    hookApplicationLifecycle();
    
    // 尝试找到应用特定的类
    for (var className in ObjC.classes) {
        if (className.toLowerCase().includes("wuaiwan") || 
            className.toLowerCase().includes("signer")) {
            
            console.log("[应用] 找到应用类: " + className);
            
            try {
                var clazz = ObjC.classes[className];
                var methods = clazz.$ownMethods;
                
                console.log("[应用] " + className + " 方法数量: " + methods.length);
                
                methods.forEach(function(methodName) {
                    if (methodName.includes("download") || 
                        methodName.includes("install") || 
                        methodName.includes("verify") ||
                        methodName.includes("activate")) {
                        
                        console.log("[应用] 关键方法: " + className + "." + methodName);
                    }
                });
            } catch (e) {
                // 忽略错误
            }
        }
    }
}, 5000);

console.log("[+] iOS绕过脚本加载完成，等待应用交互...");