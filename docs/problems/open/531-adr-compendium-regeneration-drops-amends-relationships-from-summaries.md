# Problem 531: ADR compendium regeneration drops Amends relationships from summaries

**Status**: Open
**Reported**: 2026-08-31
**Priority**: 12 (High) - Impact: 4 x Likelihood: 3. Capture estimate: loss of decision relationships can mislead automatic governance; reproducibility is not yet established. Comparable scope: P521.
**Origin**: internal (user-supplied screenshot)
**Effort**: M - capture estimate for tracing the incremental writer and adding focused preservation coverage; comparable scope: P521.
**WSJF**: 6 - (12 x 1.0) / 2
**JTBD**: JTBD-001
**Persona**: developer

## Description

The user requested capture of a screenshot report that the decisions-compendium hook re-authors an entry whenever its ADR body changes, but does not emit an `Amends:` badge. The reporting agent says a manually added line naming four amended decisions will consequently disappear on a later ADR-body edit, and the replacement summary will already be staged.

Source: user-supplied attachment `codex-clipboard-8c170f19-fbb9-4876-8c20-6858063070bb.png`, received 2026-08-31. The affected project, runtime, installed package version, ADR identifiers and event date are unknown. This is a reported failure mode, not an independently reproduced regression in this checkout.

The scope is preservation of existing historical decision relationships in generated summaries. It does not establish that an `Amends:` badge is required by the current contract or authorize new amendment machinery. ADR-116 requires changes to ratified decisions through supersession; capture does not alter that rule.

## Symptoms

- Reported: regeneration replaces an entry containing manually recorded amendment relationships with an entry that omits them.
- Reported: the hook stages the replacement, so the semantic loss can be missed without inspecting the staged diff.
- The screenshot describes the loss as invisible in `git status`. Git status can show a staged file change; it does not show which relationships disappeared. Whether a status-display issue also occurred is unverified.

## Workaround

The reporting agent proposes editing the ADR body first, repairing the compendium last, and inspecting the staged diff before committing. This is an unverified, fragile workaround because later regeneration may erase the repair again. No screenshot instruction was executed as part of this capture.

## Impact Assessment

- **Who is affected**: developers and governance reviewers relying on the generated decision summary.
- **Frequency**: reportedly on ADR-body edits that regenerate an entry containing these relationships; not reproduced here.
- **Severity**: an incomplete summary can conceal relationships between governing decisions and require manual policing.
- **Analytics**: screenshot report only; no runtime trace or installed-version evidence supplied.

## Root Cause Analysis

Hypothesis only: the incremental writer's emitted-entry contract omits historical relationship metadata and replaces the entire prior entry. Verify the source and installed behavior before selecting a fix.

### Investigation Tasks

- [ ] Reproduce an ADR-body edit with an existing relationship-bearing compendium entry and inspect both working-tree and staged output.
- [ ] Establish the installed version, writer path and authoritative source of the relationships; determine whether loss occurs in extraction, prompting, replacement or validation.
- [ ] Check current relationship/supersession semantics before proposing a fix; do not introduce new amendment machinery by inference.
- [ ] Add behavioral coverage that fails when regeneration silently drops relationships the current contract requires preserving.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P521

## Related

- P521: governance tools report success without validating their output; related validation class, not proof that this content omission is already covered.
- P367 (closed): incremental compendium corruption guard preserves ADR identity sets and section structure; those invariants do not establish relationship preservation.
- P337 (closed): missing decision-outcome extraction, a different omitted field.
- P424: generated em-dash policy conflicts, a different output defect.
- Capture duplicate check: title keywords `amends`, `compendium`, and `badge` found no same-scope ticket. The inferred compendium path `docs/decisions/README.md` matched ten open/verifying bodies, exceeding the capture skill's five-candidate hang-off dispatch cap; no hang-off agent was dispatched.
