# Questions on dev-time model access and data use with API providers

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/discussion/758388
Author: Sankalp Mhaske · posted Nov 12, 2026 · 0 comments (captured 2026-11-15)

## Questions

1. **Dev credits:** is there free access to the 8 `google-cloud/*` models during development (credits, dev key, limited quota), or is the free key only for Stage 2? *(Answered elsewhere: no credits. See 757726 / 757453.)*
2. **Free-tier APIs and data:** is it OK to send public dev task files to free-tier APIs whose terms allow **training on inputs** (e.g. the Gemini API free tier), given the "Competition Use Only" / data-security rules?
3. **Kaggle notebooks:** can `eval/run.py` run inside a Kaggle notebook (e.g. a self-hosted open-weight model on Kaggle GPUs), or only locally with Docker?
4. **Mixed models in dev:** can dev `artifacts/` mix models (a free-tier model on some tasks, another on the rest) if documented?
5. **Judge:** is there a recommended low-cost or open-weight `JUDGE_MODEL` that gives scores roughly comparable to the official judge?

> Status: unanswered by hosts at capture. Questions 2–5 are still open; question 2 matters for data-use compliance (the HF dataset terms forbid exposing the data to a model "while it is being evaluated on PLE").
