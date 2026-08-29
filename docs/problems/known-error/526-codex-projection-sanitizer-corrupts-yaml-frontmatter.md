# Problem 526: Codex projection sanitizer corrupts YAML frontmatter while expanding internal IDs

**Status**: Known Error
**Reported**: 2026-08-29
**Priority**: 20 (Very High) — Impact: 4 × Likelihood: 5 — nine generated ITIL Codex skills have invalid frontmatter on every projection build and in the published 2.1.0 cache
**Origin**: internal
**Effort**: S — keep frontmatter outside prose sanitisation or serialize the transformed metadata safely, then add one generated-output parse check
**WSJF**: (20 × 2.0) / 1 = **40**
**JTBD**: JTBD-101
**Persona**: plugin-developer

## Description

`packages/itil/scripts/sync-codex-skills.mjs` expands internal problem and decision IDs into human-readable titles across the entire `SKILL.md`, including YAML frontmatter. The replacement text contains unescaped double quotes and colon-space sequences. When a source `description:` is already double-quoted, the generated `skills-codex/*/SKILL.md` frontmatter becomes invalid YAML.

A fresh projection build followed by YAML parsing found nine invalid generated skill files: `capture-problem`, `manage-rfc`, `manage-story-map`, `manage-story`, `scaffold-intake`, `transition-problem`, `transition-problems`, `update-upstream`, and `work-problem`. The installed `@windyroad/itil@2.1.0` Codex cache reproduces the defect.

## Symptoms

- Codex reports frontmatter parse failures such as line 2, column 268 while loading installed ITIL skills.
- Invalid frontmatter can drop skill metadata and prevent normal skill discovery or invocation.
- The source `packages/itil/skills/*/SKILL.md` frontmatter parses; corruption appears only after the Codex projection transform.
- The current Codex pack tests assert file presence and string substitutions but never parse every generated frontmatter document.

## Workaround

Use an unaffected installed skill when available, or invoke the required repository workflow manually. Do not patch the plugin cache: the generated files are replaced on installation.

## Impact Assessment

- **Who is affected**: Codex users of `@windyroad/itil`, and maintainers relying on the generated projection before publication.
- **Frequency**: every Codex projection build containing the affected internal-ID expansions.
- **Severity**: Very High — nine workflow surfaces can lose their metadata or fail discovery.
- **Analytics**: 9 of 29 generated ITIL Codex skill frontmatters failed a fresh YAML parse on 2026-08-29; the published 2.1.0 cache reproduced the `transition-problems` failure.

## Root Cause Analysis

The projection transform applies `sanitize()` to the complete markdown file. `sanitize()` replaces identifiers such as `P057` with prose shaped like `the "<title>" problem`. It does not distinguish YAML frontmatter from markdown body content and does not re-serialize YAML scalars after substitution. The inserted quote terminates an existing quoted `description:` value; later punctuation is then parsed as YAML structure.

### Investigation Tasks

- [x] Reproduce against a fresh `sync-codex-skills.mjs --build` output.
- [x] Parse every generated ITIL `SKILL.md` frontmatter and identify the affected set.
- [ ] Restrict title expansion to markdown bodies, or parse and safely serialize frontmatter before body sanitisation.
- [ ] Add a behavioural check that builds the Codex projection and parses every generated skill frontmatter.
- [ ] Confirm the packed artefact and a clean Codex installation load all 29 skills without metadata parse failures.

## Second defect in the same file — absolute-path copy filter

Found 2026-08-29 while working the sibling ticket P527, and absorbed here rather than captured separately: it is a second defect in `packages/itil/scripts/sync-codex-skills.mjs` whose fix lands in the same pass.

The projection copies each skill directory with a filter that rejects any path containing a component named `test`, `eval`, or `evals` (line 219). The filter is applied to the **absolute** path, not to the path relative to the skill directory. A checkout whose absolute path contains such a component — `~/work/test/agent-plugins`, a CI runner rooted under `.../test/`, or a temp sandbox under a `test/` subdirectory — therefore has every file rejected, so nothing is copied and the build cannot proceed.

Reproduced directly on 2026-08-29: `--build` under a path containing a `test` component aborts with `ENOENT ... skills-codex/<skill>/SKILL.md` at the read that immediately follows the copy. It fails loudly, which is the good half; the bad half is that the message names a missing output file and says nothing about the filter that suppressed the input, so the cause is not recoverable from the error. It was found because bats places `$BATS_TEST_TMPDIR` under `bats-run-<id>/test/<n>/`, and a generator-exercising test written against that directory hit exactly this.

It has gone unnoticed because the maintainer checkout has no offending path component. Only the itil generator carries this filter; the architect and risk-scorer scripts do not.

- [ ] Scope the exclusion filter to the path **relative to the skill directory** being copied, so a directory name anywhere above the package root cannot suppress the copy.
- [ ] Name the filter in the failure when a skill's copy yields no `SKILL.md`, instead of surfacing a bare `ENOENT` on the output path.

## Fix Strategy

**Kind**: improve

**Shape**: internal code + behavioural test

**Target file**: `packages/itil/scripts/sync-codex-skills.mjs`

**Observed flaw**: whole-file identifier expansion injects unsafe prose into YAML scalars.

**Edit summary**: preserve or safely serialize frontmatter while applying public-title expansion to the markdown body, then parse every generated frontmatter document in `packages/itil/scripts/test/codex-pack-install.bats`.

**Evidence**:

- Fresh build on 2026-08-29 produced nine YAML parse failures.
- Installed `@windyroad/itil@2.1.0` reproduces the failure.
- Source frontmatter remains valid, isolating the defect to projection generation.

## Dependencies

- **Blocks**: reliable Codex discovery and invocation of nine ITIL skills.
- **Blocked by**: (none)
- **Composes with**: JTBD-101 (plugin structure and packaging checks keep generated runtime surfaces installable).

## Related

- **P336** — earlier source-frontmatter YAML defect. Closed correctly; this recurrence has a different root cause in Codex projection generation.
- **P263** — plugin-validation CI gate explicitly marked the earlier YAML defect out of scope and required a separate ticket.
- **P148** — this finding was initially reported by the retrospective without the mandatory automatic ticket capture; recovered after user correction.
- Hang-off check considered P375 and returned `PROCEED_NEW`: the shared ADR-083 citation was surface-text overlap, while P375 concerns unreachable deferred work.
- Captured automatically from the 2026-08-29 retrospective correction via `/wr-itil:capture-problem`.


## Stories

| ID | Title | Status |
|----|-------|--------|
| STORY-074 | STORY-074: Use generated Codex skills after upgrading without repairs | accepted |
