// Hook修改器工具 - 学习作者的修改技术
console.log("[+] 修改器Hook脚本启动...");
console.log("[+] 目标: 学习作者修改器的工作原理");

setTimeout(function() {
    console.log("[+] 开始Hook修改器功能...");
    
    // Hook修改器的关键操作
    hookCheatOperations();
    
    // Hook内存写入操作
    hookMemoryWrites();
    
    // Hook UI开关操作
    hookSwitchOperations();
    
    // Hook消费刷新机制
    hookRefreshMechanism();
    
}, 3000);

function hookCheatOperations() {
    console.log("\n=== Hook修改器操作 ===");
    
    try {
        // Hook所有可能的修改器相关类
        for (var className in ObjC.classes) {
            if (className.toLowerCase().includes("cheat") ||
                className.toLowerCase().includes("hack") ||
                className.toLowerCase().includes("mod") ||
                className.toLowerCase().includes("tool") ||
                className.toLowerCase().includes("helper") ||
                className.includes("GameForFun")) {
                
                console.log("[修改器] 找到可能的修改器类: " + className);
                
                try {
                    var clazz = ObjC.classes[className];
                    var methods = clazz.$ownMethods;
                    
                    methods.forEach(function(methodName) {
                        // Hook所有方法来观察修改器行为
                        try {
                            var method = clazz[methodName];
                            Interceptor.attach(method.implementation, {
                                onEnter: function(args) {
                                    console.log("[🔧] 修改器方法调用: " + className + "." + methodName);
                                    
                                    // 记录参数
                                    for (var i = 2; i < args.length && i < 6; i++) {
                                        try {
                                            var arg = args[i];
                                            if (!arg.isNull()) {
                                                var value = arg.toInt32();
                                                if (value === 2100000000 || value === 100000) {
                                                    console.log("[🎯] 发现目标数值参数: " + value);
                                                }
                                            }
                                        } catch (e) {
                                            // 参数不是数值，忽略
                                        }
                                    }
                                },
                                onLeave: function(retval) {
                                    // 记录返回值
                                }
                            });
                        } catch (e) {
                            // Hook失败，忽略
                        }
                    });
                    
                } catch (e) {
                    console.log("[-] 无法分析类: " + className);
                }
            }
        }
        
    } catch (e) {
        console.log("[-] Hook修改器操作失败: " + e);
    }
}

function hookMemoryWrites() {
    console.log("\n=== Hook内存写入操作 ===");
    
    try {
        // Hook memcpy - 最常用的内存复制函数
        var memcpy = Module.findExportByName(null, "memcpy");
        if (memcpy) {
            Interceptor.attach(memcpy, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    
                    if (size === 4) { // int32大小
                        try {
                            var value = Memory.readS32(args[1]);
                            
                            // 检查是否是我们关心的数值
                            if (value === 2100000000) {
                                console.log("[💰] memcpy写入金钱/体力: " + value + " -> " + args[0]);
                                console.log("[地址] 目标地址: " + args[0]);
                                
                                // 记录调用栈
                                console.log("[调用栈] " + Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress).join('\n'));
                                
                            } else if (value === 100000) {
                                console.log("[❤️] memcpy写入健康/心情: " + value + " -> " + args[0]);
                                console.log("[地址] 目标地址: " + args[0]);
                                
                                // 记录调用栈
                                console.log("[调用栈] " + Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress).join('\n'));
                            }
                        } catch (e) {
                            // 读取失败，忽略
                        }
                    }
                }
            });
            console.log("[+] memcpy Hook成功");
        }
        
        // Hook memmove
        var memmove = Module.findExportByName(null, "memmove");
        if (memmove) {
            Interceptor.attach(memmove, {
                onEnter: function(args) {
                    var size = args[2].toInt32();
                    
                    if (size === 4) {
                        try {
                            var value = Memory.readS32(args[1]);
                            
                            if (value === 2100000000 || value === 100000) {
                                console.log("[📝] memmove写入数值: " + value + " -> " + args[0]);
                            }
                        } catch (e) {
                            // 忽略
                        }
                    }
                }
            });
            console.log("[+] memmove Hook成功");
        }
        
    } catch (e) {
        console.log("[-] 内存写入Hook失败: " + e);
    }
}

function hookSwitchOperations() {
    console.log("\n=== Hook开关操作 ===");
    
    try {
        // Hook UISwitch相关操作
        var UISwitch = ObjC.classes.UISwitch;
        if (UISwitch) {
            // Hook setOn:animated:
            var setOnAnimated = UISwitch['- setOn:animated:'];
            if (setOnAnimated) {
                Interceptor.attach(setOnAnimated.implementation, {
                    onEnter: function(args) {
                        var isOn = args[2].toInt32();
                        var animated = args[3].toInt32();
                        
                        console.log("[🎛️] 开关状态改变: " + (isOn ? "开启" : "关闭") + " (动画: " + (animated ? "是" : "否") + ")");
                        
                        // 记录调用栈，看是哪个功能的开关
                        var backtrace = Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress);
                        console.log("[开关调用栈] " + backtrace.slice(0, 5).join('\n'));
                    }
                });
            }
            
            // Hook addTarget:action:forControlEvents:
            var addTarget = UISwitch['- addTarget:action:forControlEvents:'];
            if (addTarget) {
                Interceptor.attach(addTarget.implementation, {
                    onEnter: function(args) {
                        var target = new ObjC.Object(args[2]);
                        var action = args[3];
                        
                        console.log("[🎯] 开关绑定事件: target=" + target + " action=" + action);
                    }
                });
            }
        }
        
        // Hook UIControl的sendActionsForControlEvents
        var UIControl = ObjC.classes.UIControl;
        if (UIControl) {
            var sendActions = UIControl['- sendActionsForControlEvents:'];
            if (sendActions) {
                Interceptor.attach(sendActions.implementation, {
                    onEnter: function(args) {
                        var events = args[2].toInt32();
                        console.log("[🎮] 控件事件触发: " + events);
                        
                        // 记录是哪个控件触发的
                        var control = new ObjC.Object(args[0]);
                        console.log("[控件] " + control);
                    }
                });
            }
        }
        
    } catch (e) {
        console.log("[-] 开关操作Hook失败: " + e);
    }
}

function hookRefreshMechanism() {
    console.log("\n=== Hook消费刷新机制 ===");
    
    try {
        // Hook可能的刷新相关方法
        for (var className in ObjC.classes) {
            if (className.toLowerCase().includes("refresh") ||
                className.toLowerCase().includes("update") ||
                className.toLowerCase().includes("reload")) {
                
                console.log("[刷新] 找到刷新相关类: " + className);
                
                try {
                    var clazz = ObjC.classes[className];
                    var methods = clazz.$ownMethods;
                    
                    methods.forEach(function(methodName) {
                        if (methodName.toLowerCase().includes("refresh") ||
                            methodName.toLowerCase().includes("update") ||
                            methodName.toLowerCase().includes("reload")) {
                            
                            try {
                                var method = clazz[methodName];
                                Interceptor.attach(method.implementation, {
                                    onEnter: function(args) {
                                        console.log("[🔄] 刷新方法调用: " + className + "." + methodName);
                                    }
                                });
                            } catch (e) {
                                // Hook失败，忽略
                            }
                        }
                    });
                    
                } catch (e) {
                    // 类处理失败，忽略
                }
            }
        }
        
        // Hook NSTimer - 可能用于定时刷新
        var NSTimer = ObjC.classes.NSTimer;
        if (NSTimer) {
            var scheduledTimer = NSTimer['+ scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:'];
            if (scheduledTimer) {
                Interceptor.attach(scheduledTimer.implementation, {
                    onEnter: function(args) {
                        var interval = args[2]; // double类型需要特殊处理
                        var target = new ObjC.Object(args[3]);
                        var selector = args[4];
                        
                        console.log("[⏰] 定时器创建: target=" + target + " selector=" + selector);
                    }
                });
            }
        }
        
    } catch (e) {
        console.log("[-] 刷新机制Hook失败: " + e);
    }
}

// 监听特定的修改器操作
setTimeout(function() {
    console.log("\n=== 开始监听修改器操作 ===");
    console.log("请在修改器中点击开关，观察Hook输出...");
    
    // 监听NSUserDefaults的写入，看修改器如何修改游戏数据
    try {
        var NSUserDefaults = ObjC.classes.NSUserDefaults;
        
        var setIntegerForKey = NSUserDefaults['- setInteger:forKey:'];
        if (setIntegerForKey) {
            Interceptor.attach(setIntegerForKey.implementation, {
                onEnter: function(args) {
                    var value = args[2].toInt32();
                    var key = new ObjC.Object(args[3]).toString();
                    
                    if (value === 2100000000 || value === 100000) {
                        console.log("[💾] 修改器写入存档: " + key + " = " + value);
                        
                        // 记录调用栈，看是修改器的哪个部分在写入
                        var backtrace = Thread.backtrace(this.context, Backtracer.ACCURATE).map(DebugSymbol.fromAddress);
                        console.log("[存档调用栈] " + backtrace.slice(0, 3).join('\n'));
                    }
                }
            });
        }
        
    } catch (e) {
        console.log("[-] NSUserDefaults监听失败: " + e);
    }
    
}, 5000);

console.log("[+] 修改器Hook脚本加载完成");
console.log("[+] 现在请操作修改器的开关，我会记录所有相关操作...");