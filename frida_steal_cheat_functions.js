// 窃取其他修改器的功能脚本 - 增强版
// 专门用于Hook和复制其他作者的修改器实现
console.log("🕵️ 修改器功能窃取脚本已加载 - 增强版");

// 全局变量存储捕获的功能
var g_capturedFunctions = [];
var g_capturedClasses = [];
var g_capturedMethods = [];
var g_capturedValues = new Map();
var g_modificationSequence = [];
var g_realTimeCapture = true;
var g_lastCaptureTime = 0;

setTimeout(function() {
    console.log("🕵️ 开始窃取其他修改器的功能...");
    
    // 1. Hook所有可能的修改器类和方法
    hookCheatClasses();
    
    // 2. 监控修改器的数值操作
    monitorValueModifications();
    
    // 3. 捕获修改器的调用序列
    captureModificationSequence();
    
    // 4. 监控动态库和脚本加载
    monitorDynamicLoading();
    
    // 5. 生成我们自己的修改器代码
    generateOurCheatCode();
    
    console.log("=".repeat(60));
    console.log("🕵️ 修改器功能窃取系统已启动！");
    console.log("💡 现在运行其他修改器，我们将完全复制其功能");
    console.log("=".repeat(60));
    
}, 1000);

// Hook所有可能的修改器类和方法
function hookCheatClasses() {
    console.log("[窃取] 搜索修改器类和方法...");
    
    try {
        // 搜索所有可疑的修改器类
        var suspiciousClasses = [
            "FanhanGGEngine", "GameForFun", "CheatEngine", "HackTool", 
            "ModEngine", "TrainerEngine", "GameHacker", "ValueModifier",
            "CashModifier", "EnergyModifier", "HealthModifier"
        ];
        
        suspiciousClasses.forEach(function(className) {
            if (ObjC.classes[className]) {
                console.log("🎯 [发现] 修改器类: " + className);
                g_capturedClasses.push(className);
                
                // Hook这个类的所有方法
                var cls = ObjC.classes[className];
                var methods = cls.$ownMethods;
                
                console.log("📋 [" + className + "] 方法列表:");
                methods.forEach(function(method) {
                    console.log("  - " + method);
                    g_capturedMethods.push({
                        className: className,
                        methodName: method
                    });
                    
                    // Hook重要的方法
                    if (method.includes("setValue") || method.includes("modify") || 
                        method.includes("cheat") || method.includes("hack")) {
                        
                        try {
                            Interceptor.attach(cls[method].implementation, {
                                onEnter: function(args) {
                                    console.log("🔧 [窃取调用] " + className + "." + method);
                                    
                                    // 记录参数
                                    var capturedCall = {
                                        className: className,
                                        method: method,
                                        timestamp: Date.now(),
                                        args: []
                                    };
                                    
                                    for (var i = 0; i < Math.min(args.length, 5); i++) {
                                        try {
                                            var arg = ObjC.Object(args[i]);
                                            capturedCall.args.push(arg.toString());
                                            console.log("    参数[" + i + "]: " + arg);
                                        } catch (e) {
                                            capturedCall.args.push(args[i].toString());
                                            console.log("    参数[" + i + "]: " + args[i]);
                                        }
                                    }
                                    
                                    g_capturedFunctions.push(capturedCall);
                                }
                            });
                            
                            console.log("✅ 已Hook方法: " + className + "." + method);
                        } catch (e) {
                            console.log("❌ Hook失败: " + className + "." + method);
                        }
                    }
                });
            }
        });
        
        // 搜索所有包含修改器关键词的类
        var allClasses = Object.keys(ObjC.classes);
        allClasses.forEach(function(className) {
            var lowerName = className.toLowerCase();
            if (lowerName.includes("cheat") || lowerName.includes("hack") || 
                lowerName.includes("mod") || lowerName.includes("trainer") ||
                lowerName.includes("engine") && (lowerName.includes("game") || lowerName.includes("gg"))) {
                
                if (g_capturedClasses.indexOf(className) === -1) {
                    console.log("🎯 [发现] 可疑修改器类: " + className);
                    g_capturedClasses.push(className);
                    
                    // 简单Hook这个类的主要方法
                    try {
                        var cls = ObjC.classes[className];
                        var methods = cls.$ownMethods;
                        
                        methods.forEach(function(method) {
                            if (method.includes("set") || method.includes("modify") || 
                                method.includes("change") || method.includes("update")) {
                                
                                try {
                                    Interceptor.attach(cls[method].implementation, {
                                        onEnter: function(args) {
                                            console.log("🔧 [窃取] " + className + "." + method + " 被调用");
                                        }
                                    });
                                } catch (e) {}
                            }
                        });
                    } catch (e) {}
                }
            }
        });
        
        console.log("✅ 修改器类搜索完成，发现 " + g_capturedClasses.length + " 个类");
    } catch (e) {
        console.log("❌ 修改器类搜索失败: " + e.message);
    }
}

// 监控数值修改操作
function monitorValueModifications() {
    console.log("[窃取] 监控数值修改操作...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        // Hook setInteger:forKey: 来捕获数值修改
        var setInteger = NSUserDefaults['- setInteger:forKey:'];
        if (setInteger) {
            Interceptor.attach(setInteger.implementation, {
                onEnter: function(args) {
                    var value = args[2].toInt32();
                    var key = ObjC.Object(args[3]).toString();
                    
                    // 记录所有大数值的修改
                    if (value > 100000 || value === 999999999 || value === 21000000000) {
                        console.log("💰 [窃取数值] setInteger: " + key + " = " + value);
                        
                        g_capturedValues.set(key, value);
                        g_modificationSequence.push({
                            type: "setInteger",
                            key: key,
                            value: value,
                            timestamp: Date.now(),
                            stackTrace: Thread.backtrace(this.context, Backtracer.ACCURATE)
                        });
                        
                        // 分析调用栈，找出是哪个修改器调用的
                        var backtrace = Thread.backtrace(this.context, Backtracer.ACCURATE);
                        var symbols = backtrace.map(DebugSymbol.fromAddress);
                        
                        console.log("📍 [调用栈分析]:");
                        symbols.slice(0, 5).forEach(function(symbol, index) {
                            console.log("  " + index + ". " + symbol.toString());
                        });
                    }
                }
            });
        }
        
        // Hook setObject:forKey: 来捕获对象修改
        var setObject = NSUserDefaults['- setObject:forKey:'];
        if (setObject) {
            Interceptor.attach(setObject.implementation, {
                onEnter: function(args) {
                    var obj = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]).toString();
                    
                    // 检查ES3存档修改
                    if (key.includes("es3") || key.includes("ES3")) {
                        console.log("💾 [窃取存档] ES3存档修改: " + key);
                        if (obj && obj.isKindOfClass_(ObjC.classes.NSString)) {
                            console.log("  数据长度: " + obj.length());
                            
                            // 保存ES3数据用于分析
                            g_modificationSequence.push({
                                type: "setES3",
                                key: key,
                                dataLength: obj.length(),
                                timestamp: Date.now()
                            });
                        }
                    }
                    
                    // 检查数字对象
                    if (obj && obj.respondsToSelector_(ObjC.selector('integerValue'))) {
                        var value = obj.integerValue();
                        if (value > 100000) {
                            console.log("💰 [窃取对象] setObject: " + key + " = " + obj + " (" + value + ")");
                            g_capturedValues.set(key, value);
                        }
                    }
                }
            });
        }
        
        console.log("✅ 数值修改监控已启动");
    } catch (e) {
        console.log("❌ 数值修改监控失败: " + e.message);
    }
}

// 捕获修改序列
function captureModificationSequence() {
    console.log("[窃取] 捕获修改序列...");
    
    // 每5秒分析一次修改序列
    setInterval(function() {
        if (g_modificationSequence.length > 0) {
            console.log("\n📊 [修改序列分析] 捕获到 " + g_modificationSequence.length + " 个修改操作:");
            
            g_modificationSequence.forEach(function(op, index) {
                console.log("  " + (index + 1) + ". " + op.type + ": " + (op.key || "unknown") + 
                           " = " + (op.value || op.dataLength || "unknown"));
            });
            
            console.log("");
        }
    }, 5000);
}

// 监控动态库和脚本加载
function monitorDynamicLoading() {
    console.log("[窃取] 监控动态库加载...");
    
    try {
        // 监控 dlopen
        var dlopen = Module.findExportByName("libdyld.dylib", "dlopen");
        if (dlopen) {
            Interceptor.attach(dlopen, {
                onEnter: function(args) {
                    var path = Memory.readUtf8String(args[0]);
                    if (path && path.includes(".dylib")) {
                        console.log("📚 [窃取库] 加载动态库: " + path);
                        
                        // 检查是否是修改器相关的库
                        if (path.includes("cheat") || path.includes("hack") || 
                            path.includes("mod") || path.includes("trainer") ||
                            path.includes("gg") || path.includes("engine")) {
                            
                            console.log("🚨 [发现] 修改器动态库: " + path);
                            
                            // 延迟分析这个库的导出函数
                            setTimeout(function() {
                                analyzeLoadedLibrary(path);
                            }, 1000);
                        }
                    }
                }
            });
        }
        
        console.log("✅ 动态库加载监控已启动");
    } catch (e) {
        console.log("❌ 动态库加载监控失败: " + e.message);
    }
}

// 分析加载的库
function analyzeLoadedLibrary(libPath) {
    try {
        console.log("🔍 [分析库] " + libPath);
        
        var modules = Process.enumerateModules();
        modules.forEach(function(module) {
            if (module.path.includes(libPath) || module.name.includes(libPath)) {
                console.log("📋 [库信息] " + module.name + " - " + module.base);
                
                // 枚举导出函数
                var exports = module.enumerateExports();
                exports.forEach(function(exp) {
                    if (exp.name && (exp.name.includes("cheat") || exp.name.includes("modify") || 
                                    exp.name.includes("set") || exp.name.includes("hack"))) {
                        console.log("🎯 [发现函数] " + exp.name + " @ " + exp.address);
                        
                        // 尝试Hook这个函数
                        try {
                            Interceptor.attach(exp.address, {
                                onEnter: function(args) {
                                    console.log("🔧 [窃取调用] " + exp.name + " 被调用");
                                }
                            });
                        } catch (e) {}
                    }
                });
            }
        });
    } catch (e) {
        console.log("❌ 库分析失败: " + e.message);
    }
}

// 生成我们自己的修改器代码
function generateOurCheatCode() {
    // 每30秒生成一次代码
    setInterval(function() {
        if (g_capturedFunctions.length > 0 || g_capturedValues.size > 0) {
            console.log("\n" + "=".repeat(60));
            console.log("🎉 生成我们自己的修改器代码");
            console.log("=".repeat(60));
            
            // 生成Objective-C版本
            generateObjectiveCCode();
            
            // 生成Frida版本
            generateFridaCode();
            
            console.log("=".repeat(60));
            console.log("💡 代码已生成，可以直接使用！");
            console.log("=".repeat(60) + "\n");
        }
    }, 30000);
}

// 生成Objective-C代码
function generateObjectiveCCode() {
    console.log("// ========== 我们的修改器 - Objective-C版本 ==========");
    console.log(`
// 基于窃取的修改器功能生成
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 修改游戏数值的主函数
static void modifyGameValues(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSLog(@"🚀 开始修改游戏数值...");`);
    
    // 生成数值修改代码
    g_capturedValues.forEach(function(value, key) {
        console.log(`    [defaults setInteger:${value} forKey:@"${key}"];`);
        console.log(`    NSLog(@"✅ 修改 ${key} = ${value}");`);
    });
    
    console.log(`    
    [defaults synchronize];
    NSLog(@"🎉 游戏数值修改完成！");
}

// 构造函数
__attribute__((constructor))
static void OurCheatInit(void) {
    @autoreleasepool {
        NSLog(@"🎯 我们的修改器已加载");
        
        // 延迟3秒后修改数值
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            modifyGameValues();
        });
    }
}`);
}

// 生成Frida代码
function generateFridaCode() {
    console.log("\n// ========== 我们的修改器 - Frida版本 ==========");
    console.log(`
// 基于窃取的修改器功能生成
setTimeout(function() {
    console.log("🚀 开始修改游戏数值...");
    
    var NSUserDefaults = ObjC.classes.NSUserDefaults;
    var defaults = NSUserDefaults.standardUserDefaults();`);
    
    // 生成数值修改代码
    g_capturedValues.forEach(function(value, key) {
        console.log(`    defaults.setInteger_forKey_(${value}, "${key}");`);
        console.log(`    console.log("✅ 修改 ${key} = ${value}");`);
    });
    
    console.log(`    
    defaults.synchronize();
    console.log("🎉 游戏数值修改完成！");
    
}, 3000);`);
    
    // 如果捕获到了类和方法，也生成相应的调用代码
    if (g_capturedFunctions.length > 0) {
        console.log("\n// ========== 捕获到的修改器方法调用 ==========");
        g_capturedFunctions.forEach(function(func) {
            console.log(`// ${func.className}.${func.method}`);
            console.log(`// 参数: [${func.args.join(', ')}]`);
            
            if (func.className && ObjC.classes[func.className]) {
                console.log(`var ${func.className} = ObjC.classes.${func.className};`);
                console.log(`// 调用: ${func.className}.${func.method}`);
            }
        });
    }
}

console.log("📋 [提示] 修改器功能窃取系统加载完成...");