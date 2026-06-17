# I13 fix-time RFC-trace gate — rollout survey

**Date**: 2026-06-17
**Task**: RFC-005 B7 (migration sweep)
**Driver**: P314 (Rework the fix-time RFC-trace gate) Phase 2
**Method**: read-only enumeration of `docs/problems/known-error/` tickets, classified by the shipped predicate `wr-itil-check-fix-rfc-trace` (RFC-005 B3) + `## Fix Strategy`-section presence.

## Purpose

The I13 invariant (ADR-060) requires every fix proposed on a Known Error to trace to an RFC (ADR-071 unconditional; ADR-072 places the gate at the propose-fix step; ADR-073 auto-creates a missing RFC rather than blocking). RFC-005 B3/B4/B5 shipped the gate 2026-06-16. This survey enumerates the **already-Known-Error backlog** to answer the two questions RFC-005 B7 scopes:

1. **Which existing Known-Error tickets carry a proposed/in-flight fix but no RFC trace?** — these are the tickets the I13 gate would fire on the moment fix work resumes. They are the forward-dogfood (B8) candidate pool.
2. **What rollout-grandfathering posture is warranted?** — does the existing backlog need a bulk back-fill, or does the per-ticket gate-on-next-touch flow suffice?

No effort filter is applied — the gate is unconditional (ADR-071). This is a survey only; it changes no ticket and proposes no gate behaviour.

## Method + grounding (ADR-026)

For each of the 16 `docs/problems/known-error/*.md` tickets:

- **RFC-trace status** = exit signal of `wr-itil-check-fix-rfc-trace <ticket>`. Empty stdout → an RFC's `problems:` array claims the PID (TRACED). A `no-rfc-trace: P<NNN> …` directive → no RFC vehicle traces the PID (NO-RFC; the gate would auto-create per ADR-073).
- **Fix-proposal signal** = presence of a `## Fix Strategy` section (the strict propose-fix marker; Known Error status alone means root-cause + workaround documented with the fix *not yet* proposed, per ADR-022 corrected semantics).
- **Remediation** = which ADR-073 branch the gate takes: **auto-create** a problem-traced skeleton RFC (no vehicle exists) vs. **wire-existing-edge** (a vehicle exists but its `problems:` array does not yet claim the PID — the P314-iter-2 pattern).

RFC references found in ticket bodies were verified against the cited RFC's `problems:` array: every in-body `RFC-NNN` mention in the NO-RFC tickets is a `## Related` / `## Composes with` / historical citation, **not** a fix-vehicle claim (none of the cited RFCs list the citing PID in `problems:`). So no NO-RFC ticket is a mis-detected wire-existing-edge case; all are genuine auto-create candidates.

## Findings

### Population A — proposed/in-flight fix, NO RFC trace (the I13 gate-firing set)

These 5 Known-Error tickets have a `## Fix Strategy` section AND no RFC vehicle traces them. The I13 propose-fix gate fires `no-rfc-trace: P<NNN>` on each; remediation per ADR-073 is **auto-create a problem-traced skeleton RFC** (no existing vehicle to wire).

| PID | Title (abbrev) | Predicate | Fix signal | Remediation |
|-----|----------------|-----------|------------|-------------|
| P080 | No bidirectional update of upstream-reported problems | `no-rfc-trace: P080` | `## Fix Strategy` + `## Fix Released` | auto-create |
| P179 | Agent defers requested work into untracked phases | `no-rfc-trace: P179` | `## Fix Strategy` (ratified 2026-06-17) | auto-create |
| P305 | Post-Edit silent revert of working-tree files before commit | `no-rfc-trace: P305` | `## Fix Strategy` | auto-create |
| P357 | User direction is not substance ratification | `no-rfc-trace: P357` | `## Fix Strategy` (ratified 2026-06-17) | auto-create |
| P361 | `derive-release-vehicle` exit-3 unreleased false positive | `no-rfc-trace: P361` | `## Fix Strategy` | auto-create |

### Population B — Known Error, no fix proposed yet, NO RFC trace (gate not yet armed)

These 7 tickets are NO-RFC but have **no `## Fix Strategy` section** — the fix has not been proposed, so the I13 gate has not yet fired (correct per ADR-072: the gate fires at the propose-fix step, not at Known Error entry). They enter Population A the moment a fix is proposed.

| PID | Title (abbrev) | Predicate | Fix signal |
|-----|----------------|-----------|------------|
| P172 | Skill contract interactive-vs-AFK commit-gating anti-pattern | `no-rfc-trace: P172` | none (`## Phase 2 sweep — COMPLETE` narrative, no Fix Strategy header) |
| P174 | Topic-file rotation contract requires `first-written` metadata | `no-rfc-trace: P174` | none |
| P180 | Agent defers mitigation selection to user during active incident | `no-rfc-trace: P180` | none |
| P319 | Full `bats --recursive` suite hangs on architect-detect scope | `no-rfc-trace: P319` | none |
| P345 | Fix-titled commits do not transition ticket lifecycle | `no-rfc-trace: P345` | none |
| P363 | Inbound-reported tickets never receive fix-released verdict | `no-rfc-trace: P363` | none |
| P367 | architect-compendium hook truncates `decisions/README.md` tail | `no-rfc-trace: P367` | none |

### Population C — TRACED (RFC vehicle already claims the PID)

These 4 tickets already satisfy the I13 invariant; the gate is a no-op (empty predicate stdout).

| PID | Title (abbrev) | Tracing RFC(s) |
|-----|----------------|----------------|
| P170 | Problem tickets strain as fixes decompose | RFC-003, RFC-022 |
| P251 | RFC-first trace invariant not enforced at fix-time | RFC-005, RFC-006 |
| P314 | Rework the I13 gate placement + auto-create | RFC-005 |
| P359 | Changeset holding does not withhold shipment | RFC-025 |

## B8 forward-dogfood candidate recommendation

B8 takes a real Known-Error ticket from Population A, proposes a fix under the I13 gate (auto-create fires), ships a fix slice, and confirms the auto-created RFC is correct. Recommended candidates, in preference order:

1. **P361** (`derive-release-vehicle` exit-3 false positive) — small, self-contained `@windyroad/itil` script fix; a clean single-slice dogfood that exercises auto-create without dragging in broad scope. **Preferred.**
2. **P179** (agent defers requested work) — Fix Strategy freshly ratified 2026-06-17; behavioural/SKILL-prose change, larger surface.
3. **P305** (post-Edit silent revert) — Fix Strategy ratified to Option B (per-iter git worktree, RFC-023-adjacent); higher effort, partially user-gated.

P080 is **excluded** from the B8 candidate pool: it carries a `## Fix Released` section while sitting in `known-error/` with Status `Known Error` — a lifecycle inconsistency (a released fix should be in `verifying/`). Dogfooding auto-create on a ticket whose lifecycle state is itself questionable would confound the B8 evidence. See observation below.

## Rollout-grandfathering posture

**Recommendation: no bulk back-fill; rely on gate-on-next-touch.** Population A is only 5 tickets and Population B is 7 — both small. The I13 gate fires per-ticket at the propose-fix step, so each NO-RFC ticket auto-creates (or wires) its vehicle the moment fix work resumes on it. A bulk back-fill would auto-create 12 skeleton RFCs up front, most of which would sit empty until their ticket is actually worked — front-loading RFC-README churn for no throughput gain and risking the ADR-073 "systematically under-scoped auto-created RFC" failure mode (the B9 reassessment criterion) across a dozen tickets at once. The incremental gate-on-touch flow is the correct ADR-071/073 posture and needs no grandfathering exemption.

## Observation (out of B7 scope — surfaced for follow-up)

- **P080 lifecycle inconsistency**: P080 is in `docs/problems/known-error/` with Status `Known Error` but carries a `## Fix Released` section (line ~182). Per ADR-022 a released fix should be transitioned to `verifying/` with Status `Verification Pending`. This is unrelated to the I13 trace gate (B7 scope) and is flagged here for a future review/transition pass, not fixed in this iter.

## Cross-references

- RFC-005 B7 (this survey's task), B8 (forward-dogfood consuming this survey).
- ADR-060 I13 (the invariant), ADR-071 (unconditional), ADR-072 (propose-fix placement), ADR-073 (auto-create-not-block + the under-scoped-RFC reassessment criterion B9 wires).
- Predicate: `packages/itil/scripts/check-fix-rfc-trace.sh` (+ `wr-itil-check-fix-rfc-trace` shim), behavioural bats `packages/itil/scripts/test/check-fix-rfc-trace.bats`.
- ADR-026 (cost-source grounding — every classification cites its predicate/section evidence).
