#!/usr/bin/env python3
"""Normalize and merge source.json lists. Deterministic corpus helper."""

from __future__ import annotations

import argparse
import json
import sys
from typing import Any
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

DROP_QUERY = {
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "utm_term",
    "utm_content",
    "utm_id",
    "gclid",
    "fbclid",
    "mc_cid",
    "mc_eid",
    "igshid",
    "ref",
    "ref_src",
}


def canonical_url(url: str | None) -> str | None:
    if not url or not str(url).strip():
        return None
    raw = str(url).strip()
    parts = urlsplit(raw)
    scheme = (parts.scheme or "https").lower()
    host = (parts.hostname or "").lower()
    if not host:
        return raw
    port = parts.port
    netloc = host
    if port and not (scheme == "http" and port == 80) and not (scheme == "https" and port == 443):
        netloc = f"{host}:{port}"
    path = parts.path or ""
    if path != "/" and path.endswith("/"):
        path = path.rstrip("/")
    query_pairs = [
        (k, v)
        for k, v in parse_qsl(parts.query, keep_blank_values=True)
        if k.lower() not in DROP_QUERY
    ]
    query = urlencode(query_pairs, doseq=True)
    return urlunsplit((scheme, netloc, path, query, ""))


def load_items(path: str) -> list[dict[str, Any]]:
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    if isinstance(data, dict):
        if "sources" in data and isinstance(data["sources"], list):
            data = data["sources"]
        else:
            data = [data]
    if not isinstance(data, list):
        raise SystemExit(f"{path}: expected a JSON array or source object")
    out: list[dict[str, Any]] = []
    for item in data:
        if not isinstance(item, dict):
            raise SystemExit(f"{path}: array items must be objects")
        out.append(item)
    return out


def merge(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    merged: dict[str, dict[str, Any]] = {}
    passthrough: list[dict[str, Any]] = []
    for item in items:
        url = item.get("url") or item.get("canonical_url")
        canon = canonical_url(url if isinstance(url, str) else None)
        if canon:
            item = dict(item)
            item["canonical_url"] = canon
            prev = merged.get(canon)
            if prev is None:
                merged[canon] = item
            else:
                for key, value in item.items():
                    if key not in prev or prev[key] in (None, "", []):
                        prev[key] = value
        else:
            passthrough.append(item)
    return list(merged.values()) + passthrough


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="+", help="JSON files containing source objects")
    parser.add_argument("-o", "--output", help="Write merged JSON to this path")
    args = parser.parse_args(argv)
    items: list[dict[str, Any]] = []
    for path in args.files:
        items.extend(load_items(path))
    result = merge(items)
    text = json.dumps(result, indent=2, ensure_ascii=False) + "\n"
    if args.output:
        with open(args.output, "w", encoding="utf-8") as fh:
            fh.write(text)
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
