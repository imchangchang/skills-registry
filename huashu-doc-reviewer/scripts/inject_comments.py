#!/usr/bin/env python3
"""核心：注入批注 + 修订到 docx。

输入：原 docx + 决策 JSON
处理：
  1. 用 python-docx 打开文档、定位段落
  2. 对每条 decision，在段落中用 match_text 定位 run
  3. 拆分 run（把 match_text 单独拎出来），然后：
     - action=replace：前面加 <w:del>original, <w:ins>new；外加 <w:commentRangeStart/End> + <w:commentReference>
     - action=insert_after：在匹配 run 后加 <w:ins>new；外加批注标记
     - action=delete：把匹配 run 包进 <w:del>；外加批注标记
     - action=comment_only：只加批注标记，不改原文
  4. 确保 word/comments.xml 存在，每条批注写入
  5. 确保 word/_rels/document.xml.rels 和 [Content_Types].xml 里有 comments 的关系
  6. 保存为新 docx

输出：带批注 + 修订的新 docx；单条失败不中断。

用法：
    python3 inject_comments.py input.docx decisions.json --output output.docx
    python3 inject_comments.py input.docx decisions.json --output output.docx --author Claude
"""

import argparse
import copy
import json
import random
import shutil
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path

try:
    from docx import Document
    from docx.oxml.ns import qn, nsmap
    from docx.oxml import OxmlElement
    from lxml import etree
except ImportError as e:
    print(f"ERROR: missing dependency ({e}). Run: pip install python-docx lxml", file=sys.stderr)
    sys.exit(1)


# XML namespaces
NS = {
    "w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    "w14": "http://schemas.microsoft.com/office/word/2010/wordml",
    "w15": "http://schemas.microsoft.com/office/word/2012/wordml",
    "w16cid": "http://schemas.microsoft.com/office/word/2016/wordml/cid",
    "w16cex": "http://schemas.microsoft.com/office/word/2018/wordml/cex",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "ct": "http://schemas.openxmlformats.org/package/2006/content-types",
    "rel": "http://schemas.openxmlformats.org/package/2006/relationships",
}

W = NS["w"]


# --- 模板：空的 comments.xml / commentsExtended.xml 等 ---

COMMENTS_XML_TEMPLATE = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:comments xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
            xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml"/>
"""

COMMENTS_EXTENDED_TEMPLATE = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w15:commentsEx xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml"/>
"""

COMMENTS_IDS_TEMPLATE = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w16cid:commentsIds xmlns:w16cid="http://schemas.microsoft.com/office/word/2016/wordml/cid"/>
"""

COMMENTS_EXTENSIBLE_TEMPLATE = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w16cex:commentsExtensible xmlns:w16cex="http://schemas.microsoft.com/office/word/2018/wordml/cex"/>
"""


# --- 工具函数 ---

def _gen_hex_id() -> str:
    return f"{random.randint(1, 0x7FFFFFFE):08X}"


def _now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _make_element(tag: str, **attrs) -> etree._Element:
    """创建一个带 w: 命名空间的元素。"""
    el = OxmlElement(tag)
    for k, v in attrs.items():
        # k 形如 "w:id" 或 "id"
        if ":" in k:
            prefix, name = k.split(":", 1)
            el.set(qn(f"{prefix}:{name}"), str(v))
        else:
            el.set(qn(f"w:{k}"), str(v))
    return el


def _make_run(text: str, preserve_space: bool = True, is_del: bool = False) -> etree._Element:
    """创建一个 <w:r> 元素，包含 <w:t> 或 <w:delText>。"""
    r = OxmlElement("w:r")
    if is_del:
        t = OxmlElement("w:delText")
    else:
        t = OxmlElement("w:t")
    if preserve_space:
        t.set(qn("xml:space"), "preserve")
    t.text = text
    r.append(t)
    return r


def _copy_rPr(src_run: etree._Element) -> etree._Element | None:
    """复制源 run 的 <w:rPr>（格式属性），用于新 run 保持格式一致。"""
    if src_run is None:
        return None
    rPr = src_run.find(qn("w:rPr"))
    if rPr is not None:
        return copy.deepcopy(rPr)
    return None


# --- 核心：段落中定位与拆分 ---

def _paragraph_text(para_el: etree._Element) -> str:
    """拼接段落下所有 <w:t> 文本（不含 <w:delText>）。"""
    parts = []
    for t in para_el.iter(qn("w:t")):
        parts.append(t.text or "")
    return "".join(parts)


def _split_runs_at(para_el: etree._Element, match_text: str) -> tuple[list[etree._Element], int] | None:
    """把段落中第一次出现 match_text 的位置拆分出来。

    返回 (matched_runs, insert_index)：
      - matched_runs：包含 match_text 的 run 列表（可能跨多个 run，已拆分过）
      - insert_index：matched_runs 在 para_el.children 中的起始位置索引

    拆分逻辑：找到覆盖 [start, end) 字符范围的 runs，把首/尾 run 在边界处切断。
    拆分后 para 仍然是有效 XML，只是多了几个 run，可视上看不出区别。
    如果找不到 match_text，返回 None。
    """
    full = _paragraph_text(para_el)
    start = full.find(match_text)
    if start < 0:
        return None
    end = start + len(match_text)

    # 遍历 para 下的直接子元素，只关注 <w:r>；其他元素保留原位
    # 逐个 run 累计字符，判断与 [start, end) 的关系
    children = list(para_el)
    pos = 0  # 当前处理到段落文本的哪个字符
    new_matched_runs = []
    insert_idx = None  # 第一个 matched run 在 para_el 子元素中的索引

    # 为了安全，我们构造新的子元素列表，然后替换 para_el 的内容
    new_children = []

    for child in children:
        if child.tag != qn("w:r"):
            new_children.append(child)
            continue

        # 取 run 的可见文本（所有 w:t 连接）
        run_text_parts = [(t.text or "") for t in child.iter(qn("w:t"))]
        run_text = "".join(run_text_parts)
        run_start = pos
        run_end = pos + len(run_text)

        if run_end <= start or run_start >= end:
            # 与匹配区间无交集，原样保留
            new_children.append(child)
        else:
            # 有交集：需要拆分
            # 相对于 run 起点的匹配区间
            rel_start = max(0, start - run_start)
            rel_end = min(len(run_text), end - run_start)

            # run 内文本分三段：before | matched | after
            before_text = run_text[:rel_start]
            matched_text = run_text[rel_start:rel_end]
            after_text = run_text[rel_end:]

            rPr = _copy_rPr(child)

            if before_text:
                r_before = OxmlElement("w:r")
                if rPr is not None:
                    r_before.append(copy.deepcopy(rPr))
                t = OxmlElement("w:t")
                t.set(qn("xml:space"), "preserve")
                t.text = before_text
                r_before.append(t)
                new_children.append(r_before)

            if matched_text:
                r_matched = OxmlElement("w:r")
                if rPr is not None:
                    r_matched.append(copy.deepcopy(rPr))
                t = OxmlElement("w:t")
                t.set(qn("xml:space"), "preserve")
                t.text = matched_text
                r_matched.append(t)
                if insert_idx is None:
                    insert_idx = len(new_children)
                new_matched_runs.append(r_matched)
                new_children.append(r_matched)

            if after_text:
                r_after = OxmlElement("w:r")
                if rPr is not None:
                    r_after.append(copy.deepcopy(rPr))
                t = OxmlElement("w:t")
                t.set(qn("xml:space"), "preserve")
                t.text = after_text
                r_after.append(t)
                new_children.append(r_after)

        pos = run_end

    if insert_idx is None or not new_matched_runs:
        return None

    # 替换 para 内容
    for child in list(para_el):
        para_el.remove(child)
    for child in new_children:
        para_el.append(child)

    return new_matched_runs, insert_idx


# --- 注入：批注 + 修订 ---

def _make_comment_range_start(cid: int) -> etree._Element:
    return _make_element("w:commentRangeStart", id=cid)


def _make_comment_range_end(cid: int) -> etree._Element:
    return _make_element("w:commentRangeEnd", id=cid)


def _make_comment_reference(cid: int) -> etree._Element:
    r = OxmlElement("w:r")
    rPr = OxmlElement("w:rPr")
    rStyle = OxmlElement("w:rStyle")
    rStyle.set(qn("w:val"), "CommentReference")
    rPr.append(rStyle)
    r.append(rPr)
    ref = OxmlElement("w:commentReference")
    ref.set(qn("w:id"), str(cid))
    r.append(ref)
    return r


def _make_ins(run: etree._Element, ins_id: int, author: str, date: str) -> etree._Element:
    """包装一个 run 到 <w:ins>。"""
    ins = OxmlElement("w:ins")
    ins.set(qn("w:id"), str(ins_id))
    ins.set(qn("w:author"), author)
    ins.set(qn("w:date"), date)
    ins.append(run)
    return ins


def _make_del(orig_run: etree._Element, del_id: int, author: str, date: str) -> etree._Element:
    """把一个 run 转成 <w:del>。w:t 改成 w:delText。"""
    del_el = OxmlElement("w:del")
    del_el.set(qn("w:id"), str(del_id))
    del_el.set(qn("w:author"), author)
    del_el.set(qn("w:date"), date)

    # 复制 run，把 w:t 替换为 w:delText
    new_r = copy.deepcopy(orig_run)
    for t in list(new_r.iter(qn("w:t"))):
        # 转成 delText
        new_t = OxmlElement("w:delText")
        new_t.set(qn("xml:space"), "preserve")
        new_t.text = t.text or ""
        # 替换
        parent = t.getparent()
        idx = list(parent).index(t)
        parent.remove(t)
        parent.insert(idx, new_t)
    del_el.append(new_r)
    return del_el


def _apply_decision(para_el: etree._Element, decision: dict,
                    comment_id: int, change_id_start: int,
                    author: str, date: str) -> tuple[bool, str]:
    """对单个段落应用单条 decision。

    返回 (success, info_message)。
    """
    match = decision["match_text"]
    action = decision["action"]
    new_text = decision.get("new_text")

    split = _split_runs_at(para_el, match)
    if not split:
        return False, f"match_text {match!r} not found in paragraph"

    matched_runs, insert_idx = split

    # 插入 commentRangeStart 在第一个 matched run 之前
    start_marker = _make_comment_range_start(comment_id)
    end_marker = _make_comment_range_end(comment_id)
    comment_ref = _make_comment_reference(comment_id)

    # 先把 matched_runs 在 para 中找出来的位置（可能因为拆分变化过），按引用定位
    # insert_idx 是拆分后它的起始位置
    children = list(para_el)
    first_run = matched_runs[0]
    last_run = matched_runs[-1]
    # 从 children 里找索引
    try:
        first_idx = children.index(first_run)
        last_idx = children.index(last_run)
    except ValueError:
        return False, "internal error: matched run lost after split"

    change_id = change_id_start

    if action == "comment_only":
        # 只加批注标记，不动原文
        para_el.insert(first_idx, start_marker)
        # last_idx 因为插入了 start_marker 要 +1
        para_el.insert(last_idx + 2, end_marker)
        para_el.insert(last_idx + 3, comment_ref)

    elif action == "delete":
        # 把每个 matched run 替换成 <w:del>
        del_wrappers = []
        for r in matched_runs:
            del_el = _make_del(r, change_id, author, date)
            change_id += 1
            del_wrappers.append(del_el)
            parent = r.getparent()
            idx = list(parent).index(r)
            parent.remove(r)
            parent.insert(idx, del_el)

        # 重新计算位置，插入批注标记
        children = list(para_el)
        first_del_idx = children.index(del_wrappers[0])
        last_del_idx = children.index(del_wrappers[-1])
        para_el.insert(first_del_idx, start_marker)
        para_el.insert(last_del_idx + 2, end_marker)
        para_el.insert(last_del_idx + 3, comment_ref)

    elif action == "replace":
        # 先把 matched runs 包成 <w:del>
        del_wrappers = []
        for r in matched_runs:
            del_el = _make_del(r, change_id, author, date)
            change_id += 1
            del_wrappers.append(del_el)
            parent = r.getparent()
            idx = list(parent).index(r)
            parent.remove(r)
            parent.insert(idx, del_el)

        # 在最后一个 del 后面插入 <w:ins> 包裹的新 run
        rPr = _copy_rPr(matched_runs[0])
        new_run = OxmlElement("w:r")
        if rPr is not None:
            new_run.append(copy.deepcopy(rPr))
        t = OxmlElement("w:t")
        t.set(qn("xml:space"), "preserve")
        t.text = new_text or ""
        new_run.append(t)
        ins_el = _make_ins(new_run, change_id, author, date)
        change_id += 1

        children = list(para_el)
        first_del_idx = children.index(del_wrappers[0])
        last_del_idx = children.index(del_wrappers[-1])
        para_el.insert(last_del_idx + 1, ins_el)
        # 批注范围从第一个 del 到 ins
        para_el.insert(first_del_idx, start_marker)
        # 位置：first_del_idx 之后原先 last_del_idx 增加 1；再加 ins 又 +1
        # end_marker 放在 ins 之后
        # 更稳妥的做法：重新找索引
        children = list(para_el)
        ins_idx = children.index(ins_el)
        para_el.insert(ins_idx + 1, end_marker)
        para_el.insert(ins_idx + 2, comment_ref)

    elif action == "insert_after":
        # 在 matched runs 之后插入 <w:ins>
        rPr = _copy_rPr(matched_runs[0])
        new_run = OxmlElement("w:r")
        if rPr is not None:
            new_run.append(copy.deepcopy(rPr))
        t = OxmlElement("w:t")
        t.set(qn("xml:space"), "preserve")
        t.text = new_text or ""
        new_run.append(t)
        ins_el = _make_ins(new_run, change_id, author, date)
        change_id += 1

        children = list(para_el)
        last_idx = children.index(last_run)
        para_el.insert(last_idx + 1, ins_el)
        # 批注从 match 开始到 ins 结束
        first_idx = list(para_el).index(first_run)
        para_el.insert(first_idx, start_marker)
        children = list(para_el)
        ins_idx = children.index(ins_el)
        para_el.insert(ins_idx + 1, end_marker)
        para_el.insert(ins_idx + 2, comment_ref)

    else:
        return False, f"unknown action: {action}"

    return True, "OK"


# --- 确保批注基础设施存在 ---

def _ensure_comments_infrastructure(unpacked: Path, author: str) -> None:
    """确保 comments.xml / content_types / rels 都就位。"""
    word = unpacked / "word"
    word.mkdir(exist_ok=True)

    for filename, template in [
        ("comments.xml", COMMENTS_XML_TEMPLATE),
        ("commentsExtended.xml", COMMENTS_EXTENDED_TEMPLATE),
        ("commentsIds.xml", COMMENTS_IDS_TEMPLATE),
        ("commentsExtensible.xml", COMMENTS_EXTENSIBLE_TEMPLATE),
    ]:
        target = word / filename
        if not target.exists():
            target.write_text(template, encoding="utf-8")

    # 更新 [Content_Types].xml
    ct_path = unpacked / "[Content_Types].xml"
    if ct_path.exists():
        ct_tree = etree.parse(str(ct_path))
        ct_root = ct_tree.getroot()
        existing_parts = {o.get("PartName") for o in ct_root.iter() if o.tag.endswith("Override")}
        ct_ns = "http://schemas.openxmlformats.org/package/2006/content-types"

        overrides_to_add = [
            ("/word/comments.xml",
             "application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml"),
            ("/word/commentsExtended.xml",
             "application/vnd.openxmlformats-officedocument.wordprocessingml.commentsExtended+xml"),
            ("/word/commentsIds.xml",
             "application/vnd.openxmlformats-officedocument.wordprocessingml.commentsIds+xml"),
            ("/word/commentsExtensible.xml",
             "application/vnd.openxmlformats-officedocument.wordprocessingml.commentsExtensible+xml"),
        ]
        for part, ctype in overrides_to_add:
            if part not in existing_parts:
                ov = etree.SubElement(ct_root, f"{{{ct_ns}}}Override")
                ov.set("PartName", part)
                ov.set("ContentType", ctype)

        ct_tree.write(str(ct_path), xml_declaration=True, encoding="UTF-8", standalone=True)

    # 更新 word/_rels/document.xml.rels
    rels_path = unpacked / "word" / "_rels" / "document.xml.rels"
    if rels_path.exists():
        rels_tree = etree.parse(str(rels_path))
        rels_root = rels_tree.getroot()
        rel_ns = "http://schemas.openxmlformats.org/package/2006/relationships"
        existing_targets = {r.get("Target") for r in rels_root.iter() if r.tag.endswith("Relationship")}

        max_rid = 0
        for r in rels_root.iter():
            if r.tag.endswith("Relationship"):
                rid = r.get("Id", "")
                if rid.startswith("rId"):
                    try:
                        max_rid = max(max_rid, int(rid[3:]))
                    except ValueError:
                        pass

        to_add = [
            ("http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments",
             "comments.xml"),
            ("http://schemas.microsoft.com/office/2011/relationships/commentsExtended",
             "commentsExtended.xml"),
            ("http://schemas.microsoft.com/office/2016/09/relationships/commentsIds",
             "commentsIds.xml"),
            ("http://schemas.microsoft.com/office/2018/08/relationships/commentsExtensible",
             "commentsExtensible.xml"),
        ]
        for rtype, target in to_add:
            if target not in existing_targets:
                max_rid += 1
                rel = etree.SubElement(rels_root, f"{{{rel_ns}}}Relationship")
                rel.set("Id", f"rId{max_rid}")
                rel.set("Type", rtype)
                rel.set("Target", target)

        rels_tree.write(str(rels_path), xml_declaration=True, encoding="UTF-8", standalone=True)


def _append_comment_xml(unpacked: Path, comment_id: int, text: str,
                        author: str, initials: str, date: str) -> None:
    """往 word/comments.xml 里加一条批注。"""
    comments_path = unpacked / "word" / "comments.xml"
    tree = etree.parse(str(comments_path))
    root = tree.getroot()

    comment = etree.SubElement(root, f"{{{W}}}comment")
    comment.set(f"{{{W}}}id", str(comment_id))
    comment.set(f"{{{W}}}author", author)
    comment.set(f"{{{W}}}date", date)
    comment.set(f"{{{W}}}initials", initials)

    p = etree.SubElement(comment, f"{{{W}}}p")
    p.set(f"{{{NS['w14']}}}paraId", _gen_hex_id())
    p.set(f"{{{NS['w14']}}}textId", "77777777")

    r = etree.SubElement(p, f"{{{W}}}r")
    rPr = etree.SubElement(r, f"{{{W}}}rPr")
    rStyle = etree.SubElement(rPr, f"{{{W}}}rStyle")
    rStyle.set(f"{{{W}}}val", "CommentReference")
    annot_ref = etree.SubElement(r, f"{{{W}}}annotationRef")

    r2 = etree.SubElement(p, f"{{{W}}}r")
    t = etree.SubElement(r2, f"{{{W}}}t")
    t.set(qn("xml:space"), "preserve")
    t.text = text

    tree.write(str(comments_path), xml_declaration=True, encoding="UTF-8", standalone=True)


# --- 顶层编排 ---

def inject(input_docx: str, decisions_path: str, output_docx: str,
           author: str = "Claude", initials: str = "C") -> dict:
    """主入口。返回摘要字典：{success: N, skipped: M, warnings: [...]}"""
    input_path = Path(input_docx)
    output_path = Path(output_docx)
    if not input_path.exists():
        raise FileNotFoundError(f"Input not found: {input_docx}")

    decisions = json.loads(Path(decisions_path).read_text(encoding="utf-8"))
    if isinstance(decisions, dict):
        dec_list = decisions.get("decisions", [])
    else:
        dec_list = decisions
    if not isinstance(dec_list, list):
        raise ValueError("decisions JSON must contain a 'decisions' list")

    # 用 zipfile 解包原 docx 到临时目录
    import tempfile
    tmpdir = tempfile.mkdtemp(prefix="docreviewer_")
    tmp_unpacked = Path(tmpdir) / "unpacked"
    tmp_unpacked.mkdir()
    with zipfile.ZipFile(input_path, "r") as zf:
        zf.extractall(tmp_unpacked)

    # 确保批注基础设施
    _ensure_comments_infrastructure(tmp_unpacked, author)

    # 读取 word/document.xml
    doc_xml_path = tmp_unpacked / "word" / "document.xml"
    doc_tree = etree.parse(str(doc_xml_path))
    doc_root = doc_tree.getroot()

    # 获取所有段落
    body = doc_root.find(qn("w:body"))
    paragraphs = list(body.iter(qn("w:p")))

    # 为每条决策分配 comment_id 和 change_id
    # comment_id 从 0 开始；change_id 从 1000 开始避免冲突
    date = _now()
    comment_counter = 0
    change_counter = 1000

    success_count = 0
    skipped_count = 0
    warnings = []

    for i, dec in enumerate(dec_list):
        pid = dec.get("para_id")
        try:
            if pid is None or pid < 0 or pid >= len(paragraphs):
                warnings.append(f"decision[{i}]: para_id={pid} out of range (total {len(paragraphs)})")
                skipped_count += 1
                continue

            para_el = paragraphs[pid]
            ok, msg = _apply_decision(para_el, dec, comment_counter,
                                      change_counter, author, date)
            if not ok:
                warnings.append(f"decision[{i}] (para {pid}): {msg}")
                skipped_count += 1
                continue

            # 写入 comments.xml
            comment_text = dec.get("comment", "")
            severity = dec.get("severity", "info")
            full_comment = f"[{severity.upper()}] {comment_text}"
            _append_comment_xml(tmp_unpacked, comment_counter,
                               full_comment, author, initials, date)

            comment_counter += 1
            change_counter += 10  # 留点空间
            success_count += 1
        except Exception as e:
            warnings.append(f"decision[{i}]: exception {type(e).__name__}: {e}")
            skipped_count += 1

    # 保存 document.xml
    doc_tree.write(str(doc_xml_path), xml_declaration=True,
                   encoding="UTF-8", standalone=True)

    # 重新打包成 docx
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if output_path.exists():
        output_path.unlink()
    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in tmp_unpacked.rglob("*"):
            if f.is_file():
                zf.write(f, f.relative_to(tmp_unpacked))

    # 清理
    shutil.rmtree(tmpdir, ignore_errors=True)

    return {
        "success": success_count,
        "skipped": skipped_count,
        "total": len(dec_list),
        "output": str(output_path.resolve()),
        "warnings": warnings,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Inject comments + tracked changes into docx")
    parser.add_argument("input", help="Input .docx file")
    parser.add_argument("decisions", help="Input decisions.json")
    parser.add_argument("--output", "-o", required=True, help="Output .docx file")
    parser.add_argument("--author", default="Claude AI Reviewer", help="Author name")
    parser.add_argument("--initials", default="AI", help="Author initials")
    args = parser.parse_args()

    try:
        result = inject(args.input, args.decisions, args.output,
                       author=args.author, initials=args.initials)
    except Exception as e:
        print(f"ERROR: {type(e).__name__}: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        return 1

    print(json.dumps(result, ensure_ascii=False, indent=2))
    if result["skipped"]:
        print(f"\nWARN: {result['skipped']}/{result['total']} decisions skipped", file=sys.stderr)
        return 0  # 不算失败——跳过是设计内行为
    # 全绿通过的视觉反馈——录制时镜头给到这里效果炸
    print(
        f"\nSUCCESS: {result['success']} comments + revisions injected. "
        f"Open with: open {result['output']!r}",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
