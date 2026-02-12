# Skill 演化工作流详细指南

## 完整工作流程

### 阶段 1: 项目开发中发现新理解

在开发过程中，当你发现：
- 现有 Skill 缺少某个重要细节
- 遇到了 Skill 未覆盖的边界情况
- 发现了更优的实践方法

**立即记录**到 `.vibe/.skill-updates-todo.md`：

```markdown
## 待办

- [ ] embedded/mcu/stm32-h7: DMA 双缓冲配置说明
  发现时间：2026-02-12
  项目：my-robot
  问题描述：H7 系列 DMA 需要特殊配置才能使用双缓冲模式
  参考代码：src/drivers/dma.c
  建议方案：在 SKILL.md 常见问题中添加 H7 DMA 章节
```

### 阶段 2: 项目结束时提取 Skill

项目开发完成或阶段性结束时：

```bash
cd ~/projects/my-robot

# 批量提取所有待办
~/skills-registry/skills/vibe-coding/skill-evolution/patterns/extract-skill.sh \
    --source . \
    --batch-mode \
    --output-dir ~/skill-packages/

# 输出：
# ~/skill-packages/
# ├── 2026-02-12-stm32-h7-dma-buffer.pkg
# └── 2026-02-12-freertos-priority.pkg
```

### 阶段 3: 完善导入包内容

导入包生成后，需要人工完善：

```bash
# 解压导入包
cd ~/skill-packages
mkdir -p 2026-02-12-stm32-h7-dma-buffer
tar -xzf 2026-02-12-stm32-h7-dma-buffer.pkg -C 2026-02-12-stm32-h7-dma-buffer

# 编辑 delta/SKILL.md.patch，添加实际内容
vim 2026-02-12-stm32-h7-dma-buffer/delta/SKILL.md.patch

# 添加代码模式
cp ~/projects/my-robot/src/drivers/dma.c \
   2026-02-12-stm32-h7-dma-buffer/delta/patterns/dma-h7-double-buffer.c

# 重新打包
tar -czf 2026-02-12-stm32-h7-dma-buffer.pkg -C 2026-02-12-stm32-h7-dma-buffer .
```

### 阶段 4: 融合到 Skill 仓库

```bash
cd ~/skills-registry

# 预览融合
./skills/vibe-coding/skill-evolution/patterns/merge-skill.sh \
    --package ~/skill-packages/2026-02-12-stm32-h7-dma-buffer.pkg \
    --dry-run

# 执行融合
./skills/vibe-coding/skill-evolution/patterns/merge-skill.sh \
    --package ~/skill-packages/2026-02-12-stm32-h7-dma-buffer.pkg
```

### 阶段 5: 提交到仓库

```bash
cd ~/skills-registry

git add skills/embedded/mcu/st-stm32/
git commit -m "feat(stm32-h7): add DMA double buffer configuration

- Add H7 DMA specific configuration notes
- Add pattern: dma-h7-double-buffer.c
- Update from project: my-robot

Extracted using skill-evolution tool"

# 推送（按 multi-agent-safety 规定需要确认）
```

## 导入包内容规范

### delta/SKILL.md.patch 格式

```markdown
# 这是注释，不会包含在最终文件中

## 新增的章节标题

正文内容，支持 Markdown 格式。

### 子章节

- 列表项 1
- 列表项 2

```c
// 代码示例
void example() {
    // ...
}
```
```

### patterns/ 目录

放置可复用的代码模板：
- 单个函数示例
- 完整模块模板
- 配置文件示例

命名规范：`feature-specific.c` 或 `framework-example.py`

### references/ 目录

放置参考资料：
- 详细设计文档
- 调研报告
- 外部链接汇总

### HISTORY.md.entry 格式

```markdown
## YYYY-MM-DD: 简要描述（来自项目名）

**变更**: 一句话描述

**来源项目**: 项目名
**提取工具**: skill-evolution v1.0.0

**具体内容**:
- 变更点 1
- 变更点 2

**验证**: 在项目名中实际应用
```

## 融合策略详解

### append（推荐）

- **行为**: 在 SKILL.md 末尾添加新章节
- **优点**: 不会破坏现有内容，安全
- **适用**: 大部分情况

### patch

- **行为**: 修改 SKILL.md 的特定部分
- **优点**: 可以更新现有内容
- **适用**: 修正错误、更新过时内容
- **注意**: 需要更精确的内容定位

### replace

- **行为**: 完全替换 SKILL.md
- **优点**: 彻底重写
- **适用**: 几乎不用（太危险）
- **警告**: 会丢失未包含在导入包中的内容

## 常见问题

### Q: 导入包可以包含多个 Skill 的更新吗？

A: 不可以。每个导入包只针对一个 Skill，保持单一职责。

### Q: 如何处理冲突？

A: 如果目标文件已存在：
1. 使用 `--force` 覆盖
2. 或手动合并后再导入
3. 或使用 patch 策略精确定位

### Q: 导入包可以删除内容吗？

A: 当前版本不支持删除，只支持添加和修改。如需删除，请手动编辑。

### Q: 可以自动化整个流程吗？

A: 可以部分自动化：
- 提取待办：可自动化
- 生成导入包：可自动化
- 完善内容：需要人工
- 融合到仓库：可自动化（建议保留人工确认）
