---
name: huashu-doc-reviewer
description: |
  AI文档审阅助手：让AI直接在Word文档里加批注（右侧气泡）和修订标记（删除线+新文字），不返回新文件。
  覆盖：合同风险审查、报告改稿、方案逻辑补强、简历优化等"原文档留痕"类审阅场景。
  当用户提到"审合同"、"改合同"、"合同批注"、"审报告"、"报告改稿"、"方案评审"、"简历批注"、
  "文档审阅"、"word批注"、"word修订"、"docx批注"、"加批注"、"track changes"、"帮我审一下这份"、
  "标出问题"、"挑毛病"时使用。
  核心差异：AI作为审稿人直接在原文档留足迹，保留原格式，而不是返回一个新文件。
  本地运行、跨平台（Mac/Windows/Linux），适合敏感文档（合同/报告/客户资料）场景。
---

# 文档审阅助手（Doc Reviewer）

> **让AI作为审稿人**直接在Word文档里加批注和修订标记。原格式保留，原文件不动。

## 核心定位

这是一个 **工具型 skill**，不是 agent 型：

| 层级 | 谁来做 | 做什么 |
|------|-------|-------|
| 判断层 | 模型 | 读精简版文档 JSON，决定批注在哪、改什么、说什么 → 输出 JSON |
| 操作层 | Python 代码 | 解析 docx、精确字符串定位、注入 OOXML 批注/修订标签、重新打包 |

**一句话**：模型只输出 JSON，代码做所有 docx 操作。即使用弱模型也能稳定跑。

## 触发场景

| 场景 | 审阅模式 | 重点 |
|------|---------|------|
| 合同审查 | `contract` | 风险条款、兜底条款、模糊表述、责任不对等 |
| 报告改稿 | `report` | 表述优化、数据准确性、结构建议 |
| 方案评审 | `proposal` | 逻辑补强、假设质疑、可行性 |
| 简历优化 | `resume` | 表述精炼、成果量化、关键词优化 |
| 通用审阅 | `general` | 通读给建议，不特化 |

## 一键调用

```bash
# 直接注入预制的 JSON 决策（演示/调试推荐，完全不依赖模型）
python3 scripts/inject_comments.py \
    input.docx \
    decisions.json \
    --output input.reviewed.docx

# 先生成给模型看的精简 JSON（模型读这个再输出 decisions.json）
python3 scripts/read_docx.py input.docx --for-model --output input.for_model.json

# 校验模型输出的 JSON 是否合法
python3 scripts/validate_decisions.py decisions.json

# 一键编排（读 → 校验 → 注入）
python3 scripts/review_docx.py input.docx decisions.json --output input.reviewed.docx
```

输出：`<file>.reviewed.docx`——带批注（右侧气泡）+ 修订标记（删除线+新文字）。

## 工作流（5 步）

```
输入 .docx
  ↓
[Step 1] scripts/read_docx.py → 段落 JSON（给模型看的精简版）
  ↓
[Step 2] 模型 + references/reviewer-prompt.md → 决策 JSON
  ↓
[Step 3] scripts/validate_decisions.py → 强 schema 校验，失败则重试
  ↓
[Step 4] scripts/inject_comments.py → 注入批注 + 修订
  ↓
输出 .reviewed.docx
```

每步失败都是**隔离的**：
- 模型某条输出格式错 → 丢弃该条，其他继续
- 某条 `match_text` 在段落里找不到 → 跳过该条，记录 warning
- 批注注入失败 → 保留已成功注入的，最终产物仍可用

## 决策 JSON Schema（模型的唯一输出格式）

```json
{
  "mode": "contract",
  "decisions": [
    {
      "para_id": 3,
      "match_text": "根据本合同",
      "action": "replace",
      "new_text": "依据本合同",
      "comment": "公文语境'依据'比'根据'更规范",
      "severity": "minor"
    },
    {
      "para_id": 5,
      "match_text": "如遇不可抗力",
      "action": "comment_only",
      "new_text": null,
      "comment": "建议补充不可抗力的具体情形清单",
      "severity": "major"
    }
  ]
}
```

字段说明：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `para_id` | int | 是 | 段落 ID（来自 read_docx 输出） |
| `match_text` | string | 是 | 该段落中要定位的原文片段（必须精确匹配） |
| `action` | enum | 是 | `replace`（删除+插入）、`insert_after`、`delete`、`comment_only`（仅批注不改原文） |
| `new_text` | string/null | 视 action | `replace/insert_after` 时必填；`delete/comment_only` 为 null |
| `comment` | string | 是 | 批注文字（在 Word 右侧气泡显示） |
| `severity` | enum | 是 | `critical/major/minor/info` |

`action` 详解见 `references/reviewer-prompt.md`。

## 三层可靠性保护

**1. JSON Schema 强校验（validate_decisions.py）**
- 模型输出必须完全符合 schema
- 不符合就告诉模型错在哪、重试（最多 3 次）
- 3 次都失败 → 只保留已验证通过的条目，不中断流程

**2. 字符串精确匹配定位**
- 不相信模型"知道位置"
- 代码在 `doc.paragraphs[para_id].text` 里用 `str.find(match_text)` 定位
- 匹配不到：跳过该条，记录到 warnings
- 多处匹配：取第一处（后续扩展可支持"第 N 处"）

**3. 原子化失败隔离**
- 每条决策在 try/except 里执行
- 单条失败不影响后续
- 最终报告：成功 N 条，跳过 M 条，失败原因详情

## 三种审阅模式（演示默认 contract）

| 模式 | System Prompt 风格 |
|------|------------------|
| `contract` | 合同律师视角，重点找风险条款、兜底条款、不对等义务、模糊表述 |
| `report` | 编辑视角，重点看表述准确性、数据一致性、结构清晰度 |
| `proposal` | 咨询顾问视角，重点看逻辑完整性、假设是否站得住、论据是否充分 |
| `resume` | HR 视角，重点看 STAR 结构、成果量化、关键词匹配 |
| `general` | 通用审稿人视角，给总体建议 |

完整 prompts 见 `references/reviewer-prompt.md`。

## 模型调用（本地优先）

本 skill 不硬绑定模型来源。默认设计是"模型调用交给上层"：

- **演示场景（视频高潮段）**：上层 agent 用 LM Studio / Ollama 跑本地 120B 模型，生成 JSON 后调用本 skill。断网演示时，使用 `examples/decisions_demo.json` 作为 fallback
- **开发调试**：直接手写 JSON 决策文件，跳过模型那一步，验证 inject 逻辑

接入细节交给调用方。本 skill 保证：给我合法 JSON，我能稳定生成带批注的 docx。

## 目录结构

```
huashu-doc-reviewer/
├── SKILL.md                      # 本文件
├── scripts/
│   ├── read_docx.py              # 读取 docx → 段落 JSON
│   ├── validate_decisions.py     # JSON schema 校验
│   ├── inject_comments.py        # 核心：注入批注 + 修订
│   ├── review_docx.py            # 顶层编排（串起四步）
│   └── generate_sample_contract.py  # 生成 examples/sample_contract.docx
├── references/
│   ├── reviewer-prompt.md        # 三种审阅模式的 system prompt
│   └── ooxml-notes.md            # OOXML 技术细节，方便后续维护
└── examples/
    ├── sample_contract.docx      # 演示用例合同（几处埋好的风险点）
    ├── decisions_demo.json       # 对应的预制决策 JSON（演示时可离线用）
    ├── expected_output.docx      # 预跑产出（带批注+修订的成品）
    └── README.md                 # 如何重跑演示
```

## 演示用例（视频高潮段 6:30-9:30）

```bash
cd /Users/alchain/Documents/写作/.claude/skills/huashu-doc-reviewer

# Step 1（只做一次）：生成示例合同
python3 scripts/generate_sample_contract.py \
    --output examples/sample_contract.docx

# Step 2：预制决策 JSON 已在 examples/decisions_demo.json

# Step 3：一键注入
python3 scripts/inject_comments.py \
    examples/sample_contract.docx \
    examples/decisions_demo.json \
    --output examples/expected_output.docx

open examples/expected_output.docx   # Mac 下打开看效果
```

Word 打开后应看到：
- 右侧侧边栏 **18 条批注**（气泡，满屏视觉冲击）
- 原文 **5 处修订**（4 处 replace + 1 处 insert_after，删除线 + 新文字）
- 每条批注有说明（"为什么改"）
- 每条批注前缀标注 severity：`[CRITICAL]` / `[MAJOR]` / `[MINOR]`
- 录制时可加 `--author '花叔AI审稿' --initials '花'` 强化品牌感

**断网演示救命稻草**：跳过所有模型步骤，直接跑 `inject_comments.py examples/sample_contract.docx examples/decisions_demo.json`，一条命令产出带 18 批注的 docx，完全离线可复现。

## 当前阶段与限制（P1+P2 已交付）

本版本已交付：
- ✅ 读取 docx（稳定，无模型依赖）
- ✅ 注入批注（`<w:commentRangeStart/End>` + `<w:commentReference>` + 完整 comments.xml 基础设施）
- ✅ 注入修订（`<w:ins>`/`<w:del>`）
- ✅ JSON schema 校验
- ✅ 失败隔离与 warnings 汇报
- ✅ 顶层编排脚本
- ✅ 演示用例（脚本 + 决策 JSON + 预跑产物）
- ✅ 三种审阅模式 prompt

已知限制：
- 表格内文字暂不做批注（只批注 `<w:p>` 段落）
- 页眉/页脚不批注
- 图片、公式附近的批注可能定位到最近段落
- 同一段落中 `match_text` 多处出现时默认取第一处
- 本 skill **不**自动调用模型（留给上层编排 agent 处理），避免硬绑定某个 LLM provider
- 对于特别复杂的 OOXML（自定义 schema/第三方插件写的 docx），可能需要先转存一次再处理

**不做的事**：Word COM/AppleScript（跨平台优先）、PDF 审阅、实时协同。

## Credits

本 skill 的 OOXML 批注实现思路基于 Anthropic 官方 `document-skills:docx`：

- 来源：https://github.com/anthropics/skills/tree/main/document-skills/docx
- 许可证：Proprietary（详见原仓库 LICENSE.txt，受 Anthropic 使用条款约束）
- 借鉴：批注 XML 模板结构（comments.xml / commentsExtended.xml / commentsIds.xml / commentsExtensible.xml）
  以及修订标签 `<w:ins>` / `<w:del>` 的 schema 模式

本 skill 在其基础上封装了工具型工作流（JSON 驱动 + 批量注入 + 失败隔离），独立用 python-docx + 手工 XML 处理实现。如需更底层的 Word 文档创建/编辑能力，建议直接用 document-skills:docx。

其他依赖：
- **python-docx** — MIT License — 用于读取 docx 段落结构 — https://github.com/python-openxml/python-docx
- **defusedxml** — PSF License — 用于安全解析 XML — https://github.com/tiran/defusedxml

## 给调用 skill 的模型（prompt hint）

如果你是一个上层 agent 正在调用本 skill 为一份文档做审阅，标准流程是：

1. 先运行 `python3 scripts/read_docx.py <file.docx> --for-model` 拿到段落 JSON
2. 读 `references/reviewer-prompt.md` 选对应模式的 prompt
3. 把 system prompt + 段落 JSON 拼起来送给本地/云端模型
4. 拿到模型输出的 decisions JSON，先跑 `validate_decisions.py` 校验
5. 如果校验失败：把 errors 反馈给模型重试（最多 3 次）
6. 通过后跑 `inject_comments.py` 生成最终 docx

不要直接让模型输出 XML 或文档内容——那会炸掉。只让模型输出 JSON。
