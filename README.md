# Google-Drawings-Kaggle

Research notes and plan for **[Google - Agent Harness on Physical-Engineering's Last Exam (PLE)](https://www.kaggle.com/competitions/physical-engineerings-last-exam)**, a Kaggle Featured Hackathon with a **$400,000** prize pool.

> Build an open-source **agent harness**, pair it with a Google-sponsored model, and solve long-horizon structural, civil, electrical and mechanical engineering tasks from messy project folders (PDF drawings, specs, Excel, CAD/BIM).

## At a glance

| | |
|---|---|
| **Deadline** | **Jan 5, 2027, 23:59 UTC** (Stage 1 results Jan 19 · winners Jan 26) |
| **Submit** | Kaggle Writeup (≤ 2,000 words, 3 figures) + GitHub commit (`submission.yaml`, `serve.py`, `harness.py`, LICENSE, `artifacts/`) |
| **Stage 1** | Writeup judged out of 100 → **top 100** advance |
| **Stage 2** | Harness runs on **56 hidden tasks × 3**; Google pays. Highest mean score on the score/cost Pareto frontier wins (min 0.138) |
| **Prizes** | $250K · $100K · $50K |
| **Our plan** | Develop on **Gemini 3.8 Flash** (cheap) → declare **Claude Opus 5.5** for Stage 2 · budget **≤ $200** |

👉 Start here: **[docs/00-plan/01-winning-plan.md](docs/00-plan/01-winning-plan.md)**

## Repository structure

```
.
├── README.md                         ← you are here
├── docs/
│   ├── 00-plan/                      ← OUR strategy
│   │   ├── 01-winning-plan.md        stage 1 + stage 2 plan, harness design, timeline
│   │   ├── 02-models-and-budget.md   model scores, per-model costs, $200 plan, Claude API credits
│   │   └── 03-faq.md                 plain-language Q&A (stages, scoring, checks, rules)
│   ├── 01-competition/               ← Kaggle competition pages
│   │   ├── 01-overview.md            description, requirements, rubric, Stage 2, models, timeline
│   │   ├── 02-rules.md               official rules (TL;DR + full)
│   │   ├── 03-data.md                data tab + where the dev tasks live
│   │   ├── 04-discussion.md          12 forum threads indexed + official answers
│   │   ├── discussion/               one file per thread
│   │   ├── 05-code.md                10 public notebooks indexed
│   │   ├── code/                     each notebook rendered + summarised (credited to authors)
│   │   └── 06-writeups.md            writeup checklist
│   ├── 02-benchmark-and-sources/     ← links found in the competition content
│   │   ├── ple-bench-*.md            ple-bench.com: guide, agents guide, leaderboard, tasks…
│   │   ├── arxiv-ple-paper.md        PLE paper digest (arXiv 2610.30537)
│   │   ├── mercor-blog-ple-announcement.md
│   │   ├── gcp-*-pricing.md          Stage 2 cost basis (Google Cloud Model Garden)
│   │   ├── gemini-4-argon-vertex-specs.md
│   │   └── gemini-4-hydrogen-announcement.md
│   ├── 03-official-repos/            ← guides to the official GitHub repos
│   │   ├── google-research-ple/      kit, eval runner (29 tasks), protocol, models, rules, samples, submission.yaml spec
│   │   └── submission-template/      architecture, AGENTS.md, baseline artifacts (~0.49)
│   └── 04-dev-set/
│       ├── DEV-TASKS-INDEX.md        29 dev tasks: files, formats, PDF pages, token & cost estimates
│       └── NOTE.md                   the only Kaggle data file
├── scripts/
│   ├── download_dev_tasks.sh         fetch the gated HF dataset → data/dev-tasks/
│   └── clone_official_repos.sh       clone google-research/ple + submission-template → vendor/
├── data/                             (git-ignored) dev tasks after download
└── vendor/                           (git-ignored) official repo clones
```

## Setup

```bash
# 1. Official repos (kit, eval runner, template)
./scripts/clone_official_repos.sh

# 2. Dev tasks: accept terms at https://huggingface.co/datasets/google/physical-engineerings-last-exam first
uvx hf auth login
./scripts/download_dev_tasks.sh

# 3. Validate an entry / run dev tasks (from vendor/ple)
cd vendor/ple
uv run python -m kit check ../submission-template
uv run python eval/run.py ../submission-template --tasks lv-cable-sizing
```

## Notes

- **The PLE dev dataset is not included.** Its terms forbid redistribution; download it yourself with the script.
- Content under `docs/01-competition`, `docs/02-benchmark-and-sources` and `docs/03-official-repos` summarises or quotes third-party pages (Kaggle, Google, Mercor, arXiv, Apache-licensed google-research/ple). Each file links its source; rights remain with the original authors.
- Captured **2026-11-15**. Rules and prices can change, so re-check the sources before submitting.
