# 我独自生活 Frida Hook 使用教程

## 🚀 准备工作

### 1. 安装Frida
```bash
# 在电脑上安装Frida
pip install frida-tools

# 在iOS设备上安装Frida (需要越狱)
# 通过Cydia安装Frida
```

### 2. 确认设备连接
```bash
# 查看连接的设备
frida-ls-devices

# 应该能看到你的iOS设备
```

## 📱 使用方法

### 1. 启动游戏
先正常启动"我独自生活"游戏

### 2. 运行Frida脚本
```bash
# 方法1：通过应用名称Hook
frida -U -f "com.Hezi.project1" -l frida_woduzishenghua.js

# 方法2：Hook正在运行的应用
frida -U "我独自生活" -l frida_woduzishenghua.js

# 方法3：通过进程ID Hook
frida -U -p <进程ID> -l frida_woduzishenghua.js
```

### 3. 查看Hook效果
脚本运行后会显示：
```
🚀 我独自生活 Frida Hook脚本已加载
[WDZ] 开始初始化Hook...
[WDZ] 开始Hook NSUserDefaults...
[WDZ] ✅ integerForKey Hook已安装
[WDZ] ✅ objectForKey Hook已安装
[WDZ] 🎉 所有Hook已安装完成！
```

### 4. 实时控制
在Frida控制台中可以使用以下命令：

```javascript
// 开启/关闭Hook
toggleHook()

// 设置具体数值
setCash(99999999)      // 设置现金
setEnergy(99999999)    // 设置体力  
setHealth(1000000)     // 设置健康
setMood(1000000)       // 设置心情
```

## 🎯 Hook原理

### 1. NSUserDefaults Hook
- 拦截 `integerForKey:` 方法
- 拦截 `objectForKey:` 方法
- 当游戏读取数值时，返回我们设定的值

### 2. Unity PlayerPrefs Hook
- 拦截Unity的PlayerPrefs.GetInt方法
- 适用于Unity引擎游戏

### 3. SQLite Hook
- 拦截sqlite3_column_int方法
- 修改数据库查询结果

### 4. 通用数值Hook
- 拦截NSNumber的intValue方法
- 覆盖所有可能的数值获取

## 📋 常见问题

### Q: 脚本加载失败
A: 确认：
- 设备已越狱并安装Frida
- 游戏正在运行
- 应用包名正确

### Q: Hook没有效果
A: 尝试：
- 重启游戏后再运行脚本
- 检查控制台是否有拦截日志
- 尝试不同的Hook方法

### Q: 数值修改后又被重置
A: 
- 游戏可能有服务器验证
- 尝试关闭网络连接
- 使用持续Hook模式

## 🔧 高级用法

### 1. 自定义Hook
```javascript
// 在Frida控制台中执行
Java.perform(function() {
    // 添加自定义Hook代码
});
```

### 2. 内存搜索
```javascript
// 搜索特定数值
Memory.scan(ptr("0x100000000"), 0x10000000, "01 02 03 04", {
    onMatch: function(address, size) {
        console.log("找到匹配: " + address);
    }
});
```

### 3. 函数追踪
```javascript
// 追踪特定函数调用
Interceptor.attach(Module.findExportByName("libsystem_c.dylib", "malloc"), {
    onEnter: function(args) {
        console.log("malloc called with size: " + args[0]);
    }
});
```

## 💡 提示

1. **实时生效**: Frida修改是实时的，不需要重启游戏
2. **动态调试**: 可以随时修改Hook逻辑
3. **多种Hook**: 脚本包含多种Hook方式，提高成功率
4. **安全性**: 只在本地修改，不影响服务器数据

## 🎮 使用流程

1. 启动游戏 → 2. 运行Frida脚本 → 3. 查看Hook日志 → 4. 游戏中数值立即生效

这种方法比dylib注入更灵活，可以实时调试和修改！