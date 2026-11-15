# Are there sponsored model credits for local dev-set runs? ⭐ (contains the key official clarification)

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/discussion/757726
Author: Efe Karamese · posted Nov 10, 2026 · 2 votes · 4 comments (captured 2026-11-15)

## Question

Local dev runs go through `kit/model_proxy`, which bills **your own Google Cloud project**. Based on the paper's per-task costs, one full 29-task dev run costs about **$500 with Claude Opus 5.5** and **$175–260 with Gemini 4 Argon**, before any iteration. The author asks:
- Are there credits, quotas, or free access (e.g. for students or independents)?
- Must committed `artifacts/` come from the same `model_api` declared in `submission.yaml`?
- Is any server-side evaluation available during development?

## Host / staff answers

**Rujun Han (Competition Host):** no compute credits (too many participants expected). Test PLE on **open-source models**. The final ranking considers both efficiency and performance.

**Addison Howard (Kaggle Staff), official clarification (the Evaluation tab was updated to match):**
1. **No Google Cloud / Vertex AI billing account needed.** `kit/model_proxy/start.sh` uses Vertex AI by default, but all local dev experiments, **including generating `artifacts/`**, can use **any self-hosted open-weight model (Ollama, vLLM, SGLang)** or **any personal LLM subscription/API key** (see `docs/models.md` → `../../03-official-repos/google-research-ple/docs-models.md`).
2. **Paid Claude Opus 5.5 judge calls aren't required locally.** Point `JUDGE_BASE_URL` / `JUDGE_MODEL` at a local open-weight model (or start with the Python-graded dev tasks) and **name your local judge in the Writeup**. Organizers **re-score committed `artifacts/` with the official judge**.
3. Generate `artifacts/` with any local or API model, **then set `model_api` to one of the 8 `google-cloud/<id>` models** for Stage 2. A **`manifest.json` warning** from switching `submission.yaml` before committing **won't disqualify you**. Note which model generated `artifacts/` in the Writeup, and make sure your code supports the target model's API format.
4. **Comparing any two models** on the dev set, including local open-weight or personal API models, **satisfies Criterion 3** (Cross-Model Generalizability). You don't need two paid cloud endpoints.

## Other comments

- **KenoLeon:** entry is free but iteration isn't, so dev results partly measure budget. Suggests a **merit-gated grant**: give the top-N Stage 1 entries built on open-weight models a fixed credit allocation for Stage 2 iteration, as CrowdCent does. (No reply.)
- One comment was deleted.
