# MicToggleTool

<div align="center">

![Version](https://img.shields.io/github/v/release/cmyyx/MicToggleTool?label=version)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)
![License](https://img.shields.io/github/license/cmyyx/MicToggleTool)
![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2.0-red.svg)
![Size](https://img.shields.io/github/repo-size/cmyyx/MicToggleTool)
![Downloads](https://img.shields.io/github/downloads/cmyyx/MicToggleTool/total)
![Stars](https://img.shields.io/github/stars/cmyyx/MicToggleTool)
![Issues](https://img.shields.io/github/issues/cmyyx/MicToggleTool)

**一个轻量级的 Windows 麦克风快捷控制工具**

[English](#english) | [中文](#中文)

[下载](https://github.com/cmyyx/MicToggleTool/releases) • [文档](#中文) • [问题反馈](https://github.com/cmyyx/MicToggleTool/issues)

</div>

---

## 中文

### 📖 简介

MicToggleTool 是一个轻量级的 Windows 系统托盘应用程序，允许您通过全局快捷键或托盘图标快速切换麦克风的启用/禁用状态，并在麦克风被禁用时显示视觉提示。

### ✨ 主要特性

- 🎯 **全局快捷键控制** - 默认 F9，可自定义，在任何应用中都能工作
- 🖱️ **系统托盘集成** - 左键点击切换，右键显示菜单
- 💬 **悬浮窗提示** - 麦克风禁用时显示半透明提示窗口
- 🎨 **动态托盘图标** - 绿色（启用）、红色（禁用）、灰色（不可用）
- 🔧 **灵活配置** - INI 配置文件，支持自定义快捷键、悬浮窗样式等
- 🚀 **开机自启** - 可选的开机自动启动功能
- 📦 **单文件便携** - 所有资源嵌入，无需额外文件
- 🛡️ **管理员权限** - 确保快捷键在所有应用中工作（包括游戏）

### 📸 截图

> 托盘图标状态：
> - 🟢 绿色 = 麦克风启用
> - 🔴 红色 = 麦克风禁用
> - ⚪ 灰色 = 设备不可用

### 🚀 快速开始

#### 下载

从 [Releases](https://github.com/cmyyx/MicToggleTool/releases) 页面下载最新版本的 `MicToggleTool.exe`。

#### 安装

1. 将 `MicToggleTool.exe` 放到任意文件夹
2. 双击运行
3. 在 UAC 提示中点击"是"授予管理员权限
4. 首次运行时选择要控制的麦克风设备

#### 使用

- **快捷键**: 按 `F9` 切换麦克风状态（可自定义）
- **托盘图标**: 左键点击切换，右键显示菜单
- **悬浮窗**: 麦克风禁用时自动显示提示

### ⚙️ 配置

配置文件：`MicToggleTool.ini`（首次运行自动创建）

#### 主要配置项

```ini
[General]
Hotkey=F9                    ; 全局快捷键
AutoStart=0                  ; 开机自启（0=禁用, 1=启用）
TargetDevice=1               ; 目标麦克风设备 ID
AdminCheck=prompt            ; 管理员权限检查模式

[Overlay]
Enabled=1                    ; 启用悬浮窗（0=禁用, 1=启用）
Position=TopRight            ; 位置（TopLeft, TopRight, BottomLeft, BottomRight, TopCenter, BottomCenter）
OffsetX=100                  ; X 轴偏移（像素）
OffsetY=100                  ; Y 轴偏移（像素）
Transparency=200             ; 透明度（0-255）
BackgroundColor=F0F0F0       ; 背景颜色（RGB 十六进制）
TextColor=000000             ; 文字颜色（RGB 十六进制）
Text=麦克风已禁用            ; 提示文本
FontSize=14                  ; 字体大小
ShowIcon=1                   ; 显示图标（0=不显示, 1=显示）
```

#### 快捷键格式

- `F9` - 单个功能键
- `^F9` - Ctrl + F9
- `!F9` - Alt + F9
- `+F9` - Shift + F9
- `#F9` - Win + F9
- `^!M` - Ctrl + Alt + M

### 🎯 高级功能

#### 设备选择

- 支持显示设备 ID：`[18] Mic`
- 可选"显示所有设备"模式，包括扬声器
- 支持虚拟麦克风设备（Voicemeeter、VB-Audio 等）

#### 设备可用性检测

- 自动检测设备连接状态
- 设备断开时显示灰色图标
- 设备 ID 变化时自动重新查找

#### 日志记录

- 自动记录运行日志：`MicToggleTool.log`
- 日志轮转（超过 5MB 自动备份）
- 可通过托盘菜单查看日志

### 📋 系统要求

- **操作系统**: Windows 7 / 8 / 8.1 / 10 / 11
- **权限**: 管理员权限（推荐）
- **设备**: 至少一个可用的麦克风设备
- **磁盘空间**: < 5 MB

### 🔧 故障排除

#### 快捷键不工作

**问题**: 按快捷键没有反应

**解决方案**:
1. 确认程序以管理员权限运行
2. 检查快捷键是否被其他程序占用
3. 尝试更换其他快捷键（编辑 `MicToggleTool.ini` 中的 `Hotkey` 值）
4. 查看日志文件 `MicToggleTool.log` 了解详细错误
5. 在某些全屏游戏中，可能需要窗口化或无边框模式

#### 设备不可用

**问题**: 托盘图标显示灰色，提示设备不可用

**解决方案**:
1. 检查麦克风是否已连接
2. 打开设备管理器，确认设备状态正常
3. 尝试重新选择设备：
   - 右键托盘图标 → 选择设备
   - 勾选"显示所有设备（包括扬声器）"
   - 选择正确的麦克风设备
4. 检查设备是否被其他程序独占
5. 重启程序或重新插拔设备

#### UAC 提示未显示

**问题**: 双击程序没有 UAC 提示

**解决方案**:
1. 检查 Windows UAC 设置（控制面板 → 用户账户 → 更改用户账户控制设置）
2. 右键程序 → 以管理员身份运行
3. 重新下载程序（可能文件损坏或被杀毒软件修改）
4. 检查文件属性 → 兼容性 → 是否勾选了"以管理员身份运行此程序"

#### 配置文件损坏

**问题**: 程序启动时提示配置文件错误

**解决方案**:
1. 程序会自动备份损坏的配置文件（带时间戳）
2. 删除 `MicToggleTool.ini`，程序会自动创建默认配置
3. 从备份文件中恢复需要的配置项

#### 日志文件过大

**问题**: 日志文件占用空间过大

**解决方案**:
1. 程序会自动轮转日志（超过 5MB 时备份）
2. 手动删除旧的备份日志文件（`MicToggleTool.log.backup_*`）
3. 通过托盘菜单 → 查看日志，可以清理所有日志

### ❓ 常见问题 (FAQ)

#### Q: 为什么需要管理员权限？

**A**: 管理员权限确保全局快捷键能在所有应用程序中工作，包括以管理员权限运行的程序（如某些游戏、系统工具等）。如果不以管理员身份运行，快捷键可能在这些程序中无法响应。

#### Q: 程序会收集我的数据吗？

**A**: 不会。程序完全在本地运行，不会连接网络，不会收集或上传任何数据。所有配置和日志都保存在本地。

#### Q: 可以控制多个麦克风吗？

**A**: 当前版本一次只能控制一个麦克风设备。如果需要切换设备，可以通过托盘菜单 → 选择设备来更换。

#### Q: 支持 macOS 或 Linux 吗？

**A**: 不支持。本程序基于 AutoHotkey v2 开发，仅支持 Windows 平台。

#### Q: 可以自定义托盘图标吗？

**A**: 当前版本使用内置图标。如果需要自定义，可以修改源代码中的图标资源并重新编译。

#### Q: 程序占用多少资源？

**A**: 非常轻量：
- 内存占用: < 10 MB
- CPU 占用: 空闲时 < 0.1%
- 磁盘空间: < 5 MB（包含所有资源）

#### Q: 如何卸载？

**A**: 
1. 右键托盘图标 → 退出
2. 如果启用了开机自启，先取消勾选"开机启动"
3. 删除 `MicToggleTool.exe` 文件
4. （可选）删除配置文件 `MicToggleTool.ini` 和日志文件 `MicToggleTool.log`
5. （可选）删除临时图标文件夹 `%TEMP%\MicToggleTool_Icons\`

#### Q: 可以在多台电脑上使用吗？

**A**: 可以。程序是单文件便携版，可以复制到 U 盘或其他电脑使用。配置文件会在首次运行时自动创建。

#### Q: 支持哪些快捷键？

**A**: 支持所有 AutoHotkey v2 支持的快捷键格式，包括：
- 功能键：F1-F24
- 字母键：A-Z
- 数字键：0-9
- 修饰符：Ctrl (^), Alt (!), Shift (+), Win (#)
- 组合键：如 ^!M (Ctrl+Alt+M)

详见配置章节的快捷键格式说明。

### 🏗️ 技术架构

#### 核心技术

- **语言**: AutoHotkey v2.0
- **编译器**: Ahk2Exe
- **资源嵌入**: FileInstall
- **权限管理**: UAC Manifest

#### 架构设计

```
┌─────────────────────────────────────────┐
│           AppController                 │  应用主控制器
│  (初始化、协调各模块、生命周期管理)      │
└─────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
┌───────▼──────┐ ┌──▼────────┐ ┌▼──────────────┐
│ HotkeyListener│ │TrayManager│ │OverlayManager │
│  (快捷键监听) │ │ (托盘管理) │ │  (悬浮窗管理)  │
└───────┬──────┘ └──┬────────┘ └┬──────────────┘
        │           │           │
        └───────────┼───────────┘
                    │
        ┌───────────▼───────────┐
        │ MicrophoneController  │  麦克风控制核心
        │  (设备枚举、状态控制)  │
        └───────────┬───────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
┌───────▼──────┐ ┌──▼────────┐ ┌▼──────────────┐
│ConfigManager │ │AdminChecker│ │ResourceManager│
│ (配置管理)   │ │ (权限检查) │ │  (资源管理)   │
└──────────────┘ └───────────┘ └───────────────┘
```

#### 关键特性实现

**1. 单文件便携**
- 使用 `FileInstall` 在编译时嵌入图标资源
- 运行时提取到临时目录 `%TEMP%\MicToggleTool_Icons\`
- 退出时自动清理临时文件

**2. 全局快捷键**
- 使用 AutoHotkey 的 `Hotkey` 函数注册
- 需要管理员权限确保在所有应用中工作
- 支持动态更新快捷键

**3. 设备管理**
- 通过 `SoundGetName` 和 `SoundGetMute` 枚举设备
- 支持设备 ID 和名称双重识别
- 自动处理设备 ID 变化

**4. UAC 权限**
- 通过 Manifest 文件要求管理员权限
- 运行时检查权限状态
- 提供提权重启功能

**5. 配置持久化**
- INI 格式配置文件
- 自动备份损坏的配置
- 支持热重载（部分配置）

### 🛠️ 开发指南

#### 环境要求

- [AutoHotkey v2.0+](https://www.autohotkey.com/)
- Windows 7 或更高版本
- 文本编辑器（推荐 VS Code + AutoHotkey v2 扩展）

#### 项目结构

```
MicToggleTool/
├── MicToggleTool.ahk          # 主脚本文件
├── MicToggleTool.manifest     # UAC 清单文件
├── icons/                     # 图标资源
│   ├── mic_enabled.png        # 启用图标
│   ├── mic_disabled.png       # 禁用图标
│   ├── mic_unavailable.png    # 不可用图标
│   ├── mic_enabled.ico        # 程序图标
│   ├── mic_disabled.ico
│   └── mic_unavailable.ico
└── README.md                  # 本文件
```

#### 克隆项目

```bash
git clone https://github.com/cmyyx/MicToggleTool.git
cd MicToggleTool
```

#### 运行开发版本

直接运行脚本（无需编译）：

```bash
# 方法 1: 双击 MicToggleTool.ahk
# 方法 2: 使用 AutoHotkey 运行
"C:\Program Files\AutoHotkey\AutoHotkey64.exe" MicToggleTool.ahk
```

#### 编译为可执行文件

##### 方法 1: 使用 Ahk2Exe GUI

1. 打开 Ahk2Exe 编译器（通常在 `C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe`）
2. 配置：
   - **Source**: `MicToggleTool.ahk`
   - **Destination**: `MicToggleTool.exe`
   - **Icon**: `icons\mic_enabled.ico`
   - **Base File**: `AutoHotkey64.exe`
3. 点击 **Convert** 编译

##### 方法 2: 命令行编译

```bash
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "MicToggleTool.ahk" /out "MicToggleTool.exe" /icon "icons\mic_enabled.ico"
```

#### 编译说明

- **UAC 清单**: 通过脚本中的 `@Ahk2Exe-AddResource` 指令自动嵌入
- **图标资源**: 使用 `FileInstall` 在编译时嵌入到 exe 中
- **单文件**: 所有资源（图标、清单）都嵌入到 exe，无需额外文件

#### 调试

查看日志文件：
```bash
# 日志文件位置
.\MicToggleTool.log

# 实时查看日志（PowerShell）
Get-Content .\MicToggleTool.log -Wait -Tail 50
```

#### 代码结构

主要类和模块：

- **ResourceManager** - 资源管理（嵌入图标提取）
- **ConfigManager** - 配置文件管理
- **MicrophoneController** - 麦克风控制核心
- **DeviceSelector** - 设备选择对话框
- **TrayManager** - 系统托盘管理
- **OverlayManager** - 悬浮窗管理
- **HotkeyListener** - 全局快捷键监听
- **AdminChecker** - 管理员权限检查
- **SettingsDialog** - 设置对话框
- **AppController** - 应用程序主控制器

### 🤝 贡献指南

我们欢迎各种形式的贡献！

#### 报告问题

在 [Issues](https://github.com/cmyyx/MicToggleTool/issues) 页面提交问题时，请包含：

- 操作系统版本
- 程序版本
- 详细的问题描述
- 复现步骤
- 相关日志（如果有）

#### 提交代码

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

#### 代码规范

- 使用 4 空格缩进
- 函数和类使用 PascalCase
- 变量使用 camelCase
- 添加必要的注释（中文）
- 遵循现有代码风格

#### 提交信息规范

```
<type>: <subject>

<body>
```

类型（type）：
- `feat`: 新功能
- `fix`: 修复 bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建/工具相关

示例：
```
feat: 添加设备 ID 显示功能

- 在设备列表中显示设备 ID
- 格式：[ID] 设备名称
- 便于用户识别和调试
```

### 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

### 🙏 致谢

- 使用 [AutoHotkey v2](https://www.autohotkey.com/) 开发
- 图标资源嵌入技术

---

## English

### 📖 Introduction

MicToggleTool is a lightweight Windows system tray application that allows you to quickly toggle your microphone on/off using a global hotkey or tray icon, with visual feedback when the microphone is disabled.

### ✨ Key Features

- 🎯 **Global Hotkey Control** - Default F9, customizable, works in any application
- 🖱️ **System Tray Integration** - Left-click to toggle, right-click for menu
- 💬 **Overlay Notification** - Semi-transparent overlay when microphone is disabled
- 🎨 **Dynamic Tray Icon** - Green (enabled), Red (disabled), Gray (unavailable)
- 🎤 **Multi-Device Support** - Supports both real and virtual microphone devices
- 🔧 **Flexible Configuration** - INI config file, customize hotkey, overlay style, etc.
- 🚀 **Auto-Start** - Optional auto-start on Windows boot
- 📦 **Single File Portable** - All resources embedded, no additional files needed
- 🛡️ **Administrator Rights** - Ensures hotkey works in all applications (including games)

### 🚀 Quick Start

#### Download

Download the latest `MicToggleTool.exe` from the [Releases](https://github.com/cmyyx/MicToggleTool/releases) page.

#### Installation

1. Place `MicToggleTool.exe` in any folder
2. Double-click to run
3. Click "Yes" in the UAC prompt to grant administrator rights
4. Select your microphone device on first run

#### Usage

- **Hotkey**: Press `F9` to toggle microphone (customizable)
- **Tray Icon**: Left-click to toggle, right-click for menu
- **Overlay**: Automatically shows when microphone is disabled

### ⚙️ Configuration

Configuration file: `MicToggleTool.ini` (auto-created on first run)

See the Chinese section above for detailed configuration options.

### 📋 System Requirements

- **OS**: Windows 7 / 8 / 8.1 / 10 / 11
- **Permissions**: Administrator rights (recommended)
- **Device**: At least one available microphone device
- **Disk Space**: < 5 MB

### 🤝 Contributing

Issues and Pull Requests are welcome!

### 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### 📧 Contact

- Issues: [Submit Issue](https://github.com/cmyyx/MicToggleTool/issues)

---

<div align="center">

Made with ❤️ using AutoHotkey v2

⭐ Star this repo if you find it useful!

</div>
