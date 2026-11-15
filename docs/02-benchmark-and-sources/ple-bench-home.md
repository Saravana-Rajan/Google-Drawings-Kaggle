# Physical-Engineering’s Last Exam

Source: https://ple-bench.com/

# Physical-Engineering’s Last Exam

Testing AI agents on real-world engineering.

85 expert-reviewed tasks across calculations, drawings, and design reviews.

[See the leaderboard](https://ple-bench.com/leaderboard)
[arXiv](https://arxiv.org/abs/2610.30537)
[GitHub](https://github.com/google-research/ple)
[![](https://ple-bench.com/static/icons/hf-logo.svg?v=942cad1ccda9)Dataset](https://huggingface.co/datasets/google/physical-engineerings-last-exam)

## Engineering disciplines in practice

1. Design a structural frame to carry gravity and lateral loads. [Structural engineering, 10 tasks](https://ple-bench.com/tasks#structural)
2. Design a site layout for buildings, grading, and utility routes. [Civil engineering, 18 tasks](https://ple-bench.com/tasks#civil)
3. Design a switchboard and feeder layout for the connected loads. [Electrical engineering, 27 tasks](https://ple-bench.com/tasks#electrical)
4. Design a cooling loop to reject the facility's heat load. [Mechanical engineering, 30 tasks](https://ple-bench.com/tasks#mechanical)

[Skip the drawings](#research)

Design a structural frame to carry gravity and lateral loads.

[Structural engineering, 10 tasks](https://ple-bench.com/tasks#structural)

## A research initiative by scientists at Google

![](https://ple-bench.com/static/scenes/structural-dark.webp?v=dd9facf6294b)

## Enter the competition on Kaggle

Prize:
:   1st **250K USD**, 2nd **100K USD**, 3rd **50K USD**

Duration:
:   November 9, 2026 – January 5, 2027

[Join on Kaggle](https://www.kaggle.com/competitions/physical-engineerings-last-exam)

## Leaderboard

[Full leaderboard](https://ple-bench.com/leaderboard)

Frontier models evaluated on the private set, ranked with their native harness.

Each model runs at its highest reasoning effort.

**Score by model on its native harness**± std

*0.0**0.1**0.2**0.3**0.4**0.5**0.6*

1. **Opus 5.5**
   native harness: claude-code

   0.483
2. **GPT 6 Astra**
   native harness: codex

   0.458
3. **Sonnet 5.5**
   native harness: claude-code

   0.435
4. **Gemini 4 Argon**
   native harness: agy

   0.406
5. **Opus 5**
   native harness: claude-code

   0.400
6. **Fable 5**
   native harness: claude-code

   0.345
7. **Grok 4.7**
   native harness: grok-build

   0.301
8. **Gemini 3.8 Flash**
   native harness: agy

   0.275
9. **GLM 5.2**
   pi

   0.250
10. **DeepSeek-V4.1-Flash**
    native harness: dsh

    0.144
11. **Gemini 3.1 Pro**
    native harness: agy

    0.138
12. **Qwen3 Coder 480B**
    claude-code

    0.062
13. **Kimi K2 Thinking**
    opencode

    0.062
14. **MiniMax M2**
    claude-code

    0.057
15. **Qwen3-Next 80B**
    openhands

    0.043
16. **Gemma 4 26B**
    native harness: agy

    0.042
17. **gpt-oss 120B**
    native harness: codex

    0.038
18. **Llama 4 Maverick**
    pi

    0.007

The models, each on its native harness or else its best, on the 56 hidden test tasks

| # | Model | Harness | Score ± std |
| --- | --- | --- | --- |
| 1 | Claude Opus 5.5Opus 5.5 | native harness: claude-code | **0.483**±0.014 |
| 2 | GPT 6 AstraGPT 6 Astra | native harness: codex | **0.458**±0.006 |
| 3 | Claude Sonnet 5.5Sonnet 5.5 | native harness: claude-code | **0.435**±0.014 |
| 4 | Gemini 4 ArgonGemini 4 Argon | native harness: agy | **0.406**±0.013 |
| 5 | Claude Opus 5Opus 5 | native harness: claude-code | **0.400**±0.016 |
| 6 | Claude Fable 5Fable 5 | native harness: claude-code | **0.345**±0.020 |
| 7 | Grok 4.7Grok 4.7 | native harness: grok-build | **0.301**±0.007 |
| 8 | Gemini 3.8 FlashGemini 3.8 Flash | native harness: agy | **0.275**±0.007 |
| 9 | GLM 5.2GLM 5.2 | pi | **0.250**±0.004 |
| 10 | DeepSeek-V4.1-FlashDeepSeek-V4.1-Flash | native harness: dsh | **0.144**±0.023 |
| 11 | Gemini 3.1 ProGemini 3.1 Pro | native harness: agy | **0.138**±0.014 |
| 12 | Qwen3 Coder 480BQwen3 Coder 480B | claude-code | **0.062**±0.001 |
| 13 | Kimi K2 ThinkingKimi K2 Thinking | opencode | **0.062**±0.002 |
| 14 | MiniMax M2MiniMax M2 | claude-code | **0.057**±0.006 |
| 15 | Qwen3-Next 80BQwen3-Next 80B | openhands | **0.043**±0.001 |
| 16 | Gemma 4 26BGemma 4 26B | native harness: agy | **0.042**±0.004 |
| 17 | gpt-oss 120Bgpt-oss 120B | native harness: codex | **0.038**±0.005 |
| 18 | Llama 4 MaverickLlama 4 Maverick | pi | **0.007**±0.003 |

Native harness; otherwise the
model's best.

## How grading works

Each task runs in an isolated container with the project's drawings, spreadsheets, specs, and local services.

Automated scripts check quantitative outputs, while an LLM judge grades open-ended engineering work against
an expert rubric.

* No internet access
* 6 hours per task
* Three runs per harness and model

## Engineering disciplines

[All 85 tasks](https://ple-bench.com/tasks)

* [![](https://ple-bench.com/static/scenes/thumbs/structural-400.webp?v=ef7176b7b22a)
  Structural engineering
  10 tasks, 4 in the dev set](https://ple-bench.com/tasks#structural)
* [![](https://ple-bench.com/static/scenes/thumbs/civil-400.webp?v=3369b4910d2e)
  Civil engineering
  18 tasks, 9 in the dev set](https://ple-bench.com/tasks#civil)
* [![](https://ple-bench.com/static/scenes/thumbs/electrical-400.webp?v=54c833a593be)
  Electrical engineering
  27 tasks, 9 in the dev set](https://ple-bench.com/tasks#electrical)
* [![](https://ple-bench.com/static/scenes/thumbs/mechanical-400.webp?v=69784ac55b86)
  Mechanical engineering
  30 tasks, 7 in the dev set](https://ple-bench.com/tasks#mechanical)

## Academic Partners

* [![](https://ple-bench.com/static/people/jiajun-wu.webp?v=0f66a846685f)
  Jiajun WuStanford University](https://jiajunwu.com/)
* [![](https://ple-bench.com/static/people/saining-xie.webp?v=b7bfe0c01ab2)
  Saining XieNYU Courant](https://www.sainingxie.com/)
* [![](https://ple-bench.com/static/people/ranjay-krishna.webp?v=711ebdf5e262)
  Ranjay KrishnaUniversity of Washington](https://ranjaykrishna.com/)
* [![](https://ple-bench.com/static/people/mohit-bansal.webp?v=38e5be270ab7)
  Mohit BansalUNC Chapel Hill](https://www.cs.unc.edu/~mbansal/)
* [![](https://ple-bench.com/static/people/yilun-du.webp?v=b01e9591d33b)
  Yilun DuHarvard University](https://yilundu.github.io/)
* [![](https://ple-bench.com/static/people/yunzhu-li.webp?v=920f2180f9fa)
  Yunzhu LiColumbia University](https://yunzhuli.github.io/)

## Contribute a task

Share a realistic engineering problem with its starting files and grader. Accepted tasks join the benchmark with author credit.

[See what makes a good task](https://ple-bench.com/contribute)

## Competition

Build an agent harness, pair it with the model of your choice, and compete on the hidden test set.

[Go to the competition](https://ple-bench.com/competition)

## Citation

```
@misc{han2026ple,
  title         = {{PLE}: Physical-Engineering's Last Exam},
  author        = {Rujun Han and Yufan Zhuang and Arijit Ray and Han Yu and
                   Zhongying CuiZhu and George Lee and Yifei Ming and Binz Roy and
                   Varun Sakalkar and Vishy Tirumalashetty and Burak Gokturk and
                   Tomas Pfister and Chen-Yu Lee},
  year          = {2026},
  eprint        = {2610.30537},
  archivePrefix = {arXiv},
  primaryClass  = {cs.AI},
  url           = {https://arxiv.org/abs/2610.30537}
}
```
