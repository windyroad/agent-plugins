---
status: "proposed"
date: 2026-04-18
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-07-18
---

# AFK orchestrator preflight: fetch-origin and divergence handling

## Context and Problem Statement

`/wr-itil:work-problems` and any future AFK orchestrator open their work
loop by reading local state — backlog files in `docs/problems/`, the cached
README ranking, and the local working tree. None of them check `origin`
state before starting. When a parallel session (another developer machine,
another Claude session, CI) has advanced `origin/<base>` since the last
local fetch, the orchestrator iterates against a stale local view.

Observed 2026-04-18 (P040): a parallel session advanced `origin/main` by
20+ commits, creating P031–P039 with completely different semantics than
the local P031–P042 the orchestrator had created. The work-problems loop
reviewed, ranked, transitioned, and worked four problems across five
commits before the user intervened. The push then failed with a
non-fast-forward error, requiring a surgical rebase that dropped 14 of the
local problem tickets due to numbering collisions.

The cache-freshness mechanism added by P031 solved a local-staleness class
of bug; this ADR addresses the distinct **remote-divergence** class.

## Decision Drivers

- **Sibling to ADR-018 (release cadence)**: both are AFK orchestrator
  lifecycle rules. ADR-018 covers WHEN to push/release; this ADR covers
  WHEN to start. They are deliberately separate so each ADR is single-
  purpose.
- **JTBD-006 audit trail**: every AFK action should be traceable; iterating
  on a stale view breaks the audit chain.
- **JTBD-006 graceful stop on blocker**: a non-fast-forward divergence is
  the orchestrator-level equivalent of the "git conflict" blocker JTBD-006
  already lists.
- **Solo-developer persona**: the user does not trust the agent to resolve
  non-trivial merge conflicts — the orchestrator must stop and report, not
  attempt to "merge through".
- **Non-interactive authorisation (ADR-013 Rule 6)**: a fast-forward pull
  is policy-authorised (no semantic merge, no conflict resolution); a
  non-fast-forward pull is not.
- **Operator trust**: the 14 dropped tickets in the 2026-04-18 incident
  represent real lost work and substantial recovery effort.

## Considered Options

1. **Mandatory `git fetch origin` + divergence check at loop start, with
   non-interactive `git pull --ff-only` on trivial divergence**
2. **Trust local state; fetch only when push fails (reactive)**
3. **Full `git pull --rebase` preflight (eager, mutative)**

## Decision Outcome

Chosen option: **"Mandatory fetch + ff-only on trivial divergence"**,
because it is cheap (a single `git fetch`), surfaces the problem before
any work is done (cheap to recover), and only mutates the working tree on
a fast-forward (which is policy-authorised per ADR-013 Rule 6 — no
semantic merge, no conflict resolution). Reactive fetching (option 2) is
the failure mode P040 documents. Eager rebase (option 3) is too aggressive
— it mutates the working tree before the user has indicated intent to
reconcile diverged work.

**Mechanism**:

- Before opening the work loop, the orchestrator MUST run `git fetch
  origin` and compare local `HEAD` with `origin/<base>` (default `main`,
  or the branch the user is on if not `main`).
- If `HEAD` is at or ahead of `origin/<base>`: proceed normally.
- If `origin/<base>` is ahead of `HEAD` and the divergence is a pure
  fast-forward (local has no commits not on origin): run
  `git pull --ff-only` non-interactively. Report the count of pulled
  commits in the AFK iteration log.
- If `origin/<base>` is ahead AND local has unpushed commits
  (non-fast-forward divergence): STOP the loop with a clear divergence
  report (`git log --oneline HEAD..origin/<base>` and
  `git log --oneline origin/<base>..HEAD`). Do NOT attempt to rebase or
  merge non-interactively. Surface the divergence to the user.
- **Numbering-collision guard**: before creating any new ticket
  (problem, ADR, JTBD), the orchestrator (or its delegated skill) MUST
  re-check the next-ID assignment against `origin/<base>` via
  `git ls-tree origin/<base> docs/problems/` (or the equivalent for ADRs/
  JTBD). If the local choice would collide with an ID created on origin
  since the last fetch, renumber.
- **Session-continuity detection pass** (extension per P109, 2026-04-25):
  after the fetch/divergence check, the orchestrator MUST enumerate
  prior-session partial-work signals in the working tree — untracked
  `docs/decisions/*.proposed.md`, untracked `docs/problems/*.md`,
  `.afk-run-state/iter-*.json` with `"is_error": true` or
  `"api_error_status" >= 400`, stale `.claude/worktrees/*` dirs +
  `git worktree list` entries on `claude/*` branches, and uncommitted
  modifications to SKILL.md / source / ADR files. When any signal is
  present, build a structured Prior-Session State report. Route per
  ADR-013 Rule 1 (interactive `AskUserQuestion` with 4 options: resume /
  discard / leave-and-lower-priority / halt) or Rule 6 (non-interactive /
  AFK halt-with-report). Detection only — worktree cleanup (mutation) is
  out of scope and would require a separate ADR. This extension is
  within the 2026-07-18 reassessment window; no new ADR is created.
- Scope is **cross-cutting**: applies to any AFK orchestrator skill, not
  just `/wr-itil:work-problems`. Orchestrator skills MUST cite ADR-019 in
  their SKILL.md.

**Non-interactive authorisation**: per ADR-013 Rule 6, `git fetch origin`
and `git pull --ff-only` are policy-authorised actions (no semantic merge,
no destructive overwrite). `git pull --rebase`, `git merge`, and any
operation that resolves conflicts are NOT policy-authorised — they require
user input. The fail-safe (stop with divergence report) applies to the
non-fast-forward branch.

## Consequences

### Good

- Stale-backlog and ID-collision incidents like 2026-04-18 are prevented at
  source.
- The orchestrator surfaces remote divergence in seconds, not after several
  iterations of wasted work.
- Trivial fast-forward divergence is handled non-interactively, preserving
  the AFK promise.
- Aligns the orchestrator with the user's "trust agent for routine, halt
  for judgment calls" persona constraint.

### Neutral

- Adds ~1–3 seconds of `git fetch` latency at loop start (network bound).
- Cross-cutting rule means every AFK orchestrator needs a preflight step
  added.

### Bad

- A network-unreachable origin would block the loop. Mitigation: the
  orchestrator should fail open (proceed with a warning) only if
  `git fetch` returns a network-error exit code distinct from
  divergence-or-conflict; otherwise stop. Default behaviour: stop and
  report — the user can retry when network is restored.
- The collision guard adds a per-ticket-create `git ls-tree` call. Trivial
  cost.

## Confirmation

Compliance is verified by:

1. **Source review**: every AFK orchestrator skill in `packages/*/skills/`
   that loops over a backlog has a preflight step that runs `git fetch
   origin`, compares HEAD with `origin/<base>`, attempts `git pull
   --ff-only` on trivial divergence, and stops with a report on
   non-fast-forward divergence.
2. **Source review**: every skill that creates new IDs in `docs/` (problem,
   ADR, JTBD) has a numbering-collision guard against `git ls-tree
   origin/<base>`.
3. **Test**: a bats test asserts `packages/itil/skills/work-problems/SKILL.md`
   references both `git fetch origin` and `git pull --ff-only` in its
   preflight section.
4. **Behavioural**: simulate a diverged origin (temp git repo with extra
   commits on origin/main); verify the orchestrator either pulls (trivial
   case) or stops with a divergence report (non-fast-forward case).
5. **Contract-assertion bats** (P109 extension): a bats file asserts
   SKILL.md Step 0 enumerates the five session-continuity signals (per
   the Mechanism section), cites P109, cites ADR-013 Rule 6 for the AFK
   halt branch, names the four interactive-branch options, and carries a
   Non-Interactive Decision Making table row for the new branch. See
   `packages/itil/skills/work-problems/test/work-problems-preflight-session-continuity.bats`.

## Pros and Cons of the Options

### Mandatory fetch + ff-only (chosen)

- Good: cheap; surfaces problems early; only mutates on safe (ff) merges.
- Good: aligns with "trust for routine, halt for judgment" persona.
- Bad: small latency overhead at loop start.
- Bad: requires a network round-trip; offline-AFK becomes a stop condition.

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

- The project moves to a workflow where local divergence from `origin` is
  expected (e.g. long-lived feature branches replace trunk-based work).
- The number of AFK orchestrator skills grows past 3 — at that point a
  shared preflight helper skill may make more sense than per-skill
  preflights.
- Operational data shows `git fetch` latency is unacceptable, or
  network-unreachable origins are common enough to warrant a fail-open
  policy.
- ADR-018 is superseded — the two ADRs are deliberately paired.
