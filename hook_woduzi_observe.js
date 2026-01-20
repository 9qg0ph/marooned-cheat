// 观察脚本 - 学习作者的修改方式
console.log("[+] 观察学习脚本启动...");
console.log("[+] 目标: 学习作者如何修改游戏数值");
console.log("[+] 当前状态: 金钱=2100000000, 体力=2100000000, 健康=100000, 心情=100000");

setTimeout(function() {
    console.log("[+] 开始观察游戏数据存储方式...");
    
    // 观察NSUserDefaults的读写
    observeUserDefaults();
    
    // 观察内存中的目标数值
    observeTargetValues();
    
}, 5000);

function observeUserDefaults() {
    console.log("\n=== 观察NSUserDefaults存储 ===");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        if (NSUserDefaults) {
            // 观察读取操作
            var integerForKey = NSUserDefaults['- integerForKey:'];
            if (integerForKey) {
                Interceptor.attach(integerForKey.implementation, {
                    onEnter: function(args) {
                        var key = new ObjC.Object(args[2]).toString();
                        this.key = key;
                    },
                    onLeave: function(retval) {
                        var value = retval.toInt32();
                        
                        // 检查是否读取到我们修改的数值
                        if (value === 2100000000) {
                            console.log("[🎯] 读取到金钱/体力: " + this.key + " = " + value);
                        } else if (value === 100000) {
                            console.log("[🎯] 读取到健康/心情: " + this.key + " = " + value);
                        } else if (value > 1000 && value < 3000000000) {
                            console.log("[📊] 其他数值: " + this.key + " = " + value);
                        }
                    }
                });
            }
            
            // 观察写入操作
            var setIntegerForKey = NSUserDefaults['- setInteger:forKey:'];
            if (setIntegerForKey) {
                Interceptor.attach(setIntegerForKey.implementation, {
                    onEnter: function(args) {
                        var value = args[2].toInt32();
                        var key = new ObjC.Object(args[3]).toString();
                        
                        console.log("[💾] 存储数值: " + key + " = " + value);
                        
                        // 特别关注我们的目标数值
                        if (value === 2100000000 || value === 100000) {
                            console.log("[🎯] 存储修改后的数值: " + key + " = " + value);
                        }
                    }
                });
            }
            
            // 观察对象存储
            var setObjectForKey = NSUserDefaults['- setObject:forKey:'];
            if (setObjectForKey) {
                Interceptor.attach(setObjectForKey.implementation, {
                    onEnter: function(args) {
                        var obj = new ObjC.Object(args[2]);
                        var key = new ObjC.Object(args[3]).toString();
                        
                        if (obj.isKindOfClass_(ObjC.classes.NSNumber)) {
                            var value = obj.intValue();
                            console.log("[💾] 存储数字对象: " + key + " = " + value);
                            
                            if (value === 2100000000 || value === 100000) {
                                console.log("[🎯] 存储修改后的对象: " + key + " = " + value);
                            }
                        }
                    }
                });
            }
            
            console.log("[+] NSUserDefaults观察已设置");
        }
        
    } catch (e) {
        console.log("[-] NSUserDefaults观察失败: " + e);
    }
}

function observeTargetValues() {
    console.log("\n=== 观察目标数值在内存中的位置 ===");
    
    // 搜索我们修改后的数值在内存中的位置
    setTimeout(function() {
        console.log("[+] 开始搜索修改后的数值...");
        
        var foundAddresses = {
            money: [],
            health: []
        };
        
        try {
            Process.enumerateRanges('rw-', {
                onMatch: function(range) {
                    // 搜索较小的内存区域
                    if (range.size > 0x1000 && range.size < 0x1000000) {
                        searchInRange(range, foundAddresses);
                    }
                },
                onComplete: function() {
                    console.log("\n=== 搜索结果 ===");
                    console.log("找到金钱/体力地址: " + foundAddresses.money.length + " 个");
                    console.log("找到健康/心情地址: " + foundAddresses.health.length + " 个");
                    
                    // 显示前几个地址
                    foundAddresses.money.slice(0, 5).forEach(function(addr, index) {
                        console.log("  金钱/体力 " + (index + 1) + ": " + addr);
                    });
                    
                    foundAddresses.health.slice(0, 5).forEach(function(addr, index) {
                        console.log("  健康/心情 " + (index + 1) + ": " + addr);
                    });
                    
                    // 监控这些地址的变化
                    if (foundAddresses.money.length > 0) {
                        monitorAddressChanges(foundAddresses.money[0], "金钱/体力");
                    }
                    if (foundAddresses.health.length > 0) {
                        monitorAddressChanges(foundAddresses.health[0], "健康/心情");
                    }
                }
            });
        } catch (e) {
            console.log("[-] 内存搜索失败: " + e);
        }
        
    }, 3000);
}

function searchInRange(range, foundAddresses) {
    try {
        var scanSize = Math.min(range.size, 0x10000); // 最多扫描64KB
        var data = Memory.readByteArray(range.base, scanSize);
        var bytes = new Uint8Array(data);
        
        // 搜索我们的目标数值
        for (var i = 0; i < bytes.length - 4; i += 4) {
            var value = (bytes[i]) | (bytes[i+1] << 8) | (bytes[i+2] << 16) | (bytes[i+3] << 24);
            
            if (value === 2100000000) {
                foundAddresses.money.push(range.base.add(i));
            } else if (value === 100000) {
                foundAddresses.health.push(range.base.add(i));
            }
        }
        
    } catch (e) {
        // 内存读取失败，忽略
    }
}

function monitorAddressChanges(address, name) {
    console.log("\n=== 监控 " + name + " 地址变化: " + address + " ===");
    
    try {
        // 每5秒检查一次数值变化
        var lastValue = Memory.readS32(address);
        console.log("[监控] " + name + " 初始值: " + lastValue);
        
        var monitorInterval = setInterval(function() {
            try {
                var currentValue = Memory.readS32(address);
                if (currentValue !== lastValue) {
                    console.log("[变化] " + name + " 从 " + lastValue + " 变为 " + currentValue);
                    lastValue = currentValue;
                }
            } catch (e) {
                console.log("[监控] 地址 " + address + " 不可读，停止监控");
                clearInterval(monitorInterval);
            }
        }, 5000);
        
        // 10分钟后停止监控
        setTimeout(function() {
            clearInterval(monitorInterval);
            console.log("[监控] 停止监控 " + name);
        }, 600000);
        
    } catch (e) {
        console.log("[-] 无法监控地址 " + address + ": " + e);
    }
}

// 分析游戏类和方法
setTimeout(function() {
    console.log("\n=== 分析游戏类结构 ===");
    
    var gameClasses = [];
    
    for (var className in ObjC.classes) {
        if (className.includes("Game") || 
            className.includes("Player") || 
            className.includes("Data") ||
            className.includes("Hezi")) {
            
            gameClasses.push(className);
            console.log("[类] " + className);
            
            try {
                var clazz = ObjC.classes[className];
                var methods = clazz.$ownMethods;
                
                // 查找可能的数值相关方法
                methods.forEach(function(methodName) {
                    if (methodName.toLowerCase().includes("money") ||
                        methodName.toLowerCase().includes("coin") ||
                        methodName.toLowerCase().includes("gold") ||
                        methodName.toLowerCase().includes("stamina") ||
                        methodName.toLowerCase().includes("health") ||
                        methodName.toLowerCase().includes("mood")) {
                        
                        console.log("  [方法] " + methodName);
                    }
                });
                
            } catch (e) {
                // 忽略错误
            }
        }
    }
    
    console.log("\n找到 " + gameClasses.length + " 个游戏相关类");
    
}, 10000);

console.log("[+] 观察脚本加载完成，开始学习作者的修改技术...");