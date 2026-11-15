# PLE: Dev Effects Over 0.03 Held on Test, 19 of 22

- **Author:** dariushafshar
- **Kaggle URL:** https://www.kaggle.com/code/dariushafshar/ple-dev-effects-over-0-03-held-on-test-19-of-22

## Approach / key ideas

- Parses the organisers' ple-bench.com leaderboard (18 models x 7 off-the-shelf harnesses x 3 runs; hidden/dev/all views) instead of running its own benchmark.
- Key result: dev-set effects larger than 0.03 kept the same sign on hidden test in 19 of 22 cases, so dev is a fairly trustworthy proxy for large effects.
- Stage-2 prizes: the top 3 by score among Pareto-frontier (score vs cost) systems with mean test score >= 0.138.
- Dev pass cost estimates: $2.1-3.6 per task on Gemini 3.8 Flash ($60-103 for 29 tasks) and $5.3-7.6 per task on Gemini 4 Argon ($153-221).
- Configurable TARGET_SCORE, PRICE_SET and ONLY_SPONSORED, which output the cheapest model/harness pairs that reach the target.
- Caveat: costs exclude the Opus 5.5 judge calls.

## Notebook

# PLE: do dev-set effects carry to the hidden test set?

Physical-Engineering's Last Exam (Google, Kaggle hackathon) scores an agent harness on 29 public dev tasks and, for the
top 100 entries, on 56 hidden test tasks. Before spending money on dev runs it helps to know how far a dev score can be
trusted, which sponsored models can reach the prize frontier at all, and what a dev pass costs.

The organisers publish one leaderboard (ple-bench.com/leaderboard) with three views (hidden test, public dev, all 85
tasks): 18 models on 7 off-the-shelf harnesses, three runs each, with score, cost per task and minutes per task. This
notebook parses those pages (pulled 2026-11-11), embeds the numbers, and answers four questions from them. **Nothing
here is our own benchmark run, and nothing is simulated.** The numbers are the organisers' means on their harnesses, not
what a custom competition harness will score.

What you can change: `TARGET_SCORE`, `PRICE_SET` and `ONLY_SPONSORED` in the next cell, then Run All. The last section
lists the cheapest model and harness pairs that reach your target and what a full dev pass would cost.


```python
import io, math
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ===== knobs =====
TARGET_SCORE = 0.25      # the mean score you want to reach (0 to 1)
PRICE_SET = "dev"        # price the options with dev-set ("dev") or hidden-test ("test") cost per task
ONLY_SPONSORED = True    # competition entries must call one of the 8 Google-sponsored models
FLOOR = 0.138            # Stage 2 prize floor: mean test score of at least 0.138
DEV_TASKS = 29

SPONSORED = {"Gemini 4 Argon", "Gemini 3.8 Flash", "Gemini 3.1 Pro", "Gemma 4 26B",
             "Claude Opus 5.5", "gpt-oss 120B", "GLM 5.2", "Llama 4 Maverick"}
plt.rcParams.update({"figure.dpi": 110, "axes.spines.top": False, "axes.spines.right": False})

```

```python
DATA = r'''set,domain,tasks,model,harness,score,std,cost_usd,cost_approx,cost_nocache,minutes,native
test,overall,56,Claude Opus 5.5,pi,0.472,0.014,13.35,0,0,68,0
test,overall,56,Claude Opus 5.5,opencode,0.465,0.02,12.87,0,0,49,0
test,overall,56,Claude Opus 5.5,claude-code,0.483,0.014,17.12,0,0,63,1
test,overall,56,Claude Opus 5.5,agy,0.477,0.008,42.32,1,0,45,0
test,overall,56,Claude Opus 5.5,openhands,0.486,0.023,14.87,0,0,66,0
test,overall,56,Claude Opus 5.5,codex,0.464,0.019,37.62,0,0,130,0
test,overall,56,Claude Opus 5.5,hermes,0.466,0.005,16.03,0,0,66,0
test,overall,56,GPT 6 Astra,codex,0.458,0.006,9.53,0,0,26,1
test,overall,56,Claude Sonnet 5.5,pi,0.442,0.022,11.77,0,0,96,0
test,overall,56,Claude Sonnet 5.5,opencode,0.425,0.007,10.53,0,0,63,0
test,overall,56,Claude Sonnet 5.5,claude-code,0.435,0.014,18.68,0,0,99,1
test,overall,56,Claude Sonnet 5.5,agy,0.449,0.004,33.89,1,0,53,0
test,overall,56,Claude Sonnet 5.5,openhands,0.407,0.014,15.72,0,0,112,0
test,overall,56,Claude Sonnet 5.5,codex,0.431,0.029,42.56,0,0,243,0
test,overall,56,Claude Sonnet 5.5,hermes,0.451,0.038,14.71,0,0,87,0
test,overall,56,Claude Opus 5,pi,0.418,0.01,15.26,0,0,58,0
test,overall,56,Claude Opus 5,opencode,0.404,0.017,12.51,0,0,38,0
test,overall,56,Claude Opus 5,claude-code,0.4,0.016,16.52,0,0,48,1
test,overall,56,Claude Opus 5,agy,0.415,0.021,29.59,1,0,42,0
test,overall,56,Claude Opus 5,openhands,0.426,0.009,17.13,0,0,66,0
test,overall,56,Claude Opus 5,codex,0.389,0.006,20.77,0,0,69,0
test,overall,56,Claude Opus 5,hermes,0.404,0.017,13.89,0,0,52,0
test,overall,56,Gemini 4 Argon,pi,0.366,0.015,7.0,0,0,78,0
test,overall,56,Gemini 4 Argon,opencode,0.373,0.006,7.04,0,0,55,0
test,overall,56,Gemini 4 Argon,claude-code,0.411,0.014,8.51,0,0,67,0
test,overall,56,Gemini 4 Argon,agy,0.406,0.013,7.7,0,0,73,1
test,overall,56,Gemini 4 Argon,openhands,0.29,0.033,7.54,0,0,83,0
test,overall,56,Gemini 4 Argon,codex,0.389,0.017,7.13,0,0,83,0
test,overall,56,Gemini 4 Argon,hermes,0.389,0.012,7.92,0,0,61,0
test,overall,56,Claude Fable 5,pi,0.342,0.016,21.17,0,0,47,0
test,overall,56,Claude Fable 5,opencode,0.341,0.015,22.95,0,0,38,0
test,overall,56,Claude Fable 5,claude-code,0.345,0.02,26.46,0,0,45,1
test,overall,56,Claude Fable 5,agy,0.325,0.01,54.19,1,0,37,0
test,overall,56,Claude Fable 5,openhands,0.332,0.004,25.83,0,0,44,0
test,overall,56,Claude Fable 5,codex,0.345,0.015,28.77,0,0,60,0
test,overall,56,Claude Fable 5,hermes,0.333,0.009,24.3,0,0,55,0
test,overall,56,Grok 4.7,pi,0.302,0.005,8.01,0,0,40,0
test,overall,56,Grok 4.7,opencode,0.284,0.017,10.25,0,0,34,0
test,overall,56,Grok 4.7,claude-code,0.266,0.012,12.75,0,0,48,0
test,overall,56,Grok 4.7,agy,0.278,0.007,16.81,1,1,33,0
test,overall,56,Grok 4.7,openhands,0.275,0.019,8.89,0,0,34,0
test,overall,56,Grok 4.7,codex,0.259,0.02,7.02,0,0,39,0
test,overall,56,Grok 4.7,hermes,0.256,0.021,10.09,0,0,47,0
test,overall,56,Grok 4.7,grok-build,0.301,0.007,10.18,0,0,52,1
test,overall,56,Gemini 3.8 Flash,pi,0.268,0.022,2.68,0,0,42,0
test,overall,56,Gemini 3.8 Flash,opencode,0.259,0.005,2.45,0,0,25,0
test,overall,56,Gemini 3.8 Flash,claude-code,0.272,0.003,2.61,0,0,34,0
test,overall,56,Gemini 3.8 Flash,agy,0.275,0.007,2.6,0,0,40,1
test,overall,56,Gemini 3.8 Flash,openhands,0.282,0.01,3.21,0,0,33,0
test,overall,56,Gemini 3.8 Flash,codex,0.278,0.001,3.61,0,0,45,0
test,overall,56,Gemini 3.8 Flash,hermes,0.174,0.02,2.39,0,0,24,0
test,overall,56,GLM 5.2,pi,0.25,0.004,13.66,0,0,109,0
test,overall,56,GLM 5.2,opencode,0.24,0.011,,0,0,94,0
test,overall,56,GLM 5.2,claude-code,0.218,0.005,14.78,0,0,94,0
test,overall,56,GLM 5.2,agy,0.238,0.008,12.71,1,0,86,0
test,overall,56,GLM 5.2,openhands,0.234,0.005,15.5,0,0,104,0
test,overall,56,GLM 5.2,codex,0.25,0.015,12.57,0,0,121,0
test,overall,56,GLM 5.2,hermes,0.24,0.012,10.83,0,0,70,0
test,overall,56,DeepSeek-V4.1-Flash,pi,0.225,0.034,4.54,0,0,169,0
test,overall,56,DeepSeek-V4.1-Flash,opencode,0.225,0.023,3.46,0,0,172,0
test,overall,56,DeepSeek-V4.1-Flash,claude-code,0.117,0.012,3.74,0,0,241,0
test,overall,56,DeepSeek-V4.1-Flash,agy,0.092,0.013,3.5,1,0,229,0
test,overall,56,DeepSeek-V4.1-Flash,openhands,0.063,0.015,1.65,0,0,194,0
test,overall,56,DeepSeek-V4.1-Flash,codex,0.041,0.016,2.08,0,0,295,0
test,overall,56,DeepSeek-V4.1-Flash,hermes,0.053,0.026,2.98,0,0,255,0
test,overall,56,DeepSeek-V4.1-Flash,dsh,0.144,0.023,6.3,0,0,240,1
test,overall,56,Gemini 3.1 Pro,pi,0.141,0.008,2.76,0,0,24,0
test,overall,56,Gemini 3.1 Pro,opencode,0.141,0.005,2.67,0,0,15,0
test,overall,56,Gemini 3.1 Pro,claude-code,0.144,0.006,3.65,0,0,17,0
test,overall,56,Gemini 3.1 Pro,agy,0.138,0.014,2.47,0,0,15,1
test,overall,56,Gemini 3.1 Pro,openhands,0.147,0.016,4.67,0,0,16,0
test,overall,56,Gemini 3.1 Pro,codex,0.145,0.002,2.8,0,0,16,0
test,overall,56,Gemini 3.1 Pro,hermes,0.148,0.016,2.09,0,0,12,0
test,overall,56,Qwen3 Coder 480B,pi,0.042,0.005,0.15,0,0,10,0
test,overall,56,Qwen3 Coder 480B,opencode,0.045,0.002,0.25,0,0,8,0
test,overall,56,Qwen3 Coder 480B,claude-code,0.062,0.001,0.13,0,0,10,0
test,overall,56,Qwen3 Coder 480B,agy,0.044,0.006,0.49,1,0,6,0
test,overall,56,Qwen3 Coder 480B,openhands,0.06,0.007,0.21,0,0,28,0
test,overall,56,Qwen3 Coder 480B,codex,0.047,0.006,0.11,0,0,6,0
test,overall,56,Qwen3 Coder 480B,hermes,0.062,0.004,0.12,0,0,8,0
test,overall,56,Kimi K2 Thinking,pi,0.04,0.002,0.2,0,0,8,0
test,overall,56,Kimi K2 Thinking,opencode,0.062,0.002,0.28,0,0,8,0
test,overall,56,Kimi K2 Thinking,claude-code,0.046,0.014,0.25,0,0,7,0
test,overall,56,Kimi K2 Thinking,agy,0.032,0.007,0.29,1,0,18,0
test,overall,56,Kimi K2 Thinking,openhands,0.044,0.007,0.25,0,0,12,0
test,overall,56,Kimi K2 Thinking,codex,0.032,0.008,0.26,0,0,9,0
test,overall,56,Kimi K2 Thinking,hermes,0.05,0.006,0.28,0,0,8,0
test,overall,56,MiniMax M2,pi,0.046,0.002,0.094,0,0,12,0
test,overall,56,MiniMax M2,opencode,0.042,0.004,0.079,0,0,14,0
test,overall,56,MiniMax M2,claude-code,0.057,0.006,0.1,0,0,12,0
test,overall,56,MiniMax M2,agy,0.035,0.002,0.33,1,0,13,0
test,overall,56,MiniMax M2,openhands,0.053,0.003,0.13,0,0,14,0
test,overall,56,MiniMax M2,codex,0.046,0.002,0.093,0,0,14,0
test,overall,56,MiniMax M2,hermes,0.057,0.005,0.097,0,0,10,0
test,overall,56,gpt-oss 120B,pi,0.04,0.006,0.12,0,0,26,0
test,overall,56,gpt-oss 120B,opencode,0.037,0.007,0.16,0,0,47,0
test,overall,56,gpt-oss 120B,claude-code,0.042,0.002,0.11,0,0,46,0
test,overall,56,gpt-oss 120B,agy,0.042,0.003,,0,0,36,0
test,overall,56,gpt-oss 120B,openhands,0.046,0.009,0.14,0,0,52,0
test,overall,56,gpt-oss 120B,codex,0.038,0.005,0.18,0,0,45,1
test,overall,56,gpt-oss 120B,hermes,0.037,0.001,0.16,0,0,48,0
test,overall,56,Gemma 4 26B,pi,0.038,0.002,0.29,0,0,84,0
test,overall,56,Gemma 4 26B,opencode,0.027,0.003,0.45,0,0,46,0
test,overall,56,Gemma 4 26B,claude-code,0.038,0.002,0.53,0,0,88,0
test,overall,56,Gemma 4 26B,agy,0.042,0.004,0.21,1,0,95,1
test,overall,56,Gemma 4 26B,openhands,0.045,0.005,0.61,0,0,109,0
test,overall,56,Gemma 4 26B,codex,0.007,0.002,0.2,0,0,24,0
test,overall,56,Gemma 4 26B,hermes,0.018,0.002,0.29,0,0,24,0
test,overall,56,Qwen3-Next 80B,pi,0.027,0.002,1.05,0,1,59,0
test,overall,56,Qwen3-Next 80B,opencode,0.026,0.004,0.54,0,1,70,0
test,overall,56,Qwen3-Next 80B,claude-code,0.026,0.006,0.54,0,1,44,0
test,overall,56,Qwen3-Next 80B,agy,0.014,0.006,0.4,1,1,41,0
test,overall,56,Qwen3-Next 80B,openhands,0.043,0.001,0.77,0,1,92,0
test,overall,56,Qwen3-Next 80B,codex,0.01,0.005,0.56,0,1,36,0
test,overall,56,Qwen3-Next 80B,hermes,0.019,0.006,0.41,0,1,47,0
test,overall,56,Llama 4 Maverick,pi,0.007,0.003,0.34,0,1,1,0
test,overall,56,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
test,overall,56,Llama 4 Maverick,claude-code,0.004,0.001,0.063,0,1,1,0
test,overall,56,Llama 4 Maverick,agy,0.001,0.001,0.06,1,1,3,0
test,overall,56,Llama 4 Maverick,openhands,0.007,0.002,0.18,0,1,2,0
test,overall,56,Llama 4 Maverick,codex,0.0,0.001,0.097,0,1,2,0
test,overall,56,Llama 4 Maverick,hermes,0.0,0.0,0.046,0,1,1,0
test,structural,6,Claude Opus 5.5,pi,0.546,0.045,13.35,0,0,68,0
test,structural,6,Claude Opus 5.5,opencode,0.539,0.066,12.87,0,0,49,0
test,structural,6,Claude Opus 5.5,claude-code,0.563,0.059,17.12,0,0,63,1
test,structural,6,Claude Opus 5.5,agy,0.496,0.072,42.32,1,0,45,0
test,structural,6,Claude Opus 5.5,openhands,0.576,0.014,14.87,0,0,66,0
test,structural,6,Claude Opus 5.5,codex,0.516,0.079,37.62,0,0,130,0
test,structural,6,Claude Opus 5.5,hermes,0.472,0.029,16.03,0,0,66,0
test,structural,6,Claude Opus 5,pi,0.513,0.007,15.26,0,0,58,0
test,structural,6,Claude Opus 5,opencode,0.487,0.069,12.51,0,0,38,0
test,structural,6,Claude Opus 5,claude-code,0.473,0.053,16.52,0,0,48,1
test,structural,6,Claude Opus 5,agy,0.521,0.091,29.59,1,0,42,0
test,structural,6,Claude Opus 5,openhands,0.52,0.052,17.13,0,0,66,0
test,structural,6,Claude Opus 5,codex,0.523,0.023,20.77,0,0,69,0
test,structural,6,Claude Opus 5,hermes,0.497,0.099,13.89,0,0,52,0
test,structural,6,Claude Sonnet 5.5,pi,0.489,0.056,11.77,0,0,96,0
test,structural,6,Claude Sonnet 5.5,opencode,0.522,0.01,10.53,0,0,63,0
test,structural,6,Claude Sonnet 5.5,claude-code,0.474,0.07,18.68,0,0,99,1
test,structural,6,Claude Sonnet 5.5,agy,0.501,0.027,33.89,1,0,53,0
test,structural,6,Claude Sonnet 5.5,openhands,0.517,0.013,15.72,0,0,112,0
test,structural,6,Claude Sonnet 5.5,codex,0.467,0.018,42.56,0,0,243,0
test,structural,6,Claude Sonnet 5.5,hermes,0.518,0.083,14.71,0,0,87,0
test,structural,6,Claude Fable 5,pi,0.469,0.08,21.17,0,0,47,0
test,structural,6,Claude Fable 5,opencode,0.396,0.047,22.95,0,0,38,0
test,structural,6,Claude Fable 5,claude-code,0.406,0.114,26.46,0,0,45,1
test,structural,6,Claude Fable 5,agy,0.376,0.049,54.19,1,0,37,0
test,structural,6,Claude Fable 5,openhands,0.487,0.013,25.83,0,0,44,0
test,structural,6,Claude Fable 5,codex,0.48,0.087,28.77,0,0,60,0
test,structural,6,Claude Fable 5,hermes,0.446,0.042,24.3,0,0,55,0
test,structural,6,GPT 6 Astra,codex,0.484,0.013,9.53,0,0,26,1
test,structural,6,Gemini 4 Argon,pi,0.42,0.054,7.0,0,0,78,0
test,structural,6,Gemini 4 Argon,opencode,0.438,0.07,7.04,0,0,55,0
test,structural,6,Gemini 4 Argon,claude-code,0.449,0.074,8.51,0,0,67,0
test,structural,6,Gemini 4 Argon,agy,0.458,0.038,7.7,0,0,73,1
test,structural,6,Gemini 4 Argon,openhands,0.322,0.008,7.54,0,0,83,0
test,structural,6,Gemini 4 Argon,codex,0.399,0.143,7.13,0,0,83,0
test,structural,6,Gemini 4 Argon,hermes,0.382,0.04,7.92,0,0,61,0
test,structural,6,Gemini 3.8 Flash,pi,0.256,0.02,2.68,0,0,42,0
test,structural,6,Gemini 3.8 Flash,opencode,0.253,0.059,2.45,0,0,25,0
test,structural,6,Gemini 3.8 Flash,claude-code,0.322,0.083,2.61,0,0,34,0
test,structural,6,Gemini 3.8 Flash,agy,0.271,0.024,2.6,0,0,40,1
test,structural,6,Gemini 3.8 Flash,openhands,0.339,0.011,3.21,0,0,33,0
test,structural,6,Gemini 3.8 Flash,codex,0.284,0.046,3.61,0,0,45,0
test,structural,6,Gemini 3.8 Flash,hermes,0.117,0.023,2.39,0,0,24,0
test,structural,6,Grok 4.7,pi,0.325,0.033,8.01,0,0,40,0
test,structural,6,Grok 4.7,opencode,0.289,0.025,10.25,0,0,34,0
test,structural,6,Grok 4.7,claude-code,0.265,0.017,12.75,0,0,48,0
test,structural,6,Grok 4.7,agy,0.264,0.009,16.81,1,1,33,0
test,structural,6,Grok 4.7,openhands,0.273,0.019,8.89,0,0,34,0
test,structural,6,Grok 4.7,codex,0.264,0.026,7.02,0,0,39,0
test,structural,6,Grok 4.7,hermes,0.245,0.02,10.09,0,0,47,0
test,structural,6,Grok 4.7,grok-build,0.283,0.012,10.18,0,0,52,1
test,structural,6,DeepSeek-V4.1-Flash,pi,0.214,0.039,4.54,0,0,169,0
test,structural,6,DeepSeek-V4.1-Flash,opencode,0.321,0.055,3.46,0,0,172,0
test,structural,6,DeepSeek-V4.1-Flash,claude-code,0.033,0.03,3.74,0,0,241,0
test,structural,6,DeepSeek-V4.1-Flash,agy,0.017,0.029,3.5,1,0,229,0
test,structural,6,DeepSeek-V4.1-Flash,openhands,0.0,0.0,1.65,0,0,194,0
test,structural,6,DeepSeek-V4.1-Flash,codex,0.02,0.035,2.08,0,0,295,0
test,structural,6,DeepSeek-V4.1-Flash,hermes,0.0,0.0,2.98,0,0,255,0
test,structural,6,DeepSeek-V4.1-Flash,dsh,0.017,0.017,6.3,0,0,240,1
test,structural,6,GLM 5.2,pi,0.263,0.025,13.66,0,0,109,0
test,structural,6,GLM 5.2,opencode,0.276,0.016,,0,0,94,0
test,structural,6,GLM 5.2,claude-code,0.231,0.023,14.78,0,0,94,0
test,structural,6,GLM 5.2,agy,0.223,0.037,12.71,1,0,86,0
test,structural,6,GLM 5.2,openhands,0.211,0.036,15.5,0,0,104,0
test,structural,6,GLM 5.2,codex,0.268,0.038,12.57,0,0,121,0
test,structural,6,GLM 5.2,hermes,0.249,0.02,10.83,0,0,70,0
test,structural,6,Gemini 3.1 Pro,pi,0.119,0.029,2.76,0,0,24,0
test,structural,6,Gemini 3.1 Pro,opencode,0.114,0.008,2.67,0,0,15,0
test,structural,6,Gemini 3.1 Pro,claude-code,0.129,0.014,3.65,0,0,17,0
test,structural,6,Gemini 3.1 Pro,agy,0.078,0.022,2.47,0,0,15,1
test,structural,6,Gemini 3.1 Pro,openhands,0.098,0.006,4.67,0,0,16,0
test,structural,6,Gemini 3.1 Pro,codex,0.114,0.023,2.8,0,0,16,0
test,structural,6,Gemini 3.1 Pro,hermes,0.117,0.007,2.09,0,0,12,0
test,structural,6,Kimi K2 Thinking,pi,0.0,0.0,0.2,0,0,8,0
test,structural,6,Kimi K2 Thinking,opencode,0.045,0.014,0.28,0,0,8,0
test,structural,6,Kimi K2 Thinking,claude-code,0.002,0.004,0.25,0,0,7,0
test,structural,6,Kimi K2 Thinking,agy,0.001,0.002,0.29,1,0,18,0
test,structural,6,Kimi K2 Thinking,openhands,0.001,0.001,0.25,0,0,12,0
test,structural,6,Kimi K2 Thinking,codex,0.01,0.005,0.26,0,0,9,0
test,structural,6,Kimi K2 Thinking,hermes,0.01,0.005,0.28,0,0,8,0
test,structural,6,Qwen3 Coder 480B,pi,0.009,0.016,0.15,0,0,10,0
test,structural,6,Qwen3 Coder 480B,opencode,0.001,0.001,0.25,0,0,8,0
test,structural,6,Qwen3 Coder 480B,claude-code,0.022,0.011,0.13,0,0,10,0
test,structural,6,Qwen3 Coder 480B,agy,0.007,0.01,0.49,1,0,6,0
test,structural,6,Qwen3 Coder 480B,openhands,0.031,0.008,0.21,0,0,28,0
test,structural,6,Qwen3 Coder 480B,codex,0.02,0.004,0.11,0,0,6,0
test,structural,6,Qwen3 Coder 480B,hermes,0.027,0.025,0.12,0,0,8,0
test,structural,6,MiniMax M2,pi,0.012,0.014,0.094,0,0,12,0
test,structural,6,MiniMax M2,opencode,0.0,0.0,0.079,0,0,14,0
test,structural,6,MiniMax M2,claude-code,0.027,0.01,0.1,0,0,12,0
test,structural,6,MiniMax M2,agy,0.003,0.003,0.33,1,0,13,0
test,structural,6,MiniMax M2,openhands,0.002,0.003,0.13,0,0,14,0
test,structural,6,MiniMax M2,codex,0.028,0.017,0.093,0,0,14,0
test,structural,6,MiniMax M2,hermes,0.023,0.019,0.097,0,0,10,0
test,structural,6,gpt-oss 120B,pi,0.015,0.002,0.12,0,0,26,0
test,structural,6,gpt-oss 120B,opencode,0.01,0.007,0.16,0,0,47,0
test,structural,6,gpt-oss 120B,claude-code,0.005,0.001,0.11,0,0,46,0
test,structural,6,gpt-oss 120B,agy,0.011,0.008,,0,0,36,0
test,structural,6,gpt-oss 120B,openhands,0.017,0.013,0.14,0,0,52,0
test,structural,6,gpt-oss 120B,codex,0.015,0.009,0.18,0,0,45,1
test,structural,6,gpt-oss 120B,hermes,0.018,0.008,0.16,0,0,48,0
test,structural,6,Qwen3-Next 80B,pi,0.0,0.0,1.05,0,1,59,0
test,structural,6,Qwen3-Next 80B,opencode,0.0,0.0,0.54,0,1,70,0
test,structural,6,Qwen3-Next 80B,claude-code,0.011,0.018,0.54,0,1,44,0
test,structural,6,Qwen3-Next 80B,agy,0.0,0.0,0.4,1,1,41,0
test,structural,6,Qwen3-Next 80B,openhands,0.011,0.008,0.77,0,1,92,0
test,structural,6,Qwen3-Next 80B,codex,0.007,0.01,0.56,0,1,36,0
test,structural,6,Qwen3-Next 80B,hermes,0.001,0.001,0.41,0,1,47,0
test,structural,6,Gemma 4 26B,pi,0.002,0.004,0.29,0,0,84,0
test,structural,6,Gemma 4 26B,opencode,0.001,0.001,0.45,0,0,46,0
test,structural,6,Gemma 4 26B,claude-code,0.001,0.001,0.53,0,0,88,0
test,structural,6,Gemma 4 26B,agy,0.007,0.009,0.21,1,0,95,1
test,structural,6,Gemma 4 26B,openhands,0.0,0.0,0.61,0,0,109,0
test,structural,6,Gemma 4 26B,codex,0.0,0.0,0.2,0,0,24,0
test,structural,6,Gemma 4 26B,hermes,0.0,0.0,0.29,0,0,24,0
test,structural,6,Llama 4 Maverick,pi,0.0,0.0,0.34,0,1,1,0
test,structural,6,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
test,structural,6,Llama 4 Maverick,claude-code,0.0,0.0,0.063,0,1,1,0
test,structural,6,Llama 4 Maverick,agy,0.0,0.0,0.06,1,1,3,0
test,structural,6,Llama 4 Maverick,openhands,0.0,0.0,0.18,0,1,2,0
test,structural,6,Llama 4 Maverick,codex,0.0,0.0,0.097,0,1,2,0
test,structural,6,Llama 4 Maverick,hermes,0.0,0.0,0.046,0,1,1,0
test,civil,9,Claude Opus 5.5,pi,0.624,0.048,13.35,0,0,68,0
test,civil,9,Claude Opus 5.5,opencode,0.623,0.095,12.87,0,0,49,0
test,civil,9,Claude Opus 5.5,claude-code,0.703,0.053,17.12,0,0,63,1
test,civil,9,Claude Opus 5.5,agy,0.621,0.028,42.32,1,0,45,0
test,civil,9,Claude Opus 5.5,openhands,0.64,0.094,14.87,0,0,66,0
test,civil,9,Claude Opus 5.5,codex,0.635,0.01,37.62,0,0,130,0
test,civil,9,Claude Opus 5.5,hermes,0.62,0.06,16.03,0,0,66,0
test,civil,9,Claude Sonnet 5.5,pi,0.579,0.071,11.77,0,0,96,0
test,civil,9,Claude Sonnet 5.5,opencode,0.521,0.026,10.53,0,0,63,0
test,civil,9,Claude Sonnet 5.5,claude-code,0.52,0.008,18.68,0,0,99,1
test,civil,9,Claude Sonnet 5.5,agy,0.562,0.045,33.89,1,0,53,0
test,civil,9,Claude Sonnet 5.5,openhands,0.47,0.042,15.72,0,0,112,0
test,civil,9,Claude Sonnet 5.5,codex,0.514,0.063,42.56,0,0,243,0
test,civil,9,Claude Sonnet 5.5,hermes,0.557,0.139,14.71,0,0,87,0
test,civil,9,GPT 6 Astra,codex,0.576,0.055,9.53,0,0,26,1
test,civil,9,Gemini 4 Argon,pi,0.503,0.023,7.0,0,0,78,0
test,civil,9,Gemini 4 Argon,opencode,0.47,0.058,7.04,0,0,55,0
test,civil,9,Gemini 4 Argon,claude-code,0.515,0.052,8.51,0,0,67,0
test,civil,9,Gemini 4 Argon,agy,0.538,0.048,7.7,0,0,73,1
test,civil,9,Gemini 4 Argon,openhands,0.291,0.113,7.54,0,0,83,0
test,civil,9,Gemini 4 Argon,codex,0.545,0.047,7.13,0,0,83,0
test,civil,9,Gemini 4 Argon,hermes,0.481,0.057,7.92,0,0,61,0
test,civil,9,Claude Opus 5,pi,0.431,0.056,15.26,0,0,58,0
test,civil,9,Claude Opus 5,opencode,0.456,0.069,12.51,0,0,38,0
test,civil,9,Claude Opus 5,claude-code,0.461,0.084,16.52,0,0,48,1
test,civil,9,Claude Opus 5,agy,0.455,0.042,29.59,1,0,42,0
test,civil,9,Claude Opus 5,openhands,0.525,0.03,17.13,0,0,66,0
test,civil,9,Claude Opus 5,codex,0.394,0.059,20.77,0,0,69,0
test,civil,9,Claude Opus 5,hermes,0.443,0.082,13.89,0,0,52,0
test,civil,9,Claude Fable 5,pi,0.315,0.021,21.17,0,0,47,0
test,civil,9,Claude Fable 5,opencode,0.326,0.087,22.95,0,0,38,0
test,civil,9,Claude Fable 5,claude-code,0.391,0.086,26.46,0,0,45,1
test,civil,9,Claude Fable 5,agy,0.319,0.033,54.19,1,0,37,0
test,civil,9,Claude Fable 5,openhands,0.326,0.038,25.83,0,0,44,0
test,civil,9,Claude Fable 5,codex,0.351,0.041,28.77,0,0,60,0
test,civil,9,Claude Fable 5,hermes,0.312,0.021,24.3,0,0,55,0
test,civil,9,Grok 4.7,pi,0.346,0.085,8.01,0,0,40,0
test,civil,9,Grok 4.7,opencode,0.359,0.042,10.25,0,0,34,0
test,civil,9,Grok 4.7,claude-code,0.26,0.056,12.75,0,0,48,0
test,civil,9,Grok 4.7,agy,0.321,0.023,16.81,1,1,33,0
test,civil,9,Grok 4.7,openhands,0.286,0.103,8.89,0,0,34,0
test,civil,9,Grok 4.7,codex,0.314,0.105,7.02,0,0,39,0
test,civil,9,Grok 4.7,hermes,0.297,0.076,10.09,0,0,47,0
test,civil,9,Grok 4.7,grok-build,0.371,0.057,10.18,0,0,52,1
test,civil,9,Gemini 3.8 Flash,pi,0.289,0.063,2.68,0,0,42,0
test,civil,9,Gemini 3.8 Flash,opencode,0.255,0.028,2.45,0,0,25,0
test,civil,9,Gemini 3.8 Flash,claude-code,0.286,0.037,2.61,0,0,34,0
test,civil,9,Gemini 3.8 Flash,agy,0.318,0.069,2.6,0,0,40,1
test,civil,9,Gemini 3.8 Flash,openhands,0.309,0.021,3.21,0,0,33,0
test,civil,9,Gemini 3.8 Flash,codex,0.301,0.113,3.61,0,0,45,0
test,civil,9,Gemini 3.8 Flash,hermes,0.184,0.053,2.39,0,0,24,0
test,civil,9,DeepSeek-V4.1-Flash,pi,0.268,0.054,4.54,0,0,169,0
test,civil,9,DeepSeek-V4.1-Flash,opencode,0.217,0.083,3.46,0,0,172,0
test,civil,9,DeepSeek-V4.1-Flash,claude-code,0.116,0.034,3.74,0,0,241,0
test,civil,9,DeepSeek-V4.1-Flash,agy,0.062,0.066,3.5,1,0,229,0
test,civil,9,DeepSeek-V4.1-Flash,openhands,0.058,0.057,1.65,0,0,194,0
test,civil,9,DeepSeek-V4.1-Flash,codex,0.037,0.008,2.08,0,0,295,0
test,civil,9,DeepSeek-V4.1-Flash,hermes,0.032,0.018,2.98,0,0,255,0
test,civil,9,DeepSeek-V4.1-Flash,dsh,0.09,0.048,6.3,0,0,240,1
test,civil,9,GLM 5.2,pi,0.263,0.011,13.66,0,0,109,0
test,civil,9,GLM 5.2,opencode,0.209,0.04,,0,0,94,0
test,civil,9,GLM 5.2,claude-code,0.206,0.023,14.78,0,0,94,0
test,civil,9,GLM 5.2,agy,0.234,0.046,12.71,1,0,86,0
test,civil,9,GLM 5.2,openhands,0.233,0.032,15.5,0,0,104,0
test,civil,9,GLM 5.2,codex,0.238,0.045,12.57,0,0,121,0
test,civil,9,GLM 5.2,hermes,0.234,0.05,10.83,0,0,70,0
test,civil,9,Gemini 3.1 Pro,pi,0.121,0.039,2.76,0,0,24,0
test,civil,9,Gemini 3.1 Pro,opencode,0.135,0.04,2.67,0,0,15,0
test,civil,9,Gemini 3.1 Pro,claude-code,0.133,0.022,3.65,0,0,17,0
test,civil,9,Gemini 3.1 Pro,agy,0.132,0.062,2.47,0,0,15,1
test,civil,9,Gemini 3.1 Pro,openhands,0.144,0.051,4.67,0,0,16,0
test,civil,9,Gemini 3.1 Pro,codex,0.152,0.016,2.8,0,0,16,0
test,civil,9,Gemini 3.1 Pro,hermes,0.148,0.055,2.09,0,0,12,0
test,civil,9,MiniMax M2,pi,0.03,0.01,0.094,0,0,12,0
test,civil,9,MiniMax M2,opencode,0.031,0.011,0.079,0,0,14,0
test,civil,9,MiniMax M2,claude-code,0.029,0.01,0.1,0,0,12,0
test,civil,9,MiniMax M2,agy,0.018,0.003,0.33,1,0,13,0
test,civil,9,MiniMax M2,openhands,0.023,0.001,0.13,0,0,14,0
test,civil,9,MiniMax M2,codex,0.022,0.01,0.093,0,0,14,0
test,civil,9,MiniMax M2,hermes,0.04,0.029,0.097,0,0,10,0
test,civil,9,Qwen3 Coder 480B,pi,0.023,0.007,0.15,0,0,10,0
test,civil,9,Qwen3 Coder 480B,opencode,0.019,0.003,0.25,0,0,8,0
test,civil,9,Qwen3 Coder 480B,claude-code,0.036,0.017,0.13,0,0,10,0
test,civil,9,Qwen3 Coder 480B,agy,0.036,0.006,0.49,1,0,6,0
test,civil,9,Qwen3 Coder 480B,openhands,0.021,0.009,0.21,0,0,28,0
test,civil,9,Qwen3 Coder 480B,codex,0.031,0.014,0.11,0,0,6,0
test,civil,9,Qwen3 Coder 480B,hermes,0.022,0.004,0.12,0,0,8,0
test,civil,9,Kimi K2 Thinking,pi,0.03,0.01,0.2,0,0,8,0
test,civil,9,Kimi K2 Thinking,opencode,0.032,0.008,0.28,0,0,8,0
test,civil,9,Kimi K2 Thinking,claude-code,0.028,0.022,0.25,0,0,7,0
test,civil,9,Kimi K2 Thinking,agy,0.015,0.015,0.29,1,0,18,0
test,civil,9,Kimi K2 Thinking,openhands,0.027,0.007,0.25,0,0,12,0
test,civil,9,Kimi K2 Thinking,codex,0.013,0.009,0.26,0,0,9,0
test,civil,9,Kimi K2 Thinking,hermes,0.034,0.01,0.28,0,0,8,0
test,civil,9,gpt-oss 120B,pi,0.033,0.01,0.12,0,0,26,0
test,civil,9,gpt-oss 120B,opencode,0.02,0.011,0.16,0,0,47,0
test,civil,9,gpt-oss 120B,claude-code,0.021,0.009,0.11,0,0,46,0
test,civil,9,gpt-oss 120B,agy,0.011,0.006,,0,0,36,0
test,civil,9,gpt-oss 120B,openhands,0.02,0.011,0.14,0,0,52,0
test,civil,9,gpt-oss 120B,codex,0.013,0.006,0.18,0,0,45,1
test,civil,9,gpt-oss 120B,hermes,0.024,0.009,0.16,0,0,48,0
test,civil,9,Gemma 4 26B,pi,0.033,0.016,0.29,0,0,84,0
test,civil,9,Gemma 4 26B,opencode,0.013,0.002,0.45,0,0,46,0
test,civil,9,Gemma 4 26B,claude-code,0.025,0.01,0.53,0,0,88,0
test,civil,9,Gemma 4 26B,agy,0.024,0.014,0.21,1,0,95,1
test,civil,9,Gemma 4 26B,openhands,0.026,0.019,0.61,0,0,109,0
test,civil,9,Gemma 4 26B,codex,0.01,0.017,0.2,0,0,24,0
test,civil,9,Gemma 4 26B,hermes,0.026,0.007,0.29,0,0,24,0
test,civil,9,Qwen3-Next 80B,pi,0.008,0.007,1.05,0,1,59,0
test,civil,9,Qwen3-Next 80B,opencode,0.016,0.006,0.54,0,1,70,0
test,civil,9,Qwen3-Next 80B,claude-code,0.021,0.01,0.54,0,1,44,0
test,civil,9,Qwen3-Next 80B,agy,0.015,0.008,0.4,1,1,41,0
test,civil,9,Qwen3-Next 80B,openhands,0.02,0.002,0.77,0,1,92,0
test,civil,9,Qwen3-Next 80B,codex,0.005,0.006,0.56,0,1,36,0
test,civil,9,Qwen3-Next 80B,hermes,0.014,0.002,0.41,0,1,47,0
test,civil,9,Llama 4 Maverick,pi,0.001,0.002,0.34,0,1,1,0
test,civil,9,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
test,civil,9,Llama 4 Maverick,claude-code,0.001,0.001,0.063,0,1,1,0
test,civil,9,Llama 4 Maverick,agy,0.0,0.0,0.06,1,1,3,0
test,civil,9,Llama 4 Maverick,openhands,0.002,0.003,0.18,0,1,2,0
test,civil,9,Llama 4 Maverick,codex,0.0,0.0,0.097,0,1,2,0
test,civil,9,Llama 4 Maverick,hermes,0.0,0.0,0.046,0,1,1,0
test,electrical,18,Claude Opus 5.5,pi,0.453,0.009,13.35,0,0,68,0
test,electrical,18,Claude Opus 5.5,opencode,0.438,0.02,12.87,0,0,49,0
test,electrical,18,Claude Opus 5.5,claude-code,0.433,0.026,17.12,0,0,63,1
test,electrical,18,Claude Opus 5.5,agy,0.468,0.02,42.32,1,0,45,0
test,electrical,18,Claude Opus 5.5,openhands,0.479,0.014,14.87,0,0,66,0
test,electrical,18,Claude Opus 5.5,codex,0.485,0.029,37.62,0,0,130,0
test,electrical,18,Claude Opus 5.5,hermes,0.49,0.032,16.03,0,0,66,0
test,electrical,18,Claude Sonnet 5.5,pi,0.399,0.02,11.77,0,0,96,0
test,electrical,18,Claude Sonnet 5.5,opencode,0.39,0.006,10.53,0,0,63,0
test,electrical,18,Claude Sonnet 5.5,claude-code,0.406,0.038,18.68,0,0,99,1
test,electrical,18,Claude Sonnet 5.5,agy,0.395,0.011,33.89,1,0,53,0
test,electrical,18,Claude Sonnet 5.5,openhands,0.36,0.031,15.72,0,0,112,0
test,electrical,18,Claude Sonnet 5.5,codex,0.421,0.043,42.56,0,0,243,0
test,electrical,18,Claude Sonnet 5.5,hermes,0.408,0.016,14.71,0,0,87,0
test,electrical,18,Gemini 4 Argon,pi,0.323,0.026,7.0,0,0,78,0
test,electrical,18,Gemini 4 Argon,opencode,0.341,0.031,7.04,0,0,55,0
test,electrical,18,Gemini 4 Argon,claude-code,0.41,0.024,8.51,0,0,67,0
test,electrical,18,Gemini 4 Argon,agy,0.397,0.024,7.7,0,0,73,1
test,electrical,18,Gemini 4 Argon,openhands,0.318,0.028,7.54,0,0,83,0
test,electrical,18,Gemini 4 Argon,codex,0.346,0.026,7.13,0,0,83,0
test,electrical,18,Gemini 4 Argon,hermes,0.407,0.058,7.92,0,0,61,0
test,electrical,18,Claude Opus 5,pi,0.406,0.03,15.26,0,0,58,0
test,electrical,18,Claude Opus 5,opencode,0.358,0.018,12.51,0,0,38,0
test,electrical,18,Claude Opus 5,claude-code,0.367,0.03,16.52,0,0,48,1
test,electrical,18,Claude Opus 5,agy,0.374,0.006,29.59,1,0,42,0
test,electrical,18,Claude Opus 5,openhands,0.378,0.009,17.13,0,0,66,0
test,electrical,18,Claude Opus 5,codex,0.365,0.026,20.77,0,0,69,0
test,electrical,18,Claude Opus 5,hermes,0.379,0.036,13.89,0,0,52,0
test,electrical,18,GPT 6 Astra,codex,0.404,0.022,9.53,0,0,26,1
test,electrical,18,Claude Fable 5,pi,0.35,0.03,21.17,0,0,47,0
test,electrical,18,Claude Fable 5,opencode,0.332,0.013,22.95,0,0,38,0
test,electrical,18,Claude Fable 5,claude-code,0.317,0.011,26.46,0,0,45,1
test,electrical,18,Claude Fable 5,agy,0.323,0.024,54.19,1,0,37,0
test,electrical,18,Claude Fable 5,openhands,0.314,0.004,25.83,0,0,44,0
test,electrical,18,Claude Fable 5,codex,0.312,0.021,28.77,0,0,60,0
test,electrical,18,Claude Fable 5,hermes,0.32,0.012,24.3,0,0,55,0
test,electrical,18,Grok 4.7,pi,0.309,0.032,8.01,0,0,40,0
test,electrical,18,Grok 4.7,opencode,0.269,0.032,10.25,0,0,34,0
test,electrical,18,Grok 4.7,claude-code,0.271,0.017,12.75,0,0,48,0
test,electrical,18,Grok 4.7,agy,0.296,0.015,16.81,1,1,33,0
test,electrical,18,Grok 4.7,openhands,0.328,0.012,8.89,0,0,34,0
test,electrical,18,Grok 4.7,codex,0.281,0.013,7.02,0,0,39,0
test,electrical,18,Grok 4.7,hermes,0.256,0.014,10.09,0,0,47,0
test,electrical,18,Grok 4.7,grok-build,0.312,0.019,10.18,0,0,52,1
test,electrical,18,Gemini 3.8 Flash,pi,0.271,0.017,2.68,0,0,42,0
test,electrical,18,Gemini 3.8 Flash,opencode,0.25,0.008,2.45,0,0,25,0
test,electrical,18,Gemini 3.8 Flash,claude-code,0.232,0.014,2.61,0,0,34,0
test,electrical,18,Gemini 3.8 Flash,agy,0.262,0.012,2.6,0,0,40,1
test,electrical,18,Gemini 3.8 Flash,openhands,0.262,0.027,3.21,0,0,33,0
test,electrical,18,Gemini 3.8 Flash,codex,0.259,0.021,3.61,0,0,45,0
test,electrical,18,Gemini 3.8 Flash,hermes,0.186,0.008,2.39,0,0,24,0
test,electrical,18,GLM 5.2,pi,0.223,0.009,13.66,0,0,109,0
test,electrical,18,GLM 5.2,opencode,0.229,0.015,,0,0,94,0
test,electrical,18,GLM 5.2,claude-code,0.222,0.019,14.78,0,0,94,0
test,electrical,18,GLM 5.2,agy,0.233,0.032,12.71,1,0,86,0
test,electrical,18,GLM 5.2,openhands,0.227,0.016,15.5,0,0,104,0
test,electrical,18,GLM 5.2,codex,0.243,0.012,12.57,0,0,121,0
test,electrical,18,GLM 5.2,hermes,0.226,0.012,10.83,0,0,70,0
test,electrical,18,DeepSeek-V4.1-Flash,pi,0.211,0.031,4.54,0,0,169,0
test,electrical,18,DeepSeek-V4.1-Flash,opencode,0.201,0.023,3.46,0,0,172,0
test,electrical,18,DeepSeek-V4.1-Flash,claude-code,0.145,0.036,3.74,0,0,241,0
test,electrical,18,DeepSeek-V4.1-Flash,agy,0.1,0.021,3.5,1,0,229,0
test,electrical,18,DeepSeek-V4.1-Flash,openhands,0.042,0.017,1.65,0,0,194,0
test,electrical,18,DeepSeek-V4.1-Flash,codex,0.03,0.01,2.08,0,0,295,0
test,electrical,18,DeepSeek-V4.1-Flash,hermes,0.051,0.023,2.98,0,0,255,0
test,electrical,18,DeepSeek-V4.1-Flash,dsh,0.141,0.016,6.3,0,0,240,1
test,electrical,18,Gemini 3.1 Pro,pi,0.151,0.013,2.76,0,0,24,0
test,electrical,18,Gemini 3.1 Pro,opencode,0.153,0.007,2.67,0,0,15,0
test,electrical,18,Gemini 3.1 Pro,claude-code,0.159,0.003,3.65,0,0,17,0
test,electrical,18,Gemini 3.1 Pro,agy,0.158,0.017,2.47,0,0,15,1
test,electrical,18,Gemini 3.1 Pro,openhands,0.16,0.025,4.67,0,0,16,0
test,electrical,18,Gemini 3.1 Pro,codex,0.16,0.018,2.8,0,0,16,0
test,electrical,18,Gemini 3.1 Pro,hermes,0.162,0.013,2.09,0,0,12,0
test,electrical,18,MiniMax M2,pi,0.078,0.004,0.094,0,0,12,0
test,electrical,18,MiniMax M2,opencode,0.076,0.011,0.079,0,0,14,0
test,electrical,18,MiniMax M2,claude-code,0.088,0.013,0.1,0,0,12,0
test,electrical,18,MiniMax M2,agy,0.057,0.013,0.33,1,0,13,0
test,electrical,18,MiniMax M2,openhands,0.096,0.004,0.13,0,0,14,0
test,electrical,18,MiniMax M2,codex,0.069,0.001,0.093,0,0,14,0
test,electrical,18,MiniMax M2,hermes,0.068,0.012,0.097,0,0,10,0
test,electrical,18,Kimi K2 Thinking,pi,0.052,0.006,0.2,0,0,8,0
test,electrical,18,Kimi K2 Thinking,opencode,0.091,0.018,0.28,0,0,8,0
test,electrical,18,Kimi K2 Thinking,claude-code,0.076,0.016,0.25,0,0,7,0
test,electrical,18,Kimi K2 Thinking,agy,0.038,0.012,0.29,1,0,18,0
test,electrical,18,Kimi K2 Thinking,openhands,0.058,0.021,0.25,0,0,12,0
test,electrical,18,Kimi K2 Thinking,codex,0.044,0.003,0.26,0,0,9,0
test,electrical,18,Kimi K2 Thinking,hermes,0.075,0.006,0.28,0,0,8,0
test,electrical,18,Qwen3 Coder 480B,pi,0.07,0.014,0.15,0,0,10,0
test,electrical,18,Qwen3 Coder 480B,opencode,0.072,0.006,0.25,0,0,8,0
test,electrical,18,Qwen3 Coder 480B,claude-code,0.09,0.004,0.13,0,0,10,0
test,electrical,18,Qwen3 Coder 480B,agy,0.058,0.009,0.49,1,0,6,0
test,electrical,18,Qwen3 Coder 480B,openhands,0.085,0.006,0.21,0,0,28,0
test,electrical,18,Qwen3 Coder 480B,codex,0.067,0.012,0.11,0,0,6,0
test,electrical,18,Qwen3 Coder 480B,hermes,0.085,0.01,0.12,0,0,8,0
test,electrical,18,Qwen3-Next 80B,pi,0.058,0.012,1.05,0,1,59,0
test,electrical,18,Qwen3-Next 80B,opencode,0.048,0.011,0.54,0,1,70,0
test,electrical,18,Qwen3-Next 80B,claude-code,0.041,0.01,0.54,0,1,44,0
test,electrical,18,Qwen3-Next 80B,agy,0.03,0.008,0.4,1,1,41,0
test,electrical,18,Qwen3-Next 80B,openhands,0.065,0.004,0.77,0,1,92,0
test,electrical,18,Qwen3-Next 80B,codex,0.017,0.004,0.56,0,1,36,0
test,electrical,18,Qwen3-Next 80B,hermes,0.026,0.008,0.41,0,1,47,0
test,electrical,18,gpt-oss 120B,pi,0.056,0.007,0.12,0,0,26,0
test,electrical,18,gpt-oss 120B,opencode,0.054,0.007,0.16,0,0,47,0
test,electrical,18,gpt-oss 120B,claude-code,0.054,0.008,0.11,0,0,46,0
test,electrical,18,gpt-oss 120B,agy,0.061,0.005,,0,0,36,0
test,electrical,18,gpt-oss 120B,openhands,0.054,0.013,0.14,0,0,52,0
test,electrical,18,gpt-oss 120B,codex,0.035,0.004,0.18,0,0,45,1
test,electrical,18,gpt-oss 120B,hermes,0.049,0.008,0.16,0,0,48,0
test,electrical,18,Gemma 4 26B,pi,0.046,0.013,0.29,0,0,84,0
test,electrical,18,Gemma 4 26B,opencode,0.032,0.009,0.45,0,0,46,0
test,electrical,18,Gemma 4 26B,claude-code,0.044,0.003,0.53,0,0,88,0
test,electrical,18,Gemma 4 26B,agy,0.042,0.008,0.21,1,0,95,1
test,electrical,18,Gemma 4 26B,openhands,0.046,0.005,0.61,0,0,109,0
test,electrical,18,Gemma 4 26B,codex,0.005,0.004,0.2,0,0,24,0
test,electrical,18,Gemma 4 26B,hermes,0.027,0.012,0.29,0,0,24,0
test,electrical,18,Llama 4 Maverick,pi,0.006,0.007,0.34,0,1,1,0
test,electrical,18,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
test,electrical,18,Llama 4 Maverick,claude-code,0.004,0.003,0.063,0,1,1,0
test,electrical,18,Llama 4 Maverick,agy,0.0,0.0,0.06,1,1,3,0
test,electrical,18,Llama 4 Maverick,openhands,0.01,0.005,0.18,0,1,2,0
test,electrical,18,Llama 4 Maverick,codex,0.0,0.0,0.097,0,1,2,0
test,electrical,18,Llama 4 Maverick,hermes,0.0,0.0,0.046,0,1,1,0
test,mechanical,23,GPT 6 Astra,codex,0.448,0.019,9.53,0,0,26,1
test,mechanical,23,Claude Sonnet 5.5,pi,0.409,0.028,11.77,0,0,96,0
test,mechanical,23,Claude Sonnet 5.5,opencode,0.389,0.017,10.53,0,0,63,0
test,mechanical,23,Claude Sonnet 5.5,claude-code,0.415,0.013,18.68,0,0,99,1
test,mechanical,23,Claude Sonnet 5.5,agy,0.432,0.002,33.89,1,0,53,0
test,mechanical,23,Claude Sonnet 5.5,openhands,0.391,0.017,15.72,0,0,112,0
test,mechanical,23,Claude Sonnet 5.5,codex,0.397,0.014,42.56,0,0,243,0
test,mechanical,23,Claude Sonnet 5.5,hermes,0.425,0.016,14.71,0,0,87,0
test,mechanical,23,Claude Opus 5.5,pi,0.409,0.021,13.35,0,0,68,0
test,mechanical,23,Claude Opus 5.5,opencode,0.405,0.017,12.87,0,0,49,0
test,mechanical,23,Claude Opus 5.5,claude-code,0.416,0.016,17.12,0,0,63,1
test,mechanical,23,Claude Opus 5.5,agy,0.424,0.012,42.32,1,0,45,0
test,mechanical,23,Claude Opus 5.5,openhands,0.408,0.021,14.87,0,0,66,0
test,mechanical,23,Claude Opus 5.5,codex,0.367,0.031,37.62,0,0,130,0
test,mechanical,23,Claude Opus 5.5,hermes,0.385,0.005,16.03,0,0,66,0
test,mechanical,23,Claude Opus 5,pi,0.398,0.028,15.26,0,0,58,0
test,mechanical,23,Claude Opus 5,opencode,0.396,0.019,12.51,0,0,38,0
test,mechanical,23,Claude Opus 5,claude-code,0.383,0.034,16.52,0,0,48,1
test,mechanical,23,Claude Opus 5,agy,0.405,0.036,29.59,1,0,42,0
test,mechanical,23,Claude Opus 5,openhands,0.4,0.012,17.13,0,0,66,0
test,mechanical,23,Claude Opus 5,codex,0.37,0.006,20.77,0,0,69,0
test,mechanical,23,Claude Opus 5,hermes,0.384,0.039,13.89,0,0,52,0
test,mechanical,23,Gemini 4 Argon,pi,0.331,0.024,7.0,0,0,78,0
test,mechanical,23,Gemini 4 Argon,opencode,0.343,0.028,7.04,0,0,55,0
test,mechanical,23,Gemini 4 Argon,claude-code,0.361,0.031,8.51,0,0,67,0
test,mechanical,23,Gemini 4 Argon,agy,0.348,0.021,7.7,0,0,73,1
test,mechanical,23,Gemini 4 Argon,openhands,0.261,0.027,7.54,0,0,83,0
test,mechanical,23,Gemini 4 Argon,codex,0.359,0.016,7.13,0,0,83,0
test,mechanical,23,Gemini 4 Argon,hermes,0.339,0.01,7.92,0,0,61,0
test,mechanical,23,Claude Fable 5,pi,0.314,0.01,21.17,0,0,47,0
test,mechanical,23,Claude Fable 5,opencode,0.339,0.016,22.95,0,0,38,0
test,mechanical,23,Claude Fable 5,claude-code,0.332,0.014,26.46,0,0,45,1
test,mechanical,23,Claude Fable 5,agy,0.315,0.024,54.19,1,0,37,0
test,mechanical,23,Claude Fable 5,openhands,0.309,0.01,25.83,0,0,44,0
test,mechanical,23,Claude Fable 5,codex,0.333,0.011,28.77,0,0,60,0
test,mechanical,23,Claude Fable 5,hermes,0.323,0.02,24.3,0,0,55,0
test,mechanical,23,Gemini 3.8 Flash,pi,0.261,0.034,2.68,0,0,42,0
test,mechanical,23,Gemini 3.8 Flash,opencode,0.269,0.017,2.45,0,0,25,0
test,mechanical,23,Gemini 3.8 Flash,claude-code,0.285,0.015,2.61,0,0,34,0
test,mechanical,23,Gemini 3.8 Flash,agy,0.269,0.019,2.6,0,0,40,1
test,mechanical,23,Gemini 3.8 Flash,openhands,0.271,0.011,3.21,0,0,33,0
test,mechanical,23,Gemini 3.8 Flash,codex,0.282,0.036,3.61,0,0,45,0
test,mechanical,23,Gemini 3.8 Flash,hermes,0.177,0.025,2.39,0,0,24,0
test,mechanical,23,Grok 4.7,pi,0.273,0.006,8.01,0,0,40,0
test,mechanical,23,Grok 4.7,opencode,0.265,0.011,10.25,0,0,34,0
test,mechanical,23,Grok 4.7,claude-code,0.263,0.01,12.75,0,0,48,0
test,mechanical,23,Grok 4.7,agy,0.251,0.014,16.81,1,1,33,0
test,mechanical,23,Grok 4.7,openhands,0.23,0.008,8.89,0,0,34,0
test,mechanical,23,Grok 4.7,codex,0.219,0.003,7.02,0,0,39,0
test,mechanical,23,Grok 4.7,hermes,0.243,0.015,10.09,0,0,47,0
test,mechanical,23,Grok 4.7,grok-build,0.27,0.013,10.18,0,0,52,1
test,mechanical,23,GLM 5.2,pi,0.263,0.002,13.66,0,0,109,0
test,mechanical,23,GLM 5.2,opencode,0.252,0.01,,0,0,94,0
test,mechanical,23,GLM 5.2,claude-code,0.217,0.033,14.78,0,0,94,0
test,mechanical,23,GLM 5.2,agy,0.247,0.015,12.71,1,0,86,0
test,mechanical,23,GLM 5.2,openhands,0.244,0.016,15.5,0,0,104,0
test,mechanical,23,GLM 5.2,codex,0.256,0.028,12.57,0,0,121,0
test,mechanical,23,GLM 5.2,hermes,0.251,0.01,10.83,0,0,70,0
test,mechanical,23,DeepSeek-V4.1-Flash,pi,0.223,0.052,4.54,0,0,169,0
test,mechanical,23,DeepSeek-V4.1-Flash,opencode,0.225,0.029,3.46,0,0,172,0
test,mechanical,23,DeepSeek-V4.1-Flash,claude-code,0.115,0.009,3.74,0,0,241,0
test,mechanical,23,DeepSeek-V4.1-Flash,agy,0.117,0.01,3.5,1,0,229,0
test,mechanical,23,DeepSeek-V4.1-Flash,openhands,0.097,0.054,1.65,0,0,194,0
test,mechanical,23,DeepSeek-V4.1-Flash,codex,0.055,0.021,2.08,0,0,295,0
test,mechanical,23,DeepSeek-V4.1-Flash,hermes,0.077,0.053,2.98,0,0,255,0
test,mechanical,23,DeepSeek-V4.1-Flash,dsh,0.201,0.051,6.3,0,0,240,1
test,mechanical,23,Gemini 3.1 Pro,pi,0.146,0.007,2.76,0,0,24,0
test,mechanical,23,Gemini 3.1 Pro,opencode,0.141,0.014,2.67,0,0,15,0
test,mechanical,23,Gemini 3.1 Pro,claude-code,0.14,0.01,3.65,0,0,17,0
test,mechanical,23,Gemini 3.1 Pro,agy,0.141,0.008,2.47,0,0,15,1
test,mechanical,23,Gemini 3.1 Pro,openhands,0.152,0.019,4.67,0,0,16,0
test,mechanical,23,Gemini 3.1 Pro,codex,0.139,0.014,2.8,0,0,16,0
test,mechanical,23,Gemini 3.1 Pro,hermes,0.146,0.008,2.09,0,0,12,0
test,mechanical,23,Qwen3 Coder 480B,pi,0.037,0.013,0.15,0,0,10,0
test,mechanical,23,Qwen3 Coder 480B,opencode,0.046,0.002,0.25,0,0,8,0
test,mechanical,23,Qwen3 Coder 480B,claude-code,0.062,0.004,0.13,0,0,10,0
test,mechanical,23,Qwen3 Coder 480B,agy,0.046,0.011,0.49,1,0,6,0
test,mechanical,23,Qwen3 Coder 480B,openhands,0.064,0.008,0.21,0,0,28,0
test,mechanical,23,Qwen3 Coder 480B,codex,0.044,0.01,0.11,0,0,6,0
test,mechanical,23,Qwen3 Coder 480B,hermes,0.069,0.01,0.12,0,0,8,0
test,mechanical,23,MiniMax M2,pi,0.035,0.003,0.094,0,0,12,0
test,mechanical,23,MiniMax M2,opencode,0.03,0.002,0.079,0,0,14,0
test,mechanical,23,MiniMax M2,claude-code,0.051,0.004,0.1,0,0,12,0
test,mechanical,23,MiniMax M2,agy,0.034,0.005,0.33,1,0,13,0
test,mechanical,23,MiniMax M2,openhands,0.044,0.007,0.13,0,0,14,0
test,mechanical,23,MiniMax M2,codex,0.043,0.005,0.093,0,0,14,0
test,mechanical,23,MiniMax M2,hermes,0.063,0.007,0.097,0,0,10,0
test,mechanical,23,Gemma 4 26B,pi,0.044,0.008,0.29,0,0,84,0
test,mechanical,23,Gemma 4 26B,opencode,0.036,0.013,0.45,0,0,46,0
test,mechanical,23,Gemma 4 26B,claude-code,0.05,0.006,0.53,0,0,88,0
test,mechanical,23,Gemma 4 26B,agy,0.058,0.003,0.21,1,0,95,1
test,mechanical,23,Gemma 4 26B,openhands,0.063,0.01,0.61,0,0,109,0
test,mechanical,23,Gemma 4 26B,codex,0.01,0.001,0.2,0,0,24,0
test,mechanical,23,Gemma 4 26B,hermes,0.013,0.007,0.29,0,0,24,0
test,mechanical,23,gpt-oss 120B,pi,0.035,0.009,0.12,0,0,26,0
test,mechanical,23,gpt-oss 120B,opencode,0.036,0.015,0.16,0,0,47,0
test,mechanical,23,gpt-oss 120B,claude-code,0.049,0.005,0.11,0,0,46,0
test,mechanical,23,gpt-oss 120B,agy,0.047,0.012,,0,0,36,0
test,mechanical,23,gpt-oss 120B,openhands,0.057,0.015,0.14,0,0,52,0
test,mechanical,23,gpt-oss 120B,codex,0.057,0.012,0.18,0,0,45,1
test,mechanical,23,gpt-oss 120B,hermes,0.037,0.001,0.16,0,0,48,0
test,mechanical,23,Kimi K2 Thinking,pi,0.045,0.007,0.2,0,0,8,0
test,mechanical,23,Kimi K2 Thinking,opencode,0.054,0.017,0.28,0,0,8,0
test,mechanical,23,Kimi K2 Thinking,claude-code,0.04,0.017,0.25,0,0,7,0
test,mechanical,23,Kimi K2 Thinking,agy,0.042,0.005,0.29,1,0,18,0
test,mechanical,23,Kimi K2 Thinking,openhands,0.051,0.001,0.25,0,0,12,0
test,mechanical,23,Kimi K2 Thinking,codex,0.037,0.014,0.26,0,0,9,0
test,mechanical,23,Kimi K2 Thinking,hermes,0.046,0.01,0.28,0,0,8,0
test,mechanical,23,Qwen3-Next 80B,pi,0.017,0.007,1.05,0,1,59,0
test,mechanical,23,Qwen3-Next 80B,opencode,0.019,0.004,0.54,0,1,70,0
test,mechanical,23,Qwen3-Next 80B,claude-code,0.02,0.006,0.54,0,1,44,0
test,mechanical,23,Qwen3-Next 80B,agy,0.006,0.005,0.4,1,1,41,0
test,mechanical,23,Qwen3-Next 80B,openhands,0.044,0.007,0.77,0,1,92,0
test,mechanical,23,Qwen3-Next 80B,codex,0.006,0.008,0.56,0,1,36,0
test,mechanical,23,Qwen3-Next 80B,hermes,0.021,0.009,0.41,0,1,47,0
test,mechanical,23,Llama 4 Maverick,pi,0.012,0.002,0.34,0,1,1,0
test,mechanical,23,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
test,mechanical,23,Llama 4 Maverick,claude-code,0.006,0.001,0.063,0,1,1,0
test,mechanical,23,Llama 4 Maverick,agy,0.002,0.002,0.06,1,1,3,0
test,mechanical,23,Llama 4 Maverick,openhands,0.009,0.002,0.18,0,1,2,0
test,mechanical,23,Llama 4 Maverick,codex,0.001,0.002,0.097,0,1,2,0
test,mechanical,23,Llama 4 Maverick,hermes,0.001,0.001,0.046,0,1,1,0
dev,overall,29,Claude Opus 5.5,claude-code,0.551,0.032,17.3,0,0,63,1
dev,overall,29,Claude Opus 5.5,pi,0.474,0.029,13.29,0,0,71,0
dev,overall,29,Claude Opus 5.5,opencode,0.492,0.032,11.87,0,0,41,0
dev,overall,29,Claude Opus 5.5,agy,0.496,0.032,42.32,1,0,42,0
dev,overall,29,Claude Opus 5.5,codex,0.549,0.01,30.38,0,0,110,0
dev,overall,29,Claude Opus 5.5,hermes,0.526,0.001,17.17,0,0,70,0
dev,overall,29,Claude Opus 5.5,openhands,0.525,0.013,14.72,0,0,64,0
dev,overall,29,GPT 6 Astra,codex,0.53,0.01,8.42,0,0,24,1
dev,overall,29,Gemini 4 Argon,claude-code,0.473,0.037,7.62,0,0,62,0
dev,overall,29,Gemini 4 Argon,pi,0.471,0.05,5.29,0,0,70,0
dev,overall,29,Gemini 4 Argon,opencode,0.406,0.014,6.49,0,0,50,0
dev,overall,29,Gemini 4 Argon,agy,0.439,0.006,6.36,0,0,63,1
dev,overall,29,Gemini 4 Argon,codex,0.431,0.026,7.0,0,0,85,0
dev,overall,29,Gemini 4 Argon,hermes,0.454,0.018,7.0,0,0,55,0
dev,overall,29,Gemini 4 Argon,openhands,0.35,0.008,7.23,0,0,78,0
dev,overall,29,Claude Sonnet 5.5,claude-code,0.438,0.021,22.61,0,0,101,1
dev,overall,29,Claude Sonnet 5.5,pi,0.423,0.003,11.51,0,0,84,0
dev,overall,29,Claude Sonnet 5.5,opencode,0.418,0.008,10.4,0,0,60,0
dev,overall,29,Claude Sonnet 5.5,agy,0.46,0.027,33.89,1,0,52,0
dev,overall,29,Claude Sonnet 5.5,codex,0.419,0.015,38.34,0,0,224,0
dev,overall,29,Claude Sonnet 5.5,hermes,0.41,0.027,14.82,0,0,83,0
dev,overall,29,Claude Sonnet 5.5,openhands,0.449,0.018,14.43,0,0,109,0
dev,overall,29,Claude Opus 5,claude-code,0.422,0.002,18.53,0,0,51,1
dev,overall,29,Claude Opus 5,pi,0.377,0.019,14.65,0,0,57,0
dev,overall,29,Claude Opus 5,opencode,0.387,0.009,13.96,0,0,38,0
dev,overall,29,Claude Opus 5,agy,0.446,0.027,29.59,1,0,40,0
dev,overall,29,Claude Opus 5,codex,0.388,0.033,25.36,0,0,76,0
dev,overall,29,Claude Opus 5,hermes,0.381,0.011,15.05,0,0,53,0
dev,overall,29,Claude Opus 5,openhands,0.405,0.02,19.14,0,0,74,0
dev,overall,29,Claude Fable 5,claude-code,0.356,0.026,27.66,0,0,45,1
dev,overall,29,Claude Fable 5,pi,0.307,0.031,18.59,0,0,34,0
dev,overall,29,Claude Fable 5,opencode,0.353,0.024,22.87,0,0,36,0
dev,overall,29,Claude Fable 5,agy,0.365,0.006,54.19,1,0,35,0
dev,overall,29,Claude Fable 5,codex,0.35,0.011,30.19,0,0,51,0
dev,overall,29,Claude Fable 5,hermes,0.318,0.005,26.15,0,0,59,0
dev,overall,29,Claude Fable 5,openhands,0.337,0.013,26.64,0,0,40,0
dev,overall,29,Grok 4.7,claude-code,0.274,0.013,12.49,0,0,45,0
dev,overall,29,Grok 4.7,pi,0.353,0.029,5.35,0,0,35,0
dev,overall,29,Grok 4.7,opencode,0.307,0.03,10.3,0,0,32,0
dev,overall,29,Grok 4.7,agy,0.304,0.025,16.81,1,1,35,0
dev,overall,29,Grok 4.7,codex,0.267,0.011,6.85,0,0,34,0
dev,overall,29,Grok 4.7,hermes,0.311,0.001,10.95,0,0,51,0
dev,overall,29,Grok 4.7,openhands,0.272,0.007,10.72,0,0,33,0
dev,overall,29,Grok 4.7,grok-build,0.357,0.028,9.82,0,0,50,1
dev,overall,29,Gemini 3.8 Flash,claude-code,0.303,0.015,2.43,0,0,32,0
dev,overall,29,Gemini 3.8 Flash,pi,0.27,0.03,2.24,0,0,45,0
dev,overall,29,Gemini 3.8 Flash,opencode,0.261,0.008,2.06,0,0,24,0
dev,overall,29,Gemini 3.8 Flash,agy,0.243,0.023,2.68,0,0,39,1
dev,overall,29,Gemini 3.8 Flash,codex,0.272,0.025,3.56,0,0,48,0
dev,overall,29,Gemini 3.8 Flash,hermes,0.186,0.04,2.26,0,0,23,0
dev,overall,29,Gemini 3.8 Flash,openhands,0.265,0.01,3.2,0,0,31,0
dev,overall,29,GLM 5.2,claude-code,0.231,0.018,19.17,0,0,110,0
dev,overall,29,GLM 5.2,pi,0.213,0.011,16.25,0,0,129,0
dev,overall,29,GLM 5.2,opencode,0.252,0.023,,0,0,103,0
dev,overall,29,GLM 5.2,agy,0.214,0.016,12.71,1,0,87,0
dev,overall,29,GLM 5.2,codex,0.26,0.017,14.14,0,0,121,0
dev,overall,29,GLM 5.2,hermes,0.238,0.01,11.71,0,0,73,0
dev,overall,29,GLM 5.2,openhands,0.221,0.015,18.77,0,0,114,0
dev,overall,29,DeepSeek-V4.1-Flash,claude-code,0.128,0.034,3.71,0,0,231,0
dev,overall,29,DeepSeek-V4.1-Flash,pi,0.203,0.072,4.07,0,0,160,0
dev,overall,29,DeepSeek-V4.1-Flash,opencode,0.221,0.025,3.0,0,0,172,0
dev,overall,29,DeepSeek-V4.1-Flash,agy,0.08,0.015,3.5,1,0,228,0
dev,overall,29,DeepSeek-V4.1-Flash,codex,0.059,0.049,2.1,0,0,314,0
dev,overall,29,DeepSeek-V4.1-Flash,hermes,0.047,0.025,2.71,0,0,230,0
dev,overall,29,DeepSeek-V4.1-Flash,openhands,0.05,0.018,2.0,0,0,201,0
dev,overall,29,DeepSeek-V4.1-Flash,dsh,0.17,0.017,5.12,0,0,243,1
dev,overall,29,Gemini 3.1 Pro,claude-code,0.135,0.001,4.61,0,0,21,0
dev,overall,29,Gemini 3.1 Pro,pi,0.126,0.014,3.19,0,0,40,0
dev,overall,29,Gemini 3.1 Pro,opencode,0.118,0.004,2.91,0,0,14,0
dev,overall,29,Gemini 3.1 Pro,agy,0.135,0.025,2.7,0,0,17,1
dev,overall,29,Gemini 3.1 Pro,codex,0.133,0.019,4.4,0,0,24,0
dev,overall,29,Gemini 3.1 Pro,hermes,0.131,0.015,2.92,0,0,16,0
dev,overall,29,Gemini 3.1 Pro,openhands,0.126,0.007,6.93,0,0,20,0
dev,overall,29,Qwen3 Coder 480B,claude-code,0.046,0.006,0.11,0,0,8,0
dev,overall,29,Qwen3 Coder 480B,pi,0.045,0.005,0.12,0,0,8,0
dev,overall,29,Qwen3 Coder 480B,opencode,0.034,0.006,0.11,0,0,5,0
dev,overall,29,Qwen3 Coder 480B,agy,0.048,0.017,0.49,1,0,8,0
dev,overall,29,Qwen3 Coder 480B,codex,0.039,0.006,0.11,0,0,6,0
dev,overall,29,Qwen3 Coder 480B,hermes,0.061,0.008,0.16,0,0,8,0
dev,overall,29,Qwen3 Coder 480B,openhands,0.051,0.009,0.18,0,0,34,0
dev,overall,29,Kimi K2 Thinking,claude-code,0.041,0.008,0.26,0,0,7,0
dev,overall,29,Kimi K2 Thinking,pi,0.046,0.006,0.22,0,0,10,0
dev,overall,29,Kimi K2 Thinking,opencode,0.054,0.009,0.3,0,0,9,0
dev,overall,29,Kimi K2 Thinking,agy,0.04,0.007,0.29,1,0,18,0
dev,overall,29,Kimi K2 Thinking,codex,0.027,0.005,0.28,0,0,7,0
dev,overall,29,Kimi K2 Thinking,hermes,0.057,0.003,0.31,0,0,8,0
dev,overall,29,Kimi K2 Thinking,openhands,0.052,0.004,0.25,0,0,9,0
dev,overall,29,Gemma 4 26B,claude-code,0.035,0.008,0.5,0,0,101,0
dev,overall,29,Gemma 4 26B,pi,0.033,0.004,0.28,0,0,78,0
dev,overall,29,Gemma 4 26B,opencode,0.04,0.006,0.42,0,0,37,0
dev,overall,29,Gemma 4 26B,agy,0.052,0.013,0.21,1,0,95,1
dev,overall,29,Gemma 4 26B,codex,0.007,0.002,0.14,0,0,19,0
dev,overall,29,Gemma 4 26B,hermes,0.029,0.003,0.26,0,0,21,0
dev,overall,29,Gemma 4 26B,openhands,0.053,0.008,0.84,0,0,113,0
dev,overall,29,MiniMax M2,claude-code,0.046,0.009,0.12,0,0,14,0
dev,overall,29,MiniMax M2,pi,0.048,0.018,0.096,0,0,18,0
dev,overall,29,MiniMax M2,opencode,0.034,0.007,0.075,0,0,14,0
dev,overall,29,MiniMax M2,agy,0.042,0.006,0.33,1,0,12,0
dev,overall,29,MiniMax M2,codex,0.04,0.007,0.084,0,0,12,0
dev,overall,29,MiniMax M2,hermes,0.044,0.006,0.1,0,0,10,0
dev,overall,29,MiniMax M2,openhands,0.03,0.006,0.12,0,0,14,0
dev,overall,29,gpt-oss 120B,claude-code,0.042,0.003,0.096,0,0,48,0
dev,overall,29,gpt-oss 120B,pi,0.043,0.006,0.13,0,0,33,0
dev,overall,29,gpt-oss 120B,opencode,0.039,0.009,0.15,0,0,44,0
dev,overall,29,gpt-oss 120B,agy,0.036,0.011,,0,0,38,0
dev,overall,29,gpt-oss 120B,codex,0.038,0.004,0.21,0,0,55,1
dev,overall,29,gpt-oss 120B,hermes,0.045,0.006,0.17,0,0,58,0
dev,overall,29,gpt-oss 120B,openhands,0.036,0.011,0.15,0,0,60,0
dev,overall,29,Qwen3-Next 80B,claude-code,0.022,0.016,0.51,0,1,36,0
dev,overall,29,Qwen3-Next 80B,pi,0.014,0.005,0.99,0,1,52,0
dev,overall,29,Qwen3-Next 80B,opencode,0.016,0.005,0.27,0,1,58,0
dev,overall,29,Qwen3-Next 80B,agy,0.009,0.004,0.4,1,1,39,0
dev,overall,29,Qwen3-Next 80B,codex,0.025,0.002,0.43,0,1,36,0
dev,overall,29,Qwen3-Next 80B,hermes,0.017,0.008,0.45,0,1,55,0
dev,overall,29,Qwen3-Next 80B,openhands,0.026,0.003,0.5,0,1,61,0
dev,overall,29,Llama 4 Maverick,claude-code,0.004,0.003,0.084,0,1,2,0
dev,overall,29,Llama 4 Maverick,pi,0.007,0.002,0.09,0,1,1,0
dev,overall,29,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
dev,overall,29,Llama 4 Maverick,agy,0.001,0.002,0.06,1,1,4,0
dev,overall,29,Llama 4 Maverick,codex,0.0,0.0,0.086,0,1,2,0
dev,overall,29,Llama 4 Maverick,hermes,0.002,0.0,0.061,0,1,1,0
dev,overall,29,Llama 4 Maverick,openhands,0.007,0.005,0.19,0,1,2,0
dev,structural,4,Claude Sonnet 5.5,claude-code,0.317,0.01,22.61,0,0,101,1
dev,structural,4,Claude Sonnet 5.5,pi,0.326,0.01,11.51,0,0,84,0
dev,structural,4,Claude Sonnet 5.5,opencode,0.317,0.02,10.4,0,0,60,0
dev,structural,4,Claude Sonnet 5.5,agy,0.325,0.017,33.89,1,0,52,0
dev,structural,4,Claude Sonnet 5.5,codex,0.314,0.011,38.34,0,0,224,0
dev,structural,4,Claude Sonnet 5.5,hermes,0.289,0.046,14.82,0,0,83,0
dev,structural,4,Claude Sonnet 5.5,openhands,0.32,0.007,14.43,0,0,109,0
dev,structural,4,Gemini 4 Argon,claude-code,0.314,0.008,7.62,0,0,62,0
dev,structural,4,Gemini 4 Argon,pi,0.256,0.056,5.29,0,0,70,0
dev,structural,4,Gemini 4 Argon,opencode,0.325,0.007,6.49,0,0,50,0
dev,structural,4,Gemini 4 Argon,agy,0.323,0.015,6.36,0,0,63,1
dev,structural,4,Gemini 4 Argon,codex,0.316,0.009,7.0,0,0,85,0
dev,structural,4,Gemini 4 Argon,hermes,0.295,0.044,7.0,0,0,55,0
dev,structural,4,Gemini 4 Argon,openhands,0.255,0.055,7.23,0,0,78,0
dev,structural,4,Claude Opus 5.5,claude-code,0.32,0.003,17.3,0,0,63,1
dev,structural,4,Claude Opus 5.5,pi,0.307,0.012,13.29,0,0,71,0
dev,structural,4,Claude Opus 5.5,opencode,0.302,0.009,11.87,0,0,41,0
dev,structural,4,Claude Opus 5.5,agy,0.297,0.011,42.32,1,0,42,0
dev,structural,4,Claude Opus 5.5,codex,0.32,0.007,30.38,0,0,110,0
dev,structural,4,Claude Opus 5.5,hermes,0.311,0.012,17.17,0,0,70,0
dev,structural,4,Claude Opus 5.5,openhands,0.3,0.004,14.72,0,0,64,0
dev,structural,4,GPT 6 Astra,codex,0.311,0.006,8.42,0,0,24,1
dev,structural,4,Claude Opus 5,claude-code,0.292,0.005,18.53,0,0,51,1
dev,structural,4,Claude Opus 5,pi,0.299,0.007,14.65,0,0,57,0
dev,structural,4,Claude Opus 5,opencode,0.296,0.007,13.96,0,0,38,0
dev,structural,4,Claude Opus 5,agy,0.283,0.02,29.59,1,0,40,0
dev,structural,4,Claude Opus 5,codex,0.301,0.003,25.36,0,0,76,0
dev,structural,4,Claude Opus 5,hermes,0.3,0.008,15.05,0,0,53,0
dev,structural,4,Claude Opus 5,openhands,0.288,0.002,19.14,0,0,74,0
dev,structural,4,Claude Fable 5,claude-code,0.268,0.022,27.66,0,0,45,1
dev,structural,4,Claude Fable 5,pi,0.289,0.021,18.59,0,0,34,0
dev,structural,4,Claude Fable 5,opencode,0.278,0.007,22.87,0,0,36,0
dev,structural,4,Claude Fable 5,agy,0.271,0.009,54.19,1,0,35,0
dev,structural,4,Claude Fable 5,codex,0.276,0.013,30.19,0,0,51,0
dev,structural,4,Claude Fable 5,hermes,0.274,0.006,26.15,0,0,59,0
dev,structural,4,Claude Fable 5,openhands,0.287,0.008,26.64,0,0,40,0
dev,structural,4,Grok 4.7,claude-code,0.225,0.01,12.49,0,0,45,0
dev,structural,4,Grok 4.7,pi,0.236,0.021,5.35,0,0,35,0
dev,structural,4,Grok 4.7,opencode,0.229,0.015,10.3,0,0,32,0
dev,structural,4,Grok 4.7,agy,0.242,0.003,16.81,1,1,35,0
dev,structural,4,Grok 4.7,codex,0.243,0.008,6.85,0,0,34,0
dev,structural,4,Grok 4.7,hermes,0.208,0.011,10.95,0,0,51,0
dev,structural,4,Grok 4.7,openhands,0.23,0.024,10.72,0,0,33,0
dev,structural,4,Grok 4.7,grok-build,0.233,0.006,9.82,0,0,50,1
dev,structural,4,Gemini 3.8 Flash,claude-code,0.228,0.018,2.43,0,0,32,0
dev,structural,4,Gemini 3.8 Flash,pi,0.213,0.022,2.24,0,0,45,0
dev,structural,4,Gemini 3.8 Flash,opencode,0.229,0.02,2.06,0,0,24,0
dev,structural,4,Gemini 3.8 Flash,agy,0.226,0.008,2.68,0,0,39,1
dev,structural,4,Gemini 3.8 Flash,codex,0.242,0.012,3.56,0,0,48,0
dev,structural,4,Gemini 3.8 Flash,hermes,0.038,0.037,2.26,0,0,23,0
dev,structural,4,Gemini 3.8 Flash,openhands,0.218,0.006,3.2,0,0,31,0
dev,structural,4,GLM 5.2,claude-code,0.227,0.01,19.17,0,0,110,0
dev,structural,4,GLM 5.2,pi,0.172,0.014,16.25,0,0,129,0
dev,structural,4,GLM 5.2,opencode,0.179,0.031,,0,0,103,0
dev,structural,4,GLM 5.2,agy,0.199,0.006,12.71,1,0,87,0
dev,structural,4,GLM 5.2,codex,0.224,0.01,14.14,0,0,121,0
dev,structural,4,GLM 5.2,hermes,0.199,0.037,11.71,0,0,73,0
dev,structural,4,GLM 5.2,openhands,0.217,0.013,18.77,0,0,114,0
dev,structural,4,DeepSeek-V4.1-Flash,claude-code,0.0,0.0,3.71,0,0,231,0
dev,structural,4,DeepSeek-V4.1-Flash,pi,0.114,0.073,4.07,0,0,160,0
dev,structural,4,DeepSeek-V4.1-Flash,opencode,0.123,0.143,3.0,0,0,172,0
dev,structural,4,DeepSeek-V4.1-Flash,agy,0.0,0.0,3.5,1,0,228,0
dev,structural,4,DeepSeek-V4.1-Flash,codex,0.0,0.0,2.1,0,0,314,0
dev,structural,4,DeepSeek-V4.1-Flash,hermes,0.0,0.0,2.71,0,0,230,0
dev,structural,4,DeepSeek-V4.1-Flash,openhands,0.016,0.027,2.0,0,0,201,0
dev,structural,4,DeepSeek-V4.1-Flash,dsh,0.021,0.036,5.12,0,0,243,1
dev,structural,4,Gemini 3.1 Pro,claude-code,0.077,0.034,4.61,0,0,21,0
dev,structural,4,Gemini 3.1 Pro,pi,0.065,0.011,3.19,0,0,40,0
dev,structural,4,Gemini 3.1 Pro,opencode,0.078,0.021,2.91,0,0,14,0
dev,structural,4,Gemini 3.1 Pro,agy,0.057,0.024,2.7,0,0,17,1
dev,structural,4,Gemini 3.1 Pro,codex,0.074,0.005,4.4,0,0,24,0
dev,structural,4,Gemini 3.1 Pro,hermes,0.074,0.022,2.92,0,0,16,0
dev,structural,4,Gemini 3.1 Pro,openhands,0.091,0.028,6.93,0,0,20,0
dev,structural,4,Qwen3 Coder 480B,claude-code,0.016,0.008,0.11,0,0,8,0
dev,structural,4,Qwen3 Coder 480B,pi,0.041,0.011,0.12,0,0,8,0
dev,structural,4,Qwen3 Coder 480B,opencode,0.042,0.01,0.11,0,0,5,0
dev,structural,4,Qwen3 Coder 480B,agy,0.023,0.013,0.49,1,0,8,0
dev,structural,4,Qwen3 Coder 480B,codex,0.024,0.021,0.11,0,0,6,0
dev,structural,4,Qwen3 Coder 480B,hermes,0.05,0.014,0.16,0,0,8,0
dev,structural,4,Qwen3 Coder 480B,openhands,0.024,0.025,0.18,0,0,34,0
dev,structural,4,MiniMax M2,claude-code,0.019,0.02,0.12,0,0,14,0
dev,structural,4,MiniMax M2,pi,0.014,0.007,0.096,0,0,18,0
dev,structural,4,MiniMax M2,opencode,0.006,0.006,0.075,0,0,14,0
dev,structural,4,MiniMax M2,agy,0.008,0.014,0.33,1,0,12,0
dev,structural,4,MiniMax M2,codex,0.04,0.005,0.084,0,0,12,0
dev,structural,4,MiniMax M2,hermes,0.011,0.011,0.1,0,0,10,0
dev,structural,4,MiniMax M2,openhands,0.007,0.006,0.12,0,0,14,0
dev,structural,4,gpt-oss 120B,claude-code,0.022,0.003,0.096,0,0,48,0
dev,structural,4,gpt-oss 120B,pi,0.035,0.005,0.13,0,0,33,0
dev,structural,4,gpt-oss 120B,opencode,0.032,0.006,0.15,0,0,44,0
dev,structural,4,gpt-oss 120B,agy,0.034,0.004,,0,0,38,0
dev,structural,4,gpt-oss 120B,codex,0.004,0.006,0.21,0,0,55,1
dev,structural,4,gpt-oss 120B,hermes,0.028,0.012,0.17,0,0,58,0
dev,structural,4,gpt-oss 120B,openhands,0.026,0.011,0.15,0,0,60,0
dev,structural,4,Qwen3-Next 80B,claude-code,0.012,0.018,0.51,0,1,36,0
dev,structural,4,Qwen3-Next 80B,pi,0.004,0.006,0.99,0,1,52,0
dev,structural,4,Qwen3-Next 80B,opencode,0.0,0.0,0.27,0,1,58,0
dev,structural,4,Qwen3-Next 80B,agy,0.005,0.008,0.4,1,1,39,0
dev,structural,4,Qwen3-Next 80B,codex,0.028,0.002,0.43,0,1,36,0
dev,structural,4,Qwen3-Next 80B,hermes,0.016,0.027,0.45,0,1,55,0
dev,structural,4,Qwen3-Next 80B,openhands,0.001,0.002,0.5,0,1,61,0
dev,structural,4,Kimi K2 Thinking,claude-code,0.012,0.012,0.26,0,0,7,0
dev,structural,4,Kimi K2 Thinking,pi,0.018,0.011,0.22,0,0,10,0
dev,structural,4,Kimi K2 Thinking,opencode,0.023,0.02,0.3,0,0,9,0
dev,structural,4,Kimi K2 Thinking,agy,0.022,0.02,0.29,1,0,18,0
dev,structural,4,Kimi K2 Thinking,codex,0.025,0.016,0.28,0,0,7,0
dev,structural,4,Kimi K2 Thinking,hermes,0.013,0.016,0.31,0,0,8,0
dev,structural,4,Kimi K2 Thinking,openhands,0.01,0.01,0.25,0,0,9,0
dev,structural,4,Gemma 4 26B,claude-code,0.0,0.0,0.5,0,0,101,0
dev,structural,4,Gemma 4 26B,pi,0.0,0.0,0.28,0,0,78,0
dev,structural,4,Gemma 4 26B,opencode,0.0,0.0,0.42,0,0,37,0
dev,structural,4,Gemma 4 26B,agy,0.01,0.017,0.21,1,0,95,1
dev,structural,4,Gemma 4 26B,codex,0.0,0.0,0.14,0,0,19,0
dev,structural,4,Gemma 4 26B,hermes,0.0,0.0,0.26,0,0,21,0
dev,structural,4,Gemma 4 26B,openhands,0.014,0.013,0.84,0,0,113,0
dev,structural,4,Llama 4 Maverick,claude-code,0.0,0.0,0.084,0,1,2,0
dev,structural,4,Llama 4 Maverick,pi,0.005,0.009,0.09,0,1,1,0
dev,structural,4,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
dev,structural,4,Llama 4 Maverick,agy,0.0,0.0,0.06,1,1,4,0
dev,structural,4,Llama 4 Maverick,codex,0.0,0.0,0.086,0,1,2,0
dev,structural,4,Llama 4 Maverick,hermes,0.0,0.0,0.061,0,1,1,0
dev,structural,4,Llama 4 Maverick,openhands,0.005,0.009,0.19,0,1,2,0
dev,civil,9,Claude Opus 5.5,claude-code,0.695,0.053,17.3,0,0,63,1
dev,civil,9,Claude Opus 5.5,pi,0.59,0.072,13.29,0,0,71,0
dev,civil,9,Claude Opus 5.5,opencode,0.619,0.091,11.87,0,0,41,0
dev,civil,9,Claude Opus 5.5,agy,0.621,0.08,42.32,1,0,42,0
dev,civil,9,Claude Opus 5.5,codex,0.72,0.018,30.38,0,0,110,0
dev,civil,9,Claude Opus 5.5,hermes,0.682,0.059,17.17,0,0,70,0
dev,civil,9,Claude Opus 5.5,openhands,0.701,0.045,14.72,0,0,64,0
dev,civil,9,Claude Opus 5,claude-code,0.57,0.021,18.53,0,0,51,1
dev,civil,9,Claude Opus 5,pi,0.572,0.076,14.65,0,0,57,0
dev,civil,9,Claude Opus 5,opencode,0.446,0.027,13.96,0,0,38,0
dev,civil,9,Claude Opus 5,agy,0.649,0.03,29.59,1,0,40,0
dev,civil,9,Claude Opus 5,codex,0.542,0.071,25.36,0,0,76,0
dev,civil,9,Claude Opus 5,hermes,0.499,0.036,15.05,0,0,53,0
dev,civil,9,Claude Opus 5,openhands,0.537,0.032,19.14,0,0,74,0
dev,civil,9,Gemini 4 Argon,claude-code,0.573,0.019,7.62,0,0,62,0
dev,civil,9,Gemini 4 Argon,pi,0.515,0.088,5.29,0,0,70,0
dev,civil,9,Gemini 4 Argon,opencode,0.49,0.013,6.49,0,0,50,0
dev,civil,9,Gemini 4 Argon,agy,0.514,0.007,6.36,0,0,63,1
dev,civil,9,Gemini 4 Argon,codex,0.491,0.052,7.0,0,0,85,0
dev,civil,9,Gemini 4 Argon,hermes,0.549,0.033,7.0,0,0,55,0
dev,civil,9,Gemini 4 Argon,openhands,0.403,0.097,7.23,0,0,78,0
dev,civil,9,Claude Sonnet 5.5,claude-code,0.542,0.012,22.61,0,0,101,1
dev,civil,9,Claude Sonnet 5.5,pi,0.498,0.019,11.51,0,0,84,0
dev,civil,9,Claude Sonnet 5.5,opencode,0.48,0.051,10.4,0,0,60,0
dev,civil,9,Claude Sonnet 5.5,agy,0.549,0.046,33.89,1,0,52,0
dev,civil,9,Claude Sonnet 5.5,codex,0.547,0.026,38.34,0,0,224,0
dev,civil,9,Claude Sonnet 5.5,hermes,0.531,0.06,14.82,0,0,83,0
dev,civil,9,Claude Sonnet 5.5,openhands,0.564,0.008,14.43,0,0,109,0
dev,civil,9,GPT 6 Astra,codex,0.534,0.019,8.42,0,0,24,1
dev,civil,9,Claude Fable 5,claude-code,0.444,0.058,27.66,0,0,45,1
dev,civil,9,Claude Fable 5,pi,0.425,0.107,18.59,0,0,34,0
dev,civil,9,Claude Fable 5,opencode,0.481,0.064,22.87,0,0,36,0
dev,civil,9,Claude Fable 5,agy,0.501,0.093,54.19,1,0,35,0
dev,civil,9,Claude Fable 5,codex,0.501,0.025,30.19,0,0,51,0
dev,civil,9,Claude Fable 5,hermes,0.433,0.054,26.15,0,0,59,0
dev,civil,9,Claude Fable 5,openhands,0.456,0.018,26.64,0,0,40,0
dev,civil,9,Grok 4.7,claude-code,0.301,0.028,12.49,0,0,45,0
dev,civil,9,Grok 4.7,pi,0.495,0.012,5.35,0,0,35,0
dev,civil,9,Grok 4.7,opencode,0.412,0.03,10.3,0,0,32,0
dev,civil,9,Grok 4.7,agy,0.429,0.128,16.81,1,1,35,0
dev,civil,9,Grok 4.7,codex,0.43,0.049,6.85,0,0,34,0
dev,civil,9,Grok 4.7,hermes,0.424,0.034,10.95,0,0,51,0
dev,civil,9,Grok 4.7,openhands,0.487,0.061,10.72,0,0,33,0
dev,civil,9,Grok 4.7,grok-build,0.47,0.055,9.82,0,0,50,1
dev,civil,9,Gemini 3.8 Flash,claude-code,0.411,0.022,2.43,0,0,32,0
dev,civil,9,Gemini 3.8 Flash,pi,0.342,0.069,2.24,0,0,45,0
dev,civil,9,Gemini 3.8 Flash,opencode,0.308,0.066,2.06,0,0,24,0
dev,civil,9,Gemini 3.8 Flash,agy,0.293,0.081,2.68,0,0,39,1
dev,civil,9,Gemini 3.8 Flash,codex,0.361,0.054,3.56,0,0,48,0
dev,civil,9,Gemini 3.8 Flash,hermes,0.305,0.097,2.26,0,0,23,0
dev,civil,9,Gemini 3.8 Flash,openhands,0.371,0.027,3.2,0,0,31,0
dev,civil,9,GLM 5.2,claude-code,0.295,0.039,19.17,0,0,110,0
dev,civil,9,GLM 5.2,pi,0.265,0.062,16.25,0,0,129,0
dev,civil,9,GLM 5.2,opencode,0.321,0.053,,0,0,103,0
dev,civil,9,GLM 5.2,agy,0.237,0.025,12.71,1,0,87,0
dev,civil,9,GLM 5.2,codex,0.348,0.026,14.14,0,0,121,0
dev,civil,9,GLM 5.2,hermes,0.312,0.026,11.71,0,0,73,0
dev,civil,9,GLM 5.2,openhands,0.276,0.078,18.77,0,0,114,0
dev,civil,9,DeepSeek-V4.1-Flash,claude-code,0.198,0.066,3.71,0,0,231,0
dev,civil,9,DeepSeek-V4.1-Flash,pi,0.263,0.117,4.07,0,0,160,0
dev,civil,9,DeepSeek-V4.1-Flash,opencode,0.327,0.086,3.0,0,0,172,0
dev,civil,9,DeepSeek-V4.1-Flash,agy,0.129,0.063,3.5,1,0,228,0
dev,civil,9,DeepSeek-V4.1-Flash,codex,0.074,0.032,2.1,0,0,314,0
dev,civil,9,DeepSeek-V4.1-Flash,hermes,0.101,0.069,2.71,0,0,230,0
dev,civil,9,DeepSeek-V4.1-Flash,openhands,0.079,0.022,2.0,0,0,201,0
dev,civil,9,DeepSeek-V4.1-Flash,dsh,0.262,0.036,5.12,0,0,243,1
dev,civil,9,Gemini 3.1 Pro,claude-code,0.147,0.01,4.61,0,0,21,0
dev,civil,9,Gemini 3.1 Pro,pi,0.177,0.014,3.19,0,0,40,0
dev,civil,9,Gemini 3.1 Pro,opencode,0.152,0.019,2.91,0,0,14,0
dev,civil,9,Gemini 3.1 Pro,agy,0.173,0.019,2.7,0,0,17,1
dev,civil,9,Gemini 3.1 Pro,codex,0.164,0.026,4.4,0,0,24,0
dev,civil,9,Gemini 3.1 Pro,hermes,0.184,0.043,2.92,0,0,16,0
dev,civil,9,Gemini 3.1 Pro,openhands,0.149,0.017,6.93,0,0,20,0
dev,civil,9,Gemma 4 26B,claude-code,0.054,0.007,0.5,0,0,101,0
dev,civil,9,Gemma 4 26B,pi,0.056,0.006,0.28,0,0,78,0
dev,civil,9,Gemma 4 26B,opencode,0.08,0.019,0.42,0,0,37,0
dev,civil,9,Gemma 4 26B,agy,0.099,0.03,0.21,1,0,95,1
dev,civil,9,Gemma 4 26B,codex,0.015,0.013,0.14,0,0,19,0
dev,civil,9,Gemma 4 26B,hermes,0.041,0.017,0.26,0,0,21,0
dev,civil,9,Gemma 4 26B,openhands,0.083,0.01,0.84,0,0,113,0
dev,civil,9,MiniMax M2,claude-code,0.065,0.025,0.12,0,0,14,0
dev,civil,9,MiniMax M2,pi,0.08,0.036,0.096,0,0,18,0
dev,civil,9,MiniMax M2,opencode,0.036,0.007,0.075,0,0,14,0
dev,civil,9,MiniMax M2,agy,0.064,0.013,0.33,1,0,12,0
dev,civil,9,MiniMax M2,codex,0.062,0.023,0.084,0,0,12,0
dev,civil,9,MiniMax M2,hermes,0.063,0.014,0.1,0,0,10,0
dev,civil,9,MiniMax M2,openhands,0.066,0.017,0.12,0,0,14,0
dev,civil,9,Qwen3 Coder 480B,claude-code,0.046,0.011,0.11,0,0,8,0
dev,civil,9,Qwen3 Coder 480B,pi,0.044,0.011,0.12,0,0,8,0
dev,civil,9,Qwen3 Coder 480B,opencode,0.024,0.008,0.11,0,0,5,0
dev,civil,9,Qwen3 Coder 480B,agy,0.033,0.002,0.49,1,0,8,0
dev,civil,9,Qwen3 Coder 480B,codex,0.058,0.012,0.11,0,0,6,0
dev,civil,9,Qwen3 Coder 480B,hermes,0.075,0.017,0.16,0,0,8,0
dev,civil,9,Qwen3 Coder 480B,openhands,0.068,0.007,0.18,0,0,34,0
dev,civil,9,gpt-oss 120B,claude-code,0.066,0.005,0.096,0,0,48,0
dev,civil,9,gpt-oss 120B,pi,0.044,0.015,0.13,0,0,33,0
dev,civil,9,gpt-oss 120B,opencode,0.042,0.009,0.15,0,0,44,0
dev,civil,9,gpt-oss 120B,agy,0.052,0.011,,0,0,38,0
dev,civil,9,gpt-oss 120B,codex,0.05,0.011,0.21,0,0,55,1
dev,civil,9,gpt-oss 120B,hermes,0.068,0.004,0.17,0,0,58,0
dev,civil,9,gpt-oss 120B,openhands,0.048,0.014,0.15,0,0,60,0
dev,civil,9,Kimi K2 Thinking,claude-code,0.057,0.012,0.26,0,0,7,0
dev,civil,9,Kimi K2 Thinking,pi,0.066,0.015,0.22,0,0,10,0
dev,civil,9,Kimi K2 Thinking,opencode,0.056,0.013,0.3,0,0,9,0
dev,civil,9,Kimi K2 Thinking,agy,0.039,0.019,0.29,1,0,18,0
dev,civil,9,Kimi K2 Thinking,codex,0.026,0.017,0.28,0,0,7,0
dev,civil,9,Kimi K2 Thinking,hermes,0.066,0.017,0.31,0,0,8,0
dev,civil,9,Kimi K2 Thinking,openhands,0.064,0.016,0.25,0,0,9,0
dev,civil,9,Qwen3-Next 80B,claude-code,0.022,0.003,0.51,0,1,36,0
dev,civil,9,Qwen3-Next 80B,pi,0.034,0.008,0.99,0,1,52,0
dev,civil,9,Qwen3-Next 80B,opencode,0.026,0.006,0.27,0,1,58,0
dev,civil,9,Qwen3-Next 80B,agy,0.017,0.007,0.4,1,1,39,0
dev,civil,9,Qwen3-Next 80B,codex,0.036,0.017,0.43,0,1,36,0
dev,civil,9,Qwen3-Next 80B,hermes,0.016,0.008,0.45,0,1,55,0
dev,civil,9,Qwen3-Next 80B,openhands,0.045,0.011,0.5,0,1,61,0
dev,civil,9,Llama 4 Maverick,claude-code,0.006,0.005,0.084,0,1,2,0
dev,civil,9,Llama 4 Maverick,pi,0.008,0.003,0.09,0,1,1,0
dev,civil,9,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
dev,civil,9,Llama 4 Maverick,agy,0.001,0.002,0.06,1,1,4,0
dev,civil,9,Llama 4 Maverick,codex,0.001,0.001,0.086,0,1,2,0
dev,civil,9,Llama 4 Maverick,hermes,0.006,0.0,0.061,0,1,1,0
dev,civil,9,Llama 4 Maverick,openhands,0.011,0.01,0.19,0,1,2,0
dev,electrical,9,GPT 6 Astra,codex,0.682,0.042,8.42,0,0,24,1
dev,electrical,9,Claude Opus 5.5,claude-code,0.654,0.067,17.3,0,0,63,1
dev,electrical,9,Claude Opus 5.5,pi,0.496,0.062,13.29,0,0,71,0
dev,electrical,9,Claude Opus 5.5,opencode,0.561,0.009,11.87,0,0,41,0
dev,electrical,9,Claude Opus 5.5,agy,0.547,0.028,42.32,1,0,42,0
dev,electrical,9,Claude Opus 5.5,codex,0.624,0.028,30.38,0,0,110,0
dev,electrical,9,Claude Opus 5.5,hermes,0.577,0.035,17.17,0,0,70,0
dev,electrical,9,Claude Opus 5.5,openhands,0.558,0.045,14.72,0,0,64,0
dev,electrical,9,Gemini 4 Argon,claude-code,0.54,0.059,7.62,0,0,62,0
dev,electrical,9,Gemini 4 Argon,pi,0.589,0.033,5.29,0,0,70,0
dev,electrical,9,Gemini 4 Argon,opencode,0.43,0.022,6.49,0,0,50,0
dev,electrical,9,Gemini 4 Argon,agy,0.539,0.026,6.36,0,0,63,1
dev,electrical,9,Gemini 4 Argon,codex,0.49,0.007,7.0,0,0,85,0
dev,electrical,9,Gemini 4 Argon,hermes,0.495,0.08,7.0,0,0,55,0
dev,electrical,9,Gemini 4 Argon,openhands,0.369,0.043,7.23,0,0,78,0
dev,electrical,9,Claude Sonnet 5.5,claude-code,0.481,0.06,22.61,0,0,101,1
dev,electrical,9,Claude Sonnet 5.5,pi,0.488,0.066,11.51,0,0,84,0
dev,electrical,9,Claude Sonnet 5.5,opencode,0.468,0.029,10.4,0,0,60,0
dev,electrical,9,Claude Sonnet 5.5,agy,0.538,0.044,33.89,1,0,52,0
dev,electrical,9,Claude Sonnet 5.5,codex,0.429,0.087,38.34,0,0,224,0
dev,electrical,9,Claude Sonnet 5.5,hermes,0.455,0.11,14.82,0,0,83,0
dev,electrical,9,Claude Sonnet 5.5,openhands,0.48,0.054,14.43,0,0,109,0
dev,electrical,9,Claude Opus 5,claude-code,0.457,0.046,18.53,0,0,51,1
dev,electrical,9,Claude Opus 5,pi,0.354,0.048,14.65,0,0,57,0
dev,electrical,9,Claude Opus 5,opencode,0.47,0.052,13.96,0,0,38,0
dev,electrical,9,Claude Opus 5,agy,0.379,0.021,29.59,1,0,40,0
dev,electrical,9,Claude Opus 5,codex,0.401,0.043,25.36,0,0,76,0
dev,electrical,9,Claude Opus 5,hermes,0.388,0.008,15.05,0,0,53,0
dev,electrical,9,Claude Opus 5,openhands,0.425,0.05,19.14,0,0,74,0
dev,electrical,9,Claude Fable 5,claude-code,0.376,0.075,27.66,0,0,45,1
dev,electrical,9,Claude Fable 5,pi,0.192,0.02,18.59,0,0,34,0
dev,electrical,9,Claude Fable 5,opencode,0.322,0.036,22.87,0,0,36,0
dev,electrical,9,Claude Fable 5,agy,0.302,0.037,54.19,1,0,35,0
dev,electrical,9,Claude Fable 5,codex,0.289,0.025,30.19,0,0,51,0
dev,electrical,9,Claude Fable 5,hermes,0.25,0.033,26.15,0,0,59,0
dev,electrical,9,Claude Fable 5,openhands,0.299,0.052,26.64,0,0,40,0
dev,electrical,9,Grok 4.7,claude-code,0.335,0.053,12.49,0,0,45,0
dev,electrical,9,Grok 4.7,pi,0.338,0.097,5.35,0,0,35,0
dev,electrical,9,Grok 4.7,opencode,0.3,0.05,10.3,0,0,32,0
dev,electrical,9,Grok 4.7,agy,0.302,0.059,16.81,1,1,35,0
dev,electrical,9,Grok 4.7,codex,0.15,0.011,6.85,0,0,34,0
dev,electrical,9,Grok 4.7,hermes,0.321,0.021,10.95,0,0,51,0
dev,electrical,9,Grok 4.7,openhands,0.113,0.034,10.72,0,0,33,0
dev,electrical,9,Grok 4.7,grok-build,0.376,0.031,9.82,0,0,50,1
dev,electrical,9,GLM 5.2,claude-code,0.214,0.031,19.17,0,0,110,0
dev,electrical,9,GLM 5.2,pi,0.183,0.026,16.25,0,0,129,0
dev,electrical,9,GLM 5.2,opencode,0.254,0.027,,0,0,103,0
dev,electrical,9,GLM 5.2,agy,0.211,0.043,12.71,1,0,87,0
dev,electrical,9,GLM 5.2,codex,0.237,0.044,14.14,0,0,121,0
dev,electrical,9,GLM 5.2,hermes,0.211,0.027,11.71,0,0,73,0
dev,electrical,9,GLM 5.2,openhands,0.196,0.055,18.77,0,0,114,0
dev,electrical,9,Gemini 3.8 Flash,claude-code,0.197,0.024,2.43,0,0,32,0
dev,electrical,9,Gemini 3.8 Flash,pi,0.231,0.019,2.24,0,0,45,0
dev,electrical,9,Gemini 3.8 Flash,opencode,0.214,0.006,2.06,0,0,24,0
dev,electrical,9,Gemini 3.8 Flash,agy,0.222,0.019,2.68,0,0,39,1
dev,electrical,9,Gemini 3.8 Flash,codex,0.213,0.002,3.56,0,0,48,0
dev,electrical,9,Gemini 3.8 Flash,hermes,0.145,0.029,2.26,0,0,23,0
dev,electrical,9,Gemini 3.8 Flash,openhands,0.224,0.019,3.2,0,0,31,0
dev,electrical,9,DeepSeek-V4.1-Flash,claude-code,0.162,0.01,3.71,0,0,231,0
dev,electrical,9,DeepSeek-V4.1-Flash,pi,0.203,0.051,4.07,0,0,160,0
dev,electrical,9,DeepSeek-V4.1-Flash,opencode,0.222,0.042,3.0,0,0,172,0
dev,electrical,9,DeepSeek-V4.1-Flash,agy,0.079,0.042,3.5,1,0,228,0
dev,electrical,9,DeepSeek-V4.1-Flash,codex,0.084,0.1,2.1,0,0,314,0
dev,electrical,9,DeepSeek-V4.1-Flash,hermes,0.046,0.046,2.71,0,0,230,0
dev,electrical,9,DeepSeek-V4.1-Flash,openhands,0.068,0.042,2.0,0,0,201,0
dev,electrical,9,DeepSeek-V4.1-Flash,dsh,0.19,0.015,5.12,0,0,243,1
dev,electrical,9,Gemini 3.1 Pro,claude-code,0.148,0.031,4.61,0,0,21,0
dev,electrical,9,Gemini 3.1 Pro,pi,0.113,0.019,3.19,0,0,40,0
dev,electrical,9,Gemini 3.1 Pro,opencode,0.128,0.016,2.91,0,0,14,0
dev,electrical,9,Gemini 3.1 Pro,agy,0.159,0.057,2.7,0,0,17,1
dev,electrical,9,Gemini 3.1 Pro,codex,0.133,0.024,4.4,0,0,24,0
dev,electrical,9,Gemini 3.1 Pro,hermes,0.123,0.01,2.92,0,0,16,0
dev,electrical,9,Gemini 3.1 Pro,openhands,0.13,0.026,6.93,0,0,20,0
dev,electrical,9,Qwen3 Coder 480B,claude-code,0.07,0.019,0.11,0,0,8,0
dev,electrical,9,Qwen3 Coder 480B,pi,0.052,0.009,0.12,0,0,8,0
dev,electrical,9,Qwen3 Coder 480B,opencode,0.052,0.026,0.11,0,0,5,0
dev,electrical,9,Qwen3 Coder 480B,agy,0.094,0.05,0.49,1,0,8,0
dev,electrical,9,Qwen3 Coder 480B,codex,0.041,0.019,0.11,0,0,6,0
dev,electrical,9,Qwen3 Coder 480B,hermes,0.079,0.025,0.16,0,0,8,0
dev,electrical,9,Qwen3 Coder 480B,openhands,0.052,0.017,0.18,0,0,34,0
dev,electrical,9,Kimi K2 Thinking,claude-code,0.061,0.012,0.26,0,0,7,0
dev,electrical,9,Kimi K2 Thinking,pi,0.063,0.004,0.22,0,0,10,0
dev,electrical,9,Kimi K2 Thinking,opencode,0.078,0.023,0.3,0,0,9,0
dev,electrical,9,Kimi K2 Thinking,agy,0.065,0.001,0.29,1,0,18,0
dev,electrical,9,Kimi K2 Thinking,codex,0.033,0.013,0.28,0,0,7,0
dev,electrical,9,Kimi K2 Thinking,hermes,0.091,0.007,0.31,0,0,8,0
dev,electrical,9,Kimi K2 Thinking,openhands,0.086,0.022,0.25,0,0,9,0
dev,electrical,9,Gemma 4 26B,claude-code,0.045,0.011,0.5,0,0,101,0
dev,electrical,9,Gemma 4 26B,pi,0.038,0.019,0.28,0,0,78,0
dev,electrical,9,Gemma 4 26B,opencode,0.03,0.018,0.42,0,0,37,0
dev,electrical,9,Gemma 4 26B,agy,0.04,0.008,0.21,1,0,95,1
dev,electrical,9,Gemma 4 26B,codex,0.006,0.008,0.14,0,0,19,0
dev,electrical,9,Gemma 4 26B,hermes,0.031,0.024,0.26,0,0,21,0
dev,electrical,9,Gemma 4 26B,openhands,0.068,0.017,0.84,0,0,113,0
dev,electrical,9,gpt-oss 120B,claude-code,0.03,0.007,0.096,0,0,48,0
dev,electrical,9,gpt-oss 120B,pi,0.065,0.005,0.13,0,0,33,0
dev,electrical,9,gpt-oss 120B,opencode,0.048,0.013,0.15,0,0,44,0
dev,electrical,9,gpt-oss 120B,agy,0.034,0.014,,0,0,38,0
dev,electrical,9,gpt-oss 120B,codex,0.051,0.019,0.21,0,0,55,1
dev,electrical,9,gpt-oss 120B,hermes,0.045,0.019,0.17,0,0,58,0
dev,electrical,9,gpt-oss 120B,openhands,0.038,0.025,0.15,0,0,60,0
dev,electrical,9,MiniMax M2,claude-code,0.058,0.009,0.12,0,0,14,0
dev,electrical,9,MiniMax M2,pi,0.051,0.017,0.096,0,0,18,0
dev,electrical,9,MiniMax M2,opencode,0.062,0.015,0.075,0,0,14,0
dev,electrical,9,MiniMax M2,agy,0.057,0.029,0.33,1,0,12,0
dev,electrical,9,MiniMax M2,codex,0.042,0.009,0.084,0,0,12,0
dev,electrical,9,MiniMax M2,hermes,0.052,0.013,0.1,0,0,10,0
dev,electrical,9,MiniMax M2,openhands,0.008,0.009,0.12,0,0,14,0
dev,electrical,9,Qwen3-Next 80B,claude-code,0.038,0.035,0.51,0,1,36,0
dev,electrical,9,Qwen3-Next 80B,pi,0.003,0.004,0.99,0,1,52,0
dev,electrical,9,Qwen3-Next 80B,opencode,0.02,0.011,0.27,0,1,58,0
dev,electrical,9,Qwen3-Next 80B,agy,0.009,0.009,0.4,1,1,39,0
dev,electrical,9,Qwen3-Next 80B,codex,0.027,0.022,0.43,0,1,36,0
dev,electrical,9,Qwen3-Next 80B,hermes,0.032,0.029,0.45,0,1,55,0
dev,electrical,9,Qwen3-Next 80B,openhands,0.035,0.005,0.5,0,1,61,0
dev,electrical,9,Llama 4 Maverick,claude-code,0.006,0.004,0.084,0,1,2,0
dev,electrical,9,Llama 4 Maverick,pi,0.011,0.007,0.09,0,1,1,0
dev,electrical,9,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
dev,electrical,9,Llama 4 Maverick,agy,0.002,0.004,0.06,1,1,4,0
dev,electrical,9,Llama 4 Maverick,codex,0.0,0.0,0.086,0,1,2,0
dev,electrical,9,Llama 4 Maverick,hermes,0.0,0.0,0.061,0,1,1,0
dev,electrical,9,Llama 4 Maverick,openhands,0.01,0.004,0.19,0,1,2,0
dev,mechanical,7,GPT 6 Astra,codex,0.453,0.019,8.42,0,0,24,1
dev,mechanical,7,Claude Opus 5.5,claude-code,0.367,0.019,17.3,0,0,63,1
dev,mechanical,7,Claude Opus 5.5,pi,0.393,0.051,13.29,0,0,71,0
dev,mechanical,7,Claude Opus 5.5,opencode,0.35,0.007,11.87,0,0,41,0
dev,mechanical,7,Claude Opus 5.5,agy,0.384,0.02,42.32,1,0,42,0
dev,mechanical,7,Claude Opus 5.5,codex,0.363,0.01,30.38,0,0,110,0
dev,mechanical,7,Claude Opus 5.5,hermes,0.381,0.03,17.17,0,0,70,0
dev,mechanical,7,Claude Opus 5.5,openhands,0.384,0.012,14.72,0,0,64,0
dev,mechanical,7,Gemini 4 Argon,claude-code,0.349,0.093,7.62,0,0,62,0
dev,mechanical,7,Gemini 4 Argon,pi,0.385,0.058,5.29,0,0,70,0
dev,mechanical,7,Gemini 4 Argon,opencode,0.315,0.049,6.49,0,0,50,0
dev,mechanical,7,Gemini 4 Argon,agy,0.281,0.022,6.36,0,0,63,1
dev,mechanical,7,Gemini 4 Argon,codex,0.342,0.078,7.0,0,0,85,0
dev,mechanical,7,Gemini 4 Argon,hermes,0.37,0.061,7.0,0,0,55,0
dev,mechanical,7,Gemini 4 Argon,openhands,0.313,0.185,7.23,0,0,78,0
dev,mechanical,7,Claude Opus 5,claude-code,0.263,0.026,18.53,0,0,51,1
dev,mechanical,7,Claude Opus 5,pi,0.202,0.101,14.65,0,0,57,0
dev,mechanical,7,Claude Opus 5,opencode,0.257,0.016,13.96,0,0,38,0
dev,mechanical,7,Claude Opus 5,agy,0.366,0.096,29.59,1,0,40,0
dev,mechanical,7,Claude Opus 5,codex,0.222,0.018,25.36,0,0,76,0
dev,mechanical,7,Claude Opus 5,hermes,0.266,0.013,15.05,0,0,53,0
dev,mechanical,7,Claude Opus 5,openhands,0.276,0.044,19.14,0,0,74,0
dev,mechanical,7,Claude Sonnet 5.5,claude-code,0.319,0.007,22.61,0,0,101,1
dev,mechanical,7,Claude Sonnet 5.5,pi,0.297,0.07,11.51,0,0,84,0
dev,mechanical,7,Claude Sonnet 5.5,opencode,0.333,0.042,10.4,0,0,60,0
dev,mechanical,7,Claude Sonnet 5.5,agy,0.321,0.021,33.89,1,0,52,0
dev,mechanical,7,Claude Sonnet 5.5,codex,0.302,0.06,38.34,0,0,224,0
dev,mechanical,7,Claude Sonnet 5.5,hermes,0.264,0.081,14.82,0,0,83,0
dev,mechanical,7,Claude Sonnet 5.5,openhands,0.334,0.018,14.43,0,0,109,0
dev,mechanical,7,Claude Fable 5,claude-code,0.268,0.017,27.66,0,0,45,1
dev,mechanical,7,Claude Fable 5,pi,0.315,0.042,18.59,0,0,34,0
dev,mechanical,7,Claude Fable 5,opencode,0.269,0.01,22.87,0,0,36,0
dev,mechanical,7,Claude Fable 5,agy,0.327,0.081,54.19,1,0,35,0
dev,mechanical,7,Claude Fable 5,codex,0.276,0.003,30.19,0,0,51,0
dev,mechanical,7,Claude Fable 5,hermes,0.283,0.029,26.15,0,0,59,0
dev,mechanical,7,Claude Fable 5,openhands,0.261,0.032,26.64,0,0,40,0
dev,mechanical,7,Gemini 3.8 Flash,claude-code,0.275,0.047,2.43,0,0,32,0
dev,mechanical,7,Gemini 3.8 Flash,pi,0.261,0.058,2.24,0,0,45,0
dev,mechanical,7,Gemini 3.8 Flash,opencode,0.279,0.057,2.06,0,0,24,0
dev,mechanical,7,Gemini 3.8 Flash,agy,0.216,0.005,2.68,0,0,39,1
dev,mechanical,7,Gemini 3.8 Flash,codex,0.25,0.034,3.56,0,0,48,0
dev,mechanical,7,Gemini 3.8 Flash,hermes,0.17,0.017,2.26,0,0,23,0
dev,mechanical,7,Gemini 3.8 Flash,openhands,0.21,0.033,3.2,0,0,31,0
dev,mechanical,7,Grok 4.7,claude-code,0.187,0.01,12.49,0,0,45,0
dev,mechanical,7,Grok 4.7,pi,0.257,0.024,5.35,0,0,35,0
dev,mechanical,7,Grok 4.7,opencode,0.223,0.033,10.3,0,0,32,0
dev,mechanical,7,Grok 4.7,agy,0.183,0.037,16.81,1,1,35,0
dev,mechanical,7,Grok 4.7,codex,0.221,0.012,6.85,0,0,34,0
dev,mechanical,7,Grok 4.7,hermes,0.212,0.028,10.95,0,0,51,0
dev,mechanical,7,Grok 4.7,openhands,0.223,0.026,10.72,0,0,33,0
dev,mechanical,7,Grok 4.7,grok-build,0.26,0.073,9.82,0,0,50,1
dev,mechanical,7,GLM 5.2,claude-code,0.175,0.016,19.17,0,0,110,0
dev,mechanical,7,GLM 5.2,pi,0.209,0.004,16.25,0,0,129,0
dev,mechanical,7,GLM 5.2,opencode,0.202,0.005,,0,0,103,0
dev,mechanical,7,GLM 5.2,agy,0.196,0.008,12.71,1,0,87,0
dev,mechanical,7,GLM 5.2,codex,0.196,0.002,14.14,0,0,121,0
dev,mechanical,7,GLM 5.2,hermes,0.202,0.033,11.71,0,0,73,0
dev,mechanical,7,GLM 5.2,openhands,0.184,0.005,18.77,0,0,114,0
dev,mechanical,7,DeepSeek-V4.1-Flash,claude-code,0.086,0.039,3.71,0,0,231,0
dev,mechanical,7,DeepSeek-V4.1-Flash,pi,0.178,0.055,4.07,0,0,160,0
dev,mechanical,7,DeepSeek-V4.1-Flash,opencode,0.119,0.08,3.0,0,0,172,0
dev,mechanical,7,DeepSeek-V4.1-Flash,agy,0.063,0.04,3.5,1,0,228,0
dev,mechanical,7,DeepSeek-V4.1-Flash,codex,0.043,0.043,2.1,0,0,314,0
dev,mechanical,7,DeepSeek-V4.1-Flash,hermes,0.007,0.012,2.71,0,0,230,0
dev,mechanical,7,DeepSeek-V4.1-Flash,openhands,0.009,0.016,2.0,0,0,201,0
dev,mechanical,7,DeepSeek-V4.1-Flash,dsh,0.109,0.052,5.12,0,0,243,1
dev,mechanical,7,Gemini 3.1 Pro,claude-code,0.135,0.019,4.61,0,0,21,0
dev,mechanical,7,Gemini 3.1 Pro,pi,0.113,0.031,3.19,0,0,40,0
dev,mechanical,7,Gemini 3.1 Pro,opencode,0.085,0.026,2.91,0,0,14,0
dev,mechanical,7,Gemini 3.1 Pro,agy,0.1,0.005,2.7,0,0,17,1
dev,mechanical,7,Gemini 3.1 Pro,codex,0.124,0.015,4.4,0,0,24,0
dev,mechanical,7,Gemini 3.1 Pro,hermes,0.104,0.014,2.92,0,0,16,0
dev,mechanical,7,Gemini 3.1 Pro,openhands,0.112,0.005,6.93,0,0,20,0
dev,mechanical,7,Qwen3 Coder 480B,claude-code,0.034,0.021,0.11,0,0,8,0
dev,mechanical,7,Qwen3 Coder 480B,pi,0.038,0.009,0.12,0,0,8,0
dev,mechanical,7,Qwen3 Coder 480B,opencode,0.017,0.014,0.11,0,0,5,0
dev,mechanical,7,Qwen3 Coder 480B,agy,0.023,0.011,0.49,1,0,8,0
dev,mechanical,7,Qwen3 Coder 480B,codex,0.02,0.004,0.11,0,0,6,0
dev,mechanical,7,Qwen3 Coder 480B,hermes,0.027,0.015,0.16,0,0,8,0
dev,mechanical,7,Qwen3 Coder 480B,openhands,0.043,0.012,0.18,0,0,34,0
dev,mechanical,7,gpt-oss 120B,claude-code,0.039,0.005,0.096,0,0,48,0
dev,mechanical,7,gpt-oss 120B,pi,0.019,0.009,0.13,0,0,33,0
dev,mechanical,7,gpt-oss 120B,opencode,0.028,0.028,0.15,0,0,44,0
dev,mechanical,7,gpt-oss 120B,agy,0.021,0.013,,0,0,38,0
dev,mechanical,7,gpt-oss 120B,codex,0.027,0.012,0.21,0,0,55,1
dev,mechanical,7,gpt-oss 120B,hermes,0.025,0.007,0.17,0,0,58,0
dev,mechanical,7,gpt-oss 120B,openhands,0.024,0.009,0.15,0,0,60,0
dev,mechanical,7,Kimi K2 Thinking,claude-code,0.012,0.005,0.26,0,0,7,0
dev,mechanical,7,Kimi K2 Thinking,pi,0.012,0.004,0.22,0,0,10,0
dev,mechanical,7,Kimi K2 Thinking,opencode,0.034,0.024,0.3,0,0,9,0
dev,mechanical,7,Kimi K2 Thinking,agy,0.021,0.013,0.29,1,0,18,0
dev,mechanical,7,Kimi K2 Thinking,codex,0.02,0.011,0.28,0,0,7,0
dev,mechanical,7,Kimi K2 Thinking,hermes,0.026,0.002,0.31,0,0,8,0
dev,mechanical,7,Kimi K2 Thinking,openhands,0.018,0.017,0.25,0,0,9,0
dev,mechanical,7,MiniMax M2,claude-code,0.023,0.003,0.12,0,0,14,0
dev,mechanical,7,MiniMax M2,pi,0.019,0.019,0.096,0,0,18,0
dev,mechanical,7,MiniMax M2,opencode,0.012,0.004,0.075,0,0,14,0
dev,mechanical,7,MiniMax M2,agy,0.013,0.005,0.33,1,0,12,0
dev,mechanical,7,MiniMax M2,codex,0.011,0.005,0.084,0,0,12,0
dev,mechanical,7,MiniMax M2,hermes,0.029,0.003,0.1,0,0,10,0
dev,mechanical,7,MiniMax M2,openhands,0.024,0.02,0.12,0,0,14,0
dev,mechanical,7,Gemma 4 26B,claude-code,0.021,0.019,0.5,0,0,101,0
dev,mechanical,7,Gemma 4 26B,pi,0.016,0.003,0.28,0,0,78,0
dev,mechanical,7,Gemma 4 26B,opencode,0.023,0.011,0.42,0,0,37,0
dev,mechanical,7,Gemma 4 26B,agy,0.029,0.002,0.21,1,0,95,1
dev,mechanical,7,Gemma 4 26B,codex,0.003,0.006,0.14,0,0,19,0
dev,mechanical,7,Gemma 4 26B,hermes,0.029,0.001,0.26,0,0,21,0
dev,mechanical,7,Gemma 4 26B,openhands,0.017,0.021,0.84,0,0,113,0
dev,mechanical,7,Qwen3-Next 80B,claude-code,0.007,0.006,0.51,0,1,36,0
dev,mechanical,7,Qwen3-Next 80B,pi,0.007,0.002,0.99,0,1,52,0
dev,mechanical,7,Qwen3-Next 80B,opencode,0.006,0.006,0.27,0,1,58,0
dev,mechanical,7,Qwen3-Next 80B,agy,0.003,0.004,0.4,1,1,39,0
dev,mechanical,7,Qwen3-Next 80B,codex,0.008,0.001,0.43,0,1,36,0
dev,mechanical,7,Qwen3-Next 80B,hermes,0.005,0.007,0.45,0,1,55,0
dev,mechanical,7,Qwen3-Next 80B,openhands,0.004,0.003,0.5,0,1,61,0
dev,mechanical,7,Llama 4 Maverick,claude-code,0.0,0.0,0.084,0,1,2,0
dev,mechanical,7,Llama 4 Maverick,pi,0.001,0.001,0.09,0,1,1,0
dev,mechanical,7,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
dev,mechanical,7,Llama 4 Maverick,agy,0.0,0.0,0.06,1,1,4,0
dev,mechanical,7,Llama 4 Maverick,codex,0.0,0.0,0.086,0,1,2,0
dev,mechanical,7,Llama 4 Maverick,hermes,0.0,0.0,0.061,0,1,1,0
dev,mechanical,7,Llama 4 Maverick,openhands,0.0,0.0,0.19,0,1,2,0
all,overall,85,Claude Opus 5.5,pi,0.473,0.018,13.33,0,0,69,0
all,overall,85,Claude Opus 5.5,claude-code,0.506,0.014,17.18,0,0,63,1
all,overall,85,Claude Opus 5.5,opencode,0.474,0.004,12.53,0,0,46,0
all,overall,85,Claude Opus 5.5,agy,0.484,0.015,42.32,1,0,44,0
all,overall,85,Claude Opus 5.5,openhands,0.499,0.017,14.82,0,0,65,0
all,overall,85,Claude Opus 5.5,codex,0.493,0.011,35.15,0,0,123,0
all,overall,85,Claude Opus 5.5,hermes,0.486,0.003,16.42,0,0,67,0
all,overall,85,GPT 6 Astra,codex,0.483,0.005,9.15,0,0,25,1
all,overall,85,Claude Sonnet 5.5,pi,0.435,0.015,11.68,0,0,92,0
all,overall,85,Claude Sonnet 5.5,claude-code,0.436,0.002,20.02,0,0,100,1
all,overall,85,Claude Sonnet 5.5,opencode,0.423,0.006,10.48,0,0,62,0
all,overall,85,Claude Sonnet 5.5,agy,0.452,0.007,33.89,1,0,52,0
all,overall,85,Claude Sonnet 5.5,openhands,0.422,0.012,15.28,0,0,111,0
all,overall,85,Claude Sonnet 5.5,codex,0.427,0.021,41.12,0,0,236,0
all,overall,85,Claude Sonnet 5.5,hermes,0.437,0.03,14.75,0,0,86,0
all,overall,85,Gemini 4 Argon,pi,0.402,0.011,6.41,0,0,75,0
all,overall,85,Gemini 4 Argon,claude-code,0.432,0.017,8.21,0,0,66,0
all,overall,85,Gemini 4 Argon,opencode,0.384,0.008,6.86,0,0,53,0
all,overall,85,Gemini 4 Argon,agy,0.417,0.01,7.24,0,0,70,1
all,overall,85,Gemini 4 Argon,openhands,0.311,0.023,7.43,0,0,82,0
all,overall,85,Gemini 4 Argon,codex,0.403,0.006,7.09,0,0,84,0
all,overall,85,Gemini 4 Argon,hermes,0.411,0.012,7.61,0,0,59,0
all,overall,85,Claude Opus 5,pi,0.404,0.013,15.06,0,0,58,0
all,overall,85,Claude Opus 5,claude-code,0.408,0.01,17.21,0,0,49,1
all,overall,85,Claude Opus 5,opencode,0.398,0.009,13.0,0,0,38,0
all,overall,85,Claude Opus 5,agy,0.426,0.016,29.59,1,0,42,0
all,overall,85,Claude Opus 5,openhands,0.419,0.004,17.82,0,0,69,0
all,overall,85,Claude Opus 5,codex,0.388,0.015,22.33,0,0,71,0
all,overall,85,Claude Opus 5,hermes,0.396,0.015,14.29,0,0,52,0
all,overall,85,Claude Fable 5,pi,0.33,0.0,20.29,0,0,43,0
all,overall,85,Claude Fable 5,claude-code,0.349,0.015,26.87,0,0,45,1
all,overall,85,Claude Fable 5,opencode,0.345,0.012,22.92,0,0,37,0
all,overall,85,Claude Fable 5,agy,0.338,0.009,54.19,1,0,37,0
all,overall,85,Claude Fable 5,openhands,0.334,0.006,26.11,0,0,43,0
all,overall,85,Claude Fable 5,codex,0.347,0.012,29.25,0,0,57,0
all,overall,85,Claude Fable 5,hermes,0.328,0.006,24.93,0,0,56,0
all,overall,85,Grok 4.7,pi,0.319,0.009,7.1,0,0,38,0
all,overall,85,Grok 4.7,claude-code,0.268,0.012,12.66,0,0,47,0
all,overall,85,Grok 4.7,opencode,0.292,0.021,10.27,0,0,33,0
all,overall,85,Grok 4.7,agy,0.287,0.008,16.81,1,1,34,0
all,overall,85,Grok 4.7,openhands,0.274,0.012,9.51,0,0,33,0
all,overall,85,Grok 4.7,codex,0.262,0.011,6.96,0,0,38,0
all,overall,85,Grok 4.7,hermes,0.275,0.014,10.38,0,0,48,0
all,overall,85,Grok 4.7,grok-build,0.32,0.013,10.06,0,0,52,1
all,overall,85,Gemini 3.8 Flash,pi,0.269,0.02,2.53,0,0,43,0
all,overall,85,Gemini 3.8 Flash,claude-code,0.282,0.003,2.55,0,0,34,0
all,overall,85,Gemini 3.8 Flash,opencode,0.26,0.002,2.32,0,0,25,0
all,overall,85,Gemini 3.8 Flash,agy,0.264,0.007,2.63,0,0,40,1
all,overall,85,Gemini 3.8 Flash,openhands,0.276,0.006,3.21,0,0,32,0
all,overall,85,Gemini 3.8 Flash,codex,0.276,0.008,3.59,0,0,46,0
all,overall,85,Gemini 3.8 Flash,hermes,0.178,0.026,2.35,0,0,23,0
all,overall,85,GLM 5.2,pi,0.238,0.006,14.55,0,0,116,0
all,overall,85,GLM 5.2,claude-code,0.223,0.004,16.28,0,0,100,0
all,overall,85,GLM 5.2,opencode,0.244,0.007,,0,0,98,0
all,overall,85,GLM 5.2,agy,0.23,0.005,12.71,1,0,86,0
all,overall,85,GLM 5.2,openhands,0.229,0.003,16.62,0,0,108,0
all,overall,85,GLM 5.2,codex,0.253,0.012,13.11,0,0,121,0
all,overall,85,GLM 5.2,hermes,0.239,0.009,11.13,0,0,71,0
all,overall,85,DeepSeek-V4.1-Flash,pi,0.218,0.045,4.38,0,0,166,0
all,overall,85,DeepSeek-V4.1-Flash,claude-code,0.12,0.005,3.73,0,0,238,0
all,overall,85,DeepSeek-V4.1-Flash,opencode,0.224,0.023,3.27,0,0,171,0
all,overall,85,DeepSeek-V4.1-Flash,agy,0.088,0.014,3.5,1,0,228,0
all,overall,85,DeepSeek-V4.1-Flash,openhands,0.058,0.014,1.77,0,0,196,0
all,overall,85,DeepSeek-V4.1-Flash,codex,0.047,0.027,2.09,0,0,301,0
all,overall,85,DeepSeek-V4.1-Flash,hermes,0.051,0.019,2.89,0,0,246,0
all,overall,85,DeepSeek-V4.1-Flash,dsh,0.153,0.01,5.9,0,0,241,1
all,overall,85,Gemini 3.1 Pro,pi,0.136,0.003,2.91,0,0,30,0
all,overall,85,Gemini 3.1 Pro,claude-code,0.141,0.004,3.98,0,0,19,0
all,overall,85,Gemini 3.1 Pro,opencode,0.133,0.002,2.75,0,0,15,0
all,overall,85,Gemini 3.1 Pro,agy,0.137,0.016,2.55,0,0,16,1
all,overall,85,Gemini 3.1 Pro,openhands,0.14,0.01,5.44,0,0,17,0
all,overall,85,Gemini 3.1 Pro,codex,0.141,0.007,3.35,0,0,18,0
all,overall,85,Gemini 3.1 Pro,hermes,0.142,0.006,2.38,0,0,13,0
all,overall,85,Qwen3 Coder 480B,pi,0.043,0.004,0.14,0,0,10,0
all,overall,85,Qwen3 Coder 480B,claude-code,0.056,0.001,0.13,0,0,9,0
all,overall,85,Qwen3 Coder 480B,opencode,0.041,0.002,0.2,0,0,7,0
all,overall,85,Qwen3 Coder 480B,agy,0.045,0.005,0.49,1,0,7,0
all,overall,85,Qwen3 Coder 480B,openhands,0.057,0.003,0.2,0,0,30,0
all,overall,85,Qwen3 Coder 480B,codex,0.044,0.002,0.11,0,0,6,0
all,overall,85,Qwen3 Coder 480B,hermes,0.062,0.001,0.13,0,0,8,0
all,overall,85,Kimi K2 Thinking,pi,0.042,0.003,0.21,0,0,9,0
all,overall,85,Kimi K2 Thinking,claude-code,0.044,0.011,0.25,0,0,7,0
all,overall,85,Kimi K2 Thinking,opencode,0.059,0.004,0.29,0,0,9,0
all,overall,85,Kimi K2 Thinking,agy,0.035,0.002,0.29,1,0,18,0
all,overall,85,Kimi K2 Thinking,openhands,0.047,0.006,0.25,0,0,11,0
all,overall,85,Kimi K2 Thinking,codex,0.03,0.007,0.27,0,0,8,0
all,overall,85,Kimi K2 Thinking,hermes,0.052,0.005,0.29,0,0,8,0
all,overall,85,MiniMax M2,pi,0.047,0.005,0.094,0,0,14,0
all,overall,85,MiniMax M2,claude-code,0.053,0.007,0.11,0,0,13,0
all,overall,85,MiniMax M2,opencode,0.039,0.005,0.078,0,0,14,0
all,overall,85,MiniMax M2,agy,0.037,0.003,0.33,1,0,12,0
all,overall,85,MiniMax M2,openhands,0.045,0.002,0.12,0,0,14,0
all,overall,85,MiniMax M2,codex,0.044,0.003,0.09,0,0,14,0
all,overall,85,MiniMax M2,hermes,0.053,0.002,0.099,0,0,10,0
all,overall,85,Gemma 4 26B,pi,0.037,0.002,0.29,0,0,82,0
all,overall,85,Gemma 4 26B,claude-code,0.037,0.004,0.52,0,0,92,0
all,overall,85,Gemma 4 26B,opencode,0.032,0.003,0.44,0,0,42,0
all,overall,85,Gemma 4 26B,agy,0.045,0.003,0.21,1,0,95,1
all,overall,85,Gemma 4 26B,openhands,0.047,0.003,0.68,0,0,111,0
all,overall,85,Gemma 4 26B,codex,0.007,0.002,0.18,0,0,22,0
all,overall,85,Gemma 4 26B,hermes,0.022,0.002,0.28,0,0,23,0
all,overall,85,gpt-oss 120B,pi,0.041,0.004,0.12,0,0,29,0
all,overall,85,gpt-oss 120B,claude-code,0.042,0.002,0.11,0,0,46,0
all,overall,85,gpt-oss 120B,opencode,0.037,0.005,0.16,0,0,46,0
all,overall,85,gpt-oss 120B,agy,0.04,0.003,,0,0,37,0
all,overall,85,gpt-oss 120B,openhands,0.042,0.009,0.15,0,0,55,0
all,overall,85,gpt-oss 120B,codex,0.038,0.002,0.19,0,0,48,1
all,overall,85,gpt-oss 120B,hermes,0.039,0.003,0.16,0,0,52,0
all,overall,85,Qwen3-Next 80B,pi,0.022,0.003,1.03,0,1,56,0
all,overall,85,Qwen3-Next 80B,claude-code,0.025,0.008,0.53,0,1,41,0
all,overall,85,Qwen3-Next 80B,opencode,0.022,0.003,0.45,0,1,66,0
all,overall,85,Qwen3-Next 80B,agy,0.013,0.004,0.4,1,1,40,0
all,overall,85,Qwen3-Next 80B,openhands,0.037,0.001,0.68,0,1,82,0
all,overall,85,Qwen3-Next 80B,codex,0.015,0.004,0.52,0,1,36,0
all,overall,85,Qwen3-Next 80B,hermes,0.018,0.003,0.42,0,1,50,0
all,overall,85,Llama 4 Maverick,pi,0.007,0.003,0.26,0,1,1,0
all,overall,85,Llama 4 Maverick,claude-code,0.004,0.001,0.07,0,1,1,0
all,overall,85,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
all,overall,85,Llama 4 Maverick,agy,0.001,0.001,0.06,1,1,3,0
all,overall,85,Llama 4 Maverick,openhands,0.007,0.002,0.18,0,1,2,0
all,overall,85,Llama 4 Maverick,codex,0.0,0.0,0.093,0,1,2,0
all,overall,85,Llama 4 Maverick,hermes,0.001,0.0,0.051,0,1,1,0
all,structural,10,Claude Opus 5.5,pi,0.45,0.023,13.33,0,0,69,0
all,structural,10,Claude Opus 5.5,claude-code,0.466,0.037,17.18,0,0,63,1
all,structural,10,Claude Opus 5.5,opencode,0.444,0.037,12.53,0,0,46,0
all,structural,10,Claude Opus 5.5,agy,0.416,0.044,42.32,1,0,44,0
all,structural,10,Claude Opus 5.5,openhands,0.466,0.007,14.82,0,0,65,0
all,structural,10,Claude Opus 5.5,codex,0.438,0.045,35.15,0,0,123,0
all,structural,10,Claude Opus 5.5,hermes,0.408,0.016,16.42,0,0,67,0
all,structural,10,Claude Sonnet 5.5,pi,0.424,0.033,11.68,0,0,92,0
all,structural,10,Claude Sonnet 5.5,claude-code,0.411,0.045,20.02,0,0,100,1
all,structural,10,Claude Sonnet 5.5,opencode,0.44,0.004,10.48,0,0,62,0
all,structural,10,Claude Sonnet 5.5,agy,0.431,0.01,33.89,1,0,52,0
all,structural,10,Claude Sonnet 5.5,openhands,0.438,0.01,15.28,0,0,111,0
all,structural,10,Claude Sonnet 5.5,codex,0.405,0.007,41.12,0,0,236,0
all,structural,10,Claude Sonnet 5.5,hermes,0.426,0.051,14.75,0,0,86,0
all,structural,10,Claude Opus 5,pi,0.427,0.007,15.06,0,0,58,0
all,structural,10,Claude Opus 5,claude-code,0.401,0.03,17.21,0,0,49,1
all,structural,10,Claude Opus 5,opencode,0.411,0.041,13.0,0,0,38,0
all,structural,10,Claude Opus 5,agy,0.425,0.062,29.59,1,0,42,0
all,structural,10,Claude Opus 5,openhands,0.428,0.031,17.82,0,0,69,0
all,structural,10,Claude Opus 5,codex,0.434,0.014,22.33,0,0,71,0
all,structural,10,Claude Opus 5,hermes,0.418,0.063,14.29,0,0,52,0
all,structural,10,GPT 6 Astra,codex,0.415,0.01,9.15,0,0,25,1
all,structural,10,Claude Fable 5,pi,0.397,0.056,20.29,0,0,43,0
all,structural,10,Claude Fable 5,claude-code,0.35,0.074,26.87,0,0,45,1
all,structural,10,Claude Fable 5,opencode,0.349,0.027,22.92,0,0,37,0
all,structural,10,Claude Fable 5,agy,0.334,0.033,54.19,1,0,37,0
all,structural,10,Claude Fable 5,openhands,0.407,0.006,26.11,0,0,43,0
all,structural,10,Claude Fable 5,codex,0.398,0.048,29.25,0,0,57,0
all,structural,10,Claude Fable 5,hermes,0.377,0.027,24.93,0,0,56,0
all,structural,10,Gemini 4 Argon,pi,0.354,0.028,6.41,0,0,75,0
all,structural,10,Gemini 4 Argon,claude-code,0.395,0.042,8.21,0,0,66,0
all,structural,10,Gemini 4 Argon,opencode,0.393,0.04,6.86,0,0,53,0
all,structural,10,Gemini 4 Argon,agy,0.404,0.017,7.24,0,0,70,1
all,structural,10,Gemini 4 Argon,openhands,0.295,0.027,7.43,0,0,82,0
all,structural,10,Gemini 4 Argon,codex,0.366,0.086,7.09,0,0,84,0
all,structural,10,Gemini 4 Argon,hermes,0.348,0.03,7.61,0,0,59,0
all,structural,10,Gemini 3.8 Flash,pi,0.24,0.015,2.53,0,0,43,0
all,structural,10,Gemini 3.8 Flash,claude-code,0.287,0.06,2.55,0,0,34,0
all,structural,10,Gemini 3.8 Flash,opencode,0.244,0.041,2.32,0,0,25,0
all,structural,10,Gemini 3.8 Flash,agy,0.253,0.017,2.63,0,0,40,1
all,structural,10,Gemini 3.8 Flash,openhands,0.291,0.004,3.21,0,0,32,0
all,structural,10,Gemini 3.8 Flash,codex,0.267,0.032,3.59,0,0,46,0
all,structural,10,Gemini 3.8 Flash,hermes,0.085,0.025,2.35,0,0,23,0
all,structural,10,Grok 4.7,pi,0.289,0.017,7.1,0,0,38,0
all,structural,10,Grok 4.7,claude-code,0.249,0.012,12.66,0,0,47,0
all,structural,10,Grok 4.7,opencode,0.265,0.009,10.27,0,0,33,0
all,structural,10,Grok 4.7,agy,0.255,0.005,16.81,1,1,34,0
all,structural,10,Grok 4.7,openhands,0.256,0.012,9.51,0,0,33,0
all,structural,10,Grok 4.7,codex,0.255,0.016,6.96,0,0,38,0
all,structural,10,Grok 4.7,hermes,0.231,0.011,10.38,0,0,48,0
all,structural,10,Grok 4.7,grok-build,0.263,0.006,10.06,0,0,52,1
all,structural,10,GLM 5.2,pi,0.226,0.012,14.55,0,0,116,0
all,structural,10,GLM 5.2,claude-code,0.23,0.012,16.28,0,0,100,0
all,structural,10,GLM 5.2,opencode,0.234,0.007,,0,0,98,0
all,structural,10,GLM 5.2,agy,0.213,0.023,12.71,1,0,86,0
all,structural,10,GLM 5.2,openhands,0.213,0.017,16.62,0,0,108,0
all,structural,10,GLM 5.2,codex,0.25,0.019,13.11,0,0,121,0
all,structural,10,GLM 5.2,hermes,0.229,0.025,11.13,0,0,71,0
all,structural,10,DeepSeek-V4.1-Flash,pi,0.174,0.012,4.38,0,0,166,0
all,structural,10,DeepSeek-V4.1-Flash,claude-code,0.02,0.018,3.73,0,0,238,0
all,structural,10,DeepSeek-V4.1-Flash,opencode,0.226,0.096,3.27,0,0,171,0
all,structural,10,DeepSeek-V4.1-Flash,agy,0.01,0.017,3.5,1,0,228,0
all,structural,10,DeepSeek-V4.1-Flash,openhands,0.006,0.011,1.77,0,0,196,0
all,structural,10,DeepSeek-V4.1-Flash,codex,0.012,0.021,2.09,0,0,301,0
all,structural,10,DeepSeek-V4.1-Flash,hermes,0.0,0.0,2.89,0,0,246,0
all,structural,10,DeepSeek-V4.1-Flash,dsh,0.018,0.008,5.9,0,0,241,1
all,structural,10,Gemini 3.1 Pro,pi,0.097,0.018,2.91,0,0,30,0
all,structural,10,Gemini 3.1 Pro,claude-code,0.108,0.005,3.98,0,0,19,0
all,structural,10,Gemini 3.1 Pro,opencode,0.1,0.004,2.75,0,0,15,0
all,structural,10,Gemini 3.1 Pro,agy,0.07,0.004,2.55,0,0,16,1
all,structural,10,Gemini 3.1 Pro,openhands,0.095,0.015,5.44,0,0,17,0
all,structural,10,Gemini 3.1 Pro,codex,0.098,0.016,3.35,0,0,18,0
all,structural,10,Gemini 3.1 Pro,hermes,0.1,0.013,2.38,0,0,13,0
all,structural,10,Kimi K2 Thinking,pi,0.007,0.004,0.21,0,0,9,0
all,structural,10,Kimi K2 Thinking,claude-code,0.006,0.003,0.25,0,0,7,0
all,structural,10,Kimi K2 Thinking,opencode,0.037,0.001,0.29,0,0,9,0
all,structural,10,Kimi K2 Thinking,agy,0.009,0.009,0.29,1,0,18,0
all,structural,10,Kimi K2 Thinking,openhands,0.004,0.004,0.25,0,0,11,0
all,structural,10,Kimi K2 Thinking,codex,0.016,0.009,0.27,0,0,8,0
all,structural,10,Kimi K2 Thinking,hermes,0.012,0.004,0.29,0,0,8,0
all,structural,10,Qwen3 Coder 480B,pi,0.022,0.013,0.14,0,0,10,0
all,structural,10,Qwen3 Coder 480B,claude-code,0.019,0.004,0.13,0,0,9,0
all,structural,10,Qwen3 Coder 480B,opencode,0.018,0.003,0.2,0,0,7,0
all,structural,10,Qwen3 Coder 480B,agy,0.013,0.003,0.49,1,0,7,0
all,structural,10,Qwen3 Coder 480B,openhands,0.028,0.007,0.2,0,0,30,0
all,structural,10,Qwen3 Coder 480B,codex,0.022,0.007,0.11,0,0,6,0
all,structural,10,Qwen3 Coder 480B,hermes,0.036,0.013,0.13,0,0,8,0
all,structural,10,MiniMax M2,pi,0.013,0.011,0.094,0,0,14,0
all,structural,10,MiniMax M2,claude-code,0.024,0.014,0.11,0,0,13,0
all,structural,10,MiniMax M2,opencode,0.002,0.002,0.078,0,0,14,0
all,structural,10,MiniMax M2,agy,0.005,0.004,0.33,1,0,12,0
all,structural,10,MiniMax M2,openhands,0.004,0.004,0.12,0,0,14,0
all,structural,10,MiniMax M2,codex,0.033,0.01,0.09,0,0,14,0
all,structural,10,MiniMax M2,hermes,0.018,0.015,0.099,0,0,10,0
all,structural,10,gpt-oss 120B,pi,0.023,0.001,0.12,0,0,29,0
all,structural,10,gpt-oss 120B,claude-code,0.012,0.002,0.11,0,0,46,0
all,structural,10,gpt-oss 120B,opencode,0.019,0.004,0.16,0,0,46,0
all,structural,10,gpt-oss 120B,agy,0.02,0.004,,0,0,37,0
all,structural,10,gpt-oss 120B,openhands,0.021,0.012,0.15,0,0,55,0
all,structural,10,gpt-oss 120B,codex,0.011,0.004,0.19,0,0,48,1
all,structural,10,gpt-oss 120B,hermes,0.022,0.006,0.16,0,0,52,0
all,structural,10,Qwen3-Next 80B,pi,0.001,0.002,1.03,0,1,56,0
all,structural,10,Qwen3-Next 80B,claude-code,0.011,0.018,0.53,0,1,41,0
all,structural,10,Qwen3-Next 80B,opencode,0.0,0.0,0.45,0,1,66,0
all,structural,10,Qwen3-Next 80B,agy,0.002,0.003,0.4,1,1,40,0
all,structural,10,Qwen3-Next 80B,openhands,0.007,0.006,0.68,0,1,82,0
all,structural,10,Qwen3-Next 80B,codex,0.015,0.006,0.52,0,1,36,0
all,structural,10,Qwen3-Next 80B,hermes,0.005,0.009,0.42,0,1,50,0
all,structural,10,Gemma 4 26B,pi,0.001,0.002,0.29,0,0,82,0
all,structural,10,Gemma 4 26B,claude-code,0.0,0.001,0.52,0,0,92,0
all,structural,10,Gemma 4 26B,opencode,0.0,0.001,0.44,0,0,42,0
all,structural,10,Gemma 4 26B,agy,0.008,0.012,0.21,1,0,95,1
all,structural,10,Gemma 4 26B,openhands,0.006,0.005,0.68,0,0,111,0
all,structural,10,Gemma 4 26B,codex,0.0,0.0,0.18,0,0,22,0
all,structural,10,Gemma 4 26B,hermes,0.0,0.0,0.28,0,0,23,0
all,structural,10,Llama 4 Maverick,pi,0.002,0.003,0.26,0,1,1,0
all,structural,10,Llama 4 Maverick,claude-code,0.0,0.0,0.07,0,1,1,0
all,structural,10,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
all,structural,10,Llama 4 Maverick,agy,0.0,0.0,0.06,1,1,3,0
all,structural,10,Llama 4 Maverick,openhands,0.002,0.003,0.18,0,1,2,0
all,structural,10,Llama 4 Maverick,codex,0.0,0.0,0.093,0,1,2,0
all,structural,10,Llama 4 Maverick,hermes,0.0,0.0,0.051,0,1,1,0
all,civil,18,Claude Opus 5.5,pi,0.607,0.06,13.33,0,0,69,0
all,civil,18,Claude Opus 5.5,claude-code,0.699,0.04,17.18,0,0,63,1
all,civil,18,Claude Opus 5.5,opencode,0.621,0.015,12.53,0,0,46,0
all,civil,18,Claude Opus 5.5,agy,0.621,0.036,42.32,1,0,44,0
all,civil,18,Claude Opus 5.5,openhands,0.67,0.069,14.82,0,0,65,0
all,civil,18,Claude Opus 5.5,codex,0.678,0.01,35.15,0,0,123,0
all,civil,18,Claude Opus 5.5,hermes,0.651,0.007,16.42,0,0,67,0
all,civil,18,Claude Sonnet 5.5,pi,0.538,0.039,11.68,0,0,92,0
all,civil,18,Claude Sonnet 5.5,claude-code,0.531,0.009,20.02,0,0,100,1
all,civil,18,Claude Sonnet 5.5,opencode,0.5,0.035,10.48,0,0,62,0
all,civil,18,Claude Sonnet 5.5,agy,0.556,0.015,33.89,1,0,52,0
all,civil,18,Claude Sonnet 5.5,openhands,0.517,0.022,15.28,0,0,111,0
all,civil,18,Claude Sonnet 5.5,codex,0.531,0.044,41.12,0,0,236,0
all,civil,18,Claude Sonnet 5.5,hermes,0.544,0.083,14.75,0,0,86,0
all,civil,18,GPT 6 Astra,codex,0.555,0.025,9.15,0,0,25,1
all,civil,18,Claude Opus 5,pi,0.501,0.011,15.06,0,0,58,0
all,civil,18,Claude Opus 5,claude-code,0.516,0.052,17.21,0,0,49,1
all,civil,18,Claude Opus 5,opencode,0.451,0.045,13.0,0,0,38,0
all,civil,18,Claude Opus 5,agy,0.552,0.02,29.59,1,0,42,0
all,civil,18,Claude Opus 5,openhands,0.531,0.03,17.82,0,0,69,0
all,civil,18,Claude Opus 5,codex,0.468,0.038,22.33,0,0,71,0
all,civil,18,Claude Opus 5,hermes,0.471,0.049,14.29,0,0,52,0
all,civil,18,Gemini 4 Argon,pi,0.509,0.034,6.41,0,0,75,0
all,civil,18,Gemini 4 Argon,claude-code,0.544,0.034,8.21,0,0,66,0
all,civil,18,Gemini 4 Argon,opencode,0.48,0.023,6.86,0,0,53,0
all,civil,18,Gemini 4 Argon,agy,0.526,0.026,7.24,0,0,70,1
all,civil,18,Gemini 4 Argon,openhands,0.347,0.076,7.43,0,0,82,0
all,civil,18,Gemini 4 Argon,codex,0.518,0.049,7.09,0,0,84,0
all,civil,18,Gemini 4 Argon,hermes,0.515,0.025,7.61,0,0,59,0
all,civil,18,Claude Fable 5,pi,0.37,0.043,20.29,0,0,43,0
all,civil,18,Claude Fable 5,claude-code,0.418,0.065,26.87,0,0,45,1
all,civil,18,Claude Fable 5,opencode,0.403,0.065,22.92,0,0,37,0
all,civil,18,Claude Fable 5,agy,0.41,0.031,54.19,1,0,37,0
all,civil,18,Claude Fable 5,openhands,0.391,0.016,26.11,0,0,43,0
all,civil,18,Claude Fable 5,codex,0.426,0.033,29.25,0,0,57,0
all,civil,18,Claude Fable 5,hermes,0.373,0.025,24.93,0,0,56,0
all,civil,18,Grok 4.7,pi,0.42,0.043,7.1,0,0,38,0
all,civil,18,Grok 4.7,claude-code,0.281,0.023,12.66,0,0,47,0
all,civil,18,Grok 4.7,opencode,0.386,0.034,10.27,0,0,33,0
all,civil,18,Grok 4.7,agy,0.375,0.06,16.81,1,1,34,0
all,civil,18,Grok 4.7,openhands,0.387,0.059,9.51,0,0,33,0
all,civil,18,Grok 4.7,codex,0.372,0.04,6.96,0,0,38,0
all,civil,18,Grok 4.7,hermes,0.361,0.026,10.38,0,0,48,0
all,civil,18,Grok 4.7,grok-build,0.421,0.056,10.06,0,0,52,1
all,civil,18,Gemini 3.8 Flash,pi,0.315,0.048,2.53,0,0,43,0
all,civil,18,Gemini 3.8 Flash,claude-code,0.348,0.032,2.55,0,0,34,0
all,civil,18,Gemini 3.8 Flash,opencode,0.282,0.039,2.32,0,0,25,0
all,civil,18,Gemini 3.8 Flash,agy,0.305,0.007,2.63,0,0,40,1
all,civil,18,Gemini 3.8 Flash,openhands,0.34,0.024,3.21,0,0,32,0
all,civil,18,Gemini 3.8 Flash,codex,0.331,0.059,3.59,0,0,46,0
all,civil,18,Gemini 3.8 Flash,hermes,0.245,0.07,2.35,0,0,23,0
all,civil,18,GLM 5.2,pi,0.264,0.031,14.55,0,0,116,0
all,civil,18,GLM 5.2,claude-code,0.25,0.031,16.28,0,0,100,0
all,civil,18,GLM 5.2,opencode,0.266,0.017,,0,0,98,0
all,civil,18,GLM 5.2,agy,0.235,0.011,12.71,1,0,86,0
all,civil,18,GLM 5.2,openhands,0.255,0.055,16.62,0,0,108,0
all,civil,18,GLM 5.2,codex,0.293,0.033,13.11,0,0,121,0
all,civil,18,GLM 5.2,hermes,0.273,0.025,11.13,0,0,71,0
all,civil,18,DeepSeek-V4.1-Flash,pi,0.265,0.081,4.38,0,0,166,0
all,civil,18,DeepSeek-V4.1-Flash,claude-code,0.157,0.02,3.73,0,0,238,0
all,civil,18,DeepSeek-V4.1-Flash,opencode,0.284,0.067,3.27,0,0,171,0
all,civil,18,DeepSeek-V4.1-Flash,agy,0.095,0.06,3.5,1,0,228,0
all,civil,18,DeepSeek-V4.1-Flash,openhands,0.069,0.025,1.77,0,0,196,0
all,civil,18,DeepSeek-V4.1-Flash,codex,0.055,0.019,2.09,0,0,301,0
all,civil,18,DeepSeek-V4.1-Flash,hermes,0.068,0.03,2.89,0,0,246,0
all,civil,18,DeepSeek-V4.1-Flash,dsh,0.176,0.033,5.9,0,0,241,1
all,civil,18,Gemini 3.1 Pro,pi,0.149,0.014,2.91,0,0,30,0
all,civil,18,Gemini 3.1 Pro,claude-code,0.14,0.009,3.98,0,0,19,0
all,civil,18,Gemini 3.1 Pro,opencode,0.144,0.013,2.75,0,0,15,0
all,civil,18,Gemini 3.1 Pro,agy,0.152,0.04,2.55,0,0,16,1
all,civil,18,Gemini 3.1 Pro,openhands,0.147,0.028,5.44,0,0,17,0
all,civil,18,Gemini 3.1 Pro,codex,0.158,0.019,3.35,0,0,18,0
all,civil,18,Gemini 3.1 Pro,hermes,0.166,0.009,2.38,0,0,13,0
all,civil,18,Gemma 4 26B,pi,0.045,0.011,0.29,0,0,82,0
all,civil,18,Gemma 4 26B,claude-code,0.04,0.001,0.52,0,0,92,0
all,civil,18,Gemma 4 26B,opencode,0.046,0.004,0.44,0,0,42,0
all,civil,18,Gemma 4 26B,agy,0.063,0.015,0.21,1,0,95,1
all,civil,18,Gemma 4 26B,openhands,0.054,0.012,0.68,0,0,111,0
all,civil,18,Gemma 4 26B,codex,0.012,0.014,0.18,0,0,22,0
all,civil,18,Gemma 4 26B,hermes,0.033,0.008,0.28,0,0,23,0
all,civil,18,MiniMax M2,pi,0.055,0.023,0.094,0,0,14,0
all,civil,18,MiniMax M2,claude-code,0.047,0.018,0.11,0,0,13,0
all,civil,18,MiniMax M2,opencode,0.033,0.009,0.078,0,0,14,0
all,civil,18,MiniMax M2,agy,0.041,0.008,0.33,1,0,12,0
all,civil,18,MiniMax M2,openhands,0.044,0.009,0.12,0,0,14,0
all,civil,18,MiniMax M2,codex,0.042,0.012,0.09,0,0,14,0
all,civil,18,MiniMax M2,hermes,0.052,0.013,0.099,0,0,10,0
all,civil,18,Kimi K2 Thinking,pi,0.048,0.012,0.21,0,0,9,0
all,civil,18,Kimi K2 Thinking,claude-code,0.042,0.016,0.25,0,0,7,0
all,civil,18,Kimi K2 Thinking,opencode,0.044,0.01,0.29,0,0,9,0
all,civil,18,Kimi K2 Thinking,agy,0.027,0.002,0.29,1,0,18,0
all,civil,18,Kimi K2 Thinking,openhands,0.046,0.006,0.25,0,0,11,0
all,civil,18,Kimi K2 Thinking,codex,0.02,0.004,0.27,0,0,8,0
all,civil,18,Kimi K2 Thinking,hermes,0.05,0.013,0.29,0,0,8,0
all,civil,18,Qwen3 Coder 480B,pi,0.034,0.004,0.14,0,0,10,0
all,civil,18,Qwen3 Coder 480B,claude-code,0.041,0.004,0.13,0,0,9,0
all,civil,18,Qwen3 Coder 480B,opencode,0.021,0.004,0.2,0,0,7,0
all,civil,18,Qwen3 Coder 480B,agy,0.034,0.002,0.49,1,0,7,0
all,civil,18,Qwen3 Coder 480B,openhands,0.045,0.007,0.2,0,0,30,0
all,civil,18,Qwen3 Coder 480B,codex,0.044,0.007,0.11,0,0,6,0
all,civil,18,Qwen3 Coder 480B,hermes,0.048,0.008,0.13,0,0,8,0
all,civil,18,gpt-oss 120B,pi,0.038,0.012,0.12,0,0,29,0
all,civil,18,gpt-oss 120B,claude-code,0.043,0.003,0.11,0,0,46,0
all,civil,18,gpt-oss 120B,opencode,0.031,0.003,0.16,0,0,46,0
all,civil,18,gpt-oss 120B,agy,0.032,0.007,,0,0,37,0
all,civil,18,gpt-oss 120B,openhands,0.034,0.008,0.15,0,0,55,0
all,civil,18,gpt-oss 120B,codex,0.032,0.004,0.19,0,0,48,1
all,civil,18,gpt-oss 120B,hermes,0.046,0.003,0.16,0,0,52,0
all,civil,18,Qwen3-Next 80B,pi,0.021,0.006,1.03,0,1,56,0
all,civil,18,Qwen3-Next 80B,claude-code,0.021,0.007,0.53,0,1,41,0
all,civil,18,Qwen3-Next 80B,opencode,0.021,0.004,0.45,0,1,66,0
all,civil,18,Qwen3-Next 80B,agy,0.016,0.006,0.4,1,1,40,0
all,civil,18,Qwen3-Next 80B,openhands,0.032,0.007,0.68,0,1,82,0
all,civil,18,Qwen3-Next 80B,codex,0.021,0.007,0.52,0,1,36,0
all,civil,18,Qwen3-Next 80B,hermes,0.015,0.004,0.42,0,1,50,0
all,civil,18,Llama 4 Maverick,pi,0.004,0.002,0.26,0,1,1,0
all,civil,18,Llama 4 Maverick,claude-code,0.003,0.002,0.07,0,1,1,0
all,civil,18,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
all,civil,18,Llama 4 Maverick,agy,0.001,0.001,0.06,1,1,3,0
all,civil,18,Llama 4 Maverick,openhands,0.007,0.006,0.18,0,1,2,0
all,civil,18,Llama 4 Maverick,codex,0.0,0.001,0.093,0,1,2,0
all,civil,18,Llama 4 Maverick,hermes,0.003,0.0,0.051,0,1,1,0
all,electrical,27,Claude Opus 5.5,pi,0.467,0.023,13.33,0,0,69,0
all,electrical,27,Claude Opus 5.5,claude-code,0.507,0.039,17.18,0,0,63,1
all,electrical,27,Claude Opus 5.5,opencode,0.479,0.015,12.53,0,0,46,0
all,electrical,27,Claude Opus 5.5,agy,0.495,0.012,42.32,1,0,44,0
all,electrical,27,Claude Opus 5.5,openhands,0.506,0.021,14.82,0,0,65,0
all,electrical,27,Claude Opus 5.5,codex,0.531,0.016,35.15,0,0,123,0
all,electrical,27,Claude Opus 5.5,hermes,0.519,0.013,16.42,0,0,67,0
all,electrical,27,GPT 6 Astra,codex,0.496,0.014,9.15,0,0,25,1
all,electrical,27,Gemini 4 Argon,pi,0.412,0.025,6.41,0,0,75,0
all,electrical,27,Gemini 4 Argon,claude-code,0.453,0.021,8.21,0,0,66,0
all,electrical,27,Gemini 4 Argon,opencode,0.37,0.021,6.86,0,0,53,0
all,electrical,27,Gemini 4 Argon,agy,0.444,0.009,7.24,0,0,70,1
all,electrical,27,Gemini 4 Argon,openhands,0.335,0.024,7.43,0,0,82,0
all,electrical,27,Gemini 4 Argon,codex,0.394,0.019,7.09,0,0,84,0
all,electrical,27,Gemini 4 Argon,hermes,0.436,0.061,7.61,0,0,59,0
all,electrical,27,Claude Sonnet 5.5,pi,0.429,0.031,11.68,0,0,92,0
all,electrical,27,Claude Sonnet 5.5,claude-code,0.431,0.006,20.02,0,0,100,1
all,electrical,27,Claude Sonnet 5.5,opencode,0.416,0.013,10.48,0,0,62,0
all,electrical,27,Claude Sonnet 5.5,agy,0.443,0.021,33.89,1,0,52,0
all,electrical,27,Claude Sonnet 5.5,openhands,0.401,0.029,15.28,0,0,111,0
all,electrical,27,Claude Sonnet 5.5,codex,0.424,0.032,41.12,0,0,236,0
all,electrical,27,Claude Sonnet 5.5,hermes,0.424,0.041,14.75,0,0,86,0
all,electrical,27,Claude Opus 5,pi,0.388,0.03,15.06,0,0,58,0
all,electrical,27,Claude Opus 5,claude-code,0.397,0.013,17.21,0,0,49,1
all,electrical,27,Claude Opus 5,opencode,0.396,0.01,13.0,0,0,38,0
all,electrical,27,Claude Opus 5,agy,0.375,0.006,29.59,1,0,42,0
all,electrical,27,Claude Opus 5,openhands,0.393,0.016,17.82,0,0,69,0
all,electrical,27,Claude Opus 5,codex,0.377,0.018,22.33,0,0,71,0
all,electrical,27,Claude Opus 5,hermes,0.382,0.024,14.29,0,0,52,0
all,electrical,27,Claude Fable 5,pi,0.298,0.025,20.29,0,0,43,0
all,electrical,27,Claude Fable 5,claude-code,0.337,0.021,26.87,0,0,45,1
all,electrical,27,Claude Fable 5,opencode,0.329,0.009,22.92,0,0,37,0
all,electrical,27,Claude Fable 5,agy,0.316,0.013,54.19,1,0,37,0
all,electrical,27,Claude Fable 5,openhands,0.309,0.016,26.11,0,0,43,0
all,electrical,27,Claude Fable 5,codex,0.305,0.023,29.25,0,0,57,0
all,electrical,27,Claude Fable 5,hermes,0.296,0.004,24.93,0,0,56,0
all,electrical,27,Grok 4.7,pi,0.319,0.049,7.1,0,0,38,0
all,electrical,27,Grok 4.7,claude-code,0.293,0.028,12.66,0,0,47,0
all,electrical,27,Grok 4.7,opencode,0.28,0.036,10.27,0,0,33,0
all,electrical,27,Grok 4.7,agy,0.298,0.01,16.81,1,1,34,0
all,electrical,27,Grok 4.7,openhands,0.257,0.009,9.51,0,0,33,0
all,electrical,27,Grok 4.7,codex,0.237,0.01,6.96,0,0,38,0
all,electrical,27,Grok 4.7,hermes,0.277,0.016,10.38,0,0,48,0
all,electrical,27,Grok 4.7,grok-build,0.334,0.005,10.06,0,0,52,1
all,electrical,27,Gemini 3.8 Flash,pi,0.258,0.015,2.53,0,0,43,0
all,electrical,27,Gemini 3.8 Flash,claude-code,0.225,0.014,2.55,0,0,34,0
all,electrical,27,Gemini 3.8 Flash,opencode,0.238,0.003,2.32,0,0,25,0
all,electrical,27,Gemini 3.8 Flash,agy,0.248,0.002,2.63,0,0,40,1
all,electrical,27,Gemini 3.8 Flash,openhands,0.249,0.02,3.21,0,0,32,0
all,electrical,27,Gemini 3.8 Flash,codex,0.244,0.014,3.59,0,0,46,0
all,electrical,27,Gemini 3.8 Flash,hermes,0.172,0.013,2.35,0,0,23,0
all,electrical,27,GLM 5.2,pi,0.21,0.009,14.55,0,0,116,0
all,electrical,27,GLM 5.2,claude-code,0.219,0.023,16.28,0,0,100,0
all,electrical,27,GLM 5.2,opencode,0.237,0.017,,0,0,98,0
all,electrical,27,GLM 5.2,agy,0.225,0.035,12.71,1,0,86,0
all,electrical,27,GLM 5.2,openhands,0.217,0.026,16.62,0,0,108,0
all,electrical,27,GLM 5.2,codex,0.241,0.021,13.11,0,0,121,0
all,electrical,27,GLM 5.2,hermes,0.221,0.016,11.13,0,0,71,0
all,electrical,27,DeepSeek-V4.1-Flash,pi,0.208,0.033,4.38,0,0,166,0
all,electrical,27,DeepSeek-V4.1-Flash,claude-code,0.149,0.029,3.73,0,0,238,0
all,electrical,27,DeepSeek-V4.1-Flash,opencode,0.207,0.014,3.27,0,0,171,0
all,electrical,27,DeepSeek-V4.1-Flash,agy,0.093,0.015,3.5,1,0,228,0
all,electrical,27,DeepSeek-V4.1-Flash,openhands,0.051,0.004,1.77,0,0,196,0
all,electrical,27,DeepSeek-V4.1-Flash,codex,0.048,0.04,2.09,0,0,301,0
all,electrical,27,DeepSeek-V4.1-Flash,hermes,0.049,0.003,2.89,0,0,246,0
all,electrical,27,DeepSeek-V4.1-Flash,dsh,0.157,0.015,5.9,0,0,241,1
all,electrical,27,Gemini 3.1 Pro,pi,0.139,0.01,2.91,0,0,30,0
all,electrical,27,Gemini 3.1 Pro,claude-code,0.155,0.012,3.98,0,0,19,0
all,electrical,27,Gemini 3.1 Pro,opencode,0.145,0.008,2.75,0,0,15,0
all,electrical,27,Gemini 3.1 Pro,agy,0.159,0.016,2.55,0,0,16,1
all,electrical,27,Gemini 3.1 Pro,openhands,0.15,0.01,5.44,0,0,17,0
all,electrical,27,Gemini 3.1 Pro,codex,0.151,0.01,3.35,0,0,18,0
all,electrical,27,Gemini 3.1 Pro,hermes,0.149,0.006,2.38,0,0,13,0
all,electrical,27,Kimi K2 Thinking,pi,0.056,0.004,0.21,0,0,9,0
all,electrical,27,Kimi K2 Thinking,claude-code,0.071,0.015,0.25,0,0,7,0
all,electrical,27,Kimi K2 Thinking,opencode,0.087,0.006,0.29,0,0,9,0
all,electrical,27,Kimi K2 Thinking,agy,0.047,0.009,0.29,1,0,18,0
all,electrical,27,Kimi K2 Thinking,openhands,0.067,0.019,0.25,0,0,11,0
all,electrical,27,Kimi K2 Thinking,codex,0.04,0.006,0.27,0,0,8,0
all,electrical,27,Kimi K2 Thinking,hermes,0.08,0.006,0.29,0,0,8,0
all,electrical,27,Qwen3 Coder 480B,pi,0.064,0.007,0.14,0,0,10,0
all,electrical,27,Qwen3 Coder 480B,claude-code,0.083,0.009,0.13,0,0,9,0
all,electrical,27,Qwen3 Coder 480B,opencode,0.065,0.01,0.2,0,0,7,0
all,electrical,27,Qwen3 Coder 480B,agy,0.07,0.018,0.49,1,0,7,0
all,electrical,27,Qwen3 Coder 480B,openhands,0.074,0.006,0.2,0,0,30,0
all,electrical,27,Qwen3 Coder 480B,codex,0.059,0.002,0.11,0,0,6,0
all,electrical,27,Qwen3 Coder 480B,hermes,0.083,0.005,0.13,0,0,8,0
all,electrical,27,MiniMax M2,pi,0.069,0.004,0.094,0,0,14,0
all,electrical,27,MiniMax M2,claude-code,0.078,0.009,0.11,0,0,13,0
all,electrical,27,MiniMax M2,opencode,0.072,0.011,0.078,0,0,14,0
all,electrical,27,MiniMax M2,agy,0.057,0.017,0.33,1,0,12,0
all,electrical,27,MiniMax M2,openhands,0.067,0.005,0.12,0,0,14,0
all,electrical,27,MiniMax M2,codex,0.059,0.004,0.09,0,0,14,0
all,electrical,27,MiniMax M2,hermes,0.063,0.003,0.099,0,0,10,0
all,electrical,27,gpt-oss 120B,pi,0.059,0.003,0.12,0,0,29,0
all,electrical,27,gpt-oss 120B,claude-code,0.048,0.007,0.11,0,0,46,0
all,electrical,27,gpt-oss 120B,opencode,0.052,0.009,0.16,0,0,46,0
all,electrical,27,gpt-oss 120B,agy,0.052,0.008,,0,0,37,0
all,electrical,27,gpt-oss 120B,openhands,0.049,0.014,0.15,0,0,55,0
all,electrical,27,gpt-oss 120B,codex,0.04,0.005,0.19,0,0,48,1
all,electrical,27,gpt-oss 120B,hermes,0.048,0.012,0.16,0,0,52,0
all,electrical,27,Qwen3-Next 80B,pi,0.039,0.009,1.03,0,1,56,0
all,electrical,27,Qwen3-Next 80B,claude-code,0.04,0.018,0.53,0,1,41,0
all,electrical,27,Qwen3-Next 80B,opencode,0.039,0.007,0.45,0,1,66,0
all,electrical,27,Qwen3-Next 80B,agy,0.023,0.008,0.4,1,1,40,0
all,electrical,27,Qwen3-Next 80B,openhands,0.055,0.004,0.68,0,1,82,0
all,electrical,27,Qwen3-Next 80B,codex,0.02,0.008,0.52,0,1,36,0
all,electrical,27,Qwen3-Next 80B,hermes,0.027,0.006,0.42,0,1,50,0
all,electrical,27,Gemma 4 26B,pi,0.044,0.014,0.29,0,0,82,0
all,electrical,27,Gemma 4 26B,claude-code,0.044,0.005,0.52,0,0,92,0
all,electrical,27,Gemma 4 26B,opencode,0.032,0.008,0.44,0,0,42,0
all,electrical,27,Gemma 4 26B,agy,0.041,0.003,0.21,1,0,95,1
all,electrical,27,Gemma 4 26B,openhands,0.053,0.004,0.68,0,0,111,0
all,electrical,27,Gemma 4 26B,codex,0.005,0.002,0.18,0,0,22,0
all,electrical,27,Gemma 4 26B,hermes,0.028,0.008,0.28,0,0,23,0
all,electrical,27,Llama 4 Maverick,pi,0.008,0.007,0.26,0,1,1,0
all,electrical,27,Llama 4 Maverick,claude-code,0.004,0.002,0.07,0,1,1,0
all,electrical,27,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
all,electrical,27,Llama 4 Maverick,agy,0.001,0.001,0.06,1,1,3,0
all,electrical,27,Llama 4 Maverick,openhands,0.01,0.003,0.18,0,1,2,0
all,electrical,27,Llama 4 Maverick,codex,0.0,0.0,0.093,0,1,2,0
all,electrical,27,Llama 4 Maverick,hermes,0.0,0.0,0.051,0,1,1,0
all,mechanical,30,GPT 6 Astra,codex,0.45,0.017,9.15,0,0,25,1
all,mechanical,30,Claude Opus 5.5,pi,0.405,0.016,13.33,0,0,69,0
all,mechanical,30,Claude Opus 5.5,claude-code,0.405,0.015,17.18,0,0,63,1
all,mechanical,30,Claude Opus 5.5,opencode,0.392,0.011,12.53,0,0,46,0
all,mechanical,30,Claude Opus 5.5,agy,0.414,0.014,42.32,1,0,44,0
all,mechanical,30,Claude Opus 5.5,openhands,0.402,0.015,14.82,0,0,65,0
all,mechanical,30,Claude Opus 5.5,codex,0.366,0.026,35.15,0,0,123,0
all,mechanical,30,Claude Opus 5.5,hermes,0.384,0.004,16.42,0,0,67,0
all,mechanical,30,Claude Sonnet 5.5,pi,0.383,0.026,11.68,0,0,92,0
all,mechanical,30,Claude Sonnet 5.5,claude-code,0.392,0.009,20.02,0,0,100,1
all,mechanical,30,Claude Sonnet 5.5,opencode,0.376,0.003,10.48,0,0,62,0
all,mechanical,30,Claude Sonnet 5.5,agy,0.406,0.006,33.89,1,0,52,0
all,mechanical,30,Claude Sonnet 5.5,openhands,0.378,0.014,15.28,0,0,111,0
all,mechanical,30,Claude Sonnet 5.5,codex,0.374,0.025,41.12,0,0,236,0
all,mechanical,30,Claude Sonnet 5.5,hermes,0.387,0.008,14.75,0,0,86,0
all,mechanical,30,Claude Opus 5,pi,0.352,0.02,15.06,0,0,58,0
all,mechanical,30,Claude Opus 5,claude-code,0.355,0.023,17.21,0,0,49,1
all,mechanical,30,Claude Opus 5,opencode,0.364,0.011,13.0,0,0,38,0
all,mechanical,30,Claude Opus 5,agy,0.396,0.037,29.59,1,0,42,0
all,mechanical,30,Claude Opus 5,openhands,0.371,0.01,17.82,0,0,69,0
all,mechanical,30,Claude Opus 5,codex,0.336,0.009,22.33,0,0,71,0
all,mechanical,30,Claude Opus 5,hermes,0.356,0.033,14.29,0,0,52,0
all,mechanical,30,Gemini 4 Argon,pi,0.344,0.005,6.41,0,0,75,0
all,mechanical,30,Gemini 4 Argon,claude-code,0.359,0.039,8.21,0,0,66,0
all,mechanical,30,Gemini 4 Argon,opencode,0.336,0.031,6.86,0,0,53,0
all,mechanical,30,Gemini 4 Argon,agy,0.332,0.011,7.24,0,0,70,1
all,mechanical,30,Gemini 4 Argon,openhands,0.273,0.025,7.43,0,0,82,0
all,mechanical,30,Gemini 4 Argon,codex,0.355,0.006,7.09,0,0,84,0
all,mechanical,30,Gemini 4 Argon,hermes,0.347,0.021,7.61,0,0,59,0
all,mechanical,30,Claude Fable 5,pi,0.314,0.016,20.29,0,0,43,0
all,mechanical,30,Claude Fable 5,claude-code,0.317,0.015,26.87,0,0,45,1
all,mechanical,30,Claude Fable 5,opencode,0.322,0.014,22.92,0,0,37,0
all,mechanical,30,Claude Fable 5,agy,0.317,0.024,54.19,1,0,37,0
all,mechanical,30,Claude Fable 5,openhands,0.298,0.005,26.11,0,0,43,0
all,mechanical,30,Claude Fable 5,codex,0.32,0.009,29.25,0,0,57,0
all,mechanical,30,Claude Fable 5,hermes,0.314,0.022,24.93,0,0,56,0
all,mechanical,30,Gemini 3.8 Flash,pi,0.261,0.037,2.53,0,0,43,0
all,mechanical,30,Gemini 3.8 Flash,claude-code,0.282,0.02,2.55,0,0,34,0
all,mechanical,30,Gemini 3.8 Flash,opencode,0.272,0.025,2.32,0,0,25,0
all,mechanical,30,Gemini 3.8 Flash,agy,0.256,0.015,2.63,0,0,40,1
all,mechanical,30,Gemini 3.8 Flash,openhands,0.257,0.002,3.21,0,0,32,0
all,mechanical,30,Gemini 3.8 Flash,codex,0.275,0.025,3.59,0,0,46,0
all,mechanical,30,Gemini 3.8 Flash,hermes,0.175,0.021,2.35,0,0,23,0
all,mechanical,30,Grok 4.7,pi,0.269,0.009,7.1,0,0,38,0
all,mechanical,30,Grok 4.7,claude-code,0.245,0.009,12.66,0,0,47,0
all,mechanical,30,Grok 4.7,opencode,0.255,0.016,10.27,0,0,33,0
all,mechanical,30,Grok 4.7,agy,0.235,0.01,16.81,1,1,34,0
all,mechanical,30,Grok 4.7,openhands,0.228,0.007,9.51,0,0,33,0
all,mechanical,30,Grok 4.7,codex,0.22,0.001,6.96,0,0,38,0
all,mechanical,30,Grok 4.7,hermes,0.236,0.017,10.38,0,0,48,0
all,mechanical,30,Grok 4.7,grok-build,0.267,0.009,10.06,0,0,52,1
all,mechanical,30,GLM 5.2,pi,0.251,0.002,14.55,0,0,116,0
all,mechanical,30,GLM 5.2,claude-code,0.207,0.026,16.28,0,0,100,0
all,mechanical,30,GLM 5.2,opencode,0.241,0.009,,0,0,98,0
all,mechanical,30,GLM 5.2,agy,0.235,0.013,12.71,1,0,86,0
all,mechanical,30,GLM 5.2,openhands,0.231,0.013,16.62,0,0,108,0
all,mechanical,30,GLM 5.2,codex,0.242,0.022,13.11,0,0,121,0
all,mechanical,30,GLM 5.2,hermes,0.239,0.015,11.13,0,0,71,0
all,mechanical,30,DeepSeek-V4.1-Flash,pi,0.212,0.05,4.38,0,0,166,0
all,mechanical,30,DeepSeek-V4.1-Flash,claude-code,0.108,0.007,3.73,0,0,238,0
all,mechanical,30,DeepSeek-V4.1-Flash,opencode,0.202,0.037,3.27,0,0,171,0
all,mechanical,30,DeepSeek-V4.1-Flash,agy,0.104,0.006,3.5,1,0,228,0
all,mechanical,30,DeepSeek-V4.1-Flash,openhands,0.076,0.046,1.77,0,0,196,0
all,mechanical,30,DeepSeek-V4.1-Flash,codex,0.052,0.023,2.09,0,0,301,0
all,mechanical,30,DeepSeek-V4.1-Flash,hermes,0.062,0.043,2.89,0,0,246,0
all,mechanical,30,DeepSeek-V4.1-Flash,dsh,0.18,0.03,5.9,0,0,241,1
all,mechanical,30,Gemini 3.1 Pro,pi,0.138,0.011,2.91,0,0,30,0
all,mechanical,30,Gemini 3.1 Pro,claude-code,0.139,0.008,3.98,0,0,19,0
all,mechanical,30,Gemini 3.1 Pro,opencode,0.128,0.009,2.75,0,0,15,0
all,mechanical,30,Gemini 3.1 Pro,agy,0.131,0.007,2.55,0,0,16,1
all,mechanical,30,Gemini 3.1 Pro,openhands,0.142,0.014,5.44,0,0,17,0
all,mechanical,30,Gemini 3.1 Pro,codex,0.136,0.01,3.35,0,0,18,0
all,mechanical,30,Gemini 3.1 Pro,hermes,0.137,0.009,2.38,0,0,13,0
all,mechanical,30,Qwen3 Coder 480B,pi,0.037,0.011,0.14,0,0,10,0
all,mechanical,30,Qwen3 Coder 480B,claude-code,0.055,0.006,0.13,0,0,9,0
all,mechanical,30,Qwen3 Coder 480B,opencode,0.04,0.002,0.2,0,0,7,0
all,mechanical,30,Qwen3 Coder 480B,agy,0.04,0.006,0.49,1,0,7,0
all,mechanical,30,Qwen3 Coder 480B,openhands,0.059,0.003,0.2,0,0,30,0
all,mechanical,30,Qwen3 Coder 480B,codex,0.039,0.008,0.11,0,0,6,0
all,mechanical,30,Qwen3 Coder 480B,hermes,0.06,0.007,0.13,0,0,8,0
all,mechanical,30,MiniMax M2,pi,0.032,0.002,0.094,0,0,14,0
all,mechanical,30,MiniMax M2,claude-code,0.045,0.004,0.11,0,0,13,0
all,mechanical,30,MiniMax M2,opencode,0.026,0.001,0.078,0,0,14,0
all,mechanical,30,MiniMax M2,agy,0.029,0.005,0.33,1,0,12,0
all,mechanical,30,MiniMax M2,openhands,0.039,0.009,0.12,0,0,14,0
all,mechanical,30,MiniMax M2,codex,0.036,0.004,0.09,0,0,14,0
all,mechanical,30,MiniMax M2,hermes,0.055,0.006,0.099,0,0,10,0
all,mechanical,30,Gemma 4 26B,pi,0.037,0.007,0.29,0,0,82,0
all,mechanical,30,Gemma 4 26B,claude-code,0.043,0.009,0.52,0,0,92,0
all,mechanical,30,Gemma 4 26B,opencode,0.033,0.012,0.44,0,0,42,0
all,mechanical,30,Gemma 4 26B,agy,0.051,0.002,0.21,1,0,95,1
all,mechanical,30,Gemma 4 26B,openhands,0.052,0.011,0.68,0,0,111,0
all,mechanical,30,Gemma 4 26B,codex,0.008,0.002,0.18,0,0,22,0
all,mechanical,30,Gemma 4 26B,hermes,0.017,0.006,0.28,0,0,23,0
all,mechanical,30,Kimi K2 Thinking,pi,0.038,0.005,0.21,0,0,9,0
all,mechanical,30,Kimi K2 Thinking,claude-code,0.033,0.014,0.25,0,0,7,0
all,mechanical,30,Kimi K2 Thinking,opencode,0.05,0.019,0.29,0,0,9,0
all,mechanical,30,Kimi K2 Thinking,agy,0.037,0.003,0.29,1,0,18,0
all,mechanical,30,Kimi K2 Thinking,openhands,0.043,0.004,0.25,0,0,11,0
all,mechanical,30,Kimi K2 Thinking,codex,0.033,0.014,0.27,0,0,8,0
all,mechanical,30,Kimi K2 Thinking,hermes,0.041,0.007,0.29,0,0,8,0
all,mechanical,30,gpt-oss 120B,pi,0.031,0.005,0.12,0,0,29,0
all,mechanical,30,gpt-oss 120B,claude-code,0.047,0.004,0.11,0,0,46,0
all,mechanical,30,gpt-oss 120B,opencode,0.034,0.006,0.16,0,0,46,0
all,mechanical,30,gpt-oss 120B,agy,0.041,0.008,,0,0,37,0
all,mechanical,30,gpt-oss 120B,openhands,0.049,0.01,0.15,0,0,55,0
all,mechanical,30,gpt-oss 120B,codex,0.05,0.009,0.19,0,0,48,1
all,mechanical,30,gpt-oss 120B,hermes,0.034,0.001,0.16,0,0,52,0
all,mechanical,30,Qwen3-Next 80B,pi,0.015,0.006,1.03,0,1,56,0
all,mechanical,30,Qwen3-Next 80B,claude-code,0.017,0.003,0.53,0,1,41,0
all,mechanical,30,Qwen3-Next 80B,opencode,0.016,0.004,0.45,0,1,66,0
all,mechanical,30,Qwen3-Next 80B,agy,0.005,0.004,0.4,1,1,40,0
all,mechanical,30,Qwen3-Next 80B,openhands,0.035,0.005,0.68,0,1,82,0
all,mechanical,30,Qwen3-Next 80B,codex,0.007,0.006,0.52,0,1,36,0
all,mechanical,30,Qwen3-Next 80B,hermes,0.017,0.007,0.42,0,1,50,0
all,mechanical,30,Llama 4 Maverick,pi,0.009,0.002,0.26,0,1,1,0
all,mechanical,30,Llama 4 Maverick,claude-code,0.004,0.001,0.07,0,1,1,0
all,mechanical,30,Llama 4 Maverick,opencode,0.0,0.0,0.004,0,1,1,0
all,mechanical,30,Llama 4 Maverick,agy,0.001,0.002,0.06,1,1,3,0
all,mechanical,30,Llama 4 Maverick,openhands,0.007,0.002,0.18,0,1,2,0
all,mechanical,30,Llama 4 Maverick,codex,0.001,0.001,0.093,0,1,2,0
all,mechanical,30,Llama 4 Maverick,hermes,0.001,0.001,0.051,0,1,1,0
'''

```

## How the numbers were produced (from the leaderboard page itself)

- Every model ran all 85 tasks on each harness, three times; a pair's score is the mean over its complete runs.
- Cost per task is computed from token usage at list prices, cached reads included. `cost_approx` marks the page's
  "estimated cost" cells and `cost_nocache` its "no prompt caching" cells. Judge calls for rubric tasks (Claude Opus 5.5
  grades them) are not mentioned as part of the cost, so treat the cost as the harness model's cost only.
- The page prints cost and minutes per task separately for the hidden and dev views, and score per task domain
  (structural, civil, electrical, mechanical) in the domain blocks. Domain blocks of one view reuse the overall cost.
- Two cells have no cost on the page (GLM 5.2 with opencode, gpt-oss 120B with agy); they are left out of cost analyses.


```python
raw = pd.read_csv(io.StringIO(DATA))
raw["sponsored"] = raw.model.isin(SPONSORED)
print(raw.shape, "rows;", raw.model.nunique(), "models;", raw.harness.nunique(), "harnesses")
print(raw.groupby(["set", "domain"]).tasks.first().unstack().loc[["dev", "test", "all"]])

ov = raw[raw.domain == "overall"]
T = ov[ov.set == "test"].set_index(["model", "harness"]).sort_index()
V = ov[ov.set == "dev"].set_index(["model", "harness"]).sort_index()
J = T[["score", "std", "cost_usd", "minutes", "sponsored"]].join(
    V[["score", "std", "cost_usd", "minutes"]], rsuffix="_dev")
J = J.rename(columns={"score": "test", "score_dev": "dev", "cost_usd": "cost_test", "cost_usd_dev": "cost_dev",
                      "minutes": "min_test", "minutes_dev": "min_dev"})
J["gap"] = J.dev - J.test
J.head()

```

## 1. Which sponsored models can reach the prize frontier?

Stage 2 ranks finalists on the score-versus-cost Pareto frontier of mean test score against average cost, and prizes go
to the top 3 by score among frontier systems with a mean test score of at least 0.138. The organisers' own runs show the
same shape: a pair is on the frontier if no other pair scores at least as high for no more money. Entries must use one
of 8 sponsored models, so the frontier below uses only those.


```python
def frontier(df, score="test", cost="cost_test"):
    x = df.dropna(subset=[cost]).reset_index()
    keep = []
    for i, r in x.iterrows():
        dominated = ((x[score] >= r[score]) & (x[cost] <= r[cost]) &
                     ((x[score] > r[score]) | (x[cost] < r[cost]))).any()
        keep.append(not dominated)
    return x[keep].sort_values(cost)

SP = J[J.sponsored]
F = frontier(SP)
Fa = F[F.test >= FLOOR]
sponsored_on_frontier = sorted(Fa.model.unique())
print("sponsored pairs with a cost:", int(SP.cost_test.notna().sum()), "of", len(SP))
print("frontier pairs at or above the floor:")
print(Fa[["model", "harness", "test", "cost_test", "min_test"]].round(3).to_string(index=False))
print()
print(len(sponsored_on_frontier), "of 8 sponsored models have a frontier pair at or above the floor:", sponsored_on_frontier)

```

```python
fig, ax = plt.subplots(figsize=(9, 5.4))
other = J[~J.sponsored].dropna(subset=["cost_test"])
ax.scatter(other.cost_test, other.test, s=16, color="#bbbbbb", label="non-sponsored models (context)", zorder=1)
colors = {"Claude Opus 5.5": "#c4572d", "Gemini 4 Argon": "#1b6ca8", "Gemini 3.8 Flash": "#2a9d8f",
          "Gemini 3.1 Pro": "#7b61a8", "GLM 5.2": "#b08900", "gpt-oss 120B": "#555555",
          "Gemma 4 26B": "#8c6d4f", "Llama 4 Maverick": "#999999"}
for m, g in SP.dropna(subset=["cost_test"]).groupby(level=0):
    ax.scatter(g.cost_test, g.test, s=30, color=colors[m], label=m, zorder=3)
ax.step(F.cost_test, F.test, where="post", color="black", lw=1.2, zorder=2, label="sponsored Pareto frontier")
ax.axhline(FLOOR, color="#c4572d", ls=":", lw=1)
ax.text(0.0035, FLOOR + 0.006, "prize floor 0.138", color="#c4572d", fontsize=9)
ax.set_xscale("log"); ax.set_xlabel("cost per hidden-test task (US$, log scale)"); ax.set_ylabel("mean hidden-test score")
ax.set_title("Hidden-test score vs cost, organisers' runs (7 harnesses per model)")
ax.legend(fontsize=8, ncol=2, frameon=False, loc="upper left"); plt.show()

```

```python
best = (SP.reset_index().sort_values("test", ascending=False).groupby("model").head(1).set_index("model"))
cheap = (SP.dropna(subset=["cost_test"]).reset_index().query("test >= @FLOOR").sort_values("cost_test")
         .groupby("model").head(1).set_index("model"))
tab = pd.DataFrame({
    "best harness": best.harness, "best test": best.test, "cost/task $": best.cost_test,
    "dev cost/task $": best.cost_dev, "full dev pass $": best.cost_dev * DEV_TASKS,
    "min/task": best.min_test})
tab["frontier at/above floor"] = [m in sponsored_on_frontier for m in tab.index]
tab["pairs at/above floor"] = [int((SP.loc[m].test >= FLOOR).sum()) for m in tab.index]
tab.sort_values("best test", ascending=False).round(3)

```

Reading the table: Gemini 3.8 Flash, Gemini 4 Argon and Claude Opus 5.5 sit on the sponsored frontier with room to
spare. Gemini 3.1 Pro gets there only through its hermes pair at 0.148, a hair above the floor. GLM 5.2 reaches 0.25
but is dominated by Flash, which scores more for about a quarter of the cost. gpt-oss 120B, Gemma 4 26B and Llama 4 Maverick never reach the floor on any of the 7
harnesses. That is the organisers' harness set, not a bound on what a purpose-built harness can do, and the floor only
matters for the prize: a Stage 1 Writeup can still be strong with a model that sits below it.


## 2. Does a dev score predict the hidden score?

Two different questions hide here. Across models the dev average and the test average line up almost exactly. Across
harnesses *for one model*, which is what someone tuning a harness changes, the agreement is weaker. The second is the
one that matters for deciding whether a dev gain is worth believing. A "harness effect" below means a harness's score
minus the mean of that model over all harnesses, computed separately on dev and on the hidden test.


```python
def corr(a, b, method="pearson"):
    return float(pd.concat([a, b], axis=1).dropna().corr(method=method).iloc[0, 1])

by_model = J.groupby(level=0)[["test", "dev"]].mean()
r_models = corr(by_model.test, by_model.dev)
rho_models = corr(by_model.test, by_model.dev, "spearman")

dm = J.test - J.groupby(level=0).test.transform("mean")    # deviation of a harness from its model's mean
dd = J.dev - J.groupby(level=0).dev.transform("mean")
r_within = corr(dm, dd)

# cluster bootstrap over models (pairs of one model are not independent); seeded
rng = np.random.default_rng(0)
models = J.index.get_level_values(0).unique().to_numpy()
boots = []
for _ in range(2000):
    pick = rng.choice(models, size=len(models), replace=True)
    sub = pd.concat([J.loc[[m]] for m in pick])
    sm = sub.test - sub.groupby(level=0).test.transform("mean")
    sd = sub.dev - sub.groupby(level=0).dev.transform("mean")
    c = np.corrcoef(sm.values, sd.values)[0, 1]
    if np.isfinite(c): boots.append(c)
lo, hi = np.percentile(boots, [2.5, 97.5])

print(f"across {len(by_model)} models   : Pearson {r_models:.3f}   Spearman {rho_models:.3f}")
print(f"within a model ({len(J)} pairs): Pearson {r_within:.3f}   95% model-cluster bootstrap [{lo:.2f}, {hi:.2f}]")
print(f"dev minus test, all pairs: mean {J.gap.mean():+.3f}, SD {J.gap.std():.3f}, range {J.gap.min():+.3f} to {J.gap.max():+.3f}")
top = J[J.test >= 0.3]
print(f"dev minus test, pairs with test >= 0.30 (n={len(top)}): mean {top.gap.mean():+.3f}")

```

```python
big = (dm.abs() > 0.05) | (dd.abs() > 0.05)
r_small = corr(dm[~big], dd[~big]); rho_small = corr(dm[~big], dd[~big], "spearman")
rho_within = corr(dm, dd, "spearman")
print(f"within a model, Spearman {rho_within:.2f}; without the {int(big.sum())} pairs whose effect exceeds 0.05 on either set: "
      f"Pearson {r_small:.2f}, Spearman {rho_small:.2f} (n={int((~big).sum())})")

def sign_table(mask=None, ths=(0.01, 0.02, 0.03, 0.05)):
    rows = []
    for th in ths:
        sel = dd.abs() >= th
        if mask is not None: sel &= mask
        n = int(sel.sum()); same = int((np.sign(dm[sel]) == np.sign(dd[sel])).sum())
        rows.append(dict(dev_effect_at_least=th, pairs=n, same_sign_on_test=same, share=round(same / n, 2),
                         mean_abs_dev_effect=round(dd[sel].abs().mean(), 3), mean_abs_test_effect=round(dm[sel].abs().mean(), 3)))
    return pd.DataFrame(rows).set_index("dev_effect_at_least")

not_ds = J.index.get_level_values(0) != "DeepSeek-V4.1-Flash"
ST_all = sign_table(); ST_ex = sign_table(pd.Series(not_ds, index=J.index))
print("all models: did a dev harness effect of this size (either direction) have the same sign on the hidden test?")
print(ST_all.to_string())
print("\nwithout DeepSeek-V4.1-Flash (its harnesses swing widely):")
print(ST_ex.to_string())

def wilson(k, n, z=1.96):
    p = k / n; d = 1 + z * z / n
    c = (p + z * z / (2 * n)) / d; h = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / d
    return c - h, c + h
wl, wh = wilson(19, 22)
print(f"\n19 of 22 -> Wilson 95% interval {wl:.2f} to {wh:.2f}. The 0.03 cut was picked after seeing this table "
      f"(0.02 gives 26 of 34), so read the headline as descriptive, not as a pre-registered test.")

```

```python
fig, axs = plt.subplots(1, 2, figsize=(11, 4.6))
ax = axs[0]
ax.scatter(by_model.test, by_model.dev, s=26, color="#1b6ca8")
lim = [0, max(by_model.max()) * 1.08]; ax.plot(lim, lim, color="#999", lw=1)
ax.set_xlabel("model's mean hidden-test score"); ax.set_ylabel("model's mean dev score")
ax.set_title(f"Across models: r = {r_models:.3f}"); ax.set_xlim(lim); ax.set_ylim(lim)
ax = axs[1]
ax.scatter(dm, dd, s=14, color="#c4572d")
m = max(dm.abs().max(), dd.abs().max()) * 1.1; ax.plot([-m, m], [-m, m], color="#999", lw=1)
ax.axhline(0, color="#ddd", lw=.8); ax.axvline(0, color="#ddd", lw=.8)
ax.set_xlabel("harness minus its model's mean, hidden test"); ax.set_ylabel("harness minus its model's mean, dev")
ax.set_title(f"Within a model: r = {r_within:.2f}, driven by {int(big.sum())} large effects"); plt.tight_layout(); plt.show()

```

Across models the two sets agree to r = 0.99, which is mostly the 18 models spanning 0.00 to 0.53. Within a model, the
overall r is 0.78 (95% interval from resampling whole models: 0.37 to 0.90), but the right-hand plot shows why that
number flatters: a handful of large effects sit far from the pile (DeepSeek's harnesses, Gemini 4 Argon on openhands,
Gemini 3.8 Flash on hermes). Without the 9 pairs above 0.05, the within-model Pearson r falls to 0.39. What survives is
the **sign**: a harness that beats its own model's average on dev by 0.03 or more did so on the hidden test in 19 of
22 cases, and by roughly half to three quarters of the dev margin. The 0.03 cut was chosen after looking at the table (0.02 gives 26 of 34, 76%), and 19 of 22 has a 95% interval of
about 67% to 95%, so read it as a description of the organisers' data. Below 0.03 the sign agreement is still better
than a coin flip but not reliable. Both sets come from the same three runs per pair, so run-level accidents (a
rate-limit stretch, a crashed run) hit both and push these numbers up. Treat a dev gain under about 0.03 as unproven.


### Does the dev set's task mix explain the gap? (checked, and no)

The dev set is civil-heavy (9 of 29 tasks) and the hidden set is mechanical- and electrical-heavy (41 of 56). Civil is
where the strongest models score best, so a mix effect is the obvious suspect for strong models scoring higher on dev.
Reweighting each pair's four dev domain scores to the hidden mix tests that.


```python
dom = raw[(raw.domain != "overall")]
dv = dom[dom.set == "dev"].pivot_table(index=["model", "harness"], columns="domain", values="score")
w_test = dom[dom.set == "test"].groupby("domain").tasks.first(); w_test = w_test / w_test.sum()
w_dev = dom[dom.set == "dev"].groupby("domain").tasks.first(); w_dev = w_dev / w_dev.sum()
J["dev_rew"] = (dv * w_test).sum(axis=1)
rmse = lambda a, b: float(np.sqrt(((a - b) ** 2).mean()))
print("hidden-test mix:", w_test.round(3).to_dict())
print("dev mix        :", w_dev.round(3).to_dict())
print(f"RMSE vs hidden score  as published: {rmse(J.dev, J.test):.4f}   reweighted to hidden mix: {rmse(J.dev_rew, J.test):.4f}")
print(f"mean gap              as published: {(J.dev - J.test).mean():+.4f}   reweighted: {(J.dev_rew - J.test).mean():+.4f}")
print(f"pairs with test >= 0.30: as published {(top.dev - top.test).mean():+.4f}   reweighted "
      f"{(J.loc[top.index].dev_rew - J.loc[top.index].test).mean():+.4f}")

```

Honest negative: reweighting does not shrink the typical error (RMSE stays at about 0.026) and swaps a small positive
gap for a small negative one, so the dev-versus-test difference is not just the domain mix. Per-domain dev cells hold
only 4 to 9 tasks each, so they are noisy too.


## 3. Harness choice moves cost a lot more than score

Same model, similar score, very different bill. Using only costs the page does not mark as estimated:


```python
clean = J[(J.cost_test.notna())].join(T[["cost_approx"]]).query("cost_approx == 0")
rows = []
for m, g in clean.groupby(level=0):
    if len(g) < 4: continue
    rows.append(dict(model=m, pairs=len(g), score_min=g.test.min(), score_max=g.test.max(),
                     cost_min=g.cost_test.min(), cost_max=g.cost_test.max(),
                     cost_ratio=g.cost_test.max() / g.cost_test.min()))
H = pd.DataFrame(rows).set_index("model")
H["score_spread"] = H.score_max - H.score_min
H.loc[[m for m in H.index if m in SPONSORED]].sort_values("cost_ratio", ascending=False).round(3)

```

```python
op = clean.loc["Claude Opus 5.5"][["test", "cost_test", "min_test"]].sort_values("cost_test")
print(op.round(3).to_string())
ratio_opus = op.cost_test.max() / op.cost_test.min()
print(f"\nClaude Opus 5.5: scores {op.test.min():.3f} to {op.test.max():.3f}, cost {op.cost_test.min():.2f} to "
      f"{op.cost_test.max():.2f} per task ({ratio_opus:.1f}x) across {len(op)} harnesses with a non-estimated cost")

```

## 4. The knob: cheapest pairs that reach your target, and what a dev pass costs

Set `TARGET_SCORE` and `PRICE_SET` in the first cell. The table lists pairs whose hidden-test mean reaches the target
and prices a full 29-task dev pass from the chosen view's cost per task. Prices come from the organisers' list-price
accounting and exclude judge fees for rubric tasks, so a real pass costs more.


```python
pool = J if not ONLY_SPONSORED else J[J.sponsored]
price_col = "cost_dev" if PRICE_SET == "dev" else "cost_test"
opts = pool[pool.test >= TARGET_SCORE].dropna(subset=[price_col]).copy()
opts["dev_pass_$"] = opts[price_col] * DEV_TASKS
opts["hours_if_sequential"] = (opts.min_dev if PRICE_SET == "dev" else opts.min_test) * DEV_TASKS / 60
opts = opts.sort_values(price_col)
cols = ["test", "dev", price_col, "dev_pass_$", "hours_if_sequential"]
print(f"target {TARGET_SCORE}, sponsored only = {ONLY_SPONSORED}, priced with the {PRICE_SET} view: {len(opts)} pairs")
opts[cols].head(8).round(3)

```

```python
import os
out = "/kaggle/working/ple_options.csv" if os.path.exists("/kaggle/working") else "ple_options.csv"
opts[cols].round(4).to_csv(out)
print("wrote", out, len(opts), "rows")

```

### Numbers quoted above, checked against the data

The next cell fails loudly if any figure in the prose stops matching the embedded numbers.


```python
assert len(sponsored_on_frontier) == 4 and set(sponsored_on_frontier) == {
    "Claude Opus 5.5", "Gemini 3.1 Pro", "Gemini 3.8 Flash", "Gemini 4 Argon"}
assert round(r_models, 2) == 0.99 and round(r_within, 2) == 0.78 and round(rho_within, 2) == 0.50
assert int(big.sum()) == 9 and round(r_small, 2) == 0.39
assert (int(ST_all.loc[0.03, "pairs"]), int(ST_all.loc[0.03, "same_sign_on_test"])) == (22, 19)
assert abs(J.gap.std() - 0.026) < 0.001
assert round(rmse(J.dev, J.test), 3) == 0.026 and round(rmse(J.dev_rew, J.test), 3) == 0.027
assert round(ratio_opus, 1) == 2.9
assert int(round(w_test.loc[["electrical", "mechanical"]].sum() * 56)) == 41
print("all quoted numbers match")

```

## What to do with this

- If your harness work changes the dev score by less than about 0.03, do not read it as a gain; at 0.03 or more it
  held on the hidden test in 19 of 22 organiser cases, with a smaller margin.
- Before running a full dev pass, price it: about $2.1 to $3.6 per dev task on Gemini 3.8 Flash ($60 to $103 for 29
  tasks) and $5.3 to $7.6 on Gemini 4 Argon ($153 to $221), from the organisers' accounting, judge fees not included.
- The frontier here belongs to off-the-shelf harnesses. The competition rewards moving a model off this curve with a
  better harness, so a result that beats these points is the interesting one.
- Source of every number: the organisers' leaderboard at ple-bench.com (hidden test, dev and all views), pulled
  2026-11-11 and embedded above. No competition data, task files or grader material is used or shown.

