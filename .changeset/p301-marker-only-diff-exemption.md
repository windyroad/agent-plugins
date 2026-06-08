---
"@windyroad/architect": patch
"@windyroad/jtbd": patch
---

P301: oversight-marker-only ADR diffs are now exempt from the architect
and JTBD enforce-edit gates.

Multi-batch `/wr-architect:review-decisions` (ADR-066) and
`/wr-jtbd:confirm-jobs-and-personas` (ADR-068) drains previously paid
2-3 no-op-PASS architect + JTBD review round-trips per batch because
each `human-oversight: confirmed` / `oversight-date` frontmatter write
to a `docs/decisions/*.md` ADR re-tripped the full enforce-edit gate.
The marker write is the mechanical output of a decision the user
already substance-confirmed via `AskUserQuestion`; the review had
nothing substantive to assess.

Both plugins now ship a shared `is_marker_only_diff OLD NEW` predicate
at `hooks/lib/marker-only-diff.sh` (sibling-copied per the existing
`gate-helpers.sh` duplicate-shared pattern, ADR-017). The predicate
returns 0 when every added/removed non-empty line in the Edit/Write
diff matches the narrow oversight-marker frontmatter grammar:
`human-oversight:`, `oversight-date:`, `decision-makers:`, or
`supersede-ticket:`. When marker-only and the file is under
`docs/decisions/`, the enforce-edit hook short-circuits to exit 0
silently.

**Safety contracts preserved.** The
`architect-oversight-marker-discipline.sh` and
`jtbd-oversight-marker-discipline.sh` hooks remain active and enforce
the per-ADR session evidence marker for `human-oversight: confirmed`
introductions (P348 / ADR-066 amendment 2026-06-02). AFK iter
subprocesses still cannot silently ship `confirmed` markers without
the user's substance-confirm event. The exemption is exact — any
non-marker line (body content, `status:` / `date:` changes, frontmatter
keys outside the four-key grammar) fails the predicate and the diff
falls through to the normal gate. Fail-safe: the predicate returns 1
(NOT marker-only) on any parse error, so the gate proceeds with its
normal review requirement.

User-visible impact: fewer no-op architect + JTBD review delegations
during `/wr-architect:review-decisions` and
`/wr-jtbd:confirm-jobs-and-personas` drain batches; the drain finishes
faster without the round-trip context cost.

12 new behavioural bats (7 architect + 5 jtbd) cover the four critical
shapes: marker-only ADD exempts, marker-only UPDATE exempts,
mixed-marker+body still gates, pure body change still gates. Full
hook suite green: 198/198 architect + JTBD (no regression).

Architect PASS — no new ADR; the exemption mirrors the existing P029
governance-doc gate exemption shape at narrower scope, and the
ADR-009 / ADR-066 / ADR-068 marker contracts are unchanged. JTBD
PASS — serves JTBD-006 (Progress the Backlog While I'm Away) and
upholds JTBD-001 (Enforce Governance Without Slowing Down) by removing
no-op review round-trips on marker-only edits.

Closes P301.
