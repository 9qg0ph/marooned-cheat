# Frida Hook 天选打工人脚本 - 使用指南

## 前提条件

1. **手机已越狱**
2. **手机已安装 Frida Server**
3. **电脑已安装 Frida Tools**

## 安装 Frida（如果还没安装）

### 在电脑上安装 Frida Tools：
```bash
pip install frida-tools
```

### 在手机上安装 Frida Server：
1. 从 https://github.com/frida/frida/releases 下载对应版本的 frida-server
2. 解压并上传到手机 `/usr/bin/` 目录
3. 赋予执行权限：`chmod +x /usr/bin/frida-server`
4. 运行：`frida-server &`

## 运行 Hook 脚本

### 方法1：启动游戏并 Hook（推荐）
```bash
frida -U -f com.panda.worker -l hook_h5gg_tianxuan.js --no-pause
```

### 方法2：Hook 已运行的游戏
```bash
frida -U "天选打工人" -l hook_h5gg_tianxuan.js
```

或者用包名：
```bash
frida -U com.panda.worker -l hook_h5gg_tianxuan.js
```

## 操作步骤

1. 运行上面的 Frida 命令
2. 等待游戏启动完成
3. 在游戏里加载那个作者的脚本
4. 点击修改按钮（比如"无限金钱"）
5. 观察 Frida 输出的日志

## 预期输出

Frida 会显示类似这样的信息：
```
[JSCore] JavaScript 执行:
h5gg.searchNumber('100', 'I32', '0x100000000', '0x200000000')

[vm_write] 内存写入:
  地址: 0x12df3c37c
  大小: 4
  值 (I32): 999999999
```

## 如果遇到问题

### 找不到设备
```bash
# 检查设备连接
frida-ls-devices

# 应该看到你的 iPhone
```

### 找不到进程
```bash
# 列出所有进程
frida-ps -U

# 搜索游戏进程
frida-ps -U | grep -i panda
```

### Frida Server 未运行
```bash
# SSH 连接到手机
ssh root@手机IP

# 启动 frida-server
frida-server &
```

## 分析结果

把 Frida 输出的所有日志发给我，特别注意：
- `h5gg.searchNumber` 的参数（搜索什么值、什么类型、什么范围）
- `h5gg.searchNearby` 的参数
- `vm_write` 写入的地址和值
- 任何其他 h5gg API 的调用

有了这些信息，我就能知道那个作者用的是什么方法！
