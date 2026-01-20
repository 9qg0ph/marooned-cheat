// 最基础的学习脚本
console.log("[+] 基础脚本启动...");

// 延迟15秒执行，确保游戏稳定
setTimeout(function() {
    console.log("[+] 开始基础分析...");
    
    try {
        // 只分析NSUserDefaults
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        if (NSUserDefaults) {
            console.log("[+] 找到NSUserDefaults");
            
            // 只Hook最关键的方法
            var integerForKey = NSUserDefaults['- integerForKey:'];
            if (integerForKey) {
                Interceptor.attach(integerForKey.implementation, {
                    onEnter: function(args) {
                        var key = new ObjC.Object(args[2]).toString();
                        console.log("[读取] " + key);
                    },
                    onLeave: function(retval) {
                        var value = retval.toInt32();
                        if (value > 0) {
                            console.log("[数值] " + value);
                        }
                    }
                });
                console.log("[+] Hook成功");
            }
        }
        
    } catch (e) {
        console.log("[-] 错误: " + e);
    }
    
}, 15000);

console.log("[+] 等待15秒...");