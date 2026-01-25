console.log("[*] 智能 Hook 启动");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] 找到 FanhanGGEngine");
            
            // Hook setone:two:three:four:five:name: - 这个方法最可能包含参数
            var setoneMethod = FanhanGGEngine['- setone:two:three:four:five:name:'];
            if (setoneMethod) {
                Interceptor.attach(setoneMethod.implementation, {
                    onEnter: function(args) {
                        console.log("\n========== setone 被调用 ==========");
                        // 尝试解析每个参数
                        for (var i = 2; i <= 7; i++) {
                            try {
                                var obj = new ObjC.Object(args[i]);
                                console.log("  参数[" + (i-2) + "]: " + obj.toString());
                            } catch(e) {
                                try {
                                    console.log("  参数[" + (i-2) + "]: " + args[i]);
                                } catch(e2) {
                                    console.log("  参数[" + (i-2) + "]: <无法解析>");
                                }
                            }
                        }
                        console.log("=====================================\n");
                    }
                });
                console.log("[+] Hook setone 成功");
            }
            
            // 同时 Hook setValue:forKey:withType:
            var setValueMethod = FanhanGGEngine['- setValue:forKey:withType:'];
            if (setValueMethod) {
                Interceptor.attach(setValueMethod.implementation, {
                    onEnter: function(args) {
                        try {
                            var value = new ObjC.Object(args[2]);
                            var key = new ObjC.Object(args[3]);
                            var type = new ObjC.Object(args[4]);
                            console.log("\n[setValue:forKey:withType:]");
                            console.log("  key: " + key.toString());
                            console.log("  value: " + value.toString());
                            console.log("  type: " + type.toString());
                        } catch(e) {}
                    }
                });
                console.log("[+] Hook setValue 成功");
            }
            
            console.log("\n[*] Hook 完成，请在游戏中开启功能");
        }
    }
}, 2000);
