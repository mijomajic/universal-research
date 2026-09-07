# TikTok

Useful **platform-native** source for short-form content: hooks, captions, creators, hashtags, sounds, posting formats, engagement patterns, recurring themes, audience language in comments where available, visual/video references, trend research, and product or content discovery on TikTok itself.

Not by default: scientific proof, population rates, or "what people think." Algorithmic ranking and virality are distortions.

PyTok is the **preferred acquisition backend when healthy**. It sits behind this integration so it can be replaced later. Universal Research does not require TikTok, and a PyTok failure must not stop other research.

```text
PyTok / authenticated TikTok
        ↓
platform-native discovery/acquisition
        ↓
local corpus / URLs / metadata / media
        ↓
vision + text analysis
        ↓
Universal Research synthesis
```

Keep those layers separate. Do not treat a caption scrape as visual analysis, or a like count as evidence quality.

## Access (household)

1. `scripts/doctor.sh` (TikTok section) or `scripts/probe_tiktok.py --json` — trust that report, not memory.
2. If PyTok is installed and the needed capability is green, use the household interpreter (`~/.universal-research/pytok-venv` when the installer created it).
3. Reuse a **local** logged-in session under `~/.pytok` (override with `$PYTOK_HOME`). Upstream's own docs: anonymous TikTok responses are often empty; a one-time interactive login on this Mac is the supported path.
4. If login is missing and the task actually needs native TikTok: `scripts/setup-tiktok.sh`. That opens a normal browser login. Do not paste TikTok passwords into prompts. Do not scrape the user's cookie jar by hand.
5. Firecrawl a public TikTok URL only if native acquisition already found it and you need a page fallback — and only if doctor says scrape works. It is not a TikTok API.

Install PyTok from GitHub, **not PyPI** (the `pytok` name on PyPI is a different project):

https://github.com/MEOMcGill/pytok

(`networkdynamics/pytok` redirects to that repo.)

Do not copy the PyTok API into this skill. Prefer current upstream README and the installed package's call shapes; they change.

## When to use

- The object of study is TikTok itself (hooks, sounds, creators, hashtags, in-app trends).
- Short-form visual/content conventions that other platforms will not show.
- Audience wording in comments, stitches, duets — as **qualitative** language, not N.
- Product/packaging/lifestyle discovery where TikTok is a discovery surface (often alongside Pinterest, Reddit, X, and the open web).

## When not to use

- Causal, clinical, or population claims ("does creatine improve cognition") unless the user explicitly wants TikTok discourse as a separate, labeled stream
- Treating views/likes/shares as demand, quality, or prevalence
- Any plan that would make TikTok a mandatory step of Universal Research
- Advertising a capability doctor marks missing (notably **trending**, which current PyTok stubs)

## Limitations

- Algorithmic and virality bias; what ranks is not a sample of users
- Unverifiable claims in captions and comments
- Scraping is unstable; platform changes break tooling
- Authentication is often required; CAPTCHAs and anti-bot measures are common
- Upstream CAPTCHA solving is opportunistic and **unreliable**
- Engagement ≠ evidence quality
- Comments may be missing, gated, or stubbed at runtime — doctor reports `[?]` until live-verified
- Never use TikTok as scientific proof or as population-representative evidence by default

## Auth and secrets

```text
PUBLIC WEB ACCESS != AUTHENTICATED TIKTOK ACCESS
```

- Session state is **local to this Mac**: `~/.pytok/accounts.db`, `~/.pytok/profiles/`. Mode 700 on the home dir when setup can set it.
- Never commit cookies, profiles, `accounts.db`, or `$PYTOK_HOME`.
- Never print raw cookies, tokens, or passwords. Doctor only reports that a session exists, not its contents.
- Never ask the user to paste a TikTok password into an agent prompt. `setup-tiktok.sh` uses PyTok `--manual-login` so they type into the browser.
- Universal Research install/uninstall must **not** overwrite or copy `~/.pytok`.
- Do not sync auth through Git or between household Macs.

## How to read it

- Separate official brand accounts from remixes, stitches, and comment lore.
- Repeat patterns across **independent** creators/sounds beat one viral hit.
- Timestamp everything; sounds and formats move weekly.
- Quote captions/comments as language evidence; they are not N.
- If you study the video, actually look at frames/clips with a vision model. Titles and hashtags are not the visual.

Pair with first-party pages, app-store text, or papers when the claim leaves the platform. Pair **never** as a substitute for literature in science mode.

## Failure

If doctor is red or PyTok throws: say TikTok is unavailable/degraded, fall back to YouTube, the open web, Reddit, X, Pinterest/browser, Firecrawl — whatever the **question** needs — and continue. Do not fake a For You feed. Do not switch research to a random other social network "because it is similar" without saying so.
