# Request for a Pre-Submission Test Server / Dry-Run Harness Evaluation?

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/discussion/759201
Author: hengck23 · posted Nov 14, 2026 · 0 comments (captured 2026-11-15)

## Request

Entries are a GitHub repo plus a pinned commit SHA. A submission can pass the local `kit check` and the 29-task dev runs yet still fail in the official Stage 2 infrastructure: dependency installation, container resource limits, MCP connectivity, or WebSocket protocol errors.

The author asks for a dry-run service that:
1. Clones the repo at a given commit SHA.
2. Runs the official install and smoke test in the same container environment as Stage 2.
3. Executes 1–2 public dev tasks end to end.
4. Returns diagnostic logs for install, startup, protocol, or runtime failures.

The request excludes access to the hidden tasks and their scores.

> Status: unanswered at capture. **Takeaway:** reproduce the Stage 2 environment locally yourself: `debian:bookworm` install within 30 min, `/opt/harness` ≤ 2 GiB compressed, 2 CPU / 4 GB RAM, serve binding `0.0.0.0:$PORT` within 120 s.
