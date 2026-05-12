#!/usr/bin/env python3
"""校验模型输出的 decisions JSON 是否合法。

不合法的条目会被过滤掉，返回：
- clean_decisions: 所有通过校验的条目
- errors: 每条失败的原因（用于提示模型重试）

用法：
    python3 validate_decisions.py decisions.json
    python3 validate_decisions.py decisions.json --output clean_decisions.json

退出码：
    0 = 全部通过
    1 = 有失败条目（但 clean 部分仍会输出，不中断流程）
    2 = 整体结构不合法（无法解析）
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ALLOWED_MODES = {"contract", "report", "proposal", "resume", "general"}
ALLOWED_ACTIONS = {"replace", "insert_after", "delete", "comment_only"}
ALLOWED_SEVERITY = {"critical", "major", "minor", "info"}


def _validate_decision(d: Any, idx: int) -> tuple[bool, str]:
    """校验单条 decision。返回 (is_valid, error_message)。"""
    if not isinstance(d, dict):
        return False, f"decisions[{idx}]: not a dict"

    required = ["para_id", "match_text", "action", "comment", "severity"]
    for k in required:
        if k not in d:
            return False, f"decisions[{idx}]: missing field '{k}'"

    if not isinstance(d["para_id"], int) or d["para_id"] < 0:
        return False, f"decisions[{idx}]: 'para_id' must be non-negative int, got {d['para_id']!r}"

    if not isinstance(d["match_text"], str) or not d["match_text"].strip():
        return False, f"decisions[{idx}]: 'match_text' must be non-empty string"

    if d["action"] not in ALLOWED_ACTIONS:
        return False, f"decisions[{idx}]: 'action' must be one of {ALLOWED_ACTIONS}, got {d['action']!r}"

    if d["action"] in {"replace", "insert_after"}:
        nt = d.get("new_text")
        if not isinstance(nt, str) or not nt:
            return False, f"decisions[{idx}]: 'new_text' required (non-empty string) when action={d['action']}"
    elif d["action"] in {"delete", "comment_only"}:
        # new_text 应为 null 或不存在；如果是空字符串也允许
        nt = d.get("new_text")
        if nt is not None and nt != "":
            return False, f"decisions[{idx}]: 'new_text' must be null when action={d['action']}, got {nt!r}"

    if not isinstance(d["comment"], str) or not d["comment"].strip():
        return False, f"decisions[{idx}]: 'comment' must be non-empty string"

    if d["severity"] not in ALLOWED_SEVERITY:
        return False, f"decisions[{idx}]: 'severity' must be one of {ALLOWED_SEVERITY}, got {d['severity']!r}"

    return True, ""


def validate(raw: Any) -> tuple[dict, list[str]]:
    """校验整个 decisions JSON。返回 (cleaned_dict, errors_list)。

    cleaned_dict 格式：{"mode": ..., "decisions": [...通过的条目...]}
    即使 errors 非空，cleaned 中的条目仍保证合法可用。
    """
    errors: list[str] = []

    if not isinstance(raw, dict):
        return {"mode": "general", "decisions": []}, [
            "top-level must be a dict with 'mode' and 'decisions' keys"
        ]

    mode = raw.get("mode", "general")
    if mode not in ALLOWED_MODES:
        errors.append(f"mode={mode!r} not in {ALLOWED_MODES}; coerced to 'general'")
        mode = "general"

    decisions = raw.get("decisions", [])
    if not isinstance(decisions, list):
        return {"mode": mode, "decisions": []}, errors + ["'decisions' must be a list"]

    clean: list[dict] = []
    for i, d in enumerate(decisions):
        ok, err = _validate_decision(d, i)
        if ok:
            # 规范化 new_text 字段
            nd = dict(d)
            if nd["action"] in {"delete", "comment_only"}:
                nd["new_text"] = None
            clean.append(nd)
        else:
            errors.append(err)

    return {"mode": mode, "decisions": clean}, errors


def build_retry_prompt(errors: list[str]) -> str:
    """给模型重试时的 prompt 模板——指出哪条哪错，要求重新输出。"""
    if not errors:
        return "No errors. JSON is valid."
    lines = [
        "你上次输出的 decisions JSON 中以下条目不符合 schema：",
    ]
    lines.extend(f"  - {e}" for e in errors)
    lines.append("")
    lines.append("请重新输出完整的 JSON，修正以上问题。只输出 JSON，不加任何解释文字。")
    lines.append("必须字段：para_id(int), match_text(str), action(replace|insert_after|delete|comment_only), "
                 "new_text(str|null), comment(str), severity(critical|major|minor|info)")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate decisions JSON")
    parser.add_argument("input", help="Input decisions.json")
    parser.add_argument("--output", "-o", help="Output cleaned JSON (default: stdout)")
    parser.add_argument("--retry-prompt", action="store_true",
                        help="Print a retry prompt for the model on stderr")
    args = parser.parse_args()

    try:
        raw = json.loads(Path(args.input).read_text(encoding="utf-8"))
    except Exception as e:
        print(f"ERROR: Cannot parse {args.input}: {e}", file=sys.stderr)
        return 2

    cleaned, errors = validate(raw)

    out = json.dumps(cleaned, ensure_ascii=False, indent=2)
    if args.output:
        Path(args.output).write_text(out, encoding="utf-8")
        print(f"Wrote: {args.output}", file=sys.stderr)
    else:
        print(out)

    if errors:
        print(f"\n{len(errors)} validation errors:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        if args.retry_prompt:
            print("\n---Retry prompt---", file=sys.stderr)
            print(build_retry_prompt(errors), file=sys.stderr)
        return 1

    print(f"OK: {len(cleaned['decisions'])} decisions, all valid", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
