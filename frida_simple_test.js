// 简单测试脚本
console.log("🚀 简单测试脚本已加载");

setTimeout(function() {
    console.log("✅ 脚本运行正常，开始监控...");
    
    // 只监控NSUserDefaults的setInteger
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        if (NSUserDefaults) {
            var setInteger = NSUserDefaults['- setInteger:forKey:'];
            if (setInteger) {
                Interceptor.attach(setInteger.implementation, {
                    onEnter: function(args) {
                        var value = args[2].toInt32();
                        var key = ObjC.Object(args[3]).toString();
                        console.log("📝 setInteger: " + value + " forKey: " + key);
                    }
                });
                console.log("✅ NSUserDefaults setInteger 监控已启动");
            }
        }
    } catch (e) {
        console.log("❌ 监控失败: " + e.message);
    }
    
    console.log("💡 现在可以在手机上操作修改器了");
}, 1000);