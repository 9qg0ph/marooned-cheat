// Hook PlayGearLib.dylib - 学习作者修改器的核心技术
console.log("[+] PlayGearLib.dylib Hook脚本启动...");
console.log("[+] 目标: 分析PlayGearLib.dylib的修改机制");

setTimeout(function() {
    console.log("[+] 开始分析PlayGearLib.dylib...");
    
    // 1. 查找PlayGearLib模块
    findPlayGearLibModule();
    
    // 2. Hook PlayGearLib的导出函数
    hookPlayGearLibExports();
    
    // 3. Hook PlayGearLib的内存操作
    hookPlayGearLibMemory();
    
    // 4. 监控PlayGearLib与游戏的交互
    monitorPlayGearLibInteraction();
    
}, 3000);

function findPlayGearLibModule() {
    console.log("\n=== 查找PlayGearLib模块 ===");
    
    try {
        // 枚举所有已加载的模块
        var modules = Process.enumerateModules();
        var playGearModule = null;
        
        modules.forEach(function(module) {
            console.log("[模块] " + module.name + " - " + module.base);
            
            if (module.name.toLowerCase().includes("playgear") ||
                module.name.toLowerCase().includes("gamefor") ||
                module.name.toLowerCase().includes("cheat") ||
                module.name.toLowerCase().includes("hack")) {
                
                console.log("[🎯] 找到可疑模块: " + module.name);
                console.log("  基址: " + module.base);
                console.log("  大小: " + module.size);
                console.log("  路径: " + module.path);
                
                playGearModule = module;
            }
        });
        
        if (playGearModule) {
            console.log("[✅] 找到PlayGear相关模块: " + playGearModule.name);
            analyzePlayGearModule(playGearModule);
        } else {
            console.log("[⚠️] 未找到PlayGear模块，可能使用了不同的名称");
            
            // 查找所有dylib文件
            modules.forEach(function(module) {
                if (module.name.endsWith(".dylib")) {
                    console.log("[Dylib] " + module.name + " - " + module.base);
                }
            });
        }
        
    } catch (e) {
        console.log("[-] 模块枚举失败: " + e);
    }
}

function analyzePlayGearModule(module) {
    console.log("\n=== 分析PlayGear模块 ===");
    
    try {
        // 枚举模块的导出函数
        var exports = module.enumerateExports();
        console.log("[导出] 找到 " + exports.length + " 个导出函数:");
        
        exports.forEach(function(exp, index) {
            if (index < 20) { // 只显示前20个
                console.log("  [" + index + "] " + exp.name + " @ " + exp.address);
                
                // Hook重要的导出函数
                if (exp.name.toLowerCase().includes("money") ||
                    exp.name.toLowerCase().includes("coin") ||
                    exp.name.toLowerCase().includes("gold") ||
                    exp.name.toLowerCase().includes("stamina") ||
                    exp.name.toLowerCase().includes("health") ||
                    exp.name.toLowerCase().includes("mood") ||
                    exp.name.toLowerCase().includes("set") ||
                    exp.name.toLowerCase().includes("modify") ||
                    exp.name.toLowerCase().includes("cheat") ||
                    exp.name.toLowerCase().includes("hack")) {
                    
                    console.log("[🎯] 重要函数: " + exp.name);
                    hookPlayGearFunction(exp.address, exp.name);
                }
            }
        });
        
        if (exports.length > 20) {
            console.log("  ... 还有 " + (exports.length - 20) + " 个导出函数");
        }
        
        // 枚举模块的导入函数
        var imports = module.enumerateImports();
        console.log("\n[导入] 找到 " + imports.length + " 个导入函数:");
        
        imports.slice(0, 10).forEach(function(imp, index) {
            console.log("  [" + index + "] " + imp.name + " from " + imp.module);
        });
        
    } catch (e) {
        console.log("[-] 模块分析失败: " + e);
    }
}

function hookPlayGearFunction(address, name) {
    try {
        Interceptor.attach(address, {
            onEnter: function(args) {
                console.log("[🔧] PlayGear函数调用: " + name);
                
                // 记录参数
                for (var i = 0; i < args.length && i < 4; i++) {
                    try {
                        var value = args[i].toInt32();
                        if (value === 2100000000 || value === 100000) {
                            console.log("[🎯] 参数 " + i + ": " + value + " (目标数值!)");
                        } else if (Math.abs(value) > 1000 && Math.abs(value) < 3000000000) {
                            console.log("[📊] 参数 " + i + ": " + value);
                        }
                    } catch (e) {
                        // 参数不是数值
                    }
                }
            },
            onLeave: function(retval) {
                try {
                    var value = retval.toInt32();
                    if (value === 2100000000 || value === 100000) {
                        console.log("[✅] " + name + " 返回目标数值: " + value);
                    }
                } catch (e) {
                    // 返回值不是数值
                }
            }
        });
        
        console.log("[+] Hook成功: " + name);
        
    } catch (e) {
        console.log("[-] Hook失败 " + name + ": " + e);
    }
}

function hookPlayGearLibExports() {
    console.log("\n=== Hook PlayGearLib导出函数 ===");
    
    try {
        // 尝试直接查找PlayGearLib的符号
        var playGearSymbols = [
            "setMoney", "getMoney", "modifyMoney",
            "setStamina", "getStamina", "modifyStamina", 
            "setHealth", "getHealth", "modifyHealth",
            "setMood", "getMood", "modifyMood",
            "setValue", "getValue", "modifyValue",
            "enableCheat", "disableCheat", "toggleCheat",
            "refreshValue", "updateValue", "writeValue"
        ];
        
        playGearSymbols.forEach(function(symbolName) {
            try {
                var address = Module.findExportByName("PlayGearLib.dylib", symbolName);
                if (address) {
                    console.log("[🎯] 找到PlayGear符号: " + symbolName + " @ " + address);
                    hookPlayGearFunction(address, symbolName);
                } else {
                    // 尝试其他可能的模块名
                    var altNames = ["PlayGearLib", "libPlayGear.dylib", "GameForFun.dylib"];
                    altNames.forEach(function(modName) {
                        var addr = Module.findExportByName(modName, symbolName);
                        if (addr) {
                            console.log("[🎯] 在 " + modName + " 找到: " + symbolName + " @ " + addr);
                            hookPlayGearFunction(addr, symbolName);
                        }
                    });
                }
            } catch (e) {
                // 符号不存在，继续
            }
        });
        
    } catch (e) {
        console.log("[-] PlayGearLib导出Hook失败: " + e);
    }
}

function hookPlayGearLibMemory() {
    console.log("\n=== Hook PlayGearLib内存操作 ===");
    
    try {
        // Hook所有模块的内存写入，特别关注PlayGear相关的
        var memcpy = Module.findExportByName(null, "memcpy");
        if (memcpy) {
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    
                    if (size === 4) { // int32
                        try {
                            var value = Memory.readS32(args[1]);
                            
                            if (value === 2100000000 || value === 100000) {
                                console.log("[💾] PlayGear内存写入: " + value + " -> " + args[0]);
                                
                                // 获取调用栈，看是否来自PlayGear
                                var backtrace = Thread.backtrace(this.context, Backtracer.ACCURATE);
                                var symbols = backtrace.map(DebugSymbol.fromAddress);
                                
                                var isFromPlayGear = false;
                                symbols.forEach(function(symbol) {
                                    if (symbol.moduleName && (
                                        symbol.moduleName.toLowerCase().includes("playgear") ||
                                        symbol.moduleName.toLowerCase().includes("gamefor"))) {
                                        isFromPlayGear = true;
                                    }
                                });
                                
                                if (isFromPlayGear) {
                                    console.log("[🎯] 来自PlayGear的内存写入!");
                                    console.log("[调用栈] " + symbols.slice(0, 3).join('\n'));
                                }
                            }
                        } catch (e) {
                            // 读取失败
                        }
                    }
                }
            });
        }
        
        // Hook memmove
        var memmove = Module.findExportByName(null, "memmove");
        if (memmove) {
            Interceptor.attach(memmove, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    
                    if (size === 4) {
                        try {
                            var value = Memory.readS32(args[1]);
                            
                            if (value === 2100000000 || value === 100000) {
                                console.log("[📝] PlayGear memmove: " + value + " -> " + args[0]);
                            }
                        } catch (e) {
                            // 忽略
                        }
                    }
                }
            });
        }
        
    } catch (e) {
        console.log("[-] PlayGear内存Hook失败: " + e);
    }
}

function monitorPlayGearLibInteraction() {
    console.log("\n=== 监控PlayGear与游戏交互 ===");
    
    try {
        // Hook NSUserDefaults，看PlayGear如何修改游戏存档
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        if (NSUserDefaults) {
            var setIntegerForKey = NSUserDefaults['- setInteger:forKey:'];
            if (setIntegerForKey) {
                Interceptor.attach(setIntegerForKey.implementation, {
                    onEnter: function(args) {
                        var value = args[2].toInt32();
                        var key = new ObjC.Object(args[3]).toString();
                        
                        if (value === 2100000000 || value === 100000) {
                            console.log("[💾] PlayGear修改存档: " + key + " = " + value);
                            
                            // 检查调用栈是否来自PlayGear
                            var backtrace = Thread.backtrace(this.context, Backtracer.ACCURATE);
                            var symbols = backtrace.map(DebugSymbol.fromAddress);
                            
                            var playGearCall = false;
                            symbols.forEach(function(symbol) {
                                if (symbol.moduleName && (
                                    symbol.moduleName.toLowerCase().includes("playgear") ||
                                    symbol.moduleName.toLowerCase().includes("gamefor"))) {
                                    playGearCall = true;
                                }
                            });
                            
                            if (playGearCall) {
                                console.log("[🎯] 确认来自PlayGear的存档修改!");
                                console.log("[存档键] " + key);
                                console.log("[存档值] " + value);
                                console.log("[调用栈] " + symbols.slice(0, 5).join('\n'));
                            }
                        }
                    }
                });
            }
        }
        
        // 监控PlayGear可能使用的其他API
        hookPlayGearAPIs();
        
    } catch (e) {
        console.log("[-] PlayGear交互监控失败: " + e);
    }
}

function hookPlayGearAPIs() {
    console.log("\n=== Hook PlayGear可能使用的API ===");
    
    try {
        // Hook dlopen，看PlayGear是否动态加载其他库
        var dlopen = Module.findExportByName(null, "dlopen");
        if (dlopen) {
            Interceptor.attach(dlopen, {
                onEnter: function(args) {
                    var path = Memory.readUtf8String(args[0]);
                    if (path && (path.includes("PlayGear") || path.includes("GameFor"))) {
                        console.log("[📚] PlayGear加载库: " + path);
                    }
                }
            });
        }
        
        // Hook dlsym，看PlayGear查找什么符号
        var dlsym = Module.findExportByName(null, "dlsym");
        if (dlsym) {
            Interceptor.attach(dlsym, {
                onEnter: function(args) {
                    var symbol = Memory.readUtf8String(args[1]);
                    if (symbol && (
                        symbol.toLowerCase().includes("money") ||
                        symbol.toLowerCase().includes("stamina") ||
                        symbol.toLowerCase().includes("health") ||
                        symbol.toLowerCase().includes("mood"))) {
                        
                        console.log("[🔍] PlayGear查找符号: " + symbol);
                    }
                }
            });
        }
        
    } catch (e) {
        console.log("[-] PlayGear API Hook失败: " + e);
    }
}

// 搜索PlayGear在内存中的特征
setTimeout(function() {
    console.log("\n=== 搜索PlayGear内存特征 ===");
    
    try {
        // 搜索包含"PlayGear"字符串的内存区域
        Process.enumerateRanges('r--', {
            onMatch: function(range) {
                try {
                    var data = Memory.readByteArray(range.base, Math.min(range.size, 0x10000));
                    var str = Memory.readUtf8String(range.base, Math.min(range.size, 0x10000));
                    
                    if (str && (str.includes("PlayGear") || str.includes("GameFor"))) {
                        console.log("[🎯] 找到PlayGear字符串: " + range.base);
                        console.log("  内容: " + str.substring(0, 200));
                    }
                } catch (e) {
                    // 内存读取失败，忽略
                }
            },
            onComplete: function() {
                console.log("[+] PlayGear内存搜索完成");
            }
        });
        
    } catch (e) {
        console.log("[-] PlayGear内存搜索失败: " + e);
    }
    
}, 5000);

console.log("[+] PlayGearLib Hook脚本加载完成");
console.log("[+] 现在请操作修改器开关，观察PlayGear的工作机制...");