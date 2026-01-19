# 🎯 Frida修改器捕获系统使用说明

## 📋 准备工作

1. **确保手机已连接**并且Frida服务正在运行
2. **在手机上打开"我独自生活"游戏**
3. **确保其他修改器也已安装**在手机上

## 🚀 使用步骤

### 第一步：查找应用包名

运行以下任一脚本来查找应用包名：

```bash
# 方法1：查找正在运行的应用（推荐）
find_running_apps.bat

# 方法2：查找所有已安装应用
run_frida_capture.bat
```

### 第二步：启动捕获系统

找到包名后，使用以下命令启动捕获：

```bash
# 使用便捷脚本
run_frida_with_bundle.bat <应用包名>

# 或者手动运行
C:\Users\Administrator\AppData\Roaming\Python\Python38\Scripts\frida.exe -U -l frida_realtime_capture.js <应用包名>
```

### 第三步：操作其他修改器

1. **在手机上打开其他修改器**
2. **开启/关闭修改器功能**（如无限金钱、无限体力等）
3. **观察Frida控制台的实时输出**

## 📊 脚本功能说明

### 🎯 核心捕获脚本

- **`frida_realtime_capture.js`** - 实时捕获脚本（推荐使用）
  - 简单易用，专注于实时捕获
  - 自动生成修改器代码
  - 提供清晰的状态报告

- **`frida_complete_cheat_stealer.js`** - 完整窃取系统
  - 全面的Hook和监控
  - 深度分析和学习
  - 智能代码生成

- **`frida_steal_cheat_functions.js`** - 功能窃取脚本
  - 专门窃取修改器类和方法
  - 分析调用栈和执行流程

### 🛠️ 辅助工具

- **`find_running_apps.bat`** - 查找正在运行的应用
- **`run_frida_with_bundle.bat`** - 便捷启动脚本
- **`find_app_bundle.js`** - 查找应用包名的Frida脚本

## 💡 使用示例

```bash
# 1. 查找应用
find_running_apps.bat

# 2. 假设找到包名为 com.example.lifegame
run_frida_with_bundle.bat com.example.lifegame

# 3. 在手机上操作其他修改器
# 4. 观察控制台输出，系统会自动生成代码
```

## 🎉 预期结果

当你在手机上操作其他修改器时，系统会：

1. **实时显示**所有NSUserDefaults操作
2. **捕获重要数值**修改（如金钱、体力等）
3. **分析ES3存档**操作
4. **自动生成**Frida和Objective-C版本的修改器代码
5. **提供详细报告**和操作统计

## ⚠️ 注意事项

- 确保VPN已开启（如果需要）
- 手机和电脑在同一网络
- Frida服务正常运行
- 游戏和修改器都已打开
- 按Ctrl+C停止捕获

## 🔧 故障排除

如果遇到问题：

1. **检查设备连接**：`frida -U --list-devices`
2. **检查应用运行**：`frida -U --list-applications`
3. **重启Frida服务**：在手机上重启frida-server
4. **检查包名**：确保使用正确的Bundle ID

## 📝 生成的代码

系统会自动生成两种格式的修改器代码：

- **Frida版本**：可直接运行的JavaScript代码
- **Objective-C版本**：可编译为dylib的源代码

这些代码会完全复制其他修改器的功能！