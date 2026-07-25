# Problem 461: Downstream evidence-scan flags adopter-repo sightings as live regressions without version-gating against the fix release

**Status**: Open
**Reported**: 2026-07-25
**Priority**: 9 (Medium) — Impact: 3 (Moderate — causes wrong lifecycle transitions: fixed tickets flipped back to Known Error, wasting re-work and misrepresenting state) × Likelihood: 3 (Possible — fires whenever an evidence-mining pass scans adopter transcripts) — derived at capture
**Origin**: internal
**Effort**: M — a version-gate check in the downstream-scan method + a contract note in the review/evidence-mining SKILL

**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

When mining adopter-repo transcripts for evidence (the `/wr-itil:review-problems` second-pass / downstream close-or-reopen method), a sighting of a "fixed" bug still occurring in an adopter repo is treated as a **live regression** and routed to reopen — without first checking whether the adopter's **installed plugin version predates the fix**. Adopters lag behind published versions, so a post-fix-date sighting in an adopter transcript is frequently a **stale-install artifact**, not a live source regression.

Concrete cost, 2026-07-25 (this session): the downstream-scan flagged P281 (capture-problem flat-path) and P365 (external-comms private-repo commit) as "still recurring in adopters" based on addressr/voder-mcp-hub transcript sightings. Both were flipped from Verifying → Known Error on that signal. On verification, the current source is CLEAN for both (P281 writes per-state + auto-migrates; P365 has the repo-visibility precondition) — the sightings were stale adopter installs (voder explicitly on itil 0.35.6, months behind). Both had to be flipped back to Verifying. The two wrong transitions were avoidable with a version-gate.

Same root as the appetite-semantics observation left in this session (adopters silently run stale plugin semantics) — but this ticket is specifically about the **evidence-mining method** over-flagging, not the runtime stale-semantics itself.

## Symptoms

- An evidence-mining pass reports "regression recurs in <adopter>" and routes a ticket to reopen, but the adopter's transcript is from a plugin version older than the fix.
- Fixed tickets get flipped Verifying → Known Error on stale-install signals, then flipped back after source verification.
- The reviewer (agent or human) does the source-verification only after acting, not before.

## Workaround

Before treating an adopter-repo sighting as a live regression, verify the fix's presence in **current source** AND, where determinable, the adopter's **installed plugin version** vs the fix release. If current source is clean, the sighting is a stale-install artifact — do not reopen; keep/return to Verifying.

## Impact Assessment

- **Who is affected**: the maintainer running evidence-mining / review-problems passes; ticket-state integrity
- **Frequency**: whenever a downstream/adopter scan runs (increasingly, as the suite ships more adopter-facing surfaces)
- **Severity**: Moderate — wrong transitions + re-work, not data loss
- **Analytics**: N/A

## Root Cause Analysis

### Preliminary Hypothesis

The downstream-scan method (and the sub-agents that implement it) treat "bug signature present in adopter transcript after the fix date" as sufficient for a regression verdict. It should additionally require: (a) the fix is ABSENT from current source, OR (b) the adopter's installed version is ≥ the fix release. Absent either check, a post-fix adopter sighting is presumptively stale-install and must NOT drive a reopen. This is a specialisation of the "verify before asserting" discipline applied to the cross-adopter evidence axis.

### Investigation Tasks

- [ ] Add a version-gate step to the downstream-scan contract in `/wr-itil:review-problems` (and the evidence-mining sub-agent prompts): source-clean OR adopter-version ≥ fix-release before a regression verdict
- [ ] Decide whether adopter installed-version is determinable from transcripts (plugin cache paths carry versions) or must be assumed-stale
- [ ] Behavioural coverage for the "stale-install sighting → NOT a regression" path

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: the stale-adopter-version runtime-semantics gap (surfaced + left this session), P434 (capture flows write unverified claims as fact — same verify-before-asserting family)

## Related

- P281, P365 — the two tickets wrongly flipped this session on un-version-gated adopter sightings, then corrected.
- P151/P153 — the counter-case: adopter sightings that WERE a real live residual (verified in current source), correctly fixed. The method must distinguish these two cases; the version-gate is how.
- P434 — capture flows write unverified premise/root-cause as fact (same discipline family).

(captured via direct write; sibling to P434 / the stale-adopter-version gap, distinct mechanism — the evidence-mining method's missing version-gate)
