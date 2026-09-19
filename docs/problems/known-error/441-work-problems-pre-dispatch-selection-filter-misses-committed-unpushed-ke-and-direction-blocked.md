# Problem 441: work-problems pre-dispatch selection filter misses committed-but-unpushed KE (#312) and direction-blocked / interactive-only-skill (#318) states

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#312, #315, #318)
**Effort**: M (unchanged — the design is settled and bounded: one predicate, one pre-dispatch step, one gate clause, one taxonomy row).
**WSJF**: 9.0 — (9 × 2.0) / 2, re-rated 2026-09-19 on the Known Error status multiplier (was 4.5 at Open × 1.0)
**JTBD**: JTBD-006
**Persona**: developer (secondary: plugin-developer)

## Description

Two adjacent gaps in the `/wr-itil:work-problems` pre-dispatch selection machinery (the P385 relevance-close + P344 predicate-check both already live but scoped narrowly):
- **#312**: a Known-Error ticket whose fix was implemented-and-committed *this loop* but not yet pushed (below the Step 6.5 drain threshold) stays top-of-WSJF and is re-selected; P385's relevance-close keys on *already-shipped/released*, missing this transient committed-but-unpushed sub-state.
- **#318**: the orchestrator re-selects tickets that are not AFK-actionable — those carrying an open queued cat-1 direction question, or whose Fix Strategy names an interactive-only skill (`/wr-architect:create-adr`, `/wr-jtbd:update-guide`, any AskUserQuestion-bound authoring surface) — every loop as highest-WSJF (no-op skips).
- **#315** (absorbed 2026-07-15 via hang-off arbitration): upstream-blocked / placement-authority tickets cycle back to the top of the WSJF queue — the Step 1/Step 3 ranking has no signal for placement-authority, so already-known-upstream-blocked tickets are re-selected and each iter pays the full verify-and-skip cost. Live downstream evidence: 5 of 6 iters classified upstream-blocked on iter read (~83% iter waste at the WSJF frontier). NOTE: the reporter frames this as a *ranking-signal* gap, whereas this ticket's mechanism is a pre-dispatch *filter/predicate* — same symptom and fix locus; whether the implementation demotes rank or skip-filters is a design detail to resolve here, not pre-decided.

## Symptoms

- The loop burns iterations re-selecting a ticket it just worked (unpushed) or one it structurally cannot progress AFK (direction-blocked / interactive-only).

## Impact Assessment

- **Who is affected**: AFK loops; wasted iterations on no-op re-selections.
- **Frequency**: every loop with a committed-unpushed KE or a direction-blocked top ticket.
- **Severity**: Medium — wasted cost; the loop appears busy but makes no progress.

## Root Cause Analysis

### Investigation Tasks

- [x] Extend the P385 Step 3.6 relevance-close to also skip a KE whose fix is committed-but-unpushed this loop (#312).
- [x] Generalise the P344 Step 3.5 predicate into a broad "AFK-actionability" filter covering direction-blocked + interactive-only-skill-dependent tickets (#318) + upstream-blocked / placement-authority tickets (#315).


### Root cause

Selection and dispatch-eligibility are the same axis. Steps 1 and 3 rank the
backlog by tier and WSJF and then hand the top ticket straight to dispatch, so
the only question ever asked is *which ticket is most valuable*, never *can
anything be done with this ticket right now*. Two later gates do ask a narrow
version of the second question — the ratification predicate and the
already-shipped relevance gate — but each is scoped to one cause, and both sit
after the expensive selection has already committed to the ticket.

The ranking therefore rewards a ticket for being stuck. Transitioning a held
ticket to Known Error raises its score on the Known-Error multiplier, so a
ticket that cannot move re-selects *higher* on the next pass. This session is
live evidence: one ticket was fully held on two maintainer questions queued two
months earlier and re-selected at the top of the queue every pass, able only to
re-confirm the block; another was investigated, transitioned to Known Error, and
had its score raised while held on a direction question.

The signals needed to answer the second question are already durable and already
read elsewhere. A ticket records what holds it on its own `- **Blocked by**:`
line; an upstream hold is recorded by the `## Reported Upstream` section and the
upstream-report-pending marker, both of which the pre-`ALL_DONE` backlog-empty
gate already treats as non-dispatchable; an interactive-only fix path is named in
the ticket's own `## Fix Strategy`; and a committed-but-unpushed fix is visible
in git. Nothing new has to be invented or kept in sync — the signals exist, they
are simply not consulted before dispatch.


## Fix Strategy

Separate **dispatch eligibility** from **priority**. Priority answers how much a
ticket is worth; eligibility answers whether anything can be done with it right
now. Today they are one axis, which is why a ticket that cannot move competes
for — and wins — a dispatch slot.

**The load-bearing invariant: a held ticket is filtered from dispatch only.** Its
WSJF score, its Impact and Likelihood, its tier and its position in the rankings
are untouched, and it still renders in the loop summary with the reason it is
held. A held ticket is not a low-value ticket; it is a ticket waiting on someone.
Demoting its rank would corrupt the ranking's meaning and would bury a ticket
whose hold clears mid-loop.

### 1. A predicate that reads signals already on the ticket

A read-only predicate answers one question for one ticket via its exit code —
the same shape as the existing closure-blocked predicate that guards the
Verification Pending to Closed transition. It reads only what is already durable
on the ticket or in git; no new state is introduced and nothing has to be kept in
sync.

Body at `packages/itil/scripts/is-dispatch-held.sh`, with the generated PATH-shim
wrapper at `packages/itil/bin/wr-itil-is-dispatch-held` regenerated via
`npm run sync:shim-wrappers` — never hand-edited.

Exit codes: `0` held (the class, the owner and the evidence line print on
stdout); `1` not held; `2` ticket not found or unreadable. A caller that gets
`127` because an older installed version does not carry the shim treats it as
not-held and proceeds, matching the degenerate-adopter silent-pass the sibling
ratification predicate already documents.

### 2. Four held classes, each with an owner and an unhold trigger

The owner matters as much as the class. Only two of the four are owed by the
maintainer; labelling all four "held on a person" would put items on the return
checklist that the maintainer cannot action.

| Class | Signal read | Hold owner | Unhold trigger |
|---|---|---|---|
| `unpushed-fix` | ticket is Known Error and an unpushed **fix-shaped** commit references it | **loop** | re-evaluated after the loop's own release-cadence drain — never the maintainer's return |
| `direction` | the ticket's `- **Blocked by**:` line names a person-gated hold | **maintainer** | the queued question is answered |
| `interactive-only` | the ticket's `## Fix Strategy` names an interaction-bound authoring skill | **maintainer** | that skill is run in an attended session |
| `upstream` | `## Reported Upstream` section, or the upstream-report-pending marker | **upstream** | the upstream fix lands |

The loop summary groups held tickets by owner, so the maintainer's section
contains only what the maintainer owes.

### 3. Matching discipline — the false-positive surface is the whole risk

A predicate that over-fires holds a ticket that could have been worked, which is
the inverse of the harm this fix exists to prevent. Three guards, all derived
from corpus evidence rather than assumption:

- **Line-anchored, fenced blocks skipped.** A mention inside a code fence or
  mid-prose is how tickets *discuss* the mechanism; treating discussion as a
  marker would strand the backlog.
- **A negation guard on the `Blocked by` value, evaluated before the keyword
  scan.** The prevalent corpus idiom is `(none — <prose>)`, and that prose
  routinely contains hold keywords: seven of the 381 recorded lines say "none"
  and still carry one, including several that explicitly declare the ticket
  buildable now. A value opening with `(none`, `none` or `N/A`, and any
  strikethrough span, disqualifies the line whatever keywords follow.
- **The `upstream` class must exclude the misfire marker.** The documented
  recovery path for a false external-root-cause detection appends
  `- **Upstream report pending** -- false positive; detection misfire` — the
  *same* marker prefix the real hold uses, because the detection reuses it as
  its already-noted substrate. A predicate matching the prefix alone would hold
  every ticket whose detection misfired. Observed on this very ticket, whose
  body discusses upstream-blocked as a class and trips the strict token scan.
  The match requires the marker line to NOT carry the misfire wording.
- **Every occurrence is evaluated, not the first.** `- **Blocked by**:` is not a
  unique key in a ticket body, and these lists demonstrably are not
  de-duplicated. A first-match read where the first line opens `(none` masks a
  real hold below it; the inverse strands a buildable ticket. Evaluate every
  line-anchored occurrence after the fence skip and hold if any survives the
  negation guard. Fixtures cover the two-line shape in both orders.
- **`unpushed-fix` matches fix-shaped commits only.** A commit that merely
  mentions a ticket is not a fix for it — a problem capture and a briefing
  refresh both name tickets in their subjects and neither implements anything.
  The match requires a `fix` / `feat` / `refactor` / `perf` conventional type or
  a `Refs:` / `Fixes:` trailer naming the ticket, and excludes problem-capture
  and briefing-refresh subjects. Where no upstream branch is configured the
  check resolves to not-held rather than erroring.

### 4. A pre-dispatch hold gate in the orchestrator

A new pre-dispatch step runs the predicate on the selected ticket **before** the
ratification predicate and the relevance gate — it is the cheapest of the three
and shares their shape exactly: read-only, deterministic exit-code routing, no
interactive question, no commit, and a loop back to selection over the remaining
backlog with tier-first order and the within-tier ladder preserved.

It writes the **same durable per-session skip record** its two siblings write,
carrying the class and the owner. This is load-bearing, not bookkeeping: the
pre-`ALL_DONE` backlog-empty gate re-scans the live backlog and re-classifies any
ticket as dispatchable unless a recorded skip carries it. A hold kept only in
memory would be re-selected by that gate, routed back, and held again — trading a
burned-iteration livelock for a non-terminating one. The gate's recorded
non-dispatchable conditions are extended to name this step alongside the
existing ones.

The `interactive-only` class also queues one direction entry so the hold surfaces
at the loop-end question gate. Without it that class has no self-firing surface
at all — the ticket would simply stop being dispatched, visible only in a
per-session table. Scoped so it does not double-queue a question the ratification
predicate already raised.

The skip record must be **typed**, and only maintainer-owed holds may reach the
shared outstanding-questions queue. That queue is not a neutral record: the
loop-end gate surfaces every entry in it to the maintainer and then truncates
it, and the session-start surfacer replays it. Writing all four classes there
would put a pending push and an upstream wait on the maintainer's return
checklist — exactly the harm the hold-owner column exists to prevent. Either the
record carries a kind discriminator the surfacing gates filter on, or the
loop-owned and upstream-owned holds land in a separate skip file that the
backlog-empty gate names alongside the records it already reads. The
`interactive-only` direction entry is the one that genuinely belongs in the
maintainer's queue.

The existing backlog-empty gate clause needs the **same misfire guard** as the
predicate's `upstream` class. It matches the upstream marker prefix with no
exclusion today, so a ticket whose detection misfired — recorded via the
documented recovery path, which reuses that very prefix — is silently classified
non-dispatchable and drops out of the loop entirely. This ticket hit it directly.
Leaving the two surfaces disagreeing (predicate says not-held, gate says
non-dispatchable) would re-create the divergence the fix exists to remove, so the
guard lands in both.

The iter-layer skip stays exactly as it is. The two surfaces are not redundant:
the iter layer is the authoritative second source, the pre-dispatch gate is the
shift-left cost optimisation — the same division the ratification predicate
already documents.

### 5. Coverage

P441 carries three reported faces and four held classes. Story cards must cover
all of them; a card scoped to one face reads as a clean trace while the rest of
the scope is stranded.

Behavioural tests exercise the predicate against fixture tickets — one per held
class, plus one per false-positive shape named in section 3 — and prove red
before green. Fixture search roots are guarded explicitly, since a search over a
missing directory asserts nothing and passes vacuously.

## Reproduction

Observable without instrumentation, from recorded state:

1. Pick any ticket whose `- **Blocked by**:` line names a maintainer-owed hold,
   or that carries a `## Reported Upstream` section, and confirm it sits at or
   near the top of the WSJF rankings.
2. Run the AFK orchestrator. The ticket is selected, dispatched at full iter
   cost, read, classified unworkable, and skipped.
3. Run it again. The same ticket is selected again — the skip left no mark the
   next pass consults before dispatch.

Two runs of this session are the live case: one ticket held on two maintainer
questions queued two months earlier re-selected at the top every pass; another
was transitioned to Known Error while held on a direction question, which raised
its WSJF on the Known-Error multiplier so it re-selects higher while still
unable to move. Downstream reporting on #315 measured 5 of 6 iters classified
upstream-blocked on iter read.

The regression test is the behavioural suite named in the Fix Strategy: one
fixture ticket per held class asserting exit 0 with the right class and owner,
and one per false-positive shape asserting exit 1. It must fail before the
predicate exists.

## Workaround

None that removes the cost, and the two available mitigations both trade one
harm for another:

- **Answer the queued question.** Removes the hold at its source, but requires
  the maintainer to be present, which is precisely what the AFK loop assumes is
  not true.
- **Park the ticket.** Takes it out of the ranked set entirely, so it stops
  consuming dispatch slots — but it also drops out of the maintainer's WSJF
  view, which is the "silently drops its priority" failure this ticket exists to
  avoid. Acceptable only as a deliberate, reversible maintainer act, not as a
  standing workaround the loop applies on its own.

Until the fix lands the loop simply pays the wasted dispatch, and the returning
maintainer reads the skip in the loop summary rather than a pre-dispatch hold.

## Dependencies

- **Composes with**: P385 (verifying — pre-dispatch relevance-close), P344 (verifying — pre-dispatch predicate-check), P352 (runtime queue-and-continue).
- **Blocked by**: human ratification of the recorded decision that separates dispatch eligibility from priority — `docs/decisions/` entry captured 2026-09-19, born `human-oversight: unconfirmed`. The design above is settled and the approach-choice the ticket left open (filter dispatch versus demote rank) is pinned to filtering; what remains is a human confirming that recorded substance at the `/wr-architect:review-decisions` drain. Implementation waits on that confirmation **and** on ratification of the story map carrying the fix's release row — the map is the approval surface and it is still a draft, so decision ratification alone does not unblock. Both gates are self-firing — an unconfirmed decision is surfaced by the session-start oversight nudge and by the loop's own pre-`ALL_DONE` oversight drain.

## Related

- Inbound issues #312, #315, #318. Kept as one ticket: all three extend the same pre-dispatch selection filter (#315 absorbed 2026-07-15 per wr-itil:hang-off-check verdict).
- **External-root-cause detection misfire** -- recorded deliberately WITHOUT the `Upstream report pending` marker wording. The strict external-root-cause token scan hits because this ticket *discusses* upstream-blocked tickets as one of the four held classes it must recognise. Its own root cause is entirely internal: our selection machinery asks which ticket is most valuable and never asks whether anything can be done with it.
  Writing the canonical misfire marker here would have made this ticket non-dispatchable to the loop's own pre-`ALL_DONE` backlog-empty gate, which matches the marker prefix with no misfire exclusion — the ticket would have made itself invisible to the loop it exists to fix. That collision is recorded as a named guard in the Fix Strategy, and closing it in the existing gate clause is part of this ticket's scope.
