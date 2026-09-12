# dax-test-framework — Benchmark Review

**Scope note:** This is a scoped-down benchmark (1 of the 3 `evals.json` prompts, 1 run per
configuration) run directly via background sub-agents in this session, rather than the full
skill-creator `run_eval.py`/`claude -p` pipeline (which is Claude-Code-specific and unavailable in
this Copilot CLI environment). `generate_review.py`'s viewer expects the full per-run transcript
directory structure produced by that pipeline, so results are presented here as a written report
instead of the interactive HTML viewer. The full 3-eval x 3-run matrix can be run later with the
same harness (see `evals/evals.json`) if deeper statistical confidence is wanted.

## Eval 1 — DEV run stops cleanly on smoke-gate/connection failure

| Configuration | Pass rate | Time (s) | Tool calls |
|---|---|---|---|
| with_skill | **4/4 (100%)** | 249 | 11 |
| without_skill (baseline) | 2/4 (50%) | 306 | 10 |

**What differed:** Both configurations correctly avoided fabricating a suite-level pass/fail
result — that's a good baseline instinct on its own. The skill made the difference in **precision**:
the with-skill run actually executed `run_dax_tests.py` via `uv run`, quoted its genuine
`CONNECTION_ERROR` output, and explained the framework's 3-way smoke-gate classification
(`CONNECTION_ERROR` / `DAX_ERROR` / real assertion failure) that a downstream CI gate depends on to
branch correctly. The baseline reasoned generically about "missing prerequisites" without the fixed
error-type vocabulary or the smoke-gate concept at all.

Full run transcripts and grading are in `benchmark.json` in this folder.
