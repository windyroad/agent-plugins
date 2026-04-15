# Problem 011: Grep-based BATS tests produce false positives on legitimate refactors

**Status**: Open
**Reported**: 2026-04-15
**Priority**: 4 (Low) — Impact: Minor (2) x Likelihood: Likely (4)

## Description

Several BATS tests assert hook behaviour by grepping the hook source for patterns rather than executing the hook with mock input and checking output/exit codes. These tests pass when source matches the pattern they expect — but they false-positive (or false-negative) when the source legitimately changes for unrelated reasons.

This has now hit twice:

1. **First hit**: `jtbd-enforce-scope.bats` originally asserted UI extension scoping was present; ADR-007 broadened scope and the test had to be inverted. Plan called out "upgrade from grep-based to functional tests" but only the new tests were added — old grep assertions kept.
2. **Second hit (this session)**: `jtbd-enforce-scope.bats:70` asserted no `*) exit 0 ;;` pattern (per ADR-007's removal of UI-only scoping). P004 added a project-root check that legitimately uses that exact pattern. Test failed in CI on the rename commit despite hook behaviour being correct. Fixed by tightening the regex to target UI-extension filtering specifically (commit `433fdb9`).

## Symptoms

- BATS test fails after an unrelated refactor that touches the hook source
- Failure message looks like a real regression but the hook behaves correctly
- Functional tests (mock JSON → hook → exit code) all pass alongside the failing grep test
- Cost: a CI red, a re-think, a fix commit, another release

## Workaround

When a grep-based test fires false-positive, tighten the regex to target the *intent* of the original assertion (e.g., UI extensions specifically) rather than the *implementation pattern* (e.g., any `*)` case statement).

## Impact Assessment

- **Who is affected**: plugin-developer persona — anyone refactoring hooks
- **Frequency**: every legitimate hook source change risks tripping a grep assertion
- **Severity**: Low — caught by CI, fixable in minutes, but burns cache + commit cycles
- **Analytics**: 2 incidents in ~3 weeks across the same test file

## Root Cause Analysis

### Confirmed Root Cause

Grep-based assertions over-specify the implementation. They assert on *how* the hook is written, not *what* it does. Any change to hook structure that preserves behaviour can trip them.

The functional test pattern (mock JSON → execute hook → check output) is already proven in this same file (lines 76+) but co-exists with the grep tests rather than replacing them.

### Audit needed

Other plugins likely have similar grep tests. Worth a sweep:

```bash
grep -rn "grep -q.*HOOK" packages/*/hooks/test/*.bats
```

## Fix Strategy

1. **Audit**: enumerate all grep-based assertions across `packages/*/hooks/test/*.bats`
2. **Categorise**: for each, decide whether the assertion's intent is verifiable functionally (yes for almost all behavioural assertions; maybe not for "this hook is registered" structural checks)
3. **Replace**: convert behavioural greps to functional tests; keep structural checks but tighten their patterns
4. **Document**: add a note in the testing strategy ADR (ADR-005) that behavioural assertions must be functional, not source-grep

### Investigation Tasks

- [x] Identify root cause (this session)
- [ ] Audit `packages/*/hooks/test/*.bats` for grep-based behavioural assertions
- [ ] Convert behavioural greps to functional tests
- [ ] Update ADR-005 with the rule

## Related

- ADR-005 (plugin testing strategy) — should encode the rule
- Commit `433fdb9` — most recent false-positive fix
- `packages/jtbd/hooks/test/jtbd-enforce-scope.bats` — repeat offender
