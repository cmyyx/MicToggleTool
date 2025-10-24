; ============================================================================
; 麦克风快捷控制工具 (Microphone Toggle Tool)
; AutoHotkey v2 脚本
; ============================================================================

;@Ahk2Exe-SetName 麦克风快捷控制工具
;@Ahk2Exe-SetDescription 麦克风快捷控制工具 - Microphone Toggle Tool
;@Ahk2Exe-SetVersion VERSION_FULL
;@Ahk2Exe-SetCopyright Copyright (c) COPYRIGHT_YEAR
;@Ahk2Exe-SetOrigFilename MicToggleTool.exe
;@Ahk2Exe-AddResource MicToggleTool.manifest, 24
;@Ahk2Exe-AddResource icons\mic_enabled.png, ICON_ENABLED
;@Ahk2Exe-AddResource icons\mic_disabled.png, ICON_DISABLED
;@Ahk2Exe-AddResource icons\mic_unavailable.png, ICON_UNAVAILABLE

#Requires AutoHotkey v2.0

; ============================================================================
; 资源管理器 (Resource Manager)
; ============================================================================

class ResourceManager {
    
    /**
     * 从嵌入的资源中提取图标文件到临时目录
     * @param {String} resourceName - 资源名称（ICON_ENABLED, ICON_DISABLED, ICON_UNAVAILABLE）
     * @param {String} fileName - 输出文件名
     * @returns {String} 提取后的文件路径，失败返回空字符串
     */
    static ExtractIcon(resourceName, fileName) {
        try {
            ; 如果是编译后的 exe，从资源中提取
            if (A_IsCompiled) {
                tempPath := A_Temp "\MicToggleTool_Icons"
                
                ; 创建临时目录
                if !DirExist(tempPath) {
                    DirCreate(tempPath)
                }
                
                outputFile := tempPath "\" fileName
                
                ; 如果文件已存在，直接返回
                if FileExist(outputFile) {
                    return outputFile
                }
                
                ; 使用 FileInstall 在编译时嵌入文件并在运行时提取
                ; FileInstall 会在编译时将文件嵌入到 exe 中
                switch fileName {
                    case "mic_enabled.png":
                        FileInstall("icons\mic_enabled.png", outputFile, 1)
                    case "mic_disabled.png":
                        FileInstall("icons\mic_disabled.png", outputFile, 1)
                    case "mic_unavailable.png":
                        FileInstall("icons\mic_unavailable.png", outputFile, 1)
                }
                
                if FileExist(outputFile) {
                    LogInfo("已从资源提取图标: " . fileName)
                    return outputFile
                } else {
                    LogError("提取图标失败: " . fileName)
                    return ""
                }
            } else {
                ; 如果是脚本运行，直接返回文件路径
                return A_ScriptDir "\icons\" fileName
            }
        } catch as err {
            LogError("提取图标资源失败: " . err.Message)
            return ""
        }
    }
    
    /**
     * 获取图标路径（自动处理编译版本和脚本版本）
     * @param {String} iconName - 图标名称（enabled, disabled, unavailable）
     * @returns {String} 图标文件路径
     */
    static GetIconPath(iconName) {
        ; 定义图标文件名映射
        iconFiles := Map(
            "enabled", "mic_enabled.png",
            "disabled", "mic_disabled.png",
            "unavailable", "mic_unavailable.png"
        )
        
        if !iconFiles.Has(iconName) {
            LogError("未知的图标名称: " . iconName)
            return ""
        }
        
        fileName := iconFiles[iconName]
        
        ; 如果是编译版本，从资源提取
        if (A_IsCompiled) {
            resourceNames := Map(
                "enabled", "ICON_ENABLED",
                "disabled", "ICON_DISABLED",
                "unavailable", "ICON_UNAVAILABLE"
            )
            
            return this.ExtractIcon(resourceNames[iconName], fileName)
        } else {
            ; 脚本版本，直接返回文件路径
            iconPath := A_ScriptDir "\icons\" fileName
            if FileExist(iconPath) {
                return iconPath
            } else {
                LogWarning("图标文件不存在: " . iconPath)
                return ""
            }
        }
    }
    
    /**
     * 清理临时图标文件
     */
    static CleanupTempIcons() {
        try {
            if (A_IsCompiled) {
                tempPath := A_Temp "\MicToggleTool_Icons"
                if DirExist(tempPath) {
                    DirDelete(tempPath, true)
                    LogInfo("已清理临时图标文件")
                }
            }
        } catch as err {
            LogError("清理临时图标失败: " . err.Message)
        }
    }
}

; ============================================================================
; 全局变量
; ============================================================================

; 应用程序版本信息
; 注意：VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH, RELEASE_DATE, COPYRIGHT_YEAR, BUILD_TIME, BUILD_NUMBER
; 这些值会在编译时由 GitHub Actions 自动替换
global AppVersion := {
    major: VERSION_MAJOR,
    minor: VERSION_MINOR,
    patch: VERSION_PATCH,
    fullVersion: "VERSION_FULL",
    releaseDate: "RELEASE_DATE",
    buildTime: "BUILD_TIME",
    buildNumber: "BUILD_NUMBER",
    copyrightYear: "COPYRIGHT_YEAR",
    name: "麦克风快捷控制工具",
    nameEn: "Microphone Toggle Tool",
    githubRepo: "cmyyx/MicToggleTool"
}

global AppState := {
    microphoneEnabled: true,
    overlayVisible: false,
    overlayWindow: "",
    currentHotkey: "",
    configPath: A_ScriptDir "\MicToggleTool.ini",
    targetDevice: "",
    targetDeviceName: "",
    availableDevices: [],
    firstRun: false
}

; ============================================================================
; 配置管理器 (Configuration Manager)
; ============================================================================

class ConfigManager {
    
    ; 默认配置
    static DefaultConfig := Map(
        "General_Hotkey", "F9",
        "General_AutoStart", "0",
        "General_TargetDevice", "",
        "General_AdminCheck", "prompt",
        "General_AutoCheckUpdate", "1",
        "General_AutoCheckUpdateSilent", "1",
        "Overlay_Enabled", "1",
        "Overlay_Position", "TopRight",
        "Overlay_OffsetX", "100",
        "Overlay_OffsetY", "100",
        "Overlay_Transparency", "200",
        "Overlay_BackgroundColor", "F0F0F0",
        "Overlay_TextColor", "000000",
        "Overlay_Text", "麦克风已禁用",
        "Overlay_FontSize", "14",
        "Overlay_ShowIcon", "1"
    )
    
    /**
     * 加载配置文件
     * 如果配置文件不存在，则创建默认配置
     * @returns {Map} 配置数据映射
     */
    static LoadConfig() {
        configPath := AppState.configPath
        
        ; 检查配置文件是否存在
        if !FileExist(configPath) {
            LogInfo("配置文件不存在，创建默认配置")
            this.CreateDefaultConfig()
        }
        
        ; 读取配置
        config := Map()
        
        try {
            ; 读取 [General] 部分
            config["General_Hotkey"] := IniRead(configPath, "General", "Hotkey", this.DefaultConfig["General_Hotkey"])
            config["General_AutoStart"] := IniRead(configPath, "General", "AutoStart", this.DefaultConfig["General_AutoStart"])
            config["General_TargetDevice"] := IniRead(configPath, "General", "TargetDevice", this.DefaultConfig["General_TargetDevice"])
            config["General_TargetDeviceName"] := IniRead(configPath, "General", "TargetDeviceName", "")
            config["General_AdminCheck"] := IniRead(configPath, "General", "AdminCheck", this.DefaultConfig["General_AdminCheck"])
            
            ; 读取 [Overlay] 部分
            config["Overlay_Enabled"] := IniRead(configPath, "Overlay", "Enabled", this.DefaultConfig["Overlay_Enabled"])
            config["Overlay_Position"] := IniRead(configPath, "Overlay", "Position", this.DefaultConfig["Overlay_Position"])
            config["Overlay_OffsetX"] := IniRead(configPath, "Overlay", "OffsetX", this.DefaultConfig["Overlay_OffsetX"])
            config["Overlay_OffsetY"] := IniRead(configPath, "Overlay", "OffsetY", this.DefaultConfig["Overlay_OffsetY"])
            config["Overlay_Transparency"] := IniRead(configPath, "Overlay", "Transparency", this.DefaultConfig["Overlay_Transparency"])
            config["Overlay_BackgroundColor"] := IniRead(configPath, "Overlay", "BackgroundColor", this.DefaultConfig["Overlay_BackgroundColor"])
            config["Overlay_TextColor"] := IniRead(configPath, "Overlay", "TextColor", this.DefaultConfig["Overlay_TextColor"])
            config["Overlay_Text"] := IniRead(configPath, "Overlay", "Text", this.DefaultConfig["Overlay_Text"])
            config["Overlay_FontSize"] := IniRead(configPath, "Overlay", "FontSize", this.DefaultConfig["Overlay_FontSize"])
            config["Overlay_ShowIcon"] := IniRead(configPath, "Overlay", "ShowIcon", this.DefaultConfig["Overlay_ShowIcon"])
            
            ; 验证配置完整性
            if !this.ValidateConfig(config) {
                LogError("配置文件损坏或不完整，将备份并创建默认配置")
                this.HandleCorruptedConfig(configPath)
                
                ; 重新加载默认配置
                config := Map()
                config["General_Hotkey"] := this.DefaultConfig["General_Hotkey"]
                config["General_AutoStart"] := this.DefaultConfig["General_AutoStart"]
                config["General_TargetDevice"] := this.DefaultConfig["General_TargetDevice"]
                config["Overlay_Enabled"] := this.DefaultConfig["Overlay_Enabled"]
                config["Overlay_Position"] := this.DefaultConfig["Overlay_Position"]
                config["Overlay_OffsetX"] := this.DefaultConfig["Overlay_OffsetX"]
                config["Overlay_OffsetY"] := this.DefaultConfig["Overlay_OffsetY"]
                config["Overlay_Transparency"] := this.DefaultConfig["Overlay_Transparency"]
                config["Overlay_BackgroundColor"] := this.DefaultConfig["Overlay_BackgroundColor"]
                config["Overlay_TextColor"] := this.DefaultConfig["Overlay_TextColor"]
                config["Overlay_Text"] := this.DefaultConfig["Overlay_Text"]
                config["Overlay_FontSize"] := this.DefaultConfig["Overlay_FontSize"]
                config["Overlay_ShowIcon"] := this.DefaultConfig["Overlay_ShowIcon"]
            }
            
        } catch as err {
            ; 配置文件读取失败，可能损坏
            LogError("读取配置文件失败: " . err.Message . " - 将备份并创建默认配置")
            this.HandleCorruptedConfig(configPath)
            
            ; 返回默认配置
            config := Map()
            config["General_Hotkey"] := this.DefaultConfig["General_Hotkey"]
            config["General_AutoStart"] := this.DefaultConfig["General_AutoStart"]
            config["General_TargetDevice"] := this.DefaultConfig["General_TargetDevice"]
            config["Overlay_Enabled"] := this.DefaultConfig["Overlay_Enabled"]
            config["Overlay_Position"] := this.DefaultConfig["Overlay_Position"]
            config["Overlay_OffsetX"] := this.DefaultConfig["Overlay_OffsetX"]
            config["Overlay_OffsetY"] := this.DefaultConfig["Overlay_OffsetY"]
            config["Overlay_Transparency"] := this.DefaultConfig["Overlay_Transparency"]
            config["Overlay_BackgroundColor"] := this.DefaultConfig["Overlay_BackgroundColor"]
            config["Overlay_TextColor"] := this.DefaultConfig["Overlay_TextColor"]
            config["Overlay_Text"] := this.DefaultConfig["Overlay_Text"]
            config["Overlay_FontSize"] := this.DefaultConfig["Overlay_FontSize"]
            config["Overlay_ShowIcon"] := this.DefaultConfig["Overlay_ShowIcon"]
        }
        
        return config
    }
    
    /**
     * 处理损坏的配置文件
     * 备份损坏的配置文件并创建新的默认配置
     * @param {String} configPath - 配置文件路径
     */
    static HandleCorruptedConfig(configPath) {
        try {
            ; 生成备份文件名（带时间戳）
            timestamp := FormatTime(, "yyyyMMdd_HHmmss")
            backupPath := configPath . ".backup_" . timestamp
            
            ; 备份损坏的配置文件
            if FileExist(configPath) {
                try {
                    FileCopy(configPath, backupPath, 1)
                    LogInfo("已备份损坏的配置文件到: " . backupPath)
                    
                    ; 删除损坏的配置文件
                    FileDelete(configPath)
                    LogInfo("已删除损坏的配置文件")
                } catch as err {
                    LogError("备份配置文件失败: " . err.Message)
                }
            }
            
            ; 创建新的默认配置
            this.CreateDefaultConfig()
            LogInfo("已创建新的默认配置文件")
            
            ; 显示通知
            TrayTip("配置文件已恢复", "检测到配置文件损坏，已自动恢复为默认配置`n损坏的配置已备份", 3)
            
        } catch as err {
            LogError("处理损坏配置文件失败: " . err.Message)
        }
    }
    
    /**
     * 创建默认配置文件
     */
    static CreateDefaultConfig() {
        configPath := AppState.configPath
        
        ; 创建 [General] 部分
        IniWrite(this.DefaultConfig["General_Hotkey"], configPath, "General", "Hotkey")
        IniWrite(this.DefaultConfig["General_AutoStart"], configPath, "General", "AutoStart")
        IniWrite(this.DefaultConfig["General_TargetDevice"], configPath, "General", "TargetDevice")
        IniWrite(this.DefaultConfig["General_AdminCheck"], configPath, "General", "AdminCheck")
        
        ; 创建 [Overlay] 部分
        IniWrite(this.DefaultConfig["Overlay_Enabled"], configPath, "Overlay", "Enabled")
        IniWrite(this.DefaultConfig["Overlay_Position"], configPath, "Overlay", "Position")
        IniWrite(this.DefaultConfig["Overlay_OffsetX"], configPath, "Overlay", "OffsetX")
        IniWrite(this.DefaultConfig["Overlay_OffsetY"], configPath, "Overlay", "OffsetY")
        IniWrite(this.DefaultConfig["Overlay_Transparency"], configPath, "Overlay", "Transparency")
        IniWrite(this.DefaultConfig["Overlay_BackgroundColor"], configPath, "Overlay", "BackgroundColor")
        IniWrite(this.DefaultConfig["Overlay_TextColor"], configPath, "Overlay", "TextColor")
        IniWrite(this.DefaultConfig["Overlay_Text"], configPath, "Overlay", "Text")
        IniWrite(this.DefaultConfig["Overlay_FontSize"], configPath, "Overlay", "FontSize")
        IniWrite(this.DefaultConfig["Overlay_ShowIcon"], configPath, "Overlay", "ShowIcon")
    }
    
    /**
     * 保存单个配置项
     * @param {String} section - 配置部分名称 (General 或 Overlay)
     * @param {String} key - 配置键名
     * @param {String} value - 配置值
     */
    static SaveConfig(section, key, value) {
        configPath := AppState.configPath
        IniWrite(value, configPath, section, key)
    }
    
    /**
     * 获取配置值
     * @param {Map} config - 配置映射
     * @param {String} key - 配置键名 (格式: Section_Key)
     * @param {String} defaultValue - 默认值
     * @returns {String} 配置值
     */
    static GetConfig(config, key, defaultValue := "") {
        if config.Has(key) {
            return config[key]
        }
        return defaultValue
    }
    
    /**
     * 验证快捷键格式
     * @param {String} hotkey - 快捷键字符串
     * @returns {Boolean} 是否有效
     */
    static ValidateHotkey(hotkey) {
        if (hotkey = "") {
            return false
        }
        
        ; 尝试解析快捷键
        try {
            ; 检查是否包含有效的键名
            ; AHK v2 支持的修饰符: ^(Ctrl), !(Alt), +(Shift), #(Win)
            ; 有效的键包括: F1-F24, A-Z, 0-9 等
            
            ; 基本验证：检查长度和字符
            if (StrLen(hotkey) < 1 || StrLen(hotkey) > 50) {
                return false
            }
            
            ; 检查是否包含无效字符
            if RegExMatch(hotkey, "[<>]") {
                return false
            }
            
            return true
        } catch {
            return false
        }
    }
    
    /**
     * 验证配置完整性
     * @param {Map} config - 配置映射
     * @returns {Boolean} 配置是否有效
     */
    static ValidateConfig(config) {
        ; 验证必需的配置项是否存在
        requiredKeys := [
            "General_Hotkey",
            "Overlay_Enabled",
            "Overlay_Position"
        ]
        
        for key in requiredKeys {
            if !config.Has(key) {
                return false
            }
        }
        
        ; 验证快捷键
        if !this.ValidateHotkey(config["General_Hotkey"]) {
            return false
        }
        
        ; 验证数值范围
        try {
            transparency := Integer(config["Overlay_Transparency"])
            if (transparency < 0 || transparency > 255) {
                return false
            }
            
            fontSize := Integer(config["Overlay_FontSize"])
            if (fontSize < 8 || fontSize > 72) {
                return false
            }
        } catch {
            return false
        }
        
        return true
    }
}

; ============================================================================
; 麦克风控制器 (Microphone Controller)
; ============================================================================

class MicrophoneController {
    
    /**
     * 获取系统中所有可用的麦克风设备
     * @param {Boolean} noFilter - 是否禁用过滤，显示所有设备（默认 false）
     * @returns {Array} 麦克风设备列表，每个元素包含 {id, name}
     */
    static GetAllMicrophones(noFilter := false) {
        devices := []
        foundDevices := Map()  ; 用于去重
        
        try {
            LogInfo("开始枚举麦克风设备..." . (noFilter ? "（无过滤模式）" : ""))
            
            ; 方法 1: 尝试通过数字索引枚举所有设备
            Loop 20 {
                try {
                    deviceName := SoundGetName(, A_Index)
                    if (deviceName != "") {
                        ; 尝试获取静音状态来验证这是一个有效的设备
                        try {
                            SoundGetMute(, A_Index)
                            
                            ; 根据 noFilter 参数决定是否过滤
                            isRecordingDevice := true
                            
                            if (!noFilter) {
                                ; 过滤模式：只排除明确的扬声器关键词（更宽松的过滤）
                                speakerOnlyKeywords := ["扬声器", "Speakers", "Headphones", "耳机"]
                                
                                ; 检查是否是纯扬声器设备
                                for keyword in speakerOnlyKeywords {
                                    if (InStr(deviceName, keyword)) {
                                        isRecordingDevice := false
                                        LogInfo("设备 " . A_Index . " (" . deviceName . ") 被识别为扬声器，跳过")
                                        break
                                    }
                                }
                            }
                            
                            ; 添加设备（包括虚拟设备）
                            if (isRecordingDevice && !foundDevices.Has(deviceName)) {
                                devices.Push({id: String(A_Index), name: deviceName})
                                foundDevices[deviceName] := true
                                LogInfo("✓ 找到设备 " . A_Index . ": " . deviceName)
                            }
                        } catch {
                            ; 无法获取静音状态，跳过
                            continue
                        }
                    }
                } catch {
                    ; 设备不存在，继续
                    continue
                }
            }
            
            ; 方法 2: 尝试常见的设备名称
            commonNames := ["Microphone", "麦克风", "Mic", "Line In", "录音"]
            for name in commonNames {
                try {
                    deviceName := SoundGetName(, name)
                    if (deviceName != "" && !foundDevices.Has(deviceName)) {
                        ; 验证设备可用
                        try {
                            SoundGetMute(, name)
                            devices.Push({id: name, name: deviceName . " (通过名称)"})
                            foundDevices[deviceName] := true
                            LogInfo("通过名称找到设备: " . name . " -> " . deviceName)
                        } catch {
                            LogInfo("设备名称 " . name . " 不支持静音控制")
                        }
                    }
                } catch {
                    ; 设备不存在
                    continue
                }
            }
            
            ; 如果没有找到任何设备，尝试使用第一个可用设备
            if (devices.Length = 0) {
                LogWarning("未找到任何录音设备，尝试使用第一个可用设备")
                try {
                    ; 尝试设备 1
                    testName := SoundGetName(, 1)
                    if (testName != "") {
                        devices.Push({id: "1", name: testName . " (默认)"})
                        LogInfo("使用设备 1 作为默认: " . testName)
                    }
                } catch {
                    LogError("无法访问任何音频设备")
                }
            }
            
            ; 如果仍然没有设备，显示错误
            if (devices.Length = 0) {
                LogError("系统中没有可用的音频设备")
                MsgBox("错误：未找到任何音频设备`n`n请检查：`n1. 音频设备是否已连接`n2. 音频驱动是否已安装`n3. 设备管理器中设备是否正常", "设备错误", "Icon! T10")
            } else {
                LogInfo("共找到 " . devices.Length . " 个可用设备")
            }
            
        } catch as err {
            LogError("获取麦克风设备列表失败: " . err.Message)
        }
        
        return devices
    }
    
    /**
     * 设置要控制的目标麦克风设备
     * @param {String} deviceId - 设备ID（如数字索引 "1", "2" 或设备名称）
     * @returns {Boolean} 是否设置成功
     */
    static SetTargetMicrophone(deviceId) {
        try {
            LogInfo("尝试设置目标麦克风，设备ID: " . deviceId)
            
            ; 如果 deviceId 为空，使用设备 1
            if (deviceId = "") {
                deviceId := "1"
                LogInfo("设备ID为空，使用默认值: 1")
            }
            
            ; 验证设备是否可用
            testName := ""
            try {
                testName := SoundGetName(, deviceId)
                LogInfo("设备名称: " . testName)
            } catch as err {
                LogError("无法获取设备名称 (ID: " . deviceId . "): " . err.Message)
                return false
            }
            
            if (testName = "") {
                LogError("设备名称为空 (ID: " . deviceId . ")")
                return false
            }
            
            ; 验证设备支持静音控制
            try {
                SoundGetMute(, deviceId)
                LogInfo("设备支持静音控制")
            } catch as err {
                LogError("设备不支持静音控制 (ID: " . deviceId . "): " . err.Message)
                return false
            }
            
            ; 保存设备ID和名称到全局状态
            AppState.targetDevice := deviceId
            AppState.targetDeviceName := testName
            
            ; 保存设备ID和名称到配置文件
            ConfigManager.SaveConfig("General", "TargetDevice", deviceId)
            ConfigManager.SaveConfig("General", "TargetDeviceName", testName)
            
            LogInfo("✓ 目标麦克风已设置: " . testName . " (ID: " . deviceId . ")")
            return true
            
        } catch as err {
            LogError("设置目标麦克风失败: " . err.Message)
            return false
        }
    }
    
    /**
     * 查找设备ID（通过设备名称）
     * 如果设备顺序变化，通过名称重新查找设备
     * @param {String} deviceName - 设备名称
     * @returns {String} 设备ID，如果未找到返回空字符串
     */
    static FindDeviceByName(deviceName) {
        try {
            LogInfo("通过名称查找设备: " . deviceName)
            
            ; 枚举所有设备
            Loop 30 {
                try {
                    name := SoundGetName(, A_Index)
                    if (name = deviceName) {
                        LogInfo("✓ 找到设备: " . deviceName . " (新ID: " . A_Index . ")")
                        return String(A_Index)
                    }
                } catch {
                    break
                }
            }
            
            LogWarning("未找到设备: " . deviceName)
            return ""
            
        } catch as err {
            LogError("查找设备失败: " . err.Message)
            return ""
        }
    }
    
    /**
     * 获取当前目标麦克风的静音状态
     * @returns {Boolean} true=未静音(启用), false=已静音(禁用)
     */
    static GetMicrophoneState() {
        try {
            deviceId := AppState.targetDevice
            
            ; 如果 deviceId 为空，使用默认值
            if (deviceId = "") {
                deviceId := "1"
                LogWarning("设备ID为空，使用默认值: 1")
            }
            
            ; 获取静音状态
            ; SoundGetMute 返回 1 表示静音，0 表示未静音
            isMuted := SoundGetMute(, deviceId)
            
            ; 返回启用状态（与静音状态相反）
            return !isMuted
            
        } catch as err {
            LogError("获取麦克风状态失败 (设备ID: " . deviceId . "): " . err.Message)
            ; 默认返回 true（假设未静音）
            return true
        }
    }
    
    /**
     * 设置目标麦克风的静音状态
     * @param {Boolean} enabled - true=启用(取消静音), false=禁用(静音)
     * @returns {Boolean} 是否设置成功
     */
    static SetMicrophoneState(enabled) {
        try {
            deviceId := AppState.targetDevice
            
            ; 如果 deviceId 为空，使用默认值
            if (deviceId = "") {
                deviceId := "1"
                LogWarning("设备ID为空，使用默认值: 1")
            }
            
            ; 检查设备是否可用
            if !this.IsMicrophoneAvailable() {
                LogError("无法设置麦克风状态: 设备不可用 (ID: " . deviceId . ")")
                return false
            }
            
            ; 设置静音状态（enabled=true 表示取消静音，即 mute=0）
            muteValue := enabled ? 0 : 1
            SoundSetMute(muteValue, , deviceId)
            
            ; 更新全局状态
            AppState.microphoneEnabled := enabled
            
            LogInfo("✓ 麦克风状态已设置: " . (enabled ? "启用" : "禁用") . " (设备ID: " . deviceId . ")")
            return true
            
        } catch as err {
            LogError("设置麦克风状态失败 (设备ID: " . deviceId . "): " . err.Message)
            return false
        }
    }
    
    /**
     * 切换目标麦克风的状态
     * @returns {Boolean} 切换后的状态 (true=启用, false=禁用)
     */
    static ToggleMicrophone() {
        try {
            ; 检查设备是否可用
            if !this.IsMicrophoneAvailable() {
                LogError("麦克风设备不可用，无法切换")
                this.HandleDeviceUnavailable()
                return this.GetMicrophoneState()
            }
            
            ; 获取当前状态
            currentState := this.GetMicrophoneState()
            
            ; 切换到相反状态
            newState := !currentState
            
            ; 设置新状态
            if this.SetMicrophoneState(newState) {
                LogInfo("麦克风已切换: " . (newState ? "启用" : "禁用"))
                return newState
            } else {
                LogError("麦克风切换失败")
                this.HandleDeviceUnavailable()
                return currentState
            }
            
        } catch as err {
            LogError("切换麦克风失败: " . err.Message)
            this.HandleDeviceUnavailable()
            return this.GetMicrophoneState()
        }
    }
    
    /**
     * 处理麦克风设备不可用错误
     * 显示托盘通知并记录错误
     */
    static HandleDeviceUnavailable() {
        try {
            LogError("麦克风设备不可用")
            
            ; 显示托盘通知
            TrayTip("麦克风设备不可用", "无法访问麦克风设备，请检查：`n1. 设备是否已连接`n2. 设备是否被其他程序占用`n3. 音频驱动是否正常", 3)
            
            ; 可选：播放系统错误声音
            try {
                SoundBeep(500, 200)
            } catch {
                ; 忽略声音播放错误
            }
            
        } catch as err {
            LogError("处理设备不可用错误失败: " . err.Message)
        }
    }
    
    /**
     * 检查目标麦克风设备是否可用
     * 同时验证设备ID和设备名称是否匹配，确保设备未被更换
     * @param {Boolean} showWarning - 是否显示警告（默认 false）
     * @returns {Boolean} 设备是否可用
     */
    static IsMicrophoneAvailable(showWarning := false) {
        try {
            deviceId := AppState.targetDevice
            expectedDeviceName := AppState.targetDeviceName
            
            ; 如果 deviceId 为空，使用默认值
            if (deviceId = "") {
                deviceId := "1"
            }
            
            ; 尝试获取当前ID对应的设备名称
            currentDeviceName := ""
            try {
                currentDeviceName := SoundGetName(, deviceId)
            } catch {
                ; 设备ID无效
                LogInfo("设备ID " . deviceId . " 无效或设备已断开")
            }
            
            ; 情况1: 无法获取设备名称（设备已断开或ID无效）
            if (currentDeviceName = "") {
                ; 尝试通过名称查找设备
                if (expectedDeviceName != "") {
                    LogInfo("设备ID " . deviceId . " 无效，尝试通过名称查找: " . expectedDeviceName)
                    newId := this.FindDeviceByName(expectedDeviceName)
                    if (newId != "") {
                        ; 找到设备，更新设备ID
                        AppState.targetDevice := newId
                        ConfigManager.SaveConfig("General", "TargetDevice", newId)
                        deviceId := newId
                        currentDeviceName := expectedDeviceName
                        LogInfo("✓ 设备ID已自动更新: " . deviceId . " → " . newId)
                        
                        ; 发送通知提醒用户
                        try {
                            TrayTip("设备ID已更新", "设备 '" . expectedDeviceName . "' 的ID已自动更新`n`n旧ID: " . deviceId . "`n新ID: " . newId . "`n`n设备功能正常", "Iconi")
                            LogInfo("已发送设备ID更新通知")
                        } catch as err {
                            LogError("发送通知失败: " . err.Message)
                        }
                    } else {
                        ; 找不到设备，设备已断开
                        LogWarning("设备已断开: " . expectedDeviceName)
                        
                        ; 立即更新托盘图标为灰色（设备不可用）
                        if (IsSet(TrayManager)) {
                            TrayManager.UpdateTrayIconUnavailable()
                        }
                        
                        ; 只在showWarning=true时显示通知（避免重复通知）
                        if (showWarning) {
                            TrayTip("麦克风设备不可用", "设备已断开: " . expectedDeviceName . "`n`n请重新连接设备或从托盘菜单选择新设备", 5)
                        }
                        
                        return false
                    }
                } else {
                    ; 没有保存的设备名称，无法验证
                    return false
                }
            }
            
            ; 情况2: 获取到设备名称，但需要验证是否与预期匹配
            if (currentDeviceName != "") {
                ; 如果有保存的设备名称，验证是否匹配
                if (expectedDeviceName != "" && currentDeviceName != expectedDeviceName) {
                    ; 设备名称不匹配，说明设备ID指向了其他设备
                    LogWarning("设备名称不匹配 - 预期: " . expectedDeviceName . ", 实际: " . currentDeviceName)
                    
                    ; 尝试通过名称查找正确的设备
                    newId := this.FindDeviceByName(expectedDeviceName)
                    if (newId != "") {
                        ; 找到正确的设备，更新ID
                        AppState.targetDevice := newId
                        ConfigManager.SaveConfig("General", "TargetDevice", newId)
                        LogInfo("✓ 设备ID已更新: " . newId . " (名称匹配)")
                        
                        ; 验证新ID的设备支持静音控制
                        try {
                            SoundGetMute(, newId)
                            return true
                        } catch {
                            LogWarning("设备 " . newId . " 不支持静音控制")
                            if (showWarning) {
                                TrayTip("设备不支持静音控制", "设备 " . expectedDeviceName . " 不支持静音控制功能", 3)
                            }
                            return false
                        }
                    } else {
                        ; 找不到预期的设备，设备已断开或被禁用
                        LogWarning("设备已断开或被禁用: " . expectedDeviceName)
                        
                        ; 立即更新托盘图标为灰色（设备不可用）
                        if (IsSet(TrayManager)) {
                            TrayManager.UpdateTrayIconUnavailable()
                        }
                        
                        ; 只在showWarning=true时显示通知（避免重复通知）
                        if (showWarning) {
                            TrayTip("麦克风设备不可用", "设备已断开或被禁用: " . expectedDeviceName . "`n`n请重新连接设备或从托盘菜单选择新设备", 5)
                        }
                        
                        return false
                    }
                }
                
                ; 设备名称匹配或没有保存的名称，验证设备支持静音控制
                try {
                    SoundGetMute(, deviceId)
                    return true
                } catch {
                    LogWarning("设备 " . deviceId . " 不支持静音控制")
                    if (showWarning) {
                        TrayTip("设备不支持静音控制", "设备 " . currentDeviceName . " 不支持静音控制功能", 3)
                    }
                    return false
                }
            }
            
            return false
            
        } catch as err {
            ; 发生异常说明设备不可用
            LogError("检查设备可用性失败: " . err.Message)
            return false
        }
    }
}

; ============================================================================
; 设备选择对话框 (Device Selector Dialog)
; ============================================================================

class DeviceSelector {
    
    static selectedDeviceId := ""
    static deviceSelectorGui := ""
    
    /**
     * 显示设备选择对话框
     * @returns {String} 选中的设备ID，如果取消则返回空字符串
     */
    static ShowDeviceSelector() {
        ; 获取所有可用的麦克风设备（默认启用过滤）
        devices := MicrophoneController.GetAllMicrophones(false)
        
        if (devices.Length = 0) {
            MsgBox("未找到可用的麦克风设备！", "错误", "Icon!")
            return ""
        }
        
        ; 创建 GUI 窗口
        this.deviceSelectorGui := Gui("+AlwaysOnTop", "选择麦克风设备")
        this.deviceSelectorGui.SetFont("s10", "Microsoft YaHei")
        
        ; 添加说明文本
        this.deviceSelectorGui.Add("Text", "w500", "请选择要控制的麦克风设备(列表中可能包含扬声器)：")
        this.deviceSelectorGui.Add("Text", "w500 y+5", "")
        
        ; 创建设备列表框
        deviceNames := []
        for device in devices {
            ; 格式化设备名称显示：[ID] 设备名称
            displayName := "[" . device.id . "] " . device.name
            deviceNames.Push(displayName)
        }
        
        ; 添加列表框
        deviceListBox := this.deviceSelectorGui.Add("ListBox", "w500 h200 vDeviceList", deviceNames)
        
        ; 默认选中第一个设备
        deviceListBox.Choose(1)
        
        ; 添加复选框：显示所有设备（禁用过滤）
        this.deviceSelectorGui.Add("Text", "w500 y+10", "")
        showAllCheckbox := this.deviceSelectorGui.Add("Checkbox", "w500 vShowAll", "显示所有设备（包括扬声器）")
        
        ; 绑定复选框事件
        showAllCheckbox.OnEvent("Click", (*) => this.OnShowAllToggle())
        
        ; 添加按钮
        this.deviceSelectorGui.Add("Text", "w500 y+10", "")
        btnConfirm := this.deviceSelectorGui.Add("Button", "w120 h30", "确定")
        btnCancel := this.deviceSelectorGui.Add("Button", "w120 h30 x+10", "取消")
        
        ; 存储设备列表供回调使用
        this.deviceSelectorGui.devices := devices
        this.deviceSelectorGui.deviceListBox := deviceListBox
        this.selectedDeviceId := ""
        
        ; 绑定按钮事件
        btnConfirm.OnEvent("Click", (*) => this.OnConfirmClick())
        btnCancel.OnEvent("Click", (*) => this.OnCancelClick())
        
        ; 绑定窗口关闭事件
        this.deviceSelectorGui.OnEvent("Close", (*) => this.OnCancelClick())
        
        ; 显示窗口（模态）
        this.deviceSelectorGui.Show()
        
        ; 保存窗口句柄
        guiHwnd := this.deviceSelectorGui.Hwnd
        
        ; 等待用户选择（通过循环检查窗口是否关闭）
        while WinExist("ahk_id " . guiHwnd) {
            Sleep(100)
        }
        
        LogInfo("设备选择对话框已关闭，选择的设备ID: " . this.selectedDeviceId)
        return this.selectedDeviceId
    }
    
    /**
     * 处理"显示所有设备"复选框切换事件
     */
    static OnShowAllToggle() {
        try {
            ; 获取复选框状态
            showAll := this.deviceSelectorGui["ShowAll"].Value
            
            LogInfo("用户切换显示模式: " . (showAll ? "显示所有设备" : "仅显示录音设备"))
            
            ; 重新获取设备列表
            devices := MicrophoneController.GetAllMicrophones(showAll)
            
            if (devices.Length = 0) {
                MsgBox("未找到任何音频设备！", "提示", "Iconi")
                ; 恢复复选框状态
                this.deviceSelectorGui["ShowAll"].Value := 0
                return
            }
            
            ; 更新设备列表
            deviceNames := []
            for device in devices {
                ; 格式化设备名称显示：[ID] 设备名称
                displayName := "[" . device.id . "] " . device.name
                deviceNames.Push(displayName)
            }
            
            ; 更新列表框内容
            deviceListBox := this.deviceSelectorGui.deviceListBox
            deviceListBox.Delete()  ; 清空列表
            deviceListBox.Add(deviceNames)  ; 添加新列表
            deviceListBox.Choose(1)  ; 选中第一个
            
            ; 更新存储的设备列表
            this.deviceSelectorGui.devices := devices
            
            LogInfo("设备列表已更新，共 " . devices.Length . " 个设备")
            
        } catch as err {
            LogError("切换显示模式失败: " . err.Message)
            MsgBox("切换显示模式失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 确定按钮点击事件处理
     */
    static OnConfirmClick() {
        try {
            ; 获取选中的设备索引
            selectedIndex := this.deviceSelectorGui["DeviceList"].Value
            
            if (selectedIndex = 0) {
                MsgBox("请选择一个设备！", "提示", "Icon!")
                return
            }
            
            ; 获取选中的设备
            devices := this.deviceSelectorGui.devices
            selectedDevice := devices[selectedIndex]
            
            ; 保存选中的设备ID
            this.selectedDeviceId := selectedDevice.id
            
            ; 设置目标麦克风
            if MicrophoneController.SetTargetMicrophone(this.selectedDeviceId) {
                LogInfo("✓ 用户选择了设备: " . selectedDevice.name)
                
                ; 关闭窗口并清空引用
                try {
                    this.deviceSelectorGui.Destroy()
                } catch {
                    ; 忽略销毁错误
                }
                this.deviceSelectorGui := ""
            } else {
                MsgBox("设置目标麦克风失败，请重试！", "错误", "Icon! +AlwaysOnTop")
            }
            
        } catch as err {
            LogError("设备选择确认失败: " . err.Message)
            MsgBox("发生错误: " . err.Message, "错误", "Icon! +AlwaysOnTop")
        }
    }
    
    /**
     * 取消按钮点击事件处理
     */
    static OnCancelClick() {
        ; 清空选择
        this.selectedDeviceId := ""
        
        ; 关闭窗口并清空引用
        if (this.deviceSelectorGui != "") {
            try {
                this.deviceSelectorGui.Destroy()
            } catch {
                ; 忽略销毁错误
            }
            this.deviceSelectorGui := ""
        }
    }
    
    /**
     * 检查是否需要显示设备选择对话框（首次运行检测）
     * @param {Map} config - 配置映射
     * @returns {Boolean} 是否需要显示对话框
     */
    static ShouldShowDeviceSelector(config) {
        ; 检查配置中是否有目标设备
        targetDevice := ConfigManager.GetConfig(config, "General_TargetDevice", "")
        
        ; 如果目标设备为空，说明是首次运行
        if (targetDevice = "") {
            return true
        }
        
        ; 检查目标设备是否可用
        AppState.targetDevice := targetDevice
        if !MicrophoneController.IsMicrophoneAvailable() {
            LogWarning("配置的目标设备不可用，需要重新选择")
            return true
        }
        
        return false
    }
    
    /**
     * 首次运行检测并显示设备选择对话框
     * @param {Map} config - 配置映射
     * @returns {Boolean} 是否成功选择了设备
     */
    static CheckAndShowDeviceSelector(config) {
        if this.ShouldShowDeviceSelector(config) {
            LogInfo("首次运行或设备不可用，显示设备选择对话框")
            
            ; 显示设备选择对话框
            selectedDeviceId := this.ShowDeviceSelector()
            
            ; 检查是否选择了设备
            if (selectedDeviceId = "" && selectedDeviceId != 0) {
                ; 用户取消了选择
                LogWarning("用户取消了设备选择")
                return false
            }
            
            ; 更新配置（设备名称已在 SetTargetMicrophone 中保存）
            config["General_TargetDevice"] := selectedDeviceId
            config["General_TargetDeviceName"] := AppState.targetDeviceName
            
            LogInfo("设备选择完成，设备ID: " . selectedDeviceId . ", 名称: " . AppState.targetDeviceName)
            
            ; 标记首次启动，稍后在初始化完成后打开设置界面
            AppState.firstRun := true
            
            return true
        }
        
        ; 不需要显示对话框，直接使用配置的设备
        ; 注意：配置文件中的键名格式为 Section_Key，例如 General_TargetDevice
        targetDevice := ""
        targetDeviceName := ""
        
        ; 尝试从配置中读取设备信息
        if config.Has("General_TargetDevice") {
            targetDevice := config["General_TargetDevice"]
        }
        if config.Has("General_TargetDeviceName") {
            targetDeviceName := config["General_TargetDeviceName"]
        }
        
        ; 如果配置为空，使用默认值（设备 1）
        if (targetDevice = "") {
            targetDevice := "1"
            LogInfo("配置中无设备ID，使用默认值: 1")
        }
        
        AppState.targetDevice := targetDevice
        AppState.targetDeviceName := targetDeviceName
        LogInfo("使用配置的设备ID: " . targetDevice . ", 名称: " . targetDeviceName)
        return true
    }
}

; ============================================================================
; 托盘管理器 (Tray Manager)
; ============================================================================

class TrayManager {
    
    static trayMenu := ""
    static menuItemStatus := ""
    static menuItemToggle := ""
    static menuItemSelectDevice := ""
    static menuItemSettings := ""
    static menuItemAutoStart := ""
    static menuItemExit := ""
    
    /**
     * 创建系统托盘图标和菜单
     */
    static CreateTray() {
        try {
            ; 设置托盘图标提示文本
            A_IconTip := "麦克风快捷控制工具"
            
            ; 创建托盘菜单
            this.trayMenu := A_TrayMenu
            
            ; 清空默认菜单项
            this.trayMenu.Delete()
            
            ; 添加状态显示项（不可点击）- 使用空函数作为回调
            this.menuItemStatus := this.trayMenu.Add("● 麦克风: 已启用", (*) => "")
            this.trayMenu.Disable("● 麦克风: 已启用")
            
            ; 添加分隔线
            this.trayMenu.Add()
            
            ; 添加切换麦克风菜单项
            this.menuItemToggle := this.trayMenu.Add("切换麦克风", (*) => this.OnToggleMicrophone())
            
            ; 添加选择设备菜单项
            this.menuItemSelectDevice := this.trayMenu.Add("选择设备...", (*) => this.OnSelectDevice())
            
            ; 添加设置菜单项
            this.menuItemSettings := this.trayMenu.Add("设置...", (*) => this.OnOpenSettings())
            
            ; 添加查看日志菜单项
            this.trayMenu.Add("查看日志...", (*) => this.OnViewLog())
            
            ; 添加开机启动菜单项（带复选框）
            this.menuItemAutoStart := this.trayMenu.Add("开机启动", (*) => this.OnToggleAutoStart())
            
            ; 根据配置设置开机启动复选框状态
            config := ConfigManager.LoadConfig()
            autoStart := ConfigManager.GetConfig(config, "General_AutoStart", "0")
            if (autoStart = "1") {
                this.trayMenu.Check("开机启动")
            }
            
            ; 添加分隔线
            this.trayMenu.Add()
            
            ; 添加关于菜单项
            this.trayMenu.Add("关于...", (*) => this.OnAbout())
            
            ; 添加退出菜单项
            this.menuItemExit := this.trayMenu.Add("退出", (*) => this.OnExit())
            
            ; 设置托盘图标左键点击事件
            A_TrayMenu.Default := ""  ; 清除默认双击行为
            
            ; 注册托盘图标点击事件
            ; 在 AHK v2 中，使用 OnMessage 监听托盘图标点击
            OnMessage(0x404, TrayIconClick)
            
            ; 初始化托盘图标
            this.UpdateTrayIcon(AppState.microphoneEnabled)
            
            LogInfo("托盘管理器已创建")
            
        } catch as err {
            LogError("创建托盘失败: " . err.Message)
        }
    }
    
    /**
     * 根据麦克风状态更新托盘图标
     * @param {Boolean} micEnabled - 麦克风是否启用
     */
    static UpdateTrayIcon(micEnabled) {
        try {
            ; 使用 ResourceManager 获取图标路径
            iconName := micEnabled ? "enabled" : "disabled"
            iconPath := ResourceManager.GetIconPath(iconName)
            
            if (iconPath != "" && FileExist(iconPath)) {
                TraySetIcon(iconPath)
                A_IconTip := "麦克风快捷控制工具 - " . (micEnabled ? "已启用" : "已禁用")
            } else {
                ; 使用系统默认图标
                iconIndex := micEnabled ? 222 : 221
                TraySetIcon("Shell32.dll", iconIndex)
                A_IconTip := "麦克风快捷控制工具 - " . (micEnabled ? "已启用" : "已禁用")
            }
            
            LogInfo("托盘图标已更新: " . (micEnabled ? "启用" : "禁用"))
            
        } catch as err {
            LogError("更新托盘图标失败: " . err.Message)
        }
    }
    
    /**
     * 更新托盘图标为设备不可用状态（灰色麦克风+圆圈叉号）
     */
    static UpdateTrayIconUnavailable() {
        try {
            ; 使用 ResourceManager 获取图标路径
            iconPath := ResourceManager.GetIconPath("unavailable")
            
            if (iconPath != "" && FileExist(iconPath)) {
                TraySetIcon(iconPath)
            } else {
                ; 如果自定义图标不存在，使用系统图标
                TraySetIcon("Shell32.dll", 220)
            }
            
            A_IconTip := "麦克风快捷控制工具 - 设备不可用"
            
            LogInfo("托盘图标已更新: 设备不可用")
            
        } catch as err {
            LogError("更新托盘图标（不可用）失败: " . err.Message)
        }
    }
    
    /**
     * 更新托盘菜单中的状态文本
     * @param {Boolean} micEnabled - 麦克风是否启用
     */
    static UpdateTrayMenu(micEnabled) {
        try {
            ; 更新状态显示文本
            statusText := "● 麦克风: " . (micEnabled ? "已启用" : "已禁用")
            
            ; 删除旧的状态项
            try {
                this.trayMenu.Delete("● 麦克风: 已启用")
            } catch {
                ; 忽略删除错误
            }
            try {
                this.trayMenu.Delete("● 麦克风: 已禁用")
            } catch {
                ; 忽略删除错误
            }
            
            ; 在第一个位置添加新的状态项（使用空函数作为回调）
            this.trayMenu.Insert("1&", statusText, (*) => "")
            this.trayMenu.Disable(statusText)
            
            LogInfo("托盘菜单已更新: " . statusText)
            
        } catch as err {
            LogError("更新托盘菜单失败: " . err.Message)
        }
    }
    
    /**
     * 处理切换麦克风菜单项点击
     */
    static OnToggleMicrophone() {
        try {
            LogInfo("用户从托盘菜单点击切换麦克风")
            
            ; 调用应用程序控制器的切换函数
            if (IsSet(AppController)) {
                AppController.OnMicrophoneToggle()
            } else {
                ; 如果控制器未初始化，直接切换
                newState := MicrophoneController.ToggleMicrophone()
                this.UpdateTrayIcon(newState)
                this.UpdateTrayMenu(newState)
            }
            
        } catch as err {
            LogError("切换麦克风失败: " . err.Message)
            MsgBox("切换麦克风失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 处理选择设备菜单项点击
     */
    static OnSelectDevice() {
        try {
            LogInfo("用户从托盘菜单点击选择设备")
            
            ; 显示设备选择对话框
            selectedDeviceId := DeviceSelector.ShowDeviceSelector()
            
            if (selectedDeviceId != "") {
                ; 更新全局状态
                AppState.targetDevice := selectedDeviceId
                
                ; 获取当前麦克风状态并更新UI
                currentState := MicrophoneController.GetMicrophoneState()
                AppState.microphoneEnabled := currentState
                
                this.UpdateTrayIcon(currentState)
                this.UpdateTrayMenu(currentState)
                
                MsgBox("设备已更新！", "成功", "Iconi")
            }
            
        } catch as err {
            LogError("选择设备失败: " . err.Message)
            MsgBox("选择设备失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 处理设置菜单项点击
     */
    static OnOpenSettings() {
        try {
            LogInfo("用户从托盘菜单点击设置")
            
            ; 显示图形化设置对话框
            if (IsSet(SettingsDialog)) {
                SettingsDialog.ShowSettings()
            } else {
                ; 如果设置对话框类不可用，打开配置文件
                configPath := AppState.configPath
                
                if FileExist(configPath) {
                    Run(configPath)
                } else {
                    MsgBox("配置文件不存在！", "错误", "Icon!")
                }
            }
            
        } catch as err {
            LogError("打开设置失败: " . err.Message)
            MsgBox("打开设置失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 处理查看日志菜单项点击
     */
    static OnViewLog() {
        try {
            LogInfo("用户从托盘菜单点击查看日志")
            
            ; 获取日志文件路径
            logPath := GetLogFilePath()
            
            if FileExist(logPath) {
                ; 打开日志文件
                Run(logPath)
            } else {
                MsgBox("日志文件不存在！`n`n日志文件将在应用程序运行时自动创建。", "提示", "Iconi")
            }
            
        } catch as err {
            LogError("打开日志失败: " . err.Message)
            MsgBox("打开日志失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 处理开机启动菜单项点击
     */
    static OnToggleAutoStart() {
        try {
            LogInfo("用户从托盘菜单点击开机启动")
            
            ; 获取当前自动启动状态
            config := ConfigManager.LoadConfig()
            currentAutoStart := ConfigManager.GetConfig(config, "General_AutoStart", "0")
            
            ; 切换状态
            newAutoStart := (currentAutoStart = "1") ? "0" : "1"
            
            ; 调用应用程序控制器设置自动启动
            success := false
            if (IsSet(AppController)) {
                success := AppController.SetAutoStart(newAutoStart = "1", true)
            }
            
            ; 只有成功时才更新菜单复选框
            if (success || newAutoStart = "0") {
                ; 禁用总是成功的，启用需要检查
                if (newAutoStart = "1") {
                    this.trayMenu.Check("开机启动")
                } else {
                    this.trayMenu.Uncheck("开机启动")
                }
                
                ; 记录状态更新
                statusMsg := (newAutoStart = "1") ? "已启用开机自动启动" : "已禁用开机自动启动"
                LogInfo("开机启动状态已更新: " . statusMsg)
            } else {
                ; 设置失败，保持原状态
                LogWarning("开机启动设置失败，保持原状态")
            }
            
        } catch as err {
            LogError("切换开机启动失败: " . err.Message)
            MsgBox("切换开机启动失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 处理关于菜单项点击
     */
    static OnAbout() {
        try {
            LogInfo("用户从托盘菜单点击关于")
            
            ; 创建关于对话框
            aboutGui := Gui("", "关于 " . AppVersion.name)
            aboutGui.SetFont("s10", "Microsoft YaHei")
            
            ; 添加标题
            aboutGui.SetFont("s14 bold")
            aboutGui.Add("Text", "w350 Center", AppVersion.name)
            
            ; 添加版本信息
            aboutGui.SetFont("s10")
            aboutGui.Add("Text", "w350 y+20", "版本: " . AppVersion.fullVersion)
            aboutGui.Add("Text", "w350", "发布日期: " . AppVersion.releaseDate)
            
            ; 添加构建信息
            aboutGui.SetFont("s9")
            aboutGui.Add("Text", "w350 y+10", "构建时间: " . AppVersion.buildTime . " UTC")
            aboutGui.Add("Text", "w350", "构建编号: #" . AppVersion.buildNumber)
            
            ; 添加描述
            aboutGui.SetFont("s10")
            aboutGui.Add("Text", "w350 y+15", "轻量级 Windows 麦克风快捷控制工具")
            
            ; 添加 GitHub 链接
            aboutGui.Add("Text", "w350 y+15", "GitHub 项目:")
            githubLink := aboutGui.Add("Link", "w350", '<a href="https://github.com/' . AppVersion.githubRepo . '">https://github.com/' . AppVersion.githubRepo . '</a>')
            
            ; 添加按钮区域
            aboutGui.Add("Text", "w350 y+15", "")
            
            ; 检查更新按钮
            btnCheckUpdate := aboutGui.Add("Button", "x75 w100 h30", "检查更新")
            btnCheckUpdate.OnEvent("Click", (*) => this.CheckForUpdates(aboutGui))
            
            ; 关闭按钮
            btnClose := aboutGui.Add("Button", "x+10 w100 h30", "关闭")
            btnClose.OnEvent("Click", (*) => aboutGui.Destroy())
            
            ; 绑定窗口关闭事件
            aboutGui.OnEvent("Close", (*) => aboutGui.Destroy())
            
            ; 显示窗口
            aboutGui.Show()
            
        } catch as err {
            LogError("显示关于对话框失败: " . err.Message)
            MsgBox("显示关于对话框失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 检查更新
     */
    static CheckForUpdates(parentGui := "") {
        try {
            LogInfo("检查更新...")
            
            ; 获取最新版本信息
            apiUrl := "https://api.github.com/repos/" . AppVersion.githubRepo . "/releases/latest"
            
            ; 使用 ComObject 发送 HTTP 请求
            http := ComObject("WinHttp.WinHttpRequest.5.1")
            http.Open("GET", apiUrl, false)
            http.SetRequestHeader("User-Agent", "MicToggleTool")
            http.Send()
            
            if (http.Status != 200) {
                throw Error("无法连接到 GitHub API")
            }
            
            ; 解析 JSON 响应
            response := http.ResponseText
            
            ; 提取版本号和构建编号
            latestVersion := ""
            latestBuildNumber := ""
            
            if (RegExMatch(response, '"tag_name"\s*:\s*"v?([^"]+)"', &versionMatch)) {
                latestVersion := versionMatch[1]
            }
            
            ; 从 body 中提取构建编号
            ; JSON 中的 body 包含转义的换行符和星号，需要匹配 \*\*构建编号\*\*: #数字
            if (RegExMatch(response, '构建编号[*\s]*:\s*#(\d+)', &buildMatch)) {
                latestBuildNumber := buildMatch[1]
            }
            
            if (latestVersion = "") {
                throw Error("无法解析版本信息")
            }
            
            currentVersion := AppVersion.fullVersion
            currentBuildNumber := AppVersion.buildNumber
            
            LogInfo("当前版本: " . currentVersion . " (构建 #" . currentBuildNumber . ")")
            LogInfo("最新版本: " . latestVersion . " (构建 #" . latestBuildNumber . ")")
            
            ; 先比较版本号，再比较构建编号
            versionCompare := this.CompareVersions(currentVersion, latestVersion)
            hasUpdate := false
            updateMessage := ""
            
            if (versionCompare < 0) {
                ; 版本号更新
                hasUpdate := true
                updateMessage := "发现新版本 v" . latestVersion . "`n`n"
                    . "当前版本: v" . currentVersion . " (构建 #" . currentBuildNumber . ")`n"
                    . "最新版本: v" . latestVersion . " (构建 #" . latestBuildNumber . ")`n`n"
                    . "是否前往下载页面？"
            } else if (versionCompare = 0 && latestBuildNumber != "" && currentBuildNumber != "") {
                ; 版本号相同，比较构建编号
                if (Integer(currentBuildNumber) < Integer(latestBuildNumber)) {
                    hasUpdate := true
                    updateMessage := "发现同版本的新构建 v" . latestVersion . "`n`n"
                        . "当前构建: #" . currentBuildNumber . "`n"
                        . "最新构建: #" . latestBuildNumber . "`n`n"
                        . "该版本已更新，建议重新下载。`n`n"
                        . "是否前往下载页面？"
                }
            }
            
            if (hasUpdate) {
                result := MsgBox(updateMessage, "发现更新", "YesNo Icon!")
                
                if (result = "Yes") {
                    Run("https://github.com/" . AppVersion.githubRepo . "/releases/latest")
                }
            } else {
                ; 已是最新版本
                MsgBox(
                    "您已经在使用最新版本`n`n"
                    . "版本: v" . currentVersion . "`n"
                    . "构建: #" . currentBuildNumber,
                    "检查更新",
                    "Iconi"
                )
            }
            
        } catch as err {
            LogError("检查更新失败: " . err.Message)
            MsgBox("检查更新失败: " . err.Message . "`n`n请检查网络连接或稍后重试。", "错误", "Icon!")
        }
    }
    
    /**
     * 比较版本号
     * @param {String} v1 - 版本号1
     * @param {String} v2 - 版本号2
     * @returns {Integer} -1: v1 < v2, 0: v1 = v2, 1: v1 > v2
     */
    static CompareVersions(v1, v2) {
        ; 移除 'v' 前缀
        v1 := RegExReplace(v1, "^v", "")
        v2 := RegExReplace(v2, "^v", "")
        
        ; 分割版本号
        parts1 := StrSplit(v1, ".")
        parts2 := StrSplit(v2, ".")
        
        ; 比较每个部分
        maxLen := Max(parts1.Length, parts2.Length)
        Loop maxLen {
            p1 := (A_Index <= parts1.Length) ? Integer(parts1[A_Index]) : 0
            p2 := (A_Index <= parts2.Length) ? Integer(parts2[A_Index]) : 0
            
            if (p1 < p2) {
                return -1
            } else if (p1 > p2) {
                return 1
            }
        }
        
        return 0
    }
    
    /**
     * 自动检查更新（后台静默检查）
     */
    static AutoCheckForUpdates() {
        try {
            ; 检查是否启用自动检查
            if (ConfigManager.GetConfig(AppController.config, "General_AutoCheckUpdate", "1") != "1") {
                return
            }
            
            isSilent := ConfigManager.GetConfig(AppController.config, "General_AutoCheckUpdateSilent", "1") = "1"
            
            LogInfo("自动检查更新..." . (isSilent ? " (静默模式)" : ""))
            
            ; 获取最新版本信息
            apiUrl := "https://api.github.com/repos/" . AppVersion.githubRepo . "/releases/latest"
            
            ; 使用 ComObject 发送 HTTP 请求
            http := ComObject("WinHttp.WinHttpRequest.5.1")
            http.Open("GET", apiUrl, false)
            http.SetRequestHeader("User-Agent", "MicToggleTool")
            http.Send()
            
            if (http.Status != 200) {
                if (!isSilent) {
                    throw Error("无法连接到 GitHub API")
                }
                return
            }
            
            ; 解析 JSON 响应
            response := http.ResponseText
            
            ; 提取版本号和构建编号
            latestVersion := ""
            latestBuildNumber := ""
            
            if (RegExMatch(response, '"tag_name"\s*:\s*"v?([^"]+)"', &versionMatch)) {
                latestVersion := versionMatch[1]
            }
            
            if (RegExMatch(response, '构建编号[*\s]*:\s*#(\d+)', &buildMatch)) {
                latestBuildNumber := buildMatch[1]
            }
            
            if (latestVersion = "") {
                if (!isSilent) {
                    throw Error("无法解析版本信息")
                }
                return
            }
            
            currentVersion := AppVersion.fullVersion
            currentBuildNumber := AppVersion.buildNumber
            
            ; 比较版本号
            versionCompare := this.CompareVersions(currentVersion, latestVersion)
            hasUpdate := false
            
            if (versionCompare < 0) {
                hasUpdate := true
            } else if (versionCompare = 0 && latestBuildNumber != "" && currentBuildNumber != "") {
                if (Integer(currentBuildNumber) < Integer(latestBuildNumber)) {
                    hasUpdate := true
                }
            }
            
            if (hasUpdate) {
                LogInfo("自动检查发现新版本: v" . latestVersion . " (构建 #" . latestBuildNumber . ")")
                
                ; 显示通知
                result := MsgBox(
                    "发现新版本 v" . latestVersion . "`n`n"
                    . "当前版本: v" . currentVersion . " (构建 #" . currentBuildNumber . ")`n"
                    . "最新版本: v" . latestVersion . " (构建 #" . latestBuildNumber . ")`n`n"
                    . "是否前往下载页面？",
                    AppVersion.name . " - 发现更新",
                    "YesNo Icon!"
                )
                
                if (result = "Yes") {
                    Run("https://github.com/" . AppVersion.githubRepo . "/releases/latest")
                }
            } else {
                LogInfo("自动检查：当前已是最新版本")
            }
            
        } catch as err {
            ; 记录错误日志
            LogError("自动检查更新失败: " . err.Message)
            
            ; 非静默模式下显示错误弹窗
            if (!isSilent) {
                MsgBox(
                    "自动检查更新失败`n`n"
                    . "错误信息: " . err.Message . "`n`n"
                    . "可能原因：`n"
                    . "• 网络连接问题`n"
                    . "• GitHub API 暂时不可用`n"
                    . "• 防火墙阻止了连接`n`n"
                    . "您可以稍后手动检查更新（托盘菜单 → 关于 → 检查更新）",
                    AppVersion.name . " - 检查更新失败",
                    "Icon! 48"
                )
            }
            ; 静默模式下只记录日志，不显示弹窗
        }
    }
    
    /**
     * 处理退出菜单项点击
     */
    static OnExit() {
        try {
            LogInfo("用户从托盘菜单点击退出")
            
            ; 调用应用程序控制器的关闭函数
            if (IsSet(AppController)) {
                AppController.Shutdown()
            } else {
                ; 直接退出
                ExitApp()
            }
            
        } catch as err {
            LogError("退出应用失败: " . err.Message)
            ExitApp()
        }
    }
}

/**
 * 托盘图标点击事件处理函数
 * @param {Integer} wParam - 消息参数
 * @param {Integer} lParam - 消息参数
 */
TrayIconClick(wParam, lParam, msg, hwnd) {
    ; lParam 值说明:
    ; 0x201 = WM_LBUTTONDOWN (左键按下)
    ; 0x202 = WM_LBUTTONUP (左键释放)
    ; 0x203 = WM_LBUTTONDBLCLK (左键双击)
    ; 0x204 = WM_RBUTTONDOWN (右键按下)
    ; 0x205 = WM_RBUTTONUP (右键释放)
    
    if (lParam = 0x202) {  ; 左键释放（单击）
        try {
            LogInfo("用户左键点击托盘图标")
            
            ; 调用应用程序控制器的切换函数
            if (IsSet(AppController)) {
                AppController.OnMicrophoneToggle()
            } else {
                ; 如果控制器未初始化，直接切换
                newState := MicrophoneController.ToggleMicrophone()
                TrayManager.UpdateTrayIcon(newState)
                TrayManager.UpdateTrayMenu(newState)
            }
            
        } catch as err {
            LogError("托盘图标点击处理失败: " . err.Message)
        }
    }
}

; ============================================================================
; 悬浮窗管理器 (Overlay Manager)
; ============================================================================

class OverlayManager {
    
    static overlayGui := ""
    static overlayPicture := ""
    static overlayText := ""
    static config := ""
    
    /**
     * 创建悬浮窗 GUI
     * @param {Map} config - 配置映射
     */
    static CreateOverlay(config, forceCreate := false) {
        try {
            ; 保存配置引用
            this.config := config
            
            ; 检查是否启用悬浮窗（除非强制创建，如预览时）
            if (!forceCreate && ConfigManager.GetConfig(config, "Overlay_Enabled", "1") = "0") {
                LogInfo("悬浮窗已禁用，跳过创建")
                return
            }
            
            ; 创建无边框 GUI 窗口
            ; +AlwaysOnTop: 始终置顶
            ; +ToolWindow: 工具窗口样式（不在任务栏显示）
            ; -Caption: 无标题栏
            ; +Disabled: 禁用交互（鼠标穿透）
            this.overlayGui := Gui("+AlwaysOnTop +ToolWindow -Caption +Disabled", "MicOverlay")
            
            ; 设置窗口背景色
            backgroundColor := ConfigManager.GetConfig(config, "Overlay_BackgroundColor", "FF0000")
            this.overlayGui.BackColor := backgroundColor
            
            ; 获取配置
            showIcon := ConfigManager.GetConfig(config, "Overlay_ShowIcon", "1")
            overlayText := ConfigManager.GetConfig(config, "Overlay_Text", "麦克风已禁用")
            fontSize := ConfigManager.GetConfig(config, "Overlay_FontSize", "14")
            textColor := ConfigManager.GetConfig(config, "Overlay_TextColor", "FFFFFF")
            
            ; 设置字体
            this.overlayGui.SetFont("s" . fontSize . " c" . textColor . " bold", "Microsoft YaHei")
            
            ; 水平布局：图标 + 文本
            xPos := 10
            yPos := 10
            
            ; 添加图标（如果启用）
            if (showIcon = "1") {
                ; 使用 ResourceManager 获取图标路径
                iconPath := ResourceManager.GetIconPath("disabled")
                
                if (iconPath != "" && FileExist(iconPath)) {
                    ; 使用自定义图标
                    this.overlayPicture := this.overlayGui.Add("Picture", "x" . xPos . " y" . yPos . " w32 h32", iconPath)
                } else {
                    ; 使用系统图标
                    try {
                        ; 使用 AHK 的图标提取功能
                        ; 注意：这里使用 Picture 控件的 Icon 选项
                        this.overlayPicture := this.overlayGui.Add("Picture", "x" . xPos . " y" . yPos . " w32 h32 Icon221", "Shell32.dll")
                    } catch {
                        ; 如果失败，创建一个占位符
                        this.overlayPicture := this.overlayGui.Add("Text", "x" . xPos . " y" . yPos . " w32 h32 Center", "🎤")
                    }
                }
                
                xPos += 40  ; 图标宽度 + 间距
            }
            
            ; 添加文本
            this.overlayText := this.overlayGui.Add("Text", "x" . xPos . " y" . yPos . " +0x200", overlayText)
            
            ; 设置窗口透明度
            transparency := ConfigManager.GetConfig(config, "Overlay_Transparency", "200")
            
            ; 更新位置和样式
            this.UpdateOverlayPosition()
            this.UpdateOverlayStyle()
            
            ; 初始状态：隐藏
            AppState.overlayVisible := false
            
            LogInfo("悬浮窗已创建")
            
        } catch as err {
            LogError("创建悬浮窗失败: " . err.Message)
        }
    }
    
    /**
     * 显示悬浮窗
     */
    static ShowOverlay(forceCreate := false) {
        try {
            ; 如果悬浮窗未创建，先创建
            if (this.overlayGui = "") {
                LogInfo("悬浮窗未创建，先创建悬浮窗")
                this.CreateOverlay(this.config, forceCreate)
                if (this.overlayGui = "") {
                    if (!forceCreate) {
                        LogInfo("悬浮窗已禁用或创建失败")
                    } else {
                        LogError("创建悬浮窗失败，无法显示")
                    }
                    return
                }
            }
            
            ; 检查是否启用悬浮窗（除非强制显示，如预览时）
            if (!forceCreate && ConfigManager.GetConfig(this.config, "Overlay_Enabled", "1") = "0") {
                LogInfo("悬浮窗已禁用，跳过显示")
                return
            }
            
            ; 标记为可见（在更新位置之前）
            AppState.overlayVisible := true
            
            ; 更新位置（确保在正确的位置）
            this.UpdateOverlayPosition()
            
            ; 显示窗口（NoActivate 表示不激活窗口）
            this.overlayGui.Show("NoActivate")
            
            LogInfo("悬浮窗已显示")
            
        } catch as err {
            LogError("显示悬浮窗失败: " . err.Message)
        }
    }
    
    /**
     * 隐藏悬浮窗
     */
    static HideOverlay() {
        try {
            if (this.overlayGui = "") {
                ; 悬浮窗未创建，无需隐藏（不记录警告，避免日志噪音）
                return
            }
            
            ; 隐藏窗口
            this.overlayGui.Hide()
            
            AppState.overlayVisible := false
            
            LogInfo("悬浮窗已隐藏")
            
        } catch as err {
            LogError("隐藏悬浮窗失败: " . err.Message)
        }
    }
    
    /**
     * 根据配置更新悬浮窗位置
     */
    static UpdateOverlayPosition() {
        try {
            if (this.overlayGui = "") {
                return
            }
            
            ; 获取配置
            position := ConfigManager.GetConfig(this.config, "Overlay_Position", "TopRight")
            offsetX := Integer(ConfigManager.GetConfig(this.config, "Overlay_OffsetX", "10"))
            offsetY := Integer(ConfigManager.GetConfig(this.config, "Overlay_OffsetY", "10"))
            
            ; 获取屏幕尺寸
            screenWidth := A_ScreenWidth
            screenHeight := A_ScreenHeight
            
            ; 获取窗口尺寸
            ; 记录当前可见状态
            wasVisible := AppState.overlayVisible
            
            ; 临时显示窗口以获取尺寸（在屏幕外）
            this.overlayGui.Show("x-10000 y-10000 NoActivate")
            Sleep(50)  ; 等待窗口创建
            
            winWidth := 0
            winHeight := 0
            try {
                WinGetPos(, , &winWidth, &winHeight, "ahk_id " . this.overlayGui.Hwnd)
            } catch {
                ; 如果获取失败，使用默认尺寸
                winWidth := 200
                winHeight := 50
            }
            
            ; 如果尺寸为0，使用默认值
            if (winWidth = 0) {
                winWidth := 200
            }
            if (winHeight = 0) {
                winHeight := 50
            }
            
            ; 计算位置
            x := 0
            y := 0
            
            switch position {
                case "TopLeft":
                    x := offsetX
                    y := offsetY
                
                case "TopRight":
                    x := screenWidth - winWidth - offsetX
                    y := offsetY
                
                case "BottomLeft":
                    x := offsetX
                    y := screenHeight - winHeight - offsetY
                
                case "BottomRight":
                    x := screenWidth - winWidth - offsetX
                    y := screenHeight - winHeight - offsetY
                
                case "TopCenter":
                    x := (screenWidth - winWidth) // 2
                    y := offsetY
                
                case "BottomCenter":
                    x := (screenWidth - winWidth) // 2
                    y := screenHeight - winHeight - offsetY
                
                default:
                    ; 默认右上角
                    x := screenWidth - winWidth - offsetX
                    y := offsetY
            }
            
            ; 移动窗口到目标位置并根据之前的状态决定是否显示
            if (wasVisible) {
                ; 如果应该可见，使用 Show 命令移动并显示
                this.overlayGui.Show("x" . x . " y" . y . " NoActivate")
            } else {
                ; 如果不应该可见，移动后隐藏
                this.overlayGui.Move(x, y)
                this.overlayGui.Hide()
            }
            
            LogInfo("悬浮窗位置已更新: " . position . " (" . x . ", " . y . ")")
            
        } catch as err {
            LogError("更新悬浮窗位置失败: " . err.Message)
        }
    }
    
    /**
     * 根据配置更新悬浮窗样式
     */
    static UpdateOverlayStyle() {
        try {
            if (this.overlayGui = "") {
                return
            }
            
            ; 获取配置
            transparency := Integer(ConfigManager.GetConfig(this.config, "Overlay_Transparency", "200"))
            backgroundColor := ConfigManager.GetConfig(this.config, "Overlay_BackgroundColor", "FFFFFF")
            textColor := ConfigManager.GetConfig(this.config, "Overlay_TextColor", "000000")
            fontSize := ConfigManager.GetConfig(this.config, "Overlay_FontSize", "14")
            
            ; 更新背景色
            this.overlayGui.BackColor := backgroundColor
            
            ; 更新透明度（只在窗口存在时）
            try {
                if WinExist("ahk_id " . this.overlayGui.Hwnd) {
                    WinSetTransparent(transparency, "ahk_id " . this.overlayGui.Hwnd)
                }
            } catch {
                ; 窗口不存在时忽略
            }
            
            ; 更新文本样式
            if (this.overlayText != "") {
                this.overlayGui.SetFont("s" . fontSize . " c" . textColor . " bold", "Microsoft YaHei")
                
                ; 重新设置文本以应用新样式
                overlayText := ConfigManager.GetConfig(this.config, "Overlay_Text", "麦克风已禁用")
                this.overlayText.Value := overlayText
            }
            
            LogInfo("悬浮窗样式已更新")
            
        } catch as err {
            LogError("更新悬浮窗样式失败: " . err.Message)
        }
    }
    
    /**
     * 更新悬浮窗中的图标
     * @param {Boolean} micEnabled - 麦克风是否启用
     */
    static UpdateOverlayIcon(micEnabled) {
        try {
            if (this.overlayGui = "" || this.overlayPicture = "") {
                return
            }
            
            ; 检查是否显示图标
            showIcon := ConfigManager.GetConfig(this.config, "Overlay_ShowIcon", "1")
            if (showIcon = "0") {
                return
            }
            
            ; 使用 ResourceManager 获取图标路径
            iconName := micEnabled ? "enabled" : "disabled"
            iconPath := ResourceManager.GetIconPath(iconName)
            
            ; 更新图标
            if (iconPath != "" && FileExist(iconPath)) {
                this.overlayPicture.Value := iconPath
            } else {
                ; 使用系统图标
                ; 注意：Picture 控件更新系统图标需要重新创建
                ; 这里简化处理，仅在自定义图标存在时更新
            }
            
            LogInfo("悬浮窗图标已更新: " . (micEnabled ? "启用" : "禁用"))
            
        } catch as err {
            LogError("更新悬浮窗图标失败: " . err.Message)
        }
    }
    
    /**
     * 确保悬浮窗保持置顶状态
     * 用于定时检查并恢复可能因系统事件（休眠/唤醒等）而失去的置顶状态
     */
    static EnsureAlwaysOnTop() {
        try {
            ; 只在悬浮窗存在且可见时检查
            if (this.overlayGui = "" || !AppState.overlayVisible) {
                return
            }
            
            ; 检查窗口是否存在
            if !WinExist("ahk_id " . this.overlayGui.Hwnd) {
                return
            }
            
            ; 重新应用 AlwaysOnTop 属性
            ; 这会确保窗口保持在最顶层，即使系统事件导致其失去置顶状态
            try {
                WinSetAlwaysOnTop(1, "ahk_id " . this.overlayGui.Hwnd)
            } catch {
                ; 如果失败，尝试重新创建窗口的置顶属性
                try {
                    this.overlayGui.Opt("+AlwaysOnTop")
                } catch {
                    ; 忽略错误
                }
            }
            
        } catch as err {
            ; 静默处理错误，避免日志过多
            ; LogError("确保悬浮窗置顶失败: " . err.Message)
        }
    }
    
    /**
     * 销毁悬浮窗
     */
    static DestroyOverlay() {
        try {
            if (this.overlayGui != "") {
                this.overlayGui.Destroy()
                this.overlayGui := ""
                this.overlayPicture := ""
                this.overlayText := ""
                AppState.overlayVisible := false
                
                LogInfo("悬浮窗已销毁")
            }
        } catch as err {
            LogError("销毁悬浮窗失败: " . err.Message)
        }
    }
}

; ============================================================================
; 快捷键监听器 (Hotkey Listener)
; ============================================================================

class HotkeyListener {
    
    static currentHotkey := ""
    static _isRegistered := false
    
    /**
     * 获取注册状态
     * @returns {Boolean} 是否已注册
     */
    static isRegistered {
        get => this._isRegistered
        set => this._isRegistered := value
    }
    
    /**
     * 注册全局快捷键
     * @param {String} key - 快捷键字符串 (例如: "F9", "^!M")
     * @returns {Boolean} 是否注册成功
     */
    static RegisterHotkey(key) {
        try {
            ; 验证快捷键格式
            if !ConfigManager.ValidateHotkey(key) {
                LogError("快捷键格式无效: " . key)
                this.HandleHotkeyError("格式无效", key, "快捷键格式不正确，请检查配置文件")
                return false
            }
            
            ; 如果已经注册了相同的快捷键，直接返回成功
            if (this.currentHotkey = key && this.isRegistered) {
                LogInfo("快捷键已注册: " . key)
                return true
            }
            
            ; 如果已经注册了其他快捷键，先注销
            if (this.isRegistered && this.currentHotkey != "") {
                this.UnregisterHotkey()
            }
            
            ; 注册新的快捷键
            ; 使用 Hotkey 函数注册全局快捷键
            ; 回调函数使用 ObjBindMethod 绑定到类方法
            Hotkey(key, (*) => this.OnHotkeyPressed(), "On")
            
            ; 保存当前快捷键
            this.currentHotkey := key
            this.isRegistered := true
            AppState.currentHotkey := key
            
            LogInfo("快捷键已注册: " . key)
            return true
            
        } catch as err {
            ; 注册失败，可能是快捷键冲突
            LogError("注册快捷键失败: " . err.Message . " (快捷键: " . key . ")")
            
            ; 处理快捷键冲突错误
            this.HandleHotkeyError("注册失败", key, "快捷键可能已被其他程序占用或格式不正确")
            
            ; 标记为未注册
            this.isRegistered := false
            
            return false
        }
    }
    
    /**
     * 处理快捷键错误
     * 显示详细的错误通知和建议
     * @param {String} errorType - 错误类型
     * @param {String} hotkey - 快捷键
     * @param {String} message - 错误消息
     */
    static HandleHotkeyError(errorType, hotkey, message) {
        try {
            LogError("快捷键错误 [" . errorType . "]: " . hotkey . " - " . message)
            
            ; 构建详细的通知消息
            notificationTitle := "快捷键" . errorType
            notificationMsg := "快捷键: " . hotkey . "`n`n"
            notificationMsg .= message . "`n`n"
            notificationMsg .= "建议：`n"
            notificationMsg .= "1. 打开配置文件修改快捷键`n"
            notificationMsg .= "2. 尝试使用其他快捷键（如 F10, F11, ^F9）`n"
            notificationMsg .= "3. 关闭可能占用快捷键的其他程序`n`n"
            notificationMsg .= "注意：应用程序将继续运行，但快捷键功能不可用"
            
            ; 显示托盘通知
            TrayTip(notificationTitle, notificationMsg, 5)
            
            ; 播放警告声音
            try {
                SoundBeep(800, 300)
            } catch {
                ; 忽略声音播放错误
            }
            
        } catch as err {
            LogError("处理快捷键错误失败: " . err.Message)
        }
    }
    
    /**
     * 注销当前快捷键
     * @returns {Boolean} 是否注销成功
     */
    static UnregisterHotkey() {
        try {
            ; 检查是否有已注册的快捷键
            if (!this.isRegistered || this.currentHotkey = "") {
                LogInfo("没有需要注销的快捷键")
                return true
            }
            
            ; 注销快捷键
            Hotkey(this.currentHotkey, "Off")
            
            LogInfo("快捷键已注销: " . this.currentHotkey)
            
            ; 清空状态
            this.currentHotkey := ""
            this.isRegistered := false
            AppState.currentHotkey := ""
            
            return true
            
        } catch as err {
            LogError("注销快捷键失败: " . err.Message)
            return false
        }
    }
    
    /**
     * 更新快捷键配置
     * @param {String} newKey - 新的快捷键字符串
     * @returns {Boolean} 是否更新成功
     */
    static UpdateHotkey(newKey) {
        try {
            LogInfo("更新快捷键: " . (this.currentHotkey != "" ? this.currentHotkey : "无") . " -> " . newKey)
            
            ; 先注销当前快捷键
            if (this.isRegistered) {
                this.UnregisterHotkey()
            }
            
            ; 注册新的快捷键
            if this.RegisterHotkey(newKey) {
                ; 保存到配置文件
                ConfigManager.SaveConfig("General", "Hotkey", newKey)
                
                LogInfo("快捷键已更新: " . newKey)
                
                return true
            } else {
                LogError("更新快捷键失败: 无法注册新快捷键")
                
                ; 尝试恢复旧的快捷键
                if (this.currentHotkey != "") {
                    LogInfo("尝试恢复旧快捷键: " . this.currentHotkey)
                    this.RegisterHotkey(this.currentHotkey)
                }
                
                return false
            }
            
        } catch as err {
            LogError("更新快捷键失败: " . err.Message)
            return false
        }
    }
    
    /**
     * 快捷键按下时的回调函数
     * 触发麦克风切换
     */
    static OnHotkeyPressed() {
        try {
            LogInfo("快捷键被按下: " . this.currentHotkey)
            
            ; 调用应用程序控制器的切换函数
            if (IsSet(AppController)) {
                AppController.OnMicrophoneToggle()
            } else {
                ; 如果控制器未初始化，直接切换麦克风
                LogWarning("AppController 未初始化，直接切换麦克风")
                
                newState := MicrophoneController.ToggleMicrophone()
                
                ; 更新 UI（如果可用）
                if (IsSet(TrayManager)) {
                    TrayManager.UpdateTrayIcon(newState)
                    TrayManager.UpdateTrayMenu(newState)
                }
                
                if (IsSet(OverlayManager)) {
                    if (newState) {
                        OverlayManager.HideOverlay()
                    } else {
                        OverlayManager.ShowOverlay()
                    }
                }
            }
            
        } catch as err {
            LogError("快捷键回调处理失败: " . err.Message)
            
            ; 显示错误通知
            TrayTip("快捷键处理失败", "发生错误: " . err.Message, 2)
        }
    }
    
    /**
     * 获取当前注册的快捷键
     * @returns {String} 当前快捷键字符串
     */
    static GetCurrentHotkey() {
        return this.currentHotkey
    }
    
    /**
     * 检查快捷键是否已注册
     * @returns {Boolean} 是否已注册
     */
    static IsRegistered() {
        return this.isRegistered
    }
}

; ============================================================================
; 管理员权限检查器 (Administrator Privilege Checker)
; ============================================================================

class AdminChecker {
    
    /**
     * 检查当前进程是否以管理员权限运行
     * @returns {Boolean} true=以管理员权限运行, false=非管理员权限
     */
    static IsAdmin() {
        try {
            ; 尝试读取需要管理员权限的注册表项
            ; HKEY_LOCAL_MACHINE 的写入需要管理员权限
            ; 我们尝试读取一个系统注册表项来判断权限
            
            ; 方法1: 使用 RunAs 检查
            ; 在 Windows 中，管理员权限进程可以访问特定的注册表项
            
            ; 尝试创建一个临时注册表项来测试权限
            testKey := "HKEY_LOCAL_MACHINE\SOFTWARE\MicToggleToolAdminTest"
            
            try {
                ; 尝试写入测试键
                RegWrite("test", "REG_SZ", testKey, "TestValue")
                
                ; 如果成功，删除测试键
                try {
                    RegDelete(testKey, "TestValue")
                    RegDelete(testKey)
                } catch {
                    ; 忽略删除错误
                }
                
                ; 写入成功，说明有管理员权限
                LogInfo("管理员权限检查: 已确认管理员权限")
                return true
                
            } catch {
                ; 写入失败，说明没有管理员权限
                LogInfo("管理员权限检查: 未检测到管理员权限")
                return false
            }
            
        } catch as err {
            ; 发生错误，假设没有管理员权限
            LogError("管理员权限检查失败: " . err.Message)
            return false
        }
    }
    
    /**
     * 检查管理员权限并在权限不足时提示用户
     * @param {Boolean} showPrompt - 是否显示提示对话框
     * @param {Boolean} hasAdminRights - 预先检查的管理员权限状态（避免重复检查）
     * @returns {Boolean} true=有管理员权限或用户选择继续, false=无权限且用户选择退出
     */
    static CheckAndPrompt(showPrompt := true, hasAdminRights := "") {
        try {
            ; 如果没有预先提供权限状态，则检查一次
            if (hasAdminRights = "") {
                hasAdminRights := this.IsAdmin()
            }
            
            ; 检查是否有管理员权限
            if hasAdminRights {
                return true
            }
            
            ; 没有管理员权限
            if (showPrompt) {
                ; 显示提示对话框
                result := this.ShowAdminPrompt()
                
                if (result = "Retry") {
                    ; 用户选择以管理员身份重新运行
                    LogInfo("用户选择以管理员身份重新运行")
                    return this.RestartAsAdmin()
                    
                } else if (result = "Continue") {
                    ; 用户选择继续运行（功能受限）
                    LogWarning("用户选择在非管理员模式下继续运行")
                    return true
                    
                } else {
                    ; 用户选择退出
                    LogInfo("用户选择退出应用程序")
                    return false
                }
            }
            
            ; 不显示提示，直接返回 false
            return false
            
        } catch as err {
            LogError("管理员权限检查和提示失败: " . err.Message)
            return true  ; 发生错误时允许继续运行
        }
    }
    
    /**
     * 显示管理员权限提示对话框
     * @returns {String} 用户选择: "Retry"=重新运行, "Continue"=继续, "Cancel"=退出
     */
    static ShowAdminPrompt() {
        try {
            ; 创建提示对话框
            promptGui := Gui("+AlwaysOnTop", "管理员权限提示")
            promptGui.SetFont("s10", "Microsoft YaHei")
            
            ; 添加图标（警告图标）
            try {
                promptGui.Add("Picture", "x20 y20 w32 h32 Icon78", "Shell32.dll")
            } catch {
                ; 如果图标加载失败，使用文本代替
                promptGui.Add("Text", "x20 y20 w32 h32 Center", "⚠")
            }
            
            ; 添加说明文本
            promptGui.Add("Text", "x70 y20 w400", "检测到应用程序未以管理员权限运行。")
            promptGui.Add("Text", "x70 y+5 w400", "")
            promptGui.Add("Text", "x70 y+0 w400", "为了确保全局快捷键在所有应用程序中正常工作，")
            promptGui.Add("Text", "x70 y+0 w400", "建议以管理员身份运行此程序。")
            promptGui.Add("Text", "x70 y+10 w400", "")
            promptGui.Add("Text", "x70 y+0 w400 cRed", "注意：在非管理员模式下，快捷键可能无法在某些")
            promptGui.Add("Text", "x70 y+0 w400 cRed", "高权限应用程序（如游戏）中工作。")
            promptGui.Add("Text", "x70 y+10 w400", "")
            promptGui.Add("Text", "x70 y+0 w400", "请选择：")
            
            ; 添加按钮
            btnRetry := promptGui.Add("Button", "x70 y+20 w150 h35", "以管理员身份重新运行")
            btnContinue := promptGui.Add("Button", "x+10 w150 h35", "继续运行（功能受限）")
            btnCancel := promptGui.Add("Button", "x+10 w100 h35", "退出")
            
            ; 存储用户选择
            userChoice := ""
            
            ; 绑定按钮事件
            btnRetry.OnEvent("Click", (*) => (userChoice := "Retry", promptGui.Destroy()))
            btnContinue.OnEvent("Click", (*) => (userChoice := "Continue", promptGui.Destroy()))
            btnCancel.OnEvent("Click", (*) => (userChoice := "Cancel", promptGui.Destroy()))
            
            ; 绑定窗口关闭事件（等同于取消）
            promptGui.OnEvent("Close", (*) => (userChoice := "Cancel", promptGui.Destroy()))
            
            ; 保存窗口句柄（在显示前）
            guiHwnd := 0
            
            ; 显示对话框（模态）
            promptGui.Show()
            
            ; 获取窗口句柄
            try {
                guiHwnd := promptGui.Hwnd
            } catch {
                ; 如果无法获取句柄，返回默认选择
                LogWarning("无法获取提示窗口句柄")
                return "Continue"
            }
            
            ; 等待用户选择
            while WinExist("ahk_id " . guiHwnd) {
                Sleep(100)
            }
            
            LogInfo("用户选择: " . userChoice)
            return userChoice
            
        } catch as err {
            LogError("显示管理员权限提示失败: " . err.Message)
            return "Continue"  ; 发生错误时默认继续运行
        }
    }
    
    /**
     * 以管理员身份重新启动应用程序
     * @returns {Boolean} 是否成功启动（注意：成功启动后当前进程会退出）
     */
    static RestartAsAdmin() {
        try {
            ; 获取当前程序路径
            exePath := A_ScriptFullPath
            
            LogInfo("尝试以管理员身份重新启动")
            LogInfo("程序路径: " . exePath)
            
            ; 判断是脚本还是编译后的EXE
            isCompiled := (A_IsCompiled)
            
            if (isCompiled) {
                ; 编译后的EXE，直接运行
                LogInfo("检测到编译版本，直接以管理员身份运行EXE")
                try {
                    Run('*RunAs "' . exePath . '"')
                    
                    LogInfo("已请求以管理员身份运行，当前进程将退出")
                    Sleep(500)
                    ExitApp()
                    return true
                    
                } catch as runErr {
                    LogError("以管理员身份运行失败: " . runErr.Message)
                    MsgBox("无法以管理员身份重新运行。`n`n可能原因：`n- 用户取消了UAC提示`n- 系统权限限制`n`n将继续以普通权限运行。", "提权失败", "Iconx 4096")
                    return false
                }
            } else {
                ; 脚本版本，需要通过AutoHotkey.exe运行
                ahkPath := A_AhkPath
                LogInfo("检测到脚本版本，通过AHK运行")
                LogInfo("AHK路径: " . ahkPath)
                
                try {
                    ; 构建命令：AutoHotkey.exe "脚本路径"
                    Run('*RunAs "' . ahkPath . '" "' . exePath . '"')
                    
                    LogInfo("已请求以管理员身份运行，当前进程将退出")
                    Sleep(500)
                    ExitApp()
                    return true
                    
                } catch as runErr {
                    LogError("以管理员身份运行失败: " . runErr.Message)
                    MsgBox("无法以管理员身份重新运行。`n`n可能原因：`n- 用户取消了UAC提示`n- 系统权限限制`n`n将继续以普通权限运行。", "提权失败", "Iconx 4096")
                    return false
                }
            }
            
        } catch as err {
            LogError("重新启动失败: " . err.Message)
            MsgBox("重新启动失败: " . err.Message, "错误", "Iconx")
            return false
        }
    }
    
    /**
     * 获取管理员权限状态信息
     * @returns {String} 权限状态描述
     */
    static GetAdminStatus() {
        if this.IsAdmin() {
            return "已以管理员权限运行"
        } else {
            return "未以管理员权限运行（功能受限）"
        }
    }
    
    /**
     * 在应用程序启动时执行管理员权限检查
     * 这是一个便捷方法，用于在应用程序初始化时调用
     * @returns {Boolean} true=可以继续运行, false=应该退出
     */
    static CheckOnStartup() {
        LogInfo("执行启动时管理员权限检查")
        
        ; 只检查一次管理员权限
        hasAdminRights := this.IsAdmin()
        
        ; 检查并提示（传入已检查的权限状态，避免重复检查）
        if !this.CheckAndPrompt(true, hasAdminRights) {
            ; 用户选择退出
            LogInfo("管理员权限检查：用户选择退出")
            return false
        }
        
        ; 记录最终权限状态（直接使用已检查的状态，避免再次调用 IsAdmin）
        statusMsg := hasAdminRights ? "已以管理员权限运行" : "未以管理员权限运行（功能受限）"
        LogInfo("权限状态: " . statusMsg)
        
        return true
    }
}

; ============================================================================
; 快捷键工具函数 (Hotkey Utilities)
; ============================================================================

/**
 * 将 AHK 快捷键符号转换为人类可读的格式
 * @param {String} hotkeyStr - AHK 格式的快捷键字符串（如 "^#m"）
 * @returns {String} 人类可读的快捷键字符串（如 "Ctrl+Win+M"）
 */
ConvertHotkeyToReadable(hotkeyStr) {
    if (hotkeyStr = "") {
        return ""
    }
    
    readable := ""
    remaining := hotkeyStr
    
    ; 处理修饰符
    ; ^ = Ctrl
    if (InStr(remaining, "^")) {
        readable .= "Ctrl+"
        remaining := StrReplace(remaining, "^", "")
    }
    
    ; ! = Alt
    if (InStr(remaining, "!")) {
        readable .= "Alt+"
        remaining := StrReplace(remaining, "!", "")
    }
    
    ; + = Shift
    if (InStr(remaining, "+")) {
        readable .= "Shift+"
        remaining := StrReplace(remaining, "+", "")
    }
    
    ; # = Win
    if (InStr(remaining, "#")) {
        readable .= "Win+"
        remaining := StrReplace(remaining, "#", "")
    }
    
    ; 添加主键（转换为大写）
    if (remaining != "") {
        readable .= StrUpper(remaining)
    }
    
    return readable
}

/**
 * 将人类可读的快捷键转换为 AHK 格式
 * @param {String} readableStr - 人类可读的快捷键字符串（如 "Ctrl+Win+M"）
 * @returns {String} AHK 格式的快捷键字符串（如 "^#m"）
 */
ConvertReadableToHotkey(readableStr) {
    if (readableStr = "") {
        return ""
    }
    
    ahkStr := ""
    
    ; 转换为小写以便比较
    lower := StrLower(readableStr)
    
    ; 处理修饰符
    if (InStr(lower, "ctrl")) {
        ahkStr .= "^"
    }
    
    if (InStr(lower, "alt")) {
        ahkStr .= "!"
    }
    
    if (InStr(lower, "shift")) {
        ahkStr .= "+"
    }
    
    if (InStr(lower, "win")) {
        ahkStr .= "#"
    }
    
    ; 提取主键（最后一个+号后面的部分）
    parts := StrSplit(readableStr, "+")
    if (parts.Length > 0) {
        mainKey := Trim(parts[parts.Length])
        ahkStr .= mainKey
    }
    
    return ahkStr
}

; ============================================================================
; 设置对话框 (Settings Dialog)
; ============================================================================

class SettingsDialog {
    
    static settingsGui := ""
    static hotkeyEdit := ""
    static overlayEnabledCheckbox := ""
    static overlayPositionDropdown := ""
    static autoStartCheckbox := ""
    
    /**
     * 显示设置对话框
     */
    static ShowSettings() {
        try {
            ; 加载当前配置
            config := ConfigManager.LoadConfig()
            
            ; 创建设置窗口（不置顶，避免遮挡错误提示）
            this.settingsGui := Gui("", "设置 - 麦克风快捷控制工具")
            this.settingsGui.SetFont("s10", "Microsoft YaHei")
            
            ; === 快捷键设置 ===
            this.settingsGui.Add("GroupBox", "x10 y10 w380 h120", "快捷键设置")
            this.settingsGui.Add("Text", "x20 y35 w100", "全局快捷键:")
            
            ; 获取当前快捷键并转换为可读格式
            currentHotkey := ConfigManager.GetConfig(config, "General_Hotkey", "F9")
            readableHotkey := ConvertHotkeyToReadable(currentHotkey)
            
            ; 显示当前快捷键（只读）
            this.settingsGui.Add("Text", "x130 y35 w240 Border", readableHotkey)
            
            ; 添加修改按钮
            btnChangeHotkey := this.settingsGui.Add("Button", "x130 y65 w120 h30", "修改快捷键")
            btnChangeHotkey.OnEvent("Click", (*) => this.OnChangeHotkey(currentHotkey))
            
            ; 存储当前快捷键
            this.currentHotkey := currentHotkey
            this.hotkeyDisplay := this.settingsGui.Add("Text", "x20 y100 w350 cGray", "提示: 点击 '修改快捷键' 按钮来更改快捷键")
            
            ; === 悬浮窗设置 ===
            this.settingsGui.Add("GroupBox", "x10 y120 w380 h200", "悬浮窗设置")
            this.overlayEnabledCheckbox := this.settingsGui.Add("Checkbox", "x20 y145 w350", "启用悬浮窗（麦克风禁用时显示）")
            this.overlayEnabledCheckbox.Value := (ConfigManager.GetConfig(config, "Overlay_Enabled", "1") = "1")
            
            this.settingsGui.Add("Text", "x20 y175 w100", "悬浮窗位置:")
            positions := ["TopLeft", "TopRight", "TopCenter", "BottomLeft", "BottomRight", "BottomCenter"]
            positionNames := ["左上角", "右上角", "顶部居中", "左下角", "右下角", "底部居中"]
            currentPosition := ConfigManager.GetConfig(config, "Overlay_Position", "TopRight")
            
            ; 找到当前位置的索引
            currentIndex := 1
            Loop positions.Length {
                if (positions[A_Index] = currentPosition) {
                    currentIndex := A_Index
                    break
                }
            }
            
            this.overlayPositionDropdown := this.settingsGui.Add("DropDownList", "x130 y172 w240 Choose" . currentIndex, positionNames)
            
            ; 位置偏移设置
            this.settingsGui.Add("Text", "x20 y205 w100", "水平偏移 (像素):")
            this.overlayOffsetXEdit := this.settingsGui.Add("Edit", "x130 y202 w100 Number", ConfigManager.GetConfig(config, "Overlay_OffsetX", "10"))
            
            this.settingsGui.Add("Text", "x20 y235 w100", "垂直偏移 (像素):")
            this.overlayOffsetYEdit := this.settingsGui.Add("Edit", "x130 y232 w100 Number", ConfigManager.GetConfig(config, "Overlay_OffsetY", "10"))
            
            ; 监听偏移值变化，自动预览
            this.overlayOffsetXEdit.OnEvent("Change", (*) => this.OnOffsetChange(config, positions))
            this.overlayOffsetYEdit.OnEvent("Change", (*) => this.OnOffsetChange(config, positions))
            this.overlayPositionDropdown.OnEvent("Change", (*) => this.OnOffsetChange(config, positions))
            
            ; 背景颜色设置
            this.settingsGui.Add("Text", "x20 y265 w100", "背景颜色:")
            currentColor := ConfigManager.GetConfig(config, "Overlay_BackgroundColor", "F0F0F0")
            this.overlayColorEdit := this.settingsGui.Add("Edit", "x130 y262 w100", currentColor)
            this.settingsGui.Add("Text", "x240 y265 w150 cGray", "(6位16进制RGB)")
            
            ; 文字颜色设置
            this.settingsGui.Add("Text", "x20 y295 w100", "文字颜色:")
            currentTextColor := ConfigManager.GetConfig(config, "Overlay_TextColor", "000000")
            this.overlayTextColorEdit := this.settingsGui.Add("Edit", "x130 y292 w100", currentTextColor)
            this.settingsGui.Add("Text", "x240 y295 w150 cGray", "(6位16进制RGB)")
            
            ; === 其他设置 ===
            this.settingsGui.Add("GroupBox", "x10 y360 w380 h200", "其他设置")
            
            ; 开机自动启动
            this.autoStartCheckbox := this.settingsGui.Add("Checkbox", "x20 y385 w350", "开机自动启动")
            this.autoStartCheckbox.Value := (ConfigManager.GetConfig(config, "General_AutoStart", "0") = "1")
            
            ; 自动检查更新（默认关闭）
            this.autoCheckUpdateCheckbox := this.settingsGui.Add("Checkbox", "x20 y410 w350", "自动检查更新（每24小时）")
            this.autoCheckUpdateCheckbox.Value := (ConfigManager.GetConfig(config, "General_AutoCheckUpdate", "0") = "1")
            
            ; 静默检查更新（增加宽度，调整为多行显示）
            this.autoCheckUpdateSilentCheckbox := this.settingsGui.Add("Checkbox", "x40 y435 w330", "静默模式（检查出错时不提示,如果与GitHub连接不稳定建议开）")
            this.autoCheckUpdateSilentCheckbox.Value := (ConfigManager.GetConfig(config, "General_AutoCheckUpdateSilent", "1") = "1")
            
            ; 绑定自动检查更新的事件，控制静默模式的启用状态
            this.autoCheckUpdateCheckbox.OnEvent("Click", (*) => this.OnAutoCheckUpdateToggle())
            
            ; 初始化静默模式的启用状态
            this.autoCheckUpdateSilentCheckbox.Enabled := this.autoCheckUpdateCheckbox.Value
            
            ; 管理员权限检查（向下移动，给上方换行留出空间）
            this.settingsGui.Add("Text", "x20 y485 w100", "启动权限检查:")
            currentAdminCheck := ConfigManager.GetConfig(config, "General_AdminCheck", "prompt")
            this.adminCheckDropdown := this.settingsGui.Add("DropDownList", "x130 y482 w150", ["提醒", "跳过", "自动"])
            
            ; 设置当前选项
            if (currentAdminCheck = "prompt") {
                this.adminCheckDropdown.Choose(1)
            } else if (currentAdminCheck = "skip") {
                this.adminCheckDropdown.Choose(2)
            } else if (currentAdminCheck = "auto") {
                this.adminCheckDropdown.Choose(3)
            }
            
            ; 添加权限检查说明（多行，向下移动）
            this.settingsGui.Add("Text", "x20 y510 w360 cGray", "• 提醒：非管理员身份启动时提醒（推荐）")
            this.settingsGui.Add("Text", "x20 y530 w360 cGray", "• 跳过：不检查权限，直接启动")
            this.settingsGui.Add("Text", "x20 y550 w360 cGray", "• 自动：非管理员身份启动时自动提权")
            
            ; === 按钮 ===（向下移动）
            btnSave := this.settingsGui.Add("Button", "x100 y595 w90 h35", "保存")
            btnCancel := this.settingsGui.Add("Button", "x200 y595 w90 h35", "取消")
            
            ; 绑定按钮事件
            btnSave.OnEvent("Click", (*) => this.OnSave(config, positions))
            btnCancel.OnEvent("Click", (*) => this.OnCancel())
            
            ; 绑定窗口关闭事件
            this.settingsGui.OnEvent("Close", (*) => this.OnCancel())
            
            ; 显示窗口
            this.settingsGui.Show()
            
            LogInfo("设置对话框已显示")
            
        } catch as err {
            LogError("显示设置对话框失败: " . err.Message)
            MsgBox("显示设置对话框失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 处理自动检查更新复选框的切换事件
     */
    static OnAutoCheckUpdateToggle() {
        try {
            ; 获取自动检查更新的状态
            autoCheckEnabled := this.autoCheckUpdateCheckbox.Value
            
            ; 根据自动检查更新的状态，启用或禁用静默模式复选框
            this.autoCheckUpdateSilentCheckbox.Enabled := autoCheckEnabled
            
            ; 如果禁用自动检查更新，同时取消勾选静默模式
            if (!autoCheckEnabled) {
                this.autoCheckUpdateSilentCheckbox.Value := 0
            }
            
            LogInfo("自动检查更新状态切换: " . (autoCheckEnabled ? "启用" : "禁用"))
        } catch as err {
            LogError("处理自动检查更新切换失败: " . err.Message)
        }
    }
    
    /**
     * 保存设置
     */
    static OnSave(config, positions) {
        try {
            ; 获取新的快捷键
            newHotkey := this.currentHotkey
            
            ; 验证快捷键
            if (newHotkey = "") {
                MsgBox("请设置一个有效的快捷键！", "提示", "Icon!")
                return
            }
            
            ; 获取其他设置
            overlayEnabled := this.overlayEnabledCheckbox.Value ? "1" : "0"
            positionIndex := this.overlayPositionDropdown.Value
            overlayPosition := positions[positionIndex]
            overlayOffsetX := this.overlayOffsetXEdit.Value
            overlayOffsetY := this.overlayOffsetYEdit.Value
            overlayColor := this.overlayColorEdit.Value
            overlayTextColor := this.overlayTextColorEdit.Value
            autoStart := this.autoStartCheckbox.Value ? "1" : "0"
            autoCheckUpdate := this.autoCheckUpdateCheckbox.Value ? "1" : "0"
            autoCheckUpdateSilent := this.autoCheckUpdateSilentCheckbox.Value ? "1" : "0"
            
            ; 获取管理员权限检查模式
            adminCheckIndex := this.adminCheckDropdown.Value
            adminCheckMode := (adminCheckIndex = 1) ? "prompt" : (adminCheckIndex = 2) ? "skip" : "auto"
            
            ; 验证颜色格式
            if !RegExMatch(overlayColor, "^[0-9A-Fa-f]{6}$") {
                MsgBox("背景颜色格式不正确！`n请输入 6 位十六进制颜色代码（如 FFFFFF）", "提示", "Icon!")
                return
            }
            
            if !RegExMatch(overlayTextColor, "^[0-9A-Fa-f]{6}$") {
                MsgBox("文字颜色格式不正确！`n请输入 6 位十六进制颜色代码（如 000000）", "提示", "Icon!")
                return
            }
            
            ; 保存配置
            oldHotkey := ConfigManager.GetConfig(config, "General_Hotkey", "F9")
            
            ConfigManager.SaveConfig("General", "Hotkey", newHotkey)
            ConfigManager.SaveConfig("Overlay", "Enabled", overlayEnabled)
            ConfigManager.SaveConfig("Overlay", "Position", overlayPosition)
            ConfigManager.SaveConfig("Overlay", "OffsetX", overlayOffsetX)
            ConfigManager.SaveConfig("Overlay", "OffsetY", overlayOffsetY)
            ConfigManager.SaveConfig("Overlay", "BackgroundColor", overlayColor)
            ConfigManager.SaveConfig("Overlay", "TextColor", overlayTextColor)
            ConfigManager.SaveConfig("General", "AutoStart", autoStart)
            ConfigManager.SaveConfig("General", "AutoCheckUpdate", autoCheckUpdate)
            ConfigManager.SaveConfig("General", "AutoCheckUpdateSilent", autoCheckUpdateSilent)
            ConfigManager.SaveConfig("General", "AdminCheck", adminCheckMode)
            
            ; 更新快捷键（如果改变）
            if (newHotkey != oldHotkey) {
                if (IsSet(HotkeyListener)) {
                    HotkeyListener.UpdateHotkey(newHotkey)
                }
            }
            
            ; 更新悬浮窗配置
            if (IsSet(OverlayManager)) {
                OverlayManager.config := ConfigManager.LoadConfig()
                OverlayManager.UpdateOverlayStyle()
                OverlayManager.UpdateOverlayPosition()
                
                ; 如果禁用了悬浮窗，隐藏它
                if (overlayEnabled = "0") {
                    OverlayManager.HideOverlay()
                }
            }
            
            ; 更新开机自动启动
            autoStartSuccess := true
            if (IsSet(AppController)) {
                autoStartSuccess := AppController.SetAutoStart(autoStart = "1", true)
            }
            
            ; 如果设置失败，不要关闭窗口，让用户看到错误
            if (!autoStartSuccess && autoStart = "1") {
                ; 恢复复选框状态
                this.autoStartCheckbox.Value := 0
                return  ; 不关闭窗口
            }
            
            ; 更新托盘菜单的开机启动复选框
            if (IsSet(TrayManager)) {
                if (autoStart = "1" && autoStartSuccess) {
                    TrayManager.trayMenu.Check("开机启动")
                } else {
                    TrayManager.trayMenu.Uncheck("开机启动")
                }
            }
            
            LogInfo("设置已保存")
            
            ; 关闭窗口
            this.settingsGui.Destroy()
            this.settingsGui := ""
            
        } catch as err {
            LogError("保存设置失败: " . err.Message)
            MsgBox("保存设置失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 修改快捷键
     */
    static OnChangeHotkey(currentHotkey) {
        try {
            ; 创建快捷键输入对话框（置顶，确保在设置窗口上方）
            hotkeyGui := Gui("+AlwaysOnTop +Owner" . this.settingsGui.Hwnd, "修改快捷键")
            hotkeyGui.SetFont("s10", "Microsoft YaHei")
            
            hotkeyGui.Add("Text", "x20 y20 w300", "请按下新的快捷键组合：")
            hotkeyEdit := hotkeyGui.Add("Hotkey", "x20 y50 w300", currentHotkey)
            
            hotkeyGui.Add("Text", "x20 y85 w300 cGray", "提示: 建议使用 Ctrl、Alt、Shift 或 Win 组合键")
            
            btnOK := hotkeyGui.Add("Button", "x70 y120 w80 h30", "确定")
            btnCancel := hotkeyGui.Add("Button", "x170 y120 w80 h30", "取消")
            
            result := ""
            
            btnOK.OnEvent("Click", (*) => (result := hotkeyEdit.Value, hotkeyGui.Destroy()))
            btnCancel.OnEvent("Click", (*) => (result := "", hotkeyGui.Destroy()))
            hotkeyGui.OnEvent("Close", (*) => (result := "", hotkeyGui.Destroy()))
            
            ; 显示对话框
            hotkeyGui.Show()
            
            ; 等待用户操作
            guiHwnd := hotkeyGui.Hwnd
            while WinExist("ahk_id " . guiHwnd) {
                Sleep(100)
            }
            
            ; 如果用户确认了新快捷键
            if (result != "" && result != currentHotkey) {
                this.currentHotkey := result
                
                ; 更新显示
                readableHotkey := ConvertHotkeyToReadable(result)
                
                ; 找到并更新显示文本
                for hwnd, ctrl in this.settingsGui {
                    if (ctrl.Type = "Text" && InStr(ctrl.Text, "Ctrl") || InStr(ctrl.Text, "Alt") || InStr(ctrl.Text, "Win") || InStr(ctrl.Text, "F")) {
                        try {
                            ctrl.Text := readableHotkey
                            break
                        }
                    }
                }
                
                LogInfo("快捷键已修改为: " . result)
            }
            
        } catch as err {
            LogError("修改快捷键失败: " . err.Message)
            MsgBox("修改快捷键失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 偏移值或位置改变时自动预览（带防抖）
     */
    static OnOffsetChange(config, positions) {
        try {
            static previewTimer := 0
            static lastPreviewTime := 0
            
            ; 取消之前的定时器
            if (previewTimer != 0) {
                try {
                    SetTimer(previewTimer, 0)
                } catch {
                }
            }
            
            ; 设置新的定时器，300ms 后预览（防抖，增加延迟减少闪烁）
            previewTimer := () => this.OnPreview(config, positions)
            SetTimer(previewTimer, -300)
            
        } catch as err {
            LogError("偏移值变化处理失败: " . err.Message)
        }
    }
    
    /**
     * 预览悬浮窗位置
     */
    static OnPreview(config, positions) {
        try {
            static restoreTimer := 0
            static savedConfig := ""
            static savedVisibility := false
            
            ; 临时保存当前配置
            positionIndex := this.overlayPositionDropdown.Value
            overlayPosition := positions[positionIndex]
            overlayOffsetX := this.overlayOffsetXEdit.Value
            overlayOffsetY := this.overlayOffsetYEdit.Value
            overlayColor := this.overlayColorEdit.Value
            overlayTextColor := this.overlayTextColorEdit.Value
            
            ; 验证颜色格式
            if !RegExMatch(overlayColor, "^[0-9A-Fa-f]{6}$") {
                return  ; 静默忽略无效颜色
            }
            
            if !RegExMatch(overlayTextColor, "^[0-9A-Fa-f]{6}$") {
                return  ; 静默忽略无效颜色
            }
            
            ; 临时更新配置
            if (IsSet(OverlayManager) && OverlayManager.config != "") {
                ; 只在第一次预览时保存原始配置
                if (savedConfig = "") {
                    savedConfig := Map()
                    savedConfig["Overlay_Position"] := ConfigManager.GetConfig(OverlayManager.config, "Overlay_Position", "TopRight")
                    savedConfig["Overlay_OffsetX"] := ConfigManager.GetConfig(OverlayManager.config, "Overlay_OffsetX", "10")
                    savedConfig["Overlay_OffsetY"] := ConfigManager.GetConfig(OverlayManager.config, "Overlay_OffsetY", "10")
                    savedConfig["Overlay_BackgroundColor"] := ConfigManager.GetConfig(OverlayManager.config, "Overlay_BackgroundColor", "FFFFFF")
                    savedConfig["Overlay_TextColor"] := ConfigManager.GetConfig(OverlayManager.config, "Overlay_TextColor", "000000")
                    savedVisibility := AppState.overlayVisible
                }
                
                ; 应用预览配置
                OverlayManager.config["Overlay_Position"] := overlayPosition
                OverlayManager.config["Overlay_OffsetX"] := overlayOffsetX
                OverlayManager.config["Overlay_OffsetY"] := overlayOffsetY
                OverlayManager.config["Overlay_BackgroundColor"] := overlayColor
                OverlayManager.config["Overlay_TextColor"] := overlayTextColor
                
                ; 更新样式和位置
                OverlayManager.UpdateOverlayStyle()
                OverlayManager.UpdateOverlayPosition()
                
                ; 显示悬浮窗（强制创建，即使悬浮窗被禁用）
                OverlayManager.ShowOverlay(true)  ; 传递true强制创建
                
                ; 取消之前的恢复定时器
                if (restoreTimer != 0) {
                    try {
                        SetTimer(restoreTimer, 0)
                    } catch {
                    }
                }
                
                ; 设置新的恢复定时器（2秒后，减少等待时间）
                restoreTimer := () => this.RestorePreview(savedConfig, savedVisibility, &savedConfig, &restoreTimer)
                SetTimer(restoreTimer, -2000)
                
                LogInfo("预览悬浮窗位置")
            }
            
        } catch as err {
            LogError("预览悬浮窗失败: " . err.Message)
            MsgBox("预览失败: " . err.Message, "错误", "Icon!")
        }
    }
    
    /**
     * 恢复预览前的状态
     */
    static RestorePreview(oldConfig, wasVisible, &savedConfigRef, &restoreTimerRef) {
        try {
            if (IsSet(OverlayManager) && OverlayManager.config != "" && oldConfig != "") {
                ; 恢复配置
                OverlayManager.config["Overlay_Position"] := oldConfig["Overlay_Position"]
                OverlayManager.config["Overlay_OffsetX"] := oldConfig["Overlay_OffsetX"]
                OverlayManager.config["Overlay_OffsetY"] := oldConfig["Overlay_OffsetY"]
                OverlayManager.config["Overlay_BackgroundColor"] := oldConfig["Overlay_BackgroundColor"]
                OverlayManager.config["Overlay_TextColor"] := oldConfig["Overlay_TextColor"]
                
                ; 更新样式和位置
                OverlayManager.UpdateOverlayStyle()
                OverlayManager.UpdateOverlayPosition()
                
                ; 恢复可见性
                if (!wasVisible) {
                    OverlayManager.HideOverlay()
                }
                
                ; 清除保存的配置，允许下次预览重新保存
                savedConfigRef := ""
                restoreTimerRef := 0
            }
        } catch as err {
            LogError("恢复预览失败: " . err.Message)
        }
    }
    
    /**
     * 取消设置
     */
    static OnCancel() {
        try {
            if (this.settingsGui != "") {
                this.settingsGui.Destroy()
                this.settingsGui := ""
            }
        } catch as err {
            LogError("关闭设置对话框失败: " . err.Message)
        }
    }
}

; ============================================================================
; 应用程序核心控制器 (Application Core Controller)
; ============================================================================

class AppController {
    
    static config := ""
    static isInitialized := false
    static isShuttingDown := false
    
    /**
     * 初始化应用程序
     * 启动流程：加载配置 → 检查目标设备 → 初始化组件 → 显示托盘
     * @returns {Boolean} 是否初始化成功
     */
    static Initialize() {
        try {
            ; 在初始化开始前备份上次的日志
            BackupPreviousLog()
            
            LogInfo("========================================")
            LogInfo("应用程序初始化开始")
            LogInfo("应用程序: " . AppVersion.name . " (" . AppVersion.nameEn . ")")
            LogInfo("版本: " . AppVersion.fullVersion)
            LogInfo("发布日期: " . AppVersion.releaseDate)
            LogInfo("构建时间: " . AppVersion.buildTime . " UTC")
            LogInfo("构建编号: #" . AppVersion.buildNumber)
            LogInfo("========================================")
            
            ; 步骤 0: 检查管理员权限（根据配置决定）
            LogInfo("步骤 0: 检查管理员权限")
            
            ; 加载配置以获取权限检查设置
            tempConfig := ConfigManager.LoadConfig()
            adminCheckMode := ConfigManager.GetConfig(tempConfig, "General_AdminCheck", "prompt")
            
            if (adminCheckMode = "skip") {
                ; 跳过权限检查
                LogInfo("管理员权限检查已禁用（配置：跳过）")
            } else if (adminCheckMode = "prompt") {
                ; 提醒模式：非管理员身份启动时提醒
                if !AdminChecker.CheckOnStartup() {
                    ; 用户选择退出
                    LogInfo("管理员权限检查未通过，初始化终止")
                    return false
                }
            } else if (adminCheckMode = "auto") {
                ; 自动模式：非管理员身份启动时自动提权
                if !AdminChecker.IsAdmin() {
                    LogInfo("检测到非管理员权限，自动请求提权（配置：自动）")
                    if AdminChecker.RestartAsAdmin() {
                        ; 重启成功，退出当前实例
                        return false
                    } else {
                        ; 重启失败，询问是否继续
                        LogWarning("自动提权失败")
                        result := MsgBox("无法自动以管理员身份重新运行。`n`n是否继续以普通权限运行？`n（快捷键可能在某些应用程序中无法工作）", "提权失败", "YesNo Icon!")
                        if (result = "No") {
                            return false
                        }
                    }
                } else {
                    LogInfo("管理员权限检查通过（配置：自动）")
                }
            }
            
            ; 权限状态已在 CheckOnStartup 中记录，无需重复
            
            ; 步骤 1: 加载配置
            LogInfo("步骤 1: 加载配置文件")
            this.config := ConfigManager.LoadConfig()
            
            ; 验证配置
            if !ConfigManager.ValidateConfig(this.config) {
                LogError("配置验证失败，使用默认配置")
                ; 重新创建默认配置
                ConfigManager.CreateDefaultConfig()
                this.config := ConfigManager.LoadConfig()
            }
            
            LogInfo("配置加载成功")
            
            ; 步骤 2: 检查目标设备（首次运行检测）
            LogInfo("步骤 2: 检查目标麦克风设备")
            
            if !DeviceSelector.CheckAndShowDeviceSelector(this.config) {
                LogError("未选择目标设备，初始化失败")
                MsgBox("未选择麦克风设备，应用程序将退出", "初始化失败", "Icon!")
                return false
            }
            
            ; 验证设备可用性（显示警告）
            if !MicrophoneController.IsMicrophoneAvailable(true) {
                LogWarning("目标麦克风设备不可用，但继续运行")
                ; 不退出应用，允许用户稍后选择设备
            } else {
                LogInfo("目标设备检查完成: " . AppState.targetDevice)
            }
            
            ; 步骤 3: 获取初始麦克风状态
            LogInfo("步骤 3: 获取初始麦克风状态")
            AppState.microphoneEnabled := MicrophoneController.GetMicrophoneState()
            LogInfo("初始麦克风状态: " . (AppState.microphoneEnabled ? "启用" : "禁用"))
            
            ; 步骤 4: 初始化托盘管理器
            LogInfo("步骤 4: 初始化托盘管理器")
            TrayManager.CreateTray()
            LogInfo("托盘管理器初始化完成")
            
            ; 步骤 5: 初始化悬浮窗管理器
            LogInfo("步骤 5: 初始化悬浮窗管理器")
            OverlayManager.CreateOverlay(this.config)
            
            ; 根据初始状态显示或隐藏悬浮窗
            if (!AppState.microphoneEnabled) {
                OverlayManager.ShowOverlay()
            }
            
            LogInfo("悬浮窗管理器初始化完成")
            
            ; 步骤 6: 注册全局快捷键
            LogInfo("步骤 6: 注册全局快捷键")
            hotkey := ConfigManager.GetConfig(this.config, "General_Hotkey", "F9")
            
            if HotkeyListener.RegisterHotkey(hotkey) {
                LogInfo("快捷键注册成功: " . hotkey)
            } else {
                LogWarning("快捷键注册失败: " . hotkey)
                ; 快捷键注册失败不影响其他功能，继续运行
            }
            
            ; 步骤 7: 检查并设置开机自动启动
            LogInfo("步骤 7: 检查开机自动启动设置")
            autoStart := ConfigManager.GetConfig(this.config, "General_AutoStart", "0")
            
            if (autoStart = "1") {
                ; 确保注册表项存在
                this.SetAutoStart(true)
                LogInfo("开机自动启动已启用")
            } else {
                LogInfo("开机自动启动未启用")
            }
            
            ; 步骤 8: 启动设备监控定时器
            LogInfo("步骤 8: 启动设备可用性监控")
            SetTimer(() => this.CheckDeviceAvailability(), 1000)  ; 每1秒检查一次
            
            ; 步骤 9: 启动悬浮窗置顶状态监控（防止系统事件导致失去置顶）
            LogInfo("步骤 9: 启动悬浮窗置顶状态监控")
            SetTimer(() => OverlayManager.EnsureAlwaysOnTop(), 5000)  ; 每5秒检查一次
            
            ; 步骤 10: 启动自动检查更新（如果启用）
            if (ConfigManager.GetConfig(this.config, "General_AutoCheckUpdate", "1") = "1") {
                LogInfo("步骤 10: 启动自动检查更新")
                ; 延迟30秒后首次检查，然后每24小时检查一次
                SetTimer(() => TrayManager.AutoCheckForUpdates(), -30000)  ; 30秒后首次检查
                SetTimer(() => TrayManager.AutoCheckForUpdates(), 86400000)  ; 每24小时检查一次
            } else {
                LogInfo("步骤 10: 自动检查更新已禁用")
            }
            
            ; 标记为已初始化
            this.isInitialized := true
            
            LogInfo("========================================")
            LogInfo("应用程序初始化完成")
            LogInfo("========================================")
            
            ; 如果是首次运行，打开设置界面
            if (AppState.firstRun) {
                LogInfo("首次运行检测到，打开设置界面")
                SetTimer(() => SettingsDialog.ShowSettings(), -500)  ; 延迟500ms打开设置
            }
            
            return true
            
        } catch as err {
            LogError("应用程序初始化失败: " . err.Message)
            MsgBox("应用程序初始化失败: " . err.Message . "`n`n请查看日志文件获取详细信息", "初始化错误", "Icon!")
            return false
        }
    }
    
    /**
     * 处理麦克风切换事件
     * 协调麦克风控制器和 UI 更新
     */
    static OnMicrophoneToggle() {
        try {
            LogInfo("处理麦克风切换事件")
            
            ; 检查是否已初始化
            if (!this.isInitialized) {
                LogWarning("应用程序未初始化，无法切换麦克风")
                return
            }
            
            ; 检查设备是否可用（使用全局标记）
            global deviceUnavailable
            if (IsSet(deviceUnavailable) && deviceUnavailable) {
                LogError("麦克风设备不可用，无法切换")
                TrayTip("设备不可用", "目标麦克风设备不可用`n请从托盘菜单选择新设备", 3)
                return
            }
            
            ; 再次检查设备
            if !MicrophoneController.IsMicrophoneAvailable() {
                LogError("麦克风设备不可用，无法切换")
                TrayTip("设备不可用", "麦克风设备不可用，请检查设备连接", 2)
                return
            }
            
            ; 切换麦克风状态
            newState := MicrophoneController.ToggleMicrophone()
            
            ; 更新全局状态
            AppState.microphoneEnabled := newState
            
            ; 标记为内部切换，避免监控定时器重复处理
            global lastMicStateInternal := newState
            
            ; 更新所有 UI 组件
            this.UpdateUI(newState)
            
            LogInfo("麦克风切换完成: " . (newState ? "启用" : "禁用"))
            
        } catch as err {
            LogError("麦克风切换失败: " . err.Message)
            TrayTip("切换失败", "麦克风切换失败: " . err.Message, 2)
        }
    }
    
    /**
     * 更新所有 UI 组件
     * 协调更新托盘图标、菜单和悬浮窗
     * @param {Boolean} micEnabled - 麦克风是否启用
     */
    static UpdateUI(micEnabled) {
        try {
            LogInfo("更新 UI 组件: " . (micEnabled ? "启用" : "禁用"))
            
            ; 更新托盘图标
            TrayManager.UpdateTrayIcon(micEnabled)
            
            ; 更新托盘菜单
            TrayManager.UpdateTrayMenu(micEnabled)
            
            ; 更新悬浮窗
            if (micEnabled) {
                ; 麦克风启用 - 隐藏悬浮窗
                OverlayManager.HideOverlay()
            } else {
                ; 麦克风禁用 - 显示悬浮窗
                OverlayManager.ShowOverlay()
            }
            
            ; 更新悬浮窗图标（如果悬浮窗可见）
            OverlayManager.UpdateOverlayIcon(micEnabled)
            
            LogInfo("UI 更新完成")
            
        } catch as err {
            LogError("UI 更新失败: " . err.Message)
        }
    }
    
    /**
     * 设置或取消开机自动启动
     * 通过修改注册表实现
     * @param {Boolean} enabled - 是否启用自动启动
     * @param {Boolean} showError - 是否显示错误提示（默认 true）
     * @returns {Boolean} 是否设置成功
     */
    static SetAutoStart(enabled, showError := true) {
        try {
            ; 注册表路径
            regPath := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
            regKey := "MicToggleTool"
            
            ; 应用程序完整路径
            appPath := A_ScriptFullPath
            
            if (enabled) {
                ; 启用自动启动 - 写入注册表
                LogInfo("启用开机自动启动: " . appPath)
                
                try {
                    RegWrite(appPath, "REG_SZ", regPath, regKey)
                    
                    ; 更新配置
                    ConfigManager.SaveConfig("General", "AutoStart", "1")
                    
                    LogInfo("开机自动启动已启用")
                    return true
                    
                } catch as err {
                    ; 权限不足或其他错误
                    LogError("写入注册表失败: " . err.Message)
                    
                    if (showError) {
                        MsgBox("设置开机自动启动失败！`n`n错误: " . err.Message . "`n`n可能需要管理员权限", "设置失败", "Icon!")
                    }
                    
                    return false
                }
                
            } else {
                ; 禁用自动启动 - 删除注册表项
                LogInfo("禁用开机自动启动")
                
                try {
                    RegDelete(regPath, regKey)
                    LogInfo("注册表项已删除")
                } catch as err {
                    ; 注册表项可能不存在，或权限不足
                    LogWarning("删除注册表项失败: " . err.Message)
                    ; 这不是严重错误，继续执行
                }
                
                ; 更新配置
                ConfigManager.SaveConfig("General", "AutoStart", "0")
                
                LogInfo("开机自动启动已禁用")
                return true
            }
            
        } catch as err {
            LogError("设置开机自动启动失败: " . err.Message)
            
            if (showError) {
                MsgBox("设置开机自动启动失败！`n`n错误: " . err.Message, "设置失败", "Icon!")
            }
            
            return false
        }
    }
    
    /**
     * 处理权限不足错误
     * 显示详细的错误通知和建议
     * @param {String} operation - 操作名称
     * @param {String} resource - 受影响的资源
     */
    static HandlePermissionError(operation, resource) {
        try {
            LogError("权限不足: 无法" . operation . " (资源: " . resource . ")")
            
            ; 构建详细的通知消息
            notificationTitle := "权限不足"
            notificationMsg := "操作失败: " . operation . "`n"
            notificationMsg .= "原因: 权限不足，无法访问 " . resource . "`n`n"
            notificationMsg .= "建议：`n"
            notificationMsg .= "1. 以管理员身份运行应用程序`n"
            notificationMsg .= "2. 检查系统安全设置`n"
            notificationMsg .= "3. 联系系统管理员获取帮助`n`n"
            notificationMsg .= "注意：该功能将被禁用，其他功能继续正常工作"
            
            ; 显示托盘通知
            TrayTip(notificationTitle, notificationMsg, 5)
            
            ; 播放警告声音
            try {
                SoundBeep(600, 400)
            } catch {
                ; 忽略声音播放错误
            }
            
        } catch as err {
            LogError("处理权限错误失败: " . err.Message)
        }
    }
    
    /**
     * 关闭应用程序
     * 清理资源并退出
     */
    static Shutdown() {
        try {
            ; 防止重复关闭
            if (this.isShuttingDown) {
                LogWarning("应用程序正在关闭中，忽略重复请求")
                return
            }
            
            this.isShuttingDown := true
            
            LogInfo("========================================")
            LogInfo("应用程序关闭开始")
            LogInfo("========================================")
            
            ; 步骤 1: 注销快捷键
            LogInfo("步骤 1: 注销全局快捷键")
            if HotkeyListener.IsRegistered() {
                HotkeyListener.UnregisterHotkey()
            }
            
            ; 步骤 2: 销毁悬浮窗
            LogInfo("步骤 2: 销毁悬浮窗")
            OverlayManager.DestroyOverlay()
            
            ; 步骤 3: 清理托盘图标（AHK 会自动清理）
            LogInfo("步骤 3: 清理托盘图标")
            ; 托盘图标会在退出时自动清理
            
            ; 步骤 4: 清理临时图标文件
            LogInfo("步骤 4: 清理临时图标文件")
            ResourceManager.CleanupTempIcons()
            
            ; 步骤 5: 保存配置（如果有未保存的更改）
            LogInfo("步骤 5: 保存配置")
            ; 配置已经在修改时实时保存，这里不需要额外操作
            
            ; 步骤 6: 记录关闭日志
            LogInfo("========================================")
            LogInfo("应用程序关闭完成")
            LogInfo("========================================")
            
            ; 退出应用程序
            ExitApp()
            
        } catch as err {
            LogError("应用程序关闭失败: " . err.Message)
            
            ; 强制退出
            ExitApp()
        }
    }
    
    /**
     * 重新加载配置
     * 重新读取配置文件并更新所有组件
     * @returns {Boolean} 是否重新加载成功
     */
    static ReloadConfig() {
        try {
            LogInfo("重新加载配置")
            
            ; 加载新配置
            newConfig := ConfigManager.LoadConfig()
            
            ; 验证配置
            if !ConfigManager.ValidateConfig(newConfig) {
                LogError("新配置验证失败，保持当前配置")
                return false
            }
            
            ; 保存新配置
            oldConfig := this.config
            this.config := newConfig
            
            ; 更新快捷键（如果改变）
            oldHotkey := ConfigManager.GetConfig(oldConfig, "General_Hotkey", "F9")
            newHotkey := ConfigManager.GetConfig(newConfig, "General_Hotkey", "F9")
            
            if (oldHotkey != newHotkey) {
                LogInfo("快捷键已改变: " . oldHotkey . " -> " . newHotkey)
                HotkeyListener.UpdateHotkey(newHotkey)
            }
            
            ; 更新悬浮窗配置
            OverlayManager.config := newConfig
            OverlayManager.UpdateOverlayPosition()
            OverlayManager.UpdateOverlayStyle()
            
            ; 更新开机自动启动
            autoStart := ConfigManager.GetConfig(newConfig, "General_AutoStart", "0")
            this.SetAutoStart(autoStart = "1")
            
            LogInfo("配置重新加载完成")
            
            return true
            
        } catch as err {
            LogError("重新加载配置失败: " . err.Message)
            return false
        }
    }
    
    /**
     * 定期检查设备可用性和状态同步
     * 如果设备不可用，更新托盘图标并提示用户
     * 如果设备状态被外部改变，同步UI状态
     */
    static CheckDeviceAvailability() {
        try {
            static lastAvailableState := ""  ; 空字符串表示未初始化
            static lastMicState := true
            static checkCount := 0
            static unavailableLogCount := 0  ; 设备不可用时的日志计数
            
            ; 每300次检查记录一次日志（5分钟，避免日志过多）
            checkCount++
            if (Mod(checkCount, 300) = 0) {
                LogInfo("设备监控运行中 (检查次数: " . checkCount . ")")
            }
            
            ; 检查设备是否可用（不在这里显示警告，由状态变化时统一处理）
            isAvailable := MicrophoneController.IsMicrophoneAvailable(false)
            
            ; 只在状态变化或每5分钟记录一次（设备可用时）
            if (isAvailable && Mod(checkCount, 300) = 0) {
                LogInfo("设备可用性检查结果: 可用 (设备: " . AppState.targetDeviceName . ")")
            }
            
            ; 设置全局标记
            global deviceUnavailable := !isAvailable
            
            ; 初始化lastAvailableState
            if (lastAvailableState = "") {
                lastAvailableState := isAvailable
            }
            
            if (!isAvailable && lastAvailableState) {
                ; 设备刚变为不可用
                LogWarning("检测到设备不可用: " . AppState.targetDeviceName)
                unavailableLogCount := 0  ; 重置计数器
                
                ; 更新托盘图标为灰色
                if (IsSet(TrayManager)) {
                    TrayManager.UpdateTrayIconUnavailable()
                }
                
                ; 显示通知
                try {
                    TrayTip("麦克风设备不可用", 
                        "设备 '" . AppState.targetDeviceName . "' 不可用`n`n可能原因：`n- 设备已断开连接`n- 设备被其他程序占用`n- 设备驱动异常`n`n请从托盘菜单选择新设备", 
                        "Iconx")
                    LogInfo("已发送设备不可用通知")
                } catch as err {
                    LogError("发送通知失败: " . err.Message)
                }
                
                lastAvailableState := false
                
            } else if (!isAvailable && !lastAvailableState) {
                ; 设备持续不可用，每5分钟记录一次
                unavailableLogCount++
                if (Mod(unavailableLogCount, 300) = 0) {
                    LogWarning("设备持续不可用: " . AppState.targetDeviceName . " (已持续 " . (unavailableLogCount // 60) . " 分钟)")
                }
                
            } else if (isAvailable && lastAvailableState = false) {
                ; 设备恢复可用
                LogInfo("设备已恢复可用: " . AppState.targetDeviceName)
                
                ; 更新托盘图标为正常状态
                currentState := MicrophoneController.GetMicrophoneState()
                AppState.microphoneEnabled := currentState
                lastMicState := currentState
                
                if (IsSet(TrayManager)) {
                    TrayManager.UpdateTrayIcon(currentState)
                    TrayManager.UpdateTrayMenu(currentState)
                }
                
                ; 更新悬浮窗
                if (IsSet(OverlayManager)) {
                    if (currentState) {
                        OverlayManager.HideOverlay()
                    } else {
                        OverlayManager.ShowOverlay()
                    }
                }
                
                ; 显示通知
                try {
                    TrayTip("麦克风设备已恢复", "设备 '" . AppState.targetDeviceName . "' 已恢复可用", "Iconi")
                    LogInfo("已发送设备恢复通知")
                } catch as err {
                    LogError("发送通知失败: " . err.Message)
                }
                
                lastAvailableState := true
                
            } else if (isAvailable) {
                ; 设备可用，检查状态是否被外部改变
                currentState := MicrophoneController.GetMicrophoneState()
                
                ; 检查是否是内部切换（避免重复处理）
                global lastMicStateInternal
                if (IsSet(lastMicStateInternal) && currentState = lastMicStateInternal) {
                    ; 这是内部切换导致的状态变化，已经处理过了
                    lastMicState := currentState
                    try {
                        lastMicStateInternal := unset  ; 清除标记
                    } catch {
                        ; 忽略 unset 错误
                    }
                } else if (currentState != lastMicState) {
                    ; 状态被外部改变（其他应用或手动改变）
                    LogInfo("检测到麦克风状态被外部改变: " . (currentState ? "启用" : "禁用"))
                    
                    ; 同步内部状态
                    AppState.microphoneEnabled := currentState
                    lastMicState := currentState
                    
                    ; 更新UI
                    if (IsSet(TrayManager)) {
                        TrayManager.UpdateTrayIcon(currentState)
                        TrayManager.UpdateTrayMenu(currentState)
                    }
                    
                    ; 更新悬浮窗
                    if (IsSet(OverlayManager)) {
                        ; 先更新图标状态
                        OverlayManager.UpdateOverlayIcon(currentState)
                        
                        ; 然后显示或隐藏
                        if (currentState) {
                            OverlayManager.HideOverlay()
                        } else {
                            OverlayManager.ShowOverlay()
                        }
                    }
                }
            }
            
        } catch as err {
            LogError("检查设备可用性失败: " . err.Message)
        }
    }
    
    /**
     * 获取应用程序状态信息
     * @returns {String} 状态信息字符串
     */
    static GetStatusInfo() {
        try {
            info := ""
            info .= "应用程序状态信息`n"
            info .= "========================================`n"
            info .= "已初始化: " . (this.isInitialized ? "是" : "否") . "`n"
            info .= "管理员权限: " . AdminChecker.GetAdminStatus() . "`n"
            info .= "麦克风状态: " . (AppState.microphoneEnabled ? "启用" : "禁用") . "`n"
            info .= "目标设备: " . AppState.targetDevice . "`n"
            info .= "设备可用: " . (MicrophoneController.IsMicrophoneAvailable() ? "是" : "否") . "`n"
            info .= "快捷键: " . HotkeyListener.GetCurrentHotkey() . "`n"
            info .= "快捷键已注册: " . (HotkeyListener.IsRegistered() ? "是" : "否") . "`n"
            info .= "悬浮窗可见: " . (AppState.overlayVisible ? "是" : "否") . "`n"
            
            ; 获取配置信息
            if (this.config != "") {
                info .= "`n配置信息`n"
                info .= "========================================`n"
                info .= "快捷键: " . ConfigManager.GetConfig(this.config, "General_Hotkey", "未设置") . "`n"
                info .= "开机启动: " . (ConfigManager.GetConfig(this.config, "General_AutoStart", "0") = "1" ? "是" : "否") . "`n"
                info .= "悬浮窗启用: " . (ConfigManager.GetConfig(this.config, "Overlay_Enabled", "1") = "1" ? "是" : "否") . "`n"
                info .= "悬浮窗位置: " . ConfigManager.GetConfig(this.config, "Overlay_Position", "未设置") . "`n"
            }
            
            return info
            
        } catch as err {
            return "获取状态信息失败: " . err.Message
        }
    }
}

; ============================================================================
; 日志记录工具 (Logging Utilities)
; ============================================================================

/**
 * 记录错误日志
 * @param {String} message - 错误消息
 */
LogError(message) {
    LogMessage("ERROR", message)
}

/**
 * 记录警告日志
 * @param {String} message - 警告消息
 */
LogWarning(message) {
    LogMessage("WARNING", message)
}

/**
 * 记录信息日志
 * @param {String} message - 信息消息
 */
LogInfo(message) {
    LogMessage("INFO", message)
}

/**
 * 记录调试日志
 * @param {String} message - 调试消息
 */
LogDebug(message) {
    ; 调试日志默认不记录，可以通过配置启用
    ; LogMessage("DEBUG", message)
}

/**
 * 记录日志消息
 * @param {String} level - 日志级别 (ERROR, WARNING, INFO, DEBUG)
 * @param {String} message - 日志消息
 */
LogMessage(level, message) {
    try {
        logPath := A_ScriptDir "\MicToggleTool.log"
        
        ; 检查日志文件大小，如果超过 5MB 则进行轮转
        if FileExist(logPath) {
            try {
                fileSize := FileGetSize(logPath)
                maxSize := 5 * 1024 * 1024  ; 5MB
                
                if (fileSize > maxSize) {
                    RotateLogFile(logPath)
                }
            } catch {
                ; 获取文件大小失败，忽略
            }
        }
        
        ; 格式化日志条目
        timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        
        ; 对齐日志级别（固定宽度）
        levelPadded := level
        while (StrLen(levelPadded) < 7) {
            levelPadded .= " "
        }
        
        logEntry := "[" . timestamp . "] [" . levelPadded . "] " . message . "`n"
        
        ; 追加到日志文件
        FileAppend(logEntry, logPath, "UTF-8")
        
    } catch as err {
        ; 日志记录失败，静默忽略
        ; 避免无限递归，不记录日志错误
    }
}

/**
 * 轮转日志文件
 * 将当前日志文件重命名为带时间戳的备份文件
 * @param {String} logPath - 日志文件路径
 */
RotateLogFile(logPath) {
    try {
        ; 生成备份文件名（带时间戳）
        timestamp := FormatTime(, "yyyyMMdd_HHmmss")
        backupPath := logPath . ".backup_" . timestamp
        
        ; 重命名当前日志文件
        FileMove(logPath, backupPath, 1)
        
        ; 在新日志文件中记录轮转信息
        FileAppend("[" . FormatTime(, "yyyy-MM-dd HH:mm:ss") . "] [INFO   ] 日志文件已轮转，旧日志备份到: " . backupPath . "`n", logPath, "UTF-8")
        
        ; 清理旧的备份文件（保留最近5个）
        CleanupOldLogBackups(logPath)
        
    } catch as err {
        ; 轮转失败，忽略错误
    }
}

/**
 * 清理旧的日志备份文件
 * 保留最近的N个备份文件，删除更旧的备份
 * @param {String} logPath - 日志文件路径
 */
CleanupOldLogBackups(logPath) {
    try {
        ; 获取所有备份文件
        backupPattern := logPath . ".backup_*"
        backupFiles := []
        
        Loop Files, backupPattern {
            backupFiles.Push({path: A_LoopFileFullPath, time: A_LoopFileTimeModified})
        }
        
        ; 如果备份文件数量超过5个，删除最旧的
        if (backupFiles.Length > 5) {
            ; 按时间排序（最新的在前）
            sortedFiles := []
            for file in backupFiles {
                sortedFiles.Push(file)
            }
            
            ; 简单的冒泡排序（按时间降序）
            Loop sortedFiles.Length - 1 {
                i := A_Index
                Loop sortedFiles.Length - i {
                    j := A_Index
                    if (sortedFiles[j].time < sortedFiles[j + 1].time) {
                        temp := sortedFiles[j]
                        sortedFiles[j] := sortedFiles[j + 1]
                        sortedFiles[j + 1] := temp
                    }
                }
            }
            
            ; 删除超过5个的旧备份
            Loop sortedFiles.Length {
                if (A_Index > 5) {
                    try {
                        FileDelete(sortedFiles[A_Index].path)
                    } catch {
                        ; 删除失败，忽略
                    }
                }
            }
        }
        
    } catch as err {
        ; 清理失败，忽略错误
    }
}

/**
 * 备份上次运行的日志文件
 * 在应用程序启动时调用，将上次的日志重命名为带时间戳的备份
 */
BackupPreviousLog() {
    try {
        logPath := A_ScriptDir "\MicToggleTool.log"
        
        ; 如果日志文件存在，备份它
        if FileExist(logPath) {
            ; 获取日志文件的修改时间作为备份时间戳
            fileTime := FileGetTime(logPath, "M")
            timestamp := FormatTime(fileTime, "yyyyMMdd_HHmmss")
            backupPath := logPath . ".prev_" . timestamp
            
            ; 重命名为上次运行的日志
            try {
                FileMove(logPath, backupPath, 1)
            } catch {
                ; 如果重命名失败，尝试复制
                try {
                    FileCopy(logPath, backupPath, 1)
                    FileDelete(logPath)
                } catch {
                    ; 备份失败，忽略
                }
            }
            
            ; 清理旧的prev备份（只保留最近3个）
            CleanupOldPrevBackups(logPath)
        }
        
    } catch as err {
        ; 备份失败，忽略错误，不影响程序启动
    }
}

/**
 * 清理旧的prev日志备份
 * 保留最近的3个prev备份文件
 * @param {String} logPath - 日志文件路径
 */
CleanupOldPrevBackups(logPath) {
    try {
        ; 获取所有prev备份文件
        prevPattern := logPath . ".prev_*"
        prevFiles := []
        
        Loop Files, prevPattern {
            prevFiles.Push({path: A_LoopFileFullPath, time: A_LoopFileTimeModified})
        }
        
        ; 如果备份文件数量超过3个，删除最旧的
        if (prevFiles.Length > 3) {
            ; 按时间排序（最新的在前）
            sortedFiles := []
            for file in prevFiles {
                sortedFiles.Push(file)
            }
            
            ; 简单的冒泡排序（按时间降序）
            Loop sortedFiles.Length - 1 {
                i := A_Index
                Loop sortedFiles.Length - i {
                    j := A_Index
                    if (sortedFiles[j].time < sortedFiles[j + 1].time) {
                        temp := sortedFiles[j]
                        sortedFiles[j] := sortedFiles[j + 1]
                        sortedFiles[j + 1] := temp
                    }
                }
            }
            
            ; 删除超过3个的旧备份
            Loop sortedFiles.Length {
                if (A_Index > 3) {
                    try {
                        FileDelete(sortedFiles[A_Index].path)
                    } catch {
                        ; 删除失败，忽略
                    }
                }
            }
        }
        
    } catch as err {
        ; 清理失败，忽略错误
    }
}

/**
 * 获取日志文件路径
 * @returns {String} 日志文件完整路径
 */
GetLogFilePath() {
    return A_ScriptDir "\MicToggleTool.log"
}

/**
 * 清空日志文件
 * 删除当前日志文件和所有备份
 */
ClearAllLogs() {
    try {
        logPath := A_ScriptDir "\MicToggleTool.log"
        
        ; 删除当前日志文件
        if FileExist(logPath) {
            FileDelete(logPath)
        }
        
        ; 删除所有备份文件
        backupPattern := logPath . ".backup_*"
        Loop Files, backupPattern {
            try {
                FileDelete(A_LoopFileFullPath)
            } catch {
                ; 删除失败，忽略
            }
        }
        
        LogInfo("所有日志文件已清空")
        
    } catch as err {
        ; 清空失败，忽略错误
    }
}

; ============================================================================
; 应用程序入口
; ============================================================================

; 测试配置管理器
TestConfigManager() {
    ; 加载配置
    config := ConfigManager.LoadConfig()
    
    ; 验证配置
    if ConfigManager.ValidateConfig(config) {
        MsgBox("配置加载成功！`n`n快捷键: " . config["General_Hotkey"] . "`n悬浮窗文本: " . config["Overlay_Text"])
    } else {
        MsgBox("配置验证失败！")
    }
}

; 取消注释以下行来测试配置管理器
; TestConfigManager()

; 测试麦克风控制器
TestMicrophoneController() {
    ; 初始化配置
    config := ConfigManager.LoadConfig()
    AppState.targetDevice := config["General_TargetDevice"]
    
    ; 获取所有麦克风设备
    devices := MicrophoneController.GetAllMicrophones()
    deviceList := "找到 " . devices.Length . " 个麦克风设备:`n`n"
    for index, device in devices {
        deviceList .= index . ". " . device.name . " (ID: " . (device.id = "" ? "默认" : device.id) . ")`n"
    }
    
    ; 检查设备可用性
    isAvailable := MicrophoneController.IsMicrophoneAvailable()
    deviceList .= "`n目标设备可用: " . (isAvailable ? "是" : "否")
    
    ; 获取当前状态
    currentState := MicrophoneController.GetMicrophoneState()
    deviceList .= "`n当前麦克风状态: " . (currentState ? "启用" : "禁用")
    
    MsgBox(deviceList)
    
    ; 询问是否测试切换功能
    result := MsgBox("是否测试麦克风切换功能？", "测试确认", "YesNo")
    if (result = "Yes") {
        ; 切换麦克风状态
        newState := MicrophoneController.ToggleMicrophone()
        MsgBox("麦克风已切换到: " . (newState ? "启用" : "禁用"))
        
        ; 等待2秒后切换回来
        Sleep(2000)
        finalState := MicrophoneController.ToggleMicrophone()
        MsgBox("麦克风已恢复到: " . (finalState ? "启用" : "禁用"))
    }
}

; 取消注释以下行来测试麦克风控制器
; TestMicrophoneController()

; 测试设备选择对话框
TestDeviceSelector() {
    ; 初始化配置
    config := ConfigManager.LoadConfig()
    
    ; 测试首次运行检测
    MsgBox("测试首次运行检测...`n`n当前目标设备: " . config["General_TargetDevice"])
    
    if DeviceSelector.ShouldShowDeviceSelector(config) {
        MsgBox("检测到需要显示设备选择对话框")
        
        ; 显示设备选择对话框
        selectedDeviceId := DeviceSelector.ShowDeviceSelector()
        
        if (selectedDeviceId != "") {
            MsgBox("已选择设备 ID: " . (selectedDeviceId = "" ? "默认设备" : selectedDeviceId))
            
            ; 验证设备是否可用
            AppState.targetDevice := selectedDeviceId
            if MicrophoneController.IsMicrophoneAvailable() {
                MsgBox("设备验证成功！设备可用。")
            } else {
                MsgBox("设备验证失败！设备不可用。")
            }
        } else {
            MsgBox("用户取消了设备选择")
        }
    } else {
        MsgBox("不需要显示设备选择对话框`n目标设备已配置且可用")
    }
}

; 取消注释以下行来测试设备选择对话框
; TestDeviceSelector()

; 测试完整的首次运行流程
TestFirstRunFlow() {
    ; 初始化配置
    config := ConfigManager.LoadConfig()
    
    MsgBox("模拟首次运行流程...`n`n这将检查并显示设备选择对话框（如果需要）")
    
    ; 执行首次运行检测
    if DeviceSelector.CheckAndShowDeviceSelector(config) {
        MsgBox("设备选择成功！`n`n目标设备: " . AppState.targetDevice . "`n设备可用: " . (MicrophoneController.IsMicrophoneAvailable() ? "是" : "否"))
    } else {
        MsgBox("设备选择失败或用户取消")
    }
}

; 取消注释以下行来测试完整的首次运行流程
; TestFirstRunFlow()

; 测试托盘管理器
TestTrayManager() {
    ; 初始化配置
    config := ConfigManager.LoadConfig()
    
    ; 检查并选择设备
    if !DeviceSelector.CheckAndShowDeviceSelector(config) {
        MsgBox("未选择设备，无法继续测试")
        return
    }
    
    ; 获取当前麦克风状态
    AppState.microphoneEnabled := MicrophoneController.GetMicrophoneState()
    
    ; 创建托盘
    TrayManager.CreateTray()
    
    MsgBox("托盘管理器测试已启动！`n`n功能说明：`n- 左键点击托盘图标可切换麦克风状态`n- 右键点击托盘图标显示菜单`n- 菜单包含：状态显示、切换、选择设备、设置、开机启动、退出`n`n请测试各项功能，完成后从托盘菜单选择退出。", "托盘管理器测试", "Iconi")
    
    LogInfo("托盘管理器测试已启动")
}

; 取消注释以下行来测试托盘管理器
; TestTrayManager()

; 测试悬浮窗管理器
TestOverlayManager() {
    ; 初始化配置
    config := ConfigManager.LoadConfig()
    
    MsgBox("悬浮窗管理器测试开始！`n`n将测试以下功能：`n1. 创建悬浮窗`n2. 显示悬浮窗`n3. 更新位置和样式`n4. 隐藏悬浮窗`n5. 更新图标", "悬浮窗管理器测试", "Iconi")
    
    ; 创建悬浮窗
    OverlayManager.CreateOverlay(config)
    MsgBox("悬浮窗已创建（当前隐藏）`n`n点击确定显示悬浮窗", "步骤 1", "Iconi")
    
    ; 显示悬浮窗
    OverlayManager.ShowOverlay()
    MsgBox("悬浮窗已显示在屏幕右上角`n`n点击确定测试位置更新", "步骤 2", "Iconi")
    
    ; 测试不同位置
    positions := ["TopLeft", "TopRight", "BottomLeft", "BottomRight", "TopCenter", "BottomCenter"]
    for index, pos in positions {
        ; 更新配置
        ConfigManager.SaveConfig("Overlay", "Position", pos)
        config["Overlay_Position"] := pos
        OverlayManager.config := config
        
        ; 更新位置
        OverlayManager.UpdateOverlayPosition()
        
        MsgBox("悬浮窗位置已更新为: " . pos . "`n`n点击确定继续", "步骤 3." . index, "Iconi")
    }
    
    ; 恢复默认位置
    ConfigManager.SaveConfig("Overlay", "Position", "TopRight")
    config["Overlay_Position"] := "TopRight"
    OverlayManager.config := config
    OverlayManager.UpdateOverlayPosition()
    
    ; 测试样式更新
    MsgBox("测试样式更新`n`n将改变背景色为蓝色", "步骤 4", "Iconi")
    ConfigManager.SaveConfig("Overlay", "BackgroundColor", "0000FF")
    config["Overlay_BackgroundColor"] := "0000FF"
    OverlayManager.config := config
    OverlayManager.UpdateOverlayStyle()
    
    Sleep(2000)
    
    ; 恢复默认样式
    ConfigManager.SaveConfig("Overlay", "BackgroundColor", "FF0000")
    config["Overlay_BackgroundColor"] := "FF0000"
    OverlayManager.config := config
    OverlayManager.UpdateOverlayStyle()
    
    MsgBox("样式已恢复为红色`n`n点击确定测试图标更新", "步骤 5", "Iconi")
    
    ; 测试图标更新
    OverlayManager.UpdateOverlayIcon(false)
    MsgBox("图标已更新为禁用状态`n`n点击确定测试启用状态图标", "步骤 6", "Iconi")
    
    OverlayManager.UpdateOverlayIcon(true)
    MsgBox("图标已更新为启用状态`n`n点击确定隐藏悬浮窗", "步骤 7", "Iconi")
    
    ; 隐藏悬浮窗
    OverlayManager.HideOverlay()
    MsgBox("悬浮窗已隐藏`n`n点击确定再次显示", "步骤 8", "Iconi")
    
    ; 再次显示
    OverlayManager.ShowOverlay()
    MsgBox("悬浮窗已再次显示`n`n测试完成！点击确定销毁悬浮窗", "步骤 9", "Iconi")
    
    ; 销毁悬浮窗
    OverlayManager.DestroyOverlay()
    MsgBox("悬浮窗管理器测试完成！`n`n所有功能测试通过。", "测试完成", "Iconi")
    
    LogInfo("悬浮窗管理器测试完成")
}

; 取消注释以下行来测试悬浮窗管理器
; TestOverlayManager()

; 测试快捷键监听器
TestHotkeyListener() {
    ; 初始化配置
    config := ConfigManager.LoadConfig()
    
    ; 检查并选择设备
    if !DeviceSelector.CheckAndShowDeviceSelector(config) {
        MsgBox("未选择设备，无法继续测试")
        return
    }
    
    ; 获取当前麦克风状态
    AppState.microphoneEnabled := MicrophoneController.GetMicrophoneState()
    
    ; 创建托盘（用于显示通知和状态）
    TrayManager.CreateTray()
    
    ; 创建悬浮窗
    OverlayManager.CreateOverlay(config)
    
    MsgBox("快捷键监听器测试开始！`n`n将测试以下功能：`n1. 注册快捷键`n2. 测试快捷键触发`n3. 更新快捷键`n4. 测试快捷键冲突处理`n5. 注销快捷键`n`n默认快捷键: " . config["General_Hotkey"], "快捷键监听器测试", "Iconi")
    
    ; 步骤 1: 注册快捷键
    hotkey := ConfigManager.GetConfig(config, "General_Hotkey", "F9")
    if HotkeyListener.RegisterHotkey(hotkey) {
        MsgBox("快捷键已注册: " . hotkey . "`n`n请按下快捷键测试麦克风切换功能`n（观察托盘图标和悬浮窗变化）`n`n测试完成后点击确定继续", "步骤 1: 注册成功", "Iconi")
    } else {
        MsgBox("快捷键注册失败！`n`n可能是快捷键冲突，请检查日志", "步骤 1: 注册失败", "Icon!")
        return
    }
    
    ; 步骤 2: 验证快捷键状态
    isRegistered := HotkeyListener.IsRegistered()
    currentHotkey := HotkeyListener.GetCurrentHotkey()
    MsgBox("快捷键状态验证：`n`n已注册: " . (isRegistered ? "是" : "否") . "`n当前快捷键: " . currentHotkey . "`n`n点击确定测试快捷键更新", "步骤 2: 状态验证", "Iconi")
    
    ; 步骤 3: 更新快捷键
    newHotkey := "F10"
    MsgBox("将快捷键更新为: " . newHotkey . "`n`n点击确定执行更新", "步骤 3: 更新快捷键", "Iconi")
    
    if HotkeyListener.UpdateHotkey(newHotkey) {
        MsgBox("快捷键已更新为: " . newHotkey . "`n`n请按下新的快捷键测试`n（旧快捷键应该不再工作）`n`n测试完成后点击确定继续", "步骤 3: 更新成功", "Iconi")
    } else {
        MsgBox("快捷键更新失败！", "步骤 3: 更新失败", "Icon!")
    }
    
    ; 步骤 4: 测试无效快捷键
    invalidHotkey := "InvalidKey123"
    MsgBox("测试无效快捷键: " . invalidHotkey . "`n`n这应该会失败并显示错误通知`n`n点击确定执行测试", "步骤 4: 测试错误处理", "Iconi")
    
    if !HotkeyListener.UpdateHotkey(invalidHotkey) {
        MsgBox("正确！无效快捷键被拒绝`n`n当前快捷键应该保持为: " . HotkeyListener.GetCurrentHotkey() . "`n`n点击确定继续", "步骤 4: 错误处理正确", "Iconi")
    } else {
        MsgBox("错误！无效快捷键不应该被接受", "步骤 4: 错误处理失败", "Icon!")
    }
    
    ; 步骤 5: 恢复原始快捷键
    MsgBox("恢复原始快捷键: " . hotkey . "`n`n点击确定执行", "步骤 5: 恢复快捷键", "Iconi")
    HotkeyListener.UpdateHotkey(hotkey)
    
    MsgBox("快捷键已恢复为: " . HotkeyListener.GetCurrentHotkey() . "`n`n请再次测试快捷键功能`n`n测试完成后点击确定继续", "步骤 5: 恢复成功", "Iconi")
    
    ; 步骤 6: 注销快捷键
    MsgBox("测试注销快捷键`n`n点击确定执行", "步骤 6: 注销快捷键", "Iconi")
    
    if HotkeyListener.UnregisterHotkey() {
        MsgBox("快捷键已注销`n`n现在按下快捷键应该不会有任何反应`n`n请测试确认，然后点击确定", "步骤 6: 注销成功", "Iconi")
    } else {
        MsgBox("快捷键注销失败！", "步骤 6: 注销失败", "Icon!")
    }
    
    ; 验证注销状态
    isRegistered := HotkeyListener.IsRegistered()
    MsgBox("注销状态验证：`n`n已注册: " . (isRegistered ? "是" : "否") . "`n`n应该显示 '否'", "步骤 6: 状态验证", "Iconi")
    
    ; 步骤 7: 重新注册快捷键
    MsgBox("重新注册快捷键: " . hotkey . "`n`n点击确定执行", "步骤 7: 重新注册", "Iconi")
    
    if HotkeyListener.RegisterHotkey(hotkey) {
        MsgBox("快捷键已重新注册: " . hotkey . "`n`n请测试快捷键功能是否恢复正常`n`n测试完成后点击确定", "步骤 7: 重新注册成功", "Iconi")
    }
    
    ; 测试完成
    MsgBox("快捷键监听器测试完成！`n`n所有功能测试通过：`n✓ 注册快捷键`n✓ 快捷键触发回调`n✓ 更新快捷键`n✓ 错误处理（无效快捷键）`n✓ 注销快捷键`n✓ 重新注册快捷键`n`n应用程序将继续运行，您可以继续测试快捷键功能`n从托盘菜单选择退出以结束测试", "测试完成", "Iconi")
    
    LogInfo("快捷键监听器测试完成")
}

; 取消注释以下行来测试快捷键监听器
; TestHotkeyListener()

; ============================================================================
; 主应用程序入口 (Main Application Entry Point)
; ============================================================================

/**
 * 主应用程序启动函数
 * 初始化并启动应用程序
 */
Main() {
    try {
        ; 设置应用程序为单实例运行
        #SingleInstance Force
        
        ; 初始化应用程序
        if AppController.Initialize() {
            ; 初始化成功，进入消息循环
            LogInfo("应用程序正在运行...")
            
            ; AHK v2 会自动进入消息循环，脚本会持续运行
            ; 直到调用 ExitApp() 或用户关闭应用
            
        } else {
            ; 初始化失败，退出应用
            LogError("应用程序初始化失败，退出")
            ExitApp()
        }
        
    } catch as err {
        ; 捕获未处理的异常
        LogError("应用程序启动失败: " . err.Message)
        MsgBox("应用程序启动失败: " . err.Message . "`n`n请查看日志文件获取详细信息", "启动错误", "Icon!")
        ExitApp()
    }
}

; 启动主应用程序
Main()
