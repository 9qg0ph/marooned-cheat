// 立即 Hook - 不延迟
console.log("[*] 立即 Hook");

if (ObjC.available) {
    // Hook MIUAES 解密 - 这是解密的核心
    var MIUAES = ObjC.classes.MIUAES;
    if (MIUAES) {
        Interceptor.attach(MIUAES['+ MIUAESWithData:operation:mode:key:keySize:iv:padding:'].implementation, {
            onLeave: function(retval) {
                try {
                    var data = ObjC.Object(retval);
                    if (data && !data.isNull()) {
                        var len = data.length();
                        if (len > 1000) {
                            var str = ObjC.classes.NSString.alloc().initWithData_encoding_(data, 4);
                            if (str && !str.isNull()) {
                                var s = str.toString();
                                if (s.length > 500) {
                                    console.log("\n========== AES解密 (" + len + " bytes) ==========");
                                    console.log(s.substring(0, 15000));
                                    if (s.length > 15000) {
                                        console.log("\n... 共 " + s.length + " 字符");
                                    }
                                    console.log("==========================================\n");
                                }
                            }
                        }
                    }
                } catch(e) {}
            }
        });
        console.log("[+] Hook MIUAES 成功");
    }

    // 同时 Hook NSJSONSerialization
    var NSJSONSerialization = ObjC.classes.NSJSONSerialization;
    Interceptor.attach(NSJSONSerialization['+ JSONObjectWithData:options:error:'].implementation, {
        onEnter: function(args) {
            try {
                var data = ObjC.Object(args[2]);
                if (data && !data.isNull()) {
                    var len = data.length();
                    if (len > 1000) {
                        var str = ObjC.classes.NSString.alloc().initWithData_encoding_(data, 4);
                        if (str && !str.isNull()) {
                            var s = str.toString();
                            console.log("\n========== JSON解析 (" + len + " bytes) ==========");
                            console.log(s.substring(0, 15000));
                            if (s.length > 15000) {
                                console.log("\n... 共 " + s.length + " 字符");
                            }
                            console.log("==========================================\n");
                        }
                    }
                }
            } catch(e) {}
        }
    });
    console.log("[+] Hook JSON 成功");
}
