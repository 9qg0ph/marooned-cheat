# GameForFun.dylib 脚本抓取教程

## 概述

GameForFun.dylib 是一个 iOS 游戏修改插件，功能脚本从云端加载。本教程介绍如何使用 Frida 抓取云端脚本，并转换为 h5gg 格式。

---

## 一、准备工作

### 环境要求
- Windows 电脑 + Python + Frida
- 越狱 iOS 设备 + frida-server
- 目标游戏已安装 GameForFun.dylib 插件
- 有效的 VIP 账号（能正常显示功能菜单）

### 连接设备
```bash
# 检查设备连接
python -m frida_tools.ps -U
```

---

## 二、抓取脚本

### 步骤 1：创建 Hook 脚本

创建 `hook_setvalue.js`：

```javascript
// Hook setValue 方法 - 抓取功能脚本参数
console.log("[*] 等待...");

setTimeout(function() {
    if (ObjC.available) {
        var FanhanGGEngine = ObjC.classes.FanhanGGEngine;
        if (FanhanGGEngine) {
            // Hook setValue:forKey:withType:
            Interceptor.attach(FanhanGGEngine['- setValue:forKey:withType:'].implementation, {
                onEnter: function(args) {
                    var value = ObjC.Object(args[2]);
                    var key = ObjC.Object(args[3]);
                    var type = ObjC.Object(args[4]);
                    console.log("\n[setValue]");
                    console.log("  value: " + value);
                    console.log("  key: " + key);
                    console.log("  type: " + type);
                }
            });

            // Hook set:two:three:four:value:
            Interceptor.attach(FanhanGGEngine['- set:two:three:four:value:'].implementation, {
                onEnter: function(args) {
                    console.log("\n[set]");
                    console.log("  1: " + ObjC.Object(args[2]));
                    console.log("  2: " + ObjC.Object(args[3]));
                    console.log("  3: " + ObjC.Object(args[4]));
                    console.log("  4: " + ObjC.Object(args[5]));
                    console.log("  value: " + ObjC.Object(args[6]));
                }
            });

            // Hook cesfunc
            Interceptor.attach(FanhanGGEngine['- cesfunc:two:three:four:five:six:value:'].implementation, {
                onEnter: function(args) {
                    console.log("\n[cesfunc]");
                    console.log("  1: " + ObjC.Object(args[2]));
                    console.log("  2: " + ObjC.Object(args[3]));
                    console.log("  3: " + ObjC.Object(args[4]));
                    console.log("  4: " + ObjC.Object(args[5]));
                    console.log("  5: " + ObjC.Object(args[6]));
                    console.log("  6: " + ObjC.Object(args[7]));
                    console.log("  value: " + ObjC.Object(args[8]));
                }
            });

            // Hook setField
            Interceptor.attach(FanhanGGEngine['- setField:two:three:four:five:'].implementation, {
                onEnter: function(args) {
                    console.log("\n[setField]");
                    console.log("  1: " + ObjC.Object(args[2]));
                    console.log("  2: " + ObjC.Object(args[3]));
                    console.log("  3: " + ObjC.Object(args[4]));
                    console.log("  4: " + ObjC.Object(args[5]));
                    console.log("  5: " + ObjC.Object(args[6]));
                }
            });

            console.log("[+] Hook 成功，请开启功能");
        }
    }
}, 8000);
```

### 步骤 2：启动 Frida 并注入

```bash
python -m frida_tools.repl -U -f <包名> -l hook_setvalue.js
```

例如：
```bash
python -m frida_tools.repl -U -f com.fastfly.marooned -l hook_setvalue.js
```

### 步骤 3：操作游戏抓取数据

1. 等待 8 秒让 Hook 生效
2. 点击悬浮图标打开功能菜单
3. **逐个开启功能**
4. 观察控制台输出，记录每个功能的参数

### 步骤 4：记录抓取结果

示例输出：
```
[setValue]
  value: 99999
  key: marooned_gold_luobo_num
  type: Number

[setValue]
  value: 1
  key: fanhan_AVP
  type: bool
```

---

## 三、转换为 h5gg 脚本

### GameForFun 方法对应 h5gg 方法

| GameForFun 方法 | h5gg 方法 |
|----------------|-----------|
| `setValue:forKey:withType:` | `h5gg.setValue(key, value, type)` |
| `searchNumber:param2:param3:param4:` | `h5gg.searchNumber(value, type, start, end)` |
| `searchNearby:param2:param3:` | `h5gg.searchNearby(value, type, range)` |
| `editAll:param3:` | `h5gg.editAll(value, type, offset)` |
| `getResults:param1:` | `h5gg.getResults(count)` |
| `getResultsCount` | `h5gg.getResultsCount()` |
| `clearResults` | `h5gg.clearResults()` |

### h5gg 脚本模板

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>游戏名称</title>
    <style>
        /* 样式参考 无尽噩梦.html */
    </style>
</head>
<body>
    <div class="popup_container">
        <div id="H5AlertView">
            <div id="content-view">
                <div id="title-text">游戏名称</div>
                <div id="info-text">🎮 资源仅供学习使用</div>
                <div class="disclaimer">免责声明...</div>
                <div class="tip-text">使用提示</div>
                
                <!-- 功能按钮 -->
                <a href="javascript:void(0);" onclick="func1()" class="button-style">功能1</a>
                <a href="javascript:void(0);" onclick="func2()" class="button-style">功能2</a>
                
                <div class="list-group-item123">©&nbsp;2025</div>
            </div>
        </div>
    </div>

    <script>
        function func1() {    
            // 根据抓取的参数填写
            h5gg.setValue("key_name", value, "type");
            alert("功能1开启成功！");
        }     
        
        function func2() {
            h5gg.setValue("key_name", value, "type");
            alert("功能2开启成功！");
        }    
    </script>
</body>
</html>
```

---

## 四、实战案例：饥饿荒野

### 抓取结果

| 功能 | Key | Value | Type |
|------|-----|-------|------|
| 无限金萝卜 | `marooned_gold_luobo_num` | `99999` | `Number` |
| 广告跳过 | `fanhan_AVP` | `1` | `bool` |

### h5gg 脚本实现

```javascript
// 无限金萝卜
function anniu1() {    
    h5gg.setValue("marooned_gold_luobo_num", 99999, "Number");
    alert("🥕 无限金萝卜开启成功！");
}     

// 广告跳过
function anniu2() {
    h5gg.setValue("fanhan_AVP", 1, "bool");
    alert("📺 广告跳过开启成功！");
}
```

---

## 五、常见问题

### Q1: Hook 后悬浮窗不显示
- 可能是 Hook 干扰了验证流程
- 尝试增加 setTimeout 延迟时间

### Q2: 游戏闪退
- 减少 Hook 的方法数量
- 只 Hook 必要的方法

### Q3: 抓不到数据
- 确认 VIP 有效，功能菜单正常显示
- 检查 Hook 时机，可能需要调整延迟

### Q4: 功能不生效
- 检查 key 名称是否正确
- 检查 value 类型是否匹配
- 某些功能可能需要重启游戏生效

---

## 六、FanhanGGEngine 完整方法列表

```
- setValue:forKey:withType:     // 设置键值
- searchNumber:param2:param3:param4:  // 搜索数值
- searchNearby:param2:param3:   // 附近搜索
- editAll:param3:               // 批量修改
- getResults:param1:            // 获取结果
- getResultsCount               // 获取结果数量
- clearResults                  // 清除结果
- set:two:three:four:value:     // 设置值
- setField:two:three:four:five: // 设置字段
- cesfunc:two:three:four:five:six:value:  // CES 函数
- Pickaddrss:addrss:with:type:  // 地址操作
- cesOffsetHook:two:main:       // Offset Hook
- handleBase64Data:toName:location:isWrite:  // 处理 Base64 数据
```

---

## 七、注意事项

1. **仅供学习研究**，请勿用于商业用途
2. 抓取的脚本可能随游戏更新失效
3. 不同游戏的 key 名称不同，需要单独抓取
4. 某些复杂功能可能使用内存搜索而非键值存储
