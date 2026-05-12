# OOXML 技术细节（维护向）

> 给后续维护 skill 的人看。如果你在改 `inject_comments.py`，先看这篇。

## docx 本质

`.docx` = ZIP 归档，关键文件：

```
word/
├── document.xml            # 正文
├── comments.xml            # 批注正文（新增）
├── commentsExtended.xml    # 批注扩展元数据（新增）
├── commentsIds.xml         # 批注 durable ID 映射（新增）
├── commentsExtensible.xml  # 批注可扩展字段（新增）
└── _rels/
    └── document.xml.rels   # 关系映射（要加 comments 的关系）
[Content_Types].xml         # 内容类型声明（要加 comments 的类型）
```

**没有 comments.xml 的文档，无法渲染批注。**所以 skill 第一步就是确保这些文件存在。

## 命名空间

```
xmlns:w = http://schemas.openxmlformats.org/wordprocessingml/2006/main
xmlns:w14 = http://schemas.microsoft.com/office/word/2010/wordml
xmlns:w15 = http://schemas.microsoft.com/office/word/2012/wordml
xmlns:w16cid = http://schemas.microsoft.com/office/word/2016/wordml/cid
xmlns:w16cex = http://schemas.microsoft.com/office/word/2018/wordml/cex
```

如果 document.xml 的 `<w:document>` 根元素上没声明 `w14/w15` 等前缀，Word 能打开但 commentsExtended 无效。我们的脚本不改根元素，只添加 comments 相关文件——这是安全的做法。

## 批注三件套（在 document.xml 中）

批注在正文里由三部分标记：

```xml
<w:commentRangeStart w:id="0"/>       <!-- 批注区域起点 -->
<w:r>...要批注的内容...</w:r>
<w:commentRangeEnd w:id="0"/>         <!-- 批注区域终点 -->
<w:r>                                  <!-- 批注引用（必须在 End 之后） -->
  <w:rPr><w:rStyle w:val="CommentReference"/></w:rPr>
  <w:commentReference w:id="0"/>
</w:r>
```

**关键约束**：`commentRangeStart/End` 必须是 `<w:p>` 的**直接子元素**，不能嵌套在 `<w:r>` 里（我们的脚本严格遵守）。

## 修订标签

### 插入

```xml
<w:ins w:id="1" w:author="Claude AI Reviewer" w:date="2026-04-17T12:00:00Z">
  <w:r><w:t>新插入的文字</w:t></w:r>
</w:ins>
```

### 删除

```xml
<w:del w:id="2" w:author="Claude AI Reviewer" w:date="2026-04-17T12:00:00Z">
  <w:r><w:delText>被删除的文字</w:delText></w:r>
</w:del>
```

**坑**：`<w:del>` 内部的 `<w:t>` 必须换成 `<w:delText>`。我们的 `_make_del()` 做这个转换。

### 替换 = 删除 + 插入

Word 没有原生的"替换"标签。`replace` 动作的实现：
1. 原 run 变成 `<w:del>`
2. 紧接着插入 `<w:ins>` 包裹新文字
3. 批注范围从 del 起点到 ins 终点

## Run 拆分（最复杂的一步）

同一段落内 `match_text` 可能跨多个 `<w:r>`。python-docx 读出的"段落文本"是所有 run 的拼接，但注入时必须精确到字符。

`_split_runs_at()` 的算法：
1. 遍历 paragraph 下所有 `<w:r>`，累计字符位置
2. 找到与 match_text `[start, end)` 相交的 runs
3. 把这些 runs 拆分成 `before | matched | after` 三段
4. 每段保留原 run 的 `<w:rPr>`（格式属性，如字体/加粗）
5. 只 return `matched` runs（before/after 原位保留）

**副作用**：段落的 run 数量会变多，视觉上无差异。Word 打开时会自然合并。

## comments.xml 结构

```xml
<w:comments>
  <w:comment w:id="0" w:author="Claude" w:date="..." w:initials="C">
    <w:p w14:paraId="ABCDEF12" w14:textId="77777777">
      <w:r><w:rPr><w:rStyle w:val="CommentReference"/></w:rPr><w:annotationRef/></w:r>
      <w:r>
        <w:rPr><w:color w:val="000000"/><w:sz w:val="20"/><w:szCs w:val="20"/></w:rPr>
        <w:t xml:space="preserve">[SEVERITY] 批注文字</w:t>
      </w:r>
    </w:p>
  </w:comment>
  ...
</w:comments>
```

- `w:id` 必须和 document.xml 中的 `commentReference` 一致
- `w14:paraId` 是 8 位十六进制，随机生成即可

## ID 分配策略

- 批注 id：从 0 递增
- 修订（ins/del）id：从 1000 递增，每条 decision 最多消耗 3 个（左/中/右 split + ins + del）
- `change_counter += 10`，给每条 decision 预留空间

这样不同 decision 之间 id 不会冲突。

## Auto-repair 在哪儿？

我们**没有实现** auto-repair（与 document-skills:docx 的 `pack.py` 对比）。取舍：
- 好处：代码简单，测试面小
- 代价：如果模型输出特别诡异，可能生成 Word 不能打开的 XML

当前的输入净化够用：
- match_text 必须精确匹配，否则跳过
- new_text 是字符串，直接塞进 `<w:t>`，XML 转义由 lxml 自动处理
- 日期/id 都是代码生成，不接模型输入

**如果后续发现某些极端输入导致文件损坏**，可以在 `inject()` 末尾调用 document-skills:docx 的 `validate.py` 校验一次。

## 测试策略

最小 smoke test（已通过，18条基线）：
```bash
python3 scripts/generate_sample_contract.py --output /tmp/s.docx
python3 scripts/inject_comments.py /tmp/s.docx examples/decisions_demo.json --output /tmp/o.docx
python3 -c "from docx import Document; Document('/tmp/o.docx'); print('OK')"
unzip -p /tmp/o.docx word/comments.xml | grep -c '<w:comment '   # 期望 = 18（decisions 数量）
unzip -p /tmp/o.docx word/document.xml | grep -c '<w:ins '       # 期望 ≥ 5（replace + insert_after）
unzip -p /tmp/o.docx word/document.xml | grep -c '<w:del '       # 期望 ≥ 4（replace + delete）
```

如果这几步都通过，可以放心演示。

**AMD 视频录制场景专用**：`decisions_demo.json` 已精心设计为 18 条，覆盖 `replace/comment_only/insert_after`，Word 侧边栏满屏、修订标记 5 处，视觉冲击足够拉满 3 分钟慢镜头。不要随意增删条目，除非在 `/Users/alchain/Documents/写作/03-视频创作/项目/2026.04-AMD锐龙AI-MAX/skills-plan/04-doc-reviewer-录制前检查清单.md` 跑完全流程验证。

## 已知坑 & 未覆盖

| 坑 | 现状 | 解决方案 |
|----|------|---------|
| 表格内的 `<w:p>` | 段落 id 会包含表格里的段落，但 inject 逻辑应该也能跑（它只看 body 下所有 `<w:p>`）| 测试过，合同里无表格 |
| 页眉/页脚 | 不处理 | 放弃 |
| 图片附近的段落 | 只要文字匹配得上就行 | 未测试极端情况 |
| SmartArt / 复杂嵌套 | 可能拆 run 失败 | 失败会跳过，不中断 |
| 段落开头就是 match_text | 能处理（before=空） | 已测 |
| match_text 跨段落 | **不支持** | 设计限制：每条 decision 只在一个段落内 |

## 与 Anthropic `document-skills:docx` 的比较

| 维度 | document-skills:docx | huashu-doc-reviewer |
|------|---------------------|-------------------|
| 编辑方式 | unpack → 人手改 XML → pack | JSON 驱动批量注入 |
| 模型角色 | 模型写 XML diff | 模型只输出 JSON |
| 适合场景 | 任意 docx 操作 | 专注"审阅留痕"类任务 |
| 验证 | 自带 schema validator + auto-repair | 无（依赖输入净化） |

我们借鉴了它的 comments XML 模板和 track changes schema。如果将来要加"accept changes"等高级功能，建议直接调用它。
