---
"@windyroad/risk-scorer": patch
---

P309 fold-fix regression coverage — `drain-register-queue.sh` no-op on unrepresented slugs

Adds a P309-tagged behavioural bats fixture to `packages/risk-scorer/scripts/test/drain-register-queue.bats` replaying the original P309 observation: a 3-entry queue with three slugs that have no matching `docs/risks/R<NNN>-<slug>.active.md` register file. The fixture asserts the post-fix contract — 3 new register files materialised, queue truncated, `next_action=commit-staged`, and README Register table picks up all three rows.

The underlying defect was already eliminated by P171 (commit `9e91508`, 2026-05-31) which removed a vestigial `TEMPLATE.md` gate that caused silent no-op against canonical post-wipe `docs/risks/` state (no TEMPLATE.md present). P309 was reported 2026-05-26, before the P171 fix landed. Reproduction on 2026-06-03 against the live 8-entry queue returned `entries_drained=8 / new_risks_created=7 / evidence_appended=1 / next_action=commit-staged` — bug class confirmed gone.

The new bats fixture extends behavioural coverage of ADR-056 (Phase 2b drain contract) by exercising the multi-entry dedupe + truncation branch that the existing single-entry P171 test (line 309) does not assert. 18/18 GREEN.

P309 transitioned Open → Verifying per ADR-022 P143 fold-fix pattern. No source script changes.

Closes P309.
