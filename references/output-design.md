# Output design

The user owns the shape. If they named a format, use it. If they named a purpose ("I need to decide X"), pick the smallest artifact that serves that purpose.

## Default picker

| Purpose | Useful default |
| --- | --- |
| Fast orientation | Concise brief (half page to two pages) |
| Decision with tradeoffs | Memo: criteria, options, evidence, recommendation, uncertainties |
| What exists in a space | Landscape or taxonomy |
| Compare N named things | Table or matrix |
| Academic question | Literature-style review + bibliography |
| "Prove this claim" | Evidence map: claim → sources → quality |
| History / change | Timeline |
| Visual research | Catalogue + taxonomy, not a prose-only recap |
| Search demand | Keyword map clustered by intent |
| Another agent will consume it | JSON per `schemas/report.json` |

Do not emit a 20-section consulting report for a five-minute scan. Do not emit three bullet points for an exhaustive literature request.

## Shapes

**Brief** — question, 3–7 findings, confidence, what would change the answer.

**Report** — objective, method (short), findings, patterns, contradictions, open questions, sources. No mandatory ICP/VOC/TAM sections.

**Table / matrix** — rows = entities or claims; columns = the dimensions the user cares about; cells = evidence, not adjectives.

**Evidence map** — claim, support, counter, confidence, key URLs.

**Timeline** — dated events with sources; separate facts from commentary.

**Taxonomy** — named clusters, inclusion rules, exemplars, outliers.

**Source catalogue / bibliography** — consistent fields; distinguish read vs cited-from-secondary.

**Literature review** — organize by debate or finding, not paper-by-paper abstracts.

**Competitive landscape** — include indirect/substitutes when relevant; works for tools and papers, not only companies.

**Visual catalogue** — image (or path), source link, attributes, cluster id. Deduped.

**Keyword map** — cluster, intent, example queries, SERP notes, gaps.

**JSON** — validate against schemas when you claim conformance.

## Voice

Label speculation. Put numbers next to their definition and date. Quote customer language when market/content modes asked for language. Keep recommendations last and optional unless the user asked for them.
