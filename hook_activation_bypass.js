/**
 * Frida Hook脚本 - 绕过激活码验证并拦截下载链接
 * 目标应用: wuaiwan signer (com.wuaiwan.signer)
 * 目标游戏: 我独自生活
 * 
 * 使用方法：
 * frida -U -f com.wuaiwan.signer -l hook_activation_bypass.js --no-pause
 */

console.log("=".repeat(70));
console.log("[*] 激活码绕过 & 下载链接拦截脚本");
console.log("[*] 目标: 我独自生活 (版本 2.0.9, 大小 101.09M)");
console.log("=".repeat(70) + "\n");

if (ObjC.available) {
    
    // ==================== 激活码验证绕过 ====================
    
    console.log("[+] 开始Hook激活码验证...\n");
    
    // Hook UIAlertController - 拦截激活码弹窗
    var UIAlertController = ObjC.classes.UIAlertController;
    if (UIAlertController) {
        console.log("[+] Hook UIAlertController");
        
        // Hook alertControllerWithTitle
        Interceptor.attach(UIAlertController['+ alertControllerWithTitle:message:preferredStyle:'].implementation, {
            onEnter: function(args) {
                var title = new ObjC.Object(args[2]).toString();
                var message = new ObjC.Object(args[3]).toString();
                
                console.log("\n[!] 检测到弹窗:");
                console.log("标题: " + title);
                console.log("消息: " + message);
                
                // 如果是激活码相关弹窗，记录下来
                if (title.indexOf('激活') !== -1 || message.indexOf('激活') !== -1) {
                    console.log("[!!!] 这是激活码弹窗!");
                }
            }
        });
    }
    
    // Hook UITextField - 拦截激活码输入
    var UITextField = ObjC.classes.UITextField;
    if (UITextField) {
        console.log("[+] Hook UITextField");
        
        // Hook setText
        Interceptor.attach(UITextField['- setText:'].implementation, {
            onEnter: function(args) {
                var text = new ObjC.Object(args[2]).toString();
                
                if (text && text.length > 0) {
                    console.log("\n[!] UITextField输入: " + text);
                }
            }
        });
        
        // Hook text属性getter
        Interceptor.attach(UITextField['- text'].implementation, {
            onLeave: function(retval) {
                if (retval && !retval.isNull()) {
                    var text = new ObjC.Object(retval).toString();
                    if (text && text.length > 0) {
                        console.log("[!] UITextField读取: " + text);
                    }
                }
            }
        });
    }
    
    // Hook UIButton - 拦截"激活"按钮点击
    var UIButton = ObjC.classes.UIButton;
    if (UIButton) {
        console.log("[+] Hook UIButton");
        
        // Hook sendActionsForControlEvents
        Interceptor.attach(UIButton['- sendActionsForControlEvents:'].implementation, {
            onEnter: function(args) {
                var button = new ObjC.Object(args[0]);
                var title = button.currentTitle();
                
                if (title && !title.isNull()) {
                    var titleStr = title.toString();
                    console.log("\n[!] 按钮点击: " + titleStr);
                    
                    if (titleStr.indexOf('激活') !== -1 || 
                        titleStr.indexOf('下载') !== -1 ||
                        titleStr.indexOf('安装') !== -1) {
                        console.log("[!!!] 关键按钮被点击!");
                    }
                }
            }
        });
    }
    
    // ==================== 网络请求拦截 ====================
    
    console.log("\n[+] 开始Hook网络请求...\n");
    
    // Hook NSURLSession - 拦截激活验证和下载请求
    var NSURLSession = ObjC.classes.NSURLSession;
    if (NSURLSession) {
        console.log("[+] Hook NSURLSession");
        
        // Hook dataTaskWithRequest
        Interceptor.attach(NSURLSession['- dataTaskWithRequest:completionHandler:'].implementation, {
            onEnter: function(args) {
                var request = new ObjC.Object(args[2]);
                var url = request.URL().toString();
                var method = request.HTTPMethod().toString();
                
                console.log("\n" + "=".repeat(70));
                console.log("[!!!] 网络请求:");
                console.log("URL: " + url);
                console.log("Method: " + method);
                
                // 打印请求体（可能包含激活码）
                var body = request.HTTPBody();
                if (body && !body.isNull()) {
                    var bodyData = new ObjC.Object(body);
                    var bodyStr = Memory.readUtf8String(bodyData.bytes(), bodyData.length());
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
                console.log("=".repeat(70) + "\n");
            },
            onLeave: function(retval) {
                // 可以在这里修改返回值，绕过激活验证
            }
        });
        
        // Hook downloadTaskWithRequest - 拦截IPA下载
        Interceptor.attach(NSURLSession['- downloadTaskWithRequest:completionHandler:'].implementation, {
            onEnter: function(args) {
                var request = new ObjC.Object(args[2]);
                var url = request.URL().toString();
                
                console.log("\n" + "=".repeat(70));
                console.log("[!!!] 下载任务启动!");
                console.log("这可能是IPA下载链接:");
                console.log("URL: " + url);
                console.log("=".repeat(70) + "\n");
            }
        });
        
        // Hook downloadTaskWithURL
        if (NSURLSession['- downloadTaskWithURL:completionHandler:']) {
            Interceptor.attach(NSURLSession['- downloadTaskWithURL:completionHandler:'].implementation, {
                onEnter: function(args) {
                    var url = new ObjC.Object(args[2]).toString();
                    
                    console.log("\n" + "=".repeat(70));
                    console.log("[!!!] 简化下载任务:");
                    console.log("URL: " + url);
                    console.log("=".repeat(70) + "\n");
                }
            });
        }
    }
    
    // Hook NSURLConnection - 旧版网络API
    var NSURLConnection = ObjC.classes.NSURLConnection;
    if (NSURLConnection) {
        console.log("[+] Hook NSURLConnection");
        
        Interceptor.attach(NSURLConnection['+ sendSynchronousRequest:returningResponse:error:'].implementation, {
            onEnter: function(args) {
                var request = new ObjC.Object(args[2]);
                var url = request.URL().toString();
                
                console.log("\n[!] NSURLConnection同步请求:");
                console.log("URL: " + url);
            }
        });
    }
    
    // ==================== JSON解析拦截 ====================
    
    console.log("\n[+] 开始Hook JSON解析...\n");
    
    // Hook NSJSONSerialization - 拦截服务器响应
    var NSJSONSerialization = ObjC.classes.NSJSONSerialization;
    if (NSJSONSerialization) {
        console.log("[+] Hook NSJSONSerialization");
        
        // Hook JSONObjectWithData
        Interceptor.attach(NSJSONSerialization['+ JSONObjectWithData:options:error:'].implementation, {
            onEnter: function(args) {
                var data = new ObjC.Object(args[2]);
                if (data && !data.isNull()) {
                    var jsonStr = Memory.readUtf8String(data.bytes(), data.length());
                    
                    // 只打印包含关键信息的JSON
                    if (jsonStr.indexOf('激活') !== -1 || 
                        jsonStr.indexOf('download') !== -1 ||
                        jsonStr.indexOf('url') !== -1 ||
                        jsonStr.indexOf('ipa') !== -1 ||
                        jsonStr.indexOf('success') !== -1 ||
                        jsonStr.indexOf('code') !== -1) {
                        
                        console.log("\n" + "=".repeat(70));
                        console.log("[!!!] JSON响应:");
                        console.log(jsonStr);
                        console.log("=".repeat(70) + "\n");
                    }
                }
            },
            onLeave: function(retval) {
                // 可以在这里修改JSON响应，绕过激活验证
                // 例如：将 "success": false 改为 "success": true
            }
        });
    }
    
    // ==================== itms-services协议拦截 ====================
    
    console.log("\n[+] 开始Hook itms-services协议...\n");
    
    var UIApplication = ObjC.classes.UIApplication;
    if (UIApplication) {
        console.log("[+] Hook UIApplication");
        
        // iOS 10+
        if (UIApplication['- openURL:options:completionHandler:']) {
            Interceptor.attach(UIApplication['- openURL:options:completionHandler:'].implementation, {
                onEnter: function(args) {
                    var url = new ObjC.Object(args[2]).toString();
                    
                    console.log("\n" + "=".repeat(70));
                    console.log("[!!!] UIApplication openURL:");
                    console.log("URL: " + url);
                    
                    if (url.indexOf('itms-services') !== -1) {
                        console.log("\n[!!!] 发现itms-services协议!");
                        console.log("这是iOS应用安装协议!");
                        
                        // 解析manifest URL
                        var manifestMatch = url.match(/url=([^&]+)/);
                        if (manifestMatch) {
                            var manifestUrl = decodeURIComponent(manifestMatch[1]);
                            console.log("\n[!!!] Manifest URL:");
                            console.log(manifestUrl);
                            console.log("\n[*] 访问这个URL可以找到IPA真实下载地址!");
                        }
                    }
                    console.log("=".repeat(70) + "\n");
                }
            });
        }
    }
    
    // ==================== 字符串搜索 ====================
    
    console.log("\n[+] 开始Hook字符串操作...\n");
    
    // Hook NSString的stringWithFormat
    var NSString = ObjC.classes.NSString;
    if (NSString) {
        Interceptor.attach(NSString['+ stringWithFormat:'].implementation, {
            onLeave: function(retval) {
                if (retval && !retval.isNull()) {
                    var str = new ObjC.Object(retval).toString();
                    
                    if (str.indexOf('.ipa') !== -1 || 
                        str.indexOf('itms-services') !== -1 ||
                        str.indexOf('manifest') !== -1 ||
                        str.indexOf('download') !== -1) {
                        console.log("\n[!] 格式化字符串:");
                        console.log(str);
                    }
                }
            }
        });
    }
    
    // ==================== UserDefaults拦截 ====================
    
    console.log("\n[+] 开始Hook UserDefaults...\n");
    
    // Hook NSUserDefaults - 可能存储激活状态
    var NSUserDefaults = ObjC.classes.NSUserDefaults;
    if (NSUserDefaults) {
        console.log("[+] Hook NSUserDefaults");
        
        // Hook setBool
        Interceptor.attach(NSUserDefaults['- setBool:forKey:'].implementation, {
            onEnter: function(args) {
                var value = args[2];
                var key = new ObjC.Object(args[3]).toString();
                
                console.log("\n[!] UserDefaults setBool:");
                console.log("Key: " + key);
                console.log("Value: " + value);
                
                // 如果是激活状态相关的key，可以强制设置为true
                if (key.indexOf('activ') !== -1 || 
                    key.indexOf('valid') !== -1 ||
                    key.indexOf('auth') !== -1) {
                    console.log("[!!!] 这可能是激活状态标志!");
                }
            }
        });
        
        // Hook boolForKey
        Interceptor.attach(NSUserDefaults['- boolForKey:'].implementation, {
            onEnter: function(args) {
                var key = new ObjC.Object(args[2]).toString();
                
                if (key.indexOf('activ') !== -1 || 
                    key.indexOf('valid') !== -1 ||
                    key.indexOf('auth') !== -1) {
                    console.log("\n[!] UserDefaults读取激活状态:");
                    console.log("Key: " + key);
                }
            },
            onLeave: function(retval) {
                // 可以在这里强制返回true，绕过激活检查
                // retval.replace(1);
            }
        });
    }
    
    console.log("\n" + "=".repeat(70));
    console.log("[*] Hook设置完成!");
    console.log("[*] 请执行以下操作:");
    console.log("    1. 点击'激活'按钮");
    console.log("    2. 输入任意激活码（会被拦截）");
    console.log("    3. 观察控制台输出的网络请求");
    console.log("    4. 找到IPA下载链接或manifest URL");
    console.log("=".repeat(70) + "\n");
    
} else {
    console.log("[-] Objective-C运行时不可用");
}
