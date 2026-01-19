// 实时复制其他修改器的操作方法
console.log("🎯 修改器操作复制脚本已加载");

// 全局变量存储捕获的操作
var g_capturedOperations = [];
var g_gameValues = new Map();
var g_modificationPatterns = [];

setTimeout(function() {
    console.log("🎯 开始实时监控和复制修改器操作...");
    
    // 1. 监控所有数值修改操作
    captureValueModifications();
    
    // 2. 监控存档操作
    captureSaveOperations();
    
    // 3. 监控内存操作
    captureMemoryOperations();
    
    // 4. 生成可复制的代码
    generateReproducibleCode();
    
    console.log("=".repeat(60));
    console.log("🎯 修改器操作复制系统已启动！");
    console.log("💡 现在运行其他修改器，系统将记录并生成可复制的代码");
    console.log("=".repeat(60));
    
}, 1000);

// 捕获数值修改操作
function captureValueModifications() {
    console.log("[捕获] 数值修改操作...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        if (NSUserDefaults) {
            
            // 捕获 setInteger:forKey:
            var setInteger = NSUserDefaults['- setInteger:forKey:'];
            if (setInteger) {
                Interceptor.attach(setInteger.implementation, {
                    onEnter: function(args) {
                        var value = args[2].toInt32();
                        var key = ObjC.Object(args[3]).toString();
                        
                        // 记录大数值修改
                        if (value > 100000 || value === 999999999 || value === 21000000000) {
                            var operation = {
                                type: "setInteger",
                                key: key,
                                value: value,
                                timestamp: Date.now(),
                                method: "NSUserDefaults setInteger:forKey:"
                            };
                            
                            g_capturedOperations.push(operation);
                            g_gameValues.set(key, value);
                            
                            console.log("📝 [捕获] setInteger: " + value + " forKey: " + key);
                            
                            // 生成对应的代码
                            generateCodeForOperation(operation);
                        }
                    }
                });
            }
            
            // 捕获 setObject:forKey:
            var setObject = NSUserDefaults['- setObject:forKey:'];
            if (setObject) {
                Interceptor.attach(setObject.implementation, {
                    onEnter: function(args) {
                        var obj = ObjC.Object(args[2]);
                        var key = ObjC.Object(args[3]).toString();
                        
                        // 检查对象类型和值
                        var operation = {
                            type: "setObject",
                            key: key,
                            object: obj.toString(),
                            timestamp: Date.now(),
                            method: "NSUserDefaults setObject:forKey:"
                        };
                        
                        // 如果是数字对象，获取数值
                        if (obj && obj.respondsToSelector_(ObjC.selector('integerValue'))) {
                            var value = obj.integerValue();
                            operation.value = value;
                            g_gameValues.set(key, value);
                            
                            if (value > 100000) {
                                console.log("📝 [捕获] setObject: " + obj + " (" + value + ") forKey: " + key);
                                g_capturedOperations.push(operation);
                                generateCodeForOperation(operation);
                            }
                        }
                        // 如果是字符串对象（可能是 JSON 或 Base64）
                        else if (obj && obj.isKindOfClass_(ObjC.classes.NSString)) {
                            var str = obj.toString();
                            if (str.length > 1000) {
                                operation.isLargeString = true;
                                operation.stringLength = str.length;
                                console.log("📝 [捕获] setObject 大字符串: " + key + " (长度: " + str.length + ")");
                                
                                // 检查是否是 Base64 编码的数据
                                if (str.match(/^[A-Za-z0-9+/]+=*$/)) {
                                    operation.isBase64 = true;
                                    console.log("   可能是 Base64 编码数据");
                                }
                                
                                g_capturedOperations.push(operation);
                                generateCodeForOperation(operation);
                            }
                        }
                    }
                });
            }
            
            console.log("✅ NSUserDefaults 操作捕获已启动");
        }
    } catch (e) {
        console.log("❌ 数值修改捕获失败: " + e.message);
    }
}

// 捕获存档操作
function captureSaveOperations() {
    console.log("[捕获] 存档操作...");
    
    try {
        // 监控文件写入操作
        var fwrite = Module.findExportByName("libsystem_c.dylib", "fwrite");
        if (fwrite) {
            Interceptor.attach(fwrite, {
                onEnter: function(args) {
                    var size = args[1].toInt32();
                    var count = args[2].toInt32();
                    var totalSize = size * count;
                    
                    if (totalSize > 1000 && totalSize < 1000000) {
                        try {
                            var data = Memory.readUtf8String(args[0], Math.min(totalSize, 500));
                            if (data && (data.includes("UnityEngine") || data.includes("GameObject") || 
                                        data.includes("999999") || data.includes("21000000000"))) {
                                
                                var operation = {
                                    type: "fileWrite",
                                    size: totalSize,
                                    data: data.substring(0, 200),
                                    timestamp: Date.now(),
                                    method: "fwrite"
                                };
                                
                                console.log("💾 [捕获] 文件写入游戏数据: " + totalSize + " bytes");
                                console.log("   数据预览: " + data.substring(0, 100) + "...");
                                
                                g_capturedOperations.push(operation);
                                generateCodeForOperation(operation);
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        console.log("✅ 存档操作捕获已启动");
    } catch (e) {
        console.log("❌ 存档操作捕获失败: " + e.message);
    }
}

// 捕获内存操作
function captureMemoryOperations() {
    console.log("[捕获] 内存操作...");
    
    try {
        // 监控内存写入
        var memcpy = Module.findExportByName("libsystem_c.dylib", "memcpy");
        if (memcpy) {
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    if (size >= 4 && size <= 8) {
                        try {
                            var value = Memory.readU32(args[1]);
                            if (value === 999999999 || value === 21000000000 || 
                                (value > 1000000 && value < 100000000000)) {
                                
                                var operation = {
                                    type: "memoryWrite",
                                    targetAddress: args[0].toString(),
                                    sourceAddress: args[1].toString(),
                                    value: value,
                                    size: size,
                                    timestamp: Date.now(),
                                    method: "memcpy"
                                };
                                
                                console.log("🧠 [捕获] 内存写入: " + value + " 到地址 " + args[0]);
                                
                                g_capturedOperations.push(operation);
                                generateCodeForOperation(operation);
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        console.log("✅ 内存操作捕获已启动");
    } catch (e) {
        console.log("❌ 内存操作捕获失败: " + e.message);
    }
}

// 为捕获的操作生成可复制的代码
function generateCodeForOperation(operation) {
    var code = "";
    
    switch (operation.type) {
        case "setInteger":
            code = generateNSUserDefaultsIntegerCode(operation);
            break;
        case "setObject":
            code = generateNSUserDefaultsObjectCode(operation);
            break;
        case "fileWrite":
            code = generateFileWriteCode(operation);
            break;
        case "memoryWrite":
            code = generateMemoryWriteCode(operation);
            break;
    }
    
    if (code) {
        console.log("🔧 [生成代码] " + operation.type + ":");
        console.log(code);
        console.log("---");
    }
}

// 生成 NSUserDefaults setInteger 代码
function generateNSUserDefaultsIntegerCode(operation) {
    var objcCode = `// Objective-C 代码
NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
[defaults setInteger:${operation.value} forKey:@"${operation.key}"];
[defaults synchronize];`;

    var fridaCode = `// Frida 代码
var NSUserDefaults = ObjC.classes.NSUserDefaults;
var defaults = NSUserDefaults.standardUserDefaults();
defaults.setInteger_forKey_(${operation.value}, "${operation.key}");
defaults.synchronize();`;

    return objcCode + "\n\n" + fridaCode;
}

// 生成 NSUserDefaults setObject 代码
function generateNSUserDefaultsObjectCode(operation) {
    if (operation.value !== undefined) {
        var objcCode = `// Objective-C 代码 (数字对象)
NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
[defaults setObject:@${operation.value} forKey:@"${operation.key}"];
[defaults synchronize];`;

        var fridaCode = `// Frida 代码 (数字对象)
var NSUserDefaults = ObjC.classes.NSUserDefaults;
var defaults = NSUserDefaults.standardUserDefaults();
var NSNumber = ObjC.classes.NSNumber;
var numberObj = NSNumber.numberWithInteger_(${operation.value});
defaults.setObject_forKey_(numberObj, "${operation.key}");
defaults.synchronize();`;

        return objcCode + "\n\n" + fridaCode;
    } else if (operation.isLargeString) {
        return `// 大字符串对象 (${operation.stringLength} 字符)
// 可能是游戏存档数据，需要进一步分析内容`;
    }
    
    return "";
}

// 生成文件写入代码
function generateFileWriteCode(operation) {
    return `// 文件写入操作
// 大小: ${operation.size} bytes
// 数据预览: ${operation.data}
// 这可能是游戏存档文件的写入操作`;
}

// 生成内存写入代码
function generateMemoryWriteCode(operation) {
    var fridaCode = `// Frida 内存写入代码
var targetAddr = ptr("${operation.targetAddress}");
Memory.writeU32(targetAddr, ${operation.value});

// 或者使用 memcpy 方式
var sourceData = Memory.alloc(4);
Memory.writeU32(sourceData, ${operation.value});
Memory.copy(targetAddr, sourceData, 4);`;

    return fridaCode;
}

// 生成完整的可复制代码
function generateReproducibleCode() {
    // 每10秒生成一次汇总代码
    setInterval(function() {
        if (g_capturedOperations.length > 0) {
            console.log("\n" + "=".repeat(60));
            console.log("📋 生成完整的可复制代码");
            console.log("=".repeat(60));
            
            // 按类型分组操作
            var integerOps = g_capturedOperations.filter(op => op.type === "setInteger");
            var objectOps = g_capturedOperations.filter(op => op.type === "setObject");
            var memoryOps = g_capturedOperations.filter(op => op.type === "memoryWrite");
            
            if (integerOps.length > 0) {
                console.log("// ========== NSUserDefaults setInteger 操作 ==========");
                console.log("static void modifyGameValues(void) {");
                console.log("    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];");
                
                integerOps.forEach(function(op) {
                    console.log(`    [defaults setInteger:${op.value} forKey:@"${op.key}"];`);
                });
                
                console.log("    [defaults synchronize];");
                console.log("}\n");
            }
            
            if (objectOps.length > 0) {
                console.log("// ========== NSUserDefaults setObject 操作 ==========");
                objectOps.forEach(function(op) {
                    if (op.value !== undefined) {
                        console.log(`[defaults setObject:@${op.value} forKey:@"${op.key}"];`);
                    }
                });
                console.log("");
            }
            
            if (memoryOps.length > 0) {
                console.log("// ========== 内存写入操作 ==========");
                console.log("// Frida 脚本:");
                memoryOps.forEach(function(op) {
                    console.log(`Memory.writeU32(ptr("${op.targetAddress}"), ${op.value});`);
                });
                console.log("");
            }
            
            // 生成 Frida 脚本版本
            console.log("// ========== 完整 Frida 脚本 ==========");
            console.log("setTimeout(function() {");
            console.log("    var NSUserDefaults = ObjC.classes.NSUserDefaults;");
            console.log("    var defaults = NSUserDefaults.standardUserDefaults();");
            console.log("    var NSNumber = ObjC.classes.NSNumber;");
            console.log("");
            
            integerOps.forEach(function(op) {
                console.log(`    defaults.setInteger_forKey_(${op.value}, "${op.key}");`);
            });
            
            objectOps.forEach(function(op) {
                if (op.value !== undefined) {
                    console.log(`    var num${op.timestamp} = NSNumber.numberWithInteger_(${op.value});`);
                    console.log(`    defaults.setObject_forKey_(num${op.timestamp}, "${op.key}");`);
                }
            });
            
            console.log("    defaults.synchronize();");
            console.log("    console.log('游戏数值修改完成！');");
            console.log("}, 3000);");
            
            console.log("=".repeat(60) + "\n");
            
            // 清空已处理的操作
            g_capturedOperations = [];
        }
    }, 15000); // 每15秒生成一次
}

// 分析修改模式
function analyzeModificationPatterns() {
    setInterval(function() {
        if (g_gameValues.size > 0) {
            console.log("\n📊 当前捕获的游戏数值:");
            g_gameValues.forEach(function(value, key) {
                console.log(`  ${key}: ${value}`);
            });
            console.log("");
        }
    }, 20000); // 每20秒显示一次当前数值
}

// 启动模式分析
analyzeModificationPatterns();

console.log("📋 [提示] 修改器操作复制系统加载完成，等待捕获操作...");