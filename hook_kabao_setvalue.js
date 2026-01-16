console.log("[*] 卡包修仙 Hook 脚本启动...");
console.log("[*] 等待游戏加载...");

setTimeout(function() {
    if (ObjC.available) {
        console.log("[*] ObjC 运行时可用");
        
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] 找到 FanhanGGEngine 类");
            
            Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                onEnter: function(args) {
                    var value = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]);
                    var type = ObjC.Object(args[4]);
                    
                    console.log("\n[卡包修仙 setValue]");
                    console.log("  key: " + key);
                    console.log("  value: " + value);
                    console.log("  type: " + type);
                    console.log("  ==================");
                }
            });
            
            console.log("[+] Hook 成功！");
            console.log("[*] 请在游戏中逐个开启功能");
            console.log("[*] 记录下方输出的 key、value、type 参数");
        } else {
            console.log("[-] 未找到 FanhanGGEngine 类");
            console.log("[-] 请确认游戏已安装 GameForFun.dylib 插件");
        }
    } else {
        console.log("[-] ObjC 运行时不可用");
    }
}, 8000);
