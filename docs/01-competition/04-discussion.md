# Discussion — index (12 threads, captured 2026-11-15)

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/discussion

## ⭐ Official answers so far (read these first)

1. **No GCP billing needed for dev.** Use any open-weight model (Ollama/vLLM/SGLang) or a personal API key to develop and to generate the committed `artifacts/`. Then switch `submission.yaml` → `google-cloud/<id>`. The resulting `manifest.json` warning does not disqualify you. Disclose the model in the Writeup. ([757726](discussion/757726-sponsored-model-credits-for-dev-runs.md))
2. **Local judge is OK** (`JUDGE_BASE_URL` / `JUDGE_MODEL`). Name it in the Writeup; organizers re-score with the official judge. ([757726](discussion/757726-sponsored-model-credits-for-dev-runs.md))
3. **Any two models** (local ones count) satisfy the Cross-Model criterion. ([757726](discussion/757726-sponsored-model-credits-for-dev-runs.md))
4. **No free credits** for anyone. ([757453](discussion/757453-welcome-to-the-ple-competition.md), [757726](discussion/757726-sponsored-model-credits-for-dev-runs.md))
5. Tools and models inside the harness must fit **2 CPU / 4 GB RAM**. Input file types are listed on **page 10 of the paper**, and the dev set covers all of them. ([757453](discussion/757453-welcome-to-the-ple-competition.md))
6. Running dev tasks with a local Ollama model through `eval/run.py` is **allowed** under the HF dataset terms. ([757453](discussion/757453-welcome-to-the-ple-competition.md))

## All threads

| # | Thread | Author | Replies | Status |
|---|---|---|---|---|
| 📌 | [Welcome to the PLE Competition!](discussion/757453-welcome-to-the-ple-competition.md) | Rujun Han (host) | 11 | Several host answers |
| 📌 | [How to Get Started + Official Discord](discussion/756603-how-to-get-started-and-discord.md) | Addison Howard (staff) | 1 | Info |
| 1 | [Required kit check after self-hosted development](discussion/759332-required-kit-check-after-self-hosted-dev.md) | moruku36 | 1 | Open: how to pass `kit check` without a billed proxy |
| 2 | [Hide submitted Writeup until close?](discussion/759277-hide-submitted-writeup-until-close.md) | Dawood Shareef | 0 | Open |
| 3 | [Stage 2 cost: price table, cached tokens, frontier](discussion/759266-stage2-cost-price-table-cached-tokens-frontier.md) | Chunyi Liu | 0 | Open, important for cost |
| 4 | [Pre-submission test server / dry run?](discussion/759201-pre-submission-test-server-dry-run.md) | hengck23 | 0 | Open |
| 5 | [Template-baseline draft: commit/artifact freeze](discussion/759101-template-baseline-commit-artifact-freeze.md) | Pengyi Peng1 | 0 | Open |
| 6 | [Partial dev artifacts when tasks don't fit in 16 GB](discussion/759012-partial-dev-artifacts-16gb-ram.md) | No_Name | 0 | Open |
| 7 | [Dev-time model access & data use with API providers](discussion/758388-dev-time-model-access-and-data-use.md) | Sankalp Mhaske | 0 | Open |
| 8 | [AIODAM + DeepSeek V4.1 Flash on all 29 dev tasks](discussion/758084-aiodam-deepseek-29-task-study.md) | Oxunjon | 0 | Shared study, with useful lessons |
| 9 | [Looking for a teammate](discussion/757883-looking-for-teammate.md) | Dawood Shareef | 1 | Team-up |
| 10 | [Sponsored model credits for dev runs?](discussion/757726-sponsored-model-credits-for-dev-runs.md) | Efe Karamese | 4 | ⭐ Official clarification |

## Open questions to watch

- How to pass `kit check` for a `google-cloud/*` declaration without a billed Vertex proxy (759332)
- When the commit and artifacts are frozen; whether to rerun all 29 tasks after prompt changes (759101)
- Stage 2 cost: which price date applies (promo prices end Dec 1 and Jan 1), cache pricing, metering source, Pareto tolerance (759266)
- Partial `artifacts/` eligibility (759012, 757453)
- Mixed models in dev artifacts; free-tier APIs that train on inputs (758388)
