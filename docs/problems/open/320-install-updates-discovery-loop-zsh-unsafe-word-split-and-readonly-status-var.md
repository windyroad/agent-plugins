# Problem 320: /install-updates Step 2/3 discovery loop is zsh-unsafe — `for X in $VAR` word-split (P133) + `status` is a read-only zsh var

**Status**: Open
**Reported**: 2026-05-27
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: S (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical

## Description

Running `/install-updates` this session, the Step 2/3 plugin-discovery + version-compare loop failed twice on zsh:

1. **`for key in $CURRENT_PLUGINS` iterates ONCE under zsh** (P133): `$CURRENT_PLUGINS` is a newline-joined multi-line string; zsh does NOT word-split unquoted variables by default, so the loop body ran a single time with `key` = the entire 11-plugin blob. `npm view` then got a garbage package name and every plugin reported `npm=?  cached=none`. The skill's own Step 2/3 example uses exactly this shape (`for key in $CURRENT_PLUGINS`) despite the skill carrying a P133 warning about it elsewhere — the warning and the example contradict.
2. **`status` is a read-only special variable in zsh**: a version-compare loop using `status=...` died with `(eval):12: read-only variable: status`. Had to rename to `st`.

Both forced rewrites mid-skill (to a `while IFS= read -r` loop + a non-reserved var name) before the version comparison worked.

## Symptoms

- `/install-updates` Step 3 prints all enabled plugins concatenated on one line, `npm view` empty, all plugins show `cached=none` → false "nothing to update" conclusion (the P092 hazard the skill warns about, reached via the P133 word-split).
- A loop assigning `status=` aborts with `read-only variable: status` under zsh.

## Workaround

Use `while IFS= read -r key; do ...; done < <(printf '%s\n' "$CURRENT_PLUGINS")` (or a bash array per P133) and avoid the reserved names `status` (use `st`), `path`, `pipestatus`, etc.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems.
- [ ] Fix the install-updates SKILL.md Step 2/3 example: replace `for key in $CURRENT_PLUGINS` with a `while IFS= read` loop (or bash array + `"${ARR[@]}"`) per P133; the skill already cites P133 for its Step 4 array — extend the discipline to Step 2/3.
- [ ] Audit the skill's shell snippets for zsh-reserved variable names (`status`, `path`, `argv`, `pipestatus`).

## Dependencies

- **Composes with**: P133 (bash-array portability — same class; the skill's Step 4 already applies it, Step 2/3 does not), P092 (empty `npm view` = wrong name, reached here via the word-split).

## Related

- captured via /wr-retrospective:run-retro Step 2b (Skill-contract violation), 2026-05-27. Witnessed running /install-updates after the architect@0.9.2 release.
