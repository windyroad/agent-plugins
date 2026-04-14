---
"@windyroad/tdd": minor
---

Per-test-file TDD state tracking, scoped test runs, and deadlock fix

- State is now tracked per test file instead of globally — a failing Countdown test no longer blocks editing Hero
- PostToolUse runs only the relevant test file after writes, not the full suite
- Only timeout (exit 124) transitions to BLOCKED; all other non-zero exits become RED, fixing the deadlock where importing a non-existent component would block creating it
- Enforcement hook checks the associated test's state for each impl file independently
- Inject hook displays per-file states with test file identification
- New functions: tdd_find_test_for_impl, tdd_read_state_for_impl, tdd_get_all_states, tdd_suggest_test_path, tdd_run_test_file
