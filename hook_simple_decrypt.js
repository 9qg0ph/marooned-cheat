// 简单解密 Hook
console.log("[*] Hook 开始");

if (ObjC.available) {
    // Hook NSJSONSerialization
    var NSJSONSerialization = ObjC.classes.NSJSONSerialization;
    Interceptor.attach(NSJSONSerialization['+ JSONObjectWithData:options:error:'].implementation, {
        onEnter: function(args) {
            try {
                var data = ObjC.Object(args[2]);
                var str = ObjC.classes.NSString.alloc().initWithData_encoding_(data, 4);
                if (str) {
                    var s = str.toString();
                    if (s.length > 50 && s.length < 10000) {
                        console.log("\n[JSON] " + s);
                    }
                }
            } catch(e) {}
        }
    });
    console.log("[+] Hook 成功，请点击悬浮图标");
}
