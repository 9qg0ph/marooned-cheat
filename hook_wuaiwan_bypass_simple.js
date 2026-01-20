// Frida脚本 - 简化版wuaiwan signer激活码绕过
// 包名: com.wuaiwan.signer

console.log("[+] 启动wuaiwan signer激活码绕过脚本...");

Java.perform(function() {
    console.log("[+] Java环境就绪，开始Hook...");
    
    // 1. Hook所有可能的验证方法，强制返回成功
    hookAllVerificationMethods();
    
    // 2. Hook网络请求，拦截激活验证
    hookNetworkForActivation();
    
    // 3. Hook WebView JavaScript执行
    hookWebViewJavaScript();
    
    // 4. Hook存储，伪造激活状态
    hookStorageForActivation();
});

function hookAllVerificationMethods() {
    console.log("[+] Hook所有验证方法...");
    
    // 常见的验证方法名
    var verificationMethods = [
        "verify", "check", "validate", "authenticate", 
        "isActivated", "isVerified", "isLicensed", "isPremium",
        "checkActivation", "verifyCode", "validateCode"
    ];
    
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            try {
                var clazz = Java.use(className);
                var methods = clazz.class.getDeclaredMethods();
                
                methods.forEach(function(method) {
                    var methodName = method.getName();
                    
                    // 检查是否是验证相关方法
                    verificationMethods.forEach(function(vmName) {
                        if (methodName.toLowerCase().includes(vmName.toLowerCase())) {
                            console.log("[验证] 找到验证方法: " + className + "." + methodName);
                            
                            try {
                                // 尝试Hook这个方法
                                var originalMethod = clazz[methodName];
                                if (originalMethod) {
                                    originalMethod.implementation = function() {
                                        console.log("[🎯] 拦截验证方法: " + methodName);
                                        console.log("[✅] 强制返回验证成功");
                                        
                                        // 根据返回类型返回相应的成功值
                                        var returnType = method.getReturnType().getName();
                                        if (returnType === "boolean") {
                                            return true;
                                        } else if (returnType === "int") {
                                            return 1;
                                        } else if (returnType === "java.lang.String") {
                                            return "success";
                                        }
                                        
                                        return true;
                                    };
                                }
                            } catch (e) {
                                // 忽略Hook失败，继续尝试其他方法
                            }
                        }
                    });
                });
            } catch (e) {
                // 忽略无法处理的类
            }
        },
        onComplete: function() {
            console.log("[+] 验证方法Hook完成");
        }
    });
}

function hookNetworkForActivation() {
    console.log("[+] Hook网络请求...");
    
    try {
        // Hook HttpURLConnection
        var HttpURLConnection = Java.use("java.net.HttpURLConnection");
        
        HttpURLConnection.getResponseCode.implementation = function() {
            var url = this.getURL().toString();
            var originalCode = this.getResponseCode();
            
            console.log("[网络] 请求: " + url + " -> " + originalCode);
            
            // 如果是激活相关请求
            if (url.includes("activate") || 
                url.includes("verify") || 
                url.includes("check") ||
                url.includes("auth")) {
                
                console.log("[🎯] 拦截激活验证请求");
                console.log("[✅] 伪造成功响应");
                return 200; // 强制返回成功
            }
            
            return originalCode;
        };
        
        // Hook getInputStream 伪造响应内容
        HttpURLConnection.getInputStream.implementation = function() {
            var url = this.getURL().toString();
            
            if (url.includes("activate") || url.includes("verify")) {
                console.log("[🎯] 伪造激活验证响应内容");
                
                // 创建成功响应的JSON
                var successResponse = '{"status":"success","code":200,"message":"验证成功","data":{"activated":true,"premium":true}}';
                var ByteArrayInputStream = Java.use("java.io.ByteArrayInputStream");
                var bytes = Java.array('byte', successResponse.split('').map(function(c) {
                    return c.charCodeAt(0);
                }));
                
                return ByteArrayInputStream.$new(bytes);
            }
            
            return this.getInputStream();
        };
        
        console.log("[+] 网络Hook成功");
    } catch (e) {
        console.log("[-] 网络Hook失败: " + e);
    }
}

function hookWebViewJavaScript() {
    console.log("[+] Hook WebView JavaScript...");
    
    try {
        var WebView = Java.use("android.webkit.WebView");
        
        // Hook evaluateJavascript
        WebView.evaluateJavascript.implementation = function(script, callback) {
            console.log("[WebView] JavaScript: " + script.substring(0, 100) + "...");
            
            // 检查是否是激活相关的JavaScript
            if (script.includes("activate") || 
                script.includes("verify") || 
                script.includes("appInstall.postMessage")) {
                
                console.log("[🎯] 拦截激活相关JavaScript");
                
                // 如果是appInstall.postMessage调用，直接执行成功逻辑
                if (script.includes("appInstall.postMessage")) {
                    console.log("[✅] 绕过appInstall调用，直接触发下载");
                    
                    // 注入成功的JavaScript代码
                    var successScript = `
                        console.log('Frida: 绕过激活验证');
                        if (typeof window.install === 'function') {
                            window.install();
                        }
                        if (typeof window.downloadApp === 'function') {
                            window.downloadApp();
                        }
                    `;
                    
                    return this.evaluateJavascript(successScript, callback);
                }
            }
            
            return this.evaluateJavascript(script, callback);
        };
        
        console.log("[+] WebView JavaScript Hook成功");
    } catch (e) {
        console.log("[-] WebView JavaScript Hook失败: " + e);
    }
}

function hookStorageForActivation() {
    console.log("[+] Hook存储激活状态...");
    
    try {
        var SharedPreferences = Java.use("android.content.SharedPreferences");
        
        // Hook getBoolean
        SharedPreferences.getBoolean.overload('java.lang.String', 'boolean').implementation = function(key, defValue) {
            var result = this.getBoolean(key, defValue);
            
            console.log("[存储] 读取: " + key + " = " + result);
            
            // 激活相关的键强制返回true
            var activationKeys = [
                "activated", "verified", "licensed", "premium", 
                "is_activated", "is_verified", "is_premium",
                "activation_status", "license_valid"
            ];
            
            activationKeys.forEach(function(actKey) {
                if (key.toLowerCase().includes(actKey.toLowerCase())) {
                    console.log("[✅] 强制激活状态: " + key + " -> true");
                    return true;
                }
            });
            
            return result;
        };
        
        // Hook getString
        SharedPreferences.getString.overload('java.lang.String', 'java.lang.String').implementation = function(key, defValue) {
            var result = this.getString(key, defValue);
            
            console.log("[存储] 读取字符串: " + key + " = " + result);
            
            // 如果是激活码，返回一个假的有效码
            if (key.toLowerCase().includes("code") || 
                key.toLowerCase().includes("key") ||
                key.toLowerCase().includes("token")) {
                
                console.log("[✅] 伪造激活码: " + key);
                return "FRIDA_BYPASS_CODE_12345";
            }
            
            return result;
        };
        
        console.log("[+] 存储Hook成功");
    } catch (e) {
        console.log("[-] 存储Hook失败: " + e);
    }
}

// 监听应用启动
setTimeout(function() {
    console.log("[+] 延迟Hook应用特定方法...");
    
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            if (className.startsWith("com.wuaiwan")) {
                console.log("[应用] wuaiwan类: " + className);
                
                try {
                    var clazz = Java.use(className);
                    
                    // Hook所有public方法
                    var methods = clazz.class.getDeclaredMethods();
                    methods.forEach(function(method) {
                        var methodName = method.getName();
                        
                        if (methodName.includes("activate") || 
                            methodName.includes("verify") ||
                            methodName.includes("download") ||
                            methodName.includes("install")) {
                            
                            console.log("[应用] 关键方法: " + methodName);
                        }
                    });
                } catch (e) {
                    // 忽略错误
                }
            }
        },
        onComplete: function() {
            console.log("[+] 应用类扫描完成");
        }
    });
}, 3000);

console.log("[+] 激活码绕过脚本已加载，等待触发...");