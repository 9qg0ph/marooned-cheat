// 立即 Hook，不延迟
console.log("[*] 立即 Hook");

if (ObjC.available) {
    var NSURLSession = ObjC.classes.NSURLSession;
    
    Interceptor.attach(NSURLSession['- dataTaskWithRequest:completionHandler:'].implementation, {
        onEnter: function(args) {
            var request = ObjC.Object(args[2]);
            var url = request.URL().absoluteString().toString();
            
            // 抓所有 fanhan 和 SAO 相关
            if (url.indexOf('fanhan') !== -1 || url.indexOf('SAO') !== -1) {
                console.log("\n========== 请求 ==========");
                console.log("URL: " + url);
                
                var body = request.HTTPBody();
                if (body) {
                    var bodyStr = ObjC.classes.NSString.alloc().initWithData_encoding_(body, 4);
                    if (bodyStr) {
                        console.log("Body: " + bodyStr.toString().substring(0, 300));
                    }
                }
                
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
                            // 如果响应很长，保存到文件
                            if (content.length > 500) {
                                console.log("响应内容 (前2000字符):\n" + content.substring(0, 2000));
                                console.log("\n... 共 " + content.length + " 字符");
                            } else {
                                console.log("响应内容: " + content);
                            }
                        }
                    }
                    console.log("==========================\n");
                    return origImpl(data, response, error);
                };
            }
        }
    });
    
    console.log("[+] Hook 成功，等待请求...");
}
