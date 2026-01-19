// 专门监控别的作者修改器的工作方式
console.log("🕵️ 修改器监控脚本已加载");
console.log("💡 专门用来分析别的作者是如何实现修改的");

var targetCash = 2099999100; // 你的当前现金数值
var isMonitoring = true;

function log(msg) {
    console.log("[监控] " + msg);
}

setTimeout(function() {
    log("开始监控修改器行为...");
    
    // 1. 监控所有可能的Hook框架
    try {
        // 监控 MSHookFunction (Substrate/Cydia Substrate)
        var MSHookFunction = Module.findExportByName(null, "MSHookFunction");
        if (MSHookFunction) {
            Interceptor.attach(MSHookFunction, {
                onEnter: function(args) {
                    var symbol = args[0];
                    var replacement = args[1];
                    var original = args[2];
                    log("🪝 [Substrate] MSHookFunction 被调用:");
                    log("   目标函数: " + symbol);
                    log("   替换函数: " + replacement);
                    log("   原始函数: " + original);
                }
            });
            log("✅ Substrate监控已启动");
        }
        
        // 监控 fishhook
        var rebind_symbols = Module.findExportByName(null, "rebind_symbols");
        if (rebind_symbols) {
            Interceptor.attach(rebind_symbols, {
                onEnter: function(args) {
                    log("🪝 [fishhook] rebind_symbols 被调用");
                    try {
                        var rebindings = args[0];
                        var count = args[1].toInt32();
                        log("   重绑定数量: " + count);
                        
                        for (var i = 0; i < Math.min(count, 5); i++) {
                            var rebinding = rebindings.add(i * Process.pointerSize * 3);
                            var name = Memory.readUtf8String(Memory.readPointer(rebinding));
                            log("   重绑定函数: " + name);
                        }
                    } catch (e) {
                        log("   解析重绑定信息失败: " + e.message);
                    }
                }
            });
            log("✅ fishhook监控已启动");
        }
        
        // 监控 dlsym (动态符号查找)
        var dlsym = Module.findExportByName("libdyld.dylib", "dlsym");
        if (dlsym) {
            Interceptor.attach(dlsym, {
                onEnter: function(args) {
                    var handle = args[0];
                    var symbol = Memory.readUtf8String(args[1]);
                    if (symbol && (symbol.includes("integer") || symbol.includes("object") || 
                                  symbol.includes("NSUserDefaults") || symbol.includes("sqlite"))) {
                        log("🔍 [dlsym] 查找符号: " + symbol);
                    }
                }
            });
            log("✅ dlsym监控已启动");
        }
        
    } catch (e) {
        log("❌ Hook框架监控失败: " + e.message);
    }
    
    // 2. 监控动态库注入
    try {
        var dlopen = Module.findExportByName("libdyld.dylib", "dlopen");
        if (dlopen) {
            Interceptor.attach(dlopen, {
                onEnter: function(args) {
                    var path = Memory.readUtf8String(args[0]);
                    if (path && (path.includes("dylib") || path.includes("Cheat") || 
                                path.includes("Hook") || path.includes("Mod"))) {
                        log("📚 [动态库注入] dlopen: " + path);
                    }
                },
                onLeave: function(retval) {
                    if (!retval.isNull()) {
                        log("   ✅ 动态库加载成功");
                    }
                }
            });
            log("✅ 动态库监控已启动");
        }
        
        var dlclose = Module.findExportByName("libdyld.dylib", "dlclose");
        if (dlclose) {
            Interceptor.attach(dlclose, {
                onEnter: function(args) {
                    log("📚 [动态库卸载] dlclose 被调用");
                }
            });
        }
        
    } catch (e) {
        log("❌ 动态库监控失败: " + e.message);
    }
    
    // 3. 监控所有NSUserDefaults相关操作
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        if (NSUserDefaults) {
            // 监控 integerForKey
            var integerForKey = NSUserDefaults['- integerForKey:'];
            if (integerForKey) {
                Interceptor.attach(integerForKey.implementation, {
                    onEnter: function(args) {
                        this.key = ObjC.Object(args[2]).toString();
                        this.self = ObjC.Object(args[0]);
                    },
                    onLeave: function(retval) {
                        var value = retval.toInt32();
                        if (value === targetCash || value > 1000000) {
                            log("📖 [NSUserDefaults] integerForKey读取:");
                            log("   Key: " + this.key);
                            log("   Value: " + value);
                            log("   对象: " + this.self);
                        }
                    }
                });
            }
            
            // 监控 setInteger:forKey:
            var setIntegerForKey = NSUserDefaults['- setInteger:forKey:'];
            if (setIntegerForKey) {
                Interceptor.attach(setIntegerForKey.implementation, {
                    onEnter: function(args) {
                        var value = args[2].toInt32();
                        var key = ObjC.Object(args[3]).toString();
                        if (value > 1000000 || key.includes("cash") || key.includes("money")) {
                            log("✏️ [NSUserDefaults] setInteger写入:");
                            log("   Key: " + key);
                            log("   Value: " + value);
                            log("   🚨 这可能是修改器在写入数据！");
                        }
                    }
                });
            }
            
            // 监控 objectForKey
            var objectForKey = NSUserDefaults['- objectForKey:'];
            if (objectForKey) {
                Interceptor.attach(objectForKey.implementation, {
                    onEnter: function(args) {
                        this.key = ObjC.Object(args[2]).toString();
                    },
                    onLeave: function(retval) {
                        if (!retval.isNull()) {
                            var obj = ObjC.Object(retval);
                            if (obj.isKindOfClass_(ObjC.classes.NSNumber)) {
                                var value = obj.intValue();
                                if (value === targetCash || value > 1000000) {
                                    log("📖 [NSUserDefaults] objectForKey读取:");
                                    log("   Key: " + this.key);
                                    log("   Value: " + value);
                                }
                            } else if (obj.isKindOfClass_(ObjC.classes.NSString)) {
                                var str = obj.toString();
                                if (str.includes(targetCash.toString()) || str.includes("21000000000")) {
                                    log("📖 [NSUserDefaults] objectForKey读取字符串:");
                                    log("   Key: " + this.key);
                                    log("   Value: " + str);
                                }
                            }
                        }
                    }
                });
            }
            
            // 监控 setObject:forKey:
            var setObjectForKey = NSUserDefaults['- setObject:forKey:'];
            if (setObjectForKey) {
                Interceptor.attach(setObjectForKey.implementation, {
                    onEnter: function(args) {
                        var obj = ObjC.Object(args[2]);
                        var key = ObjC.Object(args[3]).toString();
                        
                        if (obj.isKindOfClass_(ObjC.classes.NSNumber)) {
                            var value = obj.intValue();
                            if (value > 1000000) {
                                log("✏️ [NSUserDefaults] setObject写入数字:");
                                log("   Key: " + key);
                                log("   Value: " + value);
                                log("   🚨 这可能是修改器在写入数据！");
                            }
                        } else if (obj.isKindOfClass_(ObjC.classes.NSString)) {
                            var str = obj.toString();
                            if (str.includes("21000000000") || str.includes(targetCash.toString())) {
                                log("✏️ [NSUserDefaults] setObject写入字符串:");
                                log("   Key: " + key);
                                log("   Value: " + str);
                                log("   🚨 这可能是修改器在写入数据！");
                            }
                        }
                    }
                });
            }
            
            log("✅ NSUserDefaults监控已启动");
        }
    } catch (e) {
        log("❌ NSUserDefaults监控失败: " + e.message);
    }
    
    // 4. 监控SQLite操作
    try {
        var sqlite3_exec = Module.findExportByName("libsqlite3.dylib", "sqlite3_exec");
        if (sqlite3_exec) {
            Interceptor.attach(sqlite3_exec, {
                onEnter: function(args) {
                    var sql = Memory.readUtf8String(args[1]);
                    if (sql && (sql.includes("UPDATE") || sql.includes("INSERT") || 
                               sql.includes(targetCash.toString()) || sql.includes("21000000000"))) {
                        log("🗄️ [SQLite] 执行SQL: " + sql);
                        log("   🚨 这可能是修改器在操作数据库！");
                    }
                }
            });
        }
        
        var sqlite3_prepare_v2 = Module.findExportByName("libsqlite3.dylib", "sqlite3_prepare_v2");
        if (sqlite3_prepare_v2) {
            Interceptor.attach(sqlite3_prepare_v2, {
                onEnter: function(args) {
                    var sql = Memory.readUtf8String(args[1]);
                    if (sql && (sql.includes("UPDATE") || sql.includes("INSERT") || 
                               sql.includes(targetCash.toString()) || sql.includes("21000000000"))) {
                        log("🗄️ [SQLite] 准备SQL: " + sql);
                    }
                }
            });
        }
        
        log("✅ SQLite监控已启动");
    } catch (e) {
        log("❌ SQLite监控失败: " + e.message);
    }
    
    // 5. 监控内存写入操作
    try {
        // 监控 memcpy
        var memcpy = Module.findExportByName("libsystem_c.dylib", "memcpy");
        if (memcpy) {
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    if (size === 4 || size === 8) { // 可能是数值
                        try {
                            var value = Memory.readU32(args[1]);
                            if (value === targetCash || value > 10000000) {
                                log("🧠 [内存] memcpy 复制大数值: " + value);
                                log("   目标地址: " + args[0]);
                                log("   源地址: " + args[1]);
                                log("   大小: " + size);
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        // 监控 memmove
        var memmove = Module.findExportByName("libsystem_c.dylib", "memmove");
        if (memmove) {
            Interceptor.attach(memmove, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    if (size === 4 || size === 8) {
                        try {
                            var value = Memory.readU32(args[1]);
                            if (value === targetCash || value > 10000000) {
                                log("🧠 [内存] memmove 移动大数值: " + value);
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        log("✅ 内存操作监控已启动");
    } catch (e) {
        log("❌ 内存操作监控失败: " + e.message);
    }
    
    // 6. 监控所有可能的修改器特征
    try {
        // 搜索包含修改器关键词的模块
        var modules = Process.enumerateModules();
        modules.forEach(function(module) {
            var name = module.name.toLowerCase();
            if (name.includes("cheat") || name.includes("hack") || name.includes("mod") || 
                name.includes("hook") || name.includes("tweak") || name.includes("inject")) {
                log("🎯 [发现可疑模块] " + module.name + " 基址: " + module.base);
                
                // 尝试Hook这个模块的导出函数
                try {
                    var exports = module.enumerateExports();
                    exports.forEach(function(exp) {
                        if (exp.name && (exp.name.includes("modify") || exp.name.includes("set") || 
                                        exp.name.includes("hook") || exp.name.includes("change"))) {
                            log("   发现可疑函数: " + exp.name);
                            
                            try {
                                Interceptor.attach(exp.address, {
                                    onEnter: function(args) {
                                        log("🚨 [修改器函数] " + exp.name + " 被调用！");
                                        for (var i = 0; i < Math.min(args.length, 3); i++) {
                                            try {
                                                log("     参数[" + i + "]: " + args[i]);
                                            } catch (e) {}
                                        }
                                    }
                                });
                            } catch (e) {}
                        }
                    });
                } catch (e) {}
            }
        });
        
        log("✅ 修改器模块监控已启动");
    } catch (e) {
        log("❌ 修改器模块监控失败: " + e.message);
    }
    
    log("=".repeat(60));
    log("✅ 修改器监控已全部启动！");
    log("💡 现在开启别的作者的修改器，应该能捕获到它的工作方式...");
    log("🎯 目标现金数值: " + targetCash);
    log("=".repeat(60));
    
}, 2000);

// 导出控制函数
this.updateTargetCash = function(value) {
    targetCash = value;
    log("更新目标现金数值为: " + value);
};

this.toggleMonitoring = function() {
    isMonitoring = !isMonitoring;
    log("监控状态: " + (isMonitoring ? "开启" : "关闭"));
};