# Sample submissions

Source: `sample_submissions/README.md` and each `sample_submissions/<name>/README.md` + `submission.yaml` in https://github.com/google-research/ple.

Every folder is a complete, working entry. All but `local-model` use a Google-sponsored model and can be submitted. Start new harnesses from `minimal/`. Samples ship **no** pre-generated `artifacts/`.

| Folder | Harness | Default `model_api` | Demonstrates |
|---|---|---|---|
| `minimal/` | Custom (Python) | `google-cloud/gemini-3.8-flash` | Smallest complete harness (<250 LOC), single tool-calling loop |
| `plan-verify/` | Custom (Python) | `google-cloud/claude-opus-5-5` | `minimal` split into planner / worker / verifier with time budgets |
| `node-protocol/` | Custom (JavaScript) | `google-cloud/claude-opus-5-5` | Speaks the WebSocket protocol directly, no `taskbridge.py` |
| `custom-openai/` | Custom (Python) | `google-cloud/gpt-oss-120b` | Full reference harness: MCP tools, streaming, compaction, deadline-aware retries |
| `local-model/` | `custom-openai` | `openai-compatible/gpt-oss-120b` | Same harness on your own GPUs (local runs only, not submittable) |
| `hermes-opus/` | Hermes Agent v0.22.2 | `google-cloud/claude-opus-5-5` | Wraps an existing agent via a terminal-backend plugin |
| `pi-opus/` | Pi 1.1.0 | `google-cloud/claude-opus-5-5` | Wraps a coding agent with a TS extension redirecting tools to the task container |
| `agy-gemini/` | Antigravity CLI 1.4.10 | `google-cloud/gemini-3.8-flash` | Wraps a closed-source CLI agent through an MCP server |

## How to run any sample

```bash
# from the root of the ple clone
uv tool install harbor==0.20.0 --with websockets
export HF_TOKEN=<read token>
cp -r sample_submissions/<sample> ../my-harness && git -C ../my-harness init -q
gcloud auth application-default login
export VERTEXAI_PROJECT=<gcp-project> MODEL_PROXY_KEY=$(openssl rand -hex 24)
kit/model_proxy/start.sh &
export MODEL_PROXY_URL=http://localhost:4000
uv run python -m kit check ../my-harness
uv run python eval/run.py ../my-harness          # writes ../my-harness/artifacts/
git -C ../my-harness add -A && git -C ../my-harness commit -m "harness and dev artifacts"
uv run python -m kit check ../my-harness         # expect "ready to submit"
```

**Changing the model:** edit `model_api`. `minimal`, `plan-verify`, `node-protocol`, `custom-openai`, `local-model` use the OpenAI-compatible endpoint, so they work with any model (lower `MAX_OUTPUT_TOKENS`, default 32000, for small-context models). `hermes-opus` and `pi-opus` support any model (native Anthropic API for Claude; `pi-opus` native Gemini API for Gemini). `agy-gemini` is Gemini-only. Every sample requests the highest reasoning level (`max` for Claude/GLM, `high` for Gemini and others; knobs: `AGY_EFFORT` in agy-gemini, `THINKING` in pi-opus, `REASONING_EFFORT` env elsewhere). Always generate `artifacts/` with the exact `model_api` you submit.

## Shared `taskbridge.py` (Python samples)

Each Python sample carries its own copy of `sample_submissions/taskbridge.py`:

| API | Description |
|---|---|
| `run(solve)` | WebSocket server on `$PORT`; calls `solve(session)` per task; return string becomes `final_message` |
| `Session.instruction`, `.workdir`, `.limits`, `.mcp_servers` | From the `task` message |
| `Session.exec(command, timeout_sec=120)` | `bash -c` in the task container -> `exit_code`, `output`, `truncated`, `timed_out` |
| `Session.read_file(path)`, `Session.write_file(path, data, append=False)` | Read (≤10 MB) bytes / write str or bytes (auto-chunked) |
| `Session.http(url, method, headers, body)` | HTTP to a task MCP server from inside the task container |
| `Session.log(text)`, `Session.usage(model, input_tokens, output_tokens, cache_read_tokens)` | One-way messages |
| `Session.time_left()` | Remaining seconds or `None` |
| `Session.final_message` | Fallback final message on cancel/exception |
| `Cancelled`, `TaskError` | Cancellation (taskbridge then sends `done`), `ok:false`/malformed-request error |
| `Relay(session)` | Local HTTP bridge for subprocess agents (`relay.env()`, `relay.mcp_url(name)`) |
| `MCPClient(session, url)` | `initialize()`, `list_tools()`, `call_tool(name, arguments)` |
| `run_process(argv, session, on_line=...)` | Runs an agent subprocess, streams stdout, stops it before deadline |

---

## minimal

- **Model:** `google-cloud/gemini-3.8-flash`.
- **Approach:** `solve(session)` in `serve.py` is the whole loop: concise system prompt + instruction + three tools (`bash`, `read_file`, `write_file`) executed via `session.exec/read_file/write_file`; tool results carry remaining minutes. A tool-less reply becomes `final_message`; empty/truncated replies get nudged (`MAX_NUDGES = 3`) and concatenated. `WRAP_UP_SEC` = 4 min before deadline: cancel in-flight call and ask for summary with `tool_choice="none"`. Retries 429/5xx/dropped connections with `RETRY_WAITS` (5 s – 2 min); on 400 context-length, trims older half of long tool outputs to 1,000 chars (`CUT_KEEP`). Updates `session.final_message` on every text reply; reports usage; preserves provider fields via `model_dump()`. Omits MCP (kit check warns at `mcp`), streaming, and compaction.
- **Files:** `serve.py`, `taskbridge.py`, `requirements.txt` (pinned `openai`, `websockets`), `submission.yaml`.
- **submission.yaml:**
  ```yaml
  name: minimal
  model_api: google-cloud/gemini-3.8-flash
  install: >-
    uv venv --python 3.12 /opt/harness/venv
    && uv pip install --python /opt/harness/venv/bin/python -r {src}/requirements.txt
  serve: /opt/harness/venv/bin/python {src}/serve.py
  ```
- **Run:** standard flow. Local without GCP: `model_api: gemini/gemini-3.8-flash` + `GEMINI_API_KEY` (local only).

## plan-verify

- **Model:** `google-cloud/claude-opus-5-5`.
- **Approach:** `agent()` wraps minimal's loop (retries, overflow trimming) with a message history, tool list, and step deadline. `solve()` runs: (1) **Planner** (`bash`, `read_file`) explores and writes a structured plan (deliverables, paths/formats, method, verification); (2) **Worker** (`bash`, `read_file`, `write_file`) produces deliverables and the summary; (3) **Verifier** (`bash`, `read_file`) in a fresh conversation (instruction + plan + worker summary only) replies `PASS` or numbered issues, fed back for fix rounds (max two verify-and-fix rounds). Time budget: planner until 10% used (`PLAN_SHARE`), worker until 25% remains (`CHECK_SHARE`), verifier until 12.5% remains, fix round until 4 min remain (`WRAP_UP_SEC`); steps skipped if < 2 min (`MIN_STEP_SEC`). No MCP.
- **Files:** `serve.py` (roles `PLANNER`, `WORKER`, `VERIFIER` prompts at top), `taskbridge.py`, `requirements.txt`, `submission.yaml`. `diff -u ../minimal/serve.py serve.py` shows the delta.
- **submission.yaml:** same `install`/`serve` as minimal; `name: plan-verify`, `model_api: google-cloud/claude-opus-5-5`.
- **Run:** standard flow. Reads `OPENAI_BASE_URL`, `OPENAI_API_KEY`, `MODEL_NAME`, `MAX_OUTPUT_TOKENS`.

## node-protocol

- **Model:** `google-cloud/claude-opus-5-5` via plain `fetch` on the OpenAI-compatible endpoint.
- **Approach:** single-file `serve.mjs` implementing the protocol directly (no taskbridge, no SDK). Loop mirrors minimal (3 tools, remaining minutes, summary 4 min before deadline, `MAX_OUTPUT_TOKENS` 32000). Incrementing request ids resolved on `result`; validates outgoing requests (empty path/command, NUL, surrogates) to avoid malformed-frame penalties; caps incoming frames at 16 MiB. Streams SSE, preserves `reasoning_content`, Gemini thought signatures, Claude `thinking_blocks`. Uses pinned `undici` fetch with 30-min idle timeout (`MODEL_IDLE_SEC`) via `HTTPS_PROXY`. On `cancel`/close: abort fetch, reject pending, send `done` within 10 s grace. Retries 408/409/429/5xx etc. with `RETRY_WAITS`; context-full 400 trims via `CUT_KEEP`. No MCP.
- **Files:** `serve.mjs`, `package.json`, `package-lock.json` (pinned `ws`, `undici`), `submission.yaml`.
- **submission.yaml:**
  ```yaml
  name: node-protocol
  model_api: google-cloud/claude-opus-5-5
  install: cd {src} && npm ci --omit=dev --no-audit --no-fund
  serve: node {src}/serve.mjs
  ```
- **Run on host:** `npm ci && PORT=8765 MODEL_NAME=claude-opus-5-5 MODEL_BASE_URL=http://localhost:4000/v1 MODEL_API_KEY=$MODEL_PROXY_KEY node serve.mjs`, then `uv run python eval/run.py --url ws://127.0.0.1:8765 --name node-protocol --tasks data-center-site-model --env-file local.env`.

## custom-openai

- **Model:** `google-cloud/gpt-oss-120b` (any model; GPT-6 locally via Responses API).
- **Approach:** most complete reference harness. Tools: `bash`, `read_file`, `write_file` (append), `edit_file` (exact replace). MCP: small catalogs (≤128 tools, <40,000 chars schema) exposed directly; larger ones via `mcp_find` + `mcp_call`. All calls streamed; continuation/stitching of truncated replies. Caps bash timeouts before wrap-up; 3 min before deadline interrupts and requests summary. Preserves Gemini signatures / Claude signed thinking; Claude `cache_control` on system + newest message. Retries up to 5x with `RETRY_WAITS`; falls back from `max_completion_tokens` to `max_tokens`. Compaction: head/tail truncation of big outputs; past `COMPACT_AT_TOKENS` (or context error) trims old tool outputs, then summarizes older turns into notes.
- **Env knobs:** `MAX_OUTPUT_TOKENS` (32000), `COMPACT_AT_TOKENS` (150000; sample sets 90000), `REASONING_EFFORT` (model's highest).
- **Files:** `serve.py`, `taskbridge.py`, `requirements.txt`, `submission.yaml`.
- **submission.yaml:**
  ```yaml
  name: custom-openai
  model_api: google-cloud/gpt-oss-120b
  install: >-
    uv venv --python 3.12 /opt/harness/venv
    && uv pip install --python /opt/harness/venv/bin/python -r {src}/requirements.txt
  serve: /opt/harness/venv/bin/python {src}/serve.py
  env:
    COMPACT_AT_TOKENS: "90000"
  ```
- **Run on host:** `python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`; `MODEL_BASE_URL=http://localhost:4000/v1 MODEL_API_KEY=$MODEL_PROXY_KEY MODEL_NAME=gpt-oss-120b PORT=8765 .venv/bin/python serve.py`; then `eval/run.py --url ws://127.0.0.1:8765 --name custom-openai --tasks data-center-site-model`.

## local-model (local runs only)

- **Model:** `openai-compatible/gpt-oss-120b` served from your GPUs (vLLM shown; SGLang, llama.cpp, Ollama in `docs-local-models.md`). Not submittable.
- **Approach:** `custom-openai`'s `serve.py` + `taskbridge.py` unchanged, behind a Caddy auth gate that checks `MODEL_API_KEY`.
- **Files:** `submission.yaml`, `local.env.example`, `host/Caddyfile` (forwards `/v1/...` with key, else 401), `host/cloudflared.yml` (Cloudflare Tunnel for a gate behind NAT), plus `serve.py`, `taskbridge.py`, `requirements.txt`.
- **submission.yaml:**
  ```yaml
  name: local-model
  model_api: openai-compatible/gpt-oss-120b
  model_base_url: https://llm.example.org/v1
  install: >-
    uv venv --python 3.12 /opt/harness/venv
    && uv pip install --python /opt/harness/venv/bin/python -r {src}/requirements.txt
  serve: /opt/harness/venv/bin/python {src}/serve.py
  env:
    MAX_OUTPUT_TOKENS: "16000"
    COMPACT_AT_TOKENS: "90000"
  ```
- **Run:**
  ```bash
  vllm serve openai/gpt-oss-120b --served-model-name gpt-oss-120b --host 127.0.0.1 --port 8000 \
    --enable-auto-tool-choice --tool-call-parser openai --reasoning-parser openai_gptoss
  export MODEL_API_KEY=$(openssl rand -hex 24); echo "MODEL_API_KEY=$MODEL_API_KEY" >> <ple clone>/local.env
  caddy run --config host/Caddyfile
  uv run python -m kit check ../my-harness --env-file local.env --model-base-url http://localhost:8090/v1
  uv run python eval/run.py ../my-harness --env-file local.env --model-base-url http://localhost:8090/v1
  ```

## hermes-opus

- **Model:** `google-cloud/claude-opus-5-5` (native Anthropic provider for Claude; OpenAI-compatible for others).
- **Approach:** per task, `serve.py` creates an isolated Hermes home with `config.yaml` + `task_env` plugin, starts a `taskbridge.Relay`, runs `hermes chat --query-file <instruction> --format stream-json` with `--run-budget` so the 80% wrap-up notice arrives `BUDGET_MARGIN_SEC` before deadline; returns final response as `final_message`, logs usage. `task_env/` is a terminal backend executing every shell command (and thus Hermes file tools) in the task container. Task MCP servers registered via relay URLs. Disabled toolsets: `web`, `browser`, `vision`, `image_gen`, `clarify`, etc. `thinking_patch.py` (install time) makes Hermes keep signed thinking blocks on the gateway; compression summaries routed via `MODEL_BASE_URL`. 1-h request / 30-min stream-idle timeouts; highest effort.
- **Tunables in serve.py:** `MAX_TURNS` (500), `BUDGET_MARGIN_SEC`, `AUX_TIMEOUT_SEC`, `REQUEST_TIMEOUT_SEC`, `STREAM_IDLE_SEC`, `DISABLED_TOOLSETS`.
- **Files:** `submission.yaml`, `thinking_patch.py`, `serve.py`, `task_env/` (`plugin.yaml`, `__init__.py`), `taskbridge.py`.
- **submission.yaml:**
  ```yaml
  name: hermes-opus
  model_api: google-cloud/claude-opus-5-5
  install: >-
    git clone --depth 1 --branch v0.22.2 https://github.com/NousResearch/hermes-agent /opt/harness/hermes
    && test "$(git -C /opt/harness/hermes rev-parse HEAD)" = d923a5eb487a17c0a68801bba9ef0f56c81040a8
    && rm -rf /opt/harness/hermes/.git /opt/harness/hermes/tests /opt/harness/hermes/website
    && cd /opt/harness/hermes
    && UV_PROJECT_ENVIRONMENT=/opt/harness/venv UV_COMPILE_BYTECODE=1
    uv sync --locked --no-dev --extra anthropic --extra mcp --python 3.14
    && /opt/harness/venv/bin/python {src}/thinking_patch.py /opt/harness/hermes
    && /opt/harness/venv/bin/python -m compileall -q -j 0 /opt/harness/hermes
  serve: /opt/harness/venv/bin/python {src}/serve.py
  ```
- **Run:** standard flow.

## pi-opus

- **Model:** `google-cloud/claude-opus-5-5` (Claude via Pi `anthropic` provider, Gemini via `google` provider; others fall back to `UNKNOWN_MODEL` — 128k ctx, 16k out, text-only; for Gemini 4 Argon set 1,048,576 / 65,536 and leave `reasoning` unset).
- **Approach:** `serve.py` = `taskbridge.run(harness.solve)`. Per task `harness.py` starts a `Relay`, writes `models.json`, `settings.json`, `mcp.json` (task MCP relay URLs), runs `pi --print --mode json` with the instruction on stdin, streams events into `log`/`usage`, returns final answer. `task-tools.ts` overrides Pi's `read`, `write`, `edit`, `bash` to run in the task container (Pi `grep`/`find`/`ls` disabled). bash up to 600 s; remaining minutes appended to the system prompt; Pi stopped 90 s before deadline; retries up to 8 times over ~4 min; 1-h silent-stream allowance; keeps Claude cache warm.
- **Tunables in harness.py:** `NOTE`, `TIME_NOTE`, `THINKING` (`off`..`max`, default `max`), `SETTINGS`, `UNKNOWN_MODEL`, extra `-e` extensions.
- **Files:** `submission.yaml`, `package.json`, `package-lock.json` (Pi `@earendil-works/pi-coding-agent` 1.1.0), `serve.py`, `harness.py`, `task-tools.ts`, `taskbridge.py`, `requirements.txt`.
- **submission.yaml:**
  ```yaml
  name: pi-opus
  model_api: google-cloud/claude-opus-5-5
  install: >-
    npm ci --prefix {src} --no-fund --no-audit
    && uv venv --python 3.12 /opt/harness/venv
    && uv pip install --python /opt/harness/venv/bin/python -r {src}/requirements.txt
  serve: /opt/harness/venv/bin/python {src}/serve.py
  ```
- **Run:** standard flow (this is the Quick-start example in the root README). Upgrade Pi: bump `package.json`, `npm install --package-lock-only`, commit both.

## agy-gemini

- **Model:** `google-cloud/gemini-3.8-flash` (Gemini-only; can switch to `gemini-4-argon`, `gemini-3.1-pro-preview`, or local `gemini/<model>`).
- **Approach:** per task `serve.py` spawns `agy -p` headless with built-in tools disabled (`tools: []`); `task_mcp.py` is a stdio MCP server exposing `shell`, `read_file` (images returned as MCP image blocks), `write_file`, `edit_file` backed by the task container via `taskbridge.Relay`. Task MCP servers proxied via `Relay.mcp_url`, all registered `"eager": true` with tool lists pre-fetched. `agy` reads `GEMINI_API_KEY` / `GOOGLE_GEMINI_BASE_URL`. Final text from `--output-format stream-json` -> `final_message`. On 40-min stall, lost connection, or rate limit (wait `60s * attempt`) resumes with `--conversation`, up to 4 attempts. Telemetry and auto-update disabled. Non-built-in models registered as `<model>-byom` with context budget `max(W - 70000, W/2 + 70000)` (`AGY_CONTEXT_WINDOW` W, default 1048576). ~300–400 MB RAM per session.
- **Env knobs:** `AGY_EFFORT` (`low`/`medium`/`high`, default high), `AGY_MODEL`, `AGY_CONTEXT_WINDOW`.
- **Files:** `submission.yaml`, `install.sh` (downloads pinned agy 1.4.10 with SHA-512 check, creates venv), `serve.py`, `task_mcp.py`, `taskbridge.py`, `requirements.txt`.
- **submission.yaml:**
  ```yaml
  name: agy-gemini
  model_api: google-cloud/gemini-3.8-flash
  install: bash {src}/install.sh
  serve: /opt/harness/venv/bin/python {src}/serve.py
  env:
    AGY_EFFORT: "high"
  ```
- **Run:** standard flow (requires `kit/model_proxy` serving the native Gemini API).
