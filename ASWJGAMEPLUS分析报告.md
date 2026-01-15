# ASWJGAMEPLUS.dylib 深度分析报告

## 概述

ASWJGAMEPLUS.dylib 是一个复杂的 iOS 游戏修改插件，支持多款游戏。本报告详细分析了该插件的工作原理、架构设计和功能实现机制。

---

## 一、基本信息

### 目标游戏：卡包修仙
- **Bundle ID**: `game.taptap.lantern.kbxx`
- **游戏引擎**: 原生 iOS（非 Unity）
- **插件版本**: ASWJGAMEPLUS.dylib

### 功能列表
**主要功能**：
1. 无限寿命
2. 冻结灵石
3. 无敌免疫
4. 无限突破
5. 增加逃跑概率

**辅助功能**：
6. 存档工具
7. 游戏变速
8. 变速模式（4种模式）

---

## 二、架构分析

### 2.1 服务器配置
- **API 接口**: `yz.66as.cn/GameApi/ASWJGAME.php?Bundelid=game.taptap.lantern.kbxx`
- **配置方式**: 动态从服务器获取功能配置
- **验证机制**: 可能包含 UDID 验证（"未获取UDID"弹窗）

### 2.2 核心类结构
```
ASWJGAMEPLUS.dylib
├── shenling (主控制类)
│   ├── 菜单管理 (UITableView)
│   ├── 功能开关处理
│   └── 提示显示
├── HookClass (Hook 管理)
├── Gennager (功能生成器)
└── 其他辅助类 (42个ObjC类)
```

### 2.3 关键偏移量
| 功能 | 偏移量 | 说明 |
|------|--------|------|
| 开关处理入口 | `0xfdc38` | 通用开关处理函数 |
| 开启功能 | `0x669a2c` | 功能开启处理 |
| 关闭功能 | `0x94c684` | 功能关闭处理 |
| 代码修补 | `0xbaa9ec` | CodePatch 函数 |
| Hook修补 | `0x46b80` | StaticInlineHookPatch2 |

---

## 三、工作流程

### 3.1 初始化流程
```
1. 加载 ASWJGAMEPLUS.dylib
2. 从服务器获取游戏配置
3. 创建 shenling 菜单界面
4. 设置 UISwitch 开关回调
```

### 3.2 功能开关流程
```
用户点击开关
    ↓
UISwitch.switchDidChange:
    ↓
ASWJGAMEPLUS.dylib + 0xfdc38 (开关处理入口)
    ↓
开启: 0x669a2c  /  关闭: 0x94c684
    ↓
shenling.MyTitle: (显示提示)
```

### 3.3 中文导出符号
```
修补开关 @ 0xe7dbf0
修补弹窗 @ 0xe7dbf1
取消冻结 @ 0xe7dec0
循环修改 @ 0x17132ff
循环冻结 @ 0xe7deb0
恢复 @ 0x161f0c0
显示地址 @ 0xe7dbf2
还原 @ 0xe7dec8
锁定 @ 0x180753e
锁定值 @ 0x18fb780
```

---

## 四、技术特点

### 4.1 复杂性分析
- **配置管理**: 服务器动态配置，非本地存储
- **代码混淆**: 大量中文符号名和混淆函数名
- **多游戏支持**: 通过 Bundle ID 区分不同游戏
- **防护机制**: 可能包含反调试和 UDID 验证

### 4.2 与 GameForFun 对比
| 特性 | GameForFun | ASWJGAMEPLUS |
|------|------------|--------------|
| 配置存储 | NSUserDefaults | 服务器+内存变量 |
| 复杂度 | 简单 | 复杂 |
| 逆向难度 | 容易 | 困难 |
| 功能实现 | 键值对 | 内存修改/Hook |
| 多游戏支持 | 否 | 是 |

---

## 五、Frida Hook 脚本

### 5.1 基础信息获取
```javascript
// 获取模块信息和导出符号
var aswjModule = Process.findModuleByName("ASWJGAMEPLUS.dylib");
var exports = aswjModule.enumerateExports();
```

### 5.2 开关监控
```javascript
// Hook UISwitch 开关变化
var UISwitch = ObjC.classes.UISwitch;
Interceptor.attach(UISwitch['- switchDidChange:'].implementation, {
    onEnter: function(args) {
        var self = new ObjC.Object(args[0]);
        console.log("开关状态: " + self.isOn());
    }
});
```

### 5.3 功能提示监控
```javascript
// Hook 功能提示
var shenling = ObjC.classes.shenling;
Interceptor.attach(shenling['+ MyTitle:'].implementation, {
    onEnter: function(args) {
        var title = new ObjC.Object(args[2]);
        console.log("功能提示: " + title);
    }
});
```

---

## 六、关键发现

### 6.1 调用栈分析
```
功能开启时:
ASWJGAMEPLUS.dylib + 0x669a2c → 0xfdc38 → UISwitch

功能关闭时:
ASWJGAMEPLUS.dylib + 0x94c684 → 0xfdc38 → UISwitch
```

### 6.2 未调用的函数
- `CodePatch` (0xbaa9ec) - 未在开关操作中调用
- `StaticInlineHookPatch2` (0x46b80) - 未在开关操作中调用

这说明该游戏的功能可能使用其他实现方式（如直接内存修改或 IL2CPP API）。

---

## 七、逆向分析建议

### 7.1 进一步分析方向
1. **静态分析**: 使用 IDA Pro/Ghidra 分析 0x669a2c 和 0x94c684 处的汇编代码
2. **内存监控**: Hook mprotect 监控内存保护修改
3. **API 调用**: 监控可能的游戏 API 调用
4. **网络分析**: 抓包分析服务器通信协议

### 7.2 复制功能的可能方案
1. **直接调用**: 调用 ASWJGAMEPLUS 的内部函数
2. **逆向实现**: 分析汇编代码，重新实现功能逻辑
3. **内存搜索**: 找到游戏内存中的关键数值并修改
4. **API Hook**: Hook 游戏的关键 API 函数

---

## 八、总结

ASWJGAMEPLUS.dylib 是一个高度复杂的游戏修改插件，采用了服务器配置、代码混淆、多游戏支持等高级技术。相比 GameForFun.dylib 的简单键值对存储，ASWJGAMEPLUS 使用了更复杂的内存操作和 Hook 技术。

要完全复制其功能需要：
1. 深入的汇编代码分析
2. 游戏内存结构的理解
3. 可能的反混淆工作
4. 大量的测试和验证

这个分析为后续的深入逆向工作提供了重要的基础信息和方向指导。

---

## 附录：Hook 脚本文件

本次分析中使用的 Frida Hook 脚本：
- `hook_aswj.js` - `hook_aswj16.js` (共16个版本)
- 每个脚本针对不同的分析目标和发现进行了优化

**注意**: 本分析仅供学习研究使用，请勿用于非法用途。