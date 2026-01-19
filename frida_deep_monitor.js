// 深层监控脚本 - 监控所有可能的修改方式
console.log("🚀 深层监控脚本已加载");

setTimeout(function() {
    console.log("✅ 开始深层监控...");
    
    // 1. 监控所有数值相关的系统调用
    try {
        // 监控 write 系统调用
        var write = Module.findExportByName("libsystem_kernel.dylib", "write");
        if (write) {
            Interceptor.attach(write, {
                onEnter: function(args) {
                    var fd = args[0].toInt32();
                    var size = args[2].toInt32();
                    if (size > 4 && size < 1000) {
                        try {
                            var data = Memory.readUtf8String(args[1], Math.min(size, 100));
                            if (data && (data.includes("cash") || data.includes("money") || data.includes("现金") || 
                                        data.includes("2099999100") || data.includes("21000000000"))) {
                                console.log("📝 [系统调用] write: " + data);
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        console.log("✅ 系统调用监控已启动");
    } catch (e) {
        console.log("❌ 系统调用监控失败: " + e.message);
    }
    
    // 2. 监控所有内存修改操作
    try {
        // 监控 mprotect (修改内存保护)
        var mprotect = Module.findExportByName("libsystem_kernel.dylib", "mprotect");
        if (mprotect) {
            Interceptor.attach(mprotect, {
                onEnter: function(args) {
                    var addr = args[0];
                    var size = args[1].toInt32();
                    var prot = args[2].toInt32();
                    console.log("🛡️ [内存保护] mprotect: " + addr + " size: " + size + " prot: " + prot);
                }
            });
        }
        
        // 监控 vm_write (虚拟内存写入)
        var vm_write = Module.findExportByName("libsystem_kernel.dylib", "vm_write");
        if (vm_write) {
            Interceptor.attach(vm_write, {
                onEnter: function(args) {
                    var task = args[0];
                    var addr = args[1];
                    var size = args[3].toInt32();
                    if (size >= 4 && size <= 8) {
                        try {
                            var value = Memory.readU32(args[2]);
                            if (value > 1000000) {
                                console.log("🧠 [虚拟内存] vm_write: " + value + " 到地址: " + addr);
                            }
                        } catch (e) {}
                    }
                }
            });
        }
        
        console.log("✅ 内存修改监控已启动");
    } catch (e) {
        console.log("❌ 内存修改监控失败: " + e.message);
    }
    
    // 3. 监控所有可能的Hook框架
    try {
        // 监控 MSHookFunction (Substrate)
        var MSHookFunction = Module.findExportByName(null, "MSHookFunction");
        if (MSHookFunction) {
            Interceptor.attach(MSHookFunction, {
                onEnter: function(args) {
                    var symbol = args[0];
                    console.log("🪝 [Substrate] MSHookFunction: " + symbol);
                }
            });
        }
        
        // 监控 fishhook
        var rebind_symbols = Module.findExportByName(null, "rebind_symbols");
        if (rebind_symbols) {
            Interceptor.attach(rebind_symbols, {
                onEnter: function(args) {
                    console.log("🪝 [fishhook] rebind_symbols 被调用");
                }
            });
        }
        
        console.log("✅ Hook框架监控已启动");
    } catch (e) {
        console.log("❌ Hook框架监控失败: " + e.message);
    }
    
    // 4. 监控动态库加载
    try {
        var dlopen = Module.findExportByName("libdyld.dylib", "dlopen");
        if (dlopen) {
            Interceptor.attach(dlopen, {
                onEnter: function(args) {
                    var path = Memory.readUtf8String(args[0]);
                    if (path && (path.includes("dylib") || path.includes("framework"))) {
                        console.log("📚 [动态库] dlopen: " + path);
                    }
                }
            });
        }
        
        console.log("✅ 动态库监控已启动");
    } catch (e) {
        console.log("❌ 动态库监控失败: " + e.message);
    }
    
    // 5. 监控特定数值的内存搜索和修改
    try {
        // 创建内存扫描器，监控包含特定数值的内存区域
        var targetValue = 2099999100; // 你的当前现金数值
        
        Process.enumerateRanges('rw-', {
            onMatch: function(range) {
                try {
                    Memory.scan(range.base, range.size, targetValue.toString(16), {
                        onMatch: function(address, size) {
                            console.log("🎯 [内存扫描] 找到目标数值 " + targetValue + " 在地址: " + address);
                            
                            // 监控这个地址的写入
                            Memory.protect(address, 4, 'rw-');
                            Interceptor.attach(address, {
                                onEnter: function(args) {
                                    console.log("✏️ [内存写入] 地址 " + address + " 被修改");
                                }
                            });
                        },
                        onError: function(reason) {}
                    });
                } catch (e) {}
            },
            onComplete: function() {
                console.log("✅ 内存扫描完成");
            }
        });
        
        console.log("✅ 内存扫描监控已启动");
    } catch (e) {
        console.log("❌ 内存扫描监控失败: " + e.message);
    }
    
    // 6. 监控所有可能修改数值的函数
    try {
        // 搜索所有包含数值修改的函数
        var modules = Process.enumerateModules();
        var hookedCount = 0;
        
        modules.forEach(function(module) {
            if (module.name.includes("project1") || module.name.includes("Unity") || 
                module.name.includes("Game") || module.name.includes("libil2cpp")) {
                
                try {
                    var exports = module.enumerateExports();
                    exports.forEach(function(exp) {
                        if (exp.name && (exp.name.includes("set") || exp.name.includes("Set") || 
                                        exp.name.includes("modify") || exp.name.includes("Modify") ||
                                        exp.name.includes("update") || exp.name.includes("Update")) && 
                                        hookedCount < 10) {
                            
                            console.log("🎯 [发现函数] " + module.name + ": " + exp.name);
                            
                            try {
                                Interceptor.attach(exp.address, {
                                    onEnter: function(args) {
                                        console.log("🔧 [函数调用] " + exp.name + " 被调用");
                                        for (var i = 0; i < Math.min(args.length, 3); i++) {
                                            try {
                                                console.log("   参数[" + i + "]: " + args[i]);
                                            } catch (e) {}
                                        }
                                    }
                                });
                                hookedCount++;
                            } catch (e) {}
                        }
                    });
                } catch (e) {}
            }
        });
        
        console.log("✅ 函数监控已启动 (监控了 " + hookedCount + " 个函数)");
    } catch (e) {
        console.log("❌ 函数监控失败: " + e.message);
    }
    
    console.log("=".repeat(60));
    console.log("✅ 深层监控已全部启动！");
    console.log("💡 现在操作修改器，应该能捕获到更多信息...");
    console.log("=".repeat(60));
    
}, 3000);