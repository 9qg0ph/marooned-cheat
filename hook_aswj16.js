// Hook ASWJGAMEPLUS - 查找Unity模块和IL2CPP函数
console.log("[*] 等待游戏加载...");

setTimeout(function() {
    console.log("[*] 开始查找Unity模块...");
    
    var aswjModule = Process.findModuleByName("ASWJGAMEPLUS.dylib");
    if (!aswjModule) {
        console.log("[-] 未找到 ASWJGAMEPLUS.dylib");
        return;
    }
    
    var base = aswjModule.base;
    console.log("[+] ASWJGAMEPLUS.dylib 基址: " + base);
    
    // 枚举所有模块，查找Unity相关的
    console.log("\n[*] 枚举所有模块:");
    var modules = Process.enumerateModules();
    var unityModule = null;
    
    modules.forEach(function(module) {
        console.log("  " + module.name + " @ " + module.base);
        
        // 查找Unity相关模块
        if (module.name.indexOf("Unity") !== -1 || 
            module.name.indexOf("libil2cpp") !== -1 ||
            module.name === "game.taptap.lantern.kbxx") {
            console.log("    [可能的Unity模块] " + module.name);
            
            // 检查是否有il2cpp导出
            var exports = module.enumerateExports();
            var hasIl2cpp = false;
            exports.forEach(function(exp) {
                if (exp.name.indexOf("il2cpp") !== -1) {
                    hasIl2cpp = true;
                }
            });
            
            if (hasIl2cpp) {
                console.log("    [确认Unity模块] " + module.name + " - 包含il2cpp导出");
                unityModule = module;
            }
        }
    });
    
    if (!unityModule) {
        console.log("[-] 未找到Unity模块");
        
        // 尝试直接查找il2cpp函数
        console.log("\n[*] 尝试直接查找il2cpp函数...");
        var il2cpp_set = Module.findExportByName(null, "il2cpp_field_static_set_value");
        if (il2cpp_set) {
            console.log("[+] 找到 il2cpp_field_static_set_value @ " + il2cpp_set);
        }
        
        var il2cpp_get = Module.findExportByName(null, "il2cpp_field_static_get_value");
        if (il2cpp_get) {
            console.log("[+] 找到 il2cpp_field_static_get_value @ " + il2cpp_get);
        }
        
        var il2cpp_class = Module.findExportByName(null, "il2cpp_class_from_name");
        if (il2cpp_class) {
            console.log("[+] 找到 il2cpp_class_from_name @ " + il2cpp_class);
        }
        
        var il2cpp_field = Module.findExportByName(null, "il2cpp_class_get_field_from_name");
        if (il2cpp_field) {
            console.log("[+] 找到 il2cpp_class_get_field_from_name @ " + il2cpp_field);
        }
        
        return;
    }
    
    console.log("\n[+] Unity模块: " + unityModule.name + " @ " + unityModule.base);
    
    // Hook il2cpp函数
    var il2cpp_set = Module.findExportByName(unityModule.name, "il2cpp_field_static_set_value");
    if (il2cpp_set) {
        Interceptor.attach(il2cpp_set, {
            onEnter: function(args) {
                var bt = Thread.backtrace(this.context, Backtracer.ACCURATE);
                var fromASWJ = false;
                for (var i = 0; i < bt.length; i++) {
                    var mod = Process.findModuleByAddress(bt[i]);
                    if (mod && mod.name === "ASWJGAMEPLUS.dylib") {
                        fromASWJ = true;
                        break;
                    }
                }
                
                if (fromASWJ) {
                    console.log("\n[il2cpp_field_static_set_value] 来自ASWJGAMEPLUS");
                    console.log("  field: " + args[0]);
                    console.log("  value_ptr: " + args[1]);
                    
                    try {
                        var valPtr = args[1];
                        console.log("  value (int): " + valPtr.readInt());
                        console.log("  value (float): " + valPtr.readFloat());
                    } catch(e) {}
                    
                    // 打印调用栈
                    console.log("  调用栈:");
                    for (var j = 0; j < Math.min(bt.length, 5); j++) {
                        var addr = bt[j];
                        var module = Process.findModuleByAddress(addr);
                        var moduleName = module ? module.name : "unknown";
                        var offset = module ? ptr(addr).sub(module.base) : "?";
                        console.log("    " + j + ": " + moduleName + " + 0x" + offset.toString(16));
                    }
                }
            }
        });
        console.log("[+] Hook il2cpp_field_static_set_value 成功");
    }
    
    // Hook shenling MyTitle
    if (ObjC.available) {
        var shenling = ObjC.classes.shenling;
        if (shenling) {
            Interceptor.attach(shenling['+ MyTitle:'].implementation, {
                onEnter: function(args) {
                    var title = new ObjC.Object(args[2]);
                    console.log("\n========== [功能触发] " + title + " ==========");
                }
            });
            console.log("[+] Hook shenling MyTitle: 成功");
        }
    }
    
    console.log("\n[*] 请操作'无限寿命'开关！");
}, 6000);