# Problem 521: Governance tools exit 0 over output they never validated

**Status**: Open
**Reported**: 2026-08-25
**Priority**: 12 (High) — Impact: 4 (Significant — a governance index that silently cannot be read is worse than one that is obviously broken; every downstream check reports clean) × Likelihood: 3 (Possible — fires whenever a generator or reconciler emits or blesses malformed output)
**Origin**: inbound-reported (adopter-repo P224)
**Effort**: M
**WSJF**: 6 — (12 × 1.0) / 2
**JTBD**: JTBD-001
**Persona**: developer

## Description

A governance tool that exits 0 over output it never validated converts a loud failure into a silent one, and silence is indistinguishable from success to every caller.

Two witnessed instances:

1. `wr-architect-generate-decisions-compendium` exited 0, reported the correct ADR count (153), and wrote **invalid UTF-8** at byte 26275 of `docs/decisions/README.md`. `grep` treats invalid UTF-8 as binary and returns *nothing* rather than erroring, so every check over the corrupted file reported no matches — which reads as clean. The reporting agent briefly took that silence as evidence the file was fine. Reported from the an adopter repo as their P224 (2026-08-19..21). **This instance is already fixed here** by commit `fe1a4ddc` (2026-08-22), which added `validate_compendium()` to iconv-validate the generated output and fail closed before the `mv`; shipped in `@windyroad/architect@0.21.4`. Cite it as the precedent fix shape — do not re-fix it.

2. `wr-itil-reconcile-readme` exits 0 over a problems table whose rows are out of WSJF rank order. Reported in the same message and **not verified here** — an investigation task, not an assertion.

The class matters more than either instance. This orchestrator ran `wr-itil-reconcile-readme docs/problems` at Step 0 on 2026-08-24, got exit 0, and selected work off the resulting rankings. The exit code currently carries more trust than it has earned.

## Symptoms

- A generator writes malformed output and reports success with a correct-looking summary line.
- Downstream `grep` / `awk` checks over the malformed file return no matches, which every caller reads as "clean".
- A reconciler blesses a file whose ordering or content invariant it never actually asserted.

## Workaround

Validate the artefact independently after any generator run — `iconv -f UTF-8 -t UTF-8 < file > /dev/null` for encoding, and re-read the invariant the tool claims to enforce rather than trusting its exit code.

## Impact Assessment

- **Who is affected**: maintainers and agents relying on governance tooling exit codes; adopters running the same generators.
- **Frequency**: per generator/reconciler invocation over content that violates an unasserted invariant.
- **Severity**: silent corruption of a governance index; downstream checks report clean; discovery is accidental.

## Root Cause Analysis

The pattern is a tool that validates its *inputs* (or nothing) and never its *own output*, then returns 0. `fe1a4ddc` closed it for one generator by validating the generated artefact and failing closed before publishing it. Nothing generalises that to the other governance tools.

### Investigation Tasks

- [ ] Enumerate the governance tools that write or bless an artefact — generators, reconcilers, compendium/index writers — and record for each whether it validates its own output before exiting 0
- [ ] Verify or refute instance 2: does `wr-itil-reconcile-readme` exit 0 over a WSJF-misordered table? Construct a misordered fixture and observe
- [ ] Decide whether the fix is per-tool (each validates its own output, the `fe1a4ddc` shape) or a shared post-write validator the tools call
- [ ] Behavioural coverage per ADR-052 — a fixture whose invariant is violated must produce a non-zero exit

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P421 (the consumer half of the same encoding class)

## Related

- **P421** (open) — reference-section awk helpers destructively truncate files containing invalid UTF-8. That is the CONSUMER half: tools that break when they *encounter* malformed input. This ticket is the PRODUCER/VALIDATION half: tools that *emit or bless* malformed output and report success. Distinct failure modes on the same class; cross-reference, not absorption.
- **P334** (closed), **P328** (closed) — earlier instances of the awk/locale encoding lineage.
- **fe1a4ddc** — the precedent fix: validate generated output, fail closed before replacing the file.
- adopter-repo P224 — the inbound report carrying instance 1.
