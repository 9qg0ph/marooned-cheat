console.log("[*] Hook GameForFun 配置加载...");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] 找到 FanhanGGEngine");
            
            // Hook getLocalScripts - 获取本地脚本
            try {
                Interceptor.attach(FanhanGGEngine['- getLocalScripts'].implementation, {
                    onEnter: function(args) {
                        console.log("\n[getLocalScripts 被调用]");
                    },
                    onLeave: function(retval) {
                        if (!retval.isNull()) {
                            var result = new ObjC.Object(retval);
                            console.log("  返回: " + result.toString());
                        }
                    }
                });
                console.log("[+] Hook getLocalScripts");
            } catch(e) {}
            
            // Hook downloadAndReplaceFile - 下载配置
            try {
                Interceptor.attach(FanhanGGEngine['- downloadAndReplaceFile:fileName:type:'].implementation, {
                    onEnter: function(args) {
                        var url = new ObjC.Object(args[2]);
                        var fileName = new ObjC.Object(args[3]);
                        var type = new ObjC.Object(args[4]);
                        console.log("\n[downloadAndReplaceFile]");
                        console.log("  URL: " + url);
                        console.log("  文件名: " + fileName);
                        console.log("  类型: " + type);
                    }
                });
                console.log("[+] Hook downloadAndReplaceFile");
            } catch(e) {}
            
            // Hook loadPlugin - 加载插件
            try {
                Interceptor.attach(FanhanGGEngine['- loadPlugin:path:'].implementation, {
                    onEnter: function(args) {
                        var plugin = new ObjC.Object(args[2]);
                        var path = new ObjC.Object(args[3]);
                        console.log("\n[loadPlugin]");
                        console.log("  插件: " + plugin);
                        console.log("  路径: " + path);
                    }
                });
                console.log("[+] Hook loadPlugin");
            } catch(e) {}
            
            // Hook getFilepath - 获取文件路径
            try {
                Interceptor.attach(FanhanGGEngine['- getFilepath:withname:type:'].implementation, {
                    onEnter: function(args) {
                        var filepath = new ObjC.Object(args[2]);
                        var name = new ObjC.Object(args[3]);
                        var type = new ObjC.Object(args[4]);
                        console.log("\n[getFilepath]");
                        console.log("  路径: " + filepath);
                        console.log("  名称: " + name);
                        console.log("  类型: " + type);
                    },
                    onLeave: function(retval) {
                        if (!retval.isNull()) {
                            var result = new ObjC.Object(retval);
                            console.log("  返回路径: " + result);
                        }
                    }
                });
                console.log("[+] Hook getFilepath");
            } catch(e) {}
            
            // Hook initial_setup - 初始化
            try {
                Interceptor.attach(FanhanGGEngine['- initial_setup'].implementation, {
                    onEnter: function(args) {
                        console.log("\n[initial_setup 被调用]");
                    }
                });
                console.log("[+] Hook initial_setup");
            } catch(e) {}
            
            // Hook setValue - 仍然监听参数设置
            try {
                Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                    onEnter: function(args) {
                        var value = new ObjC.Object(args[2]);
                        var key = new ObjC.Object(args[3]);
                        var type = new ObjC.Object(args[4]);
                        console.log("\n[setValue]");
                        console.log("  key: " + key);
                        console.log("  value: " + value);
                        console.log("  type: " + type);
                    }
                });
                console.log("[+] Hook setValue");
            } catch(e) {}
            
            console.log("\n[*] 所有 Hook 完成");
        }
    }
}, 3000);
