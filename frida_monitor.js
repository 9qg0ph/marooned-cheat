// 我独自生活 - 监控脚本
// 用于分析其他修改器的实现方式

console.log("🔍 监控脚本已加载 - 准备分析修改器实现方式");

// ==================== NSUserDefaults 监控 ====================
function monitorNSUserDefaults() {
    console.log("[监控] 开始监控 NSUserDefaults...");
    
    var NSUserDefaults = ObjC.classes.NSUserDefaults;
    if (!NSUserDefaults) {
        console.log("[错误] 找不到 NSUserDefaults");
        return;
    }
    
    // 监控 setInteger:forKey:
    var setInteger = NSUserDefaults['- setInteger:forKey:'];
    if (setInteger) {
        Interceptor.attach(setInteger.implementation, {
            onEnter: function(args) {
                var value = args[2].toInt32();
                var key = ObjC.Object(args[3]).toString();
                console.log("📝 [NSUserDefaults] setInteger: " + value + " forKey: " + key);
            }
        });
    }
    
    // 监控 setObject:forKey:
    var setObject = NSUserDefaults['- setObject:forKey:'];
    if (setObject) {
        Interceptor.attach(setObject.implementation, {
            onEnter: function(args) {
                var obj = ObjC.Object(args[2]);
                var key = ObjC.Object(args[3]).toString();
                console.log("📝 [NSUserDefaults] setObject: " + obj + " forKey: " + key);
            }
        });
    }
    
    // 监控 integerForKey:
    var integerForKey = NSUserDefaults['- integerForKey:'];
    if (integerForKey) {
        Interceptor.attach(integerForKey.implementation, {
            onEnter: function(args) {
                this.key = ObjC.Object(args[2]).toString();
            },
            onLeave: function(retval) {
                var value = retval.toInt32();
                if (value > 0) {
                    console.log("📖 [NSUserDefaults] integerForKey: " + this.key + " = " + value);
                }
            }
        });
    }
    
    // 监控 objectForKey:
    var objectForKey = NSUserDefaults['- objectForKey:'];
    if (objectForKey) {
        Interceptor.attach(objectForKey.implementation, {
            onEnter: function(args) {
                this.key = ObjC.Object(args[2]).toString();
            },
            onLeave: function(retval) {
                if (!retval.isNull()) {
                    var obj = ObjC.Object(retval);
                    console.log("📖 [NSUserDefaults] objectForKey: " + this.key + " = " + obj);
                }
            }
        });
    }
    
    console.log("✅ NSUserDefaults 监控已启动");
}

// ==================== SQLite 监控 ====================
function monitorSQLite() {
    console.log("[监控] 开始监控 SQLite...");
    
    try {
        // 监控 sqlite3_exec
        var sqlite3_exec = Module.findExportByName("libsqlite3.dylib", "sqlite3_exec");
        if (sqlite3_exec) {
            Interceptor.attach(sqlite3_exec, {
                onEnter: function(args) {
                    var sql = Memory.readUtf8String(args[1]);
                    if (sql && (sql.includes("UPDATE") || sql.includes("INSERT"))) {
                        console.log("💾 [SQLite] SQL: " + sql);
                    }
                }
            });
        }
        
        // 监控 sqlite3_bind_int
        var sqlite3_bind_int = Module.findExportByName("libsqlite3.dylib", "sqlite3_bind_int");
        if (sqlite3_bind_int) {
            Interceptor.attach(sqlite3_bind_int, {
                onEnter: function(args) {
                    var index = args[1].toInt32();
                    var value = args[2].toInt32();
                    if (value > 1000) {
                        console.log("💾 [SQLite] bind_int[" + index + "] = " + value);
                    }
                }
            });
        }
        
        console.log("✅ SQLite 监控已启动");
    } catch (e) {
        console.log("[警告] SQLite 监控失败: " + e.message);
    }
}

// ==================== 文件操作监控 ====================
function monitorFileOperations() {
    console.log("[监控] 开始监控文件操作...");
    
    try {
        // 监控 fopen
        var fopen = Module.findExportByName("libsystem_c.dylib", "fopen");
        if (fopen) {
            Interceptor.attach(fopen, {
                onEnter: function(args) {
                    var path = Memory.readUtf8String(args[0]);
                    var mode = Memory.readUtf8String(args[1]);
                    if (path && (path.includes(".plist") || path.includes(".sqlite") || path.includes(".es3"))) {
                        console.log("📁 [File] fopen: " + path + " mode: " + mode);
                    }
                }
            });
        }
        
        // 监控 fwrite
        var fwrite = Module.findExportByName("libsystem_c.dylib", "fwrite");
        if (fwrite) {
            Interceptor.attach(fwrite, {
                onEnter: function(args) {
                    var size = args[1].toInt32();
                    var count = args[2].toInt32();
                    if (size * count > 100) {
                        console.log("📁 [File] fwrite: " + (size * count) + " bytes");
                    }
                }
            });
        }
        
        console.log("✅ 文件操作监控已启动");
    } catch (e) {
        console.log("[警告] 文件操作监控失败: " + e.message);
    }
}

// ==================== 内存写入监控 ====================
function monitorMemoryWrites() {
    console.log("[监控] 开始监控内存写入...");
    
    try {
        // 监控 memcpy
        var memcpy = Module.findExportByName("libsystem_c.dylib", "memcpy");
        if (memcpy) {
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    if (size >= 4 && size <= 8) {
                        // 可能是int或long的写入
                        var value = Memory.readU32(args[1]);
                        if (value > 1000000 && value < 100000000000) {
                            console.log("🧠 [Memory] memcpy: " + value + " (" + size + " bytes)");
                        }
                    }
                }
            });
        }
        
        console.log("✅ 内存写入监控已启动");
    } catch (e) {
        console.log("[警告] 内存写入监控失败: " + e.message);
    }
}

// ==================== Objective-C 方法调用监控 ====================
function monitorObjCMethods() {
    console.log("[监控] 开始监控 Objective-C 方法...");
    
    // 监控所有包含"set"的方法调用
    var classes = Object.keys(ObjC.classes);
    var monitoredCount = 0;
    
    for (var i = 0; i < classes.length && monitoredCount < 50; i++) {
        var className = classes[i];
        if (className.includes("Player") || className.includes("Game") || className.includes("Data") || 
            className.includes("Save") || className.includes("Manager")) {
            
            try {
                var cls = ObjC.classes[className];
                var methods = cls.$ownMethods;
                
                for (var j = 0; j < methods.length; j++) {
                    var method = methods[j];
                    if (method.includes("set") && (method.includes("Cash") || method.includes("Money") || 
                        method.includes("Energy") || method.includes("Health") || method.includes("Mood"))) {
                        
                        console.log("🎯 [发现] " + className + " " + method);
                        
                        try {
                            Interceptor.attach(cls[method].implementation, {
                                onEnter: function(args) {
                                    console.log("🔧 [调用] " + className + " " + method);
                                    if (args.length > 2) {
                                        console.log("   参数: " + ObjC.Object(args[2]));
                                    }
                                }
                            });
                            monitoredCount++;
                        } catch (e) {}
                    }
                }
            } catch (e) {}
        }
    }
    
    console.log("✅ Objective-C 方法监控已启动 (监控了 " + monitoredCount + " 个方法)");
}

// ==================== 主函数 ====================
function main() {
    console.log("=".repeat(60));
    console.log("🔍 开始全面监控 - 分析修改器实现方式");
    console.log("=".repeat(60));
    
    setTimeout(function() {
        monitorNSUserDefaults();
        monitorSQLite();
        monitorFileOperations();
        monitorMemoryWrites();
        monitorObjCMethods();
        
        console.log("=".repeat(60));
        console.log("✅ 所有监控已启动！");
        console.log("💡 现在在手机上操作修改器，观察日志输出");
        console.log("=".repeat(60));
    }, 1000);
}

// 启动监控
main();
