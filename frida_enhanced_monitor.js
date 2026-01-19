// 增强监控脚本
console.log("🚀 增强监控脚本已加载");

setTimeout(function() {
    console.log("✅ 开始安装所有Hook...");
    
    // 1. 监控NSUserDefaults的所有方法
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        if (NSUserDefaults) {
            // setInteger:forKey:
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
            
            // setObject:forKey:
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
            
            // setBool:forKey:
            var setBool = NSUserDefaults['- setBool:forKey:'];
            if (setBool) {
                Interceptor.attach(setBool.implementation, {
                    onEnter: function(args) {
                        var value = args[2];
                        var key = ObjC.Object(args[3]).toString();
                        console.log("📝 [NSUserDefaults] setBool: " + value + " forKey: " + key);
                    }
                });
            }
            
            console.log("✅ NSUserDefaults 全方法监控已启动");
        }
    } catch (e) {
        console.log("❌ NSUserDefaults 监控失败: " + e.message);
    }
    
    // 2. 监控SQLite操作
    try {
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
        console.log("❌ SQLite 监控失败: " + e.message);
    }
    
    // 3. 监控文件写入
    try {
        var fwrite = Module.findExportByName("libsystem_c.dylib", "fwrite");
        if (fwrite) {
            Interceptor.attach(fwrite, {
                onEnter: function(args) {
                    var size = args[1].toInt32();
                    var count = args[2].toInt32();
                    var totalSize = size * count;
                    if (totalSize > 100 && totalSize < 10000) {
                        // 尝试读取写入的数据
                        try {
                            var data = Memory.readUtf8String(args[0], Math.min(totalSize, 200));
                            if (data && (data.includes("cash") || data.includes("money") || data.includes("现金") || 
                                        data.includes("energy") || data.includes("体力") || data.includes("health") || 
                                        data.includes("健康") || data.includes("mood") || data.includes("心情"))) {
                                console.log("📁 [File] 写入游戏数据: " + data.substring(0, 100));
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        console.log("✅ 文件写入监控已启动");
    } catch (e) {
        console.log("❌ 文件写入监控失败: " + e.message);
    }
    
    // 4. 监控内存写入
    try {
        var memcpy = Module.findExportByName("libsystem_c.dylib", "memcpy");
        if (memcpy) {
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    if (size >= 4 && size <= 8) {
                        try {
                            var value = Memory.readU32(args[1]);
                            // 检查是否是大数值（可能是游戏币等）
                            if (value > 1000000 && value < 100000000000) {
                                console.log("🧠 [Memory] 写入大数值: " + value + " (" + size + " bytes)");
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        console.log("✅ 内存写入监控已启动");
    } catch (e) {
        console.log("❌ 内存写入监控失败: " + e.message);
    }
    
    // 5. 监控所有包含"set"的方法调用
    try {
        var hookedMethods = 0;
        var classes = Object.keys(ObjC.classes);
        
        for (var i = 0; i < classes.length && hookedMethods < 20; i++) {
            var className = classes[i];
            if (className.includes("Game") || className.includes("Player") || className.includes("Data") || 
                className.includes("Manager") || className.includes("Controller")) {
                
                try {
                    var cls = ObjC.classes[className];
                    var methods = cls.$ownMethods;
                    
                    for (var j = 0; j < methods.length && hookedMethods < 20; j++) {
                        var method = methods[j];
                        if (method.includes("set") && (method.includes("Cash") || method.includes("Money") || 
                            method.includes("Energy") || method.includes("Health") || method.includes("Mood") ||
                            method.includes("Value") || method.includes("Amount"))) {
                            
                            console.log("🎯 [发现方法] " + className + " " + method);
                            
                            try {
                                Interceptor.attach(cls[method].implementation, {
                                    onEnter: function(args) {
                                        console.log("🔧 [方法调用] " + className + " " + method);
                                        if (args.length > 2) {
                                            try {
                                                var param = ObjC.Object(args[2]);
                                                console.log("   参数: " + param);
                                            } catch (e) {
                                                console.log("   参数: " + args[2]);
                                            }
                                        }
                                    }
                                });
                                hookedMethods++;
                            } catch (e) {}
                        }
                    }
                } catch (e) {}
            }
        }
        
        console.log("✅ Objective-C 方法监控已启动 (监控了 " + hookedMethods + " 个方法)");
    } catch (e) {
        console.log("❌ Objective-C 方法监控失败: " + e.message);
    }
    
    console.log("=".repeat(60));
    console.log("✅ 所有监控已启动！现在操作修改器...");
    console.log("=".repeat(60));
    
}, 2000);