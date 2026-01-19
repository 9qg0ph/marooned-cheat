// 实时修改器捕获脚本 - 简化版
// 专门用于捕获其他修改器的实时操作
console.log("🎯 实时修改器捕获脚本已启动");

var g_capturedOperations = [];
var g_lastOperationTime = 0;

setTimeout(function() {
    console.log("=".repeat(50));
    console.log("🎯 开始实时捕获修改器操作");
    console.log("📱 请在手机上操作其他修改器");
    console.log("💡 开启/关闭功能时我们将捕获操作");
    console.log("=".repeat(50));
    
    // 启动所有监控
    hookNSUserDefaults();
    hookMemoryOperations();
    startStatusReporting();
    
}, 1000);

// Hook NSUserDefaults操作
function hookNSUserDefaults() {
    console.log("[启动] NSUserDefaults监控...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        // Hook setInteger:forKey:
        var setInteger = NSUserDefaults['- setInteger:forKey:'];
        if (setInteger) {
            Interceptor.attach(setInteger.implementation, {
                onEnter: function(args) {
                    var value = args[2].toInt32();
                    var key = ObjC.Object(args[3]).toString();
                    
                    // 记录所有操作
                    var operation = {
                        type: 'setInteger',
                        key: key,
                        value: value,
                        timestamp: Date.now(),
                        time: new Date().toLocaleTimeString()
                    };
                    
                    g_capturedOperations.push(operation);
                    g_lastOperationTime = Date.now();
                    
                    // 实时显示
                    console.log("🔧 [捕获] setInteger: " + key + " = " + value + " (" + operation.time + ")");
                    
                    // 检查是否是重要数值
                    if (value > 100000 || value === 999999999 || value === 21000000000) {
                        console.log("💰 [重要] 大数值修改: " + key + " = " + value);
                        console.log("🎯 [分析] 这可能是修改器操作！");
                    }
                }
            });
        }
        
        // Hook setObject:forKey:
        var setObject = NSUserDefaults['- setObject:forKey:'];
        if (setObject) {
            Interceptor.attach(setObject.implementation, {
                onEnter: function(args) {
                    var obj = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]).toString();
                    
                    var operation = {
                        type: 'setObject',
                        key: key,
                        value: obj ? obj.toString() : 'null',
                        timestamp: Date.now(),
                        time: new Date().toLocaleTimeString()
                    };
                    
                    g_capturedOperations.push(operation);
                    g_lastOperationTime = Date.now();
                    
                    console.log("🔧 [捕获] setObject: " + key + " = " + (obj ? obj.toString().substring(0, 50) : 'null') + " (" + operation.time + ")");
                    
                    // 检查ES3存档
                    if (key.toLowerCase().includes('es3')) {
                        console.log("💾 [ES3] ES3存档操作: " + key);
                        if (obj && obj.isKindOfClass_(ObjC.classes.NSString)) {
                            console.log("📦 [ES3] 数据长度: " + obj.length());
                        }
                    }
                    
                    // 检查时间戳
                    if (key.toLowerCase().includes('timestamp')) {
                        console.log("🕐 [时间戳] 时间戳更新: " + key);
                    }
                }
            });
        }
        
        console.log("✅ NSUserDefaults监控已启动");
    } catch (e) {
        console.log("❌ NSUserDefaults监控失败: " + e.message);
    }
}

// Hook内存操作
function hookMemoryOperations() {
    console.log("[启动] 内存操作监控...");
    
    try {
        // Hook memcpy
        var memcpy = Module.findExportByName("libsystem_c.dylib", "memcpy");
        if (memcpy) {
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    if (size >= 4 && size <= 8) {
                        try {
                            var value = Memory.readU32(args[1]);
                            if (value > 1000000 && value <= 100000000000) {
                                console.log("🧠 [内存] 大数值写入: " + value + " (大小: " + size + ")");
                                g_lastOperationTime = Date.now();
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        console.log("✅ 内存操作监控已启动");
    } catch (e) {
        console.log("❌ 内存操作监控失败: " + e.message);
    }
}

// 状态报告
function startStatusReporting() {
    console.log("[启动] 状态报告...");
    
    // 每10秒报告一次状态
    setInterval(function() {
        var now = Date.now();
        var timeSinceLastOp = now - g_lastOperationTime;
        
        console.log("\n📊 [状态报告] " + new Date().toLocaleTimeString());
        console.log("📝 已捕获操作: " + g_capturedOperations.length + " 个");
        
        if (timeSinceLastOp > 15000) {
            console.log("⏰ [提醒] 请在手机上操作其他修改器");
            console.log("💡 [提示] 开启/关闭修改器功能，我们正在监听");
        } else {
            console.log("✅ [活跃] 检测到最近活动");
        }
        
        // 显示最近的操作
        if (g_capturedOperations.length > 0) {
            console.log("📋 [最近操作]:");
            var recentOps = g_capturedOperations.slice(-5);
            recentOps.forEach(function(op, index) {
                console.log("  " + (index + 1) + ". " + op.type + ": " + op.key + " = " + op.value.substring(0, 30));
            });
        }
        
        console.log("");
    }, 10000);
    
    // 每30秒生成分析报告
    setInterval(function() {
        if (g_capturedOperations.length >= 5) {
            generateAnalysisReport();
        }
    }, 30000);
}

// 生成分析报告
function generateAnalysisReport() {
    console.log("\n" + "=".repeat(60));
    console.log("📊 修改器操作分析报告");
    console.log("=".repeat(60));
    
    // 统计操作类型
    var typeCount = {};
    var keyCount = {};
    var valuePatterns = [];
    
    g_capturedOperations.forEach(function(op) {
        typeCount[op.type] = (typeCount[op.type] || 0) + 1;
        keyCount[op.key] = (keyCount[op.key] || 0) + 1;
        
        // 分析数值模式
        if (op.type === 'setInteger' && op.value > 100000) {
            valuePatterns.push({
                key: op.key,
                value: op.value,
                time: op.time
            });
        }
    });
    
    console.log("📈 操作类型统计:");
    Object.keys(typeCount).forEach(function(type) {
        console.log("  " + type + ": " + typeCount[type] + " 次");
    });
    
    console.log("\n🔑 热门键名:");
    var sortedKeys = Object.keys(keyCount).sort(function(a, b) {
        return keyCount[b] - keyCount[a];
    });
    sortedKeys.slice(0, 10).forEach(function(key) {
        console.log("  " + key + ": " + keyCount[key] + " 次");
    });
    
    if (valuePatterns.length > 0) {
        console.log("\n💰 大数值修改模式:");
        valuePatterns.forEach(function(pattern) {
            console.log("  " + pattern.key + " = " + pattern.value + " (" + pattern.time + ")");
        });
    }
    
    // 生成修改器代码
    if (valuePatterns.length >= 3) {
        console.log("\n🎉 检测到足够的修改器操作，生成代码:");
        generateCheatCode(valuePatterns);
    }
    
    console.log("=".repeat(60) + "\n");
}

// 生成修改器代码
function generateCheatCode(patterns) {
    console.log("\n// ========== 自动生成的修改器代码 ==========");
    
    // Frida版本
    console.log("// Frida版本:");
    console.log("setTimeout(function() {");
    console.log("    var NSUserDefaults = ObjC.classes.NSUserDefaults;");
    console.log("    var defaults = NSUserDefaults.standardUserDefaults();");
    console.log("    ");
    console.log("    console.log('🚀 执行学习到的修改器...');");
    
    patterns.forEach(function(pattern) {
        console.log("    defaults.setInteger_forKey_(" + pattern.value + ", '" + pattern.key + "');");
        console.log("    console.log('✅ 修改 " + pattern.key + " = " + pattern.value + "');");
    });
    
    console.log("    ");
    console.log("    defaults.synchronize();");
    console.log("    console.log('🎉 修改器执行完成！');");
    console.log("}, 3000);");
    
    // Objective-C版本
    console.log("\n// Objective-C版本:");
    console.log("static void executeLearnedCheat(void) {");
    console.log("    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];");
    console.log("    NSLog(@\"🚀 执行学习到的修改器...\");");
    console.log("    ");
    
    patterns.forEach(function(pattern) {
        console.log("    [defaults setInteger:" + pattern.value + " forKey:@\"" + pattern.key + "\"];");
        console.log("    NSLog(@\"✅ 修改 " + pattern.key + " = " + pattern.value + "\");");
    });
    
    console.log("    ");
    console.log("    [defaults synchronize];");
    console.log("    NSLog(@\"🎉 修改器执行完成！\");");
    console.log("}");
    
    console.log("// ==========================================");
}

console.log("📋 实时修改器捕获脚本已准备就绪");
console.log("💡 请在手机上操作其他修改器，我们将实时学习其操作");