# Models & Budget

Captured 2026-11-15. Sources: [PLE paper digest](../02-benchmark-and-sources/arxiv-ple-paper.md), [Model Garden pricing](../02-benchmark-and-sources/gcp-model-garden-pricing.md), [Partner model pricing](../02-benchmark-and-sources/gcp-partner-models-pricing.md), community estimates in [notebooks](../01-competition/05-code.md).

## 1. Which model performs best (PLE paper, best harness, all 85 tasks)

| Rank | `model_api` (Stage 2 allowed) | Best score | Measured cost/task |
|---|---|---|---|
| 🥇 | `google-cloud/claude-opus-5-5` | **50.6%** (Claude Code) | $13–17 |
| 🥈 | `google-cloud/gemini-4-argon` | 43.2% (Claude Code) | $6–9 (promo prices) |
| 🥉 | `google-cloud/gemini-3.8-flash` | 28.2% (Claude Code) | ~$2.55 |
| 4 | `google-cloud/glm-5.2` | 25.3% | — |
| 5 | `google-cloud/gemini-3.1-pro-preview` | 14.2% | — |
| 6 | `google-cloud/llama-4-maverick` | 0.7% | — |
| – | `google-cloud/gemma-4-26b`, `google-cloud/gpt-oss-120b` | not tested in paper | very cheap |

Key finding from the paper: **the model matters far more than the harness** (≈50-point spread across models vs ≈3 points across harnesses for one model). **Claude Code was the best harness** for Opus, Argon and Flash.

Not allowed for Stage 2 (as of capture): Gemini 4 Hydrogen (new, GA on Vertex; Stage 1 dev use only).

## 2. Per-model cost

Prices per 1M tokens (Global endpoint). Opus/Argon/Flash per-task costs measured in the paper; others are scaled by token price (rough).

| Model | $/1M in / out | Per task | 1 full dev run (29) |
|---|---|---|---|
| Claude Opus 5.5 | $4 / $20 | $13–17 | $380–500 |
| Gemini 4 Argon (promo → Nov 30) | $2 / $10 | $6–8 | $175–240 |
| Gemini 4 Argon (from Dec 1) | $4 / $20 | $12–16 | $350–480 |
| Gemini 3.8 Flash (promo → Dec 31) | $0.75 / $3.75 | ~$2.5 | ~$75 |
| Gemini 3.8 Flash (from Jan 1) | $1.50 / $7.50 | ~$5 | ~$150 |
| GLM 5.2 | $1.40 / $4.40 | ~$5 | ~$140 |
| Gemini 3.1 Pro Preview | $2 / $12 | ~$7 | ~$200 |
| Llama 4 Maverick | $0.35 / $1.15 | ~$1.2 | ~$35 |
| Gemma 4 26B | $0.15 / $0.60 | ~$0.5 | ~$15 |
| gpt-oss 120B | $0.09 / $0.36 | ~$0.3 | ~$9 |

**Stage 2 (56 hidden tasks × 3 runs) is paid by Google: $0 to us.**

Model gotchas (Gemini 4 family on Vertex): `thinking_budget` or `thinking_level="MINIMAL"` → **HTTP 400** (counts against Stage 2 score); temperature fixed; Argon default thinking is MEDIUM (set HIGH); Argon accepts only PDF + text documents (convert XLSX/DOCX); PDFs ≈ 560 tokens/page.

## 3. Our $200 plan (Option A: Gemini cash)

| Step | Model | Runs | Cost |
|---|---|---|---|
| Build harness | Claude Code (subscription) | — | $0 |
| Baseline on 6 tasks | Gemini 3.8 Flash | 6 | ~$15 |
| Improvement tests | Gemini 3.8 Flash | ~22 | ~$55 |
| **Final full dev run → committed `artifacts/`** (before Dec 31) | Gemini 3.8 Flash | 29 | ~$75 |
| 2nd model for comparison table | Gemma 4 26B | 29 | ~$15 |
| Opus sanity check | Claude Opus 5.5 | 2 | ~$35 |
| Judge + final `kit check` | Flash / Vertex proxy | — | ~$4 |
| **Total** | | | **≈ $199** |

Guards: per-task cost cap in the harness · GCP budget alerts at $100 / $150 / $190 · iterate mostly on the 12 script-graded tasks · no free-tier APIs that train on inputs (dataset terms forbid training).

## 4. Option B: Claude Ultra plan ($200/month) for API credits

Official ([help center](https://support.claude.com/en/articles/17154008-monthly-api-credits-for-max-ultra-and-team-plans), [pricing](https://claude.com/pricing)):

| Plan | Price | Monthly API credits |
|---|---|---|
| Pro / Free / Enterprise | — | none |
| Max | $100/mo | $100 |
| **Ultra** | **$200/mo** | **$200** |
| Team | per seat | $20 (Standard) / $100 (Premium) per seat, pooled ≤ $500 |

- Credits work for the **Claude API, Agent SDK, Managed Agents**, not for interactive Claude Code.
- Claim after **7 days** on the plan (claude.ai → Settings → Billing → *Link organization* to a Claude Console org). **Expire every billing cycle.** Plan auto-renews.
- On an organization (company) plan, only the **Owner/Primary Owner** can link credits, and they are company resources (needs company permission).

| | A: $200 Gemini cash | B: $200 Ultra |
|---|---|---|
| Opus test runs | ~2 | **~11–12** |
| Full 29-task final run | ✅ Flash (~$75) | ⚠️ needs a cheaper Claude model or a 2nd month |
| Best for | cheapest complete entry | **testing on the actual Stage 2 model** |

A 2nd Ultra month (~$400 total) makes Option B clearly strongest.

## 5. Is "Flash for Stage 1, Opus for Stage 2" allowed?

Yes. The Kaggle Overview (Minimum requirements) and a Kaggle Staff forum answer ([757726](../01-competition/discussion/757726-sponsored-model-credits-for-dev-runs.md)) allow generating `artifacts/` with any local/personal model and declaring a `google-cloud/*` model; disclose it in the Writeup.

Open questions (unanswered at capture): passing the final `kit check` for a `google-cloud` declaration needs a Vertex proxy, i.e. billing enabled ([759332](../01-competition/discussion/759332-required-kit-check-after-self-hosted-dev.md)); how the live dev re-run treats artifacts from a different model ([757453](../01-competition/discussion/757453-welcome-to-the-ple-competition.md)). The repo's older `docs/rules.md` still says artifacts must come from the declared model; the Kaggle page is newer.
