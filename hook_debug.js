console.log("[*] 脚本开始执行");

if (ObjC.available) {
    console.log("[+] ObjC 运行时可用");
    
    var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
    if (FanhanGGEngine) {
        console.log("[+] 找到 FanhanGGEngine 类");
        
        try {
            Interceptor.attach(FanhanGGEngine['- setone:two:three:four:five:name:'].implementation, {
                onEnter: function(args) {
                    var one = new ObjC.Object(args[2]);
                    var two = new ObjC.Object(args[3]);
                    var three = new ObjC.Object(args[4]);
                    var four = new ObjC.Object(args[5]);
                    var five = new ObjC.Object(args[6]);
                    var name = new ObjC.Object(args[7]);
                    
                    console.log("\n========== [setone] ==========");
                    console.log("  one: " + one);
                    console.log("  two: " + two);
                    console.log("  three: " + three);
                    console.log("  four: " + four);
                    console.log("  five: " + five);
                    console.log("  name: " + name);
                    console.log("==============================\n");
                }
            });
            console.log("[+] Hook setone 成功");
        } catch(e) {
            console.log("[-] Hook setone 失败: " + e);
        }
        
        console.log("[*] 准备就绪，请在游戏中开启功能");
    } else {
        console.log("[-] 未找到 FanhanGGEngine 类");
    }
} else {
    console.log("[-] ObjC 运行时不可用");
}
