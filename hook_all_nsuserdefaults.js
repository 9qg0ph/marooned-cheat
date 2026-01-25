console.log("[*] 开始监听所有 NSUserDefaults 写入操作...");

setTimeout(function() {
    if (ObjC.available) {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        var count = 0;
        
        // Hook setObject:forKey: - 显示所有
        try {
            Interceptor.attach(NSUserDefaults['- setObject:forKey:'].implementation, {
                onEnter: function(args) {
                    var object = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]);
                    console.log("\n[" + (++count) + "] setObject:forKey:");
                    console.log("  key: " + key);
                    console.log("  value: " + object);
                }
            });
            console.log("[+] Hook setObject:forKey: 成功");
        } catch(e) {}
        
        // Hook setInteger:forKey:
        try {
            Interceptor.attach(NSUserDefaults['- setInteger:forKey:'].implementation, {
                onEnter: function(args) {
                    var value = args[2];
                    var key = ObjC.Object(args[3]);
                    console.log("\n[" + (++count) + "] setInteger:forKey:");
                    console.log("  key: " + key);
                    console.log("  value: " + value);
                }
            });
            console.log("[+] Hook setInteger:forKey: 成功");
        } catch(e) {}
        
        // Hook setBool:forKey:
        try {
            Interceptor.attach(NSUserDefaults['- setBool:forKey:'].implementation, {
                onEnter: function(args) {
                    var value = args[2];
                    var key = ObjC.Object(args[3]);
                    console.log("\n[" + (++count) + "] setBool:forKey:");
                    console.log("  key: " + key);
                    console.log("  value: " + (value ? "true" : "false"));
                }
            });
            console.log("[+] Hook setBool:forKey: 成功");
        } catch(e) {}
        
        // Hook setFloat:forKey:
        try {
            Interceptor.attach(NSUserDefaults['- setFloat:forKey:'].implementation, {
                onEnter: function(args) {
                    var value = args[2];
                    var key = ObjC.Object(args[3]);
                    console.log("\n[" + (++count) + "] setFloat:forKey:");
                    console.log("  key: " + key);
                    console.log("  value: " + value);
                }
            });
            console.log("[+] Hook setFloat:forKey: 成功");
        } catch(e) {}
        
        // Hook setDouble:forKey:
        try {
            Interceptor.attach(NSUserDefaults['- setDouble:forKey:'].implementation, {
                onEnter: function(args) {
                    var value = args[2];
                    var key = ObjC.Object(args[3]);
                    console.log("\n[" + (++count) + "] setDouble:forKey:");
                    console.log("  key: " + key);
                    console.log("  value: " + value);
                }
            });
            console.log("[+] Hook setDouble:forKey: 成功");
        } catch(e) {}
        
        console.log("\n[*] 所有 Hook 设置完成");
        console.log("[!] 现在会显示所有 NSUserDefaults 写入操作");
        console.log("[*] 请在游戏中开启功能，观察输出");
    }
}, 2000);
