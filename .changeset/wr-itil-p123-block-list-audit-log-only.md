---
"@windyroad/itil": patch
---

P123 — `packages/itil/hooks/lib/block-list.sh` shared helper for the inbound-report block-list mechanism. Per ADR-046's v1 implementation contract — audit-log-only — the helper exposes `is_blocked(<hash>)`, `add_block(<hash> <evidence-ticket> <provenance>)`, `remove_block(<hash> <reason>)`, and `list_blocks()`. Caller-supplied opaque hex hashes (SHA-256 width validated); helper does not compute hashes — keeping the surface GitHub-agnostic per ADR-046 §Reassessment.

Persistence: `docs/blocked-reporters.json` (per-repo JSON array, tracked in git, hashes only — no usernames). Audit log: sibling `docs/blocked-reporters.audit.jsonl` (append-only JSONL, five-field shape per ADR-046 Q2 — `{type, reporter_id_hash, evidence_ticket, timestamp, author}`).

ADR-046 Q1/Q2/Q3 already adopted (proposed defaults accepted via prior batch AskUserQuestion at iter 9 quota-halt 2026-04-28); this iter ships the audit-log-only v1 slice and transitions ADR-046 `proposed → accepted`. Q3's "agent-monitored review-cycle" direction is resolved; un-block monitor implementation deferred to a future iter beyond this v1 slice (per ADR-046 §Q3 Adopted note).

No enforcement integration in this slice. P079's inbound-discovery filter and `/wr-itil:report-upstream`'s outbound pre-check land when those features ship — out of scope for P123 per the ticket's pacing decision (line 78). The persistence layer is the foundation those iters consume; without it they would re-derive the shape from ADR-046 inline.

Files shipped:
- `packages/itil/hooks/lib/block-list.sh` — NEW shared helper, four functions.
- `packages/itil/hooks/test/block-list.bats` — NEW behavioural bats: 10 assertions covering round-trip, idempotent add, remove path, audit-log presence (block + unblock), list_blocks shape, and hex-shape validation rejections (non-hex + wrong-length).
- `docs/blocked-reporters.json` — NEW empty array per-repo persistent block list.
- `docs/decisions/046-blocked-reporters-persistence.proposed.md` → `.accepted.md` — Status flip; Q1/Q2/Q3 confirmed adopted.
- `docs/problems/123-...known-error.md` → `.verifying.md` — Status flip + Fix Released section per ADR-022 fold-fix convention.
- `docs/problems/README.md` — WSJF Rankings + Verification Queue refresh per P062.

Architect: ALIGNED-with-notes / PASS no new ADR — ADR-046 governs; helper-doesn't-hash separation locked in; JSONL audit-log shape obvious local choice.
JTBD: ALIGNED / PASS — JTBD-101 (Extend the Suite) primary persona served by foundation-only slice; JTBD-001 + JTBD-202 compose; no regression vs zero-defence today.
TDD: 10/10 green; full itil hooks suite 95/95 green (no regression).
