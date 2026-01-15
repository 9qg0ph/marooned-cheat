// Hook FanhanGGEngine 抓取脚本
console.log("[*] Hook FanhanGGEngine");

if (ObjC.available) {
    var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
    
    // Hook handleBase64Data - 处理云端数据
    Interceptor.attach(FanhanGGEngine['- handleBase64Data:toName:location:isWrite:'].implementation, {
        onEnter: function(args) {
            var data = ObjC.Object(args[2]);
            var name = ObjC.Object(args[3]);
            var location = ObjC.Object(args[4]);
            console.log("\n[handleBase64Data]");
            console.log("  name: " + name);
            console.log("  location: " + location);
            console.log("  data: " + data.toString().substring(0, 500));
        }
    });

    // Hook cesOffsetHook - Offset Hook
    Interceptor.attach(FanhanGGEngine['- cesOffsetHook:two:main:'].implementation, {
        onEnter: function(args) {
            var one = ObjC.Object(args[2]);
            var two = ObjC.Object(args[3]);
            var main = ObjC.Object(args[4]);
            console.log("\n[cesOffsetHook]");
            console.log("  one: " + one);
            console.log("  two: " + two);
            console.log("  main: " + main);
        }
    });

    // Hook fanhances - 修改功能
    Interceptor.attach(FanhanGGEngine['- fanhances:two:three:four:obj:'].implementation, {
        onEnter: function(args) {
            var one = ObjC.Object(args[2]);
            var two = ObjC.Object(args[3]);
            var three = ObjC.Object(args[4]);
            var four = ObjC.Object(args[5]);
            var obj = ObjC.Object(args[6]);
            console.log("\n[fanhances]");
            console.log("  one: " + one);
            console.log("  two: " + two);
            console.log("  three: " + three);
            console.log("  four: " + four);
            console.log("  obj: " + obj);
        }
    });

    // Hook Write - 写入数据
    Interceptor.attach(FanhanGGEngine['- Write:ToName:type:isWrite:'].implementation, {
        onEnter: function(args) {
            var data = ObjC.Object(args[2]);
            var name = ObjC.Object(args[3]);
            var type = ObjC.Object(args[4]);
            console.log("\n[Write]");
            console.log("  data: " + data);
            console.log("  name: " + name);
            console.log("  type: " + type);
        }
    });

    // Hook fanhan - 主函数
    Interceptor.attach(FanhanGGEngine['- fanhan:'].implementation, {
        onEnter: function(args) {
            var param = ObjC.Object(args[2]);
            console.log("\n[fanhan] " + param);
        }
    });

    // Hook loadPlugin - 加载插件
    Interceptor.attach(FanhanGGEngine['- loadPlugin:path:'].implementation, {
        onEnter: function(args) {
            var plugin = ObjC.Object(args[2]);
            var path = ObjC.Object(args[3]);
            console.log("\n[loadPlugin]");
            console.log("  plugin: " + plugin);
            console.log("  path: " + path);
        }
    });

    // Hook Pickaddr - 地址操作
    Interceptor.attach(FanhanGGEngine['- Pickaddr:'].implementation, {
        onEnter: function(args) {
            var addr = ObjC.Object(args[2]);
            console.log("\n[Pickaddr] " + addr);
        }
    });

    // Hook Pickaddrss - 地址操作
    Interceptor.attach(FanhanGGEngine['- Pickaddrss:addrss:with:type:'].implementation, {
        onEnter: function(args) {
            var one = ObjC.Object(args[2]);
            var addr = ObjC.Object(args[3]);
            var with_ = ObjC.Object(args[4]);
            var type = ObjC.Object(args[5]);
            console.log("\n[Pickaddrss]");
            console.log("  one: " + one);
            console.log("  addr: " + addr);
            console.log("  with: " + with_);
            console.log("  type: " + type);
        }
    });

    console.log("[+] Hook 成功，请点击悬浮图标并开启功能");
}
