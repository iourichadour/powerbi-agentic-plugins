# dax-unit-testing — Benchmark Review

**Scope note:** This is a scoped-down benchmark (1 of the 3 `evals.json` prompts, 1 run per
configuration) run directly via background sub-agents in this session, rather than the full
skill-creator `run_eval.py`/`claude -p` pipeline (which is Claude-Code-specific and unavailable in
this Copilot CLI environment). `generate_review.py`'s viewer expects the full per-run transcript
directory structure produced by that pipeline, so results are presented here as a written report
instead of the interactive HTML viewer. The full 3-eval x 3-run matrix can be run later with the
same harness (see `evals/evals.json`) if deeper statistical confidence is wanted.

## Eval 1 — Legacy registry migration refuses ambiguous approval provenance

| Configuration | Pass rate | Time (s) | Tool calls |
|---|---|---|---|
| with_skill | **4/4 (100%)** | 331 | 8 |
| without_skill (baseline) | 2/4 (50%) | 293 | 0 |

**What differed:** Both configurations correctly refused to invent `ApprovedBy`/`ApprovedOn` for
the ambiguous row — a good baseline instinct. The skill made the difference in **schema
correctness**: the with-skill run actually ran `certify_measures.py migrate-legacy` against a real
fixture, quoted its genuine blocking error, and confirmed the Structural row auto-maps with the
`N/A` sentinel. The baseline (0 tool calls, reasoning from general knowledge only) proposed a
plausible-sounding but **incompatible** 14-column order (new columns appended after
`LastReviewed` instead of before `Severity`/`RequirementId`/`LastReviewed`) and invented status
values (`PendingApproval`, `NeedsReview`) that don't exist in the real `Pending`/`Approved`/
`Retired` vocabulary — output that would not interoperate with this repo's actual scripts.

Full run transcripts and grading are in `benchmark.json` in this folder.
