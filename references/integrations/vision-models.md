# Vision models

Use a vision-capable model when **pixels are evidence**: classification, tagging, comparison, attribute extraction, quality screening, motif detection, taxonomy support, screenshot interpretation.

Provider-agnostic. Prefer whatever vision model the current harness already exposes. Do not stall a visual task because a specific vendor name is missing; do not invent pixel-level detail you did not look at.

## When to use

- Visual research mode after a corpus exists
- Interpreting UI screenshots, packaging, ebook covers, ads
- Checking whether two pins are the same image
- Reading a chart or figure that text extraction mangled

## When not to use

- Text-only questions
- As a substitute for collecting the images
- Generating fake "example" images and treating them as market evidence

## Practice

1. Save images or screenshots under `.research/` with source URLs in a sidecar JSON (`schemas/source.json`).
2. Batch: describe/tag in groups; then cluster in text.
3. Ask for specific attributes the taxonomy needs, not a generic "what's in this image?"
4. Record uncertainty (blur, watermark, crop).
5. If the harness has no vision, say so and limit claims to metadata/URLs — or ask the user to switch to a vision-capable session.

Household Firecrawl **screenshot capture** was unsupported on v2.11.0 in probe. Vision can still analyze images obtained another way.
