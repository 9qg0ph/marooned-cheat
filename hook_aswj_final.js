// ASWJGAMEPLUS.dylib 最终分析脚本
// 基于完整分析的总结版本

console.log("[*] ASWJGAMEPLUS 最终分析脚本");
console.log("[*] 目标游戏: 卡包修仙 (game.taptap.lantern.kbxx)");
console.log("[*] 等待游戏加载...");

setTimeout(function() {
    console.log("\n=== ASWJGAMEPLUS.dylib 分析开始 ===");
    
    var aswjModule = Process.findModuleByName("ASWJGAMEPLUS.dylib");
    if (!aswjModule) {
        console.log("[-] 未找到 ASWJGAMEPLUS.dylib");
        return;
    }
    
    var base = aswjModule.base;
    console.log("[+] ASWJGAMEPLUS.dylib 基址: " + base);
    console.log("[+] 大小: " + aswjModule.size + " bytes");
    
    // 显示关键偏移量
    console.log("\n=== 关键偏移量 ===");
    var keyOffsets = {
        "开关处理入口": 0xfdc38,
        "开启功能": 0x669a2c,
        "关闭功能": 0x94c684,
        "CodePatch": 0xbaa9ec,
        "StaticInlineHookPatch2": 0x46b80
    };
    
    for (var name in keyOffsets) {
        var addr = base.add(keyOffsets[name]);
        console.log("  " + name + ": " + addr + " (+" + keyOffsets[name].toString(16) + ")");
    }
    
    // 显示中文导出符号
    console.log("\n=== 中文导出符号 ===");
    var chineseSymbols = {
        "修补开关": 0xe7dbf0,
        "修补弹窗": 0xe7dbf1,
        "取消冻结": 0xe7dec0,
        "循环修改": 0x17132ff,
        "循环冻结": 0xe7deb0,
        "恢复": 0x161f0c0,
        "显示地址": 0xe7dbf2,
        "还原": 0xe7dec8,
        "锁定": 0x180753e,
        "锁定值": 0x18fb780
    };
    
    for (var name in chineseSymbols) {
        var addr = base.add(chineseSymbols[name]);
        try {
            var val = addr.readU8();
            console.log("  " + name + ": " + addr + " = " + val);
        } catch(e) {
            console.log("  " + name + ": " + addr + " (读取失败)");
        }
    }
    
    if (!ObjC.available) {
        console.log("[-] ObjC 不可用");
        return;
    }
    
    // Hook shenling 类的关键方法
    var shenling = ObjC.classes.shenling;
    if (shenling) {
        console.log("\n=== Hook shenling 类 ===");
        
        // Hook MyTitle: 方法来监控功能提示
        try {
            Interceptor.attach(shenling['+ MyTitle:'].implementation, {
                onEnter: function(args) {
                    var title = new ObjC.Object(args[2]);
                    console.log("\n🎯 [功能触发] " + title);
                    
                    // 分析是开启还是关闭
                    var titleStr = title.toString();
                    if (titleStr.indexOf("开启成功") !== -1) {
                        console.log("   状态: ✅ 开启");
                    } else if (titleStr.indexOf("关闭成功") !== -1) {
                        console.log("   状态: ❌ 关闭");
                    }
                }
            });
            console.log("[+] Hook MyTitle: 成功");
        } catch(e) {
            console.log("[-] Hook MyTitle: 失败: " + e);
        }
        
        // Hook tableView 方法来获取功能列表
        try {
            Interceptor.attach(shenling['+ tableView:cellForRowAtIndexPath:'].implementation, {
                onEnter: function(args) {
                    this.indexPath = new ObjC.Object(args[3]);
                },
                onLeave: function(retval) {
                    try {
                        var cell = new ObjC.Object(retval);
                        var textLabel = cell.textLabel();
                        if (textLabel) {
                            var text = textLabel.text();
                            if (text) {
                                console.log("📋 功能[" + this.indexPath.row() + "]: " + text);
                            }
                        }
                    } catch(e) {}
                }
            });
            console.log("[+] Hook tableView:cellForRowAtIndexPath: 成功");
        } catch(e) {
            console.log("[-] Hook失败: " + e);
        }
    }
    
    // Hook UISwitch 来监控开关操作
    var UISwitch = ObjC.classes.UISwitch;
    if (UISwitch) {
        try {
            Interceptor.attach(UISwitch['- sendActionsForControlEvents:'].implementation, {
                onEnter: function(args) {
                    var self = new ObjC.Object(args[0]);
                    var events = args[2].toInt32();
                    
                    if (events === 4096 && self.$className === "UISwitch") {
                        var isOn = self.isOn();
                        console.log("\n🔘 [开关操作] " + (isOn ? "开启" : "关闭"));
                        
                        // 打印调用栈中的ASWJGAMEPLUS部分
                        var bt = Thread.backtrace(this.context, Backtracer.ACCURATE);
                        console.log("   调用栈:");
                        for (var i = 0; i < Math.min(bt.length, 5); i++) {
                            var addr = bt[i];
                            var module = Process.findModuleByAddress(addr);
                            if (module && module.name === "ASWJGAMEPLUS.dylib") {
                                var offset = ptr(addr).sub(module.base);
                                console.log("     ASWJGAMEPLUS + 0x" + offset.toString(16));
                            }
                        }
                    }
                }
            });
            console.log("[+] Hook UISwitch 成功");
        } catch(e) {
            console.log("[-] Hook UISwitch 失败: " + e);
        }
    }
    
    // 显示API信息
    console.log("\n=== API 信息 ===");
    console.log("  服务器: yz.66as.cn");
    console.log("  接口: /GameApi/ASWJGAME.php?Bundelid=game.taptap.lantern.kbxx");
    
    console.log("\n=== 功能列表 ===");
    var functions = [
        "无限寿命",
        "冻结灵石", 
        "无敌免疫",
        "无限突破",
        "增加逃跑概率"
    ];
    
    functions.forEach(function(func, index) {
        console.log("  " + index + ": " + func);
    });
    
    console.log("\n=== 分析完成 ===");
    console.log("✅ ASWJGAMEPLUS.dylib 使用服务器配置 + 内存变量");
    console.log("✅ 比 GameForFun.dylib 复杂得多");
    console.log("✅ 需要进一步的汇编代码分析才能完全复制功能");
    console.log("\n🎮 请操作游戏功能开关来查看实时分析！");
    
}, 6000);