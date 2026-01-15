// Hook MIUAES 抓取密钥和解密数据
console.log("[*] Hook MIUAES 抓密钥");

if (ObjC.available) {
    var MIUAES = ObjC.classes.MIUAES;
    if (MIUAES) {
        Interceptor.attach(MIUAES['+ MIUAESWithData:operation:mode:key:keySize:iv:padding:'].implementation, {
            onEnter: function(args) {
                // args[2] = data, args[3] = operation, args[4] = mode
                // args[5] = key, args[6] = keySize, args[7] = iv, args[8] = padding
                var key = ObjC.Object(args[5]);
                var keySize = ObjC.Object(args[6]);
                var iv = ObjC.Object(args[7]);
                var data = ObjC.Object(args[2]);
                
                console.log("\n[MIUAES 调用]");
                console.log("  key: " + key);
                console.log("  keySize: " + keySize);
                console.log("  iv: " + iv);
                if (data) {
                    console.log("  data长度: " + data.length());
                }
            },
            onLeave: function(retval) {
                try {
                    var data = ObjC.Object(retval);
                    if (data && !data.isNull()) {
                        var len = data.length();
                        if (len > 500) {
                            var str = ObjC.classes.NSString.alloc().initWithData_encoding_(data, 4);
                            if (str && !str.isNull()) {
                                var s = str.toString();
                                console.log("\n========== 解密结果 (" + len + " bytes) ==========");
                                console.log(s.substring(0, 20000));
                                console.log("==========================================\n");
                            }
                        }
                    }
                } catch(e) {}
            }
        });
        console.log("[+] Hook 成功");
    }
}
