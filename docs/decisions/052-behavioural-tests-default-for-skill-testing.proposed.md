---
status: "proposed"
human-oversight: unconfirmed
oversight-date: 2026-06-09
date: 2026-05-03
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-11-03
supersedes: [037-skill-testing-strategy]
---

# Behavioural-tests-default for skill testing

> **Amendment 2026-06-09 — Behavioural-only (escape hatches removed).** User direction during the 2026-05-25 `/wr-architect:review-decisions` drain: *"structural tests not permitted at all."* This amendment removes Option 1's escape-hatch surfaces in their entirety: the `WR_TDD_REVIEW_TEST=skip` env-var override (former Surface 1), the in-file `tdd-review: structural-permitted (justification: …)` comment override (former Surface 2), and the `structural-justified` permitted verdict in the `review-test` agent vocabulary. **Behavioural is the only permitted kind of skill / agent / prose-document test.** Structural assertions on prose-document content (`SKILL.md`, `agent.md`, `*.proposed.md`, `RISK-POLICY.md`, etc.) are not permitted under any justification. The chosen option becomes **Option 1A — Behavioural-only (no escape hatch)**; the prior Option 1 (behavioural-default with documented-justification escape hatches) is rejected as historical context. Tracked by P290. Re-confirm via the drain after P290 closes.

## Context and Problem Statement

ADR-037 (Skill testing strategy) — proposed 2026-04-21 — sanctioned the **contract-assertion** pattern as the default for skill tests: per-skill `<skill>-contract.bats` files greping `SKILL.md` for declared structural invariants (sections present, ADRs cited, frontmatter fields, allowed-tools entries, marker strings). The pattern shipped across ~50+ bats files in the suite.

Real-world experience since 2026-04-21 has surfaced two failure modes the contract-assertion default does not catch and one it actively causes:

1. **Misleading-phrasing pass** — a SKILL.md that contains the asserted keyword but instructs Claude incorrectly still passes. Example: `SKILL.md cites the Agent tool` passes on prose containing `"Do NOT use the Agent tool"`. Structural-grep is **strictly weaker** than a behavioural assertion.
2. **Behavioural-regression slip** — Claude's interpretation of SKILL.md changes between model versions or after a hook injects `additionalContext`; the structural greps continue passing because the SKILL.md prose did not change. The test suite reports green while the skill's actual behaviour has drifted.
3. **Refactor-blocking false-negative** — semantics-preserving compression of SKILL.md prose (e.g. shortening a heading without changing meaning) fails the structural greps and blocks the refactor. Documented incident: `install-updates` SKILL.md trim 2026-04-22, commit `c106e62` shortened Step 6 from "Sibling count > 3 — grouping fallback (P061)" to "Siblings > 3 (P061 `maxItems=4` fallback)" — the bats greped the verbatim longer phrase, CI failed, remediation commit `84c920e` restored the long string. One extra commit + one extra CI cycle + one risk-score round paid in zero behavioural value.

The user's verbatim direction (P081, 2026-04-21):

> tests that check the source code contents like the following are wasteful and not real tests. The TDD agent should fail these and suggest behavioural tests. The whole point of the tests is to test behaviour. If there are enhancements or changes needed in the testing framework or stubs, then the TDD agent should suggest them

Scope clarification (P081, 2026-04-27):

> you can't detect the bad tests with grep — it needs to work with bats, vitest, cucumber, etc. You need an LLM to do this which is why I said 'agent'

The structural-vs-behavioural distinction is **semantic**, not **syntactic**, and must work across at minimum: bats, vitest, jest, mocha, cucumber/`.feature`, pytest. ADR-037's contract-assertion default reverses: behavioural is the default; structural is permitted only when (a) the behavioural assertion is not yet expressible under the current testing framework, AND (b) the test author documents the harness gap with a linked ticket.

This ADR supersedes ADR-037 and amends ADR-005's Permitted-Exception scope.

## Decision Drivers

- **JTBD-001** (Enforce Governance Without Slowing Down) — solo-developer. Test-green ≡ safe-to-commit signal currently unreliable; contract-assertion bats can pass while the skill's behaviour is broken. This ADR restores the signal.
- **JTBD-101** (Extend the Suite with New Plugins) — plugin-developer. Copy-pasted contract bats propagate the anti-pattern across new plugins. This ADR stops the propagation by making behavioural-default the canonical pattern new plugin authors copy.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — tech-lead. Release / PR / retro / incident reviews trust test-green as behavioural evidence; structural-only evidence breaks that chain.
- **P011** (grep-based bats fragile, closed) — prior art. P011's "grep is fragile" conclusion strengthens to "grep is weak — prefer behavioural".
- **P012** (skill testing harness scope undefined, open) — driver ticket for the framework primitives Layer B will provide. This ADR narrows P012's direction to behavioural-first.
- **P081** (this ticket's direct driver) — user direction.
- **ADR-005** (Plugin testing strategy) — its Permitted-Exception scope narrows under this ADR; ADR-005's hook-testing authority (executable bash hooks under `hooks/test/`) is unaffected.
- **ADR-026** (Agent output grounding) — applies to the new `review-test` agent's output. Verdicts citing "harness gap" must reference a ticket ID, not free-text speculation.
- **ADR-013** (Structured user interaction) — applies to the new agent's output (Rule 1 interactive default; Rule 6 fail-safe).
- **ADR-044** (Decision-delegation contract) — escape-hatch framing. Env-var skip is a category-3 strategic one-time override; in-file justification comment is a category-2 deviation approval. Both are framework-mediated; neither requires per-test-file `AskUserQuestion`.
- **Anthropic `skill-creator` harness** — confirmed prior-art for behavioural skill testing (dual-run with-skill / without-skill / old-skill grader pattern). Stays deferred per ADR-037's reassessment triggers; this ADR is Layer A only.

## Considered Options

1. **Behavioural-default; structural permitted only with documented justification** (rejected per Amendment 2026-06-09) — every test author writes behavioural-first; structural is reserved for cases where the behavioural assertion is not yet expressible under the available framework primitives. A new `review-test` agent under `@windyroad/tdd` classifies test files post-write and emits an advisory verdict. Escape hatches: env var `WR_TDD_REVIEW_TEST=skip` for AFK / retrofit branches; in-file comment `tdd-review: structural-permitted (justification: …)` linking a P012-descendant harness-gap ticket. Rejected by user direction 2026-05-25: *"structural tests not permitted at all."* The escape-hatch surface accumulated into a permanent parking spot rather than a transition mechanism; the `structural-justified` verdict masked behavioural drift; per-file justification comments shipped without follow-through on the harness-gap tickets they cited.

1A. **Behavioural-only (no escape hatch)** (chosen) — every test author writes behavioural; structural assertions on prose-document content (`SKILL.md`, `agent.md`, `*.proposed.md`, `RISK-POLICY.md`, etc.) are not permitted under any justification. The `review-test` agent verdict vocabulary collapses to BEHAVIOURAL / MIXED / STRUCTURAL / UNCLEAR — STRUCTURAL becomes a failing classification, not a permitted one. There is no env-var skip surface and no in-file justification-comment surface. Tests that cannot yet be expressed behaviourally because the harness lacks a primitive (P324 / P176 / P012-descendants) are NOT permitted to ship as structural; they BLOCK on the relevant Layer B harness-gap ticket and ship only once the primitive lands.

2. **Amend ADR-037 in place** — keep ADR-037's frame, narrow its default. Rejected: ADR-037's "SKILL.md as a contract document" framing is the entire reversed premise. Asymmetric correction (amend ADR-005 scope, supersede ADR-037 frame) is cleaner.

3. **Adopt Anthropic `skill-creator` eval harness now** — full dual-run grader-subagent evaluation. Rejected for now per ADR-037's existing reassessment-triggers. Layer B (framework primitives) lands incrementally as harness-gap tickets close. ADR-037's deferral analysis applies unchanged.

4. **PreToolUse blocking gate** — block Edit/Write of test files until the agent verdict returns non-structural. Phase-2 promotion target once the in-tree structural-reliant test files are converted (P290 Phase 2, blocked on P324 Layer B harness).

5. **Status quo (keep ADR-037)** — rejected per the user direction and three documented failure modes.

## Decision Outcome

**Chosen option: Option 1A — Behavioural-only (no escape hatch).**

### Behavioural-test definition

A behavioural test asserts what the target **does** when invoked: its tool-call sequence, its final artefact state, its output text, its exit code, its side-effects on the filesystem. A structural test asserts what the target's source **says**: that a string appears in `SKILL.md`, that a frontmatter field has a particular value, that a section heading is present.

Behavioural is the only permitted kind. Structural assertions on prose-document content (`SKILL.md`, `agent.md`, `*.proposed.md`, `*.accepted.md`, `RISK-POLICY.md`, and similar prose contracts) are not permitted under any justification.

### Per-framework exemplars (canonical)

**bats:**

```bash
# STRUCTURAL (FORBIDDEN)
@test "skill cites P081" {
  run grep -F "P081" "$SKILL_MD"
  [ "$status" -eq 0 ]
}

# BEHAVIOURAL (PERMITTED)
@test "hook denies edit when gate fresh and verdict is REJECT" {
  echo '{"tool_input":{"file_path":"x.ts"},"session_id":"t"}' \
    | bash "$HOOK"
  [ "$status" -eq 2 ]
  [[ "$output" == *"BLOCKED"* ]]
}
```

**vitest:**

```js
// STRUCTURAL (FORBIDDEN)
expect(readFileSync('SKILL.md', 'utf8')).toContain('Step 5');

// BEHAVIOURAL (PERMITTED)
const result = await runSkill({ args: 'baz' });
expect(result.toolCalls).toMatchObject([
  { name: 'Skill', input: { skill: 'wr-itil:manage-problem' } },
]);
```

**cucumber/.feature:**

```gherkin
# STRUCTURAL (FORBIDDEN)
Then the SKILL.md should contain "Step 4a Verification"

# BEHAVIOURAL (PERMITTED)
Then the skill should call AskUserQuestion with options ["amend", "supersede", "one-time"]
```

**pytest:**

```python
# STRUCTURAL (FORBIDDEN)
assert "Step 5" in open("SKILL.md").read()

# BEHAVIOURAL (PERMITTED)
result = run_skill(args)
assert result.artefact_state == expected_tree
```

### No escape hatches

Per the 2026-06-09 amendment, there are no escape-hatch surfaces. The former Surface 1 (`WR_TDD_REVIEW_TEST=skip` env-var) and Surface 2 (in-file `tdd-review: structural-permitted (justification: …)` comment) are removed. The `review-test` agent emits STRUCTURAL as a failing classification, not a permitted one.

Tests that cannot yet be expressed behaviourally because the harness lacks a primitive (P324 / P176 / P012-descendants) BLOCK on the relevant Layer B harness-gap ticket. They do not ship as structural with a justification comment, and they are not skipped via an env-var. The harness-gap ticket is the unblocking work, not the test.

### `review-test` agent

A new Claude Code agent ships under `@windyroad/tdd` at `packages/tdd/agents/review-test.md`. Frontmatter mirrors `packages/architect/agents/agent.md`:

- `name: review-test`
- `tools: [Read, Glob, Grep]`
- `model: inherit`

The agent classifies a test file as STRUCTURAL / BEHAVIOURAL / MIXED / UNCLEAR. Per the 2026-06-09 amendment, `structural-justified` is removed from the vocabulary — STRUCTURAL is a failing classification, not a permitted one. Verdict shape (JSON-in-fenced-block):

```json
{
  "verdict": "structural" | "behavioural" | "mixed" | "unclear",
  "evidence": [
    { "test_name": "...", "line": 42, "why": "asserts grep -F on SKILL.md prose" }
  ],
  "suggestion": "Replace with behavioural assertion: ...",
  "harness_gap": "P324" | "P176" | "P012" | null
}
```

The `harness_gap` field MUST be either a specific ticket ID or `null` per ADR-026 grounding. Free-text speculation about missing primitives is forbidden — name the ticket or emit `null`. When the agent identifies a structural assertion that cannot yet be expressed behaviourally because of a missing harness primitive, it emits `verdict: "structural"` + a non-null `harness_gap` ticket reference — the test BLOCKS on that ticket; it does not ship as structural with a permission marker.

The agent runs in **mechanical / silent classification** stage per project CLAUDE.md (P132 inverse-P078 carve-out). It MUST NOT call `AskUserQuestion` regardless of edge-case ambiguity; if the verdict is genuinely UNCLEAR, the agent emits `verdict: "unclear"` with evidence and suggestion fields populated and lets the main agent escalate at retro time if the unclear-rate trends up.

### Invocation surface

PostToolUse Edit|Write hook at `packages/tdd/hooks/tdd-review-test.sh` triggers when a test-shaped file is written. The hook:

1. Returns immediately if file extension is not test-shaped (`.bats`, `.test.{ts,tsx,js,jsx,py,rb}`, `.spec.{ts,tsx,js,jsx,py,rb}`, `.feature`, `_test.{py,go,rb}`, etc.).
2. Returns immediately if the file path is outside `$PWD` (avoids classifying tests in node_modules, vendored libs, etc.).
3. Otherwise emits an `additionalContext` block telling the assistant to invoke the `review-test` agent against the file before continuing.

Per the 2026-06-09 amendment, the env-var skip + in-file justification-comment short-circuits are removed. Every test-shaped write inside `$PWD` triggers classification.

The hook does NOT block the Edit/Write in Phase 1 — verdict surfaces as advisory context, never as a `permissionDecision: "deny"`. Phase-2 promotion to PreToolUse blocking is the named reassessment trigger below (target: 0 structural-classified test files in-tree).

The hook composes with — does NOT modify — the existing `tdd-post-write.sh` (RGR state machine). Separation of concerns: post-write owns RGR state; review-test owns kind-of-test classification.

### Verdict-shape scope

`review-test` verdicts are PostToolUse advisory output and do NOT persist to ADR-035's `~/.claude/review-reports/` store. A future revision MAY opt into ADR-035's persistence model once `review-test` promotes to PreToolUse blocking and verdicts become release-gating evidence rather than advisory hints. Today's scope is in-session advisory only.

### Migration

The 2026-06-09 amendment removes the documented-justification escape hatch that the original migration plan relied on. The 28 in-tree test files currently carrying `tdd-review: structural-permitted` comments (per `grep -rl 'tdd-review: structural-permitted' packages/`, excluding CHANGELOG.md / SKILL.md / the agent + hook source files) are tracked by **P290 Phase 2** for behavioural conversion. The conversion is **blocked on P324** (agent-prose-verdicts have no behavioural harness — Layer B harness primitive).

Migration shape under the amendment:

1. The `review-test` agent vocabulary update + the `tdd-review-test.sh` hook escape-logic removal land as Phase 2 work alongside the test conversions.
2. Until P324 ships and P290 Phase 2 completes, the in-tree structural test files persist as-is. They are NOT permitted under this ADR — they are a known-state-of-violation tracked by P290.
3. Downstream ADRs that reference the old Surface-2 framing (ADR-064 line 130, ADR-068 line 82, ADR-075 line 53) update in lockstep as their referenced mechanism is removed.

New test files MUST be behavioural. The advisory hook continues firing in Phase 1; once Phase 2 completes (in-tree converted; structural-classified count = 0), the hook promotes to PreToolUse blocking per the Reassessment criterion below.

### ADR-005 narrowing (cross-ADR amendment)

This ADR amends ADR-005's Permitted-Exception clause. ADR-005 retains authority over hook-script testing including its existing exceptions (hooks.json content checks; file-existence / file-removed checks; safety-construct presence such as `set -euo pipefail`). The narrowing excludes prose-document content greps (SKILL.md, agent.md, *.proposed.md, RISK-POLICY.md) from the Permitted-Exception scope; those are governed by this ADR's behavioural-default rule.

ADR-005 keeps its `proposed` status. This ADR's amendment lands in ADR-005 as an additive sub-clause inside the Permitted-Exceptions list and a `[Reassessment Triggered 2026-05-03 per ADR-052]` flag in ADR-005's Reassessment Criteria section (parallel to the existing `[Reassessment Triggered 2026-04-21 per ADR-037]` flag).

## Consequences

### Good

- Test-green becomes a load-bearing behavioural signal again. JTBD-001/101/201 audit-trail integrity restored.
- Contract drift through misleading-phrasing-pass is caught: behavioural assertions fire on actual interpretation, not on keyword presence.
- Semantics-preserving SKILL.md compression no longer fails CI (the `install-updates` 2026-04-22 incident class is closed).
- Plugin authors copy-pasting test patterns inherit the behavioural-default; the propagation chain that made structural-grep contagious flips polarity.
- `review-test` agent's per-framework exemplars give plugin authors a concrete pattern library across bats / vitest / cucumber / pytest. The "clear patterns, not reverse-engineering" JTBD-101 constraint is served.
- ADR-044 framework-resolution boundary is honoured: per-test-file decisions (classify) are framework-mediated, not user-asked.
- (Amendment 2026-06-09) The single rule "behavioural-only" is a clearer pattern for new plugin authors than "behavioural-default + two escape hatches + `structural-justified` verdict." Reduces propagation surface that previously made structural-grep contagious across new plugins (JTBD-101 "clear patterns, not reverse-engineering" served better).

### Neutral

- Every new test file in `@windyroad/*` plugins now passes through the `review-test` advisory. Per-fire cost is bounded (one Read + one agent classification call). For AFK loops with ~5-10 test-file edits per iter × ~30 iter, total session cost is manageable.
- Existing ~50+ structural bats remain in-tree and continue passing; their migration is opportunistic per Plan §1.
- Test authors writing genuinely-permitted structural assertions (hook safety-constructs per ADR-005) remain unaffected: the agent classifies those as structural-justified by virtue of the file path being `hooks/test/*.bats` AND the assertion targeting executable bash, not prose.

### Bad

- Phase 1 advisory surface relies on the assistant honouring the `review-test` directive. If the assistant skips the agent invocation under load (long context, AFK iter loop), the advisory becomes unreliable. Promotion criterion below addresses this.
- The `review-test` agent's classification quality is bounded by Claude's understanding of "behavioural vs structural" semantics across frameworks. False-negatives (classifies structural as behavioural) leak into the suite; false-positives (classifies behavioural as structural) generate noise. ADR-026 grounding (verdict cites specific evidence per assertion) reduces the false-positive rate; the false-negative rate is mitigated by the user's retro-time review cycle.
- (Amendment 2026-06-09) **Layer-B blocker is now a hard gate, not a soft transition.** Tests that need a Layer B harness primitive cannot ship as structural-with-justification any more — they BLOCK on the relevant P324 / P176 / P012-descendant ticket. This raises the priority on Layer B harness work (P324 in particular) from "incremental backlog" to "release-gating for the test-coverage of any new agent-prose verdict surface." The amendment surfaces this as a backlog ranking signal: P324 and siblings rise in WSJF because they now block whole feature surfaces, not just optional test-quality improvements.
- (Amendment 2026-06-09) **Contradiction window during P290 Phase 2.** Between the 2026-06-09 amendment landing (Phase 1: docs/policy) and P290 Phase 2 completing (in-tree conversion + agent + hook source changes), the 28 in-tree structural test files persist in violation of this ADR. The contradiction is tracked in the P290 ticket body, not in this ADR. The hook continues firing advisory-only in this window; promotion to blocking waits for the in-tree count to hit zero.
- Per-fire CPU cost of the PostToolUse hook is small (jq + grep + JSON pass-through) but cumulative across an AFK loop. No performance-budget ADR covers this surface today; ungoverned risk is small (silent on most fires) but not formally accepted. Future `<NNN>-performance-budget-tdd-hooks.proposed.md` MAY land if the budget becomes load-bearing.

## Confirmation

The decision (as amended 2026-06-09) is satisfied when:

**Phase 1 (this iter — docs/policy):**

1. **ADR-052 amendment lands** at `docs/decisions/052-behavioural-tests-default-for-skill-testing.proposed.md` with `human-oversight: unconfirmed` + `oversight-date: 2026-06-09`, removing Surface 1 + Surface 2 from the body, collapsing the verdict vocabulary, and stating "behavioural-only" as the policy.

2. **ADR-005 narrowing tightens** — the "Excluded from this clause (per ADR-052)" sub-clause in ADR-005 removes the `tdd-review: structural-permitted` permission language. ADR-005's `human-oversight` clears to `unconfirmed` + `oversight-date: 2026-06-09` (substance change per ADR-066 Reassessment).

3. **ADR-064 stale cross-reference cleaned** — line 130 drops the "Surface 2 `structural-justified` framing for the agent.md doc-lint" half-sentence (mechanical, no marker clearance).

4. **P290 ticket body updated** — Investigation Tasks reflect Phase 1 done; Phase 2 enumerated with the 28 in-tree test files, downstream-consumer list (ADR-068, ADR-075, agent + hook source), and P324 Layer B blocker noted; open substance question on transition treatment of in-tree tests queued for next interactive turn.

5. **Decisions compendium regenerated** — `wr-architect-generate-decisions-compendium` runs and `docs/decisions/README.md` updates in the same commit.

**Phase 2 (deferred, blocked on P324):**

6. **`review-test` agent vocabulary updated** at `packages/tdd/agents/review-test.md` — STRUCTURAL becomes a failing classification; `structural-justified` removed from vocabulary; verdict shape collapses to behavioural / mixed / structural / unclear.

7. **`tdd-review-test.sh` hook escape logic removed** — env-var short-circuit + justification-comment short-circuit removed; hook fires on every test-shaped write inside `$PWD`.

8. **28 in-tree structural-reliant test files converted** to behavioural assertions (or deleted if the surface they cover is no longer relevant); Layer B harness primitives (P324 et al.) ship as needed to make the conversions expressible.

9. **Changeset lands** for `@windyroad/tdd` minor bump.

10. **No regression in existing TDD hook bats** — `tdd-enforce-edit.sh`, `tdd-post-write.sh`, `tdd-inject.sh`, `tdd-setup-marker.sh`, `tdd-reset.sh` all continue passing.

**Phase 3 (post-Phase-2):**

11. **Hook promotes to PreToolUse blocking** — once the in-tree structural-classified count hits 0, the advisory PostToolUse hook promotes to a blocking PreToolUse hook.

12. **Re-confirm via the drain** — `/wr-architect:review-decisions` surfaces the amended ADR-052 for human-oversight; the user confirms (or amends further). P290 closes.

## Pros and Cons of the Options

### Option 1: Behavioural-default with documented-justification escape hatches (rejected per 2026-06-09 amendment)

- **Good**: catches misleading-phrasing-pass + behavioural-regression-slip + refactor-blocking-false-negative; per-framework exemplars give plugin authors concrete patterns; escape hatches kept migration incremental; ADR-044-aligned escape framing; the agent could run silently in AFK loops without surfacing consent gates.
- **Bad** (now decisive): classification quality bounded by Claude's semantics-judgement; advisory-only surface relies on assistant honouring the directive; harness-gap tickets accumulate before primitives ship; **the escape-hatch surface became a permanent parking spot rather than a transition mechanism — `tdd-review: structural-permitted` justifications shipped across 28 in-tree test files with no follow-through on the harness-gap tickets they cited.** User direction 2026-05-25 rejected this option.

### Option 1A: Behavioural-only (no escape hatch) (chosen per 2026-06-09 amendment)

- **Good**: single rule is a clearer pattern for new plugin authors (JTBD-101 "clear patterns, not reverse-engineering" served better); removes the parking-spot surface entirely so harness-gap tickets cannot be deferred indefinitely behind a permission marker; raises priority on Layer B harness work (P324 et al.) from "incremental backlog" to "release-gating for any new agent-prose verdict surface."
- **Bad**: the Layer-B blocker is now a hard gate, not a soft transition — tests that need a harness primitive cannot ship as structural-with-justification any more; in-tree contradiction window persists from amendment landing to P290 Phase 2 completion (tracked in P290 ticket body); the 28 in-tree structural test files cannot ship as compliant under this ADR until conversion completes.

### Option 2: Amend ADR-037 in place

- **Good**: one ADR instead of two.
- **Bad**: ADR-037's "SKILL.md as contract document" framing is the entire reversed premise. Amending leaves contradictory framing in the same file. Asymmetric correction (amend ADR-005 scope, supersede ADR-037 frame) is the cleaner shape.

### Option 3: Adopt Anthropic skill-creator harness now

- **Good**: catches the behavioural-drift class directly; industry prior-art with grader-subagent + benchmark aggregation.
- **Bad**: grader-subagent authorship is itself ~1/2 of P012's XL scope; runtime cost per eval is substantial; CI integration requires new tooling. ADR-037's existing reassessment-triggers preserved here unchanged — adopt when triggers fire.

### Option 4: PreToolUse blocking gate

- **Good**: catches structural tests at write time; cannot be skipped.
- **Bad**: ~50+ existing structural bats in-tree would all block edits at landing. Promotion criterion in Reassessment lets this become Phase 2.

### Option 5: Status quo (keep ADR-037)

- **Good**: zero effort.
- **Bad**: three documented failure modes recur; user direction explicit; copy-paste propagation continues.

## Reassessment Criteria

Re-evaluate this decision if:

- **Promotion to PreToolUse blocking** — when the count of structural-classified in-tree test files drops to 0 (i.e. P290 Phase 2 completes — all 28 in-tree structural-reliant test files are converted to behavioural and the `review-test` agent emits no STRUCTURAL verdicts on the suite), promote the hook from PostToolUse advisory to PreToolUse blocking. The advisory-only surface is intended as a Phase-1 transition mechanism; once Phase 2 completes, blocking is the right shape.
- **Advisory-skip rate becomes load-bearing** — if retro-time review reveals the assistant skipping the `review-test` directive on >20% of test-file edits, escalate to PreToolUse blocking earlier (skipping defeats the advisory's purpose).
- **Classification false-negative rate recurs** — if structural tests slip past the agent's classifier and cause documented incidents (e.g. a SKILL.md prose drift not caught), tighten the agent prompt with the missed-case as a new exemplar.
- **Anthropic skill-creator harness stabilises** — if Anthropic ships a public, stable API for skill evaluation, evaluate Option 3 again per ADR-037's existing trigger.
- **Layer B primitives mature** — when the harness-gap surface (Skill-tool interceptor, AskUserQuestion stub, filesystem sandbox, subagent return stub, agent-prose-verdict harness per P324) has sufficient primitives that 100% of skill / agent behaviours are expressible behaviourally, the Layer B blocker no longer holds new test work. Until then, P324 / P176 / P012-descendant tickets gate the test work that depends on them.
- **The `review-test` agent's per-fire cost grows** — if AFK iter latency increases observably due to the PostToolUse hook, scope the hook's input or batch-classify per iter rather than per-edit.

## Related

- **P290** — Amendment 2026-06-09 driver ticket. Tracks Phase 1 (docs/policy this iter) + Phase 2 (28 in-tree test conversions + agent + hook source changes, blocked on P324).
- **P324** — Layer B harness primitive ticket (agent-prose verdict behavioural harness). Blocks P290 Phase 2 in-tree conversions of agent-prose-verdict tests.
- **P176** — Skill-invocation behavioural-test harness gap. Sibling Layer B blocker.
- **P081** — driver ticket; this ADR is its Layer A + Layer C deliverables.
- **P011** — closed; grep-fragility prior art. This ADR strengthens P011's conclusion.
- **P012** — open; harness-scope ticket. This ADR narrows P012 to behavioural-first.
- **ADR-037** (Skill testing strategy) — superseded by this ADR.
- **ADR-005** (Plugin testing strategy) — Permitted-Exception scope amended by this ADR; ADR-005's hook-testing authority unchanged.
- **ADR-013** (Structured user interaction) — Rule 1 + Rule 6 govern the `review-test` agent's output formatting.
- **ADR-014** (Commit discipline / batch grain) — single commit for ADR + agent + hook + bats + changeset is acceptable as one coherent feature batch.
- **ADR-026** (Agent output grounding) — `harness_gap` field MUST cite a specific ticket or be `null`.
- **ADR-035** (Centralised review reports) — `review-test` verdicts explicitly NOT in scope for this store today; future Phase-2 promotion may opt in.
- **ADR-044** (Decision-delegation contract) — escape-hatch framing: env-var = category 3; in-file comment = category 2.
- **ADR-045** (Hook injection budget for PreToolUse/PostToolUse) — silent-on-non-test-file pattern conforms to ADR-045's silent-on-pass discipline.
- **JTBD-001, JTBD-101, JTBD-201** — primary persona-job anchors.
- `packages/architect/agents/agent.md` — agent prompt shape precedent.
- `packages/risk-scorer/agents/wip.md` — mode-specific agent precedent.
- `packages/tdd/hooks/tdd-post-write.sh` — PostToolUse hook precedent the new hook composes alongside.
- Anthropic `skill-creator` harness — https://github.com/anthropics/claude-plugins-official/blob/main/plugins/skill-creator/skills/skill-creator/SKILL.md — deferred prior art.
