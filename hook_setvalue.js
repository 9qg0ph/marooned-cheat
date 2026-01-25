console.log("[*] 等待...");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                onEnter: function(args) {
                    var value = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]);
                    var type = ObjC.Object(args[4]);
                    console.log("\n[setValue]");
                    console.log("  key: " + key);
                    console.log("  value: " + value);
                    console.log("  type: " + type);
                }
            });
            console.log("[+] Hook 成功，请开启功能");
        }
    }
}, 8000);
