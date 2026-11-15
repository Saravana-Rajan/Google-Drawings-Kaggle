# Introducing Gemini 4 Hydrogen (Google blog)

Source: https://blog.google/innovation-and-ai/models-and-research/gemini-models/introducing-gemini-4-hydrogen/
Published Nov 12, 2026 (updated Nov 13) · Koray Kavukcuoglu, Google DeepMind · captured 2026-11-15 (paraphrased)

## Relevance to PLE

- ❌ **Not on the competition's 8 sponsored models** at capture, so it can't be declared in `submission.yaml` for Stage 2. The Overview says the list "may be updated as newer models are released", so watch for it.
- ✅ Usable for **Stage 1 dev runs and `artifacts/`** via your own Gemini API key, since personal API models are allowed (disclose it in the Writeup).
- Same price as Gemini 3.8 Flash *after* Jan 1, 2027 ($1.50 / $7.50) but reportedly much stronger (AA Index ≥ Gemini 4 Argon). **Not benchmarked on PLE.**
- Vertex AI / Model Garden availability: **not mentioned.**

## What it is

- A fast "daily driver" model for agentic and coding workflows; the upgrade path from **Gemini 3.8 Flash**.
- Frontier models remain **Gemini 4 Carbon** and **Gemini 4 Argon** (deep long-horizon reasoning). Hydrogen is meant for fast execution, including as the worker/verifier paired with Carbon or Argon.
- Model ID (from the AI Studio link): `gemini-4-hydrogen`.

## Availability

Gemini API & Google AI Studio · Android Studio · Gemini Enterprise · Google Antigravity (AI Pro/Ultra) · Gemini app (dropdown; free users via auto-selection) · Google Search · Gemini in Sheets (Pro/Ultra). Vertex AI not stated.

## Pricing & context

- **$1.50 / 1M input, $7.50 / 1M output**, flat across the full context. Cached-token price not stated.
- **1M-token input context.**

## Benchmarks reported

| Benchmark | Hydrogen | Comparison |
|---|---|---|
| Artificial Analysis Intelligence Index | **51** (high) / **54** (xhigh) | Gemini 4 Argon 50 |
| Terminal-Bench 4.1 | **57%** | Gemini 3.8 Flash 18.2% |
| HLE-Diamond | 58.8% | "leads its class" |
| Vals Tax Agent Bench | 52.3% (#1) | — |
| Vals Legal Research Bench | 55.8% (tied #1) | — |
| Multimodal Knowledge Agent (MKA) | 53.4% | — |
| Agents' Last Exam v1.1 | 71.6% | — |
| Agent Arena (live) | #5 | — |
| Terminal-Bench 4.0 (Antigravity Orchestrator, Carbon + Hydrogen) | near-Carbon success, 24% less quota, 19% faster | — |
| Partner workflows vs 3.8 Flash | 2–2.8× faster, 12–23% fewer tokens | — |

Not compared against Claude Opus 5.5 or GPT 6 Astra.

## Agent-relevant features

- Thinking levels: low / medium / **high (default)** / new **xhigh**.
- Natively **batches file-read and search calls in parallel**; adapts when a tool call fails or a search returns empty.
- About **2.5× faster** than 3.8 Flash at the default level; often uses fewer output tokens.
- Safety/reliability vs 3.8 Flash: task shortcutting and misaligned actions down 12×; overreach down up to 81%; 94% on an internal agent-honesty eval.

## Google Cloud (Vertex / Gemini Enterprise Agent Platform) model page: key specs

Source: Google Cloud docs, "Gemini 4 Hydrogen" model page (pasted by the user; last updated 2026-11-13)

| Spec | Value | PLE relevance |
|---|---|---|
| Launch stage | **GA** on Google Cloud, released Nov 12, 2026; regions global, us, eu | Available on Vertex, but **still not one of the 8 sponsored `google-cloud/*` IDs** |
| Model ID | `gemini-4-hydrogen` | |
| Context | **1,048,576 tokens, unified input + output** (incl. thinking); ≤ 65,536 output tokens per segment; long decodes via `continuation_token` (v1beta1) | Plenty for long-horizon tasks; budget output against input |
| APIs | GenerateContent, Interactions, **OpenAI-compatible Chat Completions**, Count Tokens; no Live API | Works through the kit's OpenAI-compatible / `MODEL_BASE_URL` path |
| Thinking levels | LOW / MEDIUM / **HIGH (default)** / XHIGH. **`thinking_budget` or `thinking_level="MINIMAL"` returns HTTP 400** | ⚠️ In Stage 2, **HTTP 400s count against your score**; never send these params |
| Sampling | temperature 1.0, top_p 0.95, top_k 64 are **fixed; custom values ignored** | Can't make runs deterministic via temperature |
| Caching | **Implicit only** (≥ 4,096-token prefix), durable caching on by default; explicit caching not supported. From **Jan 12, 2027**, cache-control with TTL; cache writes billed at 1.25× input | Keep a stable prompt prefix to benefit automatically |
| **Native file inputs** | PDF, plain text, **.docx/.doc/.dotx, .xlsx/.xls, .pptx/.ppt, .odt/.ods/.odp**, inline or from GCS, including inside function responses | ⭐ Can pass task PDFs and Office files directly, with no conversion step |
| Doc tokenization | **560 tokens per PDF page** (default resolution); OCR for scanned PDFs off by default; ≤ 3,000 pages/file, ≤ 3,000 docs+images/prompt | Our dev set has ≈15,176 PDF pages ≈ **8.5M tokens** at this rate (not 258/page) |
| Images | **1,120 tokens per image** (default); png/jpeg/webp/heic/heif | |
| Tools | Function calling, code execution, URL context, computer use, search grounding | ⚠️ Web search/grounding is **blocked in Stage 2**; use function calling + code execution |
| Not supported | RAG Engine, tuning, explicit caching, Live API | |
| Knowledge cutoff | March 2026 | |
| Consumption | Standard/Priority PayGo, batch, provisioned throughput | |

## Linked (not archived)

- Model card: https://storage.googleapis.com/deepmind-media/Model-Cards/Gemini-4-Hydrogen-Model-Card.pdf
- Developer post: https://blog.google/innovation-and-ai/technology/developers-tools/build-with-gemini-4-hydrogen/
- Antigravity post: https://antigravity.google/blog/gemini-4-hydrogen-in-google-antigravity
