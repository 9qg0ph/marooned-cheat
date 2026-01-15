// 抓取所有 fanhan 相关请求
console.log("[*] 等待...");

setTimeout(function() {
    if (ObjC.available) {
        var NSURLSession = ObjC.classes.NSURLSession;
        
        // Hook dataTaskWithRequest
        Interceptor.attach(NSURLSession['- dataTaskWithRequest:completionHandler:'].implementation, {
            onEnter: function(args) {
                var request = ObjC.Object(args[2]);
                var url = request.URL().absoluteString().toString();
                
                if (url.indexOf('fanhan') !== -1) {
                    console.log("\n========== 请求 ==========");
                    console.log("URL: " + url);
                    
                    var body = request.HTTPBody();
                    if (body) {
                        var bodyStr = ObjC.classes.NSString.alloc().initWithData_encoding_(body, 4);
                        if (bodyStr) {
                            console.log("Body: " + bodyStr.toString().substring(0, 200));
                        }
                    }
                    
                    // Hook 响应
                    var block = new ObjC.Block(args[3]);
                    var origImpl = block.implementation;
                    block.implementation = function(data, response, error) {
                        if (data) {
                            var nsdata = ObjC.Object(data);
                            var len = nsdata.length();
                            console.log("响应长度: " + len + " bytes");
                            
                            var str = ObjC.classes.NSString.alloc().initWithData_encoding_(nsdata, 4);
                            if (str) {
                                var content = str.toString();
                                console.log("响应内容: " + content.substring(0, 1000));
                                if (content.length > 1000) {
                                    console.log("... (截断，共 " + content.length + " 字符)");
                                }
                            }
                        }
                        console.log("==========================\n");
                        return origImpl(data, response, error);
                    };
                }
            }
        });
        
        console.log("[+] Hook 成功");
    }
}, 2000);
