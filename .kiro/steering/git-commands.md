---
inclusion: always
---

# Git 命令执行注意事项

在此电脑上，`git` 命令不在系统 PATH 中，必须使用完整路径调用。

## 正确的 Git 调用方式（PowerShell）

```powershell
& "C:\Program Files\Git\bin\git.exe" add -A
& "C:\Program Files\Git\bin\git.exe" commit -m "提交信息"
& "C:\Program Files\Git\bin\git.exe" push
```

## 推送前检查清单

1. 确保 VPN 已开启（访问 GitHub 需要）
2. 如果代理导致连接失败，先清除 Git 代理设置：
   ```powershell
   & "C:\Program Files\Git\bin\git.exe" config --global --unset http.proxy
   & "C:\Program Files\Git\bin\git.exe" config --global --unset https.proxy
   ```
3. 然后再执行 push
