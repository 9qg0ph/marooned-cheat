// Hook FanhanGGEngine 的 fanhan 方法
console.log("[*] 启动");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            // Hook fanhan: 方法
            Interceptor.attach(FanhanGGEngine['- fanhan:'].implementation, {
                onEnter: function(args) {
                    var param = ObjC.Object(args[2]);
                    console.log("\n[fanhan] 参数类型: " + param.$className);
                    console.log("[fanhan] 内容: " + param.toString().substring(0, 10000));
                }
            });
            console.log("[+] Hook fanhan: 成功");

            // Hook handleBase64Data
            Interceptor.attach(FanhanGGEngine['- handleBase64Data:toName:location:isWrite:'].implementation, {
                onEnter: function(args) {
                    var data = ObjC.Object(args[2]);
                    var name = ObjC.Object(args[3]);
                    var location = ObjC.Object(args[4]);
                    console.log("\n[handleBase64Data]");
                    console.log("  name: " + name);
                    console.log("  location: " + location);
                    if (data) {
                        console.log("  data: " + data.toString().substring(0, 5000));
                    }
                }
            });
            console.log("[+] Hook handleBase64Data 成功");
        }
        
        console.log("[*] 请点击悬浮图标");
    }
}, 5000);
