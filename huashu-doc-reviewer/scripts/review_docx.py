#!/usr/bin/env python3
"""顶层编排：把 read + validate + inject 串起来。

用法：
    # 用预制 decisions JSON（不依赖模型）：
    python3 review_docx.py input.docx decisions.json --output reviewed.docx

    # 只读取生成给模型的精简 JSON（不做注入）：
    python3 review_docx.py input.docx --extract-only --output for_model.json

注意：本脚本**不直接调用 LLM**。模型调用由上层 agent 负责。
本脚本的作用是：给定一个合法的 decisions.json，稳定、幂等地生成审阅 docx。
"""

import argparse
import json
import sys
from pathlib import Path

# 保证同目录 import 可用
sys.path.insert(0, str(Path(__file__).parent))

from read_docx import read_docx, to_model_prompt  # noqa: E402
from validate_decisions import validate  # noqa: E402
from inject_comments import inject  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description="End-to-end doc review pipeline")
    parser.add_argument("input", help="Input .docx file")
    parser.add_argument("decisions", nargs="?",
                        help="Input decisions.json (required unless --extract-only)")
    parser.add_argument("--output", "-o", required=True, help="Output file")
    parser.add_argument("--extract-only", action="store_true",
                        help="Only extract paragraphs for model prompt; no injection")
    parser.add_argument("--author", default="Claude AI Reviewer", help="Author name")
    parser.add_argument("--initials", default="AI", help="Author initials")
    args = parser.parse_args()

    if args.extract_only:
        try:
            data = read_docx(args.input)
        except Exception as e:
            print(f"ERROR: {e}", file=sys.stderr)
            return 1
        slim = to_model_prompt(data)
        Path(args.output).write_text(slim, encoding="utf-8")
        print(f"Wrote slim JSON for model: {args.output}", file=sys.stderr)
        return 0

    if not args.decisions:
        parser.error("decisions argument required unless --extract-only")

    # 校验 decisions
    try:
        raw = json.loads(Path(args.decisions).read_text(encoding="utf-8"))
    except Exception as e:
        print(f"ERROR: cannot read {args.decisions}: {e}", file=sys.stderr)
        return 1

    cleaned, errors = validate(raw)
    if errors:
        print(f"WARN: {len(errors)} validation errors (fallback: only valid decisions will be applied)",
              file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)

    if not cleaned["decisions"]:
        print("ERROR: no valid decisions to apply", file=sys.stderr)
        return 1

    # 写入临时清理后的 decisions，再传给 inject
    import tempfile
    tmp = tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False, encoding="utf-8")
    json.dump(cleaned, tmp, ensure_ascii=False, indent=2)
    tmp.close()

    try:
        result = inject(args.input, tmp.name, args.output,
                       author=args.author, initials=args.initials)
    except Exception as e:
        print(f"ERROR: inject failed: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        return 1
    finally:
        Path(tmp.name).unlink(missing_ok=True)

    print(json.dumps(result, ensure_ascii=False, indent=2))
    print(f"\nOutput: {result['output']}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
