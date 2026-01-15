// 最终版 - 只 Hook NSString 抓大 JSON
console.log("[*] 启动");

setTimeout(function() {
    if (ObjC.available) {
        var NSString = ObjC.classes.NSString;
        
        Interceptor.attach(NSString['- initWithData:encoding:'].implementation, {
            onLeave: function(retval) {
                try {
                    var str = ObjC.Object(retval);
                    if (str && !str.isNull()) {
                        var s = str.toString();
                        // 只抓大于 1000 字符且包含 JSON 特征的数据
                        if (s.length > 1000 && (s.indexOf('{"') !== -1 || s.indexOf('[{') !== -1)) {
                            console.log("\n========== JSON数据 (" + s.length + " 字符) ==========");
                            console.log(s.substring(0, 15000));
                            if (s.length > 15000) {
                                console.log("\n... 共 " + s.length + " 字符");
                            }
                            console.log("==========================================\n");
                        }
                    }
                } catch(e) {}
            }
        });
        
        console.log("[+] Hook 成功");
    }
}, 3000);
