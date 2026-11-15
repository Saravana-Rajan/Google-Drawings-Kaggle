# Artifacts

- **Author:** chaitanyajamble
- **Kaggle URL:** https://www.kaggle.com/code/chaitanyajamble/artifacts

## Approach / key ideas

- Extends the gate-ledger code (same Gate/Ledger/GFI algebra) and adds analysis artifacts: tables and figures for score/cost and attrition.
- References gpt-4o-mini, apparently as an example model; no real PLE run is reported.
- Detects masked failures (shortcut passes, full method fails) and ranks gates by GFI.
- Exports JSON for downstream harness use.
- Mostly code with little explanation; useful as a building block for a verification ledger.

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
import warnings
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
 
 
# ------------------------------------------- optional GPU / vectorised backend
 
_BACKEND: Optional[Tuple[str, object]] = None
_BACKEND_READY = False
 
 
def get_backend() -> Tuple[str, object]:
    """Pick the fastest available array backend; never raises.
 
    Order: torch+CUDA, cupy+CUDA, numpy (CPU, vectorised), pure Python ("python", None).
    """
    global _BACKEND, _BACKEND_READY
    if _BACKEND_READY and _BACKEND is not None:
        return _BACKEND
    found: Tuple[str, object] = ("python", None)
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        try:
            import torch  # type: ignore
            if torch.cuda.is_available():
                found = ("torch-cuda", torch)
        except Exception:  # noqa: BLE001 - any import/driver problem means "not available"
            pass
        if found[1] is None:
            try:
                import cupy  # type: ignore
                if cupy.cuda.runtime.getDeviceCount() > 0:
                    found = ("cupy-cuda", cupy)
            except Exception:  # noqa: BLE001
                pass
        if found[1] is None:
            try:
                import numpy  # type: ignore
                found = ("numpy-cpu", numpy)
            except Exception:  # noqa: BLE001
                pass
    _BACKEND, _BACKEND_READY = found, True
    return found
 
 
def _uniform(name: str, lib: object, n: int, seed: int):
    if name == "torch-cuda":
        gen = lib.Generator(device="cuda")  # type: ignore[attr-defined]
        gen.manual_seed(seed)
        return lib.rand(n, dtype=lib.float64, device="cuda", generator=gen)  # type: ignore[attr-defined]
    if name == "cupy-cuda":
        return lib.random.default_rng(seed).random(n)  # type: ignore[attr-defined]
    return lib.random.default_rng(seed).random(n)  # type: ignore[attr-defined]
 
 
def clay_fragility_batch(load_kn: float, b_m: float, limit_mm: float, args: Dict[str, float],
                         trials: int, seed: int = 7) -> Tuple[float, str]:
    """GFI for the clay gate with Cc +/-15% and preconsolidation pressure +/-10%.
 
    Vectorised on GPU when torch/cupy+CUDA exist, else numpy, else the scalar Python loop.
    Unified piecewise form: s = k*(Cr*log10(min(sf,sp)/s0) + Cc*log10(max(sf,sp)/sp)), sp >= s0.
    """
    name, lib = get_backend()
    if lib is None:
        def one(r: random.Random) -> bool:
            return clay_settlement_mm(load_kn, b_m, **dict(args, cc=jitter(r, args["cc"], 0.15),
                                                           sp_kpa=jitter(r, args["sp_kpa"], 0.10))) <= limit_mm
        return fragility(one, trials=min(trials, 2000), seed=seed), name
    u1 = _uniform(name, lib, trials, seed)
    u2 = _uniform(name, lib, trials, seed + 1)
    s0 = float(args["s0_kpa"])
    cc = args["cc"] * (1.0 + 0.15 * (2.0 * u1 - 1.0))
    sp = lib.clip(args["sp_kpa"] * (1.0 + 0.10 * (2.0 * u2 - 1.0)), s0, None)
    sf = s0 + load_kn / ((b_m + args["z_mid_m"]) ** 2)
    k = args["h_m"] / (1.0 + args["e0"])
    low = lib.clip(sp, None, sf)     # min(sp, sf)
    high = lib.clip(sp, sf, None)    # max(sp, sf)
    settle_mm = k * (args["cr"] * lib.log10(low / s0) + cc * lib.log10(high / sp)) * 1000.0
    passed = float((settle_mm <= limit_mm).sum())
    return passed / float(trials), name
 
 
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
            trials = 2_000_000 if get_backend()[0].endswith("cuda") else 200_000
            g.gfi = clay_fragility_batch(load_kn, b, limit_mm, args, trials)[0]
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
    print("Compute backend:", get_backend()[0])
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
 
 
# =====================================================================================
# ARTIFACT FACTORY: LLM-assisted extraction + deterministic engineering kernels
# =====================================================================================
import csv
import hashlib
import re
import urllib.request
 
DEMO_TASKS: List[Dict[str, object]] = [
    {"id": "structural-beam", "kind": "beam", "discipline": "Structural",
     "text": "Design a simply supported steel W-beam spanning 30 ft carrying dead load 0.60 klf and live load 0.90 klf. "
             "Check LRFD flexure and keep live-load deflection within L/360."},
    {"id": "electrical-feeder", "kind": "feeder", "discipline": "Electrical",
     "text": "Size a copper feeder for a 280 A load, feeder length 300 ft, downstream branch drop 1.2 %. "
             "Cumulative voltage drop must stay within 5 %. Provide a cable bill of materials in 500 ft cartons."},
    {"id": "civil-footing", "kind": "footing", "discipline": "Civil",
     "text": "A column with service load 3400 kN bears on a square spread footing over an overconsolidated clay layer. "
             "Settlement must not exceed 25 mm. Choose the footing width."},
    {"id": "mechanical-header", "kind": "pipe", "discipline": "Mechanical",
     "text": "Select the condenser-water header diameter for flow 150 L/s over length 800 m. "
             "Pump head must not exceed the 28 m head gate. Minimise 25-year present value cost."},
    {"id": "corpus-wind", "kind": "revision", "discipline": "Corpus",
     "text": "Determine the governing design wind speed from the document set.",
     "docs": [["Prelim_Sheet.pdf", "2026-01-10", 105.0], ["AHJ_Wind_Directive.pdf", "2026-03-02", 115.0]]},
]
 
FIELDS: Dict[str, List[Tuple[str, float, float]]] = {  # name, min, max (sanity range)
    "beam": [("span_ft", 5.0, 120.0), ("dead_klf", 0.0, 10.0), ("live_klf", 0.0, 10.0)],
    "feeder": [("amps", 10.0, 600.0), ("feeder_ft", 10.0, 3000.0), ("branch_pct", 0.0, 5.0)],
    "footing": [("load_kn", 50.0, 20000.0)],
    "pipe": [("q_lps", 1.0, 2000.0), ("length_m", 10.0, 10000.0), ("head_gate_m", 1.0, 200.0)],
}
 
REGEX: Dict[str, Dict[str, str]] = {
    "beam": {"span_ft": r"([\d.]+)\s*ft", "dead_klf": r"dead load\s*([\d.]+)\s*klf", "live_klf": r"live load\s*([\d.]+)\s*klf"},
    "feeder": {"amps": r"([\d.]+)\s*A\b", "feeder_ft": r"feeder length\s*([\d.]+)\s*ft", "branch_pct": r"branch drop\s*([\d.]+)\s*%"},
    "footing": {"load_kn": r"service load\s*([\d.]+)\s*kN"},
    "pipe": {"q_lps": r"flow\s*([\d.]+)\s*L/s", "length_m": r"length\s*([\d.]+)\s*m\b", "head_gate_m": r"(\d+(?:\.\d+)?)\s*m head gate"},
}
 
 
def regex_extract(kind: str, text: str) -> Dict[str, float]:
    out: Dict[str, float] = {}
    for name, pat in REGEX.get(kind, {}).items():
        m = re.search(pat, text, flags=re.I)
        if m:
            try:
                out[name] = float(m.group(1))
            except ValueError:
                pass
    return out
 
 
def get_api_key() -> str:
    key = os.environ.get("OPENAI_API_KEY", "").strip()
    if key:
        return key
    try:  # Kaggle Secrets, if present
        from kaggle_secrets import UserSecretsClient  # type: ignore
        return str(UserSecretsClient().get_secret("OPENAI_API_KEY")).strip()
    except Exception:  # noqa: BLE001
        return ""
 
 
USAGE = {"calls": 0, "prompt_tokens": 0, "completion_tokens": 0, "failures": 0}
 
 
def call_llm(system: str, user: str, json_mode: bool = False) -> Optional[str]:
    """Minimal OpenAI chat call via urllib. Returns None on ANY problem (no key, offline, bad reply)."""
    key = get_api_key()
    if not key:
        return None
    body = {"model": os.environ.get("OPENAI_MODEL", "gpt-4o-mini"), "temperature": 0,
            "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}]}
    if json_mode:
        body["response_format"] = {"type": "json_object"}
    req = urllib.request.Request("https://api.openai.com/v1/chat/completions", data=json.dumps(body).encode("utf-8"),
                                 headers={"Content-Type": "application/json", "Authorization": "Bearer " + key})
    try:
        with urllib.request.urlopen(req, timeout=int(os.environ.get("LLM_TIMEOUT", "30"))) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
        USAGE["calls"] += 1
        usage = payload.get("usage") or {}
        USAGE["prompt_tokens"] += int(usage.get("prompt_tokens", 0))
        USAGE["completion_tokens"] += int(usage.get("completion_tokens", 0))
        return str(payload["choices"][0]["message"]["content"])
    except Exception:  # noqa: BLE001 - network, auth, quota, parse: all fall back silently
        USAGE["failures"] += 1
        return None
 
 
def llm_extract(kind: str, text: str) -> Dict[str, float]:
    names = [f[0] for f in FIELDS.get(kind, [])]
    if not names:
        return {}
    raw = call_llm("Extract numeric design inputs from an engineering task. Reply with a JSON object only, "
                   "keys exactly: " + ", ".join(names) + ". Use the units implied by the key suffix. Never guess.",
                   text, json_mode=True)
    if raw is None:
        return {}
    try:
        data = json.loads(raw)
    except ValueError:
        return {}
    out: Dict[str, float] = {}
    for name, lo, hi in FIELDS[kind]:
        v = data.get(name) if isinstance(data, dict) else None
        if isinstance(v, (int, float)) and not isinstance(v, bool) and lo <= float(v) <= hi:
            out[name] = float(v)
    return out
 
 
def merge_params(kind: str, rx: Dict[str, float], lm: Dict[str, float]) -> Tuple[Dict[str, float], List[str], str]:
    """Dual extraction: regex (verbatim text) wins on conflict; the LLM fills gaps. Conflicts are reported."""
    params: Dict[str, float] = {}
    notes: List[str] = []
    source = "regex"
    for name, _, _ in FIELDS.get(kind, []):
        if name in rx and name in lm:
            if abs(rx[name] - lm[name]) > 1e-9:
                notes.append(f"CONFLICT {name}: regex={rx[name]} llm={lm[name]} -> regex used")
            params[name] = rx[name]
        elif name in rx:
            params[name] = rx[name]
        elif name in lm:
            params[name] = lm[name]
            notes.append(f"{name} taken from LLM only")
            source = "llm+regex"
    if lm and source == "regex":
        source = "llm+regex"
    return params, notes, source
 
 
def solve_task(task: Dict[str, object]) -> Dict[str, object]:
    kind = str(task["kind"])
    text = str(task["text"])
    res: Dict[str, object] = {"id": task["id"], "discipline": task["discipline"], "kind": kind, "status": "ok"}
    led = Ledger()
    try:
        if kind == "revision":
            docs = [(str(d[0]), str(d[1]), float(d[2])) for d in task["docs"]]  # type: ignore[union-attr]
            value, conflict, src = resolve_revisions(docs)
            res.update(params={"documents": [d[0] for d in docs]}, answer={"wind_mph": value, "source": src, "conflict": conflict},
                       notes=[], extraction="deterministic")
            led.add(Gate("revision conflict (0=none)", 1.0 if conflict else 0.0, 0.5, unit="", source=src))
            return dict(res, ledger=led)
        params, notes, source = merge_params(kind, regex_extract(kind, text), llm_extract(kind, text))
        missing = [n for n, _, _ in FIELDS[kind] if n not in params]
        if missing:
            return dict(res, status="incomplete", params=params, notes=notes + ["missing inputs: " + ", ".join(missing)],
                        extraction=source, answer={}, ledger=led)
        if kind == "beam":
            shape, led = pick_beam(params["span_ft"], params["dead_klf"], params["live_klf"])
            answer: Dict[str, object] = {"section": shape}
        elif kind == "feeder":
            size, led, cartons = pick_conductor(params["amps"], params["feeder_ft"], params["branch_pct"])
            answer = {"conductor_kcmil": size, "cartons_500ft": cartons}
        elif kind == "footing":
            width, led = pick_pad(params["load_kn"])
            answer = {"pad_width_m": width}
        else:
            dn, led, npv = pick_pipe(params["q_lps"], params["length_m"], params["head_gate_m"])
            answer = {"diameter_dn": dn, "npv_usd": round(npv, 0)}
        res.update(params=params, notes=notes, extraction=source, answer=answer)
    except ValueError as exc:  # infeasible within the catalog: record, never crash
        res.update(status="infeasible", params={}, notes=[str(exc)], extraction="n/a", answer={})
    return dict(res, ledger=led)
 
 
def memo_text(res: Dict[str, object]) -> str:
    led: Ledger = res["ledger"]  # type: ignore[assignment]
    facts = json.dumps({"answer": res.get("answer"), "gates": [
        {"name": g.name, "value": round(g.value, 4), "limit": g.limit, "dcr": round(g.dcr, 3)} for g in led.gates]})
    prose = call_llm("You write 3-sentence engineering memo summaries. Use ONLY the numbers given; never add or change any number.",
                     facts)
    if not prose:
        prose = f"Design for {res['id']} ({res['discipline']}): result {json.dumps(res.get('answer'))}. All numbers below were computed by deterministic kernels."
    table = led.report().replace(" | ", " | ")
    return (f"# Memo: {res['id']}\n\nStatus: {res['status']}  |  Extraction: {res.get('extraction')}\n\n{prose.strip()}\n\n"
            f"## Gate ledger (governing numbers)\n\n```\n{table}\n```\n\n## Extraction notes\n\n"
            + ("\n".join("- " + n for n in res.get("notes", [])) or "- none") + "\n")  # type: ignore[union-attr]
 
 
def write_text(path: str, text: str) -> None:
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)
 
 
def sha256_of(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        h.update(fh.read())
    return h.hexdigest()
 
 
def pick_out_dir() -> str:
    want = os.environ.get("ARTIFACT_DIR", os.path.join(os.getcwd(), "artifacts"))
    try:
        os.makedirs(want, exist_ok=True)
        probe = os.path.join(want, ".probe")
        write_text(probe, "ok")
        os.remove(probe)
        return want
    except OSError:
        return tempfile.mkdtemp(prefix="artifacts_")
 
 
def run_factory() -> int:
    out = pick_out_dir()
    manifest: List[Dict[str, object]] = []
    failures: List[List[object]] = [["task", "discipline", "status", "failed_gates", "masked_failures"]]
    for task in DEMO_TASKS:
        res = solve_task(task)
        led: Ledger = res["ledger"]  # type: ignore[assignment]
        tdir = os.path.join(out, str(res["id"]))
        os.makedirs(tdir, exist_ok=True)
        calc = {k: v for k, v in res.items() if k != "ledger"}
        write_text(os.path.join(tdir, "calc.json"), json.dumps(calc, indent=2))
        write_text(os.path.join(tdir, "ledger.json"), led.to_json() if led.gates else "[]")
        write_text(os.path.join(tdir, "memo.md"), memo_text(res))
        write_text(os.path.join(tdir, "verifier_brief.txt"), cold_read_brief(led) if led.gates else "No gates recorded.")
        failures.append([res["id"], res["discipline"], res["status"], sum(1 for g in led.gates if not g.passed),
                         sum(1 for g in led.gates if g.masked_failure)])
        print(f"{res['id']:<18} status={res['status']:<10} extraction={res.get('extraction')!s:<11} answer={json.dumps(res.get('answer'))}")
    # survival-vs-verifier-rounds table (source data for the score/cost and attrition figures)
    rows: List[List[object]] = [["q", "k", "joint_survival", "verifier_rounds_for_0.90"]]
    for q in (0.85, 0.91, 0.96, 0.99):
        for k in (3, 6, 9, 12, 15):
            rows.append([q, k, round(q ** k, 4), verifier_rounds(q, k)])
    with open(os.path.join(out, "gate_survival.csv"), "w", newline="", encoding="utf-8") as fh:
        csv.writer(fh).writerows(rows)
    with open(os.path.join(out, "failure_breakdown.csv"), "w", newline="", encoding="utf-8") as fh:
        csv.writer(fh).writerows(failures)
    write_text(os.path.join(out, "usage.json"), json.dumps(dict(USAGE, model=os.environ.get("OPENAI_MODEL", "gpt-4o-mini"),
                                                               llm_enabled=bool(get_api_key())), indent=2))
    # post-write validation: every artifact must exist, be non-empty, and JSON must parse (zero-byte-file guard)
    bad = 0
    for root, _, files in os.walk(out):
        for name in sorted(files):
            path = os.path.join(root, name)
            size = os.path.getsize(path)
            ok = size > 0
            if ok and name.endswith(".json"):
                try:
                    with open(path, encoding="utf-8") as fh:
                        json.load(fh)
                except ValueError:
                    ok = False
            bad += 0 if ok else 1
            manifest.append({"path": os.path.relpath(path, out), "bytes": size, "sha256": sha256_of(path), "valid": ok})
    write_text(os.path.join(out, "manifest.json"), json.dumps(manifest, indent=2))
    print(f"LLM enabled: {bool(get_api_key())} | calls: {USAGE['calls']} | failures: {USAGE['failures']}")
    print(f"Artifacts written: {len(manifest)} files in {out} | invalid: {bad}")
    return 0 if bad == 0 else 1
 
 
if __name__ == "__main__":
    _code = run_factory()
    if not _in_notebook():
        sys.exit(_code)
```
