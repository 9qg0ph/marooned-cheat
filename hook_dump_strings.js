// Dump 内存中的字符串
console.log("[*] 等待游戏加载...");

setTimeout(function() {
    if (ObjC.available) {
        console.log("[*] 开始扫描 NSString...");
        
        var count = 0;
        var found = [];
        
        ObjC.choose(ObjC.classes.NSString, {
            onMatch: function(instance) {
                try {
                    var str = instance.toString();
                    // 查找包含脚本关键字的字符串
                    if (str.length > 100 && str.length < 50000) {
                        if (str.indexOf('offset') !== -1 || 
                            str.indexOf('hook') !== -1 ||
                            str.indexOf('patch') !== -1 ||
                            str.indexOf('address') !== -1 ||
                            str.indexOf('memory') !== -1 ||
                            str.indexOf('cheat') !== -1 ||
                            str.indexOf('hack') !== -1 ||
                            str.indexOf('unlimited') !== -1 ||
                            str.indexOf('infinite') !== -1 ||
                            str.indexOf('金萝卜') !== -1 ||
                            str.indexOf('广告') !== -1 ||
                            str.indexOf('无限') !== -1) {
                            console.log("\n========== 找到 (" + str.length + " 字符) ==========");
                            console.log(str.substring(0, 3000));
                            console.log("==========================================\n");
                            found.push(str);
                        }
                    }
                    count++;
                    if (count % 10000 === 0) {
                        console.log("[*] 已扫描 " + count + " 个字符串...");
                    }
                } catch(e) {}
            },
            onComplete: function() {
                console.log("[*] 扫描完成，共 " + count + " 个字符串，找到 " + found.length + " 个匹配");
            }
        });
    }
}, 10000);
