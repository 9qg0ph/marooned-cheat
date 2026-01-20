// Frida脚本 - 绕过反调试保护
// Bundle ID: com.wuaiwan.signer

console.log("[+] 反调试绕过脚本启动...");

// 立即绕过反调试检测
function bypassAntiDebug() {
    console.log("[+] 绕过反调试检测...");
    
    // 1. Hook ptrace
    try {
        var ptrace = Module.findExportByName(null, "ptrace");
        if (ptrace) {
            Interceptor.attach(ptrace, {
                onEnter: function(args) {
                    console.log("[反调试] ptrace调用被拦截");
                    args[0] = ptr(0); // PT_TRACE_ME = 0，改为无害的调用
                }
            });
            console.log("[+] ptrace Hook成功");
        }
    } catch (e) {
        console.log("[-] ptrace Hook失败: " + e);
    }
    
    // 2. Hook sysctl
    try {
        var sysctl = Module.findExportByName(null, "sysctl");
        if (sysctl) {
            Interceptor.attach(sysctl, {
                onEnter: function(args) {
                    var name = Memory.readUtf8String(args[0]);
                    if (name && name.includes("kinfo_proc")) {
                        console.log("[反调试] sysctl kinfo_proc调用被拦截");
                    }
                },
                onLeave: function(retval) {
                    retval.replace(ptr(0)); // 返回成功
                }
            });
            console.log("[+] sysctl Hook成功");
        }
    } catch (e) {
        console.log("[-] sysctl Hook失败: " + e);
    }
    
    // 3. Hook dlopen检测
    try {
        var dlopen = Module.findExportByName(null, "dlopen");
        if (dlopen) {
            Interceptor.attach(dlopen, {
                onEnter: function(args) {
                    var path = Memory.readUtf8String(args[0]);
                    if (path && (path.includes("frida") || path.includes("substrate"))) {
                        console.log("[反调试] 阻止加载检测库: " + path);
                        args[0] = Memory.allocUtf8String("/dev/null");
                    }
                }
            });
            console.log("[+] dlopen Hook成功");
        }
    } catch (e) {
        console.log("[-] dlopen Hook失败: " + e);
    }
}

// 立即执行反调试绕过
bypassAntiDebug();

// 延迟执行主要Hook逻辑
setTimeout(function() {
    console.log("[+] 开始主要Hook逻辑...");
    
    // 简化的Hook，避免触发更多检测
    try {
        // Hook NSURLSession
        var NSURLSession = ObjC.classes.NSURLSession;
        if (NSURLSession) {
            console.log("[+] 找到NSURLSession");
        }
        
        // Hook WKWebView
        var WKWebView = ObjC.classes.WKWebView;
        if (WKWebView) {
            console.log("[+] 找到WKWebView");
        }
        
        console.log("[+] 基础Hook完成，应用应该可以正常运行");
        
    } catch (e) {
        console.log("[-] Hook失败: " + e);
    }
    
}, 3000);

console.log("[+] 反调试绕过脚本加载完成");