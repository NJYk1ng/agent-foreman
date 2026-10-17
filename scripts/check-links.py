#!/usr/bin/env python3
"""检查仓库内 Markdown / HTML 的本地链接和锚点。

只检查仓库里的文件；http(s) / mailto / tel / javascript 链接跳过。
Markdown 的锚点来源包括标题 slug 和显式 <a id="...">。
"""
import os
import re
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MD_FILES = [
    "README.md",
    "README.en.md",
    "CONTRIBUTING.md",
    "docs/contract.md",
    "docs/architecture.md",
]
HTML_FILES = [
    "docs/what-it-is-for.html",
    "docs/showcase.html",
]


def slug(text):
    text = text.strip().lower().replace("️", "").replace("︎", "")
    out = []
    for ch in text:
        cat = unicodedata.category(ch)
        if cat[0] in "LNM" or cat == "Pc" or ch in "- ":
            out.append(ch)
    return "".join(out).replace(" ", "-").strip("-")


def norm_anchor(anchor):
    return anchor.replace("️", "").replace("︎", "").strip("-")


def anchors(path):
    text = open(path, encoding="utf-8").read()
    result = set()
    for m in re.finditer(r'<a\s+[^>]*\bid="([^"]+)"', text):
        result.add(norm_anchor(m.group(1)))
    for m in re.finditer(r'\bid="([^"]+)"', text):
        result.add(norm_anchor(m.group(1)))
    for m in re.finditer(r"^#{1,6}\s+(.*)$", text, re.M):
        result.add(norm_anchor(slug(m.group(1))))
    return result


def links(path):
    text = open(path, encoding="utf-8").read()
    if path.endswith(".md"):
        for m in re.finditer(r'\[[^\]]*\]\(([^)\s]+)(?:\s+"[^"]*")?\)', text):
            yield m.group(1)
    else:
        for m in re.finditer(r'href=["\']([^"\']+)["\']', text):
            yield m.group(1)


def is_external(target):
    return target.startswith(
        ("http://", "https://", "mailto:", "tel:", "javascript:")
    )


def main():
    errors = []
    checked = 0
    for rel in MD_FILES + HTML_FILES:
        path = os.path.join(ROOT, rel)
        if not os.path.exists(path):
            errors.append(f"{rel}: 文件不存在")
            continue
        for target in links(path):
            target = target.strip()
            if not target or is_external(target):
                continue
            if target.startswith("#"):
                anchor = target[1:]
                if anchor and norm_anchor(anchor) not in anchors(path):
                    errors.append(f"{rel}: 锚点不存在：{target}")
                checked += 1
                continue
            file_part, _, anchor = target.partition("#")
            file_part = file_part.split("?")[0]
            full = os.path.normpath(os.path.join(os.path.dirname(path), file_part))
            if not os.path.exists(full):
                errors.append(f"{rel}: 本地文件不存在：{target}")
                continue
            if anchor and full.endswith((".md", ".html")):
                if norm_anchor(anchor) not in anchors(full):
                    errors.append(f"{rel}: 锚点不存在：{target}")
            checked += 1

    if errors:
        print(f"链接检查失败（{len(errors)} 个问题）：")
        for error in errors:
            print(f"  - {error}")
        return 1
    print(f"链接检查通过：{checked} 个本地链接/锚点")
    return 0


if __name__ == "__main__":
    sys.exit(main())
