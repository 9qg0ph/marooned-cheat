// Frida监控脚本 - wuaiwan signer行为分析
// 包名: com.wuaiwan.signer
// 目标: 深度分析应用行为，找到关键突破点

console.log("[📊] wuaiwan signer 行为监控脚本启动...");

var logData = {
    networkRequests: [],
    methodCalls: [],
    stringComparisons: [],
    fileOperations: [],
    uiEvents: []
};

Java.perform(function() {
    console.log("[+] 开始深度监控...");
    
    // 1. 监控所有网络活动
    monitorNetworkActivity();
    
    // 2. 监控方法调用
    monitorMethodCalls();
    
    // 3. 监控字符串操作
    monitorStringOperations();
    
    // 4. 监控文件操作
    monitorFileOperations();
    
    // 5. 监控UI事件
    monitorUIEvents();
    
    // 6. 监控WebView活动
    monitorWebViewActivity();
    
    // 定期输出分析报告
    setInterval(function() {
        generateAnalysisReport();
    }, 10000); // 每10秒输出一次报告
});

// 监控网络活动
function monitorNetworkActivity() {
    console.log("[🌐] 开始监控网络活动...");
    
    try {
        // Hook URL类
        var URL = Java.use("java.net.URL");
        URL.$init.overload('java.lang.String').implementation = function(spec) {
            console.log("[网络] 创建URL: " + spec);
            
            logData.networkRequests.push({
                type: "URL_CREATE",
                url: spec,
                timestamp: Date.now(),
                stack: Java.use("android.util.Log").getStackTraceString(Java.use("java.lang.Exception").$new())
            });
            
            return this.$init(spec);
        };
        
        // Hook HttpURLConnection
        var HttpURLConnection = Java.use("java.net.HttpURLConnection");
        
        HttpURLConnection.connect.implementation = function() {
            var url = this.getURL().toString();
            console.log("[网络] 连接: " + url);
            
            logData.networkRequests.push({
                type: "HTTP_CONNECT",
                url: url,
                method: this.getRequestMethod(),
                timestamp: Date.now()
            });
            
            return this.connect();
        };
        
        HttpURLConnection.getResponseCode.implementation = function() {
            var url = this.getURL().toString();
            var code = this.getResponseCode();
            
            console.log("[网络] 响应: " + url + " -> " + code);
            
            logData.networkRequests.push({
                type: "HTTP_RESPONSE",
                url: url,
                responseCode: code,
                timestamp: Date.now()
            });
            
            return code;
        };
        
        // Hook OkHttp (如果存在)
        try {
            var OkHttpClient = Java.use("okhttp3.OkHttpClient");
            var Request = Java.use("okhttp3.Request");
            
            OkHttpClient.newCall.implementation = function(request) {
                var url = request.url().toString();
                console.log("[网络] OkHttp请求: " + url);
                
                logData.networkRequests.push({
                    type: "OKHTTP_REQUEST",
                    url: url,
                    headers: request.headers().toString(),
                    timestamp: Date.now()
                });
                
                return this.newCall(request);
            };
        } catch (e) {
            console.log("[信息] OkHttp不可用");
        }
        
        console.log("[+] 网络监控设置完成");
    } catch (e) {
        console.log("[-] 网络监控设置失败: " + e);
    }
}

// 监控方法调用
function monitorMethodCalls() {
    console.log("[🔍] 开始监控方法调用...");
    
    // 监控关键类的方法调用
    var keywordClasses = [
        "com.wuaiwan",
        "activate", "verify", "check", "license", "premium"
    ];
    
    Java.enumerateLoadedClasses({
        onMatch: function(className) {
            var shouldMonitor = keywordClasses.some(function(keyword) {
                return className.toLowerCase().includes(keyword.toLowerCase());
            });
            
            if (shouldMonitor) {
                try {
                    var clazz = Java.use(className);
                    var methods = clazz.class.getDeclaredMethods();
                    
                    methods.forEach(function(method) {
                        var methodName = method.getName();
                        
                        // 只监控可能重要的方法
                        if (methodName.length > 3 && !methodName.startsWith("get") && !methodName.startsWith("set")) {
                            try {
                                var originalMethod = clazz[methodName];
                                if (originalMethod) {
                                    originalMethod.implementation = function() {
                                        console.log("[方法] 调用: " + className + "." + methodName);
                                        
                                        logData.methodCalls.push({
                                            className: className,
                                            methodName: methodName,
                                            arguments: Array.prototype.slice.call(arguments),
                                            timestamp: Date.now()
                                        });
                                        
                                        var result = originalMethod.apply(this, arguments);
                                        
                                        console.log("[方法] 返回: " + className + "." + methodName + " -> " + result);
                                        
                                        return result;
                                    };
                                }
                            } catch (e) {
                                // 忽略Hook失败的方法
                            }
                        }
                    });
                } catch (e) {
                    // 忽略无法处理的类
                }
            }
        },
        onComplete: function() {
            console.log("[+] 方法调用监控设置完成");
        }
    });
}

// 监控字符串操作
function monitorStringOperations() {
    console.log("[🔤] 开始监控字符串操作...");
    
    try {
        var String = Java.use("java.lang.String");
        
        // Hook equals
        String.equals.implementation = function(other) {
            var result = this.equals(other);
            var thisStr = this.toString();
            var otherStr = other ? other.toString() : "null";
            
            // 记录可能重要的字符串比较
            if ((thisStr.length > 4 && thisStr.length < 100) && 
                (otherStr.length > 4 && otherStr.length < 100)) {
                
                console.log("[字符串] 比较: '" + thisStr + "' == '" + otherStr + "' -> " + result);
                
                logData.stringComparisons.push({
                    string1: thisStr,
                    string2: otherStr,
                    result: result,
                    timestamp: Date.now()
                });
            }
            
            return result;
        };
        
        // Hook contains
        String.contains.implementation = function(sequence) {
            var result = this.contains(sequence);
            var thisStr = this.toString();
            var seqStr = sequence.toString();
            
            if (thisStr.length > 10 && seqStr.length > 3) {
                console.log("[字符串] 包含: '" + thisStr + "'.contains('" + seqStr + "') -> " + result);
                
                logData.stringComparisons.push({
                    type: "contains",
                    string: thisStr,
                    sequence: seqStr,
                    result: result,
                    timestamp: Date.now()
                });
            }
            
            return result;
        };
        
        console.log("[+] 字符串操作监控设置完成");
    } catch (e) {
        console.log("[-] 字符串操作监控设置失败: " + e);
    }
}

// 监控文件操作
function monitorFileOperations() {
    console.log("[📁] 开始监控文件操作...");
    
    try {
        var File = Java.use("java.io.File");
        var FileInputStream = Java.use("java.io.FileInputStream");
        var FileOutputStream = Java.use("java.io.FileOutputStream");
        
        // Hook File构造
        File.$init.overload('java.lang.String').implementation = function(pathname) {
            console.log("[文件] 创建File对象: " + pathname);
            
            logData.fileOperations.push({
                type: "FILE_CREATE",
                path: pathname,
                timestamp: Date.now()
            });
            
            return this.$init(pathname);
        };
        
        // Hook exists
        File.exists.implementation = function() {
            var path = this.getAbsolutePath();
            var exists = this.exists();
            
            console.log("[文件] 检查存在: " + path + " -> " + exists);
            
            logData.fileOperations.push({
                type: "FILE_EXISTS",
                path: path,
                exists: exists,
                timestamp: Date.now()
            });
            
            return exists;
        };
        
        // Hook FileInputStream
        FileInputStream.$init.overload('java.io.File').implementation = function(file) {
            var path = file.getAbsolutePath();
            console.log("[文件] 读取文件: " + path);
            
            logData.fileOperations.push({
                type: "FILE_READ",
                path: path,
                timestamp: Date.now()
            });
            
            return this.$init(file);
        };
        
        console.log("[+] 文件操作监控设置完成");
    } catch (e) {
        console.log("[-] 文件操作监控设置失败: " + e);
    }
}

// 监控UI事件
function monitorUIEvents() {
    console.log("[🎨] 开始监控UI事件...");
    
    try {
        var View = Java.use("android.view.View");
        var Button = Java.use("android.widget.Button");
        var EditText = Java.use("android.widget.EditText");
        
        // Hook Button点击
        View.performClick.implementation = function() {
            console.log("[UI] 点击事件");
            
            try {
                var viewClass = this.getClass().getName();
                var text = "";
                
                if (viewClass.includes("Button")) {
                    text = this.getText().toString();
                }
                
                console.log("[UI] 点击: " + viewClass + " - " + text);
                
                logData.uiEvents.push({
                    type: "CLICK",
                    viewClass: viewClass,
                    text: text,
                    timestamp: Date.now()
                });
            } catch (e) {
                // 忽略错误
            }
            
            return this.performClick();
        };
        
        // Hook EditText文本变化
        EditText.setText.overload('java.lang.CharSequence').implementation = function(text) {
            var textStr = text ? text.toString() : "";
            console.log("[UI] EditText设置文本: " + textStr);
            
            logData.uiEvents.push({
                type: "TEXT_SET",
                text: textStr,
                timestamp: Date.now()
            });
            
            return this.setText(text);
        };
        
        console.log("[+] UI事件监控设置完成");
    } catch (e) {
        console.log("[-] UI事件监控设置失败: " + e);
    }
}

// 监控WebView活动
function monitorWebViewActivity() {
    console.log("[🌍] 开始监控WebView活动...");
    
    try {
        var WebView = Java.use("android.webkit.WebView");
        
        // Hook loadUrl
        WebView.loadUrl.overload('java.lang.String').implementation = function(url) {
            console.log("[WebView] 加载URL: " + url);
            
            logData.networkRequests.push({
                type: "WEBVIEW_LOAD",
                url: url,
                timestamp: Date.now()
            });
            
            return this.loadUrl(url);
        };
        
        // Hook evaluateJavascript
        WebView.evaluateJavascript.implementation = function(script, callback) {
            console.log("[WebView] 执行JavaScript: " + script.substring(0, 200) + "...");
            
            logData.methodCalls.push({
                type: "WEBVIEW_JS",
                script: script,
                timestamp: Date.now()
            });
            
            return this.evaluateJavascript(script, callback);
        };
        
        console.log("[+] WebView活动监控设置完成");
    } catch (e) {
        console.log("[-] WebView活动监控设置失败: " + e);
    }
}

// 生成分析报告
function generateAnalysisReport() {
    console.log("\n" + "=".repeat(60));
    console.log("📊 wuaiwan signer 行为分析报告");
    console.log("=".repeat(60));
    
    console.log("🌐 网络请求: " + logData.networkRequests.length + " 个");
    logData.networkRequests.slice(-5).forEach(function(req) {
        console.log("  - " + req.type + ": " + (req.url || req.method || ""));
    });
    
    console.log("\n🔍 方法调用: " + logData.methodCalls.length + " 个");
    logData.methodCalls.slice(-5).forEach(function(call) {
        console.log("  - " + call.className + "." + call.methodName);
    });
    
    console.log("\n🔤 字符串比较: " + logData.stringComparisons.length + " 个");
    logData.stringComparisons.slice(-3).forEach(function(comp) {
        if (comp.string1 && comp.string2) {
            console.log("  - '" + comp.string1.substring(0, 20) + "' == '" + comp.string2.substring(0, 20) + "' -> " + comp.result);
        }
    });
    
    console.log("\n📁 文件操作: " + logData.fileOperations.length + " 个");
    logData.fileOperations.slice(-3).forEach(function(op) {
        console.log("  - " + op.type + ": " + op.path);
    });
    
    console.log("\n🎨 UI事件: " + logData.uiEvents.length + " 个");
    logData.uiEvents.slice(-3).forEach(function(event) {
        console.log("  - " + event.type + ": " + (event.text || event.viewClass || ""));
    });
    
    // 分析可能的突破点
    console.log("\n🎯 可能的突破点:");
    
    // 检查激活相关的网络请求
    var activationRequests = logData.networkRequests.filter(function(req) {
        return req.url && (req.url.includes("activate") || req.url.includes("verify"));
    });
    if (activationRequests.length > 0) {
        console.log("  - 发现 " + activationRequests.length + " 个激活相关网络请求");
        activationRequests.forEach(function(req) {
            console.log("    * " + req.url);
        });
    }
    
    // 检查可疑的字符串比较
    var suspiciousComparisons = logData.stringComparisons.filter(function(comp) {
        return comp.string1 && (
            comp.string1.match(/^[A-Z0-9]{8,}$/) || 
            comp.string1.includes("activate") ||
            comp.string1.includes("premium")
        );
    });
    if (suspiciousComparisons.length > 0) {
        console.log("  - 发现 " + suspiciousComparisons.length + " 个可疑字符串比较");
    }
    
    // 检查激活相关的方法调用
    var activationMethods = logData.methodCalls.filter(function(call) {
        return call.methodName && (
            call.methodName.toLowerCase().includes("verify") ||
            call.methodName.toLowerCase().includes("activate") ||
            call.methodName.toLowerCase().includes("check")
        );
    });
    if (activationMethods.length > 0) {
        console.log("  - 发现 " + activationMethods.length + " 个激活相关方法调用");
        activationMethods.forEach(function(method) {
            console.log("    * " + method.className + "." + method.methodName);
        });
    }
    
    console.log("=".repeat(60) + "\n");
}

// 导出日志数据
function exportLogData() {
    var exportData = {
        timestamp: new Date().toISOString(),
        summary: {
            networkRequests: logData.networkRequests.length,
            methodCalls: logData.methodCalls.length,
            stringComparisons: logData.stringComparisons.length,
            fileOperations: logData.fileOperations.length,
            uiEvents: logData.uiEvents.length
        },
        data: logData
    };
    
    send({
        type: "analysis_report",
        data: exportData
    });
}

// 每30秒导出一次数据
setInterval(exportLogData, 30000);

console.log("[📊] 监控脚本加载完成，开始记录应用行为...");