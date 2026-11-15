# PLE: Physical-Engineering's Last Exam

Source: https://arxiv.org/abs/2610.30537 (full text: https://arxiv.org/html/2610.30537, v2, 30 Oct 2026; v1 21 Oct 2026). License CC BY 4.0. Category cs.AI.
Links named in the paper: github.com/google-research/ple, ple-bench.com

## Authors
Rujun Han, Yufan Zhuang, Arijit Ray, Han Yu, Zhongying CuiZhu, George Lee, Yifei Ming, Binz Roy, Varun Sakalkar, Vishy Tirumalashetty, Burak Gokturk, Tomas Pfister, Chen-Yu Lee. All are at Google Cloud AI Research except Binz Roy and Varun Sakalkar, listed as Google. The data vendor is Mercor.

## Abstract (paraphrased)
Frontier LLMs score above 90% on knowledge benchmarks, but no benchmark tests whether they can do billable professional physical-engineering work. That work means modelling physics and code requirements across a multi-format project corpus, optimising cost, and issuing 2D/3D design packages that a licensed reviewer would sign off on. Existing engineering benchmarks are textbook QA, single-tool tasks or toy design problems, and many are already saturated. PLE has 85 long-horizon agentic tasks in electrical, civil, structural and mechanical engineering, built two ways: Expert-Authored (written end to end by practising engineers) and Co-Authored (engineer briefs turned into full tasks by an adversarial Creator-Solver agent pipeline, then validated and made harder by experts). The authors tested frontier LLMs under seven public agent harnesses. The best configuration averages only 50.6%, using about 27M tokens and 63 minutes per task. The authors will release 29 of the 85 tasks publicly, with their graders and the harness. The other 56 stay private for an open competition and leaderboard.

## Benchmark design
- Each task has four parts:
  - **Instruction**: a realistic brief from a colleague or client.
  - **Environment**: a realistic project file system.
  - **Deliverable specification**: the production files the agent must issue.
  - **Grader**: either a weighted expert rubric or an executable verifier with withheld reference deliverables.
- Tasks are packaged in the APEX format (APEX-Agents) and run in Archipelago-style containers (Mercor). The containers expose MCP apps (filesystem, documents, spreadsheets, PDFs, mail, calendar, chat) plus a code-execution sandbox.
- Environments contain PDFs, XLSX, DOCX, email, and CAD/BIM files (DXF/DWG/IFC). They include distractors such as superseded revisions and unrelated sheets.
- Example task (MEP coordination, hall A, 8 input files): route cable tray, busway, chilled water and sprinklers in 3D for a hall with 128 cabinets. The model must have zero clashes, serve every cabinet, meet code clearances and minimise route length.
- Example expert task: correct Section 2 of a Phase 3 cost estimate against the plan sheets and a hydraulic-grade-line report, then write a signed memo saved to a specified .docx path.
- **Co-authored ground rules**: tasks are grounded in real licensed artifacts; difficulty comes from the artifacts themselves (no vague prompts or traps); answers must be engineered, not looked up; every deliverable is verifiable against an audited reference.
- **Environment requirements (co-authored)**: at least 3 file formats, distractors, a realistic directory tree (criteria/, specs/, drawings/, vendor/), and information spread across documents so the solver must cross-reference.
- **Creator-Solver loop**:
  - The Creator is Claude Opus 5 running in Claude Code. The Solver is Claude Opus 5 running in Hermes Agent.
  - The Solver makes N=3 sandboxed attempts with no access to the grader or references.
  - A task passes when its mean score is below the difficulty target τ. Otherwise the Creator reads the Solver logs and makes the task harder (changes the objective, adds constraints, or does more deep research).
  - A Mercor expert then validates and intensifies every task.
- **Expert seed nomination form (Appendix C)** has six fields: Situation, Inputs, Goal, Constraints, Verification, Expected Output.
  - The worked example is LV cable sizing: 32 feeders at 480/208 V; NEC and UFC 3-501-01; Neher-McGrath derating; voltage drop of ≤3% per feeder and ≤5% total; 25 hard and 10 soft constraints per circuit.
  - Its deliverables are an XLSX schedule, a DXF riser plan and a JSON code-requirement register.

## Task categories and counts
| Metric | Expert | Co-authored | All |
|---|---|---|---|
| Tasks | 44 | 41 | 85 |
| Environments | 12 | 41 | 53 |
| Env files per task, mean | 62.8 | 58.7 | 60.8 |
| Env files, max | 112 | 207 | 207 |
| Grader | rubric | rubric + executable | hybrid |
| Checks per task, mean | 21.4 | 29.9 | 25.3 |

Checks per task are averaged over the 81 tasks graded by rubric items or constraints: 44 expert-authored and 37 co-authored.

| Discipline | Expert | Co-authored | Total |
|---|---|---|---|
| Mechanical | 19 | 11 | 30 |
| Electrical | 15 | 12 | 27 |
| Civil | 10 | 8 | 18 |
| Structural | 0 | 10 | 10 |

- **Environment files**: 5,170 in total (2,762 expert-authored, 2,408 co-authored).
  - Expert-authored environments: 51.6% PDF, 25.2% spreadsheets/data, 22.4% text and email. Mean footprint 3.0 MB per task.
  - Co-authored environments: 31.2% PDF, 27.5% spreadsheets/data, 16.3% text, 12.9% CAD/BIM, 7.1% schematics/images, 2.5% web portals, plus code. Mean footprint 38.1 MB per task (12.6x larger).
- **Deliverables**: 249 files in total.
  - Expert-authored: 49 files, 1.1 per task. 77.6% .docx reports, 12.2% workbooks, 10.2% CAD.
  - Co-authored: 200 files, 4.9 per task. 62.5% schedules/calcs (xlsx/csv/json), 21.0% reports/specs, 13.0% CAD/BIM (dxf/ifc/FCStd), 2.0% .py, 1.5% plotted PDF sheets.
- **Expert-authored task types**: plan-review responses, submittal reviews, capacity and energization decisions, geotechnical and foundation checks, tank shell-thickness review, close-out letters and cost positions.
- **Representative tasks in Fig. 1**: roof deck design (structural), site design as a 3D IFC model (civil), LV cable sizing with 32 circuits (electrical), cooling-tower 25-year life-cycle cost (mechanical).

## Grading methodology
- **Expert-authored tasks**:
  - Each task has a weighted rubric of binary, evidence-bound verifiers. Each verifier names a deliverable file, a criterion, a severity and a weight. Load-bearing numbers carry weight about 10; presentation items carry weight 1.
  - There are 941 items in total, 21.4 per task.
  - The score is the weight-normalised fraction of items passed.
  - Claude Opus 5.5 judges the items by reading the deliverable file itself.
- **Co-authored tasks**:
  - About 20 independent constraints per task (the target), each tagged hard (safety/feasibility) or soft (documentation/conventions).
  - The solver must also list the requirements it applied, with clause and value. These are checked against the reference.
  - Score: **s = 0.4·p + 0.6·G·O′**
    - p = fraction of constraints passed.
    - G ∈ {0,1} = hard-constraint gate.
    - O′ = normalised objective.
  - For cost tasks, O = c_bound / c, where c_bound is a certified lower bound on cost. Then O′ = clip((O − O_naive)/(1 − O_naive), 0, 1). A naive compliant design therefore earns 0 objective credit.
  - The task score is the mean of s over the items in its deliverable.
  - 12 of the graders also ask Claude Opus 5.5 to judge 3 to 6 narrative items, which count as soft constraints.
  - Exceptions: the 2 site-design and 2 MEP-coordination tasks keep their graders' own scores. MEP scores 0% on any hard clash or unserved row; an infeasible site design scores at most 50%.
- **Evaluation protocol**:
  - The agent sees no rubric, verifier or score feedback.
  - 3 runs per task, model and harness; results report the mean.
  - Each run has a 6-hour budget (21,600 s).
  - No internet. The agent can reach only a model proxy, which pins each model's highest reasoning setting.
  - Grading happens outside the agent's container.
  - Infrastructure failures are re-run. A run with no gradable deliverable scores 0%.

## Baseline results
The paper tested 14 models in 7 harnesses: Antigravity, Claude Code, Codex, Hermes, OpenCode, OpenHands and Pi. Grok 4.7 ran only in Grok Build and GPT 6 Astra only in Codex. That makes 86 model-harness pairs.

Harness versions: Antigravity 1.3.3, Claude Code 2.1.296, Codex 0.162.1, Hermes 0.22.2, OpenCode 2.0.26, OpenHands 1.54.0, Pi 1.1.0, Grok Build 1.0.52.

### Table 5 – mean score (%), all 85 tasks
| Model | Agy | CC | Cdx | Hrm | OC | OH | Pi |
|---|---|---|---|---|---|---|---|
| Claude Opus 5.5 | 48.4 | **50.6** | 49.3 | 48.6 | 47.4 | 49.9 | 47.3 |
| GPT 6 Astra | – | – | **48.3** | – | – | – | – |
| Claude Sonnet 5.5 | **45.2** | 43.6 | 42.7 | 43.7 | 42.3 | 42.2 | 43.5 |
| Gemini 4 Argon | 41.7 | **43.2** | 40.3 | 41.1 | 38.4 | 31.1 | 40.2 |
| Claude Opus 5 | **42.6** | 40.8 | 38.8 | 39.6 | 39.8 | 41.9 | 40.4 |
| Claude Fable 5 | 33.8 | **34.9** | 34.7 | 32.8 | 34.5 | 33.4 | 33.0 |
| Grok 4.7 (Grok Build) | 32.0 | | | | | | |
| Gemini 3.8 Flash | 26.4 | **28.2** | 27.6 | 17.8 | 26.0 | 27.6 | 26.9 |
| GLM 5.2 | 23.0 | 22.3 | **25.3** | 23.9 | 24.4 | 22.9 | 23.8 |
| Gemini 3.1 Pro | 13.7 | 14.1 | 14.1 | **14.2** | 13.3 | 14.0 | 13.6 |
| Qwen3 Coder 480B | 4.5 | 5.6 | 4.4 | **6.2** | 4.1 | 5.7 | 4.3 |
| Kimi K2 Thinking | 3.5 | 4.4 | 3.0 | 5.2 | **5.9** | 4.7 | 4.2 |
| MiniMax M2 | 3.7 | 5.3 | 4.4 | 5.3 | 3.9 | 4.5 | 4.7 |
| Llama 4 Maverick | 0.1 | 0.4 | 0.0 | 0.1 | 0.0 | 0.7 | 0.7 |

Notes on the table:
- Grok 4.7's 32.0% was scored in Grok Build only.
- The Fig. 2 labels name different harnesses for some points, e.g. "Gemini 4 Argon (Antigravity) 41.7%", "Qwen3 Coder (Hermes)", "MiniMax M2 (Hermes)", "Llama 4 Maverick (Claude Code) 0.4%".

### Table 3 – Claude Opus 5.5 by harness, curation approach and discipline (%)
| Harness | All (85) | Expert (44) | Co-auth (41) | Elec (27) | Civil (18) | Mech (30) | Struct (10) |
|---|---|---|---|---|---|---|---|
| Pi | 47.3 | 49.2 | 45.3 | 46.7 | 60.7 | 40.5 | 45.0 |
| OpenCode | 47.4 | 50.6 | 44.1 | 47.9 | 62.1 | 39.2 | 44.4 |
| Antigravity | 48.4 | 50.8 | 45.8 | 49.5 | 62.1 | 41.4 | 41.6 |
| Hermes | 48.6 | 49.2 | 48.0 | 51.9 | 65.1 | 38.4 | 40.8 |
| Codex | 49.3 | 50.6 | 48.0 | 53.1 | 67.8 | 36.6 | 43.8 |
| OpenHands | 49.9 | 50.7 | 49.1 | 50.6 | 67.0 | 40.2 | 46.6 |
| Claude Code | 50.6 | 53.1 | 48.0 | 50.7 | 69.9 | 40.5 | 46.6 |

### Costs (per task, list prices; only the figures stated in the text)
| Config | Score | Cost/task |
|---|---|---|
| Claude Opus 5.5 / Claude Code | 50.6% | $17.18 |
| Claude Opus 5.5 / OpenHands | 49.9% | $14.82 |
| Claude Opus 5.5 / Codex | 49.3% | $35.15 |
| Claude Opus 5.5 / OpenCode | 47.4% | $12.53 |
| Claude Opus 5.5 / Pi | 47.3% | $13.33 |
| GPT 6 Astra / Codex | 48.3% | $9.15 |
| Gemini 4 Argon / Claude Code | 43.2% | $8.21 |
| Gemini 3.8 Flash / Claude Code | 28.2% | $2.55 |

Other cost points from the text:
- Gemini 4 Argon covers the $6–9 band across four harnesses, scoring 40.2–43.2%.
- Open-weight models on the frontier cost under $0.20 per task and score under 7%.
- The 8 most expensive configurations are all Claude models in Antigravity, Claude Code or Codex. They cost $27–54 per task and score 33.8–49.3%.
- Medians across all pairs: cost $6.63, score 25.7%.
- Tokens and time for Claude Opus 5.5 in Claude Code: 27.0M tokens and 63 minutes per task overall; 39.3M and 97 minutes on co-authored tasks; 15.6M and 31 minutes on expert-authored tasks.

### Key findings
- **Far from saturated.** In Claude Code, Claude Opus 5.5 has a median task score of 43.5% and scores below 50% on 48 of 85 tasks. Even taking the best harness for each task leaves 35 tasks below 50%. Two tasks score 0% in every run; 7 score above 90%.
- **Hardest disciplines.** Mechanical (40.5%) and structural (46.6%) are the hardest; civil is the easiest (69.9%). Co-authored tasks are harder than expert-authored ones in every harness.
- **Model matters more than harness.** Scores span about 50 points across models. For a fixed model, the harness spread is 0.7–12.1 points (median 3.0).
- **Run-to-run variance.**
  - Set-level means are stable: SD 0.3–1.8 points per harness (Claude Code runs: 52.0 / 49.3 / 50.6).
  - Single tasks vary a lot: a task-harness cell has a mean range of 15.4 points over its 3 runs, and 105 of 595 cells span 30 points or more. Report averages over repeated runs.
- **Rubric judge.** The authors re-graded 1,159 LLM-judged runs.
  - A second Claude Opus 5.5 pass agrees on 98.7% of items (κ = 0.97).
  - Claude Opus 5 and Gemini 4 Argon agree with it on 95.8% and 95.5% of items (κ = 0.90) and raise scores by 3.3 and 1.3 points.
  - Claude Code ranks first under every judge.
  - Self-preference is about 2.3 points combined.

## Key failure modes
- 23.2% of all runs across the 86 pairs score 0%. Of those zero-score runs:
  - 25.3% end with no gradable deliverable.
  - 4.3% hit the time budget or an agent-side error (crashed harness, exhausted context window, output limit).
  - 70.4% deliver files that the grader scores 0%. This splits into 2,020 runs on eq.-1 tasks, 817 on rubric tasks and 726 at the all-or-nothing site-design and MEP gates.
- Claude Opus 5.5 in Claude Code scores 0% in only 11 of its 255 runs. Its losses come from hard constraints: on co-authored tasks its items satisfy 91% of constraints, yet only 41.3% satisfy every hard constraint and so earn objective credit.
- The paper names the core difficulty as producing a design that is fully safe and feasible while also pushing its cost toward the bound.

## Harness findings
- Best harness per model:
  - Claude Code: Claude Opus 5.5, Gemini 4 Argon, Claude Fable 5, Gemini 3.8 Flash.
  - Antigravity: Claude Sonnet 5.5, Claude Opus 5.
  - Hermes: Gemini 3.1 Pro, Qwen3 Coder.
  - Codex: GLM 5.2.
  - OpenCode: Kimi K2 Thinking.
  - Ties: MiniMax M2 (Claude Code and Hermes), Llama 4 Maverick (OpenHands and Pi).
- For Claude Opus 5.5, the harnesses span 47.3–50.6%. Its 0%-score runs out of 255 per harness: Pi 16, Codex 15, OpenCode 12, Claude Code 11, Hermes 8, Antigravity 7, OpenHands 6.
- Harness changes cost more than it changes score. Codex costs $35.15 per task for 49.3%, against $17.18 for Claude Code.
- Pi has no MCP support, so it reaches the apps through the shell.
- The paper recommends always reporting both model and harness.

## Other details
- Experts were paid on average $4,663 per expert-authored task and $3,157 per co-authored task (for validation and intensification).
- No task contains proprietary information. Co-authored files are public-domain, permissively licensed, or generated for the task.

## BibTeX (from arxiv.org/bibtex/2610.30537)
```bibtex
@misc{han2026plephysicalengineeringsexam,
      title={PLE: Physical-Engineering's Last Exam},
      author={Rujun Han and Yufan Zhuang and Arijit Ray and Han Yu and Zhongying CuiZhu and George Lee and Yifei Ming and Binz Roy and Varun Sakalkar and Vishy Tirumalashetty and Burak Gokturk and Tomas Pfister and Chen-Yu Lee},
      year={2026},
      eprint={2610.30537},
      archivePrefix={arXiv},
      primaryClass={cs.AI},
      url={https://arxiv.org/abs/2610.30537},
}
```
