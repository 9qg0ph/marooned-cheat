console.log("[*] 等待进程启动...");

setImmediate(function() {
    if (ObjC.available) {
        console.log("[*] ObjC 可用，开始 Hook");
        
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] 找到 FanhanGGEngine");
            
            // Hook one:two:three:four:five:
            Interceptor.attach(FanhanGGEngine['- one:two:three:four:five:'].implementation, {
                onEnter: function(args) {
                    try {
                        var one = new ObjC.Object(args[2]);
                        var two = new ObjC.Object(args[3]);
                        var three = new ObjC.Object(args[4]);
                        var four = new ObjC.Object(args[5]);
                        var five = new ObjC.Object(args[6]);
                        
                        console.log("\n[one:two:three:four:five:]");
                        console.log("  one: " + one);
                        console.log("  two: " + two);
                        console.log("  three: " + three);
                        console.log("  four: " + four);
                        console.log("  five: " + five);
                    } catch(e) {}
                }
            });
            
            // Hook setone:two:three:four:five:name:
            Interceptor.attach(FanhanGGEngine['- setone:two:three:four:five:name:'].implementation, {
                onEnter: function(args) {
                    try {
                        var one = new ObjC.Object(args[2]);
                        var two = new ObjC.Object(args[3]);
                        var three = new ObjC.Object(args[4]);
                        var four = new ObjC.Object(args[5]);
                        var five = new ObjC.Object(args[6]);
                        var name = new ObjC.Object(args[7]);
                        
                        console.log("\n[setone:two:three:four:five:name:]");
                        console.log("  one: " + one);
                        console.log("  two: " + two);
                        console.log("  three: " + three);
                        console.log("  four: " + four);
                        console.log("  five: " + five);
                        console.log("  name: " + name);
                    } catch(e) {}
                }
            });
            
            // Hook setValue:forKey:withType:
            Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                onEnter: function(args) {
                    try {
                        var value = new ObjC.Object(args[2]);
                        var key = new ObjC.Object(args[3]);
                        var type = new ObjC.Object(args[4]);
                        console.log("\n[setValue:forKey:withType:]");
                        console.log("  key: " + key);
                        console.log("  value: " + value);
                        console.log("  type: " + type);
                    } catch(e) {}
                }
            });
            
            console.log("[+] Hook 完成，请开启功能");
        } else {
            console.log("[-] 未找到 FanhanGGEngine，等待加载...");
            setTimeout(function() {
                console.log("[*] 重试查找 FanhanGGEngine...");
            }, 2000);
        }
    }
});
