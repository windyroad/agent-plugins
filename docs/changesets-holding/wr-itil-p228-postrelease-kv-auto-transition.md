---
"@windyroad/itil": patch
---

P228: work-problems Step 6.5 post-release K→V auto-transition callback —
closes the ADR-022 K→V auto-fire gap empirically witnessed by P220.

Driving incident: 2026-06-08 P220 — Phase 1 fix shipped in commit 0f58210
with `## Fix Released` populated, but the K→V transition was deferred
citing a misapplied P143 amendment. The ticket stranded in `.known-error/`
with no auto-fire surface to back-fill the transition. Investigation
(commit 4d4d0be) confirmed the gap empirically + named two viable fix
surfaces; user ratified Option B (work-problems Step 6.5 post-release
callback — tight coupling, zero K→V lag) over Option A (review-problems
~24h-lag) and Option C (close-as-superseded by ADR-079).

Ships:
- `packages/itil/lib/enumerate-postrelease-kv-candidates.sh` — new helper
  exporting `enumerate_postrelease_kv_candidates`. Walks
  `docs/problems/known-error/*.md`, invokes
  `wr-itil-derive-release-vehicle <NNN>` per ticket, emits
  `KV_CANDIDATE: P<NNN> | <changeset>` per shipped ticket (derive exit 0)
  and `KV_CANDIDATES_SUMMARY: total=<N>`. Skips legacy (exit 2 — no
  `**Release vehicle**` reference) and unreleased (exit 3 — changeset
  still in working tree) silently. Composes with P267's
  `derive-release-vehicle` helper as the deterministic filter.
- `packages/itil/scripts/run-enumerate-postrelease-kv-candidates.sh` —
  adopter-safe wrapper (sources lib relative to script per P317/RFC-009).
- `packages/itil/bin/wr-itil-enumerate-postrelease-kv-candidates` —
  ADR-049/ADR-080 PATH shim regenerated from the canonical template at
  `packages/shared/lib/shim-wrapper-template.sh`.
- `packages/itil/skills/work-problems/SKILL.md` Step 6.5 — new
  "Post-release K→V auto-transition (P228)" subsection wired as new
  Drain action step 4 (existing cache refresh renumbered to step 5).
  Per-`KV_CANDIDATE` line dispatches `/wr-itil:transition-problem
  <NNN> verifying` via the Skill tool. Non-blocking on individual
  failure; logs per-ticket; persistent failures route to Step 2.5b
  accumulated questions per existing discipline.
- `packages/itil/skills/work-problems/test/work-problems-step-6-5-postrelease-kv-callback.bats`
  — 9 behavioural test cases (absent dir / empty dir / shipped emit /
  no-vehicle skip / unreleased skip / mixed cohort / README excluded /
  unknown derive exit). Stubbed derive helper for fixture isolation.

Architectural posture (architect APPROVED 2026-06-08):
- ADR-022 (Verifying lifecycle) — implements the auto-fire surface
  ADR-022 contemplates but didn't wire.
- ADR-018 (release-cadence) — Drain action step ordering preserved;
  cache-refresh subsection renumbered to step 5; no ADR-018 amendment
  needed.
- ADR-010 amended P093 (split-skill execution ownership) — orchestrator
  dispatches transition-problem as the authoritative executor; documented
  forwarder pattern, not a round-trip.
- ADR-014 (per-transition commit grain) — each dispatched
  `/wr-itil:transition-problem` rides its own ADR-014 commit through
  architect / JTBD / risk-scorer gates per its existing contract.
- ADR-013 Rule 5 (policy-authorised silent-proceed) — callback rides
  the same authorisation as `push:watch` / `release:watch` /
  `/install-updates`; derive-helper-citation match is deterministic
  (filename equality), not a judgment call.
- ADR-044 (framework-resolution boundary) — per-candidate routing is
  framework-resolved; mid-loop `AskUserQuestion` forbidden per P130.

JTBD posture (jtbd-lead ALIGNED 2026-06-08):
- Primary: JTBD-006 (Progress the Backlog While I'm Away) — closes the
  manual loopback that previously stranded K→V transitions across AFK
  iterations.
- Persona constraint: V→C remains a maintainer-only surface; this
  callback fires K→V only — the maintainer's judgment-reserved "fix
  actually works" closure remains untouched.
- Adjacent: JTBD-001 (audit trail preserved by dispatching through
  transition-problem rather than inline state mutation).

P228 transitions Known Error → Verification Pending on this release.

@problem P228
@problem P220 (empirical witness)
@problem P267 (composed helper)
@problem P330 (input signal)
@adr ADR-022 ADR-018 ADR-010 ADR-014 ADR-013 ADR-044 ADR-049 ADR-080
@jtbd JTBD-006 JTBD-001 JTBD-101
