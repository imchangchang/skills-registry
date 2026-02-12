---
name: skill-testing
description: Skill 测试验证规范。定义如何在真实项目中测试 Skill，确保 Skill 质量、发现冲突和模糊点。所有 Skill 发布前必须经过此流程验证。
created: 2026-02-12
status: stable
tags: [vibe-coding, testing, validation, quality]
---

# Skill 测试验证规范

> 在真实项目中验证 Skill，确保质量闭环

## 核心理念

**Skill 写完后 ≠ 完成，必须在真实项目中测试通过才算完成**

```
创建/更新 Skill
    │
    ▼
在测试项目中实际使用
    │
    ├── 发现问题 → 修正 Skill → 重新测试
    │
    └── 通过验证 → 标记完成
```

## 适用场景

- 新创建的 Skill 需要验证可用性
- 更新后的 Skill 需要回归测试
- 发现 Skill 有冲突或模糊点需要排查

## AI 助手约定（强制执行）

### [强制] Skill 测试三步法

#### 步骤 1：创建测试项目

**目的**：在隔离环境中测试 Skill，不影响生产项目

**执行**：
```bash
# 1. 创建测试项目目录
mkdir -p ~/skill-testing/<skill-name>-test
cd ~/skill-testing/<skill-name>-test

# 2. 初始化 Vibe Coding
~/skills-registry/scripts/init-vibe.sh

# 3. 在 .skill-set 中只声明要测试的 Skill
# （最小化，避免其他 Skill 干扰）
echo "<category>/<skill-name>" > .skill-set
./.vibe/scripts/link-skills.sh
```

**验证清单**：
- [ ] 项目能正常初始化
- [ ] Skill 文件能被正确链接到 `.vibe/skills/`
- [ ] AI 助手能读取到 Skill 内容

#### 步骤 2：执行测试对话

**目的**：模拟真实使用场景，发现 Skill 的问题

**测试用例**（根据 Skill 类型选择）：

| Skill 类型 | 测试对话示例 |
|-----------|-------------|
| 编程规范 | "按照这个 skill 的规范，写一段示例代码" |
| 工具使用 | "使用这个 skill 推荐的方式，完成 xxx 任务" |
| 流程规范 | "根据这个 skill，我应该如何执行 xxx 操作" |
| 设计模式 | "应用这个 skill 的架构，设计一个示例" |

**必须检查的要点**：

1. **清晰度检查**
   - AI 是否理解 Skill 的指令？
   - 输出是否符合 Skill 的期望？
   - 是否有歧义或模糊的地方？

2. **可执行性检查**
   - Skill 定义的步骤是否可执行？
   - 是否有缺失的前提条件？
   - 是否有无法完成的步骤？

3. **一致性检查**
   - Skill 内部是否有矛盾？
   - 与其他常用 Skill 是否有冲突？
   - 示例和描述是否一致？

4. **完整性检查**
   - 是否覆盖了宣称的适用场景？
   - 边界情况是否考虑周全？
   - 常见问题是否有解答？

**记录问题**：
```markdown
# ~/skill-testing/<skill-name>-test/.ai-context/test-results.md

## Skill 测试记录
**Skill**: <category>/<skill-name>
**测试时间**: YYYY-MM-DD
**测试者**: <你的名字>

### 测试对话 1: <场景描述>
**用户输入**: "..."
**AI 输出**: "..."
**问题发现**: 
- [ ] 无问题
- [X] 有模糊点: <描述>
- [X] 有冲突: <描述>
- [X] 无法执行: <描述>

### 测试对话 2: ...
```

#### 步骤 3：修正并回归测试

**如果有问题**：
1. 在测试项目中记录问题
2. 返回 `~/skills-registry` 修正 Skill
3. 重新链接并测试
4. 重复直到通过

**如果通过**：
1. 在 Skill 的 HISTORY.md 中添加：
   ```markdown
   ## YYYY-MM-DD: 测试验证通过
   
   **测试项目**: ~/skill-testing/<skill-name>-test
   **测试内容**: <简要描述测试场景>
   **验证结果**: 通过
   ```
2. 提交 Skill
3. （可选）保留或删除测试项目

---

## 测试检查清单

### 基础检查（所有 Skill 必须）

- [ ] **元数据完整**：name, description, created, status
- [ ] **结构正确**：有清晰的章节划分
- [ ] **语言统一**：全文使用中文（代码除外）
- [ ] **格式正确**：Markdown 无语法错误

### 内容检查（按 Skill 类型）

**代码类 Skill**（如 stm32, python-cli）：
- [ ] 代码示例可编译/运行
- [ ] 命令可复制执行
- [ ] 路径和文件名正确

**流程类 Skill**（如 git-commits, multi-agent-safety）：
- [ ] 步骤顺序合理
- [ ] 每个步骤可执行
- [ ] 有明确的判断标准

**设计类 Skill**（如 pipeline-architecture）：
- [ ] 概念定义清晰
- [ ] 有具体应用示例
- [ ] 模式可实际应用

### 冲突检查（重要）

- [ ] **与 vibe-coding/core 无冲突**
- [ ] **与同分类 Skill 无矛盾**
- [ ] **Git 相关 Skill 与 multi-agent-safety 兼容**

---

## 常见问题

### 问题 1：测试项目需要多完整？

**解答**：
- **代码类 Skill**：需要一个最小可运行项目
- **流程类 Skill**：空项目即可，重点是对话测试
- **设计类 Skill**：需要一个示例场景

### 问题 2：发现 Skill 问题怎么办？

**解答**：
1. 在测试项目中记录问题（.ai-context/test-results.md）
2. 返回 skills-registry 修正
3. 更新 HISTORY.md
4. 重新测试

### 问题 3：Skill 更新后需要重新测试吗？

**解答**：
- **重大更新**（新增章节、修改核心流程）：完整回归测试
- **小修正**（错别字、代码示例）：简单验证即可
- **文档补充**：检查新增内容清晰度

---

## 与 vibe-coding/core 的关系

本 SKILL 遵循 **SKILL 指导执行，脚本只是辅助** 原则：

- **约定**：定义测试流程和检查清单
- **脚本**：不提供（流程需要人工判断）
- **执行**：AI 按照本 SKILL 的步骤手动执行

---

## 迭代记录

- 2026-02-12: 初始创建，定义 Skill 测试验证三步法
