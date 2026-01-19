// 我独自生活 - 高级分析脚本
// 专门用于分析其他修改器的实现方式
console.log("🚀 我独自生活高级分析脚本已加载");

// 全局变量
var g_monitoredAddresses = new Set();
var g_suspiciousValues = new Map();
var g_hookCount = 0;

setTimeout(function() {
    console.log("✅ 开始高级分析...");
    
    // 1. 监控所有可能的游戏数值修改
    monitorGameValueModifications();
    
    // 2. 监控内存写入模式
    monitorMemoryWritePatterns();
    
    // 3. 监控 ES3 存档操作
    monitorES3Operations();
    
    // 4. 监控 Unity 相关调用
    monitorUnityOperations();
    
    // 5. 监控可疑的大数值操作
    monitorSuspiciousValues();
    
    console.log("=".repeat(60));
    console.log("✅ 高级分析已全部启动！");
    console.log("💡 现在运行其他作者的修改器，观察详细分析结果");
    console.log("=".repeat(60));
    
}, 2000);

// 监控游戏数值修改
function monitorGameValueModifications() {
    console.log("[分析] 开始监控游戏数值修改...");
    
    try {
        // 监控 NSUserDefaults 的所有写入方法
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        if (NSUserDefaults) {
            
            // setInteger:forKey:
            var setInteger = NSUserDefaults['- setInteger:forKey:'];
            if (setInteger) {
                Interceptor.attach(setInteger.implementation, {
                    onEnter: function(args) {
                        var value = args[2].toInt32();
                        var key = ObjC.Object(args[3]).toString();
                        
                        // 记录所有大数值的设置
                        if (value > 1000000 || value === 999999999 || value === 21000000000) {
                            console.log("🎯 [数值修改] setInteger: " + value + " forKey: " + key);
                            console.log("   调用栈: " + Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress).join('\n   '));
                        }
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
                        
                        // 检查是否是大数值对象
                        if (obj && obj.respondsToSelector_(ObjC.selector('integerValue'))) {
                            var value = obj.integerValue();
                            if (value > 1000000 || value === 999999999 || value === 21000000000) {
                                console.log("🎯 [对象修改] setObject: " + obj + " (" + value + ") forKey: " + key);
                                console.log("   调用栈: " + Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress).join('\n   '));
                            }
                        }
                        
                        // 检查是否是 ES3 存档
                        if (key.includes("es3") || key.includes("ES3") || key === "data0.es3") {
                            console.log("💾 [ES3存档] 修改 ES3 存档: " + key);
                            console.log("   数据长度: " + (obj ? obj.length() : "unknown"));
                        }
                    }
                });
            }
            
            console.log("✅ NSUserDefaults 监控已启动");
        }
    } catch (e) {
        console.log("❌ NSUserDefaults 监控失败: " + e.message);
    }
}

// 监控内存写入模式
function monitorMemoryWritePatterns() {
    console.log("[分析] 开始监控内存写入模式...");
    
    try {
        // 监控 memcpy - 关注特定数值的写入
        var memcpy = Module.findExportByName("libsystem_c.dylib", "memcpy");
        if (memcpy) {
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    if (size >= 4 && size <= 8) {
                        try {
                            var value = Memory.readU32(args[1]);
                            
                            // 检查是否是我们关心的特殊数值
                            if (value === 999999999 || value === 21000000000 || 
                                (value > 1000000 && value < 100000000000)) {
                                
                                console.log("🧠 [内存写入] memcpy 写入特殊数值: " + value);
                                console.log("   目标地址: 0x" + args[0].toString(16));
                                console.log("   源地址: 0x" + args[1].toString(16));
                                console.log("   大小: " + size + " bytes");
                                
                                // 记录这个地址，后续监控
                                g_monitoredAddresses.add(args[0].toString());
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        // 监控 vm_write - 虚拟内存写入
        var vm_write = Module.findExportByName("libsystem_kernel.dylib", "vm_write");
        if (vm_write) {
            Interceptor.attach(vm_write, {
                onEnter: function(args) {
                    var size = args[3].toInt32();
                    if (size >= 4 && size <= 8) {
                        try {
                            var value = Memory.readU32(args[2]);
                            if (value === 999999999 || value === 21000000000 || 
                                (value > 1000000 && value < 100000000000)) {
                                
                                console.log("🧠 [虚拟内存] vm_write 写入特殊数值: " + value);
                                console.log("   目标地址: 0x" + args[1].toString(16));
                                console.log("   大小: " + size + " bytes");
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        console.log("✅ 内存写入模式监控已启动");
    } catch (e) {
        console.log("❌ 内存写入模式监控失败: " + e.message);
    }
}

// 监控 ES3 存档操作
function monitorES3Operations() {
    console.log("[分析] 开始监控 ES3 存档操作...");
    
    try {
        // 监控 Base64 编码/解码（ES3 存档使用）
        var NSData = ObjC.classes.NSData;
        if (NSData) {
            // base64EncodedStringWithOptions:
            var base64Encode = NSData['- base64EncodedStringWithOptions:'];
            if (base64Encode) {
                Interceptor.attach(base64Encode.implementation, {
                    onEnter: function(args) {
                        var data = ObjC.Object(args[0]);
                        if (data && data.length() > 10000) {
                            console.log("📦 [ES3] Base64 编码大数据: " + data.length() + " bytes");
                        }
                    },
                    onLeave: function(retval) {
                        var result = ObjC.Object(retval);
                        if (result && result.length() > 10000) {
                            console.log("📦 [ES3] Base64 编码结果: " + result.length() + " chars");
                            // 检查是否包含游戏数据特征
                            var str = result.toString();
                            if (str.includes("UnityEngine") || str.includes("GameObject")) {
                                console.log("🎮 [ES3] 检测到 Unity GameObject 数据");
                            }
                        }
                    }
                });
            }
            
            // initWithBase64EncodedString:options:
            var base64Decode = NSData['+ dataWithBase64EncodedString:options:'];
            if (base64Decode) {
                Interceptor.attach(base64Decode.implementation, {
                    onEnter: function(args) {
                        var str = ObjC.Object(args[2]);
                        if (str && str.length() > 10000) {
                            console.log("📦 [ES3] Base64 解码大字符串: " + str.length() + " chars");
                        }
                    }
                });
            }
        }
        
        // 监控 JSON 序列化/反序列化
        var NSJSONSerialization = ObjC.classes.NSJSONSerialization;
        if (NSJSONSerialization) {
            // dataWithJSONObject:options:error:
            var jsonSerialize = NSJSONSerialization['+ dataWithJSONObject:options:error:'];
            if (jsonSerialize) {
                Interceptor.attach(jsonSerialize.implementation, {
                    onEnter: function(args) {
                        var obj = ObjC.Object(args[2]);
                        console.log("📄 [JSON] 序列化对象: " + obj.$className);
                    }
                });
            }
            
            // JSONObjectWithData:options:error:
            var jsonDeserialize = NSJSONSerialization['+ JSONObjectWithData:options:error:'];
            if (jsonDeserialize) {
                Interceptor.attach(jsonDeserialize.implementation, {
                    onEnter: function(args) {
                        var data = ObjC.Object(args[2]);
                        if (data && data.length() > 1000) {
                            console.log("📄 [JSON] 反序列化大数据: " + data.length() + " bytes");
                        }
                    }
                });
            }
        }
        
        console.log("✅ ES3 存档操作监控已启动");
    } catch (e) {
        console.log("❌ ES3 存档操作监控失败: " + e.message);
    }
}

// 监控 Unity 相关操作
function monitorUnityOperations() {
    console.log("[分析] 开始监控 Unity 相关操作...");
    
    try {
        // 搜索 Unity 相关的导出函数
        var modules = Process.enumerateModules();
        var unityModule = null;
        
        for (var i = 0; i < modules.length; i++) {
            if (modules[i].name.includes("UnityFramework") || 
                modules[i].name.includes("libil2cpp") ||
                modules[i].name.includes("libunity")) {
                unityModule = modules[i];
                break;
            }
        }
        
        if (unityModule) {
            console.log("🎮 [Unity] 找到 Unity 模块: " + unityModule.name);
            
            // 监控 Unity 模块中的函数调用
            var exports = unityModule.enumerateExports();
            var hookedCount = 0;
            
            for (var j = 0; j < exports.length && hookedCount < 10; j++) {
                var exp = exports[j];
                if (exp.name && (exp.name.includes("PlayerPrefs") || 
                                exp.name.includes("SaveGame") ||
                                exp.name.includes("GameData"))) {
                    
                    console.log("🎯 [Unity] 发现相关函数: " + exp.name);
                    
                    try {
                        Interceptor.attach(exp.address, {
                            onEnter: function(args) {
                                console.log("🔧 [Unity] 调用: " + exp.name);
                            }
                        });
                        hookedCount++;
                    } catch (e) {}
                }
            }
        }
        
        console.log("✅ Unity 操作监控已启动");
    } catch (e) {
        console.log("❌ Unity 操作监控失败: " + e.message);
    }
}

// 监控可疑的大数值操作
function monitorSuspiciousValues() {
    console.log("[分析] 开始监控可疑数值操作...");
    
    // 定义我们关心的特殊数值
    var suspiciousValues = [
        999999999,    // 常见的无限数值
        21000000000,  // 你的修改器使用的数值
        2099999100,   // 日志中看到的数值
        1000000,      // 百万级数值
        999999,       // 99万级数值
        100000000     // 1亿级数值
    ];
    
    // 监控这些数值在内存中的出现
    suspiciousValues.forEach(function(value) {
        try {
            // 扫描内存中的这些数值
            Process.enumerateRanges('rw-', {
                onMatch: function(range) {
                    try {
                        Memory.scan(range.base, range.size, value.toString(16), {
                            onMatch: function(address, size) {
                                console.log("🔍 [数值扫描] 找到可疑数值 " + value + " 在地址: " + address);
                                
                                // 监控这个地址的后续写入
                                try {
                                    Interceptor.attach(address, {
                                        onEnter: function(args) {
                                            console.log("✏️ [数值监控] 地址 " + address + " 被访问");
                                        }
                                    });
                                } catch (e) {}
                            },
                            onError: function(reason) {}
                        });
                    } catch (e) {}
                },
                onComplete: function() {}
            });
        } catch (e) {}
    });
    
    console.log("✅ 可疑数值监控已启动");
}

// 辅助函数：格式化调用栈
function formatBacktrace(backtrace) {
    return backtrace.map(function(frame) {
        var symbol = DebugSymbol.fromAddress(frame);
        return "   " + symbol.toString();
    }).join('\n');
}

// 辅助函数：检查是否是游戏相关的键
function isGameRelatedKey(key) {
    var gameKeys = [
        "现金", "金钱", "cash", "money", "coin", "coins",
        "体力", "energy", "stamina", "power",
        "健康", "health", "hp", "life",
        "心情", "mood", "happiness", "spirit",
        "经验", "exp", "experience",
        "等级", "level", "grade",
        "积分", "score", "point", "points"
    ];
    
    var lowerKey = key.toLowerCase();
    return gameKeys.some(function(gameKey) {
        return lowerKey.includes(gameKey.toLowerCase());
    });
}

console.log("📋 [提示] 脚本加载完成，等待初始化...");