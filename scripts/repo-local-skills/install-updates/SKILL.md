---
name: install-updates
description: Refresh the windyroad marketplace cache and re-install any updated `@windyroad/*` plugins. Runs a single global-cache refresh from the current project — because the plugin install cache is global/shared across projects, this advances the active version for every project that enables those plugins. Run at end-of-session after a release loop so every active project picks up the new code on next session start. Repo-local skill per ADR-030.
allowed-tools: Read, Bash, Grep, Glob
---

# /install-updates

Refresh every windyroad plugin touched by recent releases in one skill invocation — a single global-cache refresh run from the current project. Interim stopgap for P045.

The plugin install cache is GLOBAL across all projects (`~/.claude/plugins/cache/windyroad/<key>/<version>/`), so a single current-project refresh advances the active version for every project that enables those plugins. No cross-project tree write; no sibling consent gate.

See `REFERENCE.md` for: global-cache rationale + historical consent-gate retirement (§ "Why current-project-only is sufficient"), marketplace-resolution semantics, uninstall+install rationale, edge cases, scope exclusions, result-token interpretation, and the P343 restart-required mechanism.

## When to invoke

- End of a release-loop session (after `npm run release:watch` publishes `@windyroad/*` packages).
- After noting a plugin bump in another session's commit log.
- Safe to run any time — it only refreshes the global cache for already-enabled plugins; it makes no cross-project tree write.

## Steps

### 1. Refresh the marketplace cache

```bash
claude plugin marketplace update windyroad
```

Marketplace resolves from the remote GitHub repo, not the local working tree — push before running. See REFERENCE.md → "Marketplace resolution semantics".

### 2. Discover the current project's installed windyroad plugins

```bash
CURRENT_PLUGINS=$(grep -oE '"wr-[a-z0-9-]+@windyroad"' .claude/settings.json 2>/dev/null \
  | sed 's/"//g; s/@windyroad//' | sort -u)
```

These are the plugin keys (`wr-<short>`) to check for updates. The skill refreshes only what is already enabled — it does not bootstrap new installs.

### 3. Determine which plugins have new npm versions

Iterate over `$CURRENT_PLUGINS` (newline-joined from Step 2) with a `while IFS= read -r` loop — NOT `for key in $CURRENT_PLUGINS`, which iterates ONCE under zsh because zsh does not word-split unquoted variables by default (P133 / P320 defect 1). The whole 11-plugin blob then arrives in `key` and `npm view` gets a garbage package name. The skill already applies the same P133 discipline in Step 4 via bash arrays — Step 3 must match.

Avoid zsh-reserved special variable names inside the loop body: **`status`, `path`, `argv`, `pipestatus`** are read-only under zsh; assigning to any of them aborts the loop with `read-only variable: …` (P320 defect 2). Use `st`, `pkg_path`, etc.

```bash
# Plugin/marketplace side uses the wr- prefix; the npm package omits it.
# Strip the prefix to obtain the npm package name:
#   plugin_key="wr-itil"      → npm_name="@windyroad/itil"
#   plugin_key="wr-architect" → npm_name="@windyroad/architect"
while IFS= read -r plugin_key; do
  [ -z "$plugin_key" ] && continue
  npm_name="@windyroad/${plugin_key#wr-}"
  latest_npm=$(npm view "$npm_name" version 2>/dev/null)
  # Filter cache dirs to strict semver (M.N.P) BEFORE sort -V | tail -1.
  # Without the filter, SHA-named git-source residual dirs (e.g.
  # `2287c49f7b4b`) win the sort — `sort -V` treats `2287c49f...` as version
  # `2287` and orders it above any `0.8.x`, so `tail -1` returns the SHA and
  # every plugin false-reports stale (P320 defect 3 / the trap captured in
  # `feedback_verify_cache_refresh_by_version_dir`).
  cached_dir="$HOME/.claude/plugins/cache/windyroad/${plugin_key}"
  highest_cached=$(ls "$cached_dir" 2>/dev/null \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V | tail -1)
  echo "${plugin_key}: npm=${latest_npm:-?}  cached=${highest_cached:-none}"
done < <(printf '%s\n' "$CURRENT_PLUGINS")
```

Naming convention (ADR-002): `wr-<short>` on the plugin/marketplace side, `@windyroad/<short>` on the npm side, same `<short>` as the source directory under `packages/`. Empty `npm view` output with exit 0 means the package name is wrong — see REFERENCE.md § "npm view returns empty — name is wrong, not private" (P092 trap).

Re-install only when `latest_npm > highest_cached`. `claude plugin list` version strings may be stale — compare against cache dir names (and filter to semver per the snippet above; the SHA residual is the recurring trap).

### 4. Install

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
  # not necessarily at the pre-refresh version.
  claude plugin marketplace update windyroad >/dev/null 2>&1 || true
  if (cd "$target" && claude plugin install "$key" --scope project); then
    echo "restored"
    return 0
  fi
  echo "lost"
  return 1
}

# restore_settings_on_loss <snapshot> <settings_file> [<lost_plugin>...]
# P259 defensive recovery. Restore the pre-loop .claude/settings.json snapshot
# iff at least one plugin ended `lost` (all retries + the marketplace-refresh
# rollback exhausted — the plugin is now absent from settings.json because the
# Step-4 uninstall removed its enabledPlugins entry and no install re-added it).
# SAFE for plugins that refreshed successfully in the SAME run: the
# enabledPlugins map carries NO version pin — the version advance lives in the
# global cache (~/.claude/plugins/cache/...), not in settings.json — so a
# successful refresh's entry is byte-identical before and after the loop, and a
# full-file restore re-adds the lost plugin(s) without regressing any success.
# ASSUMES enabledPlugins has no per-run-mutated field; if a future Claude Code
# release adds version pinning here, switch to a surgical re-add of the lost
# keys only. Prints "restored <plugins>" or "no-restore".
restore_settings_on_loss() {
  local snapshot="$1" settings="$2"; shift 2
  local lost=("$@")
  if [ "${#lost[@]}" -gt 0 ] && [ -n "$snapshot" ] && [ -f "$snapshot" ]; then
    cp "$snapshot" "$settings"
    echo "install-updates: restored .claude/settings.json from pre-loop snapshot — lost plugin(s): ${lost[*]}" >&2
    echo "restored ${lost[*]}"
    return 0
  fi
  echo "no-restore"
  return 0
}

declare -A PROJECT_STATUS
# PLUGINS_TO_UPDATE is a bash array (NOT a space-separated string) for
# cross-shell portability — see P133. Plain `for x in $VAR` word-splits
# under bash but iterates ONCE under zsh (zsh does not word-split unquoted
# variables by default), silently masking lost plugins as one bogus
# joined-name install. Array form + quoted `"${ARR[@]}"` expansion behaves
# identically under bash and zsh.
TARGET_DIR="$PWD"
PLUGINS_TO_UPDATE=(itil retrospective risk-scorer tdd)

# P259: snapshot the project's plugin-enablement state BEFORE the
# uninstall+install loop. The uninstall side of each refresh immediately
# removes the plugin's enabledPlugins entry; if every install attempt AND the
# marketplace-refresh rollback then fail (e.g. a broken manifest already
# published — the 2026-05-18 P0), the plugin is left absent and the project
# silently loses enablement (the cascade that gutted settings from 13 plugins
# to 2). The snapshot lets an exhausted `lost` outcome be undone below. A
# working-tree `cp` (not `git checkout HEAD`) captures the exact pre-run state,
# including any uncommitted settings.json edits and the untracked-file case.
SETTINGS_FILE="$TARGET_DIR/.claude/settings.json"
SETTINGS_SNAPSHOT=""
if [ -f "$SETTINGS_FILE" ]; then
  SETTINGS_SNAPSHOT="$(mktemp -t install-updates-settings.XXXXXX)"
  cp "$SETTINGS_FILE" "$SETTINGS_SNAPSHOT"
fi

for plugin in "${PLUGINS_TO_UPDATE[@]}"; do
  PROJECT_STATUS["$plugin"]=$(install_with_retry_rollback "$plugin" "$TARGET_DIR" "${PRIOR_VERSION[$plugin]}")
done

# P259: restore-on-exhausted-loss. Collect plugins that ended `lost` and
# restore the pre-loop snapshot if any are present, so a broken-manifest
# cascade can no longer gut .claude/settings.json. No-op when nothing was lost
# (empty array → zero trailing args → restore_settings_on_loss prints
# "no-restore"). Quoted `"${lost_plugins[@]}"` expansion is bash/zsh-portable
# per P133 and expands an empty array to zero args under both shells.
lost_plugins=()
for plugin in "${PLUGINS_TO_UPDATE[@]}"; do
  [ "${PROJECT_STATUS[$plugin]}" = "lost" ] && lost_plugins+=("$plugin")
done
restore_settings_on_loss "$SETTINGS_SNAPSHOT" "$SETTINGS_FILE" "${lost_plugins[@]}"
[ -n "$SETTINGS_SNAPSHOT" ] && rm -f "$SETTINGS_SNAPSHOT"
```

`--scope project` always (ADR-004). Capture per-install exit status. Do not abort the batch on a single failure — report and continue. For `lost` / `restored` / snapshot-recovery interpretation + the settings.json fallback when no snapshot was captured: see REFERENCE.md § "Step 4 result interpretation (lost / restored / snapshot recovery)".

### 5. Final report

```
| Surface | Before | After | Status |
|---------|--------|-------|--------|
| wr-itil | 0.7.1 | 0.7.2 | ✓ installed |
| wr-jtbd | 0.5.0 | 0.5.0 | ✓ restored (rollback) |
| wr-tdd  | 0.4.0 | —     | ✗ lost (rollback failed) |
```

Status tokens (P112): `installed` / `restored` / `lost` / `failed`. Token-meaning rationale: REFERENCE.md § "Status vocabulary (P112) — extended rationale".

Then `### Next step` — **"Restart Claude Code REQUIRED to use the refreshed plugin code via shims in the current session."** This is load-bearing — without restart, shim invocations may still resolve to the previous plugin version's `/bin`. The PATH-stale-shim mechanism + the absolute-path workaround for use-without-restart: REFERENCE.md § "Restart-required mechanism (P343 PATH-stale-shim)".

## Non-interactive fallback

This skill is safe to run non-interactively (e.g. inside a subagent or an AFK loop): it makes no cross-project tree write and asks no questions, so there is nothing to gate. Run it directly — it refreshes the global cache for the current project's enabled plugins and reports what it refreshed (the Step 5 table). If `npm view` or the marketplace refresh fails for a plugin, report and skip that plugin without aborting the batch.

## References

- **ADR-030** — repo-local skills (governing; consent-gate retired 2026-05-25).
- **ADR-003 / ADR-004** — marketplace distribution / project-scope only.
- **ADR-002** — `wr-<short>` ↔ `@windyroad/<short>` naming transform.
- **ADR-038 / ADR-054** — progressive-disclosure pattern / SKILL.md budget policy.
- **P045** — auto plugin install after governance release (this skill is the manual stopgap).
- **P106 / P112 / P259** — `install` silent-no-op refresh pattern / non-atomic retry+rollback / settings.json snapshot recovery.
- **P133 / P320** — zsh portability (bash arrays + `while IFS= read -r`).
- **P139** — source-of-truth at `scripts/repo-local-skills/install-updates/`; `.claude/skills/install-updates/` carries relative symlinks. Edit the source path only.
- **P343** — PATH-stale-shim mechanism; restart required to use refreshed shims in-session.
- **Risk-register bootstrap retired** — Step 6.5 auto-trigger (ADR-059 verdict A6) retired 2026-05-25. Use `/wr-risk-scorer:bootstrap-catalog` on demand.

All rationale, edge cases, scope exclusions, BRIEFING cross-refs, and per-P-ticket deep-dives: `REFERENCE.md`.
