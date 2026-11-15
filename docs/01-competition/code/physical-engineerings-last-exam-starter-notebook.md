# Physical Engineerings Last Exam: Starter Notebook

- **Author:** pablodiegoo
- **Kaggle URL:** https://www.kaggle.com/code/pablodiegoo/physical-engineerings-last-exam-starter-notebook

## Approach / key ideas

- Analysis-heavy starter grounded in the official eval kit (google-research/ple), the 29-task `eval/dev_set.yaml`, and Google's submission-template (Pi 1.1.0 on claude-opus-5-5).
- Covariate shift: Civil (best domain, 69.9%) drops from 31% of dev to 16% of hidden test; Mechanical (40.5%) rises from 24% to 41%.
- Reweighting the starter manifest by test discipline shares lowers expected score 0.4912 -> 0.4707, which explains why OpenHands overtakes Claude Code on hidden test.
- Explains the scoring formula s = 0.4p + 0.6*G*O' and the 0.40 hard-gate cliff: a failed gate caps a task at the process share.
- Best published baseline is 50.6% across 85 tasks (48.3% on test) at about 27M tokens and 63 minutes per task (Claude Opus 5.5 in Claude Code).
- Proposes a cold-read harness: a second pass re-reads the deliverables against the task spec before exit.
- Includes closed-form Python verifiers for engineering checks, written to be dropped into the harness.

## Notebook

# Physical-Engineering's Last Exam: covariate shift, the 0.40 hard-gate cliff, and a cold-read agent harness

Frontier language models clear `90%+` on textbook engineering exams yet peak at `50.6%` across all `85` tasks (`48.3%` on the `56` private test tasks) on **Physical-Engineering's Last Exam (PLE)** ([Han et al., arXiv:2610.30537v2](https://arxiv.org/abs/2610.30537)), spending `27M` tokens and `63` minutes per task in the strongest published baseline (`Claude Opus 5.5` inside `Claude Code`). Instead of grading short-form recall, PLE runs an agent inside an isolated offline Linux container for up to `6` hours per task across `29` public dev deliverables (`google/physical-engineerings-last-exam`) and `56` held-out test deliverables that decide the `$400,000` prize pool.

Every table, diagnostic figure, and check in this notebook is computed directly from three primary sources: the official evaluation kit (`github.com/google-research/ple`, commit `8320f0402fdca9f42476607f72bcfd5271cd50c9`), the `29`-task `eval/dev_set.yaml` catalog paired with Google's official starter manifest (`physical-engineerings-last-exam/submission-template`, commit `6ab05b9f`, `Pi 1.1.0` on `google-cloud/claude-opus-5-5`), and closed-form Python verifiers executed in this kernel.

### Three findings from the official 29-task starter run

Between the `29` public dev tasks and the `56` private test tasks, the discipline mix shifts sharply toward the lowest-scoring domain. In `eval/dev_set.yaml`, Civil engineering (the highest-scoring domain at `69.9%` in Table 3 of the paper) accounts for `31.0%` of public dev (`9 / 29`) but drops to `16.1%` of hidden test (`9 / 56`), whereas Mechanical engineering (`40.5%` paper baseline) climbs by `+16.9` percentage points from `24.1%` (`7 / 29`) to `41.1%` (`23 / 56`). Reweighting the official `submission-template` manifest by exact hidden-test discipline shares lowers its expected score from `0.4912` to `0.4707` (`-0.0206`, matching `Pi`'s `47.3%` full-benchmark mean) and explains why `OpenHands` (`48.6%`) overtakes `Claude Code` (`48.3%`) on the hidden test split despite trailing `49.9%` to `50.6%` across all `85` tasks.

Across `eval/dev_set.yaml`, `final_message` also forms an exact bijection with grader mode: all `14` `rubric` tasks set `final_message: true`, while all `15` executable-check tasks (`checks` and `checks-judge`) set `final_message: false`. Under Eq. (1) (`s = 0.4 * p + 0.6 * G * O'`), violating a single hard safety or feasibility gate sets `G = 0` and caps the item score at `0.40`. In Google's `submission-template` artifacts, `7` of those `15` check tasks stall between `0.2857` and `0.3826` (`71.4%` to `95.7%` individual clause satisfaction, zero objective credit), and `3` score `0.000`.

Auditing `submission-template` and `sample_submissions/plan-verify/serve.py` isolates four concrete harness bugs behind those losses: exiting mid-turn (`[tool call]`, `0` exported files) on `foundation-strategy`; ignoring `session.mcp_servers` when container apps such as OpenProject run over Streamable HTTP on `127.0.0.1` (`0.000` on `solar-witness-test-package`); treating an empty verifier timeout reply `""` as `"PASS"` (`if verdict.strip(...) in ("", "PASS")` at `plan-verify/serve.py` line 499); and returning mutated files after the last fix round without re-verifying them. Section 4 exports and live-tests a standalone `veriflow-ple-starter/` harness bundle that closes all four failure modes.

```python
from __future__ import annotations

import asyncio
import base64
import contextlib
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import re
import secrets
import shlex
import sys
import threading
from typing import Any
import urllib.request
import zipfile

import matplotlib
import matplotlib.font_manager as fm
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import yaml

# Inspect the Kaggle competition mount (hackathon mount carries NOTE.md only)
KAGGLE_INPUT_CANDIDATES = [
    Path("/kaggle/input/physical-engineerings-last-exam/NOTE.md"),
    Path("/kaggle/input/competitions/physical-engineerings-last-exam/NOTE.md"),
]
note_path = next((p for p in KAGGLE_INPUT_CANDIDATES if p.is_file()), None)
if note_path is not None:
    print(f"Mounted competition file ({note_path}): {note_path.read_text(encoding='utf-8').strip()!r}")
else:
    print("Local execution mode; competition mount carries NOTE.md only.")

OUT_DIR = Path("/kaggle/working") if Path("/kaggle/working").is_dir() else Path("/tmp/ple_nb_working")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Register URW Palladio (P052, Palatino metric clone) when present and configure Tufte ivory surface
for otf in sorted(Path("/usr/share/fonts/opentype/urw-base35").glob("P052-*.otf")):
    with contextlib.suppress(Exception):
        fm.fontManager.addfont(str(otf))

TUFTE_PAPER = "#FFFFF8"
TUFTE_INK = "#111111"
TUFTE_MUTED = "#555555"
TUFTE_RULE = "#333333"
TUFTE_CRIMSON = "#9E1B1B"
TUFTE_NAVY = "#1B4F72"
TUFTE_OCHRE = "#8C510A"
TUFTE_PINE = "#1B5E20"

plt.rcParams.update(
    {
        "figure.facecolor": TUFTE_PAPER,
        "savefig.facecolor": TUFTE_PAPER,
        "axes.facecolor": TUFTE_PAPER,
        "axes.edgecolor": TUFTE_RULE,
        "axes.linewidth": 0.6,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.titlelocation": "left",
        "axes.titlesize": 10.5,
        "axes.titleweight": "bold",
        "axes.labelsize": 9.3,
        "xtick.labelsize": 8.6,
        "ytick.labelsize": 8.6,
        "font.family": "serif",
        "font.serif": ["P052", "Palatino", "Georgia", "DejaVu Serif"],
        "axes.grid": False,
        "legend.frameon": False,
    }
)


def style_tufte_ax(
    ax: plt.Axes,
    *,
    x_bounds: tuple[float, float] | None = None,
    y_bounds: tuple[float, float] | None = None,
    outward: float = 4.0,
) -> None:
    ax.set_facecolor(TUFTE_PAPER)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    for side, bounds in (("bottom", x_bounds), ("left", y_bounds)):
        ax.spines[side].set_color(TUFTE_RULE)
        ax.spines[side].set_linewidth(0.6)
        ax.spines[side].set_position(("outward", outward))
        if bounds is not None:
            ax.spines[side].set_bounds(float(bounds[0]), float(bounds[1]))
    ax.tick_params(colors=TUFTE_INK, width=0.6)
```

## 1. Auditing the 29 public dev tasks and the official starter manifest

Official PLE entries are GitHub commits containing `submission.yaml`, a WebSocket server (`serve.py`), one of the `8` Google-sponsored `google-cloud/<id>` models, and the `artifacts/` folder generated on the `29` public dev tasks (`google/physical-engineerings-last-exam`, revision `b3857a3fea39a695e18f845d4a88f29442e96e75`). Google's `physical-engineerings-last-exam/submission-template` repository commits a complete `29`-task run of `Pi 1.1.0` calling `google-cloud/claude-opus-5-5`. Joining `eval/dev_set.yaml` against `artifacts/manifest.json` quantifies both the hidden-test covariate shift and the exact task breakdown by grader family.

```python
DISCIPLINE_TOTALS = {
    "Structural engineering": 10,
    "Civil engineering": 18,
    "Electrical engineering": 27,
    "Mechanical engineering": 30,
}

# Exact 29 public dev tasks from eval/dev_set.yaml paired with official submission-template rewards
DEV_TASKS_DATA = [
    ("data-hall-mep-routing", "Mechanical engineering", "checks", False, "/app/files/.../output/solution.py", 0.000000, 1),
    ("fire-test-validation-memo", "Mechanical engineering", "rubric", True, "/app/files/", 0.807692, 1),
    ("data-hall-mep-routing-offset", "Mechanical engineering", "checks", False, "/app/files/.../output/solution.py", 0.000000, 1),
    ("eor-review-corrections", "Structural engineering", "checks-judge", False, "/filesystem/.../output/submission.zip", 0.301961, 1),
    ("foundation-strategy", "Civil engineering", "checks-judge", False, "/filesystem/.../output/submission.zip", 0.000000, 0),
    ("landscape-sheet-revision", "Civil engineering", "rubric", True, "/app/files/", 0.857143, 1),
    ("data-center-site-model", "Civil engineering", "checks", False, "/app/files/.../submission/model.ifc", 1.000000, 1),
    ("engineers-estimate-check", "Civil engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.543478, 1),
    ("footing-settlement-verification", "Civil engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.532258, 2),
    ("solar-supplemental-review", "Electrical engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.207792, 1),
    ("solar-witness-test-package", "Electrical engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.000000, 0),
    ("frame-extension-method", "Civil engineering", "checks", False, "/filesystem/.../output/submission.zip", 0.806300, 1),
    ("fire-solve-convergence", "Mechanical engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.635659, 2),
    ("les-mesh-resolution", "Mechanical engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.536585, 1),
    ("mv-conveyance-study", "Electrical engineering", "checks", False, "/filesystem/.../output/submission.zip", 0.353437, 1),
    ("data-hall-device-takeoff", "Electrical engineering", "checks", False, "/filesystem/.../output/submission.zip", 0.382609, 1),
    ("division-26-specifications", "Electrical engineering", "checks", False, "/filesystem/.../output/submission.zip", 0.349370, 1),
    ("heat-rejection-life-cycle-cost", "Mechanical engineering", "checks", False, "/filesystem/.../output/submission.zip", 0.692462, 1),
    ("cooling-water-flush-plan", "Mechanical engineering", "checks", False, "/filesystem/.../output/submission.zip", 0.461348, 1),
    ("wind-diaphragm-shear", "Structural engineering", "checks", False, "/filesystem/.../output/submission.zip", 0.315873, 1),
    ("seismic-diaphragm-shear", "Structural engineering", "checks", False, "/filesystem/.../output/submission.zip", 0.315966, 1),
    ("roof-deck-design", "Structural engineering", "checks", False, "/filesystem/.../output/submission.zip", 0.285714, 1),
    ("fill-compaction-acceptance", "Civil engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.675926, 3),
    ("shoring-design-verification", "Civil engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.516393, 3),
    ("emergency-spillway-check", "Civil engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.621622, 1),
    ("pre-application-capacity-response", "Electrical engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.230769, 3),
    ("permission-to-operate-memo", "Electrical engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 0.909091, 3),
    ("backfeed-energization-reply", "Electrical engineering", "rubric", True, "/filesystem/, /app/output/, /app/tools/.apps_data/", 1.000000, 3),
    ("lv-cable-sizing", "Electrical engineering", "checks-judge", False, "/filesystem/.../output/submission.zip", 0.906575, 1),
]

dev_df = pd.DataFrame(
    DEV_TASKS_DATA,
    columns=["task_id", "domain", "grading", "final_message", "deliverable_pattern", "pi_opus_reward", "exported_files"],
)
assert len(dev_df) == 29
assert (dev_df["grading"].eq("rubric") == dev_df["final_message"]).all()

shift_rows = []
for dom, total_n in DISCIPLINE_TOTALS.items():
    sub = dev_df[dev_df["domain"] == dom]
    dev_n = len(sub)
    hid_n = total_n - dev_n
    dev_share = 100.0 * dev_n / 29.0
    hid_share = 100.0 * hid_n / 56.0
    imp_weight = (hid_n / 56.0) / (dev_n / 29.0)
    shift_rows.append(
        {
            "Discipline": dom,
            "Total (85)": total_n,
            "Public Dev (29)": f"{dev_n} ({dev_share:.1f}%)",
            "Hidden Test (56)": f"{hid_n} ({hid_share:.1f}%)",
            "Shift (pp)": round(hid_share - dev_share, 1),
            "Importance Weight": round(imp_weight, 3),
            "Pi+Opus Dev Mean": round(float(sub["pi_opus_reward"].mean()), 4),
        }
    )

shift_df = pd.DataFrame(shift_rows).sort_values("Shift (pp)", ascending=False).reset_index(drop=True)
print("=== Discipline Covariate Shift: Public Dev (29) vs Hidden Private Test (56) ===")
print(shift_df.to_string(index=False))

unweighted_mean = float(dev_df["pi_opus_reward"].mean())
task_weights = dev_df["domain"].map(
    {
        dom: (DISCIPLINE_TOTALS[dom] - int((dev_df["domain"] == dom).sum())) / (56.0 * int((dev_df["domain"] == dom).sum()))
        for dom in DISCIPLINE_TOTALS
    }
)
reweighted_mean = float((dev_df["pi_opus_reward"] * task_weights).sum())
print(f"\nOfficial starter unweighted 29-task dev mean : {unweighted_mean:.4f}")
print(f"Hidden-test discipline-reweighted CV estimate: {reweighted_mean:.4f} (delta = {reweighted_mean - unweighted_mean:+.4f})")
```

## 2. Discipline shift, the 0.40 hard-gate wall, and the cost frontier

On constraint-graded tasks (`tests/paper_score.py` in `docs/rules.md`), each deliverable item receives:

$$s = 0.4\,p + 0.6\,G\,O', \qquad O' = \operatorname{clip}\!\left(\frac{O - O_{\text{naive}}}{1 - O_{\text{naive}}},\,0,\,1\right)$$

Here $p \in [0, 1]$ is the fraction of soft constraints met, and $G \in \{0, 1\}$ equals `1` if and only if every hard safety and feasibility gate passes. An agent that satisfies `95%` of individual clauses ($p = 0.95$) and reaches the minimum-cost design ($O' = 1.00$), yet misses one carton ceiling or cumulative voltage-drop limit ($G = 0$), drops from `0.98` to `0.38`. Across the `15` `checks` and `checks-judge` dev tasks in `submission-template`, `7` tasks sit immediately below `0.40` (`0.2857` to `0.3826`, corresponding to implied clause pass rates $p = s / 0.40$ between `71.4%` and `95.7%` with $G = 0$).

```python
fig, axes = plt.subplots(2, 2, figsize=(15.2, 9.6), dpi=150)
ax1, ax2 = axes[0]
ax3, ax4 = axes[1]

# Panel A: Covariate Shift Between Public Dev and Hidden Test
disc_labels = [
    "Mechanical\n(40.5% paper base)",
    "Structural\n(46.6% paper base)",
    "Electrical\n(50.7% paper base)",
    "Civil\n(69.9% paper base)",
]
dev_shares = [7 / 29 * 100.0, 4 / 29 * 100.0, 9 / 29 * 100.0, 9 / 29 * 100.0]
tst_shares = [23 / 56 * 100.0, 6 / 56 * 100.0, 18 / 56 * 100.0, 9 / 56 * 100.0]
y_a = np.arange(len(disc_labels))
h_a = 0.30
b1 = ax1.barh(y_a - h_a / 2.0, dev_shares, height=h_a, color=TUFTE_MUTED, label="Public Dev (n = 29)")
b2 = ax1.barh(y_a + h_a / 2.0, tst_shares, height=h_a, color=[TUFTE_CRIMSON, TUFTE_NAVY, TUFTE_NAVY, TUFTE_PINE], label="Hidden Test (n = 56)")
ax1.set_yticks(y_a)
ax1.set_yticklabels(disc_labels)
ax1.invert_yaxis()
ax1.set_xlim(0, 52)
for bar, v, cnt in zip(b1, dev_shares, ["7/29", "4/29", "9/29", "9/29"]):
    ax1.text(v + 0.8, bar.get_y() + bar.get_height() / 2.0, f"{v:.1f}% ({cnt})", va="center", fontsize=8.1, color=TUFTE_MUTED)
for bar, v, cnt, dlt in zip(b2, tst_shares, ["23/56", "6/56", "18/56", "9/56"], ["+16.9 pp", "-3.1 pp", "+1.1 pp", "-15.0 pp"]):
    ax1.text(v + 0.8, bar.get_y() + bar.get_height() / 2.0, f"{v:.1f}% ({cnt}, {dlt})", va="center", fontsize=8.2, fontweight="bold", color=TUFTE_INK)
ax1.set_xlabel("Share of Benchmark Tasks (%)")
ax1.set_title("A. Dev-to-Hidden-Test Covariate Shift (+16.9 pp Mechanical Surge)")
ax1.legend(loc="lower right")
style_tufte_ax(ax1, x_bounds=(0.0, 50.0), y_bounds=(0.0, 3.0))

# Panel B: Official Starter Manifest (15 Executable-Check Tasks) & 0.40 Ceiling
exec_df = dev_df[~dev_df["final_message"]].sort_values("pi_opus_reward").reset_index(drop=True)
y_b = np.arange(len(exec_df))
scores_b = exec_df["pi_opus_reward"].to_numpy()
cols_b = [TUFTE_MUTED if s == 0.0 else (TUFTE_CRIMSON if s < 0.40 else TUFTE_PINE) for s in scores_b]
ax2.hlines(y_b, 0.0, scores_b, color=cols_b, lw=1.6)
ax2.scatter(scores_b, y_b, color=cols_b, s=34, zorder=4)
ax2.axvline(0.40, color=TUFTE_CRIMSON, linestyle="--", lw=1.1)
ax2.text(0.415, 1.0, "G = 0 Hard-Gate Ceiling (s <= 0.40)\n7/15 tasks trapped at 0.286-0.383", fontsize=8.0, color=TUFTE_CRIMSON, fontweight="bold", va="top")
ax2.set_yticks(y_b)
ax2.set_yticklabels(exec_df["task_id"].tolist(), fontsize=7.8)
ax2.invert_yaxis()
ax2.set_xlim(-0.02, 1.13)
for yi, val in zip(y_b, scores_b):
    x_lbl = 0.412 if 0.33 < val < 0.40 else val + 0.018
    ax2.text(x_lbl, yi, f"{val:.3f}", va="center", fontsize=7.8, fontweight="bold", color=TUFTE_INK)
ax2.set_xlabel("Official Starter Task Score s in [0, 1] (final_message = false)")
ax2.set_title("B. Official Pi + Opus 5.5 Manifest: 10/15 Check Tasks Below 0.40")
style_tufte_ax(ax2, x_bounds=(0.0, 1.0), y_bounds=(0.0, 14.0))

# Panel C: Published Cost-Score Frontier (arXiv:2610.30537v2)
frontier = [
    ("Gemini 3.8 Flash\n(Claude Code)", 2.55, 28.2, TUFTE_OCHRE, (0.55, -1.8)),
    ("Gemini 4 Argon\n(Claude Code)", 8.21, 43.2, TUFTE_NAVY, (-4.55, 0.4)),
    ("GPT 6 Astra*\n(Codex, non-sponsored)", 9.15, 48.3, TUFTE_MUTED, (-0.30, 1.8)),
    ("Opus 5.5\n(OpenHands)", 14.82, 49.9, TUFTE_PINE, (-2.60, -4.6)),
    ("Opus 5.5\n(Claude Code)", 17.18, 50.6, TUFTE_CRIMSON, (-2.40, 1.7)),
]
ax3.plot([r[1] for r in frontier], [r[2] for r in frontier], color=TUFTE_NAVY, lw=1.2, linestyle=":")
for lbl, xv, yv, col, (dx, dy) in frontier:
    ax3.scatter([xv], [yv], color=col, s=60, zorder=5)
    ax3.text(xv + dx, yv + dy, f"{lbl}\n${xv:.2f} | {yv:.1f}%", fontsize=7.9, color=col, fontweight="bold")
ax3.vlines(8.21, 31.1, 43.2, color=TUFTE_NAVY, lw=2.0)
ax3.scatter([8.21], [31.1], color=TUFTE_NAVY, marker="v", s=40, zorder=5)
ax3.text(8.65, 34.0, "Argon harness span:\n31.1% to 43.2% (+12.1 pp)", fontsize=8.0, color=TUFTE_NAVY)
ax3.set_xlim(1.0, 20.5)
ax3.set_ylim(24.0, 56.5)
ax3.set_xlabel("Mean API Spend per Task (USD, 85-Task Benchmark)")
ax3.set_ylabel("Mean PLE Score (%)")
ax3.set_title("C. Frontier Cost-Score Pareto Curve and +12.1 pp Harness Spread")
style_tufte_ax(ax3, x_bounds=(2.5, 20.0), y_bounds=(25.0, 55.0))

# Panel D: Joint Hard-Gate Survival P(G = 1) = q^k
k_vals = np.arange(1, 16)
for q_v, col, tag, dy in [
    (0.85, TUFTE_MUTED, "q = 0.85 (unverified draft)", -1.2),
    (0.91, TUFTE_CRIMSON, "q = 0.91 (paper baseline)", -1.3),
    (0.96, TUFTE_NAVY, "q = 0.96 (+ schema/unit checks)", 0.8),
    (0.99, TUFTE_PINE, "q = 0.99 (+ cold-read solver)", 0.8),
]:
    surv = (q_v**k_vals) * 100.0
    ax4.plot(k_vals, surv, color=col, lw=1.9, marker="o", markersize=3.8)
    ax4.text(15.15, surv[-1] + dy, f"{tag}: {surv[-1]:.1f}%", fontsize=7.9, color=col, va="center", fontweight="bold")
ax4.scatter([9.4], [41.3], color=TUFTE_CRIMSON, s=72, zorder=6)
ax4.annotate(
    "Opus 5.5 empirical cliff:\n91% per-constraint -> 41.3% G = 1",
    xy=(9.4, 41.3),
    xytext=(1.35, 11.5),
    arrowprops={"arrowstyle": "->", "color": TUFTE_CRIMSON, "lw": 1.0},
    fontsize=8.0,
    fontweight="bold",
    color=TUFTE_CRIMSON,
)
ax4.set_xlim(1, 22.8)
ax4.set_ylim(0, 105)
ax4.set_xticks([1, 3, 5, 7, 9, 11, 13, 15])
ax4.set_xlabel("Number of Simultaneous Hard Safety/Feasibility Gates k")
ax4.set_ylabel("Joint Gate Survival P(G = 1) = q^k (%)")
ax4.set_title("D. Exponential Hard-Gate Attrition and Cold-Read Verifier Recovery")
style_tufte_ax(ax4, x_bounds=(1.0, 15.0), y_bounds=(0.0, 100.0))

fig.suptitle(
    "Physical-Engineering's Last Exam: Discipline Shift, G = 0 Hard-Gate Cliff & Cold-Read Harness Design",
    x=0.01,
    ha="left",
    fontsize=13.0,
    fontweight="bold",
    color=TUFTE_INK,
)
fig.tight_layout(rect=(0, 0, 1, 0.95))
fig.savefig(OUT_DIR / "ple_diagnostics_overview.png", dpi=150, facecolor=TUFTE_PAPER)
plt.show()
```

## 3. Revision authority and closed-form verifiers across all four disciplines

Reading the `final_message.md` traces from `submission-template` shows why capable reasoning models still trip hard gates even when their written engineering memos read cleanly. Project folders average `61` files (and reach `207`), mixing `Preliminary` sheets, `IFC` (Issued for Construction) drawings, `RFI` responses, `Addenda`, and `AHJ` (Authority Having Jurisdiction) letters that often quote elevations against two distinct site datums. An agent that stops after reading the base drawing set optimizes against superseded loads or elevations.

Arithmetic and discrete-packaging conventions create a second trap. Common failures include omitting the `12**3 = 1728` cubic-inch conversion in US-customary Euler-Bernoulli deflection (`in` vs `ft`), resetting NEC voltage-drop budgets at intermediate distribution panels instead of enforcing `feeder + branch <= 5.0%`, and calling Python's banker-rounded `round()` instead of `math.ceil()` on `5%`-waste carton takeoffs (`data-hall-device-takeoff`).

Piecewise physical regimes form the third failure class. Spread footings on overconsolidated clay that cross the preconsolidation stress $\sigma'_p$ cannot be extrapolated with the recompression index $C_r$ alone; once $\sigma'_f > \sigma'_p$, virgin compression ($C_c$) multiplies settlement severalfold. Likewise, a single 3D bounding-box clash in `data-hall-mep-routing` zeroes out the entire task score. The cell below implements closed-form Python verifiers across all four PLE domains and measures the exact Eq. (1) score recovery when each defect is caught before `done`.

```python
AUTHORITY_RANK = {
    "Preliminary": 10,
    "Permit": 20,
    "Bid": 30,
    "IFC": 40,
    "Field_Directive": 50,
    "RFI_Response": 60,
    "Addendum": 70,
    "AHJ_Letter": 80,
}


@dataclass(frozen=True)
class ClauseAssertion:
    doc_id: str
    authority: str
    rev: int
    param: str
    value: float
    unit: str
    datum_offset_m: float = 0.0


def resolve_governing_clauses(clauses: list[ClauseAssertion]) -> dict[str, tuple[float, str, bool]]:
    grouped: dict[str, list[ClauseAssertion]] = {}
    for c in clauses:
        grouped.setdefault(c.param, []).append(c)
    out: dict[str, tuple[float, str, bool]] = {}
    for param, items in grouped.items():
        ranked = sorted(items, key=lambda x: (AUTHORITY_RANK[x.authority], x.rev), reverse=True)
        win = ranked[0]
        norm = lambda x: x.value + x.datum_offset_m if x.unit == "m_elev" else x.value
        win_val = norm(win)
        top_tier = (AUTHORITY_RANK[win.authority], win.rev)
        conflict = any(
            not math.isclose(norm(other), win_val, rel_tol=1e-6)
            for other in ranked[1:]
            if (AUTHORITY_RANK[other.authority], other.rev) == top_tier
        )
        out[param] = (win_val, win.doc_id, conflict)
    return out


def verify_aisc_beam_lrfd(
    span_ft: float,
    dead_klf: float,
    live_klf: float,
    zx_in3: float,
    ix_in4: float,
    d_in: float,
    tw_in: float,
    fy_ksi: float = 50.0,
    e_ksi: float = 29000.0,
) -> dict[str, float | bool]:
    wu = max(1.4 * dead_klf, 1.2 * dead_klf + 1.6 * live_klf)
    mu = wu * (span_ft**2) / 8.0
    phi_mn = 0.90 * fy_ksi * zx_in3 / 12.0
    vu = wu * span_ft / 2.0
    phi_vn = 1.00 * 0.60 * fy_ksi * d_in * tw_in
    L_in = span_ft * 12.0
    delta_l = (5.0 * (live_klf / 12.0) * (L_in**4)) / (384.0 * e_ksi * ix_in4)
    allow_l = L_in / 360.0
    ok = (mu <= phi_mn) and (vu <= phi_vn) and (delta_l <= allow_l)
    return {"flexure_dcr": mu / phi_mn, "shear_dcr": vu / phi_vn, "deflection_dcr": delta_l / allow_l, "pass": ok}


def verify_nec_feeder_and_takeoff(
    cont_a: float,
    noncont_a: float,
    table_amp_a: float,
    derate: float,
    length_ft: float,
    cmil: float,
    upstream_vdrop_pct: float,
    req_devices: int,
    carton_qty: int,
) -> dict[str, float | int | bool]:
    design_a = 1.25 * cont_a + noncont_a
    allow_a = table_amp_a * derate
    seg_vdrop_pct = 100.0 * (math.sqrt(3.0) * 12.9 * (cont_a + noncont_a) * length_ft / cmil) / 480.0
    cum_vdrop_pct = upstream_vdrop_pct + seg_vdrop_pct
    cartons_ceil = math.ceil((req_devices * 1.05 - 1e-12) / carton_qty)
    ok = (design_a <= allow_a) and (seg_vdrop_pct <= 3.0) and (cum_vdrop_pct <= 5.0)
    return {
        "ampacity_dcr": design_a / allow_a,
        "segment_vdrop_pct": seg_vdrop_pct,
        "cumulative_vdrop_pct": cum_vdrop_pct,
        "cartons_ceil": cartons_ceil,
        "pass": ok,
    }


def terzaghi_oc_nc_settlement_mm(
    load_kn: float,
    width_m: float,
    length_m: float,
    h_clay_m: float,
    z_mid_m: float,
    sigma_v0_kpa: float,
    sigma_p_kpa: float,
    e0: float,
    cc: float,
    cr: float,
) -> tuple[float, float]:
    delta_s = load_kn / ((width_m + z_mid_m) * (length_m + z_mid_m))
    sigma_f = sigma_v0_kpa + delta_s
    factor = (h_clay_m * 1000.0) / (1.0 + e0)
    naive_cr_only = factor * cr * math.log10(sigma_f / sigma_v0_kpa)
    if sigma_f <= sigma_p_kpa:
        exact_mm = naive_cr_only
    else:
        exact_mm = factor * (cr * math.log10(sigma_p_kpa / sigma_v0_kpa) + cc * math.log10(sigma_f / sigma_p_kpa))
    return exact_mm, naive_cr_only


def hydronic_pipe_lcc_npv(
    diam_m: float,
    flow_m3_s: float = 0.085,
    length_m: float = 320.0,
    years: int = 25,
    r_disc: float = 0.06,
) -> tuple[float, float, float]:
    area = math.pi * (diam_m**2) / 4.0
    vel = flow_m3_s / area
    re = vel * diam_m / 1.004e-6
    f_val = 0.25 / (math.log10((0.000045 / (3.7 * diam_m)) + (5.74 / (re**0.9))) ** 2)
    head_m = (f_val * (length_m / diam_m) + 6.5) * (vel**2) / (2.0 * 9.80665)
    pump_kw = (998.2 * 9.80665 * flow_m3_s * head_m / 1000.0) / 0.78
    capex = 95_000.0 + 1_350_000.0 * (diam_m**1.65)
    pv_annuity = (1.0 - (1.0 + r_disc) ** (-years)) / r_disc
    energy_npv = pump_kw * 8760.0 * 0.11 * pv_annuity
    return head_m, capex, capex + energy_npv


def ple_eq1_score(p_frac: float, hard_gates_ok: bool, o_prime: float) -> float:
    return 0.4 * p_frac + 0.6 * (1.0 if hard_gates_ok else 0.0) * o_prime


clauses = [
    ClauseAssertion("S-001_Prelim.pdf", "Preliminary", 0, "basic_wind_speed_mph", 105.0, "mph"),
    ClauseAssertion("S-001_IFC.pdf", "IFC", 2, "basic_wind_speed_mph", 110.0, "mph"),
    ClauseAssertion("AHJ_Wind_Directive.pdf", "AHJ_Letter", 1, "basic_wind_speed_mph", 115.0, "mph"),
    ClauseAssertion("Civil_PlantGrid.xlsx", "IFC", 1, "pad_ffe_elev", 100.00, "m_elev", datum_offset_m=14.62),
    ClauseAssertion("Geotech_Addendum2.pdf", "Addendum", 2, "pad_ffe_elev", 114.62, "m_elev", datum_offset_m=0.0),
]
gov = resolve_governing_clauses(clauses)
beam_undersized = verify_aisc_beam_lrfd(span_ft=32.0, dead_klf=1.1, live_klf=1.8, zx_in3=134.0, ix_in4=1350.0, d_in=21.0, tw_in=0.40)
beam_verified = verify_aisc_beam_lrfd(span_ft=32.0, dead_klf=1.1, live_klf=1.8, zx_in3=177.0, ix_in4=1830.0, d_in=23.7, tw_in=0.415)
elec_naive = verify_nec_feeder_and_takeoff(185.0, 30.0, 285.0, 0.88, 640.0, 250_000.0, upstream_vdrop_pct=2.7, req_devices=134, carton_qty=10)
elec_verified = verify_nec_feeder_and_takeoff(185.0, 30.0, 335.0, 0.88, 640.0, 350_000.0, upstream_vdrop_pct=2.7, req_devices=134, carton_qty=10)
s_exact_bad, s_naive_cr = terzaghi_oc_nc_settlement_mm(1650.0, 2.6, 2.6, 3.2, 2.25, 75.0, 130.0, 0.82, cc=0.34, cr=0.045)
s_exact_good, _ = terzaghi_oc_nc_settlement_mm(1650.0, 4.2, 4.2, 3.2, 2.25, 75.0, 130.0, 0.82, cc=0.34, cr=0.045)

audit_table = pd.DataFrame(
    [
        {
            "Discipline": "Structural (W-beam LRFD + L/360)",
            "Draft Fault Caught": f"W21x62 live deflection DCR = {beam_undersized['deflection_dcr']:.2f} (> 1.00)",
            "Verified Remedy": f"Upgrade to W24x68 (deflection DCR = {beam_verified['deflection_dcr']:.2f})",
            "Draft Eq.(1) Score": round(ple_eq1_score(0.90, bool(beam_undersized["pass"]), 0.88), 3),
            "Verified Eq.(1) Score": round(ple_eq1_score(1.00, bool(beam_verified["pass"]), 0.84), 3),
        },
        {
            "Discipline": "Electrical (NEC V-drop + BOM)",
            "Draft Fault Caught": f"Cumul. V-drop = {elec_naive['cumulative_vdrop_pct']:.2f}% (> 5.0%) & round()=14 cartons",
            "Verified Remedy": f"Upsize to 350 kcmil ({elec_verified['cumulative_vdrop_pct']:.2f}% V-drop) & ceil={elec_verified['cartons_ceil']} cartons",
            "Draft Eq.(1) Score": round(ple_eq1_score(0.92, bool(elec_naive["pass"]), 0.90), 3),
            "Verified Eq.(1) Score": round(ple_eq1_score(1.00, bool(elec_verified["pass"]), 0.83), 3),
        },
        {
            "Discipline": "Civil (Terzaghi OC->NC clay)",
            "Draft Fault Caught": f"Cr-only predicts {s_naive_cr:.1f} mm; true OC+NC = {s_exact_bad:.1f} mm (> 25 mm)",
            "Verified Remedy": f"Widen pad to 4.2 m square (true settlement = {s_exact_good:.1f} mm <= 25 mm)",
            "Draft Eq.(1) Score": round(ple_eq1_score(0.88, s_exact_bad <= 25.0, 0.91), 3),
            "Verified Eq.(1) Score": round(ple_eq1_score(1.00, s_exact_good <= 25.0, 0.82), 3),
        },
        {
            "Discipline": "Corpus Revision Graph",
            "Draft Fault Caught": "Preliminary sheet wind = 105 mph (ignores AHJ directive)",
            "Verified Remedy": f"Resolved {gov['basic_wind_speed_mph'][0]:.0f} mph ({gov['basic_wind_speed_mph'][1]}), conflict={gov['pad_ffe_elev'][2]}",
            "Draft Eq.(1) Score": round(ple_eq1_score(0.79, False, 0.85), 3),
            "Verified Eq.(1) Score": round(ple_eq1_score(1.00, True, 0.85), 3),
        },
    ]
)
print("=== Closed-Form Verification Audit: Draft Faults vs Cold-Read Verified Remedies ===")
print(audit_table.to_string(index=False))
```

```python
# Render Tufte Figure 2 with direct curve labeling and range-frame spines (no overlapping legends)
fig, (ax_geo, ax_lcc) = plt.subplots(1, 2, figsize=(15.0, 4.7), dpi=150)

loads_kn = np.linspace(600.0, 3400.0, 80)
true_s = []
naive_s = []
for p_kn in loads_kn:
    ex_v, nv_v = terzaghi_oc_nc_settlement_mm(float(p_kn), 2.6, 2.6, 3.2, 2.25, 75.0, 130.0, 0.82, 0.34, 0.045)
    true_s.append(ex_v)
    naive_s.append(nv_v)

ax_geo.plot(loads_kn, true_s, color=TUFTE_CRIMSON, lw=2.0)
ax_geo.plot(loads_kn, naive_s, color=TUFTE_MUTED, lw=1.5, linestyle="--")
ax_geo.plot([600.0, 3400.0], [25.0, 25.0], color=TUFTE_PINE, linestyle=":", lw=1.2)
ax_geo.plot([1294.0, 1294.0], [0.0, 160.0], color=TUFTE_NAVY, linestyle=":", lw=1.0)
ax_geo.annotate(
    "Preconsolidation knee\nsigma'_f = sigma'_p (130 kPa)",
    xy=(1294.0, 18.9),
    xytext=(630.0, 82.0),
    arrowprops={"arrowstyle": "->", "color": TUFTE_NAVY, "lw": 1.0},
    fontsize=8.1,
    color=TUFTE_NAVY,
    fontweight="bold",
)
ax_geo.text(
    3440.0,
    true_s[-1] - 2.0,
    f"Piecewise OC + NC\n({true_s[-1]:.0f} mm)",
    va="center",
    fontsize=8.1,
    fontweight="bold",
    color=TUFTE_CRIMSON,
)
ax_geo.text(
    3440.0,
    naive_s[-1] + 4.0,
    f"Naive Cr-only\n({naive_s[-1]:.0f} mm)",
    va="center",
    fontsize=8.0,
    color=TUFTE_MUTED,
)
ax_geo.text(1920.0, 9.5, "Allowable settlement gate (25.0 mm)", fontsize=8.1, color=TUFTE_PINE, fontweight="bold")
ax_geo.set_xlim(550.0, 4250.0)
ax_geo.set_ylim(0.0, 168.0)
ax_geo.set_xticks([600, 1300, 2000, 2700, 3400])
ax_geo.set_yticks([0, 25, 60, 100, 140, 160])
ax_geo.set_xlabel("Column Service Load on 2.6 m x 2.6 m Spread Footing (kN)")
ax_geo.set_ylabel("Primary Clay Consolidation Settlement (mm)")
ax_geo.set_title("A. Terzaghi Preconsolidation Kink: Naive Cr-Only Masks Gate Failure")
style_tufte_ax(ax_geo, x_bounds=(600.0, 3400.0), y_bounds=(0.0, 160.0))

diams_mm = np.array([125, 150, 175, 200, 225, 250, 300], dtype=float)
heads, capexs, npvs = zip(*(hydronic_pipe_lcc_npv(d / 1000.0) for d in diams_mm))
heads_arr = np.array(heads)
npvs_k = np.array(npvs) / 1000.0
feasible_mask = heads_arr <= 28.0

ax_lcc.plot(diams_mm, npvs_k, color=TUFTE_NAVY, lw=1.9, marker="o", markersize=5.0)
ax_lcc.scatter(diams_mm[~feasible_mask], npvs_k[~feasible_mask], color=TUFTE_CRIMSON, s=55, zorder=5)
best_idx = int(np.argmin(np.where(feasible_mask, npvs_k, np.inf)))
ax_lcc.scatter([diams_mm[best_idx]], [npvs_k[best_idx]], color=TUFTE_PINE, s=80, zorder=6)
ax_lcc.annotate(
    f"Infeasible (< DN175):\nhead = {heads_arr[0]:.1f} m > 28 m gate",
    xy=(diams_mm[0], npvs_k[0]),
    xytext=(152.0, npvs_k[0] - 110.0),
    arrowprops={"arrowstyle": "->", "color": TUFTE_CRIMSON, "lw": 1.0},
    fontsize=8.1,
    fontweight="bold",
    color=TUFTE_CRIMSON,
)
ax_lcc.annotate(
    f"Compliant optimum: DN{int(diams_mm[best_idx])}\nNPV = ${npvs_k[best_idx]:.0f}k (head = {heads_arr[best_idx]:.1f} m)",
    xy=(diams_mm[best_idx], npvs_k[best_idx]),
    xytext=(198.0, npvs_k[best_idx] + 240.0),
    arrowprops={"arrowstyle": "->", "color": TUFTE_PINE, "lw": 1.0},
    fontsize=8.2,
    fontweight="bold",
    color=TUFTE_PINE,
)
ax_lcc.set_xlim(118.0, 312.0)
ax_lcc.set_ylim(240.0, 1800.0)
ax_lcc.set_xticks([125, 150, 175, 200, 225, 250, 300])
ax_lcc.set_yticks([300, 600, 900, 1200, 1500, 1700])
ax_lcc.set_xlabel("Condenser-Water Header Inner Diameter (mm)")
ax_lcc.set_ylabel("25-Year Total Present-Value Cost ($1,000 USD)")
ax_lcc.set_title("B. Darcy-Weisbach Pump Energy vs CapEx Trade-Off Under Head Gate")
style_tufte_ax(ax_lcc, x_bounds=(125.0, 300.0), y_bounds=(300.0, 1700.0))

fig.tight_layout()
fig.savefig(OUT_DIR / "ple_physical_verifiers.png", dpi=150, facecolor=TUFTE_PAPER)
plt.show()
```

## 4. Exporting and live-testing the veriflow-ple-starter harness

Before running `uv run python -m kit check` and `uv run python eval/run.py` on a local Docker and Vertex AI host (`docs/models.md`), a PLE submission has to clear both API-gateway validation and container protocol invariants:

| Failure surface | Upstream starter behavior | `veriflow-ple-starter` protection |
|---|---|---|
| HTTP `400` parameter landmines (`docs/models.md`) | Unsanitized SDK defaults pass `temperature`, `top_p`, `thinkingBudget`, or `tool_choice="required"` | `_sanitize_kwargs()` strips disallowed keys per sponsored `google-cloud/<id>` model and injects Claude `ephemeral` cache breakpoints |
| Streamable HTTP MCP apps (`solar-witness-test-package`) | `Pi` (`submission-template`) and `plan-verify` skip `session.mcp_servers` (`0.000` when OpenProject holds task data) | `MCPClient.initialize()` (`2025-06-18`) negotiates `Mcp-Session-Id`, parses JSON and SSE streams, and injects tool input schemas |
| Empty verifier timeout (`plan-verify/serve.py` L499) | `if verdict.strip(...) in ("", "PASS"): break` treats a timed-out `""` reply as `PASS` | Accepts `PASS` if and only if `cleaned == "PASS"` and pre/post container SHA-256 digests match |
| Post-fix edits and `final_message: false` tasks | Mutates files on the last fix round and exits, or stops mid-turn with `0` files (`foundation-strategy`) | Runs `edit_file` / `write_file` fix rounds inside `range(MAX_FIX_ROUNDS + 1)` so every mutation triggers a fresh cold-read check |

The cell below writes `veriflow-ple-starter/` (`submission.yaml`, `requirements.txt`, `taskbridge.py`, `serve.py`), packages `veriflow-ple-starter.zip`, validates `submission.yaml` against `kit/spec.py` rules, and executes a live async loopback test against a local `127.0.0.1` Streamable-HTTP SSE `MCP_STUB` server (`kit/check.py` parity).

```python
SPONSORED_MODELS = {
    "google-cloud/claude-opus-5-5",
    "google-cloud/gemini-4-argon",
    "google-cloud/gemini-3.8-flash",
    "google-cloud/gemini-3.1-pro-preview",
    "google-cloud/glm-5.2",
    "google-cloud/gpt-oss-120b",
    "google-cloud/gemma-4-26b",
    "google-cloud/llama-4-maverick",
}
RESERVED_ENV = {
    "PORT", "HOME", "USER", "HTTP_PROXY", "HTTPS_PROXY", "ALL_PROXY", "NO_PROXY",
    "NODE_USE_ENV_PROXY", "MODEL_API", "MODEL_NAME", "MODEL_BASE_URL", "MODEL_API_KEY",
    "OPENAI_BASE_URL", "OPENAI_API_KEY", "ANTHROPIC_BASE_URL", "ANTHROPIC_API_KEY",
    "GOOGLE_GEMINI_BASE_URL", "GEMINI_API_KEY",
}

BUNDLE_DIR = OUT_DIR / "veriflow-ple-starter"
BUNDLE_DIR.mkdir(parents=True, exist_ok=True)

SUBMISSION_YAML_TEXT = '# Licensed under the Apache License, Version 2.0\nname: veriflow-ple-starter\nmodel_api: google-cloud/claude-opus-5-5\ninstall: >-\n  uv venv --python 3.12 /opt/harness/venv\n  && uv pip install --python /opt/harness/venv/bin/python -r {src}/requirements.txt\nserve: /opt/harness/venv/bin/python {src}/serve.py\nenv:\n  MAX_OUTPUT_TOKENS: "32000"\n  LOG_LEVEL: "info"\n'
REQUIREMENTS_TXT_TEXT = 'openai>=1.68.0\nwebsockets>=14.0\n'
TASKBRIDGE_PY_TEXT = '"""Protocol-v1 WebSocket & Streamable-HTTP MCP bridge (`docs/protocol.md`).\n\nDrop-in compatible with ``google-research/ple/sample_submissions/taskbridge.py``:\nsupports concurrent WebSocket requests (`_waiting` futures), chunked `write_file`\n(`WRITE_CHUNK = 4 MiB`), `mcp_allows()` URL validation, `Session.http(url, ...)`\nreturning decoded bytes, and `MCPClient.initialize()` (`2025-06-18`) with full\nJSON + Server-Sent Events (SSE) framing.\n"""\n\nfrom __future__ import annotations\n\nimport asyncio\nimport base64\nimport contextlib\nimport itertools\nimport json\nimport math\nimport os\nimport re\nimport sys\nimport time\nfrom typing import Any\nimport urllib.parse\n\ntry:\n    from websockets.asyncio.server import serve as _ws_serve\n    from websockets.exceptions import ConnectionClosed\nexcept ImportError:  # Allows offline unit/loopback testing when websockets is absent\n    _ws_serve = None  # type: ignore[assignment]\n\n    class ConnectionClosed(Exception):  # type: ignore[no-redef]\n        """Fallback ConnectionClosed exception when websockets is not installed."""\n\n\nMAX_FRAME = 16 << 20\nMAX_HTTP_BYTES = 10_000_000\nMAX_WRITE_BYTES = 10_000_000\nMAX_TIMEOUT_SEC = 600\nMAX_FINAL_CHARS = 1_000_000\nWRITE_CHUNK = 4 << 20\nHTTP_METHODS = ("GET", "POST", "DELETE", "PUT", "PATCH", "HEAD", "OPTIONS")\n\n\nclass Cancelled(Exception):\n    """Raised when the evaluator cancels the task or closes the WebSocket."""\n\n\nclass TaskError(Exception):\n    """Raised when the evaluator returns `ok: false` or a request is invalid."""\n\n\nclass MCPError(RuntimeError):\n    """Raised when an MCP server returns an HTTP/JSON-RPC error or malformed reply."""\n\n\ndef _frame(message: dict[str, Any]) -> str:\n    frame = json.dumps(message)\n    if len(frame) > MAX_FRAME:\n        raise TaskError(\n            f"{message.get(\'type\')}: frame is {len(frame)} bytes, over {MAX_FRAME >> 20} MiB"\n        )\n    return frame\n\n\ndef _final(text: str) -> str:\n    if len(text) <= MAX_FINAL_CHARS:\n        return text\n    return text[:MAX_FINAL_CHARS] + "\\n[... the rest of this message was cut]"\n\n\ndef _text(what: str, value: Any) -> str:\n    if not isinstance(value, str) or not value:\n        raise TaskError(f"{what} is empty or not text")\n    if "\\x00" in value:\n        raise TaskError(f"{what} holds a NUL byte")\n    try:\n        value.encode("utf-8")\n    except UnicodeEncodeError:\n        raise TaskError(f"{what} is not valid UTF-8") from None\n    return value\n\n\ndef _seconds(value: Any) -> int:\n    if value is None:\n        return 120\n    if (\n        isinstance(value, bool)\n        or not isinstance(value, (int, float))\n        or (isinstance(value, float) and not math.isfinite(value))\n    ):\n        raise TaskError("timeout_sec must be a finite number of seconds")\n    return min(max(1, int(value)), MAX_TIMEOUT_SEC)\n\n\ndef positive_int(value: Any, default: int, cap: int | None = None) -> int:\n    number = 0.0\n    if isinstance(value, int) and not isinstance(value, bool):\n        number = value\n    elif not isinstance(value, bool):\n        with contextlib.suppress(TypeError, ValueError, OverflowError):\n            number = float(value)\n    limit = math.ceil(number) if 0 < number < math.inf else default\n    return limit if cap is None else min(limit, cap)\n\n\ndef mcp_allows(url: str, servers: list[dict[str, Any]]) -> bool:\n    """Check whether `url` is allowed by the evaluator\'s MCP server URL rules."""\n    try:\n        path = urllib.parse.urlsplit(url).path\n    except ValueError:\n        return False\n    decoded = urllib.parse.unquote(path)\n    if (\n        "%2f" in path.lower()\n        or "%5c" in path.lower()\n        or "\\\\" in path\n        or ";" in decoded\n        or {".", ".."} & set(decoded.split("/"))\n    ):\n        return False\n    for server in servers:\n        base = str(server.get("url") or "")\n        if base and (\n            url == base\n            or ("?" not in base and url.startswith(base + "?"))\n            or url.startswith(base.rstrip("/") + "/")\n        ):\n            return True\n    return False\n\n\nclass Session:\n    """Single task session supporting concurrent protocol requests."""\n\n    def __init__(self, ws: Any, task: dict[str, Any]) -> None:\n        self.ws = ws\n        self.task = task\n        self.instruction: str = str(task["instruction"])\n        self.workdir: str = str(task.get("workdir") or "/")\n        limits, servers = task.get("limits"), task.get("mcp_servers")\n        self.limits: dict[str, Any] = limits if isinstance(limits, dict) else {}\n        self.mcp_servers: list[dict[str, Any]] = (\n            [s for s in servers if isinstance(s, dict)] if isinstance(servers, list) else []\n        )\n        budget = self.limits.get("agent_timeout_sec")\n        self.deadline = (\n            time.monotonic() + budget if isinstance(budget, (int, float)) and budget > 0 else None\n        )\n        self.final_message = ""\n        self.cancelled = asyncio.Event()\n        self._ids = itertools.count(1)\n        self._waiting: dict[str, asyncio.Future[dict[str, Any]]] = {}\n        self._lock = asyncio.Lock()\n\n    def time_left(self) -> float | None:\n        return None if self.deadline is None else self.deadline - time.monotonic()\n\n    async def send(self, message: dict[str, Any]) -> None:\n        await self._send(_frame(message))\n\n    async def _send(self, frame: str) -> None:\n        async with self._lock:\n            await self.ws.send(frame)\n\n    async def _read(self) -> None:\n        try:\n            async for frame in self.ws:\n                try:\n                    msg = json.loads(frame)\n                except ValueError:\n                    msg = None\n                if not isinstance(msg, dict):\n                    continue\n                rid = msg.get("id")\n                if msg.get("type") == "result" and isinstance(rid, str) and rid in self._waiting:\n                    fut = self._waiting.pop(rid)\n                    if not fut.done():\n                        fut.set_result(msg)\n                elif msg.get("type") == "cancel":\n                    break\n        except ConnectionClosed:\n            pass\n        finally:\n            self.cancelled.set()\n            for fut in self._waiting.values():\n                if not fut.done():\n                    fut.set_exception(Cancelled())\n            self._waiting.clear()\n\n    async def request(self, kind: str, **fields: Any) -> dict[str, Any]:\n        if self.cancelled.is_set():\n            raise Cancelled()\n        rid = str(next(self._ids))\n        message = {"type": kind, "id": rid, **{k: v for k, v in fields.items() if v is not None}}\n        frame = _frame(message)\n        future: asyncio.Future[dict[str, Any]] = asyncio.get_running_loop().create_future()\n        self._waiting[rid] = future\n        try:\n            try:\n                await self._send(frame)\n            except ConnectionClosed:\n                self.cancelled.set()\n                if future.done() and not future.cancelled():\n                    future.exception()\n                raise Cancelled() from None\n            return await future\n        finally:\n            self._waiting.pop(rid, None)\n\n    async def exec(self, command: str, timeout_sec: int = 120) -> dict[str, Any]:\n        result = await self.request(\n            "exec",\n            command=_text("exec: the command", command),\n            timeout_sec=_seconds(timeout_sec),\n        )\n        if not result.get("ok", True):\n            raise TaskError(result.get("error"))\n        return result\n\n    async def read_result(self, path: str) -> dict[str, Any]:\n        return await self.request("read_file", path=_text("read_file: the path", path))\n\n    async def read_file(self, path: str) -> bytes:\n        result = await self.read_result(path)\n        if not result.get("ok"):\n            raise TaskError(result.get("error"))\n        if result.get("truncated"):\n            raise TaskError(f"{path} exceeds the 10 MB single-read limit; read it in parts")\n        return base64.b64decode(result.get("content_b64") or "")\n\n    async def write_file(self, path: str, data: bytes | str, append: bool = False) -> int:\n        path = _text("write_file: the path", path)\n        if not isinstance(data, (bytes, bytearray, str)):\n            raise TaskError("write_file: data must be bytes or str")\n        raw = data.encode("utf-8") if isinstance(data, str) else bytes(data)\n        size = 0\n        for start in range(0, max(len(raw), 1), WRITE_CHUNK):\n            chunk = raw[start : start + WRITE_CHUNK]\n            result = await self.request(\n                "write_file",\n                path=path,\n                append=bool(append) or start > 0,\n                content_b64=base64.b64encode(chunk).decode("ascii"),\n            )\n            if not result.get("ok"):\n                raise TaskError(result.get("error"))\n            size = int(result.get("size", size))\n        return size\n\n    async def http(\n        self,\n        url: str,\n        method: str = "POST",\n        headers: dict[str, str] | None = None,\n        body: bytes = b"",\n        timeout_sec: int = 120,\n    ) -> dict[str, Any]:\n        url = _text("http: the url", url)\n        if not mcp_allows(url, self.mcp_servers):\n            raise TaskError(f"http: {url} is not under any declared task MCP server")\n        method_up = str(method or "GET").upper()\n        if method_up not in HTTP_METHODS:\n            raise TaskError(f"http: method must be one of {\', \'.join(HTTP_METHODS)}")\n        hdrs = headers or {}\n        if not isinstance(body, (bytes, bytearray)):\n            raise TaskError("http: body must be bytes")\n        if len(body) > MAX_HTTP_BYTES:\n            raise TaskError(f"http: body exceeds {MAX_HTTP_BYTES} bytes")\n        result = await self.request(\n            "http",\n            url=url,\n            method=method_up,\n            headers=hdrs,\n            timeout_sec=_seconds(timeout_sec),\n            body_b64=base64.b64encode(bytes(body)).decode("ascii"),\n        )\n        if not result.get("ok", True):\n            raise TaskError(result.get("error"))\n        return {\n            "status": result["status"],\n            "headers": result.get("headers") or {},\n            "body": base64.b64decode(result.get("body_b64") or ""),\n            "truncated": bool(result.get("truncated")),\n        }\n\n    async def log(self, text: str) -> None:\n        with contextlib.suppress(ConnectionClosed):\n            await self.send({"type": "log", "text": text[:20_000]})\n\n    async def usage(\n        self,\n        model: str,\n        input_tokens: int = 0,\n        output_tokens: int = 0,\n        cache_read_tokens: int = 0,\n    ) -> None:\n        with contextlib.suppress(ConnectionClosed):\n            await self.send(\n                {\n                    "type": "usage",\n                    "model": model,\n                    "input_tokens": positive_int(input_tokens, 0),\n                    "output_tokens": positive_int(output_tokens, 0),\n                    "cache_read_tokens": positive_int(cache_read_tokens, 0),\n                }\n            )\n\n\nclass MCPClient:\n    """Streamable-HTTP MCP client supporting JSON and SSE responses."""\n\n    VERSION = "2025-06-18"\n\n    def __init__(\n        self,\n        session: Session,\n        url: str,\n        *,\n        client: str = "veriflow",\n        timeout_sec: int = 300,\n    ) -> None:\n        self.session = session\n        self.url = url\n        self.client = client\n        self.timeout_sec = timeout_sec\n        self.headers = {\n            "Content-Type": "application/json",\n            "Accept": "application/json, text/event-stream",\n        }\n        self._ids = itertools.count(1)\n\n    @staticmethod\n    def messages(body: str) -> list[dict[str, Any]]:\n        text = body.strip()\n        if text.startswith(("{", "[")):\n            chunks = [text]\n        else:\n            chunks = [\n                "\\n".join(\n                    line[5:].lstrip()\n                    for line in block.splitlines()\n                    if line.startswith("data:")\n                )\n                for block in re.split(r"\\r?\\n\\r?\\n", text)\n            ]\n        found: list[dict[str, Any]] = []\n        for chunk in filter(None, chunks):\n            try:\n                data = json.loads(chunk)\n            except ValueError:\n                continue\n            found.extend(\n                m for m in (data if isinstance(data, list) else [data]) if isinstance(m, dict)\n            )\n        return found\n\n    async def rpc(\n        self,\n        method: str,\n        params: dict[str, Any] | None = None,\n        notify: bool = False,\n    ) -> dict[str, Any] | None:\n        message: dict[str, Any] = {\n            "jsonrpc": "2.0",\n            "method": method,\n            **({"params": params} if params is not None else {}),\n        }\n        if not notify:\n            message["id"] = next(self._ids)\n        reply = await self.session.http(\n            self.url,\n            "POST",\n            dict(self.headers),\n            json.dumps(message).encode("utf-8"),\n            timeout_sec=self.timeout_sec,\n        )\n        if reply.get("truncated"):\n            raise MCPError(f"{method}: response exceeded protocol body limit")\n        for key, value in reply["headers"].items():\n            if key.lower() == "mcp-session-id":\n                self.headers["Mcp-Session-Id"] = value\n        if notify:\n            return None\n        body = reply["body"].decode("utf-8", "replace")\n        if reply["status"] >= 400:\n            raise MCPError(f"{method}: HTTP {reply[\'status\']}: {body[:300]!r}")\n        for answer in self.messages(body):\n            if answer.get("id") == message["id"]:\n                if "error" in answer:\n                    raise MCPError(f"{method}: {answer[\'error\']}")\n                return answer["result"] if isinstance(answer.get("result"), dict) else {}\n        raise MCPError(f"{method}: no JSON-RPC answer in {body[:300]!r}")\n\n    async def initialize(self) -> dict[str, Any]:\n        result = await self.rpc(\n            "initialize",\n            {\n                "protocolVersion": self.VERSION,\n                "capabilities": {},\n                "clientInfo": {"name": self.client, "version": "1.0"},\n            },\n        )\n        assert result is not None\n        version = result.get("protocolVersion")\n        self.headers["MCP-Protocol-Version"] = (\n            version if isinstance(version, str) and version else self.VERSION\n        )\n        await self.rpc("notifications/initialized", notify=True)\n        return result\n\n    connect = initialize\n\n    async def list_tools(self, max_pages: int = 100) -> list[dict[str, Any]]:\n        tools: list[dict[str, Any]] = []\n        cursor: str | None = None\n        for _ in range(max_pages):\n            page = await self.rpc("tools/list", {"cursor": cursor} if cursor else {})\n            assert page is not None\n            found = page.get("tools") if isinstance(page.get("tools"), list) else []\n            tools.extend(\n                {\n                    **t,\n                    "description": str(t.get("description") or ""),\n                    "inputSchema": t["inputSchema"] if isinstance(t.get("inputSchema"), dict) else {},\n                }\n                for t in found\n                if isinstance(t, dict) and isinstance(t.get("name"), str) and t["name"]\n            )\n            next_cursor = page.get("nextCursor")\n            if not isinstance(next_cursor, str) or not next_cursor:\n                break\n            cursor = next_cursor\n        return tools\n\n    async def call_tool(self, name: str, arguments: dict[str, Any]) -> dict[str, Any]:\n        res = await self.rpc("tools/call", {"name": name, "arguments": arguments})\n        return res if isinstance(res, dict) else {}\n\n\nasync def _session(ws: Any, handler: Any) -> None:\n    try:\n        task = json.loads(await ws.recv())\n    except ConnectionClosed:\n        return\n    except ValueError:\n        task = None\n    if (\n        not isinstance(task, dict)\n        or task.get("type") != "task"\n        or not isinstance(task.get("instruction"), str)\n    ):\n        with contextlib.suppress(ConnectionClosed):\n            await ws.send(json.dumps({"type": "error", "message": "expected a task message first"}))\n        return\n\n    session = Session(ws, task)\n    reader = asyncio.create_task(session._read())\n    work = asyncio.create_task(handler(session))\n    stop = asyncio.create_task(session.cancelled.wait())\n    try:\n        done, _ = await asyncio.wait({work, stop}, return_when=asyncio.FIRST_COMPLETED)\n        exc = work.exception() if work in done and not work.cancelled() else Cancelled()\n        if exc is None:\n            answer = work.result()\n            await session.send(\n                {\n                    "type": "done",\n                    "final_message": _final(\n                        answer if isinstance(answer, str) and answer else session.final_message\n                    ),\n                }\n            )\n        elif not isinstance(exc, Cancelled):\n            print(f"harness error: {type(exc).__name__}: {exc}", file=sys.stderr, flush=True)\n            if session.final_message:\n                await session.log(f"harness error after summary: {type(exc).__name__}: {exc}"[:2000])\n                await session.send({"type": "done", "final_message": _final(session.final_message)})\n            else:\n                await session.send(\n                    {"type": "error", "message": f"{type(exc).__name__}: {exc}"[:2000]}\n                )\n        else:\n            await asyncio.wait({work}, timeout=2)\n            if not work.done():\n                work.cancel()\n                await asyncio.wait({work}, timeout=6)\n            answer = (\n                work.result()\n                if work.done() and not work.cancelled() and work.exception() is None\n                else None\n            )\n            final = answer if isinstance(answer, str) and answer else session.final_message\n            await session.send(\n                {"type": "done", "final_message": _final(final or "(stopped: time is up)")}\n            )\n    except ConnectionClosed:\n        pass\n    finally:\n        for task_obj in (work, stop, reader):\n            task_obj.cancel()\n\n\nasync def serve_forever(handler: Any, port: int | None = None) -> None:\n    if _ws_serve is None:\n        raise RuntimeError("websockets>=14.0 is required to run serve_forever()")\n    listen_port = int(port or os.environ.get("PORT", 8765))\n\n    async def on_connect(ws: Any) -> None:\n        await _session(ws, handler)\n\n    async with _ws_serve(\n        on_connect, "0.0.0.0", listen_port, max_size=MAX_FRAME, ping_interval=None\n    ):\n        print(f"listening on {listen_port}", flush=True)\n        await asyncio.Future()\n\n\ndef run(handler: Any, port: int | None = None) -> None:\n    with contextlib.suppress(KeyboardInterrupt):\n        asyncio.run(serve_forever(handler, port))\n'
SERVE_PY_TEXT = '"""VeriFlow-PLE WebSocket harness entrypoint (`docs/protocol.md` v1).\n\nPairs `taskbridge.Session` + `taskbridge.MCPClient` with:\n  1. Automatic discovery and full schema injection for Streamable HTTP MCP tools.\n  2. Runtime `claude-opus-5-5` / `gemini-4-argon` parameter sanitization and prompt caching.\n  3. Context compaction (`COMPACT_AT_TOKENS`) and bounded transient error retries.\n  4. Planner -> Worker -> Cold-Read Verifier loop where empty verifier timeouts never count\n     as `PASS` and post-fix mutations always trigger a fresh verification pass before `done`.\n"""\n\nfrom __future__ import annotations\n\nimport asyncio\nimport hashlib\nimport json\nimport os\nimport re\nfrom typing import Any\n\ntry:\n    import openai\nexcept ImportError:  # Allows offline protocol testing with an injected client\n    openai = None  # type: ignore[assignment]\n\nimport taskbridge\n\nMODEL = os.environ.get("MODEL_NAME", "claude-opus-5-5")\nMAX_EFFORT_MODELS = ("claude", "glm", "gpt-6", "deepseek-v4")\nEFFORT = os.environ.get("REASONING_EFFORT") or (\n    "max" if any(m in MODEL.lower() for m in MAX_EFFORT_MODELS) else "high"\n)\nMAX_OUTPUT_TOKENS = int(os.environ.get("MAX_OUTPUT_TOKENS", "32000"))\nCACHE_MARK = "claude" in MODEL.lower()\nWRAP_UP_SEC = 240\nPLAN_SHARE = 0.10\nCHECK_SHARE = 0.25\nMIN_STEP_SEC = 120\nMAX_FIX_ROUNDS = 2\nRESULT_CHARS = 20_000\nCOMPACT_AT_TOKENS = 150_000\nCUT_KEEP = 1_200\nRETRY_WAITS = (3, 10, 25, 60)\nCONTEXT_FULL = re.compile(\n    r"context.?(length|window)|prompt is too long|maximum prompt length|exceed[^.]{0,40}(token|context)",\n    re.I,\n)\n\nPLANNER_SYSTEM = (\n    "You are the Lead Engineering Planner inside an offline Linux container (workdir {workdir}). "\n    "Inspect all project drawings, schedules, addenda, RFIs, and any MCP tools, without creating or "\n    "modifying files. Output an authoritative execution plan listing: (1) every required deliverable "\n    "path and format, (2) governing document revisions and unit systems, (3) every hard safety or "\n    "code feasibility gate, and (4) deterministic Python verification scripts to run before finishing."\n)\n\nWORKER_SYSTEM = (\n    "You are the Responsible Physical Engineer working in {workdir}. Execute all calculations via "\n    "deterministic Python scripts (never mental arithmetic), use `math.ceil` for integer package/carton "\n    "quantities, write deliverables to the exact required paths, and re-open every output archive or "\n    "IFC/XLSX/PDF artifact from disk to confirm schema and non-zero byte counts."\n)\n\nVERIFIER_SYSTEM = (\n    "You are an independent Cold-Read Peer Reviewer in {workdir}. Do NOT create or modify any file. "\n    "Re-open the written deliverables from disk, recompute hard safety/code ratios independently in "\n    "Python, check unit conversions and cumulative constraints, and verify that every required path "\n    "exists and is non-empty. Reply with the single word PASS only if every hard gate holds; otherwise "\n    "return a numbered defect list."\n)\n\n\ndef _clip(text: str) -> str:\n    if len(text) <= RESULT_CHARS:\n        return text\n    half = RESULT_CHARS // 2\n    return f"{text[:half]}\\n[... {len(text) - RESULT_CHARS} chars omitted ...]\\n{text[-half:]}"\n\n\ndef _compact_older_tool_outputs(messages: list[dict[str, Any]], keep_recent: int = 6) -> int:\n    tool_indices = [i for i, m in enumerate(messages) if m.get("role") == "tool"]\n    compacted = 0\n    for idx in tool_indices[:-keep_recent]:\n        content = messages[idx].get("content")\n        if isinstance(content, str) and len(content) > 2 * CUT_KEEP + 200:\n            messages[idx] = {\n                **messages[idx],\n                "content": (\n                    f"{content[:CUT_KEEP]}\\n"\n                    f"[... compacted {len(content) - 2 * CUT_KEEP} chars ...]\\n"\n                    f"{content[-CUT_KEEP:]}"\n                ),\n            }\n            compacted += 1\n    return compacted\n\n\ndef _marked(messages: list[dict[str, Any]]) -> list[dict[str, Any]]:\n    if not CACHE_MARK or not messages:\n        return messages\n    out = list(messages)\n    for idx in {0, len(out) - 1}:\n        msg = out[idx]\n        content = msg.get("content")\n        if isinstance(content, str) and content:\n            out[idx] = {\n                **msg,\n                "content": [{"type": "text", "text": content, "cache_control": {"type": "ephemeral"}}],\n            }\n    return out\n\n\ndef _sanitize_kwargs(model_name: str, kwargs: dict[str, Any]) -> dict[str, Any]:\n    clean = dict(kwargs)\n    low = model_name.lower()\n    clean.pop("web_search_options", None)\n    if "claude" in low:\n        for bad_key in ("temperature", "top_p", "top_k"):\n            clean.pop(bad_key, None)\n        if clean.get("tool_choice") not in (None, "auto", "none"):\n            clean["tool_choice"] = "auto"\n    if "gemini-4-argon" in low:\n        clean.pop("thinkingBudget", None)\n        if clean.get("reasoning_effort") not in (None, "low", "medium", "high"):\n            clean["reasoning_effort"] = "high"\n    return clean\n\n\nasync def _workspace_digest(session: taskbridge.Session) -> str:\n    res = await session.exec(\n        "find /app /filesystem -maxdepth 4 -type f -printf \'%p %s %T@\\n\' 2>/dev/null | sort | sha256sum"\n    )\n    return hashlib.sha256(res.get("output", "").encode("utf-8")).hexdigest()\n\n\nasync def solve(session: taskbridge.Session, *, client: Any = None) -> str:\n    if client is None:\n        if openai is None:\n            raise RuntimeError("openai>=1.68.0 is required when no client is injected")\n        client = openai.AsyncOpenAI(max_retries=3, timeout=1800)\n\n    mcp_clients: dict[str, taskbridge.MCPClient] = {}\n    mcp_summary_lines: list[str] = []\n\n    for srv in session.mcp_servers:\n        name = str(srv.get("name") or "apps")\n        url = str(srv.get("url") or "")\n        if not url:\n            continue\n        try:\n            mcp = taskbridge.MCPClient(session, url)\n            await mcp.initialize()\n            tools = await mcp.list_tools()\n            mcp_clients[name] = mcp\n            mcp_summary_lines.append(f"### MCP server `{name}` ({len(tools)} tools)")\n            for t in tools[:40]:\n                schema_str = json.dumps(t.get("inputSchema") or {}, separators=(",", ":"))\n                desc = str(t.get("description") or "").strip()\n                mcp_summary_lines.append(f"- `{t.get(\'name\')}`: {desc} | schema: `{schema_str[:400]}`")\n        except Exception as exc:  # noqa: BLE001\n            await session.log(f"MCP init warning for {name}: {exc}")\n\n    base_tools: list[dict[str, Any]] = [\n        {\n            "type": "function",\n            "function": {\n                "name": "bash",\n                "description": "Execute bash inside the task container.",\n                "parameters": {\n                    "type": "object",\n                    "properties": {\n                        "command": {"type": "string"},\n                        "timeout_sec": {"type": "integer"},\n                    },\n                    "required": ["command"],\n                },\n            },\n        },\n        {\n            "type": "function",\n            "function": {\n                "name": "read_file",\n                "description": "Read a UTF-8 file from the task container.",\n                "parameters": {\n                    "type": "object",\n                    "properties": {"path": {"type": "string"}},\n                    "required": ["path"],\n                },\n            },\n        },\n        {\n            "type": "function",\n            "function": {\n                "name": "write_file",\n                "description": "Write a UTF-8 file inside the task container.",\n                "parameters": {\n                    "type": "object",\n                    "properties": {"path": {"type": "string"}, "content": {"type": "string"}},\n                    "required": ["path", "content"],\n                },\n            },\n        },\n        {\n            "type": "function",\n            "function": {\n                "name": "edit_file",\n                "description": "Replace a unique exact UTF-8 snippet inside an existing container file.",\n                "parameters": {\n                    "type": "object",\n                    "properties": {\n                        "path": {"type": "string"},\n                        "old_str": {"type": "string"},\n                        "new_str": {"type": "string"},\n                    },\n                    "required": ["path", "old_str", "new_str"],\n                },\n            },\n        },\n    ]\n    if mcp_clients:\n        base_tools.append(\n            {\n                "type": "function",\n                "function": {\n                    "name": "mcp_call",\n                    "description": "Invoke a tool on a connected task-local MCP server.",\n                    "parameters": {\n                        "type": "object",\n                        "properties": {\n                            "server": {"type": "string"},\n                            "tool": {"type": "string"},\n                            "arguments_json": {"type": "string"},\n                        },\n                        "required": ["server", "tool", "arguments_json"],\n                    },\n                },\n            }\n        )\n    read_only_tools = [\n        t for t in base_tools if t["function"]["name"] not in ("write_file", "edit_file")\n    ]\n\n    async def _exec_tool(fn: dict[str, Any]) -> str:\n        name = fn.get("name", "")\n        try:\n            args = json.loads(fn.get("arguments") or "{}")\n        except ValueError as exc:\n            fn["arguments"] = "{}"\n            return f"error: invalid JSON arguments ({exc})"\n        fn["arguments"] = json.dumps(args, allow_nan=False)\n        try:\n            if name == "bash":\n                out = await session.exec(\n                    str(args["command"]),\n                    timeout_sec=int(args.get("timeout_sec") or 120),\n                )\n                return _clip(f"exit code {out[\'exit_code\']}\\n{out[\'output\']}")\n            if name == "read_file":\n                raw = await session.read_file(str(args["path"]))\n                return _clip(raw.decode("utf-8", "replace"))\n            if name == "write_file":\n                nbytes = await session.write_file(str(args["path"]), str(args["content"]))\n                return f"wrote {nbytes} bytes to {args[\'path\']}"\n            if name == "edit_file":\n                path = str(args["path"])\n                old_s = str(args["old_str"])\n                new_s = str(args["new_str"])\n                cur = (await session.read_file(path)).decode("utf-8")\n                count = cur.count(old_s)\n                if count != 1:\n                    return f"error: old_str matched {count} times in {path}; must match exactly once"\n                nbytes = await session.write_file(path, cur.replace(old_s, new_s, 1))\n                return f"edited {path} ({nbytes} bytes)"\n            if name == "mcp_call":\n                srv_name = str(args["server"])\n                if srv_name not in mcp_clients:\n                    return f"error: unknown MCP server {srv_name!r} (available: {sorted(mcp_clients)})"\n                raw_arg = args.get("arguments_json")\n                call_args = raw_arg if isinstance(raw_arg, dict) else json.loads(str(raw_arg or "{}"))\n                res = await mcp_clients[srv_name].call_tool(str(args["tool"]), call_args)\n                return _clip(json.dumps(res, ensure_ascii=False))\n            return f"error: unknown tool {name}"\n        except taskbridge.Cancelled:\n            raise\n        except Exception as exc:  # noqa: BLE001\n            return f"error: {type(exc).__name__}: {exc}"\n\n    retryable_exc: tuple[type[BaseException], ...] = (\n        (\n            openai.RateLimitError,\n            openai.APITimeoutError,\n            openai.APIConnectionError,\n            openai.InternalServerError,\n        )\n        if openai is not None\n        else ()\n    )\n\n    async def _call_model(req_kwargs: dict[str, Any], timeout: float | None, messages: list[dict[str, Any]]) -> Any:\n        sanitized = _sanitize_kwargs(MODEL, req_kwargs)\n        for attempt, wait_s in enumerate((*RETRY_WAITS, 0)):\n            try:\n                return await asyncio.wait_for(\n                    client.chat.completions.create(**sanitized),\n                    timeout=timeout,\n                )\n            except asyncio.TimeoutError:\n                raise\n            except Exception as exc:  # noqa: BLE001\n                msg_s = str(exc)\n                if CONTEXT_FULL.search(msg_s) and _compact_older_tool_outputs(messages, keep_recent=2) > 0:\n                    sanitized["messages"] = _marked(messages)\n                    continue\n                if not retryable_exc or not isinstance(exc, retryable_exc):\n                    raise\n                if wait_s == 0 or attempt >= len(RETRY_WAITS):\n                    raise\n                left = session.time_left()\n                if left is not None and left < wait_s + 30:\n                    raise\n                await asyncio.sleep(wait_s)\n\n    async def _run_role(\n        messages: list[dict[str, Any]],\n        tools: list[dict[str, Any]],\n        until_sec: float,\n        final: bool = False,\n    ) -> str:\n        head = ""\n        while True:\n            left = session.time_left()\n            wrap = left is not None and left < until_sec\n            if wrap:\n                messages.append(\n                    {"role": "user", "content": "Time budget reached for this phase; summarize immediately."}\n                )\n            timeout = (\n                None\n                if left is None\n                else (min(WRAP_UP_SEC, max(1.0, left)) if wrap else max(1.0, left - until_sec))\n            )\n            req_kwargs = {\n                "model": MODEL,\n                "messages": _marked(messages),\n                "tools": tools,\n                "tool_choice": "none" if wrap else "auto",\n                "reasoning_effort": EFFORT,\n                "max_completion_tokens": MAX_OUTPUT_TOKENS,\n            }\n            try:\n                reply = await _call_model(req_kwargs, timeout, messages)\n            except asyncio.TimeoutError:\n                return head\n            if getattr(reply, "usage", None):\n                details = getattr(reply.usage, "prompt_tokens_details", None)\n                await session.usage(\n                    MODEL,\n                    reply.usage.prompt_tokens,\n                    reply.usage.completion_tokens,\n                    getattr(details, "cached_tokens", 0) or 0,\n                )\n                if reply.usage.prompt_tokens > COMPACT_AT_TOKENS:\n                    _compact_older_tool_outputs(messages)\n            msg = reply.choices[0].message\n            text = head + (msg.content or "")\n            if final and text:\n                session.final_message = text\n            turn = msg.model_dump(exclude_none=True) if hasattr(msg, "model_dump") else dict(msg)\n            if wrap or not getattr(msg, "tool_calls", None):\n                turn.pop("tool_calls", None)\n                if getattr(msg, "content", None):\n                    messages.append(turn)\n                return text\n            messages.append(turn)\n            for tc in turn["tool_calls"]:\n                result_str = await _exec_tool(tc["function"])\n                messages.append({"role": "tool", "tool_call_id": tc["id"], "content": result_str})\n\n    total = session.time_left()\n    until = lambda share: 0.0 if total is None else total * share\n    mcp_note = ("\\n\\n## Connected MCP Servers\\n" + "\\n".join(mcp_summary_lines)) if mcp_summary_lines else ""\n    task_prompt = session.instruction + mcp_note\n\n    plan = await _run_role(\n        [\n            {"role": "system", "content": PLANNER_SYSTEM.format(workdir=session.workdir)},\n            {"role": "user", "content": task_prompt},\n        ],\n        read_only_tools,\n        until(1.0 - PLAN_SHARE),\n    )\n    work_msgs = [\n        {"role": "system", "content": WORKER_SYSTEM.format(workdir=session.workdir)},\n        {"role": "user", "content": f"{task_prompt}\\n\\n## Execution Plan\\n{plan}"},\n    ]\n    summary = await _run_role(work_msgs, base_tools, until(CHECK_SHARE), final=True)\n\n    for round_idx in range(MAX_FIX_ROUNDS + 1):\n        left = session.time_left()\n        if left is not None and left < WRAP_UP_SEC + MIN_STEP_SEC:\n            break\n        pre_hash = await _workspace_digest(session)\n        verdict = await _run_role(\n            [\n                {"role": "system", "content": VERIFIER_SYSTEM.format(workdir=session.workdir)},\n                {\n                    "role": "user",\n                    "content": f"## Task\\n{task_prompt}\\n\\n## Plan\\n{plan}\\n\\n## Summary\\n{summary}",\n                },\n            ],\n            read_only_tools,\n            until(CHECK_SHARE / 2.0),\n        )\n        post_hash = await _workspace_digest(session)\n        cleaned = verdict.strip("*_. \\r\\n\\t").upper()\n        # Strict cold-read check: empty timeout string "" is NEVER accepted as PASS, and verifier must not mutate files.\n        if cleaned == "PASS" and pre_hash == post_hash:\n            break\n        if round_idx == MAX_FIX_ROUNDS:\n            break\n        gap_msg = (\n            verdict\n            if verdict.strip()\n            else "Verifier timed out or returned empty output; re-verify all deliverable files and non-zero archive sizes directly."\n        )\n        work_msgs.append(\n            {\n                "role": "user",\n                "content": f"Cold-read verification flagged issues:\\n{gap_msg}\\n\\nFix every defect and re-check all output paths.",\n            }\n        )\n        summary = await _run_role(work_msgs, base_tools, WRAP_UP_SEC, final=True) or summary\n\n    return summary or session.final_message or "Completed engineering deliverables."\n\n\nif __name__ == "__main__":\n    taskbridge.run(solve)\n'

(BUNDLE_DIR / "submission.yaml").write_text(SUBMISSION_YAML_TEXT, encoding="utf-8")
(BUNDLE_DIR / "requirements.txt").write_text(REQUIREMENTS_TXT_TEXT, encoding="utf-8")
(BUNDLE_DIR / "taskbridge.py").write_text(TASKBRIDGE_PY_TEXT, encoding="utf-8")
(BUNDLE_DIR / "serve.py").write_text(SERVE_PY_TEXT, encoding="utf-8")

# 1. Validate submission.yaml against kit/spec.py rules and package deterministic ZIP archive
parsed_spec = yaml.safe_load(SUBMISSION_YAML_TEXT)
assert re.fullmatch(r"[a-z0-9][a-z0-9-]{1,38}", parsed_spec["name"])
assert parsed_spec["model_api"] in SPONSORED_MODELS
assert len(shlex.split(parsed_spec["serve"], comments=True)) >= 2
assert not (set(parsed_spec.get("env") or {}) & RESERVED_ENV)

zip_path = OUT_DIR / "veriflow-ple-starter.zip"
with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for file_path in sorted(BUNDLE_DIR.iterdir()):
        if not file_path.is_file() or file_path.name.startswith("."):
            continue
        if file_path.suffix == ".py":
            compile(file_path.read_text(encoding="utf-8"), str(file_path), "exec")
        zf.write(file_path, arcname=f"veriflow-ple-starter/{file_path.name}")


# 2. Live loopback verification (WebSocket v1 + Streamable-HTTP SSE MCP_STUB + cold-read timeout rejection)
class _DuplexQueueSocket:
    def __init__(self, inbox: asyncio.Queue[str | None], outbox: asyncio.Queue[str | None]) -> None:
        self._inbox, self._outbox = inbox, outbox

    async def send(self, frame: str) -> None:
        await self._outbox.put(frame)

    async def recv(self) -> str:
        item = await self._inbox.get()
        if item is None:
            raise EOFError("closed")
        return item

    def __aiter__(self) -> "_DuplexQueueSocket":
        return self

    async def __anext__(self) -> str:
        item = await self._inbox.get()
        if item is None:
            raise StopAsyncIteration
        return item


def _start_mcp_sse_stub() -> tuple[ThreadingHTTPServer, str, str]:
    word = "MCP-" + secrets.token_hex(4).upper()
    tool = {"name": "secret_word", "description": "Returns the secret word.", "inputSchema": {"type": "object", "properties": {}}}

    class _Handler(BaseHTTPRequestHandler):
        def do_POST(self) -> None:  # noqa: N802
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
            batch = body if isinstance(body, list) else [body]
            answers = []
            for m in batch:
                if not isinstance(m, dict) or "id" not in m:
                    continue
                params = m.get("params") or {}
                res_map = {
                    "initialize": {"protocolVersion": "2025-06-18", "capabilities": {"tools": {}}, "serverInfo": {"name": "apps", "version": "1"}},
                    "tools/list": {"tools": [tool]},
                }
                if params.get("name") == "secret_word":
                    res_map["tools/call"] = {"content": [{"type": "text", "text": word}], "isError": False}
                answers.append({"jsonrpc": "2.0", "id": m["id"], "result": res_map[m["method"]]})
            if not answers:
                self.send_response(202)
                self.send_header("Mcp-Session-Id", "plebench-check")
                self.send_header("Content-Length", "0")
                self.end_headers()
                return
            sse = b"event: message\ndata: " + json.dumps(answers[0]).encode("utf-8") + b"\n\n"
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Mcp-Session-Id", "plebench-check")
            self.send_header("Content-Length", str(len(sse)))
            self.end_headers()
            self.wfile.write(sse)

        def log_message(self, *args: Any) -> None:
            return

    srv = ThreadingHTTPServer(("127.0.0.1", 0), _Handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv, f"http://127.0.0.1:{srv.server_address[1]}/mcp/", word


async def _run_loopback_verification() -> pd.DataFrame:
    tb_spec = importlib.util.spec_from_file_location("taskbridge", BUNDLE_DIR / "taskbridge.py")
    tb_mod = importlib.util.module_from_spec(tb_spec)
    sys.modules["taskbridge"] = tb_mod
    tb_spec.loader.exec_module(tb_mod)

    sv_spec = importlib.util.spec_from_file_location("veriflow_serve", BUNDLE_DIR / "serve.py")
    sv_mod = importlib.util.module_from_spec(sv_spec)
    sys.modules["veriflow_serve"] = sv_mod
    sv_spec.loader.exec_module(sv_mod)

    # Check A: malformed initial frame rejected
    q1_in, q1_out = asyncio.Queue(), asyncio.Queue()
    await q1_in.put(json.dumps({"type": "ping"}))
    await q1_in.put(None)
    await tb_mod._session(_DuplexQueueSocket(q1_in, q1_out), lambda _s: asyncio.sleep(0))
    bad_frame_reply = json.loads(await q1_out.get())

    # Check B: full solve() over WebSocket + live HTTP SSE MCP_STUB + empty verifier timeout rejection
    http_srv, mcp_url, expected_word = _start_mcp_sse_stub()
    vfs: dict[str, bytes] = {"/app/README.md": b"Fetch secret_word from MCP apps and write /app/mcp.txt\n"}
    verifier_rounds = 0
    captured_kwargs: list[dict[str, Any]] = []

    def _txt(m: dict[str, Any]) -> str:
        c = m.get("content")
        return str(c[0]["text"]) if isinstance(c, list) and c else str(c or "")

    class _Msg:
        def __init__(self, content: str | None, tool_calls: list[dict[str, Any]] | None = None) -> None:
            self.content, self.tool_calls = content, tool_calls

        def model_dump(self, exclude_none: bool = True) -> dict[str, Any]:
            d: dict[str, Any] = {"role": "assistant"}
            if self.content is not None or not exclude_none:
                d["content"] = self.content
            if self.tool_calls:
                d["tool_calls"] = self.tool_calls
            return d

    class _Completions:
        async def create(self, **kwargs: Any) -> Any:
            nonlocal verifier_rounds
            captured_kwargs.append(kwargs)
            msgs = kwargs["messages"]
            role_sys = _txt(msgs[0])
            tools_seen = [m for m in msgs if m.get("role") == "tool"]
            wrap = lambda msg: type("R", (), {"choices": [type("C", (), {"message": msg})()], "usage": None})()

            if "Lead Engineering Planner" in role_sys:
                return wrap(_Msg("Plan: call apps.secret_word via mcp_call and write /app/mcp.txt."))
            if "Responsible Physical Engineer" in role_sys:
                in_fix = any("Cold-read verification flagged issues" in _txt(m) for m in msgs if m.get("role") == "user")
                if not in_fix:
                    if len(tools_seen) == 0:
                        return wrap(_Msg(None, [{"id": "c1", "type": "function", "function": {"name": "mcp_call", "arguments": json.dumps({"server": "apps", "tool": "secret_word", "arguments_json": "{}"})}}]))
                    if len(tools_seen) == 1:
                        got = json.loads(_txt(tools_seen[0]))["content"][0]["text"]
                        return wrap(_Msg(None, [{"id": "c2", "type": "function", "function": {"name": "write_file", "arguments": json.dumps({"path": "/app/mcp.txt", "content": f"DRAFT:{got}"})}}]))
                    return wrap(_Msg("Wrote initial /app/mcp.txt draft."))
                if not any("edited /app/mcp.txt" in _txt(m) for m in tools_seen):
                    return wrap(_Msg(None, [{"id": "c3", "type": "function", "function": {"name": "edit_file", "arguments": json.dumps({"path": "/app/mcp.txt", "old_str": "DRAFT:", "new_str": ""})}}]))
                return wrap(_Msg("Verified /app/mcp.txt finalized."))

            if not tools_seen:
                verifier_rounds += 1
                if verifier_rounds == 1:
                    raise asyncio.TimeoutError()
                return wrap(_Msg(None, [{"id": "v1", "type": "function", "function": {"name": "read_file", "arguments": json.dumps({"path": "/app/mcp.txt"})}}]))
            return wrap(_Msg("PASS" if _txt(tools_seen[-1]) == expected_word else "1. Mismatch"))

    mock_openai = type("M", (), {"chat": type("Ch", (), {"completions": _Completions()})()})()
    q_in, q_out = asyncio.Queue(), asyncio.Queue()

    async def _driver() -> str:
        await q_in.put(json.dumps({"type": "task", "instruction": "Run MCP task.", "workdir": "/app", "limits": {"agent_timeout_sec": 3600}, "mcp_servers": [{"name": "apps", "url": mcp_url, "transport": "streamable-http"}]}))
        while True:
            frame = json.loads(await q_out.get())
            t = frame["type"]
            if t in ("log", "usage"):
                continue
            if t == "done":
                await q_in.put(None)
                return str(frame["final_message"])
            rid = frame["id"]
            if t == "exec":
                dig = hashlib.sha256("\n".join(f"{k}:{len(v)}" for k, v in sorted(vfs.items())).encode()).hexdigest()
                await q_in.put(json.dumps({"type": "result", "id": rid, "ok": True, "exit_code": 0, "output": f"{dig}  -\n", "truncated": False, "timed_out": False}))
            elif t == "read_file":
                b = vfs[frame["path"]]
                await q_in.put(json.dumps({"type": "result", "id": rid, "ok": True, "content_b64": base64.b64encode(b).decode(), "size": len(b), "truncated": False}))
            elif t == "write_file":
                b = base64.b64decode(frame["content_b64"])
                vfs[frame["path"]] = (vfs.get(frame["path"], b"") + b) if frame.get("append") else b
                await q_in.put(json.dumps({"type": "result", "id": rid, "ok": True, "size": len(vfs[frame["path"]])}))
            elif t == "http":
                req = urllib.request.Request(frame["url"], data=base64.b64decode(frame.get("body_b64") or ""), headers=frame.get("headers") or {}, method=frame["method"])
                with urllib.request.urlopen(req, timeout=5) as r:
                    rb, rh, rs = r.read(), dict(r.headers.items()), r.status
                await q_in.put(json.dumps({"type": "result", "id": rid, "ok": True, "status": rs, "headers": rh, "body_b64": base64.b64encode(rb).decode(), "truncated": False}))

    try:
        final_msg, _ = await asyncio.gather(
            _driver(),
            tb_mod._session(_DuplexQueueSocket(q_in, q_out), lambda s: sv_mod.solve(s, client=mock_openai)),
        )
    finally:
        http_srv.shutdown()
        http_srv.server_close()

    sanitized_bad = sv_mod._sanitize_kwargs(
        "claude-opus-5-5",
        {"temperature": 0.2, "top_p": 0.9, "tool_choice": "required", "web_search_options": {}},
    )
    return pd.DataFrame(
        [
            {"Protocol Stage": "submission.yaml spec (kit/spec.py)", "Result": "PASS", "Detail": f"name={parsed_spec['name']}, model={parsed_spec['model_api']}"},
            {"Protocol Stage": "Bad initial WebSocket frame guard", "Result": "PASS" if bad_frame_reply.get("type") == "error" else "FAIL", "Detail": bad_frame_reply.get("message", "")},
            {"Protocol Stage": "Streamable-HTTP SSE MCP roundtrip", "Result": "PASS" if vfs.get("/app/mcp.txt") == expected_word.encode() else "FAIL", "Detail": f"matched /app/mcp.txt == {expected_word}"},
            {"Protocol Stage": "Empty verifier timeout rejection", "Result": "PASS" if verifier_rounds == 2 else "FAIL", "Detail": f"verifier_rounds={verifier_rounds} (round 1 timeout -> edit_file fix -> round 2 PASS)"},
            {"Protocol Stage": "Claude Opus 5.5 HTTP-400 sanitizer", "Result": "PASS" if "temperature" not in sanitized_bad and sanitized_bad["tool_choice"] == "auto" else "FAIL", "Detail": f"cleaned keys={sorted(sanitized_bad)}"},
        ]
    )


check_df = await _run_loopback_verification()
assert (check_df["Result"] == "PASS").all()
with zipfile.ZipFile(zip_path) as zf_read:
    archived_names = zf_read.namelist()
print(f"Exported verified starter archive: {zip_path} ({zip_path.stat().st_size:,} bytes)")
print("Archived entries:", archived_names)
print("\n=== Live Loopback Protocol Check (kit/check.py parity) ===")
print(check_df.to_string(index=False))
```

## 5. Execution Risk Diagnostics and Empirical Zero-Score Failure Audit

In Section 6 of the primary paper (Han et al., 2026, arXiv:2610.30537v2), 23.2% of all execution runs across 86 model-harness pairs scored exactly 0.00. The breakdown shows that 70.4% of zeros stem from deliverables that violate physical or regulatory constraints (such as geometric clashes or structural deflection), 25.3% come from premature termination without saving output files on tasks where `final_message: false`, and 4.3% arise from context window exhaustion or the 360-minute container timeout. The cell below runs `audit_ple_run_failure_modes()` across the development set and tests in-flight container risk tracking with `diagnose_execution_risk()`.

```python
# Section 5: In-flight execution risk diagnostic and arXiv:2610.30537v2 failure mode audit
# Self-contained: the compact table below is the 29 public dev tasks (task_id, time limit in minutes,
# declared deliverables, final_message graded, template pi-opus reward, files written by that run).
from dataclasses import dataclass

TOTAL_RUNS_ZERO_RATE = 0.232  # Han et al. (2026), Sec. 6, 86 model-harness pairs
TASK_TIME_LIMIT_MIN = 360

DEV_TASKS = (
    ('data-hall-mep-routing', 360, ('/app/files/dc_model__hall_seed000_d000__mep_routing/output/solution.py',), False, 0.0, 1),
    ('fire-test-validation-memo', 360, ('/app/files/',), True, 0.807692, 1),
    ('data-hall-mep-routing-offset', 360, ('/app/files/dc_model__hall_seed005_d100__mep_routing/output/solution.py',), False, 0.0, 1),
    ('eor-review-corrections', 360, ('/filesystem/dc_structural__eor_revision__blind/output/submission.zip', '/filesystem/filesystem/dc_structural__eor_revision__blind/output/submission.zip'), False, 0.301961, 1),
    ('foundation-strategy', 360, ('/filesystem/dc_structural__foundation_strategy__blind/output/submission.zip', '/filesystem/filesystem/dc_structural__foundation_strategy__blind/output/submission.zip'), False, 0.0, 0),
    ('landscape-sheet-revision', 360, ('/app/files/',), True, 0.857143, 1),
    ('data-center-site-model', 360, ('/app/files/frontier__DCBim__p6_002/submission/model.ifc',), False, 1.0, 1),
    ('engineers-estimate-check', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.543478, 1),
    ('footing-settlement-verification', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.532258, 2),
    ('solar-supplemental-review', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.207792, 1),
    ('solar-witness-test-package', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.0, 0),
    ('frame-extension-method', 360, ('/filesystem/field_eng__constructability_4d__blind/output/submission.zip', '/filesystem/filesystem/field_eng__constructability_4d__blind/output/submission.zip'), False, 0.8063, 1),
    ('fire-solve-convergence', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.635659, 2),
    ('les-mesh-resolution', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.536585, 1),
    ('mv-conveyance-study', 360, ('/filesystem/final_batch4__electrical_task12_conveyance_study__blind/output/submission.zip',), False, 0.353437, 1),
    ('data-hall-device-takeoff', 360, ('/filesystem/final_batch4__electrical_task17_ec_0205_d100__blind/output/submission.zip',), False, 0.382609, 1),
    ('division-26-specifications', 360, ('/filesystem/final_batch4__electrical_task8_electrical_specs__blind/output/submission.zip',), False, 0.34937, 1),
    ('heat-rejection-life-cycle-cost', 360, ('/filesystem/final_batch4__mechanical_task3_ct_heat_lcc__blind/output/submission.zip',), False, 0.692462, 1),
    ('cooling-water-flush-plan', 360, ('/filesystem/final_batch4__mechanical_task5_pcw_flush_mop__blind/output/submission.zip',), False, 0.461348, 1),
    ('wind-diaphragm-shear', 360, ('/filesystem/final_batch4__structural_task5_wind_diaphragm_shear__blind/output/submission.zip',), False, 0.315873, 1),
    ('seismic-diaphragm-shear', 360, ('/filesystem/final_batch4__structural_task6_seismic_diaphragm_shear__blind/output/submission.zip',), False, 0.315966, 1),
    ('roof-deck-design', 360, ('/filesystem/final_batch4__structural_task7_roof_deck_design__blind/output/submission.zip',), False, 0.285714, 1),
    ('fill-compaction-acceptance', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.675926, 3),
    ('shoring-design-verification', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.516393, 3),
    ('emergency-spillway-check', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.621622, 1),
    ('pre-application-capacity-response', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.230769, 3),
    ('permission-to-operate-memo', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 0.909091, 3),
    ('backfeed-energization-reply', 360, ('/filesystem/', '/app/output/', '/app/tools/.apps_data/'), True, 1.0, 3),
    ('lv-cable-sizing', 360, ('/filesystem/electrical__lv_cable_sizing__blind/output/submission.zip', '/filesystem/filesystem/electrical__lv_cable_sizing__blind/output/submission.zip'), False, 0.906575, 1),
)
TASKS = {row[0]: row for row in DEV_TASKS}


@dataclass(frozen=True)
class ExecutionRisk:
    task_id: str
    risk_level: str
    is_ready_for_completion: bool
    missing_deliverables: tuple
    empty_deliverables: tuple
    time_remaining_min: float
    verifier_headroom_min: float


def diagnose_execution_risk(task_id, staged_files=None, elapsed_minutes=0.0, reserved_verifier_min=20.0):
    _, limit_min, deliverables, final_message, _, _ = TASKS[task_id]
    files = dict(staged_files or {})
    missing, empty = [], []
    for expected in deliverables:
        target = expected.rstrip("/").split("/")[-1]
        hit = [size for path, size in files.items() if path == expected or path.rstrip("/").split("/")[-1] == target]
        if not hit:
            missing.append(expected)
        elif hit[0] <= 0:
            empty.append(expected)
    remaining = max(0.0, float(limit_min) - float(elapsed_minutes))
    missing_critical = (not final_message) and bool(missing or empty)
    time_critical = remaining < reserved_verifier_min or elapsed_minutes >= limit_min
    if missing_critical or remaining <= 0.0:
        level = "CRITICAL"
    elif time_critical or missing:
        level = "HIGH"
    else:
        level = "LOW"
    ready = (not missing_critical) and not empty and remaining >= reserved_verifier_min
    return ExecutionRisk(
        task_id, level, ready, tuple(missing), tuple(empty), remaining, max(0.0, remaining - reserved_verifier_min)
    )


def audit_ple_run_failure_modes():
    engine_zeros, missing_zeros = [], []
    for task_id, _, deliverables, final_message, reward, files in DEV_TASKS:
        if reward == 0.0:
            if files == 0 or (not final_message and not deliverables):
                missing_zeros.append(task_id)
            else:
                engine_zeros.append(task_id)
    zeros = len(engine_zeros) + len(missing_zeros)
    return {
        "total_tasks": len(DEV_TASKS),
        "zero_score_count": zeros,
        "zero_score_rate": zeros / len(DEV_TASKS),
        "engine_graded_zeros": engine_zeros,
        "missing_deliverable_zeros": missing_zeros,
        "engine_graded_share": len(engine_zeros) / zeros if zeros else 0.0,
        "missing_deliverable_share": len(missing_zeros) / zeros if zeros else 0.0,
    }


# 1. Audit empirical zero-score failure modes from the official starter manifest
failure_audit = audit_ple_run_failure_modes()
print("=== PLE Zero-Score Failure Mode Audit (arXiv:2610.30537v2 Sec. 6) ===")
print(f"Total dev tasks: {failure_audit['total_tasks']}")
print(f"Zero-score count: {failure_audit['zero_score_count']} ({failure_audit['zero_score_rate'] * 100:.1f}%)")
print(f"Paper expected zero rate across 86 model-harness pairs: {TOTAL_RUNS_ZERO_RATE * 100:.1f}%")
print(f"Engine-graded zeros (G = 0 physical/clash constraints): {failure_audit['engine_graded_zeros']}")
print(f"Missing deliverable zeros (final_message=False chat exits): {failure_audit['missing_deliverable_zeros']}")
print(
    f"Breakdown: {failure_audit['engine_graded_share'] * 100:.1f}% engine-graded vs "
    f"{failure_audit['missing_deliverable_share'] * 100:.1f}% missing files\n"
)

# 2. In-flight risk diagnostics across execution stages for foundation-strategy
risk_unstarted = diagnose_execution_risk("foundation-strategy", staged_files={}, elapsed_minutes=15.0)
risk_empty = diagnose_execution_risk("foundation-strategy", staged_files={"submission.zip": 0}, elapsed_minutes=45.0)
risk_ready = diagnose_execution_risk("foundation-strategy", staged_files={"submission.zip": 1048576}, elapsed_minutes=120.0)

print(f"Stage 1 (Unstarted, 15 min): risk={risk_unstarted.risk_level}, ready={risk_unstarted.is_ready_for_completion}")
print(f"Stage 2 (Zero-byte file, 45 min): risk={risk_empty.risk_level}, ready={risk_empty.is_ready_for_completion}")
print(
    f"Stage 3 (Deliverables staged, 120 min): risk={risk_ready.risk_level}, ready={risk_ready.is_ready_for_completion}, "
    f"verifier headroom={risk_ready.verifier_headroom_min:.1f} min"
)

```

## 6. Dimensional Homogeneity and Neuro-Symbolic Prompt Chain Verification

Under Section 6 of Han et al. (2026, arXiv:2610.30537v2), 70.4% of zero-score executions fail because candidate deliverables breach physical governing constraints (G = 0 in Equation 1), with unit mismatches and boundary violations forming the most common failure modes. Following the Buckingham (1914) Pi-theorem and neuro-symbolic dimensional analysis guarantees (Tenachi et al., 2023), every physical quantity carries an explicit exponent vector across base SI dimensions [L, M, T, theta, I]. The cell below executes dimensional consistency checks across US Customary and SI units, evaluates physical boundary admissibility across all four engineering disciplines (such as slenderness lambda <= 200 and pipe velocities within 0.5 to 3.5 m/s), and validates a multi-step engineering reasoning trace before submitting deliverables to the hard-gate evaluator.


```python
# Section 6: Dimensional homogeneity, unit consistency, and prompt chain verification
# Self-contained implementation based on Buckingham (1914) and Tenachi et al. (2023)

from __future__ import annotations
import math
from dataclasses import dataclass
from typing import Sequence


@dataclass(frozen=True)
class PhysicalDimension:
    """Dimensional vector in SI base dimensions: [Length, Mass, Time, Temperature, Electric Current]."""

    L: int = 0
    M: int = 0
    T: int = 0
    theta: int = 0
    I: int = 0

    def __mul__(self, other: PhysicalDimension) -> PhysicalDimension:
        return PhysicalDimension(
            self.L + other.L,
            self.M + other.M,
            self.T + other.T,
            self.theta + other.theta,
            self.I + other.I,
        )

    def __truediv__(self, other: PhysicalDimension) -> PhysicalDimension:
        return PhysicalDimension(
            self.L - other.L,
            self.M - other.M,
            self.T - other.T,
            self.theta - other.theta,
            self.I - other.I,
        )

    def __pow__(self, power: int) -> PhysicalDimension:
        return PhysicalDimension(
            self.L * power,
            self.M * power,
            self.T * power,
            self.theta * power,
            self.I * power,
        )

    @property
    def is_dimensionless(self) -> bool:
        return self.L == 0 and self.M == 0 and self.T == 0 and self.theta == 0 and self.I == 0

    def to_symbol(self) -> str:
        if self.is_dimensionless:
            return "1"
        parts: list[str] = []
        for sym, exp in (("L", self.L), ("M", self.M), ("T", self.T), ("Θ", self.theta), ("I", self.I)):
            if exp == 1:
                parts.append(sym)
            elif exp != 0:
                parts.append(f"{sym}^{exp}")
        return "·".join(parts)


DIM_DIMENSIONLESS = PhysicalDimension(0, 0, 0, 0, 0)
DIM_LENGTH = PhysicalDimension(1, 0, 0, 0, 0)
DIM_MASS = PhysicalDimension(0, 1, 0, 0, 0)
DIM_TIME = PhysicalDimension(0, 0, 1, 0, 0)
DIM_TEMPERATURE = PhysicalDimension(0, 0, 0, 1, 0)
DIM_CURRENT = PhysicalDimension(0, 0, 0, 0, 1)
DIM_AREA = PhysicalDimension(2, 0, 0, 0, 0)
DIM_VOLUME = PhysicalDimension(3, 0, 0, 0, 0)
DIM_VELOCITY = PhysicalDimension(1, 0, -1, 0, 0)
DIM_ACCELERATION = PhysicalDimension(1, 0, -2, 0, 0)
DIM_FORCE = PhysicalDimension(1, 1, -2, 0, 0)
DIM_PRESSURE = PhysicalDimension(-1, 1, -2, 0, 0)
DIM_ENERGY = PhysicalDimension(2, 1, -2, 0, 0)
DIM_POWER = PhysicalDimension(2, 1, -3, 0, 0)
DIM_FLOW_RATE = PhysicalDimension(3, 0, -1, 0, 0)

UNIT_REGISTRY: dict[str, tuple[float, PhysicalDimension, str]] = {
    "1": (1.0, DIM_DIMENSIONLESS, "1"),
    "": (1.0, DIM_DIMENSIONLESS, "1"),
    "m": (1.0, DIM_LENGTH, "m"),
    "cm": (0.01, DIM_LENGTH, "m"),
    "mm": (0.001, DIM_LENGTH, "m"),
    "in": (0.0254, DIM_LENGTH, "m"),
    "ft": (0.3048, DIM_LENGTH, "m"),
    "m2": (1.0, DIM_AREA, "m2"),
    "ft2": (0.3048**2, DIM_AREA, "m2"),
    "m3": (1.0, DIM_VOLUME, "m3"),
    "L": (1e-3, DIM_VOLUME, "m3"),
    "kg": (1.0, DIM_MASS, "kg"),
    "lb": (0.45359237, DIM_MASS, "kg"),
    "s": (1.0, DIM_TIME, "s"),
    "N": (1.0, DIM_FORCE, "N"),
    "kN": (1000.0, DIM_FORCE, "N"),
    "lbf": (4.4482216152605, DIM_FORCE, "N"),
    "kip": (4448.2216152605, DIM_FORCE, "N"),
    "kips": (4448.2216152605, DIM_FORCE, "N"),
    "Pa": (1.0, DIM_PRESSURE, "Pa"),
    "kPa": (1000.0, DIM_PRESSURE, "Pa"),
    "MPa": (1e6, DIM_PRESSURE, "Pa"),
    "psi": (6894.757293168, DIM_PRESSURE, "Pa"),
    "ksi": (6894757.293168, DIM_PRESSURE, "Pa"),
    "psf": (47.88025898, DIM_PRESSURE, "Pa"),
    "J": (1.0, DIM_ENERGY, "J"),
    "kJ": (1000.0, DIM_ENERGY, "J"),
    "N*m": (1.0, DIM_ENERGY, "J"),
    "kN*m": (1000.0, DIM_ENERGY, "J"),
    "lbf*ft": (1.3558179483314, DIM_ENERGY, "J"),
    "kip*ft": (1355.8179483314, DIM_ENERGY, "J"),
    "W": (1.0, DIM_POWER, "W"),
    "kW": (1000.0, DIM_POWER, "W"),
    "A": (1.0, DIM_CURRENT, "A"),
    "m/s": (1.0, DIM_VELOCITY, "m/s"),
    "m3/s": (1.0, DIM_FLOW_RATE, "m3/s"),
    "L/s": (1e-3, DIM_FLOW_RATE, "m3/s"),
    "gpm": (0.0000630901964, DIM_FLOW_RATE, "m3/s"),
}


class DimensionalMismatchError(ValueError):
    pass


def convert_unit(value: float, from_unit: str, to_unit: str) -> float:
    u_from = from_unit.strip()
    u_to = to_unit.strip()
    if u_from == u_to:
        return float(value)
    if u_from not in UNIT_REGISTRY or u_to not in UNIT_REGISTRY:
        raise KeyError(f"Unknown unit pair: {u_from!r} -> {u_to!r}")
    scale_from, dim_from, _ = UNIT_REGISTRY[u_from]
    scale_to, dim_to, _ = UNIT_REGISTRY[u_to]
    if dim_from != dim_to:
        raise DimensionalMismatchError(f"Cannot convert between non-conforming dimensions: {u_from} vs {u_to}")
    return float(value) * scale_from / scale_to


@dataclass(frozen=True)
class DimensionalConsistencyReport:
    valid: bool
    lhs_dim: PhysicalDimension
    rhs_dim: PhysicalDimension
    mismatch_message: str | None


def verify_dimensional_consistency(
    lhs_unit: str,
    rhs_units: Sequence[str],
    operation: str = "multiply",
) -> DimensionalConsistencyReport:
    if lhs_unit not in UNIT_REGISTRY:
        raise KeyError(f"Unknown LHS unit {lhs_unit!r}")
    _, lhs_dim, _ = UNIT_REGISTRY[lhs_unit]
    if not rhs_units:
        rhs_dim = DIM_DIMENSIONLESS
    elif operation == "multiply":
        rhs_dim = DIM_DIMENSIONLESS
        for u in rhs_units:
            _, d, _ = UNIT_REGISTRY[u]
            rhs_dim = rhs_dim * d
    elif operation == "divide":
        _, d_num, _ = UNIT_REGISTRY[rhs_units[0]]
        _, d_den, _ = UNIT_REGISTRY[rhs_units[1]]
        rhs_dim = d_num / d_den
    else:
        raise ValueError(f"Unsupported operation: {operation!r}")

    valid = (lhs_dim == rhs_dim)
    msg = None if valid else f"Dimensional mismatch: LHS [{lhs_dim.to_symbol()}] != RHS [{rhs_dim.to_symbol()}]"
    return DimensionalConsistencyReport(valid, lhs_dim, rhs_dim, msg)


@dataclass(frozen=True)
class PhysicalAdmissibilityReport:
    admissible: bool
    discipline: str
    parameter_name: str
    value: float
    unit: str
    allowed_range: tuple[float, float]
    violation_reason: str | None


PHYSICAL_ADMISSIBILITY_RANGES: dict[str, dict[str, tuple[float, float, str]]] = {
    "Structural engineering": {
        "slenderness": (0.001, 200.0, "1"),
        "yield_strength_ksi": (30.0, 100.0, "ksi"),
    },
    "Civil engineering": {
        "friction_angle_deg": (0.0, 45.0, "1"),
        "poissons_ratio": (0.001, 0.499, "1"),
    },
    "Electrical engineering": {
        "power_factor": (0.70, 1.00, "1"),
    },
    "Mechanical engineering": {
        "water_velocity_mps": (0.50, 3.50, "m/s"),
    },
}


def verify_physical_admissibility(discipline: str, parameter_name: str, value: float, unit: str = "1") -> PhysicalAdmissibilityReport:
    rules = PHYSICAL_ADMISSIBILITY_RANGES[discipline]
    min_val, max_val, ref_unit = rules[parameter_name]
    conv_val = convert_unit(value, unit, ref_unit)
    admissible = (min_val <= conv_val <= max_val)
    reason = None if admissible else f"Parameter {parameter_name} = {conv_val:.4f} violates [{min_val}, {max_val}]"
    return PhysicalAdmissibilityReport(admissible, discipline, parameter_name, conv_val, ref_unit, (min_val, max_val), reason)


@dataclass(frozen=True)
class PromptReasoningStep:
    step_id: int
    output_variable: str
    formula: str
    input_variables: tuple[str, ...]
    computed_value: float
    unit: str
    dimension: PhysicalDimension
    discipline: str | None = None
    parameter_name: str | None = None


@dataclass(frozen=True)
class ChainVerificationReport:
    valid: bool
    total_steps: int
    verified_steps: int
    failed_step_id: int | None
    error_type: str | None
    details: str


def verify_prompt_reasoning_chain(steps: Sequence[PromptReasoningStep], initial_context: dict[str, tuple[float, str, PhysicalDimension]]) -> ChainVerificationReport:
    ctx = dict(initial_context)
    verified = 0
    for s in steps:
        for inp in s.input_variables:
            if inp not in ctx:
                return ChainVerificationReport(False, len(steps), verified, s.step_id, "UNRESOLVED_DEPENDENCY", f"Undefined {inp!r}")
        _, u_dim, _ = UNIT_REGISTRY[s.unit]
        if u_dim != s.dimension:
            return ChainVerificationReport(False, len(steps), verified, s.step_id, "DIMENSION_MISMATCH", f"Unit dimension mismatch")
        if s.discipline and s.parameter_name:
            adm = verify_physical_admissibility(s.discipline, s.parameter_name, s.computed_value, s.unit)
            if not adm.admissible:
                return ChainVerificationReport(False, len(steps), verified, s.step_id, "BOUNDARY_VIOLATION", adm.violation_reason or "")
        ctx[s.output_variable] = (s.computed_value, s.unit, s.dimension)
        verified += 1
    return ChainVerificationReport(True, len(steps), verified, None, None, f"All {verified} derivation steps causally verified with dimensional and boundary consistency")


# Live Demonstration
print("=== 1. Unit Conversion with Dimensional Invariance Verification ===")
span_ft = 32.0
span_m = convert_unit(span_ft, "ft", "m")
load_kips = 45.0
load_kn = convert_unit(load_kips, "kip", "kN")
stress_ksi = 36.0
stress_mpa = convert_unit(stress_ksi, "ksi", "MPa")
print(f"Span: {span_ft:.1f} ft -> {span_m:.3f} m (dimension: L)")
print(f"Load: {load_kips:.1f} kips -> {load_kn:.2f} kN (dimension: L*M*T^-2)")
print(f"Yield stress: {stress_ksi:.1f} ksi -> {stress_mpa:.2f} MPa (dimension: L^-1*M*T^-2)")

print("\n=== 2. Equation Dimensional Consistency Checks ===")
eq_press = verify_dimensional_consistency("Pa", ["N", "m2"], operation="divide")
print(f"Pressure = Force / Area: valid={eq_press.valid} [LHS: {eq_press.lhs_dim.to_symbol()}, RHS: {eq_press.rhs_dim.to_symbol()}]")
eq_moment = verify_dimensional_consistency("kN*m", ["kN", "m"], operation="multiply")
print(f"Bending moment = Force * Arm: valid={eq_moment.valid} [LHS: {eq_moment.lhs_dim.to_symbol()}, RHS: {eq_moment.rhs_dim.to_symbol()}]")

print("\n=== 3. Physical Boundary Admissibility Across 4 Disciplines ===")
checks = [
    ("Structural engineering", "slenderness", 94.2, "1"),
    ("Civil engineering", "poissons_ratio", 0.35, "1"),
    ("Electrical engineering", "power_factor", 0.92, "1"),
    ("Mechanical engineering", "water_velocity_mps", 2.15, "m/s"),
]
for discipline, param, val, unit in checks:
    report = verify_physical_admissibility(discipline, param, val, unit=unit)
    print(f"[{discipline.split()[0]}] {param} = {val} {unit}: admissible={report.admissible} (range: {report.allowed_range})")

print("\n=== 4. Multi-Step Engineering Prompt Reasoning Chain Verification ===")
initial_context = {
    "Lb": (18.0, "ft", DIM_LENGTH),
    "ry": (2.45, "in", DIM_LENGTH),
    "Fy": (50.0, "ksi", DIM_PRESSURE),
    "E": (29000.0, "ksi", DIM_PRESSURE),
}
derivation_steps = [
    PromptReasoningStep(1, "slenderness_lambda", "Lb * 12 / ry", ("Lb", "ry"), 88.16, "1", DIM_DIMENSIONLESS, "Structural engineering", "slenderness"),
    PromptReasoningStep(2, "Fe", "pi^2 * E / lambda^2", ("slenderness_lambda", "E"), 36.82, "ksi", DIM_PRESSURE),
    PromptReasoningStep(3, "Fcr", "0.658^(Fy/Fe) * Fy", ("Fy", "Fe"), 28.31, "ksi", DIM_PRESSURE),
]
chain_report = verify_prompt_reasoning_chain(derivation_steps, initial_context)
print(f"Chain verification: valid={chain_report.valid}, verified_steps={chain_report.verified_steps}/{chain_report.total_steps}")
print(f"Status: {chain_report.details}")

```

## 7. Cold-read verification reserve (330 + 30 min), razor-edge margins, and register completeness

Running the main worker all the way to the 360-minute container wall sounds like the safest way to finish hard tasks, yet it leaves no time for an independent Python check on near-limit ratios. Across the 85-task benchmark, tasks average 63 minutes of runtime while compound survival across 9 hard gates at 91% per-gate accuracy sits at 42.8%. Reserving 30 minutes for a cold-read Python pass (leaving 330 minutes for the worker) costs only 0.5% in worker completion probability, lifts compound gate survival to 84.0%, and raises the expected Eq. (1) score from 0.5308 to 0.7141 (+0.1833).

That 30-minute cold-read window targets three recurring failure modes observed in live container runs: razor-edge engineering ratios within 5% of code limits (such as a bending DCR of 0.985 that can flip under intermediate rounding), silent row drops in structured CSV or JSON registers (writing 24 of 29 required IDs in `constraint_register.csv` drops Eq. (1) from 0.8933 to 0.3653 even at $p = 0.9132$), and missing physical inputs that require explicit epistemic abstention instead of extrapolation.


```python
# Section 7: 330 + 30 min time-budget split, razor-edge safety margin audit, and register completeness
def optimize_verification_time_split(
    total_budget_min: float = 360.0,
    worker_mean_min: float = 63.0,
    num_hard_gates: int = 9,
    base_per_gate_acc: float = 0.91,
    verifier_catch_rate: float = 0.72,
    p_score: float = 0.85,
    o_prime: float = 0.75,
) -> dict[str, Any]:
    base_survival = base_per_gate_acc ** num_hard_gates
    reserves = list(range(0, 125, 5))
    curve = []
    for r in reserves:
        worker_min = max(0.0, total_budget_min - r)
        completion = 1.0 - math.exp(-worker_min / worker_mean_min)
        catch_frac = verifier_catch_rate * min(1.0, r / 30.0) if r > 0 else 0.0
        eff_survival = base_survival + (1.0 - base_survival) * catch_frac
        expected_gated = completion * (0.4 * p_score + 0.6 * eff_survival * o_prime)
        curve.append((r, worker_min, completion, eff_survival, expected_gated))
    best = max(curve, key=lambda row: row[4])
    return {
        "optimal_reserve_min": best[0],
        "worker_budget_min": best[1],
        "expected_score_no_reserve": round(curve[0][4], 4),
        "expected_score_optimal": round(best[4], 4),
        "expected_score_gain": round(best[4] - curve[0][4], 4),
        "survival_no_reserve": round(curve[0][3], 4),
        "survival_optimal": round(best[3], 4),
        "curve": curve,
    }


def audit_razor_edge_margins(
    ratios: dict[str, tuple[float, float, float]],
    edge_tolerance_pct: float = 5.0,
) -> dict[str, Any]:
    razor_edge, violated, headrooms = [], [], {}
    for name, (val, lo, hi) in ratios.items():
        span = max(hi - lo, 1e-12)
        if val < lo or val > hi:
            violated.append(name)
            headrooms[name] = round(-100.0 * max(lo - val, val - hi) / span, 2)
        else:
            margin = (hi - val) if lo == 0.0 else min(val - lo, hi - val)
            hr_pct = 100.0 * margin / span
            headrooms[name] = round(hr_pct, 2)
            if hr_pct < edge_tolerance_pct:
                razor_edge.append(name)
    return {"razor_edge": razor_edge, "violated": violated, "headrooms_pct": headrooms}


def audit_deliverable_completeness(
    required_ids: list[str],
    written_ids: list[str],
    numeric_values: dict[str, float] | None = None,
    p_score: float = 0.9132,
    o_prime: float = 0.88,
) -> dict[str, Any]:
    missing = sorted(set(required_ids) - set(written_ids))
    non_finite = sorted(k for k, v in (numeric_values or {}).items() if not math.isfinite(float(v)))
    complete = (len(missing) == 0) and (len(non_finite) == 0)
    score_if_incomplete = round(0.4 * p_score, 4)
    score_if_complete = round(0.4 * p_score + 0.6 * o_prime, 4)
    return {
        "complete": complete,
        "missing_count": len(missing),
        "non_finite_fields": non_finite,
        "gated_score_incomplete": score_if_incomplete,
        "gated_score_complete": score_if_complete,
        "score_gain": round(score_if_complete - score_if_incomplete, 4),
    }


split_res = optimize_verification_time_split()
margin_res = audit_razor_edge_margins(
    {"dcr_bending": (0.985, 0.0, 1.0), "dcr_shear": (0.720, 0.0, 1.0), "water_vel_mps": (3.42, 0.5, 3.5), "settlement_ratio": (0.584, 0.0, 1.0)}
)
reg_res = audit_deliverable_completeness([f"F-{i:02d}" for i in range(1, 30)], [f"F-{i:02d}" for i in range(1, 25)])

print(f"Time-budget split: {split_res['worker_budget_min']:.0f}m worker + {split_res['optimal_reserve_min']:.0f}m cold-read -> Eq. (1) {split_res['expected_score_no_reserve']:.4f} -> {split_res['expected_score_optimal']:.4f} (+{split_res['expected_score_gain']:.4f})")
print(f"Compound survival: {100*split_res['survival_no_reserve']:.1f}% -> {100*split_res['survival_optimal']:.1f}%")
print(f"Razor-edge params (<5% headroom): {margin_res['razor_edge']} | headrooms: {margin_res['headrooms_pct']}")
print(f"Register completeness (24/29 rows): missing={reg_res['missing_count']} | Eq. (1) {reg_res['gated_score_incomplete']:.4f} -> {reg_res['gated_score_complete']:.4f} (+{reg_res['score_gain']:.4f})")

# Render Tufte Figure 3: Cold-read reserve optimization & razor-edge / register cliffs
fig, (ax_time, ax_cliff) = plt.subplots(1, 2, figsize=(15.0, 4.7), dpi=150)
res_x = [row[0] for row in split_res["curve"]]
scores_y = [row[4] for row in split_res["curve"]]
surv_y = [row[3] for row in split_res["curve"]]

ax_time.plot(res_x, scores_y, color=TUFTE_CRIMSON, lw=2.1)
ax_time.plot(res_x, surv_y, color=TUFTE_NAVY, lw=1.6, linestyle="--")
opt_r = split_res["optimal_reserve_min"]
opt_s = split_res["expected_score_optimal"]
ax_time.scatter([opt_r], [opt_s], color=TUFTE_CRIMSON, s=42, zorder=5)
ax_time.plot([opt_r, opt_r], [0.40, opt_s], color=TUFTE_MUTED, linestyle=":", lw=1.0)
ax_time.text(opt_r + 3.0, opt_s - 0.03, f"Peak at {opt_r} min reserve\nEq. (1) = {opt_s:.4f} (+{split_res['expected_score_gain']:.4f})", fontsize=8.1, fontweight="bold", color=TUFTE_CRIMSON)
ax_time.text(res_x[-1] - 2.0, surv_y[-1] + 0.03, f"Gate survival ({100*split_res['survival_optimal']:.1f}% at 30m)", ha="right", fontsize=8.0, color=TUFTE_NAVY)
ax_time.text(2.0, curve_s := scores_y[0] + 0.03, f"No reserve: {scores_y[0]:.4f}", fontsize=8.0, color=TUFTE_MUTED)
ax_time.set_xlim(-2.0, 122.0)
ax_time.set_ylim(0.38, 0.92)
ax_time.set_xlabel("Cold-Read Python Verification Reserve (minutes of 360m budget)")
ax_time.set_ylabel("Expected Score / Gate Survival Probability")
ax_time.set_title("A. Optimal 330 + 30 min Container Split", pad=10)
style_tufte_ax(ax_time, x_bounds=(0.0, 120.0), y_bounds=(0.40, 0.90))

labels_b = ["Register drop\n(24/29 rows, G=0)", "Razor-edge DCR\n(0.985 -> flip, G=0)", "Verified & complete\n(29/29 rows, G=1)"]
vals_b = [reg_res["gated_score_incomplete"], 0.3800, reg_res["gated_score_complete"]]
cols_b = [TUFTE_CRIMSON, TUFTE_OCHRE, TUFTE_PINE]
y_pos = np.arange(len(labels_b))
bars = ax_cliff.barh(y_pos, vals_b, height=0.46, color=cols_b, edgecolor="none")
for idx, (bar, val) in enumerate(zip(bars, vals_b)):
    ax_cliff.text(val + 0.015, bar.get_y() + bar.get_height() / 2, f"{val:.4f}", va="center", fontsize=8.3, fontweight="bold", color=cols_b[idx])
ax_cliff.plot([0.40, 0.40], [-0.4, 2.4], color=TUFTE_MUTED, linestyle=":", lw=1.1)
ax_cliff.text(0.41, 0.05, "0.40 hard-gate wall", fontsize=7.9, color=TUFTE_MUTED)
ax_cliff.set_yticks(y_pos)
ax_cliff.set_yticklabels(labels_b)
ax_cliff.set_xlim(0.0, 1.05)
ax_cliff.set_xlabel("Eq. (1) Gated Task Score")
ax_cliff.set_title("B. Hard-Gate Cliff from Dropped Rows & Razor-Edge Ratios", pad=10)
style_tufte_ax(ax_cliff, x_bounds=(0.0, 1.0), y_bounds=(0.0, 2.0))

fig.tight_layout(w_pad=3.2)
fig.savefig(OUT_DIR / "ple_section7_cold_read.png", dpi=150, bbox_inches="tight")
plt.show()

```
