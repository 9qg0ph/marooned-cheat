console.log("[*] 简化Hook启动...");

setTimeout(function() {
    if (ObjC.available) {
        try {
            var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
            if (FanhanGGEngine) {
                console.log("[+] 找到FanhanGGEngine，开始Hook...");
                
                Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                    onEnter: function(args) {
                        try {
                            var key = ObjC.Object(args[3]).toString();
                            var type = ObjC.Object(args[4]).toString();
                            
                            console.log("\n=== Hook到setValue ===");
                            console.log("Key: " + key);
                            console.log("Type: " + type);
                            console.log("====================");
                        } catch (e) {
                            console.log("Hook处理错误: " + e);
                        }
                    }
                });
                console.log("[+] Hook成功！现在可以点击功能了");
            } else {
                console.log("[-] 未找到FanhanGGEngine类");
            }
        } catch (e) {
            console.log("[-] Hook失败: " + e);
        }
    }
}, 5000);

console.log("[*] 等待5秒...");