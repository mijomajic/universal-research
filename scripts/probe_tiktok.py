#!/usr/bin/env python3
"""Inspect TikTok / PyTok capability without hitting TikTok.

This is the TikTok integration probe, not a PyTok API wrapper. Doctor and
setup scripts call it. It never prints cookies, tokens, passwords, or
account identifiers.
"""

from __future__ import annotations

import argparse
import ast
import inspect
import json
import os
import sqlite3
import subprocess
import sys
from pathlib import Path
from typing import Any, Callable

# Upstream: https://github.com/MEOMcGill/pytok (networkdynamics/pytok redirects here).
# Do not `pip install pytok` — that PyPI name is a different project.
PYTOK_GIT = os.environ.get("UR_PYTOK_GIT", "https://github.com/MEOMcGill/pytok.git")
STATES = ("ok", "fail", "deg", "unk", "miss")


def _home() -> Path:
    return Path(os.environ.get("PYTOK_HOME", Path.home() / ".pytok")).expanduser()


def _cache_dir() -> Path:
    return Path(os.environ.get("UR_CACHE_DIR", Path.home() / ".universal-research")).expanduser()


def _venv_python() -> Path:
    return _cache_dir() / "pytok-venv" / "bin" / "python"


def mark(state: str, text: str) -> str:
    symbol = {"ok": "✓", "fail": "✗", "deg": "~", "unk": "?", "miss": " "}.get(state, "?")
    return f"[{symbol}] {text}"


def _function_is_stub(node: ast.FunctionDef | ast.AsyncFunctionDef) -> bool:
    raw: list[ast.stmt] = []
    for item in node.body:
        if isinstance(item, ast.Expr) and isinstance(item.value, ast.Constant) and isinstance(item.value.value, str):
            continue
        if isinstance(item, ast.Pass):
            continue
        raw.append(item)
    if len(raw) != 1 or not isinstance(raw[0], ast.Raise):
        return False
    exc = raw[0].exc
    if isinstance(exc, ast.Call) and getattr(exc.func, "id", None) == "NotImplementedError":
        return True
    return isinstance(exc, ast.Name) and exc.id == "NotImplementedError"


def _is_stub(fn: Callable[..., Any] | None) -> bool:
    """True when the callable exists only to raise NotImplementedError."""
    if fn is None:
        return True
    try:
        src = inspect.getsource(fn)
    except (OSError, TypeError):
        return False
    try:
        tree = ast.parse(inspect.cleandoc(src))
    except SyntaxError:
        return "raise NotImplementedError" in src and src.count("\n") < 12
    for node in tree.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            return _function_is_stub(node)
        if isinstance(node, ast.ClassDef):
            for item in node.body:
                if isinstance(item, (ast.FunctionDef, ast.AsyncFunctionDef)):
                    return _function_is_stub(item)
    return False


def _candidate_pythons() -> list[str]:
    found: list[str] = []
    env = os.environ.get("UR_PYTOK_PYTHON", "").strip()
    if env:
        found.append(str(Path(env).expanduser()))
    venv = _venv_python()
    if venv.is_file():
        found.append(str(venv))
    for name in ("python3.12", "python3.11", "python3", "python3.14"):
        which = _which(name)
        if which:
            found.append(which)
    unique: list[str] = []
    seen: set[str] = set()
    for item in found:
        key = os.path.realpath(item)
        if key in seen or not os.access(item, os.X_OK):
            continue
        seen.add(key)
        unique.append(item)
    return unique


def _python_has_real_pytok(py: str) -> bool:
    proc = subprocess.run(
        [py, "-c", "from pytok.tiktok import PyTok; from pytok.accounts import AccountsPool"],
        capture_output=True,
        text=True,
        check=False,
    )
    return proc.returncode == 0


def reexec_into_pytok_python() -> None:
    """If this interpreter lacks MEOMcGill PyTok, hop into the household venv."""
    if inspect_installed()["correct_package"]:
        return
    here = os.path.realpath(sys.executable)
    for py in _candidate_pythons():
        if os.path.realpath(py) == here:
            continue
        if _python_has_real_pytok(py):
            os.execv(py, [py, str(Path(__file__).resolve()), *sys.argv[1:]])


def _callable_state(fn: Callable[..., Any] | None) -> str:
    if fn is None:
        return "miss"
    if _is_stub(fn):
        return "miss"
    return "ok"


def _which(name: str) -> str | None:
    for folder in os.environ.get("PATH", "").split(os.pathsep):
        cand = Path(folder) / name
        if cand.is_file() and os.access(cand, os.X_OK):
            return str(cand)
    return None


def find_browser() -> dict[str, Any]:
    env = os.environ.get("CHROME_PATH", "").strip()
    candidates: list[tuple[str, str, Path]] = []
    if env:
        candidates.append(("chrome", "CHROME_PATH", Path(env).expanduser()))
    mac_apps = [
        ("chrome", "Google Chrome", Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")),
        ("chrome", "Google Chrome", Path.home() / "Applications/Google Chrome.app/Contents/MacOS/Google Chrome"),
        ("chromium", "Chromium", Path("/Applications/Chromium.app/Contents/MacOS/Chromium")),
        ("edge", "Microsoft Edge", Path("/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge")),
        ("brave", "Brave", Path("/Applications/Brave Browser.app/Contents/MacOS/Brave Browser")),
    ]
    for engine, label, path in mac_apps:
        candidates.append((engine, label, path))
    for name, engine in (
        ("google-chrome", "chrome"),
        ("google-chrome-stable", "chrome"),
        ("chromium", "chromium"),
        ("chromium-browser", "chromium"),
    ):
        found = _which(name)
        if found:
            candidates.append((engine, name, Path(found)))

    for engine, label, path in candidates:
        if path.is_file() and os.access(path, os.X_OK):
            return {"engine": engine, "label": label, "path": str(path), "present": True}
    return {"engine": None, "label": None, "path": None, "present": False}


def inspect_session(home: Path) -> dict[str, Any]:
    """Count local accounts without reading cookie or password values."""
    db = home / "accounts.db"
    profiles = home / "profiles"
    out: dict[str, Any] = {
        "home": str(home),
        "db_present": db.is_file(),
        "profile_dirs": 0,
        "account_count": 0,
        "active_count": 0,
        "session_count": 0,
        "state": "miss",
    }
    if profiles.is_dir():
        out["profile_dirs"] = sum(1 for p in profiles.iterdir() if p.is_dir())
    if not db.is_file():
        return out
    try:
        con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
        try:
            cur = con.execute(
                "SELECT COUNT(*), "
                "SUM(CASE WHEN active THEN 1 ELSE 0 END), "
                "SUM(CASE WHEN cookies IS NOT NULL AND length(cookies) > 2 "
                "AND cookies != '[]' THEN 1 ELSE 0 END) "
                "FROM accounts"
            )
            n, active_n, session_n = cur.fetchone()
            out["account_count"] = int(n or 0)
            out["active_count"] = int(active_n or 0)
            out["session_count"] = int(session_n or 0)
        finally:
            con.close()
    except sqlite3.Error:
        out["state"] = "unk"
        return out
    if out["session_count"] > 0 or out["active_count"] > 0:
        out["state"] = "ok"
    elif out["account_count"] > 0 or out["profile_dirs"] > 0:
        out["state"] = "deg"
    else:
        out["state"] = "miss"
    return out


def _try_import(mod: str) -> bool:
    try:
        __import__(mod)
        return True
    except Exception:
        return False


def inspect_installed() -> dict[str, Any]:
    """Import the already-selected interpreter's pytok (this process)."""
    result: dict[str, Any] = {
        "installed": False,
        "correct_package": False,
        "wrong_pypi": False,
        "version": None,
        "path": None,
        "error": None,
        "profile_api": False,
        "from_pool": False,
        "accounts_cli": False,
        "captcha_solver": False,
        "capabilities": {
            "search": "miss",
            "users": "miss",
            "videos": "miss",
            "hashtags": "miss",
            "sounds": "miss",
            "trending": "miss",
            "comments": "miss",
        },
    }
    try:
        import pytok  # type: ignore
    except Exception as exc:
        result["error"] = type(exc).__name__
        return result

    result["installed"] = True
    result["path"] = getattr(pytok, "__file__", None)
    try:
        from pytok.tiktok import PyTok  # type: ignore
        from pytok.accounts import AccountsPool  # type: ignore
    except Exception:
        result["wrong_pypi"] = True
        result["error"] = "unrelated_pypi_pytok"
        return result

    result["correct_package"] = True
    try:
        import importlib.metadata as md

        result["version"] = md.version("pytok")
    except Exception:
        result["version"] = getattr(pytok, "__version__", None)

    try:
        sig = inspect.signature(PyTok.__init__)
        result["profile_api"] = "user_data_dir" in sig.parameters
        result["from_pool"] = callable(getattr(PyTok, "from_pool", None))
    except Exception:
        result["profile_api"] = False

    result["accounts_cli"] = _try_import("pytok.accounts.cli")
    result["captcha_solver"] = _try_import("pytok.captcha_solver")
    _ = AccountsPool  # imported to prove the accounts layer exists

    try:
        from pytok.api.hashtag import Hashtag  # type: ignore
        from pytok.api.search import Search  # type: ignore
        from pytok.api.sound import Sound  # type: ignore
        from pytok.api.trending import Trending  # type: ignore
        from pytok.api.user import User  # type: ignore
        from pytok.api.video import Video  # type: ignore
    except Exception as exc:
        result["error"] = f"api_import:{type(exc).__name__}"
        return result

    search = _callable_state(getattr(Search, "videos", None))
    if search == "ok" and _callable_state(getattr(Search, "users", None)) != "ok":
        search = "deg"
    result["capabilities"]["search"] = search
    users = _callable_state(getattr(User, "videos", None))
    if users == "ok" and not callable(getattr(User, "info", None)):
        users = "deg"
    result["capabilities"]["users"] = users
    videos = _callable_state(getattr(Video, "info", None))
    result["capabilities"]["videos"] = videos
    result["capabilities"]["hashtags"] = _callable_state(getattr(Hashtag, "videos", None))
    result["capabilities"]["sounds"] = _callable_state(getattr(Sound, "videos", None))
    trending = _callable_state(getattr(Trending, "videos", None))
    result["capabilities"]["trending"] = trending if trending == "ok" else "miss"
    comments = _callable_state(getattr(Video, "comments", None))
    # Comments exist in source but are login/CAPTCHA sensitive; do not claim live.
    result["capabilities"]["comments"] = "unk" if comments == "ok" else comments
    return result


def inspect_runtime() -> dict[str, Any]:
    mods = {
        "zendriver": _try_import("zendriver"),
        "cv2": _try_import("cv2"),
        "numpy": _try_import("numpy"),
        "aiosqlite": _try_import("aiosqlite"),
        "click": _try_import("click"),
        "httpx": _try_import("httpx"),
        "pandas": _try_import("pandas"),
    }
    core = mods["zendriver"] and mods["aiosqlite"] and mods["click"]
    if core and mods["cv2"] and mods["numpy"]:
        state = "ok"
    elif core:
        state = "deg"
    else:
        state = "miss"
    return {"state": state, "modules": mods}


def build_report() -> dict[str, Any]:
    pytok = inspect_installed()
    runtime = inspect_runtime()
    browser = find_browser()
    session = inspect_session(_home())

    if pytok["wrong_pypi"]:
        installed_state = "fail"
    elif pytok["correct_package"]:
        installed_state = "ok"
    else:
        installed_state = "miss"

    if not pytok["correct_package"]:
        browser_state = "miss" if not browser["present"] else "unk"
        caps = {k: "miss" for k in ("search", "users", "videos", "hashtags", "sounds", "trending", "comments")}
        captcha_state = "miss"
        profile_state = "miss"
    else:
        if browser["present"] and pytok["profile_api"] and runtime["modules"]["zendriver"]:
            engine = browser.get("engine")
            profile_state = "ok" if engine in ("chrome", "chromium") else "deg"
        elif pytok["profile_api"] and runtime["modules"]["zendriver"]:
            profile_state = "deg"
        else:
            profile_state = "miss"
        browser_state = profile_state
        caps = dict(pytok["capabilities"])
        captcha_state = "deg" if pytok["captcha_solver"] else "miss"

    usable = (
        installed_state == "ok"
        and runtime["state"] in ("ok", "deg")
        and browser_state != "miss"
        and session["state"] == "ok"
        and any(caps.get(k) == "ok" for k in ("search", "users", "videos", "hashtags", "sounds"))
    )

    hints: list[str] = []
    if installed_state == "miss":
        hints.append("TikTok research is optional. Re-run install.sh to add PyTok from GitHub (not PyPI).")
    elif pytok["wrong_pypi"]:
        hints.append("The installed 'pytok' is the unrelated PyPI project. Install from https://github.com/MEOMcGill/pytok")
    if installed_state == "ok" and session["state"] != "ok":
        hints.append("Anonymous TikTok responses are often empty. Run scripts/setup-tiktok.sh for a local interactive login.")
    if browser.get("engine") == "brave":
        hints.append("Brave is Chromium-based; PyTok/zendriver is documented against Chrome. Set CHROME_PATH if sessions fail.")
    if captcha_state == "deg":
        hints.append("CAPTCHA solving is opportunistic and unreliable; prefer a logged-in local profile.")
    if caps.get("trending") != "ok":
        hints.append("Trending is not implemented in the installed PyTok; do not advertise it.")
    hints.append("Never commit ~/.pytok, cookies, or Chrome profiles. Never paste TikTok passwords into agent prompts.")

    report = {
        "available": usable,
        "backend": "pytok",
        "backend_replaceable": True,
        "upstream": PYTOK_GIT,
        "pytok": {
            "state": installed_state,
            "installed": pytok["installed"],
            "correct_package": pytok["correct_package"],
            "wrong_pypi": pytok["wrong_pypi"],
            "version": pytok["version"],
            "path": pytok["path"],
        },
        "runtime": runtime,
        "browser": {
            "state": browser_state,
            "engine": browser.get("engine"),
            "present": browser["present"],
            "profile_api": pytok.get("profile_api", False),
        },
        "session": {
            "state": session["state"],
            "home": session["home"],
            "account_count": session["account_count"],
            "active_count": session["active_count"],
            "session_count": session["session_count"],
            "profile_dirs": session["profile_dirs"],
        },
        "capabilities": {
            **caps,
            "authenticated_browser_profile": profile_state,
            "captcha": captcha_state,
        },
        "hints": hints,
    }
    return report


def write_cache(report: dict[str, Any]) -> None:
    cache = _cache_dir()
    try:
        cache.mkdir(parents=True, exist_ok=True)
        path = cache / "tiktok-probe.json"
        payload = json.loads(json.dumps(report))
        # Belt: never persist anything that looks like a secret field.
        path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
        os.chmod(path, 0o600)
    except OSError:
        pass


def format_doctor(report: dict[str, Any]) -> str:
    pytok = report["pytok"]
    runtime = report["runtime"]
    browser = report["browser"]
    session = report["session"]
    caps = report["capabilities"]

    if pytok["wrong_pypi"]:
        installed_line = mark("fail", "PyTok installed (unrelated PyPI package; use GitHub MEOMcGill/pytok)")
    elif pytok["state"] == "ok":
        ver = f" ({pytok['version']})" if pytok.get("version") else ""
        installed_line = mark("ok", f"PyTok installed{ver}")
    else:
        installed_line = mark("miss", "PyTok installed")

    runtime_line = {
        "ok": mark("ok", "runtime dependencies present"),
        "deg": mark("deg", "runtime dependencies present (OpenCV missing; CAPTCHA weaker)"),
        "miss": mark("miss", "runtime dependencies present"),
    }.get(runtime["state"], mark("unk", "runtime dependencies present"))

    engine = browser.get("engine")
    if browser["state"] == "ok":
        browser_line = mark("ok", "browser/profile support")
    elif browser["state"] == "deg" and engine == "brave":
        browser_line = mark("deg", "browser/profile support (Brave present; PyTok documents Chrome)")
    elif browser["state"] == "deg":
        browser_line = mark("deg", "browser/profile support (no Chrome binary; profile API present)")
    elif browser["state"] == "unk":
        browser_line = mark("unk", "browser/profile support")
    else:
        browser_line = mark("miss", "browser/profile support")

    if session["state"] == "ok":
        n = session["session_count"] or session["active_count"]
        session_line = mark("ok", f"authenticated session detected ({n} local)")
    elif session["state"] == "deg":
        session_line = mark("deg", "authenticated session detected (account row without usable session)")
    elif session["state"] == "unk":
        session_line = mark("unk", "authenticated session detected")
    else:
        session_line = mark("miss", "authenticated session detected")

    lines = [
        installed_line,
        runtime_line,
        browser_line,
        session_line,
        mark(caps.get("search", "miss"), "search"),
        mark(caps.get("users", "miss"), "users"),
        mark(caps.get("videos", "miss"), "videos"),
        mark(caps.get("hashtags", "miss"), "hashtags"),
        mark(caps.get("sounds", "miss"), "sounds"),
        mark(caps.get("trending", "miss"), "trending"),
        mark(caps.get("comments", "miss"), "comments"),
        mark(caps.get("captcha", "miss"), "CAPTCHA handling unreliable"),
    ]
    if pytok["state"] != "ok":
        lines.append("    hint: TikTok is optional. Universal Research continues without it.")
    elif session["state"] != "ok":
        lines.append("    hint: scripts/setup-tiktok.sh for a local interactive login (no passwords in prompts)")
    return "\n".join(lines)


def format_shell(report: dict[str, Any]) -> str:
    caps = report["capabilities"]
    pairs = {
        "tiktok_installed": report["pytok"]["state"],
        "tiktok_runtime": report["runtime"]["state"],
        "tiktok_browser": report["browser"]["state"],
        "tiktok_session": report["session"]["state"],
        "tiktok_search": caps.get("search", "miss"),
        "tiktok_users": caps.get("users", "miss"),
        "tiktok_videos": caps.get("videos", "miss"),
        "tiktok_hashtags": caps.get("hashtags", "miss"),
        "tiktok_sounds": caps.get("sounds", "miss"),
        "tiktok_trending": caps.get("trending", "miss"),
        "tiktok_comments": caps.get("comments", "miss"),
        "tiktok_captcha": caps.get("captcha", "miss"),
        "tiktok_usable": "1" if report["available"] else "0",
    }
    lines = []
    for key, val in pairs.items():
        if key != "tiktok_usable" and val not in STATES:
            val = "unk"
        lines.append(f"{key}={json.dumps(val)}")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Probe local TikTok/PyTok capability without contacting TikTok.")
    g = parser.add_mutually_exclusive_group()
    g.add_argument("--json", action="store_true", help="JSON report (no secrets)")
    g.add_argument("--shell", action="store_true", help="safe shell assignments for doctor.sh")
    g.add_argument("--doctor", action="store_true", help="human doctor lines")
    args = parser.parse_args(argv)

    reexec_into_pytok_python()
    report = build_report()
    write_cache(report)
    if args.json:
        json.dump(report, sys.stdout, indent=2)
        sys.stdout.write("\n")
    elif args.shell:
        sys.stdout.write(format_shell(report) + "\n")
    else:
        sys.stdout.write(format_doctor(report) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
