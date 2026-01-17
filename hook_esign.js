// Frida Hook ESign
console.log("[*] Hook ESign start...");

if (ObjC.available) {
    console.log("[*] ObjC Runtime available");
    
    // Hook file operations
    try {
        var NSFileManager = ObjC.classes.NSFileManager;
        if (NSFileManager) {
            Interceptor.attach(NSFileManager['- copyItemAtPath:toPath:error:'].implementation, {
                onEnter: function(args) {
                    var fromPath = ObjC.Object(args[2]).toString();
                    var toPath = ObjC.Object(args[3]).toString();
                    if (fromPath.indexOf('.ipa') !== -1 || toPath.indexOf('.ipa') !== -1) {
                        console.log("\n[File Copy] IPA operation:");
                        console.log("  From: " + fromPath);
                        console.log("  To: " + toPath);
                    }
                }
            });
            console.log("[+] Hooked NSFileManager copyItemAtPath");
        }
    } catch(e) {
        console.log("[-] NSFileManager hook failed: " + e);
    }
    
    // Hook codesign tools
    try {
        var NSTask = ObjC.classes.NSTask;
        if (NSTask) {
            Interceptor.attach(NSTask['- setLaunchPath:'].implementation, {
                onEnter: function(args) {
                    var launchPath = ObjC.Object(args[2]).toString();
                    if (launchPath.indexOf('codesign') !== -1 || launchPath.indexOf('ldid') !== -1) {
                        console.log("\n[Sign Tool] Launch:");
                        console.log("  Path: " + launchPath);
                        this.isSignTool = true;
                    }
                }
            });
            
            Interceptor.attach(NSTask['- setArguments:'].implementation, {
                onEnter: function(args) {
                    if (this.isSignTool) {
                        var arguments = ObjC.Object(args[2]);
                        console.log("  Args: " + arguments.toString());
                    }
                }
            });
            console.log("[+] Hooked NSTask sign tools");
        }
    } catch(e) {
        console.log("[-] NSTask hook failed: " + e);
    }
}

// Hook system calls
try {
    var execve = Module.findExportByName(null, 'execve');
    if (execve) {
        Interceptor.attach(execve, {
            onEnter: function(args) {
                var path = args[0].readUtf8String();
                if (path && (path.indexOf('codesign') !== -1 || path.indexOf('ldid') !== -1)) {
                    console.log("\n[execve] Command:");
                    console.log("  Path: " + path);
                }
            }
        });
        console.log("[+] Hooked execve");
    }
} catch(e) {
    console.log("[-] execve hook failed: " + e);
}

console.log("\n[*] Hook complete! Start signing in ESign...\n");