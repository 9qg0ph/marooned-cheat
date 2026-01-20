// 轻量级脚本 - 我独自生活
console.log("[+] 轻量级修改器启动...");

// 延迟10秒执行，让游戏完全稳定
setTimeout(function() {
    console.log("[+] 开始轻量级Hook...");
    
    try {
        // 只Hook NSUserDefaults，这是最安全的方法
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        if (NSUserDefaults) {
            console.log("[+] 找到NSUserDefaults");
            
            // Hook integerForKey - 读取数值时修改
            var integerForKey = NSUserDefaults['- integerForKey:'];
            if (integerForKey) {
                Interceptor.attach(integerForKey.implementation, {
                    onLeave: function(retval) {
                        var value = retval.toInt32();
                        
                        // 如果读取的是大数值（可能是金钱/体力），返回21亿
                        if (value > 0 && value < 2100000000) {
                            console.log("[数值] 读取到: " + value + "，修改为21亿");
                            retval.replace(ptr(2100000000));
                        }
                    }
                });
                console.log("[+] Hook integerForKey 成功");
            }
            
            // Hook objectForKey - 读取对象时修改
            var objectForKey = NSUserDefaults['- objectForKey:'];
            if (objectForKey) {
                Interceptor.attach(objectForKey.implementation, {
                    onLeave: function(retval) {
                        if (!retval.isNull()) {
                            try {
                                var obj = new ObjC.Object(retval);
                                if (obj.isKindOfClass_(ObjC.classes.NSNumber)) {
                                    var value = obj.intValue();
                                    if (value > 0 && value < 2100000000) {
                                        console.log("[对象] 读取到数字: " + value);
                                        var newNumber = ObjC.classes.NSNumber.numberWithInt_(2100000000);
                                        retval.replace(newNumber);
                                    }
                                }
                            } catch (e) {
                                // 忽略错误
                            }
                        }
                    }
                });
                console.log("[+] Hook objectForKey 成功");
            }
        }
        
        console.log("[+] 轻量级Hook设置完成");
        
    } catch (e) {
        console.log("[-] Hook失败: " + e);
    }
    
}, 10000);

console.log("[+] 脚本加载完成，等待10秒后开始Hook...");