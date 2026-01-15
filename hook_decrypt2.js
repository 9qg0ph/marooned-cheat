// Hook 解密相关方法
console.log("[*] Hook 解密");

if (ObjC.available) {
    // 列出所有可能的解密类
    var found = [];
    for (var name in ObjC.classes) {
        if (name.indexOf('AES') !== -1 || name.indexOf('Crypt') !== -1 || 
            name.indexOf('Cipher') !== -1 || name.indexOf('Decrypt') !== -1 ||
            name.indexOf('Security') !== -1) {
            found.push(name);
        }
    }
    console.log("找到的加密类: " + found.join(", "));

    // Hook NSData 的各种解码方法
    var NSData = ObjC.classes.NSData;
    
    // Hook base64 解码后的数据处理
    Interceptor.attach(NSData['- initWithBase64EncodedData:options:'].implementation, {
        onLeave: function(retval) {
            try {
                var data = ObjC.Object(retval);
                if (data && !data.isNull()) {
                    var len = data.length();
                    if (len > 1000) {
                        console.log("\n[Base64解码] 长度: " + len);
                    }
                }
            } catch(e) {}
        }
    });

    // Hook 字符串创建，找解密后的 JSON
    var NSString = ObjC.classes.NSString;
    Interceptor.attach(NSString['- initWithData:encoding:'].implementation, {
        onLeave: function(retval) {
            try {
                var str = ObjC.Object(retval);
                if (str && !str.isNull()) {
                    var s = str.toString();
                    // 检查是否是 JSON 格式的脚本数据
                    if (s.length > 500 && (s.indexOf('{') !== -1 || s.indexOf('[') !== -1)) {
                        if (s.indexOf('func') !== -1 || s.indexOf('name') !== -1 ||
                            s.indexOf('offset') !== -1 || s.indexOf('value') !== -1 ||
                            s.indexOf('hook') !== -1 || s.indexOf('patch') !== -1 ||
                            s.indexOf('menu') !== -1 || s.indexOf('cheat') !== -1 ||
                            s.indexOf('gold') !== -1 || s.indexOf('coin') !== -1 ||
                            s.indexOf('ad') !== -1 || s.indexOf('skip') !== -1) {
                            console.log("\n========== 解密数据 ==========");
                            console.log(s.substring(0, 8000));
                            if (s.length > 8000) {
                                console.log("\n... 共 " + s.length + " 字符");
                            }
                            console.log("==============================\n");
                        }
                    }
                }
            } catch(e) {}
        }
    });

    console.log("[+] Hook 成功，等待解密数据...");
}
