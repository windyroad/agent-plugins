# Ask Hygiene — 2026-05-07 P170 Slice 5 RFC-002 T4 (iter 7)

Per ADR-044 / P135 Phase 5. Cross-session trail consumed by `packages/retrospective/scripts/check-ask-hygiene.sh`.

## Calls

(no AskUserQuestion calls fired this iter; user-pinned direction "just work P170" + framework-resolved decisions throughout)

## Counts

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Notes

- Iter ran under AFK `/wr-itil:work-problems` orchestration with user-pinned scope (P170 RFC-002 T4).
- Stage 1 (T4 source refactor) + Stage 2 (changeset-to-holding) followed framework-resolved 2-commit pattern (ADR-060 § Confirmation criterion 6 / P177).
- All decisions were framework-mediated: ADR-031 (per-state authoritative), ADR-014 (single-purpose), ADR-051 (load-bearing-from-the-start), ADR-052 (behavioural tests).
- External-comms gate hash-mismatch trap fired despite clean PASS verdict — applied iter-prompt-prescribed bash heredoc fallback (P163 sibling, recurrence captured at orchestrator outstanding_questions per iter 6 deferral).
