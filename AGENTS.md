# Skills Registry 开发指南

本仓库是 Vibe Coding 技能库，用于存储和管理 AI 协作开发的知识技能。

## AI 助手须知

**首次进入此项目时，需要读取以下目录，如果下面有一个文档，可以直接和用户沟通是否需要恢复这个上下文，如果有多个可以让用户选择一个恢复，或者是把多个上下文压缩到一起恢复**：
- `.ai-context/*.md` - 项目创建会话记录

**关键规范**:
- 所有文档使用中文
- 不使用 emoji（使用 [OK], [X] 等纯文本标记）
- 文件使用 UTF-8 编码

## 仓库结构

```
skills-registry/
├── README.md              # 项目说明
├── AGENTS.md             # 本文件 - AI 开发指南
├── scripts/              # 管理脚本
│   ├── install.sh        # 安装脚本
│   ├── uninstall.sh      # 卸载脚本
│   ├── vibe              # 主命令入口
│   ├── init-vibe.sh      # 项目初始化
│   ├── remove-vibe.sh    # 项目移除
│   ├── add-skill.sh      # 添加技能
│   ├── update-skills.sh  # 更新技能
│   ├── vibe-status.sh    # 状态查看
│   └── new-skill.sh      # 创建新技能
├── templates/            # 项目模板
│   ├── AGENTS.md         # 项目 AGENTS.md 模板
│   └── init-project.sh   # 项目初始化模板
└── skills/               # 技能库
    ├── dev-workflow/     # 开发工作流技能
    ├── embedded/         # 嵌入式技能
    └── software/         # 软件技能
```

## 开发规范

### 语言与格式
- **所有文档使用中文编写**
- 脚本使用 Bash（兼容 POSIX）
- 文档使用 Markdown
- 代码注释使用中文
- 框图采用Mermaid绘制
- 文件一律使用utf-8编码
- **不使用 emoji 表情符号**（使用纯文本标记如 [OK], [X], [!] 等）

### 文件组织
- SKILL.md：核心指导文档，< 500 行
- 脚本：保持精简，单一职责
- 模板：提供完整可用示例

### 命名规范
- 技能目录：小写，连字符分隔
- 脚本：kebab-case，`.sh` 后缀
- 模板文件：描述性名称

## 工作流

### 1. 开发新技能

```bash
# 使用脚本创建技能框架
./scripts/new-skill.sh <category>/<skill-name>

# 示例
./scripts/new-skill.sh embedded/mcu/gd32
./scripts/new-skill.sh software/ros2-nav
```

### 2. 修改现有技能

直接编辑对应 skill 目录下的文件：
- `SKILL.md` - 核心指导
- `patterns/` - 代码模板
- `references/` - 参考资料

### 3. 修改管理脚本

编辑 `scripts/` 目录下的脚本：
- 保持向后兼容
- 添加错误处理
- 更新帮助信息

### 4. 提交规范
- 除非有明确指令要求推送，否则不要执行推送

```bash
# 精确提交
git add scripts/init-vibe.sh
git commit -m "fix(init): 修复路径解析问题"

# 提交信息格式
type(scope): subject

type:
  - feat: 新功能
  - fix: 修复
  - docs: 文档
  - refactor: 重构
  - test: 测试
  - chore: 构建/工具

scope:
  - install: 安装脚本
  - init: 初始化
  - skill: 技能相关
  - template: 模板
```

### 5. 质量门禁

提交前检查：
- [ ] 脚本可执行权限正确
- [ ] 脚本语法检查通过 `bash -n`
- [ ] 帮助信息完整
- [ ] 中文文档无乱码

## 多代理安全规则（强制）

- [X] **不要**使用 `git add .`
- [X] **不要**创建 `git stash`
- [X] **不要**切换分支（除非明确要求）
- [X] **不要**修改 `.worktrees/`
- [OK] 使用精确文件提交

## 技能设计原则

### 1. 渐进式披露
```
SKILL.md（精简核心）
  ↓ 按需加载
references/（详细资料）
  ↓ 按需加载
patterns/（代码模板）
```

### 2. 知识无版本
- 不强制版本号
- 用 HISTORY.md 记录演进
- 错误就改，补充就加

### 3. 实践导向
- 只记录验证过的知识
- 从实际项目提取
- 持续迭代优化

## 新增技能检查清单

创建新技能时检查：

- [ ] `SKILL.md` 包含完整的 frontmatter
- [ ] 有清晰的适用场景说明
- [ ] 核心概念不超过 5 个
- [ ] 包含快速开始示例
- [ ] 有常见问题章节
- [ ] `HISTORY.md` 记录创建
- [ ] 如需要，添加 `patterns/` 模板
- [ ] 如需要，添加 `references/` 参考

## 脚本开发规范

### Bash 脚本模板

```bash
#!/bin/bash
# 脚本名称 - 一句话描述

set -euo pipefail

# 颜色输出（可选）
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 使用说明
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help    显示帮助"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            usage
            ;;
        *)
            # 默认行为
            ;;
    esac
}

main "$@"
```

### 必须遵循

1. **Shebang**: `#!/bin/bash`
2. **严格模式**: `set -euo pipefail`
3. **帮助信息**: 提供 `--help`
4. **错误处理**: 检查文件/目录存在
5. **中文输出**: 用户可见信息使用中文

## 迭代记录

- 2024-01-15: 初始创建 AGENTS.md

---

*本文件供 AI 助手阅读，指导 skills-registry 开发*
