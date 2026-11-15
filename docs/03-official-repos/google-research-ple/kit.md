# kit/ — the submission kit (`python -m kit`)

Source: `kit/README.md`, `kit/__main__.py`, `kit/spec.py`, `kit/protocol.py`, `docs/artifacts.md` in https://github.com/google-research/ple.

The kit reproduces the evaluation pipeline on your own machine: it builds your bundle in the builder image, starts your WebSocket server behind the egress proxy, tests model connectivity, runs a smoke task and an MCP task, and reviews your `artifacts/`. Run all commands from the root of the ple clone; your entry lives in its own Git repo (e.g. `../my-harness`).

## Modules (one-liners)

| File | Role |
|---|---|
| `__main__.py` | CLI: `check`, `validate`, `build`, `up`, `artifacts`, `models` |
| `spec.py` | Parses and validates `submission.yaml` (see `submission-yaml-spec.md`) |
| `models.py` | The 8 `google-cloud/<id>` models, local providers, env variables injected into the serve container |
| `protocol.py` | Serve protocol v1 constants and frame validation (limits below) |
| `check.py` | The `kit check` stage runner |
| `build.py`, `builder/Dockerfile` | Build container (`debian:bookworm` + uv + Node 22), bundle packing |
| `stack.py`, `egress.py`, `compose/` | Serve container + egress proxy (gost) stack |
| `relay.py`, `capture.py` | Relay between evaluator and task container; transcript capture |
| `artifacts.py`, `export.py` | `artifacts/` review rules and the exporter used by `eval/run.py` |
| `harbor_agent.py`, `harbor_docker.py`, `replay_agent.py` | Harbor integration (runs your server as a Harbor agent; replays committed artifacts for `--artifacts` grading) |
| `model_proxy/` | `start.sh` + LiteLLM `config.yaml` serving the 8 google-cloud models from Vertex AI on `http://localhost:4000`; `effort_default.py` (defaults to highest reasoning effort), `judge_fallback.py` (`<model>-judge`, Opus 5.5 -> Opus 5 refusal fallback) |

## Commands

```bash
uv run python -m kit check ../my-harness [--cancel-test] [--no-smoke] [--keep] [--rebuild] [--work DIR] [--env-file FILE] [--model-base-url URL]
uv run python -m kit validate ../my-harness   # check submission.yaml only (no Docker)
uv run python -m kit build ../my-harness      # build the bundle and serve image only
uv run python -m kit up ../my-harness         # start your server in its container and print its ws:// address
uv run python -m kit artifacts ../my-harness  # review artifacts/ (--from runs/<run> imports a run first, --json)
uv run python -m kit models                   # list the google-cloud models
```

Flag availability: `--work` and `--rebuild` on `check`/`build`/`up`; `--env-file` and `--model-base-url` on `check`/`up`; `--no-smoke`, `--cancel-test`, `--keep` on `check`; `--from` and `--json` on `artifacts`.

## `kit check` — stages (in order, stops at first failure)

| Stage | What it validates |
|---|---|
| `submission.yaml` | Every field and rule of `submission.yaml` (`spec.validate`) |
| `model` (settings) | Before building: `MODEL_PROXY_URL` + `MODEL_PROXY_KEY` for a `google-cloud` model, or your own model's key and any `--model-base-url` (env or `--env-file`) |
| `files` | Files named in `serve` exist; scripts run by `install`/`serve` have LF endings (CRLF warns); no file looks like an API key or private key; no Git LFS in harness files; symlinks checked out as links (`core.symlinks` not false); submodules fetchable anonymously; entry is the root of its own repo with everything committed |
| `build` | Runs `install` in the builder container and validates the bundle (cached unless files change or `--rebuild`) |
| `model` | Your model answers a short prompt from the serve image through the egress proxy |
| `listen` | Server accepts a WebSocket connection within 120 s |
| `smoke` | Small task: harness must write `/app/hello.txt` and send `done` |
| `mcp` | Task whose answer comes from a tool on the task's MCP server (only **warns** if your harness does not use MCP) |
| `cancel` | With `--cancel-test`: cancels a task after 45 s and checks the harness still sends `done` |
| `artifacts` | Validates `artifacts/` (rules below) and that it is committed; warns on API-key-looking text |

Prints **`ready to submit`** only when every stage passes, `artifacts/` is valid, `model_api` is `google-cloud/<id>`, and the entry is at the root of a Git repo with everything committed. `--no-smoke` never yields `ready to submit`.

Exit codes: `0` every stage run passed (even if not yet ready to submit); `1` a stage failed or a requested stage did not run; `130` interrupted. Requires a local Docker daemon (no remote `DOCKER_HOST`).

Logs: `~/.cache/plebench/<name>/` (or `--work`): `build.log`, `serve.log`, `egress.log`, `relay.log`, stage logs (`egress-model.log`, `serve-mcp.log`, ...), `check.json`. Key values are redacted as `[NAME]` in console and `check.json` (raw logs are not redacted).

### Not covered by `kit check`

- Model key scoping (in evaluation the key works only for the declared model; the local proxy serves all eight).
- Submodule `.git` dirs (evaluation checks out submodules with `.git`, depth 1; kit stages files only).
- Uncached builds (eval always builds from scratch — pin deps or test with `--rebuild`).
- Dev-set grading and concurrency (use `eval/run.py`; in evaluation many tasks may run concurrently).

## `kit artifacts` — what it validates

Reviews `artifacts/` on disk (not the commit) plus working-tree git state. `--from <run dir>` first imports a run's artifacts into the entry; `--json` prints the review as JSON.

**Refused (commit not usable):** no usable `artifacts/` folder (incl. fallbacks); an archive committed instead of a folder; Git LFS tracking the artifacts; more than 512 MiB or 10,000 files; no dev task has usable artifacts; git ignores the whole `artifacts/` folder (fix: `git add -f artifacts`).

**Task scores 0 (others still graded):** symlink or submodule in the task folder; deliverable file > 95 MiB, > 2,000 files, or > 256 MiB total; paths with `.`/`..` segments, backslash, control chars, non-UTF-8; paths nested > 64 folders, > 1,024 bytes, or filename > 255 bytes; two paths differing only by case; Git LFS pointer; nothing to grade; only `final_message.md` for a files-only grader; a file/symlink/submodule where the task folder should be.

**Warned, graded as-is:** missing task folders (score 0); missing/empty `final_message.md` where the grader reads it; files outside `deliverables` or outside `files/`; `.gitignore`/`.gitattributes`/`.gitmodules` in a task folder; non-dev-task folders (suggests closest id); raw Harbor trial folders; `manifest.json` missing or mismatched (edited artifacts, other dev-set version, older harness). Ignored files inside `artifacts/`; on-disk vs object-store mismatch (prints fix); unreadable files stop the kit with a `chmod`/`chown` hint.

**Accepted fallbacks (with warning):** `Artifacts/`, `artifact/`, `dev_artifacts/`, `dev-artifacts/`; a single `runs/<run>/artifacts/`; one extra wrapper folder; Harbor trial names (`<id>__abc`); task ids with other case/underscores/spaces; `<task-id>/app/files/...` without `files/`; `init.py` shortcuts for single-deliverable tasks; `final_message.txt` / `final_message` / `final-message.md` / `message.md`.

Expected layout:

```
artifacts/
  manifest.json            written by the kit (do not edit): run, harness digest, blob ids per file
  .gitattributes / .gitignore   written by the kit
  <task-id>/
    final_message.md
    files/<container path without leading "/">
    deleted.txt            optional
    trajectory.json        optional, never graded
```

## Container contract (summary)

- **Build**: clone at commit (with `.git` + submodules) into `debian:bookworm` builder (uv at `/opt/harness/bin/uv`, Node 22 at `/opt/harness/node`, git, curl, compilers, python3). `install` runs as root with internet for up to 30 min. Only `/opt/harness` is packed (≤ 2 GiB packed, 8 GiB unpacked, no file > 8 GiB). Use `uv venv --python 3.12 /opt/harness/venv` (not `python3 -m venv`); apt packages don't carry over. Anonymous clone: no LFS, public https submodules. Folders named `artifact(s)` (any case, optional `dev`/`dev-`/`dev_` prefix) and `runs/<run>/artifacts/` are stripped. Repo incl. `.git` ≤ 1 GiB.
- **Serve**: fresh `linux/amd64` container per task, `serve` run in `/opt/harness/src` as uid 1000, read-only root FS, 2 CPUs, 4 GB RAM, 512 processes, 1 GB `/tmp`, 1 GB `$HOME`. Must accept a WebSocket on `0.0.0.0:$PORT` within 120 s. Outbound only via egress proxy (`HTTPS_PROXY`, `HTTP_PROXY`, `ALL_PROXY`, `NODE_USE_ENV_PROXY=1`) to the model API host only; idle connections closed after 30 min; provider-hosted tools rejected with 400.
- **Task**: no network; harness sends `exec` / `read_file` / `write_file` / `http` (to task MCP servers). Only declared deliverable paths (regular files) + final message are graded.

## Protocol limits (`kit/protocol.py`)

| Constant | Value |
|---|---|
| `VERSION` | 1 |
| `START_SEC` | 120 (accept WebSocket within) |
| `MAX_FRAME_BYTES` | 16 MiB |
| `MAX_MALFORMED` | 20 frames per task |
| `MAX_IN_FLIGHT` | 8 concurrent requests |
| `CANCEL_GRACE_SEC` | 10 |
| `DEFAULT_EXEC_TIMEOUT_SEC` / `EXEC_TIMEOUT_SEC` | 120 / 600 |
| `MAX_OUTPUT_BYTES` | 100,000 (exec output, head+tail kept) |
| `MAX_READ_BYTES` / `MAX_HTTP_BYTES` / `MAX_WRITE_BYTES` | 10 MB each |
| `MAX_ID_CHARS` | 128 |
| `MAX_LOG_CHARS` | 20,000 |
| Request types | `exec`, `read_file`, `write_file`, `http`; one-way `log`, `usage`, `done`, `error` |
| HTTP methods | GET, POST, DELETE, PUT, PATCH, HEAD, OPTIONS |
| Agent timeout (`spec.AGENT_TIMEOUT_SEC`) | 6 h per task |
