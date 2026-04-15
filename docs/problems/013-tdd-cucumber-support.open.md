# Problem 013: TDD plugin lacks Cucumber/BDD support

**Status**: Open
**Reported**: 2026-04-16
**Priority**: 12 (High) — Impact: Significant (4) x Likelihood: Possible (3)

## Description

The TDD plugin (`packages/tdd`) has two gaps that degrade the workflow for users writing Cucumber/BDD tests:

1. **`.feature` files are not recognized as tests.** `tdd_classify_file()` in `packages/tdd/hooks/lib/tdd-gate.sh` only matches `*.test.*` and `*.spec.*`. Writing a Cucumber `.feature` file does not transition the state from IDLE to RED, so BDD users must create a throwaway `.test.js` wrapper just to enter the TDD cycle.
2. **Vague Gherkin outcome steps are not flagged.** A step like `Then the address detail will have related links` has no assertion on *what* links exist. The TDD enforcement gate accepts this as a passing test even though it asserts nothing meaningful. There is currently no quality review for test content — only for test presence.

Addressr reported (1) externally as their P005 after hitting the friction in real project work.

## Symptoms

- Cucumber users on projects governed by `@windyroad/tdd` must create thin `*.test.js` wrappers to satisfy the hook (extra boilerplate, confusing dual-test surface).
- `.feature` files written alone leave the test file's state at IDLE, blocking implementation edits even though a test exists.
- Gherkin scenarios with vague `Then` steps (no concrete expected value or structure) pass the TDD gate and give false confidence.
- Example vague step from addressr: `Then the address detail will have related links` — does not specify which links, how many, or what they point to.

## Workaround

1. For file recognition: create a companion `<name>.test.js` file importing the step definitions or a function under test. This satisfies the classifier.
2. For vague Gherkin: no automated workaround. Reviewers must manually check scenarios for concrete assertions.

## Impact Assessment

- **Who is affected**:
  - Solo-developer persona using Cucumber/BDD (JTBD-002 — ship with confidence)
  - Tech-lead persona in consulting contexts where BDD is common
  - Plugin-developer persona if the classifier becomes an extension point (JTBD-101)
- **Frequency**: Every file edit on a BDD-first project. Vague-step issue: every Gherkin scenario authored by the agent without explicit assertion.
- **Severity**: High — the fake-wrapper workaround violates the "speed without sacrificing quality" constraint and BDD is a mainstream test style.
- **Analytics**: N/A. External report: `addressr/docs/problems/005-tdd-hook-cucumber-friction.open.md`.

## Root Cause Analysis

### Gap 1 — classifier

`tdd_classify_file()` (packages/tdd/hooks/lib/tdd-gate.sh:15-23) matches only `.test.*` and `.spec.*`. `.feature` falls through to impl classification. The pair-detection logic (lines 129-181) also assumes a `Name.test.ext`/`Name.spec.ext` convention that doesn't map to Cucumber's `features/` ↔ `features/step_definitions/` layout.

### Gap 2 — quality review

No mechanism exists for reviewing test *content* quality. The gate enforces presence and RED→GREEN transitions but not assertion strength. Cucumber's natural-language surface makes vague steps especially easy to miss.

### Investigation Tasks

- [ ] Decide scope of `.feature` recognition: classifier only, or also a new pair-detection mode for features ↔ step definitions
- [ ] Prototype classifier extension (small, reversible change)
- [ ] Design a vague-outcome heuristic: e.g. flag `Then` steps lacking quoted literals, numbers, or explicit structural predicates
- [ ] Decide whether vague-step detection belongs in the gate (blocking) or an agent review (advisory)
- [ ] Create reproduction tests under `packages/tdd/test/`
- [ ] Draft ADR for gap 2 if a new enforcement surface is introduced (architect flagged this)

## Related

- External report: `~/Projects/addressr/docs/problems/005-tdd-hook-cucumber-friction.open.md`
- Addressr briefing note: `~/Projects/addressr/docs/BRIEFING.md` (line 35)
- `packages/tdd/hooks/lib/tdd-gate.sh` — `tdd_classify_file()` and pair detection
- ADR 005 (proposed): `docs/decisions/005-plugin-testing-strategy.proposed.md` — names `tdd_classify_file` as a unit-tested function
- ADR 002 (proposed): `docs/decisions/002-monorepo-per-plugin-packages.proposed.md` — scopes `@windyroad/tdd` as a standalone plugin
- JTBD-002: `docs/jtbd/solo-developer/JTBD-002-ship-with-confidence.proposed.md`
- JTBD-001: Enforce Governance Without Slowing Down
