# 项目模板文件

本目录包含创建新项目时的模板文件，可直接复制使用。

## 使用方法

### 1. AGENTS.md 模板

```bash
# 创建新项目时
cp ~/skills-registry/templates/AGENTS.md ~/projects/my-project/AGENTS.md

# 然后编辑，填写项目特定信息
vim ~/projects/my-project/AGENTS.md
```

### 2. 快速创建新项目

使用提供的脚本：

```bash
~/skills-registry/templates/init-project.sh my-project
```

## 模板文件说明

| 文件 | 用途 | 说明 |
|------|------|------|
| `AGENTS.md` | AI 开发指南 | 每个项目必须，根据项目定制 |

## AGENTS.md 模板结构

```
1. 启用的 Skills         # 声明技能加载方式
2. 项目信息              # 技术栈、目录结构
3. 开发规范              # 代码规范、命名规范
4. 工作流               # 提交、质量门禁、PR
5. 多代理安全规则        # 禁止操作（重要！）
6. 工具脚本             # 项目脚本说明
7. 调试指南             # 常见问题
8. Skill 迭代           # 如何更新技能
9. 项目特定知识         # 项目专属内容
```

## 定制指南

复制 AGENTS.md 后，必须修改以下部分：

### 1. 项目信息
```markdown
### 技术栈
- 语言：[你的语言]
- 平台：[你的平台]
```

### 2. 启用的 Skills
```markdown
# 编辑 .skill-set 文件
embedded/mcu/st-stm32
dev-workflow/git-commits
dev-workflow/quality-gates
```

### 3. 项目特定规范
根据项目需要添加：
- 编码规范（缩进、命名）
- 架构要求
- 特殊工具使用

### 4. 删除示例内容
删除模板中的 `[填写...]` 和示例内容。

## 最佳实践

1. **不要直接修改模板**
   - 复制到项目后再修改
   - 保持模板通用性

2. **项目间差异**
   - 技术栈不同 → 修改"技术栈"和"规范"部分
   - 团队习惯不同 → 修改"工作流"部分
   - 特殊要求 → 添加"项目特定知识"

3. **保持更新**
   - 如发现模板问题，提交 PR 到 skills-registry
   - 不要只在自己的项目中修复

---

*模板版本：2026-02*
