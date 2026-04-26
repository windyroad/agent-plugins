---
"@windyroad/tdd": patch
---

P096 Phase 2 — `tdd-post-write.sh` (PostToolUse Edit|Write) silenced on no-signal emissions:

- **Silent on GREEN unchanged**: when `OLD_STATE == NEW_STATE == GREEN`, exit 0 with zero stdout. The assistant already knows the file passes; re-emitting the STATE UPDATE block adds no signal.
- **RED test-output hash dedupe**: hash the last-50-lines test output keyed by `/tmp/tdd-stdout-hash-${SESSION_ID}-${ENCODED_TEST}`; on match, emit `Test output unchanged from previous emission (hash match).` in place of the full body. Suppresses duplicate failure output across consecutive RED edits of the same impl file.
- **Drop GREEN ACTION line**: the standing "Tests are passing... You may refactor..." prose is content the assistant already has from the STATE UPDATE block. RED + BLOCKED ACTION lines retained (they carry actionable next-step signal).

Estimated session injection-byte savings: -1 to -15 KB per typical session, dominated by `tdd-post-write.sh` cumulative reduction.

7 new behavioural bats tests (`packages/tdd/hooks/test/tdd-post-write-phase2.bats`) cover silent-on-GREEN-unchanged, hash dedupe both branches, GREEN-transition no ACTION line, RED ACTION line preservation, empty-session-id fallback. All green.

Refs: P096, P095 (session-marker), ADR-038 (progressive disclosure).
