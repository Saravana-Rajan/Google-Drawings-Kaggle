# Architecture

```
 Evaluator ──WebSocket (JSON frames)──► serve.py ─► taskbridge.run(harness.solve)
     ▲                                                  │  Session (per connection)
     │ exec/read_file/write_file/http results            ▼
     │                                          harness.solve(session)
 Task container                                   │ opens taskbridge.Relay (127.0.0.1 HTTP, random token)
 (workdir e.g. /app,                              │ writes Pi config (models/settings/mcp.json)
  MCP servers, no net)                            ▼
                                         pi --print --mode json -e task-tools.ts  (Node subprocess)
                                           │ model calls ──► HTTPS_PROXY ──► model endpoint
                                           │ read/write/edit/bash ──► POST $TASK_RELAY_URL/{read_file,write_file,exec}
                                           │ MCP tools ──► $TASK_RELAY_URL/mcp/<server>/...
                                           ▼
                                  Relay ─► Session.request(...) ─► WebSocket ─► evaluator ─► task container
```

## Components

- **serve.py** is the entrypoint. It calls `taskbridge.run(harness.solve)`, which runs `serve_forever`: a `websockets` server on `0.0.0.0:$PORT` (default 8765), with `max_size` 16 MiB and pings disabled. Each container handles one connection, which is one task.
- **taskbridge.py** implements the protocol.
  - `_session(ws, handler)`: the first frame must be `{"type":"task", "instruction":...}`. Otherwise the server replies `{"type":"error"}`. It then starts a reader task, the handler task and a cancel watcher.
  - `Session`: `request(kind, **fields)` sends `{type, id, ...}` and waits on the matching `{"type":"result","id"}` frame. Helpers wrap it: `exec`, `read_file` (with chunking), `write_file` (4 MB chunks with `append`), `http`, `log` (one-way, capped at 20k chars) and `usage` (one-way). It also exposes `time_left()`, `workdir`, `mcp_servers`, `final_message` and a `cancelled` event.
  - `Relay`: a local HTTP server on 127.0.0.1 behind a random path token. Routes are `POST /<token>/exec|read_file|write_file`, which forward to the Session, and `/<token>/mcp/<name>/...`, which proxies Streamable-HTTP MCP through the `http` request. GET/SSE returns 405. `relay.env()` sets `TASK_RELAY_URL` and adds localhost to `NO_PROXY`. `relay.mcp_url(name)` gives the per-server URL.
  - `run_process(argv, session, stdin, on_line, stop_before_sec, ...)` starts the agent subprocess. It streams stdout lines to `on_line` and stderr lines to the log. It kills the process group at exit, on cancel, or `stop_before_sec` before the deadline (`time_share` shrinks that reserve on short tasks). It also contains `MCPClient`, a raw HTTP/1.1 request parser and limit constants.
- **harness.py** contains `solve(session)`.
  1. Creates a temp dir under `$HOME` with `agent/` (`PI_CODING_AGENT_DIR`) and `work/` (Pi's local cwd).
  2. `provider()` picks the Pi provider from env. `ANTHROPIC_BASE_URL` selects `anthropic` (anthropic-messages API, `COMPAT` flags off for the Google Cloud Claude route). `GOOGLE_GEMINI_BASE_URL` selects `google` (`/v1beta`). Anything else selects `model` (openai-completions on `MODEL_BASE_URL` + `MODEL_API_KEY`).
  3. `configure()` writes `models.json`. If `pi --offline --list-models` (30 s timeout) doesn't know `MODEL_NAME`, it adds `UNKNOWN_MODEL` limits (128k context, 16,384 max tokens, text only). It also writes `settings.json` (no project trust, cache warming off, 6 retries) and `mcp.json` (each task MCP server pointed at the relay, 300 s timeout).
  4. Runs `pi --print --mode json --no-session -nc -ns -np -na -e task-tools.ts --provider P --model M --thinking max --append-system-prompt NOTE`. The instruction goes on stdin, with `stop_before_sec=90`. Env: `PI_OFFLINE=1`, `PI_TELEMETRY=0`, `PI_SKIP_VERSION_CHECK=1`, `TASK_WORKDIR`.
  5. `Run.on_event` handles Pi's events. On an assistant `message_end` it updates `final_message`, logs model errors, and sends `usage` (input = input + cacheRead + cacheWrite). It logs `tool_execution_start`, `auto_retry_start` and `compaction_start`.
  6. Raises `RuntimeError` if Pi never replied, so the evaluator treats it as not started and retries. Otherwise it returns the last assistant text.
- **task-tools.ts** is a Pi extension that registers four tools.

## Tools exposed to the model

| Tool | Backed by | Notes |
|---|---|---|
| `read` | relay `read_file` | Paths are relative to `TASK_WORKDIR`. Images (.png/.jpg/.jpeg/.gif/.webp) are detected by extension. Over 10 MB it errors and suggests bash. Pi's own `<tmp>/pi-*-<hex>.log` overflow files are read locally |
| `write` | relay `write_file` | The relay creates parent dirs |
| `edit` | relay `read_file` + `write_file` | Pi's edit tool with remote I/O |
| `bash` | relay `exec` | Runs `cd '<cwd>' \|\| exit 1` and then the command. Timeout is `min(timeout, 600)`, or 600 if unset/0. Output over 100 KB is middle-truncated with a notice. An abort only stops the wait; the command runs on |
| MCP tools | Pi `mcp.json` pointing at relay `/mcp/<name>` | Whatever tools the task's `mcp_servers` expose (e.g. an `apps` server; some list hundreds of tools) |

`before_agent_start` sets Pi's system-prompt cwd to `TASK_WORKDIR`. `inTask()` wraps every tool so its context `cwd` is the workdir.

## WebSocket protocol flow (protocol 1)

1. Evaluator sends `{"type":"task","protocol":1,"session","instruction","workdir","limits":{agent_timeout_sec:21600, exec_timeout_sec:600, max_output_bytes:100000, max_write_bytes:10000000},"mcp_servers":[{name,url,transport}]}`.
2. Harness sends requests with unique ids: `exec {command,timeout_sec}`, `read_file {path}`, `write_file {path,content_b64,append}`, `http {method,url,headers,body_b64}`. Up to 8 run concurrently. Each gets back `{"type":"result","id",...}` with `ok`/`error`, `exit_code`/`output`/`truncated`/`timed_out`, `content_b64`/`size`, or `status`/`headers`/`body_b64`.
3. Harness sends one-way `log {text}` and `usage {model,input_tokens,output_tokens,cache_read_tokens}` frames.
4. The task ends with the harness sending `done {final_message}` (capped at 1M chars) or `error {message}`. If the handler raised after a summary existed, taskbridge still sends `done` with that summary.
5. On timeout the evaluator sends `cancel {reason}` and closes the socket 10 s later. taskbridge gives the handler 2 s, then cancels it, waits up to 6 s more, and sends `done` with the best final message (or "(stopped: time is up)").

Limits: 16 MiB per frame, 10 MB per write/http body, 600 s exec cap. More than 20 malformed frames ends the session.

## Environment variables

| Variable | Set by | Used for |
|---|---|---|
| `PORT` | evaluator | WebSocket listen port (`serve_forever`; default 8765) |
| `MODEL_API` | evaluator | full `model_api` string (not read by this harness) |
| `MODEL_NAME` | evaluator | `--model` passed to Pi |
| `MODEL_BASE_URL`, `MODEL_API_KEY` | evaluator | OpenAI-compatible fallback provider `model` |
| `OPENAI_BASE_URL`, `OPENAI_API_KEY` | evaluator | same values as `MODEL_*` (unused here) |
| `ANTHROPIC_BASE_URL`, `ANTHROPIC_API_KEY` | evaluator (Claude) | Pi `anthropic` provider (this entry's path) |
| `GOOGLE_GEMINI_BASE_URL`, `GEMINI_API_KEY` | evaluator (Gemini) | Pi `google` provider |
| `HTTPS_PROXY`/`HTTP_PROXY`/`ALL_PROXY`, `NODE_USE_ENV_PROXY=1` | evaluator | all egress; only the model host is reachable |
| `HOME` | evaluator (tmpfs) | parent of the per-task scratch dir |
| `TASK_RELAY_URL` | `Relay.env()` | where task-tools.ts and MCP calls go |
| `NO_PROXY`/`no_proxy` | `Relay.env()` | localhost is added so the relay bypasses the proxy |
| `TASK_WORKDIR` | harness.py | tool cwd / path root (from `session.workdir`) |
| `PI_CODING_AGENT_DIR`, `PI_OFFLINE`, `PI_SKIP_VERSION_CHECK`, `PI_TELEMETRY`, `NODE_NO_WARNINGS` | harness.py | Pi configuration |

Serve container: uid 1000, read-only `/opt/harness`, 1 GB tmpfs for `/tmp` and `$HOME`, 2 CPU, 4 GB RAM, 512 processes. It must listen within 120 s.
