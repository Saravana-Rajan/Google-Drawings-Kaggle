# Data

Source: https://www.kaggle.com/competitions/physical-engineerings-last-exam/data (via `kaggle competitions files/download`)
Captured: 2026-11-15

## Kaggle Data tab

The Kaggle competition has **no dataset**. The only file is `NOTE.md` (55 bytes), saved at [`../04-dev-set/NOTE.md`](../04-dev-set/NOTE.md):

> Welcome! This is a Hackathon with no provided dataset.

## Where the real data is: the PLE dev tasks on Hugging Face

| Item | Value |
|---|---|
| Dataset | https://huggingface.co/datasets/google/physical-engineerings-last-exam |
| Access | **Gated**: accept the terms on the dataset page, then use a HF **read** token |
| Contents | **29 public dev tasks** (project folders: PDF drawings, XLSX, DXF/IFC CAD/BIM, specs; ~61 files per task on average) |
| Hidden | 56 test tasks (6 Structural, 9 Civil, 18 Electrical, 23 Mechanical); never released |
| Data terms | Competition use only; the HF form includes "I will NOT expose this data to any model/agent while it is being evaluated on PLE". Hosts confirmed running dev tasks via `eval/run.py` with local models is fine ([757453](discussion/757453-welcome-to-the-ple-competition.md)) |
| Task list | All 29 dev tasks with discipline, grading type, and time limits: [`../03-official-repos/google-research-ple/eval.md`](../03-official-repos/google-research-ple/eval.md) · baseline outputs per task: [`../03-official-repos/submission-template/dev-tasks-artifacts.md`](../03-official-repos/submission-template/dev-tasks-artifacts.md) |

### Download

```bash
uvx hf auth login                       # paste your HF read token once
scripts/download_dev_tasks.sh            # -> data/dev-tasks/
```
`eval/run.py` also downloads the dataset automatically when `HF_TOKEN` is set (see `../03-official-repos/google-research-ple/eval.md`).
