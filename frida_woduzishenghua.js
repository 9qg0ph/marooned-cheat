// 我独自生活 实时Hook修改器
// 基于发现：必须保持开启状态才有效果
// 说明使用的是实时拦截而非存档修改

console.log("🚀 实时Hook修改器已加载");
console.log("💡 基于发现：需要保持开启状态 = 实时拦截方式");

// 全局变量
var isHookEnabled = true;
var targetValues = {
    cash: 21000000000,
    energy: 21000000000,
    health: 1000000,
    mood: 1000000
};

// 已知的游戏数值
var knownValues = {
    currentCash: 2099999100  // 当前现金数值
};

// 工具函数
function log(msg) {
    console.log("[实时Hook] " + msg);
}

// 实时拦截所有可能的数值获取方法
function setupRealTimeHooks() {
    log("开始安装实时Hook...");
    
    // 1. Hook NSUserDefaults - 最常用的存储方式
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        if (NSUserDefaults) {
            // integerForKey - 拦截整数读取
            var integerForKey = NSUserDefaults['- integerForKey:'];
            if (integerForKey) {
                Interceptor.attach(integerForKey.implementation, {
                    onLeave: function(retval) {
                        if (!isHookEnabled) return;
                        
                        var originalValue = retval.toInt32();
                        
                        // 精确匹配当前现金数值
                        if (originalValue === knownValues.currentCash) {
                            log("🎯 拦截现金读取: " + originalValue + " → " + targetValues.cash);
                            retval.replace(targetValues.cash);
                        }
                        // 范围匹配其他数值
                        else if (originalValue >= 1000000 && originalValue <= 10000000000) {
                            log("🎯 拦截大数值: " + originalValue + " → " + targetValues.cash);
                            retval.replace(targetValues.cash);
                        }
                        else if (originalValue >= 100 && originalValue <= 1000000) {
                            log("🎯 拦截中数值: " + originalValue + " → " + targetValues.health);
                            retval.replace(targetValues.health);
                        }
                    }
                });
                log("✅ integerForKey Hook已安装");
            }
            
            // objectForKey - 拦截对象读取
            var objectForKey = NSUserDefaults['- objectForKey:'];
            if (objectForKey) {
                Interceptor.attach(objectForKey.implementation, {
                    onLeave: function(retval) {
                        if (!isHookEnabled || retval.isNull()) return;
                        
                        var obj = ObjC.Object(retval);
                        if (obj.isKindOfClass_(ObjC.classes.NSNumber)) {
                            var originalValue = obj.intValue();
                            
                            if (originalValue === knownValues.currentCash) {
                                log("🎯 拦截现金对象: " + originalValue + " → " + targetValues.cash);
                                retval.replace(ObjC.classes.NSNumber.numberWithLongLong_(targetValues.cash));
                            }
                            else if (originalValue >= 1000000 && originalValue <= 10000000000) {
                                log("🎯 拦截大数值对象: " + originalValue + " → " + targetValues.cash);
                                retval.replace(ObjC.classes.NSNumber.numberWithLongLong_(targetValues.cash));
                            }
                            else if (originalValue >= 100 && originalValue <= 1000000) {
                                log("🎯 拦截中数值对象: " + originalValue + " → " + targetValues.health);
                                retval.replace(ObjC.classes.NSNumber.numberWithInt_(targetValues.health));
                            }
                        }
                    }
                });
                log("✅ objectForKey Hook已安装");
            }
        }
    } catch (e) {
        log("❌ NSUserDefaults Hook失败: " + e.message);
    }
    
    // 2. Hook NSNumber的数值获取方法
    try {
        var NSNumber = ObjC.classes.NSNumber;
        if (NSNumber) {
            var intValue = NSNumber['- intValue'];
            if (intValue) {
                Interceptor.attach(intValue.implementation, {
                    onLeave: function(retval) {
                        if (!isHookEnabled) return;
                        
                        var originalValue = retval.toInt32();
                        
                        if (originalValue === knownValues.currentCash) {
                            log("🎯 拦截NSNumber现金: " + originalValue + " → " + targetValues.cash);
                            retval.replace(targetValues.cash);
                        }
                        else if (originalValue >= 1000000 && originalValue <= 10000000000) {
                            log("🎯 拦截NSNumber大数值: " + originalValue + " → " + targetValues.cash);
                            retval.replace(targetValues.cash);
                        }
                        else if (originalValue >= 100 && originalValue <= 1000000) {
                            log("🎯 拦截NSNumber中数值: " + originalValue + " → " + targetValues.health);
                            retval.replace(targetValues.health);
                        }
                    }
                });
                log("✅ NSNumber intValue Hook已安装");
            }
            
            var longLongValue = NSNumber['- longLongValue'];
            if (longLongValue) {
                Interceptor.attach(longLongValue.implementation, {
                    onLeave: function(retval) {
                        if (!isHookEnabled) return;
                        
                        var originalValue = retval.toInt32();
                        
                        if (originalValue === knownValues.currentCash) {
                            log("🎯 拦截NSNumber longLong现金: " + originalValue + " → " + targetValues.cash);
                            retval.replace(targetValues.cash);
                        }
                        else if (originalValue >= 1000000 && originalValue <= 10000000000) {
                            log("🎯 拦截NSNumber longLong大数值: " + originalValue + " → " + targetValues.cash);
                            retval.replace(targetValues.cash);
                        }
                    }
                });
                log("✅ NSNumber longLongValue Hook已安装");
            }
        }
    } catch (e) {
        log("❌ NSNumber Hook失败: " + e.message);
    }
    
    // 3. Hook SQLite数据库读取
    try {
        var sqlite3_column_int = Module.findExportByName("libsqlite3.dylib", "sqlite3_column_int");
        if (sqlite3_column_int) {
            Interceptor.attach(sqlite3_column_int, {
                onLeave: function(retval) {
                    if (!isHookEnabled) return;
                    
                    var originalValue = retval.toInt32();
                    
                    if (originalValue === knownValues.currentCash) {
                        log("🎯 拦截SQLite现金: " + originalValue + " → " + targetValues.cash);
                        retval.replace(targetValues.cash);
                    }
                    else if (originalValue >= 1000000 && originalValue <= 10000000000) {
                        log("🎯 拦截SQLite大数值: " + originalValue + " → " + targetValues.cash);
                        retval.replace(targetValues.cash);
                    }
                    else if (originalValue >= 100 && originalValue <= 1000000) {
                        log("🎯 拦截SQLite中数值: " + originalValue + " → " + targetValues.health);
                        retval.replace(targetValues.health);
                    }
                }
            });
            log("✅ SQLite Hook已安装");
        }
    } catch (e) {
        log("❌ SQLite Hook失败: " + e.message);
    }
    
    log("🎉 所有实时Hook已安装完成！");
    log("💡 现在游戏中的数值读取都会被拦截和修改");
}

// 主函数
function main() {
    log("=".repeat(60));
    log("🎯 实时Hook修改器 - 保持开启状态生效");
    log("=".repeat(60));
    
    setTimeout(function() {
        setupRealTimeHooks();
        
        log("=".repeat(60));
        log("✅ 实时Hook修改器已启动！");
        log("💡 现在游戏中读取数值时会被自动拦截和修改");
        log("🔄 保持此脚本运行状态，关闭后修改失效");
        log("=".repeat(60));
    }, 2000);
}

// 导出控制函数
global.toggleHook = function() {
    isHookEnabled = !isHookEnabled;
    log("Hook状态: " + (isHookEnabled ? "开启" : "关闭"));
};

global.setCash = function(value) {
    targetValues.cash = value;
    log("现金目标值设置为: " + value);
};

global.setEnergy = function(value) {
    targetValues.energy = value;
    log("体力目标值设置为: " + value);
};

global.setHealth = function(value) {
    targetValues.health = value;
    log("健康目标值设置为: " + value);
};

global.setMood = function(value) {
    targetValues.mood = value;
    log("心情目标值设置为: " + value);
};

// 新增：更新当前数值
global.updateCurrentCash = function(value) {
    knownValues.currentCash = value;
    log("更新当前现金数值为: " + value);
};

// 启动
main();