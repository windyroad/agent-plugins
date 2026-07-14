---
status: "proposed"
date: 2026-07-05
human-oversight: rejected-pending-supersede
oversight-date: 2026-07-13
supersede-ticket: P345
oversight-note: "REJECTED in the 2026-07-13 review-decisions drain — reverses the 2026-07-04 advisory-only ratification per ADR-066 Reassessment. User: you can't say a commit fixes something and leave the problem Open. If there is no more work, the ticket MUST NOT stay Open — verifying is the correct state, and a fix-titled commit should BLOCK if the ticket is not verifying/closed. The sole exception is when the problem is broken into multiple fixes (more work remains), where Open is legitimate. This upgrades the advisory to a gate — which this ADR's own binding rule says requires superseding it. Superseding decision + the multi-fix-exception mechanics tracked on P345."
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, downstream adopters]
reassessment-date: 2026-10-05
---

# Fix-titled-commit lifecycle drift surfaces as an advisory, never an auto-fire or hard gate

## Context and Problem Statement

A commit titled `fix(<pkg>): P<NNN> ...` claims to land fix code for a named problem ticket, but nothing maps that commit-title signal to the ticket's lifecycle. The ticket stays `Open` across the release that ships the fix, across CI verification, and across N intervening commits until a later session or the ~24h `review-problems` cadence closes the gap (P345; P334 is the captured witness chain). The two existing lifecycle automations don't cover this seam: `review-problems` item 10 keys off body-documented root-cause+workaround, and P228's post-release enumerator acts only on `.known-error/` tickets carrying `## Fix Released`. Fix-titled commits fall through the gap.

Closing the seam requires choosing an enforcement posture — and that choice is load-bearing for every future lifecycle automation, so per ADR-073's confirmation clause it needs a ratified ADR before implementation.

## Decision Drivers

- **Known Error is a knowledge claim, not an observable fact.** `Known Error` asserts "root cause known + workaround documented". A `fix(...): P<NNN>` commit establishes only that code claiming to fix the ticket landed — not that root cause was analysed. This is the inverse of P228's K→V seam, where "a release shipped" IS an observable fact safe to auto-fire on.
- **ADR-040 declarative-first / ADR-013 Rule 6 fail-open** — prefer advisory surfaces over hard blocks; never brick an AFK loop on a hygiene signal.
- **No fabrication under commit pressure** — a hard gate would force the agent to invent Known-Error semantics (or a transition) just to land the commit.
- **The drift is self-healing on cadence** — review-problems item 10 and P228's enumerator catch up later; the residual harm is a lag window, which an advisory shortens without asserting anything.

## Considered Options

1. **Post-commit advisory hook (chosen; ratified in the 2026-07-04 drain as P345 fix surface (a))** — detect the drift, emit a stderr nudge, never block.
2. **Release-time O→KE auto-fire** (extend P228's enumerator) — rejected: mechanically asserts Known-Error semantics (root-cause-known) that a fix-titled commit does not establish.
3. **Hard commit gate requiring a paired transition** — rejected: same semantic fabrication risk, plus ADR-040's advisory-over-block preference.
4. **Co-locate with the P314 fix-time RFC-trace gate** — rejected: only fires inside manage-problem/work-problems, missing direct `fix(...)` commits authored outside those skills — exactly the residual class.

## Decision Outcome

Chosen option: **post-commit advisory hook**, because **a lifecycle transition may only be automated on observable facts, and O→KE rests on a knowledge claim** — so the strongest honest surface for the fix-titled-commit signal is an advisory. Lifecycle drift on fix-titled commits surfaces as a PostToolUse:Bash ADVISORY (`packages/itil/hooks/itil-fix-title-lifecycle-advisory.sh`) that parses `fix(<pkg>): P<NNN>` commit titles in the just-landed HEAD commit and emits a stderr nudge when a named ticket is still `Open` on disk with no paired lifecycle transition in the same commit. Advisory-only, never blocks; NOT auto-fire, NOT a hard gate. The hook DETECTS; a skill (or the human) PERFORMS the transition, per ADR-014's hook-detects-skill-commits grain and the P378 sibling precedent.

**Binding rule for future lifecycle automation**: any surface acting on the fix-titled-commit signal MUST stay advisory unless the transition it fires asserts only observable facts (the P228 K→V shape — "a release shipped" is observable; "root cause is known" is not). "Upgrading" this advisory to an auto-fire or gate requires superseding this ADR.

## Consequences

### Good

- The drift is surfaced at the commit where it occurs, shrinking the lag window the catch-up cadences leave, with zero blocking risk to AFK loops.
- The knowledge-claim vs observable-fact boundary is now recorded where future designers will look (the compendium), not only in a ticket body.

### Neutral

- Copy-and-retarget of the P378 sibling (`itil-commit-trailer-transition-advisory.sh`); same cost profile (~one python3 spawn per Bash call).

### Bad

- An advisory can be ignored; durable orphaning remains possible for commits landed outside any session that reads stderr. The catch-up cadences (review-problems item 10, P228 enumerator) remain the backstop.

## Confirmation

Behavioural bats in `packages/itil/hooks/test/itil-fix-title-lifecycle-advisory.bats` exercise the hook end-to-end (ADR-052):

1. `fix(pkg): P<NNN> ...` commit with the ticket still in `docs/problems/open/` → stderr advisory naming the ticket, exit 0.
2. Same commit shape with the ticket in `known-error/` (or absent) → silent, exit 0.
3. Non-fix-titled commit naming a P<NNN> → silent (the signal is the `fix` type, not the token).
4. Advisory never blocks: exit 0 on every path, including bypass env var and malformed input.

## More Information

- P345 (`docs/problems/`) — driving problem; § Ratified Direction records the 2026-07-04 drain confirmation.
- ADR-073 — the fix-approach-needs-a-ratified-ADR clause this ADR discharges; RFC-044 traces the fix.
- P228 / P234 / P378 — sibling seams and the detect-then-advise hook precedent.
- ADR-040 (declarative-first), ADR-013 Rule 6 (fail-open), ADR-045 (injection budget), ADR-014 (hook detects, skill commits).
