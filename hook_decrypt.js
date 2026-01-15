// Hook 解密函数，抓取明文数据

console.log("[*] 等待 Hook 解密函数...");

setTimeout(function() {
    if (ObjC.available) {
        try {
            // Hook NSJSONSerialization - 解析 JSON 时会调用
            var NSJSONSerialization = ObjC.classes.NSJSONSerialization;
            if (NSJSONSerialization) {
                var jsonMethod = NSJSONSerialization['+ JSONObjectWithData:options:error:'];
                if (jsonMethod) {
                    Interceptor.attach(jsonMethod.implementation, {
                        onEnter: function(args) {
                            try {
                                var data = ObjC.Object(args[2]);
                                var str = ObjC.classes.NSString.alloc().initWithData_encoding_(data, 4);
                                if (str) {
                                    var s = str.toString();
                                    if (s.indexOf('fanhan') !== -1 || s.indexOf('Fanhan') !== -1 || 
                                        s.indexOf('udid') !== -1 || s.indexOf('UDID') !== -1 ||
                                        s.indexOf('vip') !== -1 || s.indexOf('time') !== -1 ||
                                        s.indexOf('menu') !== -1 || s.indexOf('func') !== -1) {
                                        console.log("\n[JSON 解析] " + s.substring(0, 2000));
                                    }
                                }
                            } catch(e) {}
                        }
                    });
                    console.log("[+] Hook NSJSONSerialization 成功");
                }
            }

            // Hook NSString initWithData - 字符串解码
            var NSString = ObjC.classes.NSString;
            var initWithData = NSString['- initWithData:encoding:'];
            if (initWithData) {
                Interceptor.attach(initWithData.implementation, {
                    onLeave: function(retval) {
                        try {
                            var str = ObjC.Object(retval);
                            if (str) {
                                var s = str.toString();
                                if (s.length > 50 && s.length < 5000) {
                                    if (s.indexOf('fanhan') !== -1 || s.indexOf('Fanhan') !== -1 ||
                                        s.indexOf('udid') !== -1 || s.indexOf('UDID') !== -1 ||
                                        s.indexOf('expire') !== -1 || s.indexOf('time') !== -1 ||
                                        s.indexOf('menu') !== -1 || s.indexOf('func') !== -1 ||
                                        s.indexOf('gold') !== -1 || s.indexOf('ad') !== -1) {
                                        console.log("\n[解密数据] " + s.substring(0, 2000));
                                    }
                                }
                            }
                        } catch(e) {}
                    }
                });
                console.log("[+] Hook NSString 成功");
            }

            // Hook 常见加密库
            var CCCrypt = Module.findExportByName(null, "CCCrypt");
            if (CCCrypt) {
                Interceptor.attach(CCCrypt, {
                    onEnter: function(args) {
                        this.op = args[0].toInt32(); // 0=encrypt, 1=decrypt
                        this.dataOut = args[6];
                        this.dataOutLen = args[7];
                    },
                    onLeave: function(retval) {
                        if (this.op === 1) { // decrypt
                            try {
                                var len = this.dataOutLen.readU32();
                                if (len > 0 && len < 10000) {
                                    var data = this.dataOut.readByteArray(len);
                                    var str = "";
                                    var bytes = new Uint8Array(data);
                                    for (var i = 0; i < Math.min(len, 500); i++) {
                                        if (bytes[i] >= 32 && bytes[i] < 127) {
                                            str += String.fromCharCode(bytes[i]);
                                        }
                                    }
                                    if (str.length > 20) {
                                        console.log("\n[CCCrypt 解密] " + str);
                                    }
                                }
                            } catch(e) {}
                        }
                    }
                });
                console.log("[+] Hook CCCrypt 成功");
            }

            console.log("\n[*] 请点击悬浮图标触发验证...\n");

        } catch(e) {
            console.log("[-] Error: " + e);
        }
    }
}, 5000);
