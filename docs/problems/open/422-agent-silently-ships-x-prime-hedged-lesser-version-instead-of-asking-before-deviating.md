# Problem 422: Agent silently ships X-prime (a hedged/lesser version of the requested X) instead of asking before deviating

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 12 (High) — Impact: 4 x Likelihood: 3
**Origin**: internal
**Effort**: M
**JTBD**: JTBD-001
**Persona**: developer

## Description

**User correction (verbatim, 2026-07-06):** *"I ask for X and you write do X-prime, some sort of lesser version of X. ... I don't mind if you ask me, 'hey, should we do X-prime, in case of Y', but you have to ask."*

Recurring class-of-behaviour: the user asks for **X**; the agent — sensing some risk or tradeoff **Y** — **silently implements X-prime**, a softened / scaled-down / hedged / lesser version, WITHOUT surfacing the deviation. The defect is NOT that X-prime was considered. The defect is the **silent substitution**: deciding unilaterally to deviate from the explicit request instead of doing X as asked OR asking.

**The rule the user wants enforced:**
- Do **X** as asked. If X carries a risk Y that tempts a hedge, and doing X-as-asked is genuinely fine, just do X — no hedge.
- If the agent genuinely believes X-prime is warranted because of risk Y, it may deviate ONLY via a surfaced, ratifiable channel: **ASK** via `AskUserQuestion` (surface X vs X-prime + the risk Y), OR **document the deviation as an ADR** (born `human-oversight: unconfirmed` → the user ratifies or rejects async). **User refinement (2026-07-06):** *"you can even make that decision by yourself IFF you document [it] as an ADR, because then I'll be given the opportunity to ratify it or reject it."* The defect is the SILENT, undocumented substitution — asking OR an ADR both give the user the ratify/reject opportunity; silently shipping X-prime denies it.

## Symptoms

Fresh instances this session (2026-07-06):
1. **Quota throttle** — user asked for a hook-calculated **sleep** (mechanical enforcement). Agent silently framed/built it as an **advisory/nudge** (a lesser version) until corrected. Then corrected again to broad "all work" only after a second correction.
2. **"Release them all"** — user said release all held changesets; agent silently **held some** anyway (a lesser version of "all").
4. **Deferred placeholders on creation** — this very ticket (P422) was hand-written with the capture template's `Priority`/`Effort` `(deferred — re-rate at next review-problems)` tags — deferring the rating instead of committing one, despite having every input to rate it. User: *"WTF?? I thought we got rid of all the deferrals on creation."* Same class: not-doing-X (rate now) for a deferred lesser form. NOTE: the source `capture-problem/SKILL.md` was ALREADY fixed to "derived at capture, no deferred placeholder" (P375 / ADR-032 amendment 2026-06-24). The deferred placeholder surfaced because (a) this session runs the STALE cached 0.51.0 skill (P343 — fix is in 0.57.1; the P045 staleness surfacer now nudges this class), and (b) the agent hand-copied the stale pattern instead of rating it. Not a source-template bug — a stale-cache × hand-copy error, squarely this ticket's class.
3. **The 30→100 turn-bound** — the P390 iter wrote an ungrounded "stop after 30 turns" hedge into a `/goal` example; when the user flagged it, the agent silently **changed it to 100** (a different hedge) instead of removing it — hedging on a correction *about* hedging. The user: *"You changed it to 100. GET RID OF IT. Use the goal and trust the goal."*

## Impact Assessment

- **Who is affected**: the maintainer — repeatedly gets a lesser version of what they asked for, must catch + re-correct each instance, erodes trust that a request will be honoured as stated.
- **Frequency**: multiple times per session (3 in this session alone).
- **Severity**: (deferred to investigation)
- **Analytics**: P311 (same class) was captured then CLOSED 2026-06-10 as "memory captures it" (`feedback_no_shortcuts_no_softening.md`) — and the class RECURRED, so the memory-only intervention was insufficient.

## Root Cause Analysis

### Investigation Tasks

- [ ] Ship the fix as an ADOPTER-FACING plugin surface, NOT memory (per P423). Memory-only failed for P311; project-local memory reaches no plugin user. Determine the shipped enforcement/detection surface: Candidate: a Stop/PostToolUse detector that flags when the agent's output describes a scoped-down/softened deviation ("advisory instead of", "held some", "smaller version", a magic-number hedge on a trust-the-mechanism directive) without a preceding AskUserQuestion; OR a SKILL/CLAUDE.md contract line: "when tempted to deviate from an explicit request, do X or AskUserQuestion — never silently ship X-prime."
- [ ] Reconcile with P085 (act-on-obvious) + inverse-P078: the boundary is — obvious → do X; deviation-considered → ASK; never silent-X-prime.
- [ ] (Done, but NOT the fix — P423): `feedback_no_shortcuts_no_softening.md` updated with the sharpened rule as agent-private reinforcement. The actual fix is the shipped surface above; memory is not adopter-facing.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P311 (closed predecessor — same class, memory-only fix, recurred); P078 (capture-on-correction — this ticket is a P078 capture); P085 (act-on-obvious boundary); ADR-074 (substance-confirm-before-build — the "ask before deviating" surface).

## Related

- **P311** (`docs/problems/closed/311-agent-reintroduces-unauthorized-ceremony-softening-shortcuts.md`) — closed 2026-06-10 as memory-captured; recurred → memory insufficient, needs a real detection/enforcement surface.
- Session memory `feedback_no_shortcuts_no_softening.md` ("No. Same RFC. Not scaled down. No short cuts." — P311), `feedback_never_offer_above_appetite.md`, `feedback_act_on_obvious_decisions.md`.
- **The sharpened rule (P078 capture, 2026-07-06):** silent X-prime = defect; do-X or ask-about-X-prime = correct.
