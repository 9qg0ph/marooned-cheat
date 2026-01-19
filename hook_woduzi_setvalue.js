console.log("[*] 我独自生活 Hook 脚本启动...");
console.log("[*] 等待游戏加载...");

setTimeout(function() {
    if (ObjC.available) {
        console.log("[*] ObjC 运行时可用");
        
        // Hook NSUserDefaults 的所有写入操作
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        if (NSUserDefaults) {
            console.log("[+] 找到 NSUserDefaults 类");
            
            // Hook setObject:forKey:
            var setObjectMethod = NSUserDefaults['- setObject:forKey:'];
            if (setObjectMethod) {
                Interceptor.attach(setObjectMethod.implementation, {
                    onEnter: function(args) {
                        var key = ObjC.Object(args[3]);
                        var value = ObjC.Object(args[2]);
                        
                        // 只记录数值类型的key
                        if (value && (value.isKindOfClass_(ObjC.classes.NSNumber) || 
                            typeof value.toString() === 'string' && !isNaN(value.toString()))) {
                            console.log("\n[NSUserDefaults setObject:forKey:]");
                            console.log("  key: " + key);
                            console.log("  value: " + value);
                            console.log("  value type: " + value.$className);
                            console.log("  ==================");
                        }
                    }
                });
                console.log("[+] Hook setObject:forKey: 成功");
            }
            
            // Hook setInteger:forKey:
            var setIntegerMethod = NSUserDefaults['- setInteger:forKey:'];
            if (setIntegerMethod) {
                Interceptor.attach(setIntegerMethod.implementation, {
                    onEnter: function(args) {
                        var key = ObjC.Object(args[3]);
                        var value = args[2].toInt32();
                        
                        console.log("\n[NSUserDefaults setInteger:forKey:]");
                        console.log("  key: " + key);
                        console.log("  value: " + value);
                        console.log("  ==================");
                    }
                });
                console.log("[+] Hook setInteger:forKey: 成功");
            }
            
            // Hook objectForKey: 和 integerForKey: (读取操作)
            var objectForKeyMethod = NSUserDefaults['- objectForKey:'];
            if (objectForKeyMethod) {
                Interceptor.attach(objectForKeyMethod.implementation, {
                    onEnter: function(args) {
                        var key = ObjC.Object(args[2]);
                        this.key = key.toString();
                    },
                    onLeave: function(retval) {
                        if (retval && retval.isNull() === false) {
                            var value = ObjC.Object(retval);
                            if (value && value.isKindOfClass_(ObjC.classes.NSNumber)) {
                                var numValue = value.intValue();
                                // 只记录可能的游戏数值（大于0的整数）
                                if (numValue > 0 && numValue < 10000000000) {
                                    console.log("\n[NSUserDefaults objectForKey:]");
                                    console.log("  key: " + this.key);
                                    console.log("  value: " + numValue);
                                    console.log("  ==================");
                                }
                            }
                        }
                    }
                });
                console.log("[+] Hook objectForKey: 成功");
            }
            
            var integerForKeyMethod = NSUserDefaults['- integerForKey:'];
            if (integerForKeyMethod) {
                Interceptor.attach(integerForKeyMethod.implementation, {
                    onEnter: function(args) {
                        var key = ObjC.Object(args[2]);
                        this.key = key.toString();
                    },
                    onLeave: function(retval) {
                        var value = retval.toInt32();
                        // 只记录可能的游戏数值
                        if (value > 0 && value < 10000000000) {
                            console.log("\n[NSUserDefaults integerForKey:]");
                            console.log("  key: " + this.key);
                            console.log("  value: " + value);
                            console.log("  ==================");
                        }
                    }
                });
                console.log("[+] Hook integerForKey: 成功");
            }
        }
        
        // 尝试Hook FanhanGGEngine（如果游戏使用了这个框架）
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] 找到 FanhanGGEngine 类");
            
            var setValueMethod = FanhanGGEngine['- setValue:forKey:withType:'];
            if (setValueMethod) {
                Interceptor.attach(setValueMethod.implementation, {
                    onEnter: function(args) {
                        var value = ObjC.Object(args[2]);
                        var key = ObjC.Object(args[3]);
                        var type = ObjC.Object(args[4]);
                        
                        console.log("\n[FanhanGGEngine setValue:forKey:withType:]");
                        console.log("  key: " + key);
                        console.log("  value: " + value);
                        console.log("  type: " + type);
                        console.log("  ==================");
                    }
                });
                console.log("[+] Hook FanhanGGEngine setValue 成功");
            }
        }
        
        console.log("\n[+] 所有Hook安装完成！");
        console.log("[*] 请在游戏中：");
        console.log("    1. 查看现金、体力、健康、心情数值");
        console.log("    2. 进行一次消费操作（如购买物品）");
        console.log("    3. 观察下方输出的key和value");
        console.log("[*] 记录所有包含数值的key，特别是现金、体力、健康、心情相关的");
        
    } else {
        console.log("[-] ObjC 运行时不可用");
    }
}, 8000);
