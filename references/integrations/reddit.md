# Reddit

Useful **qualitative** source: lived experience, recurring questions, pain points, objections, workarounds, customer language, niche knowledge, sentiment, anecdotal product reports.

Not by default: scientific proof, prevalence, or "the market thinks."

## When to use

Market language, support-like stories, practitioner tricks, "has anyone tried X," moderation/community norms of a subreddit that *is* the object of study.

## When not to use

- Settling causal or clinical claims
- Population rates ("most women…") from comment counts
- A subreddit that is off-topic noise for this question

## Access

Reddit's anonymous APIs are treated as dead by Agent Reach. Prefer:

1. `agent-reach doctor --json` → `opencli reddit …` on desktop with a logged-in Chrome session, or `rdt` if that is the active backend.
2. Firecrawl a **permalink** only if native read already found the thread and you need cleaner markdown.

Do not scrape cookie stores. Do not commit session files.

## How to read it

- Prefer repeating claims across **independent** threads/subreddits over one highly upvoted comment.
- Note subreddit selection (who hangs out here).
- Brigading, bots, and temporal drift (advice from 2018 presented as current).
- Quotes are language evidence; they are not N.

Pair with reviews, support docs, or interviews when making product decisions. Pair **never** as a substitute for papers in science mode.
