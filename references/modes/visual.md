# Visual research mode

For questions where **images are the evidence**. Collect, dedupe, classify, then synthesize. A folder of undifferentiated screenshots is not research.

## What this mode is for

Reference corpora, visual taxonomy, composition, subject, camera angle, lighting, color, typography, layout, material/texture, props, environment, motifs, style clusters, conventions, outliers, trend-over-time, comparison.

## Method

1. **Define the visual question** — audience, product type, era, "popular" according to whom.
2. **Build a corpus** — Pinterest (browser), product sites, store screenshots, editorial, packaging. Save files + source URLs under `.research/`.
3. **Dedup** — same image reuploaded is one item. `scripts/merge_sources.py` for URLs; vision or hash for pixels if available.
4. **Attributes** — tag what the question needs (not every possible axis).
5. **Cluster** — name conventions; keep outliers as outliers.
6. **Synthesize** — patterns with exemplars. Popularity on Pinterest ≠ target-audience preference.
7. **Vision** — use a vision-capable model when the pixels matter. See [../integrations/vision-models.md](../integrations/vision-models.md).

## Sources

Pinterest and image search for discovery; original landing pages and publisher sites for provenance. Firecrawl `scrape --format images` or similar **only if doctor verified it**. Household v2.11.0: **screenshots were unsupported** by the engine in probe; do not plan around screenshots unless doctor flips that bit.

Agent Reach has **no native Pinterest channel** as of the 2026-09 docs pass. Browser session → collect → optional Firecrawl on original URLs → vision.

## Output

Taxonomy + catalogue (path, source URL, tags, cluster). Optional moodboard description. Not a prose recap that ignores the images.
