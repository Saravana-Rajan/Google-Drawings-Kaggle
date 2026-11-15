# google-research/ple — notes

Reference notes on https://github.com/google-research/ple (local clone: `../google-research-ple-src`). Apache-2.0 (code); `pyproject.toml` declares `Apache-2.0 AND CC-BY-4.0`. Python package name `plebench` 0.1.0, Python >= 3.10, deps: `pyyaml`, `websockets`, `python-dotenv`, `huggingface-hub>=1.31,<2`.

## What it is

**Physical-Engineering's Last Exam (PLE)** is an 85-task benchmark of real-world engineering work (structural 10, civil 18, electrical 27, mechanical 30). Each task runs in an isolated container and asks for a project deliverable (calculation package, design review, drawing, memo), graded 0–1 by automated checks, an LLM rubric judge, or both.

In the **PLE competition**, an entry is a single GitHub commit containing:

1. a **harness** — a WebSocket server (any language) that drives a model through each task,
2. `submission.yaml` declaring one of the 8 Google-sponsored `google-cloud/<id>` **models** (no API keys in the repo),
3. the **`artifacts/`** it produced on the **29 public dev tasks**, exported by `eval/run.py`.

Ranking is on **56 hidden test tasks**; submission mechanics and dates "will be announced" on https://ple-bench.com.

## Files in this folder

| File | Contents |
|---|---|
| `README.md` | This overview, directory tree, quickstart, external links |
| `docs-rules.md` | Verbatim `docs/rules.md` — dev/test sets, entries, scoring formula, fair play |
| `docs-protocol.md` | Verbatim `docs/protocol.md` — WebSocket serve protocol v1 |
| `docs-models.md` | Verbatim `docs/models.md` — the 8 models, env vars, local proxy, model tips |
| `docs-artifacts.md` | Verbatim `docs/artifacts.md` — `artifacts/` layout, limits, refusal/warning rules, manifest |
| `docs-local-models.md` | Verbatim `docs/local-models.md` — serving your own model (vLLM/SGLang/llama.cpp/Ollama) |
| `kit.md` | The kit: commands, `kit check` stages, `kit artifacts` rules, container contract, protocol limits |
| `eval.md` | `eval/run.py` usage/flags, output layout, grading, full 29-task dev-set table |
| `sample-submissions.md` | All 8 samples: approach, model, files, submission.yaml, how to run |
| `submission-yaml-spec.md` | Every `submission.yaml` field and allowed value (from `kit/spec.py`, `kit/models.py`) |

## Repository tree

```
ple/
├── README.md, LICENSE, CONTRIBUTING.md, CODE_OF_CONDUCT.md, pyproject.toml
├── docs/
│   ├── rules.md            rules and scoring
│   ├── protocol.md         serve protocol v1
│   ├── models.md           models and runtime env vars
│   ├── artifacts.md        dev-set artifacts
│   └── local-models.md     running on a model you serve
├── kit/                    submission kit: `uv run python -m kit <cmd>`
│   ├── README.md
│   ├── __main__.py         CLI (check, validate, build, up, artifacts, models)
│   ├── spec.py             submission.yaml validation
│   ├── models.py           model catalog and env injection
│   ├── protocol.py         protocol limits and frame validation
│   ├── check.py, build.py, stack.py, egress.py, relay.py, capture.py
│   ├── artifacts.py, export.py
│   ├── harbor_agent.py, harbor_docker.py, replay_agent.py
│   ├── builder/Dockerfile  debian:bookworm + uv + Node 22 builder image
│   ├── compose/            egress proxy (gost) compose files
│   └── model_proxy/        start.sh, config.yaml (LiteLLM on Vertex AI), effort_default.py, judge_fallback.py
├── eval/
│   ├── README.md
│   ├── run.py              run/grade/export the dev set via Harbor
│   └── dev_set.yaml        29 dev tasks (HF dataset google/physical-engineerings-last-exam)
└── sample_submissions/
    ├── README.md
    ├── taskbridge.py       shared Python implementation of the protocol
    ├── minimal/            Python, gemini-3.8-flash
    ├── plan-verify/        Python, claude-opus-5-5
    ├── node-protocol/      JavaScript, claude-opus-5-5
    ├── custom-openai/      Python, gpt-oss-120b
    ├── local-model/        custom-openai on openai-compatible/gpt-oss-120b (local only)
    ├── hermes-opus/        Hermes Agent v0.22.2, claude-opus-5-5
    ├── pi-opus/            Pi 1.1.0, claude-opus-5-5
    └── agy-gemini/         Antigravity CLI 1.4.10, gemini-3.8-flash
```

## Quickstart

Requirements: Docker, uv, a Google Cloud project (Vertex AI) for the local model proxy, and a Hugging Face read token with access to the gated dataset.

```bash
# 1. Install Harbor (runs the dev tasks; the kit's agent needs websockets)
uv tool install harbor==0.20.0 --with websockets
export HF_TOKEN=<your Hugging Face read token>

# 2. Copy a starter entry into its own Git repository outside the clone
cp -r sample_submissions/pi-opus ../my-harness
git -C ../my-harness init -q

# 3. Start the local proxy for the google-cloud models (billed to your GCP project)
gcloud auth application-default login
export VERTEXAI_PROJECT=<your-gcp-project> MODEL_PROXY_KEY=$(openssl rand -hex 24)
kit/model_proxy/start.sh &
export MODEL_PROXY_URL=http://localhost:4000

# 4. Build, start, test the model, run smoke and MCP checks
uv run python -m kit check ../my-harness

# 5. Run and score the dev set; writes ../my-harness/artifacts/
uv run python eval/run.py ../my-harness

# Before you submit
git -C ../my-harness add -A && git -C ../my-harness commit -m "harness and dev artifacts"
uv run python -m kit check ../my-harness      # must end with "ready to submit"
# push the commit to a GitHub repository (submission details TBA on ple-bench.com)
```

## How an entry runs

```
 your server (serve.py)  <---- websocket ---->  evaluator  ---- runs your requests ---->  task container
         |                                                                                (project files,
         +---- egress proxy ----> your model's API, and no other host                      no network)
```

Per task (up to 6 h) the evaluator sends the task over the WebSocket; the harness issues `exec` / `read_file` / `write_file` / `http` (task MCP servers: documents, spreadsheets, email, CAD) requests and ends with `done` + `final_message`.

## External links

Found in the repo's Markdown docs and READMEs (excluding npm lockfile registry URLs, shields.io badge images, and localhost/placeholder URLs):

- Competition site and leaderboard: https://ple-bench.com
- Paper (arXiv 2610.30537): https://arxiv.org/abs/2610.30537
- Dev-set dataset (gated): https://huggingface.co/datasets/google/physical-engineerings-last-exam
- Hugging Face tokens: https://huggingface.co/settings/tokens
- Docker install: https://docs.docker.com/engine/install/
- uv: https://docs.astral.sh/uv/
- Hermes Agent: https://github.com/NousResearch/hermes-agent
- Pi (pi-mono): https://github.com/badlogic/pi-mono
- Antigravity CLI: https://antigravity.google/product/antigravity-cli
- Antigravity CLI docs: https://antigravity.google/docs/cli/overview
- Antigravity CLI binary (pinned in agy-gemini `install.sh`): https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.10-5501573669978112/linux-x64/cli_linux_x64.tar.gz
- vLLM: https://docs.vllm.ai
- SGLang: https://docs.sglang.io
- llama.cpp server: https://github.com/ggml-org/llama.cpp/tree/master/tools/server
- Ollama: https://docs.ollama.com
- Caddy: https://caddyserver.com
- Cloudflare Tunnel: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/
- Anthropic API (own-model local runs): https://api.anthropic.com
- Google AI Studio / Gemini API (own-model local runs): https://generativelanguage.googleapis.com
- Google OSS Vulnerability Rewards Program: https://bughunters.google.com/open-source-security
- Apache License 2.0: http://www.apache.org/licenses/LICENSE-2.0
