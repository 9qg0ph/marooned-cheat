// Hook 解密后的脚本内容
console.log("[*] Hook 开始");

if (ObjC.available) {
    // 找到 GameForFun 相关类
    var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
    if (FanhanGGEngine) {
        console.log("[+] 找到 FanhanGGEngine");
        
        // 列出所有方法
        var methods = FanhanGGEngine.$ownMethods;
        for (var i = 0; i < methods.length; i++) {
            console.log("  方法: " + methods[i]);
        }
    }

    // Hook AES/DES 解密 - CommonCrypto
    var CCCrypt = Module.findExportByName(null, "CCCrypt");
    if (CCCrypt) {
        Interceptor.attach(CCCrypt, {
            onEnter: function(args) {
                this.op = args[0].toInt32(); // 0=encrypt, 1=decrypt
                this.dataOut = args[6];
                this.dataOutAvailable = args[7].toInt32();
                this.dataOutMoved = args[8];
            },
            onLeave: function(retval) {
                if (this.op === 1 && retval.toInt32() === 0) { // decrypt success
                    try {
                        var len = this.dataOutMoved.readU32();
                        if (len > 100 && len < 50000) {
                            var data = this.dataOut.readByteArray(len);
                            var str = "";
                            var bytes = new Uint8Array(data);
                            for (var i = 0; i < len; i++) {
                                str += String.fromCharCode(bytes[i]);
                            }
                            // 检查是否包含脚本关键字
                            if (str.indexOf('func') !== -1 || str.indexOf('menu') !== -1 ||
                                str.indexOf('gold') !== -1 || str.indexOf('ad') !== -1 ||
                                str.indexOf('cheat') !== -1 || str.indexOf('hack') !== -1 ||
                                str.indexOf('hook') !== -1 || str.indexOf('patch') !== -1 ||
                                str.indexOf('offset') !== -1 || str.indexOf('address') !== -1 ||
                                str.indexOf('memory') !== -1 || str.indexOf('value') !== -1 ||
                                str.indexOf('无限') !== -1 || str.indexOf('跳过') !== -1 ||
                                str.indexOf('{') !== -1) {
                                console.log("\n========== 解密数据 (" + len + " bytes) ==========");
                                console.log(str.substring(0, 3000));
                                console.log("==========================================\n");
                            }
                        }
                    } catch(e) {}
                }
            }
        });
        console.log("[+] Hook CCCrypt 成功");
    }

    // Hook NSData 的 base64 解码
    var NSData = ObjC.classes.NSData;
    Interceptor.attach(NSData['- initWithBase64EncodedString:options:'].implementation, {
        onLeave: function(retval) {
            try {
                var data = ObjC.Object(retval);
                var len = data.length();
                if (len > 100 && len < 50000) {
                    var str = ObjC.classes.NSString.alloc().initWithData_encoding_(data, 4);
                    if (str) {
                        var s = str.toString();
                        if (s.indexOf('func') !== -1 || s.indexOf('menu') !== -1 ||
                            s.indexOf('{') !== -1) {
                            console.log("\n[Base64解码] " + s.substring(0, 2000));
                        }
                    }
                }
            } catch(e) {}
        }
    });

    console.log("\n[+] Hook 成功，请点击悬浮图标查看功能菜单");
}
