---
name: install-updates
description: Refresh the windyroad marketplace cache and re-install any updated `@windyroad/*` plugins into the current project AND into each sibling project (`../*/`) that has one or more windyroad plugins enabled. Run at end-of-session after a release loop so every active project picks up the new code on next session start. Repo-local skill per ADR-030.
allowed-tools: Read, Bash, Grep, Glob, AskUserQuestion
---

# /install-updates

Refresh every windyroad plugin install touched by recent releases — current project plus sibling projects — in one skill invocation. Interim stopgap for P045.

See `REFERENCE.md` in this directory for rationale, edge cases, scope exclusions, and the ADR-030 Confirmation amendment.

## When to invoke

- End of a release-loop session (after `npm run release:watch` publishes `@windyroad/*` packages).
- After noting a plugin bump in another session's commit log.
- Never mid-work on something unrelated — this skill writes to sibling projects.

## Steps

### 1. Refresh the marketplace cache

```bash
claude plugin marketplace update windyroad
```

Marketplace resolves from the remote GitHub repo, not the local working tree — push before running. See REFERENCE.md → "Marketplace resolution semantics".

### 2. Discover current project's installed windyroad plugins

```bash
CURRENT_PROJECT=$(basename "$PWD")
CURRENT_PLUGINS=$(grep -oE '"wr-[a-z0-9-]+@windyroad"' .claude/settings.json 2>/dev/null \
  | sed 's/"//g; s/@windyroad//' | sort -u)
```

**Rename-mapping detection (P059)**: load `rename-mapping.json`; for each enabled name matching `renames[].from`, record a `STALE_CURRENT` entry with `from`, `to`, `adr`, `since`. Current project is always confirmed — its stale entries always migrate in Step 6.5.

### 3. Discover sibling projects

```bash
SIBLINGS=()
for d in ../*/; do
  name=$(basename "$d")
  [ "$name" = "$CURRENT_PROJECT" ] && continue
  [ -f "$d.claude/settings.json" ] || continue
  if grep -qE '"wr-[a-z0-9-]+@windyroad"' "$d.claude/settings.json" 2>/dev/null; then
    SIBLINGS+=("$name")
  fi
done
```

**Per-sibling rename-mapping detection (P059)**: scan each sibling's `.claude/settings.json` for enabled-plugin keys matching `renames[].from`. Record `STALE_SIBLING` entries; only user-confirmed siblings migrate in Step 6.5.

### 4. Determine which plugins have new npm versions

For each unique plugin name across current + siblings:

```bash
npm view "@windyroad/<plugin-short-name>" version
```

Compare against `~/.claude/plugins/cache/windyroad/wr-<plugin-short-name>/`. Re-install only when npm latest > highest cached version. `claude plugin list` version strings may be stale — compare against cache dir names.

### 5. Flag legacy JTBD layouts (ADR-008 Option 3, P019)

```bash
if [ -f "$d/docs/JOBS_TO_BE_DONE.md" ] && [ ! -d "$d/docs/jtbd" ]; then
  LEGACY_JTBD_PROJECTS+=("$name")
fi
```

Dormant JTBD gate after wr-jtbd install lands. Flagged in the final report.

### 6. Consent gate (mandatory per ADR-030)

Invoke `AskUserQuestion` with one question, `multiSelect=true`. **Name every detected sibling in the question body** regardless of options count (ADR-030's "list every sibling" requirement).

- **Siblings ≤ 3** — one option per sibling plus `"Dry-run — show the plan but don't install"`.
- **Siblings > 3** (P061 `maxItems=4` fallback) — four bucketed options:
  1. `All <N> projects (Recommended)`
  2. `Current project only`
  3. `Dry-run — show the plan but don't install`
  4. The auto-provided `Other — provide custom text` covers custom subsets.

Either shape satisfies ADR-030 Confirmation. Never install without explicit consent for a sibling.

### 6.5. Auto-migrate ADR-documented stale entries (P059)

For each `STALE_*` entry whose target is in the user-confirmed install plan:

1. Install the canonical `to` plugin in the target's project scope:
   ```bash
   (cd "$TARGET_DIR" && claude plugin install "wr-${TO}@windyroad" --scope project)
   ```
2. Remove the stale `from` key from the target's `.claude/settings.json` (`claude plugin uninstall` refuses project-scope; direct mutation is authorised by the ADR-030 Confirmation amendment for ADR-documented renames):
   ```bash
   node -e '
     const fs = require("fs");
     const f = process.argv[1];
     const j = JSON.parse(fs.readFileSync(f, "utf8"));
     if (j.enabledPlugins) delete j.enabledPlugins["'"wr-${FROM}@windyroad"'"];
     fs.writeFileSync(f, JSON.stringify(j, null, 2) + "\n");
   ' "$TARGET_DIR/.claude/settings.json"
   ```
3. Record in `MIGRATED` as `<target> <from> → <to> (per <adr>)`.

Skip migration for siblings the user excluded from the install plan. Non-ADR-documented stale entries are NOT auto-migrated — see REFERENCE.md → "P059 rename-mapping authority".

### 7. Install

```bash
for plugin in $PLUGINS_TO_UPDATE; do
  (cd "$TARGET_DIR" && claude plugin install "wr-$plugin@windyroad" --scope project)
done
```

`--scope project` always (ADR-004). Capture per-install exit status. Do not abort the batch on a single failure — report and continue.

### 8. Final report

```
| Project | Plugin | Before | After | Status |
|---------|--------|--------|-------|--------|
| <project> | wr-itil | 0.7.1 | 0.7.2 | ✓ installed |
```

Then `### Auto-migrated stale entries (ADR-documented renames)` — list `MIGRATED` entries or explicitly state "No rename migrations applied this run." (ADR-030 Confirmation amendment transparency).

Then `### Legacy JTBD layouts (ADR-008 Option 3 breaking change)` if any projects flagged in Step 5 — list them with a `/wr-jtbd:update-guide` reminder.

Then `### Next step` — "Restart Claude Code to pick up the new plugin code. Active sessions continue running the old code until restart (per P045 direction 2026-04-20 — auto-restart explicitly rejected)."

## Non-interactive fallback

If `AskUserQuestion` is unavailable (e.g. running inside a subagent): emit a dry-run table of intended installs and a note that the user must re-run interactively. Do NOT install without consent.

## References

- **ADR-030** — repo-local skills (governing).
- **ADR-003 / ADR-004** — marketplace distribution / project-scope only.
- **ADR-008 Option 3** — legacy JTBD breaking change (Step 5).
- **ADR-013 Rule 6** — non-interactive fallback pattern.
- **P045** — auto plugin install after governance release. This skill is the manual stopgap until P045's automated queue lands.
- **P059 / ADR-010 / ADR-030 amendment** — rename-mapping authority.
- **P061** — sibling-count > 3 fallback (`maxItems=4`).
- **P098** — SKILL+REFERENCE split pattern applied here (progressive disclosure per ADR-038).

Rationale, edge cases, scope exclusions, and per-step BRIEFING references: `REFERENCE.md`.
