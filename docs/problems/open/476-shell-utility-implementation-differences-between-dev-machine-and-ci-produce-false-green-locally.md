# Problem 476: Shell-utility implementation differences between this machine and CI produce false-green locally

**Status**: Open
**Reported**: 2026-07-30
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 — derived at capture from the description per Step 4a
**Origin**: internal
**Effort**: M — derived at capture per Step 4a
**JTBD**: JTBD-002
**Persona**: developer

## Description

This machine has **GNU coreutils on `PATH` despite being macOS**, and `grep` resolves to `ugrep`. CI runs stock GNU utilities on Linux. Where a shell utility's behaviour differs between those two, a test can pass locally and fail on CI — or worse, pass in both while asserting nothing. Three instances landed in a single session (2026-07-29/30), each with a different mechanism:

1. **A guard `grep` over a directory that does not exist.** `run grep -rIlE 'pattern' bin/ hooks/` from the wrong cwd matched nothing, so `[ -z "$output" ]` passed for the wrong reason. Whether it passed *at all* was implementation-dependent, because bats' `run` merges stderr into `$output` and GNU grep emits a "No such file" warning where `ugrep` is quiet. Vacuous in both, green locally, **red on CI**. Fixed by guarding the search roots (`docs/briefing` + memory carry this one).
2. **`stat -f %Lp` for a file mode.** That is the BSD spelling; under GNU `stat`, `-f` means `--file-system` and prints a multi-line volume block **with exit 0** — so `stat -f %Lp || stat -c %a` accepted the volume blob as a mode. Silent wrong answer, not an error. Fixed by shape-validating the result (`[0-7][0-7][0-7]`) instead of trusting exit status. Same class caught `chmod --reference`, which is GNU-only and whose swallowed failure normalised every migrated file to 644 while the comment claimed preservation.
3. **`grep -r` with exactly one file argument.** GNU grep omits the filename prefix in that case; this machine's grep emits it. A lint fixture asserting the output named the offending file passed locally and **failed on CI** — while the assertion immediately before it, that the lint fired at all, passed on both. Fixed with `-H` (commit `3105b60e`).

The pattern across all three: **the wrong utility variant does not fail loudly.** It exits 0 with different output, or emits a warning that only one implementation produces. So the usual reflex — "the test passed, therefore the assertion holds" — is unsound on this machine specifically.

## Symptoms

- A test suite is green locally and red on CI, with no code difference between the two runs.
- A negative assertion (`[ -z "$output" ]`, `grep -c … = 0`) passes without exercising anything.
- A fallback chain `A || B` silently accepts A's wrong-variant output because A exited 0.
- Reviewers cannot reproduce a reported hit count, because theirs is case- or implementation-sensitive where the author's was not.

## Workaround

Three habits, all used successfully during the session but none enforced:

- For any negative assertion, inject a real violation and watch it go RED before believing it.
- Shape-validate a utility's output rather than trusting its exit status when the flag spelling is platform-specific.
- Force the deterministic form of anything optional — `-H` on grep, `LC_ALL=C`, explicit field specs — rather than relying on a default that differs.

## Impact Assessment

- **Who is affected**: this repo's own development loop primarily. Adopters are affected indirectly: a shipped script written against the local variant can be wrong in their environment, which is the same root as the `chmod --reference` defect that reached the migration script.
- **Frequency**: three times in one session. Every new bats guard or shell helper is an opportunity.
- **Severity**: no adopter-visible breakage from the test instances, but each cost a red-CI round trip, and instance 2 was a genuine shipped-code defect found only because a reviewer challenged the premise. The compounding cost is trust: a suite that reddens on CI for portability reasons trains the reader to discount CI.
- **Analytics**: 3 known instances, all 2026-07-29/30. Instance 1 reddened `main`. Instance 3 reddened `main`.

## Root Cause Analysis

Preliminary — the environment asymmetry is established, the absence of a control is established, the best control shape is not.

The repo has no check that a shell utility invocation behaves identically under the two variants it will actually meet. CI is the detector today, which means red CI *is* the impact rather than a control against it — per RISK-POLICY's independence test, monitoring that fires after the harm is not a control. Nothing warns an author that `stat -f`, `chmod --reference`, a bare `grep -r` on one file, or a locale-sensitive sort will behave differently where it runs.

### Investigation Tasks

- [ ] Decide the control shape — genuinely open, and worth an ask rather than a silent pick. Candidates: (a) a lint over `packages/**/*.sh` and `**/*.bats` for known-divergent invocations (`stat -f`, `chmod --reference`, `grep -r` without `-H`, `sed -i` without a suffix, `sort` without `LC_ALL`), which is cheap and catches authoring rather than execution; (b) run the affected suites under both utility variants in CI, which catches execution but doubles that job; (c) a documented checklist, which has no cadence and by this repo's own standing principle therefore will not happen.
- [ ] Enumerate the divergent invocations already in the tree, so the size of the existing exposure is known rather than assumed. The three found so far were all found by accident.
- [ ] Check whether `packages/itil/scripts/check-locale-discipline.sh` is the natural home — it already exists and already polices one member of this class (`LC_ALL`), so this may be an extension rather than a new surface.
- [ ] Consider whether the reflex "prove RED by injecting a violation" can be made structural for negative assertions rather than left to author discipline.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: the control-shape decision above
- **Composes with**: P208 (git-push gate does not check CI status — the sibling axis: this ticket is about tests lying green, P208 is about not reading CI at all), P459 (flaky eval reddens CI on unrelated commits — same trust-erosion effect, different cause)

## Related

Captured via `/wr-itil:capture-problem`. The three instances are recorded in session memory (`feedback_bats_grep_over_missing_dir_passes_vacuously`, which now carries all three mechanisms) and two are in `docs/briefing/`. Both the JTBD and risk reviewers flagged during the P474 follow-up that the memory entries are written guidance and therefore zero control paths, and that the class has no ticket which would catch a fourth instance — this ticket is that gap, recorded rather than left to the next accident.

Title-only duplicate grep surfaced P012 (skill-testing harness), P324 (agent-prose verdicts lack a behavioural harness), P422 and P208 on broad `local|CI` keywords. None is this defect: P012 and P324 concern the absence of a harness for a surface, not the unreliability of a harness that exists; P208 concerns the push gate not reading CI status at all. P208 is the closest sibling and is named under Dependencies rather than absorbed, because its fix (read CI status before release) does not make a locally-green test trustworthy.
