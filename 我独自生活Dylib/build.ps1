# 我独自生活修改器 v16.0 高级版编译脚本 (PowerShell版本)

Write-Host "🚀 开始编译 WoduziCheat v16.0 高级版..." -ForegroundColor Green

# 检查源文件
if (-not (Test-Path "WoduziCheat_Advanced.m")) {
    Write-Host "❌ 错误: 未找到 WoduziCheat_Advanced.m 文件" -ForegroundColor Red
    Write-Host "请确保在正确的目录中运行此脚本" -ForegroundColor Yellow
    Read-Host "按回车键退出"
    exit 1
}

# 设置编译参数
$ARCH = "arm64"
$MIN_IOS_VERSION = "14.0"
$SOURCE_FILE = "WoduziCheat_Advanced.m"
$OUTPUT_FILE = "WoduziCheat_Advanced.dylib"

Write-Host "📋 编译配置:" -ForegroundColor Cyan
Write-Host "   架构: $ARCH"
Write-Host "   最低iOS版本: $MIN_IOS_VERSION"
Write-Host "   源文件: $SOURCE_FILE"
Write-Host "   输出文件: $OUTPUT_FILE"
Write-Host ""

# 获取SDK路径
try {
    $SDK_PATH = & xcrun --sdk iphoneos --show-sdk-path 2>$null
    if (-not $SDK_PATH) {
        throw "无法获取SDK路径"
    }
    Write-Host "SDK路径: $SDK_PATH" -ForegroundColor Green
} catch {
    Write-Host "❌ 错误: 无法获取iOS SDK路径" -ForegroundColor Red
    Write-Host "请确保已安装Xcode Command Line Tools" -ForegroundColor Yellow
    Write-Host "运行: xcode-select --install" -ForegroundColor Yellow
    Read-Host "按回车键退出"
    exit 1
}

Write-Host ""
Write-Host "🔨 正在编译高级版..." -ForegroundColor Yellow

# 编译命令
$compileArgs = @(
    "-arch", $ARCH,
    "-isysroot", $SDK_PATH,
    "-miphoneos-version-min=$MIN_IOS_VERSION",
    "-dynamiclib",
    "-framework", "UIKit",
    "-framework", "Foundation",
    "-fobjc-arc",
    "-O2",
    "-o", $OUTPUT_FILE,
    $SOURCE_FILE
)

try {
    & clang @compileArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 编译成功!" -ForegroundColor Green
        Write-Host ""
        
        # 显示文件信息
        if (Test-Path $OUTPUT_FILE) {
            $fileInfo = Get-Item $OUTPUT_FILE
            Write-Host "📊 文件信息:" -ForegroundColor Cyan
            Write-Host "   文件名: $($fileInfo.Name)"
            Write-Host "   大小: $([math]::Round($fileInfo.Length / 1MB, 2)) MB"
            Write-Host "   创建时间: $($fileInfo.CreationTime)"
            Write-Host ""
            
            # 检查ldid
            try {
                & ldid --version 2>$null | Out-Null
                Write-Host "🔐 正在进行代码签名..." -ForegroundColor Yellow
                & ldid -S $OUTPUT_FILE
                Write-Host "✅ 代码签名完成" -ForegroundColor Green
            } catch {
                Write-Host "⚠️  警告: 未找到ldid，跳过代码签名" -ForegroundColor Yellow
                Write-Host "   可以手动安装: brew install ldid" -ForegroundColor Gray
            }
            
            Write-Host ""
            Write-Host "🎉 编译完成!" -ForegroundColor Green
            Write-Host "📁 输出文件: $(Get-Location)\$OUTPUT_FILE" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "📋 使用说明:" -ForegroundColor Cyan
            Write-Host "1. 将 $OUTPUT_FILE 注入到游戏中"
            Write-Host "2. 启动游戏，看到红色'高级'悬浮按钮"
            Write-Host "3. 点击按钮打开高级功能菜单"
            Write-Host "4. 先启用Hook，再设置数值"
            Write-Host "5. 在游戏中操作触发拦截"
            Write-Host ""
            Write-Host "🔧 技术特性:" -ForegroundColor Cyan
            Write-Host "• 多层Hook架构 (NSUserDefaults + 内存操作)"
            Write-Host "• 智能数值识别系统"
            Write-Host "• PlayGearLib标准数值 (21亿/10万)"
            Write-Host "• 实时拦截统计"
            Write-Host "• 完整日志记录"
            Write-Host ""
            Write-Host "⚠️  重要: 这是v16.0高级版，不同于v15.3稳定版!" -ForegroundColor Yellow
            
        } else {
            Write-Host "❌ 错误: 未找到输出文件" -ForegroundColor Red
        }
    } else {
        throw "编译失败，退出代码: $LASTEXITCODE"
    }
} catch {
    Write-Host "❌ 编译失败!" -ForegroundColor Red
    Write-Host "错误信息: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "请检查:" -ForegroundColor Yellow
    Write-Host "1. Xcode Command Line Tools是否已安装"
    Write-Host "2. iOS SDK是否可用"
    Write-Host "3. 源文件是否存在语法错误"
}

Write-Host ""
Read-Host "按回车键退出"