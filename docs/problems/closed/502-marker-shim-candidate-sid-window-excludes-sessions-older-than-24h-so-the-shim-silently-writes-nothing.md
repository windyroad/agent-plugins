# Problem 502: The marker shim's 24h candidate-SID window excludes long sessions, so it silently writes no marker

**Status**: Closed
**Reported**: 2026-08-20
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3 — derived at capture. Impact 3: the caller cannot land the `human-oversight: confirmed` edit the shim exists to permit, and the deny message points back at the shim that just "succeeded" — a recoverable dead-end with a documented env-var workaround, not data loss. Likelihood 3: fires only on sessions older than 24h, which is a minority of sessions but the normal shape of an AFK `/wr-itil:work-problems` loop and of multi-day interactive sessions; observed once in the 2026-08-20 transcript sweep.
**Origin**: internal
**Effort**: S — derived at capture: a window/fallback policy change at three duplicated sites plus bats coverage that already has a window-override entry point. Sized against P380, the same three-site sweep over the same `find /tmp` enumeration.
**WSJF**: 9 — (9 × 1.0) / 1 (added 2026-08-21 review)
**JTBD**: JTBD-001
**Persona**: developer

## Closed as no longer relevant

- **Evidence shape**: current source and focused behavioural checks, plus direct exercise of the published packages.
- **Closed on**: 2026-08-31.
- **Current-source evidence**: commit `c5a0cb23` removed candidate-SID enumeration from the architect and JTBD oversight helpers. Each helper now validates one standalone command; its `PostToolUse:Bash` hook writes one artefact-and-session marker from the exact successful command event's injected `session_id`.
- **Published evidence**: registry packages `@windyroad/architect@0.22.1` and `@windyroad/jtbd@0.14.3` match that caller-bound implementation. In isolated packed-package fixtures with an aged announce marker present, the architect and JTBD hooks wrote two markers total, both for the fixture caller, and none for the aged unrelated session. Published `@windyroad/itil@2.1.8` retained the deliberate 1440-minute ADR-050 (Capture the runtime stdin session_id via a PreToolUse hook so the create-gate marker binds to the same SID the runtime hook will see) fanout bound, returned the fixture caller from the runtime-SID path, and returned exit 1 when no candidate existed.
- **Behavioural evidence**: `npx bats packages/architect/hooks/test/architect-oversight-marker-discipline.bats packages/jtbd/hooks/test/jtbd-oversight-marker-discipline.bats packages/itil/hooks/test/session-id.bats packages/itil/hooks/test/manage-problem-enforce-create.bats` passed 78/78. This covers exact caller binding without announce markers, rejection of unrelated or non-exact events, runtime-SID precedence, bounded candidate enumeration, empty-candidate output, and create-gate enforcement.
- **Architecture and JTBD review**: fresh `wr-architect:agent` and `wr-jtbd:agent` reviews passed. The closure preserves ADR-002 (Monorepo with Independently Installable Per-Plugin Packages), ADR-038 (Progressive disclosure + once-per-session budget for UserPromptSubmit governance prose), ADR-050, ADR-110 (A ratification marker can only be written when someone actually ratified), ADR-116 (Ratified decisions change only by supersession), JTBD-001 (Enforce Governance Without Slowing Down), and JTBD-006 (Progress the Backlog While I'm Away); no fix row, new decision, job, map, story, or implementation is required.
- **Residual boundary**: this closure does not claim that ADR-050 guarantees the caller in every compound same-project concurrency case. If a caller's announce marker is older than 1440 minutes while the shared runtime marker holds a concurrent sibling SID, the subsequent create gate may still deny. ADR-050 accepts that recoverable fail-closed tradeoff. It is not the former oversight-shim silent-zero-write or cross-session authority-grant defect.
- **Recovery**: rerun `/wr-itil:transition-problem 502 known-error` to reopen if the caller-bound oversight path regresses or new evidence shows the reported defect remains.

## Description

`packages/itil/hooks/lib/session-id.sh::get_candidate_session_ids` enumerates `/tmp/*-announced-<UUID>` markers with `find -L ... -mmin "-${window_mins}"`, where `window_mins="${SESSION_CANDIDATE_WINDOW_MINS:-1440}"` (line 214). The same 1440 default is duplicated inline at `packages/architect/scripts/mark-oversight-confirmed.sh:79` and `packages/jtbd/scripts/mark-oversight-confirmed.sh:80`.

A session running longer than 24 hours has an announce marker whose mtime now falls outside that window. Enumeration returns empty, the shim takes its cold path, prints a stderr diagnostic, and **exits 0**. The caller reads exit 0 as success and proceeds. The `architect-oversight-marker-discipline` hook then DENIES the `human-oversight: confirmed` Edit the shim was invoked to permit — and its deny message points the caller back at the shim they just ran.

The condition is distinct from an empty `CLAUDE_SESSION_ID`: here candidate markers **do** exist on disk and are simply filtered out by age.

Observed 2026-08-07 in the `windyroad` repo (session `8bf5f717`), recorded in that session's own compaction summary:

> Marker shim silent no-op. Candidate-SID enumeration uses a 1440-min window; session had run longer. Exit 0, no marker. Fixed with `SESSION_CANDIDATE_WINDOW_MINS=10080`.

Surfaced by a 2026-08-20 sweep of ~4,200 Claude Code transcripts and ~16,100 Codex session files.

## The bound is deliberate — this ticket re-litigates it, it does not report a forgotten default

`session-id.sh` lines 201-202 already name this exact failure mode as an accepted tradeoff: *"A loop running >24h degrades gracefully to the recoverable create-gate deny (status quo), not silent corruption."* The bound exists to defend against the stale-marker accumulation pathology recorded on **P124** (the 103-accumulated-UUID regression). Widening the window trades one pathology for the other, so the fix is a design question, not a constant bump.

The naive remedy — raise the default to 10080 (the in-session workaround) — is therefore **not** obviously correct and must not be applied without weighing the P124 direction.

**Measured on this machine, 2026-08-20** — the accumulation is not hypothetical and is not historical:

| Marker family | Count in `/tmp` (or `$TMPDIR`) |
|---|---|
| `*-announced-<UUID>` (the candidate corpus this window filters) | 1,435 |
| `manage-problem-grep-<UUID>-*` (create-gate markers) | 1,002 |
| `claude-risk-<UUID>/` (risk-marker dirs) | 266 |

This sharpens the tradeoff rather than settling it. `wr-itil-mark-create-gate` writes its marker under **every** candidate SID (ADR-050 Option C, P260) — the 1,002 create-gate markers above are what a 1440-minute window already produces. A 10080-minute window widens the candidate set that each marker-write fans out across, so the workaround scales the write cost with the very corpus P124 was raised about. Any fix that keeps age-bounded enumeration should be sized against these numbers, and a `/tmp` reaper may be the missing prerequisite rather than a separate concern.

## Symptoms

- `wr-architect-mark-oversight-confirmed` / `wr-jtbd-mark-oversight-confirmed` exit 0, print `no candidate session id discoverable` on stderr, and write nothing.
- The subsequent `human-oversight: confirmed` Edit is denied by the oversight-marker-discipline hook.
- The deny message names the shim as the remedy, so a caller that does not read stderr loops.

## Workaround

Export a wider window before invoking the shim:

```bash
SESSION_CANDIDATE_WINDOW_MINS=10080 wr-architect-mark-oversight-confirmed <path>
```

Session-local only; nothing makes a future session apply it.

## Impact Assessment

- **Who is affected**: any session older than 24h that needs to ratify a governance artefact — AFK `/wr-itil:work-problems` loops and multi-day interactive sessions. Adopters as well as this repo (the shim ships in `@windyroad/architect` and `@windyroad/jtbd`).
- **Frequency**: once per ratification attempt, for the whole remaining life of the session.
- **Severity**: recoverable dead-end. No corruption; the marker is absent rather than wrong.
- **Analytics**: 2026-08-20 transcript sweep — one confirmed occurrence with an in-session diagnosis; the silent-exit-0 shape means undiagnosed occurrences would present only as an unexplained oversight-marker deny.

## Root Cause Analysis

### Preliminary Hypothesis

Candidate enumeration bounds recency by marker **mtime**, but an announce marker's mtime records when the session *started*, not when it was last active. Session liveness and marker age are therefore uncorrelated for exactly the long-running sessions the bound is meant to exclude. Any fix that keeps an age bound but refreshes marker mtime on activity (or falls back to the newest marker regardless of age when enumeration is otherwise empty) resolves the tension without re-opening P124's accumulation.

### Investigation Tasks

- [x] Confirm whether announce markers are ever re-touched during a session, or written once at SessionStart: ADR-038 confirms write-once, with no touch refresh.
- [x] Weigh the candidate fixes against P124's accumulation pathology: P368 (The oversight-marker helper writes markers for the wrong sessions and exits silently) removed announce-marker discovery from oversight confirmation instead of weakening ADR-050's bounded create-gate fanout.
- [x] Decide whether the cold-path `exit 0` contract should change: the oversight helper is now a validator whose exact PostToolUse event writes evidence; the separate ITIL create-gate wrapper returns nonzero when its candidate stream is empty.
- [x] De-duplicate the 1440 literal across the three sites: the architect and JTBD copies no longer exist; the ITIL constant remains local under ADR-002 and deliberate under ADR-050.
- [x] Create a reproduction test: focused source suites pass 78/78, and isolated published-package fixtures exercise aged announce markers, exact caller binding, runtime-SID selection, and the no-candidate exit.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P124, P260, P368, P380

## Related

(captured via `/wr-itil:capture-problem`; hang-off arbitration returned PROCEED_NEW)

- **P260** (`docs/problems/verifying/260-p119-create-gate-marker-race-between-concurrent-claude-sessions-via-shared-runtime-sid-file.md`) — **the design-authority sibling.** The bounded multi-UUID candidate-write this ticket indicts originates in P260's ADR-050 Option C. The pre-filter did not surface it; the hang-off arbiter did, and flagged that P260 may be the better absorbing parent. Re-evaluate at the next `/wr-itil:review-problems` cluster pass.
- **P124** (`docs/problems/verifying/124-manage-problem-step-2-session-id-discovery-is-brittle.md`) — the stale-marker accumulation pathology (103 accumulated UUIDs) that motivated the bound. Its three released phases concern *selection among present candidates* in `get_current_session_id`; this ticket concerns *exclusion of candidates before selection* in `get_candidate_session_ids`. In tension with P124's fix, not an extension of it.
- **P368** (`docs/problems/verifying/368-wr-architect-mark-oversight-confirmed-cannot-discover-session-id-when-clause-empty-and-no-announce-markers.md`) — nearest sibling, distinguished on all three axes. P368's root cause narrowed to the macOS `/tmp`-symlink `find` bug, fixed with `find -L` via P380 and shipped in `@windyroad/architect@0.18.4`; that `-L` is present and working. The stderr-diagnostic-then-exit-0 behaviour described above **is** P368's shipped option-(b) fix behaving as specified. This is a residual gap in that fix, not a re-open of it.
- **P380** — the three-site `find /tmp` sweep; the precedent for the cross-package shape a fix here would take.
- **P402** (reopened) — sibling marker-persistence failure on a different axis (dispatch mode). Same user-visible symptom: a genuine review the gate cannot see.
- Surfaced alongside P503 (Bash-routed writes bypass the `Edit|Write`-scoped gates) by the same 2026-08-20 transcript sweep.
