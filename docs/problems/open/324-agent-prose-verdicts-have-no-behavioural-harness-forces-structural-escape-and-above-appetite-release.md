# Problem 324: Agent-prose verdicts have no behavioural test harness — forcing the ADR-052 structural-test escape hatch + above-appetite release workarounds, perpetuating the structural tests the user has rejected

**Status**: Open
**Reported**: 2026-05-27
**Priority**: 9 (Med-High) — Impact: 3 x Likelihood: 3 (deferred — re-rate at next /wr-itil:review-problems; flagged HIGH-LEVERAGE — see Impact)
**Effort**: L (deferred — re-rate at next /wr-itil:review-problems)

## Description

There is no behavioural test harness for **agent-prose verdicts** — the LLM-generated output of the architect / jtbd / voice-tone / risk-scorer review agents (e.g. `[Unratified Dependency]`, `ISSUES FOUND`, `Needs Direction`). `bats` (this repo's test model) is deterministic shell and cannot exercise a prompt-driven agent. That gap (the root of `P012` master-harness + `P176`) has a compounding, recurring cost:

1. Every new agent verdict ships via the **ADR-052 structural-test escape hatch** (Surface 2, the line the user selected: "Escape") — a doc-lint bats that greps the agent.md prose, NOT a behavioural test of the verdict. **The user has repeatedly directed that structural tests are not acceptable and circumvent the desired outcome** (`P081`: "wasteful, not real tests"; `P290`: "structural tests not permitted at all" — user direction during the P283 drain). The escape hatch exists *only because* the harness doesn't.
2. The agent-verdict release class is **structurally above appetite**: R009 scores it 8/25 (Impact 4 — ships to every adopter's review workflow — × Likelihood 2, where the Likelihood-2 floor is precisely "the LLM verdict has no behavioural harness"). Evidence can't reduce it (unlike a deterministic hook à la P283, one observed firing doesn't prove an LLM verdict always fires correctly). So every agent-verdict release needs a hold-changeset + user-override workaround.

**Concrete, twice this session (2026-05-27):** RFC-010 (architect surface-3) and RFC-011 (jtbd surface-3) each shipped a structural-permitted bats and rode an above-appetite 8/25 release that required user-override.

**Behaviour-reflex (the captured-on-correction half, sibling of P197 contract-bypass-reflex):** the agent treated the harness gap as an *immovable standing constraint to route around* (reach for the structural escape + hold/override) rather than naming it as the *highest-leverage fix*. Building the harness would (a) make behavioural-only testing possible so the ADR-052 escape hatch can finally be removed (`P290`), (b) drop the entire agent-verdict release class within appetite, (c) retire the recurring release-gate blocker for every future agent verdict. The user surfaced this directly: *"why aren't you implementing P176/P012?"* + *"structural tests are not ok and circumvent the desired outcome."*

## Symptoms

- Each new review-agent verdict ships with a `tdd-review: structural-permitted (justification: P176)` bats (grep of agent.md prose), never a behavioural test of the verdict itself.
- Each agent-verdict changeset scores R009 8/25 and is held + released via user-override (RFC-010, RFC-011).
- `P290` (remove the structural escape hatch) stays blocked — it cannot land until the harness gives a behavioural alternative.

## Impact Assessment

- **Who is affected**: maintainers (every agent-verdict change pays the escape-hatch + override tax) + the framework's own credibility (it ships the structural tests it tells adopters not to write).
- **Frequency**: every new or changed review-agent verdict, indefinitely, until the harness exists. Already 2× this session.
- **Severity / leverage**: **HIGH-LEVERAGE.** This is the single root that gates the agent-verdict release class, blocks P290, and forces the structural-test pattern the user rejected. `P012`'s WSJF 0.75 (XL effort) under-rates its true leverage now that it is the *recurring* release-gate blocker, not just an abstract "harness scope undefined."

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems; re-rate P012's WSJF up given its recurring-blocker leverage.
- [x] **Evaluate the solution space** (record an ADR amending ADR-052) — **DONE: `ADR-075` (born-confirmed 2026-05-28; scope-extended + re-confirmed 2026-06-02; `human-oversight: confirmed`).** Full options A–E evaluation recorded there; the design choice below is **not an open question — it is a ratified decision.**
  - **(A) `@windyroad/skill-creator` eval/benchmark capability** — it already does LLM-in-the-loop skill evals (triggering accuracy, variance analysis). Determine whether its harness pattern extends from skill-triggering to agent-verdict-correctness (feed the agent a fixture change → assert the verdict). Closest existing in-repo tooling; investigate first. → **Verdict (ADR-075): reuse the grader+variance *pattern*, reject as the *tool*** — its turnkey path scores only "did the skill trigger", and its output-quality path is an interactive human-in-the-loop loop, not a headless CI gate.
  - **(B) LLM-as-judge** — run the real agent against a fixture diff, have a second model grade verdict correctness against a rubric. Industry-standard (promptfoo, deepeval, OpenAI/Anthropic evals, Braintrust). Non-deterministic → needs pass-rate thresholds + variance bounds, not binary asserts. → **CHOSEN (ADR-075): promptfoo**, exec provider wrapping `claude -p --system-prompt "$(cat agent.md)"` (subscription auth, no API key — verified in-session 2026-05-28). Becomes **Tier B** (`llm-rubric`, N-sample pass^k, release-gated).
  - **(C) Golden-transcript / snapshot** — record canonical agent outputs on fixtures, assert structural invariants of the verdict (verdict line present, correct artifact named, marker file written). Cheaper, deterministic, but weaker than (B) on semantic correctness. → **Adopted as Tier A's spirit (ADR-075)**: deterministic `contains`/`regex`/`is-json` assertions, CI + pre-commit/pre-push gated.
  - **(D) Live-agent-in-CI** — invoke the agent in CI on fixtures. Most faithful, but network + cost + flake; needs a gating policy (sampled, not every PR). → **Rejected as default cadence (ADR-075); kept as the conceptual driver behind Tier B (release-only, sampled).**
  - Likely shape: a thin first slice — (C)-style deterministic invariants for cheap CI coverage + a (B)-style sampled eval for semantic correctness — leveraging (A) if its harness fits. → **Confirmed: two-tier (Tier A deterministic / Tier B llm-rubric), per-package `packages/<plugin>/agents/eval/`, tarball-excluded.**
- [x] Decide CI integration (which surfaces run live vs. recorded; cost/flake budget) — **DONE (ADR-075 + `RFC-012`): Tier A blocks the CI pipeline + a pre-commit/pre-push hook (deterministic, secret-free); Tier B blocks the release pipeline (sampled pass^k, `CLAUDE_CODE_OAUTH_TOKEN` subscription OAuth, where the R009 adopter-facing risk materialises).**
- [ ] Once a behavioural alternative exists, unblock `P290` (remove the ADR-052 structural escape hatch) and back-fill behavioural tests for the architect (RFC-010) + jtbd (RFC-011) verdicts. → **This is the BUILD, tracked as `RFC-012` S1–S5 (S6 SKILL-prose slice already landed, closing P012). Implementation work — queued, not done in this RCA pass.**

### Investigation status (updated 2026-06-16, P324 iter-14 RCA pass)

The solution-space investigation this ticket was opened to do is **complete and human-ratified** — there is **no outstanding design question**:

- **Solution space evaluated** → `ADR-075` (promptfoo, two-tier, per-package configs; amends ADR-052 + ADR-005; `human-oversight: confirmed` 2026-06-02). The chosen option, provider mechanism, location, cadence, and auth posture are all user-confirmed via AskUserQuestion (2026-05-28) — re-surfacing them as an open choice would re-ask a decision already made.
- **CI integration decided** → Tier A (CI + pre-commit/pre-push) / Tier B (release) — recorded in ADR-075 §Decision Outcome and `RFC-012` Tasks.
- **Build vehicle** → `RFC-012` (single RFC for both agent-prose and SKILL-prose surfaces, per ADR-070/ADR-060 sprawl-avoidance). **S6** (SKILL-prose first slice, `packages/itil/skills/manage-problem/eval/`) **has landed** (commit `04e73336`, closes P012). **S1–S5** (agent-prose harness build → P290 unblock → RFC-010/RFC-011 graduation) **remain pending**.

**Remaining P324 work is implementation, not investigation** — the RFC-012 S1–S5 build (L effort: root devDependency, per-package eval configs, Tier-A/Tier-B CI + release wiring, structural-bats retirement). Per the AFK no-implement scope (ADR-074 substance-confirm is already satisfied by ADR-075's confirmed oversight; the gate here is build-effort/release-class, not missing direction), this is **queued for a dedicated RFC-012 build session**, not progressed in an RCA iteration. P324 stays Open until the S1–S5 harness build retires the agent-prose escape hatch and graduates the agent-verdict release class within appetite.

## Dependencies

- **Blocks**: `P290` (remove ADR-052 structural escape hatch — needs a behavioural alternative first); within-appetite release of every agent-verdict change (RFC-010, RFC-011, and future).
- **Composes with / sharpens**: `P012` (master harness — this is the agent-prose-verdict facet + its now-quantified leverage), `P176` (agent-side I2 coverage gap — same root), `P081` (structural tests are wasteful), `P197` (contract-bypass-reflex — the behaviour sibling).

## Related

- captured via /wr-itil:capture-problem + P078 capture-on-correction (user: *"structural tests are not ok and circumvent the desired outcome"* + *"why aren't you implementing P176/P012"*), 2026-05-27.
- **ADR-075** — the adoption decision this ticket's investigation produced (promptfoo, two-tier, per-package; amends ADR-052 + ADR-005; `human-oversight: confirmed` 2026-06-02). Built via RFC-012.
- **ADR-052** — behavioural-tests-default; its Surface-2 structural escape hatch (the selected line) is what this harness would let P290 remove. **Narrowed by ADR-075** for agent-prose (and, per the 2026-06-02 amendment, SKILL-prose) verdicts.
- **R009** (`docs/risks/`) — the 8/25 agent-prose residual class this harness reduces.
- RFC-010 / RFC-011 — the two in-session instances that paid the escape-hatch + override tax.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-012 | proposed | Build the promptfoo agent-prose verdict eval harness |
