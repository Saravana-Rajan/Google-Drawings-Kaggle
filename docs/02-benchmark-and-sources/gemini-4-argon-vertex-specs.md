# Gemini 4 Argon: Google Cloud model page (specs)

Source: https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/gemini/4-argon
Captured: 2026-11-15 (paraphrased)

## Relevance to PLE

- ✅ **Sponsored Stage 2 model**: `google-cloud/gemini-4-argon`.
- PLE paper: best score **43.2%** (in Claude Code), about $8/task at promo prices. Second-best sponsored model after Claude Opus 5.5 (50.6%).
- Price (see `gcp-model-garden-pricing.md`): **$2 / $10 per 1M tokens until Nov 30, 2026 → $4 / $20 from Dec 1** (cached input $0.10 → $0.20).
- ⚠️ **Default thinking level is MEDIUM**: for max score set **HIGH** explicitly (the kit's `model_proxy/effort_default.py` defaults to the highest effort locally; set it in your harness too).
- ⚠️ **Never send `thinking_budget` or `thinking_level="MINIMAL"`**: they return **HTTP 400**, which counts against you in Stage 2.
- ⚠️ **Documents: only PDF + plain text** natively (Hydrogen also takes Office files). **Convert `.xlsx`/`.docx` yourself** (openpyxl / python-docx) before sending.
- PDFs ≈ **560 tokens/page**, images **1,120 tokens** each; dev set ≈ 15,176 PDF pages ≈ 8.5M tokens if every page were sent.
- Non-streaming output is capped at **32,768 tokens per segment** (65,536 streaming). **Stream** long generations.

## Model IDs

| ID | Notes |
|---|---|
| `gemini-4-argon` | Frontier model for deep work (coding, finance, legal, cyber, science) |
| `gemini-4-argon-cyber-permissive` | Defensive-security variant; allowlist via the Fairwind Program; no computer use |

Launch stage, release date, knowledge cutoff: **not stated** on the page.

## Key behaviour

| Spec | Value |
|---|---|
| Context | **1,048,576 tokens, unified input + output** (output includes thinking and function calls) |
| Output per segment | 65,536 streaming / **32,768 non-streaming**; long decodes up to 1M − input via `continuation_token` (v1beta1 only) or `background=true` (Interactions API) |
| Thinking levels | LOW / **MEDIUM (default)** / HIGH. `thinking_budget` or `MINIMAL` → **HTTP 400** |
| Sampling | temperature / top_p / top_k custom values **ignored** |
| Caching | **Implicit only**, ≥ 4,096-token prefix, durable caching on by default; no explicit caching. Prices not on this page |
| Modalities | In: text, image, audio, video, PDF · Out: text |
| Capabilities | Thinking, system instructions, structured output, implicit caching, agentic video ✓ · RAG Engine, tuning ✗ |
| Tools | Function calling, code execution, URL context, computer use, search grounding ✓ (web search is **blocked in PLE Stage 2**) |
| APIs | GenerateContent, Interactions, **Chat Completions (OpenAI-compatible)**, Count Tokens ✓ · Live API ✗ |
| Consumption | Provisioned Throughput, batch, Standard/Priority PayGo ✓ · fixed quota ✗ |

## Input limits

- GenerateContent: 500 MiB compressed · Interactions: 256 MiB (sync/stream), 9.75 MiB uncompressed (deferred)
- ≤ 3,000 images + PDFs per prompt; ≤ 3,000 pages per PDF; up to 6,500 files including plain text
- Per file: 2 GiB − 500 KiB (GCS), 15 MiB (HTTP URL), 256 MB inline part
- Images: PNG, JPEG, WEBP, HEIC, HEIF · Docs: `application/pdf`, `text/plain` · OCR on scanned PDFs **off** by default
- Video ≤ ~45 min with audio (70 tokens/frame) · Audio ≤ ~8.4 h

## Regions

PayGo: global, us, eu · ML processing: us, eu, europe-west2, asia-southeast1 · Provisioned Throughput: + global.
