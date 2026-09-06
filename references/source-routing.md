# Source routing

Choose sources from the **evidence the question needs**, not from a default stack. Never invoke Reddit, X, Pinterest, Firecrawl, or Agent Reach because they exist.

## Source classes

| Class | Typical questions | Watch-outs |
| --- | --- | --- |
| Official docs / specs | How it works, guaranteed behavior | Marketing pages masquerading as docs |
| First-party company | Positioning, pricing, feature claims | Incentive to overstate |
| Primary scientific literature | Does X cause Y in population Z | Abstracts without methods |
| Systematic reviews / meta-analyses | Settled-enough empirical questions | Outdated reviews; junk-in junk-out |
| Academic databases / books | History of ideas, theory | Paywalls; citation lag |
| Government / regulatory data | Prevalence, filings, labor, safety | Definitions and vintages |
| Industry reports | Market size, category narratives | Method often opaque |
| Specialist press | Informed secondary | Repeats press releases |
| Mainstream web | Orientation, names, dates | Thin SEO pages |
| Code / GitHub / issues | Implementation truth | Abandoned repos; version drift |
| Forums / Reddit | Lived experience, language, workarounds | Selection and brigading |
| X | Announcements, live discourse | Virality and bots |
| Pinterest / image boards | Visual conventions | Reposts, no provenance |
| Product pages / reviews | Features, complaints, pricing signals | Fake reviews; survivorship |
| SERPs | Demand, intent, competitive coverage | Personalized/geo SERPs |

## Suitability rules

1. **Match class to claim type.** Causal/scientific → primary or review literature. Language/pain → communities. Behavior of software → docs and code. Aesthetics → images.
2. **Primary vs secondary.** Prefer primary when facts, APIs, or study results are at stake. Secondary is fine for orientation and for locating primaries.
3. **Freshness.** Check dates on anything that can move: prices, APIs, rankings, social mood, market shares.
4. **Authority is domain-local.** A Nature paper is not an authority on TikTok creative trends. A popular founder is not an authority on RCT methods.
5. **Independence.** Two blog posts summarizing the same press release are one source. Count independent origins, not URLs.
6. **Bias and incentives.** Note who pays, who ranks, who is selling.
7. **Triangulation.** For non-trivial claims, seek at least two independent classes or two independent primaries.
8. **Diversity without redundancy.** After the second similar SEO roundup, stop and go primary or go elsewhere.
9. **Social when language or experience matters.** Customer wording, objections, workarounds, niche practice.
10. **Primary when the claim is factual or scientific.** Social may illustrate, not prove.

## Tool mapping (capabilities)

| Need | Prefer | Avoid |
| --- | --- | --- |
| Known URL, static or JS page | Firecrawl `scrape` (self-hosted) or a short fetch | Crawling the whole site |
| Many URLs on one domain | `map` if doctor shows it works; else docs index / crawl with a tight limit | Unbounded crawl |
| Section-scale corpus | Firecrawl `crawl` with `--limit` / path filters | Cloud Firecrawl |
| Platform-native search (X, Reddit, …) | Agent Reach after `doctor --json` | Anonymous scrape of login walls |
| Login-gated visual discovery | Authenticated browser (Pinterest default) | Assuming Agent Reach has Pinterest |
| Image meaning | Vision model on saved files | Guessing from filenames |
| Official GitHub | `gh` | Scraping the HTML UI |
| Scientific papers | Publisher pages, reviews, paper indexes **that this runtime actually has** | Treating Reddit as the literature |

If a capability is down, fall back to the next **local** layer and say so. Never fail over to `api.firecrawl.dev`.

## Sequence (skippable)

```text
simple discovery → direct page → Firecrawl scrape → map/crawl
    → Agent Reach native route → authenticated browser → vision
```

Skip to the layer that matches the evidence need.
