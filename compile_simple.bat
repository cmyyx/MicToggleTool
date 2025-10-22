@echo off
chcp 65001 >nul
echo ===============================================================================
echo 麦克风快捷控制工具 - 简化编译脚本
echo ===============================================================================
echo.

REM 直接使用 Ahk2Exe 编译
echo [信息] 开始编译...
"D:\Tools\AutoHotkey\Compiler\Ahk2Exe.exe" /in "MicToggleTool.ahk" /out "MicToggleTool.exe" /icon "icons\mic_enabled.ico"

if %ERRORLEVEL% equ 0 (
    echo.
    echo [成功] 编译完成！
    echo.
    echo 输出文件: MicToggleTool.exe
    if exist MicToggleTool.exe (
        for %%A in (MicToggleTool.exe) do echo 文件大小: %%~zA 字节
    )
    echo.
    echo 注意：UAC 清单已通过脚本内的编译指令嵌入
    echo 请测试程序是否正常运行并显示 UAC 提示
) else (
    echo.
    echo [错误] 编译失败！错误代码: %ERRORLEVEL%
)

echo.
pause
