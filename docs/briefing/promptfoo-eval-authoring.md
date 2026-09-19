# promptfoo Eval Authoring

Cross-session learnings about authoring `promptfooconfig.yaml` SKILL evals — Tier-A regex pitfalls, Nunjucks rendering, Tier-B llm-rubric routing. Split out of `governance-workflow.md` 2026-06-10 per Tier 3 budget rotation (P099 Branch B, split-by-subtopic). Oldest entries archived to `promptfoo-eval-authoring-archive.md` across multiple rotations (2026-06-28 regex-engine + Nunjucks; 2026-06-29 the three 2026-06-27 entries — AGENT-prose `--system-prompt`, tarball `files`-negation, flaky-suite Tier-B; 2026-08-21 the 2026-06-28 structural-vs-behavioural entry; 2026-09-19 the 2026-08-21 `--filter-pattern` / first-`llm-rubric`-grader entry). Load the archive alongside this file when full historical context is needed.

## What You Need to Know

### Bind Promptfoo to the Node ABI used by its installed native dependency (2026-08-31)

`npx promptfoo` can select a different Node runtime from `node` in the same shell. P426 reproduced `better-sqlite3` module 137 versus runtime module 147 even though `node -v` reported Node 24. P459 independently hit the same ABI boundary with Node 26 against a Node 24-built dependency; prefixing the unchanged `npx promptfoo` command with the Node 24 `PATH` let both focused boundary cases run and pass. Invoking `node_modules/promptfoo/dist/src/entrypoint.js` with the explicit matching binary is the equivalent direct form. Treat config validation and direct provider runs as useful diagnostics, but retain the full focused Promptfoo result as the semantic gate. <!-- signal-score: 3 | last-classified: 2026-08-31 | first-written: 2026-08-31 -->

### Bind runtime-specific cases with a per-test provider in mixed Claude/Codex configs (2026-08-29)

A config-level provider still targets the default Claude skill when the normal full suite runs. A Codex-only case that passed under a command-wide `WR_EVAL_RUNTIME=codex` can therefore fail in CI or exercise the wrong contract. Put `provider: 'exec:env WR_EVAL_RUNTIME=codex bash ./run-skill-eval.sh'` on each Codex-only test; keep `defaultTest.options.provider` for rubric grading. Prove the binding by running the filtered cases without a global runtime override. P528's five Goal lifecycle cases passed 5/5 in that shape. <!-- signal-score: -3 | last-classified: 2026-08-30 | first-written: 2026-08-29 -->

### An inline `(?i)` in a Tier-A regex errors instead of asserting, and every test reads as a content failure (2026-09-19)

JavaScript regular expressions have no inline flag syntax, so `value: '(?i)(foo|bar)'` on a `regex` or `not-regex` assertion does not compile. promptfoo reports `Invalid regex pattern: Invalid regular expression: /(?i)(foo|bar)/: Invalid group` **as an assertion failure**, and the summary line counts it among the failures with no separate error tally. Every test carrying the pattern goes red at once while the model output is visibly correct, which reads as the prose being wrong rather than the assertion being unparseable. Write the case into the character class (`[Pp]lugins?`) or match the literal casing; paths and command names are lowercase in practice. Check `gradingResult.componentResults[].reason` on a confusing red — `Invalid regex pattern` there is the tell, and it is not visible in the table view.

<!-- signal-score: 2 | last-classified: 2026-09-19 | first-written: 2026-09-19 -->

### Grade the recommendation, not whether the response mentions the rejected value (2026-08-30)

A Tier-A `not-contains: '2.25'` assertion rejected a correct response that explained 2.25 was the pre-transition value that must not be persisted. Semantic negatives need an `llm-rubric` that fails when the response recommends the forbidden outcome, while allowing it to contrast the right and wrong values. Keep the rubric's scope equally precise: “all listed preflight checks” does not mean every route-specific lifecycle mechanic. The P512 eval initially expanded that phrase to Known Error-only release seeding even though the folded Open-to-verifying route starts with objective release evidence already populated. <!-- signal-score: 1 | last-classified: 2026-08-30 | first-written: 2026-08-30 -->
