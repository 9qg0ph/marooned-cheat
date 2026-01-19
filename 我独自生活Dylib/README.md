# 我独自生活修改器

## 📦 最新版本

**WoduziCheat.m** - 稳定版（2026年1月20日更新）

## 🎯 功能特点

- ✅ 只修改数值，保留游戏进度
- ✅ 自动备份原存档，安全可靠
- ✅ 修改后自动重启游戏生效
- ✅ 支持plist格式存档修改，稳定不闪退
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

1. 下载编译好的 `WoduziCheat.dylib`
2. 使用注入工具注入到游戏
3. 启动游戏，看到 **独** 字悬浮按钮（会自动加载科技虎图标）
4. 点击按钮，选择要开启的功能
5. 确认后游戏会立即关闭
6. 手动重新打开游戏即可看到效果

## 🔧 编译方法

### GitHub Actions 自动编译
推送代码到 GitHub 后会自动编译，下载 Artifacts 中的 dylib 文件。

### 手动编译
```bash
clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -fobjc-arc \
  -o WoduziCheat.dylib \
  WoduziCheat.m

ldid -S WoduziCheat.dylib
```

## 💡 技术细节

### 存档结构
游戏使用 plist 格式存储存档：
- 路径：`Library/Preferences/com.Hezi.project1.plist`
- 格式：Property List (plist)

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
1. 读取 plist 格式的存档文件
2. 备份原存档到 `.backup` 文件
3. 修改所有相关数值字段
4. 保留所有其他游戏进度数据
5. 写回 plist 文件，自动重启游戏

### 关键技术突破
1. **plist格式支持** - 使用NSPropertyListSerialization处理
2. **多字段同步修改** - 确保所有相关字段一致性
3. **版权保护** - Base64编码+动态拼接防止二进制修改
4. **UI优化** - 参考天选打工人样式，添加免责声明

## 🛠️ 开发历程

### 基于天选打工人改进
1. **存档格式适配** - 从SQLite改为plist格式
2. **字段映射优化** - 支持游戏的多个同义字段
3. **稳定性提升** - plist格式更简单可靠

### 关键发现
- 游戏使用标准iOS plist格式存储数据
- 存在多个同义字段需要同时修改
- plist格式比SQLite更稳定，不存在锁定问题

## ⚠️ 注意事项

1. 修改前会自动备份原存档到 `.backup` 文件
2. 点击功能后游戏会立即关闭，这是正常现象
3. 手动重新打开游戏查看效果
4. 只修改数值，不会影响游戏进度
5. 日志文件位置：`Documents/woduzi_cheat.log`（可用Filza查看）

## 🔒 安全保护

- 版权信息 Base64 编码 + 动态拼接
- 图标URL Base64 编码 + 动态拼接  
- 防止二进制文件修改版权和图标

## 📄 免责声明

本工具仅供技术研究与学习，严禁用于商业用途及非法途径。使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。严禁倒卖、传播或用于牟利，否则后果自负。

## 📄 License

© 2026 𝐈𝐎𝐒𝐃𝐊 科技虎