// Hook 点击功能按钮时的调用
console.log("[*] 启动");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            // Hook cesOffsetHook - 这是执行 hook 的方法
            Interceptor.attach(FanhanGGEngine['- cesOffsetHook:two:main:'].implementation, {
                onEnter: function(args) {
                    var one = ObjC.Object(args[2]);
                    var two = ObjC.Object(args[3]);
                    var main = ObjC.Object(args[4]);
                    console.log("\n[cesOffsetHook]");
                    console.log("  one: " + one);
                    console.log("  two: " + two);
                    console.log("  main: " + main);
                }
            });

            // Hook fanhances
            Interceptor.attach(FanhanGGEngine['- fanhances:two:three:four:obj:'].implementation, {
                onEnter: function(args) {
                    console.log("\n[fanhances]");
                    console.log("  one: " + ObjC.Object(args[2]));
                    console.log("  two: " + ObjC.Object(args[3]));
                    console.log("  three: " + ObjC.Object(args[4]));
                    console.log("  four: " + ObjC.Object(args[5]));
                    console.log("  obj: " + ObjC.Object(args[6]));
                }
            });

            // Hook Pickaddrss
            Interceptor.attach(FanhanGGEngine['- Pickaddrss:addrss:with:type:'].implementation, {
                onEnter: function(args) {
                    console.log("\n[Pickaddrss]");
                    console.log("  one: " + ObjC.Object(args[2]));
                    console.log("  addr: " + ObjC.Object(args[3]));
                    console.log("  with: " + ObjC.Object(args[4]));
                    console.log("  type: " + ObjC.Object(args[5]));
                }
            });

            console.log("[+] Hook 成功，请开启一个功能");
        }
    }
}, 3000);
