# AIODAM + DeepSeek V4.1 Flash: exploratory work on all 29 PLE dev tasks

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/discussion/758084
Author: Oxunjon Ubaydullayev (Oxunjon) · posted Nov 11, 2026 · 0 comments (captured 2026-11-15)
Full report and code: https://github.com/oxunjonuz/aiodam-ple-29-task-study (48-page report; attachment `aiodam-ple-29-research-package.zip`)

> ⚠️ The author's own caveats: these are **not official scores**. The agent could **see verifier code** and sometimes reference data, some checks ran on the host rather than in the official verifier container, results are self-reported and not audited, and **no real LLM-judge score** exists for the 14 rubric tasks or for the judge parts of the 3 mixed tasks.

## Reported programmatic results (0–1)

| Task | Score |
|---|---|
| cooling-water-flush-plan | 0.949 |
| data-center-site-model | 1.000 |
| data-hall-device-takeoff | 0.970 |
| data-hall-mep-routing | 1.000 |
| data-hall-mep-routing-offset | 1.000 |
| division-26-specifications | 1.000 |
| frame-extension-method | 0.807 |
| heat-rejection-life-cycle-cost | 1.000 |
| mv-conveyance-study | 0.702 |
| roof-deck-design | 0.839 |
| seismic-diaphragm-shear | 0.905 |
| wind-diaphragm-shear | 0.763 |

**Mixed (checks + judge), partial only:** eor-review-corrections 0.880 without judge (0.920 with a mechanical stub); foundation-strategy 0.883 without judge; lv-cable-sizing 0.893 without judge.

**14 rubric tasks, deliverable prepared but not judged:** backfeed-energization-reply, emergency-spillway-check, engineers-estimate-check, fill-compaction-acceptance, fire-solve-convergence, fire-test-validation-memo, footing-settlement-verification, landscape-sheet-revision, les-mesh-resolution, permission-to-operate-memo, pre-application-capacity-response, shoring-design-verification, solar-supplemental-review, solar-witness-test-package.

## Findings worth noting

- **Wind diaphragm:** the first single-deck design failed the **cost gate**. A **zoned deck schedule** cut installed cost from $340,662 to $283,660 and raised reward from 0.233 to 0.763. The earlier claim that the constraints were incompatible was wrong; it only held for the one-deck configuration. *Lesson: the objective O′ only pays once every gate passes, so search over design configurations.*
- **Data-center site (IFC4):** a manually generated IFC4 model was feasible on all 17 constraints, with objective 351.8 against a ceiling of 473. A **GUID error escaped the task grader but was caught by IFC validation**. *Lesson: run IFC schema validation yourself.*
- **Heat-rejection LCC:** the 1.0 is weak evidence because the deliverable reproduces the verifier's reference construction. The agent's water-margin estimate (0.77%) differed from the grader's (~0.0132%) because they used different models.
- **MEP routing:** two solution scripts scored 1.0 by reconstructing and routing the models and checking clearances; these were not blind evaluations.

## Code excerpt shared (DXF → Shapely)

```python
from functools import lru_cache
import ezdxf
from shapely.geometry import LineString, Polygon

@lru_cache(maxsize=1)
def dxf_layers():
    doc = ezdxf.readfile(str(WS / "20_drawings/C-101_Site_Utility_Plan_Rev4.dxf"))
    out = {}
    for e in doc.modelspace():
        if e.dxftype() == "LWPOLYLINE":
            pts = [(float(p[0]), float(p[1])) for p in e.get_points("xy")]
            if e.closed:
                out.setdefault(e.dxf.layer, []).append(Polygon(pts))
        elif e.dxftype() == "LINE":
            a = (e.dxf.start.x, e.dxf.start.y)
            b = (e.dxf.end.x, e.dxf.end.y)
            out.setdefault(e.dxf.layer, []).append(LineString([a, b]))
    return out
```
*(Useful tools: `ezdxf` for DXF and `shapely` for geometry.)*
