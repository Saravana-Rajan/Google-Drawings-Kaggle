# Guide | Physical-Engineering’s Last Exam

Source: https://ple-bench.com/competition/guide

# Guide

Build a harness server (`serve.py`) with its `submission.yaml`, check it with
the kit, and run it on the public dev set. Entries are submitted on [Kaggle](https://www.kaggle.com/competitions/physical-engineerings-last-exam).

## How to start

1. ### Copy a sample

   The
   competition repository includes working samples, the validation kit, and the dev set. Copy a
   sample into its own git repository (for example, `../my-harness`).
2. ### Check it

   Run `python -m kit check ../my-harness` to test your container and smoke task. It
   requires Docker.
3. ### Run the dev set

   Run `eval/run.py ../my-harness` to run your harness on the public dev set, score it
   with the dev-set graders, and write `artifacts/`.

Using a coding agent? Point it to the [instructions for coding agents](https://ple-bench.com/competition/agents).

## Your repository

```
submission.yaml    entry name, model_api, and your install and serve commands
serve.py           WebSocket server started by serve for each task
harness.py         your agent loop, or a wrapper around an existing agent
artifacts/         dev-set outputs and manifest written by eval/run.py
```

This layout matches the `pi-opus` sample. Smaller entries like `minimal`
keep the entire loop in `serve.py`.

### submission.yaml

```
name: my-harness                          # entry name
model_api: google-cloud/claude-opus-5-5   # see Models below
install: >-                               # runs once at image build time (as root, with internet)
  uv venv --python 3.12 /opt/harness/venv
  && uv pip install --python /opt/harness/venv/bin/python -r {src}/requirements.txt
serve: /opt/harness/venv/bin/python {src}/serve.py    # starts your server on $PORT
env:                                      # non-sensitive settings, quoted as strings (optional)
  LOG_LEVEL: "info"
```

`{src}` expands to `/opt/harness/src` and `{port}` to
`$PORT`. Only `/opt/harness` is kept after the build step, and runtime package downloads are
blocked.

## Models

Entries run on Google sponsored models only; your own API keys and model servers are not accepted. The evaluator
supplies the key. Set `model_api` to one of these models:

* `google-cloud/gemini-4-argon`: Gemini 4 Argon
* `google-cloud/gemini-3.8-flash`: Gemini 3.8 Flash
* `google-cloud/gemini-3.1-pro-preview`: Gemini 3.1 Pro (preview)
* `google-cloud/claude-opus-5-5`: Claude Opus 5.5
* `google-cloud/gpt-oss-120b`: gpt-oss 120B
* `google-cloud/glm-5.2`: GLM 5.2
* `google-cloud/gemma-4-26b`: Gemma 4 26B A4B
* `google-cloud/llama-4-maverick`: Llama 4 Maverick 17B 128E

## Dev-set artifacts

`eval/run.py`
writes and hashes this folder automatically; do not edit it by hand.

```
uv run python eval/run.py ../my-harness              # runs the dev set, writes ../my-harness/artifacts/
uv run python -m kit artifacts ../my-harness         # checks the folder with the evaluator's rules
uv run python eval/run.py --artifacts ../my-harness  # grades the folder as the evaluator does (calls only the judge)
```

See `docs/artifacts.md` for the folder's full validation rules.

## What your server receives

| Variable | Value |
| --- | --- |
| `PORT` | TCP port your WebSocket server listens on |
| `MODEL_API`, `MODEL_NAME` | Your `model_api` string and the model name to pass in API requests |
| `MODEL_BASE_URL`, `MODEL_API_KEY` | OpenAI-compatible base URL and key, set for every model (also mirrored as `OPENAI_BASE_URL` and `OPENAI_API_KEY`) |
| `ANTHROPIC_BASE_URL`, `ANTHROPIC_API_KEY` | Native Anthropic endpoint and key (for Claude models) |
| `GOOGLE_GEMINI_BASE_URL`, `GEMINI_API_KEY` | Native Gemini endpoint and key (for Gemini models) |
| Your `env` | Passed through unchanged |

## How a task runs

For each task, the evaluator starts your harness in an isolated container (read-only root filesystem, uid 1000,
2 CPUs, 4 GB RAM) and connects to `0.0.0.0:$PORT`
over a WebSocket. Your harness queries the model and sends WebSocket requests to run commands, read and write files,
and call MCP tools inside the task container, ending with a `done` message.

Your container

### Your harness

* `serve` listens on `0.0.0.0:$PORT`
* 2 CPUs, 4 GB RAM, read-only `/opt/harness`
* runs your loop or an existing agent via `taskbridge.py`

1. The evaluator sends your harness:
   `task`prompt, workdir, time limits, MCP servers
2. Your harness sends the evaluator:
   `exec` `read_file` `write_file` `http`shell commands, file I/O, MCP tool calls
3. The evaluator answers your harness with:
   `result`command output or file data for each request
4. Your harness ends the task with:
   `done`your closing summary, passed to the graders

Runs each task

### The evaluator

* one WebSocket session per task
* enforces time and resource limits

1. In the task's container, the evaluator:
   executes each request as the task user
2. Back from the task's container:
   returns command output and file contents

Task container no network

### The task

* project files in `workdir`
* `bash` shell as the task user
* local MCP app servers when needed (mail, calendar, docs)

Via egress proxy only

### Your model

* `model_api`: a Google sponsored model
* only your model endpoint is reachable; web search and outside APIs are blocked

After the task finishes

### The graders

* automated verification scripts on deliverable files
* LLM rubric judge reviewing deliverables and your closing summary

All commands and file operations pass through the evaluator. Your harness never
accesses the task container or grading scripts directly.

### Bring an existing agent

To wrap an existing CLI agent without writing a WebSocket client, use `taskbridge.py` from the sample
submissions. It runs a local HTTP relay so your subprocess agent can execute commands, read and write files, and
call MCP tools inside the task container.

1. Pi
2. `task-tools.ts`
3. `taskbridge.py` (local relay)
4. WebSocket
5. evaluator
6. task container

See `pi-opus`, `hermes-opus`, and `agy-gemini` in the competition repository for working examples.

### Requirements

Build once
:   `install` runs once at build time with internet access. Only `/opt/harness` is kept (up to
    2 GiB compressed); runtime package downloads are blocked.

Listen in time
:   Accept a WebSocket connection on `0.0.0.0:$PORT` within 120 seconds of startup.

Act through the protocol
:   Exchange UTF-8 JSON frames up to 16 MiB (up to 8 concurrent requests). File reads and writes use base64.

Reach only your model
:   Outbound traffic goes through `HTTPS_PROXY`, which permits only your declared model endpoint.

Deliver, then say done
:   Write all requested files to the exact paths in the prompt and send your summary in `done` before the
    task timeout.
