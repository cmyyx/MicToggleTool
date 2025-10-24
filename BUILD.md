# 构建指南

本文档说明如何在本地和 GitHub Actions 中构建 MicToggleTool。

## 本地构建

### 前提条件

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)
2. 确保 Ahk2Exe 编译器已安装（通常在 `C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe`）

### 使用构建脚本

#### 基本用法

```powershell
# 使用默认开发版本 (0.0.0-dev)
.\build_local.ps1

# 指定版本号
.\build_local.ps1 -Version 1.0.0

# 指定版本号和构建编号
.\build_local.ps1 -Version 1.0.0 -BuildNumber 42
```

#### 参数说明

- `-Version`: 版本号（格式：x.y.z，默认：0.0.0-dev）
- `-BuildNumber`: 构建编号（默认：0）

### 构建过程

构建脚本会自动：

1. 备份原始 `MicToggleTool.ahk` 文件
2. 替换版本号占位符：
   - `VERSION_MAJOR` → 主版本号
   - `VERSION_MINOR` → 次版本号
   - `VERSION_PATCH` → 修订号
   - `VERSION_FULL` → 完整版本号
   - `BUILD_TIME` → 构建时间（UTC）
   - `BUILD_NUMBER` → 构建编号
   - `RELEASE_DATE` → 发布日期
   - `COPYRIGHT_YEAR` → 版权年份
3. 使用 Ahk2Exe 编译为 exe 文件
4. 恢复原始文件
5. 显示编译结果和 SHA256 哈希值

### 输出

成功构建后会生成：
- `MicToggleTool.exe` - 可执行文件

### 自定义 Ahk2Exe 路径

如果 Ahk2Exe 不在默认位置，编辑 `build_local.ps1` 文件，修改 `$ahk2exePath` 变量：

```powershell
$ahk2exePath = "你的\AutoHotkey\路径\Compiler\Ahk2Exe.exe"
```

## GitHub Actions 自动构建

### 触发方式

#### 1. Tag 推送触发

推送符合 `v*.*.*` 格式的 tag：

```bash
git tag v1.0.0
git push origin v1.0.0
```

#### 2. 手动触发

在 GitHub 仓库页面：
1. 进入 Actions 标签页
2. 选择 "Build and Release" 工作流
3. 点击 "Run workflow"
4. 输入版本号（可选，留空则使用最新 tag）

### 自动化流程

GitHub Actions 会自动：

1. 检出代码
2. 获取版本号（从 tag 或手动输入）
3. 下载最新的 AutoHotkey 和 Ahk2Exe
4. 替换版本号占位符
5. 编译 exe 文件
6. 计算 SHA256 哈希值
7. 生成更新日志
8. 创建 GitHub Release
9. 上传编译好的文件

### 构建产物

每次构建会生成：
- `MicToggleTool.exe` - 可执行文件
- `MicToggleTool.exe.sha256` - SHA256 校验文件
- Release Notes - 包含更新日志、下载链接、校验信息等

## 版本号管理

### 版本号格式

遵循语义化版本规范：`MAJOR.MINOR.PATCH`

- `MAJOR`: 主版本号（不兼容的 API 变更）
- `MINOR`: 次版本号（向后兼容的功能新增）
- `PATCH`: 修订号（向后兼容的问题修正）

### 构建编号

- GitHub Actions: 使用 `github.run_number`（累计运行次数）
- 本地构建: 手动指定或使用默认值 0

## 故障排除

### 本地构建失败

**问题**: 找不到 Ahk2Exe.exe

**解决方案**:
1. 确认已安装 AutoHotkey v2
2. 检查 Ahk2Exe 路径是否正确
3. 修改脚本中的 `$ahk2exePath` 变量

**问题**: 编译成功但 exe 未生成

**解决方案**:
1. 检查是否有杀毒软件阻止
2. 确认有足够的磁盘空间
3. 以管理员身份运行 PowerShell

### GitHub Actions 构建失败

**问题**: 权限错误 (403)

**解决方案**:
- 确认工作流文件中有 `permissions: contents: write`

**问题**: 编译超时或卡住

**解决方案**:
- 工作流已配置重试机制，通常会自动恢复
- 可以手动重新运行工作流

## 开发建议

### 本地测试

在推送 tag 之前，建议先本地构建测试：

```powershell
# 构建测试版本
.\build_local.ps1 -Version 1.0.0-test -BuildNumber 999

# 运行并测试
.\MicToggleTool.exe
```

### 版本发布流程

1. 完成功能开发和测试
2. 更新 CHANGELOG（如果有）
3. 本地构建并测试
4. 提交所有更改
5. 创建并推送 tag
6. 等待 GitHub Actions 完成构建
7. 验证 Release 页面的内容

## 相关文件

- `build_local.ps1` - 本地构建脚本
- `.github/workflows/release.yml` - GitHub Actions 工作流
- `MicToggleTool.ahk` - 源代码（包含版本号占位符）
- `compile_simple.bat` - 旧的简单编译脚本（已弃用）

## 注意事项

1. **不要直接修改版本号占位符**：这些占位符会在构建时自动替换
2. **本地构建会自动恢复原始文件**：即使构建失败，源文件也会被恢复
3. **构建编号是累计的**：GitHub Actions 的构建编号会持续增长
4. **时间使用 UTC**：所有时间戳都使用 UTC 时区，避免时区混淆
