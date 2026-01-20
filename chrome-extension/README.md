# IPA下载拦截器 Chrome扩展

## 功能说明
这是一个Chrome浏览器扩展，用于拦截和绕过app.ios80.com网站的IPA下载限制。

## 安装步骤

### 1. 开启开发者模式
1. 打开Chrome浏览器
2. 地址栏输入：`chrome://extensions/`
3. 右上角开启"开发者模式"

### 2. 加载扩展
1. 点击"加载已解压的扩展程序"
2. 选择 `chrome-extension` 文件夹
3. 扩展安装完成

### 3. 使用方法
1. 访问 https://app.ios80.com 的任意下载页面
2. 扩展会自动激活并显示在地址栏右侧
3. 点击下载按钮时，扩展会自动拦截并尝试绕过限制
4. 成功时会显示通知并复制IPA地址到剪贴板

## 工作原理

### 多层拦截机制
1. **inject.js**: 在页面JavaScript执行前注入，劫持 `appInstall` 接口
2. **content.js**: 监听页面事件，执行多种绕过策略
3. **background.js**: 拦截网络请求，提取关键参数

### 绕过策略
1. **Manifest文件尝试**: 直接访问可能的manifest.plist文件
2. **IPA直接下载**: 尝试常见的IPA文件路径
3. **API端点探测**: 测试各种API接口

## 特性
- ✅ 自动拦截下载请求
- ✅ 多种绕过策略
- ✅ 实时结果显示
- ✅ 一键复制IPA地址
- ✅ 结果导出功能
- ✅ 详细的调试信息

## 注意事项
- 仅供学习研究使用
- 请遵守相关法律法规
- 不保证100%成功率
- 建议配合VPN使用

## 调试信息
打开Chrome开发者工具(F12)查看Console标签页，可以看到详细的拦截和绕过过程。

## 文件结构
```
chrome-extension/
├── manifest.json     # 扩展配置文件
├── background.js     # 后台脚本(网络拦截)
├── content.js        # 内容脚本(页面交互)
├── inject.js         # 注入脚本(接口劫持)
├── popup.html        # 弹出界面
├── popup.js          # 弹出界面逻辑
├── icon.png          # 扩展图标
└── README.md         # 说明文档
```