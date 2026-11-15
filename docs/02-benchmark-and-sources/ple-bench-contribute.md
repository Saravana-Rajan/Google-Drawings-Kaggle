# Contribute a task | Physical-Engineering’s Last Exam

Source: https://ple-bench.com/contribute

# Contribute a task

Share a realistic engineering problem with its starting project files and grader.
Accepted tasks join the benchmark with author credit.

[Sign in with GitHub to contribute](https://ple-bench.com/login?next=/contribute/register)

## What makes a good task

Example task

### Pump selection for a chilled-water loop

Starting filesThe load schedule, piping layout, and manufacturer pump curves.

a

The workSelect the pumps, determine the operating duty point on the system curve, and verify the
NPSH margin.

b

DeliverablesA completed pump schedule workbook and a concise selection memo for the project engineer.

GradingA verification script checks the duty point and NPSH calculations; a structured rubric evaluates the
engineering memo.

c

aComplete inputs
:   Include all drawings, data tables, and constraints an engineer needs to solve the problem without guessing.

bEngineering judgment
:   Aim for work that takes an experienced engineer several hours and requires multi-step analysis rather than a single plug-in formula.

cClear grading
:   Use deterministic checks, specific rubric criteria, or both, so two independent reviewers would award the same score.

## Task files

Place each task in its own directory inside a GitHub repository (if the repository is private, install the competition's GitHub App first).
When you submit, we validate these files at the latest commit on your chosen branch:

task.toml
:   time limit and CPU/memory resources allocated to the task

instruction.md
:   the problem statement and deliverable requirements shown to the agent

environment/
:   a Dockerfile and the starting project files placed in the container

tests/test.sh
:   the grading entry point that evaluates the deliverables and writes the final score

tests/rubric.json
:   weighted evaluation criteria, when the task uses an LLM rubric judge

* Leave out confidential informationUse public codes and fictionalized project names, and strip client
  or employer identifiers from every file and metadata field.
* Keep the reference answer outside the folderDo not include reference solutions anywhere in the task folder (`environment/` or `tests/`); reviewers request them separately when testing your grader.

## Review

1. **Submitted and structure checked.** We automatically verify that all required files are present and well-formed.
2. **In review.** An engineering reviewer builds the container, tests the grader, and checks the prompt
   and starting files for clarity and completeness.
3. **Decision.** We accept the task into the benchmark, request revisions, or explain why it was declined. To address feedback,
   push a new commit and resubmit.

## Contribution terms

Contributors confirm that they have the right to share the tasks they submit and that no task contains confidential client or employer information. Accepted tasks may be published with the benchmark along with their starting files and graders.
