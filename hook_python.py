import frida
import sys

def on_message(message, data):
    if message['type'] == 'send':
        print("[*] {}".format(message['payload']))
    else:
        print(message)

js_code = """
if (ObjC.available) {
    var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
    if (FanhanGGEngine) {
        send("[+] 找到 FanhanGGEngine");
        
        // Hook setone:two:three:four:five:name:
        Interceptor.attach(FanhanGGEngine['- setone:two:three:four:five:name:'].implementation, {
            onEnter: function(args) {
                var params = [];
                for (var i = 2; i <= 7; i++) {
                    try {
                        var obj = new ObjC.Object(args[i]);
                        params.push(obj.toString());
                    } catch(e) {
                        params.push(args[i].toString());
                    }
                }
                send("\\n[setone] " + params.join(" | "));
            }
        });
        
        // Hook setValue:forKey:withType:
        Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
            onEnter: function(args) {
                try {
                    var value = new ObjC.Object(args[2]);
                    var key = new ObjC.Object(args[3]);
                    var type = new ObjC.Object(args[4]);
                    send("\\n[setValue] key=" + key + " value=" + value + " type=" + type);
                } catch(e) {}
            }
        });
        
        send("[+] Hook 完成，请开启功能");
    } else {
        send("[-] 未找到 FanhanGGEngine");
    }
} else {
    send("[-] ObjC 不可用");
}
"""

try:
    device = frida.get_usb_device()
    print("[*] 连接到设备: {}".format(device))
    
    # 附加到进程
    pid = 88893
    print("[*] 附加到进程: {}".format(pid))
    session = device.attach(pid)
    
    print("[*] 创建脚本...")
    script = session.create_script(js_code)
    script.on('message', on_message)
    
    print("[*] 加载脚本...")
    script.load()
    
    print("[*] Hook 已激活，等待数据...")
    print("[*] 按 Ctrl+C 退出\n")
    sys.stdin.read()
    
except KeyboardInterrupt:
    print("\n[*] 退出")
except Exception as e:
    print("[!] 错误: {}".format(e))
