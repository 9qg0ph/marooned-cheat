// ASWJGAMEPLUS 功能复制脚本
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
    
    // 功能映射
    var functions = {
        "无限寿命": 0,
        "冻结灵石": 1, 
        "无敌免疫": 2,
        "无限突破": 3,
        "增加逃跑概率": 4
    };
    
    // 创建功能控制接口
    this.ASWJ = {
        enable: function(funcName) {
            var funcId = functions[funcName];
            if (funcId === undefined) {
                console.log("[-] 未知功能: " + funcName);
                return false;
            }
            
            try {
                // 调用开启函数
                var enableFn = new NativeFunction(enableFunc, 'void', ['int']);
                enableFn(funcId);
                console.log("[+] 开启功能: " + funcName);
                return true;
            } catch(e) {
                console.log("[-] 开启失败: " + e);
                return false;
            }
        },
        
        disable: function(funcName) {
            var funcId = functions[funcName];
            if (funcId === undefined) {
                console.log("[-] 未知功能: " + funcName);
                return false;
            }
            
            try {
                // 调用关闭函数
                var disableFn = new NativeFunction(disableFunc, 'void', ['int']);
                disableFn(funcId);
                console.log("[+] 关闭功能: " + funcName);
                return true;
            } catch(e) {
                console.log("[-] 关闭失败: " + e);
                return false;
            }
        },
        
        enableAll: function() {
            for (var funcName in functions) {
                this.enable(funcName);
            }
        },
        
        disableAll: function() {
            for (var funcName in functions) {
                this.disable(funcName);
            }
        },
        
        listFunctions: function() {
            console.log("可用功能:");
            for (var funcName in functions) {
                console.log("  " + functions[funcName] + ": " + funcName);
            }
        }
    };
    
    console.log("\n=== ASWJ 功能控制器已就绪 ===");
    console.log("使用方法:");
    console.log("  ASWJ.enable('无限寿命')     - 开启功能");
    console.log("  ASWJ.disable('无限寿命')    - 关闭功能");
    console.log("  ASWJ.enableAll()           - 开启所有功能");
    console.log("  ASWJ.disableAll()          - 关闭所有功能");
    console.log("  ASWJ.listFunctions()       - 列出所有功能");
    
}, 3000);