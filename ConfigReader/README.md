# GameForFun 配置读取器

## 用途
这个应用专门用来读取 GameForFun.dylib 加载的游戏配置。

## 使用方法

### 1. 编译 IPA
推送到 GitHub，通过 Actions 自动编译。

### 2. 注入 GameForFun.dylib
使用工具将 GameForFun.dylib 注入到编译好的 IPA 中。

### 3. 用 Filza 修改包名
1. 安装注入后的 IPA
2. 用 Filza 打开应用目录
3. 找到 `Info.plist`
4. 修改 `CFBundleIdentifier` 为目标游戏的包名
   - 元气骑士: `com.ChillyRoom.DungeonShooter`
   - 饥饿荒野: `com.fastfly.marooned`
   - 其他游戏: 对应的 Bundle ID

### 4. 重启应用
修改包名后，重启应用。GameForFun 会根据新的包名加载对应游戏的配置。

### 5. 查看配置
应用会自动显示：
- FanhanGGEngine 的所有方法
- 本地脚本内容
- 配置文件位置和内容

## 原理
GameForFun.dylib 根据应用的 Bundle ID 从云端加载不同游戏的功能配置。
通过修改包名，我们可以让 GameForFun 加载任意游戏的配置，然后读取这些配置。
