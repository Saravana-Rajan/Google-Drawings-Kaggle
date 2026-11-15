# Initial template-baseline draft: commit and artifact freeze questions

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/discussion/759101
Author: Pengyi Peng1 · posted Nov 14, 2026 · 0 comments (captured 2026-11-15)

## Context

The author saved a draft Writeup based on the organizers' **unchanged Pi / Claude Opus 5.5 submission template**. The draft credits the template's authors and separates the supplied 29-task dev artifacts from the author's own experiments. Nothing has been submitted or reproduced yet.

## Questions

1. **When are the commit and artifacts frozen for judging?** At the latest Writeup submission, at a linked commit field, or at the final deadline? What should be updated when replacing an earlier commit?
2. The template allows unchanged artifacts to be reused, while harness changes require regeneration. How should **inherited template artifacts** be disclosed? Do all 29 tasks need a rerun after **every functional harness change**, even a prompt-only revision?
3. The inherited artifacts lack **usage/cost records**. Should the score-vs-cost figure mark cost as unmeasured, or should the author wait for a fresh instrumented run? Is there a recommended cost-reporting format for the model comparison?

> Status: unanswered at capture. **Takeaway:** the template's bundled `artifacts/` (mean reward ≈ 0.491, no cost fields; see `../../03-official-repos/submission-template/dev-tasks-artifacts.md`) is a baseline. Regenerate artifacts with your own harness and record token usage.
