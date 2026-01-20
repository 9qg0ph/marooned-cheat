// Frida脚本 - 我独自生活游戏修改器
// Bundle ID: com.Hezi.project1
// 目标: 修改游戏数值（金钱、体力、健康、心情）

console.log("[+] 我独自生活游戏修改器启动...");

// 游戏数值修改
var targetValues = {
    money: 2100000000,    // 21亿金钱
    stamina: 2100000000,  // 21亿体力  
    health: 100,          // 100健康
    mood: 100            // 100心情
};

// 延迟执行，等待游戏完全加载
setTimeout(function() {
    console.log("[+] 开始Hook游戏数值...");
    
    // Hook内存读写操作
    hookMemoryOperations();
    
    // Hook可能的数值设置方法
    hookValueSetters();
    
    // Hook NSUserDefaults存档
    hookGameSave();
    
    // 搜索和修改内存中的数值
    searchAndModifyValues();
    
}, 3000);

// Hook内存操作
function hookMemoryOperations() {
    console.log("[+] Hook内存操作...");
    
    try {
        // Hook malloc/free来跟踪内存分配
        var malloc = Module.findExportByName(null, "malloc");
        var free = Module.findExportByName(null, "free");
        
        if (malloc) {
            Interceptor.attach(malloc, {
                onEnter: function(args) {
                    this.size = args[0].toInt32();
                },
                onLeave: function(retval) {
                    if (this.size >= 4 && this.size <= 16) {
                        // 可能是游戏数值的内存分配
                        console.log("[内存] malloc分配: " + this.size + " bytes at " + retval);
                    }
                }
            });
        }
        
        // Hook memcpy来监控内存复制
        var memcpy = Module.findExportByName(null, "memcpy");
        if (memcpy) {
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    if (size == 4) { // int32大小
                        var value = Memory.readS32(args[1]);
                        
                        // 检查是否是我们关心的数值
                        if (Math.abs(value) > 1000000 && Math.abs(value) < 3000000000) {
                            console.log("[内存] memcpy发现大数值: " + value + " -> " + args[0]);
                            
                            // 如果是金钱或体力范围，替换为目标值
                            if (value > 1000000) {
                                Memory.writeS32(args[1], targetValues.money);
                                console.log("[✅] 替换为目标金钱值: " + targetValues.money);
                            }
                        }
                        
                        // 检查健康和心情数值
                        if (value >= 0 && value <= 100) {
                            console.log("[内存] 发现可能的健康/心情值: " + value);
                        }
                    }
                }
            });
        }
        
    } catch (e) {
        console.log("[-] 内存操作Hook失败: " + e);
    }
}

// Hook数值设置方法
function hookValueSetters() {
    console.log("[+] Hook数值设置方法...");
    
    // 搜索可能的游戏类
    for (var className in ObjC.classes) {
        if (className.includes("Game") || 
            className.includes("Player") || 
            className.includes("Data") ||
            className.includes("Manager") ||
            className.includes("Hezi")) {
            
            console.log("[游戏] 找到可能的游戏类: " + className);
            
            try {
                var clazz = ObjC.classes[className];
                var methods = clazz.$ownMethods;
                
                methods.forEach(function(methodName) {
                    // 查找设置数值的方法
                    if (methodName.toLowerCase().includes("money") ||
                        methodName.toLowerCase().includes("coin") ||
                        methodName.toLowerCase().includes("gold") ||
                        methodName.toLowerCase().includes("stamina") ||
                        methodName.toLowerCase().includes("health") ||
                        methodName.toLowerCase().includes("mood") ||
                        methodName.toLowerCase().includes("set") ||
                        methodName.toLowerCase().includes("update")) {
                        
                        console.log("[游戏] 关键方法: " + className + "." + methodName);
                        
                        try {
                            var method = clazz[methodName];
                            Interceptor.attach(method.implementation, {
                                onEnter: function(args) {
                                    console.log("[🎯] 调用数值方法: " + methodName);
                                    
                                    // 如果方法有参数，尝试修改
                                    if (args.length > 2) {
                                        var value = args[2];
                                        try {
                                            var intValue = value.toInt32();
                                            console.log("[数值] 原始值: " + intValue);
                                            
                                            // 根据数值范围判断类型并修改
                                            if (intValue > 1000000) {
                                                // 可能是金钱或体力
                                                args[2] = ptr(targetValues.money);
                                                console.log("[✅] 修改为目标金钱: " + targetValues.money);
                                            } else if (intValue >= 0 && intValue <= 100) {
                                                // 可能是健康或心情
                                                args[2] = ptr(100);
                                                console.log("[✅] 修改为满值: 100");
                                            }
                                        } catch (e) {
                                            // 不是数值参数，忽略
                                        }
                                    }
                                }
                            });
                        } catch (e) {
                            // Hook失败，忽略
                        }
                    }
                });
            } catch (e) {
                // 类处理失败，忽略
            }
        }
    }
}

// Hook游戏存档
function hookGameSave() {
    console.log("[+] Hook游戏存档...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        // Hook setInteger:forKey:
        var setIntegerForKey = NSUserDefaults['- setInteger:forKey:'];
        if (setIntegerForKey) {
            Interceptor.attach(setIntegerForKey.implementation, {
                onEnter: function(args) {
                    var value = args[2].toInt32();
                    var key = new ObjC.Object(args[3]).toString();
                    
                    console.log("[存档] 设置整数: " + key + " = " + value);
                    
                    // 检查是否是游戏数值的键
                    if (key.toLowerCase().includes("money") ||
                        key.toLowerCase().includes("coin") ||
                        key.toLowerCase().includes("gold") ||
                        key.toLowerCase().includes("cash")) {
                        
                        console.log("[✅] 修改金钱存档: " + key + " -> " + targetValues.money);
                        args[2] = ptr(targetValues.money);
                        
                    } else if (key.toLowerCase().includes("stamina") ||
                               key.toLowerCase().includes("energy")) {
                        
                        console.log("[✅] 修改体力存档: " + key + " -> " + targetValues.stamina);
                        args[2] = ptr(targetValues.stamina);
                        
                    } else if (key.toLowerCase().includes("health") ||
                               key.toLowerCase().includes("hp")) {
                        
                        console.log("[✅] 修改健康存档: " + key + " -> " + targetValues.health);
                        args[2] = ptr(targetValues.health);
                        
                    } else if (key.toLowerCase().includes("mood") ||
                               key.toLowerCase().includes("happy")) {
                        
                        console.log("[✅] 修改心情存档: " + key + " -> " + targetValues.mood);
                        args[2] = ptr(targetValues.mood);
                    }
                }
            });
        }
        
        // Hook setObject:forKey:
        var setObjectForKey = NSUserDefaults['- setObject:forKey:'];
        if (setObjectForKey) {
            Interceptor.attach(setObjectForKey.implementation, {
                onEnter: function(args) {
                    var obj = new ObjC.Object(args[2]);
                    var key = new ObjC.Object(args[3]).toString();
                    
                    console.log("[存档] 设置对象: " + key + " = " + obj);
                    
                    // 如果是数字对象，尝试修改
                    if (obj.isKindOfClass_(ObjC.classes.NSNumber)) {
                        var value = obj.intValue();
                        console.log("[存档] 数字对象值: " + value);
                        
                        if (key.toLowerCase().includes("money") && value != targetValues.money) {
                            var newNumber = ObjC.classes.NSNumber.numberWithInt_(targetValues.money);
                            args[2] = newNumber;
                            console.log("[✅] 修改金钱对象: " + targetValues.money);
                        }
                    }
                }
            });
        }
        
    } catch (e) {
        console.log("[-] 游戏存档Hook失败: " + e);
    }
}

// 搜索和修改内存中的数值
function searchAndModifyValues() {
    console.log("[+] 搜索内存中的游戏数值...");
    
    // 延迟执行内存搜索
    setTimeout(function() {
        try {
            // 枚举所有内存区域
            Process.enumerateRanges('rw-', {
                onMatch: function(range) {
                    // 只搜索堆内存
                    if (range.size > 0x1000 && range.size < 0x10000000) {
                        searchRangeForValues(range);
                    }
                },
                onComplete: function() {
                    console.log("[+] 内存搜索完成");
                }
            });
        } catch (e) {
            console.log("[-] 内存搜索失败: " + e);
        }
    }, 5000);
}

// 在内存范围中搜索数值
function searchRangeForValues(range) {
    try {
        var data = Memory.readByteArray(range.base, Math.min(range.size, 0x100000));
        var bytes = new Uint8Array(data);
        
        // 搜索可能的游戏数值
        for (var i = 0; i < bytes.length - 4; i += 4) {
            var value = (bytes[i]) | (bytes[i+1] << 8) | (bytes[i+2] << 16) | (bytes[i+3] << 24);
            
            // 检查是否是我们关心的数值范围
            if (value > 1000000 && value < 3000000000) {
                var addr = range.base.add(i);
                console.log("[内存] 找到大数值: " + value + " at " + addr);
                
                // 尝试修改为目标值
                try {
                    Memory.writeS32(addr, targetValues.money);
                    console.log("[✅] 修改内存数值: " + addr + " -> " + targetValues.money);
                } catch (e) {
                    // 内存不可写，忽略
                }
            }
            
            // 检查健康心情数值 (0-100)
            if (value >= 0 && value <= 100) {
                var addr = range.base.add(i);
                
                // 尝试修改为满值
                try {
                    Memory.writeS32(addr, 100);
                } catch (e) {
                    // 内存不可写，忽略
                }
            }
        }
    } catch (e) {
        // 内存读取失败，忽略
    }
}

console.log("[+] 我独自生活修改器加载完成，开始监控游戏数值...");