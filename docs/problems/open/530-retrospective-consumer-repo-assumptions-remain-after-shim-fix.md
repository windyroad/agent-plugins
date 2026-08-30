# Problem 530: Retrospective consumer-repo assumptions remain after shim fix

**Status**: Open
**Reported**: 2026-08-28
**Priority**: 10 (High) — Impact: 2 × Likelihood: 5. Impact 2: both checks fail open, so retrospectives and context analysis continue, but adopters receive a recurring false failure and a guard whose diagnosis is always wrong. Likelihood 5: both paths deterministically affect every consumer repository without this source monorepo layout.
**Origin**: inbound-reported (#453)
**Effort**: S — two narrow fixes in one package plus focused behavioural checks
**WSJF**: 10 — (10 × 1.0) / 1
**JTBD**: (unconfirmed — elicitation queued)
**Persona**: (unconfirmed — elicitation queued)

## Description

Two `@windyroad/retrospective` surfaces retain source-monorepo assumptions after the 0.27.3 shim repair:

1. `wr-retrospective-check-readme-jtbd-currency` treats an absent or empty `packages/` inventory as a parse failure or emits no `TOTAL` line, instead of returning the valid clean result `TOTAL packages=0 drift_instances=0`.
2. `analyze-context` Step 0 checks the repo-relative source path `packages/retrospective/scripts/measure-context-budget.sh`, even though Step 1 correctly invokes the installed `wr-retrospective-measure-context-budget` shim.

Both defects fail open, so they do not stop the workflow. They do produce recurring incorrect diagnostics in every adopter repository that consumes the plugin without containing its source monorepo.

### Inbound report body (verbatim)

> ## Description
>
> Two surfaces in `wr-retrospective` still assume the plugin's own `packages/` monorepo layout, so they give the wrong answer in a repo that consumes the plugin rather than develops it. These are what is left after 0.27.3 shipped the three missing `bin/` shims reported in #362.
>
> **1. `check-readme-jtbd-currency` treats "no plugin packages here" as a parse error.** Invoked the way run-retro Step 2b invokes it, with no argument, `<packages-dir>` defaults to `./packages`, which does not exist in a consumer repo, so the script prints `check-readme-jtbd-currency: packages dir not found: packages` to stderr and exits 2. That exit is documented, and run-retro's Step 2b interpretation branch 3 catches it and fails open, so nothing breaks. The problem is that the answer is wrong rather than that it is unhandled: a repo with no plugin packages has no plugin READMEs that could have drifted, and the true verdict is `TOTAL packages=0 drift_instances=0`, which the pass could then report as clean. Instead every retro in a consumer repo logs a failure line for a check that had nothing to find.
>
> The script's own header says both things. Line 17 reads "Exit code is always 0 -- the script is advisory". The "Exit codes:" block then reads, at line 44, "0 = always (advisory only -- count is signal, not failure)", and at line 45, "2 = parse error (packages-dir missing or unreadable)". The run-retro SKILL carries the same pair, at line 177 and line 183. Whichever half is intended, the two halves disagree, and a reader of either file cannot tell which behaviour to expect.
>
> **2. The `analyze-context` Step 0 guard names a repo-relative path.** Step 0 runs `test -x packages/retrospective/scripts/measure-context-budget.sh` and instructs the reader to halt with "verify the wr-retrospective plugin is installed and up to date" when it fails. Outside the source monorepo that test always fails, so the guard's verdict is always wrong. It is inert rather than harmful only because Step 1 measures through the `wr-retrospective-measure-context-budget` shim a few lines later and succeeds. The same file states the rule Step 0 breaks: line 48 reads "ADR-049 -- never invoke the canonical script via repo-relative path; the path does not resolve in adopter trees."
>
> ## Symptoms
>
> - `wr-retrospective-check-readme-jtbd-currency` in a repo with no `packages/` directory: exit 2, stderr `check-readme-jtbd-currency: packages dir not found: packages`. Every retro logs `JTBD currency advisory failed: ...` for a check with nothing to find.
> - Pointing the same command at a directory that exists but holds no package subdirectories with READMEs: exit 0 and no output at all. The `TOTAL` line Step 2b parses is suppressed when `total_packages` is 0, so neither invocation yields the clean verdict.
> - `analyze-context` Step 0's `test -x packages/retrospective/scripts/measure-context-budget.sh` returns non-zero on every invocation outside the source monorepo, while `command -v wr-retrospective-measure-context-budget` resolves fine.
>
> ## Workaround
>
> Both already fail open in practice. Step 2b's interpretation branch 3 absorbs the exit 2, and the Step 0 guard is contradicted by Step 1 before it can do any harm. No action is needed to keep a retro running; the cost is a recurring failure line and a guard that trains its reader to ignore it.
>
> ## Affected plugin or component
>
> `@windyroad/retrospective`. Files: `scripts/check-readme-jtbd-currency.sh` (the missing-directory branch and the suppressed `TOTAL` line), and `skills/analyze-context/SKILL.md` Step 0.
>
> ## Frequency
>
> Every retro and every deep context analysis run in any repo that consumes the plugin rather than develops it.
>
> ## Versions
>
> - Local plugin: `@windyroad/retrospective@0.27.5` (highest cached; shims resolve highest-version-wins per ADR-080)
> - Upstream package: `@windyroad/retrospective@0.27.5`
> - Claude Code CLI: 2.1.245
> - Node: v24.16.0
> - OS: Darwin 25.3.0 arm64
>
> ## Evidence
>
> Observed in a consumer repo with no `packages/` directory, against 0.27.5:
>
> ```text
> $ wr-retrospective-check-readme-jtbd-currency; echo "exit=$?"
> check-readme-jtbd-currency: packages dir not found: packages
> exit=2
>
> $ wr-retrospective-check-readme-jtbd-currency "$PWD"; echo "exit=$?"
> exit=0
> ```
>
> ```text
> $ sed -n '35p' ~/.claude/plugins/cache/windyroad/wr-retrospective/0.27.5/skills/analyze-context/SKILL.md
> test -x packages/retrospective/scripts/measure-context-budget.sh
> ```
>
> The same session confirmed the three sites from #362 are working here: `wr-retrospective-check-briefing-budgets`, `wr-retrospective-check-ask-hygiene` and `wr-retrospective-check-tickets-deferred-cause` all resolve and exit 0, and run-retro names the shims for the first two at lines 359 and 301.
>
> Suggested shape for both:
>
> 1. In `check-readme-jtbd-currency.sh`, make the missing-directory branch emit `TOTAL packages=0 drift_instances=0` and exit 0, and emit the same line when the directory exists but yields no packages. An empty inventory is a real answer rather than a parse failure. Keeping exit 2 for a directory that exists but cannot be read would preserve the distinction line 45 is reaching for, and would let lines 17 and 44 and the SKILL's line 177 stop contradicting it.
> 2. In `skills/analyze-context/SKILL.md` Step 0, replace `test -x packages/retrospective/scripts/measure-context-budget.sh` with `command -v wr-retrospective-measure-context-budget`, matching the shim Step 1 already calls and the rule line 48 already states.
>
> ## Additional context
>
> Related to #362, which reported the three missing `bin/` shims and is still open. Those shims ship from 0.27.3 onward, so this report covers only what is left rather than restating that one.
>
> ## Cross-reference
>
> Reported from https://github.com/windyroad/windyroad, where this is tracked as P130 in `docs/problems/`.

## Symptoms

- A consumer repo without `packages/` gets exit 2 and a false JTBD-currency failure line.
- An existing empty inventory emits no `TOTAL` result.
- The Step 0 guard fails while the installed shim used by Step 1 resolves and succeeds.

## Workaround

Both paths already fail open. Ignore the false advisory and continue to the shim-backed measurement.

## Impact Assessment

- **Who is affected**: plugin adopters running retrospectives or deep context analysis outside this source monorepo.
- **Frequency**: deterministic on every affected invocation.
- **Severity**: inaccurate diagnostics and eroded trust, without workflow interruption or data loss.
- **Analytics**: reproduced against `@windyroad/retrospective@0.27.5` in the reporting consumer repository.

## Root Cause Analysis

The two surfaces bypass the installed-plugin boundary in different ways: the currency check treats a source-only directory as required input, while the Step 0 guard tests a source-only executable path instead of the published shim. The canonical installed invocation already exists and is used correctly in Step 1.

### Investigation Tasks

- [ ] Make an absent or empty package inventory return `TOTAL packages=0 drift_instances=0` and exit 0; preserve a real unreadable-directory error.
- [ ] Replace the Step 0 repo-relative executable guard with a shim lookup.
- [ ] Add focused checks for absent inventory, empty inventory, unreadable inventory, and consumer-repo shim discovery.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: JTBD/persona anchoring decision queued for human input

## Related

- Upstream report: [windyroad/agent-plugins#453](https://github.com/windyroad/agent-plugins/issues/453)
- **P151**: fixed actual command dispatch through published shims; #453 is a remaining preflight guard found after that fix.
- **P152**: established the currency detector; absent-inventory handling is a new consumer-input defect, not its deferred enforcement phase.
- **P153**: fixed plugin-attribution traversal; these are sibling monorepo assumptions with different root causes.
- **P158**: closed after wiring the detector; #453 concerns the wired surface's behaviour.
- **P182**: closed measurement-enumeration defect; neither finding shares its glob root cause.
- Hang-off verdict: **PROCEED_NEW**. No candidate master ticket or unfinished phase absorbs both post-fix consumer-repo defects.
