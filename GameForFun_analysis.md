# GameForFun.dylib 逆向分析报告

## 基本信息
- 文件大小: ~2.8MB
- 架构: ARM64 (64-bit Mach-O)
- 源码路径: `/Users/liangguanhan/Desktop/FanHanFunPlus/`

## Mach-O 段信息
| Segment | VMAddr | VMSize | FileOffset |
|---------|--------|--------|------------|
| __TEXT | 0x0 | 0x120000 | 0x0 |
| __DATA | 0x120000 | 0x1E4000 | 0x120000 |
| __LINKEDIT | 0x304000 | 0xAC000 | 0x204000 |

---

## 完整执行流程

```
游戏启动
    ↓
__mod_init_func 调用初始化函数
    ↓
_init_v @ 0x257BC
    ↓
showFloatWindow @ 0x24C30
    ↓
showFloatWindowContinueb @ 0x25218
    ↓
[检查本地 UDID] (FanhanKeychain)
    ↓
├─ 无 UDID ──────────────────────────────────────────────┐
│   ↓                                                    │
│   弹窗提示 "设备没有绑定UDID"                              │
│   ↓                                                    │
│   点击跳转 https://www.fanhangame.ltd/game/udid/        │
│   ↓                                                    │
│   下载安装描述文件                                        │
│   ↓                                                    │
│   描述文件回传 UDID 到本地 WebServer (127.0.0.1:5020)     │
│   ↓                                                    │
│   重启游戏                                              │
│                                                        │
└─ 有 UDID ─────────────────────────────────────────────┘
    ↓
[VIP 验证] POST https://www.fanhangame.ltd/game/udid/vip/main.php
          参数: Udid=%@
          返回: Fanhantime (过期时间)
    ↓
├─ VIP 有效 → block_invoke @ 0x331E8 → initFloatMenu @ 0x33450 → 显示菜单
│
├─ VIP 无效 → 弹窗 "未开通服务"
│
└─ 验证失败 → block_invoke_2 @ 0x3427C → 弹窗 "菜单加载失败"
```

## 关键函数地址

### 初始化链
| 地址 | 函数 | 说明 |
|------|------|------|
| 0x257BC | `_init_v` | dylib 加载时的初始化入口 |
| 0x24C30 | `showFloatWindow` | 显示浮窗的主函数 |
| 0x25218 | `showFloatWindowContinueb` | 继续显示浮窗（包含验证逻辑） |
| 0x331E8 | `block_invoke` | 验证成功回调 |
| 0x3427C | `block_invoke_2` | 验证失败回调（显示 UDID 弹窗） |
| 0x33450 | `initFloatMenu` | 初始化浮窗菜单 |
| 0x35824 | `initFloatButton` | 初始化浮窗按钮 |

### 浮窗组件
| 地址 | 类/方法 | 说明 |
|------|---------|------|
| 0x06EA8 | `FloatController init` | 浮窗控制器 |
| 0x07C88 | `FloatButton init` | 浮窗按钮 |
| 0x08A70 | `FloatButton touchesBegan:` | 按钮触摸开始 |
| 0x092B4 | `FloatButton tapMe` | 按钮点击 |
| 0x0CE38 | `FloatMenu initWithFrame:` | 浮窗菜单初始化 |

### FanhanAlertView 弹窗
| 地址 | 方法 | 说明 |
|------|------|------|
| 0x42DFC | `showNotice:title:...` | 显示通知弹窗 (感叹号图标) |
| 0x43810 | `showNotice:subTitle:...` | 显示通知弹窗 |
| 0x42FFC | `showInfo:title:...` | 显示信息弹窗 |
| 0x439C8 | `showInfo:subTitle:...` | 显示信息弹窗 |
| 0x42CFC | `showError:title:...` | 显示错误弹窗 |
| 0x42EFC | `showWarning:title:...` | 显示警告弹窗 |
| 0x448EC | `showView` | 显示弹窗视图 (被依赖，不能禁用) |

---

## 验证机制

### 验证 URL
```
POST https://www.fanhangame.ltd/game/SAO/FanhanGame.php
参数: User_Udid=%@&BundleID=%@
```

### 验证流程
1. `showFloatWindowContinueb` 发起网络请求
2. 请求成功 → `block_invoke` → `initFloatMenu` → 显示菜单
3. 请求失败 → `block_invoke_2` → 显示 "设备没有绑定UDID" 弹窗

---

## 已测试的补丁

### v1 - 禁用 showError/showWarning
**结果**: ❌ 弹窗仍出现（弹窗用的是 showNotice/showInfo）

### v2 - 禁用 showView/showTitle
**结果**: ❌ 闪退（这些方法被其他功能依赖）

### v3 - 禁用 showNotice/showInfo
**结果**: 待测试

### v4 - 禁用所有弹窗方法
**结果**: ✓ 不弹 UDID 窗口，但点击悬浮图标提示"菜单加载失败"
**原因**: 验证失败，initFloatMenu 没有被调用

### v5 - NOP TBNZ + 禁用弹窗
**结果**: 待测试

### v6 - showFloatWindowContinueb 直接返回
**结果**: 待测试（可能导致浮窗不显示）

### v7 - 跳转到 initFloatMenu
**结果**: ❌ 仍弹 UDID 窗口（跳转计算可能有误）

---

## 问题分析

### 为什么 v4 菜单加载失败？
v4 禁用了所有弹窗，但验证仍然失败，导致：
1. `block_invoke_2` 被调用（验证失败回调）
2. 弹窗被禁用所以不显示
3. 但 `initFloatMenu` 没有被调用
4. 点击悬浮按钮时，菜单未初始化，显示"加载失败"

### 解决方案
需要让验证成功回调 `block_invoke` 被调用，而不是失败回调 `block_invoke_2`

---

## 下一步补丁方案

### 方案 A: 让 block_invoke_2 调用 initFloatMenu
修改 `block_invoke_2 @ 0x3427C`，让它跳转到 `initFloatMenu @ 0x33450`

### 方案 B: 修改验证结果判断
找到判断验证结果的代码，强制走成功分支

### 方案 C: 直接调用 initFloatMenu
在 `showFloatWindowContinueb` 中直接调用 `initFloatMenu`，跳过验证

---

## ARM64 指令参考
| 指令 | 编码 | 字节 (小端) |
|------|------|-------------|
| RET | 0xD65F03C0 | C0 03 5F D6 |
| NOP | 0xD503201F | 1F 20 03 D5 |
| MOV W0, #1 | 0x52800020 | 20 00 80 52 |
| B offset | 0x14000000 + imm26 | 计算得出 |
