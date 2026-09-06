# Synthesis

Synthesis is clustering, comparing, and weighing — not concatenating summaries.

## Do

- Cluster findings by theme, not by source order.
- Name recurring patterns and how many independent sources support them.
- Compare competing explanations; say what each would predict.
- Surface contradictions and outliers without burying them.
- Separate **evidence** (what was observed) from **interpretation** (what you think it means).
- Quantify when the data actually support numbers; otherwise stay qualitative.
- Preserve uncertainty and scope (who, when, where).
- Tie every major point back to the user's decision or question.
- List unanswered questions and, if useful, the next cheapest research step.

## Do not

- Flatten conflict into false consensus.
- Let the most eloquent source win.
- Treat "several articles said" as independent replication.
- Hide weak support behind confident tone.
- Dump a bibliography and call it a landscape.

## Working method

1. Normalize sources (title, url, date, class, one-line claim). `scripts/merge_sources.py` helps at corpus scale.
2. Tag each finding to a subquestion.
3. For each subquestion: supporting evidence, counterevidence, confidence, gap.
4. One more pass for anything still weakly held that the depth mode promised to settle.
5. Write to the requested shape. If JSON is requested, `schemas/finding.json` and `schemas/report.json` are the interchange forms.

## Confidence in the output

State confidence per major claim, not once for the whole document. A high-confidence definition plus a low-confidence market-size guess should not share a single "we found that…" paragraph.
