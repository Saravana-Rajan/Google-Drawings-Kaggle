#!/usr/bin/env bash
# Download the 29 public PLE dev tasks (gated HF dataset) into data/dev-tasks/ (git-ignored).
# Prereqs: accept the terms at https://huggingface.co/datasets/google/physical-engineerings-last-exam
#          then `uvx hf auth login` (or export HF_TOKEN=...).
# The dataset terms forbid redistribution: never commit data/.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data
uvx hf download google/physical-engineerings-last-exam --repo-type dataset --local-dir data/dev-tasks --max-workers 16
echo "Done -> $(pwd)/data/dev-tasks"
