// 分析其他修改器的开关行为
console.log("🔍 修改器开关行为分析脚本已加载");

// 全局变量
var g_originalValues = new Map();
var g_currentValues = new Map();
var g_hookOperations = [];
var g_writeOperations = [];

setTimeout(function() {
    console.log("🔍 开始分析修改器的开关行为...");
    
    // 1. 记录当前游戏数值
    recordCurrentValues();
    
    // 2. 监控实时Hook行为
    monitorRealTimeHooks();
    
    // 3. 监控存档写入行为
    monitorSaveWrites();
    
    // 4. 监控数值变化模式
    monitorValueChanges();
    
    console.log("=".repeat(60));
    console.log("🔍 修改器开关行为分析已启动！");
    console.log("💡 现在操作其他修改器的开关，观察行为模式");
    console.log("=".repeat(60));
    
}, 1000);

// 记录当前游戏数值
function recordCurrentValues() {
    console.log("[记录] 当前游戏数值...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        var defaults = NSUserDefaults.standardUserDefaults();
        
        // 常见的游戏数值字段
        var gameKeys = [
            "现金", "金钱", "cash", "money", "coin", "coins",
            "体力", "energy", "stamina", "power", 
            "健康", "health", "hp", "life",
            "心情", "mood", "happiness", "spirit"
        ];
        
        console.log("📊 [当前数值] 游戏数据快照:");
        gameKeys.forEach(function(key) {
            try {
                var value = defaults.integerForKey_(key);
                if (value > 0) {
                    g_originalValues.set(key, value);
                    g_currentValues.set(key, value);
                    console.log("  " + key + ": " + value);
                }
            } catch (e) {}
        });
        
        console.log("✅ 数值记录完成");
    } catch (e) {
        console.log("❌ 数值记录失败: " + e.message);
    }
}

// 监控实时Hook行为
function monitorRealTimeHooks() {
    console.log("[监控] 实时Hook行为...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        // Hook integerForKey: 来检测实时拦截
        var integerForKey = NSUserDefaults['- integerForKey:'];
        if (integerForKey) {
            Interceptor.attach(integerForKey.implementation, {
                onEnter: function(args) {
                    this.key = ObjC.Object(args[2]).toString();
                    this.startTime = Date.now();
                },
                onLeave: function(retval) {
                    var value = retval.toInt32();
                    var originalValue = g_originalValues.get(this.key);
                    
                    // 检测是否被Hook修改
                    if (originalValue && originalValue !== value && value > 100000) {
                        console.log("🪝 [实时Hook] " + this.key + " 被拦截修改:");
                        console.log("   原值: " + originalValue + " → Hook值: " + value);
                        
                        g_hookOperations.push({
                            type: "realtime_hook",
                            key: this.key,
                            originalValue: originalValue,
                            hookedValue: value,
                            timestamp: Date.now()
                        });
                    }
                    
                    // 更新当前值
                    g_currentValues.set(this.key, value);
                }
            });
        }
        
        // Hook objectForKey: 来检测对象拦截
        var objectForKey = NSUserDefaults['- objectForKey:'];
        if (objectForKey) {
            Interceptor.attach(objectForKey.implementation, {
                onEnter: function(args) {
                    this.key = ObjC.Object(args[2]).toString();
                },
                onLeave: function(retval) {
                    if (!retval.isNull()) {
                        var obj = ObjC.Object(retval);
                        if (obj.respondsToSelector_(ObjC.selector('integerValue'))) {
                            var value = obj.integerValue();
                            var originalValue = g_originalValues.get(this.key);
                            
                            if (originalValue && originalValue !== value && value > 100000) {
                                console.log("🪝 [对象Hook] " + this.key + " 被拦截修改:");
                                console.log("   原值: " + originalValue + " → Hook值: " + value);
                            }
                        }
                    }
                }
            });
        }
        
        console.log("✅ 实时Hook监控已启动");
    } catch (e) {
        console.log("❌ 实时Hook监控失败: " + e.message);
    }
}

// 监控存档写入行为
function monitorSaveWrites() {
    console.log("[监控] 存档写入行为...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        // 监控 setInteger:forKey:
        var setInteger = NSUserDefaults['- setInteger:forKey:'];
        if (setInteger) {
            Interceptor.attach(setInteger.implementation, {
                onEnter: function(args) {
                    var value = args[2].toInt32();
                    var key = ObjC.Object(args[3]).toString();
                    
                    // 检测是否是"恢复"操作（设置较小的固定值）
                    if ((value === 10000 || value === 100 || value === 1000) && 
                        (key.includes("现金") || key.includes("cash") || key.includes("money") ||
                         key.includes("体力") || key.includes("energy") || key.includes("stamina") ||
                         key.includes("健康") || key.includes("health") || key.includes("hp") ||
                         key.includes("心情") || key.includes("mood") || key.includes("happiness"))) {
                        
                        console.log("💾 [存档覆盖] 检测到固定值写入:");
                        console.log("   " + key + " = " + value + " (可能是关闭修改器时的覆盖操作)");
                        
                        g_writeOperations.push({
                            type: "save_overwrite",
                            key: key,
                            value: value,
                            timestamp: Date.now(),
                            isRestoreOperation: true
                        });
                    }
                    // 检测大数值写入（开启修改器）
                    else if (value > 100000) {
                        console.log("💾 [存档修改] 检测到大数值写入:");
                        console.log("   " + key + " = " + value + " (可能是开启修改器时的操作)");
                        
                        g_writeOperations.push({
                            type: "save_modify",
                            key: key,
                            value: value,
                            timestamp: Date.now(),
                            isModifyOperation: true
                        });
                    }
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
                    
                    if (obj && obj.respondsToSelector_(ObjC.selector('integerValue'))) {
                        var value = obj.integerValue();
                        
                        if ((value === 10000 || value === 100 || value === 1000) && 
                            (key.includes("现金") || key.includes("cash") || key.includes("money") ||
                             key.includes("体力") || key.includes("energy") || key.includes("stamina") ||
                             key.includes("健康") || key.includes("health") || key.includes("hp") ||
                             key.includes("心情") || key.includes("mood") || key.includes("happiness"))) {
                            
                            console.log("💾 [对象覆盖] 检测到固定值对象写入:");
                            console.log("   " + key + " = " + obj + " (" + value + ")");
                        }
                    }
                    
                    // 检测ES3存档的修改
                    if (key.includes("es3") || key.includes("ES3")) {
                        console.log("💾 [ES3存档] 检测到ES3存档修改: " + key);
                        console.log("   数据长度: " + (obj ? obj.length() : "unknown"));
                    }
                }
            });
        }
        
        console.log("✅ 存档写入监控已启动");
    } catch (e) {
        console.log("❌ 存档写入监控失败: " + e.message);
    }
}

// 监控数值变化模式
function monitorValueChanges() {
    console.log("[监控] 数值变化模式...");
    
    // 每5秒检查一次数值变化
    setInterval(function() {
        var hasChanges = false;
        
        g_currentValues.forEach(function(currentValue, key) {
            var originalValue = g_originalValues.get(key);
            if (originalValue && originalValue !== currentValue) {
                if (!hasChanges) {
                    console.log("\n📈 [数值变化] 检测到数值变化:");
                    hasChanges = true;
                }
                console.log("  " + key + ": " + originalValue + " → " + currentValue);
            }
        });
        
        if (hasChanges) {
            console.log("");
        }
    }, 5000);
}

// 生成行为分析报告
setInterval(function() {
    if (g_hookOperations.length > 0 || g_writeOperations.length > 0) {
        console.log("\n" + "=".repeat(60));
        console.log("📊 修改器行为分析报告");
        console.log("=".repeat(60));
        
        if (g_hookOperations.length > 0) {
            console.log("🪝 实时Hook操作 (" + g_hookOperations.length + " 次):");
            g_hookOperations.forEach(function(op, index) {
                console.log("  " + (index + 1) + ". " + op.key + ": " + op.originalValue + " → " + op.hookedValue);
            });
            console.log("");
        }
        
        if (g_writeOperations.length > 0) {
            console.log("💾 存档写入操作 (" + g_writeOperations.length + " 次):");
            var restoreOps = g_writeOperations.filter(op => op.isRestoreOperation);
            var modifyOps = g_writeOperations.filter(op => op.isModifyOperation);
            
            if (modifyOps.length > 0) {
                console.log("  📈 修改操作:");
                modifyOps.forEach(function(op, index) {
                    console.log("    " + (index + 1) + ". " + op.key + " = " + op.value);
                });
            }
            
            if (restoreOps.length > 0) {
                console.log("  📉 恢复操作:");
                restoreOps.forEach(function(op, index) {
                    console.log("    " + (index + 1) + ". " + op.key + " = " + op.value);
                });
            }
            console.log("");
        }
        
        // 推测实现方式
        console.log("🔍 推测的实现方式:");
        if (g_hookOperations.length > 0 && g_writeOperations.filter(op => op.isRestoreOperation).length > 0) {
            console.log("  ✅ 双重机制: 实时Hook + 存档覆盖");
            console.log("  - 开启时: Hook拦截数值读取，返回大数值");
            console.log("  - 关闭时: 写入固定的'正常'数值到存档");
        } else if (g_hookOperations.length > 0) {
            console.log("  ✅ 纯Hook机制: 仅实时拦截数值读取");
        } else if (g_writeOperations.length > 0) {
            console.log("  ✅ 存档修改机制: 直接修改存档数据");
        }
        
        console.log("=".repeat(60) + "\n");
        
        // 清空已分析的操作
        g_hookOperations = [];
        g_writeOperations = [];
    }
}, 20000); // 每20秒生成一次报告

console.log("📋 [提示] 修改器开关行为分析系统加载完成...");