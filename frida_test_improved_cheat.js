// 测试改进后的修改器效果
console.log("🧪 测试改进后的修改器效果");

setTimeout(function() {
    console.log("🧪 开始测试改进后的修改器...");
    
    // 1. 检查ES3存档
    checkES3SaveData();
    
    // 2. 监控修改器操作
    monitorCheatOperations();
    
    console.log("=".repeat(60));
    console.log("🧪 修改器效果测试已启动！");
    console.log("💡 现在使用你的改进修改器，观察效果");
    console.log("=".repeat(60));
    
}, 1000);

// 检查ES3存档
function checkES3SaveData() {
    console.log("[检查] ES3存档状态...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        var defaults = NSUserDefaults.standardUserDefaults();
        
        // 检查 data1.es3（其他修改器使用的）
        var data1ES3 = defaults.objectForKey_("data1.es3");
        if (data1ES3) {
            console.log("✅ 找到 data1.es3 存档");
            console.log("   数据长度: " + data1ES3.length());
        } else {
            console.log("❌ 未找到 data1.es3 存档");
        }
        
        // 检查 data0.es3（你原来使用的）
        var data0ES3 = defaults.objectForKey_("data0.es3");
        if (data0ES3) {
            console.log("✅ 找到 data0.es3 存档");
            console.log("   数据长度: " + data0ES3.length());
        } else {
            console.log("❌ 未找到 data0.es3 存档");
        }
        
        // 检查时间戳
        var timestamp1 = defaults.objectForKey_("timestamp_data1.es3");
        if (timestamp1) {
            console.log("✅ 找到 data1.es3 时间戳: " + timestamp1);
        }
        
        var timestamp0 = defaults.objectForKey_("timestamp_data0.es3");
        if (timestamp0) {
            console.log("✅ 找到 data0.es3 时间戳: " + timestamp0);
        }
        
        console.log("✅ ES3存档检查完成");
    } catch (e) {
        console.log("❌ ES3存档检查失败: " + e.message);
    }
}

// 监控修改器操作
function monitorCheatOperations() {
    console.log("[监控] 修改器操作...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        // 监控ES3存档的修改
        var setObject = NSUserDefaults['- setObject:forKey:'];
        if (setObject) {
            Interceptor.attach(setObject.implementation, {
                onEnter: function(args) {
                    var obj = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]).toString();
                    
                    if (key.includes("es3") || key.includes("ES3")) {
                        console.log("📦 [你的修改器] ES3存档操作: " + key);
                        if (obj && obj.isKindOfClass_(ObjC.classes.NSString)) {
                            console.log("   数据长度: " + obj.length());
                        }
                    }
                    
                    if (key.includes("timestamp")) {
                        console.log("🕐 [你的修改器] 时间戳更新: " + key + " = " + obj);
                    }
                }
            });
        }
        
        // 监控数值修改
        var setInteger = NSUserDefaults['- setInteger:forKey:'];
        if (setInteger) {
            Interceptor.attach(setInteger.implementation, {
                onEnter: function(args) {
                    var value = args[2].toInt32();
                    var key = ObjC.Object(args[3]).toString();
                    
                    if (value === 21000000000 || value === 1000000) {
                        console.log("💰 [你的修改器] 数值修改: " + key + " = " + value);
                    }
                }
            });
        }
        
        console.log("✅ 修改器操作监控已启动");
    } catch (e) {
        console.log("❌ 修改器操作监控失败: " + e.message);
    }
}

// 定期检查游戏数值
setInterval(function() {
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        var defaults = NSUserDefaults.standardUserDefaults();
        
        console.log("\n📊 [定期检查] 当前游戏数值:");
        
        // 检查常见的数值字段
        var keys = ["现金", "金钱", "cash", "money", "体力", "energy", "健康", "health", "心情", "mood"];
        var hasValues = false;
        
        keys.forEach(function(key) {
            try {
                var value = defaults.integerForKey_(key);
                if (value > 0) {
                    console.log("  " + key + ": " + value);
                    hasValues = true;
                }
            } catch (e) {}
        });
        
        if (!hasValues) {
            console.log("  未找到明显的游戏数值字段");
        }
        
        console.log("");
    } catch (e) {}
}, 15000); // 每15秒检查一次

console.log("📋 [提示] 修改器效果测试系统加载完成...");