console.log("[*] 快速抓取Hook启动...");

setTimeout(function() {
    if (ObjC.available) {
        try {
            var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
            if (FanhanGGEngine) {
                console.log("[+] 找到FanhanGGEngine，开始Hook setValue...");
                
                Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                    onEnter: function(args) {
                        try {
                            var value = ObjC.Object(args[2]);
                            var key = ObjC.Object(args[3]);
                            var type = ObjC.Object(args[4]);
                            
                            console.log("\n=== 功能参数抓取 ===");
                            console.log("Key: " + key);
                            console.log("Type: " + type);
                            
                            // 如果是roleInfo，尝试解析关键数据
                            if (key.toString() === "roleInfo") {
                                var valueStr = value.toString();
                                console.log("这是roleInfo数据，长度: " + valueStr.length);
                                
                                // 尝试提取关键字段
                                try {
                                    if (valueStr.includes("currency")) {
                                        var currencyMatch = valueStr.match(/"currency":(\d+)/);
                                        if (currencyMatch) {
                                            console.log("货币值: " + currencyMatch[1]);
                                        }
                                    }
                                    
                                    if (valueStr.includes("hp")) {
                                        var hpMatch = valueStr.match(/"hp":(\d+)/);
                                        if (hpMatch) {
                                            console.log("血量值: " + hpMatch[1]);
                                        }
                                    }
                                    
                                    if (valueStr.includes("lifeSpan")) {
                                        var lifeMatch = valueStr.match(/"lifeSpan":(\d+)/);
                                        if (lifeMatch) {
                                            console.log("寿命值: " + lifeMatch[1]);
                                        }
                                    }
                                } catch (parseError) {
                                    console.log("解析数据时出错: " + parseError);
                                }
                            } else {
                                // 其他key直接显示value
                                var valueStr = value.toString();
                                if (valueStr.length > 100) {
                                    valueStr = valueStr.substring(0, 100) + "...";
                                }
                                console.log("Value: " + valueStr);
                            }
                            
                            console.log("==================");
                        } catch (e) {
                            console.log("Hook处理错误: " + e);
                        }
                    }
                });
                console.log("[+] Hook成功！现在可以点击功能了");
                console.log("[*] 提示：点击功能后游戏会闪退，这是正常的");
                console.log("[*] 我们会在闪退前抓取到参数");
            } else {
                console.log("[-] 未找到FanhanGGEngine类");
            }
        } catch (e) {
            console.log("[-] Hook失败: " + e);
        }
    }
}, 5000);

console.log("[*] 等待5秒让游戏加载...");