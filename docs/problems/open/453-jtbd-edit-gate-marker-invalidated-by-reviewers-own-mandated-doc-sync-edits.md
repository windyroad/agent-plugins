# Problem 453: wr-jtbd edit-gate marker invalidated by the reviewer's own required doc-sync edits — PASS self-deletes, forcing an extra re-review round

**Status**: Open
**Reported**: 2026-07-15
**Priority**: 6 (Medium) — Impact: 2 (Minor — one extra marker-refresh review round of friction per occurrence; no data loss) × Likelihood: 3 (Possible — any reviewer verdict that mandates edits to the gate's own policy files is self-defeating by construction) — derived at capture per Step 4a
**Origin**: inbound-reported (#340)
**Effort**: M — design-bearing: (a) hash job/persona substance not quoted-label prose, (b) PASS pre-authorises the specific mandated edits, or (c) document the round-3 refresh as canonical; must reconcile with P419's helper-path fix shapes
**WSJF**: 3 — (6 × 1.0) / 2 (added 2026-07-26 review)
**JTBD**: JTBD-001
**Persona**: developer

## Description

The wr-jtbd edit-gate marker is invalidated by the JTBD reviewer's own required edits — reviewer-mandated `docs/jtbd/` doc-sync edits change the policy hash, self-deleting the PASS marker the same reviewer just issued, forcing an extra marker-refresh review round. Observed: a JTBD round-2 PASS required syncing two job files' quoted CTA labels; applying those edits invalidated the gate ("jtbd policy file changed since last review"), blocking the next source-file write until a round-3 re-review refreshed the marker.

Any verdict that mandates edits to the gate's own policy files is self-defeating — the compliance action invalidates the compliance proof.

## Symptoms

- Applying reviewer-mandated docs/jtbd/ edits deletes the just-issued PASS marker.
- Next gated write blocks with "jtbd policy file changed since last review" until a redundant re-review.

## Workaround

Pay the round-3 re-review to refresh the marker.

## Impact Assessment

- **Who is affected**: developer persona — anyone whose JTBD review verdict mandates doc-sync edits.
- **Frequency**: per mandated-edit verdict; observed downstream (their P096).
- **Severity**: Minor — pure friction, but structural (compliance invalidates proof).
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Choose the fix shape: substance-hash vs PASS-pre-authorised-edits vs canonical round-3 doc; joint design with P419 (same gate-hash-cannot-distinguish-authorised-edits root-cause class).
- [ ] Create reproduction test.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P419 (capture-story reverse-trace edit relocks the same gate — helper-rendered mechanical-edit trigger; this ticket is the reviewer-mandated semantic-edit trigger; cluster under a possible "gate hashes files, not substance" master at the next review)

## Related

- Upstream issue #340 (inbound; reporter's downstream ticket P096).
- Hang-off arbitration 2026-07-15 (wr-itil:hang-off-check): PROCEED_NEW — P419 is a sibling surface (helper-path trigger; its marker-refresh-after-mechanical-render fix shape does nothing for reviewer-mandated semantic edits, and this ticket's pre-authorise shape has no meaning for P419's helper path); P313 (verifying) is verdict-substance mis-classification, not hash drift; P301's shipped exemption is deliberately scoped to oversight-marker-only frontmatter diffs on docs/decisions/ and body edits fall through by design.
