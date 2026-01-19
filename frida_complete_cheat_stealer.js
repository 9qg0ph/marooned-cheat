// 完整的修改器窃取系统 - 增强版
// 实时学习、分析、生成并部署我们自己的修改器
console.log("🎯 完整修改器窃取系统已加载 - 增强版");

// 全局数据存储
var g_learnedData = {
    values: new Map(),
    methods: [],
    classes: [],
    es3Operations: [],
    hookSequence: [],
    callStacks: [],
    timingPatterns: [],
    memoryWrites: [],
    fileOperations: [],
    networkRequests: []
};

var g_generatedFiles = [];
var g_analysisComplete = false;
var g_captureActive = true;
var g_lastActivity = Date.now();

setTimeout(function() {
    console.log("🎯 启动完整修改器窃取系统...");
    
    // 1. 全面Hook和监控
    setupComprehensiveHooks();
    
    // 2. 实时分析和学习
    startRealTimeAnalysis();
    
    // 3. 智能代码生成
    startIntelligentCodeGeneration();
    
    // 4. 自动文件生成
    startAutoFileGeneration();
    
    // 5. 活动监控
    startActivityMonitoring();
    
    console.log("=".repeat(60));
    console.log("🎯 完整修改器窃取系统已启动！");
    console.log("💡 系统将全面学习其他修改器并生成完整解决方案");
    console.log("📱 请在手机上操作其他修改器，我们将实时捕获");
    console.log("=".repeat(60));
    
}, 1000);

// 活动监控 - 检测用户是否在操作修改器
function startActivityMonitoring() {
    setInterval(function() {
        var now = Date.now();
        var timeSinceLastActivity = now - g_lastActivity;
        
        if (timeSinceLastActivity > 10000 && g_captureActive) {
            console.log("⏰ [提醒] 请在手机上操作其他修改器，我们正在等待捕获...");
            console.log("💡 [提示] 开启/关闭修改器功能，我们将学习其实现方式");
        }
        
        // 显示当前捕获状态
        if (g_learnedData.methods.length > 0) {
            console.log("📊 [状态] 已捕获 " + g_learnedData.methods.length + " 个操作");
        }
    }, 15000);
}

// 设置全面的Hook和监控
function setupComprehensiveHooks() {
    console.log("[Hook] 设置全面监控...");
    
    // Hook所有NSUserDefaults操作
    hookNSUserDefaults();
    
    // Hook所有可能的修改器类
    hookSuspiciousClasses();
    
    // Hook内存操作
    hookMemoryOperations();
    
    // Hook文件操作
    hookFileOperations();
    
    // Hook网络操作（如果修改器有云端功能）
    hookNetworkOperations();
}

// Hook NSUserDefaults的所有操作
function hookNSUserDefaults() {
    console.log("[Hook] NSUserDefaults全方位监控...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        // Hook所有set方法
        var setMethods = [
            '- setInteger:forKey:',
            '- setObject:forKey:',
            '- setBool:forKey:',
            '- setFloat:forKey:',
            '- setDouble:forKey:'
        ];
        
        setMethods.forEach(function(methodName) {
            var method = NSUserDefaults[methodName];
            if (method) {
                Interceptor.attach(method.implementation, {
                    onEnter: function(args) {
                        g_lastActivity = Date.now(); // 更新活动时间
                        
                        var key = ObjC.Object(args[3]).toString();
                        var value;
                        
                        if (methodName.includes('setInteger')) {
                            value = args[2].toInt32();
                        } else if (methodName.includes('setObject')) {
                            value = ObjC.Object(args[2]);
                        } else if (methodName.includes('setBool')) {
                            value = args[2];
                        } else {
                            value = args[2];
                        }
                        
                        // 记录所有修改操作
                        var operation = {
                            method: methodName,
                            key: key,
                            value: value.toString(),
                            timestamp: Date.now(),
                            callStack: Thread.backtrace(this.context, Backtracer.ACCURATE)
                        };
                        
                        g_learnedData.methods.push(operation);
                        
                        if (isImportantGameValue(key, value)) {
                            console.log("🎯 [重要修改] " + methodName + ": " + key + " = " + value);
                            console.log("🕐 [时间] " + new Date().toLocaleTimeString());
                            g_learnedData.values.set(key, value);
                            
                            // 分析调用栈
                            analyzeCallStack(operation.callStack, key, value);
                            
                            // 检查是否是ES3相关
                            if (key.toLowerCase().includes('es3')) {
                                g_learnedData.es3Operations.push(operation);
                                console.log("💾 [ES3操作] 检测到ES3存档操作: " + key);
                            }
                        }
                        
                        // 记录所有操作，不只是重要的
                        console.log("📝 [所有操作] " + methodName + ": " + key + " = " + value);
                    }
                });
            }
        });
        
        // Hook所有get方法 - 增强版
        var getMethods = [
            '- integerForKey:',
            '- objectForKey:',
            '- boolForKey:',
            '- floatForKey:',
            '- doubleForKey:'
        ];
        
        getMethods.forEach(function(methodName) {
            var method = NSUserDefaults[methodName];
            if (method) {
                Interceptor.attach(method.implementation, {
                    onEnter: function(args) {
                        this.key = ObjC.Object(args[2]).toString();
                        this.startTime = Date.now();
                    },
                    onLeave: function(retval) {
                        var value = retval;
                        if (methodName.includes('integerForKey')) {
                            value = retval.toInt32();
                        } else if (methodName.includes('objectForKey')) {
                            value = ObjC.Object(retval);
                        }
                        
                        if (isImportantGameValue(this.key, value)) {
                            console.log("📖 [重要读取] " + methodName + ": " + this.key + " = " + value);
                            
                            // 记录读取模式
                            g_learnedData.timingPatterns.push({
                                type: 'read',
                                key: this.key,
                                value: value.toString(),
                                duration: Date.now() - this.startTime,
                                timestamp: Date.now()
                            });
                        }
                        
                        // 记录所有读取操作
                        if (this.key && this.key.length > 0) {
                            console.log("👁️ [读取] " + methodName + ": " + this.key + " = " + value);
                        }
                    }
                });
            }
        });
        
        console.log("✅ NSUserDefaults全方位监控已启动");
    } catch (e) {
        console.log("❌ NSUserDefaults监控失败: " + e.message);
    }
}

// Hook可疑的修改器类
function hookSuspiciousClasses() {
    console.log("[Hook] 搜索和Hook修改器类...");
    
    try {
        // 扩展的可疑类名列表
        var suspiciousNames = [
            "FanhanGGEngine", "GameForFun", "CheatEngine", "HackTool",
            "ModEngine", "TrainerEngine", "GameHacker", "ValueModifier",
            "CashModifier", "EnergyModifier", "HealthModifier", "MoodModifier",
            "GameManager", "DataManager", "SaveManager", "PlayerManager",
            "ResourceManager", "CurrencyManager", "StatsManager"
        ];
        
        // 搜索所有类
        var allClasses = Object.keys(ObjC.classes);
        var foundClasses = [];
        
        allClasses.forEach(function(className) {
            var lowerName = className.toLowerCase();
            
            // 检查是否匹配可疑名称
            var isSuspicious = suspiciousNames.some(function(suspName) {
                return lowerName.includes(suspName.toLowerCase());
            });
            
            // 或者包含修改器关键词
            if (!isSuspicious) {
                var keywords = ['cheat', 'hack', 'mod', 'trainer', 'engine', 'gg'];
                isSuspicious = keywords.some(function(keyword) {
                    return lowerName.includes(keyword);
                });
            }
            
            if (isSuspicious) {
                foundClasses.push(className);
                console.log("🎯 [发现类] " + className);
                
                g_learnedData.classes.push({
                    name: className,
                    methods: [],
                    timestamp: Date.now()
                });
                
                // Hook这个类的所有方法
                hookClassMethods(className);
            }
        });
        
        console.log("✅ 发现并Hook了 " + foundClasses.length + " 个可疑类");
    } catch (e) {
        console.log("❌ 修改器类搜索失败: " + e.message);
    }
}

// Hook指定类的所有方法
function hookClassMethods(className) {
    try {
        var cls = ObjC.classes[className];
        var methods = cls.$ownMethods;
        
        console.log("📋 [" + className + "] 发现 " + methods.length + " 个方法");
        
        methods.forEach(function(methodName) {
            try {
                Interceptor.attach(cls[methodName].implementation, {
                    onEnter: function(args) {
                        console.log("🔧 [调用] " + className + "." + methodName);
                        
                        // 记录方法调用
                        var methodCall = {
                            className: className,
                            methodName: methodName,
                            args: [],
                            timestamp: Date.now(),
                            callStack: Thread.backtrace(this.context, Backtracer.ACCURATE)
                        };
                        
                        // 记录参数
                        for (var i = 0; i < Math.min(args.length, 5); i++) {
                            try {
                                var arg = ObjC.Object(args[i]);
                                methodCall.args.push(arg.toString());
                                console.log("    参数[" + i + "]: " + arg);
                            } catch (e) {
                                methodCall.args.push(args[i].toString());
                                console.log("    参数[" + i + "]: " + args[i]);
                            }
                        }
                        
                        g_learnedData.hookSequence.push(methodCall);
                        
                        // 更新类信息
                        var classInfo = g_learnedData.classes.find(function(c) {
                            return c.name === className;
                        });
                        if (classInfo) {
                            classInfo.methods.push(methodCall);
                        }
                    }
                });
                
                console.log("✅ 已Hook: " + className + "." + methodName);
            } catch (e) {
                // 某些方法可能无法Hook，忽略错误
            }
        });
    } catch (e) {
        console.log("❌ Hook类方法失败: " + className + " - " + e.message);
    }
}

// Hook内存操作
function hookMemoryOperations() {
    console.log("[Hook] 内存操作监控...");
    
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
                            if (isImportantNumericValue(value)) {
                                console.log("🧠 [内存写入] 重要数值: " + value + " (大小: " + size + ")");
                                
                                g_learnedData.methods.push({
                                    method: "memcpy",
                                    targetAddr: args[0].toString(),
                                    value: value,
                                    size: size,
                                    timestamp: Date.now()
                                });
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        // Hook vm_write
        var vm_write = Module.findExportByName("libsystem_kernel.dylib", "vm_write");
        if (vm_write) {
            Interceptor.attach(vm_write, {
                onEnter: function(args) {
                    var size = args[3].toInt32();
                    if (size >= 4 && size <= 8) {
                        try {
                            var value = Memory.readU32(args[2]);
                            if (isImportantNumericValue(value)) {
                                console.log("🧠 [虚拟内存] 重要数值: " + value);
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

// Hook文件操作
function hookFileOperations() {
    console.log("[Hook] 文件操作监控...");
    
    try {
        // Hook fwrite
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
                            if (data && (data.includes("999999") || data.includes("21000000000") || 
                                        data.includes("UnityEngine") || data.includes("GameObject"))) {
                                console.log("💾 [文件写入] 游戏数据: " + totalSize + " bytes");
                                console.log("   内容预览: " + data.substring(0, 100) + "...");
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        console.log("✅ 文件操作监控已启动");
    } catch (e) {
        console.log("❌ 文件操作监控失败: " + e.message);
    }
}

// Hook网络操作
function hookNetworkOperations() {
    console.log("[Hook] 网络操作监控...");
    
    try {
        // Hook NSURLSession
        var NSURLSession = ObjC.classes.NSURLSession;
        if (NSURLSession) {
            var dataTask = NSURLSession['- dataTaskWithRequest:completionHandler:'];
            if (dataTask) {
                Interceptor.attach(dataTask.implementation, {
                    onEnter: function(args) {
                        var request = ObjC.Object(args[2]);
                        if (request) {
                            var url = request.URL();
                            if (url) {
                                console.log("🌐 [网络请求] " + url.absoluteString());
                            }
                        }
                    }
                });
            }
        }
        
        console.log("✅ 网络操作监控已启动");
    } catch (e) {
        console.log("❌ 网络操作监控失败: " + e.message);
    }
}

// 实时分析和学习
function startRealTimeAnalysis() {
    console.log("[分析] 启动实时分析...");
    
    // 每10秒进行一次分析
    setInterval(function() {
        if (g_learnedData.methods.length > 0) {
            analyzeLearnedData();
        }
    }, 10000);
}

// 分析学习到的数据
function analyzeLearnedData() {
    console.log("\n📊 [实时分析] 分析学习数据...");
    
    // 分析数值模式
    var valuePatterns = analyzeValuePatterns();
    
    // 分析调用模式
    var callPatterns = analyzeCallPatterns();
    
    // 分析时序模式
    var timingPatterns = analyzeTimingPatterns();
    
    console.log("📈 [分析结果]:");
    console.log("  数值模式: " + valuePatterns.length + " 个");
    console.log("  调用模式: " + callPatterns.length + " 个");
    console.log("  时序模式: " + timingPatterns.length + " 个");
    
    // 如果分析足够，标记为完成
    if (valuePatterns.length >= 5 && callPatterns.length >= 3) {
        g_analysisComplete = true;
        console.log("✅ 分析完成，可以生成修改器代码");
    }
}

// 分析数值模式
function analyzeValuePatterns() {
    var patterns = [];
    var valueGroups = {};
    
    g_learnedData.values.forEach(function(value, key) {
        var category = categorizeKey(key);
        if (!valueGroups[category]) {
            valueGroups[category] = [];
        }
        valueGroups[category].push({ key: key, value: value });
    });
    
    Object.keys(valueGroups).forEach(function(category) {
        if (valueGroups[category].length > 0) {
            patterns.push({
                category: category,
                values: valueGroups[category],
                count: valueGroups[category].length
            });
        }
    });
    
    return patterns;
}

// 分析调用模式
function analyzeCallPatterns() {
    var patterns = [];
    var methodCounts = {};
    
    g_learnedData.methods.forEach(function(method) {
        var key = method.method + ":" + method.key;
        methodCounts[key] = (methodCounts[key] || 0) + 1;
    });
    
    Object.keys(methodCounts).forEach(function(key) {
        if (methodCounts[key] >= 2) {
            patterns.push({
                pattern: key,
                count: methodCounts[key]
            });
        }
    });
    
    return patterns;
}

// 分析时序模式
function analyzeTimingPatterns() {
    return g_learnedData.timingPatterns.slice(-10); // 返回最近10个
}

// 智能代码生成
function startIntelligentCodeGeneration() {
    console.log("[生成] 启动智能代码生成...");
    
    // 每30秒检查是否可以生成代码
    setInterval(function() {
        if (g_analysisComplete && g_generatedFiles.length === 0) {
            generateCompleteCheatSolution();
        }
    }, 30000);
}

// 生成完整的修改器解决方案
function generateCompleteCheatSolution() {
    console.log("\n🏭 [生成] 创建完整修改器解决方案...");
    
    // 生成多个版本的修改器
    var solutions = {
        objectiveC: generateObjectiveCCheat(),
        frida: generateFridaCheat(),
        dylib: generateDylibCheat(),
        hookScript: generateHookScript()
    };
    
    // 保存生成的代码
    Object.keys(solutions).forEach(function(type) {
        g_generatedFiles.push({
            type: type,
            code: solutions[type],
            timestamp: Date.now()
        });
    });
    
    console.log("🎉 完整修改器解决方案生成完成！");
    displayGeneratedSolutions(solutions);
}

// 生成Objective-C修改器
function generateObjectiveCCheat() {
    var code = `
// 自动生成的我独自生活修改器
// 基于完整学习其他修改器的行为模式
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface LearnedCheat : NSObject
+ (void)executeCheat;
+ (void)modifyValues;
+ (void)modifyES3Data;
@end

@implementation LearnedCheat

+ (void)executeCheat {
    NSLog(@"🚀 执行学习到的修改器...");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self modifyValues];
        [self modifyES3Data];
        NSLog(@"✅ 修改器执行完成");
    });
}

+ (void)modifyValues {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 基于学习到的数值模式`;
    
    g_learnedData.values.forEach(function(value, key) {
        if (typeof value === 'number' && value > 1000) {
            code += `\n    [defaults setInteger:${value} forKey:@"${key}"];`;
        }
    });
    
    code += `
    
    [defaults synchronize];
    NSLog(@"💰 数值修改完成");
}

+ (void)modifyES3Data {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 基于学习到的ES3操作模式`;
    
    var es3Keys = [];
    g_learnedData.es3Operations.forEach(function(op) {
        if (es3Keys.indexOf(op.key) === -1) {
            es3Keys.push(op.key);
        }
    });
    
    es3Keys.forEach(function(key) {
        if (!key.includes("timestamp")) {
            code += `
    
    NSString *es3Data = [defaults objectForKey:@"${key}"];
    if (es3Data) {
        NSLog(@"📦 处理ES3存档: ${key}");
        // 更新时间戳
        NSNumber *timestamp = @([[NSDate date] timeIntervalSince1970] * 1000000);
        [defaults setObject:timestamp forKey:@"timestamp_${key}"];
    }`;
        }
    });
    
    code += `
    
    [defaults synchronize];
    NSLog(@"💾 ES3数据修改完成");
}

@end

// 构造函数
__attribute__((constructor))
static void LearnedCheatInit(void) {
    @autoreleasepool {
        NSLog(@"🧠 学习型修改器已加载");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [LearnedCheat executeCheat];
        });
    }
}`;
    
    return code;
}

// 生成Frida修改器
function generateFridaCheat() {
    var code = `
// 自动生成的Frida修改器
// 基于完整学习其他修改器的行为模式

setTimeout(function() {
    console.log("🧠 执行学习型Frida修改器...");
    
    var NSUserDefaults = ObjC.classes.NSUserDefaults;
    var defaults = NSUserDefaults.standardUserDefaults();
    var NSNumber = ObjC.classes.NSNumber;
    var NSDate = ObjC.classes.NSDate;
    
    try {
        // 基于学习到的数值修改`;
        
    g_learnedData.values.forEach(function(value, key) {
        if (typeof value === 'number' && value > 1000) {
            code += `\n        defaults.setInteger_forKey_(${value}, "${key}");`;
            code += `\n        console.log("✅ 修改 ${key} = ${value}");`;
        }
    });
    
    code += `
        
        // 基于学习到的ES3操作`;
        
    var es3Keys = [];
    g_learnedData.es3Operations.forEach(function(op) {
        if (es3Keys.indexOf(op.key) === -1 && !op.key.includes("timestamp")) {
            es3Keys.push(op.key);
        }
    });
    
    es3Keys.forEach(function(key) {
        code += `
        
        var es3Data_${key.replace(/[^a-zA-Z0-9]/g, '_')} = defaults.objectForKey_("${key}");
        if (es3Data_${key.replace(/[^a-zA-Z0-9]/g, '_')}) {
            console.log("📦 处理ES3存档: ${key}");
            var timestamp = NSNumber.numberWithLongLong_(NSDate.date().timeIntervalSince1970() * 1000000);
            defaults.setObject_forKey_(timestamp, "timestamp_${key}");
        }`;
    });
    
    code += `
        
        defaults.synchronize();
        console.log("🎉 学习型修改器执行完成！");
        
    } catch (e) {
        console.log("❌ 修改器执行失败: " + e.message);
    }
    
}, 3000);`;
    
    return code;
}

// 生成Dylib修改器
function generateDylibCheat() {
    return `
// Dylib版本修改器
// 将Objective-C代码编译为动态库

// Makefile:
/*
ARCHS = arm64
TARGET = iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = LearnedCheat
LearnedCheat_FILES = LearnedCheat.m
LearnedCheat_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/library.mk
*/

// 编译步骤:
// 1. 将Objective-C代码保存为 LearnedCheat.m
// 2. 创建上述Makefile
// 3. 运行: make package
// 4. 将生成的.dylib注入到游戏中`;
}

// 生成Hook脚本
function generateHookScript() {
    var code = `
// 学习到的Hook脚本
// 可以继续学习和改进

console.log("🎯 执行学习到的Hook脚本...");

// 学习到的重要类:`;

    g_learnedData.classes.forEach(function(cls) {
        code += `\n// ${cls.name} - 发现 ${cls.methods.length} 个方法调用`;
    });
    
    code += `

// 学习到的重要方法调用序列:`;
    
    g_learnedData.hookSequence.slice(-10).forEach(function(call, index) {
        code += `\n// ${index + 1}. ${call.className}.${call.methodName}`;
    });
    
    code += `

// 可以基于以上信息继续深入分析和Hook`;
    
    return code;
}

// 显示生成的解决方案
function displayGeneratedSolutions(solutions) {
    console.log("\n" + "=".repeat(80));
    console.log("🎉 完整修改器解决方案已生成");
    console.log("=".repeat(80));
    
    Object.keys(solutions).forEach(function(type) {
        console.log("\n// ========== " + type.toUpperCase() + " 版本 ==========");
        console.log(solutions[type]);
    });
    
    console.log("\n" + "=".repeat(80));
    console.log("💡 解决方案包含:");
    console.log("  1. Objective-C 版本 - 可编译为dylib");
    console.log("  2. Frida 版本 - 可直接运行");
    console.log("  3. Dylib 版本 - 编译指南");
    console.log("  4. Hook 脚本 - 继续学习用");
    console.log("=".repeat(80));
}

// 自动文件生成
function startAutoFileGeneration() {
    console.log("[文件] 启动自动文件生成...");
    
    // 这里可以添加自动保存生成代码到文件的逻辑
    // 由于Frida环境限制，主要用于显示
}

// 辅助函数
function isImportantGameValue(key, value) {
    if (typeof key !== 'string') return false;
    
    var lowerKey = key.toLowerCase();
    var gameKeywords = [
        'cash', 'money', 'coin', '现金', '金钱', '金币',
        'energy', 'stamina', 'power', '体力', '能量',
        'health', 'hp', 'life', '健康', '血量',
        'mood', 'happiness', 'spirit', '心情',
        'exp', 'experience', '经验', 'level', '等级'
    ];
    
    var hasKeyword = gameKeywords.some(function(keyword) {
        return lowerKey.includes(keyword);
    });
    
    if (!hasKeyword) return false;
    
    // 检查数值范围
    if (typeof value === 'number') {
        return value > 100 && value <= 100000000000;
    }
    
    if (value && typeof value.integerValue === 'function') {
        var intVal = value.integerValue();
        return intVal > 100 && intVal <= 100000000000;
    }
    
    return false;
}

function isImportantNumericValue(value) {
    return value > 1000000 && value <= 100000000000;
}

function categorizeKey(key) {
    var lowerKey = key.toLowerCase();
    
    if (lowerKey.includes('cash') || lowerKey.includes('money') || lowerKey.includes('现金') || lowerKey.includes('金钱')) {
        return 'cash';
    }
    if (lowerKey.includes('energy') || lowerKey.includes('stamina') || lowerKey.includes('体力')) {
        return 'energy';
    }
    if (lowerKey.includes('health') || lowerKey.includes('hp') || lowerKey.includes('健康')) {
        return 'health';
    }
    if (lowerKey.includes('mood') || lowerKey.includes('happiness') || lowerKey.includes('心情')) {
        return 'mood';
    }
    
    return 'other';
}

function analyzeCallStack(callStack, key, value) {
    try {
        var symbols = callStack.map(DebugSymbol.fromAddress);
        var relevantFrames = symbols.slice(0, 5);
        
        g_learnedData.callStacks.push({
            key: key,
            value: value,
            frames: relevantFrames.map(function(frame) {
                return frame.toString();
            }),
            timestamp: Date.now()
        });
    } catch (e) {
        // 忽略调用栈分析错误
    }
}

console.log("📋 [提示] 完整修改器窃取系统加载完成...");