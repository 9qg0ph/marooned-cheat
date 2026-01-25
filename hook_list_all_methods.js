console.log("[*] 列出 FanhanGGEngine 的所有方法...");

if (ObjC.available) {
    var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
    if (FanhanGGEngine) {
        console.log("[+] FanhanGGEngine 类存在");
        console.log("\n[*] 所有方法:");
        var methods = FanhanGGEngine.$ownMethods;
        methods.forEach(function(m) {
            console.log("  " + m);
        });
        
        console.log("\n[*] 搜索包含 'value' 的方法:");
        methods.forEach(function(m) {
            if (m.toLowerCase().indexOf('value') !== -1) {
                console.log("  ✓ " + m);
            }
        });
        
        console.log("\n[*] 搜索包含 'set' 的方法:");
        methods.forEach(function(m) {
            if (m.toLowerCase().indexOf('set') !== -1) {
                console.log("  ✓ " + m);
            }
        });
    }
}
