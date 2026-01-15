// Hook AES 解密，抓取明文脚本
console.log("[*] Hook AES 解密");

if (ObjC.available) {
    // Hook CCCrypt (CommonCrypto)
    var CCCrypt = Module.findExportByName(null, "CCCrypt");
    if (CCCrypt) {
        Interceptor.attach(CCCrypt, {
            onEnter: function(args) {
                this.op = args[0].toInt32(); // 0=encrypt, 1=decrypt
                this.alg = args[1].toInt32(); // 0=AES, 1=DES, 2=3DES
                this.dataIn = args[4];
                this.dataInLen = args[5].toInt32();
                this.dataOut = args[6];
                this.dataOutAvailable = args[7].toInt32();
                this.dataOutMoved = args[8];
            },
            onLeave: function(retval) {
                if (this.op === 1 && retval.toInt32() === 0) { // decrypt success
                    try {
                        var len = this.dataOutMoved.readU32();
                        if (len > 500) { // 只关注大数据
                            console.log("\n[AES解密] 长度: " + len + " bytes");
                            
                            var data = this.dataOut.readByteArray(len);
                            var bytes = new Uint8Array(data);
                            
                            // 转字符串
                            var str = "";
                            for (var i = 0; i < len; i++) {
                                if (bytes[i] >= 32 && bytes[i] < 127) {
                                    str += String.fromCharCode(bytes[i]);
                                } else if (bytes[i] === 10 || bytes[i] === 13) {
                                    str += "\n";
                                }
                            }
                            
                            console.log("解密内容:\n" + str.substring(0, 5000));
                            if (str.length > 5000) {
                                console.log("\n... 共 " + str.length + " 字符");
                            }
                        }
                    } catch(e) {
                        console.log("Error: " + e);
                    }
                }
            }
        });
        console.log("[+] Hook CCCrypt 成功");
    } else {
        console.log("[-] CCCrypt 未找到");
    }
}
