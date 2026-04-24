# Problem 113: `/wr-itil:report-upstream` is installed and enabled but does not appear in Claude Code slash-command autocomplete

**Status**: Verification Pending
**Reported**: 2026-04-24
**Priority**: 9 (Med) — Impact: Moderate (3) x Likelihood: Likely (3)
**Effort**: S (single-line frontmatter edit)
**WSJF**: 0 (excluded from ranking per ADR-022 — Verification Pending)

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

### Confirmed root cause (2026-04-24 investigation)

`packages/itil/skills/report-upstream/SKILL.md` declares `allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion` — missing two tools the skill body actually invokes:

- **Missing `Agent`** — line 330 invokes `wr-risk-scorer:pipeline` subagent (requires the `Agent` tool).
- **Missing `Skill`** — line 330 falls back to `/wr-risk-scorer:assess-release` skill per ADR-015 (requires the `Skill` tool).

Cross-skill comparison of `allowed-tools` across all 13 itil skills establishes the pattern: every AskUserQuestion-declaring itil skill that does multi-skill orchestration also declares `Skill`. `report-upstream` is the **only** AskUserQuestion-declaring itil skill that omits `Skill` — and the only one failing autocomplete. This is an improbable coincidence.

**Candidate mechanism (to confirm post-release)**: Claude Code's TUI slash-command autocomplete appears to validate declared-vs-used tools in skill frontmatter and silently drop skills whose bodies invoke tools not declared in `allowed-tools`, while still registering the skill for agent-side `Skill()` invocation (which bypasses autocomplete). The server-side enumerator (which populates the agent's available-skills list) is more lenient; the TUI client enumerator is stricter.

This explains every observation in the ticket:
- Agent-side `Skill(skill: "wr-itil:report-upstream")` works → server enumerator registered the skill
- TUI autocomplete omits it → client enumerator filtered it out on declared-vs-used mismatch
- Sibling skills work → they declare all tools they invoke
- No plugin.json skills array, no marketplace manifest gap → path-based enumeration works for siblings, so the gap is not in enumeration, it is in post-enumeration validation

### Hypotheses ruled out

- **Hypothesis 1** (frontmatter name collision / prefix conflict) — ruled out. `od -c` byte dump confirms identical frontmatter shape to `manage-problem`; both parse as valid YAML with the same three keys (`name`, `description`, `allowed-tools`); no invisible / control / non-ASCII characters in frontmatter.
- **Hypothesis 2** (plugin manifest enumeration gap) — ruled out. `packages/itil/.claude-plugin/plugin.json` has no `skills` array for ANY skill, yet 12/13 siblings enumerate correctly. Path-based enumeration (`skills/<name>/SKILL.md`) is what Claude Code uses.
- **Hypothesis 3** (Claude-Code-side filter) — **partially confirmed**. A filter exists (allowed-tools completeness), but it is not opaque or "undocumented" in the sense originally feared — it is a reasonable sanity check. The fix is in this repo, not upstream. Parking-with-upstream-report is NOT required.

### Investigation Tasks

- [x] Diff the SKILL.md frontmatter of `report-upstream` vs a working sibling (`manage-problem`) — byte-level diff done; identical shape; ruled out Hypothesis 1.
- [x] Locate the `@windyroad/itil` plugin manifest — confirmed no skills array exists for any skill; path-based enumeration; ruled out Hypothesis 2.
- [x] Tabulate `allowed-tools` across all 13 itil skills — identified `report-upstream` as the sole outlier among AskUserQuestion-declaring skills.
- [x] Cross-reference with skill body usage — confirmed line 330 invokes both `Agent` (subagent) and `Skill` (fallback) without declaration.
- [ ] Verify the fix resolves autocomplete (post-release, user verification).
- [ ] (Follow-up, advisory) consider a lint rule + ADR enforcing "every tool invoked in SKILL.md body must appear in `allowed-tools`" to prevent recurrence across `@windyroad/*` plugins.

### Reproduction test

Not added. A structural bats check that greps for `Skill, Agent` in `report-upstream/SKILL.md` would be a structural test per P081 ("wasteful and not real tests"). The behavioural test — "when user types `/wr-itil:report` in the TUI, autocomplete shows `report-upstream`" — is not reachable from the test harness; verification is via user observation in the next session after `@windyroad/itil` ships.

### Fix Strategy

**Shape**: one-line frontmatter edit. **Target file**: `packages/itil/skills/report-upstream/SKILL.md` line 4.

**Before**:
```
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
```

**After**:
```
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill, Agent
```

**Evidence supporting this specific fix**:
- 2026-04-24 observation: `/wr-itil:report` autocomplete returns only `/wr-itil:work-problems` (screenshot evidence in session history).
- SKILL.md presence confirmed: `~/.claude/plugins/cache/windyroad/wr-itil/0.18.0/skills/report-upstream/SKILL.md` — 360 lines, 21KB, valid YAML frontmatter.
- Plugin enabled: `.claude/settings.json` contains `"wr-itil@windyroad"` in `enabledPlugins`.
- Sibling skills from the same plugin version register correctly — rules out plugin-wide registration failure.
- allowed-tools cross-skill tabulation: every AskUserQuestion-declaring itil skill declares `Skill`; `report-upstream` is the sole exception.
- Architect review (2026-04-24): PASS — fix aligns with ADR-015 fallback pattern; no ADR conflict; advisory follow-up ADR optional if fix works.
- JTBD review (2026-04-24): PASS — serves JTBD-001 (enforce governance without slowing down) and JTBD-301 (report without pre-classifying); discovery-friction removal, no behaviour change.

## Fix Released

Fix landed 2026-04-24 in `packages/itil/skills/report-upstream/SKILL.md` line 4: added `Skill, Agent` to `allowed-tools`. Ships in the next `@windyroad/itil` patch release (changeset `.changeset/p113-report-upstream-allowed-tools.md`). Verification path: after `/install-updates` in a new session, type `/wr-itil:report` in the TUI and confirm `/wr-itil:report-upstream` appears in autocomplete. If autocomplete still omits it, the allowed-tools hypothesis is wrong and the ticket reopens for upstream escalation.

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
