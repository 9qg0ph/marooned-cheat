// 查找应用包名脚本
console.log("🔍 查找已安装的应用包名...");

// 获取所有已安装的应用
var apps = [];
try {
    // 尝试枚举所有应用
    var LSApplicationWorkspace = ObjC.classes.LSApplicationWorkspace;
    if (LSApplicationWorkspace) {
        var workspace = LSApplicationWorkspace.defaultWorkspace();
        var allApps = workspace.allInstalledApplications();
        
        console.log("📱 找到 " + allApps.count() + " 个已安装应用");
        
        for (var i = 0; i < allApps.count(); i++) {
            var app = allApps.objectAtIndex_(i);
            var bundleId = app.bundleIdentifier().toString();
            var displayName = app.localizedName() ? app.localizedName().toString() : "未知";
            
            // 查找包含"独自"、"生活"、"我独自生活"等关键词的应用
            if (displayName.includes("独自") || displayName.includes("生活") || 
                bundleId.toLowerCase().includes("life") || bundleId.toLowerCase().includes("alone") ||
                bundleId.toLowerCase().includes("living") || bundleId.toLowerCase().includes("survival")) {
                
                console.log("🎯 [匹配] " + displayName + " -> " + bundleId);
                apps.push({
                    name: displayName,
                    bundleId: bundleId
                });
            }
        }
    }
} catch (e) {
    console.log("❌ 无法枚举应用: " + e.message);
}

// 如果没找到，显示所有应用让用户选择
if (apps.length === 0) {
    console.log("🔍 未找到匹配的应用，显示所有应用供参考:");
    
    try {
        var LSApplicationWorkspace = ObjC.classes.LSApplicationWorkspace;
        if (LSApplicationWorkspace) {
            var workspace = LSApplicationWorkspace.defaultWorkspace();
            var allApps = workspace.allInstalledApplications();
            
            for (var i = 0; i < Math.min(allApps.count(), 50); i++) {
                var app = allApps.objectAtIndex_(i);
                var bundleId = app.bundleIdentifier().toString();
                var displayName = app.localizedName() ? app.localizedName().toString() : "未知";
                
                console.log((i + 1) + ". " + displayName + " -> " + bundleId);
            }
        }
    } catch (e) {
        console.log("❌ 无法枚举应用: " + e.message);
    }
} else {
    console.log("\n✅ 找到可能的目标应用:");
    apps.forEach(function(app, index) {
        console.log((index + 1) + ". " + app.name + " -> " + app.bundleId);
    });
}

console.log("\n💡 使用方法:");
console.log("frida -U -l script.js <包名>");
console.log("例如: frida -U -l frida_realtime_capture.js com.example.game");