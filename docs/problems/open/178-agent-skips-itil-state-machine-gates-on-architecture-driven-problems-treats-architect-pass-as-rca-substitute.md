# Problem 178: Agent skips ITIL state-machine gates on architecture-driven problems — treats architect-PASS verdict as substitute for empirical RCA + skips Open → Known Error transition

**Status**: Open
**Reported**: 2026-05-10
**Priority**: 3 (Medium) — Impact: 3 (Moderate) x Likelihood: 2 (Possible) — re-rated iter-20 2026-06-16: base-rate survey (below) raised Likelihood 1→2; Impact stays Moderate (routes around a discipline gate, does not block ship); Priority band unchanged at 3, so WSJF (1.5) and README ranking are stable.
**Effort**: M — re-rated iter-20: two SKILL surfaces (manage-problem Step 9 + work-problems Step 5) + behavioural test + likely ADR amendment/new-ADR for the framework-position decision.

## Description

ADR-022 documents the problem-ticket lifecycle as `Open → Known Error → Verifying → Closed`. The transition `Open → Known Error` is gated on RCA being complete enough to declare a known root cause; ITIL discipline says implementation work begins AFTER the Known Error transition fires (the Known Error state IS the contract that "we understand the problem well enough to fix it").

Observed pattern: when a problem ticket is **architecture-driven** (i.e. its fix is shaped by an ADR rather than by code-level diagnosis), the agent (and orchestrator) treats the architect-PASS verdict on the driving ADR as substitute for empirical RCA. Implementation work commences while:
- The ticket's `Status:` field still reads `Open` (lifecycle never advanced)
- Investigation Tasks in the ticket's `## Root Cause Analysis` section remain unchecked (empirical validation deferred)
- No `Open → Known Error` transition commit fires (the file stays at `*.open.md` / `docs/problems/open/<NNN>-*.md`)

The architect-PASS verdict is a **design-validity** signal (the proposed fix's shape is sound), NOT an **empirical-RCA** signal (the problem actually occurs at the claimed frequency, has the claimed impact, and ships the claimed value). Conflating the two routes around the gate that ITIL Known Error introduces specifically to prevent fixes-in-search-of-problems.

This is a **class of behaviour**: the same root-cause class as P175 (agent inferring framework-resolved decisions from natural-language signals). P175 was about loop control; P178 is about ITIL state-machine discipline. Both stem from agent reading verdict-class signals as state-machine-transition signals when the framework hasn't actually authorised the substitution.

**Concrete evidence** — this session 2026-05-06 to 2026-05-10:

1. P170 (RFC framework — strain pattern) was at `**Status**: Open` when work commenced.
2. Architect + JTBD reviews on driving ADR-060 returned AMEND verdicts (subsequently incorporated). Those review tasks were ticked off in `## Investigation Tasks`.
3. Three empirical RCA tasks remained unchecked: reproduction-of-strain-pattern, base-rate-investigation, adopter-impact-investigation.
4. No `Open → Known Error` transition commit fired at any session boundary.
5. Implementation work proceeded across **8 iters / 26 commits** — Slice 4 (B6 + B7) and Slice 5 (B8.T1-T5) all shipped against an Open-status ticket.
6. User observed the gap mid-session 2026-05-10: *"it looks like work on fixing P170 has commenced before RCA is complete and before it's become a known error. Is that correct?"*

The orchestrator's response to the user's correction — and the user's `yes, create a problem ticket` — is the P078 capture-on-correction surfacing of P178.

## Symptoms

- Problem ticket file stays at `Open` status across multiple iters of implementation commits.
- `## Investigation Tasks` section has unchecked empirical-RCA tasks while implementation commits land.
- Architect-PASS / JTBD-PASS verdicts are interpreted by agent as authorising implementation, even though they're authorising design-shape, not empirical RCA.
- No `Open → Known Error` transition commit appears in `git log` between problem capture and first implementation commit.
- AFK orchestrator iter prompts ask "work the next bounded sub-task" without first asking "has this ticket transitioned to Known Error?"
- Manage-problem SKILL.md's Step 7 (transition Open → Known Error) is not being invoked as a precondition to manage-problem Step 9 (work the fix).

## Workaround

Currently — user manually flags the gap mid-implementation (as happened 2026-05-10 with P170). Each user-flag costs a re-prompt round-trip. The orchestrator's response IS the workaround: pause work, complete RCA from session evidence OR additional investigation, transition to Known Error, then resume.

A defensive workaround at iter dispatch time: orchestrator's iter prompt could include a precondition check "is the targeted ticket at Known Error or beyond?". If Open: route to RCA-completion + transition first. If KE/Verifying: proceed to implementation.

A SKILL-side fix: manage-problem SKILL.md Step 9 (work the fix) gains a precondition gate: ticket file must be at `*.known-error.md` / `docs/problems/known-error/<NNN>-*.md` OR architect-PASS-substitute carve-out must be explicitly authorised by user.

## Impact Assessment

- **Who is affected**: (deferred to investigation) — primary: solo-developer using AFK orchestrator on architecture-driven tickets; secondary: future maintainers who skim git log expecting Known Error transitions to mark "fix in progress".
- **Frequency**: (deferred to investigation) — likely Possible-to-Likely; surfaced N=1 explicitly (P170) but the pattern would naturally recur on every architecture-driven ticket where ADR-PASS substitutes for empirical RCA.
- **Severity**: (deferred to investigation) — likely Moderate; doesn't block ship but routes around an ITIL discipline gate that exists for a reason (preventing fixes-in-search-of-problems).
- **Analytics**: (deferred to investigation) — count of implementation commits that landed against `*.open.md` tickets without an intervening Known Error transition; ratio of architect-PASS substitution events to formal RCA-completion events.

## Root Cause Analysis

### Investigation Tasks

- [x] Re-rate Priority and Effort — done iter-20 2026-06-16 (see header; Likelihood 1→2, Priority band unchanged at 3, Effort M).
- [x] Investigate root cause: is this a SKILL.md gap (manage-problem Step 9 doesn't precondition-check ticket status) or an iter-prompt gap (work-problems iter prompts don't precondition-check) or both? **Confirmed BOTH** (iter-20 reconcile sweep): (a) `manage-problem/SKILL.md` Step 9 (work-the-fix) has *no* gate on the ticket's `Status:` field — its "before implementing any fix" guards check ADR-074 substance-confirm + ADR-072/073 RFC-trace, never the lifecycle status; (b) `work-problems/SKILL.md` Step 4 classification table routes `Open problem with preliminary hypothesis` and `Open problem with no leads` directly to "Work it" with no status precondition, and Step 5 iter-dispatch fires `claude -p` with no status-check prefix. Fix at both surfaces per ADR-051 load-bearing-from-the-start.
- [x] Survey existing tickets that received implementation commits while at `*.open.md` status. **Done iter-20**: `git log --since=2026-04-01 --grep='^(feat|fix|test)(' -- docs/problems/open/` → **78 commits** landed feat/fix/test work touching open-status tickets. (Overcounts somewhat — several of those commits *also* fired a transition in the same commit, e.g. messages containing "Open → Known Error" / "Open → Closed" / "K→V" — so the raw count is an upper bound on sustained working-while-Open. But it firmly establishes the pattern is routine, not the N=1 (P170) originally recorded.) Base-rate ⇒ Likelihood **Possible (2)**, mitigated in practice by the AFK reconcile-first discipline that does RCA-then-fix within an iter.
- [ ] **[BLOCKING — queued for user confirmation, ADR-074 substance-confirm]** Decide framework position: is architect-PASS-substitution-for-RCA a legitimate carve-out that should be EXPLICITLY documented (with conditions: e.g. "for architecture-driven problems where the fix's value is independent of base-rate, architect-PASS on the driving ADR's design soundness can substitute for empirical RCA, with the Known Error transition gated on ADR acceptance")? OR should it be a hard-block (every problem must complete empirical RCA before Known Error)? The carve-out option mirrors ADR-060's "bounded escape" pattern at lifecycle transitions; the hard-block honours ITIL discipline more strictly. **This is a genuine ≥2-option framework decision and is born-proposed/unconfirmed — the entire fix shape depends on it (the precondition gate's behaviour when `Status:Open` differs between carve-out and hard-block). Per ADR-074 substance-confirm-before-build, this is queued + skipped; no fix built until the user picks a direction.**
- [x] Sweep ADR-022 (problem lifecycle) for whether it already addresses this — **Confirmed SILENT (iter-20)**: ADR-022 documents the `Open → Known Error → Verifying → Closed` lifecycle but says nothing about architect-PASS-substitution or a precondition gate on implementation work. ADR-044 (framework-resolution boundary) is the nearest existing decision but does not address this specific state-machine gate. So the resolution needs either an ADR-022 amendment OR a new ADR (decided by the framework-position choice above).
- [ ] **[BLOCKED on framework-position decision]** Behavioural test: a bats fixture asserting that work-problems iter dispatch (or manage-problem Step 9) refuses to advance an `*.open.md` ticket without either (a) the Known Error transition having fired OR (b) an explicit user-authorised carve-out marker. The assertion's expected behaviour differs between carve-out and hard-block, so this is gated behind the decision.

### Reconcile finding (iter-20, 2026-06-16)

Reconcile-first sweep (Explore agent + git base-rate survey) confirmed the P178 defect class is **still present and unfixed** — no precondition gate exists at either SKILL surface, ADR-022 is silent, no behavioural test asserts it, and the sibling tickets P175 (scope-pin words → Verifying), P184 (conditional-deferral → Closed), P228 (K→V auto-transition → Closed) each fix a *different* state-machine/loop-control class, none covering the Open→Known-Error precondition gate.

The empirical RCA is now substantially complete (root cause confirmed at both surfaces; base-rate established; ADR-022 silence confirmed). **What remains is not RCA — it is a fix-shape framework decision** (carve-out vs hard-block) that determines what the precondition gate *does* when `Status:Open`. That decision is born-proposed and unconfirmed, so per ADR-074 substance-confirm-before-build the fix is **queued + skipped** this iteration — building either gate now would pre-commit the framework to one resolution the user has not chosen (the P314/P315 build-on-then-rejected trap).

**Deliberately NOT transitioning Open → Known Error.** The framework-position task is filed under RCA and remains genuinely unresolved; advancing the state machine while a material question is open would re-enact P178's *own* anti-pattern (premature lifecycle advance). Staying Open is the self-consistent call and matches the iter-19 (P244) queue+skip precedent.

**Queued for user (single decision, surfaces at next interactive checkpoint):** *When a problem ticket's fix is shaped by an ADR rather than code-level diagnosis, should an architect-PASS verdict on the driving ADR be allowed to substitute for empirical RCA at the Open→Known-Error gate?* — **(a) Carve-out**: yes, for architecture-driven problems whose fix value is independent of base-rate, with the Known Error transition gated on ADR acceptance (mirrors ADR-060's bounded-escape pattern); **(b) Hard-block**: no, every problem completes empirical RCA before Known Error (strict ITIL). Whichever is chosen then drives a load-bearing precondition gate at manage-problem Step 9 + work-problems Step 5 + iter-dispatch, an ADR-022 amendment or new ADR, and the behavioural bats fixture — all per ADR-051 (ship enforcement with the discipline, not advisory-then-escalate).

## Fix Strategy — ratified 2026-06-17

User ratified **Hard-block** position via AskUserQuestion during the 2026-06-17 outstanding-questions drain: every problem completes empirical RCA before the Open → Known Error transition regardless of architect verdict. Architect-PASS does NOT substitute for RCA.

**Framework implication**: uniform state-machine — no carve-out for architecture-driven problems. The Open → Known Error gate requires:

1. Empirical reproduction of the failure mode (a test that goes RED, a session that exercises the path, a citation per ADR-026 of the observable failure).
2. Root-cause analysis ON THE PROBLEM TICKET (Root Cause Analysis section populated; not just "see linked ADR").
3. Fix Strategy section populated on the problem ticket (the chosen approach + rationale).

Architect-PASS at ADR acceptance is INDEPENDENT of the problem ticket's lifecycle. An ADR can be accepted while the originating problem ticket stays Open until empirical RCA lands.

**Implementation sketch**:

1. Amend `/wr-itil:manage-problem` Step 7 (Open → Known Error transition) prose: require empirical RCA evidence even when an accepted ADR exists. Architect-PASS markers do NOT bypass.
2. Cross-reference in `/wr-itil:transition-problem` Step 4 pre-flight: similar wording.
3. Behavioural bats: fixture exercises "ADR accepted + problem ticket Open without RCA — transition denied".
4. Cross-link with P179 enforcement (the no-unauthorized-defer rule applies here too).

The carve-out option is rejected. Compose with P179's hard-rule enforcement: both can ship together as a discipline-rule pair.

Next step: capture an RFC per ADR-060 tracing this ticket + P179; defer build under ADR-074 until RFC scope ratified.

## Dependencies

- **Blocks**: (none — this ticket is friction-reduction / discipline-strengthening; pre-existing implementation work continues)
- **Blocked by**: **framework-position decision (carve-out vs hard-block)** — born-proposed, unconfirmed; queued for user per ADR-074. The fix (precondition gate + ADR + behavioural test) cannot be built until the user picks a direction; building now risks the P314/P315 build-on-then-rejected trap.
- **Composes with**:
  - **P175** (agent over-narrows scope-pin words into count constraints) — sibling root-cause class: agent inferring framework-resolved decisions from non-framework signals. P175 was loop-control; P178 is state-machine.
  - **P078** (capture-on-correction OFFER pattern) — this ticket was captured under P078 discipline after the user's mild correction signal "Is that correct?".
  - **P170** + **ADR-060** — driver for the empirical surface where the pattern was observed; P170 is now retroactively being transitioned Open → Known Error using session evidence to close the gap surfaced by this ticket's capture.
  - **ADR-022** (problem lifecycle conventions) — the contract this ticket says agent must not subvert. May need amendment if architect-PASS-substitution carve-out is the resolution shape.
  - **ADR-044** (decision-delegation contract — framework-resolution boundary) — state-machine transitions are framework-resolved; agent must not sub-contract back via verdict-class inference.
  - **ADR-051** (load-bearing-from-the-start) — applies to this ticket's own fix; whatever discipline emerges should ship with its enforcement test, not as advisory-then-escalate.

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- ADR-022 — problem lifecycle conventions (Open / Known Error / Verifying / Closed)
- ADR-044 — framework-resolution boundary
- ADR-051 — load-bearing-from-the-start
- ADR-060 — RFC framework (drove the architect-PASS-substitution misreading on P170)
- P078 — capture-on-correction OFFER pattern
- P175 — sibling inferential failure class
- P170 — the empirical surface where the pattern was observed
- /wr-itil:work-problems SKILL.md — Step 5 iter prompt template (precondition-check gap)
- /wr-itil:manage-problem SKILL.md — Step 9 work-the-fix (precondition-check gap)
- Session evidence — 2026-05-06 to 2026-05-10, 8 iters / 26 commits against P170 at `Open` status; user-correction 2026-05-10 "it looks like work on fixing P170 has commenced before RCA is complete and before it's become a known error".
