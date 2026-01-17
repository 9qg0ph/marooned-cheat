# 天选打工人修改器

## 📦 最新版本

**TianXuanCheat.m** - 稳定版（参考卡包修仙成功实现）

## 🎯 功能特点

- ✅ 只修改数值，保留游戏进度
- ✅ 自动备份原存档
- ✅ 修改后自动重启游戏
- ✅ 稳定可靠，不会闪退

## 🎮 支持功能

| 功能 | 说明 |
|------|------|
| 💰 无限金钱 | 金钱设置为 999999999 |
| 🏆 无限金条 | 金条设置为 999999999 |
| ⚡ 无限体力 | 体力设置为 999999999 |
| 😊 心情满值 | 心情设置为 100 |
| 🎯 无限积分 | 积分设置为 999999999 |
| 🎁 一键全开 | 所有数值一键修改 |

## 📝 使用方法

1. 下载编译好的 `TianXuanCheat.dylib`
2. 使用注入工具注入到游戏
3. 启动游戏，看到 💼 悬浮按钮
4. 点击按钮，选择要开启的功能
5. 游戏会自动重启，重新打开即可看到效果

## 🔧 编译方法

```bash
clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -lsqlite3 \
  -fobjc-arc \
  -o TianXuanCheat.dylib \
  TianXuanCheat.m

ldid -S TianXuanCheat.dylib
```

## 💡 技术细节

### 存档结构
游戏使用 SQLite 数据库存储存档：
- 路径：`Documents/jsb.sqlite`
- 表名：`data`
- 键名：`ssx45sss`
- 格式：JSON

### 数据结构
```json
{
  "info": {
    "money": 999999999,    // 金钱
    "mine": 999999999,     // 金条
    "power": 999999999,    // 体力
    "mood": 100,           // 心情
    "integral": 999999999  // 积分
  },
  "cards": [...],          // 卡牌数据（保留）
  "calendar": {...},       // 日历数据（保留）
  ...                      // 其他游戏进度（保留）
}
```

### 修改原理
1. 读取 SQLite 数据库中的存档 JSON
2. 解析 JSON，只修改 `info` 字段中的数值
3. 保留所有其他游戏进度数据
4. 写回数据库
5. 自动重启游戏使修改生效

## ⚠️ 注意事项

1. 修改前会自动备份原存档到 `jsb.sqlite.backup`
2. 修改后游戏会自动退出，重新打开即可
3. 只修改数值，不会影响游戏进度
4. 建议在游戏主界面使用

## 📄 License

© 2025 𝐈𝐎𝐒𝐃𝐊 科技虎
