# Problem 330: derive-release-vehicle helper requires pre-edit of ticket changeset reference — three-touch when one-touch would suffice

**Status**: Open
**Reported**: 2026-05-30 (work-problems wrap retro)
**Priority**: 6 (Medium) — Impact: 2 (Minor — adopter UX friction on every K→V transition; recoverable via documented exit-2 routing) × Likelihood: 3 (Possible — fires on every K→V where the changeset reference isn't already in the ticket body)
**Effort**: S (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical
**WSJF**: 3.0 (deferred — re-rate at next /wr-itil:review-problems)

## Description

The `wr-itil-derive-release-vehicle` helper (shipped @windyroad/itil@0.37.0 iter 1 this session; dogfooded 3 times in K→V iters this session) exits 2 with `ERROR: no .changeset/<name>.md reference in <ticket-path>` when invoked before the K→V transition writes the `## Fix Released` section. K→V is typically the surface that adds the changeset reference — so the contract forces a three-touch sequence per K→V transition: pre-edit ticket to seed changeset reference, run helper, then edit citation block. One-touch would suffice if either the helper or the manage-problem fix-ship step seeded the reference deterministically.

## Symptoms

- 4 K→V dogfoods this session (P267 iter 2, P316 iter 5, P281 iter 8, P302 iter 10). Of those:
  - P267 iter 2: inherited the changeset reference from prior iter 1 work (worked first-call)
  - P316 iter 5: required exit-2 routing — append changeset path to ticket body, re-run helper
  - P281 iter 8: required exit-2 routing — same pattern as P316
  - P302 iter 10: required exit-2 routing — same pattern as P316/P281 (4th data point; 3/4 dogfoods = 75% hit rate)
- Helper script: `packages/itil/scripts/derive-release-vehicle.sh` line 109 (the contract check that emits the ERROR).
- Concrete observable: iter 8 first probe returned `ERROR: no .changeset/<name>.md reference in docs/problems/known-error/281-...md` exit 2; iter manually appended the reference, second probe returned exit 0. iter 10 (P302) reproduced exactly: first probe `ERROR: no .changeset/<name>.md reference in docs/problems/known-error/302-...md` exit 2; appended `**Release vehicle**: .changeset/p302-decision-confirmation-presentation-rule.md ...` paragraph to Fix Strategy; second probe exit 0 with full citation.
- Cross-iter session evidence: 3 of 4 dogfoods (~75%) hit the friction — sustained pattern, confirmed across sessions (P302 iter 10 is a separate subprocess from P281 iter 8; same defect class fires reliably).

## Workaround

Pre-edit the ticket file to insert the changeset filename reference before invoking `wr-itil-derive-release-vehicle <ticket-id>`. Documented in the transition-problem SKILL contract.

## Impact Assessment

- **Who is affected**: every K→V transition using the helper (orchestrator iters + interactive `/wr-itil:transition-problem to-verifying` invocations).
- **Frequency**: 2 of 3 K→V dogfoods this session (~66%); ~5-10 K→V transitions per week typical sustained rate.
- **Severity**: Minor — recoverable via documented routing, not a blocker. But UX friction compounds over many K→V cycles.
- **Analytics**: friction observed only on the helper-call surface; no production damage; no adopter-side impact.

## Root Cause Analysis

### Why the helper requires the reference up-front

The helper's contract is "derive release vehicle from a closed-ticket file body that already cites the changeset". The original design assumed the changeset reference would be in the ticket body BEFORE K→V — typical for the manage-problem flow where the fix commit explicitly names the changeset in the ticket (fold-fix pattern, `closes P<NNN>` commit). But the standalone K→V transition path (where the fix shipped in a prior iter and K→V is its own iter) doesn't seed the reference — there's no fold-fix to drag the reference into the body.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Confirm the 3 candidate fix options below + architect verdict on which option fits ADR-049 shim contract + ADR-022 lifecycle
- [ ] Bats coverage extending derive-release-vehicle.bats with the K→V-standalone path

## Fix Strategy

Three candidate options (architect verdict needed):

- **Option A**: helper accepts `--changeset <name>` flag for first-K→V cases — caller passes the changeset path explicitly, no ticket edit required.
- **Option B**: `/wr-itil:manage-problem` Step N (fix-ship time) inserts changeset reference inline as part of the `**Fix Shipped:**` frontmatter shape — every fix-ship seeds the reference deterministically.
- **Option C** (combine): helper accepts flag AND manage-problem ships reference inline.

**Kind**: improve  
**Shape**: script (helper script + optional SKILL.md update)  
**Target file**: `packages/itil/scripts/derive-release-vehicle.sh` + `packages/itil/skills/transition-problem/SKILL.md` Step 6 + possibly `packages/itil/skills/manage-problem/SKILL.md`  
**Observed flaw**: 3-touch K→V cycle when 1-touch would suffice; helper assumes prior reference seed that standalone K→V iter doesn't provide  
**Edit summary**: per architect verdict, add `--changeset` flag to helper OR add seeding step to manage-problem fix-ship surface OR both

## Dependencies

- **Blocks**: (none — workaround works)
- **Blocked by**: (none)
- **Composes with**: ADR-049 (`bin/` PATH naming grammar), ADR-022 (Verifying lifecycle), `/wr-itil:transition-problem` Step 6, `/wr-itil:work-problems` Step 5 K→V iter pattern

## Related

- P267 (Verifying — the codification ticket that shipped the helper this session)
- P281 (Verifying — second K→V dogfood instance where exit-2 routing required)
- P316 (Verifying — first K→V dogfood instance where exit-2 routing required)
- P302 (Verifying — fourth K→V dogfood instance where exit-2 routing required; transitioned this iter)
- 2026-05-30 work-problems iter 8 retro observation (captured in `docs/retros/2026-05-30-work-problems-iter8-p281-kv.md` outstanding_questions)
- 2026-05-30 work-problems wrap retro (P330 capture)
- 2026-05-30 work-problems iter 10 retro (P302 K→V dogfood — this evidence append)
