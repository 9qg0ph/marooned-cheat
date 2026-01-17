// Frida Hook H5GG API - 抓取天选打工人脚本的调用
console.log("[*] Hook H5GG API 开始...");

if (ObjC.available) {
    console.log("[*] Objective-C Runtime 可用");
    
    // Hook WKWebView 的 evaluateJavaScript
    try {
        var WKWebView = ObjC.classes.WKWebView;
        if (WKWebView) {
            Interceptor.attach(WKWebView['- evaluateJavaScript:completionHandler:'].implementation, {
                onEnter: function(args) {
                    var jsCode = ObjC.Object(args[2]).toString();
                    if (jsCode.indexOf('h5gg') !== -1) {
                        console.log("\n[WKWebView] JavaScript 调用:");
                        console.log(jsCode);
                        console.log("---");
                    }
                }
            });
            console.log("[+] Hooked WKWebView evaluateJavaScript");
        }
    } catch(e) {
        console.log("[-] WKWebView hook failed: " + e);
    }
    
    // Hook UIWebView 的 stringByEvaluatingJavaScriptFromString
    try {
        var UIWebView = ObjC.classes.UIWebView;
        if (UIWebView) {
            Interceptor.attach(UIWebView['- stringByEvaluatingJavaScriptFromString:'].implementation, {
                onEnter: function(args) {
                    var jsCode = ObjC.Object(args[2]).toString();
                    if (jsCode.indexOf('h5gg') !== -1) {
                        console.log("\n[UIWebView] JavaScript 调用:");
                        console.log(jsCode);
                        console.log("---");
                    }
                }
            });
            console.log("[+] Hooked UIWebView stringByEvaluatingJavaScriptFromString");
        }
    } catch(e) {
        console.log("[-] UIWebView hook failed: " + e);
    }
}

// Hook vm_write (内存写入) - 最重要的部分
try {
    var vm_write = Module.findExportByName(null, 'vm_write');
    if (vm_write) {
        var writeCount = 0;
        Interceptor.attach(vm_write, {
            onEnter: function(args) {
                var address = args[1];
                var size = args[3];
                var data = args[2];
                
                // 只记录4字节的写入（I32类型）
                if (size.toInt32() === 4) {
                    try {
                        var value = data.readS32();
                        // 只记录大数值的写入（可能是金钱/金条修改）
                        if (value > 10000 || value === 999999 || value === 999999999) {
                            writeCount++;
                            console.log("\n[vm_write #" + writeCount + "] 内存写入:");
                            console.log("  地址: 0x" + address.toString(16));
                            console.log("  值: " + value);
                        }
                    } catch(e) {}
                }
            }
        });
        console.log("[+] Hooked vm_write");
    }
} catch(e) {
    console.log("[-] vm_write hook failed: " + e);
}

console.log("\n[*] Hook 完成！");
console.log("[*] 现在在游戏里运行那个作者的脚本，点击修改按钮...\n");
