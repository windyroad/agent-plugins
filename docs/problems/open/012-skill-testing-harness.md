# Problem 012: Skill Testing Harness Scope Undefined

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 6 (Medium) — Impact: Moderate (3) x Likelihood: Possible (2)
**Effort**: XL — new companion ADR for skill testing strategy, per-skill test framework decisions, retrofit of existing skills across the entire suite (itil, retrospective, architect, risk-scorer, jtbd, voice-tone, style-guide, tdd, connect) (L → XL 2026-04-19 per P047: scope explicitly "undefined", suite-wide, new ADR required)
**WSJF**: 0.75 — (6 × 1.0) / 8

## REOPENED 2026-06-04 — closure was premature (evals never green)

**User direction 2026-06-04**: reopen. The 2026-06-02 closure was on "infrastructure proven end-to-end", NOT "eval passes". Verified 2026-06-04: `npx promptfoo eval` against the manage-problem reference slice reports **0/1 passed**; the report-upstream slice (added by iter 37) reports **0/4 passed**. The harness *runs* (after a `better-sqlite3` rebuild for a local Node-version mismatch — NODE_MODULE_VERSION 137 vs 127, likely also a CI concern) but its assertions are **mis-calibrated** — correct agent responses are marked FAIL (e.g. report-upstream test emits the exact ratified leaf-decision "impact to our repository / reputation / reported party" and is marked FAIL).

**Remaining work to truly close P012**:
- Recalibrate the manage-problem + report-upstream eval assertions so they go GREEN against the correct responses (Tier-A deterministic icontains/contains/regex tuned to the actual SKILL-prose output shape).
- Fix the `better-sqlite3` / Node-version rebuild so `npx promptfoo eval` runs cleanly in CI (not just after a manual `npm rebuild`).
- Establish that the harness produces GREEN behavioural evidence — that is the actual P012 close criterion, superseding the "infra proven" closure.
- Until green: the R009 prose-floor discharge mechanism (P355) cannot credit any eval (P355's own rule requires `npx promptfoo eval` PASSES); the held cohort (P270/P344/P351/P308) stays held on the R009 floor.

**Why reopen rather than successor-ticket** (user direction 2026-06-04): the harness-gap this ticket tracks is NOT truly closed until the evals pass; a single ticket carries the full arc rather than splitting infra-shipped from evals-green.

## Closure (2026-06-02) — SUPERSEDED by 2026-06-04 reopen above

**Closed via RFC-012 S6** — the first SKILL eval landing at `packages/itil/skills/manage-problem/eval/promptfooconfig.yaml` closes the harness gap this ticket was opened to track.

**Closure mechanism**: ADR-037 (the original P012-driven decision — contract-assertion bats as the sanctioned skill-testing path with skill-creator reassessment triggers) was superseded 2026-05-03 by ADR-052 (behavioural-default). ADR-052 was then amended 2026-06-02 by **ADR-075** (promptfoo agent-prose verdict eval harness) extending behavioural-eval scope to **SKILL prose surfaces** at `packages/<plugin>/skills/<skill>/eval/promptfooconfig.yaml`. **RFC-012** (amended same date) is the build vehicle. The harness gap ADR-037's reassessment triggers (carried forward into ADR-052) had been waiting for is now closed — the harness exists, identical in shape to the agent-prose harness, with the first SKILL slice exercising the P330 Option B Release-vehicle-seed behaviour as Tier A deterministic backstop.

**Lineage**: ADR-037 (contract-assertion default) → ADR-052 (behavioural-default) → ADR-075 (behavioural-harness primitive) → ADR-075 Amendment 2026-06-02 (SKILL-surface extension) → RFC-012 S6 (first SKILL eval landing) → this ticket closes.

**Investigation Tasks resolution** (carried forward from the original ticket body below): the skill-creator-equivalent harness IS adopted, in the promptfoo shape decided in ADR-075 — exec provider wrapping `claude -p --append-system-prompt` (subscription auth, no API key). Retrofit across remaining skills proceeds incrementally under RFC-012 follow-up slices; this ticket closes on the first slice landing per the lineage above. The `<skill>-contract.bats` pattern ADR-037 sanctioned remains accepted under ADR-052 until each is touched + retrofitted (no big-bang retrofit obligation).

**Evidence**: ADR-075 amended (`docs/decisions/075-promptfoo-agent-prose-verdict-eval-harness.proposed.md` § "Amendment 2026-06-02"); RFC-012 S6 task added (`docs/rfcs/RFC-012-promptfoo-agent-prose-verdict-eval-harness.proposed.md`); first SKILL eval at `packages/itil/skills/manage-problem/eval/promptfooconfig.yaml` + driver `run-skill-eval.sh`; ADR-037 supersession trail extended (`docs/decisions/037-skill-testing-strategy.superseded.md` § "Update 2026-06-02").

## Direction decision (2026-04-20, user — AFK loop stop-condition #2)

**ADR scope**: **New companion ADR**, not an ADR-005 amendment. Skills differ enough from hooks (LLM-interpreted prose vs executable bash) that the testing strategy deserves its own decision record (contract testing, golden outputs, skill-specific harness semantics). Mint the next free ADR ID at draft time.

Implication: Investigation Task "amend ADR-005 vs new companion ADR" is resolved. The companion ADR can be drafted as the next AFK iteration, with ADR-005 left as the hook-testing contract.

## Description

ADR-005 scopes `bats-core` testing to **hook** shell scripts (`packages/{plugin}/hooks/test/*.bats`). Skills — the markdown documents Claude interprets at runtime — have no testing strategy. All 23 existing `.bats` files test hooks; no skill has automated tests.

While introducing `manage-incident` (ADR-011), the question surfaced: what does "functional test of a skill" mean when the skill is prose-with-embedded-bash? Several options exist, each with trade-offs. A quick Option A-lite pattern (execute only the embedded bash fragments) was adopted for `manage-incident` as a holding pattern, but the broader question needs a proper decision before a second skill follows suit.

## Symptoms

- ADR-005 says nothing about skill tests.
- ADR-011 had to invent a test location and narrow the test scope to fit within ADR-005's letter, flagged by the architect as an Undocumented Decision.
- Structural SKILL.md assertions (required sections, frontmatter) are currently blocked by P011's source-grep ban — but SKILL.md contracts are arguably structural, not behavioural.
- No way today to catch contract drift between a skill and its documented interface beyond a single mocked handoff assertion.

## Workaround

`manage-incident` ships with Option A-lite tests: execute embedded bash fragments + mocked `Skill`-tool handoff contract, under `packages/itil/skills/manage-incident/test/`. This covers the mechanical parts but not the prose instructions Claude interprets.

## Impact Assessment

- **Who is affected**: plugin authors (JTBD-101), and tech-leads relying on auditability (JTBD-201).
- **Frequency**: Every new skill addition will hit this decision gap until resolved.
- **Severity**: Medium — no user-facing breakage, but test discipline across the suite drifts without a rule.
- **Analytics**: N/A.

## Root Cause Analysis

### Preliminary Hypothesis

ADR-005 was written when skills were thin and skill count was 1. The plugin suite has since grown to multiple skills, and ADR-010 explicitly signals more ITIL skills coming. ADR-005 needs to either extend its scope to skills or explicitly scope skills out and defer to a companion ADR.

### Investigation Tasks

- [ ] Survey all existing skills (`manage-problem`, `manage-incident`, `update-guide`, `setup-tests`, `run-retro`, `extend-suite`, `generate` for c4/wardley, `send`/`setup` for connect, `configure`/`access` for discord) — what fraction of each skill's logic is executable bash vs prose instruction?
- [ ] Decide: amend ADR-005 (add Skill Testing section) vs. new companion ADR
- [ ] Decide: are structural SKILL.md assertions a Permitted Exception to P011's source-grep ban?
- [ ] Decide: formalise `packages/{plugin}/skills/<name>/test/*.bats` as the skill-test location
- [ ] Decide: if logic needs to be testable beyond the bash fragments, extract to `packages/{plugin}/lib/` shell libraries (noting this conflicts with ADR-011's rejection of shared-lib extraction as premature)
- [ ] Create reproduction test (a SKILL.md contract assertion that fails today due to no harness)
- [ ] **Evaluate adopting Anthropic's `skill-creator` eval harness pattern** (https://github.com/anthropics/claude-plugins-official/blob/main/plugins/skill-creator/skills/skill-creator/SKILL.md). Materially expands the option space beyond bash-fragment execution + mocked handoff. Key elements to consider adopting:
  - `evals/evals.json` — prompts with `assertions` array, one eval case per scenario
  - `eval_metadata.json` per case, `grading.json` with load-bearing fields `text` / `passed` / `evidence` (viewer depends on these)
  - `scripts/aggregate_benchmark` → `benchmark.json` / `benchmark.md` with pass_rate, time, tokens, mean±stddev, delta
  - Dual-run pattern: spawn with-skill AND baseline (without-skill) subagents in the same turn; snapshot `old_skill` when improving. Captures differential value of the skill, not just absolute pass.
  - Workspace layout: `<skill>-workspace/iteration-N/eval-<name>/{with_skill,without_skill,old_skill}/outputs/`
  - Grader + analyzer subagents (`agents/grader.md`, `agents/analyzer.md`)
  - HTML review UI (`eval-viewer/generate_review.py`, `--static` for headless/CI)
  - Guidance: "make skill descriptions a little bit 'pushy'" (undertriggering); "keep SKILL.md under 500 lines"; "subjective skills are better evaluated qualitatively — don't force assertions"
- [ ] Add "Option: adopt Anthropic skill-creator eval harness" to the ADR so MADR's minimum-two-options rule is met with a stronger comparison (architect note).
- [ ] Design how centralised `~/.claude/skill-reports/<plugin>/` data (P034) feeds into eval cases — real-world skill outputs as ground-truth for improvement iterations across all plugins (architect, jtbd, itil, risk-scorer, voice-tone, style-guide, tdd, c4, wardley)
- [ ] Check P011's source-grep ban compatibility: a grader-subagent dual-run is functional/behavioural, not source-grep, so it is compatible with ADR-005's P011 clause (architect note).
- [ ] When resolving P012, flag ADR-005 with `[Reassessment Triggered]` — its own reassessment criterion ("If Claude Code adds a way to test agent behavior programmatically") is arguably now met by this upstream evidence (architect note).

## Decision record

**ADR-037** (Skill testing strategy — contract-assertion bats companion to ADR-005) — drafted 2026-04-21. Companion ADR per the pinned direction; does NOT supersede ADR-005. SKILL.md framed as a **contract document** (parallel to `hooks.json` in ADR-005). Contract-assertions on SKILL.md structural invariants (sections, cited ADRs, `allowed-tools` content, marker strings verbatim) are the sanctioned pattern. P011 source-grep ban preserved via the contract-vs-behavioural distinction. Anthropic's `skill-creator` eval harness evaluated as a first-class considered option and deferred with 7 named reassessment triggers. ADR-005 flagged `[Reassessment Triggered]` per this ticket's investigation task. Shared helper library at `packages/shared/test/skill-test-helpers.bash` via ADR-017 sync pattern. Retrofit tracked here.

This ticket (P012) remains **Open** as the execution tracker. Closes when:
- `packages/shared/test/skill-test-helpers.bash` lands with the baseline helper library.
- Every `@windyroad/*` skill has at least one `<skill>-contract.bats` (phased retrofit; ~10-15 new files across ~8 plugins).
- `packages/shared/test/skill-contract-coverage.bats` enforces coverage (with allowlist during Phase 1; allowlist removed at Phase 2).
- ADR-017 drift check for the helper library runs in CI.
- `@jtbd` / `@problem` traceability annotations land per ADR-025 inheritance.

## Related

- **ADR-037** — decision record for this ticket. Closes the design question.
- ADR-005 (`docs/decisions/005-plugin-testing-strategy.proposed.md`) — testing strategy to extend or amend
- ADR-011 (`docs/decisions/011-manage-incident-skill.proposed.md`) — adopted Option A-lite as a holding pattern pending this problem's resolution
- ADR-010 (`docs/decisions/010-rename-wr-problem-to-wr-itil.proposed.md`) — signals more skills coming, making this decision time-bound
- JTBD-101 (`docs/jtbd/plugin-developer/JTBD-101-extend-suite.proposed.md`) — plugin authors need a clear pattern
- JTBD-201 (`docs/jtbd/tech-lead/JTBD-201-restore-service-fast.proposed.md`) — auditability constraint
- Anthropic official `skill-creator` eval harness — https://github.com/anthropics/claude-plugins-official/blob/main/plugins/skill-creator/skills/skill-creator/SKILL.md (substantial prior art for testing SKILL.md documents)
- P034 (`docs/problems/034-centralise-risk-reports-for-cross-project-skill-improvement.open.md`) — centralised `~/.claude/skill-reports/<plugin>/` storage providing real-world output data as eval inputs for the skill-creator improvement cycle across all plugins (not just risk-scorer)

## Findings 2026-06-04 (eval-calibration investigation)

**Root cause of "never green" identified + partially fixed:**

1. **Invalid JS regex (FIXED)**: the promptfoo regex/not-regex assertions used PCRE inline-flag groups `(?is)` / `(?ims)` which JavaScript `new RegExp(value)` rejects as "Invalid group" — the assertions ERRORED (counted as FAIL), they never actually evaluated. Both eval slices carried this. Fixed by converting to JS-compatible form: character classes for case-insensitivity (`[Rr]elease`), `[\s\S]` for dotall, `(^|\n)` for line-anchoring, quote negative-lookbehind `(?<!")` to exclude quoted/contrastive mentions. **manage-problem eval now 1/1 GREEN, stable across runs.**

2. **better-sqlite3 / Node-version rebuild (RECURRING, not yet CI-fixed)**: `npx promptfoo eval` fails with `ERR_DLOPEN_FAILED` (NODE_MODULE_VERSION 137 vs 127) until `npm rebuild better-sqlite3` is run. The rebuild does not persist (reverts after subprocess npm operations). CI needs a guaranteed rebuild step before `npm run eval:skills`. STILL OPEN.

3. **Non-deterministic Tier-A flakiness (STILL OPEN — the real remaining work)**: report-upstream's 4 multi-paragraph semantic tests fail *different* assertions on *different* runs — the LLM paraphrases its (correct) answer differently each time, tripping brittle Tier-A regexes (e.g. contrastive mentions of superseded "halt the orchestrator" / "never auto-report" phrases the not-regex catches). Got 0/4 → 3/4 → 2/4 across runs; never stable 4/4. Per ADR-075, semantic checks on non-deterministic multi-paragraph output are the **Tier-B `llm-rubric` (N-sample pass^k)** use case, not Tier-A deterministic regex. The report-upstream eval's semantic assertions ("does it halt?", "does it cite the impact axes?") should convert to llm-rubric; the deterministic Tier-A should retain only paraphrase-proof anchors (verbatim section names like `## Queued Upstream Report`, command shapes like `gh issue create`).

**Remaining P012 close criteria**: (a) report-upstream eval stably GREEN via Tier-B llm-rubric for semantic assertions; (b) CI better-sqlite3 rebuild guaranteed; (c) the manage-problem-style stable-deterministic pattern documented as the reference for paraphrase-proof Tier-A anchors.

## Findings 2026-06-04b (Tier-B llm-rubric grader — criterion (a) MET)

**Criterion (a) is now MET — report-upstream eval is stably GREEN.**

Diagnosed the *exact* mechanism behind finding #3's flake: the brittle assertions were all **`not-regex` on a NEGATIVE contract clause** (`(?<!")[Hh]alt\s+the\s+[Oo]rchestrator`, `[Nn]ever\s+auto[\s\-]?report`, `[Aa]lways[\s\-]?queue\s+regardless`). A `not-regex` FAILS when its pattern *matches* the output — so the behaviourally-CORRECT answer "the orchestrator does **NOT** halt" trips the not-regex, because the forbidden substring "halt the orchestrator" appears *inside the negation*. The quote-lookbehind only excluded quoted mentions, not negated ones. A regex fundamentally cannot distinguish "must-not-X satisfied" from "the word X appears in a negating clause" — that is the Tier-B `llm-rubric` case, exactly as ADR-075 anticipated.

**Fix shipped:**

1. **Claude-based llm-rubric grader** at `packages/itil/skills/report-upstream/eval/grade-llm-rubric.sh` — a promptfoo grading-provider driver wrapping `claude -p` under subscription auth (no API key; CI/release-token excluded per ADR-075 §6). Instructs strict-JSON `{pass, score, reason}` output + a defensive awk balanced-brace extractor so a stray code-fence cannot break the promptfoo parse. Wired via `defaultTest.options.provider` in `promptfooconfig.yaml`.

2. **Converted the four negative/semantic clauses to `type: llm-rubric`** (each rubric explicitly notes that a *negated* mention satisfies the must-not clause). **Retained the paraphrase-proof positive Tier-A anchors** (`gh issue create`, `Reported Upstream`, `Queued Upstream Report`, `SECURITY.md`, the three impact-axis regexes, `risk-reduc`) — mirroring the manage-problem stable-deterministic pattern (criterion (c) reference).

3. **Second flake class fixed (prompt/rubric mismatch)**: test 4's prompt only asks the model to *name* the impact axes, not to describe routing — so an early rubric demanding "routing is risk-band-dependent" over-specified beyond the elicitation and flaked ~1-in-4. Re-scoped the rubric to require only that the axes be framed as gate-scoring *inputs* (inherently assessment-driven), FAILing solely on an explicit always-queue-regardless claim. Same lesson as the dropped `external-comms`-icontains: do not assert for content the prompt does not elicit.

**Stability evidence**: post-fix runs — 100%, 100%, then a single T3-rubric flake (the prompt/rubric mismatch, now fixed), then **6 consecutive 4/4 ALL-PASS runs** after the test-4 rubric re-scope. manage-problem eval remains 1/1 stable. The systematic negation-false-fail that made the eval "never green" is eliminated.

**Remaining open**: criterion (b) — better-sqlite3 CI rebuild (finding #2) — is the last blocker before P012 can close. The evals run under subscription auth (local/dev dogfood), NOT in CI, so (b) is about making `npm run eval:skills` runnable from a clean install, not about gating CI. Criterion (c) reference pattern is documented inline above (positive paraphrase-proof Tier-A anchors + negative clauses → llm-rubric + never assert un-elicited content).
