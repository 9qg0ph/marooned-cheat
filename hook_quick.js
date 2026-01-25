if (ObjC.available) {
    var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
    if (FanhanGGEngine) {
        // 只 hook setone 方法
        Interceptor.attach(FanhanGGEngine['- setone:two:three:four:five:name:'].implementation, {
            onEnter: function(args) {
                var one = new ObjC.Object(args[2]);
                var two = new ObjC.Object(args[3]);
                var three = new ObjC.Object(args[4]);
                var four = new ObjC.Object(args[5]);
                var five = new ObjC.Object(args[6]);
                var name = new ObjC.Object(args[7]);
                
                console.log("\n[setone]");
                console.log("  one: " + one);
                console.log("  two: " + two);
                console.log("  three: " + three);
                console.log("  four: " + four);
                console.log("  five: " + five);
                console.log("  name: " + name);
            }
        });
        console.log("[+] Hook OK");
    }
}
