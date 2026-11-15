# PLE Dev Set — downloaded task index

Source: https://huggingface.co/datasets/google/physical-engineerings-last-exam (gated; **do not redistribute / commit publicly**)
Location: `data/dev-tasks/tasks/<task-id>/` · 29 tasks · downloaded 2026-11-15
Disciplines: {'mechanical': 7, 'structural': 4, 'civil': 9, 'electrical': 9} · Grading: {'checks': 12, 'rubric': 14, 'checks-judge': 3}

Each task folder: `instruction.md` / `task.toml` (the brief), `environment/files|filesystem/` (**project documents the agent reads**), `environment/tools/` (tool-app source: Excel, FreeCAD, mail, calendar, code exec — not documents), `tests/` + evaluator (graders — the agent must never read them).

## Per task (agent-facing input documents only)

| Task | Discipline | Grading | Input files | PDFs | PDF pages≈ | Images | Sheets | DOCX | CAD/BIM | Input MB | All files |
|---|---|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| [backfeed-energization-reply](../../data/dev-tasks/tasks/backfeed-energization-reply/) | electrical | rubric | 95 | 56 | 142 | 0 | 29 | 7 | 0 | 5.5 | 3180 |
| [cooling-water-flush-plan](../../data/dev-tasks/tasks/cooling-water-flush-plan/) | mechanical | checks | 51 | 20 | 944 | 0 | 8 | 10 | 11 | 20.2 | 73 |
| [data-center-site-model](../../data/dev-tasks/tasks/data-center-site-model/) | civil | checks | 6 | 0 | 0 | 0 | 0 | 0 | 2 | 0.0 | 42 |
| [data-hall-device-takeoff](../../data/dev-tasks/tasks/data-hall-device-takeoff/) | electrical | checks | 38 | 7 | 635 | 17 | 0 | 0 | 0 | 37.2 | 71 |
| [data-hall-mep-routing](../../data/dev-tasks/tasks/data-hall-mep-routing/) | mechanical | checks | 8 | 0 | 0 | 7 | 0 | 0 | 0 | 1.4 | 34 |
| [data-hall-mep-routing-offset](../../data/dev-tasks/tasks/data-hall-mep-routing-offset/) | mechanical | checks | 8 | 0 | 0 | 7 | 0 | 0 | 0 | 1.4 | 34 |
| [division-26-specifications](../../data/dev-tasks/tasks/division-26-specifications/) | electrical | checks | 124 | 40 | 1572 | 0 | 8 | 9 | 3 | 21.4 | 151 |
| [emergency-spillway-check](../../data/dev-tasks/tasks/emergency-spillway-check/) | civil | rubric | 56 | 37 | 274 | 0 | 11 | 3 | 0 | 1.0 | 2364 |
| [engineers-estimate-check](../../data/dev-tasks/tasks/engineers-estimate-check/) | civil | rubric | 56 | 37 | 274 | 0 | 11 | 3 | 0 | 1.0 | 2304 |
| [eor-review-corrections](../../data/dev-tasks/tasks/eor-review-corrections/) | structural | checks-judge | 94 | 69 | 856 | 0 | 11 | 1 | 0 | 18.3 | 117 |
| [fill-compaction-acceptance](../../data/dev-tasks/tasks/fill-compaction-acceptance/) | civil | rubric | 55 | 37 | 274 | 0 | 14 | 2 | 0 | 1.5 | 2416 |
| [fire-solve-convergence](../../data/dev-tasks/tasks/fire-solve-convergence/) | mechanical | rubric | 50 | 16 | 68 | 1 | 12 | 5 | 0 | 1.2 | 2355 |
| [fire-test-validation-memo](../../data/dev-tasks/tasks/fire-test-validation-memo/) | mechanical | rubric | 50 | 16 | 68 | 1 | 12 | 5 | 0 | 1.2 | 65 |
| [footing-settlement-verification](../../data/dev-tasks/tasks/footing-settlement-verification/) | civil | rubric | 55 | 37 | 274 | 0 | 14 | 2 | 0 | 1.5 | 2298 |
| [foundation-strategy](../../data/dev-tasks/tasks/foundation-strategy/) | civil | checks-judge | 50 | 33 | 3404 | 0 | 7 | 3 | 1 | 107.9 | 73 |
| [frame-extension-method](../../data/dev-tasks/tasks/frame-extension-method/) | civil | checks | 35 | 0 | 0 | 0 | 21 | 0 | 2 | 63.4 | 55 |
| [heat-rejection-life-cycle-cost](../../data/dev-tasks/tasks/heat-rejection-life-cycle-cost/) | mechanical | checks | 50 | 14 | 1547 | 0 | 11 | 10 | 4 | 78.7 | 74 |
| [landscape-sheet-revision](../../data/dev-tasks/tasks/landscape-sheet-revision/) | civil | rubric | 112 | 74 | 548 | 0 | 22 | 6 | 0 | 2.0 | 127 |
| [les-mesh-resolution](../../data/dev-tasks/tasks/les-mesh-resolution/) | mechanical | rubric | 50 | 16 | 68 | 1 | 12 | 5 | 0 | 1.2 | 2355 |
| [lv-cable-sizing](../../data/dev-tasks/tasks/lv-cable-sizing/) | electrical | checks-judge | 32 | 14 | 271 | 0 | 6 | 0 | 10 | 3.6 | 60 |
| [mv-conveyance-study](../../data/dev-tasks/tasks/mv-conveyance-study/) | electrical | checks | 66 | 31 | 2265 | 0 | 25 | 0 | 2 | 27.9 | 89 |
| [permission-to-operate-memo](../../data/dev-tasks/tasks/permission-to-operate-memo/) | electrical | rubric | 95 | 56 | 142 | 0 | 29 | 7 | 0 | 5.5 | 3180 |
| [pre-application-capacity-response](../../data/dev-tasks/tasks/pre-application-capacity-response/) | electrical | rubric | 95 | 56 | 142 | 0 | 29 | 7 | 0 | 5.5 | 3180 |
| [roof-deck-design](../../data/dev-tasks/tasks/roof-deck-design/) | structural | checks | 31 | 9 | 349 | 0 | 7 | 1 | 6 | 4.3 | 58 |
| [seismic-diaphragm-shear](../../data/dev-tasks/tasks/seismic-diaphragm-shear/) | structural | checks | 40 | 15 | 326 | 0 | 7 | 2 | 6 | 10.1 | 64 |
| [shoring-design-verification](../../data/dev-tasks/tasks/shoring-design-verification/) | civil | rubric | 55 | 37 | 274 | 0 | 14 | 2 | 0 | 1.5 | 2416 |
| [solar-supplemental-review](../../data/dev-tasks/tasks/solar-supplemental-review/) | electrical | rubric | 53 | 28 | 102 | 0 | 16 | 6 | 0 | 5.3 | 3051 |
| [solar-witness-test-package](../../data/dev-tasks/tasks/solar-witness-test-package/) | electrical | rubric | 53 | 28 | 102 | 0 | 16 | 6 | 0 | 5.3 | 3051 |
| [wind-diaphragm-shear](../../data/dev-tasks/tasks/wind-diaphragm-shear/) | structural | checks | 37 | 12 | 255 | 0 | 8 | 1 | 8 | 3.6 | 65 |
| **TOTAL** | | | **1600** | **795** | **15176** | **34** | **360** | **103** | **55** | **438.6** | **33402** |

## Input documents by format (all 29 tasks)

| Extension | Files | MB |
|---|--:|--:|
| `.pdf` | 795 | 286.4 |
| `.xlsx` | 284 | 9.1 |
| `.docx` | 103 | 4.0 |
| `.csv` | 75 | 34.3 |
| `.eml` | 56 | 0.2 |
| `.dxf` | 48 | 2.5 |
| `.sec` | 45 | 5.3 |
| `.md` | 38 | 0.3 |
| `.png` | 34 | 20.9 |
| `.txt` | 34 | 1.6 |
| `(none)` | 21 | 0.0 |
| `.xml` | 20 | 1.4 |
| `.json` | 14 | 0.2 |
| `.ifc` | 7 | 63.8 |
| `.ies` | 7 | 0.0 |
| `.fcstd` | 6 | 0.1 |
| `.cc` | 4 | 0.8 |
| `.py` | 3 | 0.0 |
| `.idf` | 2 | 1.4 |
| `.ply` | 2 | 5.2 |
| `.xls` | 1 | 0.7 |
| `.hh` | 1 | 0.1 |

## Token & Gemini cost estimate — reading every input document once

- PDF pages ≈ 15,176 × 258 tok/page ≈ **3.9M** tokens (older-Gemini default; **Gemini 4 Hydrogen bills 560 tok/page → ≈ 8.5M**, images 1,120 tok each)
- Text-like files (109.6 MB ÷ 4 chars/token) ≈ **27.4M** — mostly large data files (`.csv` 34 MB, `.ifc`/`.xml`/`.json` models & logs) that an agent would query with code rather than read whole, so a realistic 'read' is closer to **~10–15M** tokens (≈ $10–30 on Gemini 3.8 Flash)
- XLSX/DOCX (rough, after conversion) ≈ **3.3M** · Images (34) ≈ **0.03M**
- **Total input ≈ 34.6M tokens**, assumed output ≈ 3.5M (10%)

| Model | $/1M in / out | One full read |
|---|---|--:|
| Gemini 3.8 Flash (promo → Dec 31) | $0.75 / $3.75 | **$39** |
| Gemini 3.8 Flash (from Jan 1, 2027) | $1.5 / $7.5 | **$78** |
| Gemini 3.1 Pro Preview (≤200K ctx) | $2 / $12 | **$111** |
| Gemini 4 Argon (promo → Nov 30) | $2 / $10 | **$104** |
| Gemini 4 Argon (from Dec 1) | $4 / $20 | **$208** |
| Gemini 4 Hydrogen (not a Stage 2 model; Stage 1 only) | $1.5 / $7.5 | **~$85** raw · ~$30–40 realistic |
| Gemma 4 26B | $0.15 / $0.6 | **$7** |

> ⚠️ A real **agent run** costs far more than one read: the agent re-sends its growing context every step (paper: up to ~27M tokens/task for the top config). Community estimates for one full 29-task dev run: **~$60–100 on Gemini 3.8 Flash, ~$150–260 on Gemini 4 Argon**. Cap tokens/steps per task in your harness and set a GCP budget alert. See `../01-competition/code/ple-dev-effects-over-0-03-held-on-test-19-of-22.md`.


## Task briefs (from task_cards.jsonl)

| Task | Discipline | Grading | Title — summary |
|---|---|---|---|
| backfeed-energization-reply | electrical | rubric | **Reply on a community solar site's backfeed energization date** — Assess whether a community solar site can be energized for backfeed on the requested date, draft the developer response, and initiate the work package. |
| cooling-water-flush-plan | mechanical | checks | **Flushing and passivation of a data hall's process cooling water** — Develop the cleaning, flushing, and passivation procedure for a data hall's process cooling water loop. |
| data-center-site-model | civil | checks | **Feasible data-center site design as an IFC model** — Generate an IFC site model for a two-phase data-center campus that satisfies all requirements in its approval document. |
| data-hall-device-takeoff | electrical | checks | **Device takeoff and priced bill of materials for a data hall** — Complete an electrical device takeoff from a data hall's drawing set and price the bill of materials. |
| data-hall-mep-routing | mechanical | checks | **Clash-free MEP routing through a data hall** — Reconstruct a data hall from seven drawing sheets and generate a clash-free IFC4 model routing cable tray, busway, and chilled-water piping. |
| data-hall-mep-routing-offset | mechanical | checks | **Clash-free MEP routing through a data hall on an offset structural grid** — Route MEP systems through a data hall where the structural grid is offset from the floor tiles, clearing a cross-aisle and 104 sprinkler heads. |
| division-26-specifications | electrical | checks | **Division 26 project specifications for an Army facility** — Write the Division 26 electrical specifications for an Army facility from its coordinated design package. |
| emergency-spillway-check | civil | rubric | **Emergency spillway check behind a plan-check comment** — Evaluate a stormwater basin's emergency spillway drawing against a plan-check comment and specify the required revisions in a memo. |
| engineers-estimate-check | civil | rubric | **Engineer's estimate checked before a bond conversation** — Verify a project section of an engineer's estimate against the construction plans before sending it to the surety broker. |
| eor-review-corrections | structural | checks-judge | **Issue an engineer-of-record review's corrections to two bid packages** — Incorporate engineer-of-record markups into an issued drawing revision across two bid packages, including comment dispositions, sheet index updates, and change documentation. |
| fill-compaction-acceptance | civil | rubric | **Acceptance of slab-on-grade fill compaction testing** — Check slab-on-grade fill compaction test records against the earthwork specification and issue a materials acceptance record. |
| fire-solve-convergence | mechanical | rubric | **Disposition of a non-converging fire-simulation solve** — Issue a signed disposition on a fire simulation's non-converging steady solve before a fourth run begins. |
| fire-test-validation-memo | mechanical | rubric | **Validation memo for a fire-resistance simulation against its test** — Evaluate whether a fire-resistance simulation is validated against furnace test data and write an engineering validation memo. |
| footing-settlement-verification | civil | rubric | **Settlement verification of a building block's spread footings on clay** — Verify the long-term settlement of a building block's spread footings on clay against the project record and issue the verification memo. |
| foundation-strategy | civil | checks-judge | **Spread footings or aggregate piers for six data-campus building pads** — Select spread footings or aggregate piers for six building pads from geotechnical records and deliver a design basis, schedule, and constraint register. |
| frame-extension-method | civil | checks | **Method package for a frame extension over an occupied floor** — Plan a steel frame extension over an occupied floor and check the construction method package against applicable safety regulations. |
| heat-rejection-life-cycle-cost | mechanical | checks | **Life-cycle cost of a condenser-water heat rejection replacement** — Design a condenser-water heat rejection replacement for a federal campus and justify the selection with a life-cycle cost analysis. |
| landscape-sheet-revision | civil | rubric | **Street-tree revision worked into a landscape resubmittal** — Incorporate a street-tree review comment into a landscape drawing set and check the package for agency resubmittal. |
| les-mesh-resolution | mechanical | rubric | **Mesh-resolution basis for an LES fire case** — Document the mesh-resolution basis of a large-eddy fire simulation to close out a peer-review comment. |
| lv-cable-sizing | electrical | checks-judge | **Low-voltage wire schedule with voltage drop and duct-bank ampacity** — Size a building's low-voltage wire schedule for voltage drop, duct-bank ampacity, and cost, complete with a constraint register and design basis. |
| mv-conveyance-study | electrical | checks | **Conveyance study for a 13.8 kV site distribution** — Complete the conveyance study and cost workbook for seven medium-voltage circuits in a 13.8 kV site distribution system. |
| permission-to-operate-memo | electrical | rubric | **Permission-to-operate memo for an office complex's PV system** — Determine whether a utility operations center can grant permission to operate for a PV site on the requested date and initiate the work package. |
| pre-application-capacity-response | electrical | rubric | **Response to a pre-application request for feeder capacity** — Draft a utility response to a developer's pre-application capacity request for a distribution feeder and close out the tracking record. |
| roof-deck-design | structural | checks | **Roof deck design for gravity and lateral loads** — Design a data center's steel roof deck for gravity and lateral loads, specifying gauge, fastener pattern, and diaphragm capacity. |
| seismic-diaphragm-shear | structural | checks | **Seismic diaphragm shears and shear-wall loads** — Compute the seismic diaphragm shears and shear-wall loads for a data-center lateral force-resisting system. |
| shoring-design-verification | civil | rubric | **Verification of a revised shoring design ahead of an excavation** — Verify a revised excavation shoring design against logged groundwater and subsurface conditions prior to excavation. |
| solar-supplemental-review | electrical | rubric | **Supplemental interconnection review memo for a solar project** — Write the supplemental interconnection review memo for a solar application on a distribution feeder. |
| solar-witness-test-package | electrical | rubric | **Witness-test scope and schedule for municipal solar arrays** — Prepare the witness-test scope and schedule for municipal solar arrays that require testing, and identify those that do not. |
| wind-diaphragm-shear | structural | checks | **Roof diaphragm shears and shear-wall loads for wind** — Compute the wind roof-diaphragm shears and shear-wall loads for a single-story data hall. |