# Firecrawl (web acquisition)

Firecrawl is a **web extraction/crawling capability**, not the research method. Universal Research decides whether a page corpus is needed; official Firecrawl CLI skills teach the flags.

Household V1 uses a **self-hosted** server only.

```text
API:    http://192.168.1.80:3002
        (exactly that; no trailing slash)
Server: v2.11.0 Docker on 192.168.1.80
CLI:    `firecrawl` (tested: firecrawl-cli 1.23.3)
Auth:   none. Do not send FIRECRAWL_API_KEY. Do not use api.firecrawl.dev.
```

Custom `FIRECRAWL_API_URL` makes the official CLI skip Cloud API-key auth. If a leftover Cloud key exists in the environment or `credentials.json`, **ignore it** for research traffic.

## When to use

- JS-rendered or messy HTML that a raw fetch will not clean
- Main-content markdown, links, metadata
- Tight `crawl` of a docs section or competitor set
- `map` **if** doctor shows it returning URLs (see matrix)
- Image URL extraction **if** verified

Prefer a simple fetch/`gh`/official API when that already yields the primary source.

## When not to use

- The answer is in a paper, repo, or Agent Reach native object you already have
- Search/screenshot/interact when doctor marks them down
- Any workflow that would "just use Cloud this once"
- Pasting cookies or passwords into scrape actions

## How to invoke

Always pass the household endpoint if the process env might lack it:

```bash
export FIRECRAWL_API_URL="http://192.168.1.80:3002"
firecrawl scrape "https://example.com" --only-main-content -o .research/page.md
firecrawl crawl "https://docs.example.com/x" --limit 25 --max-depth 2 --wait -o .research/crawl.json
```

Write bulky output to `.firecrawl/` or `.research/`. Read incrementally.

Delegate command details to the installed official skill (`firecrawl` / `firecrawl-scrape` / `firecrawl-crawl`, etc.). If those skills talk about `firecrawl login`, credits, or `api.firecrawl.dev`, **override**: this household does not use them.

Install/refresh Codex CLI skills (installer does this; no browser login):

```bash
firecrawl setup core --agent codex -g -y
```

That command currently installs the official catalog (scrape/search/crawl/map/interact/agent/monitor/parse/download/research-index/developer-index). **Hosted indexes and Cloud-only verbs still must not be aimed at this LAN API.** Prefer scrape/crawl (and map only if it returns links).

## Capability matrix (probed 2026-09-07)

Probes used CLI 1.23.3 against `http://192.168.1.80:3002` (v2.11.0). Re-run `scripts/doctor.sh --probe` after server upgrades.

| Family | Status | Evidence |
| --- | --- | --- |
| scrape (markdown) | **available** | `success: true` on example.com; clean markdown |
| crawl | **available** | `--limit 1 --wait` completed with markdown |
| map | **degraded** | API `success: true` but `links: []` on example.com and docs.python.org |
| search | **unavailable** | CLI returned "No results found"; self-host `/search` needs Google/SearXNG |
| screenshot | **unavailable** | warning: engine does not support screenshot |
| interact | **unverified** | Needs live session + often hosted/AI pieces; do not assume |
| images format | **unverified** | Not probed; try once on a real visual task and cache the result |
| parse (local files) | **unverified** | CLI talks to `/v2/parse`; probe before depending |
| `research` / `developer` indexes | **hosted-only** | Do not call against this API |
| monitor / agent extract | **do not assume** | Credits, Fire-engine, or `OPENAI_API_KEY` on server |

Self-host docs (v2.11.0): no Fire-engine (weaker vs bot walls); API keys optional; `USE_DB_AUTHENTICATION=false`.

## Failure behavior

If the LAN server is unreachable: report it, continue with Agent Reach / `gh` / direct retrieval / browser. **Never** rewrite `FIRECRAWL_API_URL` to Cloud.

Repair hint: confirm the Windows host is up, Mac is 192.168.1.131 or .136, firewall allows TCP 3002, URL has no trailing slash, then `curl -sS -m 5 http://192.168.1.80:3002/` expecting `Firecrawl API`.
