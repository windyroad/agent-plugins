# Problem 428: work-problems Step 5 dispatch heredoc-in-command-substitution is unparseable under macOS /bin/bash 3.2

**Status**: Known Error
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#345)
**Effort**: S. WSJF = (9 × 1.0) / 1 = 9.0.
**WSJF**: 18 — (9 × 2.0) / 1 (2026-08-30: Open → Known Error after confirming both Bash 3.2 incompatibilities and a portable workaround)
**JTBD**: JTBD-006
**Persona**: plugin-developer

## Description

The `/wr-itil:work-problems` Step 5 iter-dispatch command embeds a heredoc inside a command substitution that macOS's stock `/bin/bash` 3.2 cannot parse. The launch fails silently (zero-byte prompt / no iter). `bash -n` on a 5.x bash gives false confidence because the construct parses there.

**Second failure mode in the same snippet — `mapfile` (added 2026-08-25).** The Step 5 dispatch also contains:

```
mapfile -t PLUGIN_DIR_ARGS < <(wr-itil-resolve-governance-plugin-dirs)
```

`mapfile` is a bash **4+** builtin. macOS ships GNU bash **3.2.57** as `/bin/bash`, where it fails with `mapfile: command not found`, `PLUGIN_DIR_ARGS` expands empty, and the `claude -p` iter is dispatched with **no `--plugin-dir` arguments at all**.

That silently defeats P382. In a project-scoped-plugin adopter tree the iter then has no windyroad governance agents or gate hooks, and commits ungated — the exact failure P382's fix exists to prevent. Nothing surfaces: the dispatch still succeeds and the iter still runs.

Witnessed twice on 2026-08-24 in this repo: both the Step 0b and Step 0d pre-flight dispatches emitted `mapfile: command not found` and ran with zero plugin dirs. It went unnoticed until a P382 verification claim was checked against the wrapper log — and that claim was wrong as a result.

Verified fix shape: a `while IFS= read -r` accumulation loop works on bash 3.2 and yields the correct 14 arguments (7 governance plugins x 2 tokens):

```
PLUGIN_DIR_ARGS=()
while IFS= read -r _l; do [ -n "$_l" ] && PLUGIN_DIR_ARGS+=("$_l"); done \
  < <(wr-itil-resolve-governance-plugin-dirs)
```

Same skill, same step, same shipped snippet, same bash-3.2 root cause as the heredoc defect above — hence folded here rather than captured as a sibling.

## Symptoms

- On macOS default bash 3.2, the Step 5 dispatch produces no iter (silent launch failure). Works on bash 5.x, masking the defect during development.
- `mapfile: command not found` on stderr, followed by a dispatch that runs but carries no `--plugin-dir` arguments, so the iter loses its governance surface (P382 inert).

## Workaround

Run the dispatch with Bash 4 or newer. On macOS Bash 3.2, write the prompt heredoc to a temporary file and accumulate the resolver's newline-delimited arguments with `while IFS= read -r` before invoking `claude -p`.

## Impact Assessment

- **Who is affected**: macOS adopters running AFK loops on the system bash.
- **Frequency**: every dispatch on bash 3.2.
- **Severity**: Medium — silent no-op; the loop appears to run but does nothing.

## Root Cause Analysis

The shipped Step 5 command shape assumed two shell capabilities that are not available across the supported macOS runtime: it nested a heredoc inside command substitution, and it used the Bash 4-only `mapfile` builtin. The latter is an executable silent-governance failure: Bash 3.2 continues after `mapfile: command not found`, expands an empty array, and launches `claude -p` without any governance plugin arguments.

The regression test extracts the shipped command prefix, executes it with macOS `/bin/bash` 3.2.57, and inspects the actual subprocess arguments. Before the fix it failed because every `--plugin-dir` argument was absent; after the fix it passes the prompt and both resolver-emitted argument pairs, including a path containing a space.

### Investigation Tasks

- [x] Write the iter prompt to a file and pass it via `$(cat "$FILE")` rather than a heredoc in command substitution; cover the shipped command under macOS Bash 3.2.
- [x] Replace `mapfile -t PLUGIN_DIR_ARGS` with a bash-3.2-compatible `while IFS= read -r` accumulation loop, and exercise the runtime argument handoff rather than relying on `bash -n`.
- [x] Sweep the other shipped SKILL dispatch snippets for bash-4-only builtins. No other `mapfile`, `readarray`, or associative-array use was found in shipped `packages/*/skills/**/SKILL.md` files.

## Fix Strategy

Use the smallest portable command shape already supported by Bash 3.2: create one prompt temp file, read it with `cat`, collect resolver output in an indexed array with a `while read` loop, and remove both temporary files after the subprocess exits. RFC-082 / STORY-076 is the release vehicle. `.changeset/calm-bats-launch.md` carries the `@windyroad/itil` patch release; the fix remains unreleased in this iteration by user direction.

## Verification Evidence

- `LC_ALL=C bats --recursive packages/itil/skills/work-problems/test ...` plus the resolver, renderer, story-map, story reconciliation, and reverse-reference suites: 556/556 passed on macOS `/bin/bash` 3.2.57.

## Dependencies

- **Composes with**: P420 (bash-3.2 portability class — sibling, distinct script + fix; do not fold).

## Related

- Inbound issue #345.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-076 | STORY-076: My unattended backlog loop launches every iteration with its governance plugins on macOS | in-progress |
