console.log("[*] 开始 Hook NSUserDefaults...");

setTimeout(function() {
    if (ObjC.available) {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        // Hook setObject:forKey:
        try {
            Interceptor.attach(NSUserDefaults['- setObject:forKey:'].implementation, {
                onEnter: function(args) {
                    var object = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]);
                    var keyStr = key.toString();
                    
                    // 只显示可能相关的 key（过滤掉系统的）
                    if (keyStr.indexOf('fanhan') !== -1 || 
                        keyStr.indexOf('soul') !== -1 || 
                        keyStr.indexOf('knight') !== -1 ||
                        keyStr.indexOf('cheat') !== -1 ||
                        keyStr.indexOf('hack') !== -1 ||
                        keyStr.indexOf('gold') !== -1 ||
                        keyStr.indexOf('coin') !== -1 ||
                        keyStr.indexOf('gem') !== -1 ||
                        keyStr.indexOf('diamond') !== -1) {
                        console.log("\n[setObject:forKey:]");
                        console.log("  key: " + keyStr);
                        console.log("  value: " + object);
                    }
                }
            });
            console.log("[+] Hook setObject:forKey: 成功");
        } catch(e) {
            console.log("[-] Hook setObject:forKey: 失败: " + e);
        }
        
        // Hook setInteger:forKey:
        try {
            Interceptor.attach(NSUserDefaults['- setInteger:forKey:'].implementation, {
                onEnter: function(args) {
                    var value = args[2];
                    var key = ObjC.Object(args[3]);
                    var keyStr = key.toString();
                    
                    if (keyStr.indexOf('fanhan') !== -1 || 
                        keyStr.indexOf('soul') !== -1 || 
                        keyStr.indexOf('knight') !== -1 ||
                        keyStr.indexOf('cheat') !== -1 ||
                        keyStr.indexOf('hack') !== -1 ||
                        keyStr.indexOf('gold') !== -1 ||
                        keyStr.indexOf('coin') !== -1 ||
                        keyStr.indexOf('gem') !== -1 ||
                        keyStr.indexOf('diamond') !== -1) {
                        console.log("\n[setInteger:forKey:]");
                        console.log("  key: " + keyStr);
                        console.log("  value: " + value);
                    }
                }
            });
            console.log("[+] Hook setInteger:forKey: 成功");
        } catch(e) {
            console.log("[-] Hook setInteger:forKey: 失败: " + e);
        }
        
        // Hook setBool:forKey:
        try {
            Interceptor.attach(NSUserDefaults['- setBool:forKey:'].implementation, {
                onEnter: function(args) {
                    var value = args[2];
                    var key = ObjC.Object(args[3]);
                    var keyStr = key.toString();
                    
                    if (keyStr.indexOf('fanhan') !== -1 || 
                        keyStr.indexOf('soul') !== -1 || 
                        keyStr.indexOf('knight') !== -1 ||
                        keyStr.indexOf('cheat') !== -1 ||
                        keyStr.indexOf('hack') !== -1 ||
                        keyStr.indexOf('gold') !== -1 ||
                        keyStr.indexOf('coin') !== -1 ||
                        keyStr.indexOf('gem') !== -1 ||
                        keyStr.indexOf('diamond') !== -1) {
                        console.log("\n[setBool:forKey:]");
                        console.log("  key: " + keyStr);
                        console.log("  value: " + (value ? "true" : "false"));
                    }
                }
            });
            console.log("[+] Hook setBool:forKey: 成功");
        } catch(e) {
            console.log("[-] Hook setBool:forKey: 失败: " + e);
        }
        
        // Hook setFloat:forKey:
        try {
            Interceptor.attach(NSUserDefaults['- setFloat:forKey:'].implementation, {
                onEnter: function(args) {
                    var value = args[2];
                    var key = ObjC.Object(args[3]);
                    var keyStr = key.toString();
                    
                    if (keyStr.indexOf('fanhan') !== -1 || 
                        keyStr.indexOf('soul') !== -1 || 
                        keyStr.indexOf('knight') !== -1 ||
                        keyStr.indexOf('cheat') !== -1 ||
                        keyStr.indexOf('hack') !== -1 ||
                        keyStr.indexOf('gold') !== -1 ||
                        keyStr.indexOf('coin') !== -1 ||
                        keyStr.indexOf('gem') !== -1 ||
                        keyStr.indexOf('diamond') !== -1) {
                        console.log("\n[setFloat:forKey:]");
                        console.log("  key: " + keyStr);
                        console.log("  value: " + value);
                    }
                }
            });
            console.log("[+] Hook setFloat:forKey: 成功");
        } catch(e) {
            console.log("[-] Hook setFloat:forKey: 失败: " + e);
        }
        
        console.log("\n[*] NSUserDefaults Hook 设置完成");
        console.log("[*] 请在游戏中开启功能");
    }
}, 3000);
