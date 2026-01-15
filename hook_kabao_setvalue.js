console.log("[*] 卡包修仙 Hook 脚本启动...");

setTimeout(function() {
    if (ObjC.available) {
        console.log("[*] ObjC 可用，开始查找 FanhanGGEngine 类...");
        
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            console.log("[+] 找到 FanhanGGEngine 类，开始 Hook setValue 方法...");
            
            Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                onEnter: function(args) {
                    try {
                        var value = ObjC.Object(args[2]);
                        var key = ObjC.Object(args[3]);
                        var type = ObjC.Object(args[4]);
                        
                        // 只显示简短的关键信息，避免过长输出导致崩溃
                        var valueStr = value.toString();
                        if (valueStr.length > 200) {
                            valueStr = valueStr.substring(0, 200) + "...";
                        }
                        
                        console.log("\n[卡包修仙 setValue]");
                        console.log("  key: " + key);
                        console.log("  value: " + valueStr);
                        console.log("  type: " + type);
                        console.log("  ==================");
                    } catch (e) {
                        console.log("Hook error: " + e);
                    }
                }
            });
            console.log("[+] Hook 成功！请在游戏中开启功能来抓取参数");
            console.log("[*] 操作步骤：");
            console.log("    1. 点击悬浮图标打开功能菜单");
            console.log("    2. 逐个开启每个功能");
            console.log("    3. 记录控制台输出的参数");
        } else {
            console.log("[-] 未找到 FanhanGGEngine 类，可能游戏未加载或版本不匹配");
        }
    } else {
        console.log("[-] ObjC 不可用");
    }
}, 8000);

console.log("[*] 等待 8 秒让游戏完全加载...");