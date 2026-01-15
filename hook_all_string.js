// Hook 所有字符串创建，找 fanhan 相关
console.log("[*] Hook 开始");

if (ObjC.available) {
    // Hook NSURLSession 响应
    var NSURLSession = ObjC.classes.NSURLSession;
    Interceptor.attach(NSURLSession['- dataTaskWithRequest:completionHandler:'].implementation, {
        onEnter: function(args) {
            var request = ObjC.Object(args[2]);
            var url = request.URL().absoluteString().toString();
            if (url.indexOf('fanhan') !== -1) {
                console.log("\n[请求] " + url);
                
                // Hook completionHandler
                var block = new ObjC.Block(args[3]);
                var origImpl = block.implementation;
                block.implementation = function(data, response, error) {
                    if (data) {
                        var nsdata = ObjC.Object(data);
                        var str = ObjC.classes.NSString.alloc().initWithData_encoding_(nsdata, 4);
                        if (str) {
                            console.log("[响应原始] " + str.toString().substring(0, 500));
                        }
                    }
                    return origImpl(data, response, error);
                };
            }
        }
    });

    // Hook GameForFun 的类
    var classes = ObjC.classes;
    for (var name in classes) {
        if (name.indexOf('Fanhan') !== -1 || name.indexOf('Float') !== -1) {
            console.log("[类] " + name);
        }
    }

    console.log("\n[+] Hook 成功，请点击悬浮图标");
}
