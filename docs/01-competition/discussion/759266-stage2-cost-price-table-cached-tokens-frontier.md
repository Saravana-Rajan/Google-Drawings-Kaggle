# Stage 2 cost: price table, cached tokens, and how the frontier is decided

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/discussion/759266
Author: Chunyi Liu · posted Nov 14, 2026 · 0 comments (captured 2026-11-15)

## Question to hosts

The Stage 2 ranking uses a performance-cost Pareto frontier priced at Google Cloud Model Garden list prices. The author asks hosts to clarify:

1. **Which price table and date apply?** Some sponsored models have promotional prices that end before Stage 2 runs. For example, Gemini 4 Argon's price doubles on Dec 1, 2026 and Gemini 3.8 Flash's on Jan 1, 2027 (see `../../02-benchmark-and-sources/gcp-model-garden-pricing.md`).
2. Are **cache reads and cache writes** priced at their own list rates, or as ordinary input tokens?
3. Are token counts taken from the **harness's usage frames** or from the **evaluation gateway's own metering**?
4. Is cost the **mean per task run over all 168 runs**?
5. Is the frontier decided by **strict dominance**, or is there a **tolerance** for near-ties in score or cost?

These answers determine how entrants should account for caching.

> Status: unanswered at capture. Important for cost optimisation.
