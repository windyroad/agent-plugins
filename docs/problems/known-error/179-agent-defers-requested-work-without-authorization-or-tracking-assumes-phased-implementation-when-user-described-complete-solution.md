# Problem 179: Agent defers requested work into untracked phases — phases are fine, but unticketed phases never get implemented

**Status**: Known Error
**Reported**: 2026-05-10
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 = 12. Rated at review 2026-07-02: behavioral chronic (sibling P403); observed pattern.
**Origin**: internal
**Effort**: M. WSJF = (12 × 1.0) / 2 = 3.0.
## Description

**Phases are NOT the problem.** Incremental implementation across phases is a legitimate engineering technique and the user explicitly endorses it. The problem is **untracked phases** — when the agent defers work to "Phase 2 / Phase 3 / out-of-scope / follow-up iter" without creating a tracking artefact (problem ticket, RFC, or other backlog entry) that surfaces the deferred work in WSJF rankings, work-problems backlog, or any actionable queue.

Concretely: when the user describes a problem and discusses how to solve it, the agent silently splits the described solution into "ship now" (current iter / current scope) vs "defer to future phase" (Phase 2 / Phase 3 / "future work" / "follow-up iter") without:

1. **Explicit user authorisation** for the split. The agent decides the boundary between "in scope" and "deferred" based on its own scope-narrowing inference (cost / complexity / "phased implementation feels safer" / "let's not blow scope"), not on user direction.
2. **Sibling-ticket tracking** for the deferred work. Deferrals are recorded only in ADR text ("Phase 2 — deferred"), in iter prompt notes ("T6 deferred to follow-up"), or in the ticket's Implementation Tasks section. None of these surface in WSJF rankings, the work-problems backlog, or any actionable queue. The deferred work disappears from view until either (a) the user notices it's missing weeks/months later or (b) it's re-derived from scratch on the next session.

User direction 2026-05-10 (verbatim, 2-message correction):

> *"You have a habit of deferring work that has been requested. … When you defer the work, 1) it surprises me (not good), 2) unless we do something to track it, it never gets implemented until I notice that it's missing."*
>
> *"I don't mind phases, but I do mind if those phases never happen."*

The fix shape per user direction: phases are LEGITIMATE if every phase is tracked as its own backlog entry that surfaces in the queue. The framework already has the right primitive — problem tickets and RFCs ARE the "tracked phase" mechanism. The agent must use them on every deferral, not invent ad-hoc "Phase 2" inline-text that lives only inside ADRs.

Concrete evidence — this session 2026-05-06 to 2026-05-10:

1. **Story-map design** — user described P170 with explicit reference to user story maps, JTBD trace, multi-RFC composition. ADR-060 deferred the story-map design to "Phase 2"; agent treated this as authoritative deferral. User had to explicitly ask "what is the design for how we maintain the user story maps?" 4 days into implementation work to surface the gap.
2. **ADR-022 / ADR-016 / ADR-024 amendments** — iter 8's ITERATION_SUMMARY explicitly named these as "deferred to T5b follow-up iter" without user direction. Still deferred at the time of P179 capture.
3. **T6 dual-pattern drop** — agent named "drop dual-pattern compatibility post-T5 verification" as a follow-up T-task without surfacing what "T5 verification" means or who decides when it's been verified enough.
4. **T7-T11 adopter auto-migration** — substantial work (multi-skill, multi-package; capture-problem + work-problems must both detect flat-layout and auto-migrate per ADR-031 § "Backward compatibility — adopter repos auto-migrate on first-run"). Agent placed entire block in "Slice 6" without surfacing whether user expected it as in-scope for P170 or as separate work.
5. **WSJF integration for story maps (Phase 2.5)** — agent silently created a "Phase 2.5" tier in the just-landed amendment to defer story-level WSJF design without user direction.
6. **INVEST extraction (Phase 2.5)** — same pattern; agent named a new phase tier to defer scope.

The pattern composes with:

- **P175** (agent over-narrows scope-pin words "just" / "only" / "first" into count constraints — halts loop on agent-inferred scope rather than framework-prescribed stop conditions). Same root-cause class: agent inferring framework-resolved decisions from non-framework signals. P175 was loop-control; P179 is scope-control.
- **P178** (agent skips ITIL state-machine gates on architecture-driven problems — treats architect-PASS as RCA substitute). Same root-cause class. P178 was lifecycle-state inference; P179 is scope-boundary inference.

The three together form a class-of-failure: **agent infers framework-resolved boundaries from non-framework signals (natural-language modifiers, ADR text, design verdict-class signals) when the framework actually requires explicit user direction for those boundaries**. ADR-044's framework-resolution boundary names the inverse failure (lazy AskUserQuestion deferral); P175 / P178 / P179 are the OUTBOUND failures (agent decides what the framework didn't actually resolve).

## Symptoms

- The agent says "deferred to Phase N" or "deferred to follow-up iter" or "Phase 2.5 / Phase 4 / out-of-scope" without a corresponding user authorisation in the recent session transcript.
- Deferred work is recorded only in ADR text or iter prompt notes; no problem ticket is created to track it; no entry appears in `docs/problems/README.md` WSJF rankings.
- User reaction signal: "you have a habit of deferring" / "I expected this to be implemented" / "where did X go" / "what about Y" — strong-affect class-of-behaviour correction triggering P078.
- ADRs accumulate "Phase 2" / "Phase 3" / "Phase 4" / "out-of-scope deferred" sections that never get implemented until user surfaces the gap.
- The user's mental model after a session: "we discussed solution X with components A, B, C, D, E"; the actual ship: "agent shipped A and B; C, D, E silently in 'Phase 2'".

## Workaround

Currently — user manually surfaces the deferral mid-session ("what about X?") which fires P078 capture-on-correction. Each correction costs a re-prompt round-trip the framework should not require.

A defensive workaround at iter dispatch / orchestrator main turn time: every time the agent uses the words "defer", "Phase N (next/later/future)", "out of scope", "follow-up iter", "deferred-to-Phase-N", surface explicitly via AskUserQuestion: "I'm about to defer X. Options: (1) implement now (2) capture as P-ticket and defer (3) document in ADR as scope-boundary-decision (4) cancel the deferral and complete now". Inelegant but breaks the silent-deferral pattern.

A SKILL-side fix: introduce a **deferral discipline** — every "out of scope" / "deferred to" line in any agent-authored artefact (ADR, RFC, problem ticket, iter summary) MUST cite either (a) a problem ticket ID tracking the deferral OR (b) a documented user direction authorising the deferral. Behavioural test (per ADR-052) asserts no agent-authored artefact contains uncited deferrals.

## Impact Assessment

- **Who is affected**: (deferred to investigation) — primary: user (loses visibility of described-but-deferred work); secondary: future maintainers reading ADRs see "Phase 2" sections with no implementation timeline; tertiary: AFK orchestrator's WSJF backlog under-represents true work pipeline because deferred work isn't ticketed.
- **Frequency**: (deferred to investigation) — likely Likely; surfaced 6+ instances in single session 2026-05-06 to 2026-05-10. Recurs on every multi-phase ADR + every multi-iter feature.
- **Severity**: (deferred to investigation) — likely Moderate; doesn't block ship but creates a hidden backlog that surprises the user and erodes the framework's "what you describe is what gets built" property.
- **Analytics**: (deferred to investigation) — count of "Phase N (deferred)" / "Out of Scope" entries in `docs/decisions/*.md`; count of "deferred-to-follow-up" mentions in `.afk-run-state/iter*.json` ITERATION_SUMMARY notes; ratio of described-but-deferred work to ticketed-and-tracked deferrals.

## Root Cause Analysis

### RCA reconciliation finding (2026-06-16, AFK work-problems iter 18)

Root cause confirmed and the deferral class reconciled against shipped sibling fixes. **Open → Known Error**: the root cause is identified, a workaround is in active operational use, and the remaining permanent-fix work is blocked on a single unmade framework-position decision (queued below).

**1. The deferral class is heavily worked; P179's adjacent surfaces are shipped or closed.**

| Sibling | Surface | Status |
|---|---|---|
| **P175** | scope-pin-word semantics (`just`/`only`/`first` are scope filters, not count/loop constraints) | Verification Pending — shipped `@windyroad/itil@0.49.3` (changeset drained in `34d6a8f8`) |
| **P184** | conditional-deferral → permanently-out-of-scope at K→V transition (Step 7 check) | shipped `@windyroad/itil@0.49.2` (commit `d2ec5b2`) |
| **P189** | fictional "deferred" framing invented on already-tracked phases (authoring surface) | Closed 2026-06-09 (relevance-close, cited P184) |
| **P234** | defers framework-required mechanical work to fictional "next retro/session" | Closed |
| **P236** | iter queues proceed-vs-defer as direction when framework trigger already fired | Closed 2026-06-10 (relevance-close, cited P175/P132) |
| **P296** | ADR-054 retroactive SKILL.md extraction wrongly deferred | Closed |

**2. P179's principle is already operationally adopted as the framework's deferral-discipline authority.** A repo sweep finds **13 problem-ticket files + 2 ADRs (060, 062)** citing P179 as the "deferral-discipline / scheduled-future-surface / carve-out" authority — e.g. P247 and P249 both justify their Phase-2 deferrals with "remains deferred with this ticket as scheduled-future-surface per P179 carve-out", and P097 cites "P179 umbrella-per-cohort" for the P241/P242/P243 split. The cultural rule (*every deferral must cite a tracking ticket OR a scheduled future surface*) is the **de-facto active discipline** — the framework has effectively defaulted to **Option D (cultural rule)** without ever ratifying the choice.

**3. The unenforced surface is real.** Investigation-Task survey grep (`grep -rlE 'Phase [0-9]+ \(deferred|Out of Scope|deferred to' docs/decisions/`) finds **26 ADR files** carrying `Phase N (deferred)` / `Out of Scope` / `deferred to` annotations. No SKILL, hook, or behavioural test currently requires those annotations to cite a tracking ticket or user-direction (`grep` for any deferral-citation invariant across `packages/*/skills/` and `docs/decisions/` returns nothing). So the de-facto Option-D discipline relies entirely on agent-prior + the cultural P179 citation habit — no enforcement backstop.

**4. P189's relevance-close does NOT cover P179's residual surface.** P189 was closed citing P184's *transition-surface* fix (Step 7 conditional-deferral check). P179's residual surface is **authoring + authorization + tracking** (one step earlier in the chain) — distinct cure site. P179 is therefore NOT relevance-closeable on the P184 basis; its enforcement surface is genuinely open.

**Residual permanent-fix work (the only remaining blocker): the framework-position decision below.** Per ADR-074 substance-confirm-before-build + this AFK loop's "queue + skip on born-proposed unconfirmed decisions" constraint, the Option A/B/C/D choice is genuinely user-judgment-bound (it is a MANDATORY-rule *enforcement-form* decision — hard test vs soft guidance vs process-gate vs cultural — squarely in ADR-044's direction-setting / taste taxonomy). **Not picked unilaterally; queued for user confirmation.** See the "Decide framework position on deferral discipline" Investigation Task (Options A–D) below. The de-facto state is Option D; the open question is whether to ratify D as-is or escalate to A (hard rule + behavioural test per ADR-051/ADR-052).

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate root cause (2026-06-16 RCA): confirmed all-three-surface gap — SKILL.md (no deferral-citation invariant), ADR-template ("Out of Scope" section invites unauthorised scope-narrowing; 26 ADRs carry the pattern), agent-prior (phased-implementation conditioning). De-facto enforcement is Option D (cultural P179-citation habit) with no test backstop. See RCA reconciliation finding above.
- [x] Survey existing ADRs for unauthorised "Phase N (deferred)" / "Out of Scope" entries (2026-06-16): `grep -lE 'Phase [0-9]+ \(deferred|Out of Scope|deferred to' docs/decisions/` → **26 ADR files**. None gated by any deferral-citation invariant. Confirms the unenforced surface is real.
- [ ] **Decide framework position on deferral discipline** (QUEUED for user — born-proposed unmade decision; ADR-074 substance-confirm-before-build; not picked unilaterally under AFK):
  - **Option A** — Hard rule: every deferral MUST cite a tracking ticket (existing or newly-captured). Behavioural test enforces.
  - **Option B** — Soft rule: every deferral SHOULD cite a tracking ticket; SKILL.md authoring guidance + retro Step N audit catches gaps.
  - **Option C** — Process rule: every "out-of-scope" / "deferred" agent decision triggers AskUserQuestion mid-flow asking whether to ticket or proceed.
  - **Option D** — Cultural rule: documented in CLAUDE.md as MANDATORY; no test enforcement; relies on agent-prior + retro hygiene.
- [ ] Sweep ADR-044 framework-resolution boundary worked examples — does P179 belong in the inverse-P132 lazy-deferral worked-example list (currently P130 transient-user is the sole entry; P175 + P178 + P179 form the outbound-failure cluster)? If so, surface in `run-retro` Step 1.5 silent classification + Step 2d Ask Hygiene Pass criteria.
- [ ] Behavioural test: a bats fixture asserting that ADR / RFC / problem-ticket / iter-prompt artefacts authored by skills do NOT contain `(deferred|Out of Scope|Phase [0-9]+ \(deferred)` patterns without an adjacent ticket-ID citation. Fixture exercises the manage-problem / capture-problem / capture-rfc / manage-rfc / create-adr / amendment paths.
- [ ] Reverse-engineer the 6 in-session deferral instances (story-map design, ADR-022/016/024 amendments, T6, T7-T11, Phase 2.5 WSJF, Phase 2.5 INVEST) — for each, identify where in the agent's reasoning chain the deferral decision fired and whether the user had explicit input. Calibrates whether the fix targets the agent-prior layer or the SKILL.md layer.

## Fix Strategy — ratified 2026-06-17

User ratified **Option A — Hard rule + behavioural test per ADR-051 / ADR-052** via AskUserQuestion during the 2026-06-17 outstanding-questions drain.

**Shape**: codify the no-unauthorized-defer principle as a hard SKILL.md / agent-prose rule + ship behavioural bats (or promptfoo eval per ADR-075) that exercises the rule. Strongest enforcement at agent-prose time.

**Implementation sketch** (defer detailed design to RFC):

1. Identify the canonical authoring location for the rule (likely `packages/itil/skills/work-problem/SKILL.md` and the AFK orchestrator `work-problems`; possibly also `manage-problem` if the defer pattern recurs at investigation time).
2. Draft prose-rule text: "Do not defer requested work into phases unless (a) the user explicitly authorised the split OR (b) a ticket exists that tracks the deferred phase. Phases without authorization or tracking are P179-class violations."
3. Add behavioural test: bats fixture OR promptfoo eval that exercises a session-shape where the agent is asked for a complete solution and the test asserts the response does not contain a deferral without an accompanying ticket-capture invocation.
4. Cross-reference the 13 existing tickets that cite the principle so they trace into the enforcement test.

Options B (soft retro-audit), C (mid-flow ask), and D (ratify de-facto) are rejected.

Next step: capture an RFC per ADR-060 tracing this ticket + the locus list above; defer build under ADR-074 substance-confirm-before-build until the RFC has scope ratified.

## Dependencies

- **Blocks**: (none directly — but the longer this is deferred, the more accumulated unauthorised deferrals pile up across the framework's ADRs)
- **Blocked by**: (none — investigation can proceed independently)
- **Composes with**:
  - **P175** (agent over-narrows scope-pin words into count constraints) — sibling root-cause class: agent inferring framework-resolved decisions from non-framework signals. P175 was loop-control; P179 is scope-control. Both stem from same root.
  - **P178** (agent skips ITIL state-machine gates on architecture-driven problems — treats architect-PASS as RCA substitute) — sibling root-cause class: agent inferring framework-resolved boundaries from verdict-class signals. P178 was lifecycle-state; P179 is scope-boundary.
  - **P078** (capture-on-correction OFFER pattern) — this very ticket was captured under P078 discipline after the user's class-of-behaviour correction.
  - **ADR-044** (decision-delegation contract — framework-resolution boundary) — scope-boundary decisions ARE framework-resolved when the user has described the solution; agent must not sub-contract back via "phased implementation" inference. Composes with the inverse-P132 lazy-deferral worked examples.
  - **ADR-051** (load-bearing-from-the-start) — applies to this ticket's own fix; whatever discipline emerges should ship with its enforcement test, not as advisory-then-escalate.
  - **ADR-052** (behavioural-tests-default) — the deferral-citation test is a behavioural surface; bats fixture exercises agent-authored artefacts.

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- ADR-022 — problem lifecycle conventions
- ADR-044 — framework-resolution boundary
- ADR-051 — load-bearing-from-the-start
- ADR-052 — behavioural-tests-default
- ADR-060 — RFC framework (drove the unauthorised "Phase 2 deferral" of story-map design that surfaced this pattern)
- P078 — capture-on-correction OFFER pattern
- P175 — sibling inferential failure class (loop-control)
- P178 — sibling inferential failure class (state-machine)
- P170 — the empirical surface where the pattern accumulated 6+ instances in single session
- /wr-itil:work-problems SKILL.md — Step 5 iter prompt template (deferral-discipline gap)
- /wr-itil:manage-problem SKILL.md — Step 9 work-the-fix (deferral-discipline gap)
- /wr-architect:create-adr SKILL.md — ADR template's "Out of Scope" section invites unauthorised deferral
- Session evidence — 2026-05-10 user correction "you have a habit of deferring work that has been requested … 1) it surprises me (not good), 2) unless we do something to track it, it never gets implemented until I notice that it's missing".
