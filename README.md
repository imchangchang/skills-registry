# Skills 注册中心

多 Agent 技能存储库，支持 OpenCode、KimiCode、VSCode、Codex、Claude Code 等主流 AI 编码助手。

## 目录结构

```
skills-registry/
├── .claude-plugin/            # Claude Code 插件配置
│   └── plugin.json            # 插件清单
├── skills/                    # Agent 技能定义
│   ├── opencode/             # OpenCode 技能
│   ├── kimi/                 # KimiCode 技能
│   ├── claude-code/          # Claude Code 技能
│   ├── openai/               # OpenAI Codex 技能
│   ├── gemini/               # Gemini 技能
│   └── mcp/                  # MCP (Model Context Protocol) 插件
└── README.md
```

## 技能说明

技能存储在 `skills/` 目录下，按 Agent 平台分类。

### 技能目录规范

每个技能目录下包含：

- `SKILL.md` - 技能定义文件（必需），包含名称、描述、使用方式
- `template/` - 模板文件目录（可选），存放可复用的文件模板

### SKILL.md 格式

```markdown
---
name: 技能名称
description: "简短描述"
---
# 技能说明

（详细的使用说明和示例）
```

## Claude Code 安装方式

### 方式一：软链接安装（推荐）

```bash
ln -sfn <skills-registry路径>/skills/claude-code/<技能名> ~/.claude/skills/<技能名>
```

例如安装 docker-dev-workflow：

```bash
ln -sfn ~/skills-registry/skills/claude-code/docker-dev-workflow ~/.claude/skills/docker-dev-workflow
```

### 方式二：复制安装

```bash
cp -r <skills-registry路径>/skills/claude-code/<技能名> ~/.claude/skills/
```

### 方式三：插件模式安装

发布为插件后使用命令安装：

```bash
claude plugin install <owner>/skills-registry
```

插件配置文件在 `.claude-plugin/plugin.json`：

```json
{
  "name": "skills-registry",
  "description": "多 Agent 技能存储库",
  "version": "1.0.0",
  "skills": [
    "docker-dev-workflow"
  ]
}
```

安装后重启 Claude Code，使用 `/skill` 命令查看已安装的技能列表。

## OpenCode 安装方式

```bash
cp -r skills/opencode/<技能名> ~/.opencode/skills/
```

## KimiCode / Codex

参考各 Agent 官方文档进行技能安装。

## 添加新技能

1. 在对应 Agent 目录下创建技能文件夹：`skills/<agent>/<技能名>/`
2. 创建 `SKILL.md` 文件，包含 frontmatter 元数据
3. （可选）添加 `template/` 目录存放模板文件
4. 如果是 Claude Code 插件模式，更新 `.claude-plugin/plugin.json` 中的 `skills` 数组
5. 更新本目录下的 README.md

## 当前已有技能

- [docker-dev-workflow](./skills/claude-code/docker-dev-workflow/) - Docker + Dev Container 开发流程（Claude Code）
