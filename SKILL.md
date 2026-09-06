---
name: universal-research
description: >
  Orchestrates evidence-based research across domains (general, market, scientific,
  academic, technical, competitive, content, visual, keyword/search). Infers the
  research type from intent, plans, gathers and evaluates sources, iterates on gaps,
  and returns the user-requested deliverable. Use when the user wants research,
  investigation, a literature review, competitive landscape, market or customer
  insight, visual pattern analysis, keyword mapping, or an evidence-backed comparison.
  Do not use for ordinary Q&A, rewriting, math, jokes, or other tasks that do not
  need external evidence gathering.
license: MIT
metadata:
  version: "1.0.0"
  short-description: Domain-general research orchestrator
  household: "private two-Mac LAN; Firecrawl at 192.168.1.80:3002"
---

# Universal Research

A research **orchestrator**, not a template. Infer what kind of research the request needs, load only the relevant lenses, gather evidence, and return whatever artifact the user asked for.

Do not impose ICP, VOC, literature-review structure, SERP analysis, competitor matrices, or visual taxonomies unless they serve this request.

## When this applies

Trigger on intent, not the word "research":

- investigate / survey / deep dive / gather evidence / find sources / find patterns
- compare alternatives using external information
- review literature, understand a market or niche, inspect competitors
- research content or visual trends, keyword/search demand
- determine what is known about a question

Do **not** trigger for ordinary Q&A, arithmetic, rewriting, jokes, generic explanations the model can answer directly, or implementation work that does not need evidence gathering.

If both this skill and a platform-fetch skill (Agent Reach, Firecrawl CLI skills) are available, **this skill plans**. Those tools acquire. They do not replace quality checks or synthesis.

## Enhanced research kit

This environment can be much stronger than generic web search. Reason in capabilities, not vendors.

```text
planning + orchestration
        │
   ┌────┼──────────────┐
   ▼    ▼              ▼
Agent  Firecrawl    authenticated
Reach  CLI          browser/session
   │    │              │
   └────┴──────┬───────┘
               ▼
     corpus → vision/analysis → synthesis → requested artifact
```

Before assuming a channel works, prefer `scripts/doctor.sh` (or its last report). If Agent Reach is missing, continue with a **degraded** kit: Firecrawl + ordinary public web. Never silently switch Firecrawl to Cloud.

| Layer | Role | Skip when |
| --- | --- | --- |
| Direct retrieval / `gh` / docs | Cheap primary sources | You already have the page |
| Firecrawl CLI | JS pages, map/crawl, clean markdown, corpora | A short fetch already answers it |
| Agent Reach | Native X/Reddit/etc. after `doctor --json` | Channel is down or irrelevant |
| Authenticated browser | Login-gated surfaces (incl. Pinterest unless a native route exists) | Public copy is enough |
| Vision model | Images/screenshots as evidence | The task is text-only |

Escalate only as far as the question requires. Do not walk the whole ladder.

Household runtime, canonical docs, and the verified Firecrawl matrix: [references/docs-index.md](references/docs-index.md).

## Intake

Infer everything you can. Ask only if a missing fact would **materially change** the plan (wrong geography, wrong time window, wrong deliverable, or primary sources required vs not).

Possible dimensions (not a questionnaire): topic, purpose/decision, breadth, depth/rigor, output shape, geography, time period, source include/exclude, time/cost, visual evidence, primary-source requirement.

If subject + purpose + depth + structure are already present, **proceed**.

## Breadth and depth are independent

| | Shallow | Deep |
| --- | --- | --- |
| Narrow | Quick scan of one question | Exhaust one question |
| Broad | Landscape map, light evidence | Wide corpus + iterated branches |

"Deep" means more rigor on the question, not more unrelated topics.

Depth defaults: `quick-scan` · `standard` · `deep-dive` · `exhaustive`. They scale source count, triangulation, iteration, and output detail.

A five-minute scan and "be exhaustive" must produce **different plans**. Self-hosted Firecrawl has no Cloud credit meter; still respect local compute, network, rate limits, model cost, and platform rules.

## Workflow

1. **Intent** — domain mix, deliverable, breadth × depth.
2. **Intake** — fill gaps only if they change the plan.
3. **Decompose** — answerable subquestions; exploratory vs confirmatory.
4. **Plan** — evidence needed, source classes, modes, tools, stop rules.
5. **Route sources/tools** — choose capabilities; do not invoke every integration.
6. **Collect** — first pass, then normalize (use `schemas/` when a corpus or JSON is useful).
7. **Gap search** — contradictions, weak support, missing branches → targeted follow-up. Non-trivial work gets at least one iteration loop scaled to depth.
8. **Analyze + quality** — domain-appropriate evidence rules.
9. **Synthesize** — patterns, not a stack of summaries. Preserve disagreement.
10. **Deliver** — the user's structure, not a canonical report template.

Load [references/research-planning.md](references/research-planning.md) before collection on anything beyond a quick scan.

## Mode routing

Modes are **lenses**. Multiple may apply. Load only what you will use.

| Load | When the request is mainly |
| --- | --- |
| [references/modes/general.md](references/modes/general.md) | No strong domain, or as a base layer |
| [references/modes/science.md](references/modes/science.md) | Empirical/scientific claims, trials, mechanisms |
| [references/modes/academic.md](references/modes/academic.md) | Literature, citation chains, schools of thought |
| [references/modes/market.md](references/modes/market.md) | Customers, demand, category, pricing, language |
| [references/modes/technical.md](references/modes/technical.md) | Systems, APIs, implementations, tradeoffs |
| [references/modes/visual.md](references/modes/visual.md) | Images, aesthetics, layout, visual patterns |
| [references/modes/competitive.md](references/modes/competitive.md) | Alternatives (products, tools, papers, methods) |
| [references/modes/content.md](references/modes/content.md) | Formats, hooks, narratives, content ecosystems |
| [references/modes/keyword.md](references/modes/keyword.md) | Queries, intent, SERPs, search demand |

Convention: every `references/modes/<id>.md` is a lens named `<id>`. Add a file to add a mode. Do not rewrite this controller.

## Source and tool routing

Load [references/source-routing.md](references/source-routing.md) when choosing where evidence should come from.

Load an integration reference **only if that capability is actually useful**:

| File | Use for |
| --- | --- |
| [references/integrations/firecrawl.md](references/integrations/firecrawl.md) | Web extraction/crawl/map against the **self-hosted** CLI |
| [references/integrations/agent-reach.md](references/integrations/agent-reach.md) | Platform routing, native X/Reddit, session-aware access |
| [references/integrations/reddit.md](references/integrations/reddit.md) | Lived experience, language, objections — not population proof |
| [references/integrations/x.md](references/integrations/x.md) | Current discourse, announcements, operator commentary |
| [references/integrations/pinterest.md](references/integrations/pinterest.md) | Visual discovery (browser-first unless doctor shows a native route) |
| [references/integrations/vision-models.md](references/integrations/vision-models.md) | Interpreting images/screenshots |

Do not treat Reddit, X, or Pinterest as scientific proof. Do not use Firecrawl Cloud. Do not dump cookies, tokens, or session secrets into context or output.

Official Firecrawl CLI skills teach **commands**. This skill decides **whether, why, and how much**.

## Quality, synthesis, output

- Claims trace to evidence. Separate observation, pattern, speculation, uncertainty, and recommendation.
- Load [references/evidence-quality.md](references/evidence-quality.md) when confidence, study design, or conflicting sources matter.
- Load [references/synthesis.md](references/synthesis.md) before the final write-up on standard+ depth.
- Load [references/output-design.md](references/output-design.md) when the deliverable shape is non-obvious. Obey an explicit user structure.
- Optional JSON: `schemas/research-brief.json`, `source.json`, `finding.json`, `report.json`. Use them to normalize a corpus, not to force machine output on every task.

## Corpus-first work

When scale helps (dozens–hundreds of pages, comments, pins, papers), write bulk output under `.research/` or `.firecrawl/` and read in batches. Dedup with `scripts/merge_sources.py` when merging source lists. Do not paste a raw crawl into context.

## Failures

Broad coverage is the goal; universal access is not. Report CAPTCHAs, paywalls, dead channels, local Firecrawl gaps, and missing auth. Do not fabricate sources or silently substitute Cloud Firecrawl.

## Safety

Never print raw cookies or auth tokens. Never copy session state into this repo. Never paste credentials into Firecrawl. Prefer Agent Reach / OpenCLI / approved browser tools for login-gated sites. Leave `~/.agent-reach/` and browser profiles untouched.
