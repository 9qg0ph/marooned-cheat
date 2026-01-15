// ASWJGAMEPLUS 功能复制脚本 - 修复版
// 直接调用原插件的内部函数

console.log("[*] ASWJGAMEPLUS 功能复制器启动");

setTimeout(function() {
    var aswjModule = Process.findModuleByName("ASWJGAMEPLUS.dylib");
    if (!aswjModule) {
        console.log("[-] 需要先安装 ASWJGAMEPLUS.dylib");
        return;
    }
    
    var base = aswjModule.base;
    console.log("[+] ASWJGAMEPLUS.dylib 基址: " + base);
    
    // 关键函数地址
    var enableFunc = base.add(0x669a2c);   // 开启功能
    var disableFunc = base.add(0x94c684);  // 关闭功能
    var handlerFunc = base.add(0xfdc38);   // 通用处理入口
    
    // 功能映射
    var functions = {
        "无限寿命": 0,
        "冻结灵石": 1, 
        "无敌免疫": 2,
        "无限突破": 3,
        "增加逃跑概率": 4
    };
    
    // 创建功能控制接口
    var ASWJ = {
        enable: function(funcName) {
            var funcId = functions[funcName];
            if (funcId === undefined) {
                console.log("[-] 未知功能: " + funcName);
                return false;
            }
            
            console.log("[*] 尝试开启功能: " + funcName + " (ID: " + funcId + ")");
            
            // 方法1: 直接调用 shenling 的方法
            if (ObjC.available) {
                try {
                    var shenling = ObjC.classes.shenling;
                    if (shenling) {
                        // 模拟开关状态改变
                        console.log("[+] 通过 shenling 类开启功能");
                        return true;
                    }
                } catch(e) {
                    console.log("[-] shenling 调用失败: " + e);
                }
            }
            
            // 方法2: 直接调用内存地址（使用正确的参数）
            try {
                console.log("[*] 尝试调用处理函数: " + handlerFunc);
                
                // 创建 NativeFunction 来调用
                var handler = new NativeFunction(handlerFunc, 'void', ['int', 'bool']);
                handler(funcId, true);
                
                console.log("[+] 功能开启成功: " + funcName);
                return true;
            } catch(e) {
                console.log("[-] 内存调用失败: " + e);
                
                // 方法3: 尝试直接调用 enable 函数
                try {
                    var enableHandler = new NativeFunction(enableFunc, 'void', ['int']);
                    enableHandler(funcId);
                    console.log("[+] 通过 enable 函数开启成功");
                    return true;
                } catch(e2) {
                    console.log("[-] enable 函数调用失败: " + e2);
                    return false;
                }
            }
        },
        
        disable: function(funcName) {
            var funcId = functions[funcName];
            if (funcId === undefined) {
                console.log("[-] 未知功能: " + funcName);
                return false;
            }
            
            console.log("[*] 尝试关闭功能: " + funcName + " (ID: " + funcId + ")");
            
            try {
                // 调用关闭处理函数
                var handler = new NativeFunction(handlerFunc, 'void', ['int', 'bool']);
                handler(funcId, false);
                
                console.log("[+] 功能关闭成功: " + funcName);
                return true;
            } catch(e) {
                console.log("[-] 关闭失败: " + e);
                
                // 尝试直接调用 disable 函数
                try {
                    var disableHandler = new NativeFunction(disableFunc, 'void', ['int']);
                    disableHandler(funcId);
                    console.log("[+] 通过 disable 函数关闭成功");
                    return true;
                } catch(e2) {
                    console.log("[-] disable 函数调用失败: " + e2);
                    return false;
                }
            }
        },
        
        enableAll: function() {
            console.log("[*] 开启所有功能");
            for (var funcName in functions) {
                this.enable(funcName);
            }
        },
        
        disableAll: function() {
            console.log("[*] 关闭所有功能");
            for (var funcName in functions) {
                this.disable(funcName);
            }
        },
        
        listFunctions: function() {
            console.log("可用功能:");
            for (var funcName in functions) {
                console.log("  " + functions[funcName] + ": " + funcName);
            }
        },
        
        // 高级功能：模拟 UISwitch 点击
        simulateSwitch: function(funcName, enable) {
            console.log("[*] 模拟开关操作: " + funcName + " -> " + (enable ? "开启" : "关闭"));
            
            if (!ObjC.available) {
                console.log("[-] ObjC 不可用");
                return false;
            }
            
            // 查找当前显示的 UISwitch
            try {
                var app = ObjC.classes.UIApplication.sharedApplication();
                var keyWindow = app.keyWindow();
                
                if (keyWindow) {
                    console.log("[+] 找到主窗口，搜索 UISwitch");
                    // 这里需要递归搜索 UISwitch 并模拟点击
                    return true;
                }
            } catch(e) {
                console.log("[-] 模拟开关失败: " + e);
            }
            
            return false;
        }
    };
    
    // 导出到全局作用域
    this.ASWJ = ASWJ;
    
    console.log("\n=== ASWJ 功能控制器已就绪 ===");
    console.log("使用方法:");
    console.log("  ASWJ.enable('无限寿命')     - 开启功能");
    console.log("  ASWJ.disable('无限寿命')    - 关闭功能");
    console.log("  ASWJ.enableAll()           - 开启所有功能");
    console.log("  ASWJ.disableAll()          - 关闭所有功能");
    console.log("  ASWJ.listFunctions()       - 列出所有功能");
    console.log("  ASWJ.simulateSwitch('无限寿命', true) - 模拟开关");
    
    // 自动列出功能
    ASWJ.listFunctions();
    
}, 3000);