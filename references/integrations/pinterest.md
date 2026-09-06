# Pinterest

Visual **discovery** source: aesthetics, style, composition, packaging, mood clusters, lifestyle/design trends.

Popularity is not proof of broad preference. Reposts hide provenance.

## Access (household)

Agent Reach **does not currently document a Pinterest channel**. Unless `agent-reach doctor --json` later shows one:

```text
authenticated browser (user's logged-in Pinterest session)
        → collect pin/board URLs, image URLs, outbound source links
        → Firecrawl the original source page if extraction helps
        → vision model on saved images
        → cluster / taxonomy
```

Do not hardcode "Agent Reach supports Pinterest."

## When to use

Visual mode tasks, moodboards, "what do modern X products look like," packaging/layout conventions.

## When not to use

- Non-visual questions
- Treating pin volume as sales or search demand
- Citing a pin as the original designer without the outbound source

## Limitations

Unclear provenance, duplicates, stale pins, algorithmic popularity bias, image-to-source separation. Keep the **original** URL when the pin provides one. Dedup before clustering.

Household Firecrawl screenshots were **unsupported** in the 2026-09 probe; save images via browser download or image URLs, then run vision on files.
