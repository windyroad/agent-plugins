# Problem 425: wr-architect edit-gate re-litigates its own same-session PASS — [Unratified Dependency] over-fires on agent-prescribed born-proposed ADRs

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#342)
**Effort**: M. WSJF = (9 × 2.0) / 2 = 9.0.
**WSJF**: 9.0 — (9 × 2.0) / 2 (re-rated 2026-07-26 on the Open → Known Error transition; Effort held at M — the fix surface narrowed to one agent-prose file plus one predicate, but the option pick is unratified so the design half is still live)
**JTBD**: JTBD-006 (primary — progress the backlog while I'm away), JTBD-001 (secondary — enforce governance without slowing down)
**Persona**: developer

> **Re-anchored 2026-07-26** on the JTBD gate's instruction, replacing the AFK-auto-capture defaults (`JTBD-101` / `plugin-developer`). `JTBD-101` (extend the suite with new plugins) was a genuine mis-anchor — P425 builds no plugin and changes no package structure. Persona moved to `developer` because `JTBD-006` and `JTBD-001` both carry `persona: developer`, and the harmed party is anyone running an AFK loop with `@windyroad/architect` installed, including adopters; `plugin-developer` describes the fix locus, not the job holder, and would understate the blast radius.

## Description

A fresh, stateless architect review re-flags a just-captured born-proposed ADR as an `[Unratified Dependency]` blocker — an ADR the same architect prescribed minutes earlier in the same session. Under AFK, mid-loop ratification is structurally impossible, so the flag burns the iteration: a same-session PASS is re-litigated against its own output.

> **Mechanism corrected at root-cause confirmation (2026-07-26).** This description originally attributed the deadlock to the `docs/decisions/` commit invalidating the drift-hash marker. Reading the source showed that is not the cause — `architect-refresh-hash.sh` already refreshes the hash on an allowed write to `docs/decisions/`, and the substance hash excludes `README.md`, so the compendium regen does not drift it either. The deadlock needs no marker invalidation: the guard is stateless, so **any** fresh spawn in the session re-flags. See Root Cause Analysis.

## Symptoms

- Architect prescribes an ADR capture mid-iter (PASS). The ADR lands born `human-oversight: unconfirmed`. The next architect edit-gate invocation (same session) re-reads the tree, finds the unratified ADR, and denies — deadlock in AFK.
- This is precisely the over-firing case that P318 (which added the `[Unratified Dependency]` guard) dismissed as "born-confirmed keeps the unratified set near zero."

## Impact Assessment

- **Who is affected**: AFK work-problems loops that touch architecture; the loop stalls on its own prescribed ADR.
- **Frequency**: any iter that captures a born-proposed ADR then needs a further gated edit.
- **Severity**: Medium — AFK deadlock; forces manual intervention.

## Root Cause Analysis

**Confirmed 2026-07-26** by reading the shipped source. Root cause: **the `[Unratified Dependency]` guard is a stateless pure function of the cited ADR's on-disk frontmatter, and the framework separately mandates that mid-loop ADRs be born unratified.** The two are structurally incompatible under AFK.

### The guard has no provenance input

`packages/architect/agents/agent.md` lines 177-196 (shipped by RFC-010 for P318 as ADR-074 enforcement surface 3) defines the flag as: fire iff the cited ADR's frontmatter lacks `human-oversight: confirmed` AND the file is not `*.superseded.md` AND it does not carry the `rejected-pending-supersede` + `supersede-ticket:` pair. `packages/architect/scripts/is-decision-unconfirmed.sh` is the executable mirror of the same three-part definition.

Every input to that decision is the target file's own frontmatter. Nothing in the contract can distinguish:

- a **stale** unratified ADR that someone is quietly building production code on — the P315 failure P318 legitimately closes; from
- an ADR **this same architect prescribed minutes earlier in this same session**, whose unratified state is the framework working as designed.

### The framework mandates the artefact the guard blocks

`packages/architect/skills/capture-adr/SKILL.md` line 209 (ADR-066 amendment 2026-06-02 / P348) requires a capture-time ADR to be born `human-oversight: unconfirmed`. `confirmed` is not available as an alternative: `architect-oversight-marker-discipline.sh` DENIES any write introducing `confirmed` without a matching session-scoped evidence marker, and a marker without a real confirm event is the P348 hollow-marker bug.

So the architect prescribes an ADR capture, `capture-adr` is obliged to mint it unratified, and the next architect spawn is obliged to flag it. The only clearing action the verdict names — `/wr-architect:review-decisions` — is an `AskUserQuestion` drain, which the ADR-044 AFK carve-out forbids mid-loop. The flag is therefore **unrecoverable under AFK**, and the iteration burns.

### Correction to the reported mechanism — it is not the drift hash

The capture description (and inbound #342) attribute the deadlock to drift-hash marker invalidation. That is only partly right, and following it would send the fix to the wrong file:

- `architect-refresh-hash.sh` **already** refreshes the stored hash after an allowed Edit/Write to `docs/decisions/` while a valid marker exists — that hook exists precisely to stop a just-approved new ADR from invalidating its own marker.
- `_substance_hash_path` (`packages/architect/hooks/lib/gate-helpers.sh` line 45) hashes `docs/decisions/*.md` **excluding `README.md`**, so the compendium regen that accompanies every ADR write does not drift the hash either.

The deadlock does not require marker invalidation at all. Any **fresh** architect spawn later in the same session re-evaluates from scratch — TTL slide, a re-review after an `ISSUES FOUND`, or simply the next distinct gated edit — and re-flags the same ADR. **The defect is the statelessness of the guard, not the hash.**

This is the narrower, load-bearing distinction from the sibling tickets: P453 and P419 are genuinely about a gate hashing files rather than substance. P425 is about a *verdict* that has no memory of its own prior output.

### Why P318 dismissed this

RFC-010 line 33-34 bounds the guard's noise on an explicit premise: *"the near-zero unratified set keeps noise negligible"* (census 2026-05-27: 61/65 ratified). That premise holds in interactive steady state, where `create-adr` births ADRs confirmed and the drain clears the tail. It is **falsified inside an AFK loop**, where every ADR the loop captures is necessarily born unratified and cannot be drained until the human returns. P425 is a defect in RFC-010's own delivered scope, not a new surface.

### Reproduction

No automated reproduction case exists yet. The reason is a **named, ticketed harness gap** — not a licence to ship a structural test (architect review 2026-07-26 corrected an earlier draft of this section on both counts):

- The behavioural harness for this agent **already exists**: `packages/architect/agents/eval/promptfooconfig.yaml` runs the real architect agent and already carries two `[Unratified Dependency]` cases. "Not testable until the promptfoo harness lands" is false.
- What is missing is specifically the **positive-fire** fixture. That config's own COVERAGE NOTE says why: the agent reads the live `docs/decisions` root, so the positive branch needs a synthetic fixture corpus isolated from live decisions. A half-built fixture already sits unwired at `packages/architect/agents/eval/fixtures/repo/docs/decisions/074-unratified-fixture.proposed.md`, while `run-agent-eval.sh` line 39 does `cd "$REPO_ROOT"` — so the fixture corpus is never the working directory. This is the architect twin of the JTBD RFC-012 S1b slice, tracked by **P324 / RFC-012**.
- No `structural-permitted` fallback is available or claimed. ADR-052's 2026-06-09 amendment **repealed** both escape hatches; line 187 records the in-tree structural files — RFC-010's own T3 among them — as a known state of violation tracked by P290, not as precedent. Per ADR-052 line 135 the correct disposition is to **block on the harness-gap ticket**, which is what Phase 2 does.

So the Phase 2 reproduction is a new case in the existing promptfoo config, blocked on the fixture-corpus cwd wiring (P324 / RFC-012 architect slice). Until then, the reproduction evidence is the manual recipe below.

Manual reproduction recipe (empirically witnessed; inbound #342 plus AFK iterations on this repo):

1. In one session, take an architect verdict that prescribes recording a decision, and capture it via `/wr-architect:capture-adr`. The ADR lands `human-oversight: unconfirmed` by mandate.
2. In the same session, attempt any further gated edit whose change cites or implements that ADR.
3. The fresh architect spawn emits `ISSUES FOUND / [Unratified Dependency]` naming the ADR it just prescribed, with the action "ratify via `/wr-architect:review-decisions` before this lands".
4. Under AFK there is no path to step 3's action, so the iteration halts with no work landed.

## Workaround

Sequence the session so no gated edit citing the new ADR follows its capture: land the ADR capture as the **last** gated write of the iteration and hold the dependent work for the next session, after the interactive `/wr-architect:review-decisions` drain ratifies it. Where the dependent work is code, this costs nothing extra — ADR-096 holds that code for ratification anyway.

If a gated edit is genuinely unavoidable mid-loop and a real same-session architect PASS is already in hand, the load-bearing-gate recovery in `docs/briefing/hooks-and-gates.md` (assert the marker, remove the `.hash` sibling) applies. That is user-authorised bypass of a misfiring gate, not a routine step, and it does not scale — it clears the hash, not the verdict, so the next fresh spawn re-flags.

## Fix Strategy

Fix vehicle: **RFC-010** (`docs/rfcs/RFC-010-architect-flags-build-on-unratified-adr.proposed.md`), Phase 2 — the RFC that shipped this guard. The trace edge is wired into RFC-010 rather than minting a new RFC, per P371: this is a defect in RFC-010's delivered scope operating outside the premise RFC-010 itself recorded.

The fix must add a fourth "do not flag" case to the guard without weakening the three legitimate cases P318 closes. **The option is not picked — it is queued for human ratification** (ADR-044 category-1 direction-setting).

Per **ADR-070 line 44** (no considered-options block in an RFC body) the option enumeration lives here, in the ticket, and in the iteration's queued questions — **not** in RFC-010. The alternative compliant home was to capture the amendment ADR now carrying the options; that was rejected as the fix locus for this iteration because minting a born-`unconfirmed` ADR mid-AFK-loop is *literally the defect this ticket describes*, and it would drag in an off-skill `docs/decisions/README.md` regen whose compendium hook has a known truncation failure mode. Recording the options on the WSJF-ranked ticket keeps them visible without reproducing the bug.

Four viable options (D and the cautions on A/C added by architect review 2026-07-26):

- **(A) Same-session sanction ledger.** `capture-adr` / `architect-mark-reviewed` record the prescribed ADR id in a session-scoped ledger; the guard skips ledgered ids. Matches the ticket's original framing and self-expires with the session. Costs: it destroys the guard's pure-function-of-frontmatter property; the ledger must be a real file and `.claude/` is forbidden as an agent write target (P131); the architect agent has only Read/Glob/Grep, so the ledger path must be handed to it in its prompt, which is fragile across the subprocess dispatch boundary; and a fresh spawn that never receives the path re-flags anyway.
- **(B) Fourth ratified-equivalent frontmatter skip.** An `oversight-queued: P<NNN>` marker written on the ADR-066 P348 AFK fallback path and consumed/cleared by the `/wr-architect:review-decisions` drain. Mirrors the shipped P316 `rejected-pending-supersede` + `supersede-ticket:` pair exactly, so it needs no new mechanism: it preserves the pure-function property, is read identically by the Grep-only agent and by `is-decision-unconfirmed.sh`, survives fresh spawns, is durable across session boundaries, and the paired ticket is the anti-rot device. Costs a frontmatter grammar addition plus a drain-side consume step, and **needs a bound** — otherwise an AFK loop can mint the marker broadly and then build code freely on unratified decisions, which is the P315 hole reopened.
- **(C) Scope the guard by the kind of dependent work.** Do not flag when the change under review is itself governance-artefact authoring under `docs/{decisions,rfcs,stories,story-maps}/` tracing the cited ADR; keep flagging code. Statelessly derivable from paths already in the review prompt, so it is the shortest diff — agent.md prose only, no new marker, no new state. Caution: **as literally stated this is broader than ADR-074 permits.** ADR-074 line 46 gates "dependent **artifacts**", not dependent code, so an RFC that implements a picked option is itself dependent work and a blanket path-based exemption would wave it through.
- **(C′) Architect's advisory lean — draw the line at substance commitment, not file path.** A refinement of C: an artefact that records a decision's *existence, trace and blocked-ness* without committing to its substance is not building on that substance; any artefact **or** code implementing a chosen option is. Faithful to ADR-074 line 46, needs no new state or marker, stays a pure function of inputs the agent already has, and it explains why the RFC-010 Phase 2 edit made under this very ticket does not trip the guard. Recorded as the reviewer's advisory lean, **not** as a pick.
- **(D) Status quo.** Accept the over-fire as AFK noise and rely on reviewers reading past it. The cost is the one this ticket measures: a burned iteration per occurrence, with no automatic recovery path.

(B) and (C)/(C′) compose rather than exclude — C/C′ fixes the harm-model scoping, B remains available if a sanctioned code-path exception is later needed. (A) and (B) are alternatives.

**Lockstep surfaces for whichever option lands** (architect review 2026-07-26): the pick amends **both** ADR-074's enforcement-surface-3 contract **and** ADR-066's definition of "unconfirmed", so the ADR must be recorded against both. Enforcement-surface-3's own mirror discipline then requires the change be applied in lockstep to `packages/architect/agents/agent.md` **and** `packages/architect/scripts/is-decision-unconfirmed.sh` (kept in sync by the contract in that script's header lines 12-18, with a drift test in `scripts/test/is-decision-unconfirmed.bats`) — **plus the JTBD twin**, `packages/jtbd/scripts/is-job-or-persona-unconfirmed.sh` and `packages/jtbd/agents/agent.md`, which carry the same guard via RFC-011. Missing the JTBD twin would leave the identical deadlock live on the other gate.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: human ratification of the option pick above. No AFK path — see ADR-044 AFK carve-out.
- **Composes with**: P318 (closed — added the guard and dismissed this over-fire on a premise AFK falsifies), P453 (open — sibling gate-self-invalidation surface on the JTBD gate; that one is genuinely hash-vs-substance, this one is verdict statelessness), P419 (same hash-vs-substance class as P453), P313 (verifying — edit-gate re-litigation / catch-22 family, different mechanism), P316 (unratified ADRs resurfacing; source of the `rejected-pending-supersede` precedent option B copies), P400 (verifying — marker-hook non-firing on resume; compounds recovery cost when this flag fires).

## Related

- Inbound issue #342.
- RFC-010 Phase 2 — fix vehicle (trace edge wired 2026-07-26 per P371 existing-vehicle-untraced sub-case).
- `docs/briefing/afk-ratification-hold.md` — the class of wall this ticket's fix is held behind.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-010 | proposed | Architect flags changes built on an unratified ADR |
