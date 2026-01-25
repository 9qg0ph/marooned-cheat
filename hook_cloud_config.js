console.log("[*] Hook GameForFun 云端配置加载...");

if (ObjC.available) {
    // Hook NSURLSession 网络请求
    var NSURLSession = ObjC.classes.NSURLSession;
    if (NSURLSession) {
        console.log("[+] 找到 NSURLSession");
        
        // Hook dataTaskWithRequest
        var dataTaskWithRequest = NSURLSession['- dataTaskWithRequest:completionHandler:'];
        if (dataTaskWithRequest) {
            Interceptor.attach(dataTaskWithRequest.implementation, {
                onEnter: function(args) {
                    var request = new ObjC.Object(args[2]);
                    var url = request.URL().toString();
                    
                    // 只记录可能是 GameForFun 的请求
                    if (url.indexOf('fanhan') !== -1 || 
                        url.indexOf('game') !== -1 || 
                        url.indexOf('config') !== -1 ||
                        url.indexOf('script') !== -1) {
                        console.log("\n[网络请求]");
                        console.log("  URL: " + url);
                        console.log("  Method: " + request.HTTPMethod());
                    }
                },
                onLeave: function(retval) {
                    // 可以在这里捕获响应
                }
            });
        }
    }
    
    // Hook NSString 的 stringWithContentsOfURL (可能用于加载云端脚本)
    var NSString = ObjC.classes.NSString;
    if (NSString) {
        var stringWithContentsOfURL = NSString['+ stringWithContentsOfURL:encoding:error:'];
        if (stringWithContentsOfURL) {
            Interceptor.attach(stringWithContentsOfURL.implementation, {
                onEnter: function(args) {
                    var url = new ObjC.Object(args[2]);
                    console.log("\n[加载远程字符串]");
                    console.log("  URL: " + url.toString());
                },
                onLeave: function(retval) {
                    if (retval.isNull()) return;
                    var content = new ObjC.Object(retval);
                    var str = content.toString();
                    if (str.length > 0 && str.length < 10000) {
                        console.log("  内容: " + str);
                    } else {
                        console.log("  内容长度: " + str.length);
                    }
                }
            });
        }
    }
    
    // Hook NSData 的 dataWithContentsOfURL
    var NSData = ObjC.classes.NSData;
    if (NSData) {
        var dataWithContentsOfURL = NSData['+ dataWithContentsOfURL:'];
        if (dataWithContentsOfURL) {
            Interceptor.attach(dataWithContentsOfURL.implementation, {
                onEnter: function(args) {
                    var url = new ObjC.Object(args[2]);
                    console.log("\n[加载远程数据]");
                    console.log("  URL: " + url.toString());
                },
                onLeave: function(retval) {
                    if (retval.isNull()) return;
                    var data = new ObjC.Object(retval);
                    console.log("  数据长度: " + data.length());
                }
            });
        }
    }
    
    // Hook FanhanGGEngine 的初始化方法
    var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
    if (FanhanGGEngine) {
        console.log("[+] 找到 FanhanGGEngine");
        
        // 列出所有方法，寻找可能的配置加载方法
        var methods = FanhanGGEngine.$ownMethods;
        console.log("\n[FanhanGGEngine 方法列表]");
        methods.forEach(function(method) {
            if (method.indexOf('load') !== -1 || 
                method.indexOf('init') !== -1 || 
                method.indexOf('config') !== -1 ||
                method.indexOf('fetch') !== -1 ||
                method.indexOf('get') !== -1) {
                console.log("  " + method);
            }
        });
    }
    
    console.log("\n[*] Hook 完成，等待云端配置加载...");
} else {
    console.log("[-] ObjC 不可用");
}
