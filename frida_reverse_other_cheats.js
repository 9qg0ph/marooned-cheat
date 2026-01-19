// 逆向分析其他修改器的实现方式
console.log("🕵️ 逆向分析脚本已加载 - 专门分析其他修改器");

// 全局变量
var g_detectedCheats = [];
var g_hookMethods = [];
var g_memoryPatches = [];

setTimeout(function() {
    console.log("🔍 开始逆向分析其他修改器...");
    
    // 1. 检测常见的 Hook 框架
    detectHookFrameworks();
    
    // 2. 监控动态库注入
    monitorDylibInjection();
    
    // 3. 监控 Method Swizzling
    monitorMethodSwizzling();
    
    // 4. 监控内存补丁
    monitorMemoryPatches();
    
    // 5. 监控 Objective-C 运行时操作
    monitorObjCRuntime();
    
    // 6. 检测修改器特征
    detectCheatSignatures();
    
    console.log("=".repeat(60));
    console.log("🕵️ 逆向分析系统已启动！");
    console.log("💡 现在运行其他作者的修改器，系统将分析其实现方式");
    console.log("=".repeat(60));
    
}, 1500);

// 检测常见的 Hook 框架
function detectHookFrameworks() {
    console.log("[检测] 扫描 Hook 框架...");
    
    var frameworks = [
        { name: "Substrate", symbols: ["MSHookFunction", "MSHookMessageEx", "_MSHookFunction"] },
        { name: "Fishhook", symbols: ["rebind_symbols", "rebind_symbols_image"] },
        { name: "Dobby", symbols: ["DobbyHook", "DobbyInstrument"] },
        { name: "Frida", symbols: ["frida_agent_main", "gum_init_embedded"] }
    ];
    
    frameworks.forEach(function(framework) {
        framework.symbols.forEach(function(symbol) {
            var addr = Module.findExportByName(null, symbol);
            if (addr) {
                console.log("🪝 [检测到] " + framework.name + " 框架 - 符号: " + symbol);
                
                // Hook 这些函数来监控使用
                try {
                    Interceptor.attach(addr, {
                        onEnter: function(args) {
                            console.log("🔧 [" + framework.name + "] " + symbol + " 被调用");
                            if (symbol === "MSHookFunction" || symbol === "DobbyHook") {
                                console.log("   目标函数: " + args[0]);
                                console.log("   替换函数: " + args[1]);
                            }
                        }
                    });
                } catch (e) {}
            }
        });
    });
}

// 监控动态库注入
function monitorDylibInjection() {
    console.log("[监控] 动态库注入...");
    
    try {
        // 监控 dlopen
        var dlopen = Module.findExportByName("libdyld.dylib", "dlopen");
        if (dlopen) {
            Interceptor.attach(dlopen, {
                onEnter: function(args) {
                    var path = Memory.readUtf8String(args[0]);
                    if (path && path.includes(".dylib")) {
                        console.log("📚 [动态库] 加载: " + path);
                        
                        // 检查是否是修改器相关的库
                        if (path.includes("cheat") || path.includes("hack") || 
                            path.includes("mod") || path.includes("trainer")) {
                            console.log("🚨 [修改器] 检测到可疑动态库: " + path);
                            g_detectedCheats.push({
                                type: "dylib",
                                path: path,
                                timestamp: new Date().toISOString()
                            });
                        }
                    }
                }
            });
        }
        
        // 监控 dlsym
        var dlsym = Module.findExportByName("libdyld.dylib", "dlsym");
        if (dlsym) {
            Interceptor.attach(dlsym, {
                onEnter: function(args) {
                    var symbol = Memory.readUtf8String(args[1]);
                    if (symbol && (symbol.includes("hook") || symbol.includes("patch") || 
                                  symbol.includes("cheat") || symbol.includes("setValue"))) {
                        console.log("🔍 [符号查找] 查找可疑符号: " + symbol);
                    }
                }
            });
        }
        
        console.log("✅ 动态库注入监控已启动");
    } catch (e) {
        console.log("❌ 动态库注入监控失败: " + e.message);
    }
}

// 监控 Method Swizzling
function monitorMethodSwizzling() {
    console.log("[监控] Method Swizzling...");
    
    try {
        // 监控 method_exchangeImplementations
        var exchangeImp = Module.findExportByName("libobjc.A.dylib", "method_exchangeImplementations");
        if (exchangeImp) {
            Interceptor.attach(exchangeImp, {
                onEnter: function(args) {
                    var method1 = args[0];
                    var method2 = args[1];
                    
                    console.log("🔄 [Swizzling] 交换方法实现");
                    console.log("   方法1: " + method1);
                    console.log("   方法2: " + method2);
                    
                    g_hookMethods.push({
                        type: "swizzling",
                        method1: method1.toString(),
                        method2: method2.toString(),
                        timestamp: new Date().toISOString()
                    });
                }
            });
        }
        
        // 监控 method_setImplementation
        var setImp = Module.findExportByName("libobjc.A.dylib", "method_setImplementation");
        if (setImp) {
            Interceptor.attach(setImp, {
                onEnter: function(args) {
                    var method = args[0];
                    var imp = args[1];
                    
                    console.log("🔧 [Hook] 设置方法实现");
                    console.log("   方法: " + method);
                    console.log("   新实现: " + imp);
                    
                    g_hookMethods.push({
                        type: "setImplementation",
                        method: method.toString(),
                        implementation: imp.toString(),
                        timestamp: new Date().toISOString()
                    });
                }
            });
        }
        
        console.log("✅ Method Swizzling 监控已启动");
    } catch (e) {
        console.log("❌ Method Swizzling 监控失败: " + e.message);
    }
}

// 监控内存补丁
function monitorMemoryPatches() {
    console.log("[监控] 内存补丁...");
    
    try {
        // 监控 mprotect (修改内存保护)
        var mprotect = Module.findExportByName("libsystem_kernel.dylib", "mprotect");
        if (mprotect) {
            Interceptor.attach(mprotect, {
                onEnter: function(args) {
                    var addr = args[0];
                    var size = args[1].toInt32();
                    var prot = args[2].toInt32();
                    
                    // 检查是否是可执行权限的修改
                    if (prot & 0x4) { // PROT_EXEC
                        console.log("🛡️ [内存保护] 修改为可执行: " + addr + " 大小: " + size);
                        
                        g_memoryPatches.push({
                            type: "mprotect",
                            address: addr.toString(),
                            size: size,
                            protection: prot,
                            timestamp: new Date().toISOString()
                        });
                    }
                }
            });
        }
        
        // 监控 vm_protect
        var vm_protect = Module.findExportByName("libsystem_kernel.dylib", "vm_protect");
        if (vm_protect) {
            Interceptor.attach(vm_protect, {
                onEnter: function(args) {
                    var task = args[0];
                    var addr = args[1];
                    var size = args[2].toInt32();
                    var set_max = args[3];
                    var new_prot = args[4].toInt32();
                    
                    console.log("🛡️ [虚拟内存] vm_protect: " + addr + " 大小: " + size + " 保护: " + new_prot);
                }
            });
        }
        
        console.log("✅ 内存补丁监控已启动");
    } catch (e) {
        console.log("❌ 内存补丁监控失败: " + e.message);
    }
}

// 监控 Objective-C 运行时操作
function monitorObjCRuntime() {
    console.log("[监控] Objective-C 运行时...");
    
    try {
        // 监控 class_addMethod
        var addMethod = Module.findExportByName("libobjc.A.dylib", "class_addMethod");
        if (addMethod) {
            Interceptor.attach(addMethod, {
                onEnter: function(args) {
                    var cls = args[0];
                    var sel = args[1];
                    var imp = args[2];
                    
                    console.log("➕ [运行时] 添加方法到类");
                    console.log("   类: " + ObjC.Object(cls));
                    console.log("   选择器: " + ObjC.selectorAsString(sel));
                }
            });
        }
        
        // 监控 objc_setAssociatedObject
        var setAssociated = Module.findExportByName("libobjc.A.dylib", "objc_setAssociatedObject");
        if (setAssociated) {
            Interceptor.attach(setAssociated, {
                onEnter: function(args) {
                    var object = args[0];
                    var key = args[1];
                    var value = args[2];
                    
                    console.log("🔗 [关联对象] 设置关联对象");
                    console.log("   对象: " + ObjC.Object(object));
                    console.log("   值: " + ObjC.Object(value));
                }
            });
        }
        
        console.log("✅ Objective-C 运行时监控已启动");
    } catch (e) {
        console.log("❌ Objective-C 运行时监控失败: " + e.message);
    }
}

// 检测修改器特征
function detectCheatSignatures() {
    console.log("[检测] 修改器特征...");
    
    // 检测常见的修改器字符串
    var cheatStrings = [
        "cheat", "hack", "trainer", "mod", "crack",
        "infinite", "unlimited", "999999", "21000000000",
        "setValue", "setInteger", "GameForFun", "FanhanGGEngine"
    ];
    
    // 扫描内存中的这些字符串
    Process.enumerateRanges('r--', {
        onMatch: function(range) {
            cheatStrings.forEach(function(str) {
                try {
                    Memory.scanSync(range.base, range.size, str).forEach(function(match) {
                        console.log("🔍 [特征检测] 找到可疑字符串 '" + str + "' 在: " + match.address);
                    });
                } catch (e) {}
            });
        },
        onComplete: function() {
            console.log("✅ 特征检测完成");
        }
    });
    
    // 检测可疑的类和方法
    if (ObjC.available) {
        var suspiciousClasses = [
            "FanhanGGEngine", "GameForFun", "CheatEngine", "HackTool"
        ];
        
        suspiciousClasses.forEach(function(className) {
            if (ObjC.classes[className]) {
                console.log("🚨 [类检测] 发现可疑类: " + className);
                
                // 列出该类的所有方法
                var cls = ObjC.classes[className];
                var methods = cls.$ownMethods;
                console.log("   方法列表:");
                methods.forEach(function(method) {
                    console.log("     " + method);
                });
            }
        });
    }
}

// 定期报告检测结果
setInterval(function() {
    if (g_detectedCheats.length > 0 || g_hookMethods.length > 0 || g_memoryPatches.length > 0) {
        console.log("\n" + "=".repeat(50));
        console.log("📊 检测报告 (" + new Date().toLocaleTimeString() + ")");
        console.log("=".repeat(50));
        
        if (g_detectedCheats.length > 0) {
            console.log("🚨 检测到的修改器:");
            g_detectedCheats.forEach(function(cheat, index) {
                console.log("  " + (index + 1) + ". " + cheat.type + ": " + cheat.path);
            });
        }
        
        if (g_hookMethods.length > 0) {
            console.log("🪝 检测到的 Hook 操作: " + g_hookMethods.length + " 个");
        }
        
        if (g_memoryPatches.length > 0) {
            console.log("🛡️ 检测到的内存补丁: " + g_memoryPatches.length + " 个");
        }
        
        console.log("=".repeat(50) + "\n");
    }
}, 30000); // 每30秒报告一次

console.log("📋 [提示] 逆向分析系统加载完成，等待初始化...");