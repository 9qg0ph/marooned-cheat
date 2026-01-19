// 我独自生活 Frida Hook脚本
// 用于动态分析和修改游戏数值
// 当前现金数值: 2099999100

console.log("🚀 我独自生活 Frida Hook脚本已加载");
console.log("🎯 目标现金数值: 2099999100");

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
    console.log("[WDZ] " + msg);
}

// 检查是否是目标数值
function isTargetValue(value, key) {
    var lowerKey = key.toLowerCase();
    
    // 精确匹配当前现金数值
    if (value === knownValues.currentCash) {
        log("🎯 发现当前现金数值: " + value);
        return { type: 'cash', newValue: targetValues.cash };
    }
    
    // 范围匹配
    if (value >= 1000000 && value <= 10000000000) {
        if (lowerKey.includes('cash') || lowerKey.includes('money') || lowerKey.includes('现金') || lowerKey.includes('金钱')) {
            return { type: 'cash', newValue: targetValues.cash };
        } else if (lowerKey.includes('energy') || lowerKey.includes('stamina') || lowerKey.includes('体力')) {
            return { type: 'energy', newValue: targetValues.energy };
        }
    }
    
    if (value >= 1 && value <= 1000000) {
        if (lowerKey.includes('health') || lowerKey.includes('hp') || lowerKey.includes('健康')) {
            return { type: 'health', newValue: targetValues.health };
        } else if (lowerKey.includes('mood') || lowerKey.includes('happiness') || lowerKey.includes('心情')) {
            return { type: 'mood', newValue: targetValues.mood };
        }
    }
    
    return null;
}

function hookNSUserDefaults() {
    log("开始Hook NSUserDefaults...");
    
    // Hook integerForKey
    var NSUserDefaults = ObjC.classes.NSUserDefaults;
    if (NSUserDefaults) {
        var integerForKey = NSUserDefaults['- integerForKey:'];
        if (integerForKey) {
            Interceptor.attach(integerForKey.implementation, {
                onEnter: function(args) {
                    this.key = ObjC.Object(args[2]).toString();
                },
                onLeave: function(retval) {
                    if (!isHookEnabled) return;
                    
                    var originalValue = retval.toInt32();
                    var result = isTargetValue(originalValue, this.key);
                    
                    if (result) {
                        log("🎯 拦截" + result.type + "字段: " + this.key + " (原值: " + originalValue + " → 新值: " + result.newValue + ")");
                        retval.replace(result.newValue);
                    } else if (originalValue === knownValues.currentCash) {
                        log("🎯 精确拦截现金: " + this.key + " (原值: " + originalValue + " → 新值: " + targetValues.cash + ")");
                        retval.replace(targetValues.cash);
                    }
                }
            });
            log("✅ integerForKey Hook已安装");
        }
        
        // Hook objectForKey
        var objectForKey = NSUserDefaults['- objectForKey:'];
        if (objectForKey) {
            Interceptor.attach(objectForKey.implementation, {
                onEnter: function(args) {
                    this.key = ObjC.Object(args[2]).toString();
                },
                onLeave: function(retval) {
                    if (!isHookEnabled) return;
                    if (!retval.isNull()) {
                        var obj = ObjC.Object(retval);
                        if (obj.isKindOfClass_(ObjC.classes.NSNumber)) {
                            var originalValue = obj.intValue();
                            var result = isTargetValue(originalValue, this.key);
                            
                            if (result) {
                                log("🎯 拦截" + result.type + "对象: " + this.key + " (原值: " + originalValue + " → 新值: " + result.newValue + ")");
                                if (result.type === 'cash' || result.type === 'energy') {
                                    retval.replace(ObjC.classes.NSNumber.numberWithLongLong_(result.newValue));
                                } else {
                                    retval.replace(ObjC.classes.NSNumber.numberWithInt_(result.newValue));
                                }
                            } else if (originalValue === knownValues.currentCash) {
                                log("🎯 精确拦截现金对象: " + this.key + " (原值: " + originalValue + " → 新值: " + targetValues.cash + ")");
                                retval.replace(ObjC.classes.NSNumber.numberWithLongLong_(targetValues.cash));
                            }
                        }
                    }
                }
            });
            log("✅ objectForKey Hook已安装");
        }
    }
}

// Hook Unity相关方法
function hookUnityMethods() {
    log("开始Hook Unity方法...");
    
    // 尝试Hook Unity的PlayerPrefs
    try {
        var UnityEngine = Module.findExportByName("UnityFramework", "UnityEngine");
        if (UnityEngine) {
            log("找到Unity引擎");
            
            // Hook PlayerPrefs.GetInt
            var getIntAddr = Module.findExportByName("UnityFramework", "PlayerPrefs_GetInt");
            if (getIntAddr) {
                Interceptor.attach(getIntAddr, {
                    onEnter: function(args) {
                        this.key = Memory.readUtf8String(args[0]);
                    },
                    onLeave: function(retval) {
                        if (!isHookEnabled) return;
                        
                        var key = this.key.toLowerCase();
                        var originalValue = retval.toInt32();
                        
                        if (key.includes('cash') || key.includes('money') || key.includes('现金') || key.includes('金钱')) {
                            log("🎯 Unity拦截现金: " + this.key + " (" + originalValue + " → " + targetValues.cash + ")");
                            retval.replace(targetValues.cash);
                        } else if (key.includes('energy') || key.includes('stamina') || key.includes('体力')) {
                            log("🎯 Unity拦截体力: " + this.key + " (" + originalValue + " → " + targetValues.energy + ")");
                            retval.replace(targetValues.energy);
                        } else if (key.includes('health') || key.includes('hp') || key.includes('健康')) {
                            log("🎯 Unity拦截健康: " + this.key + " (" + originalValue + " → " + targetValues.health + ")");
                            retval.replace(targetValues.health);
                        } else if (key.includes('mood') || key.includes('happiness') || key.includes('心情')) {
                            log("🎯 Unity拦截心情: " + this.key + " (" + originalValue + " → " + targetValues.mood + ")");
                            retval.replace(targetValues.mood);
                        }
                    }
                });
                log("✅ Unity PlayerPrefs Hook已安装");
            }
        }
    } catch (e) {
        log("Unity Hook失败: " + e.message);
    }
}

// Hook SQLite数据库操作
function hookSQLite() {
    log("开始Hook SQLite...");
    
    try {
        // Hook sqlite3_column_int
        var sqlite3_column_int = Module.findExportByName("libsqlite3.dylib", "sqlite3_column_int");
        if (sqlite3_column_int) {
            Interceptor.attach(sqlite3_column_int, {
                onLeave: function(retval) {
                    if (!isHookEnabled) return;
                    
                    var value = retval.toInt32();
                    // 如果是合理的游戏数值范围，尝试修改
                    if (value > 100 && value < 100000000) {
                        if (value < 10000) {
                            // 可能是健康/心情
                            retval.replace(targetValues.health);
                            log("🎯 SQLite拦截小数值: " + value + " → " + targetValues.health);
                        } else {
                            // 可能是现金/体力
                            retval.replace(targetValues.cash);
                            log("🎯 SQLite拦截大数值: " + value + " → " + targetValues.cash);
                        }
                    }
                }
            });
            log("✅ SQLite Hook已安装");
        }
    } catch (e) {
        log("SQLite Hook失败: " + e.message);
    }
}

// 通用数值Hook - Hook所有可能返回数值的方法
function hookCommonMethods() {
    log("开始Hook通用方法...");
    
    // Hook NSNumber的intValue方法
    try {
        var NSNumber = ObjC.classes.NSNumber;
        if (NSNumber) {
            var intValue = NSNumber['- intValue'];
            if (intValue) {
                Interceptor.attach(intValue.implementation, {
                    onLeave: function(retval) {
                        if (!isHookEnabled) return;
                        
                        var value = retval.toInt32();
                        // 修改特定范围的数值
                        if (value >= 1000 && value <= 50000000) {
                            if (value < 10000) {
                                retval.replace(targetValues.health);
                                log("🎯 NSNumber拦截小数值: " + value + " → " + targetValues.health);
                            } else {
                                retval.replace(targetValues.cash);
                                log("🎯 NSNumber拦截大数值: " + value + " → " + targetValues.cash);
                            }
                        }
                    }
                });
                log("✅ NSNumber intValue Hook已安装");
            }
        }
    } catch (e) {
        log("NSNumber Hook失败: " + e.message);
    }
}

// 主函数
function main() {
    log("开始初始化Hook...");
    
    // 等待应用完全加载
    setTimeout(function() {
        hookNSUserDefaults();
        hookUnityMethods();
        hookSQLite();
        hookCommonMethods();
        
        log("🎉 所有Hook已安装完成！");
        log("💡 使用方法：");
        log("   - toggleHook() : 开启/关闭Hook");
        log("   - setCash(value) : 设置现金数值");
        log("   - setEnergy(value) : 设置体力数值");
        log("   - setHealth(value) : 设置健康数值");
        log("   - setMood(value) : 设置心情数值");
        
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

// 新增：监控所有数值读取
global.enableMonitor = function() {
    log("开启数值监控模式...");
    
    // Hook所有可能的数值获取方法
    var NSNumber = ObjC.classes.NSNumber;
    if (NSNumber) {
        var intValue = NSNumber['- intValue'];
        if (intValue) {
            Interceptor.attach(intValue.implementation, {
                onLeave: function(retval) {
                    var value = retval.toInt32();
                    // 只记录可能的游戏数值
                    if (value >= 1000 && value <= 10000000000) {
                        log("📊 监控到数值: " + value);
                    }
                }
            });
        }
    }
    
    log("✅ 数值监控已启用");
};

// 启动
main();