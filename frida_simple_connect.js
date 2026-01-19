// 简单连接测试脚本
console.log("🚀 连接测试脚本已加载");

setTimeout(function() {
    console.log("✅ 成功连接到游戏进程！");
    console.log("📱 应用信息:");
    console.log("   包名: " + ObjC.classes.NSBundle.mainBundle().bundleIdentifier().toString());
    console.log("   版本: " + ObjC.classes.NSBundle.mainBundle().objectForInfoDictionaryKey_("CFBundleShortVersionString").toString());
    
    // 简单测试NSUserDefaults
    try {
        var defaults = ObjC.classes.NSUserDefaults.standardUserDefaults();
        console.log("✅ NSUserDefaults可用");
        
        // 列出所有存储的key
        var dict = defaults.dictionaryRepresentation();
        var keys = dict.allKeys();
        console.log("📋 存储的key数量: " + keys.count());
        
        // 显示前10个key
        for (var i = 0; i < Math.min(10, keys.count()); i++) {
            var key = keys.objectAtIndex_(i).toString();
            console.log("   Key[" + i + "]: " + key);
        }
        
    } catch (e) {
        console.log("❌ NSUserDefaults测试失败: " + e.message);
    }
    
    console.log("=".repeat(50));
    console.log("✅ 连接测试完成！现在可以开启别的修改器进行监控");
    console.log("=".repeat(50));
    
}, 2000);