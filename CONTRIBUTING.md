# 贡献指南

感谢您考虑为 MicToggleTool 做出贡献！

## 行为准则

请保持友好和尊重。我们致力于为每个人提供一个无骚扰的体验。

## 如何贡献

### 报告 Bug

在提交 Bug 报告之前，请：

1. 检查是否已有相同的 Issue
2. 确认使用的是最新版本
3. 查看 [FAQ](README.md#常见问题-faq) 和 [故障排除](README.md#故障排除)

提交 Bug 时，请包含：

- **操作系统版本**: Windows 版本和构建号
- **程序版本**: 在"关于"对话框中查看
- **问题描述**: 清晰描述问题
- **复现步骤**: 详细的步骤
- **预期行为**: 您期望发生什么
- **实际行为**: 实际发生了什么
- **日志文件**: 附上 `MicToggleTool.log` 的相关部分
- **截图**: 如果适用

### 建议新功能

我们欢迎新功能建议！请：

1. 检查 [路线图](README.md#路线图) 是否已计划
2. 在 Issues 中搜索是否有类似建议
3. 创建新 Issue，使用 "Feature Request" 标签
4. 详细描述功能和使用场景

### 提交代码

#### 准备工作

1. Fork 本仓库
2. 克隆您的 Fork
   ```bash
   git clone https://github.com/YOUR_USERNAME/MicToggleTool.git
   cd MicToggleTool
   ```
3. 创建特性分支
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### 开发

1. 安装 [AutoHotkey v2.0+](https://www.autohotkey.com/)
2. 进行您的更改
3. 测试您的更改
4. 确保代码符合规范（见下文）

#### 代码规范

- **缩进**: 使用 4 个空格
- **命名**:
  - 类名和函数名: `PascalCase`
  - 变量名: `camelCase`
  - 常量: `UPPER_CASE`
- **注释**: 使用中文注释，解释"为什么"而不是"是什么"
- **文档**: 为公共函数添加文档注释

示例：
```ahk
/**
 * 获取麦克风设备列表
 * @param {Boolean} noFilter - 是否禁用过滤
 * @returns {Array} 设备列表
 */
static GetAllMicrophones(noFilter := false) {
    ; 实现代码
}
```

#### 提交

1. 提交更改
   ```bash
   git add .
   git commit -m "feat: 添加新功能"
   ```

2. 推送到您的 Fork
   ```bash
   git push origin feature/your-feature-name
   ```

3. 创建 Pull Request

#### 提交信息规范

使用语义化提交信息：

```
<type>: <subject>

<body>

<footer>
```

**类型 (type)**:
- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 代码重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具相关

**示例**:
```
feat: 添加多语言支持

- 添加英文语言包
- 添加语言切换功能
- 更新设置界面

Closes #123
```

### Pull Request 流程

1. 确保 PR 描述清晰
2. 关联相关 Issue（如果有）
3. 确保代码通过测试
4. 等待代码审查
5. 根据反馈进行修改
6. PR 被合并后，您可以删除分支

### 测试

在提交 PR 前，请测试：

- [ ] 程序能正常编译
- [ ] 所有现有功能正常工作
- [ ] 新功能按预期工作
- [ ] 没有引入新的 Bug
- [ ] 日志输出正常
- [ ] 配置文件兼容

运行测试脚本：
```bash
# 测试麦克风控制
AutoHotkey64.exe test_microphone_only.ahk

# 测试设备选择
AutoHotkey64.exe test_device_selector.ahk
```

### 文档

如果您的更改影响用户使用，请更新：

- `README.md` - 主要文档
- `README.txt` - 用户说明
- 代码注释
- 更新日志

## 开发环境设置

### 推荐工具

- **编辑器**: Visual Studio Code
- **扩展**: AutoHotkey v2 Language Support
- **调试**: AutoHotkey v2 Debugger

### VS Code 配置

创建 `.vscode/settings.json`:
```json
{
    "files.encoding": "utf8bom",
    "files.eol": "\r\n",
    "[ahk2]": {
        "editor.tabSize": 4,
        "editor.insertSpaces": true
    }
}
```

## 发布流程

（仅维护者）

1. 更新版本号
   - `MicToggleTool.ahk` 中的 `AppVersion`
   - `README.md` 中的版本徽章
   - 更新日志

2. 编译发布版本
   ```bash
   .\compile_simple.bat
   ```

3. 测试发布版本

4. 创建 Git 标签
   ```bash
   git tag -a v1.0.1 -m "Release v1.0.1"
   git push origin v1.0.1
   ```

5. 在 GitHub 创建 Release
   - 上传 `MicToggleTool.exe`
   - 附上更新日志
   - 标记为 Latest Release

## 获取帮助

如有疑问，可以：

- 查看 [README.md](README.md)
- 搜索现有 [Issues](https://github.com/cmyyx/MicToggleTool/issues)
- 创建新 Issue 提问

## 许可证

通过贡献，您同意您的贡献将在 [MIT License](LICENSE) 下授权。

---

再次感谢您的贡献！🎉
