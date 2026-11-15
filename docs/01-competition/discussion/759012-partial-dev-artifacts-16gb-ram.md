# Partial dev artifacts/ when the largest tasks don't fit in 16 GB RAM?

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/discussion/759012
Author: No_Name · posted Nov 13, 2026 · 0 comments (captured 2026-11-15)

## Context

The author develops on a **16 GB RAM** machine (Docker Desktop on WSL 2) with no cloud budget. The eval README says Docker Desktop needs about **6 CPUs and 16.25 GB memory** for the largest dev task plus its serve stack, so some of the 29 tasks may not run locally.

## Questions

1. If `artifacts/` covers only the tasks that run locally, with the missing ones listed in the Writeup, is the entry still eligible for Stage 1 and Stage 2?
2. Will `kit artifacts` / `kit check` accept an `artifacts/` with missing tasks, or do missing tasks need placeholder outputs (scored 0)?
3. Can the hosts share peak memory for the largest dev tasks, or say which tasks use the **12 GB containers**?

> Status: unanswered at capture. **Takeaway:** plan for ≥ 6 CPU / ~16.25 GB Docker memory when running the full dev set (see `../../03-official-repos/google-research-ple/eval.md`).
