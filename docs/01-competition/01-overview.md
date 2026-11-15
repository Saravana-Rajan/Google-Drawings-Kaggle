# Overview — Google - Agent Harness on Physical-Engineering's Last Exam

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/overview
Captured: 2026-11-15

> Build autonomous agent harnesses to solve real-world structural, civil, electrical, and mechanical engineering tasks.

| Field | Value |
|---|---|
| Host | Google (Google Cloud AI Research, with Mercor + Stanford, NYU, UW, UNC Chapel Hill, Harvard, Columbia) |
| Type | Featured **Hackathon** (no leaderboard; Kaggle Writeup submission) |
| Prize pool | **$400,000** (does not award Kaggle points or medals) |
| Start | November 9, 2026 |
| Final deadline | **January 5, 2027, 11:59 PM UTC** |
| Participation (at capture) | 1,767 entrants · 31 participants · 31 teams · 31 submissions |
| Tags | Engineering, Model Comparison, Agentic, NLP |

## In one paragraph

Build an **open-source autonomous agent harness**, pair it with **one of 8 Google-sponsored foundation models**, and tackle **Physical-Engineering's Last Exam (PLE)** ([ple-bench.com](https://ple-bench.com/)) — a benchmark of **85 expert-reviewed, long-horizon tasks** across structural, civil, electrical, and mechanical engineering (29 public dev tasks + 56 hidden test tasks). Document findings in a **Kaggle Writeup**.

## Description

- Models score >90% on isolated engineering Q&A but stall on real project folders; top frontier models score **below 50%** on PLE.
- Real engineering = multi-hour investigation across dozens of messy, interdependent files: 3D CAD geometry, geotechnical soil borings, municipal utility rules, 50-file specification packages, deliverables a licensed reviewer would stamp.
- Typical agent failures: misreading drawing callouts, applying the wrong code clause, dropping unit conversions, quitting early.
- Example: routing chilled-water piping across seven drawing sheets around an offset structural grid and 104 sprinkler heads without clashing a steel beam through an air duct.
- Your job: engineer **verification loops, CAD & spreadsheet tool integrations, context-management strategies, and self-checks** to turn raw project folders into graded artifacts — e.g. seismic shear-wall calcs, clay footing settlement memos, clash-free **IFC4** 3D building models, 25-year cooling-tower cost studies.
- Announcement partner post: [Mercor blog](https://www.mercor.com/blog/introducing-physical-engineering-s-last-exam-ple-with-google-cloud-ai-research/) → see `../02-benchmark-and-sources/mercor-blog-ple-announcement.md`.

## Submission Requirements

Submit **one Kaggle Writeup (≤ 2,000 words)** before the deadline (can un-submit / edit / re-submit; un-submitted drafts are not judged). It must include:

1. Coverage of **all 5 Stage 1 rubric criteria**, a **Media Gallery cover image**, and **3 figures**:
   1. an **architecture diagram**
   2. a **score-vs-cost plot**
   3. a **failure breakdown on the 29 dev tasks**
2. **GitHub repo URL** under *Project Links* and the **40-character commit SHA** (`git rev-parse HEAD`) at the top of the Writeup. That commit must include:
   - `submission.yaml` (set to one of the 8 `google-cloud/*` models)
   - `serve.py`, `harness.py`
   - an **Apache-2.0 or MIT `LICENSE`**
   - the **unpacked `artifacts/`** from `uv run python eval/run.py`
   - must pass `uv run python -m kit check` and `uv run python -m kit artifacts`
   - Private repo during the competition? Install the [ple-submission GitHub App](https://github.com/apps/ple-submission/installations/new) and make it **public at competition close**.
3. If you use an open-weight or custom local judge (`JUDGE_MODEL`) instead of a frontier model for dev scores, **state which judge model** you used.

## Tracks and Awards — Main Track · $400,000

| Place | Prize |
|---|---|
| 🥇 First | $250,000 |
| 🥈 Second | $100,000 |
| 🥉 Third | $50,000 |

## Evaluation

Two stages: **Stage 1** = 100-point Writeup + pre-screening qualification gate; **Stage 2** = live execution on **56 hidden test tasks**.

### Minimum requirements (all four needed for Stage 1)

1. **Kaggle Writeup** (≤ 2,000 words) covering all 5 rubric criteria + 3 figures (architecture diagram, score-vs-cost plot, dev-set failure breakdown).
2. **GitHub repo + 40-char commit SHA** under Project Links. Repo root must include `submission.yaml`, `serve.py` / `harness.py`, Apache-2.0 or MIT license, unpacked `artifacts/`. (Private → install `ple-submission` app, make public at close.)
3. Set **`model_api`** in `submission.yaml` to one of the 8 official `google-cloud/<id>` models for Stage 2.
   - No Google Cloud / Vertex AI billing needed during local dev — you may run experiments and generate `artifacts/` with **any self-hosted open-weight model or personal LLM subscription/API key**.
   - In Stage 2 the evaluation proxy **blocks custom API keys (`.env`), external model servers, and web search**; Google supplies the eval key free.
4. Pass `uv run python -m kit check` and `uv run python -m kit artifacts` via the PLE Competition Kit.
   - Committed `artifacts/` must be an **unpacked directory** (≤ **512 MiB** and ≤ **10,000 files**, **no Git LFS, no symlinks**) generated by `uv run python eval/run.py`.
   - Switching `model_api` to your target `google-cloud/<id>` *after* generating artifacts on a local/personal model is **allowed**; paid LLM-judge calls are not required for local dev — just document the local model and judge setup in the Writeup. Organizers **re-score `artifacts/` with the official judge**.

### Stage 1 Writeup Rubric (100 pts)

| # | Criterion | Pts | What judges look for |
|---|---|---|---|
| 1 | **Insight & Failure Analysis** | 25 | Teach something non-obvious about engineering agents. Real dev-set failures (misreading a drawing callout, wrong code clause, unit errors, stopping early), controlled ablations ("we added X, dev score went A → B"), and ideas that failed. |
| 2 | **Engineering Reasoning** | 25 | Walk through a concrete dev-set task; compare agent trajectory vs. a licensed engineer's workflow. Where reasoning held, where it took shortcuts, which domain skills (reading CAD/PDF drawings, checking code tables, running solvers) separated passes from failures. |
| 3 | **Cross-Model Generalizability** | 15 | Test on the 29 public dev tasks with **≥ 2 models** (local open-weight / personal API OK), ideally across families. Which changes help every model vs. only one; how model choice shifts accuracy and token cost. Comparison table in Writeup; commit a single target `google-cloud/<id>` in `submission.yaml`. |
| 4 | **Efficiency & Scaling** | 20 | Plot dev score vs. compute budget (calls, tokens, runtime, or parallel verification attempts). Mark where accuracy plateaus; estimate remaining headroom. |
| 5 | **Clarity & Visuals** | 15 | Write for an ML researcher without CE/ME/EE background; headline finding near the top. 3 required figures; < 2,000 words. |
| | **Total** | **100** | |

**Top 100** Stage 1 submissions advance to Stage 2. Entries must pass automated `kit check` / `artifacts/` verification before being rubric-scored and may be pre-screened on a small hidden-task subset.

### Stage 2 — Hidden Test Evaluation

56 hidden tasks: **6 Structural, 9 Civil, 18 Electrical, 23 Mechanical**.

1. Evaluator **clones your commit**, runs `install` once in a **`debian:bookworm`** build container (**30-min timeout**, `/opt/harness` capped at **2 GiB compressed**), then a **smoke test**: serve binds `0.0.0.0:$PORT` within **120 s**, writes a test file, sends `done`.
2. Grades your committed `artifacts/` on the 29 dev tasks and **re-runs a random dev sample live**. Failing reproducibility or **hard-coding outputs ⇒ disqualified**.
3. Each hidden task runs in an isolated container: **2 CPUs, 4 GB RAM**, read-only `/opt/harness`, writable 1 GB `/tmp` and `$HOME`, **6-hour limit per task**, over **WebSocket**.
4. Verification scripts check quantitative calcs, CAD/IFC geometries, and constraints; an **LLM judge (Claude Opus 5.5)** grades open-ended deliverables on 0.0–1.0. Ungraded or timed-out tasks without a `done` or `error` frame score **0.0**.

Each finalist runs **3 independent times × 56 tasks = 168 task runs**. Stage 2 results = **performance-cost Pareto** of mean score and average cost (cost from [Model Garden pricing](https://cloud.google.com/model-garden/pricing) and [Partner models pricing](https://cloud.google.com/model-garden/partner-models/pricing) → see `../02-benchmark-and-sources/`).

- Prizes go to the **top 3 by mean score among systems on the Pareto frontier**.
- Must reach a **mean Stage 2 score ≥ 0.138** to qualify for the frontier / prizes.
- Organizers publish all scores and costs; evaluator faults and sponsored-endpoint rate limits/outages are retried without penalty. **HTTP 400s, unrecovered crashes and timeouts count against you.**

### Final Prize Ranking

Stage 1 is only a qualification gate. Among finalists on the Stage 2 Pareto frontier, **Stage 2 mean test score** determines 1st/2nd/3rd. Ties → Stage 1 Writeup score, then earlier Kaggle submission timestamp.

### Sponsored Models

Entries run only on Google-sponsored models injected by the evaluator proxy (`MODEL_BASE_URL` / `OPENAI_BASE_URL`, `ANTHROPIC_BASE_URL`, `GOOGLE_GEMINI_BASE_URL`). List may be updated.

| `model_api` identifier | Model | Family |
|---|---|---|
| `google-cloud/gemini-4-argon` | Gemini 4 Argon | Gemini |
| `google-cloud/gemini-3.8-flash` | Gemini 3.8 Flash | Gemini |
| `google-cloud/gemini-3.1-pro-preview` | Gemini 3.1 Pro (Preview) | Gemini |
| `google-cloud/gemma-4-26b` | Gemma 4 26B A4B | Gemma (open-weight) |
| `google-cloud/claude-opus-5-5` | Claude Opus 5.5 | Claude |
| `google-cloud/gpt-oss-120b` | gpt-oss 120B | Open-weight |
| `google-cloud/glm-5.2` | GLM 5.2 | GLM (open-weight) |
| `google-cloud/llama-4-maverick` | Llama 4 Maverick 17B 128E | Llama (open-weight) |

### How to Submit

1. Clone [google-research/ple](https://github.com/google-research/ple) and start from [physical-engineerings-last-exam/submission-template](https://github.com/physical-engineerings-last-exam/submission-template) (or `sample_submissions/pi-opus`, `hermes-opus`, or `agy-gemini`). → see `../03-official-repos/`
2. Validate and generate:
   ```bash
   uv run python -m kit check ../my-harness
   uv run python eval/run.py ../my-harness
   uv run python -m kit artifacts ../my-harness
   ```
3. Commit code + `submission.yaml` + `artifacts/` in **one commit** and push:
   ```bash
   git add -A && git commit -m "PLE harness submission" && git push
   ```
4. On Kaggle → **Writeups** tab → **New Writeup** → attach GitHub repo under Project Links → put 40-char commit SHA at top → **Submit**.

> Direct registration/submission on ple-bench.com is **closed**; official entries go through Kaggle Writeups. Competition guide: [ple-bench.com/competition/guide](https://ple-bench.com/competition/guide) → `../02-benchmark-and-sources/ple-bench-competition-guide.md`.

## Acknowledgements (BibTeX)

```bibtex
@misc{han2026ple,
  title = {{PLE}: Physical-Engineering's Last Exam},
  author = {Rujun Han and Yufan Zhuang and Arijit Ray and Han Yu and
            Zhongying CuiZhu and George Lee and Yifei Ming and Binz Roy and
            Varun Sakalkar and Vishy Tirumalashetty and Burak Gokturk and
            Tomas Pfister and Chen-Yu Lee},
  year = {2026},
  eprint = {2610.30537},
  archivePrefix = {arXiv},
  primaryClass = {cs.AI},
  url = {https://arxiv.org/abs/2610.30537}
}
```
Paper digest → `../02-benchmark-and-sources/arxiv-ple-paper.md`.

## Judges

- Yufan Zhuang — Research Scientist, Google
- Rujun Han — Research Scientist, Google
- Arijit Ray — Research Scientist, Google
- Chen-Yu Lee — Research Scientist, Google

## Timeline (11:59 PM UTC unless noted)

| Date | Milestone |
|---|---|
| Nov 9, 2026 | Start date |
| **Jan 5, 2027** | **Final submission deadline** — Writeups + committed GitHub repos (with dev-set `artifacts/`) |
| Jan 19, 2027 | Stage 1 Writeup judging complete (Top 100 → Stage 2) |
| Jan 26, 2027 | Stage 2 test evaluation complete & winners announced |

## Competition citation

Rujun Han, Yufan Zhuang, Arijit Ray, Han Yu, Zhongying CuiZhu, George Lee, Yifei Ming, Binz Roy, Varun Sakalkar, Vishy Tirumalashetty, Addison Howard, Paul Mooney, Burak Gokturk, Tomas Pfister, and Chen-Yu Lee. *Google - Agent Harness on Physical-Engineering's Last Exam.* https://www.kaggle.com/competitions/physical-engineerings-last-exam, 2026. Kaggle.
