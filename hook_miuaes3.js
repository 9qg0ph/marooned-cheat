// Hook MIUAES 解密
console.log("[*] Hook MIUAES");

if (ObjC.available) {
    var MIUAES = ObjC.classes.MIUAES;
    
    // Hook 主加解密方法
    Interceptor.attach(MIUAES['+ MIUAESWithData:operation:mode:key:keySize:iv:padding:'].implementation, {
        onEnter: function(args) {
            // operation 是 NSNumber，args[3]
            try {
                var opNum = ObjC.Object(args[3]);
                this.operation = parseInt(opNum.toString());
            } catch(e) {
                this.operation = -1;
            }
        },
        onLeave: function(retval) {
            if (this.operation === 1 && retval) { // decrypt
                try {
                    var data = ObjC.Object(retval);
                    if (data && !data.isNull()) {
                        var len = data.length();
                        if (len > 500) {
                            console.log("\n[MIUAES 解密] 长度: " + len + " bytes");
                            
                            var str = ObjC.classes.NSString.alloc().initWithData_encoding_(data, 4);
                            if (str && !str.isNull()) {
                                var s = str.toString();
                                console.log("\n========== 解密内容 ==========");
                                console.log(s.substring(0, 10000));
                                if (s.length > 10000) {
                                    console.log("\n... 共 " + s.length + " 字符");
                                }
                                console.log("==============================\n");
                            }
                        }
                    }
                } catch(e) {
                    console.log("Error: " + e);
                }
            }
        }
    });

    console.log("[+] Hook 成功");
}
