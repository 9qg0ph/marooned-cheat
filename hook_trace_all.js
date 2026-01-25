console.log("[*] 开始追踪 FanhanGGEngine 所有方法调用...");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] 找到 FanhanGGEngine 类");
            
            var methods = FanhanGGEngine.$ownMethods;
            var hookedCount = 0;
            
            methods.forEach(function(methodName) {
                try {
                    // 跳过一些基础方法
                    if (methodName.indexOf('retain') !== -1 || 
                        methodName.indexOf('release') !== -1 ||
                        methodName.indexOf('dealloc') !== -1) {
                        return;
                    }
                    
                    Interceptor.attach(FanhanGGEngine[methodName].implementation, {
                        onEnter: function(args) {
                            console.log("\n[调用] " + methodName);
                            
                            // 尝试打印参数
                            for (var i = 2; i < Math.min(args.length, 8); i++) {
                                try {
                                    var arg = ObjC.Object(args[i]);
                                    console.log("  arg[" + (i-2) + "]: " + arg);
                                } catch(e) {
                                    console.log("  arg[" + (i-2) + "]: " + args[i]);
                                }
                            }
                        }
                    });
                    hookedCount++;
                } catch(e) {
                    // 忽略无法 hook 的方法
                }
            });
            
            console.log("[+] 成功 Hook " + hookedCount + " 个方法");
            console.log("\n[*] 现在请在游戏中开启功能");
            console.log("[!] 控制台会显示所有被调用的方法和参数");
        } else {
            console.log("[-] 未找到 FanhanGGEngine 类");
        }
    }
}, 3000);
