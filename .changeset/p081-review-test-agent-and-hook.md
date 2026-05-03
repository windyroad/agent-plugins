---
"@windyroad/tdd": minor
---

P081 Layer A — behavioural-tests-default for skill testing.

Adds the `review-test` agent at `packages/tdd/agents/review-test.md` that
classifies test files (bats / vitest / cucumber / pytest / etc.) as
structural (asserts source-prose content) or behavioural (exercises the
target). Adds a PostToolUse Edit|Write advisory hook
`tdd-review-test.sh` that emits an `additionalContext` directive after
each test-file write, telling the assistant to invoke the agent.

Two escape hatches per ADR-052:

- `WR_TDD_REVIEW_TEST=skip` env var (ADR-044 category 3 strategic
  one-time override) — silences advisories for the session.
- In-file comment `tdd-review: structural-permitted (justification:
  <ticket>)` (ADR-044 category 2 deviation approval) — silences
  advisories for that specific file when the behavioural alternative
  is not yet expressible under the current harness primitives.

Companion ADRs in `docs/decisions/`:

- ADR-052 (proposed) — behavioural-tests-default for skill testing,
  supersedes ADR-037.
- ADR-037 — superseded; banner block points readers to ADR-052.
- ADR-005 — Permitted-Exception scope narrowed to exclude
  prose-document content greps; hook-script safety-construct
  exception preserved.

Phase 1 advisory only. Promotion to PreToolUse blocking is named in
ADR-052 reassessment criteria.
