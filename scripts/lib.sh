# Shared constants and helpers for Universal Research household V1.
# Compatible with macOS /bin/bash 3.2.

UR_FIRECRAWL_API_URL_CANON="http://192.168.1.80:3002"
UR_FIRECRAWL_SERVER_VERSION="v2.11.0"
UR_REPO_SLUG="${UR_REPO:-mijomajic/universal-research}"
UR_CACHE_DIR="${UR_CACHE_DIR:-$HOME/.universal-research}"
UR_DOCTOR_CACHE="${UR_CACHE_DIR}/doctor-cache.json"

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
