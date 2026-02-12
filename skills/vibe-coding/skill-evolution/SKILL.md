---
name: skill-evolution
description: Skill 演化与沉淀指南。定义从项目实践中提取知识、生成 Skill 沉淀产物的完整流程。项目仓库只生成产物，中央仓库由专门 Agent 应用。
created: 2026-02-12
status: stable
tags: [vibe-coding, skill-management, evolution]
---

# Skill 演化指南

> 项目仓库生成沉淀产物，中央仓库应用产物
> 
> **核心原则**：关注点分离，项目不直接修改中央仓库

## 架构边界

```
┌─────────────────────────────────────────────────────────┐
│                    项目仓库 (Project)                      │
│  ┌─────────────────────────────────────────────────┐   │
│  │  1. 发现问题 → 2. 记录 → 3. 生成沉淀产物         │   │
│  │                                                  │   │
│  │  产物：skill-export/ 目录 或 .skill-patch 文件   │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────┬───────────────────────────────┘
                          │ 复制产物到中央仓库
                          ▼
┌─────────────────────────────────────────────────────────┐
│                 中央仓库 (skills-registry)                │
│  ┌─────────────────────────────────────────────────┐   │
│  │  1. 读取产物 → 2. 应用 → 3. 验证 → 4. 提交      │   │
│  │                                                  │   │
│  │  由中央仓库的 AGENT 执行（遵循中央仓库规范）     │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## 适用场景

- 项目开发中积累了新的最佳实践，需要沉淀到 Skill
- 发现现有 Skill 的不足，需要反馈改进
- 跨项目复用新提炼的知识模式

## 快速决策

```
用户问：怎么沉淀 skill？
    │
    ├── 已有 Skill，简单修正？
    │       └── 方式 1：直接编辑中央仓库（推荐）
    │           场景：你发现 stm32 skill 有个错别字
    │           做法：直接打开 ~/skills-registry 编辑提交
    │
    ├── 从当前项目提炼系统性的新经验？
    │       └── 方式 2：项目生成沉淀产物
    │           场景：你的机器人项目发现了新的 DMA 配置模式
    │           做法：在项目内生成 skill-export/，复制到中央仓库
    │
    └── 要创建全新的 Skill？
            └── 方式 3：在中央仓库新建
                场景：你创建了一个全新的 ROS2 导航 skill
                做法：直接在 ~/skills-registry 创建新 skill
```

---

## 方式 1：直接编辑中央仓库（简单修复）

**适用场景**：
- 发现现有 Skill 有错误（错别字、代码示例错误）
- 需要补充一个小细节
- 紧急修复

**执行步骤**：

```bash
# 1. 进入中央仓库（不在项目仓库内执行）
cd ~/skills-registry

# 2. 直接编辑对应 skill
vim skills/<category>/<skill-name>/SKILL.md

# 3. 更新 HISTORY.md
echo "- $(date +%Y-%m-%d): 修正 xxx" >> skills/<category>/<skill-name>/HISTORY.md

# 4. 提交
git add .
git commit -m "fix(<skill-name>): 修正 xxx"
```

**关键**：这是**在中央仓库中**执行，不是在项目仓库内。

---

## 方式 2：项目生成沉淀产物（推荐用于项目经验）

**适用场景**：
- 从项目中积累了新经验
- 需要系统性地整理和沉淀
- 可能涉及多个文件（SKILL.md + patterns/）

### 步骤 1：项目内记录

在 `.vibe/.skill-updates-todo.md` 记录：

```markdown
## 待办

- [ ] stm32: 补充 DMA 双缓冲配置
  发现时间：2026-02-12
  项目：my-robot
  问题描述：H7 DMA 双缓冲需要特殊配置
  建议方案：在常见问题中添加 H7 DMA 章节
  参考代码：src/drivers/dma.c
```

### 步骤 2：生成沉淀产物

在项目仓库内执行：

```bash
# 1. 在项目根目录创建导出目录
mkdir -p skill-export/stm32-dma-update
cd skill-export/stm32-dma-update

# 2. 创建标准结构
mkdir -p delta/patterns

# 3. 编写 SKILL.md.patch（要追加的内容）
cat > delta/SKILL.md.patch << 'EOF'
## 新增：H7 DMA 双缓冲配置

### 问题：H7 DMA 双缓冲不工作
**现象**: 配置后 DMA 不传输数据
**原因**: H7 系列需要额外配置 MDMA
**解决**: 
```c
// 正确的 H7 DMA 双缓冲配置
// ... 代码示例 ...
```
EOF

# 4. 如有代码模式，添加到 patterns/
cp ../../src/drivers/dma_h7.c delta/patterns/

# 5. 编写 manifest.json
cat > manifest.json << 'EOF'
{
  "target_skill": "embedded/mcu/stm32",
  "change_type": "append",
  "source_project": "my-robot",
  "created_at": "2026-02-12",
  "description": "补充 H7 DMA 双缓冲配置"
}
EOF

# 6. 编写 HISTORY.md.entry
cat > HISTORY.md.entry << 'EOF'
## 2026-02-12: 补充 H7 DMA 双缓冲配置（来自 my-robot 项目）

**变更**: 添加 H7 DMA 双缓冲配置说明和示例代码

**来源项目**: my-robot
**问题**: H7 DMA 双缓冲需要特殊配置 MDMA
**解决**: 添加配置示例和常见问题说明
EOF
```

### 步骤 3：复制产物到中央仓库

```bash
# 在项目仓库内
cp -r skill-export/stm32-dma-update ~/skills-registry/skill-imports/

# 或者打包传输
cd skill-export
tar -czf stm32-dma-update.tar.gz stm32-dma-update/
# 复制 stm32-dma-update.tar.gz 到 ~/skills-registry/skill-imports/
```

### 步骤 4：在中央仓库应用

**切换到中央仓库上下文**：

```bash
cd ~/skills-registry

# 1. 查看产物
ls skill-imports/stm32-dma-update/

# 2. 应用 SKILL.md.patch（追加到文件）
cat skill-imports/stm32-dma-update/delta/SKILL.md.patch >> skills/embedded/mcu/stm32/SKILL.md

# 3. 复制 patterns/
cp skill-imports/stm32-dma-update/delta/patterns/* skills/embedded/mcu/stm32/patterns/

# 4. 更新 HISTORY.md
cat skill-imports/stm32-dma-update/HISTORY.md.entry >> skills/embedded/mcu/stm32/HISTORY.md

# 5. 提交
git add skills/embedded/mcu/stm32/
git commit -m "feat(stm32): 补充 H7 DMA 双缓冲配置

- 添加 H7 DMA 双缓冲配置说明
- 添加代码示例 patterns/dma_h7.c
- 来自 my-robot 项目实践经验

Source: skill-imports/stm32-dma-update/"
```

---

## 方式 3：在中央仓库新建 Skill

**适用场景**：
- 现有技能库没有覆盖的领域
- 需要创建全新的知识模块

**执行步骤**：

```bash
# 1. 在中央仓库创建
cd ~/skills-registry
mkdir -p skills/<category>/<skill-name>
cd skills/<category>/<skill-name>

# 2. 创建基本文件
touch SKILL.md HISTORY.md metadata.json
mkdir -p patterns references

# 3. 编写内容（参考 skill-creator skill）
# ...

# 4. 提交
git add .
git commit -m "feat(<category>): add <skill-name> skill

- 添加 <描述> 的完整指南
- 初始版本"
```

---

## 产物格式规范

### skill-export/ 目录结构

```
skill-export/
└── <update-name>/
    ├── manifest.json          # 元数据
    ├── delta/
    │   ├── SKILL.md.patch     # 要追加的内容
    │   └── patterns/          # 新增的模式文件
    └── HISTORY.md.entry       # 历史记录条目
```

### manifest.json

```json
{
  "target_skill": "embedded/mcu/stm32",
  "change_type": "append",
  "source_project": "my-robot",
  "created_at": "2026-02-12",
  "description": "简要描述变更内容"
}
```

---

## 关键原则

### [强制] 不删除项目沉淀的 Skill

**本质**：只要是开发技能，即使从特定项目提取，也是知识资产

**禁止**：
- ❌ 不要因为"这是项目特定的"就删除 Skill
- ❌ 不要以"现在用不到"为由删除已有 Skill
- ❌ 不要因为"内容有重叠"就随意合并删除

**正确做法**：
- ✅ 项目沉淀的 Skill 是宝贵资产，必须保留
- ✅ 如果是领域通用的（如视频处理、AI API），整理为通用 Skill
- ✅ 如果确实非常项目特定，标记为 `status: draft`，但不删除
- ✅ 内容重叠时，通过 HISTORY.md 说明演进关系，而不是删除

**判断标准**：
```
是否涉及开发技术？
    ├── 是 → 保留（沉淀为通用 Skill）
    │        例如：python-pipeline、whisper-asr、video-processing
    │
    └── 否 → 判断是否为纯业务逻辑
             ├── 是 → 可以删除（如"某某公司的订单流程"）
             └── 否 → 保留并标记为 draft
```

### DO（推荐）

- [OK] **项目内生成产物**：在项目仓库整理经验，生成 skill-export/
- [OK] **中央仓库应用产物**：在中央仓库上下文中应用和提交
- [OK] **简单修复直接改**：小错误直接编辑中央仓库
- [OK] **保持边界清晰**：项目不直接修改中央仓库文件

### DON'T（避免）

- [X] **不要在项目仓库内直接修改 ~/skills-registry/**
- [X] **不要把中央仓库的提交逻辑放在项目仓库**
- [X] **不要混淆两个仓库的上下文**
- [X] **不要删除任何项目沉淀的 Skill**（除非是纯业务逻辑）

---

## 与 skill-testing 的配合

生成的沉淀产物应该在中央仓库经过测试：

```
项目仓库：生成 skill-export/stm32-dma-update/
    ↓ 复制到中央仓库
中央仓库：应用产物 → 使用 skill-testing 验证 → 提交
```

---

## 迭代记录

- 2026-02-12: 初始创建，明确项目仓库和中央仓库的边界
