# Agent Reach (platform access)

Agent Reach is a **selector, installer, health checker, and router**. It is not a wrapper you must call for every HTTP get. After `agent-reach doctor --json`, invoke the **upstream** tool it reports (`opencli`, `twitter`, `rdt`, `gh`, `yt-dlp`, …).

In this household it is the enhanced-access layer for authenticated and platform-native channels. Firecrawl remains the bulk web extractor.

If Agent Reach is missing, Universal Research still runs (degraded kit). Do not invent a fork. Do not install the unrelated PyPI project if upstream still warns against it — follow [docs/install.md](https://raw.githubusercontent.com/Panniantong/agent-reach/main/docs/install.md).

## When to use

- Native discovery on X, Reddit, YouTube, GitHub, etc.
- Login-gated social that anonymous scrape cannot see
- Routing "what is the current working backend for Reddit?"

## When not to use

- Official docs, papers, or a single public URL Firecrawl/fetch already handles
- Scientific proof
- Any need to scrape the user's cookie jar "because it would be easier"

## Doctor first

```bash
agent-reach doctor
agent-reach doctor --json
```

Trust `active_backend` when set. `active_backend: null` may mean doctor skipped a live cookie probe, not that the backend is absent. Only live-check a channel when this task needs it.

Prefer current commands from the installed Agent Reach skill and upstream `--help` over snippets frozen here.

## Auth and secrets

```text
PUBLIC WEB ACCESS != AUTHENTICATED PLATFORM ACCESS
```

- Reuse an existing authorized session; do not nag for login if doctor is already green.
- Never print cookies, `TWITTER_AUTH_TOKEN`, `TWITTER_CT0`, or Header String exports.
- Never copy `~/.agent-reach/config.yaml` (mode 600) into the research repo or into Firecrawl.
- twitter-cli: doctor config ≠ process env. If the twitter backend is twitter-cli, set token env in the **child process** without echoing values.
- OpenCLI: uses the user's existing Chrome session. Do not auto-login as the user.
- Installer/uninstall of Universal Research must **not** overwrite Agent Reach credentials.

Recommended human practice (upstream): dedicated research accounts for cookie-based platforms.

## Platforms (docs pass, 2026-09)

Zero-config-ish: web (Jina), YouTube, GitHub, RSS, Exa (if MCP configured), V2EX, Bilibili basic.

Needs session/cookies: X/Twitter, Reddit (no anonymous path), Facebook, Instagram, XiaoHongShu, Xueqiu, LinkedIn full.

**Pinterest is not a documented channel.** Do not assume a native route. Use [pinterest.md](pinterest.md). If a future doctor JSON shows Pinterest, use it.

**TikTok is not an Agent Reach channel.** Use [tiktok.md](tiktok.md) (PyTok when doctor is green). Do not wait for Agent Reach to grow a TikTok backend.

## X and Reddit

When doctor shows a working route:

1. Search/discover natively (preserve post/thread IDs and URLs).
2. Firecrawl the permalink only if you need cleaner full-page extraction.
3. Treat as qualitative/linguistic evidence. See [reddit.md](reddit.md) and [x.md](x.md).

## Install (only with explicit permission)

Universal Research `install.sh --with-agent-reach` may install the GitHub package. Default `agent-reach install --env=auto` is **check-only**. `--system` needs a second explicit yes (`UR_AGENT_REACH_SYSTEM=1`). Optional channels (twitter, reddit, opencli, …) are user choices, not a silent `--channels=all`.

Workspace rule from upstream: do not clone Agent Reach into the current project directory; use `~/.agent-reach/` and `/tmp/`.

## Failure

If doctor is red, say which channel is down and continue with other classes. Do not fake a thread.
