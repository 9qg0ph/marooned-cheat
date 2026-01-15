// 轻量级 Hook - 只抓功能执行参数
console.log("[*] 等待...");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            // Hook Pickaddrss - 内存修改
            try {
                Interceptor.attach(FanhanGGEngine['- Pickaddrss:addrss:with:type:'].implementation, {
                    onEnter: function(args) {
                        console.log("\n[内存修改]");
                        console.log("  模块: " + ObjC.Object(args[2]));
                        console.log("  地址: " + ObjC.Object(args[3]));
                        console.log("  值: " + ObjC.Object(args[4]));
                        console.log("  类型: " + ObjC.Object(args[5]));
                    }
                });
            } catch(e) {}

            // Hook cesOffsetHook - Offset Hook
            try {
                Interceptor.attach(FanhanGGEngine['- cesOffsetHook:two:main:'].implementation, {
                    onEnter: function(args) {
                        console.log("\n[Offset Hook]");
                        console.log("  one: " + ObjC.Object(args[2]));
                        console.log("  two: " + ObjC.Object(args[3]));
                        console.log("  main: " + ObjC.Object(args[4]));
                    }
                });
            } catch(e) {}

            // Hook fanhances
            try {
                Interceptor.attach(FanhanGGEngine['- fanhances:two:three:four:obj:'].implementation, {
                    onEnter: function(args) {
                        console.log("\n[fanhances]");
                        console.log("  1: " + ObjC.Object(args[2]));
                        console.log("  2: " + ObjC.Object(args[3]));
                        console.log("  3: " + ObjC.Object(args[4]));
                        console.log("  4: " + ObjC.Object(args[5]));
                        console.log("  obj: " + ObjC.Object(args[6]));
                    }
                });
            } catch(e) {}

            console.log("[+] Hook 成功，请开启功能");
        }
    }
}, 8000);
