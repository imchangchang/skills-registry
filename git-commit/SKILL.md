---
name: Git Commit
description: |
  当用户想要提交代码时触发此 skill。执行 git commit 工作流：
  - 检查 git 用户名和邮箱是否已配置，未配置则中断并提示用户设置
  - 生成符合规范的 commit message（中文优先）
  - 获取AI工具类型和版本信息，使用 Assisted-by 标签标注
  - 执行 commit
  触发场景包括但不限于：用户说"提交"、"commit"、"提交代码"、"帮我提交"、"git commit"等
---

# Git Commit Skill

此 skill 规范 git commit 工作流，参考 Linux Kernel 的 AI 协作规范，确保每次提交都有正确的作者信息和规范的 commit message。

## 工作流程

### 第一步：检查 git 用户配置

在执行 commit 前，**必须**先检查用户是否已配置 git 用户名和邮箱。

执行以下命令检查：

```bash
git config --global user.name
git config --global user.email
```

**如果用户名或邮箱未配置**（返回为空）：
1. 告诉用户需要先设置 git 用户信息
2. 提供设置命令示例：
   ```bash
   git config --global user.name "你的名字"
   git config --global user.email "your@email.com"
   ```
3. **不要继续执行 commit**，等待用户完成配置后重新触发

**如果已配置**：继续下一步。

---

### 第二步：检查AI工具类型和模型

首先检查是否能识别到自己是何种Agent（如 Claude Code、Copilot、Cursor 等），如果无法识别则询问用户：**"本次提交使用的Agent软件是什么？**

根据用户的回答，记录软件名称和版本信息，准备在后续的 commit message 中使用 `Assisted-by` 标签进行标注。

然后检查是否能识别到自己的模型类型，如果识别不到则询问用户：**"本次提交使用的AI模型是什么？请提供具体模型信息。"**

---

### 第三步：生成 Commit Message

Commit message **默认使用中文**，遵循 Conventional Commits 格式：

```
<type>(<scope>): <简短描述>

[可选的详细说明]

[可选的 footer 标签]
```

**Type 类型**（使用中文）：

| Type | 中文含义 | 英文原文 |
|------|----------|----------|
| feat | 新功能 | feature |
| fix | 修复 bug | bug fix |
| refactor | 重构 | refactoring |
| perf | 性能优化 | performance |
| docs | 文档更新 | documentation |
| style | 格式调整 | styling |
| test | 测试相关 | testing |
| chore | 构建/工具 | build/tooling |
| ci | CI/CD | CI/CD |
| revert | 回滚 | revert |

**Scope（范围）**：用中文描述影响模块，如 `用户模块`、`登录功能`、`支付流程` 等。如果不确定或影响范围广，可以省略。

**规则**：
- 第一行不超过 72 字符
- 使用命令式语气："添加功能" 而非 "添加了功能"
- 在 footer 添加 `Assisted-by` 行

---

### 第四步：AI 参与标注格式

当有 AI 参与时，使用 `Assisted-by` 标签，格式为：

```
Assisted-by: <软件名>:<模型版本> [辅助工具]
```

**格式说明**：
- 冒号前的 `<软件名>` 使用具体产品名+版本号，版本号需要以v开头
- 冒号后的 `<模型版本>` 使用实际运行的模型/引擎标识
- 辅助工具（如 coccinelle、sparse、smatch、clang-tidy）可选

**常用格式示例**：

```
Assisted-by: Claude Code v2.1.114:Minimax-M2.7-highspeed
```

---

### 第五步：Commit Message 示例
fix(支付模块): 修复金额计算精度问题

使用 Claude Code 协助排查，发现浮点数运算存在精度丢失。
已在测试环境验证通过。

Assisted-by: Claude Code v2.1.114:Minimax-M2.7-highspeed coccinelle

---

### 第六步：确认并执行 Commit

1. 将生成的 commit message 展示给用户
2. 询问确认：`"以上 commit message 是否合适？输入 '是' 确认提交，或输入修改意见"`
3. 根据用户反馈调整（如果有）
4. 执行提交：

```bash
# 先检查 staged 的文件
git status

# 执行 commit
git commit -m "<commit message>"
```

---

### 第七步：显示结果

Commit 成功后，显示：
- 提交成功的提示
- 本次提交的 hash（简短格式）
- 变动的文件数量和行数

如果需要推送，询问是否同时推送。

---

## 注意事项

1. **用户配置优先**：任何情况下都先确保 git 用户信息已配置，这是 commit 的前提
2. **中文为主**：commit message 默认使用中文，除非用户明确要求英文
3. **AI 标注必须准确**：使用具体软件名和实际模型版本，不要用模糊的描述
4. **辅助工具可选**：coccinelle、sparse、smatch、clang-tidy 等静态分析工具可以标注
5. **人类全权负责**：人类对提交负全部责任，AI 只是辅助工具
6. **遵守项目规范**：确保生成的 commit message 符合项目的提交规范和要求

## Linux Kernel AI Commit 规范参考

此 skill 参考 Linux Kernel 官方规范（`Documentation/process/coding-assistants.rst`）：

- AI agents **绝对不能**添加 `Signed-off-by`，只有人类能签署 DCO
- 使用 `Assisted-by` 标签标注 AI 参与
- 所有代码必须与项目许可证兼容
