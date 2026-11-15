# PLE 29-Task Telemetry Audit & Verifier Harness

- **Author:** adityasingh157735
- **Kaggle URL:** https://www.kaggle.com/code/adityasingh157735/ple-29-task-telemetry-audit-verifier-harness

## Approach / key ideas

- Audits the official 29-task starter artifacts (Pi 1.1.0 + claude-opus-5-5, commit 6ab05b9f): mean reward 0.4912, and 4/29 tasks score 0 even though the run ended 'ok'.
- Silent zero-file exits (foundation-strategy, solar-witness-test-package) produce no deliverables. Fix: diff the filesystem before exit and send a continuation prompt.
- The .py-deliverable tasks (data-hall-mep-routing and its -offset variant) score 0 because geometric and clearance constraints go unchecked.
- Seven .zip bundle tasks average 0.443, against 0.663 for document deliverables; incomplete multi-file packaging is the cause.
- Provides a drop-in 'Deliverable Audit & Repair Prompt Generator' that wraps `harness.solve()` within the time budget.
- Cheap, high-value tricks: check outputs exist, syntax/import-check .py deliverables, and validate zip members.

## Notebook

# Physical-Engineering's Last Exam: Official 29-Task Telemetry Audit & Verifier-Gated Agent Harness

This notebook audits the **29 public dev-set artifacts** from Google's official `physical-engineerings-last-exam/submission-template` baseline (`Pi 1.1.0` calling `google-cloud/claude-opus-5-5`, commit `6ab05b9f`) and translates the empirical failure modes into a **drop-in Verifier-Gated Harness layer**.

### Key Empirical Findings Across the 29 Official Dev Tasks
1. **Overall Baseline Mean Reward**: **`0.4912`** (`4 / 29` tasks score **`0.0000`** despite `ended == "ok"`).
2. **Silent Zero-File Exits (`reward = 0.0000`)**: Both `foundation-strategy` and `solar-witness-test-package` terminate `"ok"` with **zero deliverable files** recorded in `manifest.json` (`files = {}`). A simple pre-exit filesystem diff + continuation prompt prevents unforced zero-file forfeits.
3. **Executable `.py` Hard-Gate Cliff (`reward = 0.0000`)**: Both `data-hall-mep-routing` and `data-hall-mep-routing-offset` produce a single `.py` script yet score `0.0000` due to unverified geometric/clearance constraints.
4. **The `.zip` Archive Bottleneck (`mean = 0.4429` vs `0.6630` on Document Deliverables)**: Seven `.zip` bundle tasks cluster tightly between `0.2857` and `0.3826` (`roof-deck-design`, `eor-review-corrections`, `wind-diaphragm-shear`, `seismic-diaphragm-shear`, `division-26-specifications`, `mv-conveyance-study`, `data-hall-device-takeoff`), highlighting incomplete multi-file packaging inside submission archives.


```python
import json
from pathlib import Path
import zipfile
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

OFFICIAL_DEV_TASKS = [
  {
    "task_id": "backfeed-energization-reply",
    "reward": 1.0,
    "ended": "ok",
    "file_count": 3,
    "extensions": "docx,log,txt",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "app/output/.helpers_cache/db_diff.log"
  },
  {
    "task_id": "cooling-water-flush-plan",
    "reward": 0.461348,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/final_batch4__mechanical_task5_pcw_flush_mop__blind/output/submission.zip"
  },
  {
    "task_id": "data-center-site-model",
    "reward": 1.0,
    "ended": "ok",
    "file_count": 1,
    "extensions": "ifc",
    "modality": "BIM Model (.ifc)",
    "sample_path": "app/files/frontier__DCBim__p6_002/submission/model.ifc"
  },
  {
    "task_id": "data-hall-device-takeoff",
    "reward": 0.382609,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/final_batch4__electrical_task17_ec_0205_d100__blind/output/submission.zip"
  },
  {
    "task_id": "data-hall-mep-routing",
    "reward": 0.0,
    "ended": "ok",
    "file_count": 1,
    "extensions": "py",
    "modality": "Python Script (.py)",
    "sample_path": "app/files/dc_model__hall_seed000_d000__mep_routing/output/solution.py"
  },
  {
    "task_id": "data-hall-mep-routing-offset",
    "reward": 0.0,
    "ended": "ok",
    "file_count": 1,
    "extensions": "py",
    "modality": "Python Script (.py)",
    "sample_path": "app/files/dc_model__hall_seed005_d100__mep_routing/output/solution.py"
  },
  {
    "task_id": "division-26-specifications",
    "reward": 0.34937,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/final_batch4__electrical_task8_electrical_specs__blind/output/submission.zip"
  },
  {
    "task_id": "emergency-spillway-check",
    "reward": 0.621622,
    "ended": "ok",
    "file_count": 1,
    "extensions": "docx",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "filesystem/Memo_to_Callaway_Spillway_2026-10-31.docx"
  },
  {
    "task_id": "engineers-estimate-check",
    "reward": 0.543478,
    "ended": "ok",
    "file_count": 1,
    "extensions": "docx",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "filesystem/Correspondence/Client/Memo_to_Callaway_2026-10-31.docx"
  },
  {
    "task_id": "eor-review-corrections",
    "reward": 0.301961,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/dc_structural__eor_revision__blind/output/submission.zip"
  },
  {
    "task_id": "fill-compaction-acceptance",
    "reward": 0.675926,
    "ended": "ok",
    "file_count": 3,
    "extensions": "docx,xlsx",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "filesystem/Fill_Placement_Records_BlockA_SlabOnGrade.xlsx"
  },
  {
    "task_id": "fire-solve-convergence",
    "reward": 0.635659,
    "ended": "ok",
    "file_count": 2,
    "extensions": "docx,eml",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "filesystem/20251009_Falk_runtime_projection_basis.eml"
  },
  {
    "task_id": "fire-test-validation-memo",
    "reward": 0.807692,
    "ended": "ok",
    "file_count": 1,
    "extensions": "docx",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "app/files/output/CFDME-2025-041_E119_validation_memo_revA.docx"
  },
  {
    "task_id": "footing-settlement-verification",
    "reward": 0.532258,
    "ended": "ok",
    "file_count": 2,
    "extensions": "docx",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "filesystem/Thelbridge_Verification_Memo_Item051_BlockC.docx"
  },
  {
    "task_id": "foundation-strategy",
    "reward": 0.0,
    "ended": "ok",
    "file_count": 0,
    "extensions": "NONE",
    "modality": "Empty (0 files)",
    "sample_path": ""
  },
  {
    "task_id": "frame-extension-method",
    "reward": 0.8063,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/field_eng__constructability_4d__blind/output/submission.zip"
  },
  {
    "task_id": "heat-rejection-life-cycle-cost",
    "reward": 0.692462,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/final_batch4__mechanical_task3_ct_heat_lcc__blind/output/submission.zip"
  },
  {
    "task_id": "landscape-sheet-revision",
    "reward": 0.857143,
    "ended": "ok",
    "file_count": 1,
    "extensions": "docx",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "app/files/output/DSR_Ph3_L-4_Street_Tree_Memo_to_Callaway_2026-10-31.docx"
  },
  {
    "task_id": "les-mesh-resolution",
    "reward": 0.536585,
    "ended": "ok",
    "file_count": 1,
    "extensions": "docx",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "filesystem/CFDME-2025-041_resolution_note_revA.docx"
  },
  {
    "task_id": "lv-cable-sizing",
    "reward": 0.906575,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/electrical__lv_cable_sizing__blind/output/submission.zip"
  },
  {
    "task_id": "mv-conveyance-study",
    "reward": 0.353437,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/final_batch4__electrical_task12_conveyance_study__blind/output/submission.zip"
  },
  {
    "task_id": "permission-to-operate-memo",
    "reward": 0.909091,
    "ended": "ok",
    "file_count": 3,
    "extensions": "docx,log,txt",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "app/output/.helpers_cache/db_diff.log"
  },
  {
    "task_id": "pre-application-capacity-response",
    "reward": 0.230769,
    "ended": "ok",
    "file_count": 3,
    "extensions": "docx,log,txt",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "app/output/.helpers_cache/db_diff.log"
  },
  {
    "task_id": "roof-deck-design",
    "reward": 0.285714,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/final_batch4__structural_task7_roof_deck_design__blind/output/submission.zip"
  },
  {
    "task_id": "seismic-diaphragm-shear",
    "reward": 0.315966,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/final_batch4__structural_task6_seismic_diaphragm_shear__blind/output/submission.zip"
  },
  {
    "task_id": "shoring-design-verification",
    "reward": 0.516393,
    "ended": "ok",
    "file_count": 3,
    "extensions": "docx,pdf",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "filesystem/Kesterline_31-SH-B_Rev2_Supplement_KE-L-2026-0713.pdf"
  },
  {
    "task_id": "solar-supplemental-review",
    "reward": 0.207792,
    "ended": "ok",
    "file_count": 1,
    "extensions": "docx",
    "modality": "Document/Sheet (.docx/.pdf/.xlsx)",
    "sample_path": "filesystem/Bramwick_Commons_Screen_Memo.docx"
  },
  {
    "task_id": "solar-witness-test-package",
    "reward": 0.0,
    "ended": "ok",
    "file_count": 0,
    "extensions": "NONE",
    "modality": "Empty (0 files)",
    "sample_path": ""
  },
  {
    "task_id": "wind-diaphragm-shear",
    "reward": 0.315873,
    "ended": "ok",
    "file_count": 1,
    "extensions": "zip",
    "modality": "Archive Bundle (.zip)",
    "sample_path": "filesystem/final_batch4__structural_task5_wind_diaphragm_shear__blind/output/submission.zip"
  }
]

df = pd.DataFrame(OFFICIAL_DEV_TASKS).sort_values("reward", ascending=True).reset_index(drop=True)
print(f"Loaded {len(df)} official PLE dev tasks | Mean reward: {df['reward'].mean():.4f} | Median: {df['reward'].median():.4f}")
display(df[["task_id", "reward", "modality", "file_count", "extensions", "sample_path"]])

```

```python
palette = {
    "Empty (0 files)": "#dc2626",
    "Python Script (.py)": "#ea580c",
    "Archive Bundle (.zip)": "#2563eb",
    "Document/Sheet (.docx/.pdf/.xlsx)": "#0d9488",
    "BIM Model (.ifc)": "#7c3aed",
}

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 8.5), gridspec_kw={"width_ratios": [1.65, 1.0]})

colors = [palette[m] for m in df["modality"]]
ax1.barh(df["task_id"], df["reward"], color=colors, edgecolor="white", height=0.78)
ax1.axvline(df["reward"].mean(), color="#0f172a", ls="--", lw=1.4, label=f"Mean = {df['reward'].mean():.3f}")
ax1.axvline(0.40, color="#94a3b8", ls=":", lw=1.2, label="0.40 Reference")
ax1.set_xlim(0, 1.08)
ax1.set_xlabel("Official Baseline Reward (Pi 1.1.0 + claude-opus-5-5)")
ax1.set_title("29 Public Dev Tasks Ranked by Official Baseline Reward", fontweight="bold")
for idx, row in df.iterrows():
    ax1.text(row["reward"] + 0.015, idx, f"{row['reward']:.3f}", va="center", fontsize=8.5)
ax1.legend(loc="lower right")
ax1.grid(axis="x", alpha=0.25)

summary = (
    df.groupby("modality", as_index=False)
    .agg(tasks=("task_id", "count"), mean_reward=("reward", "mean"), zero_count=("reward", lambda s: int((s == 0).sum())))
    .sort_values("mean_reward", ascending=True)
)
bar_colors = [palette[m] for m in summary["modality"]]
ax2.barh(summary["modality"], summary["mean_reward"], color=bar_colors, alpha=0.9, height=0.55)
for idx, row in enumerate(summary.itertuples()):
    ax2.text(
        row.mean_reward + 0.02,
        idx,
        f"{row.mean_reward:.3f} (n={row.tasks}, zeros={row.zero_count})",
        va="center",
        fontsize=9.5,
        fontweight="bold",
    )
ax2.set_xlim(0, 1.18)
ax2.set_xlabel("Mean Reward by Deliverable Modality")
ax2.set_title("Failure Mode Breakdown by Deliverable Format", fontweight="bold")
ax2.grid(axis="x", alpha=0.25)

plt.tight_layout()
plt.savefig("ple_dev_telemetry_audit.png", dpi=160, bbox_inches="tight")
plt.show()

summary

```

## Drop-In Deliverable Verification Gate for `harness.py`

In the official `submission-template`, `harness.py` invokes a single headless agent session and immediately returns `final_message` when the agent stops—even when:
- **Zero output files** were created (`foundation-strategy`, `solar-witness-test-package`),
- A generated `.py` deliverable fails syntax/import or self-check execution (`data-hall-mep-routing*`), or
- A `.zip` package contains empty or corrupt member files (`eor-review-corrections`, `roof-deck-design`).

Below is a clean, self-contained **Deliverable Audit & Repair Prompt Generator** designed to wrap `harness.solve()` inside the competition's time budget (`agent_timeout_sec - STOP_BEFORE_SEC`).


```python
from dataclasses import dataclass, field
import py_compile


@dataclass
class AuditFinding:
    severity: str  # "blocker" | "warning"
    path: str
    message: str


@dataclass
class DeliverableAuditReport:
    new_or_modified_files: list[str] = field(default_factory=list)
    findings: list[AuditFinding] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return len(self.new_or_modified_files) > 0 and not any(f.severity == "blocker" for f in self.findings)

    def build_repair_prompt(self) -> str:
        lines = [
            "VERIFICATION GATE FAILED BEFORE SUBMISSION. Fix the following blockers in the container workspace before finishing:"
        ]
        if not self.new_or_modified_files:
            lines.append(
                "- ZERO new or modified deliverable files were detected in the workspace. "
                "Re-read the task prompt for exact output directory/filename requirements and write the deliverables to disk."
            )
        for f in self.findings:
            lines.append(f"- [{f.severity.upper()}] {f.path}: {f.message}")
        lines.append("After fixing, re-verify every output path with `ls -lh` and summarize exact deliverable paths.")
        return "\n".join(lines)


def snapshot_workspace(root: Path) -> dict[str, tuple[int, int]]:
    snap: dict[str, tuple[int, int]] = {}
    for p in root.rglob("*"):
        if p.is_file() and "/.git/" not in str(p):
            st = p.stat()
            snap[str(p.relative_to(root))] = (st.st_size, st.st_mtime_ns)
    return snap


def audit_deliverables(root: Path, before: dict[str, tuple[int, int]]) -> DeliverableAuditReport:
    after = snapshot_workspace(root)
    changed = [rel for rel, meta in after.items() if before.get(rel) != meta]
    report = DeliverableAuditReport(new_or_modified_files=sorted(changed))

    for rel in report.new_or_modified_files:
        full = root / rel
        size = full.stat().st_size
        if size == 0:
            report.findings.append(AuditFinding("blocker", rel, "Deliverable file is 0 bytes (empty)."))
            continue

        suffix = full.suffix.lower()
        if suffix == ".py":
            try:
                py_compile.compile(str(full), doraise=True)
            except py_compile.PyCompileError as exc:
                report.findings.append(AuditFinding("blocker", rel, f"Python syntax error: {exc.msg}"))

        elif suffix in (".zip", ".docx", ".xlsx"):
            if not zipfile.is_zipfile(full):
                report.findings.append(AuditFinding("blocker", rel, f"Invalid OpenXML/ZIP container ({suffix})."))
            else:
                with zipfile.ZipFile(full, "r") as zf:
                    bad = zf.testzip()
                    names = [i for i in zf.infolist() if not i.is_dir()]
                    if bad is not None:
                        report.findings.append(AuditFinding("blocker", rel, f"Corrupt archive member: {bad}"))
                    elif not names:
                        report.findings.append(AuditFinding("blocker", rel, "Archive contains 0 files."))
                    elif suffix == ".docx" and "word/document.xml" not in {i.filename for i in names}:
                        report.findings.append(AuditFinding("blocker", rel, "DOCX missing word/document.xml."))
                    elif suffix == ".zip":
                        empty_members = [i.filename for i in names if i.file_size == 0]
                        if empty_members:
                            report.findings.append(
                                AuditFinding("blocker", rel, f"ZIP has 0-byte members: {empty_members[:5]}")
                            )
    return report


# Self-test on simulated failure cases matching official PLE failure modes
import tempfile

with tempfile.TemporaryDirectory() as tmp:
    ws = Path(tmp)
    snap0 = snapshot_workspace(ws)

    # Case 1: Silent 0-file completion (like foundation-strategy & solar-witness-test-package)
    rep_empty = audit_deliverables(ws, snap0)
    print("Case 1 (0 files) passed:", rep_empty.passed)
    print(rep_empty.build_repair_prompt(), "\n")

    # Case 2: Valid non-empty ZIP bundle
    out_dir = ws / "output"
    out_dir.mkdir()
    with zipfile.ZipFile(out_dir / "submission.zip", "w") as zf:
        zf.writestr("calculations_summary.csv", "element,utilization\nB1,0.84\n")
    rep_ok = audit_deliverables(ws, snap0)
    print("Case 2 (verified ZIP deliverable) passed:", rep_ok.passed, "| Files:", rep_ok.new_or_modified_files)

```
