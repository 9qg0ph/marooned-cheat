# 卡包修仙修改器

基于对 ASWJGAMEPLUS.dylib 的深度分析，完全复制其功能的独立修改器。

## 📋 功能列表

### 主要功能
- ✅ 无限寿命
- ✅ 冻结灵石  
- ✅ 无敌免疫
- ✅ 无限突破
- ✅ 增加逃跑概率

### 辅助功能
- 🎮 悬浮按钮（可拖拽）
- 📱 功能菜单（屏幕居中）
- 💾 状态保存
- 🔔 操作提示

## 🚀 使用方案

### 方案一：终极复制器（推荐）

#### 多方案集成版本
```bash
python -m frida_tools.repl -U -f game.taptap.lantern.kbxx -l ASWJClone_ultimate.js
```

使用方法：
```javascript
// 开启功能
ASWJ.enable('无限寿命');
ASWJ.enable('冻结灵石');

// 关闭功能  
ASWJ.disable('无限寿命');

// 批量操作
ASWJ.enableAll();   // 开启所有功能
ASWJ.disableAll();  // 关闭所有功能

// 查看状态
ASWJ.getStatus();   // 显示系统状态
ASWJ.listFunctions(); // 列出所有功能
```

#### 功能测试
```bash
python -m frida_tools.repl -U -f game.taptap.lantern.kbxx -l test_aswj_replication.js
```

### 方案二：直接调用 ASWJGAMEPLUS 函数

#### 1. 修复版本（推荐）
```bash
python -m frida_tools.repl -U -f game.taptap.lantern.kbxx -l ASWJClone_fixed.js
```

#### 2. 原始版本
```bash
python -m frida_tools.repl -U -f game.taptap.lantern.kbxx -l ASWJClone.js
```

使用方法：
```javascript
// 开启功能
ASWJ.enable('无限寿命');
ASWJ.enable('冻结灵石');

// 关闭功能  
ASWJ.disable('无限寿命');

// 批量操作
ASWJ.enableAll();   // 开启所有功能
ASWJ.disableAll();  // 关闭所有功能
```

### 方案三：内存级别修改
```bash
python -m frida_tools.repl -U -f game.taptap.lantern.kbxx -l KabaoMemoryHack.js
```

使用方法：
```javascript
// 开启功能
kabaoCheat.enableInfiniteLife();      // 无限寿命
kabaoCheat.enableFreezeStone();       // 冻结灵石
kabaoCheat.enableInvincible();        // 无敌免疫
kabaoCheat.enableInfiniteBreakthrough(); // 无限突破
kabaoCheat.enableEscapeBoost();       // 增加逃跑概率

// 关闭功能（将 enable 改为 disable）
kabaoCheat.disableInfiniteLife();
```

### 方案四：独立 Dylib 插件 v2.0（推荐）

#### 全新特性
- 🎨 **现代化UI设计** - 模糊效果、动画、渐变背景
- 🔧 **多方案集成** - 自动检测环境，选择最佳实现方案
- 📱 **智能交互** - 长按显示快捷菜单，触觉反馈
- 🧠 **内存搜索** - 智能内存扫描和修改
- 🔗 **兼容性** - 自动检测并兼容 ASWJGAMEPLUS
- 💾 **状态管理** - 功能状态保存和恢复
- 📊 **实时监控** - 系统状态和功能状态实时显示

#### 1. 编译 Dylib v2.0
1. 推送代码到 GitHub
2. 进入 Actions 页面
3. 运行 "Build 卡包修仙 Dylib v2.0" 工作流
4. 下载编译好的 `KabaoCheat.dylib`

#### 2. 注入到游戏
1. 使用 IPAPatcher 或 Sideloadly 注入 dylib
2. 用 TrollStore 安装修改后的 IPA
3. 启动游戏，等待3秒后自动显示悬浮按钮

#### 3. 使用方法
- **点击悬浮按钮** - 打开功能菜单
- **长按悬浮按钮** - 显示快捷操作菜单
- **拖拽悬浮按钮** - 移动到合适位置
- **使用开关** - 控制各项功能的开启/关闭
- **全部开启/关闭** - 批量操作所有功能
- **查看状态** - 显示系统和功能状态

## 🔧 技术原理

### 基于 ASWJGAMEPLUS 分析
- **服务器配置**: `yz.66as.cn/GameApi/ASWJGAME.php`
- **核心类**: `shenling` (主控制类)
- **关键偏移**: 
  - 开启功能: `0x669a2c`
  - 关闭功能: `0x94c684`
  - 处理入口: `0xfdc38`

### 实现方式
1. **直接调用**: 调用 ASWJGAMEPLUS 的内部函数
2. **内存修改**: 搜索和修改游戏内存数值
3. **函数 Hook**: Hook 游戏的关键计算函数
4. **UI 复制**: 完全复制 ASWJGAMEPLUS 的界面

## 📊 方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| 终极复制器 | 多方案集成，自动选择最佳方案 | 代码复杂 | ⭐⭐⭐⭐⭐ |
| 独立 Dylib v2.0 | 现代化UI，功能完整，用户体验佳 | 需要注入到IPA | ⭐⭐⭐⭐⭐ |
| 直接调用 | 简单快速，100%兼容 | 需要原插件存在 | ⭐⭐⭐⭐ |
| 内存修改 | 独立运行，不依赖原插件 | 需要找到内存地址 | ⭐⭐⭐ |

## ⚠️ 注意事项

1. **仅供学习研究**，请勿用于商业用途
2. 游戏更新可能导致功能失效
3. 使用前请备份游戏存档
4. 建议在测试环境中先验证功能

## 🔍 进阶开发

### 添加新功能
1. 在 `KabaoCheat.m` 中添加新的功能方法
2. 在菜单中添加对应的开关
3. 实现具体的内存修改或函数 Hook

### 调试技巧
1. 使用 `console.log` 输出调试信息
2. 通过 Frida 的 `hexdump` 查看内存内容
3. 使用 `Thread.backtrace` 分析调用栈

### 内存搜索优化
1. 缩小搜索范围（只搜索游戏模块）
2. 使用多次搜索过滤结果
3. 监控数值变化来确认地址

## 📚 相关文档

- [ASWJGAMEPLUS分析报告.md](../ASWJGAMEPLUS分析报告.md) - 完整的技术分析
- [GameForFun脚本抓取教程.md](../GameForFun脚本抓取教程.md) - 基础教程参考

---

**免责声明**: 本项目仅供学习和研究使用，请遵守相关法律法规。