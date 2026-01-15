// Hook setValue 方法
console.log("[*] 等待...");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            // Hook setValue:forKey:withType:
            Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                onEnter: function(args) {
                    var value = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]);
                    var type = ObjC.Object(args[4]);
                    console.log("\n[setValue]");
                    console.log("  value: " + value);
                    console.log("  key: " + key);
                    console.log("  type: " + type);
                }
            });

            // Hook set:two:three:four:value:
            Interceptor.attach(FanhanGGEngine['- set:two:three:four:value:'].implementation, {
                onEnter: function(args) {
                    console.log("\n[set]");
                    console.log("  1: " + ObjC.Object(args[2]));
                    console.log("  2: " + ObjC.Object(args[3]));
                    console.log("  3: " + ObjC.Object(args[4]));
                    console.log("  4: " + ObjC.Object(args[5]));
                    console.log("  value: " + ObjC.Object(args[6]));
                }
            });

            // Hook cesfunc
            Interceptor.attach(FanhanGGEngine['- cesfunc:two:three:four:five:six:value:'].implementation, {
                onEnter: function(args) {
                    console.log("\n[cesfunc]");
                    console.log("  1: " + ObjC.Object(args[2]));
                    console.log("  2: " + ObjC.Object(args[3]));
                    console.log("  3: " + ObjC.Object(args[4]));
                    console.log("  4: " + ObjC.Object(args[5]));
                    console.log("  5: " + ObjC.Object(args[6]));
                    console.log("  6: " + ObjC.Object(args[7]));
                    console.log("  value: " + ObjC.Object(args[8]));
                }
            });

            // Hook setField
            Interceptor.attach(FanhanGGEngine['- setField:two:three:four:five:'].implementation, {
                onEnter: function(args) {
                    console.log("\n[setField]");
                    console.log("  1: " + ObjC.Object(args[2]));
                    console.log("  2: " + ObjC.Object(args[3]));
                    console.log("  3: " + ObjC.Object(args[4]));
                    console.log("  4: " + ObjC.Object(args[5]));
                    console.log("  5: " + ObjC.Object(args[6]));
                }
            });

            console.log("[+] Hook 成功，请开启功能");
        }
    }
}, 8000);
