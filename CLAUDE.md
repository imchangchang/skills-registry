# Skills 注册中心

多 Agent 技能存储库，支持 OpenCode、KimiCode、VSCode、Codex、Claude Code 等主流 AI 编码助手。

## 目录结构

```
skills-registry/
├── .claude-plugin/            # Claude Code 插件配置
│   └── plugin.json            # 插件清单
├── skills/                    # Agent 技能定义
│   ├── claude-code/          # Claude Code 技能
│   ├── opencode/             # OpenCode 技能
│   ├── kimi/                 # KimiCode 技能
│   ├── openai/               # OpenAI Codex 技能
│   ├── gemini/               # Gemini 技能
│   └── mcp/                  # MCP 插件
└── README.md
```

## 技能目录规范

每个技能目录下包含：

- `SKILL.md` - 技能定义文件（必需），包含 frontmatter 元数据
- `template/` - 模板文件目录（可选），存放可复用的文件模板

### SKILL.md frontmatter 格式

```markdown
---
name: 技能名称
description: "简短描述"
agent: claude-code  # 可选，指定适用的 Agent
---

# 技能说明

（详细的使用说明和示例）
```

## Claude Code 技能

### 已有技能

| 技能 | 说明 |
|------|------|
| docker-dev-workflow | Docker + Dev Container 开发流程 |
| git-commit | Git Commit 规范工作流 |

### 安装方式

**软链接安装（推荐）**
```bash
ln -sfn <skills-registry路径>/skills/claude-code/<技能名> ~/.claude/skills/<技能名>
```

**插件模式安装**
```bash
claude plugin install <owner>/skills-registry
```

## git-commit 工作流

提交代码时必须遵循此工作流：

1. **检查 git 用户配置** - 确认 user.name 和 user.email 已设置
2. **询问 Agent 信息** - 获取软件名称、版本和模型信息
3. **生成 Commit Message** - 中文优先，遵循 Conventional Commits 格式
4. **使用 Assisted-by 标注** - 格式：`软件名:v版本:模型 [辅助工具]`
5. **确认后执行提交**
6. **显示结果** - 包含 hash、文件数、行数

详见 `skills/claude-code/git-commit/SKILL.md`

## 添加新技能

1. 在对应 Agent 目录下创建技能文件夹：`skills/<agent>/<技能名>/`
2. 创建 `SKILL.md` 文件，包含 frontmatter 元数据
3. （可选）添加 `template/` 目录存放模板文件
4. **必须更新以下位置**：
   - `.claude-plugin/plugin.json` 中的 `skills` 数组（Claude Code 技能）
   - `skills/<agent>/README.md` 中的"已有技能"列表
   - 本仓库根目录的 `README.md`
5. 提交时使用 git-commit skill

## 提交规范

- Commit message 默认使用中文
- 遵循 Conventional Commits 格式
- 使用 `Assisted-by` 标签标注 AI 参与
- AI 不可添加 `Signed-off-by`，人类负全部责任
