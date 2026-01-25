console.log("[*] 快速捕获所有参数...");

var capturedData = [];

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] Hook 成功");
            
            // Hook setValue
            Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                onEnter: function(args) {
                    try {
                        var value = new ObjC.Object(args[2]).toString();
                        var key = new ObjC.Object(args[3]).toString();
                        var type = new ObjC.Object(args[4]).toString();
                        
                        var data = {
                            key: key,
                            value: value,
                            type: type
                        };
                        
                        capturedData.push(data);
                        
                        console.log("\n[setValue #" + capturedData.length + "]");
                        console.log("  key: " + key);
                        console.log("  value: " + value);
                        console.log("  type: " + type);
                        console.log("  ==================");
                    } catch(e) {
                        console.log("[-] 解析错误: " + e);
                    }
                }
            });
            
            // Hook setone (可能也用于设置参数)
            try {
                Interceptor.attach(FanhanGGEngine['- setone:two:three:four:five:name:'].implementation, {
                    onEnter: function(args) {
                        try {
                            var params = [];
                            for (var i = 2; i <= 7; i++) {
                                params.push(new ObjC.Object(args[i]).toString());
                            }
                            console.log("\n[setone]");
                            console.log("  参数: " + params.join(" | "));
                            console.log("  ==================");
                        } catch(e) {}
                    }
                });
            } catch(e) {}
            
            console.log("[*] 请开启所有功能，逐个测试");
        }
    }
}, 5000);

// 进程退出前打印汇总
Process.setExceptionHandler(function(details) {
    console.log("\n\n========== 捕获数据汇总 ==========");
    console.log("共捕获 " + capturedData.length + " 条参数");
    capturedData.forEach(function(data, index) {
        console.log("\n" + (index + 1) + ". key: " + data.key);
        console.log("   value: " + data.value);
        console.log("   type: " + data.type);
    });
    console.log("\n==================================");
});
