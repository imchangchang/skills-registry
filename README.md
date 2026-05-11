# Skills 注册中心

多 Agent 技能存储库，支持 Docker 开发环境、Git Commit 等 Claude Code 技能。

## 目录结构

```
skills-registry/
├── .claude-plugin/            # Claude Code 插件配置
│   ├── plugin.json            # 插件清单
│   └── marketplace.json        # Marketplace 清单
├── skills/                    # Claude Code 技能目录
│   ├── docker-dev-workflow/  # Docker + Dev Container 开发流程
│   └── git-commit/            # Git Commit 规范工作流
├── CLAUDE.md
└── README.md
```

## 技能目录规范

每个技能目录下包含：

- `SKILL.md` - 技能定义文件（必需），包含名称、描述、使用方式
- `template/` - 模板文件目录（可选），存放可复用的文件模板

### SKILL.md 格式

```markdown
---
name: 技能名称
description: "简短描述"
user_invocable: true
version: "1.0.0"
---

# 技能说明

（详细的使用说明和示例）
```

## 安装方式

### Marketplace 安装（推荐）

```bash
# 添加 marketplace
claude plugin marketplace add imchangchang/skills-registry

# 安装
claude plugin install imchangchang/skills-registry
```

### 软链接安装

```bash
ln -sfn <skills-registry路径>/skills/<技能名> ~/.claude/skills/<技能名>
```

## 当前已有技能

- [docker-dev-workflow](./skills/docker-dev-workflow/) - Docker + Dev Container 开发流程
- [git-commit](./skills/git-commit/) - Git Commit 规范工作流

## 添加新技能

1. 在 `skills/` 目录下创建技能文件夹：`skills/<技能名>/`
2. 创建 `SKILL.md` 文件，包含 frontmatter 元数据
3. （可选）添加 `template/` 目录存放模板文件
4. 更新本目录下的 README.md
