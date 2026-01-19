// 复制其他修改器的ES3存档修改方法
console.log("🎯 ES3存档修改方法复制脚本已加载");

setTimeout(function() {
    console.log("🎯 开始复制ES3存档修改方法...");
    
    // 1. 监控ES3存档的读取和写入
    monitorES3Operations();
    
    // 2. 捕获存档数据结构
    captureES3Structure();
    
    // 3. 生成修改代码
    generateES3ModificationCode();
    
    console.log("=".repeat(60));
    console.log("🎯 ES3存档修改方法复制系统已启动！");
    console.log("💡 现在操作其他修改器，我们将学习其ES3修改方法");
    console.log("=".repeat(60));
    
}, 1000);

// 监控ES3存档操作
function monitorES3Operations() {
    console.log("[监控] ES3存档操作...");
    
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        // 监控ES3存档的setObject操作
        var setObject = NSUserDefaults['- setObject:forKey:'];
        if (setObject) {
            Interceptor.attach(setObject.implementation, {
                onEnter: function(args) {
                    var obj = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]).toString();
                    
                    // 捕获ES3相关的操作
                    if (key.includes("data1.es3") || key.includes("timestamp_data1.es3")) {
                        console.log("📦 [ES3操作] 键: " + key);
                        
                        if (obj && obj.isKindOfClass_(ObjC.classes.NSString)) {
                            var dataStr = obj.toString();
                            console.log("   数据类型: 字符串");
                            console.log("   数据长度: " + dataStr.length);
                            
                            // 如果是ES3存档数据，尝试解析
                            if (key === "data1.es3" && dataStr.length > 1000) {
                                console.log("🔍 [ES3数据] 捕获到完整ES3存档:");
                                analyzeES3Data(dataStr);
                            }
                        } else if (obj && obj.respondsToSelector_(ObjC.selector('integerValue'))) {
                            var value = obj.integerValue();
                            console.log("   数据类型: 数字");
                            console.log("   数值: " + value);
                        }
                        
                        console.log("---");
                    }
                }
            });
        }
        
        // 监控ES3存档的读取
        var objectForKey = NSUserDefaults['- objectForKey:'];
        if (objectForKey) {
            Interceptor.attach(objectForKey.implementation, {
                onEnter: function(args) {
                    this.key = ObjC.Object(args[2]).toString();
                },
                onLeave: function(retval) {
                    if (this.key.includes("data1.es3") && !retval.isNull()) {
                        var obj = ObjC.Object(retval);
                        console.log("📖 [ES3读取] 读取ES3存档: " + this.key);
                        
                        if (obj.isKindOfClass_(ObjC.classes.NSString)) {
                            console.log("   数据长度: " + obj.length());
                        }
                    }
                }
            });
        }
        
        console.log("✅ ES3存档操作监控已启动");
    } catch (e) {
        console.log("❌ ES3存档操作监控失败: " + e.message);
    }
}

// 分析ES3数据结构
function analyzeES3Data(dataStr) {
    try {
        console.log("🔍 [ES3分析] 开始分析ES3数据结构...");
        
        // 检查是否是Base64编码
        if (dataStr.match(/^[A-Za-z0-9+/]+=*$/)) {
            console.log("   格式: Base64编码");
            
            // 尝试解码
            try {
                var NSData = ObjC.classes.NSData;
                var decodedData = NSData.alloc().initWithBase64EncodedString_options_(dataStr, 0);
                if (decodedData) {
                    var jsonStr = ObjC.classes.NSString.alloc().initWithData_encoding_(decodedData, 4); // NSUTF8StringEncoding = 4
                    if (jsonStr) {
                        console.log("   解码后长度: " + jsonStr.length());
                        console.log("   内容预览: " + jsonStr.toString().substring(0, 200) + "...");
                        
                        // 尝试解析JSON
                        try {
                            var NSJSONSerialization = ObjC.classes.NSJSONSerialization;
                            var jsonData = jsonStr.dataUsingEncoding_(4);
                            var jsonObj = NSJSONSerialization.JSONObjectWithData_options_error_(jsonData, 0, NULL);
                            
                            if (jsonObj) {
                                console.log("   JSON解析成功！");
                                analyzeGameData(jsonObj);
                            }
                        } catch (e) {
                            console.log("   JSON解析失败: " + e.message);
                        }
                    }
                }
            } catch (e) {
                console.log("   Base64解码失败: " + e.message);
            }
        } else {
            console.log("   格式: 纯文本JSON");
            console.log("   内容预览: " + dataStr.substring(0, 200) + "...");
        }
        
    } catch (e) {
        console.log("❌ ES3数据分析失败: " + e.message);
    }
}

// 分析游戏数据
function analyzeGameData(jsonObj) {
    console.log("🎮 [游戏数据] 分析JSON结构...");
    
    try {
        if (jsonObj.isKindOfClass_(ObjC.classes.NSDictionary)) {
            var dict = jsonObj;
            var keys = dict.allKeys();
            
            console.log("   顶级键数量: " + keys.count());
            
            for (var i = 0; i < Math.min(keys.count(), 5); i++) {
                var key = keys.objectAtIndex_(i);
                var value = dict.objectForKey_(key);
                console.log("   键[" + i + "]: " + key + " = " + value.class());
                
                // 如果是字典，进一步分析
                if (value.isKindOfClass_(ObjC.classes.NSDictionary)) {
                    analyzeGameDataRecursive(value, "    ");
                }
            }
        }
    } catch (e) {
        console.log("❌ 游戏数据分析失败: " + e.message);
    }
}

// 递归分析游戏数据
function analyzeGameDataRecursive(dict, indent) {
    try {
        var keys = dict.allKeys();
        
        for (var i = 0; i < Math.min(keys.count(), 3); i++) {
            var key = keys.objectAtIndex_(i);
            var value = dict.objectForKey_(key);
            
            console.log(indent + "子键: " + key + " = " + value.class());
            
            // 检查是否是游戏数值
            if (value.isKindOfClass_(ObjC.classes.NSNumber)) {
                var numValue = value.integerValue();
                if (numValue > 1000) {
                    console.log(indent + "  🎯 发现大数值: " + numValue);
                }
            }
            
            // 如果还是字典且层级不深，继续递归
            if (value.isKindOfClass_(ObjC.classes.NSDictionary) && indent.length < 12) {
                analyzeGameDataRecursive(value, indent + "  ");
            }
        }
    } catch (e) {}
}

// 捕获存档数据结构
function captureES3Structure() {
    console.log("[捕获] ES3存档数据结构...");
    
    // 定期检查当前的ES3存档
    setInterval(function() {
        try {
            var NSUserDefaults = ObjC.classes.NSUserDefaults;
            var defaults = NSUserDefaults.standardUserDefaults();
            
            var es3Data = defaults.objectForKey_("data1.es3");
            if (es3Data && es3Data.isKindOfClass_(ObjC.classes.NSString)) {
                var dataStr = es3Data.toString();
                console.log("📊 [定期检查] ES3存档状态:");
                console.log("   数据长度: " + dataStr.length);
                console.log("   最后修改: " + new Date().toLocaleTimeString());
            }
        } catch (e) {}
    }, 10000); // 每10秒检查一次
}

// 生成ES3修改代码
function generateES3ModificationCode() {
    console.log("[生成] ES3修改代码...");
    
    setTimeout(function() {
        console.log("\n" + "=".repeat(60));
        console.log("📋 基于捕获信息生成的ES3修改代码");
        console.log("=".repeat(60));
        
        console.log("// ========== Objective-C 版本 ==========");
        console.log(`
// 修改ES3存档的方法
static void modifyES3SaveData(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 1. 读取当前ES3存档
    NSString *currentES3 = [defaults objectForKey:@"data1.es3"];
    if (!currentES3) {
        NSLog(@"未找到ES3存档");
        return;
    }
    
    // 2. Base64解码
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:currentES3 options:0];
    NSString *jsonString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    
    // 3. 解析JSON
    NSError *error = nil;
    NSMutableDictionary *gameData = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] 
        options:NSJSONReadingMutableContainers error:&error];
    
    if (error || !gameData) {
        NSLog(@"JSON解析失败: %@", error.localizedDescription);
        return;
    }
    
    // 4. 修改游戏数据（需要根据实际结构调整）
    // 这里需要根据捕获到的数据结构来修改
    [self modifyGameDataRecursively:gameData];
    
    // 5. 重新序列化为JSON
    NSData *newJsonData = [NSJSONSerialization dataWithJSONObject:gameData options:0 error:&error];
    if (error || !newJsonData) {
        NSLog(@"JSON序列化失败: %@", error.localizedDescription);
        return;
    }
    
    // 6. Base64编码
    NSString *newJsonString = [[NSString alloc] initWithData:newJsonData encoding:NSUTF8StringEncoding];
    NSString *newES3Data = [[newJsonString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    
    // 7. 保存回NSUserDefaults
    [defaults setObject:newES3Data forKey:@"data1.es3"];
    
    // 8. 更新时间戳
    NSNumber *timestamp = @([[NSDate date] timeIntervalSince1970] * 1000000);
    [defaults setObject:timestamp forKey:@"timestamp_data1.es3"];
    
    // 9. 同步
    [defaults synchronize];
    
    NSLog(@"ES3存档修改完成！");
}

// 递归修改游戏数据
static void modifyGameDataRecursively(NSMutableDictionary *dict) {
    for (NSString *key in [dict allKeys]) {
        id value = dict[key];
        
        if ([value isKindOfClass:[NSMutableDictionary class]]) {
            [self modifyGameDataRecursively:value];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            NSInteger numValue = [value integerValue];
            
            // 根据键名和数值范围判断是否是游戏资源
            if (numValue > 100 && numValue < 1000000000) {
                NSString *lowerKey = [key lowercaseString];
                if ([lowerKey containsString:@"cash"] || [lowerKey containsString:@"money"] || 
                    [lowerKey containsString:@"现金"] || [lowerKey containsString:@"金钱"]) {
                    dict[key] = @21000000000;
                } else if ([lowerKey containsString:@"energy"] || [lowerKey containsString:@"stamina"] || 
                          [lowerKey containsString:@"体力"]) {
                    dict[key] = @21000000000;
                } else if ([lowerKey containsString:@"health"] || [lowerKey containsString:@"hp"] || 
                          [lowerKey containsString:@"健康"]) {
                    dict[key] = @1000000;
                } else if ([lowerKey containsString:@"mood"] || [lowerKey containsString:@"happiness"] || 
                          [lowerKey containsString:@"心情"]) {
                    dict[key] = @1000000;
                }
            }
        }
    }
}
`);
        
        console.log("\n// ========== Frida 版本 ==========");
        console.log(`
// Frida脚本版本
setTimeout(function() {
    console.log("开始修改ES3存档...");
    
    var NSUserDefaults = ObjC.classes.NSUserDefaults;
    var defaults = NSUserDefaults.standardUserDefaults();
    var NSData = ObjC.classes.NSData;
    var NSString = ObjC.classes.NSString;
    var NSJSONSerialization = ObjC.classes.NSJSONSerialization;
    var NSDate = ObjC.classes.NSDate;
    var NSNumber = ObjC.classes.NSNumber;
    
    // 读取ES3存档
    var currentES3 = defaults.objectForKey_("data1.es3");
    if (!currentES3) {
        console.log("未找到ES3存档");
        return;
    }
    
    console.log("找到ES3存档，长度: " + currentES3.length());
    
    // Base64解码
    var decodedData = NSData.alloc().initWithBase64EncodedString_options_(currentES3, 0);
    var jsonString = NSString.alloc().initWithData_encoding_(decodedData, 4);
    
    // 解析JSON
    var jsonData = jsonString.dataUsingEncoding_(4);
    var gameData = NSJSONSerialization.JSONObjectWithData_options_error_(jsonData, 1, NULL); // NSJSONReadingMutableContainers = 1
    
    if (gameData) {
        console.log("JSON解析成功，开始修改数据...");
        
        // 这里需要根据实际的数据结构来修改
        // 示例：修改顶级数值字段
        modifyGameDataRecursively(gameData);
        
        // 重新序列化
        var newJsonData = NSJSONSerialization.dataWithJSONObject_options_error_(gameData, 0, NULL);
        var newJsonString = NSString.alloc().initWithData_encoding_(newJsonData, 4);
        var newES3Data = newJsonString.dataUsingEncoding_(4).base64EncodedStringWithOptions_(0);
        
        // 保存
        defaults.setObject_forKey_(newES3Data, "data1.es3");
        
        // 更新时间戳
        var timestamp = NSNumber.numberWithLongLong_(NSDate.date().timeIntervalSince1970() * 1000000);
        defaults.setObject_forKey_(timestamp, "timestamp_data1.es3");
        
        defaults.synchronize();
        
        console.log("ES3存档修改完成！");
    } else {
        console.log("JSON解析失败");
    }
    
    function modifyGameDataRecursively(dict) {
        // 根据捕获到的实际数据结构来实现
        console.log("递归修改游戏数据...");
    }
    
}, 3000);
`);
        
        console.log("=".repeat(60));
        console.log("💡 提示：以上代码需要根据实际捕获到的ES3数据结构进行调整");
        console.log("=".repeat(60) + "\n");
        
    }, 5000);
}

console.log("📋 [提示] ES3存档修改方法复制系统加载完成...");