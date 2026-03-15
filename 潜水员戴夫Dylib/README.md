# 潜水员戴夫修改器 (Dave the Diver Cheat)

## 功能 (10个)
1. 冻结物品（不用请勿开启）
2. 冻结金币（不用请勿开启）
3. 无敌锁血
4. 无限氧气
5. 敌我免疫攻击
6. 潜水加速
7. 餐厅移动加速
8. 无限子弹
9. 无限金币（出售一次食材即可）
10. 物品堆叠不重置

## 原理
通过 IL2CPP API 在运行时查找游戏方法并修改其机器码：
- `IngredientsStorage.Decrease` → RET（物品不减少）
- `PlayerInfoSave.set_gold` → RET（金币不变）
- `PlayerBreathHandler.ExhaleUpdate` → RET（血量不减）
- `PlayerBreathHandler.set_HP` → RET（氧气不减）
- `Damager.CheckDamagerAttack` → RET（免疫攻击）
- `PlayerCharacter.DetermineMoveSpeed` → return 10.0（加速）
- `DaveMoveValue.get_speedMultiplier` → return 9.0（餐厅加速）
- `GunWeaponHandler.DecreaseBullet` → RET（子弹不减）
- `IngredientsData.get_Price` → return 99980001（高价出售）
- `InventoryItemSlotSave.set_TotalCount` → RET（堆叠不重置）

## 编译方法

### 方法1: GitHub Actions (推荐)
1. 推送到 GitHub
2. 进入 Actions → "Build Dave the Diver Cheat Dylib"
3. 下载 `DaveCheat.dylib`

### 方法2: Mac 本地编译
```bash
cd 潜水员戴夫Dylib

clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -miphoneos-version-min=14.0 \
  -dynamiclib \
  -framework UIKit \
  -framework Foundation \
  -fobjc-arc \
  -o DaveCheat.dylib \
  DaveCheat.m

ldid -S DaveCheat.dylib
```

## 安装方法
1. 将 `DaveCheat.dylib` 注入到潜水员戴夫 IPA 中
2. 使用 TrollStore 或其他工具安装
3. 打开游戏，3秒后出现蓝色悬浮按钮 "DV"
4. 点击悬浮按钮打开功能菜单
5. 开关对应功能即可

## 特点
- **无授权验证** — 不需要网络验证，直接使用
- **无反调试** — 没有任何防护/检测代码
- **轻量级** — 纯功能代码，无混淆无加密
- **可开关** — 每个功能独立开关，关闭时恢复原始代码

## 注意事项
- 仅供学习研究使用
- 需要与游戏版本匹配（IL2CPP方法名可能随版本变化）
- 如果某功能提示"方法未找到"，说明游戏版本不匹配
