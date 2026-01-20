// Frida终极脚本 - wuaiwan signer完全绕过
// 包名: com.wuaiwan.signer
// 目标: 完全绕过所有限制，直接获取IPA下载

console.log("[🚀] wuaiwan signer 终极绕过脚本启动...");

Java.perform(function() {
    console.log("[+] Java环境准备完成");
    
    // 延迟执行，确保应用完全加载
    setTimeout(function() {
        console.log("[+] 开始执行终极绕过策略...");
        
        // 1. 暴力Hook所有可能的验证
        bruteForceHookVerification();
        
        // 2. Hook UI相关，直接跳过激活界面
        hookUIComponents();
        
        // 3. Hook网络层，完全控制请求响应
        hookNetworkLayer();
        
        // 4. Hook WebView，注入绕过代码
        hookWebViewComplete();
        
        // 5. Hook文件系统，伪造激活文件
        hookFileSystem();
        
        // 6. Hook反射调用
        hookReflection();
        
        // 7. 监控所有字符串比较
        hookStringComparison();
        
    }, 1000);
});

// 暴力Hook所有验证相关方法
function bruteForceHookVerification() {
    console.log("[💪] 暴力Hook所有验证方法...");
    
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            try {
                var clazz = Java.use(className);
                var methods = clazz.class.getDeclaredMethods();
                
                methods.forEach(function(method) {
                    var methodName = method.getName();
                    var returnType = method.getReturnType().getName();
                    
                    // 如果方法名包含验证相关关键词且返回boolean
                    if (returnType === "boolean" && (
                        methodName.toLowerCase().includes("verify") ||
                        methodName.toLowerCase().includes("check") ||
                        methodName.toLowerCase().includes("valid") ||
                        methodName.toLowerCase().includes("auth") ||
                        methodName.toLowerCase().includes("activ") ||
                        methodName.toLowerCase().includes("licen") ||
                        methodName.toLowerCase().includes("premium") ||
                        methodName.toLowerCase().includes("vip") ||
                        methodName.toLowerCase().includes("unlock")
                    )) {
                        try {
                            console.log("[🎯] Hook验证方法: " + className + "." + methodName);
                            
                            clazz[methodName].implementation = function() {
                                console.log("[✅] 强制验证成功: " + methodName);
                                return true;
                            };
                        } catch (e) {
                            // 忽略Hook失败的方法
                        }
                    }
                });
            } catch (e) {
                // 忽略无法处理的类
            }
        },
        onComplete: function() {
            console.log("[+] 暴力Hook完成");
        }
    });
}

// Hook UI组件，直接跳过激活界面
function hookUIComponents() {
    console.log("[🎨] Hook UI组件...");
    
    try {
        // Hook Dialog
        var AlertDialog = Java.use("android.app.AlertDialog");
        var Dialog = Java.use("android.app.Dialog");
        
        // Hook AlertDialog.show
        AlertDialog.show.implementation = function() {
            console.log("[UI] AlertDialog.show被调用");
            
            // 检查对话框内容，如果是激活相关就不显示
            try {
                var message = this.getMessage();
                if (message && (
                    message.toString().includes("激活") ||
                    message.toString().includes("验证") ||
                    message.toString().includes("activate") ||
                    message.toString().includes("code")
                )) {
                    console.log("[🚫] 阻止激活对话框显示");
                    return; // 不显示对话框
                }
            } catch (e) {
                // 忽略错误
            }
            
            return this.show();
        };
        
        // Hook Activity启动
        var Activity = Java.use("android.app.Activity");
        Activity.startActivity.overload('android.content.Intent').implementation = function(intent) {
            var action = intent.getAction();
            var component = intent.getComponent();
            
            console.log("[UI] 启动Activity: " + (component ? component.getClassName() : action));
            
            // 如果是激活相关的Activity，跳过
            if (component && (
                component.getClassName().includes("Activ") ||
                component.getClassName().includes("Verify") ||
                component.getClassName().includes("License")
            )) {
                console.log("[🚫] 阻止激活Activity启动");
                return; // 不启动Activity
            }
            
            return this.startActivity(intent);
        };
        
        console.log("[+] UI组件Hook成功");
    } catch (e) {
        console.log("[-] UI组件Hook失败: " + e);
    }
}

// 完全控制网络层
function hookNetworkLayer() {
    console.log("[🌐] 完全控制网络层...");
    
    try {
        // Hook所有HTTP相关类
        var URL = Java.use("java.net.URL");
        var HttpURLConnection = Java.use("java.net.HttpURLConnection");
        var HttpsURLConnection = Java.use("javax.net.ssl.HttpsURLConnection");
        
        // Hook URL构造
        URL.$init.overload('java.lang.String').implementation = function(spec) {
            console.log("[网络] 创建URL: " + spec);
            
            // 如果是激活验证URL，替换为假的成功URL
            if (spec.includes("activate") || 
                spec.includes("verify") || 
                spec.includes("check") ||
                spec.includes("auth")) {
                
                console.log("[🔄] 重定向激活URL到本地成功响应");
                // 使用一个总是返回成功的URL
                spec = "http://127.0.0.1:1/success";
            }
            
            return this.$init(spec);
        };
        
        // Hook HttpURLConnection响应
        HttpURLConnection.getResponseCode.implementation = function() {
            var url = this.getURL().toString();
            var code = this.getResponseCode();
            
            console.log("[网络] 响应码: " + url + " -> " + code);
            
            // 所有激活相关请求都返回200
            if (url.includes("activate") || 
                url.includes("verify") || 
                url.includes("127.0.0.1")) {
                console.log("[✅] 强制返回成功响应码");
                return 200;
            }
            
            return code;
        };
        
        // Hook getInputStream，提供假的成功响应
        HttpURLConnection.getInputStream.implementation = function() {
            var url = this.getURL().toString();
            
            if (url.includes("activate") || 
                url.includes("verify") || 
                url.includes("127.0.0.1")) {
                
                console.log("[✅] 提供假的成功响应内容");
                
                var successJson = JSON.stringify({
                    "status": "success",
                    "code": 200,
                    "message": "验证成功",
                    "data": {
                        "activated": true,
                        "premium": true,
                        "vip": true,
                        "expires": "2099-12-31",
                        "token": "FRIDA_BYPASS_TOKEN_12345"
                    }
                });
                
                var ByteArrayInputStream = Java.use("java.io.ByteArrayInputStream");
                var bytes = Java.array('byte', successJson.split('').map(c => c.charCodeAt(0)));
                return ByteArrayInputStream.$new(bytes);
            }
            
            return this.getInputStream();
        };
        
        console.log("[+] 网络层Hook成功");
    } catch (e) {
        console.log("[-] 网络层Hook失败: " + e);
    }
}

// 完整Hook WebView
function hookWebViewComplete() {
    console.log("[🌍] 完整Hook WebView...");
    
    try {
        var WebView = Java.use("android.webkit.WebView");
        var WebViewClient = Java.use("android.webkit.WebViewClient");
        
        // Hook loadUrl
        WebView.loadUrl.overload('java.lang.String').implementation = function(url) {
            console.log("[WebView] 加载URL: " + url);
            
            // 注入绕过脚本
            var bypassScript = `
                javascript:(function(){
                    console.log('Frida: 注入绕过脚本');
                    
                    // 重写appInstall对象
                    if (typeof window.appInstall !== 'undefined') {
                        window.appInstall.postMessage = function(shortLink) {
                            console.log('Frida: 拦截appInstall.postMessage', shortLink);
                            
                            // 直接触发下载，跳过激活验证
                            if (typeof window.install === 'function') {
                                window.install();
                            }
                            
                            // 尝试直接构造下载链接
                            var possibleUrls = [
                                'https://app.ios80.com/download/' + shortLink + '.ipa',
                                'https://static.ios80.com/ipa/' + shortLink + '.ipa',
                                'https://files.ios80.com/' + shortLink + '.ipa'
                            ];
                            
                            possibleUrls.forEach(function(testUrl) {
                                console.log('Frida: 尝试下载URL:', testUrl);
                                var a = document.createElement('a');
                                a.href = testUrl;
                                a.download = shortLink + '.ipa';
                                a.click();
                            });
                            
                            return false;
                        };
                    }
                    
                    // 重写所有验证函数
                    ['verify', 'check', 'validate', 'isActivated'].forEach(function(funcName) {
                        if (typeof window[funcName] === 'function') {
                            window[funcName] = function() {
                                console.log('Frida: 绕过验证函数', funcName);
                                return true;
                            };
                        }
                    });
                    
                    // 自动点击下载按钮
                    setTimeout(function() {
                        var downloadBtns = document.querySelectorAll('button, a, [onclick]');
                        downloadBtns.forEach(function(btn) {
                            var text = btn.textContent || btn.innerText || '';
                            if (text.includes('下载') || text.includes('安装') || text.includes('install')) {
                                console.log('Frida: 找到下载按钮，自动点击');
                                btn.click();
                            }
                        });
                    }, 2000);
                })();
            `;
            
            // 如果是IPA下载页面，先加载绕过脚本
            if (url.includes("ios80.com") || url.includes("ipa")) {
                console.log("[🎯] 检测到IPA页面，注入绕过脚本");
                this.loadUrl(bypassScript);
                
                // 延迟加载原始URL
                var self = this;
                setTimeout(function() {
                    self.loadUrl(url);
                }, 500);
                return;
            }
            
            return this.loadUrl(url);
        };
        
        // Hook evaluateJavascript
        WebView.evaluateJavascript.implementation = function(script, callback) {
            console.log("[WebView] JavaScript: " + script.substring(0, 150) + "...");
            
            // 如果是激活相关脚本，替换为成功脚本
            if (script.includes("appInstall.postMessage") || 
                script.includes("activate") || 
                script.includes("verify")) {
                
                console.log("[🔄] 替换激活脚本为绕过脚本");
                
                var bypassScript = `
                    console.log('Frida: 执行绕过脚本');
                    
                    // 直接触发成功回调
                    if (typeof callback === 'function') {
                        callback('success');
                    }
                    
                    // 尝试直接下载
                    if (typeof window.location !== 'undefined') {
                        var shortLink = window.location.pathname.split('/')[1];
                        if (shortLink) {
                            window.location.href = 'https://app.ios80.com/download/' + shortLink + '.ipa';
                        }
                    }
                `;
                
                return this.evaluateJavascript(bypassScript, callback);
            }
            
            return this.evaluateJavascript(script, callback);
        };
        
        console.log("[+] WebView完整Hook成功");
    } catch (e) {
        console.log("[-] WebView Hook失败: " + e);
    }
}

// Hook文件系统，伪造激活文件
function hookFileSystem() {
    console.log("[📁] Hook文件系统...");
    
    try {
        var File = Java.use("java.io.File");
        var FileInputStream = Java.use("java.io.FileInputStream");
        
        // Hook File.exists
        File.exists.implementation = function() {
            var path = this.getAbsolutePath();
            var exists = this.exists();
            
            console.log("[文件] 检查文件存在: " + path + " -> " + exists);
            
            // 如果是激活相关文件，伪造存在
            if (path.includes("license") || 
                path.includes("activate") || 
                path.includes("premium") ||
                path.includes(".key") ||
                path.includes(".lic")) {
                
                console.log("[✅] 伪造激活文件存在");
                return true;
            }
            
            return exists;
        };
        
        console.log("[+] 文件系统Hook成功");
    } catch (e) {
        console.log("[-] 文件系统Hook失败: " + e);
    }
}

// Hook反射调用
function hookReflection() {
    console.log("[🔍] Hook反射调用...");
    
    try {
        var Method = Java.use("java.lang.reflect.Method");
        
        Method.invoke.overload('java.lang.Object', '[Ljava.lang.Object;').implementation = function(obj, args) {
            var methodName = this.getName();
            var className = this.getDeclaringClass().getName();
            
            console.log("[反射] 调用方法: " + className + "." + methodName);
            
            // 如果是验证相关的反射调用，返回成功
            if (methodName.toLowerCase().includes("verify") ||
                methodName.toLowerCase().includes("check") ||
                methodName.toLowerCase().includes("valid") ||
                methodName.toLowerCase().includes("activ")) {
                
                console.log("[✅] 反射验证方法返回成功");
                
                var returnType = this.getReturnType().getName();
                if (returnType === "boolean") {
                    return true;
                } else if (returnType === "int") {
                    return 1;
                } else if (returnType === "java.lang.String") {
                    return "success";
                }
            }
            
            return this.invoke(obj, args);
        };
        
        console.log("[+] 反射Hook成功");
    } catch (e) {
        console.log("[-] 反射Hook失败: " + e);
    }
}

// 监控字符串比较
function hookStringComparison() {
    console.log("[🔤] Hook字符串比较...");
    
    try {
        var String = Java.use("java.lang.String");
        
        // Hook equals
        String.equals.implementation = function(other) {
            var result = this.equals(other);
            var thisStr = this.toString();
            var otherStr = other ? other.toString() : "null";
            
            // 只记录可能的激活码比较
            if ((thisStr.length > 5 && thisStr.length < 50) || 
                (otherStr.length > 5 && otherStr.length < 50)) {
                
                if (thisStr.includes("activate") || 
                    otherStr.includes("activate") ||
                    thisStr.match(/^[A-Z0-9]{8,}$/) ||
                    otherStr.match(/^[A-Z0-9]{8,}$/)) {
                    
                    console.log("[🔤] 字符串比较: '" + thisStr + "' == '" + otherStr + "' -> " + result);
                    
                    // 如果看起来像激活码比较，强制返回true
                    if (thisStr.match(/^[A-Z0-9]{8,}$/) || otherStr.match(/^[A-Z0-9]{8,}$/)) {
                        console.log("[✅] 强制激活码比较成功");
                        return true;
                    }
                }
            }
            
            return result;
        };
        
        console.log("[+] 字符串比较Hook成功");
    } catch (e) {
        console.log("[-] 字符串比较Hook失败: " + e);
    }
}

// 监听应用生命周期事件
Java.perform(function() {
    try {
        var ActivityThread = Java.use("android.app.ActivityThread");
        
        ActivityThread.currentApplication.implementation = function() {
            var app = this.currentApplication();
            
            if (app) {
                var packageName = app.getPackageName();
                console.log("[生命周期] 当前应用: " + packageName);
                
                if (packageName === "com.wuaiwan.signer") {
                    console.log("[🎯] 目标应用已启动，执行最终绕过策略...");
                    
                    // 延迟执行最终策略
                    setTimeout(function() {
                        finalBypassStrategy();
                    }, 5000);
                }
            }
            
            return app;
        };
    } catch (e) {
        console.log("[-] 生命周期Hook失败: " + e);
    }
});

// 最终绕过策略
function finalBypassStrategy() {
    console.log("[🏁] 执行最终绕过策略...");
    
    // 枚举所有wuaiwan相关的类
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            if (className.startsWith("com.wuaiwan")) {
                console.log("[最终] wuaiwan类: " + className);
                
                try {
                    var clazz = Java.use(className);
                    
                    // 获取所有方法
                    var methods = clazz.class.getDeclaredMethods();
                    methods.forEach(function(method) {
                        var methodName = method.getName();
                        
                        // Hook所有可能相关的方法
                        if (methodName.includes("download") ||
                            methodName.includes("install") ||
                            methodName.includes("verify") ||
                            methodName.includes("activate") ||
                            methodName.includes("check")) {
                            
                            console.log("[最终] 关键方法: " + className + "." + methodName);
                            
                            try {
                                // 尝试Hook这个方法
                                var originalMethod = clazz[methodName];
                                if (originalMethod) {
                                    originalMethod.implementation = function() {
                                        console.log("[🎯] 最终拦截: " + methodName);
                                        
                                        // 如果是验证方法，返回成功
                                        if (methodName.includes("verify") || methodName.includes("check")) {
                                            console.log("[✅] 最终验证成功");
                                            return true;
                                        }
                                        
                                        // 如果是下载方法，尝试直接执行
                                        if (methodName.includes("download") || methodName.includes("install")) {
                                            console.log("[📥] 最终触发下载");
                                            
                                            // 尝试调用原方法
                                            try {
                                                return originalMethod.apply(this, arguments);
                                            } catch (e) {
                                                console.log("[📥] 原方法调用失败，返回成功");
                                                return true;
                                            }
                                        }
                                        
                                        // 其他方法正常执行
                                        return originalMethod.apply(this, arguments);
                                    };
                                }
                            } catch (e) {
                                // 忽略Hook失败
                            }
                        }
                    });
                } catch (e) {
                    // 忽略处理失败的类
                }
            }
        },
        onComplete: function() {
            console.log("[🏁] 最终绕过策略执行完成");
        }
    });
}

console.log("[🚀] 终极绕过脚本加载完成，等待应用启动...");