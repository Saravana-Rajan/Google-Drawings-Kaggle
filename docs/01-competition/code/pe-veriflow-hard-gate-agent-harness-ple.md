# PE-VeriFlow Hard-Gate Agent Harness PLE

- **Author:** robinamirbahar
- **Kaggle URL:** https://www.kaggle.com/code/robinamirbahar/pe-veriflow-hard-gate-agent-harness-ple

## Approach / key ideas

- PE-VeriFlow: a 3-gate verification loop. Gate 1 checks authority and revision precedence; Gate 2 runs coupled physics solvers (Neher-McGrath thermal, lug-capped voltage drop, datum/3D headroom); Gate 3 is a cold-read deliverable auditor.
- Reference point is the starter baseline: 0.491 mean, 0.516 median, with 4 zero-score runs (Opus 5.5).
- Claims 10/10 hard gates covered by the coupled physics checks.
- Model routing matrix across 8 sponsored models plus gemini-4-carbon, Gemini 4 Argon and Claude Opus 5.5, with a reasoning-effort setting per model.
- Programmatic Gate-3 time budget: about 240s of work and a 90s self-check before submission.
- Heavy HTML styling; the useful content is in the Python gate code.

## Notebook

<div style="font-family:'Google Sans','Roboto','Segoe UI',sans-serif; background:#FFFFFF; border:1px solid #DADCE0; border-radius:14px; overflow:hidden; box-shadow:0 2px 6px rgba(60,64,67,0.10); margin-bottom:20px;">
  <div style="display:flex; height:6px; width:100%;">
    <div style="flex:1; background:#4285F4;"></div>
    <div style="flex:1; background:#EA4335;"></div>
    <div style="flex:1; background:#FBBC04;"></div>
    <div style="flex:1; background:#34A853;"></div>
  </div>
  <div style="padding:22px 26px 18px 26px;">
    <div style="display:flex; flex-wrap:wrap; justify-content:space-between; align-items:center; gap:10px; margin-bottom:10px;">
      <span style="background:#E8F0FE; color:#1A73E8; font-weight:700; font-size:11px; letter-spacing:0.9px; text-transform:uppercase; padding:5px 12px; border-radius:999px; border:1px solid #D2E3FC;">
        ROBINA MIRBAHAR &middot; GOOGLE DEVELOPER EXPERT
      </span>
      <span style="color:#5F6368; font-size:12px; font-weight:500;">
        Google &ndash; Agent Harness on Physical-Engineering&rsquo;s Last Exam (PLE)
      </span>
    </div>
    <div style="font-size:22px; font-weight:700; color:#202124; line-height:1.25; margin-bottom:6px;">
      PE-VeriFlow Agent Harness &mdash; Executable 3-Gate Verification for Physical Engineering
    </div>
    <div style="font-size:14px; color:#5F6368; line-height:1.5; margin-bottom:16px;">
      Hands-on Python implementation of my 3-Gate engineering verification loop (<b>Gate 1:</b> Authority &amp; Revision Precedence &rarr; <b>Gate 2:</b> Coupled Neher-McGrath Thermal, Lug-Capped Voltage-Drop &amp; 3D Spatial Solvers &rarr; <b>Gate 3:</b> Cold-Read Deliverable Auditor) across <b>Claude Opus 5.5</b>, <b>Gemini 4 Carbon</b> (<code>gemini-4-carbon</code>), and <b>Gemini 4 Argon</b>
    </div>
    <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(175px, 1fr)); gap:12px; margin-top:12px;">
      <div style="background:#FFFFFF; border:1px solid #DADCE0; border-top:3px solid #1A73E8; border-radius:10px; padding:12px 14px; box-shadow:0 1px 2px rgba(60,64,67,0.06);">
        <div style="font-size:11px; font-weight:700; color:#5F6368; text-transform:uppercase; letter-spacing:0.6px;">29-Task Starter Baseline</div>
        <div style="font-size:17px; font-weight:700; color:#202124; margin:4px 0 2px 0;">0.491 Mean &middot; 0.516 Med</div>
        <div style="font-size:12px; color:#1A73E8; font-weight:500;">Starter b96-r1 Opus 5.5 (4 zero runs)</div>
      </div>
      <div style="background:#FFFFFF; border:1px solid #DADCE0; border-top:3px solid #1E8E3E; border-radius:10px; padding:12px 14px; box-shadow:0 1px 2px rgba(60,64,67,0.06);">
        <div style="font-size:11px; font-weight:700; color:#5F6368; text-transform:uppercase; letter-spacing:0.6px;">Coupled Physics Gates</div>
        <div style="font-size:17px; font-weight:700; color:#202124; margin:4px 0 2px 0;">10 / 10 Hard Gates</div>
        <div style="font-size:12px; color:#1E8E3E; font-weight:500;">Thermal, VD, Datum &amp; 3D Headroom</div>
      </div>
      <div style="background:#FFFFFF; border:1px solid #DADCE0; border-top:3px solid #9334E6; border-radius:10px; padding:12px 14px; box-shadow:0 1px 2px rgba(60,64,67,0.06);">
        <div style="font-size:11px; font-weight:700; color:#5F6368; text-transform:uppercase; letter-spacing:0.6px;">Model Routing Matrix</div>
        <div style="font-size:17px; font-weight:700; color:#202124; margin:4px 0 2px 0;">8 Sponsored + Carbon</div>
        <div style="font-size:12px; color:#9334E6; font-weight:500;">1M Ctx &middot; high (G) | max (C/GLM)</div>
      </div>
      <div style="background:#FFFFFF; border:1px solid #DADCE0; border-top:3px solid #F9AB00; border-radius:10px; padding:12px 14px; box-shadow:0 1px 2px rgba(60,64,67,0.06);">
        <div style="font-size:11px; font-weight:700; color:#5F6368; text-transform:uppercase; letter-spacing:0.6px;">Programmatic Gate-3</div>
        <div style="font-size:17px; font-weight:700; color:#202124; margin:4px 0 2px 0;">240s Work &middot; 90s Stop</div>
        <div style="font-size:12px; color:#E37400; font-weight:500;">Stdlib ZIP/XLSX/IFC/DXF cold audit</div>
      </div>
    </div>
  </div>
</div>

<div style="font-family:'Google Sans','Roboto','Segoe UI',sans-serif; margin:22px 0 12px 0; padding:10px 14px; background:#F8F9FA; border-left:4px solid #1E8E3E; border-radius:0 8px 8px 0;">
  <div style="font-size:11px; font-weight:700; color:#1E8E3E; text-transform:uppercase; letter-spacing:0.8px;">Section 01</div>
  <div style="font-size:17px; font-weight:700; color:#202124; margin-top:1px;">Environment, Google Material-3 Chart Styling &amp; Hard-Gate Survival Diagnostics</div>
  <div style="font-size:12.5px; color:#5F6368; margin-top:2px;">Configure reproducible Material-3 diagnostics and plot conjunctive $p^K$ hard-gate survival across coupled engineering checks</div>
</div>

```python
import csv
import hashlib
import io
import json
import math
import os
import tempfile
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import Circle, Rectangle
from IPython.display import display, HTML

np.random.seed(42)

# Apply Google Developer Material-3 Light Chart Theme
plt.rcParams.update({
    "figure.facecolor": "#FFFFFF",
    "axes.facecolor": "#F8F9FA",
    "axes.edgecolor": "#DADCE0",
    "axes.linewidth": 0.9,
    "axes.grid": True,
    "grid.color": "#E8EAED",
    "grid.linestyle": "--",
    "grid.linewidth": 0.7,
    "grid.alpha": 0.85,
    "axes.axisbelow": True,
    "axes.labelcolor": "#202124",
    "axes.titlesize": 11.2,
    "axes.titleweight": "bold",
    "axes.labelsize": 9.8,
    "xtick.color": "#5F6368",
    "ytick.color": "#5F6368",
    "xtick.labelsize": 8.8,
    "ytick.labelsize": 8.8,
    "legend.frameon": True,
    "legend.facecolor": "#FFFFFF",
    "legend.edgecolor": "#DADCE0",
    "legend.fontsize": 8.4,
    "font.family": "sans-serif",
    "savefig.facecolor": "#FFFFFF",
})

# Analytical p^K Hard-Gate Survival Law (Eq. 1 sensitivity) vs PLE Paper Sec. 5.3 Zero-Score Taxonomy
k_gates = np.arange(1, 19)
p_ref = [0.910, 0.950, 0.985]

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14.6, 4.5), dpi=130)

ax1.plot(k_gates, (p_ref[2] ** k_gates) * 100, "-o", color="#1E8E3E", lw=2.3, markersize=5.2,
         label=f"Analytical Eq. (1) High Per-Gate Reliability (p={p_ref[2]:.3f})")
ax1.plot(k_gates, (p_ref[1] ** k_gates) * 100, "-s", color="#1A73E8", lw=2.1, markersize=4.8,
         label=f"Analytical Eq. (1) Moderate Reliability (p={p_ref[1]:.2f})")
ax1.plot(k_gates, (p_ref[0] ** k_gates) * 100, "--^", color="#D93025", lw=2.2, markersize=5.2,
         label=f"Analytical Eq. (1) Unverified Baseline (p={p_ref[0]:.2f})")

ax1.axhline(41.3, color="#B31412", linestyle=":", lw=1.5, label="PLE Paper Co-Authored Hard-Gate Pass Rate (41.3%)")
ax1.scatter([10], [(p_ref[0] ** 10) * 100], color="#D93025", s=85, zorder=5)
ax1.annotate(
    "K=10 coupled gates:\n0.91^10 = 38.9% (~41.3% in PLE)",
    xy=(10, 38.9), xytext=(10.5, 20.0),
    arrowprops=dict(arrowstyle="->", color="#B31412", lw=1.3),
    fontsize=8.4, fontweight="bold", color="#B31412",
)
ax1.set_title("A. Analytical Conjunctive Survival Law (S = p^K, Eq. 1)")
ax1.set_xlabel("Coupled Hard Engineering Safety Gates per Deliverable (K)")
ax1.set_ylabel("All-Hard-Gates Survival Rate (%)")
ax1.set_ylim(0, 105)
ax1.legend(loc="lower left")

causes = [
    "Context / Timeout Crash (4.3%)",
    "Abrupt Early Termination (25.3%)",
    "Invalid Deliverable Written (70.4%)",
]
shares = [4.3, 25.3, 70.4]
bar_cols = ["#F9AB00", "#FA7B17", "#D93025"]
bars = ax2.barh(causes, shares, color=bar_cols, edgecolor="#202124", height=0.50)
for b in bars:
    w = b.get_width()
    ax2.text(w + 1.3, b.get_y() + b.get_height() / 2, f"{w:.1f}%", va="center", fontweight="bold", color="#202124", fontsize=9.2)
ax2.set_xlim(0, 84)
ax2.set_title("B. PLE Paper Sec. 5.3: Anatomy of 0.0-Score Runs (23.2% of Trials)")
ax2.set_xlabel("Share of Complete Zero-Score Failures (%)")

plt.tight_layout()
plt.show()

print(f"[Analytical Eq. (1) Survival @ K=10] p={p_ref[0]:.2f}->{p_ref[0]**10*100:.1f}% | p={p_ref[1]:.2f}->{p_ref[1]**10*100:.1f}% | p={p_ref[2]:.3f}->{p_ref[2]**10*100:.1f}%")
```

<div style="font-family:'Google Sans','Roboto','Segoe UI',sans-serif; margin:22px 0 12px 0; padding:10px 14px; background:#F8F9FA; border-left:4px solid #F9AB00; border-radius:0 8px 8px 0;">
  <div style="font-size:11px; font-weight:700; color:#E37400; text-transform:uppercase; letter-spacing:0.8px;">Section 02</div>
  <div style="font-size:17px; font-weight:700; color:#202124; margin-top:1px;">Multi-File Campus Engineering Corpus &amp; 10-Hard-Gate Physics Evaluator</div>
  <div style="font-size:12.5px; color:#5F6368; margin-top:2px;">Constructing an interdependent project folder with superseded specs, RFI overrides, 12-duct Neher-McGrath mutual heating, lug-capped voltage drop, and 3D headroom clashes</div>
</div>

### 2.1 Three Cross-Document Engineering Traps Embedded in `WORKDIR`
I materialize a **multi-file campus engineering workspace** (`specs/`, `geotech/`, `rfis/`, `drawings/`, `schedules/`, `output/`) mirroring the cross-document constraints in PLE's `lv-cable-sizing`, `data-hall-mep-routing-offset`, and `footing-settlement-verification` tasks:
- **Trap A (Document Precedence & RFI Backfill Override):** `EDS-26_Rev2_2025-04.md` (superseded) allows `3.5%` segment drop and waives mutual heating, while `CB-GEO-007_Preliminary.md` lists native clay $\rho = 0.95\text{ K}\cdot\text{m/W}$ and draft footing elevation `El. 740.5 ft`. Governing **`EDS-26_Rev4_2026-08.md`**, **`RFI-034`**, and **`S-201 Rev.4`** enforce $\rho = 0.60\text{ K}\cdot\text{m/W}$ fluidized backfill, strict `3.0%` segment / `5.0%` cumulative drop from `T-1` lugs with **no panel reset**, and footing bottom **`El. 746.0 ft`** (`+5.5 ft` datum shift).
- **Trap B (Coupled Leaf-to-Root Voltage Drop & 2D Mutual Heating):** Branch `B-17` is lug-capped at `#6 AWG CU` (`2.99%` drop). A greedy solver sizes parent feeder `F-05` at `2 sets of AL 500 kcmil` (`2.38% <= 3.0%` locally), pushing `SE-1 + F-05 + B-17` cumulative drop above **`5.00%`**. Simultaneously, packing `SE-1` (`2000 A` bus) into adjacent ducts `D1..D6` overheats center ducts past the **`75.0 C`** terminal lug limit under 2D Kennelly image-method mutual heating.
- **Trap C (Soft Prompt Preference vs. Hard 3D NFPA-13 Clash on `Sheet A-602`):** The prompt prefers overhead routing (`0..2600 mm`), but sprinkler deflectors at `+3024.6 mm` minus `460 mm` clearance cap overhead runs at **`+2564.6 mm < 2600.0 mm` minimum headroom**, requiring `100%` underfloor routing (`-60 mm` / `-480 mm`).

```python
WORKDIR = Path(tempfile.mkdtemp(prefix="ple_campus_corpus_"))
for folder in ("specs", "drawings", "geotech", "rfis", "schedules", "output"):
    (WORKDIR / folder).mkdir(parents=True, exist_ok=True)

(WORKDIR / "specs" / "EDS-26_Rev2_2025-04.md").write_text(
    "# Electrical Design Standard EDS-26 (Revision 2 - SUPERSEDED)\n"
    "- Feeder VD <= 3.5%; Total VD <= 5.5%; NEC Table 310.16 with 0.90 factor (mutual heating waived).\n"
    "- Service Entrance SE-1: 6x AL 600 kcmil in D1..D6 permitted.\n",
    encoding="utf-8",
)
(WORKDIR / "specs" / "EDS-26_Rev4_2026-08.md").write_text(
    "# Electrical Design Standard EDS-26 (Revision 4 - ISSUED FOR CONSTRUCTION, GOVERNING)\n"
    "- Sec 1.1: Supersedes Rev 2. Most restrictive rule governs under NFPA 70 (2023) & IBC (2024). RFIs govern.\n"
    "- Sec 2.1 (HARD GATE): Feeder VD <= 3.00%; Branch VD <= 3.00%; Cumulative T-1 lug VD <= 5.00% (NO reset).\n"
    "- Sec 2.3 (HARD GATE): SE-1 bus = 2000 A (derated ampacity >= 2000 A); main breaker trip = 1600 A (for VD).\n"
    "- DB-1 (3x4 12-duct bank, pitch=0.19m, depth=1.05m): Neher-McGrath T_cond <= 75.0 C; <= 4 sizes > #1 AWG.\n"
    "- Campus reel discount: 6.0% material discount when total conductor length >= 38,000 ft.\n",
    encoding="utf-8",
)
(WORKDIR / "geotech" / "CB-GEO-007_Preliminary.md").write_text(
    "# Geotechnical Draft CB-GEO-007\n- Native clay rho = 0.95 K*m/W. Assumed footing bottom: El. 740.5 ft (Not computed).\n",
    encoding="utf-8",
)
(WORKDIR / "rfis" / "RFI-034_Approved_Backfill_and_NOAA.md").write_text(
    "# RFI-034 Official Response (GOVERNING)\n"
    "1. DB-1 Backfill: Engineered thermal backfill rho = 0.60 K*m/W supersedes native 0.95 K*m/W.\n"
    "2. NOAA Ambient: 42.0 C outdoor, 46.0 C roof, 27.45 C earth at 1.05 m.\n",
    encoding="utf-8",
)
(WORKDIR / "drawings" / "A-602_and_S-201_Rev4_Callouts.md").write_text(
    "# Governing Drawing Callouts\n"
    "- Sheet S-201 Rev.4: Spread footing bottoms at El. 746.0 ft (+5.5 ft shift vs CB-GEO-007 El. 740.5 ft).\n"
    "- Sheet A-602 Rev.3: Sprinklers at +3024.6 mm AFF; 460.0 mm clearance -> +2564.6 mm max overhead < 2600.0 mm headroom.\n"
    "  Note 7: NO OVERHEAD PATHWAY ZONE IN THIS HALL. Route 100% in underfloor void (-60 mm / -480 mm).\n",
    encoding="utf-8",
)

circuits_rows = [
    ["SE-1", "T-1",  "service_feeder", 2000.0, 1600.0, 420.0, 6, 600.00, "duct_bank_DB1"],
    ["F-10", "SE-1", "sub_feeder",      580.0,  580.0, 360.0, 2, 600.00, "duct_bank_DB1"],
    ["F-05", "SE-1", "panel_feeder",    760.0,  760.0, 315.0, 3, 600.00, "indoor_conduit"],
    ["F-06", "SE-1", "panel_feeder",    420.0,  420.0, 290.0, 2, 500.00, "indoor_conduit"],
    ["F-08", "SE-1", "rooftop_feeder",  310.0,  310.0, 260.0, 1, 600.00, "rooftop_conduit"],
    ["B-17", "F-05", "branch_lug_cap",   44.0,   44.0, 165.0, 1,  26.25, "indoor_branch"],
    ["B-09", "F-05", "branch_lug_cap",   38.0,   38.0, 180.0, 1,  26.25, "indoor_branch"],
    ["B-12", "F-06", "branch_std",       52.0,   52.0, 145.0, 1,  41.74, "indoor_branch"],
    ["B-21", "F-10", "branch_pdu",      115.0,  115.0, 130.0, 1, 105.60, "indoor_branch"],
    ["B-24", "F-08", "branch_ahu",       82.0,   82.0, 115.0, 1,  66.36, "rooftop_conduit"],
]
with open(WORKDIR / "schedules" / "campus_circuit_schedule.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["circuit", "parent", "role", "ampacity_load_a", "vd_load_a", "one_way_length_ft", "max_sets", "max_lug_kcmil", "environment"])
    w.writerows(circuits_rows)

CONDUCTOR_CATALOG = [
    ("#6 AWG",    26.24, "CU", 0.4910, 0.051,  65.0,  1.45),
    ("#4 AWG",    41.74, "CU", 0.3080, 0.048,  85.0,  2.15),
    ("#2 AWG",    66.36, "CU", 0.1940, 0.045, 115.0,  3.25),
    ("#1/0 AWG", 105.60, "CU", 0.1220, 0.044, 150.0,  4.90),
    ("4/0 AWG",  211.60, "AL", 0.1000, 0.041, 180.0,  3.60),
    ("4/0 AWG",  211.60, "CU", 0.0608, 0.041, 230.0,  9.40),
    ("300 kcmil",300.00, "AL", 0.0707, 0.040, 230.0,  4.85),
    ("300 kcmil",300.00, "CU", 0.0429, 0.040, 285.0, 12.90),
    ("500 kcmil",500.00, "AL", 0.0424, 0.039, 310.0,  7.40),
    ("500 kcmil",500.00, "CU", 0.0258, 0.039, 380.0, 20.60),
    ("600 kcmil",600.00, "AL", 0.0353, 0.038, 340.0,  8.75),
    ("600 kcmil",600.00, "CU", 0.0214, 0.038, 420.0, 24.80),
]
CATALOG_BY_KEY = {
    (r[0], r[2]): {"size": r[0], "kcmil": r[1], "material": r[2], "r_ohm_kft": r[3], "x_ohm_kft": r[4], "amp_75c": r[5], "usd_ft": r[6]}
    for r in CONDUCTOR_CATALOG
}
DUCT_COORDS = {f"D{idx+1}": ((idx % 4) * 0.19, 1.05 + (idx // 4) * 0.19) for idx in range(12)}


def line_to_line_vd_pct(current_a: float, length_ft: float, sets: int, spec: dict[str, Any], pf: float = 0.90) -> float:
    sin_phi = math.sqrt(max(0.0, 1.0 - pf * pf))
    z_eff = spec["r_ohm_kft"] * pf + spec["x_ohm_kft"] * sin_phi
    v_drop = math.sqrt(3.0) * (current_a / sets) * (length_ft / 1000.0) * z_eff
    return (v_drop / 480.0) * 100.0


def neher_mcgrath_ductbank_temps(
    duct_assignments: dict[str, tuple[float, dict[str, Any]]],
    rho_soil: float = 0.60,
    t_earth_c: float = 27.45,
) -> dict[str, dict[str, float]]:
    q_w_m = {
        d_id: 3.0 * (i_set ** 2) * ((sp["r_ohm_kft"] / 1000.0) * 3.28084)
        for d_id, (i_set, sp) in duct_assignments.items()
    }
    results = {}
    for d_i, (i_set, sp) in duct_assignments.items():
        xi, yi = DUCT_COORDS[d_i]
        r_earth_self = (rho_soil / (2.0 * math.pi)) * math.log((2.0 * yi) / (0.115 / 2.0))
        dt_self = q_w_m[d_i] * (0.22 + r_earth_self)
        dt_mut = sum(
            q_j * (rho_soil / (2.0 * math.pi)) * math.log(math.hypot(xi - DUCT_COORDS[d_j][0], yi + DUCT_COORDS[d_j][1]) / math.hypot(xi - DUCT_COORDS[d_j][0], yi - DUCT_COORDS[d_j][1]))
            for d_j, q_j in q_w_m.items() if d_j != d_i
        )
        t_cond = t_earth_c + dt_self + dt_mut
        derated_amp = min(sp["amp_75c"], i_set * math.sqrt((75.0 - t_earth_c) / max(dt_self + dt_mut, 1e-6)))
        results[d_i] = {"t_cond_c": round(t_cond, 2), "dt_mutual_k": round(dt_mut, 2), "derated_amp_a": round(derated_amp, 1)}
    return results


def ambient_factor_75c(env_name: str) -> float:
    t_amb = 46.0 if env_name == "rooftop_conduit" else 30.0
    return 1.0 if t_amb <= 30.0 else math.sqrt((75.0 - t_amb) / 45.0)


def evaluate_engineering_submission(zip_path: Path) -> dict[str, Any]:
    gates, notes = {}, []
    with zipfile.ZipFile(zip_path, "r") as zf:
        names = set(zf.namelist())
        req = {"wire_schedule.csv", "design_record.json", "constraint_register.csv"}
        det_headers = all(info.date_time == (1980, 1, 1, 0, 0, 0) for info in zf.infolist())
        gates["H10_cold_read_archive"] = req.issubset(names) and det_headers
        ws_rows = list(csv.DictReader(io.StringIO(zf.read("wire_schedule.csv").decode("utf-8"))))
        record = json.loads(zf.read("design_record.json").decode("utf-8"))
        reg_rows = list(csv.DictReader(io.StringIO(zf.read("constraint_register.csv").decode("utf-8"))))

    sched_df = pd.read_csv(WORKDIR / "schedules" / "campus_circuit_schedule.csv").set_index("circuit")
    by_cid = {r["circuit"]: r for r in ws_rows}
    cited = " ".join(r.get("source_doc", "") for r in reg_rows)

    gates["H1_governing_revisions"] = (
        record.get("governing_elec_spec") == "EDS-26 Rev 4"
        and abs(float(record.get("db1_backfill_rho_k_m_w", 0.0)) - 0.60) < 1e-3
        and "RFI-034" in cited and len(reg_rows) >= 8
    )
    if not gates["H1_governing_revisions"]:
        notes.append("H1 FAIL: Cited superseded EDS-26 Rev 2 or missed RFI-034 backfill rho=0.60 K*m/W.")

    seg_drops, lug_ok, amp_ok_non_db, large_sizes = {}, True, True, set()
    tot_ft, raw_mat, labor = 0.0, 0.0, 0.0
    for cid, gt in sched_df.iterrows():
        r = by_cid[cid]
        sets = int(r["sets"])
        sp = CATALOG_BY_KEY[(r["size"], r["material"])]
        if sp["kcmil"] > 106.0:
            large_sizes.add(sp["size"])
        if sp["kcmil"] > float(gt["max_lug_kcmil"]) + 0.05 or sets > int(gt["max_sets"]):
            lug_ok = False
        seg_drops[cid] = line_to_line_vd_pct(float(gt["vd_load_a"]), float(gt["one_way_length_ft"]), sets, sp)
        if gt["environment"] != "duct_bank_DB1":
            f_grp = 1.0 if sets == 1 else 0.80
            cap = sets * sp["amp_75c"] * ambient_factor_75c(gt["environment"]) * f_grp
            if cap + 1e-6 < float(gt["ampacity_load_a"]):
                amp_ok_non_db = False
        c_ft = float(gt["one_way_length_ft"]) * sets * 4.0
        tot_ft += c_ft
        raw_mat += c_ft * sp["usd_ft"]
        labor += c_ft * (1.85 if sp["material"] == "CU" else 1.45)

    duct_map = {}
    for cid in ("SE-1", "F-10"):
        r = by_cid[cid]
        ducts = [d.strip() for d in r["ducts"].split(",") if d.strip()]
        sets = int(r["sets"])
        sp = CATALOG_BY_KEY[(r["size"], r["material"])]
        for d_id in ducts:
            duct_map[d_id] = (float(sched_df.loc[cid, "ampacity_load_a"]) / sets, sp)

    nm = neher_mcgrath_ductbank_temps(duct_map, rho_soil=0.60, t_earth_c=27.45)
    max_t = max(v["t_cond_c"] for v in nm.values())
    se1_ducts = [d.strip() for d in by_cid["SE-1"]["ducts"].split(",") if d.strip()]
    f10_ducts = [d.strip() for d in by_cid["F-10"]["ducts"].split(",") if d.strip()]
    se1_amp = min(nm[d]["derated_amp_a"] for d in se1_ducts) * int(by_cid["SE-1"]["sets"])
    f10_amp = min(nm[d]["derated_amp_a"] for d in f10_ducts) * int(by_cid["F-10"]["sets"])

    gates["H2_db1_thermal_le_75C"] = max_t <= 75.0
    if not gates["H2_db1_thermal_le_75C"]:
        notes.append(f"H2 FAIL: DB-1 conductor temp {max_t:.2f} C exceeds 75.0 C switchgear terminal rating.")
    gates["H3_derated_ampacity"] = amp_ok_non_db and (se1_amp >= 2000.0) and (f10_amp >= 580.0)
    if not gates["H3_derated_ampacity"]:
        notes.append(f"H3 FAIL: Derated ampacity below load (SE-1={se1_amp:.1f}A vs 2000A, F-10={f10_amp:.1f}A vs 580A).")
    gates["H4_segment_vd_le_3pct"] = all(v <= 3.0001 for v in seg_drops.values())

    cum_drops = {}
    for cid in sched_df.index:
        cur, tot_vd = cid, 0.0
        while cur in seg_drops:
            tot_vd += seg_drops[cur]
            parent = sched_df.loc[cur, "parent"]
            if parent == "T-1":
                break
            cur = parent
        cum_drops[cid] = tot_vd

    gates["H5_cumulative_vd_le_5pct"] = all(v <= 5.0001 for v in cum_drops.values())
    if not gates["H5_cumulative_vd_le_5pct"]:
        w_cid, w_vd = max(cum_drops.items(), key=lambda kv: kv[1])
        notes.append(f"H5 FAIL: Cumulative T-1->feeder->branch drop on {w_cid} = {w_vd:.2f}% > 5.00%.")
    gates["H6_lug_and_set_caps"] = lug_ok
    gates["H7_palette_le_4_sizes"] = len(large_sizes) <= 4
    gates["H8_3d_mep_clash_free"] = (record.get("mep_routing_zone") == "underfloor_void") and (float(record.get("mep_pathway_top_z_mm", 999)) <= 0.0)
    if not gates["H8_3d_mep_clash_free"]:
        notes.append("H8 FAIL: Overhead MEP zone (+2550mm) clashes with 460mm sprinkler buffer vs 2600mm headroom.")
    gates["H9_footing_datum_746ft"] = abs(float(record.get("governing_footing_el_ft", 0.0)) - 746.0) < 1e-2
    if not gates["H9_footing_datum_746ft"]:
        notes.append("H9 FAIL: Used draft CB-GEO-007 El. 740.5 ft instead of S-201 Rev.4 El. 746.0 ft.")

    disc = 0.06 if tot_ft >= 38000.0 else 0.0
    true_usd = raw_mat * (1.0 - disc) + labor
    cost_match = abs(float(record.get("installed_cost_usd", -1.0)) - true_usd) <= 2.0
    hard_pass = all(gates.values()) and cost_match
    cost_eff = max(0.0, min(1.0, 560000.0 / max(true_usd, 560000.0)))
    final_score = round(0.70 + 0.30 * cost_eff, 3) if hard_pass else 0.000

    return {
        "hard_pass": hard_pass, "final_score": final_score,
        "gates_passed": sum(1 for v in gates.values() if v),
        "installed_cost_usd": round(true_usd, 2), "total_conductor_ft": round(tot_ft, 1),
        "discount_applied": disc > 0, "max_db1_temp_c": round(max_t, 2),
        "se1_derated_amp_a": round(se1_amp, 1), "b17_cum_vd_pct": round(cum_drops["B-17"], 3),
        "gates": gates, "notes": notes,
    }

print(f"[CORPUS READY] {len(list(WORKDIR.rglob('*.*')))} project files materialized in {WORKDIR.name}")
```

<div style="font-family:'Google Sans','Roboto','Segoe UI',sans-serif; margin:22px 0 12px 0; padding:10px 14px; background:#F8F9FA; border-left:4px solid #9334E6; border-radius:0 8px 8px 0;">
  <div style="font-size:11px; font-weight:700; color:#9334E6; text-transform:uppercase; letter-spacing:0.8px;">Section 03</div>
  <div style="font-size:17px; font-weight:700; color:#202124; margin-top:1px;">Open-Loop Baseline vs. 3-Gate <code>PE-VeriFlow</code> Closed-Loop Execution &amp; Physics Visuals</div>
  <div style="font-size:12.5px; color:#5F6368; margin-top:2px;">Demonstrating upward voltage-drop budget propagation, perimeter duct-bank placement, and cold-read self-verification</div>
</div>

```python
def write_deterministic_zip(zip_path: Path, files_dict: dict[str, str]) -> str:
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for fname in sorted(files_dict):
            info = zipfile.ZipInfo(filename=fname, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            zf.writestr(info, files_dict[fname].encode("utf-8"))
    return hashlib.sha256(zip_path.read_bytes()).hexdigest()


def run_naive_open_loop(workdir: Path) -> Path:
    sched = pd.read_csv(workdir / "schedules" / "campus_circuit_schedule.csv")
    # Locally valid segment VD, but ignores coupled leaf lug cap, adjacent duct mutual heating, and A-602/S-201 overrides
    choices = {
        "SE-1": (6, "600 kcmil", "AL", "D1, D2, D3, D4, D5, D6"),
        "F-10": (2, "500 kcmil", "AL", "D7, D8"),
        "F-05": (2, "500 kcmil", "AL", ""),
        "F-06": (2, "300 kcmil", "AL", ""),
        "F-08": (1, "500 kcmil", "CU", ""),
        "B-17": (1, "#6 AWG", "CU", ""),
        "B-09": (1, "#6 AWG", "CU", ""),
        "B-12": (1, "#4 AWG", "CU", ""),
        "B-21": (1, "#1/0 AWG", "CU", ""),
        "B-24": (1, "#2 AWG", "CU", ""),
    }
    ws = io.StringIO()
    cw = csv.writer(ws)
    cw.writerow(["circuit", "sets", "size", "material", "ducts"])
    for cid in sched["circuit"]:
        cw.writerow([cid, *choices[cid]])
    reg = "id,source_doc,requirement\nC-01,EDS-26 Rev 2,Feeder VD <= 3.5%\nC-02,CB-GEO-007,Native soil 0.95 K*m/W\n"
    rec = json.dumps({
        "governing_elec_spec": "EDS-26 Rev 2", "db1_backfill_rho_k_m_w": 0.95,
        "mep_routing_zone": "overhead_zone", "mep_pathway_top_z_mm": 2550.0,
        "governing_footing_el_ft": 740.5, "installed_cost_usd": 195000.0,
    }, indent=2)
    out = workdir / "output" / "naive_submission.zip"
    write_deterministic_zip(out, {"wire_schedule.csv": ws.getvalue(), "constraint_register.csv": reg, "design_record.json": rec})
    return out


def run_pe_veriflow_harness(workdir: Path) -> tuple[Path, list[str], str]:
    logs = []
    sched_df = pd.read_csv(workdir / "schedules" / "campus_circuit_schedule.csv").set_index("circuit")

    # Gate 1: Reconcile governing specs, RFI-034 thermal backfill, S-201 datum, and A-602 3D headroom
    gov_spec, rho_gov, footing_el = "EDS-26 Rev 4", 0.60, 746.0
    max_legal_overhead_mm = 3024.6 - 460.0  # 2564.6 mm < 2600.0 mm minimum headroom
    mep_zone, mep_z_mm = ("underfloor_void", -60.0) if max_legal_overhead_mm < 2600.0 else ("overhead_zone", 2550.0)
    logs.append(f"[Gate 1] Locked {gov_spec} + RFI-034 (rho={rho_gov}) + S-201 (El.{footing_el}ft) + A-602 ({mep_zone} @ {mep_z_mm}mm)")

    # Gate 2A: Optimize DB-1 perimeter ducts (D1,D2,D5,D6,D9,D10 for SE-1; D4,D8 for F-10; core D3,D7 empty!)
    perim_se1, outer_f10 = ["D1", "D2", "D5", "D6", "D9", "D10"], ["D4", "D8"]
    best_db = None
    for se_sz in ("500 kcmil", "600 kcmil"):
        for se_mat in ("AL", "CU"):
            for f10_sz in ("500 kcmil", "600 kcmil"):
                for f10_mat in ("AL", "CU"):
                    sp_se, sp_f10 = CATALOG_BY_KEY[(se_sz, se_mat)], CATALOG_BY_KEY[(f10_sz, f10_mat)]
                    dmap = {d: (2000.0 / 6.0, sp_se) for d in perim_se1}
                    dmap.update({d: (580.0 / 2.0, sp_f10) for d in outer_f10})
                    nm = neher_mcgrath_ductbank_temps(dmap, rho_soil=rho_gov, t_earth_c=27.45)
                    t_max = max(v["t_cond_c"] for v in nm.values())
                    se_amp = min(nm[d]["derated_amp_a"] for d in perim_se1) * 6
                    f10_amp = min(nm[d]["derated_amp_a"] for d in outer_f10) * 2
                    se_vd = line_to_line_vd_pct(1600.0, float(sched_df.loc["SE-1", "one_way_length_ft"]), 6, sp_se)
                    f10_vd = line_to_line_vd_pct(580.0, float(sched_df.loc["F-10", "one_way_length_ft"]), 2, sp_f10)
                    if t_max <= 75.0 and se_amp >= 2000.0 and f10_amp >= 580.0 and se_vd <= 3.0 and (se_vd + f10_vd) <= 5.0:
                        c_proxy = 420 * 24 * sp_se["usd_ft"] + 360 * 8 * sp_f10["usd_ft"]
                        if best_db is None or c_proxy < best_db[0]:
                            best_db = (c_proxy, se_sz, se_mat, se_vd, f10_sz, f10_mat, f10_vd, t_max, se_amp)

    _, se_sz, se_mat, se_vd, f10_sz, f10_mat, f10_vd, db_tmax, se_amp = best_db
    chosen = {"SE-1": (6, se_sz, se_mat, ", ".join(perim_se1)), "F-10": (2, f10_sz, f10_mat, ", ".join(outer_f10))}
    logs.append(f"[Gate 2A] DB-1 Perimeter Solution: SE-1=6x {se_mat} {se_sz} (Amp={se_amp:.1f}A, T_max={db_tmax:.1f}C <= 75C, VD={se_vd:.2f}%)")

    # Gate 2B: Upward lug-constrained voltage-drop propagation from leaf branches to parent feeders
    leaf_vd = {}
    for cid in ("B-17", "B-09", "B-12", "B-21", "B-24"):
        gt = sched_df.loc[cid]
        cands = [
            (sp["usd_ft"], line_to_line_vd_pct(float(gt["vd_load_a"]), float(gt["one_way_length_ft"]), 1, sp), sz, mat)
            for (sz, mat), sp in CATALOG_BY_KEY.items()
            if sp["kcmil"] <= float(gt["max_lug_kcmil"]) + 0.05
            and sp["amp_75c"] * ambient_factor_75c(gt["environment"]) >= float(gt["ampacity_load_a"])
            and line_to_line_vd_pct(float(gt["vd_load_a"]), float(gt["one_way_length_ft"]), 1, sp) <= 3.0
        ]
        cands.sort(key=lambda x: (x[0], x[1]))
        _, vd_b, sz_b, mat_b = cands[0]
        chosen[cid] = (1, sz_b, mat_b, "")
        leaf_vd[cid] = vd_b

    for f_cid in ("F-05", "F-06", "F-08"):
        gt = sched_df.loc[f_cid]
        worst_leaf = max((leaf_vd[c] for c in leaf_vd if sched_df.loc[c, "parent"] == f_cid), default=0.0)
        budget_vd = min(3.0, 5.0 - se_vd - worst_leaf)
        feas = []
        for sets in range(1, int(gt["max_sets"]) + 1):
            for (sz, mat), sp in CATALOG_BY_KEY.items():
                if sp["kcmil"] > float(gt["max_lug_kcmil"]) + 0.05:
                    continue
                cap = sets * sp["amp_75c"] * ambient_factor_75c(gt["environment"]) * (1.0 if sets == 1 else 0.80)
                vd = line_to_line_vd_pct(float(gt["vd_load_a"]), float(gt["one_way_length_ft"]), sets, sp)
                if cap >= float(gt["ampacity_load_a"]) and vd <= budget_vd:
                    ft = float(gt["one_way_length_ft"]) * sets * 4.0
                    feas.append((ft * (sp["usd_ft"] + (1.85 if mat == "CU" else 1.45)), sets, sz, mat, vd))
        feas.sort(key=lambda x: x[0])
        _, s_f, sz_f, mat_f, vd_f = feas[0]
        chosen[f_cid] = (s_f, sz_f, mat_f, "")
        logs.append(f"[Gate 2B] {f_cid}: leaf VD={worst_leaf:.2f}% -> feeder budget={budget_vd:.2f}% -> {s_f}x {mat_f} {sz_f} (Cum={se_vd+vd_f+worst_leaf:.2f}%)")

    tot_ft, raw_mat, labor = 0.0, 0.0, 0.0
    for cid, gt in sched_df.iterrows():
        s, sz, mat, _ = chosen[cid]
        sp = CATALOG_BY_KEY[(sz, mat)]
        ft = float(gt["one_way_length_ft"]) * s * 4.0
        tot_ft += ft
        raw_mat += ft * sp["usd_ft"]
        labor += ft * (1.85 if mat == "CU" else 1.45)
    installed_usd = raw_mat * (0.94 if tot_ft >= 38000.0 else 1.0) + labor

    ws = io.StringIO()
    cw = csv.writer(ws)
    cw.writerow(["circuit", "sets", "size", "material", "ducts"])
    for cid in sched_df.index:
        cw.writerow([cid, *chosen[cid]])

    reg_buf = io.StringIO()
    rw = csv.writer(reg_buf)
    rw.writerow(["id", "source_doc", "requirement"])
    for idx_r, (doc_s, req_s) in enumerate([
        ("EDS-26 Rev 4 Sec 1.1", "Reject superseded Rev 2; NFPA 70 2023 most restrictive rule governs"),
        ("RFI-034 Item 1", "Engineered backfill rho=0.60 K*m/W supersedes CB-GEO-007 0.95 K*m/W"),
        ("RFI-034 Item 2", "NOAA extreme ambient: 42C outdoor, 46C roof, 27.45C earth"),
        ("EDS-26 Rev 4 Sec 2.1", "Segment VD <= 3.00%; Cumulative T-1 lug VD <= 5.00% without reset"),
        ("EDS-26 Rev 4 Sec 2.3", "SE-1 derated ampacity >= 2000A; 1600A trip for VD; DB-1 T_cond <= 75.0C"),
        ("EDS-26 Rev 4 Sec 2.3", "Max 4 conductor sizes > #1 AWG; 6% bulk discount >= 38,000 ft"),
        ("Sheet A-602 Rev.3", "Sprinkler 3024.6-460=2564.6mm < 2600mm headroom -> 100% underfloor void"),
        ("Sheet S-201 Rev.4", "Governing footing bottom El. 746.0 ft (+5.5 ft shift vs CB-GEO-007)"),
    ], 1):
        rw.writerow([f"C-0{idx_r}", doc_s, req_s])

    rec = json.dumps({
        "governing_elec_spec": gov_spec, "db1_backfill_rho_k_m_w": rho_gov,
        "mep_routing_zone": mep_zone, "mep_pathway_top_z_mm": mep_z_mm,
        "governing_footing_el_ft": footing_el, "total_conductor_ft": round(tot_ft, 1),
        "installed_cost_usd": round(installed_usd, 2),
    }, indent=2)

    out_zip = workdir / "output" / "submission.zip"
    sha = write_deterministic_zip(out_zip, {"wire_schedule.csv": ws.getvalue(), "constraint_register.csv": reg_buf.getvalue(), "design_record.json": rec})

    # Gate 3: Independent Cold-Read Deliverable Verification Before Emitting `done`
    cold_check = evaluate_engineering_submission(out_zip)
    assert cold_check["hard_pass"], f"Gate 3 blocked exit: {cold_check['notes']}"
    logs.append(f"[Gate 3] Cold-Read Verifier PASSED 10/10 Hard Gates | sha256={sha[:16]}... | Score={cold_check['final_score']:.3f}")
    return out_zip, logs, sha


naive_zip = run_naive_open_loop(WORKDIR)
vf_zip, vf_logs, vf_sha = run_pe_veriflow_harness(WORKDIR)
naive_res = evaluate_engineering_submission(naive_zip)
vf_res = evaluate_engineering_submission(vf_zip)

for lg in vf_logs:
    print(lg)

summary_df = pd.DataFrame([
    {
        "Harness Configuration": "Open-Loop Baseline (No Gates)",
        "Hard Gates": f"{naive_res['gates_passed']}/10",
        "DB-1 Max Temp": f"{naive_res['max_db1_temp_c']:.1f} C",
        "SE-1 Ampacity": f"{naive_res['se1_derated_amp_a']:.0f} A",
        "B-17 Cum VD": f"{naive_res['b17_cum_vd_pct']:.2f}%",
        "Total Wire (ft)": f"{naive_res['total_conductor_ft']:,.0f}",
        "Installed Cost": f"USD {naive_res['installed_cost_usd']:,.2f}",
        "PLE Score": f"{naive_res['final_score']:.3f}",
    },
    {
        "Harness Configuration": "PE-VeriFlow (3-Gate Closed Loop)",
        "Hard Gates": f"{vf_res['gates_passed']}/10",
        "DB-1 Max Temp": f"{vf_res['max_db1_temp_c']:.1f} C",
        "SE-1 Ampacity": f"{vf_res['se1_derated_amp_a']:.0f} A",
        "B-17 Cum VD": f"{vf_res['b17_cum_vd_pct']:.2f}%",
        "Total Wire (ft)": f"{vf_res['total_conductor_ft']:,.0f}",
        "Installed Cost": f"USD {vf_res['installed_cost_usd']:,.2f}",
        "PLE Score": f"{vf_res['final_score']:.3f}",
    },
])
display(summary_df)

# Visualize 2D Duct-Bank Thermal Field & Sheet A-602 Spatial Clash Proof
naive_dmap = {f"D{i}": (2000.0 / 6.0, CATALOG_BY_KEY[("600 kcmil", "AL")]) for i in range(1, 7)}
naive_dmap.update({"D7": (290.0, CATALOG_BY_KEY[("500 kcmil", "AL")]), "D8": (290.0, CATALOG_BY_KEY[("500 kcmil", "AL")])})
t_naive = neher_mcgrath_ductbank_temps(naive_dmap, rho_soil=0.60, t_earth_c=27.45)

vf_dmap = {d: (2000.0 / 6.0, CATALOG_BY_KEY[("500 kcmil", "CU")]) for d in ["D1", "D2", "D5", "D6", "D9", "D10"]}
vf_dmap.update({d: (290.0, CATALOG_BY_KEY[("500 kcmil", "AL")]) for d in ["D4", "D8"]})
t_vf = neher_mcgrath_ductbank_temps(vf_dmap, rho_soil=0.60, t_earth_c=27.45)

fig, axes = plt.subplots(1, 3, figsize=(15.6, 4.6), dpi=130)
for ax, t_map, ttl in [
    (axes[0], t_naive, "A. Open-Loop DB-1 (Adjacent AL 600)\nInner Ducts Overheat > 75.0 C Limit!"),
    (axes[1], t_vf, "B. PE-VeriFlow DB-1 (Perimeter CU 500)\nCore D3, D7 Vacant -> All Ducts <= 75.0 C"),
]:
    ax.add_patch(Rectangle((-0.11, 0.93), 0.79, 0.62, facecolor="#E8EAED", edgecolor="#5F6368", lw=1.6))
    for idx in range(12):
        d_id = f"D{idx+1}"
        x, y = DUCT_COORDS[d_id]
        if d_id in t_map:
            tc = t_map[d_id]["t_cond_c"]
            col = "#D93025" if tc > 75.0 else ("#F9AB00" if tc > 69.0 else "#1E8E3E")
            txt = f"{d_id}\n{tc:.1f}C"
            fg = "#FFFFFF" if col in ("#D93025", "#1E8E3E") else "#202124"
        else:
            col, txt, fg = "#FFFFFF", f"{d_id}\nSpare", "#5F6368"
        ax.add_patch(Circle((x, y), 0.068, facecolor=col, edgecolor="#202124", lw=1.2))
        ax.text(x, y, txt, ha="center", va="center", fontsize=7.5, fontweight="bold", color=fg)
    ax.set_xlim(-0.16, 0.73)
    ax.set_ylim(1.62, 0.86)
    ax.set_xlabel("Trench Width (m)")
    ax.set_ylabel("Depth Below Grade (m)")
    ax.set_title(ttl)

ax3 = axes[2]
ax3.axhspan(2564.6, 3024.6, color="#FAD2CF", alpha=0.85, label="NFPA-13 460mm Sprinkler Buffer")
ax3.axhspan(0.0, 2600.0, color="#FEF7E0", alpha=0.65, label="IBC 2600mm Min Walking Headroom")
ax3.axhspan(-600.0, 0.0, color="#CEEAD6", alpha=0.85, label="Underfloor Routing Void (-600..0mm)")
ax3.axhline(3024.6, color="#B31412", lw=1.8)
ax3.axhline(2600.0, color="#E37400", lw=1.6, linestyle="--")
ax3.axhline(2564.6, color="#D93025", lw=1.6, linestyle=":")
ax3.axhline(0.0, color="#202124", lw=2.0)
ax3.text(0.5, 2280, "OVERHEAD IMPOSSIBLE\n3024.6 - 460 = 2564.6 mm\n(35.4 mm Clash vs 2600 mm!)",
         ha="center", va="center", fontsize=8.0, fontweight="bold", color="#B31412",
         bbox=dict(boxstyle="round,pad=0.3", facecolor="#FFFFFF", edgecolor="#D93025"))
ax3.text(0.5, -310, "PE-VeriFlow Underfloor Routing\nTray (-60mm) & CHW (-480mm): 0 Clashes",
         ha="center", va="center", fontsize=8.0, fontweight="bold", color="#137333")
ax3.set_xlim(0, 1)
ax3.set_ylim(-640, 3220)
ax3.set_xticks([])
ax3.set_ylabel("Elevation Z Above Raised Floor (mm)")
ax3.set_title("C. Sheet A-602 Spatial Clash Proof\n(Soft Prompt Preference vs Hard Code)")
ax3.legend(loc="lower center", fontsize=7.3)

plt.tight_layout()
plt.show()
```

<div style="font-family:'Google Sans','Roboto','Segoe UI',sans-serif; margin:22px 0 12px 0; padding:10px 14px; background:#F8F9FA; border-left:4px solid #00ACC1; border-radius:0 8px 8px 0;">
  <div style="font-size:11px; font-weight:700; color:#00838F; text-transform:uppercase; letter-spacing:0.8px;">Section 04</div>
  <div style="font-size:17px; font-weight:700; color:#202124; margin-top:1px;">29-Task Starter Telemetry, Live Gate-3 Container Audit &amp; Sponsored Model Routing</div>
  <div style="font-size:12.5px; color:#5F6368; margin-top:2px;">Inspecting verified b96-r1 starter runs alongside published PLE baselines, live pure-stdlib defect trapping, and all 8 sponsored google-cloud/* models</div>
</div>

```python
# Verified 29-task starter b96-r1 metrics from artifacts/manifest.json and artifacts/*/trajectory.json
STARTER_29_TASKS = [
    ("backfeed-energization-reply", "Electrical", 69, 1.000000, 3),
    ("cooling-water-flush-plan", "Mechanical", 111, 0.461348, 1),
    ("data-center-site-model", "Civil", 39, 1.000000, 1),
    ("data-hall-device-takeoff", "Electrical", 151, 0.382609, 1),
    ("data-hall-mep-routing", "Mechanical", 124, 0.000000, 1),
    ("data-hall-mep-routing-offset", "Mechanical", 160, 0.000000, 1),
    ("division-26-specifications", "Electrical", 137, 0.349370, 1),
    ("emergency-spillway-check", "Civil", 68, 0.621622, 1),
    ("engineers-estimate-check", "Civil", 39, 0.543478, 1),
    ("eor-review-corrections", "Structural", 125, 0.301961, 1),
    ("fill-compaction-acceptance", "Civil", 58, 0.675926, 3),
    ("fire-solve-convergence", "Mechanical", 65, 0.635659, 2),
    ("fire-test-validation-memo", "Mechanical", 65, 0.807692, 1),
    ("footing-settlement-verification", "Civil", 66, 0.532258, 2),
    ("foundation-strategy", "Civil", 73, 0.000000, 0),
    ("frame-extension-method", "Civil", 81, 0.806300, 1),
    ("heat-rejection-life-cycle-cost", "Mechanical", 115, 0.692462, 1),
    ("landscape-sheet-revision", "Civil", 60, 0.857143, 1),
    ("les-mesh-resolution", "Mechanical", 41, 0.536585, 1),
    ("lv-cable-sizing", "Electrical", 76, 0.906575, 1),
    ("mv-conveyance-study", "Electrical", 90, 0.353437, 1),
    ("permission-to-operate-memo", "Electrical", 90, 0.909091, 3),
    ("pre-application-capacity-response", "Electrical", 91, 0.230769, 3),
    ("roof-deck-design", "Structural", 97, 0.285714, 1),
    ("seismic-diaphragm-shear", "Structural", 94, 0.315966, 1),
    ("shoring-design-verification", "Civil", 69, 0.516393, 3),
    ("solar-supplemental-review", "Electrical", 54, 0.207792, 1),
    ("solar-witness-test-package", "Electrical", 22, 0.000000, 0),
    ("wind-diaphragm-shear", "Structural", 111, 0.315873, 1),
]
starter_df = pd.DataFrame(STARTER_29_TASKS, columns=["task_id", "domain", "steps", "reward", "files_delivered"])

domain_summary_df = (
    starter_df.groupby("domain", as_index=False)
    .agg(
        tasks=("task_id", "count"),
        mean_reward=("reward", "mean"),
        median_reward=("reward", "median"),
        zero_score_runs=("reward", lambda s: int((s == 0.0).sum())),
        mean_steps=("steps", "mean"),
    )
    .sort_values("mean_reward", ascending=False)
)

published_frontier_df = pd.DataFrame([
    ["Claude Opus 5.5 + Claude Code (arXiv:2610.30537)", "Anthropic", "0.506", "~27M tok (~USD 17.18/task)", "Published benchmark frontier"],
    ["Starter Opus 5.5 Baseline (b96-r1, 29 dev)", "google-cloud/claude-opus-5-5", f"{starter_df['reward'].mean():.3f}", f"{starter_df['steps'].mean():.1f} mean steps", "Unmodified artifacts/ baseline"],
    ["Gemini 4 Argon (arXiv:2610.30537)", "Google Gemini 4", "0.402-0.432", "Benchmark suite", "Published paper evaluation"],
    ["Gemini 3.8 Flash (arXiv:2610.30537)", "Google Gemini 3.8", "0.282", "Benchmark suite", "Published paper evaluation"],
    ["Stage-2 Prize Eligibility Floor", "Competition Rule", "0.138", "3h budget", "Minimum score threshold"],
], columns=["System / Model", "Provider / API", "Mean Reward", "Trajectory / Token Scale", "Source"])

display(domain_summary_df)
display(published_frontier_df)

# Pure-stdlib Gate-3 container inspector matching harness.py `_CONTAINER_AUDIT_PY`
EXCEL_ERRORS = ("#REF!", "#DIV/0!", "#VALUE!", "#NAME?", "#N/A", "#NUM!", "#NULL!")


def gate3_check_payload(ext: str, data: bytes, label: str, defects: list[str], depth: int = 0) -> None:
    if len(data) == 0:
        defects.append(f"{label}: empty 0-byte deliverable")
        return
    if ext == ".zip" and depth == 0:
        try:
            with zipfile.ZipFile(io.BytesIO(data)) as zf:
                entries = [i for i in zf.infolist() if not i.is_dir()]
                if not entries:
                    defects.append(f"{label}: archive has zero files")
                    return
                bad = zf.testzip()
                if bad is not None:
                    defects.append(f"{label}: corrupt archive entry {bad}")
                    return
                for info in entries[:64]:
                    inner_ext = Path(info.filename).suffix.lower()
                    gate3_check_payload(inner_ext, zf.read(info.filename), f"{label}!{info.filename}", defects, depth + 1)
        except zipfile.BadZipFile:
            defects.append(f"{label}: corrupt ZIP archive")
    elif ext in (".xlsx", ".xlsm"):
        with zipfile.ZipFile(io.BytesIO(data)) as xz:
            names = set(xz.namelist())
            if "xl/workbook.xml" not in names:
                defects.append(f"{label}: missing xl/workbook.xml")
                return
            for nm in names:
                if nm.startswith("xl/worksheets/") and nm.endswith(".xml"):
                    raw_xml = xz.read(nm)
                    root = ET.fromstring(raw_xml)
                    for cell in root.iter():
                        if (cell.tag == "c" or cell.tag.endswith("}c")) and cell.attrib.get("t") == "e":
                            defects.append(f"{label} ({nm}): Excel error cell")
                            return
                    txt_xml = raw_xml.decode("utf-8", errors="ignore")
                    for err in EXCEL_ERRORS:
                        if f"<v>{err}</v>" in txt_xml:
                            defects.append(f"{label} ({nm}): formula error {err}")
                            return
    elif ext == ".json":
        try:
            json.loads(data.decode("utf-8"))
        except ValueError as exc:
            defects.append(f"{label}: invalid JSON ({exc})")
    elif ext == ".dxf":
        txt = data.decode("utf-8", errors="replace")
        if "SECTION" not in txt or "EOF" not in txt:
            defects.append(f"{label}: incomplete DXF (missing SECTION/EOF)")
    elif ext == ".ifc":
        txt = data.decode("utf-8", errors="replace")
        if "ISO-10303-21;" not in txt or "END-ISO-10303-21;" not in txt:
            defects.append(f"{label}: incomplete IFC (missing ISO-10303-21 wrapper)")


def audit_bundle(file_map: dict[str, bytes], final_message: str) -> list[str]:
    defects: list[str] = []
    if not file_map:
        if final_message.strip() in ("", "[tool call]") or final_message.strip().endswith((".", "...")):
            defects.append(f"Zero new deliverable files written; incomplete final message ({final_message!r}).")
    for fname, raw in sorted(file_map.items()):
        gate3_check_payload(Path(fname).suffix.lower(), raw, fname, defects)
    return defects


# Verify Gate-3 catches real injected silent defects AND passes clean vf_zip with 0 defects
bad_xlsx_buf = io.BytesIO()
with zipfile.ZipFile(bad_xlsx_buf, "w") as xz:
    xz.writestr("xl/workbook.xml", "<workbook/>")
    xz.writestr("xl/worksheets/sheet1.xml", '<worksheet><sheetData><row><c t="e"><v>#REF!</v></c></row></sheetData></worksheet>')
trapped_zip_buf = io.BytesIO()
with zipfile.ZipFile(trapped_zip_buf, "w") as zf:
    zf.writestr("calc_book.xlsx", bad_xlsx_buf.getvalue())
    zf.writestr("design.json", "{broken-json")

aborted_defects = audit_bundle({}, "[tool call]")
trapped_defects = audit_bundle(
    {"submission.zip": trapped_zip_buf.getvalue(), "site.ifc": b"ISO-10303-21;\nIFCPROJECT();\n", "plan.dxf": b"0\nSECTION\n"},
    "Completed.",
)
clean_vf_defects = audit_bundle({"submission.zip": vf_zip.read_bytes()}, "Verified 10/10 gates.")

print(f"[Gate-3 Test A: Empty Aborted Run] Caught {len(aborted_defects)} defect(s): {aborted_defects}")
print(f"[Gate-3 Test B: Multi-Format Traps] Caught {len(trapped_defects)} defect(s): {trapped_defects}")
print(f"[Gate-3 Test C: Clean vf_zip Bundle] Caught {len(clean_vf_defects)} defect(s)")
assert len(aborted_defects) == 1 and len(trapped_defects) == 4 and len(clean_vf_defects) == 0

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14.8, 4.6), dpi=130)

# Panel A: Published PLE Frontier vs Verified Starter Baseline
f_labels = ["Gemini 3.8 Flash\n(arXiv:2610.30537)", "Gemini 4 Argon\n(arXiv:2610.30537)", "Starter Opus 5.5\n(b96-r1, n=29)", "Claude Opus 5.5\n(arXiv:2610.30537)"]
f_vals = [0.282, 0.417, float(starter_df["reward"].mean()), 0.506]
f_cols = ["#9AA0A6", "#F9AB00", "#1A73E8", "#1E8E3E"]
yp = np.arange(len(f_labels))
bars = ax1.barh(yp, f_vals, height=0.50, color=f_cols, edgecolor="#202124", lw=0.8)
ax1.errorbar([0.417], [1], xerr=[[0.015], [0.015]], fmt="none", ecolor="#202124", elinewidth=1.6, capsize=4)
for idx_b, (b, val) in enumerate(zip(bars, f_vals)):
    xt = (0.432 if idx_b == 1 else val) + 0.012
    suf = " (0.402-0.432)" if idx_b == 1 else ""
    ax1.text(xt, b.get_y() + b.get_height() / 2, f"{val:.3f}{suf}", va="center", ha="left", fontsize=8.8, fontweight="bold", color="#202124")
ax1.axvline(0.138, color="#D93025", linestyle="--", lw=1.5)
ax1.text(0.145, 3.42, "Stage-2 eligibility floor (0.138)", color="#D93025", fontsize=8.4, fontweight="bold")
ax1.set_yticks(yp)
ax1.set_yticklabels(f_labels, fontsize=8.8)
ax1.set_xlim(0, 0.64)
ax1.set_ylim(-0.55, 3.72)
ax1.set_xlabel("Mean Normalized Task Reward")
ax1.set_title("A. Published PLE Frontier & Verified Starter Reference")

# Panel B: Verified 29-Task Steps vs Score Scatter
dom_palette = {"Civil": "#1A73E8", "Electrical": "#F9AB00", "Mechanical": "#1E8E3E", "Structural": "#D93025"}
for dm, dcol in dom_palette.items():
    sub = starter_df[starter_df["domain"] == dm]
    ax2.scatter(sub["steps"], sub["reward"], s=65, color=dcol, edgecolor="#202124", lw=0.7, label=f"{dm} (n={len(sub)})", zorder=3)
ax2.axhline(float(starter_df["reward"].mean()), color="#3C4043", linestyle="--", lw=1.3, label=f"Mean ({starter_df['reward'].mean():.3f})")
ax2.axhspan(-0.04, 0.04, color="#FCE8E6", alpha=0.6, zorder=1)
ax2.set_xlim(10, 172)
ax2.set_ylim(-0.08, 1.10)
ax2.set_xlabel("Trajectory Length (Verified ATIF Steps)")
ax2.set_ylabel("Task Reward (Starter b96-r1)")
ax2.set_title("B. Trajectory Steps vs Task Reward Across All 29 Dev Tasks")
ax2.legend(loc="upper right", fontsize=8.0)

plt.tight_layout()
plt.show()

# Explicit Routing Table for all 8 Sponsored Competition Models + BYO Gemini 4 Carbon
SPONSORED_MODEL_ROUTING = [
    {"model_api": "google-cloud/claude-opus-5-5", "context": 200_000, "max_out": 128_000, "thinking": "max", "cacheWarming": "streaming"},
    {"model_api": "google-cloud/claude-sonnet-5", "context": 200_000, "max_out": 64_000, "thinking": "max", "cacheWarming": "streaming"},
    {"model_api": "google-cloud/gemini-4-argon", "context": 1_048_576, "max_out": 65_536, "thinking": "high", "cacheWarming": "streaming"},
    {"model_api": "google-cloud/gemini-3.8-pro", "context": 1_048_576, "max_out": 65_536, "thinking": "high", "cacheWarming": "streaming"},
    {"model_api": "google-cloud/gemini-3.8-flash", "context": 1_048_576, "max_out": 65_536, "thinking": "high", "cacheWarming": "streaming"},
    {"model_api": "google-cloud/glm-6", "context": 200_000, "max_out": 65_536, "thinking": "max", "cacheWarming": "streaming"},
    {"model_api": "google-cloud/qwen-4-320b", "context": 262_144, "max_out": 65_536, "thinking": "high", "cacheWarming": "streaming"},
    {"model_api": "google-cloud/gpt-oss-120b", "context": 131_072, "max_out": 32_768, "thinking": "high", "cacheWarming": "streaming"},
    {"model_api": "gemini/gemini-4-carbon (local BYO)", "context": 1_048_576, "max_out": 65_536, "thinking": "high", "cacheWarming": "streaming"},
]
display(pd.DataFrame(SPONSORED_MODEL_ROUTING))

# Optional Live Gemini 4 Carbon (`gemini-4-carbon`) Interactions API Hook
GEMINI_4_CARBON_HARNESS_CONFIG = {
    "id": "gemini-4-carbon",
    "provider": "google",
    "api": "google-generative-ai",
    "contextWindow": 1_048_576,
    "maxTokens": 65_536,
    "input": ["text", "image"],
    "thinking_level": "high",
}

api_key = os.environ.get("GEMINI_API_KEY", "")
if not api_key:
    try:
        from kaggle_secrets import UserSecretsClient  # type: ignore
        api_key = UserSecretsClient().get_secret("GEMINI_API_KEY") or ""
    except Exception:
        api_key = ""

if api_key:
    from google import genai
    client = genai.Client(api_key=api_key)
    corpus_blob = "\n\n".join(f"### {p.name}\n{p.read_text(encoding='utf-8')}" for p in sorted(WORKDIR.rglob("*.md")))
    interaction = client.interactions.create(
        model="gemini-4-carbon",
        input=f"Run PE-VeriFlow Gate 1 authority reconciliation on these files and list governing vs rejected documents:\n{corpus_blob}",
        generation_config={"thinking_level": "high"},
    )
    print("[LIVE GEMINI 4 CARBON GATE-1 AUDIT]\n", interaction.output_text)
else:
    print("[OFFLINE HERMETIC VERIFICATION MODE] Configured harness.py Gemini 4 Carbon capability routing:")
    print(json.dumps(GEMINI_4_CARBON_HARNESS_CONFIG, indent=2))

assert naive_res["final_score"] == 0.0 and naive_res["gates_passed"] < 10
assert vf_res["hard_pass"] is True and vf_res["gates_passed"] == 10 and vf_res["final_score"] >= 0.95
print(f"\n[ALL CONTRACT & GATE-3 CHECKS VERIFIED] Open-Loop Score = {naive_res['final_score']:.3f} ({naive_res['gates_passed']}/10 gates) -> PE-VeriFlow Score = {vf_res['final_score']:.3f} (10/10 hard gates, sha256={vf_sha[:16]}...)")
```

---
<div align="center" style="font-family:'Google Sans','Roboto','Segoe UI',sans-serif; background:#FFFFFF; border:1px solid #DADCE0; border-radius:14px; overflow:hidden; box-shadow:0 2px 6px rgba(60,64,67,0.08); margin-top:24px;">
  <div style="display:flex; height:5px; width:100%;">
    <div style="flex:1; background:#4285F4;"></div>
    <div style="flex:1; background:#EA4335;"></div>
    <div style="flex:1; background:#FBBC04;"></div>
    <div style="flex:1; background:#34A853;"></div>
  </div>
  <div style="padding:18px 24px;">
    <div style="font-size:15px; font-weight:700; color:#202124; margin-bottom:4px;">
      📚 Co-Author of <i>AI Engineering: From Classical ML to RAG &amp; Agentic AI Systems</i> (2026)
    </div>
    <div style="font-size:13.5px; color:#3C4043; margin-bottom:6px;">
      👩‍💻 <b>Robina Mirbahar</b> &middot; AI/ML Google Developer Expert (GDE) 🇵🇰 &middot; Google Cloud Champion Innovator &middot; Microsoft Certified Trainer
    </div>
    <div style="font-size:12.5px; color:#5F6368; margin-bottom:10px;">
      🎤 International Speaker &nbsp;|&nbsp; 📝 Technical Author &nbsp;|&nbsp; 🚀 Mentor @ Google for Startups &amp; Women Techmakers Ambassador
    </div>
    <div style="font-size:13px; font-weight:600;">
      <a href="https://github.com/RobinaMirbahar/ple-veriflow-harness" style="color:#1A73E8; text-decoration:none;">PE-VeriFlow Harness Repo (@RobinaMirbahar)</a>
      &nbsp;&middot;&nbsp;
      <a href="https://www.kaggle.com/competitions/physical-engineerings-last-exam/writeups/pe-veriflow-3-gate-verification-harness-ple" style="color:#1A73E8; text-decoration:none;">Kaggle PLE Writeup</a>
      &nbsp;&middot;&nbsp;
      <a href="https://www.linkedin.com/in/robinamirbahar" style="color:#1A73E8; text-decoration:none;">LinkedIn (in/robinamirbahar)</a>
      &nbsp;&middot;&nbsp;
      <a href="https://arxiv.org/abs/2610.30537" style="color:#1A73E8; text-decoration:none;">PLE Paper (arXiv:2610.30537)</a>
    </div>
  </div>
</div>
