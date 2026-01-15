// Hook MIUAES 解密
console.log("[*] Hook MIUAES");

if (ObjC.available) {
    var MIUAES = ObjC.classes.MIUAES;
    if (MIUAES) {
        console.log("[+] 找到 MIUAES 类");
        
        // 列出所有方法
        var methods = MIUAES.$ownMethods;
        console.log("方法列表:");
        for (var i = 0; i < methods.length; i++) {
            console.log("  " + methods[i]);
        }
        
        // Hook 解密方法
        for (var i = 0; i < methods.length; i++) {
            var method = methods[i];
            if (method.indexOf('decrypt') !== -1 || method.indexOf('Decrypt') !== -1 ||
                method.indexOf('decode') !== -1 || method.indexOf('Decode') !== -1) {
                (function(m) {
                    Interceptor.attach(MIUAES[m].implementation, {
                        onEnter: function(args) {
                            console.log("\n[调用] " + m);
                            if (args[2]) {
                                var input = ObjC.Object(args[2]);
                                console.log("输入: " + input.toString().substring(0, 200));
                            }
                        },
                        onLeave: function(retval) {
                            if (retval) {
                                var output = ObjC.Object(retval);
                                console.log("输出: " + output.toString().substring(0, 3000));
                            }
                        }
                    });
                    console.log("[+] Hook " + m);
                })(method);
            }
        }
    }

    // 同时 Hook NSString initWithData 抓大数据
    var NSString = ObjC.classes.NSString;
    Interceptor.attach(NSString['- initWithData:encoding:'].implementation, {
        onLeave: function(retval) {
            try {
                var str = ObjC.Object(retval);
                if (str && !str.isNull()) {
                    var s = str.toString();
                    if (s.length > 1000 && s.indexOf('{') !== -1) {
                        console.log("\n========== 大JSON数据 (" + s.length + " 字符) ==========");
                        console.log(s.substring(0, 5000));
                        console.log("==========================================\n");
                    }
                }
            } catch(e) {}
        }
    });

    console.log("[+] Hook 完成");
}
