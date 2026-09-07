# Canonical documentation index

Refresh tool knowledge from these links rather than from memory. Hosted-only features in vendor docs **do not** apply to the household Firecrawl unless doctor has verified them locally.

## Household runtime

```text
Firecrawl API:  http://192.168.1.80:3002
(no trailing slash)

Server:         Firecrawl v2.11.0 self-hosted (Docker, Windows PC 192.168.1.80)
Clients:        Mac A 192.168.1.131 · Mac B 192.168.1.136
Auth:           none (trusted LAN). No Firecrawl Cloud account, key, or credits.
CLI tested:     firecrawl-cli 1.23.3 against that server (2026-09-07)
```

Never point research traffic at `api.firecrawl.dev` as a fallback.

Capability matrix from that probe: [integrations/firecrawl.md](integrations/firecrawl.md).

Re-check the live machine with `scripts/doctor.sh`.

## Universal Research / Codex skills

- Codex: https://github.com/openai/codex
- OpenAI skills catalog: https://github.com/openai/skills
- Codex skill-creator sample: https://github.com/openai/codex/blob/main/codex-rs/skills/src/assets/samples/skill-creator/SKILL.md
- Agent Skills spec: https://agentskills.io/specification

## Firecrawl

- Main repo: https://github.com/firecrawl/firecrawl
- Self-hosting (pinned tree): https://github.com/firecrawl/firecrawl/blob/v2.11.0/SELF_HOST.md
- CLI repo: https://github.com/firecrawl/cli
- CLI docs: https://docs.firecrawl.dev/sdks/cli
- Official agent skills: https://github.com/firecrawl/skills
- CLI core skill (current CLI tree; path may move): https://github.com/firecrawl/cli
- Install official Codex CLI skills: `firecrawl setup core --agent codex -g -y`  
  Do **not** pass `--browser`. Do not run Cloud login. Do not install hosted MCP as a requirement.

Self-host notes from v2.11.0 docs: `USE_DB_AUTHENTICATION=false`; API keys optional; no Fire-engine (harder anti-bot); `/search` needs Google or SearXNG on the server; screenshot/interact/AI extract need engine or model support that this LAN deploy may lack.

## Agent Reach

- Repo: https://github.com/Panniantong/agent-reach (canonical: https://github.com/Panniantong/Agent-Reach)
- Install: https://raw.githubusercontent.com/Panniantong/agent-reach/main/docs/install.md
- Update: https://raw.githubusercontent.com/Panniantong/agent-reach/main/docs/update.md
- Bundled skill: https://github.com/Panniantong/Agent-Reach/blob/main/agent_reach/skill/SKILL.md
- English README: https://github.com/Panniantong/Agent-Reach/blob/main/docs/README_en.md

Do **not** `pip install agent-reach` from PyPI if upstream still warns that the PyPI name is a different project. Install from the GitHub archive / pipx as in the install guide.

Cookies/tokens live in `~/.agent-reach/` (typically `config.yaml`, mode 600). Do not copy them here.

Pinterest is **not** in the current Agent Reach channel list. Treat it as browser-first until `agent-reach doctor --json` shows a Pinterest backend.

## TikTok / PyTok

Preferred **optional** backend for short-form native acquisition. Replaceable; not part of the core methodology.

- Canonical repo: https://github.com/MEOMcGill/pytok  
  (`https://github.com/networkdynamics/pytok` redirects here)
- README / install: https://github.com/MEOMcGill/pytok/blob/master/README.md
- Recommended install (upstream): `pip install git+https://github.com/MEOMcGill/pytok.git@master`  
  **Do not** `pip install pytok` from PyPI — that name is a different project.
- Examples: https://github.com/MEOMcGill/pytok/tree/master/examples
- Issues: https://github.com/MEOMcGill/pytok/issues

Household install puts the package in `~/.universal-research/pytok-venv` when missing. Session state is **local**: `~/.pytok` (or `$PYTOK_HOME`) — accounts SQLite, cookie backups, Chrome profiles. Never commit it. Never print cookies. Interactive login: `scripts/setup-tiktok.sh`.

Trust `scripts/doctor.sh` / `scripts/probe_tiktok.py` for what this Mac can do. Upstream documents authenticated-pool use; anonymous TikTok responses are often empty. CAPTCHA solving is unreliable. **Trending** is a stub in current PyTok (`NotImplementedError`) — do not advertise it.

## When docs disagree with doctor

Trust **runtime doctor output** for what this machine can do. Trust upstream docs for how to invoke a tool that doctor says is up. When a platform route changes, prefer current Agent Reach / Firecrawl docs over frozen command snippets in this skill.
