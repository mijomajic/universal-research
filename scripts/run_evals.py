#!/usr/bin/env python3
"""Structural evals + helper unit tests. Behavioral cases are scored by an agent/human."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True, check=False, **kwargs)


def test_merge_sources() -> None:
    sys.path.insert(0, str(SCRIPTS))
    import merge_sources  # type: ignore

    a = {"title": "A", "url": "https://Example.com/path/?utm_source=x"}
    b = {"title": "A2", "url": "https://example.com/path"}
    merged = merge_sources.merge([a, b])
    assert len(merged) == 1, merged
    assert merged[0]["canonical_url"] == "https://example.com/path"
    assert merge_sources.canonical_url("http://x.com:80/a/") == "http://x.com/a"


def test_persist() -> None:
    with tempfile.TemporaryDirectory() as td:
        zshrc = Path(td) / ".zshrc"
        zshrc.write_text(
            'export FIRECRAWL_API_URL="http://192.168.1.80:3002/"\n'
            'export FIRECRAWL_API_URL="http://192.168.1.80:3002"\n'
            "export PATH=/usr/bin\n",
            encoding="utf-8",
        )
        script = f"""
set -e
. "{SCRIPTS / "lib.sh"}"
ur_persist_firecrawl_url "{zshrc}"
"""
        proc = run(["bash", "-c", script])
        if proc.returncode != 0:
            raise AssertionError(proc.stderr or proc.stdout)
        text = zshrc.read_text(encoding="utf-8")
        assert text.count("FIRECRAWL_API_URL=") == 1, text
        assert 'export FIRECRAWL_API_URL="http://192.168.1.80:3002"' in text
        assert "http://192.168.1.80:3002/" not in text
        assert "PATH=/usr/bin" in text


def test_evals_index() -> None:
    evals = json.loads((ROOT / "evals" / "evals.json").read_text(encoding="utf-8"))
    polarities = [bool(c["trigger"]) for c in evals["cases"]]
    assert True in polarities and False in polarities
    modes = {m for c in evals["cases"] for m in c.get("modes") or []}
    needed = {
        "science",
        "academic",
        "market",
        "technical",
        "visual",
        "keyword",
        "competitive",
        "content",
        "general",
    }
    missing = needed - modes
    assert not missing, missing


def main() -> int:
    val = run([sys.executable, str(SCRIPTS / "validate.py")])
    sys.stdout.write(val.stdout)
    sys.stderr.write(val.stderr)
    if val.returncode != 0:
        return val.returncode
    tests = [test_merge_sources, test_persist, test_evals_index]
    failed = 0
    for fn in tests:
        try:
            fn()
            print(f"ok  {fn.__name__}")
        except Exception as exc:
            failed += 1
            print(f"FAIL {fn.__name__}: {exc}")
    print("behavioral cases: see evals/evals.json (agent/human scored)")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
