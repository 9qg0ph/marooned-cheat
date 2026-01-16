# 天选打工人游戏修改方案

## 当前情况分析

1. **游戏类型**: 基于 V8 JavaScript 引擎的单机游戏
2. **包名**: com.panda.worker
3. **进程名**: 天选打工人
4. **引擎**: 可能是 Cocos Creator 或类似的 H5 游戏引擎
5. **数据目录**: `/var/mobile/Containers/Data/Application/EF44028A-27A5-4940-8BC1-0EBADED29AC0`

## 推荐方案

### 方案 1: 使用 iGameGuardian（最简单）⭐⭐⭐⭐⭐

**优点**: 
- 图形化界面，操作简单
- 专门为 iOS 游戏设计
- 支持内存搜索和修改
- 支持脚本自动化

**步骤**:
1. 在 Cydia/Sileo 安装 iGameGuardian
2. 打开游戏，记下当前金钱数值（如 15057）
3. 打开 iGameGuardian，搜索 15057
4. 在游戏中改变金钱（花费或获得）
5. 在 iGameGuardian 中精确搜索新数值
6. 重复直到结果很少，然后修改

**下载**: 
- Cydia 源: https://iosgods.com/repo/
- 或者搜索 "iGameGuardian deb" 手动安装

---

### 方案 2: 修改游戏存档文件 ⭐⭐⭐⭐

**原理**: 单机游戏通常将数据保存在本地文件中

**步骤**:
1. SSH 连接到手机
2. 进入游戏数据目录:
   ```bash
   cd /var/mobile/Containers/Data/Application/EF44028A-27A5-4940-8BC1-0EBADED29AC0
   ```
3. 查找存档文件:
   ```bash
   find . -name "*.json" -o -name "*.db" -o -name "*.sqlite" -o -name "*.plist"
   ```
4. 备份并编辑存档文件:
   ```bash
   cp Documents/save.json Documents/save.json.bak
   nano Documents/save.json
   ```
5. 修改金钱数值，保存后重启游戏

**工具**:
- SSH 客户端: Termius, PuTTY
- 文件管理器: Filza (iOS)

---

### 方案 3: 使用 GameGem ⭐⭐⭐⭐

**特点**: 另一个流行的 iOS 游戏修改器

**安装**:
```bash
# Cydia 源
https://cydia.iphonecake.com/
```

**使用方法**: 与 iGameGuardian 类似

---

### 方案 4: Frida 脚本注入（当前方案）⭐⭐⭐

**优点**: 
- 灵活，可以深度定制
- 不需要额外安装工具

**缺点**:
- 需要编程知识
- 对于 JavaScript 引擎的游戏，hook 比较困难

**当前问题**:
- 内存搜索结果为 0，可能是因为:
  1. 金钱数值不是以 int32 存储
  2. 可能是 float 或 double 类型
  3. 可能经过加密或编码

**改进方案**:
- 搜索 float/double 类型
- 搜索加密后的值
- Hook JavaScript 层面的函数

---

## 立即可用的解决方案

### 使用 Filza 查找和修改存档

1. **安装 Filza**:
   - Cydia 源: https://tigisoftware.com/cydia/
   
2. **打开 Filza**，导航到:
   ```
   /var/mobile/Containers/Data/Application/EF44028A-27A5-4940-8BC1-0EBADED29AC0/Documents
   ```

3. **查找存档文件**:
   - 查看 `.json`, `.db`, `.sqlite`, `.plist` 文件
   - 用文本编辑器打开查看内容
   - 搜索 "money", "coin", "gold", "15057" 等关键词

4. **修改数值**:
   - 备份原文件
   - 修改金钱数值
   - 保存并重启游戏

---

## 下一步建议

**最快的方法**: 
1. 安装 iGameGuardian 或 GameGem
2. 使用图形界面进行内存搜索和修改

**如果想继续用 Frida**:
1. 我可以创建一个搜索 float/double 的脚本
2. 或者尝试 hook Cocos Creator 的 API

你想尝试哪个方案？
