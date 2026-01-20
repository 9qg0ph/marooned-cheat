// 学习脚本 - 分析我独自生活游戏的修改方式
console.log("[+] 游戏分析学习脚本启动...");

// 延迟执行，避免触发反调试
setTimeout(function() {
    console.log("[+] 开始分析游戏结构...");
    
    // 1. 分析游戏类结构
    analyzeGameClasses();
    
    // 2. 监控内存读写
    monitorMemoryAccess();
    
    // 3. 监控存档操作
    monitorSaveOperations();
    
    // 4. 分析数值变化
    analyzeValueChanges();
    
}, 3000);

// 分析游戏类结构
function analyzeGameClasses() {
    console.log("\n=== 游戏类结构分析 ===");
    
    var gameClasses = [];
    
    for (var className in ObjC.classes) {
        // 查找可能的游戏相关类
        if (className.includes("Game") || 
            className.includes("Player") || 
            className.includes("Data") ||
            className.includes("Manager") ||
            className.includes("Controller") ||
            className.includes("Hezi") ||
            className.toLowerCase().includes("money") ||
            className.toLowerCase().includes("coin")) {
            
            gameClasses.push(className);
            console.log("[类] 游戏类: " + className);
            
            try {
                var clazz = ObjC.classes[className];
                var methods = clazz.$ownMethods;
                
                console.log("  方法数量: " + methods.length);
                
                // 显示前10个方法
                methods.slice(0, 10).forEach(function(methodName) {
                    console.log("    - " + methodName);
                });
                
                if (methods.length > 10) {
                    console.log("    ... 还有 " + (methods.length - 10) + " 个方法");
                }
                
            } catch (e) {
                console.log("  无法分析此类");
            }
        }
    }
    
    console.log("\n找到 " + gameClasses.length + " 个可能的游戏类");
}

// 监控内存访问
function monitorMemoryAccess() {
    console.log("\n=== 内存访问监控 ===");
    
    try {
        // Hook malloc来跟踪内存分配
        var malloc = Module.findExportByName(null, "malloc");
        if (malloc) {
            var mallocCount = 0;
            
            Interceptor.attach(malloc, {
                onEnter: function(args) {
                    this.size = args[0].toInt32();
                },
                onLeave: function(retval) {
                    mallocCount++;
                    
                    // 只记录可能存储游戏数据的内存分配
                    if (this.size >= 4 && this.size <= 64) {
                        if (mallocCount % 100 === 0) { // 每100次记录一次，避免刷屏
                            console.log("[内存] malloc: " + this.size + " bytes -> " + retval);
                        }
                    }
                }
            });
            
            console.log("[+] malloc监控已设置");
        }
        
        // Hook memcpy来监控内存复制
        var memcpy = Module.findExportByName(null, "memcpy");
        if (memcpy) {
            var memcpyCount = 0;
            
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    memcpyCount++;
                    
                    if (size === 4 && memcpyCount % 50 === 0) { // 4字节可能是int32
                        try {
                            var value = Memory.readS32(args[1]);
                            if (Math.abs(value) > 1000 && Math.abs(value) < 3000000000) {
                                console.log("[内存] memcpy int32: " + value + " -> " + args[0]);
                            }
                        } catch (e) {
                            // 忽略读取错误
                        }
                    }
                }
            });
            
            console.log("[+] memcpy监控已设置");
        }
        
    } catch (e) {
        console.log("[-] 内存监控设置失败: " + e);
    }
}

// 监控存档操作
function monitorSaveOperations() {
    console.log("\n=== 存档操作监控 ===");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        if (NSUserDefaults) {
            // 监控所有的set操作
            var setMethods = [
                '- setInteger:forKey:',
                '- setObject:forKey:',
                '- setBool:forKey:',
                '- setFloat:forKey:',
                '- setDouble:forKey:'
            ];
            
            setMethods.forEach(function(methodName) {
                try {
                    var method = NSUserDefaults[methodName];
                    if (method) {
                        Interceptor.attach(method.implementation, {
                            onEnter: function(args) {
                                var key = new ObjC.Object(args[3]).toString();
                                var value;
                                
                                if (methodName.includes('Integer')) {
                                    value = args[2].toInt32();
                                } else if (methodName.includes('Bool')) {
                                    value = args[2].toInt32() ? "YES" : "NO";
                                } else if (methodName.includes('Float')) {
                                    value = args[2]; // 需要特殊处理
                                } else if (methodName.includes('Object')) {
                                    try {
                                        var obj = new ObjC.Object(args[2]);
                                        value = obj.toString();
                                    } catch (e) {
                                        value = "Object";
                                    }
                                }
                                
                                console.log("[存档] " + methodName + " key: " + key + " value: " + value);
                                
                                // 特别关注可能的游戏数值键
                                if (key.toLowerCase().includes("money") ||
                                    key.toLowerCase().includes("coin") ||
                                    key.toLowerCase().includes("gold") ||
                                    key.toLowerCase().includes("stamina") ||
                                    key.toLowerCase().includes("health") ||
                                    key.toLowerCase().includes("mood") ||
                                    key.toLowerCase().includes("energy")) {
                                    
                                    console.log("[🎯] 重要游戏数值: " + key + " = " + value);
                                }
                            }
                        });
                    }
                } catch (e) {
                    // 方法不存在，忽略
                }
            });
            
            // 监控所有的get操作
            var getMethods = [
                '- integerForKey:',
                '- objectForKey:',
                '- boolForKey:',
                '- floatForKey:',
                '- doubleForKey:'
            ];
            
            getMethods.forEach(function(methodName) {
                try {
                    var method = NSUserDefaults[methodName];
                    if (method) {
                        Interceptor.attach(method.implementation, {
                            onEnter: function(args) {
                                var key = new ObjC.Object(args[2]).toString();
                                this.key = key;
                            },
                            onLeave: function(retval) {
                                var value;
                                
                                if (methodName.includes('integer')) {
                                    value = retval.toInt32();
                                } else if (methodName.includes('bool')) {
                                    value = retval.toInt32() ? "YES" : "NO";
                                } else if (methodName.includes('object')) {
                                    try {
                                        if (!retval.isNull()) {
                                            var obj = new ObjC.Object(retval);
                                            value = obj.toString();
                                        } else {
                                            value = "nil";
                                        }
                                    } catch (e) {
                                        value = "Object";
                                    }
                                }
                                
                                // 只记录重要的键
                                if (this.key && (
                                    this.key.toLowerCase().includes("money") ||
                                    this.key.toLowerCase().includes("coin") ||
                                    this.key.toLowerCase().includes("gold") ||
                                    this.key.toLowerCase().includes("stamina") ||
                                    this.key.toLowerCase().includes("health") ||
                                    this.key.toLowerCase().includes("mood") ||
                                    this.key.toLowerCase().includes("energy"))) {
                                    
                                    console.log("[📖] 读取游戏数值: " + this.key + " = " + value);
                                }
                            }
                        });
                    }
                } catch (e) {
                    // 方法不存在，忽略
                }
            });
            
            console.log("[+] NSUserDefaults监控已设置");
        }
        
    } catch (e) {
        console.log("[-] 存档监控设置失败: " + e);
    }
}

// 分析数值变化
function analyzeValueChanges() {
    console.log("\n=== 数值变化分析 ===");
    
    // 定期扫描内存中的数值
    var scanInterval = setInterval(function() {
        console.log("\n--- 内存扫描 " + new Date().toLocaleTimeString() + " ---");
        
        try {
            // 扫描堆内存寻找可能的游戏数值
            Process.enumerateRanges('rw-', {
                onMatch: function(range) {
                    // 只扫描较小的内存区域，避免性能问题
                    if (range.size > 0x1000 && range.size < 0x100000) {
                        scanRangeForGameValues(range);
                    }
                },
                onComplete: function() {
                    // 扫描完成
                }
            });
        } catch (e) {
            console.log("[-] 内存扫描失败: " + e);
        }
        
    }, 30000); // 每30秒扫描一次
    
    // 10分钟后停止扫描
    setTimeout(function() {
        clearInterval(scanInterval);
        console.log("[+] 停止定期扫描");
    }, 600000);
}

// 扫描内存范围寻找游戏数值
function scanRangeForGameValues(range) {
    try {
        // 只读取前4KB避免性能问题
        var scanSize = Math.min(range.size, 0x1000);
        var data = Memory.readByteArray(range.base, scanSize);
        var bytes = new Uint8Array(data);
        
        var foundValues = [];
        
        // 按4字节对齐扫描
        for (var i = 0; i < bytes.length - 4; i += 4) {
            var value = (bytes[i]) | (bytes[i+1] << 8) | (bytes[i+2] << 16) | (bytes[i+3] << 24);
            
            // 查找可能的游戏数值
            if (value > 1000 && value < 2200000000) {
                foundValues.push({
                    address: range.base.add(i),
                    value: value
                });
            }
        }
        
        // 只显示前5个找到的值，避免刷屏
        if (foundValues.length > 0) {
            console.log("[扫描] 在 " + range.base + " 找到 " + foundValues.length + " 个可能的数值:");
            foundValues.slice(0, 5).forEach(function(item) {
                console.log("  " + item.address + ": " + item.value);
            });
        }
        
    } catch (e) {
        // 内存读取失败，忽略
    }
}

console.log("[+] 学习脚本加载完成，开始分析游戏...");