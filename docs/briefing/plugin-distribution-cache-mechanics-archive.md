# Plugin Distribution — Cache and Install Mechanics (Archive)

Archived from `plugin-distribution-cache-mechanics.md` (Tier-3 rotation 2026-07-04, P099 split-by-subtopic). Multi-install / worktree-registry / TUI-autocomplete quirks — settled reference detail (closed P113/P115); pulled out of the active file to keep it under the Tier-3 budget. Restore with `git mv` back if a quirk recurs.

## What Will Surprise You

- **`claude plugin list` shows installs across ALL projects** (N entries = N project-scope installs per ADR-004, not duplicates; check `installed_plugins.json` for each `projectPath`). Two entries at *different versions* mean a stale install outlived its project path — most commonly an abandoned git worktree under `.claude/worktrees/<name>`, the smoking gun for silent-autocomplete-shadowing.
- **`installed_plugins.json` accumulates worktree-scope installs indefinitely — `git worktree remove` does NOT cascade-cleanup the registry.** Stale rows stay enabled until `claude plugin uninstall --scope project` is run *from inside the worktree path* (before removing it) or hand-edited out: `(cd <worktree> && claude plugin uninstall <plugin>@<marketplace> --scope project)` then `git worktree remove`. (closed P113; P115 tracks install-updates worktree scanning)
- **TUI autocomplete and the agent-side skill enumerator disagree under multiple install entries at different versions.** TUI uses the first-matching entry (earlier version wins → newer skills invisible in `/`); the agent enumerator unions them (all `Skill(...)`-invokable). When a skill appears "missing": check `claude plugin list` for duplicate entries and `installed_plugins.json` for stale rows BEFORE checking SKILL.md frontmatter. Upstream anthropics/claude-code#52831.
