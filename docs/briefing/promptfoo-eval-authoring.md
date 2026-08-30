# promptfoo Eval Authoring

Cross-session learnings about authoring `promptfooconfig.yaml` SKILL evals — Tier-A regex pitfalls, Nunjucks rendering, Tier-B llm-rubric routing. Split out of `governance-workflow.md` 2026-06-10 per Tier 3 budget rotation (P099 Branch B, split-by-subtopic). Oldest entries archived to `promptfoo-eval-authoring-archive.md` across multiple rotations (2026-06-28 regex-engine + Nunjucks; 2026-06-29 the three 2026-06-27 entries — AGENT-prose `--system-prompt`, tarball `files`-negation, flaky-suite Tier-B; 2026-08-21 the 2026-06-28 structural-vs-behavioural entry). Load the archive alongside this file when full historical context is needed.

## What You Need to Know

### Bind runtime-specific cases with a per-test provider in mixed Claude/Codex configs (2026-08-29)

A config-level provider still targets the default Claude skill when the normal full suite runs. A Codex-only case that passed under a command-wide `WR_EVAL_RUNTIME=codex` can therefore fail in CI or exercise the wrong contract. Put `provider: 'exec:env WR_EVAL_RUNTIME=codex bash ./run-skill-eval.sh'` on each Codex-only test; keep `defaultTest.options.provider` for rubric grading. Prove the binding by running the filtered cases without a global runtime override. P528's five Goal lifecycle cases passed 5/5 in that shape. <!-- signal-score: -3 | last-classified: 2026-08-30 | first-written: 2026-08-29 -->

### Two ways a promptfoo run fails that are NOT your assertions: the filter flag is `--filter-pattern`, and a config's FIRST `llm-rubric` needs a grader wired or it errors like a failure (2026-08-21)

Both hit in one session and both read as "my new cases are wrong" when nothing is wrong with them.

**The filter flag is `--filter-pattern <regex>`.** `--filter-description` does not exist; promptfoo prints its full ~40-line help and exits 1, which scrolls the actual error off the top and looks like a config parse failure. Filtering matters here because a full config run against `claude -p` takes many minutes — `--filter-pattern 'P508'` ran three cases in 49s where the whole file would have run dozens.

**A config's first `llm-rubric` assertion needs `defaultTest.options.provider` or every rubric case errors.** Without it promptfoo falls back to its own default grader — on this machine Vertex AI — and emits `API call error: Agent Platform API has not been used in project … or it is disabled`. That lands in the results table as a FAILED case, not an errored one, so the obvious read is "my rubric is wrong". The tell is `-o <json>` + `gradingResult.componentResults[].reason` starting with `API call error:`; a genuine rubric failure reads as prose about the response. **The repo convention is one grader per skill family, referenced sibling-relative** — `manage-story`, `manage-story-map` and `review-design` all point at a sibling's copy (`exec:bash ../../<sibling>/eval/grade-llm-rubric.sh`) rather than carrying their own. 15 copies exist in-tree, no two identical, and no copies-in-sync check covers them, so borrowing beats copying. Witnessed adding the P508 exit-3 cases to `manage-problem`, which had never carried a rubric before. <!-- signal-score: -1 | last-classified: 2026-08-30 | first-written: 2026-08-21 -->

### Grade the recommendation, not whether the response mentions the rejected value (2026-08-30)

A Tier-A `not-contains: '2.25'` assertion rejected a correct response that explained 2.25 was the pre-transition value that must not be persisted. Semantic negatives need an `llm-rubric` that fails when the response recommends the forbidden outcome, while allowing it to contrast the right and wrong values. Keep the rubric's scope equally precise: “all listed preflight checks” does not mean every route-specific lifecycle mechanic. The P512 eval initially expanded that phrase to Known Error-only release seeding even though the folded Open-to-verifying route starts with objective release evidence already populated. <!-- signal-score: 1 | last-classified: 2026-08-30 | first-written: 2026-08-30 -->
