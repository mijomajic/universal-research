#!/usr/bin/env python3
"""Structural validation for the universal-research skill package."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "SKILL.md",
    "install.sh",
    "uninstall.sh",
    "README.md",
    "agents/openai.yaml",
    "references/research-planning.md",
    "references/source-routing.md",
    "references/evidence-quality.md",
    "references/synthesis.md",
    "references/output-design.md",
    "references/docs-index.md",
    "references/modes/general.md",
    "references/modes/market.md",
    "references/modes/science.md",
    "references/modes/academic.md",
    "references/modes/technical.md",
    "references/modes/visual.md",
    "references/modes/competitive.md",
    "references/modes/content.md",
    "references/modes/keyword.md",
    "references/integrations/agent-reach.md",
    "references/integrations/firecrawl.md",
    "references/integrations/reddit.md",
    "references/integrations/x.md",
    "references/integrations/pinterest.md",
    "references/integrations/vision-models.md",
    "schemas/research-brief.json",
    "schemas/source.json",
    "schemas/finding.json",
    "schemas/report.json",
    "scripts/doctor.sh",
    "scripts/lib.sh",
    "scripts/merge_sources.py",
    "scripts/parse_agent_reach_doctor.py",
    "evals/evals.json",
]

SCHEMA_REQUIRED = {
    "research-brief.json": ["topic", "research_questions", "depth"],
    "source.json": ["title"],
    "finding.json": ["claim"],
    "report.json": ["objective", "key_findings"],
}


def parse_frontmatter(text: str) -> dict[str, str]:
    if not text.startswith("---"):
        raise ValueError("SKILL.md must start with YAML frontmatter")
    end = text.find("\n---", 3)
    if end == -1:
        raise ValueError("SKILL.md frontmatter is unclosed")
    block = text[3:end].strip("\n")
    data: dict[str, str] = {}
    key: str | None = None
    acc: list[str] = []
    folded = False
    for line in block.splitlines():
        if key and (line.startswith("  ") or line.startswith("\t") or (folded and line and not re.match(r"^[A-Za-z0-9_-]+:", line))):
            acc.append(line.strip())
            continue
        if key is not None:
            data[key] = " ".join(x for x in acc if x)
            key = None
            acc = []
            folded = False
        m = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if not m:
            continue
        key, val = m.group(1), m.group(2)
        if val in (">", "|"):
            folded = True
            acc = []
        else:
            acc = [val.strip().strip('"').strip("'")]
            folded = False
    if key is not None:
        data[key] = " ".join(x for x in acc if x)
    return data


def main() -> int:
    errors: list[str] = []
    for rel in REQUIRED_FILES:
        path = ROOT / rel
        if not path.is_file():
            errors.append(f"missing {rel}")

    skill = ROOT / "SKILL.md"
    if skill.is_file():
        text = skill.read_text(encoding="utf-8")
        lines = text.splitlines()
        if len(lines) > 500:
            errors.append(f"SKILL.md has {len(lines)} lines (limit 500)")
        try:
            meta = parse_frontmatter(text)
        except ValueError as exc:
            errors.append(str(exc))
            meta = {}
        if meta.get("name") != "universal-research":
            errors.append(f"frontmatter name must be universal-research, got {meta.get('name')!r}")
        desc = meta.get("description", "")
        if not desc:
            errors.append("frontmatter description is empty")
        elif len(desc) > 1024:
            errors.append(f"description is {len(desc)} chars (max 1024)")
        if "research" not in desc.lower():
            errors.append("description should mention research")
        body = text.split("\n---", 2)[-1]
        for needle in (
            "references/modes/",
            "references/integrations/firecrawl.md",
            "references/docs-index.md",
            "ordinary Q&A",
        ):
            if needle not in body:
                errors.append(f"SKILL.md body missing {needle!r}")

    for name, required in SCHEMA_REQUIRED.items():
        path = ROOT / "schemas" / name
        if not path.is_file():
            continue
        try:
            schema = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"{name}: invalid JSON ({exc})")
            continue
        props = schema.get("required") or []
        for field in required:
            if field not in props:
                errors.append(f"{name}: required[] missing {field}")

    evals_path = ROOT / "evals" / "evals.json"
    if evals_path.is_file():
        try:
            evals = json.loads(evals_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            errors.append(f"evals.json: {exc}")
            evals = {}
        cases = evals.get("cases") or []
        if len(cases) < 8:
            errors.append("evals.json should include trigger-positive, negative, and domain cases")
        polarities = {True: 0, False: 0}
        for case in cases:
            rel = case.get("file")
            if not rel:
                errors.append("eval case missing file")
                continue
            if not (ROOT / "evals" / rel).is_file():
                errors.append(f"missing eval file {rel}")
            polarities[bool(case.get("trigger"))] = polarities.get(bool(case.get("trigger")), 0) + 1
        if polarities.get(True, 0) < 1 or polarities.get(False, 0) < 1:
            errors.append("evals must include both trigger-positive and trigger-negative cases")

    if "api.firecrawl.dev" in (ROOT / "SKILL.md").read_text(encoding="utf-8"):
        errors.append("SKILL.md must not send agents to Firecrawl Cloud")

    if errors:
        print("validate: FAIL")
        for err in errors:
            print(f"  - {err}")
        return 1
    print("validate: OK")
    print(f"  files {len(REQUIRED_FILES)}")
    print(f"  SKILL.md lines {len((ROOT / 'SKILL.md').read_text(encoding='utf-8').splitlines())}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
