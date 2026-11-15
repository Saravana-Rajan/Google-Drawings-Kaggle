# Our Plan: Top 100 (Stage 1) → Win (Stage 2)

Budget: **max $200** · Deadline: **Jan 5, 2027** · Written 2026-11-15

## The idea in one line

Build a **careful engineer agent** (Claude Code + strong self-checking). Practise cheaply on **Gemini 3.8 Flash**, write an honest, clear report → **top 100**. Run it on **Claude Opus 5.5** in Stage 2 (Google pays) → **highest score wins**.

## Models

| Use | Model | Who pays |
|---|---|---|
| Building the code | Claude Code (our subscription) | $0 |
| Practice + final dev outputs (Stage 1) | Gemini 3.8 Flash (before Dec 31) | us |
| 2nd model for comparison table | Gemma 4 26B | us (~$15) |
| Stage 2 declared model | **Claude Opus 5.5** (`google-cloud/claude-opus-5-5`) | Google |

## Why we can beat the ~50% best system

The best system (Opus + Claude Code) loses points in 3 places. We fix each:

| Problem | Our fix |
|---|---|
| 23% of runs score **0** (no file, or a broken file) | **Deliverable checker**: before finishing, confirm every required file exists, opens, and runs; force a deliverable 30 min before the time limit; always send `done` |
| Meets 91% of rules but only **41% pass ALL safety rules** (one fail = lose the design points) | **Rule checker**: list every hard requirement, write a small Python test for each (units, code limits, clearances), fix until all pass, only then optimise cost |
| Same task, very different scores run to run | **Several attempts + pick the best** using our own checker |
| Old/superseded drawings are planted as traps | **Revision tracker**: always use the latest revision |
| Misreads drawings/units | **Toolbox**: PDF, Excel, Word, DXF, IFC readers + unit library |

Rules: no hard-coded answers, no special-casing tasks, never read the graders.

## Stage 1 (top 100): the report

Must pass `kit check` + `kit artifacts`, then a ≤ 2,000-word Writeup with 3 figures:
1. **Architecture diagram**: our agent
2. **Score vs cost chart**: more attempts → higher score, where it levels off
3. **Failure chart**: what failed on the 29 tasks and why

Content: before/after numbers for each fix, one task explained like an engineer would, a Flash vs Gemma (+ small Opus) table, and the headline finding first.

## Budget ($200)

| Step | Cost |
|---|---|
| Baseline: 6 tasks on Flash | $15 |
| Improvement tests (~22 task runs) | $55 |
| Final full 29-task run on Flash | $75 |
| Gemma full run (comparison) | $15 |
| 2 Opus check runs | $35 |
| Judge + final kit check | $4 |
| **Total** | **≈ $199** |

Safety: per-task cost cap in the code, GCP budget alerts at $100 / $150 / $190, iterate mainly on the 12 script-graded tasks.

## Timeline

| Dates | Goal |
|---|---|
| Nov 15–22 | Set up; run the template on 6 tasks; list every failure |
| Nov 23–Dec 6 | Build: deliverable checker, rule checker, revision tracker, toolbox; measure each |
| Dec 7–20 | Multiple attempts + pick best; robustness; 2 Opus checks |
| Dec 21–31 | Final 29-task Flash run + Gemma run; make the 3 figures |
| Jan 1–5 | Write report, `kit check` → "ready to submit", submit (visibility: at close) |

## Honest odds

- Top 100: a fair chance if everything passes the checks and the report is clear (not guaranteed).
- Win: hard. Many teams use Opus + Claude Code; our edge must come from the checkers.
