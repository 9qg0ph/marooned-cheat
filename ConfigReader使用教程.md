# GameForFun 配置读取器使用教程

## 原理说明

GameForFun.dylib 会根据应用的 **Bundle ID** 从云端加载对应游戏的功能配置。

我们的策略：
1. 创建一个专门的配置读取器应用
2. 注入 GameForFun.dylib
3. 用 Filza 修改应用的 Bundle ID 为目标游戏的包名
4. GameForFun 会自动加载该游戏的配置
5. 应用会读取并显示所有配置信息

---

## 使用步骤

### 第一步：获取 IPA

1. 代码已推送到 GitHub
2. 访问 Actions 页面运行 "Build Config Reader IPA"
3. 下载编译好的 `ConfigReader.ipa`

### 第二步：注入 GameForFun.dylib

使用注入工具（如 IPAPatcher、Sideloadly）：
1. 打开 ConfigReader.ipa
2. 注入 GameForFun.dylib
3. 保存注入后的 IPA

### 第三步：安装应用

使用 TrollStore 安装注入后的 IPA。

### 第四步：用 Filza 修改包名

1. 打开 Filza
2. 导航到：`/var/containers/Bundle/Application/`
3. 找到 "配置读取器" 应用目录
4. 进入应用目录，找到 `Info.plist`
5. 用文本编辑器打开 `Info.plist`
6. 找到 `<key>CFBundleIdentifier</key>` 这一行
7. 修改下一行的值为目标游戏的包名：

```xml
<!-- 修改前 -->
<key>CFBundleIdentifier</key>
<string>com.test.configreader</string>

<!-- 修改为元气骑士 -->
<key>CFBundleIdentifier</key>
<string>com.ChillyRoom.DungeonShooter</string>

<!-- 或修改为饥饿荒野 -->
<key>CFBundleIdentifier</key>
<string>com.fastfly.marooned</string>
```

8. 保存文件

### 第五步：重启应用

1. 完全关闭配置读取器应用
2. 重新打开应用
3. 等待 2-3 秒，应用会自动读取配置

### 第六步：查看配置

应用会在黑色背景的日志区域显示：

```
========================================
开始读取 GameForFun 配置...
========================================

当前包名: com.ChillyRoom.DungeonShooter

✓ 找到 FanhanGGEngine 类

--- FanhanGGEngine 方法列表 ---
  getLocalScripts
  getFilepath:withname:type:
  ...

--- 尝试获取本地脚本 ---
脚本内容: {...}

--- 搜索配置文件 ---
发现文件: /path/to/config.json
  内容: {...}

========================================
配置读取完成
========================================
```

---

## 常见游戏包名

| 游戏名称 | Bundle ID |
|---------|-----------|
| 元气骑士 | com.ChillyRoom.DungeonShooter |
| 饥饿荒野 | com.fastfly.marooned |
| 我独自生活 | 待补充 |
| 其他游戏 | 用 Frida 查询：`python -m frida_tools.ps -U` |

---

## 优势

1. **一次编译，多次使用** - 只需修改包名即可测试不同游戏
2. **无需 Frida** - 应用自动读取配置，不需要外部 hook
3. **可视化显示** - 所有配置直接显示在屏幕上
4. **方便调试** - 可以看到 GameForFun 的所有方法和文件

---

## 注意事项

1. 修改 Bundle ID 后必须重启应用才能生效
2. 确保 GameForFun.dylib 已正确注入
3. 某些游戏的配置可能需要网络连接才能加载
4. 如果没有显示配置，检查 GameForFun 是否支持该游戏

---

## 故障排除

### 问题：应用闪退
- 检查 GameForFun.dylib 是否正确注入
- 尝试重新安装应用

### 问题：未找到 FanhanGGEngine 类
- GameForFun.dylib 未注入或注入失败
- 重新注入 dylib

### 问题：没有显示配置内容
- 该游戏可能不被 GameForFun 支持
- 尝试其他已知支持的游戏包名
- 检查网络连接
