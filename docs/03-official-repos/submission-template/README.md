# submission-template: notes

Notes on the cloned [physical-engineerings-last-exam/submission-template](https://github.com/physical-engineerings-last-exam/submission-template) (local clone: `../submission-template-src`).

## What it is

A ready-to-submit entry for the **Physical-Engineering's Last Exam (PLE) harness competition**. The entry is the [Pi](https://github.com/badlogic/pi-mono) coding agent (`@earendil-works/pi-coding-agent` 1.1.0) driving **`google-cloud/claude-opus-5-5`** (a Google-sponsored model, so no API key is needed).

The evaluator starts the harness as a WebSocket server and sends it one engineering task per connection. The harness runs Pi headless. Pi's `read`/`write`/`edit`/`bash` tools and the task's MCP servers are forwarded into the task container through the competition protocol.

`artifacts/` already holds a full dev-set run (29 tasks, mean reward about 0.49), so you can submit the template unchanged. If you change any harness file, `name` included, the manifest hashes no longer match and you must rerun the dev set.

Related notes in this folder:
- [architecture.md](architecture.md): how the pieces fit, the protocol flow, tools and env vars
- [agents-md.md](agents-md.md): the full rules (render of `AGENTS.md`)
- [dev-tasks-artifacts.md](dev-tasks-artifacts.md): the 29 dev tasks, deliverables and scores

## Files

| File | What it does |
|---|---|
| `submission.yaml` | Entry config: `name: my-harness`, `model_api: google-cloud/claude-opus-5-5`, `install` (`npm ci` of Pi + a uv Python 3.12 venv at `/opt/harness/venv` with `requirements.txt`), `serve: /opt/harness/venv/bin/python {src}/serve.py` |
| `serve.py` | 3-line entrypoint: `taskbridge.run(harness.solve)` serves on `$PORT` (default 8765) |
| `harness.py` | `solve(session)`: writes Pi's `models.json` / `settings.json` / `mcp.json` into a temp agent dir, then runs `pi --print --mode json ... -e task-tools.ts` with the instruction on stdin. It parses Pi's JSON event stream into the final message, `usage` and `log` frames. Settings you can tune: `NOTE` (appended system prompt), `THINKING="max"`, `STOP_BEFORE_SEC=90`, `UNKNOWN_MODEL` limits, `COMPAT` flags |
| `task-tools.ts` | Pi extension. It replaces Pi's built-in `read`, `write`, `edit` and `bash` with versions that POST to the local relay (`TASK_RELAY_URL`), with paths rooted at `TASK_WORKDIR`. Bash calls are capped at 600 s and reads at 10 MB |
| `taskbridge.py` | The competition protocol library (about 50 KB). It provides the WebSocket server and `Session` (exec/read_file/write_file/http/log/usage, cancel handling). It also has `Relay`, a local HTTP relay that gives a subprocess agent token-protected access to `/exec`, `/read_file`, `/write_file` and `/mcp/<server>`, plus an MCP client, `run_process` and `time_share` |
| `package.json` / `package-lock.json` | Pins Pi 1.1.0 and its dependency tree. To upgrade, edit `package.json`, run `npm install --package-lock-only` and commit both |
| `requirements.txt` | `websockets==15.0.1` (the only Python dependency) |
| `artifacts/` | Dev-set outputs written by `eval/run.py`: one folder per task (`files/<container path>`, `final_message.md`, `trajectory.json`) plus `manifest.json`. Its `.gitignore` (`!*`) and `.gitattributes` (`-text -filter ...`) keep the files byte-exact. Never edit by hand |
| `AGENTS.md` | The full rules, written for a coding agent working on the entry |
| `LICENSE` | Apache 2.0 (Google LLC) |
| `.gitignore` | Repository ignores |

## Directory tree

```
submission-template-src/
├── .gitignore
├── AGENTS.md
├── LICENSE
├── README.md
├── harness.py
├── package.json
├── package-lock.json
├── requirements.txt
├── serve.py
├── submission.yaml
├── task-tools.ts
├── taskbridge.py
└── artifacts/
    ├── .gitattributes
    ├── .gitignore
    ├── manifest.json
    └── <29 task folders>/
        ├── final_message.md
        ├── trajectory.json
        └── files/{filesystem,app}/...   (deliverables at their container paths; absent if none)
```

## Run, validate, submit

You need `uv`, a local Docker daemon (images run as `linux/amd64`) and Harbor (`uv tool install harbor==0.20.0 --with websockets`). Run every command from the **competition repository root**, with the entry cloned beside it as `../your-repo`.

```bash
# 0. Create your own copy: "Use this template" on GitHub (private if you add .env),
#    install the PLE-submission GitHub App, clone it next to the competition repo,
#    and set `name` in submission.yaml (2-39 chars, a-z 0-9 -).

# 1. A google-cloud model needs the local Vertex AI proxy (see docs/models.md)
kit/model_proxy/start.sh          # uses VERTEXAI_PROJECT, MODEL_PROXY_URL, MODEL_PROXY_KEY

# 2. Check the entry (yaml, files, .env, build, model, listen, smoke[, cancel], artifacts)
uv run python -m kit check ../your-repo [--cancel-test] [--rebuild]

# 3. Run and score the dev set; this writes ../your-repo/artifacts/
uv run python eval/run.py ../your-repo
uv run python eval/run.py ../your-repo --tasks <id>          # rerun one task
uv run python eval/run.py --regrade runs/<name>-<time>       # regrade only, if the judge failed

# 4. Validate the artifacts and grade them as the server would
uv run python -m kit artifacts ../your-repo
uv run python eval/run.py --artifacts ../your-repo

# 5. Commit the harness and artifacts together, then push
git -C ../your-repo add -A && git -C ../your-repo commit -m "dev artifacts" && git -C ../your-repo push
git -C ../your-repo rev-parse HEAD
```

**Step 6: submit.** On the portal, open `/competition/submit`, pick the repository and branch, review the checks and submit. Status moves through `queued → validating → building → smoke → running → grading → scored|failed`. Each participant gets 3 scored submissions and can have only one in flight at a time.

Logs go to `~/.cache/pele/<name>/` (`build.log`, `serve.log`, `egress.log`, `relay.log`, `check.json`).
