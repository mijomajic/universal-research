# Technical research mode

Engineering and implementation research. Prefer primary technical sources.

## What this mode is for

Official docs, source, specifications, repositories, issue trackers, benchmarks, architecture comparisons, tradeoffs, dependencies, security implications, operational complexity, performance, ecosystem maturity, version sensitivity, reproducibility.

## Method

1. **Pin versions** — language, library, protocol, and date. "Best" without a version is often wrong in six months.
2. **Primary first** — current docs, REAMEs that match the tag, source, RFCs/specs, `gh` for issues/PRs.
3. **Architecture options** — enumerate 2–5 real approaches people use, not a fantasy taxonomy.
4. **Tradeoffs** — consistency, latency, ops burden, failure modes, lock-in, complexity. Use a matrix if comparing.
5. **Evidence for performance/security** — reproducible numbers, threat model, or an honest "unbenchmarked."
6. **Ecosystem** — maintenance, community, compatibility, who runs it in production.
7. **Reproduce mentally** — could a competent engineer follow this on Monday?

## Sources

Docs sites, GitHub/GitLab, package registries, status pages, CVEs, engineering blogs **checked against code**. Firecrawl for JS-rendered doc sites. Agent Reach/GitHub via `gh`. Skip Reddit as proof of correctness; it is useful for "this footgun exists."

Do not use Firecrawl Cloud `developer` / hosted indexes unless doctor says that endpoint is the local one (household v2.11.0: treat hosted indexes as unavailable).

## Pitfalls

- Comparing last year's API to this year's.
- Vendor benchmarks with no hardware/version.
- Security advice copied from tweets.
