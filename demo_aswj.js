// ASWJGAMEPLUS 功能演示脚本
// 展示如何使用各种复制方案

console.log("[*] ASWJGAMEPLUS 功能演示开始");

function demo() {
    console.log("\n=== 演示开始 ===");
    
    // 检查环境
    console.log("\n1. 环境检查");
    var aswjModule = Process.findModuleByName("ASWJGAMEPLUS.dylib");
    var gameFound = false;
    
    var modules = Process.enumerateModules();
    for (var i = 0; i < modules.length; i++) {
        if (modules[i].name.indexOf("game.taptap.lantern.kbxx") !== -1) {
            gameFound = true;
            break;
        }
    }
    
    console.log("ASWJGAMEPLUS.dylib: " + (aswjModule ? "✓ 已找到" : "✗ 未找到"));
    console.log("卡包修仙游戏: " + (gameFound ? "✓ 已找到" : "✗ 未找到"));
    console.log("ObjC 运行时: " + (ObjC.available ? "✓ 可用" : "✗ 不可用"));
    
    // 演示方案选择
    console.log("\n2. 方案选择建议");
    if (aswjModule) {
        console.log("✓ 推荐使用: ASWJClone_ultimate.js (终极复制器)");
        console.log("✓ 备选方案: ASWJClone_fixed.js (直接调用)");
    } else {
        console.log("- 推荐使用: KabaoMemoryHack.js (内存修改)");
        console.log("- 备选方案: 卡包修仙Dylib/KabaoCheat.m (独立插件)");
    }
    
    // 演示基本功能
    console.log("\n3. 功能演示");
    
    if (aswjModule) {
        console.log("演示直接调用方案:");
        demoDirectCall(aswjModule);
    }
    
    if (gameFound) {
        console.log("演示内存搜索:");
        demoMemorySearch();
    }
    
    if (ObjC.available) {
        console.log("演示 Hook 设置:");
        demoHookSetup();
    }
    
    console.log("\n=== 演示完成 ===");
    console.log("\n使用建议:");
    console.log("1. 先运行 test_aswj_replication.js 进行全面测试");
    console.log("2. 根据测试结果选择最适合的方案");
    console.log("3. 使用 ASWJClone_ultimate.js 获得最佳体验");
}

function demoDirectCall(aswjModule) {
    try {
        var base = aswjModule.base;
        var handlerFunc = base.add(0xfdc38);
        
        console.log("  基址: " + base);
        console.log("  处理函数: " + handlerFunc);
        
        // 尝试创建 NativeFunction
        var handler = new NativeFunction(handlerFunc, 'void', ['int', 'bool']);
        console.log("  ✓ NativeFunction 创建成功");
        
        // 模拟调用（不实际执行，避免影响游戏）
        console.log("  模拟调用: handler(0, true) - 开启无限寿命");
        console.log("  模拟调用: handler(0, false) - 关闭无限寿命");
        
    } catch(e) {
        console.log("  ✗ 直接调用演示失败: " + e);
    }
}

function demoMemorySearch() {
    try {
        console.log("  搜索常见数值...");
        
        var testValues = [100, 1000];
        var totalFound = 0;
        
        for (var i = 0; i < testValues.length; i++) {
            var value = testValues[i];
            var count = searchValueDemo(value);
            totalFound += count;
            console.log("  搜索 " + value + ": 找到 " + count + " 个地址");
        }
        
        if (totalFound > 0) {
            console.log("  ✓ 内存搜索可用，找到 " + totalFound + " 个潜在地址");
        } else {
            console.log("  - 内存搜索未找到匹配值");
        }
        
    } catch(e) {
        console.log("  ✗ 内存搜索演示失败: " + e);
    }
}

function searchValueDemo(value) {
    var count = 0;
    var ranges = Process.enumerateRanges('rw-');
    
    // 限制搜索范围，避免演示时间过长
    for (var i = 0; i < Math.min(ranges.length, 5); i++) {
        var range = ranges[i];
        try {
            var data = range.base.readByteArray(Math.min(range.size, 1024));
            var view = new DataView(data);
            
            for (var offset = 0; offset < data.byteLength - 4; offset += 4) {
                if (view.getInt32(offset, true) === value) {
                    count++;
                    if (count >= 5) break; // 限制结果数量
                }
            }
        } catch(e) {
            // 忽略错误
        }
        if (count >= 5) break;
    }
    
    return count;
}

function demoHookSetup() {
    try {
        var hookCount = 0;
        
        // 演示 UISwitch Hook
        if (ObjC.classes.UISwitch) {
            var UISwitch = ObjC.classes.UISwitch;
            var method = UISwitch['- setOn:animated:'];
            if (method) {
                console.log("  ✓ UISwitch Hook 可用");
                hookCount++;
            }
        }
        
        // 演示 shenling Hook
        if (ObjC.classes.shenling) {
            var shenling = ObjC.classes.shenling;
            console.log("  ✓ shenling 类可用");
            console.log("    方法数量: " + shenling.$ownMethods.length);
            
            var hasMyTitle = shenling.$ownMethods.indexOf('+ MyTitle:') !== -1;
            if (hasMyTitle) {
                console.log("  ✓ MyTitle 方法可用");
                hookCount++;
            }
        }
        
        console.log("  Hook 设置: " + hookCount + " 个可用");
        
    } catch(e) {
        console.log("  ✗ Hook 演示失败: " + e);
    }
}

// 延迟启动演示
setTimeout(demo, 2000);