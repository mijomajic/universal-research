# X (Twitter)

Useful for **current discourse**: emerging narratives, expert/operator commentary, product announcements, community reaction, positioning, recent signals.

Not privileged by default. Recency and engagement are distortions, not authority.

## When to use

Launches, outage chatter, "what are practitioners saying this week," locating a primary announcement, tracking a live controversy.

## When not to use

- Baseline scientific or historical questions better served by papers and books
- Treating likes/reposts as public opinion
- Unverified screenshots of tweets without a URL

## Access

1. Agent Reach doctor → twitter-cli or OpenCLI per `active_backend`.
2. twitter-cli needs `TWITTER_AUTH_TOKEN` and `TWITTER_CT0` in the child environment; do not print them. Doctor-stored cookies are not automatically exported to your shell.
3. Firecrawl a public status URL only if native read failed and the tweet is actually public.

## How to read it

- Separate **first-party** accounts (company, author, registry) from quote-tweets and dunking.
- Virality ≠ importance; ratio ≠ proof.
- Bots, paid promotion, and reply spam.
- Timestamp everything; discourse moves.

Use as a pointer to primary sources (blog, paper, GitHub release) whenever the tweet is not itself the object of study.
