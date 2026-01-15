console.log("[*] 防闪退Hook启动...");

setTimeout(function() {
    if (ObjC.available) {
        try {
            // Hook exit相关函数防止闪退
            var exit_ptr = Module.findExportByName(null, "exit");
            if (exit_ptr) {
                Interceptor.attach(exit_ptr, {
                    onEnter: function(args) {
                        console.log("[!] 阻止exit调用，防止闪退");
                        return false; // 阻止执行
                    }
                });
                console.log("[+] Hook exit成功");
            }
            
            // Hook abort函数
            var abort_ptr = Module.findExportByName(null, "abort");
            if (abort_ptr) {
                Interceptor.attach(abort_ptr, {
                    onEnter: function(args) {
                        console.log("[!] 阻止abort调用，防止闪退");
                        return false;
                    }
                });
                console.log("[+] Hook abort成功");
            }
            
            // Hook UIApplication terminate
            var UIApplication = ObjC.classes.UIApplication;
            if (UIApplication) {
                var terminateMethod = UIApplication['- terminate:'];
                if (terminateMethod) {
                    Interceptor.attach(terminateMethod.implementation, {
                        onEnter: function(args) {
                            console.log("[!] 阻止UIApplication terminate，防止闪退");
                            return false;
                        }
                    });
                    console.log("[+] Hook UIApplication terminate成功");
                }
            }
            
            // Hook setValue方法来抓取参数
            var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
            if (FanhanGGEngine) {
                console.log("[+] 找到FanhanGGEngine，开始Hook setValue...");
                
                Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                    onEnter: function(args) {
                        try {
                            var value = ObjC.Object(args[2]);
                            var key = ObjC.Object(args[3]);
                            var type = ObjC.Object(args[4]);
                            
                            var valueStr = value.toString();
                            if (valueStr.length > 500) {
                                valueStr = valueStr.substring(0, 500) + "...";
                            }
                            
                            console.log("\n=== 抓取到setValue ===");
                            console.log("Key: " + key);
                            console.log("Type: " + type);
                            console.log("Value: " + valueStr);
                            console.log("========================");
                        } catch (e) {
                            console.log("setValue Hook错误: " + e);
                        }
                    }
                });
                console.log("[+] Hook setValue成功！");
            } else {
                console.log("[-] 未找到FanhanGGEngine类");
            }
            
            console.log("[+] 所有Hook完成！现在可以安全点击功能了");
            
        } catch (e) {
            console.log("[-] Hook失败: " + e);
        }
    } else {
        console.log("[-] ObjC不可用");
    }
}, 6000);

console.log("[*] 等待6秒让游戏完全加载...");