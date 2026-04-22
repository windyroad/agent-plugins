---
status: "proposed"
date: 2026-04-15
amended-date: 2026-04-21
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users]
reassessment-date: 2027-04-15
---

# Rename `wr-problem` Plugin to `wr-itil`

## Amendments

- **2026-04-21 (P071 amendment)** — Adds the "Skill Granularity" section below codifying "one skill per distinct user intent". Argument-subcommands (like `/wr-itil:manage-problem list`, `... work`, `... review`, `... <NNN> known-error`) are the anti-pattern P071 identifies — they do not surface in Claude Code autocomplete, forcing users to reverse-engineer SKILL.md Operations tables or hold the subcommand vocabulary in working memory. The amendment codifies separate skills as the expected shape for distinct user intents, with argument parameters permitted only for data (IDs, paths, URLs). Deprecation-window policy for existing argumented skills included. Scope of this amendment extends ADR-010's naming-pattern authority from "skill-file level" to "skill-granularity level"; no supersession (ADR-010 stays `.proposed.md`). ADR-011 (manage-incident) inherits the amendment via its ADR-010 citation; ADR-032 (invocation patterns) pre-committed to the same rule at line 29.

- **2026-04-22 (P093 amendment — Split-skill execution ownership)** — Adds a sub-rule to the deprecation-window contract: a clean-split skill hosts its own execution inline. The split skill does NOT re-invoke the deprecated host skill to run the execution block; the host's thin-router forwarder routes one-way to the split skill and returns its output verbatim. When execution code also serves in-host call sites (review auto-transitions, Parked paths, sibling-status closures), use "copy, not move": the host retains its inline block for in-skill callers, and the split skill carries a scoped inline copy for the user-initiated path. Without this rule, the P071 split shape can deadlock: if both the split skill and the host's forwarder point at each other for the execution block, a contract-literal agent recurses. P093 observed the deadlock in `/wr-itil:transition-problem ↔ /wr-itil:manage-problem <NNN> <status>`. The fix relocates the authoritative Step 7 block into `/wr-itil:transition-problem` (copy-not-move; manage-problem's in-skill block stays for Step 9b auto-transition + Parked + Step 9d closure) and strips the round-trip clause from the forwarder. This amendment generalises the rule so the same trap does not recur on future splits.

## Context and Problem Statement

The `wr-problem` plugin implements an ITIL-aligned problem management process. The current name reflects its only skill (`update-ticket`, which creates/updates problem tickets) rather than the framework it implements.

As the plugin matures, natural next steps are peer ITIL skills — incident management, change management, continual improvement — all of which share the same domain model (tickets, lifecycle, prioritisation). The current name forecloses that expansion or forces a later rename.

Tracked as P010 (`docs/problems/010-rename-wr-problem-to-wr-itil.open.md`).

## Decision Drivers

- **Framework alignment**: the plugin is ITIL-shaped, not problem-shaped. The name should say so.
- **Room for expansion**: future ITIL-aligned skills (incident, change) should fit under the same plugin without another rename.
- **Pre-1.0 surface**: the plugin suite is pre-release. Renames are cheap now; expensive after adoption grows.
- **Rename precedent**: ADR-006 (`cross-repo-signal → connect`) established the pattern — hard rename, no deprecation shim, no traces of the old name.
- **Dependency coordination**: `@windyroad/retrospective` depends on `@windyroad/problem`. Any rename must bump both together.

## Considered Options

### Option 1: Hard rename to `wr-itil` (chosen)

- npm package: `@windyroad/problem` → `@windyroad/itil`
- Plugin name: `wr-problem` → `wr-itil`
- Directory: `packages/problem/` → `packages/itil/`
- Skill command: `/wr-problem:update-ticket` → `/wr-itil:manage-problem`
- Skill directory: `skills/update-ticket/` → `skills/manage-problem/`
- Bump `@windyroad/retrospective` to depend on `@windyroad/itil`
- `npm deprecate @windyroad/problem "Renamed to @windyroad/itil"` on any already-published versions
- No shim package published

### Option 2: Keep `wr-problem`, add new plugin per ITIL skill

Leave `wr-problem` alone. Create `@windyroad/incident`, `@windyroad/change`, etc. as separate plugins when needed.

### Option 3: Rename to broader non-ITIL name (e.g. `wr-ops`, `wr-process`)

Pick a neutral label that admits ITIL skills plus other process tooling (retrospectives, post-mortems, etc.).

### Option 4: Defer — keep `wr-problem` until a second ITIL skill is actually needed

Don't rename speculatively. Pay the rename cost only when the second skill forces the issue.

## Decision Outcome

**Chosen option: Option 1 — hard rename to `wr-itil`.**

The plugin already *is* an ITIL implementation. The current name is misleading today, independent of future expansion. Renaming is a cosmetic fix that becomes materially more expensive with every release, published dependency, and external reference. Pre-1.0 is the right time.

No shim package: the `cross-repo-signal → connect` precedent is clean, and there are no known external consumers. The only internal consumer (`@windyroad/retrospective`) is bumped in the same changeset. For published versions, `npm deprecate` provides a tombstone without a shim.

## Scope

### Rename mapping

| From | To |
|------|-----|
| `@windyroad/problem` (npm) | `@windyroad/itil` |
| `wr-problem` (plugin name) | `wr-itil` |
| `packages/problem/` | `packages/itil/` |
| `/wr-problem:update-ticket` | `/wr-itil:manage-problem` |
| `packages/problem/skills/update-ticket/` | `packages/itil/skills/manage-problem/` |

### Files to update

- `packages/problem/package.json` → name, bin
- `packages/problem/.claude-plugin/plugin.json` → plugin name
- `packages/problem/skills/update-ticket/SKILL.md` → rename to `manage-problem` + update frontmatter
- `packages/problem/hooks/` — any references
- `packages/problem/agents/` — any references
- `packages/problem/README.md`
- `packages/retrospective/package.json` → dependency bump
- `packages/retrospective/skills/*` — references to the old command
- `.claude-plugin/marketplace.json` — entry rename
- `packages/agent-plugins/bin/install.mjs` — PLUGINS array
- `README.md` (root) and `docs/BRIEFING.md` — any mentions
- `docs/decisions/002-monorepo-per-plugin-packages.proposed.md` — update package inventory (lines 95-98, 124-125) to reflect `itil/` / `@windyroad/itil`
- BATS tests — grep for `wr-problem`, `@windyroad/problem`, `update-ticket`, `update_ticket`
- `docs/problems/010-...` — mark fix strategy ADR number as ADR-010

### Out of scope

- Adding incident/change/other ITIL skills — this ADR makes room for them but does not add them.
- Changing the ticket format or lifecycle — unchanged.
- Migrating historical problem docs — `docs/problems/` structure is unchanged.

## Scope Signalling

This rename signals **room for expansion**, not commitment to it. Additional ITIL skills (incident, change) are not in scope here. If a second skill is added, reuse the `/wr-itil:<verb>-<object>` naming pattern (`manage-problem`, `manage-incident`, `manage-change`).

## Skill Granularity (added by P071 amendment, 2026-04-21)

### Rule: one skill per distinct user intent

Each distinct user intent is its own named skill under `/wr-<plugin>:<verb>-<object>`. Argument-subcommands (words that act as verbs, like `list`, `work`, `review`, `close`, `known-error`) are the anti-pattern P071 identifies — they do not surface in Claude Code's `/<plugin>:` autocomplete, forcing users to reverse-engineer SKILL.md Operations tables to discover sub-operations. Users report three-memory-loads per invocation (remember the host skill, the subcommand name, and the argument type); new adopters cannot discover sub-operations without reading SKILL.md.

**Permitted argument shapes**:

- **Data parameters** — IDs, paths, URLs, numbers. Example: `/wr-itil:manage-problem 072` (where `072` is a problem ID, data not verb). These are parameters to a single user intent, not distinct user intents.
- **Forbidden shapes**: verbs or named sub-operations as free-text arguments. Example anti-pattern: `/wr-itil:manage-problem list` → should be `/wr-itil:list-problems` as its own skill.

### Split test

Apply before introducing any argument-style routing in a new or amended SKILL.md:

1. Does the argument represent a distinct user intent (the user is asking for a different *action* rather than passing *data*)? If yes, split into a separate skill.
2. Does the argument substitute for a verb (`list`, `create`, `update`, `close`, `review`, etc.)? If yes, split.
3. Is the argument a data parameter (ID, path, URL, free-form text that parameterises a single action)? If yes, keep as an argument.

### Deprecation window for existing argumented skills

Existing skills (currently `/wr-itil:manage-problem`, `/wr-itil:manage-incident`, possibly `/wr-<plugin>:update-guide` for voice-tone / style-guide / jtbd / risk-scorer) have argumented subcommands that must be split per this rule. The deprecation policy:

- **Until next major version bump of the affected plugin** — original argumented skill retains its subcommand routes as **thin-router forwarders**. Each forwarder:
  - Invokes the new named skill via the Skill tool (not via re-prompting the user).
  - Emits a one-line systemMessage deprecation notice: `"/wr-<plugin>:<old> <arg>" is deprecated; use "/wr-<plugin>:<new>" directly. This forwarder will be removed in <plugin>'s next major version.`
  - Preserves all existing behaviour; no functional regression during the window.
- **At major version bump** — forwarders removed; old argumented forms hard-fail with the redirect message as their final emission.

Data-parameter arguments (non-verb) are NOT affected by the deprecation — they stay as-is on the split skills.

### Implementation tracked under P071

Execution of the split audit and forwarder authoring tracks under P071 as the implementation ticket. The ADR authorises the rule; P071 does the plugin-by-plugin work.

## Migration Path for Users

- Any user who installed `wr-problem` via the marketplace will silently stop receiving updates after this rename.
- Release notes and the plugin README must document:
  - The rename
  - The new install command (`npx @windyroad/itil` or marketplace re-install)
  - The new skill command (`/wr-itil:manage-problem`)
- `npm deprecate @windyroad/problem "Renamed to @windyroad/itil — install @windyroad/itil instead"` after the new package publishes.

## Consequences

### Good

- Plugin name matches framework scope
- Room for peer ITIL skills without a second rename
- One-and-done rename while pre-1.0

### Neutral

- Naming pattern (`/wr-itil:manage-problem`) establishes a template for future skills — no binding commitment, just a suggestion
- ADR-002 package inventory updated in the same change

### Bad

- External users who installed `@windyroad/problem` / `wr-problem` must re-install under the new name
- Documentation and tutorials that reference the old name become stale
- Git blame churn across multiple packages

## Confirmation

- [ ] `grep -rn "wr-problem\|@windyroad/problem\|packages/problem/\|update-ticket" --exclude-dir=node_modules --exclude-dir=.git` returns only intentional references (e.g. in this ADR and P010)
- [ ] `@windyroad/retrospective` package.json updated to depend on `@windyroad/itil`
- [ ] `.claude-plugin/marketplace.json` entry renamed
- [ ] `packages/agent-plugins/bin/install.mjs` PLUGINS array updated
- [ ] ADR-002 inventory and dependency graph updated
- [ ] All BATS tests pass
- [ ] `npm deprecate @windyroad/problem` executed for any previously published versions
- [ ] Changesets: `@windyroad/itil` new package, `@windyroad/retrospective` minor bump, release notes call out migration

### Skill Granularity Confirmation (added by P071 amendment)

- [ ] Bats doc-lint across every `@windyroad/*` plugin that asserts: for each SKILL.md's Operations table, every argument is either a data-parameter (matches `<NNN>`, `<path>`, `<url>`, `<ID>` or similar placeholder) OR the row explicitly carries a `DEPRECATED (forwarder; removed in v<N>.0.0)` marker. Word-arguments that act as verbs without the forwarder marker fail the assertion. The forwarder allowlist is the deprecation-window escape hatch from the Consequences section above.
- [ ] Each SKILL.md file whose Operations table contains a forwarder row carries a `deprecated-arguments: true` frontmatter flag so tooling can distinguish actively-deprecated skills from clean-split skills.
- [ ] P071 implementation commits audit every `@windyroad/*` skill and list the new skill names in `.claude-plugin/plugin.json` manifests; bats doc-lint for each new skill follows the existing per-skill test pattern.

## Reassessment Criteria

- **Expansion confirmed**: if a second ITIL skill (incident, change, or similar) is added within 12 months, the `wr-itil` framing was right — no action.
- **No expansion**: if no peer ITIL skill is added within 12 months, the rename may have been premature. Reassess whether `wr-itil` is still the best framing or whether a narrower name (reverting to `wr-problem`) or broader name (`wr-ops`) would be clearer.
- **External adoption signals**: if users ask for non-ITIL process tooling (post-mortems, OKR tracking) that naturally would live here, reconsider the `itil` framing.

## Reassessment Criteria (P071 amendment additions)

- A second legitimate verb-as-argument use case emerges that CANNOT cleanly split into its own skill (e.g. a verb that is fundamentally a parameter choice, not a user intent). Signal: revisit the split test.
- The deprecation-window forwarder pattern proves confusing or systematically wrong. Signal: revisit the window length or the forwarder shape (thin router vs hard-fail redirect).

## Related

- P010 (`docs/problems/010-rename-wr-problem-to-wr-itil.open.md`) — the problem this ADR resolves
- ADR-002 (monorepo structure) — package inventory needs updating as part of this change
- ADR-006 (connect plugin) — rename precedent (`cross-repo-signal → connect`)
- **P071** (argument-based skill subcommands not discoverable) — drives the 2026-04-21 amendment
- **ADR-011** (manage-incident skill) — inherits this amendment via its ADR-010 citation
- **ADR-032** (governance-skill invocation patterns) — pre-commits to this rule at line 29; sibling-skill pattern of foreground + `capture-*` background is the canonical application
- **ADR-028** (External-comms gate) — amendment-in-place precedent this amendment follows
- `feedback_skill_subcommand_discoverability.md` — user memory that motivated this amendment
