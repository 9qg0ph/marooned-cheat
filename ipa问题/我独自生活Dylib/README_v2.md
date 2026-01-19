# 我独自生活修改器 v2.0

## 📦 最新版本

**WoduziCheat_v2.m** - NSUserDefaults直接修改版（2026年1月20日更新）
**WoduziCheat.m** - plist文件修改版（已废弃）

## 🎯 功能特点

- ✅ 直接修改NSUserDefaults，无需文件操作
- ✅ 实时生效，无需备份恢复
- ✅ 修改后自动重启游戏生效
- ✅ 支持真实存档结构，稳定不闪退
- ✅ 版权信息和图标URL加密保护
- ✅ 参考天选打工人成功实现，UI美观

## 🎮 支持功能

| 功能 | 说明 |
|------|------|
| 💰 无限金钱 | 所有金钱相关字段设置为 999999999 |
| ⚡ 无限体力 | 所有体力相关字段设置为 999999999 |
| ❤️ 无限健康 | 所有健康相关字段设置为 1000000 |
| 😊 无限心情 | 所有心情相关字段设置为 1000000 |
| 🎯 无限经验 | 经验和积分设置为 999999999 |
| 🎁 一键全开 | 金钱+体力+健康+心情+经验全满 |

## 📝 使用方法

1. 下载编译好的 `WoduziCheat_v2.dylib`
2. 使用注入工具注入到游戏
3. 启动游戏，看到 **独** 字悬浮按钮（会自动加载科技虎图标）
4. 点击按钮，选择要开启的功能
5. 确认后游戏会立即关闭
6. 手动重新打开游戏即可看到效果

## 🔧 编译方法

### 手动编译
```bash
clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -fobjc-arc \
  -o WoduziCheat_v2.dylib \
  WoduziCheat_v2.m

ldid -S WoduziCheat_v2.dylib
```

## 💡 技术细节

### 存档结构
游戏使用 NSUserDefaults 存储数据：
- 路径：`Library/Preferences/com.Hezi.project1.plist`
- 格式：NSUserDefaults (二进制plist)
- 访问：直接通过NSUserDefaults API

### 数据结构
游戏存档包含多个金钱、体力、健康相关字段：
```
金钱相关：userCash, 金钱, 玩家现金, 现金, 当前现金, Cash, Money, money
体力相关：Stamina, 玩家体力, gameEnergy, stamina, userEnergy
健康相关：当前健康, 健康, health, gameHealth, hp
心情相关：Happiness, gameMood, Mood
经验相关：experience, score, exp
```

### 修改原理
1. 直接使用NSUserDefaults API读取游戏数据
2. 修改所有相关数值字段
3. 调用synchronize保存到plist文件
4. 自动重启游戏使修改生效

### 关键技术突破
1. **NSUserDefaults直接修改** - 无需处理二进制plist文件
2. **多字段同步修改** - 确保所有相关字段一致性
3. **实时生效** - 无需备份恢复机制
4. **版权保护** - Base64编码+动态拼接防止二进制修改

## 🛠️ 开发历程

### v2.0 重大改进
1. **存档访问方式** - 从文件操作改为NSUserDefaults API
2. **稳定性提升** - 直接API调用，避免文件锁定问题
3. **代码简化** - 无需备份恢复逻辑

### 关键发现
- 游戏使用NSUserDefaults存储数据，对应二进制plist文件
- 直接使用NSUserDefaults API比文件操作更稳定
- 存在多个同义字段需要同时修改

## ⚠️ 注意事项

1. v2.0版本无需备份，直接修改NSUserDefaults
2. 点击功能后游戏会立即关闭，这是正常现象
3. 手动重新打开游戏查看效果
4. 只修改数值，不会影响游戏进度
5. 日志文件位置：`Documents/woduzi_cheat_v2.log`（可用Filza查看）

## 🔒 安全保护

- 版权信息 Base64 编码 + 动态拼接
- 图标URL Base64 编码 + 动态拼接  
- 防止二进制文件修改版权和图标

## 📄 免责声明

本工具仅供技术研究与学习，严禁用于商业用途及非法途径。使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。严禁倒卖、传播或用于牟利，否则后果自负。

## 📄 License

© 2026 𝐈𝐎𝐒𝐃𝐊 科技虎