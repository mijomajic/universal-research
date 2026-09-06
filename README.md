# Universal Research

Private household skill: a **domain-general research orchestrator** for two Macs on the LAN. It is not a public product, not a market-research template, and not a Firecrawl Cloud wrapper.

It infers what kind of research a request needs, loads only the relevant lenses, gathers evidence, iterates on gaps, and returns the artifact the user asked for.

## Household runtime

```text
Mac A     192.168.1.131
Mac B     192.168.1.136
Firecrawl 192.168.1.80:3002   v2.11.0 self-hosted Docker
          FIRECRAWL_API_URL=http://192.168.1.80:3002
          no trailing slash, no Cloud key, no Cloud credits
```

Windows firewall should allow only those two Macs on TCP 3002.

## One-command Codex install

`gh` must already be authenticated to this private repo.

```bash
gh api \
  -H "Accept: application/vnd.github.raw+json" \
  repos/mijomajic/universal-research/contents/install.sh | bash
```

From a checkout:

```bash
./install.sh --yes
./install.sh --yes --with-agent-reach   # only if you want Agent Reach installed
```

Installs the skill into `~/.agents/skills/universal-research` and **symlinks it into every detected agent** (Cursor, Codex, Claude, Gemini, OpenClaw, Windsurf, Continue, Trae, Kiro, …). Also persists the Firecrawl endpoint in `~/.zshrc` and `~/.zshenv`, reuses an existing Firecrawl CLI, installs official Firecrawl skills with `firecrawl setup core -g -y` (no `--browser`), and probes the LAN server.

It will **not** create a Firecrawl Cloud account, consume Cloud credits, overwrite `~/.agent-reach/`, or copy cookies.

## Doctor

```bash
~/.agents/skills/universal-research/scripts/doctor.sh --probe
```

Reports Codex, skill install, repo access, Firecrawl CLI/endpoint/server/scrape, official Firecrawl skills, Agent Reach routes, and derived kit status. Expensive probes are cached ~24h.

If Firecrawl is offline the skill still installs; doctor says so; research continues on remaining sources. There is no Cloud fallback.

## What the agent should do

`SKILL.md` is the controller. References load on demand:

- `references/modes/` — lenses (science, market, visual, …). Add `legal.md` later without rewriting the core.
- `references/integrations/` — Firecrawl, Agent Reach, Reddit, X, Pinterest, vision.
- `schemas/` — optional JSON for briefs/sources/findings/reports.
- `scripts/merge_sources.py` — URL canonicalization and corpus merge.

Official Firecrawl CLI skills teach commands. This skill decides whether, why, and how wide/deep to collect.

## Uninstall

```bash
~/.agents/skills/universal-research/uninstall.sh
```

Leaves Firecrawl CLI, the LAN endpoint export, Agent Reach, and browser sessions alone. `--purge-firecrawl-env` is opt-in.

## Collaborator

Grant the roommate GitHub account read access on this private repo (`gh repo add-collaborator`). Installer does not guess that username.

## Safety

Do not commit `~/.agent-reach/config.yaml`, browser profiles, tokens, or `.env` secrets. The LAN Firecrawl URL is not a credential and may live in the repo.

## Evals

```bash
python3 scripts/run_evals.py
python3 scripts/validate.py
```
