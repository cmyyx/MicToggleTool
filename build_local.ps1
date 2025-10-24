# 本地构建脚本
# 用于在本地开发环境中编译 MicToggleTool

param(
    [string]$Version = "0.0.0-dev",
    [string]$BuildNumber = "0"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MicToggleTool 本地构建脚本" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 解析版本号
$parts = $Version.Split('.')
if ($parts.Length -lt 3) {
    Write-Host "错误: 版本号格式不正确，应为 x.y.z 格式" -ForegroundColor Red
    Write-Host "示例: .\build_local.ps1 -Version 1.0.0 -BuildNumber 1" -ForegroundColor Yellow
    exit 1
}

$major = $parts[0] -replace '[^0-9]', ''
$minor = $parts[1]
$patch = $parts[2] -replace '[^0-9]', ''

# 获取当前时间（UTC）
$utcNow = (Get-Date).ToUniversalTime()
$date = $utcNow.ToString("yyyy-MM-dd")
$buildTime = $utcNow.ToString("yyyy-MM-dd HH:mm:ss")
$year = $utcNow.ToString("yyyy")

Write-Host "版本信息:" -ForegroundColor Green
Write-Host "  版本号: $major.$minor.$patch" -ForegroundColor White
Write-Host "  构建时间: $buildTime UTC" -ForegroundColor White
Write-Host "  构建编号: #$BuildNumber" -ForegroundColor White
Write-Host "  发布日期: $date" -ForegroundColor White
Write-Host ""

# 备份原始文件
Write-Host "备份原始文件..." -ForegroundColor Yellow
Copy-Item "MicToggleTool.ahk" "MicToggleTool.ahk.backup" -Force

try {
    # 读取文件内容
    $content = Get-Content "MicToggleTool.ahk" -Raw -Encoding UTF8
    
    # 替换版本号占位符
    Write-Host "替换版本号占位符..." -ForegroundColor Yellow
    $content = $content -replace 'VERSION_MAJOR', $major
    $content = $content -replace 'VERSION_MINOR', $minor
    $content = $content -replace 'VERSION_PATCH', $patch
    $content = $content -replace 'VERSION_FULL', "$major.$minor.$patch"
    $content = $content -replace 'RELEASE_DATE', $date
    $content = $content -replace 'BUILD_TIME', $buildTime
    $content = $content -replace 'BUILD_NUMBER', $BuildNumber
    $content = $content -replace 'COPYRIGHT_YEAR', $year
    
    # 保存修改后的文件
    Set-Content "MicToggleTool.ahk" -Value $content -Encoding UTF8 -NoNewline
    
    Write-Host "✓ 版本信息已更新" -ForegroundColor Green
    Write-Host ""
    
    # 检查必需的文件
    Write-Host "检查必需文件..." -ForegroundColor Yellow
    
    $requiredFiles = @(
        "MicToggleTool.ahk",
        "icons\mic_enabled.ico",
        "icons\mic_disabled.ico",
        "icons\mic_unavailable.ico"
    )
    
    $missingFiles = @()
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Host "  ✓ $file" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $file (缺失)" -ForegroundColor Red
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "错误: 缺少必需的文件" -ForegroundColor Red
        Write-Host "请确保以下文件存在:" -ForegroundColor Yellow
        foreach ($file in $missingFiles) {
            Write-Host "  - $file" -ForegroundColor White
        }
        throw "Missing required files"
    }
    
    Write-Host ""
    
    # 动态查找 AutoHotkey 安装路径
    Write-Host "查找 AutoHotkey 安装路径..." -ForegroundColor Yellow
    
    $ahkInstallPath = $null
    $baseFile = $null
    $ahk2exePath = $null
    
    # 使用 where.exe 查找 AutoHotkey64.exe
    try {
        $whereResult = where.exe AutoHotkey64.exe 2>$null
        if ($whereResult) {
            # where.exe 可能返回多个结果，取第一个
            if ($whereResult -is [array]) {
                $baseFile = $whereResult[0]
            } else {
                $baseFile = $whereResult
            }
            
            # 从 AutoHotkey64.exe 路径推导安装目录
            $ahkInstallPath = Split-Path $baseFile -Parent
            $ahk2exePath = Join-Path $ahkInstallPath "Compiler\Ahk2Exe.exe"
            
            Write-Host "  ✓ 找到 AutoHotkey: $ahkInstallPath" -ForegroundColor Green
        }
    } catch {
        Write-Host "  where.exe 查找失败" -ForegroundColor Yellow
    }
    
    # 如果 where.exe 失败，尝试常见路径
    if (-not $ahkInstallPath) {
        Write-Host "  尝试常见安装路径..." -ForegroundColor Yellow
        
        $commonPaths = @(
            "C:\Program Files\AutoHotkey",
            "D:\Tools\AutoHotkey",
            "$env:LOCALAPPDATA\Programs\AutoHotkey",
            "$env:ProgramFiles\AutoHotkey"
        )
        
        foreach ($path in $commonPaths) {
            $testBase = Join-Path $path "AutoHotkey64.exe"
            $testAhk2exe = Join-Path $path "Compiler\Ahk2Exe.exe"
            
            if ((Test-Path $testBase) -and (Test-Path $testAhk2exe)) {
                $ahkInstallPath = $path
                $baseFile = $testBase
                $ahk2exePath = $testAhk2exe
                Write-Host "  ✓ 找到 AutoHotkey: $ahkInstallPath" -ForegroundColor Green
                break
            }
        }
    }
    
    # 验证必需文件
    if (-not $ahkInstallPath) {
        Write-Host ""
        Write-Host "错误: 未找到 AutoHotkey 安装" -ForegroundColor Red
        Write-Host "请确保已安装 AutoHotkey v2" -ForegroundColor Yellow
        throw "AutoHotkey not found"
    }
    
    if (-not (Test-Path $ahk2exePath)) {
        Write-Host ""
        Write-Host "错误: 未找到 Ahk2Exe.exe" -ForegroundColor Red
        Write-Host "路径: $ahk2exePath" -ForegroundColor White
        throw "Ahk2Exe.exe not found"
    }
    
    if (-not (Test-Path $baseFile)) {
        Write-Host ""
        Write-Host "错误: 未找到 AutoHotkey64.exe (Base file)" -ForegroundColor Red
        Write-Host "路径: $baseFile" -ForegroundColor White
        throw "AutoHotkey64.exe not found"
    }
    
    Write-Host "✓ Ahk2Exe: $ahk2exePath" -ForegroundColor Green
    Write-Host "✓ Base file: $baseFile" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "开始编译..." -ForegroundColor Yellow
    Write-Host "命令: $ahk2exePath" -ForegroundColor Gray
    Write-Host "参数: /in MicToggleTool.ahk /out MicToggleTool.exe /icon icons\mic_enabled.ico /base $baseFile /silent" -ForegroundColor Gray
    Write-Host ""
    
    # 编译（使用 /silent 避免 GUI 弹窗）
    $arguments = @(
        "/in", "MicToggleTool.ahk",
        "/out", "MicToggleTool.exe",
        "/icon", "icons\mic_enabled.ico",
        "/base", $baseFile,
        "/silent"
    )
    
    # 捕获输出
    $output = & $ahk2exePath $arguments 2>&1
    $exitCode = $LASTEXITCODE
    
    # 显示输出
    if ($output) {
        Write-Host "Ahk2Exe 输出:" -ForegroundColor Gray
        Write-Host $output -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "Ahk2Exe 退出码: $exitCode" -ForegroundColor Gray
    Write-Host ""
    
    # 等待文件系统同步
    Start-Sleep -Seconds 2
    
    # 检查编译结果
    if (Test-Path "MicToggleTool.exe") {
        $size = (Get-Item "MicToggleTool.exe").Length
        $sizeMB = [math]::Round($size / 1MB, 2)
        
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "✓ 编译成功!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "文件: MicToggleTool.exe" -ForegroundColor White
        Write-Host "大小: $sizeMB MB ($size bytes)" -ForegroundColor White
        Write-Host ""
        
        # 计算 SHA256
        $hash = (Get-FileHash -Path "MicToggleTool.exe" -Algorithm SHA256).Hash
        Write-Host "SHA256: $hash" -ForegroundColor White
        Write-Host ""
        
    } else {
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "✗ 编译失败" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "MicToggleTool.exe 未生成" -ForegroundColor White
        throw "Compilation failed"
    }
    
} catch {
    Write-Host ""
    Write-Host "构建失败: $_" -ForegroundColor Red
    exit 1
} finally {
    # 恢复原始文件
    Write-Host "恢复原始文件..." -ForegroundColor Yellow
    Move-Item "MicToggleTool.ahk.backup" "MicToggleTool.ahk" -Force
    Write-Host "✓ 原始文件已恢复" -ForegroundColor Green
}

Write-Host ""
Write-Host "构建完成!" -ForegroundColor Cyan
