---
"@windyroad/itil": minor
---

P314 Phase 2 (RFC-005 B3/B4/B5) — ship the I13 fix-time RFC-trace gate that auto-creates a missing RFC

Enforces the Problem→RFC trace at fix-proposal time (ADR-072 placement: the propose-fix step on a Known Error, conforming to ADR-022; ADR-073 behaviour: auto-create a missing RFC, everywhere — never block).

- **New load-bearing predicate** `scripts/check-fix-rfc-trace.sh` (+ ADR-049 bin shim `wr-itil-check-fix-rfc-trace`): scans `docs/rfcs/` for any RFC whose `problems:` array claims the problem's PID (PID-boundary-safe — P31/P3140 do not match P314), emits a `no-rfc-trace: P<NNN>` auto-create directive on stdout when none does, and **exits 0 unconditionally — a missing RFC is never a block** (ADR-073). The create half is orchestrated through `/wr-itil:capture-rfc` (the canonical ADR-070-compliant problem-traced-skeleton vehicle) — no create logic duplicated.
- **`manage-problem/SKILL.md`** — the Known Error fix-implementation traversal now runs the predicate as an **I13 propose-fix gate** preamble: empty → proceed; directive → auto-create via capture-rfc (no consent gate — framework-mediated per P132), then proceed. Closes the prior "no RFCs referenced → silent legacy direct-implementation" hole (the RFC-less-fix-proceeds gap ADR-072 exists to close).
- **`work-problems/SKILL.md`** — the AFK orchestrator delegates fix work through the same manage-problem traversal (gate covers the AFK surface transitively, ADR-073 "everywhere"); a second carve-out is added to the no-`capture-*`-mid-iter prohibition (the auto-create is the in-scope mandatory vehicle for the iter's own fix, not an aside-capture) + the event is structured-logged for the ADR-073 reassessment criterion.

11 behavioural bats GREEN (`scripts/test/check-fix-rfc-trace.bats`). Architect + JTBD gates PASS (no new ADR — pure RFC-005 mechanism for ratified ADR-072/073).
