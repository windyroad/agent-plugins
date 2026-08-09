# Problem 494: Plugin tests and project-conformance tests are the same suite, so neither can be right

**Status**: Open
**Reported**: 2026-08-09
**Priority**: 16 (High) — Impact: 4 × Likelihood: 4. Impact 4: adopters receive tests that assert on this repository's governance content, so a suite they run reports failures about artefacts they have never had; and the conformance checks that should protect this project cannot be targeted at the changes that break them. Likelihood 4: it is the current state of every published package with tests, not a latent risk.
**Origin**: corrective-feedback (user, 2026-08-09)
**Effort**: L — a taxonomy, a home for the second category, and thirteen files to move or rewrite.
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

There are two kinds of test in this repository and only one place to put them.

**A plugin test verifies the plugin behaves.** It must build its own fixtures, because the plugin will run in someone else's repository against their decisions, their tickets and their stories. It ships in the package.

**A project-conformance test verifies that *this* project uses the plugins correctly.** It must read `docs/`, because that is the thing being checked, and it must run whenever `docs/` changes. It does not ship.

Today every test is the first kind by location and some are the second by behaviour. Thirteen test files resolve their root to the actual repository and assert against its `docs/` tree, and they sit under `packages/` alongside the plugin tests. There is no `test/` or `scripts/test/` at the repository root — the second category has no home, so it was written into the first.

### What ships

`files` in each package includes `scripts/` and `skills/`, both of which carry `test/` subdirectories. Only `skills/*/eval/` is excluded. Measured by `npm pack --dry-run`:

| Package | Test files in the tarball |
|---|---|
| `@windyroad/itil` | 171 |
| `@windyroad/architect` | 37 |
| `@windyroad/retrospective` | 31 |
| `@windyroad/jtbd` | 18 |
| `@windyroad/risk-scorer` | 0 |

So the thirteen that read this repository's `docs/` are published. An adopter who runs them is told about decisions they do not have.

### The thirteen, by how they fail

**They assert on this corpus's content.** `no-type-regression-guard` greps the real `docs/problems/` to prove no ticket carries a `**Type**:` field. `oversight-mirror-corpus-lint` lints the real `docs/stories/` and `docs/story-maps/`. `check-rfc-rejected-alternatives` runs against the real `docs/rfcs/`. These are conformance checks on this project, correctly written and filed in the wrong category.

**They open this repository's artefacts by name.** Three work-problems tests read `013-structured-user-interaction…`, `018-inter-iteration-release-cadence…` and `022-problem-lifecycle-verification-pending…` by filename. `manage-problem-verification-pending` accepts either the `.proposed.md` or `.accepted.md` spelling of ADR-022 — it is asserting on this project's decision history. No adopter has any of these files.

**They read per-project configuration.** `inbound-channels-cache-shape` reads `docs/problems/.upstream-channels.json` and `docs/audits/inbound-discovery-log.md`. In an adopter repository those are their channels, or absent.

**One uses live content as a fixture.** `drain-register-queue` copies this repository's `docs/risks/README.md` in as its test input. The same defect wearing a disguise: the fixture changes whenever the corpus does.

### Why this is the parent of the CI-filter question

P493 asks whether a docs-only change can skip the build. It cannot be answered while the two categories are one suite. The correct rule falls straight out of the taxonomy: a docs change must run the conformance tests and need not run the plugin tests. That is only expressible once the two are separable, which they are not today — which is why P493's measured path table reads as a constraint to design around when it is really a description of this defect.

## Symptoms

- A test that fails because a governance document changed, in a suite meant to verify code.
- A published package containing tests that name decisions the adopter has never had.
- No way to run "just the checks that a docs change could break".
- A test whose fixture is a live file in the repository it is testing.

## Workaround

Run the whole suite. That is what happens now, and it is the cost P493 records.

## Impact Assessment

- **Who is affected**: adopters, who receive and may run tests that assert on someone else's content; and this project, which cannot target its own conformance checks.
- **Frequency**: on every publish for the shipping half; on every docs change for the targeting half.
- **Severity**: an adopter-facing correctness problem in what is published, plus a structural block on P493.
- **Analytics**: none.

## Root Cause Analysis

Suspected: tests were filed next to the code they exercise, which is right for plugin tests and wrong for conformance tests — and nothing ever distinguished the two, because there was no second location to file into. Once the only home was `packages/`, a conformance check had nowhere else to go. The publishing half follows from `files` including `scripts/` and `skills/` wholesale, with the one carve-out (`skills/*/eval/`) suggesting the question was asked once about evals and never generalised.

### Investigation Tasks

- [ ] Write the taxonomy down, somewhere that binds. A plugin test builds its own fixtures and never reads `docs/`; a conformance test reads `docs/` and does not ship. Without it recorded, the next test lands in whichever directory is nearest.
- [ ] Decide where conformance tests live. A repository-root `test/` is the obvious candidate and is outside every package's `files`, so it cannot ship by accident.
- [ ] Classify and move the thirteen. Most are conformance checks that are correct as written and simply misfiled; the work is relocation, not rewriting.
- [ ] Rewrite the ones that are genuinely plugin tests reaching for convenience — `drain-register-queue` copying the live `docs/risks/README.md` is the clear case, and it needs a fixture of its own.
- [ ] Stop shipping test files. `files` currently includes `scripts/` and `skills/` wholesale; the `!skills/*/eval/` negation shows the mechanism works, and the same treatment applied to `test/` would keep hundreds of files out of every tarball. Verify with `npm pack --dry-run` rather than by reading the manifest.
- [ ] Then answer P493. Once the categories are separable, the CI rule is: a docs change runs the conformance suite and skips the plugin suite.
- [ ] Check whether adopters can even run the shipped tests today, and whether any have. If the packages carry no runner entry point, the harm is dead weight in the tarball rather than false failures — which changes the priority but not the fix.

## Dependencies

- **Blocks**: P493 — the docs-only CI filter cannot be specified until the two categories are separable.
- **Blocked by**: (none)

## Related

- **P493** — a docs-only change runs the full build. Blocked by this: the filter it asks for is a straightforward rule once the taxonomy exists, and unspecifiable before.
- **P492** — nothing nudges when unpushed work piles up. Same session, and the same underlying pressure: making a push cheap and making it frequent both depend on the build doing only the work the change warrants.
- **ADR-052** — behavioural tests as the default. This does not contradict it; a conformance check on a real corpus is behavioural. What is wrong is where it lives and that it ships.
- **P151 / P153 / P219 / P317** — the recurring class where shipped artefacts reference repo-relative paths that only resolve in this monorepo. This is the same class one level up: shipped *tests* that only pass in this monorepo.

(captured at the maintainer's direction: *"there can be different types of tests. 1) tests that verify the plugins, which MUST use fixtures 2) tests that verify the use of the plugins within this project. They MUST use docs and MUST run on a docs change."*)
