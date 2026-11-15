# Gate ledger 

- **Author:** chaitanyajamble
- **Kaggle URL:** https://www.kaggle.com/code/chaitanyajamble/gate-ledger

## Approach / key ideas

- Code-only notebook with no prose, an earlier or companion version of the 'artifacts' notebook by the same author.
- Gate algebra: a `Gate` dataclass with value, limit and a naive_value from a shortcut method, giving a DCR (demand/capacity ratio), pass/fail, and a 'masked failure' flag (the naive method passes but the full method fails).
- A `Ledger` collects gates and renders a markdown/JSON table with status and a Gate Fragility Index (GFI, 0-1).
- Useful pattern: record every engineering check in a ledger so failures where the shortcut looked fine get surfaced before submission.
- No model calls and no PLE scores reported.

## Notebook

```python
# This Python 3 environment comes with many helpful analytics libraries installed
# It is defined by the kaggle/python Docker image: https://github.com/kaggle/docker-python
# For example, here's several helpful packages to load

import numpy as np # linear algebra
import pandas as pd # data processing, CSV file I/O (e.g. pd.read_csv)

# Input data files are available in the read-only "../input/" directory
# For example, running this (by clicking run or pressing Shift+Enter) will list all files under the input directory

import os
for dirname, _, filenames in os.walk('/kaggle/input'):
    for filename in filenames:
        print(os.path.join(dirname, filename))

# You can write up to 20GB to the current directory (/kaggle/working/) that gets preserved as output when you create a version using "Save & Run All" 
# You can also write temporary files to /kaggle/temp/, but they won't be saved outside of the current session

# Use the kagglehub client library to attach Kaggle resources like competitions, datasets, and models to your session
# Learn more about kagglehub: https://github.com/Kaggle/kagglehub/blob/main/README.md

import kagglehub
# kagglehub.dataset_download('<owner>/<dataset-slug>')
```

```python
from __future__ import annotations
 
import json
import math
import os
import random
import sys
import tempfile
from dataclasses import dataclass, asdict, field
from typing import Callable, Dict, List, Optional, Sequence, Tuple
 
# ----------------------------------------------------------------- gate algebra
 
 
@dataclass
class Gate:
    name: str
    value: float          # derived quantity (full method)
    limit: float          # allowable value
    naive_value: Optional[float] = None  # quantity from the shortcut method
    unit: str = ""
    source: str = ""
    gfi: Optional[float] = None          # Gate Fragility Index in [0, 1]
 
    @property
    def dcr(self) -> float:
        return self.value / self.limit if self.limit else math.inf
 
    @property
    def passed(self) -> bool:
        return self.value <= self.limit
 
    @property
    def masked_failure(self) -> bool:
        """Naive method says pass while the full method says fail."""
        return self.naive_value is not None and self.naive_value <= self.limit < self.value
 
 
@dataclass
class Ledger:
    gates: List[Gate] = field(default_factory=list)
 
    def add(self, gate: Gate) -> Gate:
        self.gates.append(gate)
        return gate
 
    def ok(self, guard: float = 1.0) -> bool:
        return all(g.dcr <= guard for g in self.gates)
 
    def report(self) -> str:
        rows = ["gate | value | limit | DCR | status | GFI"]
        for g in self.gates:
            status = "MASKED-FAIL" if g.masked_failure else ("PASS" if g.passed else "FAIL")
            gfi = "n/a" if g.gfi is None else f"{g.gfi:.2f}"
            rows.append(f"{g.name} | {g.value:.4g}{g.unit} | {g.limit:.4g}{g.unit} | {g.dcr:.3f} | {status} | {gfi}")
        return "\n".join(rows)
 
    def to_json(self) -> str:
        return json.dumps([dict(asdict(g), dcr=g.dcr, passed=g.passed) for g in self.gates], indent=2)
 
 
def fragility(fn: Callable[[random.Random], bool], trials: int = 400, seed: int = 7) -> float:
    rng = random.Random(seed)
    return sum(1 for _ in range(trials) if fn(rng)) / trials
 
 
def jitter(rng: random.Random, x: float, tol: float) -> float:
    return x * (1.0 + rng.uniform(-tol, tol))
 
# ------------------------------------------------------- kernel 1: steel beam
 
# name: (Ix in^4, Zx in^3, weight plf). Demo table; confirm against the AISC manual.
W_SHAPES: Dict[str, Tuple[float, float, float]] = {
    "W16x31": (375.0, 54.0, 31.0), "W18x50": (800.0, 101.0, 50.0),
    "W21x50": (984.0, 110.0, 50.0), "W24x55": (1350.0, 134.0, 55.0),
    "W24x62": (1550.0, 153.0, 62.0), "W21x62": (1330.0, 144.0, 62.0),
    "W21x68": (1480.0, 160.0, 68.0), "W24x68": (1830.0, 177.0, 68.0),
}
 
 
def beam_gates(shape: str, span_ft: float, dead_klf: float, live_klf: float,
               fy: float = 50.0, e_ksi: float = 29000.0, defl_ratio: float = 360.0,
               tol: float = 0.0, rng: Optional[random.Random] = None) -> Ledger:
    ix, zx, w = W_SHAPES[shape]
    if rng is not None and tol > 0:
        dead_klf, live_klf, span_ft = jitter(rng, dead_klf, tol), jitter(rng, live_klf, tol), jitter(rng, span_ft, tol)
    wd = dead_klf + w / 1000.0
    wu = 1.2 * wd + 1.6 * live_klf
    mu = wu * span_ft ** 2 / 8.0 * 12.0           # kip-in
    phi_mn = 0.9 * fy * zx
    l_in = span_ft * 12.0
    live_defl = 5.0 * (live_klf / 12.0) * l_in ** 4 / (384.0 * e_ksi * ix)
    led = Ledger()
    led.add(Gate("flexure Mu/phiMn", mu, phi_mn, unit=" k-in", source="AISC360 F2"))
    led.add(Gate("live deflection", live_defl, l_in / defl_ratio, unit=" in", source="L/360 live"))
    return led
 
 
def pick_beam(span_ft: float, dead: float, live: float, guard: float = 0.90, gfi_target: float = 0.95,
              tol: float = 0.05) -> Tuple[str, Ledger]:
    best: Optional[Tuple[float, str, Ledger]] = None
    for name, (_, _, wt) in W_SHAPES.items():
        led = beam_gates(name, span_ft, dead, live)
        if not led.ok(guard):
            continue
        for i, g in enumerate(led.gates):
            idx = i
            g.gfi = fragility(lambda r, n=name, k=idx: beam_gates(n, span_ft, dead, live, tol=tol, rng=r).gates[k].passed)
        if all((g.gfi or 0.0) >= gfi_target for g in led.gates) and (best is None or wt < best[0]):
            best = (wt, name, led)
    if best is None:
        raise ValueError("no catalog beam satisfies guard band and fragility target")
    return best[1], best[2]
 
# ------------------------------------------- kernel 2: cumulative V-drop + BOM
 
CU_OHM_PER_KFT = {"2/0": 0.0967, "4/0": 0.0608, "250": 0.0515, "300": 0.0429, "350": 0.0367, "500": 0.0258}
 
 
AMPACITY_75C = {"2/0": 175.0, "4/0": 230.0, "250": 255.0, "300": 285.0, "350": 310.0, "500": 380.0}
 
 
def vdrop_pct(size: str, amps: float, feet: float, volts: float = 480.0) -> float:
    return 100.0 * math.sqrt(3.0) * amps * CU_OHM_PER_KFT[size] * feet / 1000.0 / volts
 
 
def pick_conductor(amps: float, feeder_ft: float, branch_pct: float, limit_pct: float = 5.0,
                   carton_ft: float = 500.0) -> Tuple[str, Ledger, int]:
    for size in CU_OHM_PER_KFT:  # ascending ampacity order in the table above
        if amps > AMPACITY_75C[size]:
            continue
        feeder = vdrop_pct(size, amps, feeder_ft)
        total = feeder + branch_pct
        if total <= limit_pct * 0.95:
            led = Ledger()
            led.add(Gate("cumulative V-drop", total, limit_pct, naive_value=feeder, unit=" %", source="NEC 210/215 FPN"))
            cartons = math.ceil(3 * feeder_ft * 1.05 / carton_ft)  # ceil, never round
            return size, led, cartons
    raise ValueError("no conductor in table meets cumulative voltage drop")
 
# ------------------------------------------ kernel 3: Terzaghi OC/NC clay
 
def clay_settlement_mm(load_kn: float, b_m: float, h_m: float, e0: float, cc: float, cr: float,
                       s0_kpa: float, sp_kpa: float, z_mid_m: float, naive: bool = False) -> float:
    ds = load_kn / ((b_m + z_mid_m) * (b_m + z_mid_m))      # 2:1 stress spread, square pad
    sf = s0_kpa + ds
    k = h_m / (1.0 + e0)
    if naive or sf <= sp_kpa:
        s = k * cr * math.log10(sf / s0_kpa)
    elif s0_kpa >= sp_kpa:
        s = k * cc * math.log10(sf / s0_kpa)
    else:
        s = k * (cr * math.log10(sp_kpa / s0_kpa) + cc * math.log10(sf / sp_kpa))
    return s * 1000.0
 
 
def pick_pad(load_kn: float, limit_mm: float = 25.0, guard: float = 0.90, gfi_target: float = 0.95) -> Tuple[float, Ledger]:
    args = dict(h_m=3.0, e0=0.9, cc=0.30, cr=0.04, s0_kpa=70.0, sp_kpa=130.0, z_mid_m=3.0)
    b = 2.0
    while b <= 8.0:
        full = clay_settlement_mm(load_kn, b, **args)
        if full <= limit_mm * guard:
            led = Ledger()
            g = Gate("clay settlement", full, limit_mm,
                     naive_value=clay_settlement_mm(load_kn, b, naive=True, **args), unit=" mm", source="Terzaghi OC->NC")
            g.gfi = fragility(lambda r: clay_settlement_mm(load_kn, b, **dict(args, cc=jitter(r, 0.30, 0.15), sp_kpa=jitter(r, 130.0, 0.10))) <= limit_mm)
            led.add(g)
            if (g.gfi or 0.0) >= gfi_target:
                return round(b, 2), led
        b += 0.2
    raise ValueError("no pad width up to 8 m meets settlement limit")
 
# --------------------------------------- kernel 4: Darcy-Weisbach NPV pipe
 
 
def head_loss_m(d_mm: float, q_lps: float, length_m: float, rough_mm: float = 0.046) -> float:
    d, q = d_mm / 1000.0, q_lps / 1000.0
    v = q / (math.pi * d * d / 4.0)
    re = v * d / 1.0e-6
    f = 0.25 / (math.log10(rough_mm / 1000.0 / (3.7 * d) + 5.74 / re ** 0.9)) ** 2  # Swamee-Jain
    return f * length_m / d * v * v / (2.0 * 9.81)
 
 
def pick_pipe(q_lps: float = 150.0, length_m: float = 800.0, head_gate_m: float = 28.0) -> Tuple[int, Ledger, float]:
    best: Optional[Tuple[float, int, Ledger]] = None
    for dn in (125, 150, 175, 200, 225, 250, 300):
        h = head_loss_m(dn, q_lps, length_m)
        capex = 0.9 * dn * length_m
        kw = 1000.0 * 9.81 * (q_lps / 1000.0) * h / 0.7 / 1000.0
        pv = sum(kw * 8000.0 * 0.12 / (1.06 ** y) for y in range(1, 26))
        npv = capex + pv
        led = Ledger()
        led.add(Gate("pump head", h, head_gate_m, unit=" m", source="Darcy-Weisbach"))
        if led.ok(0.95) and (best is None or npv < best[0]):
            best = (npv, dn, led)
    if best is None:
        raise ValueError("no diameter meets head gate")
    return best[1], best[2], best[0]
 
# ----------------------------------------------- kernel 5: revision resolver
 
 
def resolve_revisions(docs: Sequence[Tuple[str, str, float]]) -> Tuple[float, bool, str]:
    """docs = (filename, ISO date, value). Latest date wins; same-date disagreement = conflict."""
    ordered = sorted(docs, key=lambda d: d[1])
    latest = [d for d in ordered if d[1] == ordered[-1][1]]
    return latest[-1][2], len({d[2] for d in latest}) > 1, latest[-1][0]
 
# ------------------------------------------------- verifier budget planner
 
 
def verifier_rounds(q: float, k: int, catch: float = 0.6, target: float = 0.90, cap: int = 8) -> int:
    """Smallest r with prod over k gates of 1-(1-q)(1-catch)^r >= target."""
    for r in range(cap + 1):
        if (1.0 - (1.0 - q) * (1.0 - catch) ** r) ** k >= target:
            return r
    return cap
 
 
def cold_read_brief(led: Ledger) -> str:
    lines = ["Recompute each gate independently from disk files; reply PASS only if every DCR <= 1.0:"]
    lines += [f"- {g.name}: limit {g.limit:.4g}{g.unit} ({g.source}); also run the naive variant and report any flip." for g in led.gates]
    return "\n".join(lines)
 
# ----------------------------------------------------------------- self-test
 
 
def main() -> int:
    master = Ledger()
    shape, led = pick_beam(span_ft=30.0, dead=0.60, live=0.90)
    master.gates += led.gates
    size, led, cartons = pick_conductor(amps=280.0, feeder_ft=300.0, branch_pct=1.2)
    master.gates += led.gates
    width, led = pick_pad(load_kn=3400.0)
    master.gates += led.gates
    dn, led, npv = pick_pipe()
    master.gates += led.gates
    wind, conflict, src = resolve_revisions([("Prelim_Sheet.pdf", "2026-01-10", 105.0), ("AHJ_Wind_Directive.pdf", "2026-03-02", 115.0)])
    print("Selected: beam", shape, "| conductor", size, f"| cartons {cartons}", f"| pad {width} m", f"| pipe DN{dn} NPV ${npv:,.0f}")
    print("Wind:", wind, "mph from", src, "conflict =", conflict)
    print(master.report())
    masked = [g.name for g in master.gates if g.masked_failure]
    print("Masked failures at selected designs:", masked or "none")
    # show the shortcut trap: a Cr-only pad that looks fine but fails the full check
    trap = clay_settlement_mm(3400.0, 2.6, 3.0, 0.9, 0.30, 0.04, 70.0, 130.0, 3.0)
    trap_naive = clay_settlement_mm(3400.0, 2.6, 3.0, 0.9, 0.30, 0.04, 70.0, 130.0, 3.0, naive=True)
    print(f"Trap (3400 kN on 2.6 m pad): Cr-only {trap_naive:.1f} mm vs OC+NC {trap:.1f} mm (limit 25 mm)")
    print("Verifier rounds for q=0.91,k=9:", verifier_rounds(0.91, 9), "| q=0.96,k=9:", verifier_rounds(0.96, 9))
    print(cold_read_brief(master).splitlines()[0])
    out = os.path.join(tempfile.mkdtemp(prefix="gateledger_"), "ledger.json")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(master.to_json())
    print("Ledger JSON bytes:", os.path.getsize(out))
    return 0 if master.ok() else 1
 
 
def _in_notebook() -> bool:
    """True under IPython/Jupyter/Kaggle, where raising SystemExit triggers a UserWarning."""
    return "ipykernel" in sys.modules or "IPython" in sys.modules or hasattr(sys, "ps1")
 
 
if __name__ == "__main__":
    _code = main()
    if not _in_notebook():
        sys.exit(_code)
```
