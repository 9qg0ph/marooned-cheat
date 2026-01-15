// Hook FanhanGGEngine 所有方法
console.log("[*] 等待...");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            var methods = FanhanGGEngine.$ownMethods;
            console.log("[*] FanhanGGEngine 方法:");
            
            methods.forEach(function(method) {
                console.log("  " + method);
                
                // Hook 所有实例方法
                if (method.startsWith('- ')) {
                    try {
                        Interceptor.attach(FanhanGGEngine[method].implementation, {
                            onEnter: function(args) {
                                console.log("\n[调用] " + method);
                                // 打印前几个参数
                                for (var i = 2; i < Math.min(args.length, 7); i++) {
                                    try {
                                        var obj = ObjC.Object(args[i]);
                                        console.log("  arg" + (i-2) + ": " + obj.toString().substring(0, 500));
                                    } catch(e) {}
                                }
                            }
                        });
                    } catch(e) {}
                }
            });
            
            console.log("\n[+] Hook 完成，请开启功能");
        }
    }
}, 8000);
