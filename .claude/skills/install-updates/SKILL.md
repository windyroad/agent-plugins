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

For each unique plugin key (`wr-<short>`) across current + siblings — after rename-mapping resolution from Steps 2/3, always operate on the post-rename `to` value so a renamed plugin's version check queries the current package:

```bash
# Plugin/marketplace side uses the wr- prefix; the npm package omits it.
# Strip the prefix to obtain the npm package name:
#   plugin_key="wr-itil"      → npm_name="@windyroad/itil"
#   plugin_key="wr-architect" → npm_name="@windyroad/architect"
npm_name="@windyroad/${plugin_key#wr-}"
npm view "$npm_name" version
```

Naming convention (ADR-002): `wr-<short>` on the plugin/marketplace side, `@windyroad/<short>` on the npm side, same `<short>` as the source directory under `packages/`.

**Empty `npm view` output with exit 0 means the package name is wrong — NOT that the package is private.** `@windyroad/*` packages are public on the npm registry (e.g. <https://www.npmjs.com/package/@windyroad/itil>). If every plugin returns empty, the skill is using the wrong naming transformation — stop and fix before concluding "nothing to install," otherwise Step 7 will silently skip real updates.

Compare against `~/.claude/plugins/cache/windyroad/${plugin_key}/` (the cache directory uses the plugin key `wr-<short>`, not the npm name). Re-install only when npm latest > highest cached version. `claude plugin list` version strings may be stale — compare against cache dir names.

### 5. Flag legacy JTBD layouts (ADR-008 Option 3, P019)

```bash
if [ -f "$d/docs/JOBS_TO_BE_DONE.md" ] && [ ! -d "$d/docs/jtbd" ]; then
  LEGACY_JTBD_PROJECTS+=("$name")
fi
```

Dormant JTBD gate after wr-jtbd install lands. Flagged in the final report.

### 6. Consent gate (mandatory per ADR-030)

Invoke `AskUserQuestion` with one question, `multiSelect=true`.

**Sibling count ≤ 3** — original contract applies: one option per sibling plus `"Dry-run — show the plan but don't install"`.

**Sibling count > 3 — grouping fallback (P061)**. `AskUserQuestion` caps `maxItems` at 4; fall back to bucketed options, and **name every detected sibling in the question body text** (the cap applies to options, not to the question description, so the full list is still presented per ADR-030's "list every sibling" requirement):

1. `All <N> projects (Recommended)`
2. `Current project only`
3. `Dry-run — show the plan but don't install`
4. The auto-provided `Other — provide custom text` covers custom subsets.

Either shape (≤ 3 or > 3 fallback) satisfies the ADR-030 Confirmation consent gate. Never install without explicit consent for a sibling.

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

Uninstall first to force a fresh download — `claude plugin install` silently no-ops when the plugin is already installed, so updates never land (P106 / BRIEFING "Plugin Distribution"). The uninstall+install chain is not atomic: if uninstall succeeds and install fails, the plugin is gone (P112). Wrap the install side in bounded retry + rollback so a transient failure cannot silently remove a plugin.

```bash
# install_with_retry_rollback <plugin> <target> <prior_version>
# Refresh a single plugin in a project scope with retry + rollback safety.
# Uninstall first (P106 workaround for install silent-no-op), retry the
# install 3× with exponential backoff (1s, 2s, 4s), and on exhaustion
# refresh the marketplace cache + one rollback install attempt.
# Prints one of: installed | restored | lost
install_with_retry_rollback() {
  local plugin="$1" target="$2" prior="${3:-unknown}"
  local key="wr-$plugin@windyroad"
  (cd "$target" && claude plugin uninstall "$key" --scope project) || true
  local attempt delay=1
  for attempt in 1 2 3; do
    if (cd "$target" && claude plugin install "$key" --scope project); then
      echo "installed"
      return 0
    fi
    if [ "$attempt" -lt 3 ]; then
      sleep "$delay"
      delay=$((delay * 2))
    fi
  done
  # All retries exhausted. Rollback path: refresh the marketplace cache
  # and attempt one more install — distinct from retry because the cache
  # has been refreshed, maximising the chance a different outcome lands.
  # Prior version (${prior}) is captured for reporting; marketplace
  # resolves to latest, so "restored" here means the plugin is present,
  # not necessarily at the pre-Step-7 version.
  claude plugin marketplace update windyroad >/dev/null 2>&1 || true
  if (cd "$target" && claude plugin install "$key" --scope project); then
    echo "restored"
    return 0
  fi
  echo "lost"
  return 1
}

declare -A PROJECT_STATUS
for plugin in $PLUGINS_TO_UPDATE; do
  PROJECT_STATUS["$plugin"]=$(install_with_retry_rollback "$plugin" "$TARGET_DIR" "${PRIOR_VERSION[$plugin]}")
done
```

`--scope project` always (ADR-004). Capture per-install exit status. Do not abort the batch on a single failure — report and continue. A `lost` status means the plugin was removed and could not be restored; the user must reinstall manually.

### 8. Final report

```
| Project | Plugin | Before | After | Status |
|---------|--------|--------|-------|--------|
| <project> | wr-itil | 0.7.1 | 0.7.2 | ✓ installed |
| <project> | wr-jtbd | 0.5.0 | 0.5.0 | ✓ restored (rollback) |
| <project> | wr-tdd  | 0.4.0 | —     | ✗ lost (rollback failed) |
```

Status vocabulary (P112): `✓ installed` — install landed first or within retry budget. `✓ restored (rollback)` — all retries exhausted; marketplace-cache refresh + one rollback install succeeded. `✗ lost (rollback failed)` — retries and rollback both failed; plugin is absent from the project and the user must reinstall manually. `✗ failed` — pre-install step (e.g. uninstall) errored, plugin left in original state.

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
