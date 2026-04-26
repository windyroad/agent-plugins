---
"@windyroad/itil": patch
---

P127: scaffold-intake idempotency bats fixture — snapshot dir now lives outside `$TEST_DIR` to fix Linux CI failure

The `fixture: full re-application is idempotent (no diff)` test in `packages/itil/skills/scaffold-intake/test/scaffold-intake-fixture.bats` was failing on Linux CI but passing on macOS local — a test-harness portability bug, not a production-skill bug. Root cause: `cp -R . "$TEST_DIR/.snapshot-1"` ran with `$PWD == $TEST_DIR`, so the destination was a child of the source. GNU `cp` (Linux / Ubuntu CI) refuses this case with `cp: cannot copy a directory, '.', into itself, ...`; BSD `cp` on macOS APFS silently allows it. The non-zero exit aborted the test on Linux only.

Fix: take the snapshot into a sibling `mktemp -d` directory outside `$TEST_DIR`, eliminating the source-into-itself recursion. No production SKILL.md or template changes — `scaffold_all` was already deterministic. The idempotency assertion shape is unchanged: still `cp` first state → re-run `scaffold_all` → `diff -ru` against snapshot.

Verification: 29/29 scaffold-intake bats pass on both Linux (`bats/bats:latest` Alpine container) and macOS local. Restores CI green-on-main for `@windyroad/itil` (CI was red on every commit since `8653541`).

Closes P127 → Verification Pending pending CI confirmation.
