# /install-updates — Reference

Deep context for the `/install-updates` skill. Load on demand when the runtime steps in `SKILL.md` do not give you enough to act. Progressive-disclosure companion per ADR-038 pattern applied to skill bodies (reference implementation of the pattern P097 is expected to generalise).

## Contract (per ADR-030)

- **Repo-local skill.** Not published. Lives in `.claude/skills/install-updates/` and is versioned by repo git history.
- **First action is a consent gate.** `AskUserQuestion` lists every sibling project this skill detected, with a dry-run option. No install runs before user confirmation.
- **Installs use `claude plugin install <pkg>@windyroad --scope project`.** Never global scope (ADR-004).
- **Does NOT restart Claude Code.** ADR-013 Rule 6 governs non-interactive behaviour; P045's 2026-04-20 direction decision explicitly rejected auto-restart. User restarts on their own cadence.
- **Does NOT migrate legacy JTBD layouts.** That's `/wr-jtbd:update-guide`'s job. Projects on the legacy `docs/JOBS_TO_BE_DONE.md`-only layout are flagged in Step 8 with a migration reminder (ADR-008 Option 3).

## Marketplace resolution semantics (Step 1)

Per BRIEFING: "The marketplace resolves from the remote GitHub repo, not the local working tree. You cannot install a new plugin until changes are pushed and `claude plugin marketplace update windyroad` pulls the latest."

Workflow implication: run the full release pipeline (`push:watch` + `release:watch`) BEFORE invoking `/install-updates`. Installing from an unpushed working tree silently resolves against the last-published version.

## Rename-mapping detection and authority (Steps 2, 3, 6.5 / P059)

The `rename-mapping.json` table in this directory is the source of truth for ADR-documented plugin renames. Format:

```json
{
  "renames": [
    { "from": "wr-problem", "to": "wr-itil", "adr": "ADR-010", "since": "2026-03-15" }
  ]
}
```

**Authorisation chain** for direct `settings.json` mutation in Step 6.5:

1. The rename is ADR-documented (recorded in the mapping table with an `adr` field).
2. The target sibling is in the user-confirmed install plan from Step 6 (current project is always confirmed).
3. ADR-030 Confirmation amendment authorises direct settings.json mutation under these two conditions without a second consent gate.

`claude plugin uninstall --scope project` works and is the supported refresh path. The working refresh pattern for project-scoped plugins is `uninstall + install` (P106 / BRIEFING "Plugin Distribution").

Non-ADR-documented stale entries (manual user choices, plugins no longer in use) are NOT in `rename-mapping.json` and are NOT auto-migrated. User handles those manually.

## Consent gate shape — the P061 fallback (Step 6)

ADR-030 requires that the consent gate list every detected sibling. `AskUserQuestion` caps `maxItems` at 4.

- **Siblings ≤ 3** — one option per sibling + dry-run = ≤ 4 options. Fits cleanly.
- **Siblings > 3** — the per-sibling options don't fit. Fallback: four bucketed options with every detected sibling named in the question body text (the cap applies to options, not to the question description, so ADR-030's "list every sibling" requirement is satisfied via the question body).

The `Other — provide custom text` affordance lets the user name a free-form subset (e.g. "addressr, bbstats"); the skill parses against the detected set.

Either shape satisfies ADR-030 Confirmation criteria (first action; lists all detected siblings; dry-run present; user retains subset authority).

## Edge cases

- **No windyroad plugins in current project.** Skip steps 2-7, report "nothing to install here" but still run on confirmed siblings if any found.
- **No siblings with windyroad plugins.** Skip the consent gate's sibling options; offer only the dry-run option. Current project is still installed without a consent gate (ADR-004 scope — it's the project the skill lives in).
- **Cache dir missing for a plugin.** The plugin was never installed locally. Skip it — `install-updates` only refreshes what's already enabled; it does not bootstrap new installs.
- **`npm view` fails.** Plugin may not be published yet or network is down. Report and skip that plugin; do not block other plugins.
- **Version-string staleness.** `claude plugin list` may show stale version strings (BRIEFING line 34). Always compare against `~/.claude/plugins/cache/windyroad/<plugin>/` directory names, not `list` output.
- **Plugin name vs npm package name mismatch.** Plugin name / marketplace cache key = `wr-<short-name>`; npm package = `@windyroad/<short-name>` (no `wr-` prefix). `npm view` returns empty (exit 0) for wrong names — treat empty output as "verify the name" (P092).

## Non-interactive fallback details (ADR-013 Rule 6)

When `AskUserQuestion` is unavailable (running inside a subagent without that tool, or a test harness):

1. Emit a dry-run table of intended installs.
2. Note that the user must re-run interactively to complete.
3. Do NOT install anything.

The fallback preserves ADR-030's "no install without consent" invariant even when the structured interaction path is blocked.

## Not in scope (deliberately)

- Updating non-windyroad plugins (`anthropics/skill-creator`, `claude-plugins-official`). Out of scope.
- Migrating legacy JTBD layouts. That's `/wr-jtbd:update-guide`'s job — this skill only flags.
- Restarting Claude Code. User restarts on their own cadence (P045 direction 2026-04-20).
- Global-scope installs (`--scope user`). ADR-004: project-scope only.
- Pruning obsolete plugins. If you uninstalled a plugin manually, this skill does nothing about it — it only re-installs what is currently enabled.

## ADR cross-references

- **ADR-030** — governing decision; Confirmation criteria apply here.
- **ADR-003** — marketplace distribution (Confirmation amended in the same commit as ADR-030 to permit this skill).
- **ADR-004** — project-scoped plugin install.
- **ADR-008 Option 3** — legacy JTBD-layout breaking change; drives Step 5.
- **ADR-010** — `wr-problem` → `wr-itil` rename (primary P059 use-case).
- **ADR-013 Rule 6** — non-interactive fallback pattern.
- **ADR-038** — progressive disclosure for governance tooling context. This split implements the pattern at the SKILL.md level.
- **P045** — auto plugin install after governance release; interim manual stopgap.
- **P059** — rename-mapping auto-migration + direct settings.json mutation authorisation.
- **P061** — sibling-count > 3 `AskUserQuestion` `maxItems` fallback.
- **P092** — `wr-` prefix mismatch between plugin name and npm package name.
- **P098** — SKILL+REFERENCE split pattern applied here.
- **BRIEFING.md** — marketplace resolution semantics, version-string staleness, `plugin install` vs `plugin update` distinction.
