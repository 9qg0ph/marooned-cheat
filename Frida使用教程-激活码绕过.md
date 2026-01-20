# Frida Hook教程 - 绕过激活码获取IPA下载链接

## 📱 目标应用信息
- **应用名称**: 我独自生活
- **版本**: 2.0.9
- **大小**: 101.09M
- **分发平台**: wuaiwan signer (com.wuaiwan.signer)
- **价格**: ¥14.0
- **问题**: 需要激活码才能下载

## 🎯 目标
通过Frida Hook拦截激活验证过程，找到IPA的真实下载链接

## 📋 前置要求

### 1. 安装Frida
```bash
# 在电脑上安装Frida工具
pip install frida-tools

# 在越狱iPhone上安装Frida
# 打开Cydia，添加源: https://build.frida.re
# 搜索并安装 Frida
```

### 2. 确认设备连接
```bash
# 通过USB连接iPhone到电脑
# 查看已连接的设备
frida-ls-devices

# 应该看到类似输出：
# Id                                        Type    Name
# ----------------------------------------  ------  ------------
# local                                     local   Local System
# xxxxxxxx-xxxxxxxxxxxx                     usb     iPhone
```

### 3. 查看应用进程
```bash
# 列出iPhone上运行的所有应用
frida-ps -Ua

# 查找wuaiwan相关应用
frida-ps -Ua | grep -i wuaiwan
```

## 🚀 使用步骤

### 方法1：启动应用并附加Hook

```bash
# 启动应用并立即附加Hook脚本
frida -U -f com.wuaiwan.signer -l hook_activation_bypass.js --no-pause
```

### 方法2：附加到已运行的应用

```bash
# 先手动打开wuaiwan应用
# 然后附加Hook脚本
frida -U -n "wuaiwan" -l hook_activation_bypass.js

# 或者使用包名
frida -U com.wuaiwan.signer -l hook_activation_bypass.js
```

## 📝 操作流程

### 1. 启动Hook脚本
```bash
frida -U -f com.wuaiwan.signer -l hook_activation_bypass.js --no-pause
```

你会看到类似输出：
```
======================================================================
[*] 激活码绕过 & 下载链接拦截脚本
[*] 目标: 我独自生活 (版本 2.0.9, 大小 101.09M)
======================================================================

[+] 开始Hook激活码验证...
[+] Hook UIAlertController
[+] Hook UITextField
[+] Hook UIButton
...
[*] Hook设置完成!
======================================================================
```

### 2. 在应用中操作
1. 找到"我独自生活"应用
2. 点击"下载安装"按钮
3. 弹出激活码输入框
4. 输入任意激活码（例如：123456）
5. 点击"激活"按钮

### 3. 观察控制台输出

Hook脚本会拦截并显示：

#### 激活码输入
```
[!] UITextField输入: 123456
```

#### 激活验证请求
```
======================================================================
[!!!] 网络请求:
URL: https://api.wuaiwan.com/activate
Method: POST
Body: {"code":"123456","app_id":"woduzi"}
Headers:
  Content-Type: application/json
  Authorization: Bearer xxxxx
======================================================================
```

#### 服务器响应
```
======================================================================
[!!!] JSON响应:
{"success":true,"download_url":"https://cdn.wuaiwan.com/apps/woduzi_2.0.9.ipa"}
======================================================================
```

#### IPA下载链接
```
======================================================================
[!!!] 下载任务启动!
这可能是IPA下载链接:
URL: https://cdn.wuaiwan.com/apps/woduzi_2.0.9.ipa
======================================================================
```

#### itms-services协议
```
======================================================================
[!!!] UIApplication openURL:
URL: itms-services://?action=download-manifest&url=https%3A%2F%2Fapi.wuaiwan.com%2Fmanifest%2Fwoduzi.plist

[!!!] 发现itms-services协议!
这是iOS应用安装协议!

[!!!] Manifest URL:
https://api.wuaiwan.com/manifest/woduzi.plist

[*] 访问这个URL可以找到IPA真实下载地址!
======================================================================
```

## 🔍 获取IPA下载地址的方法

### 方法1：直接从Hook输出获取
如果Hook脚本拦截到了直接的IPA下载链接，直接复制使用：
```
https://cdn.wuaiwan.com/apps/woduzi_2.0.9.ipa
```

### 方法2：从Manifest文件获取
如果拦截到的是manifest URL：
```bash
# 下载manifest文件
curl "https://api.wuaiwan.com/manifest/woduzi.plist" -o manifest.plist

# 查看文件内容
cat manifest.plist
```

manifest.plist内容示例：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items</key>
    <array>
        <dict>
            <key>assets</key>
            <array>
                <dict>
                    <key>kind</key>
                    <string>software-package</string>
                    <key>url</key>
                    <string>https://cdn.wuaiwan.com/apps/woduzi_2.0.9.ipa</string>
                </dict>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

从中提取IPA URL：
```
https://cdn.wuaiwan.com/apps/woduzi_2.0.9.ipa
```

### 方法3：使用Python脚本解析
```python
import plistlib
import urllib.request

# 下载manifest文件
manifest_url = "https://api.wuaiwan.com/manifest/woduzi.plist"
response = urllib.request.urlopen(manifest_url)
plist_data = response.read()

# 解析plist
plist = plistlib.loads(plist_data)

# 提取IPA URL
ipa_url = plist['items'][0]['assets'][0]['url']
print(f"IPA下载地址: {ipa_url}")
```

## 📥 下载IPA文件

获取到IPA下载地址后：

```bash
# 使用curl下载
curl -L "https://cdn.wuaiwan.com/apps/woduzi_2.0.9.ipa" -o woduzi_2.0.9.ipa

# 或使用wget
wget "https://cdn.wuaiwan.com/apps/woduzi_2.0.9.ipa"

# 或使用aria2（支持断点续传）
aria2c "https://cdn.wuaiwan.com/apps/woduzi_2.0.9.ipa"
```

## 🛠️ 高级技巧

### 1. 保存Hook输出到文件
```bash
frida -U -f com.wuaiwan.signer -l hook_activation_bypass.js --no-pause > hook_output.log 2>&1
```

### 2. 实时过滤关键信息
```bash
frida -U -f com.wuaiwan.signer -l hook_activation_bypass.js --no-pause | grep -E "(URL|download|ipa|manifest)"
```

### 3. 修改Hook脚本绕过激活验证

在 `hook_activation_bypass.js` 中找到这段代码：
```javascript
// Hook boolForKey
Interceptor.attach(NSUserDefaults['- boolForKey:'].implementation, {
    onLeave: function(retval) {
        // 可以在这里强制返回true，绕过激活检查
        // retval.replace(1);  // 取消注释这行
    }
});
```

取消注释 `retval.replace(1);` 可以强制激活状态为true。

### 4. 修改JSON响应

在JSON解析Hook中：
```javascript
onLeave: function(retval) {
    // 修改JSON响应，绕过激活验证
    if (retval && !retval.isNull()) {
        var jsonObj = new ObjC.Object(retval);
        // 这里可以修改JSON对象
        // 例如：将 success: false 改为 success: true
    }
}
```

## ⚠️ 常见问题

### 1. 找不到应用进程
```bash
# 确认应用包名
frida-ps -Ua | grep -i wuaiwan

# 如果找不到，尝试：
frida-ps -Ua | grep -i "我独自生活"
```

### 2. Hook脚本无响应
- 确保应用已经打开到激活码界面
- 尝试重启应用和Hook脚本
- 检查Frida版本是否最新

### 3. 拦截不到下载链接
- 可能需要实际输入有效激活码
- 或者应用使用了加密通信
- 尝试使用其他Hook脚本（hook_wuaiwan_signer.js）

### 4. 下载链接失效
- 链接可能有时效性
- 可能需要特定的请求头（User-Agent、Authorization等）
- 尝试在Hook输出中查找完整的请求头信息

## 📚 相关文件

- `hook_activation_bypass.js` - 激活码绕过脚本（推荐）
- `hook_wuaiwan_signer.js` - wuaiwan应用专用Hook脚本
- `hook_app_download.js` - 通用下载链接拦截脚本

## 🎓 学习资源

- [Frida官方文档](https://frida.re/docs/home/)
- [Frida JavaScript API](https://frida.re/docs/javascript-api/)
- [iOS逆向工程](https://github.com/iosre/iOSAppReverseEngineering)

## ⚖️ 免责声明

本教程仅供技术研究和学习使用，请勿用于非法用途。使用本教程获取的应用安装包仅限个人学习使用，请支持正版应用。
