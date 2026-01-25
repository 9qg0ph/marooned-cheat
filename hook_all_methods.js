console.log("[*] 开始 Hook FanhanGGEngine 所有方法...");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] 找到 FanhanGGEngine 类");
            
            // Hook setValue:forKey:withType:
            try {
                Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                    onEnter: function(args) {
                        var value = ObjC.Object(args[2]);
                        var key = ObjC.Object(args[3]);
                        var type = ObjC.Object(args[4]);
                        console.log("\n[setValue:forKey:withType:]");
                        console.log("  key: " + key);
                        console.log("  value: " + value);
                        console.log("  type: " + type);
                    }
                });
                console.log("[+] Hook setValue:forKey:withType: 成功");
            } catch(e) {
                console.log("[-] Hook setValue:forKey:withType: 失败: " + e);
            }
            
            // Hook setone:two:three:four:five:name:
            try {
                Interceptor.attach(FanhanGGEngine['- setone:two:three:four:five:name:'].implementation, {
                    onEnter: function(args) {
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
                    }
                });
                console.log("[+] Hook setone:two:three:four:five:name: 成功");
            } catch(e) {
                console.log("[-] Hook setone:two:three:four:five:name: 失败: " + e);
            }
            
            // Hook setspeed:two:three:four:five:floatdata:
            try {
                Interceptor.attach(FanhanGGEngine['- setspeed:two:three:four:five:floatdata:'].implementation, {
                    onEnter: function(args) {
                        var speed = ObjC.Object(args[2]);
                        var two = ObjC.Object(args[3]);
                        var three = ObjC.Object(args[4]);
                        var four = ObjC.Object(args[5]);
                        var five = ObjC.Object(args[6]);
                        var floatdata = ObjC.Object(args[7]);
                        console.log("\n[setspeed:two:three:four:five:floatdata:]");
                        console.log("  speed: " + speed);
                        console.log("  two: " + two);
                        console.log("  three: " + three);
                        console.log("  four: " + four);
                        console.log("  five: " + five);
                        console.log("  floatdata: " + floatdata);
                    }
                });
                console.log("[+] Hook setspeed:two:three:four:five:floatdata: 成功");
            } catch(e) {
                console.log("[-] Hook setspeed:two:three:four:five:floatdata: 失败: " + e);
            }
            
            // Hook getValue:param2:
            try {
                Interceptor.attach(FanhanGGEngine['- getValue:param2:'].implementation, {
                    onEnter: function(args) {
                        var param1 = ObjC.Object(args[2]);
                        var param2 = ObjC.Object(args[3]);
                        console.log("\n[getValue:param2:] 调用");
                        console.log("  param1: " + param1);
                        console.log("  param2: " + param2);
                    },
                    onLeave: function(retval) {
                        console.log("  返回值: " + ObjC.Object(retval));
                    }
                });
                console.log("[+] Hook getValue:param2: 成功");
            } catch(e) {
                console.log("[-] Hook getValue:param2: 失败: " + e);
            }
            
            console.log("\n[*] 所有 Hook 设置完成，请在游戏中开启功能");
        }
    }
}, 5000);
