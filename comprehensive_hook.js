console.log("[*] 全面Hook启动...");

setTimeout(function() {
    if (ObjC.available) {
        try {
            var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
            if (FanhanGGEngine) {
                console.log("[+] 找到FanhanGGEngine类");
                
                // Hook setValue方法
                try {
                    Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                        onEnter: function(args) {
                            try {
                                var value = ObjC.Object(args[2]);
                                var key = ObjC.Object(args[3]);
                                var type = ObjC.Object(args[4]);
                                
                                console.log("\n=== setValue Hook ===");
                                console.log("Key: " + key);
                                console.log("Type: " + type);
                                console.log("Value: " + (value.toString().length > 100 ? value.toString().substring(0, 100) + "..." : value.toString()));
                                console.log("====================");
                            } catch (e) {
                                console.log("setValue Hook错误: " + e);
                            }
                        }
                    });
                    console.log("[+] Hook setValue成功");
                } catch (e) {
                    console.log("[-] Hook setValue失败: " + e);
                }
                
                // 尝试Hook其他可能的方法
                var methods = FanhanGGEngine.$ownMethods;
                console.log("[*] FanhanGGEngine类的方法数量: " + methods.length);
                
                // 查找包含"patch", "inject", "currency", "money"等关键词的方法
                methods.forEach(function(method) {
                    var methodName = method.toLowerCase();
                    if (methodName.includes('patch') || methodName.includes('inject') || 
                        methodName.includes('currency') || methodName.includes('money') ||
                        methodName.includes('coin') || methodName.includes('gold')) {
                        console.log("[*] 发现可疑方法: " + method);
                        
                        try {
                            Interceptor.attach(FanhanGGEngine[method].implementation, {
                                onEnter: function(args) {
                                    console.log("\n=== " + method + " 被调用 ===");
                                    for (var i = 0; i < args.length && i < 5; i++) {
                                        try {
                                            var arg = ObjC.Object(args[i]);
                                            console.log("参数" + i + ": " + arg);
                                        } catch (e) {
                                            console.log("参数" + i + ": [无法解析]");
                                        }
                                    }
                                    console.log("========================");
                                }
                            });
                            console.log("[+] Hook " + method + " 成功");
                        } catch (e) {
                            console.log("[-] Hook " + method + " 失败: " + e);
                        }
                    }
                });
                
                // Hook所有以"set"开头的方法
                methods.forEach(function(method) {
                    if (method.startsWith('- set') || method.startsWith('+ set')) {
                        try {
                            Interceptor.attach(FanhanGGEngine[method].implementation, {
                                onEnter: function(args) {
                                    console.log("\n=== " + method + " 被调用 ===");
                                    try {
                                        if (args.length > 2) {
                                            var arg1 = ObjC.Object(args[2]);
                                            console.log("参数: " + arg1);
                                        }
                                    } catch (e) {
                                        console.log("参数解析失败");
                                    }
                                    console.log("========================");
                                }
                            });
                            console.log("[+] Hook " + method + " 成功");
                        } catch (e) {
                            // 忽略失败的方法
                        }
                    }
                });
                
            } else {
                console.log("[-] 未找到FanhanGGEngine类");
            }
            
            console.log("[+] 全面Hook完成！现在点击功能试试");
            
        } catch (e) {
            console.log("[-] Hook失败: " + e);
        }
    }
}, 5000);

console.log("[*] 等待5秒让游戏加载...");