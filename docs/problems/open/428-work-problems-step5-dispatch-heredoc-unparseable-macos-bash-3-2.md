# Problem 428: work-problems Step 5 dispatch heredoc-in-command-substitution is unparseable under macOS /bin/bash 3.2

**Status**: Open
**Reported**: 2026-07-06
**Priority**: 9 (Medium) — Impact: 3 × Likelihood: 3
**Origin**: inbound-reported (#345)
**Effort**: S. WSJF = (9 × 1.0) / 1 = 9.0.
**WSJF**: 9 — (9 × 1.0) / 1 (added 2026-07-26 review)
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

## Impact Assessment

- **Who is affected**: macOS adopters running AFK loops on the system bash.
- **Frequency**: every dispatch on bash 3.2.
- **Severity**: Medium — silent no-op; the loop appears to run but does nothing.

## Root Cause Analysis

### Investigation Tasks

- [ ] Write the iter prompt to a file and pass it via `$(cat "$FILE")` (or `--prompt-file`) rather than a heredoc in command substitution; add a bash-3.2 parse check to CI.
- [ ] Replace `mapfile -t PLUGIN_DIR_ARGS` with a bash-3.2-compatible `while IFS= read -r` accumulation loop, and have the CI bash-3.2 check cover bash-4-only builtins (`mapfile`, `readarray`, associative arrays) as well as parse failures — a construct that *parses* on 3.2 but does not *exist* on 3.2 fails at runtime, not at `bash -n`.
- [ ] Sweep the other shipped SKILL dispatch snippets for bash-4-only builtins.

## Dependencies

- **Composes with**: P420 (bash-3.2 portability class — sibling, distinct script + fix; do not fold).

## Related

- Inbound issue #345.
