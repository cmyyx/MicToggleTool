; 创建统一风格的麦克风图标（启用、禁用、不可用）
#Requires AutoHotkey v2.0
#SingleInstance Force

; 创建icons目录
if !DirExist("icons") {
    DirCreate("icons")
}

; 创建三个图标
CreateEnabledIcon()
CreateDisabledIcon()
CreateUnavailableIcon()

MsgBox("所有图标已创建完成！`n`n已创建：`n- mic_enabled.ico (绿色麦克风)`n- mic_disabled.ico (红色麦克风+斜杠)`n- mic_unavailable.ico (灰色麦克风+圆圈叉号)`n`n图标位置: " . A_ScriptDir . "\icons\", "图标创建完成", "Iconi")

; ===== 创建启用状态图标（绿色麦克风） =====
CreateEnabledIcon() {
    try {
        size := 32
        outputPath := A_ScriptDir "\icons\mic_enabled.png"
        
        pToken := Gdip_Startup()
        if (!pToken) {
            return false
        }
        
        pBitmap := Gdip_CreateBitmap(size, size)
        pGraphics := Gdip_GraphicsFromImage(pBitmap)
        Gdip_SetSmoothingMode(pGraphics, 4)
        Gdip_GraphicsClear(pGraphics, 0x00000000)
        
        ; 绿色
        pBrush := Gdip_BrushCreateSolid(0xFF00AA00)
        pPen := Gdip_CreatePen(0xFF00AA00, 2.5)
        
        ; 绘制麦克风主体
        Gdip_FillRoundedRectangle(pGraphics, pBrush, 11, 6, 10, 14, 2)
        
        ; 绘制麦克风底座弧线
        Gdip_DrawArc(pGraphics, pPen, 8, 18, 16, 10, 0, 180)
        
        ; 绘制麦克风支架
        Gdip_DrawLine(pGraphics, pPen, 16, 23, 16, 28)
        
        ; 绘制麦克风底座横线
        Gdip_DrawLine(pGraphics, pPen, 12, 28, 20, 28)
        
        ; 保存
        Gdip_SaveBitmapToFile(pBitmap, outputPath)
        
        ; 清理
        Gdip_DeleteBrush(pBrush)
        Gdip_DeletePen(pPen)
        Gdip_DeleteGraphics(pGraphics)
        Gdip_DisposeImage(pBitmap)
        Gdip_Shutdown(pToken)
        
        ; 复制为ICO
        if FileExist(outputPath) {
            try {
                FileCopy(outputPath, A_ScriptDir "\icons\mic_enabled.ico", 1)
            }
        }
        
        return true
    } catch as err {
        MsgBox("创建启用图标失败: " . err.Message)
        return false
    }
}

; ===== 创建禁用状态图标（红色麦克风+斜杠） =====
CreateDisabledIcon() {
    try {
        size := 32
        outputPath := A_ScriptDir "\icons\mic_disabled.png"
        
        pToken := Gdip_Startup()
        if (!pToken) {
            return false
        }
        
        pBitmap := Gdip_CreateBitmap(size, size)
        pGraphics := Gdip_GraphicsFromImage(pBitmap)
        Gdip_SetSmoothingMode(pGraphics, 4)
        Gdip_GraphicsClear(pGraphics, 0x00000000)
        
        ; 红色
        pBrush := Gdip_BrushCreateSolid(0xFFCC0000)
        pPen := Gdip_CreatePen(0xFFCC0000, 2.5)
        
        ; 绘制麦克风主体
        Gdip_FillRoundedRectangle(pGraphics, pBrush, 11, 6, 10, 14, 2)
        
        ; 绘制麦克风底座弧线
        Gdip_DrawArc(pGraphics, pPen, 8, 18, 16, 10, 0, 180)
        
        ; 绘制麦克风支架
        Gdip_DrawLine(pGraphics, pPen, 16, 23, 16, 28)
        
        ; 绘制麦克风底座横线
        Gdip_DrawLine(pGraphics, pPen, 12, 28, 20, 28)
        
        ; 绘制斜杠（从左上到右下）
        pPenSlash := Gdip_CreatePen(0xFFCC0000, 3.0)
        Gdip_DrawLine(pGraphics, pPenSlash, 6, 6, 26, 26)
        
        ; 保存
        Gdip_SaveBitmapToFile(pBitmap, outputPath)
        
        ; 清理
        Gdip_DeleteBrush(pBrush)
        Gdip_DeletePen(pPen)
        Gdip_DeletePen(pPenSlash)
        Gdip_DeleteGraphics(pGraphics)
        Gdip_DisposeImage(pBitmap)
        Gdip_Shutdown(pToken)
        
        ; 复制为ICO
        if FileExist(outputPath) {
            try {
                FileCopy(outputPath, A_ScriptDir "\icons\mic_disabled.ico", 1)
            }
        }
        
        return true
    } catch as err {
        MsgBox("创建禁用图标失败: " . err.Message)
        return false
    }
}

; ===== 创建不可用状态图标（灰色麦克风+圆圈叉号） =====
CreateUnavailableIcon() {
    try {
        size := 32
        outputPath := A_ScriptDir "\icons\mic_unavailable.png"
        
        pToken := Gdip_Startup()
        if (!pToken) {
            return false
        }
        
        pBitmap := Gdip_CreateBitmap(size, size)
        pGraphics := Gdip_GraphicsFromImage(pBitmap)
        Gdip_SetSmoothingMode(pGraphics, 4)
        Gdip_GraphicsClear(pGraphics, 0x00000000)
        
        ; 灰色
        pBrush := Gdip_BrushCreateSolid(0xFF808080)
        pPen := Gdip_CreatePen(0xFF808080, 2.5)
        
        ; 绘制麦克风主体
        Gdip_FillRoundedRectangle(pGraphics, pBrush, 11, 6, 10, 14, 2)
        
        ; 绘制麦克风底座弧线
        Gdip_DrawArc(pGraphics, pPen, 8, 18, 16, 10, 0, 180)
        
        ; 绘制麦克风支架
        Gdip_DrawLine(pGraphics, pPen, 16, 23, 16, 28)
        
        ; 绘制麦克风底座横线
        Gdip_DrawLine(pGraphics, pPen, 12, 28, 20, 28)
        
        ; 绘制圆圈+叉号（右下角）
        pBrushCircle := Gdip_BrushCreateSolid(0xFFE0E0E0)
        pPenCircle := Gdip_CreatePen(0xFFA0A0A0, 2.0)
        
        circleX := 22
        circleY := 22
        circleR := 9
        
        ; 绘制圆圈背景
        Gdip_FillEllipse(pGraphics, pBrushCircle, circleX - circleR, circleY - circleR, circleR * 2, circleR * 2)
        
        ; 绘制圆圈边框
        Gdip_DrawEllipse(pGraphics, pPenCircle, circleX - circleR, circleY - circleR, circleR * 2, circleR * 2)
        
        ; 绘制叉号
        crossSize := 5
        Gdip_DrawLine(pGraphics, pPenCircle, circleX - crossSize, circleY - crossSize, circleX + crossSize, circleY + crossSize)
        Gdip_DrawLine(pGraphics, pPenCircle, circleX + crossSize, circleY - crossSize, circleX - crossSize, circleY + crossSize)
        
        ; 保存
        Gdip_SaveBitmapToFile(pBitmap, outputPath)
        
        ; 清理
        Gdip_DeleteBrush(pBrush)
        Gdip_DeleteBrush(pBrushCircle)
        Gdip_DeletePen(pPen)
        Gdip_DeletePen(pPenCircle)
        Gdip_DeleteGraphics(pGraphics)
        Gdip_DisposeImage(pBitmap)
        Gdip_Shutdown(pToken)
        
        ; 复制为ICO
        if FileExist(outputPath) {
            try {
                FileCopy(outputPath, A_ScriptDir "\icons\mic_unavailable.ico", 1)
            }
        }
        
        return true
    } catch as err {
        MsgBox("创建不可用图标失败: " . err.Message)
        return false
    }
}

; ===== GDI+ 辅助函数 =====

Gdip_Startup() {
    if !DllCall("GetModuleHandle", "str", "gdiplus", "ptr") {
        DllCall("LoadLibrary", "str", "gdiplus")
    }
    si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("uint", 1, si, 0)
    DllCall("gdiplus\GdiplusStartup", "ptr*", &pToken := 0, "ptr", si, "ptr", 0)
    return pToken
}

Gdip_Shutdown(pToken) {
    DllCall("gdiplus\GdiplusShutdown", "ptr", pToken)
}

Gdip_CreateBitmap(w, h) {
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "int", w, "int", h, "int", 0, "int", 0x26200A, "ptr", 0, "ptr*", &pBitmap := 0)
    return pBitmap
}

Gdip_GraphicsFromImage(pBitmap) {
    DllCall("gdiplus\GdipGetImageGraphicsContext", "ptr", pBitmap, "ptr*", &pGraphics := 0)
    return pGraphics
}

Gdip_SetSmoothingMode(pGraphics, mode) {
    DllCall("gdiplus\GdipSetSmoothingMode", "ptr", pGraphics, "int", mode)
}

Gdip_GraphicsClear(pGraphics, color) {
    DllCall("gdiplus\GdipGraphicsClear", "ptr", pGraphics, "uint", color)
}

Gdip_BrushCreateSolid(color) {
    DllCall("gdiplus\GdipCreateSolidFill", "uint", color, "ptr*", &pBrush := 0)
    return pBrush
}

Gdip_CreatePen(color, width) {
    DllCall("gdiplus\GdipCreatePen1", "uint", color, "float", width, "int", 2, "ptr*", &pPen := 0)
    return pPen
}

Gdip_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, r) {
    DllCall("gdiplus\GdipFillRectangle", "ptr", pGraphics, "ptr", pBrush, "float", x, "float", y, "float", w, "float", h)
}

Gdip_DrawArc(pGraphics, pPen, x, y, w, h, startAngle, sweepAngle) {
    DllCall("gdiplus\GdipDrawArc", "ptr", pGraphics, "ptr", pPen, "float", x, "float", y, "float", w, "float", h, "float", startAngle, "float", sweepAngle)
}

Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2) {
    DllCall("gdiplus\GdipDrawLine", "ptr", pGraphics, "ptr", pPen, "float", x1, "float", y1, "float", x2, "float", y2)
}

Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h) {
    DllCall("gdiplus\GdipFillEllipse", "ptr", pGraphics, "ptr", pBrush, "float", x, "float", y, "float", w, "float", h)
}

Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h) {
    DllCall("gdiplus\GdipDrawEllipse", "ptr", pGraphics, "ptr", pPen, "float", x, "float", y, "float", w, "float", h)
}

Gdip_SaveBitmapToFile(pBitmap, sOutput) {
    if (SubStr(sOutput, -3) = ".png") {
        pCodec := "image/png"
    } else if (SubStr(sOutput, -3) = ".jpg" || SubStr(sOutput, -4) = ".jpeg") {
        pCodec := "image/jpeg"
    } else {
        pCodec := "image/png"
    }
    
    nCount := 0
    nSize := 0
    DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", &nCount, "uint*", &nSize)
    ci := Buffer(nSize, 0)
    DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, "ptr", ci)
    
    Loop nCount {
        pCodecInfo := ci.Ptr + (48 + 7 * A_PtrSize) * (A_Index - 1)
        pMimeType := NumGet(pCodecInfo + 32 + 4 * A_PtrSize, "ptr")
        sMimeType := StrGet(pMimeType, "UTF-16")
        if (sMimeType = pCodec) {
            pClsid := pCodecInfo
            break
        }
    }
    
    DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", sOutput, "ptr", pClsid, "ptr", 0)
}

Gdip_DeleteBrush(pBrush) {
    DllCall("gdiplus\GdipDeleteBrush", "ptr", pBrush)
}

Gdip_DeletePen(pPen) {
    DllCall("gdiplus\GdipDeletePen", "ptr", pPen)
}

Gdip_DeleteGraphics(pGraphics) {
    DllCall("gdiplus\GdipDeleteGraphics", "ptr", pGraphics)
}

Gdip_DisposeImage(pBitmap) {
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
}
