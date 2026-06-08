# Problem 301: ADR-066/068 oversight-marker frontmatter writes trip the full architect+JTBD edit-gate each drain batch

**Status**: Known Error
**Reported**: 2026-05-25
**Priority**: 6 (Medium) — Impact: 2 (Minor — re-review round-trips slow the drain but don't break it; the markers still land) × Likelihood: 3 (Likely — every `/wr-architect:review-decisions` + `/wr-jtbd:confirm-jobs-and-personas` drain batch, plus every adopter running the drains; recurs ~per-batch on a multi-batch drain)
**Effort**: M — define a gate-light path for oversight-marker-only frontmatter writes to docs/decisions/ + docs/jtbd/ (the architect/JTBD enforce-edit hooks gain an exemption for a diff that adds only `human-oversight: confirmed` + `oversight-date`)
**WSJF**: 6/2 × 2.0 = **6.0** (Known Error multiplier 2.0 — fix implemented; awaiting release)

## Description

Observed across the 2026-05-25 P283/ADR-066 ADR-oversight drain (15 batches, ~37 ADRs confirmed). Writing the `human-oversight: confirmed` + `oversight-date` marker is the **mechanical output of a decision the user just confirmed via AskUserQuestion** — it changes no decision content (orthogonal to `status:` per ADR-066). Yet each batch of marker-writes to `docs/decisions/*.proposed.md` tripped the **full architect + JTBD edit-gate**, whose markers expired/slid between batches, forcing a re-delegation round-trip:

- Batch 8 (ADR-020): blocked on architect review (`jtbd policy file changed since last review`).
- Batch 10 (ADR-004/025): blocked on architect review.
- (Plus the initial drain batches re-gated as the TTL slid.)

Each round-trip is two agent delegations (architect + JTBD) that both return PASS on a 2-line frontmatter addition — the review has nothing substantive to assess (the human already confirmed the decision; the marker is policy-authorised by ADR-066). The gate is doing real work for decision-CONTENT edits to ADRs, but the oversight-marker write is precisely the case where the content is unchanged.

## Symptoms

- Architect/JTBD enforce-edit gate fires on `docs/decisions/*.md` + `docs/jtbd/**/*.md` marker-only writes; markers (~3600s TTL, ADR-009) expire across a long drain so re-review fires several times per session.
- Each re-review is a no-op PASS (the diff adds only the two oversight-marker lines; no Decision Outcome / driver / option change).
- The architect's own verdicts this session repeatedly noted "trivial mechanical frontmatter addition … no decision-content change … PASS" — evidence the review has nothing to assess.

## Workaround

Re-delegate architect + JTBD per batch when the gate blocks (the round-trips this ticket is about). The gate correctly allows the write after the no-op review.

## Root Cause Analysis

### Investigation Tasks

- [x] Decide the gate-light mechanism: the architect/JTBD enforce-edit hooks detect a diff that adds ONLY `human-oversight: confirmed` + `oversight-date: <date>` to frontmatter (no other line changed) and allow it without requiring a fresh review marker. The write is policy-authorised by ADR-066 (the human confirmed via AskUserQuestion; the marker records that confirmation). **Implemented** via shared `lib/marker-only-diff.sh::is_marker_only_diff` predicate sourced by both `architect-enforce-edit.sh` and `jtbd-enforce-edit.sh`; gate short-circuits to exit 0 for `docs/decisions/*.md` marker-only Edit/Write.
- [x] Guard against abuse: the exemption must be exact (only those two lines added, nothing else in the diff) so it can't be used to slip decision-content changes past the gate. **Implemented** via narrow allow-list grammar in the predicate — only `human-oversight:`, `oversight-date:`, `decision-makers:`, `supersede-ticket:` lines (plus blank lines) may differ between OLD and NEW; any body change, status:/date: change, or non-marker frontmatter change fails the predicate and falls through to the normal gate. Behavioural bats coverage: marker-only-add exempts, mixed-marker-plus-body still gates, pure-body change still gates, marker-only-update exempts.
- [x] Reconcile with ADR-066/068 (the drain is the authorised writer) + ADR-009 (marker lifecycle) + P029 (existing governance-doc gate exemptions). Architect-PASS confirms alignment: the marker-discipline hook (P348/ADR-066 amendment) remains the safety net for `human-oversight: confirmed` introductions, so the exemption does NOT weaken AFK-iter subprocess discipline. P029 shape mirrored — narrower scope (marker-only diffs only, not whole-path exemption).
- [ ] Consider whether `/wr-architect:review-decisions` + `/wr-jtbd:confirm-jobs-and-personas` should set a longer-lived drain-session marker so a multi-batch drain doesn't re-gate per batch. **Deferred** — the marker-only-diff exemption above eliminates the per-batch re-gate already; a drain-session marker is now a nice-to-have for non-marker-only edits during a drain (rare). Re-rate if observed empirically.

## Fix Strategy

Shared `is_marker_only_diff OLD NEW` predicate in `packages/architect/hooks/lib/marker-only-diff.sh` (+ sibling copy in `packages/jtbd/hooks/lib/` per the existing `gate-helpers.sh` duplicate-shared pattern). The predicate uses `difflib.SequenceMatcher` to compute opcodes between OLD and NEW line sequences; every line in a non-`equal` opcode must match the narrow oversight-marker frontmatter grammar (or be blank). Fail-safe: returns 1 (NOT marker-only) on any parse error.

Both `architect-enforce-edit.sh` and `jtbd-enforce-edit.sh` source the helper and, after the existing path-exclusion case-block but BEFORE the gate-marker check, short-circuit to exit 0 when:
1. File path matches `docs/decisions/*.md`, AND
2. Tool is Edit or Write, AND
3. `is_marker_only_diff OLD NEW` returns 0.

The architect-oversight-marker-discipline.sh hook (PreToolUse, separate from the enforce-edit gate) continues to enforce per-ADR session evidence for `human-oversight: confirmed` introductions (P348 / ADR-066 amendment 2026-06-02 contract preserved).

## Dependencies

- **Blocks**: efficient operation of the ADR-066/068 oversight drains (and adopter drains).
- **Blocked by**: none.
- **Composes with**: ADR-066/ADR-068 (the drain mechanisms whose marker-writes this exempts), ADR-009 (gate marker lifecycle / TTL), P029 (governance-doc gate exemptions), the architect/JTBD enforce-edit hooks.

## Related

(captured 2026-05-25 during the P283/ADR-066 oversight drain retro)

- **ADR-066** + **ADR-068** — the oversight mechanisms; their marker-writes are the exemption target.
- **P283** / **P288** — the driving tickets.
- **ADR-009** — gate marker lifecycle (the TTL that expires mid-drain).
- `packages/architect/hooks/architect-enforce-edit.sh` + `packages/jtbd/hooks/jtbd-enforce-edit.sh` — the gate hooks to extend.
