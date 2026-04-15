# Problem 010: Rename wr-problem to wr-itil

**Status**: Open
**Reported**: 2026-04-15
**Priority**: 3 (Low) — Impact: Minor (2) x Likelihood: Possible (3)

## Description

The `wr-problem` plugin name is too narrow — it implements an ITIL-aligned problem management process, not just "problem" tracking. The name should reflect the broader ITIL framing, opening the door for additional ITIL-aligned skills (incident, change, etc.) under the same plugin.

### Renames requested

| From | To |
|------|-----|
| `@windyroad/problem` (npm) | `@windyroad/itil` |
| `wr-problem` (plugin name) | `wr-itil` |
| `packages/problem/` | `packages/itil/` |
| `/wr-problem:update-ticket` (skill command) | `/wr-itil:manage-problem` |
| `skills/update-ticket/` | `skills/manage-problem/` |

## Symptoms

- Plugin name implies scope narrower than actual implementation
- No room to add peer ITIL skills (incident, change) without another rename later

## Workaround

None — the current name works, it's just misleading.

## Impact Assessment

- **Who is affected**: Users installing the plugin; contributors extending it
- **Frequency**: On every install and skill invocation
- **Severity**: Low — cosmetic/naming, not functional
- **Analytics**: N/A

## Root Cause Analysis

### Confirmed Root Cause

Plugin was named after its first (and currently only) skill ("problem") rather than its process framework (ITIL). This same pattern was previously applied to `cross-repo-signal` and corrected via rename to `connect`.

## Fix Strategy

**Write an ADR first.** This is a significant rename with blast radius similar to the `cross-repo-signal → connect` rename (ADR-006 updates). An ADR is needed to document:

1. Why rename (ITIL framing, room for expansion)
2. Migration path for existing users of `@windyroad/problem`
3. Dependency updates: `@windyroad/retrospective` depends on `@windyroad/problem`
4. Whether this signals intent to add further ITIL-aligned skills (incident, change, etc.)

Files to change (after ADR is approved):

- `packages/problem/` → `packages/itil/` (directory rename)
- `packages/problem/package.json` — npm name, bin
- `packages/problem/.claude-plugin/plugin.json` — plugin name
- `packages/problem/skills/update-ticket/SKILL.md` — rename to `manage-problem` + update frontmatter
- `packages/problem/hooks/` — any references to `wr-problem` agent/skill patterns
- `packages/problem/agents/` — agent descriptions
- `packages/problem/README.md`
- `.claude-plugin/marketplace.json` — entry rename
- `packages/agent-plugins/bin/install.mjs` — PLUGINS array
- `packages/retrospective/` — dependency reference
- All BATS tests that grep for `wr-problem` or `update-ticket`
- `docs/BRIEFING.md` — any references
- `docs/decisions/` — any ADR references (e.g., ADR-002)

### Investigation Tasks

- [ ] Write ADR for the rename (next available: ADR-009)
- [ ] List all references to `wr-problem` / `@windyroad/problem` / `update-ticket`
- [ ] Plan migration path (deprecate old package or just rename?)
- [ ] Implement after ADR approval

## Related

- Similar rename precedent: `cross-repo-signal → connect` (ADR-006)
- `packages/problem/` — plugin to rename
- `packages/retrospective/` — depends on `@windyroad/problem`
