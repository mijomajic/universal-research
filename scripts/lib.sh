# Shared constants and helpers for Universal Research household V1.
# Compatible with macOS /bin/bash 3.2.

UR_FIRECRAWL_API_URL_CANON="http://192.168.1.80:3002"
UR_FIRECRAWL_SERVER_VERSION="v2.11.0"
UR_REPO_SLUG="${UR_REPO:-mijomajic/universal-research}"
UR_CACHE_DIR="${UR_CACHE_DIR:-$HOME/.universal-research}"
UR_DOCTOR_CACHE="${UR_CACHE_DIR}/doctor-cache.json"
UR_PYTOK_GIT="${UR_PYTOK_GIT:-https://github.com/MEOMcGill/pytok.git}"
UR_PYTOK_GIT_REF="${UR_PYTOK_GIT_REF:-master}"
UR_PYTOK_VENV="${UR_PYTOK_VENV:-$UR_CACHE_DIR/pytok-venv}"

ur_codex_home() {
  if [[ -n "${CODEX_HOME:-}" ]]; then
    printf '%s\n' "$CODEX_HOME"
  else
    printf '%s\n' "$HOME/.codex"
  fi
}

ur_canon_skill() {
  printf '%s\n' "$HOME/.agents/skills/universal-research"
}

ur_skill_dst() {
  printf '%s\n' "$(ur_canon_skill)"
}

# Existing agent skill directories on this Mac (absolute paths).
ur_list_skill_homes() {
  local d
  for d in \
    "$HOME/.agents/skills" \
    "$HOME/.codex/skills" \
    "$HOME/.cursor/skills" \
    "$HOME/.claude/skills" \
    "$HOME/.gemini/skills" \
    "$HOME/.openclaw/skills" \
    "$HOME/.opencode/skills" \
    "$HOME/.kiro/skills" \
    "$HOME/.trae/skills" \
    "$HOME/.continue/skills" \
    "$HOME/.codeium/windsurf/skills" \
    "$HOME/.codex-muse/skills" \
    "$HOME/.amp/skills"
  do
    if [[ -d "$d" ]]; then
      printf '%s\n' "$d"
    fi
  done
}

ur_link_skill_into_home() {
  local canon="$1"
  local home="$2"
  local dest="$home/universal-research"
  if [[ "$home" == "$(dirname "$canon")" ]]; then
    return 0
  fi
  mkdir -p "$home"
  if [[ -e "$dest" || -L "$dest" ]]; then
    rm -rf "$dest"
  fi
  ln -sfn "$canon" "$dest"
  printf '%s\n' "$dest"
}

ur_normalize_firecrawl_url() {
  local url="${1:-$UR_FIRECRAWL_API_URL_CANON}"
  url="$(printf '%s' "$url" | tr -d '[:space:]')"
  url="${url%/}"
  if [[ -z "$url" ]]; then
    url="$UR_FIRECRAWL_API_URL_CANON"
  fi
  if [[ "${UR_ALLOW_CUSTOM_ENDPOINT:-}" != "1" ]]; then
    url="$UR_FIRECRAWL_API_URL_CANON"
  fi
  printf '%s\n' "$url"
}

# Idempotent: exactly one FIRECRAWL_API_URL export in the target file.
ur_persist_firecrawl_url() {
  local file="$1"
  local url
  url="$(ur_normalize_firecrawl_url "${2:-}")"
  local dir
  dir="$(dirname "$file")"
  mkdir -p "$dir"
  touch "$file"
  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/ur-zsh.XXXXXX")"
  grep -vE '^[[:space:]]*(export[[:space:]]+)?FIRECRAWL_API_URL=' "$file" 2>/dev/null \
    | grep -vE '^[[:space:]]*# Universal Research — household Firecrawl[[:space:]]*$' \
    > "$tmp" || true
  if [[ -s "$tmp" ]]; then
    local last
    last="$(tail -c 1 "$tmp" 2>/dev/null || true)"
    if [[ -n "$last" && "$last" != $'\n' ]]; then
      printf '\n' >> "$tmp"
    fi
  fi
  printf '# Universal Research — household Firecrawl\nexport FIRECRAWL_API_URL="%s"\n' "$url" >> "$tmp"
  mv "$tmp" "$file"
}

ur_mark() {
  local state="$1"
  shift
  case "$state" in
    ok) printf '[✓] %s\n' "$*" ;;
    fail) printf '[✗] %s\n' "$*" ;;
    deg) printf '[~] %s\n' "$*" ;;
    unk) printf '[?] %s\n' "$*" ;;
    miss) printf '[ ] %s\n' "$*" ;;
    *) printf '[?] %s\n' "$*" ;;
  esac
}

ur_have() {
  command -v "$1" >/dev/null 2>&1
}

ur_pytok_home() {
  printf '%s\n' "${PYTOK_HOME:-$HOME/.pytok}"
}

ur_pytok_venv() {
  printf '%s\n' "${UR_PYTOK_VENV:-$UR_CACHE_DIR/pytok-venv}"
}

ur_python_is_310() {
  local py="$1"
  "$py" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1
}

ur_pick_cpython() {
  local c
  for c in ${UR_PYTOK_PYTHON:-} python3.12 python3.11 python3 python3.14; do
    [[ -n "$c" ]] || continue
    if ur_have "$c" && ur_python_is_310 "$c"; then
      command -v "$c"
      return 0
    fi
  done
  return 1
}

# Interpreter used to import PyTok (household venv if present).
ur_pytok_python() {
  local venv py
  venv="$(ur_pytok_venv)"
  if [[ -x "$venv/bin/python" ]]; then
    printf '%s\n' "$venv/bin/python"
    return 0
  fi
  if [[ -n "${UR_PYTOK_PYTHON:-}" && -x "${UR_PYTOK_PYTHON}" ]]; then
    printf '%s\n' "$UR_PYTOK_PYTHON"
    return 0
  fi
  if py="$(ur_pick_cpython)"; then
    printf '%s\n' "$py"
    return 0
  fi
  command -v python3
}

ur_pytok_import_ok() {
  local py
  py="$(ur_pytok_python)"
  "$py" -c "from pytok.tiktok import PyTok; from pytok.accounts import AccountsPool" >/dev/null 2>&1
}
