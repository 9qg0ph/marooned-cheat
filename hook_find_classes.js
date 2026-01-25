console.log("[*] 开始搜索 GameForFun 相关类...");

setTimeout(function() {
    if (ObjC.available) {
        console.log("[*] ObjC 运行时可用，开始枚举类...");
        
        // 搜索所有包含 Fanhan 或 GG 的类
        var classes = [];
        for (var className in ObjC.classes) {
            if (className.toLowerCase().indexOf('fanhan') !== -1 || 
                className.toLowerCase().indexOf('gg') !== -1 ||
                className.toLowerCase().indexOf('engine') !== -1) {
                classes.push(className);
            }
        }
        
        if (classes.length > 0) {
            console.log("[+] 找到以下相关类:");
            classes.forEach(function(name) {
                console.log("  - " + name);
                
                // 尝试列出类的方法
                try {
                    var methods = ObjC.classes[name].$ownMethods;
                    if (methods.length > 0) {
                        console.log("    方法:");
                        methods.slice(0, 10).forEach(function(method) {
                            console.log("      * " + method);
                        });
                        if (methods.length > 10) {
                            console.log("      ... 还有 " + (methods.length - 10) + " 个方法");
                        }
                    }
                } catch(e) {}
            });
        } else {
            console.log("[-] 未找到 Fanhan/GG 相关类");
            console.log("[*] 尝试搜索 setValue 相关方法...");
            
            // 搜索所有包含 setValue 的类
            var setValueClasses = [];
            for (var className in ObjC.classes) {
                try {
                    var methods = ObjC.classes[className].$ownMethods;
                    for (var i = 0; i < methods.length; i++) {
                        if (methods[i].indexOf('setValue') !== -1 && 
                            methods[i].indexOf('forKey') !== -1) {
                            setValueClasses.push({
                                className: className,
                                method: methods[i]
                            });
                            break;
                        }
                    }
                } catch(e) {}
            }
            
            if (setValueClasses.length > 0) {
                console.log("[+] 找到包含 setValue:forKey 的类:");
                setValueClasses.slice(0, 20).forEach(function(item) {
                    console.log("  - " + item.className + " -> " + item.method);
                });
            }
        }
    } else {
        console.log("[-] ObjC 运行时不可用");
    }
}, 3000);
