# examples/ 目录

这里是演示用的完整一套素材：合同 → 决策 JSON → 带批注的产物。

## 文件清单

| 文件 | 说明 | 大小 |
|------|------|------|
| `sample_contract.docx` | 模拟商单合同（多处埋了风险点） | ~37KB |
| `decisions_demo.json` | 预制的决策 JSON（**18 条批注**，涵盖 replace/comment_only/insert_after） | ~6KB |
| `expected_output.docx` | 预跑的带批注产物（视频演示直接用它）含 18 批注 + 11 修订标签 | ~41KB |
| `README.md` | 本文件 |

## 怎么重跑

如果你改了 decisions 或想验证代码：

```bash
cd <skill 根目录>

# Step 1（可选，已有就不用跑）：重生成合同
python3 scripts/generate_sample_contract.py --output examples/sample_contract.docx

# Step 2：从 decisions_demo.json 注入批注+修订
python3 scripts/inject_comments.py \
    examples/sample_contract.docx \
    examples/decisions_demo.json \
    --output examples/expected_output.docx

# Step 3：打开看效果（Mac）
open examples/expected_output.docx
```

Windows：
```
start examples/expected_output.docx
```

## 预期效果

Word 打开 `expected_output.docx` 后：

1. **右侧侧边栏有 18 条批注气泡**（满屏视觉冲击，录制慢镜头管够）
2. **正文里有 5 处修订标记**（4 处 replace + 1 处 insert_after，红色删除线 + 红色新文字）：
   - 第 7 段：「根据本合同」→「依据本合同」
   - 第 13 段：「30日内」→「15个工作日内」
   - 第 17 段：「乙方应无条件配合删除或修改」→「双方协商确定处理方案」
   - 第 23 段：「乙方不得将相关内容用于其他商业用途」→「未经甲方书面同意...直接竞争关系的商业用途」
   - 第 29 段：「甲方所在地人民法院」→「乙方所在地或合同签订地人民法院」
   - 第 32 段：「另行签订补充协议」后追加「，补充协议与本合同具有同等法律效力」
3. 其余 12 条是 `comment_only`（只加批注，不动原文）
4. 每条批注前缀带 severity：`[CRITICAL]` / `[MAJOR]` / `[MINOR]`
5. 批注作者显示为「Claude AI Reviewer」

## 视频演示使用建议

**场景**：脚本 6:30-9:30 公文批注段（全片高潮）

**录制脚本**：
1. 镜头给到终端，敲入：
   ```
   python3 scripts/inject_comments.py \
       examples/sample_contract.docx \
       examples/decisions_demo.json \
       --output examples/expected_output.docx
   ```
2. 回车，看到 `"success": 10, "skipped": 0`
3. 切到 Finder，双击 `expected_output.docx`
4. Word 打开，镜头慢慢扫到右侧批注气泡
5. 演示：鼠标点开第一条批注，念出批注文字（"公文语境下'依据'比'根据'更规范"）

**如果本地大模型要参与**（完整流程演示）：
1. 第一步先跑 `scripts/read_docx.py sample_contract.docx --for-model --output for_model.json`
2. 把 for_model.json 送给本地 LLM（带 `references/reviewer-prompt.md` 的 contract prompt）
3. LLM 输出 decisions.json
4. 再跑 inject_comments.py

**演示断网兜底**：如果本地模型当天发抽，直接跳过 LLM 步骤，用 decisions_demo.json。画面节奏一样好看，观众看不出差别。
