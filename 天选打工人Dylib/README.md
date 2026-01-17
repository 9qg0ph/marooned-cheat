# 天选打工人修改器

## 📦 两个版本

### 1. TianXuanDaGongRenCheat.m（内存搜索版）
- **原理**：通过搜索爱心值100定位金钱和金条在内存中的位置
- **优点**：实时生效，不需要重启
- **缺点**：
  - 需要爱心满100才能定位
  - 只能修改金钱和金条
  - 每次启动游戏都需要重新修改
  - 可能找不到地址

### 2. TianXuanSaveModifier.m（存档修改版）⭐ 推荐
- **原理**：直接修改 `jsb.sqlite` 存档数据库
- **优点**：
  - ✅ 永久生效，修改一次即可
  - ✅ 可以修改所有数据（金钱、金条、体力、心情、积分）
  - ✅ 不需要特定条件（如爱心满100）
  - ✅ 更稳定可靠
- **缺点**：需要重启游戏才能生效

## 🎯 功能对比

| 功能 | 内存搜索版 | 存档修改版 |
|------|-----------|-----------|
| 💰 无限金钱 | ✅ | ✅ |
| 🏆 无限金条 | ✅ | ✅ |
| ⚡ 无限体力 | ❌ | ✅ |
| 😊 心情满值 | ❌ | ✅ |
| 🎯 无限积分 | ❌ | ✅ |
| 实时生效 | ✅ | ❌（需重启）|
| 永久生效 | ❌ | ✅ |
| 使用条件 | 需爱心满100 | 无条件 |

## 📝 使用方法

### 存档修改版（推荐）
1. 将 `TianXuanSaveModifier.m` 编译成 dylib
2. 注入到游戏
3. 点击悬浮按钮 💾
4. 选择要修改的项目
5. **重启游戏**即可生效

### 内存搜索版
1. 将 `TianXuanDaGongRenCheat.m` 编译成 dylib
2. 注入到游戏
3. **确保爱心已满100**
4. 点击悬浮按钮 💼
5. 选择要修改的项目
6. 立即生效

## 🔧 编译方法

### 存档修改版（需要链接 sqlite3）

```bash
clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -lsqlite3 \
  -fobjc-arc \
  -o TianXuanSaveModifier.dylib \
  TianXuanSaveModifier.m

ldid -S TianXuanSaveModifier.dylib
```

### 内存搜索版

```bash
clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -fobjc-arc \
  -o TianXuanDaGongRenCheat.dylib \
  TianXuanDaGongRenCheat.m

ldid -S TianXuanDaGongRenCheat.dylib
```

## ⚠️ 注意事项

1. **存档修改版**修改后必须重启游戏才能看到效果
2. **内存搜索版**需要爱心满100才能定位地址
3. 建议使用**存档修改版**，更稳定且功能更全
4. 修改前建议备份存档

## 📱 存档位置

```
/var/mobile/Containers/Data/Application/[APP_ID]/Documents/jsb.sqlite
```

## 💡 技术细节

### 存档数据结构
```json
{
  "info": {
    "money": 999999999,    // 金钱
    "mine": 999999999,     // 金条
    "power": 999999999,    // 体力
    "mood": 100,           // 心情
    "integral": 999999999  // 积分
  }
}
```

### 数据库表结构
- 表名：`data`
- 字段：`key` (TEXT), `value` (TEXT)
- 存档key：`ssx45sss`

### 内存搜索版偏移
- 金钱 = 爱心地址 - 0x18
- 金条 = 爱心地址 - 0x14

## 📄 License

© 2025 𝐈𝐎𝐒𝐃𝐊 科技虎
