---
status: proposed
rfc-id: p333-iter-error-marker-staleness-filter
reported: 2026-06-03
decision-makers: [Tom Howard]
problems: [P333]
adrs: [ADR-019, ADR-032, ADR-071]
jtbd: [JTBD-006]
stories: []
---

# RFC-015: P333 — `.afk-run-state/iter-*.json` error-marker staleness filter for /wr-itil:work-problems Step 0

**Status**: proposed
**Reported**: 2026-06-03
**Problems**: P333
**ADRs**: ADR-019 (AFK orchestrator preflight — extension surface where the staleness predicate is anchored), ADR-032 (subprocess artefact contract — `.afk-run-state/iter-*.json` shape the predicate gates), ADR-071 (every fix goes through an RFC — why this RFC exists)
**JTBD**: JTBD-006 (Progress the Backlog While I'm Away — false-positive halts on stale residuals violate the AFK forward-progress outcome)

> **Problem-traced thin RFC (ADR-071 unconditional compliance).** This RFC carries the P333 fix under the RFC-first framework per ADR-071 / ADR-072 / ADR-073. It carries **no independent decisions** (per ADR-070 + the user-pinned `feedback_no_shortcuts_no_softening`): the staleness-predicate shape (mtime vs HEAD-commit-time OR 24h, whichever is more permissive) is a routine engineering judgement below the ADR-bar; the architect agent confirmed PASS on the predicate choice + the RFC-fold-in addresses the load-bearing RFC-trace requirement. Pattern modelled on RFC-007 (the P260 retro-fit). Status transitions `proposed → in-progress → verifying` alongside the P333 ticket per ADR-022 fold-fix.

## Summary

P333: `/wr-itil:work-problems` Step 0 session-continuity detection (per P109) enumerated `.afk-run-state/iter-*.json` error markers (`is_error: true` OR `api_error_status >= 400`) with no freshness predicate. Because `.afk-run-state/` is gitignored, iter state accumulates indefinitely across sessions; any stale residual from a prior session fired the AFK fail-safe (halt-with-report or interactive `AskUserQuestion`) on every subsequent invocation — even after the prior session's load-bearing work was verified-closed via an intervening commit. Witnessed 2026-05-30: an iter-4-p246.json marker from 2026-05-18 was still firing the gate despite P246 being verified-closed in commit 9eea44c on an intervening session. User direction at the time: "Proceed, but capture a problem for not being able to detect that it's stale and having to ask."

The fix adds a staleness predicate to the Step 0 enumerator: a marker is load-bearing only if its mtime is newer than HEAD's commit time (`git log -1 --format=%at HEAD`) OR within the last 24h, whichever is more permissive. Stale residuals (older than HEAD AND older than 24h) are skipped silently. Directional asymmetry: `fresh = halt, stale = silent skip`. When ≥1 stale marker is silently skipped, the iter summary emits a one-line annotation per the JTBD-006 audit-trail outcome so the skip action remains traceable + recoverable on user return.

## Driving problem trace

- **P333** (`docs/problems/verifying/333-work-problems-step-0-session-continuity-no-staleness-filter-iter-error-marker-residual.md`) — Step 0 session-continuity detection has no staleness filter on `.afk-run-state/iter-*.json` error markers; stale residuals indefinite false-positive the halt/ask gate. Status: Verification Pending (fold-fix per ADR-022 P143 lands the verifying transition in the same commit as the fix).

## Scope

Single-commit landing — SKILL.md amendment + behavioural bats + ticket transition + changeset (this RFC's capture is its own commit per ADR-014 single-grain; the iter fix commit follows):

- `packages/itil/skills/work-problems/SKILL.md` — amend Step 0 enumerator at line 67 (the `.afk-run-state/iter-*.json` error-markers row). Add the staleness predicate (mtime vs HEAD-commit-time OR 24h, more permissive of two), the directional asymmetry (fresh = halt, stale = silent skip), and the iter-summary annotation shape for the silent-skip path.
- `packages/itil/skills/work-problems/test/work-problems-step-0-iter-error-staleness.bats` — new contract-assertion bats fixture (per ADR-037) asserting the staleness-predicate contract strings the SKILL.md prose pins (P333 trace, staleness-filter naming, mtime + HEAD-commit-time primitive, 24h fallback, silent-skip directive, is_error / api_error_status field-name coexistence, iter-summary annotation shape).
- `docs/problems/verifying/333-*.md` — fold-fix ticket transition (Open → Verification Pending; renamed `docs/problems/open/` → `docs/problems/verifying/`) per ADR-022 P143.
- `.changeset/wr-itil-p333-iter-error-marker-staleness-filter.md` — `@windyroad/itil` patch changeset; on release advances the P333 status to Verifying-by-release and this RFC `proposed → verifying`.

## Decisions carried (none — predicate shape resolved architect-PASS)

This RFC carries no independent architectural decisions. The staleness-predicate shape (mtime vs HEAD-commit-time OR 24h, more permissive) was architect-resolved on the prior review (`a60465c75842d591b`): "engineering-sound for the failure mode P333 describes... the 'more permissive' disjunction sensibly handles the 'fresh repo, no commits since marker but marker is still load-bearing' edge case." Alternatives considered and rejected as below-ADR-bar: "no longer referenced by an open ticket" (requires cross-ticket reasoning at Step 0 — unbounded scope), "older than HEAD by N commits" (commit-count is a poor proxy for time on bursty repos). The chosen predicate is the simplest sufficient shape.

## Deferred (advisory, captured for follow-up)

Two advisory items from the architect review (`a60465c75842d591b`) deferred per this iter's user-pinned no-ADR-edits scope constraint:

1. **ADR-019 in-place amendment** — the ADR's P109-extension surface at lines 93–106 names the iter-*.json signal without the freshness qualifier; an amendment paragraph naming the staleness predicate keeps the ADR + SKILL.md from drifting. Advisory-not-load-bearing.
2. **Existing fixture extension** — `packages/itil/skills/work-problems/test/work-problems-preflight-session-continuity.bats` (the existing P109 preflight contract bats) should gain one complementary assertion that the SKILL.md prose for the iter-*.json row also names "staleness" / "stale" / "mtime". The new fixture `work-problems-step-0-iter-error-staleness.bats` covers the staleness-specific assertions; the cross-fixture coupling is advisory-not-load-bearing.

Both items captured in the P333 ticket's `## Related` section under DEFERRED markers. A follow-up problem ticket may pick them up at a later /wr-itil:review-problems pass.

## Tasks

- [x] SKILL.md amendment at line 67.
- [x] New behavioural bats fixture (`work-problems-step-0-iter-error-staleness.bats`).
- [x] P333 ticket fold-fix transition (Open → Verification Pending; `docs/problems/open/` → `docs/problems/verifying/`).
- [x] `@windyroad/itil` patch changeset queued.
- [ ] Release the held changeset → P333 `Verifying → Closed` (release-gated; this RFC `proposed → verifying`).

## Verification

The held `@windyroad/itil` changeset `wr-itil-p333-iter-error-marker-staleness-filter.md` is the release marker. On release, P333 transitions `Verifying-by-fold-fix → Closed-by-release-evidence` (per ADR-022) and this RFC transitions `proposed → verifying`. User-side verification: a `/wr-itil:work-problems` AFK invocation in a working tree with mixed fresh + stale iter-*.json error markers should halt-or-ask on the fresh markers and silently skip the stale ones with the iter-summary annotation. The behavioural bats fixture asserts the contract; the staleness predicate is exercised at runtime via the Step 0 enumerator's mtime check.

## Related

- **P333** — driving problem ticket (Verification Pending; fold-fix landed alongside this RFC).
- **ADR-019** — AFK orchestrator preflight; P109 extension surface where the staleness predicate is anchored (in-place amendment deferred per scope constraint).
- **ADR-032** — subprocess artefact contract; the `.afk-run-state/iter-*.json` shape the staleness predicate gates.
- **ADR-071** — every fix goes through an RFC; this RFC is the unconditional-trace compliance instance for the P333 fix.
- **RFC-007** — the P260 retro-fit RFC this RFC's structure is modelled on (thin problem-traced retro-fit, no independent decisions).
- **P109** — parent session-continuity detection extension.
- **JTBD-006** — Progress the Backlog While I'm Away; the AFK-persona job the staleness filter sharpens.
