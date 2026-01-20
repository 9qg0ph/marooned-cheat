// Frida脚本 - 深度Hook wuaiwan signer应用
// 包名: com.wuaiwan.signer
// 目标: 绕过激活码验证，拦截IPA下载链接

console.log("[+] 开始Hook wuaiwan signer应用...");

// 等待应用启动
Java.perform(function() {
    console.log("[+] Java环境已准备就绪");
    
    // 1. Hook网络请求相关类
    hookNetworkRequests();
    
    // 2. Hook WebView相关
    hookWebView();
    
    // 3. Hook激活码验证
    hookActivationCode();
    
    // 4. Hook下载相关
    hookDownloadMethods();
    
    // 5. Hook JavaScript接口
    hookJavaScriptInterface();
    
    // 6. Hook SharedPreferences (可能存储激活状态)
    hookSharedPreferences();
    
    console.log("[+] 所有Hook已设置完成");
});

// Hook网络请求
function hookNetworkRequests() {
    console.log("[+] 开始Hook网络请求...");
    
    // Hook OkHttp
    try {
        var OkHttpClient = Java.use("okhttp3.OkHttpClient");
        var Request = Java.use("okhttp3.Request");
        var Response = Java.use("okhttp3.Response");
        
        // Hook OkHttpClient.newCall
        OkHttpClient.newCall.implementation = function(request) {
            var url = request.url().toString();
            console.log("[网络] OkHttp请求: " + url);
            
            // 检查是否是激活相关请求
            if (url.includes("activate") || url.includes("verify") || url.includes("check")) {
                console.log("[激活] 检测到激活相关请求: " + url);
            }
            
            // 检查是否是下载相关请求
            if (url.includes("download") || url.includes("install") || url.includes(".ipa")) {
                console.log("[下载] 检测到下载相关请求: " + url);
            }
            
            var call = this.newCall(request);
            return call;
        };
        
        console.log("[+] OkHttp Hook成功");
    } catch (e) {
        console.log("[-] OkHttp Hook失败: " + e);
    }
    
    // Hook HttpURLConnection
    try {
        var HttpURLConnection = Java.use("java.net.HttpURLConnection");
        
        HttpURLConnection.getResponseCode.implementation = function() {
            var url = this.getURL().toString();
            var responseCode = this.getResponseCode();
            
            console.log("[网络] HttpURLConnection: " + url + " -> " + responseCode);
            
            // 如果是激活验证请求且返回错误，伪造成功
            if ((url.includes("activate") || url.includes("verify")) && responseCode !== 200) {
                console.log("[激活] 伪造激活验证成功");
                return 200;
            }
            
            return responseCode;
        };
        
        console.log("[+] HttpURLConnection Hook成功");
    } catch (e) {
        console.log("[-] HttpURLConnection Hook失败: " + e);
    }
}

// Hook WebView
function hookWebView() {
    console.log("[+] 开始Hook WebView...");
    
    try {
        var WebView = Java.use("android.webkit.WebView");
        
        // Hook loadUrl
        WebView.loadUrl.overload('java.lang.String').implementation = function(url) {
            console.log("[WebView] 加载URL: " + url);
            
            // 检查是否是IPA下载页面
            if (url.includes("ios80.com") || url.includes("ipa")) {
                console.log("[下载] 检测到IPA相关页面: " + url);
            }
            
            return this.loadUrl(url);
        };
        
        // Hook evaluateJavascript
        WebView.evaluateJavascript.implementation = function(script, callback) {
            console.log("[WebView] 执行JavaScript: " + script.substring(0, 200));
            
            // 检查是否是激活相关的JavaScript
            if (script.includes("activate") || script.includes("verify") || script.includes("appInstall")) {
                console.log("[激活] 检测到激活相关JavaScript");
            }
            
            return this.evaluateJavascript(script, callback);
        };
        
        console.log("[+] WebView Hook成功");
    } catch (e) {
        console.log("[-] WebView Hook失败: " + e);
    }
}

// Hook激活码验证
function hookActivationCode() {
    console.log("[+] 开始Hook激活码验证...");
    
    // 尝试找到激活相关的类和方法
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            if (className.includes("activate") || 
                className.includes("verify") || 
                className.includes("license") ||
                className.includes("auth")) {
                
                console.log("[激活] 找到可能的激活类: " + className);
                
                try {
                    var clazz = Java.use(className);
                    var methods = clazz.class.getDeclaredMethods();
                    
                    methods.forEach(function(method) {
                        var methodName = method.getName();
                        console.log("[激活] 方法: " + className + "." + methodName);
                        
                        // Hook可能的验证方法
                        if (methodName.includes("verify") || 
                            methodName.includes("check") || 
                            methodName.includes("validate")) {
                            
                            try {
                                clazz[methodName].implementation = function() {
                                    console.log("[激活] 拦截验证方法: " + methodName);
                                    console.log("[激活] 返回验证成功");
                                    return true; // 强制返回验证成功
                                };
                            } catch (e) {
                                console.log("[-] Hook方法失败: " + methodName + " - " + e);
                            }
                        }
                    });
                } catch (e) {
                    console.log("[-] 处理激活类失败: " + e);
                }
            }
        },
        onComplete: function() {
            console.log("[+] 激活类扫描完成");
        }
    });
}

// Hook下载相关方法
function hookDownloadMethods() {
    console.log("[+] 开始Hook下载方法...");
    
    // Hook DownloadManager
    try {
        var DownloadManager = Java.use("android.app.DownloadManager");
        var DownloadManagerRequest = Java.use("android.app.DownloadManager$Request");
        
        DownloadManager.enqueue.implementation = function(request) {
            console.log("[下载] DownloadManager.enqueue被调用");
            
            // 尝试获取下载URL
            try {
                var uri = request.mUri.value;
                if (uri) {
                    console.log("[下载] 下载URL: " + uri.toString());
                    
                    // 如果是IPA文件，记录下来
                    if (uri.toString().includes(".ipa")) {
                        console.log("[🎉] 找到IPA下载链接: " + uri.toString());
                        
                        // 发送到日志或保存
                        send({
                            type: "ipa_url_found",
                            url: uri.toString(),
                            timestamp: new Date().toISOString()
                        });
                    }
                }
            } catch (e) {
                console.log("[-] 获取下载URL失败: " + e);
            }
            
            return this.enqueue(request);
        };
        
        console.log("[+] DownloadManager Hook成功");
    } catch (e) {
        console.log("[-] DownloadManager Hook失败: " + e);
    }
}

// Hook JavaScript接口
function hookJavaScriptInterface() {
    console.log("[+] 开始Hook JavaScript接口...");
    
    try {
        var WebView = Java.use("android.webkit.WebView");
        
        // Hook addJavascriptInterface
        WebView.addJavascriptInterface.implementation = function(obj, name) {
            console.log("[JS接口] 添加JavaScript接口: " + name);
            
            // 如果是appInstall相关接口，进行特殊处理
            if (name.includes("appInstall") || name.includes("install")) {
                console.log("[JS接口] 检测到安装相关接口: " + name);
                
                // 尝试Hook接口对象的方法
                try {
                    var objClass = obj.getClass();
                    var methods = objClass.getDeclaredMethods();
                    
                    methods.forEach(function(method) {
                        var methodName = method.getName();
                        console.log("[JS接口] 接口方法: " + methodName);
                        
                        if (methodName.includes("postMessage") || methodName.includes("install")) {
                            console.log("[JS接口] Hook关键方法: " + methodName);
                        }
                    });
                } catch (e) {
                    console.log("[-] Hook接口对象失败: " + e);
                }
            }
            
            return this.addJavascriptInterface(obj, name);
        };
        
        console.log("[+] JavaScript接口Hook成功");
    } catch (e) {
        console.log("[-] JavaScript接口Hook失败: " + e);
    }
}

// Hook SharedPreferences
function hookSharedPreferences() {
    console.log("[+] 开始Hook SharedPreferences...");
    
    try {
        var SharedPreferences = Java.use("android.content.SharedPreferences");
        var Editor = Java.use("android.content.SharedPreferences$Editor");
        
        // Hook getBoolean - 可能用于检查激活状态
        SharedPreferences.getBoolean.overload('java.lang.String', 'boolean').implementation = function(key, defValue) {
            var result = this.getBoolean(key, defValue);
            
            console.log("[存储] 读取布尔值: " + key + " = " + result);
            
            // 如果是激活相关的键，强制返回true
            if (key.includes("activate") || 
                key.includes("verified") || 
                key.includes("licensed") ||
                key.includes("premium")) {
                
                console.log("[激活] 强制激活状态为true: " + key);
                return true;
            }
            
            return result;
        };
        
        // Hook getString
        SharedPreferences.getString.overload('java.lang.String', 'java.lang.String').implementation = function(key, defValue) {
            var result = this.getString(key, defValue);
            
            console.log("[存储] 读取字符串: " + key + " = " + result);
            
            // 如果是激活码相关，可以伪造
            if (key.includes("code") || key.includes("key") || key.includes("token")) {
                console.log("[激活] 检测到激活码相关键: " + key);
            }
            
            return result;
        };
        
        console.log("[+] SharedPreferences Hook成功");
    } catch (e) {
        console.log("[-] SharedPreferences Hook失败: " + e);
    }
}

// 监听应用生命周期
Java.perform(function() {
    var ActivityThread = Java.use("android.app.ActivityThread");
    
    ActivityThread.currentApplication.implementation = function() {
        var app = this.currentApplication();
        
        if (app != null) {
            var packageName = app.getPackageName();
            if (packageName === "com.wuaiwan.signer") {
                console.log("[+] 目标应用已启动: " + packageName);
                
                // 延迟执行一些Hook，确保应用完全加载
                setTimeout(function() {
                    console.log("[+] 执行延迟Hook...");
                    hookAppSpecificMethods();
                }, 2000);
            }
        }
        
        return app;
    };
});

// Hook应用特定方法
function hookAppSpecificMethods() {
    console.log("[+] 开始Hook应用特定方法...");
    
    // 枚举所有已加载的类，寻找应用特定的类
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            // 只关注应用自己的类
            if (className.startsWith("com.wuaiwan") || 
                className.includes("signer") ||
                className.includes("download") ||
                className.includes("install")) {
                
                console.log("[应用] 找到应用类: " + className);
                
                try {
                    var clazz = Java.use(className);
                    var methods = clazz.class.getDeclaredMethods();
                    
                    methods.forEach(function(method) {
                        var methodName = method.getName();
                        
                        // Hook关键方法
                        if (methodName.includes("download") || 
                            methodName.includes("install") || 
                            methodName.includes("verify") ||
                            methodName.includes("check")) {
                            
                            console.log("[应用] 关键方法: " + className + "." + methodName);
                        }
                    });
                } catch (e) {
                    console.log("[-] 处理应用类失败: " + e);
                }
            }
        },
        onComplete: function() {
            console.log("[+] 应用类扫描完成");
        }
    });
}

console.log("[+] Frida脚本加载完成，等待应用启动...");