# promptfoo Eval Authoring

Cross-session learnings about authoring `promptfooconfig.yaml` SKILL evals — Tier-A regex pitfalls, Nunjucks rendering, Tier-B llm-rubric routing. Split out of `governance-workflow.md` 2026-06-10 per Tier 3 budget rotation (P099 Branch B, split-by-subtopic). Oldest entries archived to `promptfoo-eval-authoring-archive.md` across multiple rotations (2026-06-28 regex-engine + Nunjucks; 2026-06-29 the three 2026-06-27 entries — AGENT-prose `--system-prompt`, tarball `files`-negation, flaky-suite Tier-B; 2026-08-21 the 2026-06-28 structural-vs-behavioural entry; 2026-09-19 the 2026-08-21 `--filter-pattern` / first-`llm-rubric`-grader entry; 2026-09-19 split-by-date again — the 2026-08-29 per-test-provider and 2026-08-30 grade-the-recommendation entries). Load the archive alongside this file when full historical context is needed.

## What You Need to Know

### A fixture is not portable between the codex and claude runners — they read different corpora (2026-09-19)

`packages/<plugin>/agents/eval/` ships two configs, and the provider behind each reads a different world. `run-codex-agent-eval.sh` copies `fixtures/repo/.` into a temp dir and runs `--cd "$TMP_REPO"`, so the agent sees a two-file synthetic corpus. `run-agent-eval.sh` does `cd "$REPO_ROOT"`, so the agent sees all ~130 live ADRs. Any fixture whose correct verdict depends on what the corpus does or does not contain therefore **inverts** between them. Copying one across is not a port.

Worked example, P290 iter: the codex config's NEEDS DIRECTION fixture asks whether plugin distribution should use a remote marketplace only or also a repo-local one. Unpinned in the synthetic corpus, so NEEDS DIRECTION is right there. In the live corpus ADR-003 and ADR-120 pin it twice over, and `agent.md` says direction fixed by an accepted ADR means the agent must NOT ask — so the correct live verdict is PASS and the ported fixture fails, or worse flakes on corpus-reading variance and quietly erodes the verdict it was meant to certify. The architect gate caught it before it was written.

Two habits that cost nothing and catch this: grep `docs/decisions/` for the fixture's topic before settling on it (`grep -ril 'bash 3|bash 4|bash 5|BASH_VERSINFO' docs/decisions/*.md` returning empty is what made the replacement safe), and run the real runner on the prompt BEFORE adding it to the config — `bash packages/<plugin>/agents/eval/run-agent-eval.sh "<prompt>"` needs no secret, only your logged-in session. The tell that the agent genuinely read the corpus rather than pattern-matching your prompt is unprompted live-repo detail in its answer.

Note also that only `promptfooconfig.yaml` is CI-gated: `npm run eval:agents` globs that exact name, so a fixture that exists only in `promptfooconfig.codex.yaml` is not coverage you can retire a test against.

<!-- signal-score: 2 | last-classified: 2026-09-19 | first-written: 2026-09-19 -->

### A red Tier-B case can be the fixture's fault, and reading it as a prose gap edits the SKILL wrongly (2026-09-19)

On the P472 iter a new SKILL-prose eval went 3 passed / 1 failed on its first run. The failing case fed the agent a scenario the fix makes impossible — the detector reporting a missing row for a story while the repair helper withholds that same story — and the agent noticed: it answered that the premise was inconsistent and declined to act, which the rubric scored as a refusal to follow the directive. The directive was fine. The fixture was not.

The pull is to read a red Tier-B case as evidence the prose is unclear and to go strengthen the prose, which ships a real edit driven by a fake signal. The check that costs nothing: before touching the SKILL, ask whether the fixture's world can exist under the change you just made. A narrowing fix in particular makes states unreachable, and any case written from the pre-fix world may now be describing something the code prevents. Rewriting that one case to a reachable scenario — the helper withholding a *sibling* story while the original finding clears — turned it green with no prose change at all.

Worth keeping the agent's refusal in view as a signal in its own right: an agent that spots your inconsistent premise is behaving correctly, and a rubric that fails it is measuring the fixture.
<!-- signal-score: 2 | last-classified: 2026-09-19 | first-written: 2026-09-19 -->

