# FAQ: plain-language answers

Captured 2026-11-15. Details: [overview](../01-competition/01-overview.md) · [rules](../01-competition/02-rules.md) · [discussion](../01-competition/04-discussion.md).

## What do they want from us?
An **AI agent that does an engineer's job**: given a messy project folder (PDF drawings, specs, Excel, CAD, emails, old superseded revisions), it produces the deliverable a licensed engineer would (calc memo, IFC 3D model, cable schedule, cost study, review letter). We don't build the AI model; we build the **harness** around it: planning, reading files with tools, running calculations, checking its own work, writing outputs.

## Is there a frontend?
**No, it's backend only.** The harness is a WebSocket server (`serve.py` / `harness.py`) that Google's grader talks to automatically, inside a container with 2 CPUs and 4 GB RAM. The only visuals are the 3 figures in the Writeup.

## What are Stage 1 and Stage 2?
Like a job application:
- **Stage 1 = the written application.** Before Jan 5 we submit code + a ≤ 2,000-word report. Judges score the **report** out of 100 → the **top 100** advance (around **Jan 19**).
- **Stage 2 = the practical test.** Google runs our agent on **56 secret tasks, 3 times each**, and pays for it. Highest score (among cost-efficient entries) wins (**Jan 26**).

Stage 1 gets you into the final; Stage 2 decides the winner.

## How is Stage 1 scored?
By judges reading the Writeup, out of 100:

| Criterion | Points |
|---|---|
| Insight & failure analysis (real failures, before/after experiments) | 25 |
| Engineering reasoning (one task walked through vs a real engineer) | 25 |
| Cross-model results (≥ 2 models; local ones count) | 15 |
| Efficiency & scaling (score-vs-cost chart) | 20 |
| Clarity & visuals (< 2,000 words, 3 figures, headline first) | 15 |

The repo must also pass `kit check` + `kit artifacts`, or it is not judged at all. You only learn whether you made the top 100, not the points.

## What does "average" mean in Stage 2?
Each of the 168 attempts (56 tasks × 3) scores 0.0–1.0; the average is their mean. Example: scores 0.8, 0.6, 0.7, 0.0, 0.3, 0.2 → 2.6 ÷ 6 = **0.43**. You need **≥ 0.138** to qualify.

## What is the "cost-efficient" (Pareto) rule?
An entry is knocked out if another entry is **both better and cheaper**. Among the remaining entries the **highest average wins**. The top-scoring entry is always on the frontier, so **for #1, maximise score**.

| Agent | Avg | $/task | Result |
|---|---|---|---|
| A | 0.50 | $10 | ✅ stays |
| B | 0.45 | $2 | ✅ stays (cheapest) |
| C | 0.44 | $12 | ❌ out (A better and cheaper) |
| D | 0.55 | $30 | ✅ stays (highest) → **wins** |

## Can we test and get a score before submitting?
**Yes, locally, as often as we like** (no Kaggle leaderboard):
- `kit check`: **pass/fail** (does it install, start, connect, finish a smoke task?) → must print `ready to submit`.
- `eval/run.py`: **real 0–1 scores** on the 29 dev tasks using the official graders (rubric tasks need a judge model; local judge OK, organizers re-score). Results + token usage in `runs/<run>/results.json`.

We **cannot** see hidden-test scores, and there is no official pre-submission test server.

## Do we need to show accuracy?
Yes: dev-set scores (0–1 per task) go **into the Writeup** (score-vs-cost plot, failure breakdown, model comparison, ablations). There's no minimum score for Stage 1; Stage 2 needs ≥ 0.138 to qualify for prizes.

## What is the dev data?
A gated Hugging Face dataset of **29 tasks** (1.1 GB, ~33k files, of which ~1,500 are input documents: ~795 PDFs ≈ 15,200 pages, ~360 spreadsheets, ~100 Word files, ~60 CAD/BIM, 34 images). See [DEV-TASKS-INDEX](../04-dev-set/DEV-TASKS-INDEX.md). Most of the 33k files are tool-app source code and graders (never read the graders).

## Can we use Flash for development and Opus for Stage 2?
**Yes** (officially allowed; disclose it). See [models & budget §5](02-models-and-budget.md#5-is-flash-for-stage-1-opus-for-stage-2-allowed).

## Can we get free credits?
- **Competition:** no; hosts said so.
- **Anthropic:** Max ($100/mo) / Ultra ($200/mo) / Team plans include monthly **API credits** (usable for Opus dev runs via API key). See [models & budget §4](02-models-and-budget.md#4-option-b-claude-ultra-plan-200month-for-api-credits).

## Honest odds?
- **Top 100:** a fair chance if the repo passes all checks and the report is clear and honest; not guaranteed (1,700+ entrants, though many never submit).
- **Win:** hard. Many teams will use Opus + Claude Code (~50% baseline). Our edge must come from the deliverable checker, hard-constraint checker, revision tracking and multiple attempts.

## Key dates (11:59 PM UTC)
| Date | Event |
|---|---|
| Jan 5, 2027 | Final submission deadline |
| Jan 19, 2027 | Stage 1 done, top 100 chosen |
| Jan 26, 2027 | Winners announced |
