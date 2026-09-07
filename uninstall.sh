#!/usr/bin/env bash
# Remove the global skill copy and agent symlinks. Does not touch Firecrawl CLI,
# Agent Reach credentials, PyTok, ~/.pytok, browser sessions, or FIRECRAWL_API_URL.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$ROOT/scripts/lib.sh" ]]; then
  # shellcheck source=scripts/lib.sh
  . "$ROOT/scripts/lib.sh"
else
  ur_canon_skill() { printf '%s\n' "$HOME/.agents/skills/universal-research"; }
  ur_list_skill_homes() { printf '%s\n' "$HOME/.codex/skills"; }
fi

PURGE_ENV=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --purge-firecrawl-env) PURGE_ENV=1 ;;
    -h|--help)
      echo "Usage: uninstall.sh [--purge-firecrawl-env]"
      echo "Removes ~/.agents/skills/universal-research and agent symlinks."
      echo "--purge-firecrawl-env also strips FIRECRAWL_API_URL from ~/.zshrc and ~/.zshenv."
      echo "Never deletes ~/.agent-reach, ~/.pytok, cookies, or firecrawl-cli credentials."
      exit 0
      ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

CANON="$(ur_canon_skill)"
ur_list_skill_homes | while IFS= read -r home; do
  dest="$home/universal-research"
  [[ -e "$dest" || -L "$dest" ]] || continue
  if [[ "$home" == "$(dirname "$CANON")" ]]; then
    continue
  fi
  rm -rf "$dest"
  echo "removed $dest"
done

if [[ -e "$CANON" ]]; then
  rm -rf "$CANON"
  echo "removed $CANON"
else
  echo "not installed at $CANON"
fi

if [[ "$PURGE_ENV" -eq 1 ]]; then
  for f in "$HOME/.zshrc" "$HOME/.zshenv"; do
    [[ -f "$f" ]] || continue
    tmp="$(mktemp "${TMPDIR:-/tmp}/ur-un.XXXXXX")"
    grep -vE '^[[:space:]]*(export[[:space:]]+)?FIRECRAWL_API_URL=' "$f" \
      | grep -vE '^[[:space:]]*# Universal Research — household Firecrawl[[:space:]]*$' \
      > "$tmp" || true
    mv "$tmp" "$f"
    echo "stripped FIRECRAWL_API_URL from $f"
  done
fi

echo "Agent Reach config, PyTok, and browser sessions were not modified."
