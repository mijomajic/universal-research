#!/usr/bin/env bash
# Household installer: Codex skill + self-hosted Firecrawl endpoint + optional Agent Reach.
set -euo pipefail

UR_REPO_SLUG="${UR_REPO:-mijomajic/universal-research}"
UR_FIRECRAWL_API_URL_CANON="http://192.168.1.80:3002"
WITH_AGENT_REACH=0
SKIP_FC_SKILLS=0
SKIP_PROBE=0
YES=0
FROM_TREE=""

usage() {
  cat <<EOF
Usage: install.sh [options]

  --yes                  Unattended (needed for npm CLI install if firecrawl is missing)
  --with-agent-reach     Install Agent Reach from GitHub if missing (check-only unless
                         UR_AGENT_REACH_SYSTEM=1)
  --skip-firecrawl-skills
  --skip-probe
  --from-tree DIR        Install from an already unpacked checkout

Canonical skill: ~/.agents/skills/universal-research
Symlinked into every detected agent skills dir (Cursor, Codex, Claude, Gemini, …).

Environment:
  CODEX_HOME             Default: ~/.codex
  UR_REPO                Default: $UR_REPO_SLUG
  UR_INSTALL_AGENT_REACH=1
  UR_AGENT_REACH_SYSTEM=1   Pass --system to agent-reach install (explicit)
  UR_INSTALL_FIRECRAWL=1    Allow npm install -g firecrawl-cli
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) YES=1 ;;
    --with-agent-reach) WITH_AGENT_REACH=1 ;;
    --skip-firecrawl-skills) SKIP_FC_SKILLS=1 ;;
    --skip-probe) SKIP_PROBE=1 ;;
    --from-tree) FROM_TREE="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

if [[ "${UR_INSTALL_AGENT_REACH:-}" == "1" ]]; then
  WITH_AGENT_REACH=1
fi

echo "==> preflight"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer targets the household Macs (macOS)." >&2
  exit 1
fi

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$CODEX_HOME/skills"
mkdir -p "$HOME/.agents/skills"
if [[ -d "$HOME/.opencode" && ! -d "$HOME/.opencode/skills" ]]; then
  mkdir -p "$HOME/.opencode/skills"
fi

find_local_root() {
  local src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" && -f "$src" ]]; then
    local dir
    dir="$(cd "$(dirname "$src")" && pwd)"
    if [[ -f "$dir/SKILL.md" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
  fi
  return 1
}

TREE=""
if [[ -n "$FROM_TREE" ]]; then
  TREE="$FROM_TREE"
elif TREE="$(find_local_root)"; then
  :
else
  echo "==> fetching private repo $UR_REPO_SLUG"
  if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) is required to install from the private repo." >&2
    exit 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    echo "gh is not authenticated. Run: gh auth login" >&2
    exit 1
  fi
  if ! gh api "repos/$UR_REPO_SLUG" --jq .full_name >/dev/null 2>&1; then
    echo "Cannot read $UR_REPO_SLUG. Check private-repo access before installing." >&2
    exit 1
  fi
  TREE="$(mktemp -d "${TMPDIR:-/tmp}/ur-src.XXXXXX")"
  gh repo clone "$UR_REPO_SLUG" "$TREE" -- --depth 1
fi

if [[ ! -f "$TREE/SKILL.md" ]]; then
  echo "SKILL.md missing in $TREE" >&2
  exit 1
fi

# shellcheck source=scripts/lib.sh
. "$TREE/scripts/lib.sh"
ENDPOINT="$(ur_normalize_firecrawl_url)"
SKILL_DST="$(ur_canon_skill)"

echo "==> installing skill → $SKILL_DST"
mkdir -p "$SKILL_DST"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete \
    --exclude '.git/' \
    --exclude '.research/' \
    --exclude '.firecrawl/' \
    --exclude '__pycache__/' \
    --exclude '.DS_Store' \
    "$TREE/" "$SKILL_DST/"
else
  rm -rf "$SKILL_DST"
  mkdir -p "$SKILL_DST"
  cp -R "$TREE/." "$SKILL_DST/"
  rm -rf "$SKILL_DST/.git"
fi
chmod +x "$SKILL_DST/install.sh" "$SKILL_DST/uninstall.sh" "$SKILL_DST/scripts/"*.sh "$SKILL_DST/scripts/"*.py 2>/dev/null || true

echo "==> linking into agent skill directories"
ur_list_skill_homes | while IFS= read -r home; do
  linked="$(ur_link_skill_into_home "$SKILL_DST" "$home" || true)"
  if [[ -n "${linked:-}" ]]; then
    echo "  $linked"
  fi
done
# Codex always gets a link even if CODEX_HOME was empty before
mkdir -p "$CODEX_HOME/skills"
ur_link_skill_into_home "$SKILL_DST" "$CODEX_HOME/skills" >/dev/null || true

echo "==> persisting FIRECRAWL_API_URL=$ENDPOINT"
ur_persist_firecrawl_url "$HOME/.zshrc" "$ENDPOINT"
ur_persist_firecrawl_url "$HOME/.zshenv" "$ENDPOINT"
export FIRECRAWL_API_URL="$ENDPOINT"

echo "==> Firecrawl CLI"
if ! command -v firecrawl >/dev/null 2>&1; then
  if [[ "$YES" -eq 1 || "${UR_INSTALL_FIRECRAWL:-}" == "1" ]]; then
    echo "installing firecrawl-cli globally via npm"
    npm install -g firecrawl-cli
  else
    echo "firecrawl CLI missing. Re-run with --yes to npm install -g firecrawl-cli" >&2
    echo "or: npm install -g firecrawl-cli" >&2
    exit 1
  fi
else
  echo "reusing $(command -v firecrawl) $(firecrawl --version 2>/dev/null | head -n 1 || true)"
fi

# Do not run `firecrawl login` / `--browser`. Custom API URL skips Cloud auth.
# Do not rewrite CLI credentials.json.

if [[ "$SKIP_FC_SKILLS" -eq 0 ]]; then
  echo "==> official Firecrawl Codex skills (no browser login)"
  if firecrawl setup core --help >/dev/null 2>&1; then
    if ! firecrawl setup core -g -y; then
      echo "warning: firecrawl setup core failed; doctor will flag missing skills" >&2
    fi
  else
    echo "warning: this firecrawl CLI has no 'setup core'; install skills manually" >&2
  fi
fi

if [[ "$SKIP_PROBE" -eq 0 ]]; then
  echo "==> probing $ENDPOINT"
  code="$(curl -sS -m 5 -o /dev/null -w '%{http_code}' "$ENDPOINT/" || echo 000)"
  if [[ "$code" != "200" ]]; then
    echo "warning: Firecrawl HTTP $code — skill installed anyway; doctor will explain repair" >&2
  else
    tmp="$(mktemp "${TMPDIR:-/tmp}/ur-probe.XXXXXX")"
    if FIRECRAWL_API_URL="$ENDPOINT" firecrawl scrape "https://example.com" --api-url "$ENDPOINT" --only-main-content -o "$tmp" \
      && grep -q "Example Domain" "$tmp"; then
      echo "scrape: success"
    else
      echo "warning: scrape probe failed; not falling back to Firecrawl Cloud" >&2
    fi
    rm -f "$tmp"
  fi
fi

echo "==> Agent Reach"
if command -v agent-reach >/dev/null 2>&1; then
  echo "present; leaving ~/.agent-reach untouched"
  agent-reach doctor || true
elif [[ "$WITH_AGENT_REACH" -eq 1 ]]; then
  echo "installing Agent Reach from GitHub (not PyPI)"
  if command -v pipx >/dev/null 2>&1; then
    pipx install "https://github.com/Panniantong/agent-reach/archive/main.zip"
  else
    python3 -m venv "$HOME/.agent-reach-venv"
    # shellcheck disable=SC1091
    . "$HOME/.agent-reach-venv/bin/activate"
    pip install "https://github.com/Panniantong/agent-reach/archive/main.zip"
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HOME/.agent-reach-venv/bin/agent-reach" "$HOME/.local/bin/agent-reach"
    deactivate || true
  fi
  if [[ "${UR_AGENT_REACH_SYSTEM:-}" == "1" ]]; then
    agent-reach install --env=auto --system
  else
    agent-reach install --env=auto || true
  fi
  agent-reach doctor || true
else
  echo "not installed (pass --with-agent-reach to install). Kit is degraded without it."
fi

echo "==> Universal Research doctor"
if [[ "$SKIP_PROBE" -eq 1 ]]; then
  bash "$SKILL_DST/scripts/doctor.sh" || true
else
  bash "$SKILL_DST/scripts/doctor.sh" --probe || true
fi

echo
echo "Installed: $SKILL_DST"
echo "Endpoint:  $FIRECRAWL_API_URL"
echo "Open a new terminal or: export FIRECRAWL_API_URL=\"$ENDPOINT\""
echo "Never use Firecrawl Cloud for this household path."
