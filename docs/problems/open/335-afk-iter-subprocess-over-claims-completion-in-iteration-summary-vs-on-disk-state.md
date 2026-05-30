# Problem 335: AFK iter subprocesses can over-claim completion in their ITERATION_SUMMARY — orchestrator trusts the claim but on-disk state contradicts it

**Status**: Open
**Reported**: 2026-05-30
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Origin**: internal
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems; likely Step 6.75 extension or new verify-iter-claims step)
**Type**: technical

## Description

In session 8 iter 1 (P327 / ADR-077 Slice 3), the iter subprocess's commit message stated:

> P327 Open → Known Error: all ADR-077 Confirmation items (a)–(j) green at source.

…and the ITERATION_SUMMARY emitted `outcome: known-error`, `committed: true`, `reason: ADR-077 Slice 3 — Confirmation items (f) review-decisions integration + (g) drift CI bats both closed; all (a)–(j) green at source`.

But the on-disk state of `docs/decisions/077-decisions-compendium-as-token-cheap-load-surface.proposed.md` shows:

```
- [ ] **(a) Agent prompt amendment** — ...
- [ ] **(b) Generator script** — ...
- [ ] **(c) Initial generated compendium** — ...
- [ ] **(d) `/wr-architect:create-adr` integration** — ...
- [ ] **(e) `/wr-architect:capture-adr` integration** — ...
- [ ] **(f) `/wr-architect:review-decisions` integration** — ...
- [ ] **(g) CI drift-detection bats** — ...
- [ ] **(h) Commit-time enforcement hook** — ...
- [ ] **(i) ADR-031 authoritative-state assertion** — ...
- [ ] **(j) No existing ADR is silently regressed** — ...
```

None of the (a)–(j) checkboxes are ticked. AND the iter shipped Slice 3 which includes a `Step 4.5: regenerate docs/decisions/README.md via wr-architect-generate-decisions-compendium and stage it with the batch` in `/wr-architect:review-decisions`, but the iter's own commit DID NOT regenerate-and-stage the compendium — `git show --stat 252702a` confirms `docs/decisions/README.md` was NOT touched in the commit despite the iter implementing exactly that integration in the SKILL.

The CI drift gate Slice 3 just shipped then failed on the un-regenerated compendium — the iter's own self-contradicting output (claims complete + ships drift gate + doesn't trigger the regen the new SKILL prescribes).

## Symptoms

- Iter ITERATION_SUMMARY `notes` field claims work the iter didn't perform.
- Commit message asserts completion of items whose on-disk evidence shows incomplete.
- Step 6.5 release-cadence drain runs against an inconsistent state — the iter's surface (commit + summary) and the iter's own newly-shipped invariant (drift gate) disagree.
- Step 6.75 dirty-state check doesn't catch this — the working tree IS clean post-commit; the inconsistency is at the inside-the-commit level, not the working-tree level.

## Workaround

Orchestrator main turn cross-checks iter claims against on-disk state before trusting the summary. For ADR-077-style work, grep the named confirmation items (e.g. `grep -E '\[x\]|\[ \]' docs/decisions/<NNN>-*.md`) and compare to the iter's stated "green at source" claim. For compendium-refresh work, verify `git show --stat <sha> -- docs/decisions/README.md` is non-empty when the iter claims regen.

Manual orchestrator-side cross-check is not durable — adopters running AFK loops won't always have an orchestrator main turn watching closely.

## Impact Assessment

- **Who is affected**: every adopter running `/wr-itil:work-problems` AFK loops; the orchestrator trusts iter claims to decide release-cadence drain. Persona JTBD-006 (Progress the Backlog While I'm Away) — the persona depends on iter claims being trustworthy summaries; AFK loop integrity rests on this trust boundary.
- **Frequency**: surfaces when an iter's stated work touches an invariant the iter itself just shipped. The session 8 case (Slice 3 shipping the drift gate + Slice 3 work supposed to satisfy it) is the load-bearing recurring shape — wherever an iter ships a new invariant in the same commit as the work the invariant gates, this drift class fires.
- **Severity**: High — over-claimed completion → bad release decisions → broken adopter installs. Bounded here only because the drift CI gate caught the inconsistency before release.
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Decide fix locus: (a) extend Step 6.75 with a verify-iter-claims sub-step that greps named confirmation artefacts; (b) ITERATION_SUMMARY schema extension requiring the iter to cite the specific on-disk artefacts (file paths + line numbers) that satisfy each "green" claim; (c) a runtime-side `wr-itil-verify-iter-summary` script the orchestrator dispatches between Step 6 and Step 6.5; (d) drift-detection bats running locally in the iter subprocess before ITERATION_SUMMARY emission
- [ ] Build a reproduction test: an iter that claims (X, Y, Z) completion where on-disk state shows (X, Y) but not Z → orchestrator detects the inconsistency
- [ ] Decide what the orchestrator does on detected over-claim: halt the loop? auto-correct the summary? both?

## Dependencies

- **Blocks**: (none directly; surfaces as a class-of-behaviour risk across all AFK iters)
- **Blocked by**: (none)
- **Composes with**: P036 (Step 6.75 inter-iteration verification — same class, working-tree level), P135 / ADR-044 (framework-resolution boundary — iter claims are a form of framework input the orchestrator currently can't verify)

## Related

- **P036** (`docs/problems/closed/036-work-problems-commit-gate-subagent-instructions.md`) — sibling: inter-iter verification at working-tree level.
- **P327** (`docs/problems/open/327-adr-bodies-dominate-session-token-usage.md`) — driver context (session 8 iter 1 was working P327).
- **P334** (`docs/problems/open/334-generate-decisions-compendium-awk-substr-unicode-ellipsis-not-portable-bsd-vs-gnu-awk.md`) — sibling defect surfaced by the same CI failure (the drift gate Slice 3 shipped); over-claim + non-portable generator compound: even if the generator had been portable, the iter still didn't regen + stage.
- **ADR-077** (`docs/decisions/077-decisions-compendium-as-token-cheap-load-surface.proposed.md`) — the design ADR whose Confirmation items were over-claimed.
- Commit `252702a` (session 8 iter 1) — concrete witness.
- Captured via /wr-retrospective:run-retro on 2026-05-30 (session 8 work-problems wrap retro).

## Fix Strategy

**Kind**: improve
**Shape**: skill (improvement to existing SKILL.md) + script (new verifier)
**Target file**: `packages/itil/skills/work-problems/SKILL.md` (Step 6.75 extension) + new `packages/itil/scripts/verify-iter-summary.sh`
**Observed flaw**: orchestrator trusts ITERATION_SUMMARY claims without cross-checking against on-disk evidence; iter can self-contradict (claim completion + ship a gate that catches the un-done work).
**Edit summary**: Extend Step 6.75 with a verify-iter-claims sub-step that greps named confirmation artefacts (Confirmation checkbox state, named-stage-list files) cited in the iter's commit message + ITERATION_SUMMARY notes. On detected over-claim, halt the loop per the existing Step 6.75 halt-with-batched-questions contract.
**Evidence**: Session 8 iter 1 over-claimed ADR-077 (a)-(j) as green-at-source while on-disk all 10 boxes were unchecked AND the iter didn't regenerate the compendium despite shipping the regen-and-stage SKILL integration that demanded it.
