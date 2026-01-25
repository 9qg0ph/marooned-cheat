console.log("[*] 开始搜索...");

if (ObjC.available) {
    console.log("[+] ObjC 可用");
    
    // 检查 FanhanGGEngine 类是否存在
    var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
    if (FanhanGGEngine) {
        console.log("[+] 找到 FanhanGGEngine 类");
        console.log("[*] 类的方法:");
        var methods = FanhanGGEngine.$ownMethods;
        methods.forEach(function(m) {
            console.log("  " + m);
        });
    } else {
        console.log("[-] 未找到 FanhanGGEngine 类");
        console.log("[*] 搜索所有包含 'Fanhan' 的类...");
        
        var found = false;
        for (var className in ObjC.classes) {
            if (className.indexOf('Fanhan') !== -1) {
                console.log("[+] 找到: " + className);
                found = true;
            }
        }
        
        if (!found) {
            console.log("[-] 没有找到任何 Fanhan 相关的类");
            console.log("[!] GameForFun 插件可能没有注入到这个游戏中");
        }
    }
} else {
    console.log("[-] ObjC 不可用");
}
