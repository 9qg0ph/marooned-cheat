# 元气骑士测试应用

这是一个用于测试 GameForFun Hook 的简单 iOS 应用。

## Bundle ID
`com.ChillyRoom.DungeonShooter`

## 用途
- 提供一个没有反调试保护的测试环境
- 用于验证 Frida Hook 脚本是否正确工作
- 可以注入 GameForFun.dylib 进行功能测试

## 编译
推送到 GitHub 后，GitHub Actions 会自动编译生成 IPA 文件。

## 安装
1. 下载编译好的 IPA
2. 使用 TrollStore 或其他工具安装
3. 运行应用后使用 Frida 附加测试
