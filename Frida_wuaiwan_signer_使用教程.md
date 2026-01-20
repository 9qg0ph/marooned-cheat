# Frida Hook wuaiwan signer 使用教程

## 目标应用
- **包名**: `com.wuaiwan.signer`
- **功能**: 绕过激活码验证，直接获取IPA下载链接

## 准备工作

### 1. 安装Frida
```bash
# 安装Frida
pip install frida-tools

# 或者使用npm
npm install -g frida-tools
```

### 2. 设备准备
- 已越狱的iOS设备 或 已Root的Android设备
- 设备上安装Frida Server
- 确保设备与电脑在同一网络

### 3. 安装目标应用
确保设备上已安装 `com.wuaiwan.signer` 应用

## 使用方法

### 方法1: 使用高级Hook脚本
```bash
# 连接设备并运行高级脚本
frida -U -f com.wuaiwan.signer -l hook_wuaiwan_signer_advanced.js --no-pause

# 或者如果应用已经在运行
frida -U com.wuaiwan.signer -l hook_wuaiwan_signer_advanced.js
```

### 方法2: 使用简化绕过脚本
```bash
# 运行简化绕过脚本
frida -U -f com.wuaiwan.signer -l hook_wuaiwan_bypass_simple.js --no-pause
```

## 脚本功能说明

### hook_wuaiwan_signer_advanced.js (高级版)
- ✅ 全面Hook网络请求 (OkHttp, HttpURLConnection)
- ✅ Hook WebView和JavaScript执行
- ✅ 拦截激活码验证逻辑
- ✅ 监控下载管理器
- ✅ Hook JavaScript接口
- ✅ 伪造SharedPreferences存储状态
- ✅ 自动扫描应用特定类和方法

### hook_wuaiwan_bypass_simple.js (简化版)
- ✅ 强制所有验证方法返回成功
- ✅ 拦截激活网络请求并伪造成功响应
- ✅ 绕过WebView中的appInstall.postMessage调用
- ✅ 伪造本地激活状态存储

## 操作步骤

### 1. 启动Hook
```bash
# 选择一个脚本运行
frida -U com.wuaiwan.signer -l hook_wuaiwan_bypass_simple.js
```

### 2. 操作应用
1. 打开wuaiwan signer应用
2. 浏览到IPA下载页面
3. 点击下载按钮
4. **不要输入激活码** - 脚本会自动绕过验证

### 3. 观察输出
Frida控制台会显示：
```
[+] 启动wuaiwan signer激活码绕过脚本...
[+] Java环境就绪，开始Hook...
[🎯] 拦截验证方法: verifyActivationCode
[✅] 强制返回验证成功
[🎯] 拦截激活验证请求
[✅] 伪造成功响应
```

### 4. 获取下载链接
- 高级脚本会自动拦截并显示IPA下载链接
- 简化脚本会绕过验证，让应用正常进入下载流程

## 预期效果

### 成功绕过后
1. 不再弹出激活码输入框
2. 直接进入下载界面
3. 可以正常下载IPA文件
4. Frida控制台显示拦截的下载链接

### 如果失败
1. 检查应用包名是否正确
2. 尝试重启应用后再Hook
3. 查看Frida输出的错误信息
4. 尝试使用另一个脚本版本

## 高级用法

### 实时监控
```bash
# 持续监控应用行为
frida -U com.wuaiwan.signer -l hook_wuaiwan_signer_advanced.js --runtime=v8
```

### 保存日志
```bash
# 将输出保存到文件
frida -U com.wuaiwan.signer -l hook_wuaiwan_bypass_simple.js > frida_log.txt
```

### 自定义Hook
可以修改脚本中的关键词列表来适应不同版本的应用：
```javascript
var verificationMethods = [
    "verify", "check", "validate", "authenticate", 
    "isActivated", "isVerified", "isLicensed", "isPremium"
    // 添加更多可能的方法名
];
```

## 故障排除

### 常见问题
1. **连接失败**: 检查Frida Server是否正在运行
2. **Hook失败**: 应用可能使用了反调试保护
3. **方法找不到**: 应用版本可能不同，需要调整Hook目标

### 调试技巧
```bash
# 列出设备上的应用
frida-ps -U

# 检查应用是否在运行
frida-ps -U | grep wuaiwan

# 查看应用详细信息
frida -U com.wuaiwan.signer -e "console.log(Java.enumerateLoadedClasses())"
```

## 注意事项
- 仅供学习研究使用
- 请遵守相关法律法规
- 不要用于商业用途
- 建议在测试环境中使用

## 成功案例
当看到以下输出时，说明绕过成功：
```
[🎯] 拦截激活相关JavaScript
[✅] 绕过appInstall调用，直接触发下载
[🎉] 找到IPA下载链接: https://xxx.com/xxx.ipa
```