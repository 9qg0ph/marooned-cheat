// 我独自生活 Frida Hook脚本
// 用于动态分析和修改游戏数值

console.log("🚀 我独自生活 Frida Hook脚本已加载");

// 全局变量
var isHookEnabled = true;
var targetValues = {
    cash: 21000000000,
    energy: 21000000000,
    health: 1000000,
    mood: 1000000
};

// 工具函数
function log(msg) {
    console.log("[WDZ] " + msg);
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
                    
                    var key = this.key.toLowerCase();
                    var originalValue = retval.toInt32();
                    
                    // 检查是否是我们要修改的字段
                    if (key.includes('cash') || key.includes('money') || key.includes('现金') || key.includes('金钱')) {
                        log("🎯 拦截现金字段: " + this.key + " (原值: " + originalValue + " → 新值: " + targetValues.cash + ")");
                        retval.replace(targetValues.cash);
                    } else if (key.includes('energy') || key.includes('stamina') || key.includes('体力')) {
                        log("🎯 拦截体力字段: " + this.key + " (原值: " + originalValue + " → 新值: " + targetValues.energy + ")");
                        retval.replace(targetValues.energy);
                    } else if (key.includes('health') || key.includes('hp') || key.includes('健康')) {
                        log("🎯 拦截健康字段: " + this.key + " (原值: " + originalValue + " → 新值: " + targetValues.health + ")");
                        retval.replace(targetValues.health);
                    } else if (key.includes('mood') || key.includes('happiness') || key.includes('心情')) {
                        log("🎯 拦截心情字段: " + this.key + " (原值: " + originalValue + " → 新值: " + targetValues.mood + ")");
                        retval.replace(targetValues.mood);
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
                            var key = this.key.toLowerCase();
                            var originalValue = obj.intValue();
                            
                            if (key.includes('cash') || key.includes('money') || key.includes('现金') || key.includes('金钱')) {
                                log("🎯 拦截现金对象: " + this.key + " (原值: " + originalValue + " → 新值: " + targetValues.cash + ")");
                                retval.replace(ObjC.classes.NSNumber.numberWithLongLong_(targetValues.cash));
                            } else if (key.includes('energy') || key.includes('stamina') || key.includes('体力')) {
                                log("🎯 拦截体力对象: " + this.key + " (原值: " + originalValue + " → 新值: " + targetValues.energy + ")");
                                retval.replace(ObjC.classes.NSNumber.numberWithLongLong_(targetValues.energy));
                            } else if (key.includes('health') || key.includes('hp') || key.includes('健康')) {
                                log("🎯 拦截健康对象: " + this.key + " (原值: " + originalValue + " → 新值: " + targetValues.health + ")");
                                retval.replace(ObjC.classes.NSNumber.numberWithInt_(targetValues.health));
                            } else if (key.includes('mood') || key.includes('happiness') || key.includes('心情')) {
                                log("🎯 拦截心情对象: " + this.key + " (原值: " + originalValue + " → 新值: " + targetValues.mood + ")");
                                retval.replace(ObjC.classes.NSNumber.numberWithInt_(targetValues.mood));
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

// 启动
main();