---
name: install-updates
description: Refresh the windyroad marketplace cache and re-install any updated `@windyroad/*` plugins into the current project AND into each sibling project (`../*/`) that has one or more windyroad plugins enabled. Run at end-of-session after a release loop so every active project picks up the new code on next session start. Repo-local skill per ADR-030.
allowed-tools: Read, Bash, Grep, Glob, AskUserQuestion
---

# /install-updates

Refresh every windyroad plugin install touched by recent releases — current project plus sibling projects — in one skill invocation. Interim stopgap for P045 (the automated queue is not yet built).

## When to invoke

- **End of a release-loop session**: after `npm run release:watch` publishes one or more `@windyroad/*` packages to npm, run `/install-updates` before closing the session so the next session starts on fresh code.
- **After reading a BRIEFING note that a plugin changed**: if you notice a windyroad plugin bump in another session's commit log, run `/install-updates` to catch up.
- **Never**: if you are currently mid-work on something else. This skill writes to sibling projects; wait for a natural pause.

## Contract (per ADR-030)

- Repo-local skill. Not published. Lives in `.claude/skills/install-updates/` and is versioned by repo git history.
- First action is a consent gate — `AskUserQuestion` listing every sibling project this skill detected, with a dry-run option. No install runs before user confirmation.
- Installs use `claude plugin install <pkg>@windyroad --scope project`. Never global scope.
- Does NOT restart Claude Code (ADR-013 Rule 6; also explicitly rejected by P045's 2026-04-20 direction decision). User restarts on their own cadence.
- Does NOT migrate legacy JTBD layouts (that is `/wr-jtbd:update-guide`'s job). Projects on the legacy `docs/JOBS_TO_BE_DONE.md`-only layout are flagged in the final report with a migration reminder (ADR-008 Option 3).

## Steps

### 1. Refresh the marketplace cache

Run once regardless of which projects you are updating:

```bash
claude plugin marketplace update windyroad
```

Per the session's BRIEFING: "The marketplace resolves from the remote GitHub repo, not the local working tree. You cannot install a new plugin until changes are pushed and `claude plugin marketplace update windyroad` pulls the latest."

### 2. Discover current project's installed windyroad plugins

```bash
CURRENT_PROJECT=$(basename "$PWD")
CURRENT_PLUGINS=$(grep -oE '"wr-[a-z0-9-]+@windyroad"' .claude/settings.json 2>/dev/null \
  | sed 's/"//g; s/@windyroad//' | sort -u)
```

Save `CURRENT_PLUGINS` — the set of plugin names (without the `@windyroad` suffix) enabled in `.claude/settings.json`.

**Rename-mapping detection (P059)**: load `.claude/skills/install-updates/rename-mapping.json` and compare each enabled name in `CURRENT_PLUGINS` against the `renames[].from` column. For each match, record a `STALE_CURRENT` entry with the `from` name, `to` name, `adr` reference, and `since` date. These entries are migrated automatically in Step 6.5 within already-confirmed siblings — the current project is always confirmed, so its stale entries always migrate. The mapping table is the source of truth for ADR-documented renames; non-mapped plugins (manual user choices) are NOT considered stale.

### 3. Discover sibling projects

```bash
SIBLINGS=()
for d in ../*/; do
  name=$(basename "$d")
  # Skip the current project.
  [ "$name" = "$CURRENT_PROJECT" ] && continue
  # Skip directories without a .claude/settings.json.
  [ -f "$d.claude/settings.json" ] || continue
  # Skip directories with no windyroad plugins enabled.
  if grep -qE '"wr-[a-z0-9-]+@windyroad"' "$d.claude/settings.json" 2>/dev/null; then
    SIBLINGS+=("$name")
  fi
done
```

`SIBLINGS` is the set of sibling directory names (not full paths) that have at least one windyroad plugin enabled.

**Per-sibling rename-mapping detection (P059)**: for each detected sibling, scan its `.claude/settings.json` for enabled-plugin keys whose short-name matches `renames[].from` in `rename-mapping.json`. Record a `STALE_SIBLING` entry per match. These are migrated automatically in Step 6.5 — but only for siblings the user confirms in Step 6's consent gate. Siblings the user excludes from the install plan are NOT migrated.

### 4. Determine which plugins have new npm versions

For each unique plugin name across current + siblings:

```bash
npm view "@windyroad/<plugin-short-name>" version
```

Compare the result against the latest cached version under `~/.claude/plugins/cache/windyroad/wr-<plugin-short-name>/`. Only plugins where npm latest > highest cached version need re-install.

Per BRIEFING line 34: `claude plugin list` may show stale version strings. Compare against the actual cache dir names, not `list` output.

### 5. Flag legacy JTBD layouts (ADR-008 Option 3, P019)

For each project being updated (current + confirmed siblings):

```bash
if [ -f "$d/docs/JOBS_TO_BE_DONE.md" ] && [ ! -d "$d/docs/jtbd" ]; then
  # Legacy-only layout — wr-jtbd@0.6.0+ gate will be dormant.
  LEGACY_JTBD_PROJECTS+=("$name")
fi
```

These projects will have a dormant JTBD gate after the wr-jtbd install lands. The final report surfaces them with a `/wr-jtbd:update-guide` reminder.

### 6. Consent gate (mandatory per ADR-030)

Invoke `AskUserQuestion` with **one question, multiSelect=true**:

- `header: "Install targets"`
- `question: "Which projects should receive the updated plugins? Detected siblings below. Current project is always included."`
- Options: one per detected sibling name, plus a `"Dry-run — show the plan but don't install"` option.

The user can pick any subset (or dry-run). Never install without explicit consent for a sibling.

### 6.5. Auto-migrate ADR-documented stale entries (P059)

For each `STALE_CURRENT` and `STALE_SIBLING` entry whose target sibling is in the user-confirmed install plan from Step 6 (the current project is always confirmed):

1. Install the canonical (`to`) plugin in the target's project scope:
   ```bash
   (cd "$TARGET_DIR" && claude plugin install "wr-${TO}@windyroad" --scope project)
   ```
2. Remove the stale (`from`) key from `$TARGET_DIR/.claude/settings.json`:
   ```bash
   # Direct settings.json mutation — `claude plugin uninstall` refuses
   # project-scope per BRIEFING line 17. The mutation is authorised
   # by the ADR-030 Confirmation amendment (P059): ADR-documented
   # rename migrations within already-confirmed siblings MAY install
   # the new plugin AND remove the stale key without a second consent
   # gate.
   node -e '
     const fs = require("fs"), path = require("path");
     const f = process.argv[1];
     const j = JSON.parse(fs.readFileSync(f, "utf8"));
     if (j.enabledPlugins) delete j.enabledPlugins["'"wr-${FROM}@windyroad"'"];
     fs.writeFileSync(f, JSON.stringify(j, null, 2) + "\n");
   ' "$TARGET_DIR/.claude/settings.json"
   ```
3. Record the migration in a `MIGRATED` array for the Step 8 report: `<target> <from> → <to> (per <adr>)`.

If a `STALE_*` entry's target is NOT confirmed in Step 6 (user excluded the sibling from the install plan), skip the migration for that target. Excluded siblings keep their stale enabled-plugin keys; the user can re-run with that sibling included to migrate them.

The ADR-documented rename + sibling-set consent together constitute the authorisation for direct settings.json mutation. Non-ADR-documented stale entries (e.g. plugins the user uninstalled manually) are NOT in `rename-mapping.json` and are NOT auto-migrated by this step.

### 7. Install

For each confirmed project (current + user-confirmed siblings):

```bash
for plugin in $PLUGINS_TO_UPDATE; do
  # `cd` in a subshell so the parent cwd stays on the current project.
  (cd "$TARGET_DIR" && claude plugin install "wr-$plugin@windyroad" --scope project)
done
```

Capture each install's exit status. Use `--scope project` always — per ADR-004, global scope is avoided.

If any install fails, report the failure but continue with the remaining installs. Do not abort the whole batch on a single failure.

### 8. Final report

Print a markdown table:

```
| Project | Plugin | Before | After | Status |
|---------|--------|--------|-------|--------|
| <project> | wr-itil | 0.7.1 | 0.7.2 | ✓ installed |
| <project> | wr-architect | 0.4.0 | 0.4.1 | ✓ installed |
| ...
```

Then an **Auto-migrated stale entries (ADR-documented renames)** section listing each entry from the `MIGRATED` array, or — if no migrations applied — explicitly stating "No rename migrations applied this run." (per the ADR-030 Confirmation amendment transparency contract). Format:

```
### Auto-migrated stale entries (ADR-documented renames)

| Project | From | To | ADR |
|---------|------|----|----|
| <project> | wr-problem | wr-itil | ADR-010 |
| ... | ... | ... | ... |
```

The mapping table source: `.claude/skills/install-updates/rename-mapping.json`.

Then a **Legacy JTBD layouts** section if any were flagged in Step 5:

```
### Legacy JTBD layouts (ADR-008 Option 3 breaking change)

The following projects still have `docs/JOBS_TO_BE_DONE.md` without `docs/jtbd/`.
After the wr-jtbd install, the JTBD gate will be dormant until you run
`/wr-jtbd:update-guide` to migrate each project.

- <project name>
- ...
```

Then a **Restart reminder**:

```
### Next step

Restart Claude Code to pick up the new plugin code. Active sessions
continue running the old code until restart (per P045 direction decision
2026-04-20 — auto-restart explicitly rejected).
```

## Non-interactive fallback

If `AskUserQuestion` is unavailable (e.g. running inside a subagent that lacks the tool), emit a **dry-run table** of intended installs and a note that the user must re-run interactively. Do NOT install anything without consent.

## Edge cases

- **No windyroad plugins in current project**: skip steps 2-7, report "nothing to install here" but still run on confirmed siblings if any were found.
- **No siblings with windyroad plugins**: skip the consent gate's sibling options; only offer the dry-run option. Current project is still installed without a consent gate (it's the project the skill lives in — ADR-004 scope).
- **Cache dir missing for a plugin**: the plugin was never installed locally. Skip it — `install-updates` only refreshes what's already enabled; it does not bootstrap new installs.
- **npm view fails**: the plugin may not be published yet or the network is down. Report the failure and skip that plugin; do not block other plugins.

## Not in scope (deliberately)

- Updating non-windyroad plugins (e.g. `anthropics/skill-creator`, `claude-plugins-official`). Out of scope.
- Migrating legacy JTBD layouts. That is `/wr-jtbd:update-guide`'s job — this skill only flags.
- Restarting Claude Code. User restarts on their own cadence (P045 direction).
- Global-scope installs (`--scope user`). ADR-004: project-scope only.
- Pruning obsolete plugins. If you uninstalled a plugin, this skill does nothing about it — it only re-installs what is currently enabled.

## References

- **ADR-030** — governing decision for repo-local skills; Confirmation criteria apply here.
- **ADR-003** — marketplace distribution (Confirmation amended in the same commit as ADR-030 to permit this skill).
- **ADR-004** — project-scoped plugin install.
- **ADR-008 Option 3** — legacy JTBD-layout breaking change; drives Step 5.
- **ADR-013 Rule 6** — non-interactive fallback pattern.
- **P045** — auto plugin install after governance release. This skill is the manual stopgap until P045's automated queue lands.
- **P059 / ADR-010 / ADR-030 amendment** — rename-mapping table at `.claude/skills/install-updates/rename-mapping.json` is consumed by Step 2/3 detection and Step 6.5 auto-migration. Direct settings.json mutation for ADR-documented rename migrations within already-confirmed siblings is authorised by the ADR-030 Confirmation amendment.
- **BRIEFING.md** — marketplace resolution from remote repo, version-string staleness, `plugin install` vs `plugin update` distinction.
