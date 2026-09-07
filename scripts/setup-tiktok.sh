#!/usr/bin/env bash
# Local interactive TikTok login for Universal Research.
# Session state stays in $PYTOK_HOME (default ~/.pytok) on this Mac.
# Never prints cookies/tokens. Never asks for a password in this prompt.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
. "$ROOT/scripts/lib.sh"

FORCE=0
STATUS=0
IDENTIFIER=""

usage() {
  cat <<EOF
Usage: scripts/setup-tiktok.sh [--status] [--force] [--id IDENTIFIER]

  --status       Report local TikTok capability and exit (no browser)
  --force        Open a login window even if a session already exists
  --id NAME      Local pool identifier (email / phone / username). Not a password.

Opens PyTok's manual browser login so you sign in on tiktok.com yourself.
Credentials stay in the browser; cookies stay in ~/.pytok (or \$PYTOK_HOME).
Do not commit that directory. Do not paste TikTok passwords into agent prompts.

Anonymous TikTok collection is often empty; login is recommended but not required
for Universal Research as a whole.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status) STATUS=1 ;;
    --force) FORCE=1 ;;
    --id) IDENTIFIER="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

PY="$(ur_pytok_python)"
HOME_DIR="$(ur_pytok_home)"

if [[ "$STATUS" -eq 1 ]]; then
  echo "TikTok setup status"
  echo "  python: $PY"
  echo "  PYTOK_HOME: $HOME_DIR"
  "$PY" "$ROOT/scripts/probe_tiktok.py" --doctor
  exit 0
fi

if ! "$PY" -c "from pytok.tiktok import PyTok; from pytok.accounts import AccountsPool" >/dev/null 2>&1; then
  echo "PyTok is not installed in $PY" >&2
  echo "Re-run ./install.sh so it can install PyTok from GitHub (not PyPI)." >&2
  echo "Universal Research still works without TikTok." >&2
  exit 1
fi

session_state="$("$PY" "$ROOT/scripts/probe_tiktok.py" --json | python3 -c 'import json,sys; print(json.load(sys.stdin).get("session",{}).get("state",""))')"
if [[ "$session_state" == "ok" && "$FORCE" -eq 0 ]]; then
  echo "A local TikTok session already exists under $HOME_DIR."
  echo "Leaving it untouched. Pass --force to open a new interactive login."
  "$PY" "$ROOT/scripts/probe_tiktok.py" --doctor
  exit 0
fi

if [[ ! -t 0 || ! -t 1 ]]; then
  echo "This setup needs a real desktop and an interactive terminal." >&2
  echo "Run: $ROOT/scripts/setup-tiktok.sh" >&2
  exit 2
fi

if [[ -z "$IDENTIFIER" ]]; then
  echo "A browser window will open. Log into TikTok there (email/SMS/CAPTCHA as TikTok asks)."
  echo "This script will not ask for your password."
  printf "Local account label (email / phone / TikTok username): "
  read -r IDENTIFIER
fi
IDENTIFIER="$(printf '%s' "$IDENTIFIER" | tr -d '[:space:]')"
if [[ -z "$IDENTIFIER" ]]; then
  echo "No identifier given; aborting. TikTok remains optional." >&2
  exit 1
fi

mkdir -p "$HOME_DIR"
chmod 700 "$HOME_DIR" 2>/dev/null || true

echo "Registering local pool entry (no password stored by this script)…"
if ! "$PY" -m pytok.accounts.cli add --username "$IDENTIFIER" >/dev/null 2>&1; then
  # Already present is fine; login still refreshes the session.
  true
fi

echo "Opening a visible Chrome/Chromium window. Sign in yourself; this waits for the session."
echo "Cookies stay in $HOME_DIR and are never printed."
if ! "$PY" -m pytok.accounts.cli login --username "$IDENTIFIER" --manual-login; then
  echo "Login did not complete. Universal Research still works; TikTok stays degraded." >&2
  echo "You can retry later: $ROOT/scripts/setup-tiktok.sh --force" >&2
  exit 1
fi

echo
echo "Local session stored under $HOME_DIR (this Mac only; not git)."
"$PY" "$ROOT/scripts/probe_tiktok.py" --doctor
