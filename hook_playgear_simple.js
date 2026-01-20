// 轻量级PlayGear Hook脚本
console.log("[+] 轻量级PlayGear分析脚本启动...");

// 延迟执行，避免超时
setTimeout(function() {
    console.log("[+] 开始分析PlayGear...");
    
    // 只做最基本的模块枚举
    findPlayGearModule();
    
}, 8000);

function findPlayGearModule() {
    console.log("\n=== 查找PlayGear模块 ===");
    
    try {
        var modules = Process.enumerateModules();
        console.log("[+] 总共找到 " + modules.length + " 个模块");
        
        modules.forEach(function(module) {
            // 只显示dylib文件
            if (module.name.endsWith(".dylib")) {
                console.log("[Dylib] " + module.name + " @ " + module.base);
                
                // 检查是否是PlayGear相关
                if (module.name.toLowerCase().includes("playgear") ||
                    module.name.toLowerCase().includes("gamefor") ||
                    module.name.toLowerCase().includes("cheat") ||
                    module.name === "GameForFun.dylib") {
                    
                    console.log("[🎯] 找到目标模块: " + module.name);
                    console.log("  基址: " + module.base);
                    console.log("  大小: " + module.size + " bytes");
                    console.log("  路径: " + module.path);
                    
                    // 简单分析这个模块
                    analyzeTargetModule(module);
                }
            }
        });
        
    } catch (e) {
        console.log("[-] 模块枚举失败: " + e);
    }
}

function analyzeTargetModule(module) {
    console.log("\n=== 分析目标模块: " + module.name + " ===");
    
    try {
        // 枚举导出函数
        var exports = module.enumerateExports();
        console.log("[导出] 共 " + exports.length + " 个导出函数");
        
        if (exports.length > 0) {
            console.log("[导出函数列表]:");
            exports.slice(0, 15).forEach(function(exp, index) {
                console.log("  " + (index + 1) + ". " + exp.name + " @ " + exp.address);
            });
            
            if (exports.length > 15) {
                console.log("  ... 还有 " + (exports.length - 15) + " 个函数");
            }
        }
        
        // 枚举导入函数
        var imports = module.enumerateImports();
        console.log("\n[导入] 共 " + imports.length + " 个导入函数");
        
        if (imports.length > 0) {
            console.log("[重要导入函数]:");
            var importantImports = imports.filter(function(imp) {
                return imp.name && (
                    imp.name.includes("NSUserDefaults") ||
                    imp.name.includes("setValue") ||
                    imp.name.includes("setInteger") ||
                    imp.name.includes("memcpy") ||
                    imp.name.includes("memmove")
                );
            });
            
            importantImports.slice(0, 10).forEach(function(imp, index) {
                console.log("  " + (index + 1) + ". " + imp.name + " from " + imp.module);
            });
        }
        
        // Hook关键函数
        hookKeyFunctions(module);
        
    } catch (e) {
        console.log("[-] 模块分析失败: " + e);
    }
}

function hookKeyFunctions(module) {
    console.log("\n=== Hook关键函数 ===");
    
    try {
        var exports = module.enumerateExports();
        
        exports.forEach(function(exp) {
            // 只Hook看起来重要的函数
            if (exp.name && (
                exp.name.toLowerCase().includes("set") ||
                exp.name.toLowerCase().includes("modify") ||
                exp.name.toLowerCase().includes("change") ||
                exp.name.toLowerCase().includes("update") ||
                exp.name.toLowerCase().includes("write") ||
                exp.name.toLowerCase().includes("money") ||
                exp.name.toLowerCase().includes("stamina") ||
                exp.name.toLowerCase().includes("health") ||
                exp.name.toLowerCase().includes("mood"))) {
                
                console.log("[🎯] Hook重要函数: " + exp.name);
                
                try {
                    Interceptor.attach(exp.address, {
                        onEnter: function(args) {
                            console.log("[🔧] " + exp.name + " 被调用");
                            
                            // 检查参数中是否有我们的目标数值
                            for (var i = 0; i < Math.min(args.length, 4); i++) {
                                try {
                                    var value = args[i].toInt32();
                                    if (value === 2100000000) {
                                        console.log("[💰] 参数 " + i + ": 金钱/体力值 " + value);
                                    } else if (value === 100000) {
                                        console.log("[❤️] 参数 " + i + ": 健康/心情值 " + value);
                                    }
                                } catch (e) {
                                    // 参数不是数值
                                }
                            }
                        }
                    });
                } catch (e) {
                    console.log("[-] Hook失败: " + exp.name);
                }
            }
        });
        
    } catch (e) {
        console.log("[-] 函数Hook失败: " + e);
    }
}

// 监控内存写入
setTimeout(function() {
    console.log("\n=== 监控内存写入 ===");
    
    try {
        var memcpy = Module.findExportByName(null, "memcpy");
        if (memcpy) {
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    
                    if (size === 4) {
                        try {
                            var value = Memory.readS32(args[1]);
                            
                            if (value === 2100000000 || value === 100000) {
                                console.log("[💾] 内存写入目标数值: " + value + " -> " + args[0]);
                                
                                // 简单的调用栈检查
                                var caller = this.returnAddress;
                                var module = Process.findModuleByAddress(caller);
                                if (module) {
                                    console.log("[来源] " + module.name);
                                    
                                    if (module.name.toLowerCase().includes("playgear") ||
                                        module.name.toLowerCase().includes("gamefor")) {
                                        console.log("[🎯] 来自PlayGear的写入!");
                                    }
                                }
                            }
                        } catch (e) {
                            // 忽略
                        }
                    }
                }
            });
            console.log("[+] memcpy监控已设置");
        }
        
    } catch (e) {
        console.log("[-] 内存监控失败: " + e);
    }
    
}, 10000);

console.log("[+] 轻量级PlayGear脚本加载完成");
console.log("[+] 请等待分析完成后操作修改器...");