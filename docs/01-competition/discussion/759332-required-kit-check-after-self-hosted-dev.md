# Required kit check after self-hosted development, before Stage 2 access

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/discussion/759332
Author: moruku36 · posted Nov 15, 2026 · 1 comment (captured 2026-11-15)

## Question

- The Overview allows dev artifacts generated with a **self-hosted model**, followed by switching `submission.yaml` to an eligible Google-sponsored model; `kit check` and `kit artifacts` are still required.
- In the public kit, a local-model entry is labelled **own-model / not ready**, while checking a `google-cloud` declaration **requires a model proxy**. The documented local Vertex proxy is billed to the participant's project, and sponsored Stage 2 access appears conditional on selection.
- Questions:
  1. What is the intended way to satisfy the final kit-check requirement **without paid model API calls** before Stage 2 selection?
  2. Is a successful self-hosted runtime check + genuine unchanged artifacts + a disclosed declaration switch sufficient, or is there a separate sponsored validation route? What kit-check output should participants provide?
  3. Is a **CPU-only Docker dev run with a self-hosted model** acceptable, given authorized access to the gated dev tasks and disclosure of the actual model and judge?
- References:
  - https://github.com/google-research/ple/blob/8320f0402fdca9f42476607f72bcfd5271cd50c9/docs/models.md
  - https://github.com/google-research/ple/blob/8320f0402fdca9f42476607f72bcfd5271cd50c9/kit/check.py#L990-L1006

## Comments

- **Navneet:** thanks for the overview (no host answer yet).

> Status: **unanswered by hosts** at capture time. Worth watching; it decides how to pass `kit check` without a billed Vertex proxy.
