---
status: "proposed"
human-oversight: confirmed
oversight-date: 2026-06-10
date: 2026-04-18
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-07-18
---

# AFK orchestrator preflight: get the repo into a clean state before starting

## Context and Problem Statement

`/wr-itil:work-problems` and any future AFK orchestrator open their work
loop against local state — backlog files in `docs/problems/`, the cached
README ranking, and the local working tree. If the working tree or the
local-vs-origin relationship is not in a clean state when the loop opens,
the orchestrator iterates against a stale or contradictory view, silently
strands prior-session in-flight work, or commits half-done work as if it
were intentional.

The umbrella problem is **"the repo must be in a clean state before the
work loop opens"**. There are three classes of unclean state the
orchestrator encounters in practice:

1. **Origin has moved** (the local tree is behind a parallel session, CI,
   or another developer machine). Observed 2026-04-18 (P040): a parallel
   session advanced `origin/main` by 20+ commits, creating P031–P039 with
   completely different semantics than the local P031–P042 the
   orchestrator had created. The work-problems loop reviewed, ranked,
   transitioned, and worked four problems across five commits before the
   user intervened. The push then failed with a non-fast-forward error,
   requiring a surgical rebase that dropped 14 of the local problem
   tickets due to numbering collisions.
2. **Uncommitted work belongs in a commit** (a prior AFK subprocess hit
   quota, was cancelled, or crashed mid-iter, leaving in-flight changes
   in the working tree that belong to that iter's ticket). The current
   conservative behaviour is to halt; the umbrella goal calls for
   committing the in-flight work when its provenance is unambiguous and
   its risk is within appetite (deferred to a follow-up — see Branch 2
   below).
3. **The tree is genuinely messy** (ambiguous uncommitted state,
   non-fast-forward divergence, partial-prior-session work whose
   provenance is unclear, or signal combinations P109 enumerates). The
   orchestrator must surface the state to a human (interactive) or halt
   with a structured report (AFK) — never silently proceed.

The cache-freshness mechanism added by P031 solved a local-staleness
class of bug; this ADR addresses the distinct **clean-state preflight**
class.

## Decision Drivers

- **Sibling to ADR-018 (release cadence)**: both are AFK orchestrator
  lifecycle rules. ADR-018 covers WHEN to push/release; this ADR covers
  WHEN to start. They are deliberately separate so each ADR is single-
  purpose.
- **JTBD-006 audit trail** ("every action taken during AFK mode should
  be traceable via git history and the progress summary"): iterating on
  a stale view breaks the audit chain; silently stranding in-flight work
  breaks the "progress continues without me being present" guarantee;
  Branch 2's auto-commit (when implemented) MUST emit a distinct commit
  subject so the audit trail distinguishes preflight-recovered work from
  iter-N work.
- **JTBD-006 graceful stop on blocker** ("the loop stops gracefully
  when nothing actionable remains, or when it hits a blocker like a git
  conflict"): a non-fast-forward divergence and an ambiguously-dirty tree
  are both orchestrator-level "blockers" — Branch 3 is the formalisation.
- **JTBD-001 Enforce Governance Without Slowing Down**: Branch 2's
  auto-commit (when implemented) MUST compose with the architect / JTBD
  / style-guide / voice-tone / TDD / risk-scorer gates the standard
  commit path enforces. Pre-existing changes whose gate state is unknown
  MUST demote to Branch 3 rather than silently bypass governance.
- **JTBD-008 audit trail for coordinated changes**: pre-existing
  uncommitted source edits without an in-progress RFC trace are signals
  for Branch 3 (ambiguous provenance), not Branch 2 (routine recovery).
- **Solo-developer persona constraint**: the user trusts the agent to
  commit low-risk changes and does NOT trust the agent to resolve
  non-trivial merge conflicts or commit high-risk changes. The 3-branch
  shape maps cleanly onto this axis — Branch 2 is the "routine
  low-risk" lane, Branch 3 is the "judgment-call / high-risk" lane.
- **Non-interactive authorisation (ADR-013 Rule 6)**: `git fetch` and
  `git pull --ff-only` are policy-authorised (no semantic merge); auto-
  commit of provenance-unambiguous in-flight work routed through the
  standard gate pipeline is policy-authorised by analogy with ADR-014
  ("governance skills commit their own completed work"); semantic merge,
  rebase, and ambiguous-state resolution are NOT policy-authorised and
  route to Branch 3.
- **Operator trust**: the 14 dropped tickets in the 2026-04-18 incident
  represent real lost work and substantial recovery effort.

## Considered Options

1. **Three-branch clean-state preflight: Pull (ff-only) / Commit (in-flight
   routine recovery; conservative routing-to-Branch-3 until follow-up
   defines auto-commit criteria) / AskUserQuestion or AFK-halt (messy
   tree)** — the umbrella reframe driven by the user direction 2026-05-25:
   *"what I really want is to get the repo into a clean state before
   starting. Sometimes that's a pull, sometimes that needs some commits.
   Sometimes it's in a mess and needs decision input via AskUserQuestion."*
2. **Narrow: mandatory `git fetch origin` + divergence check at loop
   start, with non-interactive `git pull --ff-only` on trivial
   divergence** — the prior (narrow) scope of this ADR. Covers only
   Branch 1; silently halts on Branch 2-shaped state; halts (interactive
   via P109 extension only) on Branch 3-shaped state without naming the
   umbrella goal.
3. **Trust local state; fetch only when push fails (reactive)** — the
   P040 failure mode this ADR was originally introduced to prevent.
4. **Full `git pull --rebase` preflight (eager, mutative)** — too
   aggressive; mutates the working tree before the user has indicated
   intent to reconcile diverged work.

## Decision Outcome

Chosen option: **"Three-branch clean-state preflight"**, because it is
the honest articulation of the umbrella goal the user pinned 2026-05-25
*"get the repo into a clean state before starting"*. It absorbs P040's
narrow-fetch case (Branch 1), the prior-session in-flight recovery case
JTBD-006 names (Branch 2), and the genuinely-messy-tree case P109
enumerates the signals for (Branch 3). The 3-branch shape maps cleanly
onto the solo-developer persona's risk-graded trust axis. Reactive
fetching (option 3) is the failure mode P040 documents. Eager rebase
(option 4) violates the persona constraint on non-trivial conflict
resolution.

### Branches

**Branch 1 — Pull (origin moved, trivial fast-forward):**

- Run `git fetch origin`.
- Compare local `HEAD` with `origin/<base>` (default `main`, or the
  branch the user is on if not `main`).
- If `HEAD` is at or ahead of `origin/<base>`: proceed (Branch 1's
  trivial case, no mutation).
- If `origin/<base>` is ahead of `HEAD` and the divergence is a pure
  fast-forward (local has no commits not on origin): run
  `git pull --ff-only` non-interactively. Report the count of pulled
  commits in the AFK iteration log. Proceed.
- **Network failure**: if `git fetch origin` returns a network error,
  halt with report (fail-closed). The user can retry when network is
  restored.

**Branch 2 — Commit (uncommitted work that belongs in a commit):**

The user direction includes *"sometimes that needs some commits"* — the
umbrella goal authorises auto-committing pre-existing uncommitted work
when **both** of the following discriminator conditions hold:

1. **Provenance unambiguous**: the uncommitted changes are attributable
   to the prior iter's own in-flight flow (e.g. an `.afk-run-state/iter-*.json`
   with `"is_error": true` AND a coherent diff scoped to that iter's
   ticket file + related source paths). When provenance cannot be
   established by mechanical inspection, demote to Branch 3.
2. **Risk within appetite**: the change risk is computable and below the
   appetite per ADR-018 (and RISK-POLICY.md). When risk exceeds appetite
   or cannot be scored, demote to Branch 3.

**Gate composition (per JTBD-001)**: Branch 2's auto-commit MUST route
through the same architect / JTBD / style-guide / voice-tone / TDD /
risk-scorer gates as a standard iter commit. Pre-existing changes whose
gate state is unknown (no markers in `/tmp` for the current session)
MUST demote to Branch 3 — auto-commit must not silently bypass
governance.

**Audit-trail commit-subject convention (per JTBD-006)**: Branch 2
commits MUST carry a distinct subject so the audit trail distinguishes
preflight-recovered work from iter-N work. Convention:

```text
chore(preflight): recover prior-session in-flight work — <ticket-ref>
```

**Deferred — current implementation routes Branch 2 → Branch 3**: the
auto-commit criteria above name the discriminator, but the live work-
problems Step 0 implementation conservatively routes all uncommitted-
source-edit signals to Branch 3 (halt-with-report) until a follow-up
problem ticket lands the auto-commit mechanism, the risk-score gate
wiring, and the contract-assertion bats. The umbrella ADR documents
Branch 2's shape so a future reader sees the goal even while the
implementation is conservative. Follow-up to be captured.

**Branch 3 — AskUserQuestion / AFK-halt (genuinely messy tree):**

A tree is "genuinely messy" when any of the following signals are
present and cannot be resolved by Branch 1 (pull) or Branch 2 (in-flight
commit) under their discriminator conditions:

- Non-fast-forward divergence (local has commits not on `origin/<base>`
  AND `origin/<base>` is ahead). Do NOT attempt rebase or merge non-
  interactively.
- Ambiguous uncommitted state (provenance not establishable; or
  risk-above-appetite; or gate state unknown).
- Partial prior-session work whose provenance is unclear (the P109
  signal enumeration below).

**Routing per ADR-013:**

- **Interactive** (Rule 1): present the Prior-Session State report via
  `AskUserQuestion` with four options — Resume / Discard / Leave-and-
  lower-priority / Halt. Route the chosen branch before opening the
  work loop.
- **Non-interactive / AFK** (Rule 6): **halt the loop with the structured
  report**. This is a deliberate HALT carve-out from the 2026-06-06
  Rule 6 amendment's queue-and-continue default — ambiguous session-
  continuity state requires user input, and non-interactive recovery
  would mask the bug this preflight is meant to surface. Future
  amendments to Rule 6 should preserve this carve-out unless the
  underlying bug-masking concern is independently addressed.

### Mechanism

- Before opening the work loop, the orchestrator MUST execute the
  branch routing above in this order:
  1. Run `git fetch origin` (Branch 1 gate; network-failure halts).
  2. Run the session-continuity detection pass (enumerated below) to
     populate the signal set that drives Branch 2 vs Branch 3 routing.
  3. Resolve via Branches 1 / 2 / 3 according to the signal shape.
- **Numbering-collision guard**: before creating any new ticket
  (problem, ADR, JTBD), the orchestrator (or its delegated skill) MUST
  re-check the next-ID assignment against `origin/<base>` via
  `git ls-tree origin/<base> docs/problems/` (or the equivalent for ADRs/
  JTBD). If the local choice would collide with an ID created on origin
  since the last fetch, renumber.
- Scope is **cross-cutting**: applies to any AFK orchestrator skill, not
  just `/wr-itil:work-problems`. Orchestrator skills MUST cite ADR-019
  in their SKILL.md.

### Session-continuity signal enumeration (Branch 3 detection mechanism, per P109)

The detection enumeration below populates the signal set the branch
router consumes. P109 introduced this enumeration as a `Step 0`
extension 2026-04-25; the 3-branch reframe absorbs it as Branch 3's
detection mechanism. The five signals are preserved verbatim from the
P109 extension so the contract-assertion bats at
`packages/itil/skills/work-problems/test/work-problems-preflight-session-continuity.bats`
continue to hold:

- Untracked `docs/decisions/*.proposed.md` — drafted but unlanded ADRs
  from a prior iter.
- Untracked `docs/problems/*.md` — drafted but unlanded problem
  tickets.
- `.afk-run-state/iter-*.json` with `"is_error": true` or
  `"api_error_status" >= 400` AND fresh per the staleness filter (P333
  refinement: file mtime newer than HEAD's commit time OR within the
  last 24h, whichever is more permissive; stale residuals silently
  skipped with one-line iter-summary annotation).
- Stale `.claude/worktrees/*` dirs + `git worktree list` entries on
  `claude/*` branches — prior subagent worktrees that were not cleaned
  up. Detection only — mutation (cleanup) is out of scope and requires
  a separate ADR.
- Uncommitted modifications to SKILL.md / source / ADR files — the
  prior session was mid-authoring. The Branch 2 discriminator applies
  to this signal class first (provenance + risk-appetite gates); under
  the current conservative implementation it routes to Branch 3.

When any signal is present, build a structured Prior-Session State
report listing each hit (signal category, path, one-line summary). An
empty signal set means clean pass-through to the work loop. This
extension was originally introduced within the 2026-07-18 reassessment
window per P109 (no new ADR); the present amendment reframes the
umbrella decision and is in-place per the ADR-066 substance-change
clearance (P301 marker-only-diff exemption).

### Non-interactive authorisation summary

- **Branch 1 actions** (`git fetch origin`, `git pull --ff-only`):
  policy-authorised per ADR-013 Rule 6. No semantic merge, no
  destructive overwrite.
- **Branch 2 auto-commit** (deferred; conservative routing-to-Branch-3
  in the current implementation): policy-authorised by analogy with
  ADR-014 when the Branch 2 discriminator + JTBD-001 gate composition
  hold. The discriminator failure-mode (any unmet condition) demotes to
  Branch 3.
- **Branch 3 routing** (interactive `AskUserQuestion` / AFK halt-with-
  report): interactive surfacing per ADR-013 Rule 1; AFK halt is a
  deliberate carve-out from Rule 6's 2026-06-06 queue-and-continue
  default, justified by the bug-masking concern.
- **Always-forbidden**: `git pull --rebase`, `git merge` resolving
  semantic conflicts, any operation that resolves uncommitted-state
  ambiguity without user input. These require Branch 3 routing.

## Consequences

### Good

- Stale-backlog and ID-collision incidents like 2026-04-18 are prevented
  at source (Branch 1).
- Prior-session in-flight work has a named umbrella treatment (Branch 2)
  rather than silently halting alongside ambiguous state — even under
  the current conservative implementation, the umbrella names the
  shape and the discriminator the follow-up will encode.
- Genuinely-messy-tree state is surfaced to a human (interactive) or
  halts with a structured report (AFK) — never silently proceeded past
  (Branch 3).
- Aligns the orchestrator with the user's "trust agent for routine,
  halt for judgment calls" persona constraint via the Branch 2 / Branch
  3 risk-graded routing.

### Neutral

- Adds ~1–3 seconds of `git fetch` latency at loop start (network bound).
- Cross-cutting rule means every AFK orchestrator needs a preflight step
  added.
- The umbrella reframe documents Branch 2 even though its auto-commit
  is currently routed-to-Branch-3 by the live implementation. A future
  reader sees a 3-branch ADR with a 2-branch implementation; the
  Deferred clause inside Branch 2 names the gap so the audit trail
  reads as intentional, not as drift.

### Bad

- A network-unreachable origin would block the loop. Mitigation: the
  orchestrator should fail open (proceed with a warning) only if
  `git fetch` returns a network-error exit code distinct from
  divergence-or-conflict; otherwise stop. Default behaviour: stop and
  report — the user can retry when network is restored.
- The collision guard adds a per-ticket-create `git ls-tree` call.
  Trivial cost.
- Branch 2's deferred implementation means the conservative current
  behaviour (halt on uncommitted source edits regardless of
  provenance / risk) lasts until the follow-up ticket lands the auto-
  commit mechanism. This is a known trade-off — the alternative is
  shipping Branch 2's auto-commit without the gate-composition wiring,
  which would silently bypass governance (forbidden per JTBD-001).

## Confirmation

Compliance is verified by:

1. **Source review**: every AFK orchestrator skill in `packages/*/skills/`
   that loops over a backlog has a preflight step naming the three
   branches and routing per the discriminator above.
2. **Source review**: every skill that creates new IDs in `docs/`
   (problem, ADR, JTBD) has a numbering-collision guard against
   `git ls-tree origin/<base>`.
3. **Test**: a bats test asserts `packages/itil/skills/work-problems/SKILL.md`
   references both `git fetch origin` and `git pull --ff-only` in its
   Branch 1 preflight section, and names the three-branch umbrella in
   the Step 0 introduction.
4. **Behavioural**: simulate a diverged origin (temp git repo with extra
   commits on origin/main); verify the orchestrator either pulls (Branch
   1 trivial case) or halts with a Branch 3 divergence report (non-fast-
   forward case).
5. **Contract-assertion bats** (P109 extension, preserved through the
   3-branch reframe): a bats file asserts SKILL.md Step 0 enumerates
   the five session-continuity signals (per the Mechanism section),
   cites P109, cites ADR-013 Rule 6 for the AFK halt branch, names the
   four interactive-branch options, and carries a Non-Interactive
   Decision Making table row for the new branch. See
   `packages/itil/skills/work-problems/test/work-problems-preflight-session-continuity.bats`.

## Pros and Cons of the Options

### Three-branch clean-state preflight (chosen)

- Good: honest articulation of the umbrella goal the user pinned.
- Good: 3-branch shape maps cleanly onto the solo-developer persona's
  risk-graded trust axis.
- Good: absorbs P040's narrow-fetch case + P109's session-continuity
  detection enumeration without re-opening either's closure.
- Bad: Branch 2's auto-commit deferred to a follow-up ticket; current
  implementation conservatively routes Branch 2 → Branch 3 (halts on
  uncommitted source edits even when in-flight provenance might be
  unambiguous).

### Narrow: mandatory fetch + ff-only (prior, superseded by the reframe)

- Good: cheap; surfaces problems early; only mutates on safe (ff)
  merges.
- Good: aligns with "trust for routine, halt for judgment" persona.
- Bad: silently halts on Branch 2-shaped state without naming the
  umbrella; reader has to derive the umbrella from the SKILL.md prose
  rather than the ADR.
- Bad: requires a network round-trip; offline-AFK becomes a stop
  condition.

### Reactive (fetch only on push failure)

- Good: zero latency until something goes wrong.
- Bad: this is the P040 failure mode — by the time push fails, hours of
  AFK work may need to be unwound.
- Bad: recovery cost is much higher than prevention cost.

### Eager rebase preflight

- Good: leaves the orchestrator with the freshest possible state.
- Bad: `git pull --rebase` mutates the working tree even on non-trivial
  divergence; can leave the tree in a conflicted state.
- Bad: non-interactive rebase conflict resolution is exactly the kind of
  judgment call the persona forbids.

## Reassessment Criteria

Revisit this decision if:

- The project moves to a workflow where local divergence from `origin`
  is expected (e.g. long-lived feature branches replace trunk-based
  work).
- The number of AFK orchestrator skills grows past 3 — at that point a
  shared preflight helper skill may make more sense than per-skill
  preflights.
- Operational data shows `git fetch` latency is unacceptable, or
  network-unreachable origins are common enough to warrant a fail-open
  policy.
- ADR-018 is superseded — the two ADRs are deliberately paired.
- The Branch 2 follow-up ticket lands the auto-commit mechanism +
  gate-composition wiring + bats. At that point, the live implementation
  realises the full 3-branch shape and this ADR's "Deferred — current
  implementation routes Branch 2 → Branch 3" clause is removed.
- The 2026-06-06 ADR-013 Rule 6 queue-and-continue amendment's bug-
  masking concern is independently addressed for the session-continuity
  signal class. At that point the Branch 3 AFK-halt carve-out can be
  re-evaluated against the queue-and-continue default.
