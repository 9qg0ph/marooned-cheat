# 我独自生活修改器

## 📦 最新版本

**WoduziCheat.m** - 稳定版（2026年1月18日创建）

## 🎯 功能特点

- ✅ 基于NSUserDefaults修改，安全可靠
- ✅ 首次使用强制免责声明确认
- ✅ 修改后自动重启游戏生效
- ✅ 版权信息和图标URL加密保护
- ✅ 参考天选打工人和卡包修仙成功实现

## 🎮 支持功能

| 功能 | 说明 |
|------|------|
| 💰 无限金币 | 金币设置为 999999999 |
| 💎 无限钻石 | 钻石设置为 999999999 |
| ⚡ 无限体力 | 体力设置为 999999999 |
| 🎁 一键全开 | 金币+钻石+体力+等级+积分全满 |

## 📝 使用方法

1. 下载编译好的 `WoduziCheat.dylib`
2. 使用注入工具注入到游戏
3. 启动游戏，看到 **虎** 字悬浮按钮（会自动加载科技虎图标）
4. 首次点击会弹出免责声明，必须点击"同意"才能继续
5. 选择要开启的功能
6. 确认后游戏会立即关闭
7. 手动重新打开游戏即可看到效果

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
游戏使用 NSUserDefaults (plist文件) 存储存档：
- 路径：`Library/Preferences/com.Hezi.project1.plist`
- 格式：二进制plist
- 修改方式：NSUserDefaults API

### 修改字段
程序会尝试修改以下可能的字段名：

**金币相关**：
- `money`, `coin`, `coins`, `gold`, `currency`, `cash`
- `金币`, `金钱`, `货币`

**钻石相关**：
- `diamond`, `diamonds`, `gem`, `gems`, `crystal`, `premium`
- `钻石`, `宝石`, `水晶`

**体力相关**：
- `energy`, `stamina`, `power`, `hp`, `health`
- `体力`, `能量`, `血量`

**其他**：
- `exp`, `experience`, `level`, `score`, `point`, `points`
- `等级`, `积分`

### 修改原理
1. 使用NSUserDefaults读取游戏存档
2. 批量设置可能的字段名为目标数值
3. 调用synchronize()保存到plist文件
4. 自动重启游戏使修改生效

## 🛠️ 开发特色

### 智能字段匹配
- 支持中英文字段名
- 覆盖常见的游戏数值字段
- 批量修改确保成功率

### 安全保护
- 首次使用强制免责声明
- 版权信息加密保护
- 图标URL加密保护

## ⚠️ 注意事项

1. 首次使用必须同意免责声明，不同意会直接退出
2. 点击功能后游戏会立即关闭，这是正常现象
3. 手动重新打开游戏查看效果
4. 基于NSUserDefaults修改，相对安全
5. 日志文件位置：`Documents/woduzishenghua_cheat.log`（可用Filza查看）

## 🔒 安全保护

- 版权信息 Base64 编码 + 动态拼接
- 图标URL Base64 编码 + 动态拼接  
- 防止二进制文件修改版权和图标

## 📄 免责声明

本工具仅供技术研究与学习，严禁用于商业用途及非法途径。使用本工具修改游戏可能违反游戏服务条款，用户需自行承担一切风险和责任。严禁倒卖、传播或用于牟利，否则后果自负。

## 📄 License

© 2026 𝐈𝐎𝐒𝐃𝐊 科技虎