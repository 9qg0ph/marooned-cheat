// 扫描内存中的脚本数据
console.log("[*] 扫描内存");

setTimeout(function() {
    if (ObjC.available) {
        // 获取 FanhanGGEngine 实例
        ObjC.choose(ObjC.classes.FanhanGGEngine, {
            onMatch: function(instance) {
                console.log("[+] 找到 FanhanGGEngine 实例: " + instance);
                
                // 尝试获取属性
                try {
                    var names = instance.names();
                    console.log("names: " + names);
                } catch(e) {}
            },
            onComplete: function() {
                console.log("[*] 扫描完成");
            }
        });

        // 获取 FloatMenu 实例
        ObjC.choose(ObjC.classes.FloatMenu, {
            onMatch: function(instance) {
                console.log("[+] 找到 FloatMenu 实例: " + instance);
                
                // 列出所有属性
                var props = instance.$ivars;
                for (var key in props) {
                    console.log("  " + key + ": " + props[key]);
                }
            },
            onComplete: function() {}
        });

        // 获取 FloatController 实例
        ObjC.choose(ObjC.classes.FloatController, {
            onMatch: function(instance) {
                console.log("[+] 找到 FloatController 实例: " + instance);
            },
            onComplete: function() {}
        });
    }
}, 8000);
