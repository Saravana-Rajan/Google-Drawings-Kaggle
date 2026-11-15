# Dev-set artifacts (29 tasks)

These are the outputs of Pi on Claude Opus 5.5, stored in `artifacts/` of the template.

## manifest.json summary

- `format`: 1. `created`: 2026-10-20T03:33:56Z. `dev_set`: `ce9ebf50...a123`.
- Harness: `name` my-harness, `model_api` google-cloud/claude-opus-5-5, commit `6ab05b9f`, `dirty`: false, tree `35113078...`. The manifest stores git blob hashes for all 12 harness files.
- Each task entry has run `b96-r1`, `ended`, `reward`, the deliverable file hashes, the `final_message` hash, `deleted` and `skipped`.
- All 29 tasks have `ended: ok`. **Mean reward 0.491.** Two tasks scored 1.0 and four scored 0.0. **The manifest has no cost or token fields.**
- Discipline is listed only when the deliverable path names it (`electrical`, `mechanical`, `structural`, `field_eng`). Otherwise it is "-".

| Task id | Discipline (stated) | Deliverable (from final_message.md) | Output files (under `files/`) | Reward |
|---|---|---|---|---|
| backfeed-energization-reply | - | Reply letter refusing to confirm 07/29/2025 backfeed energization of Site 3 (permit not final, drawing issues), plus OpenProject WP #47 | `filesystem/Halbray_Backfeed_Reply.docx`, `app/output/.helpers_cache/db_diff.{log,txt}` | 1.000 |
| cooling-water-flush-plan | mechanical | PCW flushing/hydrotest programme for 8 circuits ($48,808, done by hour 721), 7-file package | `filesystem/final_batch4__mechanical_task5_pcw_flush_mop__blind/output/submission.zip` | 0.461 |
| data-center-site-model | - | Data-center campus site layout (roads, data halls, phases) as IFC4 | `app/files/frontier__DCBim__p6_002/submission/model.ifc` | 1.000 |
| data-hall-device-takeoff | electrical | Device takeoff: takeoff/locations/bom/register CSVs + basis.md from the E-001 legend | `filesystem/final_batch4__electrical_task17_ec_0205_d100__blind/output/submission.zip` | 0.383 |
| data-hall-mep-routing | - | ifcopenshell script that builds the hall and routes three MEP services into IFC4 | `app/files/dc_model__hall_seed000_d000__mep_routing/output/solution.py` | 0.000 |
| data-hall-mep-routing-offset | - | Same as above for the offset hall variant; all routing under the floor | `app/files/dc_model__hall_seed005_d100__mep_routing/output/solution.py` | 0.000 |
| division-26-specifications | electrical | Six tailored UFGS Division 26 sections + design_basis.xlsx | `filesystem/final_batch4__electrical_task8_electrical_specs__blind/output/submission.zip` | 0.349 |
| emergency-spillway-check | - | 13-page memo: the drawn emergency spillway is undersized, with freeboard errors, calcs and revised C-9 wording | `filesystem/Memo_to_Callaway_Spillway_2026-10-31.docx` | 0.622 |
| engineers-estimate-check | - | Memo correcting Section 2 subtotal ($1,309,439) and bond figure ($5,390,000) | `filesystem/Correspondence/Client/Memo_to_Callaway_2026-10-31.docx` | 0.543 |
| eor-review-corrections | structural (`dc_structural`) | EOR revision plan for BP-2/BP-3 (amendment vs re-issue), 7-file package | `filesystem/dc_structural__eor_revision__blind/output/submission.zip` | 0.302 |
| fill-compaction-acceptance | - | Materials acceptance record: Lift 6 fill tests FD-14 to FD-17 REJECTED | `filesystem/Thelbridge_Materials_Acceptance_Fill_Compaction_2026-0708.docx`, `filesystem/Thelbridge_Materials_Acceptance_Record_TEMPLATE.docx`, `filesystem/Fill_Placement_Records_BlockA_SlabOnGrade.xlsx` | 0.676 |
| fire-solve-convergence | - | Technical note: the transient fire-solve plateau is plume puffing (0.87 Hz), not numerical; plus a runtime email | `filesystem/CFDME-2025-041_transient_solve_disposition_revA.docx`, `filesystem/20251009_Falk_runtime_projection_basis.eml` | 0.636 |
| fire-test-validation-memo | - | Validation memo: companion run vs certified E119 test is +13 min, outside criterion | `app/files/output/CFDME-2025-041_E119_validation_memo_revA.docx` | 0.808 |
| footing-settlement-verification | - | Item 051 verification memo: NOT VERIFIED (consolidation settlement about 5 in, never computed) | `filesystem/Thelbridge_Verification_Memo_Item051_BlockC.docx`, `filesystem/Thelbridge_Verification_Memo_TEMPLATE_v1.docx` | 0.532 |
| foundation-strategy | - | None. The final message is just "[tool call]"; the run ended with no deliverable | (none) | 0.000 |
| frame-extension-method | field_eng | Constructability 4D package: 294-activity sequence, stability/occupancy checks, done by day 214 | `filesystem/field_eng__constructability_4d__blind/output/submission.zip` | 0.806 |
| heat-rejection-life-cycle-cost | mechanical | Cooling-tower selection/LCC for CUP, ANNEX and LAB: 3 DXFs, 3 workbooks, register, basis | `filesystem/final_batch4__mechanical_task3_ct_heat_lcc__blind/output/submission.zip` | 0.692 |
| landscape-sheet-revision | - | Memo: the 11/30 L-4 street-tree revision date can't be committed until 4 prerequisites clear | `app/files/output/DSR_Ph3_L-4_Street_Tree_Memo_to_Callaway_2026-10-31.docx` | 0.857 |
| les-mesh-resolution | - | Resolution note: LES mesh index is about 30 (finer than the 5-10 band); item closable without new runs | `filesystem/CFDME-2025-041_resolution_note_revA.docx` | 0.537 |
| lv-cable-sizing | electrical | LV cable sizing for 32 circuits, $151,024.48 installed | `filesystem/electrical__lv_cable_sizing__blind/output/submission.zip` | 0.907 |
| mv-conveyance-study | electrical | MV conveyance study: 11-sheet workbook + report, 7 items / 34 options priced | `filesystem/final_batch4__electrical_task12_conveyance_study__blind/output/submission.zip` | 0.353 |
| permission-to-operate-memo | - | Memo: PTO cannot issue 08/04/2025 (no live telemetry with the recloser open), plus WP #47 | `filesystem/Corwyn_PTO_Memo.docx`, `app/output/.helpers_cache/db_diff.{log,txt}` | 0.909 |
| pre-application-capacity-response | - | Pre-application response: 0.8 MW indicative capacity on ALN-108 (not 3.0); case #44 closed | `filesystem/ALN-108_PreApplication_Response.docx`, `app/output/.helpers_cache/db_diff.{log,txt}` | 0.231 |
| roof-deck-design | structural | Roof deck design: 3 zones, 2 gages, $233,642 (xlsx, dxf, register, basis) | `filesystem/final_batch4__structural_task7_roof_deck_design__blind/output/submission.zip` | 0.286 |
| seismic-diaphragm-shear | structural | Seismic diaphragm design, cases S01-S12, $340,195 (record, plan, workbook, register, basis) | `filesystem/final_batch4__structural_task6_seismic_diaphragm_shear__blind/output/submission.zip` | 0.316 |
| shoring-design-verification | - | Item 048 shoring verification memo: NOT VERIFIED (su 1,400 vs 900-1,100 psf; FS 0.31-0.81) | `filesystem/Thelbridge_Verification_Memo_Item048_BlockB.docx`, `filesystem/Thelbridge_Verification_Memo_TEMPLATE_v2.docx`, `filesystem/Kesterline_31-SH-B_Rev2_Supplement_KE-L-2026-0713.pdf` | 0.516 |
| solar-supplemental-review | - | Superseding screen memo: Bramwick Commons passes the minimum-load screen (daytime minimum) | `filesystem/Bramwick_Commons_Screen_Memo.docx` | 0.208 |
| solar-witness-test-package | - | None. The run stopped mid-task ("Now the case tracking in OpenProject...") | (none) | 0.000 |
| wind-diaphragm-shear | structural | Wind diaphragm package: lateral schedule, plan DXF, register, 19-page calcs PDF, basis | `filesystem/final_batch4__structural_task5_wind_diaphragm_shear__blind/output/submission.zip` | 0.316 |

Every task folder also contains `final_message.md` and `trajectory.json`.

## Observations
- Four zeros: both MEP-routing `solution.py` tasks, and two runs that ended without a deliverable or summary (foundation-strategy, solar-witness-test-package). The two runs that ended with nothing are the clearest place to gain points.
- Memo/letter (.docx) tasks average higher than the multi-file `submission.zip` design packages (structural packages about 0.29-0.32).
- `app/output/.helpers_cache/db_diff.*` appears on the three utility/OpenProject tasks. These are captured app-state diffs, not files the agent wrote.
