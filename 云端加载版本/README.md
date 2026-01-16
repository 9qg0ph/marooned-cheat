# 卡包修仙云端加载版修改器

## 🌟 云端加载特性

### 优势
- **动态更新** - 无需重新编译dylib，功能可远程更新
- **灵活配置** - 通过JSON配置文件控制所有功能
- **实时推送** - 新功能可以实时推送给用户
- **A/B测试** - 可以为不同用户推送不同的功能配置
- **快速修复** - 发现问题可以立即通过云端配置修复

### 工作原理
1. **启动加载** - dylib启动时从云端服务器加载配置
2. **本地缓存** - 如果云端加载失败，使用本地默认配置
3. **手动刷新** - 用户可以手动刷新云端配置
4. **动态执行** - 根据云端配置动态生成功能按钮和执行逻辑

## 📋 功能列表

### 当前功能
- 💎 无限灵石（锁定数值，使用后不减少）
- ⚡ 无限灵气（锁定数值，使用后不减少）
- ❤️ 无限血量
- ⏰ 增加20年寿命
- 🌟 新功能测试（云端动态添加）

### 云端配置示例
```json
{
  "title": "💎 无限灵石",
  "successMessage": "💎 无限灵石锁定成功！",
  "autoRestart": true,
  "modifications": {
    "currency": 99999999,
    "lingzhi": 99999999,
    "currencyReduce": 0
  }
}
```

## 🚀 部署方式

### 1. 服务器部署
```bash
# 将kabao-features.json部署到你的服务器
# 例如：https://your-server.com/api/kabao-features.json
```

### 2. 修改URL
在CloudBasedCheat.m中修改配置URL：
```objective-c
NSURL *configURL = [NSURL URLWithString:@"https://your-server.com/api/kabao-features.json"];
```

### 3. 编译dylib
```bash
clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -fobjc-arc \
  -o CloudBasedCheat.dylib \
  CloudBasedCheat.m
```

## 🔧 配置说明

### 功能配置字段
- `title` - 按钮显示的标题
- `icon` - 图标（可选）
- `successMessage` - 成功提示信息
- `autoRestart` - 是否自动重启游戏
- `modifications` - 要修改的游戏数据

### 特殊操作
- `"ADD:20"` - 在当前值基础上增加20
- `"MUL:2"` - 将当前值乘以2
- `"SET:100"` - 直接设置为100

### 安全考虑
- 使用HTTPS确保配置传输安全
- 可以添加签名验证防止配置被篡改
- 限制配置文件大小防止恶意攻击

## 📱 用户体验

### 界面特性
- 显示云端加载状态
- 支持手动刷新配置
- 动态生成功能按钮
- 保持原有UI风格

### 错误处理
- 网络超时自动使用本地配置
- JSON解析失败回退到默认功能
- 显示加载状态和错误信息

## 🔄 更新流程

1. **修改配置** - 在服务器上更新kabao-features.json
2. **用户刷新** - 用户点击"刷新云端配置"按钮
3. **立即生效** - 新配置立即在菜单中生效
4. **无需重装** - 用户无需重新安装dylib

## 🎯 应用场景

- **游戏更新适配** - 游戏更新后快速调整参数
- **功能测试** - 新功能先小范围测试
- **紧急修复** - 发现问题立即推送修复
- **个性化配置** - 不同用户群体不同功能
- **活动功能** - 临时活动功能动态开启

这种云端加载方式让修改器具有了极大的灵活性和可维护性！