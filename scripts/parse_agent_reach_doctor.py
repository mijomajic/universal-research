#!/usr/bin/env python3
"""Parse `agent-reach doctor --json` into shell assignments. Stdin = JSON."""

from __future__ import annotations

import json
import sys


def emit(name: str, val: str) -> None:
    print(f"{name}={json.dumps(val)}")


def pick(channels: dict, *keys):
    keyset = {k.lower() for k in keys}
    for k in keys:
        if k in channels and channels[k]:
            return channels[k]
    ch = channels.get("channels") or channels.get("data") or {}
    if isinstance(ch, dict):
        for k, v in ch.items():
            if str(k).lower() in keyset:
                return v
    if isinstance(ch, list):
        for item in ch:
            if isinstance(item, dict) and str(item.get("name", "")).lower() in keyset:
                return item
    return None


def status_of(channels: dict, keys: tuple[str, ...], pretty: str) -> str:
    item = pick(channels, *keys)
    if item is None:
        return "deg" if pretty == "pinterest" else "miss"
    if isinstance(item, str):
        t = item.lower()
        if "ok" in t or "ready" in t or t in ("yes", "true"):
            return "ok"
        return "deg"
    if isinstance(item, dict):
        active = item.get("active_backend") or item.get("backend")
        status = str(item.get("status") or item.get("state") or "")
        if active:
            return "ok"
        if "ok" in status.lower() or status.lower() in ("ready", "available"):
            return "ok"
        if item.get("ok") is True:
            return "ok"
        return "deg"
    return "unk"


def main() -> int:
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except Exception:
        emit("x_state", "unk")
        emit("reddit_state", "unk")
        emit("pinterest_state", "deg")
        return 0
    channels = data if isinstance(data, dict) else {}
    emit("x_state", status_of(channels, ("twitter", "x", "twitter/x"), "x"))
    emit("reddit_state", status_of(channels, ("reddit",), "reddit"))
    emit("pinterest_state", status_of(channels, ("pinterest",), "pinterest"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
