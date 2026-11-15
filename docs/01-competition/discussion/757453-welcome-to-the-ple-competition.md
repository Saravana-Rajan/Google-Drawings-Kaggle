# Welcome to the PLE Competition! (📌 pinned)

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/discussion/757453
Author: Rujun Han (Competition Host) · posted ~Nov 10, 2026 · 4 votes · 11 comments (captured 2026-11-15)

## Original post

PLE was built to test whether AI agents can move beyond textbook benchmarks and tackle realistic, multi-file physical engineering design problems across Mechanical, Electrical, Civil and Structural domains. References: the paper *PLE: Physical-Engineering's Last Exam*, plus Google Cloud Blog and Mercor Blog posts. The host team will follow the forums to answer questions about tasks, the evaluation harness, and submission requirements.

## Key host answers (⭐ = official)

| Question | Answer |
|---|---|
| ⭐ Can the harness run local DL models (e.g. YOLO on CPU) or install free proprietary tools (ODA File Converter DWG→DXF)? Which file formats? | **Arijit Ray (host):** only tools/models that fit the **2 CPU / 4 GB RAM** limits are supported. Possible input file types are listed on **page 10 of the paper**; the dev set has representative examples of all of them. |
| ⭐ Dev-set costs (~$17/task × 29 tasks ≈ $500–750 per run): credits? free trial? partial artifacts? | **Arijit Ray (host):** **no free credits** (too many participants). During the dev phase you **don't need a cloud subscription**: use any LLM subscription you already have, or the listed open-source models. Cloud-hosted models are just options; the description will be updated to make this clear. |
| ⭐ HF dataset form says "I will NOT expose this data to any model/agent while it is being evaluated on PLE". Can I run a dev task with a local Ollama model via `eval/run.py`? | **Rujun Han (host):** **Yes.** Testing PLE on published open-source models is encouraged (also addresses the cost question). |

## Open questions in the thread (unanswered at capture)

- **Rohit:** If `artifacts/` came from a local/personal model while `submission.yaml` declares `google-cloud/X`, how does the Stage 2 live dev re-run judge reproducibility, given scores will differ between models?
- **binhle2410:** `docs/rules.md` says artifacts "must be exported by eval/run.py from the harness you submit, running the model_api declared in submission.yaml" and not "with another model", and `kit check` only accepts google-cloud models. Can artifacts come from a non-listed model (e.g. Gemini 3.5 Flash-Lite on the free AI Studio tier)? Do non-listed models count for the cross-model criterion? *(The Overview was later updated to allow artifacts from local/personal models; see 01-overview.md.)*
- **Seung Gu:** "No purchase required" (Rules C.4a) and the Reasonableness Standard (B.6b) versus paid dev runs. Also asked whether entries with partial dev artifacts are eligible. Partly answered by the host reply above.
- **Dawood Shareef:** Is there an official way to run a sponsored `google-cloud/*` model on the dev tasks without enabling billing (Kaggle-hosted endpoint, participant program)? He passed the local smoke test with Ollama. No host answer.

## Other comments

- **Chris Cotton:** ex-carpenter with Trimble experience turning floor plans/PDFs into accurate layouts (with April tags); thinks the task resembles model-from-drawing plus clash detection.
- **Robina Mirbahar:** thanks; notes the contrast with single-file coding benchmarks (multi-file drawing sets, specs, physical constraints).
