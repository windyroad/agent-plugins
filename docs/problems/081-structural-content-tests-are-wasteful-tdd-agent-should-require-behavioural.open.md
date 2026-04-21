# Problem 081: Structural source-content tests are wasteful — TDD agent should reject them and require behavioural tests (+ framework / stub enhancements)

**Status**: Open
**Reported**: 2026-04-21
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: L — TDD agent enhancement (new detection + suggestion surface) + testing-framework / stub / harness enhancements (so behavioural tests for LLM-interpreted skills are feasible at all) + amendment / supersession of ADR-005 Permitted-Exception and ADR-037 contract-assertion pattern + retrofit of existing structural bats across the suite (~50+ files across itil, retrospective, architect, risk-scorer, jtbd, voice-tone, style-guide, tdd, connect, discord packages). Architect review at implementation time to decide ADR shape (amend both vs supersede vs draft new) AND to scope the retrofit window (all-at-once vs per-skill-as-touched). L bucket reflects the reasonable-lower bound; may push to XL if the retrofit is bundled into one release, or scope-split across multiple phased tickets if the framework enhancements require new subagent types or Claude Code harness changes.

**WSJF**: 3.0 — (12 × 1.0) / 4 — High severity (every test we write going forward inherits the wrong style; every existing test is now suspect); large effort (framework changes + retrofit). Ranks in the 3.0-tier alongside P014 / P064 / P065. Above the 2.0 XL-tier tickets; below the 6.0 M-tier top-of-queue.

## Description

The project ships ~50+ bats files across plugin packages that follow the **structural contract-assertion pattern** blessed by `ADR-037` (skill testing strategy) and `ADR-005`'s Permitted-Exception carve-out. Each file greps its target SKILL.md (or ADR, or hook script) for specific content strings — "SKILL.md cites P077", "Step 5 names the Agent tool", "allowed-tools includes Agent" — and asserts the grep found a match.

User direction (2026-04-21 interactive, verbatim):

> tests that check the source code contents like the following are wasteful and not real tests. The TDD agent should fail these and suggest behavioural tests. The whole point of the tests is to test behaviour. If there are enhancements or changes needed in the testing framework or stubs, then the TDD agent should suggest them

This supersedes (or at minimum amends) ADR-005's Permitted-Exception and ADR-037's contract-assertion pattern. Going forward:

1. The TDD agent (the `wr-tdd` plugin's gate + review skills) must **detect** structural source-content tests when they are added and **reject** them.
2. The TDD agent must **suggest behavioural alternatives** — what the test should actually assert about the target's behaviour.
3. When the suggested behavioural test is not yet expressible under the current testing framework / stubs (e.g. a skill's behaviour depends on Claude interpreting SKILL.md prose and dispatching tool calls — not trivially unit-testable with bats), the TDD agent must **propose framework / stub / harness enhancements** that would make the behavioural test feasible.

A behavioural test for a skill asserts what the skill DOES when invoked — its tool-call sequence, its final artefact state, its output message — not what its SKILL.md SAYS. The two are correlated (SKILL.md is what Claude interprets) but a structural grep is strictly weaker: it confirms the author wrote certain words, not that Claude does the right thing when reading them. Structural assertions are "a prose-level sniff test" that pass on misleading phrasing, tautologically-worded contracts, and copy-paste drift as long as the keywords line up.

This gap composes with the open `P012` (skill testing harness scope undefined) and amends its direction: the harness we design must be BEHAVIOURAL-first, not structural-first. The user's 2026-04-20 direction on P012 was "new companion ADR (ADR-037)"; today's direction narrows ADR-037's scope from "structural contract-assertion as default" to "structural as last resort, behavioural as default".

## Symptoms

- Every skill ships with a bats file that greps its SKILL.md for keywords. The grep passes whenever the author types the expected phrase; it says nothing about whether Claude will do the right thing at runtime.
- Tests like `SKILL.md cites P077`, `SKILL.md Step 5 names the Agent tool`, `SKILL.md allowed-tools includes Agent` are **self-referential** — they pass iff the author wrote the required marker, not iff the skill exhibits the required behaviour.
- Contract drift is trivially easy: an author can change the SKILL.md prose in a way that passes the grep but changes the behaviour (e.g. "names the Agent tool" passes on any mention of "Agent tool", including `"Do NOT use the Agent tool"`).
- Regression detection is limited to "did someone delete the keyword from SKILL.md". Behavioural regressions (Claude interprets the skill differently after a version bump; a hook's script no longer honours the contract despite the SKILL.md saying it should; a skill's delegation target changed from `/wr-itil:manage-problem` to some other path) slip through.
- The `wr-tdd` plugin's Red-Green-Refactor gate currently has no opinion on structural tests — authors write them, they pass, gate advances. The plugin mistakes "keyword present" for "behaviour correct".
- Tests of this shape mislead human readers: someone reviewing a PR sees "19 tests pass" and assumes the skill is covered, when in reality nothing about its behaviour was exercised.
- **Block legitimate progressive-disclosure trims.** When authors compress SKILL.md prose (e.g. replacing a verbose heading with an equivalent shorter phrasing), the structural greps fire on the missing exact string and fail CI. Observed 2026-04-22 during the P098 `install-updates` SKILL.md trim: commit `c106e62` shortened Step 6 from "Sibling count > 3 — grouping fallback (P061)" to "Siblings > 3 (P061 `maxItems=4` fallback)" — a semantics-preserving compression — but the bats file `.claude/skills/install-updates/test/install-updates-consent-gate-sibling-cap.bats` greped for the verbatim longer phrase. CI run `24750456039` failed hook-tests step on 5 not-ok lines (718/719/721/722/723). Remediation commit `84c920e` restored the exact verbatim strings (`Sibling count > 3 — grouping fallback (P061)`, `caps \`maxItems\` at 4`, `name every detected sibling in the question body text`, `Sibling count ≤ 3`, `original contract applies`, `Either shape (≤ 3 or > 3 fallback) satisfies the ADR-030 Confirmation consent gate`). The compression trim was preserved around the restored strings, but the cost was one extra commit + one extra CI cycle + one risk-score round. This is the predicted failure mode: structural tests block semantics-preserving refactors that behavioural tests would ignore.

## Workaround

Accept the gap. Structural tests catch SOME drift (author deleted the keyword) and that's non-zero. But every structural test should carry a known-limitation note ("this is a content-present sniff test, not a behavioural assertion") and the Red-Green-Refactor cycle should demand a behavioural-test follow-up ticket on each. No such convention today — structural tests ship solo.

## Impact Assessment

- **Who is affected**:
  - **solo-developer persona** (`JTBD-001` — enforce governance without slowing down) — governance signals (test-green ≡ safe-to-commit) are trusted by the developer; structural-only tests make test-green an unreliable signal.
  - **plugin-developer persona** (`JTBD-101` — extend the suite) — downstream plugin authors inherit the wrong pattern when they copy the shipped contract-assertion bats as a template. The anti-pattern propagates.
  - **tech-lead persona** (`JTBD-201` — audit trail) — PR review, release assessment, and retrospective reviews all treat test-green as evidence of behaviour; structural-only evidence breaks that chain.
- **Frequency**: every new test. Every retrofit of an existing test. Every CI run that reports "477/477 green".
- **Severity**: High. Systematic misalignment of test-effort with test-value. Every structural test costs author + maintainer effort while delivering substantially less coverage than a behavioural test would.
- **Analytics**: N/A today. Post-fix candidate metrics: (1) ratio of structural-to-behavioural assertions in the shipped suite, (2) bugs caught by behavioural tests that structural tests missed, (3) TDD-agent-rejection count per week as a leading indicator of pattern adoption.

## Root Cause Analysis

### Structural

**ADR-005** (BATS hook testing) carves out a Permitted Exception to the source-grep ban for "structural assertions" — specifically, bats files asserting that hook scripts contain required safety constructs (e.g. `set -euo pipefail`). The exception was scoped narrowly but has been read as blanket permission for structural grep in general.

**ADR-037** (skill testing strategy — proposed) blessed the **contract-assertion pattern**: per-skill `test/*-contract.bats` files that grep SKILL.md for the skill's documented contract elements. This was chosen because "behavioural tests for LLM-interpreted skills are not trivially expressible" and structural-grep was the accessible alternative. The ADR explicitly named structural-grep as DEFAULT for skills, marking it as "a pragmatic lower bound pending a behavioural harness".

**`wr-tdd` plugin** ships a Red-Green-Refactor gate (TDD state tracked per test file) but has no opinion on the KIND of test being written. Structural-grep test files pass through the RED→GREEN→REFACTOR cycle same as behavioural ones. No detection, no suggestion, no framework-enhancement hinting.

**`bats-core` framework** provides file-level test isolation + setup/teardown + assertions. It does NOT provide stubs for Claude's interpretation, for Agent-tool invocations, for Skill-tool delegation, or for subagent return contracts. A behavioural test of a skill today would require:
- Simulating or running Claude against the SKILL.md + args
- Mocking or intercepting tool calls (Write / Edit / Bash / Skill / Agent)
- Asserting on tool-call sequences + final artefact state

None of that infrastructure exists. The shipped pattern (structural grep) is the path of least resistance — and it's what the codebase now does by default.

### Why the pattern was adopted

`P011` (grep-based bats tests fragile — closed) drove the initial tightening: grep on source code is a fragile coupling because renaming a function breaks the test even when the behaviour is unchanged. ADR-005's Permitted Exception was the compromise: structural grep is acceptable for things that ARE structural contracts (e.g. safety constructs in hook scripts, required sections in SKILL.md frontmatter). The exception stopped short of allowing arbitrary keyword-grep but that nuance was lost in practice — "structural grep is sometimes OK" became "structural grep is default for anything contract-like".

`P012` (skill testing harness scope undefined) identified the missing piece: behavioural testing of skills requires a harness that doesn't exist. The 2026-04-20 direction pin chose a companion ADR (ADR-037) but did not preclude a future amendment that raises the behavioural-testing bar.

`ADR-037` landed structural-grep-as-default because the alternative was "no tests at all". The direction today is: raise the bar — structural-grep is last resort, not default.

### Candidate fix

The work has three layers:

**Layer A: TDD agent detection + rejection + suggestion.**

`wr-tdd` plugin gains new behaviour in its gate + review surfaces:
1. **Detect** structural-grep patterns in new bats files (heuristic: `run grep ... "$SKILL_FILE"` / `"$HOOK_FILE"` / equivalent paths; assertion tests `$status -eq 0`; no `run <target-command>` that invokes the target skill/hook with arguments).
2. **Reject** new structural tests at gate time. The gate reports "This test appears structural (greps source content) rather than behavioural (exercises the target). Structural tests are wasteful per P081 + ADR-005 amended. Please write a behavioural test."
3. **Suggest** behavioural alternatives per test. For the specific target being tested, propose what the behavioural assertion should look like (e.g. "For skill X delegating via Skill tool: simulate invocation with known args and assert the Skill-tool call carries the expected target + arguments").
4. **Propose framework / stub enhancements** when the behavioural alternative is not yet expressible. Concrete examples: a subagent stub that returns a scripted ITERATION_SUMMARY; a Skill-tool invocation interceptor that captures `(target, args)` tuples; a Write/Edit recorder that asserts on final file state without touching the real filesystem.

**Layer B: Framework / stub / harness enhancements.**

Make behavioural testing feasible at all. Concrete candidates:
- **Skill-invocation harness** — a bats helper that loads a SKILL.md, runs it against a scripted model (either a stubbed LLM that executes the SKILL.md's embedded bash deterministically, OR a real Claude API call in a recording-mode CI environment), captures tool-call sequences, and returns them for assertion.
- **Tool-call interceptor** — mocks for `Skill`, `Agent`, `Write`, `Edit`, `Bash`, `AskUserQuestion` that return pre-scripted results and record the invocation parameters.
- **Subagent return stub** — for skills that spawn subagents (ADR-032 + P077), a stub that returns a pre-scripted summary block without actually spawning a subagent.
- **Filesystem sandbox** — a temp-dir-rooted filesystem for skills that create / rename / commit files; assertions on final tree state rather than on SKILL.md content.
- **AskUserQuestion stub** — a pre-scripted answer table for skills that branch on user answers.

The harness shape is `P012`'s scope. This ticket's Layer B is "flesh out the harness so Layer A's behavioural-test suggestions are actually expressible".

**Layer C: ADR-005 amendment + ADR-037 supersession (or amendment).**

- **ADR-005 Permitted Exception** — narrow the scope. Structural grep is still permitted for hook scripts' safety constructs (`set -euo pipefail`), but NOT for content-assertion on SKILL.md / ADR / prose documents. The exception becomes "hook-safety-construct-only", not "anything that looks structural".
- **ADR-037** — supersede or amend. The contract-assertion pattern becomes "permitted as a pragmatic last-resort when Layer B's harness cannot express the behavioural assertion, AND the skill's Review-documentation section explicitly cites the missing harness capability and links a P081-descendant ticket tracking the enhancement". Default flips from structural to behavioural.
- **New ADR (alternative)** — if the amendments are substantial, draft a new ADR (e.g. "Skill testing defaults to behavioural") that supersedes both ADR-005's Permitted Exception scope and ADR-037's contract-assertion default. Architect review decides ADR shape.

**Layer D: Retrofit of existing structural bats.**

~50+ existing files across plugin packages are now technically-debt. Retrofit strategy options:
1. **Big-bang retrofit** — one AFK sprint converts all structural bats to behavioural + harness-calls. High-effort, high-risk.
2. **Incremental-as-touched** — each skill's bats gets retrofitted the next time the skill is edited. Lower-risk, multi-release.
3. **Deprecation window** — existing structural bats continue to pass but get a "deprecated, not behavioural" warning annotation. Fails only on NEW structural tests. Eventually all deprecated-structural get retrofitted.

Architect review at implementation decides retrofit strategy.

### Lean direction

No direction pinned yet — architect review at implementation is required because the ADR-005 / ADR-037 change is substantive and the harness design (Layer B) is cross-cutting.

**Preferred starting shape** (subject to architect review):
- Layer A: ship first. TDD-agent detection + rejection + suggestion. No framework changes needed — it's a rule change in the TDD gate.
- Layer B: second. Framework enhancements rolled out per need. Bats helpers + stubs + harness primitives land as each skill retrofits or as each new skill wants behavioural tests.
- Layer C: alongside Layer A. ADR-005 amendment + ADR-037 supersession drafted as this ticket's architect-review outcome.
- Layer D: incremental-as-touched (Option 2). Big-bang retrofit is too risky; deprecation window is over-engineered. Each skill retrofits next time it's edited.

### Related sub-concerns

**Sub-concern 1**: hook scripts are different from skills. A hook is executable bash — behavioural testing is "run the hook, assert on exit code + stdout/stderr + side effects". ADR-005's Permitted Exception covers hook safety-construct structural checks, which stay valid (a `set -euo pipefail` assertion isn't replaceable by a behavioural test without re-running every hook under a test harness that knows the expected failure cases). This ticket's scope is primarily SKILL.md and ADR-prose grep, not hook safety-constructs.

**Sub-concern 2**: test-the-ADR-itself grep. Some bats files grep ADRs for specific clauses (e.g. `ADR-037 contract-assertion pattern`). These are meta-structural — asserting that the authoring discipline was followed. Architect review decides whether these are in-scope for rejection (probably yes — ADRs are prose documents like SKILL.md).

**Sub-concern 3**: policy-file grep (`RISK-POLICY.md`, `CLAUDE.md`, `PERMISSIONS.md`). These are neither hooks nor skills but policy documents. Same calculus as SKILL.md grep — wasteful without a behavioural binding. Architect review decides scope.

**Sub-concern 4**: bats-core limitation. bats is a shell test runner, not an LLM interpretation harness. Any serious behavioural testing of skills probably needs either (a) a new test runner purpose-built for LLM-interpreted prose, OR (b) a bats helper library that wraps a stubbed model or a real API call. Architect + P012 review decide.

**Sub-concern 5**: cost of behavioural tests. Real API calls cost tokens + latency; stubbed interpretation may drift from real Claude behaviour. Architect review decides: recording-mode fixture? deterministic stub? mix of both?

**Sub-concern 6**: retrospective application to this commit. This ticket's OWN reproduction test should be a BEHAVIOURAL test of the TDD agent's detection — not a structural grep of the TDD agent's SKILL.md. Architect review flags the shape of the first test this ticket's fix MUST pass.

### Investigation Tasks

- [ ] Architect review: decide ADR shape (amend ADR-005 + ADR-037 separately, amend ADR-037 while scoping ADR-005's Permitted Exception down, or new ADR that supersedes both). Decide retrofit strategy (big-bang / incremental / deprecation-window).
- [ ] Draft the ADR change(s). Land the new direction as the authoritative definition of "what counts as a meaningful test".
- [ ] Implement Layer A: TDD agent detection + rejection + suggestion surface. Hook fires at Write on new `*.bats` / `*.test.ts` / `*.spec.ts` files. Produces a structured rejection message with behavioural-alternative suggestion + framework-enhancement proposal.
- [ ] Implement Layer B: at least ONE framework primitive (e.g. Skill-tool invocation interceptor) so the rejection message has a credible "here's how to write the behavioural version" payload. Additional primitives land as subsequent tickets.
- [ ] End-to-end test the TDD agent: author a structural bats file; verify the agent rejects with the right suggestion shape. Author a behavioural test using the new framework primitive; verify the agent accepts.
- [ ] Retrofit strategy execution: pick Option 1/2/3 per architect; execute. Note: this is likely its own sibling ticket — do not conflate with the agent + framework work.
- [ ] Update the `wr-tdd` plugin's SKILL.md / CLAUDE.md documentation to describe the new rule. Future plugin authors land on the behavioural-default pattern.
- [ ] Update ADR-037's Confirmation bats — if ADR-037 itself has structural-grep assertions (which it does — it's one of the meta-structural offenders), they become the first retrofit candidates. Target the dogfood.
- [ ] Cross-check with P012 direction: P012's harness-definition scope narrows to behavioural-first; amend P012's direction record to reflect this session's refinement.
- [ ] Cross-check with P018 (TDD enforce BDD + Example Mapping) — composition possibility: BDD's behaviour-driven shape naturally aligns with this ticket's behavioural-default direction.

## Related

- **P011** (`docs/problems/011-grep-based-bats-tests-fragile.closed.md`) — prior art on grep-based test fragility. This ticket extends P011's conclusion from "grep is fragile" to "grep is weak — prefer behavioural".
- **P012** (`docs/problems/012-skill-testing-harness.open.md`) — the testing-harness scope ticket. This ticket's Layer B narrows P012's direction to behavioural-first.
- **P018** (`docs/problems/018-tdd-enforce-bdd-example-mapping-principles.open.md`) — TDD enforce BDD + Example Mapping. Composes directly: BDD's Given-When-Then cadence IS the behavioural shape this ticket's rule demands.
- **P015** (`docs/problems/015-tdd-vague-gherkin-detection.open.md`) — TDD vague-Gherkin detection. Sibling concern in the TDD-agent-quality axis.
- **ADR-005** (`docs/decisions/005-bats-hook-testing.proposed.md`) — Permitted Exception scope narrows under this ticket's direction.
- **ADR-037** (`docs/decisions/037-skill-testing-strategy.proposed.md`) — contract-assertion pattern supersedes or amends under this ticket's direction.
- All existing `*-contract.bats` files across `packages/*/skills/*/test/` and `packages/*/hooks/test/` — retrofit candidates under Layer D.
- **JTBD-001**, **JTBD-101**, **JTBD-201** — personas whose test-green-means-safe contract this ticket restores.

## Session note (author)

This ticket was authored after the user flagged the pattern during manage-problem slice-4 halt recovery (2026-04-21 session). The slice-4 bats files I committed as the halt recovery ARE the kind of structural-grep tests this ticket identifies as wasteful — they're dogfood examples of the problem. When Layer A + Layer B ship, those files become the first retrofit candidates.

The user's frustration ("these are wasteful, not real tests") was a strong-signal correction. Per `P078` (assistant-offers-problem-ticket-on-user-correction) direction, that signal maps directly to this ticket's creation. `P078`'s implementation — when it ships — should surface this pattern automatically the next time a structural-grep bats file passes through Write/Edit without a paired behavioural test.
