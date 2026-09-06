#!/usr/bin/env bash
# Report the research capabilities actually available on this Mac.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=lib.sh
. "$ROOT/scripts/lib.sh"

PROBE=0
PROBE_ALL=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --probe) PROBE=1 ;;
    --probe-all) PROBE=1; PROBE_ALL=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: scripts/doctor.sh [--probe] [--probe-all]

  --probe      Cheap live checks: API root + one scrape (cached 24h unless forced)
  --probe-all  Also try map (still avoids crawl/search/interact)
EOF
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      exit 2
      ;;
  esac
  shift
done

mkdir -p "$UR_CACHE_DIR"
CODEX_HOME_RESOLVED="$(ur_codex_home)"
SKILL_DST="$(ur_skill_dst)"
ENDPOINT="$(ur_normalize_firecrawl_url "${FIRECRAWL_API_URL:-}")"
NOW_EPOCH="$(date +%s)"

ok() { ur_mark ok "$@"; }
fail() { ur_mark fail "$@"; }
deg() { ur_mark deg "$@"; }
unk() { ur_mark unk "$@"; }
miss() { ur_mark miss "$@"; }

have_codex=0
have_skill=0
have_repo=0
have_cli=0
endpoint_ok=0
server_ok=0
scrape_ok=0
skills_fc=0
map_state="unk"
ar_installed=0
ar_doctor=0
x_state="miss"
reddit_state="miss"
pinterest_state="deg"
browser_state="miss"

echo "Universal Research"
echo "─────────────────────────────────────────"

if [[ -d "$CODEX_HOME_RESOLVED" ]]; then
  ok "Codex detected ($CODEX_HOME_RESOLVED)"
  have_codex=1
else
  fail "Codex detected ($CODEX_HOME_RESOLVED missing)"
fi

if [[ -f "$SKILL_DST/SKILL.md" ]] || [[ -f "$ROOT/SKILL.md" ]]; then
  if [[ -f "$SKILL_DST/SKILL.md" ]]; then
    ok "universal-research installed ($SKILL_DST)"
  else
    deg "universal-research present in checkout but not copied to $SKILL_DST"
  fi
  have_skill=1
else
  fail "universal-research installed"
fi

if ur_have gh; then
  if gh api "repos/$UR_REPO_SLUG" --jq .full_name >/dev/null 2>&1; then
    ok "private repo/update access ($UR_REPO_SLUG)"
    have_repo=1
  else
    deg "private repo/update access (cannot read $UR_REPO_SLUG yet)"
  fi
else
  miss "private repo/update access (gh CLI missing)"
fi

echo
echo "Firecrawl"

if ur_have firecrawl; then
  fc_ver="$(firecrawl --version 2>/dev/null | head -n 1 || true)"
  ok "CLI installed ${fc_ver:+($fc_ver)}"
  have_cli=1
else
  fail "CLI installed"
fi

current_url="${FIRECRAWL_API_URL:-}"
current_url="${current_url%/}"
if [[ "$current_url" == "$UR_FIRECRAWL_API_URL_CANON" ]]; then
  ok "FIRECRAWL_API_URL=$UR_FIRECRAWL_API_URL_CANON"
  endpoint_ok=1
else
  fail "FIRECRAWL_API_URL=$UR_FIRECRAWL_API_URL_CANON (current: ${FIRECRAWL_API_URL:-unset})"
fi

http_code="$(curl -sS -m 5 -o /dev/null -w '%{http_code}' "$ENDPOINT/" 2>/dev/null || echo 000)"
if [[ "$http_code" == "200" ]]; then
  ok "local server reachable ($ENDPOINT, Firecrawl $UR_FIRECRAWL_SERVER_VERSION expected)"
  server_ok=1
else
  fail "local server reachable (HTTP $http_code from $ENDPOINT)"
  echo "    hint: Windows host 192.168.1.80, TCP 3002, no trailing slash, this Mac should be .131 or .136"
fi

read_cache() {
  python3 - "$UR_DOCTOR_CACHE" "$NOW_EPOCH" <<'PY'
import json, sys, os
path, now = sys.argv[1], int(sys.argv[2])
if not os.path.isfile(path):
    raise SystemExit(0)
try:
    data = json.load(open(path))
except Exception:
    raise SystemExit(0)
age = now - int(data.get("epoch", 0))
if age > 86400:
    raise SystemExit(0)
print(json.dumps(data))
PY
}

write_cache() {
  python3 - "$UR_DOCTOR_CACHE" "$NOW_EPOCH" "$1" "$2" <<'PY'
import json, sys
path, epoch, scrape, mapped = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
data = {"epoch": epoch, "scrape": scrape, "map": mapped}
json.dump(data, open(path, "w"))
PY
}

cache_json="$(read_cache || true)"
cached_scrape=""
cached_map=""
if [[ -n "$cache_json" ]]; then
  cached_scrape="$(python3 -c 'import json,sys; d=json.loads(sys.argv[1]); print(d.get("scrape",""))' "$cache_json")"
  cached_map="$(python3 -c 'import json,sys; d=json.loads(sys.argv[1]); print(d.get("map",""))' "$cache_json")"
fi

if [[ "$PROBE" -eq 1 && "$server_ok" -eq 1 && "$have_cli" -eq 1 ]]; then
  tmp_scrape="$(mktemp "${TMPDIR:-/tmp}/ur-scrape.XXXXXX")"
  if FIRECRAWL_API_URL="$ENDPOINT" firecrawl scrape "https://example.com" --api-url "$ENDPOINT" --only-main-content -o "$tmp_scrape" >/dev/null 2>&1 \
    && grep -q "Example Domain" "$tmp_scrape"; then
    scrape_ok=1
    ok "scrape verified"
  else
    fail "scrape verified"
  fi
  rm -f "$tmp_scrape"
  map_state="deg"
  if [[ "$PROBE_ALL" -eq 1 ]]; then
    map_out="$(FIRECRAWL_API_URL="$ENDPOINT" firecrawl map "https://example.com" --api-url "$ENDPOINT" --json 2>/dev/null || true)"
    map_n="$(python3 -c 'import json,sys
raw=sys.stdin.read()
try:
 d=json.loads(raw[raw.find("{"):] if "{" in raw else raw)
 links=(d.get("data") or d).get("links") or []
 print(len(links) if isinstance(links,list) else 0)
except Exception:
 print(0)
' <<<"$map_out")"
    if [[ "$map_n" -gt 0 ]]; then
      map_state="ok"
    else
      map_state="deg"
    fi
  fi
  write_cache "$([[ $scrape_ok -eq 1 ]] && echo ok || echo fail)" "$map_state"
elif [[ "$cached_scrape" == "ok" ]]; then
  scrape_ok=1
  ok "scrape verified (cached <24h; pass --probe to recheck)"
elif [[ "$server_ok" -eq 1 && "$have_cli" -eq 1 ]]; then
  unk "scrape verified (pass --probe)"
  scrape_ok=0
else
  fail "scrape verified"
fi

if [[ "$cached_map" == "ok" ]]; then
  map_state="ok"
elif [[ "$cached_map" == "deg" ]]; then
  map_state="deg"
fi

fc_skill=""
for cand in \
  "$CODEX_HOME_RESOLVED/skills/firecrawl/SKILL.md" \
  "$HOME/.codex/skills/firecrawl/SKILL.md" \
  "$HOME/.agents/skills/firecrawl/SKILL.md"
do
  if [[ -f "$cand" ]]; then
    fc_skill="$cand"
    break
  fi
done
if [[ -n "$fc_skill" ]]; then
  ok "official Firecrawl Codex skills present"
  skills_fc=1
else
  fail "official Firecrawl Codex skills present"
fi

case "$map_state" in
  ok) ok "map" ;;
  deg) deg "map (API accepted empty link lists in household probe; do not rely on it)" ;;
  *) unk "map" ;;
esac
ok "crawl (verified against self-hosted v2.11.0 at skill build; not re-run by doctor)"
ur_mark fail "search (household probe returned no results; never fall back to Cloud)"
unk "interact"
ur_mark fail "screenshots/images (engine unsupported in v2.11.0 probe)"

echo
echo "Agent Reach"

if ur_have agent-reach; then
  ar_installed=1
  ok "installed ($(agent-reach version 2>/dev/null | head -n 1 || echo present))"
  if agent-reach doctor --help >/dev/null 2>&1 || agent-reach doctor >/dev/null 2>&1; then
    ar_doctor=1
    ok "doctor available"
  else
    fail "doctor available"
  fi
  ar_json="$(agent-reach doctor --json 2>/dev/null || true)"
  if [[ -n "$ar_json" ]]; then
    eval "$(printf '%s\n' "$ar_json" | python3 "$ROOT/scripts/parse_agent_reach_doctor.py")"
  else
    x_state="unk"
    reddit_state="unk"
  fi
else
  miss "installed"
  miss "doctor available"
fi

case "$x_state" in
  ok) ok "X route working" ;;
  deg) deg "X route working" ;;
  unk) unk "X route working" ;;
  *) miss "X route working" ;;
esac
case "$reddit_state" in
  ok) ok "Reddit route working" ;;
  deg) deg "Reddit route working" ;;
  unk) unk "Reddit route working" ;;
  *) miss "Reddit route working" ;;
esac
if [[ "$pinterest_state" == "ok" ]]; then
  ok "Pinterest native route"
else
  deg "Pinterest native route unavailable (use authenticated browser)"
fi

echo
echo "Authenticated Browser"
if ur_have opencli; then
  ok "reusable browser sessions available (opencli)"
  browser_state="ok"
elif [[ "$ar_installed" -eq 1 ]]; then
  unk "reusable browser sessions available (install OpenCLI if desktop login-gated sites are needed)"
else
  miss "reusable browser sessions available"
fi

echo
echo "Research Kit"
if [[ "$scrape_ok" -eq 1 || "$server_ok" -eq 1 ]]; then
  ok "web extraction"
else
  fail "web extraction"
fi
if [[ "$x_state" == "ok" || "$reddit_state" == "ok" ]]; then
  ok "social/platform research"
elif [[ "$ar_installed" -eq 1 ]]; then
  deg "social/platform research (Agent Reach present; routes not green)"
else
  miss "social/platform research (Agent Reach not installed)"
fi
if [[ "$browser_state" == "ok" || "$x_state" == "ok" || "$reddit_state" == "ok" ]]; then
  ok "authenticated-session research"
else
  deg "authenticated-session research"
fi
ok "visual research (vision model = current harness; Firecrawl screenshots unavailable)"
ok "iterative deep research (method; scale with requested depth)"

echo
if [[ "$server_ok" -eq 0 ]]; then
  echo "Firecrawl server offline: skill remains usable; do not switch to Firecrawl Cloud."
fi
if [[ "$ar_installed" -eq 0 ]]; then
  echo "Agent Reach missing: degraded kit. Official install: https://raw.githubusercontent.com/Panniantong/agent-reach/main/docs/install.md"
fi
