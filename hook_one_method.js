console.log("[*] Hook one:two:three:four:five: 方法...");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] 找到 FanhanGGEngine 类");
            
            // Hook one:two:three:four:five:
            try {
                Interceptor.attach(FanhanGGEngine['- one:two:three:four:five:'].implementation, {
                    onEnter: function(args) {
                        try {
                            var one = ObjC.Object(args[2]);
                            var two = ObjC.Object(args[3]);
                            var three = ObjC.Object(args[4]);
                            var four = ObjC.Object(args[5]);
                            var five = ObjC.Object(args[6]);
                            
                            console.log("\n[one:two:three:four:five:]");
                            console.log("  one: " + one);
                            console.log("  two: " + two);
                            console.log("  three: " + three);
                            console.log("  four: " + four);
                            console.log("  five: " + five);
                        } catch(e) {
                            console.log("  解析参数出错: " + e);
                        }
                    }
                });
                console.log("[+] Hook one:two:three:four:five: 成功");
            } catch(e) {
                console.log("[-] Hook 失败: " + e);
            }
            
            // 同时 hook setone:two:three:four:five:name:
            try {
                Interceptor.attach(FanhanGGEngine['- setone:two:three:four:five:name:'].implementation, {
                    onEnter: function(args) {
                        try {
                            var one = ObjC.Object(args[2]);
                            var two = ObjC.Object(args[3]);
                            var three = ObjC.Object(args[4]);
                            var four = ObjC.Object(args[5]);
                            var five = ObjC.Object(args[6]);
                            var name = ObjC.Object(args[7]);
                            
                            console.log("\n[setone:two:three:four:five:name:]");
                            console.log("  one: " + one);
                            console.log("  two: " + two);
                            console.log("  three: " + three);
                            console.log("  four: " + four);
                            console.log("  five: " + five);
                            console.log("  name: " + name);
                        } catch(e) {
                            console.log("  解析参数出错: " + e);
                        }
                    }
                });
                console.log("[+] Hook setone:two:three:four:five:name: 成功");
            } catch(e) {
                console.log("[-] Hook setone 失败: " + e);
            }
            
            console.log("\n[*] Hook 完成，请在游戏中开启功能");
        }
    }
}, 3000);
