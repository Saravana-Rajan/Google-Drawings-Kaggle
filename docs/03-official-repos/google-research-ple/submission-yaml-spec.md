# `submission.yaml` specification

Source: `kit/spec.py`, `kit/models.py`, `kit/README.md`, `docs/models.md` in https://github.com/google-research/ple. Validate with `uv run python -m kit validate <entry>` (no Docker).

## File-level rules

- File name `submission.yaml`, at the **root** of the entry repo (the evaluation server reads it from the root of the build context).
- At most **16 KiB**; must be UTF-8; must be a YAML mapping; must not nest too deeply.
- **Allowed keys only**: `name`, `model_api`, `model_base_url`, `install`, `serve`, `env`. Any other key is refused (`unknown key ... (allowed: ...)`).
- Removed keys, refused with an explanation:
  - `secrets` — "removed; the competition takes no keys (google-cloud models need none, and a local run of your own model reads its key from the environment or --env-file)"
  - `egress` — "removed; a harness reaches its model's endpoint and no other host"

## Fields

| Field | Required | Type | Rules / allowed values |
|---|---|---|---|
| `name` | yes | string | Regex `[a-z0-9][a-z0-9-]{1,38}`: 2–39 chars of `a-z`, `0-9`, `-`, starting with a letter or digit. Leaderboard entry name. |
| `model_api` | yes | string | `<provider>/<model>`. See table below. Only `google-cloud/<id>` is accepted for submission. |
| `model_base_url` | only with `openai-compatible/` | string | Must be an `https://` URL on a public DNS name: no spaces/control chars, no credentials (`@`), no query, no fragment, not an IP address, valid port, not single-label, not ending in `.local`/`.internal`/`.localhost`, must not end in `/chat/completions`. Trailing `/` stripped. Refused for any other provider ("only with model_api: openai-compatible/<model>"). For a local server keep a placeholder (e.g. `https://llm.example.org/v1`) and pass `--model-base-url`. |
| `install` | no | string (shell command) | Runs once at build time as root with internet (≤ 30 min). Placeholder `{src}` -> `/opt/harness/src`. `{port}` not allowed. No NUL / unpaired surrogates. Blank `install:` = no install. |
| `serve` | yes | string (shell command) | Run for each task in `/opt/harness/src` as uid 1000; must start the WebSocket server on `$PORT`. Placeholders `{src}` and `{port}`. Must be a valid shell command line (`shlex.split`, balanced quotes) and not only a comment. Files it names must exist (`kit check` files stage). |
| `env` | no | mapping `NAME: "value"` | Keys: regex `[A-Z_][A-Z0-9_]{0,63}`. Values must be **quoted strings** (YAML numbers/bools refused), one line, no `${...}`, no NUL/CR/LF, never an API key. Placeholders `{src}`, `{port}` allowed. Reserved names refused (below). |

### Placeholders

- `{src}` = `/opt/harness/src` (allowed in `install`, `serve`, `env`).
- `{port}` = the server port (allowed in `serve`, `env`; also in `$PORT`). Not allowed in `install`.
- `${src}` / `${port}` (with `$`) are left untouched for the shell. Other `{...}` braces are left as-is.

### `model_api` values

Google-sponsored (submittable, no key in the entry):

| `model_api` | Model | APIs |
|---|---|---|
| `google-cloud/gemini-4-argon` | Gemini 4 Argon | OpenAI Chat Completions, Gemini API |
| `google-cloud/gemini-3.8-flash` | Gemini 3.8 Flash | OpenAI Chat Completions, Gemini API |
| `google-cloud/gemini-3.1-pro-preview` | Gemini 3.1 Pro (preview) | OpenAI Chat Completions, Gemini API |
| `google-cloud/claude-opus-5-5` | Claude Opus 5.5 | OpenAI Chat Completions, Anthropic Messages |
| `google-cloud/gpt-oss-120b` | gpt-oss 120B | OpenAI Chat Completions |
| `google-cloud/glm-5.2` | GLM 5.2 | OpenAI Chat Completions |
| `google-cloud/gemma-4-26b` | Gemma 4 26B A4B | OpenAI Chat Completions |
| `google-cloud/llama-4-maverick` | Llama 4 Maverick 17B 128E | OpenAI Chat Completions |

Local runs only (never `ready to submit`; model name regex `[A-Za-z0-9][A-Za-z0-9._:/@+-]{0,127}`):

| `model_api` | Key (env / `--env-file`) | Allowed outbound host |
|---|---|---|
| `openai/<model>` | `OPENAI_API_KEY` | `api.openai.com` |
| `anthropic/<model>` | `ANTHROPIC_API_KEY` | `api.anthropic.com` |
| `gemini/<model>` | `GEMINI_API_KEY` | `generativelanguage.googleapis.com` |
| `openai-compatible/<model>` + `model_base_url` | `MODEL_API_KEY` | host of `model_base_url` / `--model-base-url` |

### Reserved `env` names (cannot be set)

Set by the evaluator: `PORT`, `HOME`, `USER`, `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`, `NO_PROXY`, `NODE_USE_ENV_PROXY`.

Model variables (injected per `docs/models.md`): `MODEL_API`, `MODEL_NAME`, `MODEL_BASE_URL`, `MODEL_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_API_KEY`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_API_KEY`, `GOOGLE_GEMINI_BASE_URL`, `GEMINI_API_KEY` — reserved even if your model does not use them.

## What the server receives at runtime (google-cloud)

| Variable | Value |
|---|---|
| `MODEL_API` | `model_api` as written |
| `MODEL_NAME` | `<id>` |
| `MODEL_BASE_URL`, `MODEL_API_KEY` | Gateway URL (`.../v1`) and the entry's key (= `OPENAI_BASE_URL`, `OPENAI_API_KEY`) |
| `ANTHROPIC_BASE_URL`, `ANTHROPIC_API_KEY` | Gateway URL without `/v1` (Claude only) |
| `GOOGLE_GEMINI_BASE_URL`, `GEMINI_API_KEY` | Gateway URL without `/v1` (Gemini only) |
| `PORT` | Port to listen on (`0.0.0.0`) |

In evaluation the key works only for the declared model (others get `403`).

## Example

```yaml
name: my-harness                          # 2-39 chars of a-z, 0-9, -
model_api: google-cloud/claude-opus-5-5   # docs/models.md
install: >-                               # optional: once at build time as root, with internet
  uv venv --python 3.12 /opt/harness/venv
  && uv pip install --python /opt/harness/venv/bin/python -r {src}/requirements.txt
serve: /opt/harness/venv/bin/python {src}/serve.py    # required: WebSocket server on $PORT
env:                                      # optional: non-secret settings, quoted strings
  LOG_LEVEL: "info"
```
