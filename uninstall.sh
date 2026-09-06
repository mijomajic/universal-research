#!/usr/bin/env bash
# Remove the Codex skill copy. Does not touch Firecrawl CLI, Agent Reach
# credentials, browser sessions, or FIRECRAWL_API_URL (shared household infra).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$ROOT/scripts/lib.sh" ]]; then
  # shellcheck source=scripts/lib.sh
  . "$ROOT/scripts/lib.sh"
else
  UR_FIRECRAWL_API_URL_CANON="http://192.168.1.80:3002"
  ur_codex_home() {
    if [[ -n "${CODEX_HOME:-}" ]]; then
      printf '%s\n' "$CODEX_HOME"
    else
      printf '%s\n' "$HOME/.codex"
    fi
  }
  ur_skill_dst() {
    printf '%s\n' "$(ur_codex_home)/skills/universal-research"
  }
fi

PURGE_ENV=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --purge-firecrawl-env) PURGE_ENV=1 ;;
    -h|--help)
      echo "Usage: uninstall.sh [--purge-firecrawl-env]"
      echo "Default: delete ~/.codex/skills/universal-research only."
      echo "--purge-firecrawl-env also strips FIRECRAWL_API_URL from ~/.zshrc and ~/.zshenv."
      echo "Never deletes ~/.agent-reach, cookies, or firecrawl-cli credentials."
      exit 0
      ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

DST="$(ur_skill_dst)"
if [[ -e "$DST" ]]; then
  rm -rf "$DST"
  echo "removed $DST"
else
  echo "not installed at $DST"
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

echo "Agent Reach config and browser sessions were not modified."
