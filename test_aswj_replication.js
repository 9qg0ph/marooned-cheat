// ASWJGAMEPLUS 复制功能测试脚本
// 用于测试所有复制方案的有效性

console.log("[*] ASWJGAMEPLUS 复制功能测试开始");

class ASWJTester {
    constructor() {
        this.testResults = {};
        this.aswjModule = null;
        this.gameModule = null;
        this.init();
    }
    
    init() {
        console.log("[*] 初始化测试环境");
        this.findModules();
        this.runAllTests();
    }
    
    findModules() {
        // 查找 ASWJGAMEPLUS 模块
        this.aswjModule = Process.findModuleByName("ASWJGAMEPLUS.dylib");
        if (this.aswjModule) {
            console.log("[+] 找到 ASWJGAMEPLUS.dylib @ " + this.aswjModule.base);
        } else {
            console.log("[-] 未找到 ASWJGAMEPLUS.dylib");
        }
        
        // 查找游戏模块
        var modules = Process.enumerateModules();
        for (var i = 0; i < modules.length; i++) {
            var module = modules[i];
            if (module.name.indexOf("game.taptap.lantern.kbxx") !== -1) {
                this.gameModule = module;
                console.log("[+] 找到游戏模块: " + module.name);
                break;
            }
        }
    }
    
    runAllTests() {
        console.log("\n=== 开始全面测试 ===");
        
        // 测试1: 模块检测
        this.testModuleDetection();
        
        // 测试2: ObjC 类检测
        this.testObjCClasses();
        
        // 测试3: 函数地址验证
        this.testFunctionAddresses();
        
        // 测试4: 内存搜索
        this.testMemorySearch();
        
        // 测试5: Hook 设置
        this.testHookSetup();
        
        // 测试6: 实际功能调用
        this.testFunctionCalls();
        
        // 显示测试结果
        this.showResults();
    }
    
    testModuleDetection() {
        console.log("\n[测试1] 模块检测");
        
        this.testResults['aswj_module'] = this.aswjModule !== null;
        this.testResults['game_module'] = this.gameModule !== null;
        
        console.log("ASWJGAMEPLUS.dylib: " + (this.aswjModule ? "✓" : "✗"));
        console.log("游戏模块: " + (this.gameModule ? "✓" : "✗"));
        
        if (this.aswjModule) {
            console.log("  基址: " + this.aswjModule.base);
            console.log("  大小: " + this.aswjModule.size);
            console.log("  路径: " + this.aswjModule.path);
        }
    }
    
    testObjCClasses() {
        console.log("\n[测试2] ObjC 类检测");
        
        if (!ObjC.available) {
            console.log("✗ ObjC 运行时不可用");
            this.testResults['objc_available'] = false;
            return;
        }
        
        this.testResults['objc_available'] = true;
        console.log("✓ ObjC 运行时可用");
        
        // 检测关键类
        var keyClasses = ['shenling', 'UISwitch', 'UIApplication'];
        for (var i = 0; i < keyClasses.length; i++) {
            var className = keyClasses[i];
            var classExists = ObjC.classes[className] !== undefined;
            this.testResults['class_' + className] = classExists;
            console.log(className + ": " + (classExists ? "✓" : "✗"));
            
            if (classExists && className === 'shenling') {
                // 检测 shenling 的方法
                var shenling = ObjC.classes.shenling;
                var methods = shenling.$ownMethods;
                console.log("  shenling 方法数量: " + methods.length);
                
                // 查找关键方法
                var hasMyTitle = methods.indexOf('+ MyTitle:') !== -1;
                this.testResults['shenling_mytitle'] = hasMyTitle;
                console.log("  MyTitle 方法: " + (hasMyTitle ? "✓" : "✗"));
            }
        }
    }
    
    testFunctionAddresses() {
        console.log("\n[测试3] 函数地址验证");
        
        if (!this.aswjModule) {
            console.log("✗ 无法测试，ASWJGAMEPLUS 模块未找到");
            return;
        }
        
        var base = this.aswjModule.base;
        var addresses = {
            'enable': base.add(0x669a2c),
            'disable': base.add(0x94c684),
            'handler': base.add(0xfdc38)
        };
        
        for (var name in addresses) {
            var addr = addresses[name];
            try {
                // 尝试读取地址处的内容
                var data = addr.readU32();
                this.testResults['addr_' + name] = true;
                console.log(name + " @ " + addr + ": ✓ (0x" + data.toString(16) + ")");
            } catch(e) {
                this.testResults['addr_' + name] = false;
                console.log(name + " @ " + addr + ": ✗ (" + e + ")");
            }
        }
    }
    
    testMemorySearch() {
        console.log("\n[测试4] 内存搜索");
        
        if (!this.gameModule) {
            console.log("✗ 无法测试，游戏模块未找到");
            return;
        }
        
        // 搜索一些常见数值
        var testValues = [0, 1, 100, 1000];
        var totalFound = 0;
        
        for (var i = 0; i < testValues.length; i++) {
            var value = testValues[i];
            var found = this.searchValue(value);
            totalFound += found;
            console.log("搜索 " + value + ": 找到 " + found + " 个地址");
        }
        
        this.testResults['memory_search'] = totalFound > 0;
        console.log("内存搜索: " + (totalFound > 0 ? "✓" : "✗"));
    }
    
    searchValue(value) {
        var count = 0;
        var ranges = Process.enumerateRanges('rw-');
        
        for (var i = 0; i < Math.min(ranges.length, 10); i++) { // 限制搜索范围
            var range = ranges[i];
            try {
                var data = range.base.readByteArray(Math.min(range.size, 4096)); // 限制读取大小
                var view = new DataView(data);
                
                for (var offset = 0; offset < data.byteLength - 4; offset += 4) {
                    if (view.getInt32(offset, true) === value) {
                        count++;
                        if (count >= 10) break; // 限制结果数量
                    }
                }
            } catch(e) {
                // 忽略错误
            }
            if (count >= 10) break;
        }
        
        return count;
    }
    
    testHookSetup() {
        console.log("\n[测试5] Hook 设置");
        
        var hookCount = 0;
        
        // 测试 UISwitch Hook
        if (ObjC.available && ObjC.classes.UISwitch) {
            try {
                var UISwitch = ObjC.classes.UISwitch;
                var method = UISwitch['- setOn:animated:'];
                if (method) {
                    Interceptor.attach(method.implementation, {
                        onEnter: function(args) {
                            // 测试 Hook
                        }
                    });
                    hookCount++;
                    console.log("UISwitch Hook: ✓");
                }
            } catch(e) {
                console.log("UISwitch Hook: ✗ (" + e + ")");
            }
        }
        
        // 测试 shenling Hook
        if (ObjC.available && ObjC.classes.shenling) {
            try {
                var shenling = ObjC.classes.shenling;
                var method = shenling['+ MyTitle:'];
                if (method) {
                    Interceptor.attach(method.implementation, {
                        onEnter: function(args) {
                            // 测试 Hook
                        }
                    });
                    hookCount++;
                    console.log("shenling Hook: ✓");
                }
            } catch(e) {
                console.log("shenling Hook: ✗ (" + e + ")");
            }
        }
        
        this.testResults['hook_setup'] = hookCount > 0;
        console.log("Hook 设置: " + (hookCount > 0 ? "✓" : "✗") + " (" + hookCount + " 个)");
    }
    
    testFunctionCalls() {
        console.log("\n[测试6] 函数调用测试");
        
        if (!this.aswjModule) {
            console.log("✗ 无法测试，ASWJGAMEPLUS 模块未找到");
            return;
        }
        
        var base = this.aswjModule.base;
        var handlerFunc = base.add(0xfdc38);
        
        try {
            // 尝试创建 NativeFunction
            var handler = new NativeFunction(handlerFunc, 'void', ['int', 'bool']);
            this.testResults['native_function'] = true;
            console.log("NativeFunction 创建: ✓");
            
            // 尝试调用（使用安全的参数）
            try {
                handler(0, true);  // 尝试开启功能0
                console.log("函数调用: ✓");
                this.testResults['function_call'] = true;
                
                // 立即关闭
                handler(0, false);
                console.log("函数关闭: ✓");
            } catch(e) {
                console.log("函数调用: ✗ (" + e + ")");
                this.testResults['function_call'] = false;
            }
        } catch(e) {
            console.log("NativeFunction 创建: ✗ (" + e + ")");
            this.testResults['native_function'] = false;
        }
    }
    
    showResults() {
        console.log("\n=== 测试结果汇总 ===");
        
        var passed = 0;
        var total = 0;
        
        for (var test in this.testResults) {
            total++;
            if (this.testResults[test]) {
                passed++;
            }
        }
        
        console.log("通过: " + passed + "/" + total + " (" + Math.round(passed/total*100) + "%)");
        
        console.log("\n详细结果:");
        for (var test in this.testResults) {
            var status = this.testResults[test] ? "✓" : "✗";
            console.log("  " + test + ": " + status);
        }
        
        // 给出建议
        console.log("\n=== 建议 ===");
        if (this.testResults['aswj_module']) {
            console.log("✓ 建议使用直接调用方案 (ASWJClone_fixed.js)");
        } else {
            console.log("- 建议使用独立实现方案 (KabaoCheat.m)");
        }
        
        if (this.testResults['memory_search']) {
            console.log("✓ 可以使用内存修改方案 (KabaoMemoryHack.js)");
        }
        
        if (this.testResults['hook_setup']) {
            console.log("✓ 可以使用 Hook 方案");
        }
        
        console.log("\n推荐使用 ASWJClone_ultimate.js 获得最佳兼容性");
    }
}

// 延迟启动测试
setTimeout(function() {
    global.tester = new ASWJTester();
}, 2000);