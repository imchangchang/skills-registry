#!/usr/bin/env python3
"""
generate_sample_finance.py — 生成一份模拟公司半年财务数据作为演示输入。

产出 examples/sample_finance.xlsx，三张表：
  薪资    员工 × 月 的薪资发放（2026-01 到 2026-06）
  订单    客户/部门/金额/日期
  成本    部门 × 月 的运营成本

特意埋入若干异常点（负金额、超高薪资、异常月份订单），让三个专家都能产出真实结论。
"""

from __future__ import annotations

import random
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd


RNG = random.Random(20260417)   # 固定种子，保证可重复

DEPARTMENTS = ["销售", "市场", "产品", "研发", "财务", "行政"]
MONTHS = ["2026-01", "2026-02", "2026-03", "2026-04", "2026-05", "2026-06"]


def gen_salary() -> pd.DataFrame:
    rows = []
    employees = [
        (f"E{1000+i:04d}",
         RNG.choice(DEPARTMENTS),
         RNG.choice(["P4", "P5", "P6", "P7", "M1", "M2"]))
        for i in range(60)
    ]
    base_by_level = {"P4": 14000, "P5": 18000, "P6": 24000,
                     "P7": 32000, "M1": 38000, "M2": 52000}
    for emp_id, dept, level in employees:
        base = base_by_level[level] + RNG.randint(-2000, 3500)
        for m in MONTHS:
            amount = base + RNG.randint(-500, 900)
            # 埋异常：销售部几个月有高额奖金
            if dept == "销售" and m in ("2026-03", "2026-06"):
                amount += RNG.randint(8000, 26000)
            rows.append({
                "员工ID": emp_id,
                "部门": dept,
                "职级": level,
                "月份": m,
                "薪资": amount,
            })
    # 埋 2 条明显离群
    rows.append({"员工ID": "E9001", "部门": "销售", "职级": "M2",
                 "月份": "2026-03", "薪资": 186000})
    rows.append({"员工ID": "E9002", "部门": "研发", "职级": "P7",
                 "月份": "2026-05", "薪资": 98000})
    return pd.DataFrame(rows)


def gen_orders() -> pd.DataFrame:
    customers = [f"C{9000+i:03d}" for i in range(40)]
    rows = []
    for m in MONTHS:
        start = datetime.strptime(m + "-01", "%Y-%m-%d")
        for _ in range(RNG.randint(110, 160)):
            day = start + timedelta(days=RNG.randint(0, 27))
            cust = RNG.choice(customers)
            dept = RNG.choice(["销售", "市场"])
            # 基本正态分布金额
            amount = max(800, int(RNG.gauss(mu=18000, sigma=11000)))
            if RNG.random() < 0.05:
                amount = int(amount * RNG.choice([3, 4, 5]))  # 大单
            rows.append({
                "订单日期": day.strftime("%Y-%m-%d"),
                "月份": m,
                "客户ID": cust,
                "部门": dept,
                "金额": amount,
                "状态": RNG.choices(
                    ["成交", "取消", "退款"], weights=[0.85, 0.1, 0.05])[0],
            })
    # 埋 14 条负金额（异常分析师应该能抓到）
    for _ in range(14):
        rows.append({
            "订单日期": "2026-03-" + str(RNG.randint(1, 28)).zfill(2),
            "月份": "2026-03",
            "客户ID": RNG.choice(customers),
            "部门": "销售",
            "金额": -RNG.randint(500, 3500),
            "状态": "退款",
        })
    df = pd.DataFrame(rows)
    return df.sort_values("订单日期").reset_index(drop=True)


def gen_costs() -> pd.DataFrame:
    rows = []
    base_cost = {"销售": 380000, "市场": 420000, "产品": 260000,
                 "研发": 720000, "财务": 95000, "行政": 140000}
    for dept, base in base_cost.items():
        for m in MONTHS:
            fluct = RNG.randint(-60000, 80000)
            rows.append({
                "部门": dept,
                "月份": m,
                "人力成本": int(base * 0.55 + RNG.randint(-15000, 15000)),
                "运营成本": int(base * 0.35 + fluct * 0.5),
                "其他成本": int(base * 0.10 + fluct * 0.3),
                "合计": 0,
            })
    df = pd.DataFrame(rows)
    df["合计"] = df[["人力成本", "运营成本", "其他成本"]].sum(axis=1)
    return df


def main() -> None:
    out = Path(__file__).parent / "sample_finance.xlsx"
    with pd.ExcelWriter(out, engine="openpyxl") as writer:
        gen_salary().to_excel(writer, sheet_name="薪资", index=False)
        gen_orders().to_excel(writer, sheet_name="订单", index=False)
        gen_costs().to_excel(writer, sheet_name="成本", index=False)
    print(f"[sample] 已生成: {out}")


if __name__ == "__main__":
    main()
