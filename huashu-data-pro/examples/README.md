# huashu-data-pro 演示用例

为 AMD 视频第四段（4:00-6:30）演示场景准备的最小闭环：
一份多表 Excel 财务数据 → 多专家并行分析 → 网页/Excel/PPT 三种报告。

## 文件清单

| 文件 | 用途 |
|------|------|
| `generate_sample_finance.py` | 生成假数据脚本（固定随机种子，可重复） |
| `sample_finance.xlsx` | 模拟公司半年财务（薪资/订单/成本三张表，含埋入的异常） |
| `sample_analysis.json` | 预制的多专家分析结果（三视角 + headline numbers + pivot hint） |
| `sample_report.xlsx` | Excel 报告产出（花叔录制时可直接打开对比） |

## 快速验证

```bash
cd .claude/skills/huashu-data-pro

# 1. 重新生成假数据（如果需要）
python3 examples/generate_sample_finance.py

# 2. 跑 Excel 报告生成
python3 scripts/build_xlsx.py \
  --data examples/sample_finance.xlsx \
  --analysis examples/sample_analysis.json \
  --output examples/sample_report.xlsx \
  --title "2026 H1 财务体检报告"

# 3. 打开检查视觉
open examples/sample_report.xlsx
```

## 预期产出（Excel 报告里应该看到）

- **核心摘要** sheet：蓝色顶线 + 三文鱼粉底 + 6 张 big number 卡片 + 结论段落
- **关键指标** sheet：三视角合并表，斑马纹，深棕灰表头
- **透视_结构** sheet：部门 × 月份 的订单金额透视，暖色色阶
- **原始_薪资 / 原始_订单 / 原始_成本** sheet：冻结首行 + 自动筛选 + 数值列色阶

## 视频演示完整命令（目标画面）

```bash
# 演示时终端输入（假设 LOCAL_LLM_BASE_URL 已 export）
huashu-data-pro analyze examples/sample_finance.xlsx \
  --formats web,xlsx,pptx \
  --local \
  --experts all
```

预期终端打印（视频要录这段）：

```
[huashu-data-pro] 启动三个视角并行分析 ──
  [●] 趋势分析师   启动 → 分析中 ⋯ → 完成
  [●] 结构分析师   启动 → 分析中 ⋯ → 完成
  [●] 异常分析师   启动 → 分析中 ⋯ → 完成
[huashu-data-pro] 三视角汇总完成，开始生成报告 ──
  [web]  HTML 报告  ⋯  done
  [xlsx] Excel 报告 ⋯  done
  [pptx] PPT 报告   ⋯  done
```

## 数据里埋了什么（演示剧本的 punchline）

为了让三个专家都能给出真实结论，数据里故意放进去：

- **趋势分析师会发现**：6 月订单金额较 1 月增长 +31%，销售部 3 月和 6 月奖金峰值清晰
- **结构分析师会发现**：销售部独占订单 68%，前 20% 客户贡献 67% 金额（典型二八）
- **异常分析师会发现**：
  - 14 条负金额订单全部集中在 2026-03
  - 2 条极端离群薪资：E9001（18.6 万）、E9002（9.8 万）

`sample_analysis.json` 的 findings/metrics 都对这些真实埋点有对应。

## 录制前的稳定性清单

- [ ] 依赖已装：`pip show openpyxl pandas` 版本 >= 3.1 / 2.0
- [ ] `unset ALL_PROXY HTTP_PROXY HTTPS_PROXY`
- [ ] 本地模型启动：LM Studio 或 Ollama 就绪（详见 `references/local-model-config.md`）
- [ ] 关 WIFI 也能跑完整个流程
- [ ] Excel 打开不乱码、数据透视色阶正常、封面 big number 排版居中
