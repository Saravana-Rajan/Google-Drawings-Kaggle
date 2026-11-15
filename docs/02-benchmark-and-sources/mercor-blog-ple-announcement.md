# Introducing Physical-Engineering's Last Exam (PLE) with Google Cloud AI Research

Source: https://www.mercor.com/blog/introducing-physical-engineering-s-last-exam-ple-with-google-cloud-ai-research/

- Date: Nov 3, 2026 (Research category)
- Authors: Michael Bennett, Ricardo Haegler Pilnik, Vaibhav Mittal
- Retrieval note: fetched via WebFetch, which returns an AI-processed rendering of the page and not the raw HTML. The figures below are as that tool reported them.

## Overview
Mercor and Google's AI & Infrastructure research team released PLE, a benchmark of **85 long-horizon tasks** in mechanical, electrical, civil and structural engineering. Licensed engineers from Mercor's expert network wrote or validated each task. Every task runs in an environment built on Mercor's open-source **Archipelago** framework. The best configuration was **Claude Opus 5.5 running in Claude Code**, which scored **48.3%** on the hidden test set. It averaged about **27M tokens and 63 minutes per task**.

## Disciplines
| Discipline | Tasks | Example task |
|---|---|---|
| Mechanical | 30 | Cooling loop plus a clash-free 3D equipment hall |
| Electrical | 27 | Size a switchboard and its cable schedule |
| Civil | 18 | Full campus layout, including grading and utilities |
| Structural | 10 | Roof deck design |

The post argues that strength in one discipline does not transfer to another, because each has its own codes, conventions and failure modes.

## Task creation
- **44 tasks written by experts:** licensed engineers built the project folder, the prompt and the grading rubric.
- **41 tasks built by Google:** made in an adversarial loop. A Creator agent drafts a task, a Solver agent tries to break it, and the Creator hardens it.
- Engineers validated all 85 tasks.

## Environment
- Each task runs in a containerized project folder of about **61 files**. These include PDFs, spreadsheets, emails, 2D CAD drawings, 3D BIM models, and outdated revisions planted as traps.
- The agent has **no internet access** and up to **6 hours**. It must find the governing codes, run the calculations and deliver a design.

## Grading
- An agent earns cost-efficiency points only after its design passes **every hard safety and feasibility check**.
- The top agent met **91%** of individual constraints on average, but cleared every hard check in only **41%** of tasks.

## Results (mean score on the 56-task hidden test set, updated Oct 23, 2026)
Each model ran in its native harness or in its best-performing harness.

| Model | Score |
|---|---|
| Claude Opus 5.5 | 48.3% |
| GPT 6 Astra | 45.8% |
| Claude Sonnet 5.5 | 43.5% |
| Gemini 4 Argon | 40.6% |
| Claude Opus 5 | 40.0% |
| Claude Fable 5 | 34.5% |
| Grok 4.7 | 30.1% |
| Gemini 3.8 Flash | 27.5% |
| GLM 5.2 | 25.0% |
| DeepSeek-V4.1-Flash | 14.4% |
| Gemini 3.1 Pro | 13.8% |
| Qwen3 Coder 480B | 6.2% |
| Kimi K2 Thinking | 6.2% |
| MiniMax M2 | 5.7% |
| Qwen3-Next 80B | 4.3% |
| Gemma 4 26B | 4.2% |
| gpt-oss 120B | 3.8% |
| Llama 4 Maverick | 0.7% |

- The post says it evaluated **14 frontier models across 7 agent harnesses**. The table above has 18 rows. This is an inconsistency in the source as fetched; it was not resolved.
- The choice of model matters more than the choice of harness. Scores span up to about **50 points** across models. Running the same model on different harnesses changes its score by a median of about **3 points**.
- **Figure:** a bar chart titled "Physical-Engineering's Last Exam (PLE)" shows the scores above. Its headline is that no frontier model clears 50%. Image: https://cdn.sanity.io/images/h6s14f4z/production/27594fd42f5c61d4980ecf4b2c30ac3de463c896-3840x2160.png (source: ple-bench.com).

## Open participation
- Google released **29 public tasks**, the grading tools and the evaluation container.
- An open competition runs on the hidden test set. **13 Google-sponsored models** can be run for free. Prizes are still to be announced.
- Readers can also contribute a task through ple-bench.com.

## Outbound links
Content:
- PLE / contribute a task: https://ple-bench.com/
- Google's blog post: https://cloud.google.com/blog/products/ai-machine-learning/introducing-physical-engineerings-last-exam-for-agents
- Chart image: https://cdn.sanity.io/images/h6s14f4z/production/27594fd42f5c61d4980ecf4b2c30ac3de463c896-3840x2160.png

Navigation and footer (relative links are on mercor.com):
- / , /apex/ , /enterprise/ , /experts/ , /mission/ , /partner/ , /blog/ , /blog/?category=research
- https://work.mercor.com/login , https://work.mercor.com/explore , https://talent.docs.mercor.com/
- /resources/ , /stories/ , /apex/apex-agents-leaderboard/ , /apex/apex-accounting-leaderboard/ , /apex/apex-swe-leaderboard/ , /apex/off-the-shelf-data/ , /research/labor-index/benchmark-map/
- /enterprise-evals/ , /data/ , /robotics/ , /careers/ , https://trust.mercor.com , /newsroom/
- /terms-of-service/ , /privacy-notice/ , /images/footer/privacyoptions.svg
- https://twitter.com/mercor , https://www.youtube.com/@mercor-ai , https://www.linkedin.com/company/mercor-ai/ , https://www.instagram.com/mercor_ai/
