// 只 Hook 网络响应，抓取完整数据
console.log("[*] 等待...");

setTimeout(function() {
    if (ObjC.available) {
        // Hook NSURLSession completionHandler
        var NSURLSession = ObjC.classes.NSURLSession;
        
        Interceptor.attach(NSURLSession['- dataTaskWithRequest:completionHandler:'].implementation, {
            onEnter: function(args) {
                var request = ObjC.Object(args[2]);
                var url = request.URL().absoluteString().toString();
                
                if (url.indexOf('fanhan') !== -1 || url.indexOf('Fanhan') !== -1) {
                    console.log("\n[请求] " + url);
                    this.isFanhan = true;
                    
                    // 保存原始 block
                    var block = new ObjC.Block(args[3]);
                    var origImpl = block.implementation;
                    
                    block.implementation = function(data, response, error) {
                        if (data) {
                            var nsdata = ObjC.Object(data);
                            var len = nsdata.length();
                            console.log("[响应长度] " + len + " bytes");
                            
                            // 尝试转字符串
                            var str = ObjC.classes.NSString.alloc().initWithData_encoding_(nsdata, 4);
                            if (str) {
                                console.log("[响应内容]\n" + str.toString());
                            } else {
                                // 尝试 hex dump
                                var bytes = nsdata.bytes();
                                var hex = "";
                                for (var i = 0; i < Math.min(len, 200); i++) {
                                    hex += ("0" + bytes.add(i).readU8().toString(16)).slice(-2) + " ";
                                }
                                console.log("[响应HEX] " + hex);
                            }
                        }
                        return origImpl(data, response, error);
                    };
                }
            }
        });
        
        console.log("[+] Hook 成功，请操作");
    }
}, 3000);
