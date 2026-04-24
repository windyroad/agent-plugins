# Problem 113: `/wr-itil:report-upstream` is installed and enabled but does not appear in Claude Code slash-command autocomplete

**Status**: Open
**Reported**: 2026-04-24
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Likely (3)
**Effort**: M
**WSJF**: (9 × 1.0) / 2 = **4.5**

> Identified 2026-04-24 during a session where the user wanted to invoke `/wr-itil:report-upstream` and it was not discoverable. Typed `/report` — only `/insights` / `/teleport` / `/remote-env` appeared (none of which are wr- plugin skills). Typed `/wr-itil:report` — only `/wr-itil:work-problems` appeared (fuzzy match on "r" / "po"). The direct-prefix match `/wr-itil:report-upstream` was absent from the dropdown both times. The skill file exists at the expected path and the plugin is enabled — the skill is silently missing from the enumerator that feeds autocomplete.

## Description

`/wr-itil:report-upstream` is a shipped skill in `@windyroad/itil@0.18.0`. Its SKILL.md is present at the expected location inside the plugin cache, its frontmatter is identical in shape to sibling skills that DO autocomplete, and the plugin is enabled in the project's `.claude/settings.json`. But Claude Code's slash-command autocomplete does not list it.

Observable contrast with other wr-itil skills in the same plugin version:

| Skill | File present in cache? | Autocomplete on prefix? |
|---|---|---|
| `/wr-itil:manage-problem` | Yes | Yes |
| `/wr-itil:manage-incident` | Yes | Yes |
| `/wr-itil:work-problems` | Yes | Yes (matches `/wr-itil:report` on fuzzy "r") |
| `/wr-itil:review-problems` | Yes | Yes |
| `/wr-itil:transition-problem` | Yes | Yes |
| `/wr-itil:report-upstream` | Yes (360 lines, 21KB, valid frontmatter) | **No** |

P071 (Argument-based skill subcommands are not discoverable) describes a different autocomplete gap — arguments / subcommands on visible skills. P071's Description even asserts that `/wr-itil:` picker shows `report-upstream` alongside `manage-problem`, `manage-incident`, `work-problems` — an assertion that was true at the time but is now false for `report-upstream` specifically. This ticket covers the case P071 takes for granted.

## Symptoms

- Typing `/report` in slash-command autocomplete shows `/insights`, `/teleport`, `/remote-env` — no `/wr-itil:report-upstream`.
- Typing `/wr-itil:report` shows only `/wr-itil:work-problems` (a fuzzy / substring match), not the direct-prefix match `/wr-itil:report-upstream`.
- The skill IS invocable via the `Skill` tool from the agent side (e.g. `Skill(skill: "wr-itil:report-upstream")`) — the gap is only in the user-facing autocomplete surface.
- Other wr-itil skills in the same plugin version register correctly in autocomplete.
- Observed 2026-04-24 in the Claude Code TUI; session had restarted since `@windyroad/itil@0.18.0` was installed so it's not a cache-staleness issue.

## Workaround

- **Invoke via full name**: type or paste the exact `/wr-itil:report-upstream` — the underlying skill responds normally, just doesn't surface in suggestions.
- **Invoke via SDK agent delegation**: if working through the agent, the `Skill` tool call works regardless of the autocomplete filter.
- **Check the plugin cache directly**: `ls ~/.claude/plugins/cache/windyroad/wr-itil/<version>/skills/` confirms the SKILL.md is present so the user knows they haven't hallucinated the skill name.

## Impact Assessment

- **Who is affected**: any user who tries to discover `/wr-itil:report-upstream` via slash-command autocomplete without knowing the exact name.
- **Frequency**: every time a user needs to file an upstream problem report. Primary discovery surface is broken.
- **Severity**: Moderate. The feature exists and is reachable via two workarounds, but the normal discovery path (type `/` + partial name) returns a false-negative — the skill *looks* uninstalled. New plugin users are the most likely to be stuck; long-time users recover via the workarounds.
- **Reputation cost**: silent missing skills make the plugin look half-broken even when the underlying feature is sound. This is exactly the `appears missing` failure mode a discoverability gate is supposed to catch.

## Root Cause Analysis

### Preliminary Hypothesis

Three candidate root causes, ranked by how cheap they are to confirm:

1. **SKILL.md name-field collision or prefix conflict.** Some internal enumerator may deduplicate or filter by a name-prefix heuristic. If `/wr-itil:report-upstream`'s `name:` frontmatter or file path collides with a Claude Code built-in or a hook-reserved prefix, the enumerator may skip it. Quick to confirm: compare the SKILL.md frontmatter field-by-field against a sibling that DOES appear (e.g. `/wr-itil:manage-problem`). The user's in-session `head -20` comparison showed identical shape, so this is lower-likelihood than hypothesis 2.
2. **Plugin manifest enumeration gap.** `@windyroad/itil`'s `package.json` / `plugin.json` may not list `report-upstream` in whatever skills-exported array Claude Code reads, OR the enumerator may require a specific field (e.g. `slashCommand`, `displayName`) that `report-upstream`'s manifest entry lacks. The plugin.json inspected this session contained only `name`, `version`, `description` — no skills-array visible at all, so either (a) Claude Code auto-enumerates the `skills/` subdir (in which case why is this one skipped) or (b) there's a skills manifest elsewhere (`marketplace.json`?) with per-skill entries that need explicit authoring. Most likely root cause.
3. **Autocomplete filter heuristic.** Claude Code may have an undocumented filter that hides skills matching some criterion (e.g. allowed-tools list includes a restricted tool, skill name contains a reserved substring like "upstream" treated as a network-call signal). Would be Claude-Code-side, not fixable in this repo; if so, this ticket's resolution is "report to Anthropic" and park. Low-likelihood but must be ruled out.

### Investigation Tasks

- [ ] Diff the SKILL.md frontmatter of `report-upstream` vs a working sibling (e.g. `manage-problem`) — any single-field difference. Byte-level diff of the frontmatter block.
- [ ] Locate the `@windyroad/itil` marketplace / plugin manifest that lists skills (check `marketplace.json`, `plugin.json`, any `skills` array). Confirm whether `report-upstream` is registered or absent.
- [ ] If manifest is absent, confirm the enumerator is path-based (`skills/<name>/SKILL.md`) — compare with other working plugins' manifests to establish the expected shape.
- [ ] Test via clean install: uninstall + reinstall `wr-itil` in a fresh project and observe whether `/wr-itil:report-upstream` autocompletes. Isolates per-session caching from per-install registration.
- [ ] If manifest is the root cause, patch the manifest AND add a per-plugin bats / CI check that every `skills/<NAME>/SKILL.md` has a corresponding manifest entry (prevents regression on future new skills).
- [ ] If the root cause is Claude-Code-side filter, open an upstream report via `/wr-itil:report-upstream` itself (ironically, via the workaround invocation) and park this ticket with the upstream reference.

### Fix Strategy

**Shape**: investigate-then-fix. Root cause unconfirmed; the three hypotheses above imply three very different fixes (SKILL.md edit, plugin manifest edit, or upstream report + park). Do not commit to a fix shape before the diff/manifest inspection.

**Target file (likely)**: `packages/itil/.claude-plugin/plugin.json` or a sibling marketplace manifest if one exists.

**Evidence**:
- 2026-04-24 observation: `/wr-itil:report` autocomplete returns only `/wr-itil:work-problems` (screenshot evidence in session history).
- SKILL.md presence confirmed: `~/.claude/plugins/cache/windyroad/wr-itil/0.18.0/skills/report-upstream/SKILL.md` — 360 lines, 21KB, valid YAML frontmatter.
- Plugin enabled: `.claude/settings.json` contains `"wr-itil@windyroad"` in `enabledPlugins`.
- Sibling skills from the same plugin version register correctly — rules out plugin-wide registration failure.

## Dependencies

- **Blocks**: user reports of upstream problems via the normal discovery path. Workaround exists (type the full name), so not a total block.
- **Blocked by**: investigation of the three candidate root causes above.
- **Composes with**: P071 (argument-based subcommand discoverability) — same autocomplete surface, different symptom class. P071's assumption that `report-upstream` is visible to `/wr-itil:` picker may need updating once P113 roots.

## Related

- **P071** (`docs/problems/071-argument-based-skill-subcommands-not-discoverable-in-autocomplete.open.md`) — adjacent autocomplete discoverability gap (arguments, not skills). Distinct root cause.
- **ADR-024** (`docs/decisions/024-cross-project-problem-reporting-contract.proposed.md`) — defines the `report-upstream` contract. The skill implements this ADR; autocomplete invisibility undermines ADR-024's discoverability guarantee.
- **ADR-033** (`docs/decisions/033-report-upstream-classifier-problem-first.proposed.md`) — partially supersedes ADR-024 Steps 3 and 5; same skill affected.
- **P067** (`docs/problems/067-report-upstream-classifier-is-not-problem-first.verifying.md`) — recent successful fix to `report-upstream`; the Fix Released commit proves the skill file was being updated correctly. Suggests the registration gap is a newer regression or a long-standing dormant issue only surfaced when a user tried to discover the skill by prefix.
- **JTBD-001** (`docs/jtbd/solo-developer/JTBD-001-enforce-governance.proposed.md`) — under-60-second per-edit target. The discovery workaround (type full name) doesn't exceed that; the discovery FAIL does break the "without slowing down" half.
