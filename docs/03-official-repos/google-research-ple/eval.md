# eval/ — dev-set evaluation (`eval/run.py`)

Source: `eval/README.md`, `eval/dev_set.yaml`, `eval/run.py` argument parser in https://github.com/google-research/ple.

`eval/run.py` runs your entry on the **29 public dev tasks**, grades them with the benchmark graders (via Harbor), and exports the outputs into your entry's `artifacts/` folder (to be committed with the harness). `eval/run.py --artifacts` grades a committed `artifacts/` folder offline.

## Prerequisites

- Docker (about 10 GB free disk for base images, plus world images; the 12 MCP "world" rubric tasks build ~17 GB images, each given at least 1 h to build).
  - macOS/Windows Docker Desktop: at least **6 CPUs and 16.25 GB memory**. Windows: run inside WSL 2, repo under `~`, `core.autocrlf input`, `core.symlinks` not false.
- `uv` and Harbor 0.20.0 with websockets: `uv tool install harbor==0.20.0 --with websockets`.
- Model access:
  - `google-cloud/<id>` models: `MODEL_PROXY_URL` + `MODEL_PROXY_KEY` pointing at a local proxy (`kit/model_proxy/start.sh`, LiteLLM on Vertex AI, port 4000).
  - Own model (local runs only): `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GEMINI_API_KEY` / `MODEL_API_KEY`.
- A judge for `rubric` and `checks-judge` tasks, first available of:
  1. `JUDGE_BASE_URL` + `JUDGE_API_KEY` (any OpenAI-compatible endpoint; `JUDGE_API_KEY` without `JUDGE_BASE_URL` stops the run)
  2. `MODEL_PROXY_URL` + `MODEL_PROXY_KEY`
  3. the entry's own model and key (local-only entries)
  - `JUDGE_MODEL` defaults to `claude-opus-5-5` (leaderboard judge is Claude Opus 5.5; `eval/run.py` requests `<model>-judge` from `kit/model_proxy` for standard-effort judging; refused judge calls fall back once to Claude Opus 5).
  - On Linux, a local judge must listen on `0.0.0.0` (reachable from Docker bridge).
- Hugging Face access to the gated dataset `google/physical-engineerings-last-exam`: accept terms, set `HF_TOKEN` (or `uv run hf auth login`). `--tasks-dir DIR` uses pre-downloaded tasks. Tasks are cached in `~/.cache/plebench/tasks/<commit>/`.

Keep settings in an env file outside your entry (e.g. `local.env` at the root of the ple clone; `*.env` is gitignored):

```bash
# local.env
MODEL_PROXY_URL=http://localhost:4000
MODEL_PROXY_KEY=<the key you gave kit/model_proxy/start.sh>
# JUDGE_BASE_URL=https://<an OpenAI-compatible endpoint>/v1
# JUDGE_API_KEY=<its key>
# HF_TOKEN=<a Hugging Face token, if needed>
# OPENAI_API_KEY=<your key>, for a local run on openai/<model>
```

## Usage

```bash
# All 29 dev tasks (exports ../my-harness/artifacts/)
uv run python eval/run.py ../my-harness --env-file local.env

# Specific tasks only
uv run python eval/run.py ../my-harness --env-file local.env --tasks data-center-site-model,engineers-estimate-check

# Re-grade judge failures without re-running the harness
uv run python eval/run.py --regrade runs/<name>-<time> --env-file local.env

# Grade committed artifacts/ offline (fresh task container, no harness run)
uv run python eval/run.py --artifacts ../my-harness

# Debug against an already running server (kit up prints the ws:// address)
uv run python -m kit up ../my-harness
uv run python eval/run.py --url ws://127.0.0.1:<port> --name my-harness --tasks data-center-site-model

# Model you serve yourself (openai-compatible/<model>, local only)
uv run python eval/run.py ../my-harness --env-file local.env --model-base-url http://localhost:8090/v1

# Copy a run's artifacts into the entry later
uv run python -m kit artifacts <entry> --from <run dir>
```

### Flags

| Flag | Meaning |
|---|---|
| `<entry>` (positional) | Directory holding `submission.yaml` (or that file) |
| `--url ws://...` | Run against an already running server instead of building the entry (no harness digest recorded, so don't submit artifacts from it) |
| `--name` | With `--url`: harness name in the results |
| `--model` | With `--url`: the model it calls, for the results |
| `--tasks id,id` | Comma-separated dev task ids (default: all) |
| `--trials N` | How many tasks to run in parallel (default: as many as Docker CPU/memory allow, slot sized for largest task: 6 CPUs / 16.25 GB for full set) |
| `--attempts N` | Max attempts per task on evaluator-side faults (default 3) |
| `--env-file FILE` | `NAME=value` settings (proxy, judge, HF token, own-model key) |
| `--model-base-url URL` | Override `model_base_url` for an `openai-compatible` entry (`localhost` is rewritten to `host.docker.internal`) |
| `--out DIR` | New or empty folder for the run (default `runs/<name>-<time>/`) |
| `--rebuild` | Build even if nothing changed |
| `--tasks-dir DIR` | Use pre-downloaded task folders as-is |
| `--regrade <run>` | Re-grade tasks whose judge grading failed, with the exact dataset revision recorded in `results.json` |
| `--no-export` | Leave the entry's `artifacts/` untouched |
| `--artifacts <entry>` | Grade the committed `artifacts/` offline |

`Ctrl-C` cancels running trials (up to 120 s; press again to kill Harbor). Exit codes: `0` success, `1` any task unmeasured (counts as 0) or unusable artifacts, `130` interrupted. Live progress: `tail -f runs/<run>/attempt1/harbor.log` (Harbor's "Mean" is the raw, unscaled reward).

### Time and cost

- Each task container: 2–4 CPUs, 4–12 GB memory, plus 2 CPUs / 4.25 GB for serve + egress containers. Timed verifiers score lower under CPU contention or amd64 emulation on Apple silicon.
- 6-hour per-task limit (174 h total if serial; most harnesses finish far sooner).
- Judge: one call per rubric task (or per rendered document group), a few per `checks-judge` task, plus retries.

## Run output layout

```
runs/<name>-<time>/              (runs/<name>-artifacts-<time>/ for --artifacts)
  results.json                   overall and per-task scores, statuses, and token usage
  export.json, artifacts/        export record and exported artifacts with manifest.json (not for --artifacts)
  tasks/                         per-run copy of each task
  attempt1/                      retries go to attempt2/ and attempt3/
    harbor.log                   Harbor console output
    job.yaml, task-limits.yaml   Harbor job config and container resource limits
    jobs/dev/<task>__<id>/       one trial (`harbor view runs/<run>/attempt1/jobs` browses them)
      result.json                Harbor's trial record
      agent/                     <name>.txt (protocol transcript), serve.log, egress.log, trajectory.json
      artifacts/                 deliverables Harbor passed to the verifier
      deliverables/              deliverables copied out by the kit (used by --regrade)
      verifier/                  test-stdout.txt, grade.json, grade.log, or GRADER_FAILED.txt
  attempt1-regrade1/             grader replays for trials whose judge grading failed
```

## Grading

- `checks`: programmatic checks, no network.
- `rubric`: LLM judge scores deliverables against an expert rubric.
- `checks-judge`: programmatic checks that also query the LLM judge on parts of the deliverable.
- Score per task = reward / reward_scale, in [0, 1]. Constraint+objective tasks (grader includes `tests/paper_score.py`) use `s = 0.4 p + 0.6 G O'` per item (see `docs-rules.md`).

| Trial outcome | What `eval/run.py` does |
|---|---|
| Harness ended (`done`, `error`, `AgentTimeoutError`, `NonZeroAgentExitCodeError`) | Measured: deliverables in the container are graded |
| Harness errored before the model produced any output | Not started: re-run up to `--attempts`; unmeasured (0) if it never starts (context-overflow / provider-limit endings are graded as-is) |
| `rubric`/`checks-judge` grader failed | Re-graded from snapshotted deliverables up to 3 times |
| Other evaluator fault | Full trial re-run up to `--attempts` |
| Broken `task.toml` or image build failure | Not measured, not re-run |

## The 29 dev tasks (from `eval/dev_set.yaml`)

| # | id | title | discipline | grading | time limit (min) | final_message read | deliverables |
|--:|---|---|---|---|--:|---|---|
| 1 | `data-hall-mep-routing` | Clash-free MEP routing through a data hall | Mechanical engineering | `checks` | 360 | no | `/app/files/dc_model__hall_seed000_d000__mep_routing/output/solution.py` |
| 2 | `fire-test-validation-memo` | Validation memo for a fire-resistance simulation against its test | Mechanical engineering | `rubric` | 360 | yes | `/app/files/` |
| 3 | `data-hall-mep-routing-offset` | Clash-free MEP routing through a data hall on an offset structural grid | Mechanical engineering | `checks` | 360 | no | `/app/files/dc_model__hall_seed005_d100__mep_routing/output/solution.py` |
| 4 | `eor-review-corrections` | Issue an engineer-of-record review's corrections to two bid packages | Structural engineering | `checks-judge` | 360 | no | `/filesystem/dc_structural__eor_revision__blind/output/submission.zip`<br>`/filesystem/filesystem/dc_structural__eor_revision__blind/output/submission.zip` |
| 5 | `foundation-strategy` | Spread footings or aggregate piers for six data-campus building pads | Civil engineering | `checks-judge` | 360 | no | `/filesystem/dc_structural__foundation_strategy__blind/output/submission.zip`<br>`/filesystem/filesystem/dc_structural__foundation_strategy__blind/output/submission.zip` |
| 6 | `landscape-sheet-revision` | Street-tree revision worked into a landscape resubmittal | Civil engineering | `rubric` | 360 | yes | `/app/files/` |
| 7 | `data-center-site-model` | Feasible data-center site design as an IFC model | Civil engineering | `checks` | 360 | no | `/app/files/frontier__DCBim__p6_002/submission/model.ifc` |
| 8 | `engineers-estimate-check` | Engineer's estimate checked before a bond conversation | Civil engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 9 | `footing-settlement-verification` | Settlement verification of a building block's spread footings on clay | Civil engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 10 | `solar-supplemental-review` | Supplemental interconnection review memo for a solar project | Electrical engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 11 | `solar-witness-test-package` | Witness-test scope and schedule for municipal solar arrays | Electrical engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 12 | `frame-extension-method` | Method package for a frame extension over an occupied floor | Civil engineering | `checks` | 360 | no | `/filesystem/field_eng__constructability_4d__blind/output/submission.zip`<br>`/filesystem/filesystem/field_eng__constructability_4d__blind/output/submission.zip` |
| 13 | `fire-solve-convergence` | Disposition of a non-converging fire-simulation solve | Mechanical engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 14 | `les-mesh-resolution` | Mesh-resolution basis for an LES fire case | Mechanical engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 15 | `mv-conveyance-study` | Conveyance study for a 13.8 kV site distribution | Electrical engineering | `checks` | 360 | no | `/filesystem/final_batch4__electrical_task12_conveyance_study__blind/output/submission.zip` |
| 16 | `data-hall-device-takeoff` | Device takeoff and priced bill of materials for a data hall | Electrical engineering | `checks` | 360 | no | `/filesystem/final_batch4__electrical_task17_ec_0205_d100__blind/output/submission.zip` |
| 17 | `division-26-specifications` | Division 26 project specifications for an Army facility | Electrical engineering | `checks` | 360 | no | `/filesystem/final_batch4__electrical_task8_electrical_specs__blind/output/submission.zip` |
| 18 | `heat-rejection-life-cycle-cost` | Life-cycle cost of a condenser-water heat rejection replacement | Mechanical engineering | `checks` | 360 | no | `/filesystem/final_batch4__mechanical_task3_ct_heat_lcc__blind/output/submission.zip` |
| 19 | `cooling-water-flush-plan` | Flushing and passivation of a data hall's process cooling water | Mechanical engineering | `checks` | 360 | no | `/filesystem/final_batch4__mechanical_task5_pcw_flush_mop__blind/output/submission.zip` |
| 20 | `wind-diaphragm-shear` | Roof diaphragm shears and shear-wall loads for wind | Structural engineering | `checks` | 360 | no | `/filesystem/final_batch4__structural_task5_wind_diaphragm_shear__blind/output/submission.zip` |
| 21 | `seismic-diaphragm-shear` | Seismic diaphragm shears and shear-wall loads | Structural engineering | `checks` | 360 | no | `/filesystem/final_batch4__structural_task6_seismic_diaphragm_shear__blind/output/submission.zip` |
| 22 | `roof-deck-design` | Roof deck design for gravity and lateral loads | Structural engineering | `checks` | 360 | no | `/filesystem/final_batch4__structural_task7_roof_deck_design__blind/output/submission.zip` |
| 23 | `fill-compaction-acceptance` | Acceptance of slab-on-grade fill compaction testing | Civil engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 24 | `shoring-design-verification` | Verification of a revised shoring design ahead of an excavation | Civil engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 25 | `emergency-spillway-check` | Emergency spillway check behind a plan-check comment | Civil engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 26 | `pre-application-capacity-response` | Response to a pre-application request for feeder capacity | Electrical engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 27 | `permission-to-operate-memo` | Permission-to-operate memo for an office complex's PV system | Electrical engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 28 | `backfeed-energization-reply` | Reply on a community solar site's backfeed energization date | Electrical engineering | `rubric` | 360 | yes | `/filesystem/`<br>`/app/output/`<br>`/app/tools/.apps_data/` |
| 29 | `lv-cable-sizing` | Low-voltage wire schedule with voltage drop and duct-bank ampacity | Electrical engineering | `checks-judge` | 360 | no | `/filesystem/electrical__lv_cable_sizing__blind/output/submission.zip`<br>`/filesystem/filesystem/electrical__lv_cable_sizing__blind/output/submission.zip` |

Total tasks: 29. Dataset: `google/physical-engineerings-last-exam` @ `b3857a3fea39a695e18f845d4a88f29442e96e75`.

By discipline: Civil engineering 9, Electrical engineering 9, Mechanical engineering 7, Structural engineering 4.

By grading: `checks` 12, `checks-judge` 3, `rubric` 14.

### What each task asks for (from `eval/README.md`)

| Task | Discipline | Graded by | What it asks for |
|---|---|---|---|
| `data-hall-mep-routing` | Mechanical engineering | `checks` | Reconstruct a data hall from seven drawing sheets and generate a clash-free IFC4 model routing cable tray, busway, and chilled-water piping |
| `fire-test-validation-memo` | Mechanical engineering | `rubric` | Evaluate a fire-resistance simulation against furnace test data and write an engineering validation memo in Word |
| `data-hall-mep-routing-offset` | Mechanical engineering | `checks` | Route MEP systems in a data hall where the structural grid is offset from the floor tiles, navigating a cross-aisle and 104 sprinkler heads |
| `eor-review-corrections` | Structural engineering | `checks-judge` | Turn engineer-of-record review markups into an issued drawing revision across two bid packages, including comment dispositions, a sheet index, and change documentation |
| `foundation-strategy` | Civil engineering | `checks-judge` | Choose between spread footings and aggregate piers for six building pads using geotechnical records, and deliver a design basis, schedule, and constraint register |
| `landscape-sheet-revision` | Civil engineering | `rubric` | Incorporate a street-tree comment into a landscape drawing set and verify the package for agency resubmittal |
| `data-center-site-model` | Civil engineering | `checks` | Lay out a two-phase data-center campus that meets every binding requirement in its approval document, as an IFC model |
| `engineers-estimate-check` | Civil engineering | `rubric` | Audit a section of an engineer's estimate against the project plans before it goes to the surety broker |
| `footing-settlement-verification` | Civil engineering | `rubric` | Verify the long-term settlement of a building block's spread footings on clay and issue the verification memo |
| `solar-supplemental-review` | Electrical engineering | `rubric` | Write the supplemental interconnection review memo for a solar application on a distribution feeder |
| `solar-witness-test-package` | Electrical engineering | `rubric` | Prepare the witness-test scope and schedule for municipal solar arrays that require testing, and list those that do not |
| `frame-extension-method` | Civil engineering | `checks` | Prepare a construction method package for a steel frame extension over an occupied floor, verified against safety regulations |
| `fire-solve-convergence` | Mechanical engineering | `rubric` | Provide a signed engineering disposition on a non-converging steady-state fire simulation before a fourth run is attempted |
| `les-mesh-resolution` | Mechanical engineering | `rubric` | Document the mesh-resolution basis of a large-eddy fire simulation to close a peer-review item |
| `mv-conveyance-study` | Electrical engineering | `checks` | Produce a conveyance study and cost workbook for seven 13.8 kV medium-voltage distribution circuits |
| `data-hall-device-takeoff` | Electrical engineering | `checks` | Complete an electrical device takeoff from a data hall drawing set and price the bill of materials |
| `division-26-specifications` | Electrical engineering | `checks` | Write Division 26 electrical specifications for an Army facility from its coordinated design package |
| `heat-rejection-life-cycle-cost` | Mechanical engineering | `checks` | Design a condenser-water heat rejection replacement for a federal campus and justify it with a life-cycle cost analysis |
| `cooling-water-flush-plan` | Mechanical engineering | `checks` | Create a cleaning, flushing, and passivation plan for a data hall's process cooling-water system prior to turnover |
| `wind-diaphragm-shear` | Structural engineering | `checks` | Calculate wind roof-diaphragm shears and shear-wall loads for a single-story data hall |
| `seismic-diaphragm-shear` | Structural engineering | `checks` | Calculate seismic diaphragm shears and shear-wall loads along a data-center building's lateral load path |
| `roof-deck-design` | Structural engineering | `checks` | Design a data center's steel roof deck for gravity and lateral loads, specifying gage, fastener pattern, and diaphragm capacity |
| `fill-compaction-acceptance` | Civil engineering | `rubric` | Decide whether slab-on-grade fill compaction testing and its records meet the earthwork specification, as a materials acceptance record |
| `shoring-design-verification` | Civil engineering | `rubric` | Verify a revised excavation shoring design against the logged groundwater and subsurface conditions before the excavation starts |
| `emergency-spillway-check` | Civil engineering | `rubric` | Check whether a stormwater basin's emergency spillway as drawn can answer a plan-check comment, and set out the revisions in a memo |
| `pre-application-capacity-response` | Electrical engineering | `rubric` | Write a utility's response to a pre-application request for a feeder's available capacity, and close the case in its tracking |
| `permission-to-operate-memo` | Electrical engineering | `rubric` | Advise whether permission to operate can issue for a PV site on the requested date, and open a work package for what stands in the way |
| `backfeed-energization-reply` | Electrical engineering | `rubric` | Reply to a community solar developer on whether its site can be energized for backfeed on the requested date, and open a work package |
| `lv-cable-sizing` | Electrical engineering | `checks-judge` | Size a building's low-voltage cable schedule for voltage drop, duct-bank ampacity, and cost, with a constraint register and design basis |

Each task is a Harbor task under `tasks/<id>/` in the Hugging Face dataset; each `sha256` in `dev_set.yaml` records the task folder digest at export time. Directory deliverables end with `/`. Note the rubric/MCP "world" tasks all share the deliverable set `/filesystem/`, `/app/output/`, `/app/tools/.apps_data/` and read `final_message`.
