# Research planning

Use this before collection on anything beyond a quick scan. The plan should be short enough to execute, not a second report.

## From request to questions

Rewrite vague prompts into questions that evidence could answer.

| User said | Better research question |
| --- | --- |
| Research AI coding agents. | What are the main product classes, who uses them, what jobs they perform, and which architectural approaches are current as of {year}? |
| Is creatine good for the brain? | In healthy adults, what is the randomized/human evidence that creatine changes cognition, with effect size, population, and limitations? |

If the user already asked a precise question, keep it. Do not "expand" a confirmatory question into a market study.

Split a broad topic into 3–8 subquestions that cover: definition/scope, current state, mechanisms or causes, alternatives, evidence quality, and open questions — then drop any that the purpose does not need.

## Exploratory vs confirmatory

- **Exploratory** — map a space, find language, find players, find debates. Favor breadth, diverse source classes, clustering.
- **Confirmatory** — test a claim or choose among options. Favor primary evidence, pre-declared criteria, counterevidence, stop when the claim is saturated.

Most real requests mix both: explore just enough to name the options, then confirm the ones that matter.

## Breadth-first vs depth-first

- Start **breadth-first** when the category, players, or vocabulary are unclear.
- Start **depth-first** when the question is already narrow (one claim, one architecture, one population).
- After a broad pass, recurse only into branches with high decision value. Do not confuse "found many links" with "went deep."

## Depth

| Depth | Sources (order of magnitude) | Iteration | Stopping |
| --- | --- | --- | --- |
| quick-scan | A handful of high-leverage sources | 0–1 | Can brief the user in minutes |
| standard | Enough to triangulate main claims | 1–2 | Main subquestions have evidence or an explicit gap |
| deep-dive | Primary sources + counterevidence | 2–4 | Weak claims revisited; contradictions surfaced |
| exhaustive | Corpus-scale, citation chaining, saturation | until marginal value drops | Completeness over speed; still report leftovers |

Honor explicit budgets: "five-minute scan" vs "exhaustive." Local Firecrawl is not a reason to crawl the internet by default.

## Evidence requirements before collection

For each subquestion, name:

1. What would count as an answer (metric, date, population, artifact).
2. The **source class** that can provide it (paper, official docs, filed data, lived experience, visual corpus).
3. Whether primary sources are required.
4. What would falsify or complicate the answer.

Do not collect Reddit threads to settle a clinical claim. Do not collect only RCTs to learn how customers describe a product.

## Constraints

Fold in time, cost, access, and recency:

- Recency: news, pricing, APIs, and social discourse go stale fast; mechanisms and history less so.
- Access: prefer sources the current kit can actually reach (see doctor / docs-index).
- Cost: model time and rate limits still matter on a self-hosted Firecrawl.

Write **stop rules** in the plan: max iterations, max new branches, "stop if two independent primary sources agree," or "stop when the next hour would only add duplicates."

## Clarification

Ask only when the answer would change source class, geography, population, time window, or deliverable. Do not ask the user to choose a framework (ICP, PRISMA, TAM) unless they asked for that artifact.

Proceed without asking when the request already has subject, purpose, depth, and structure.
