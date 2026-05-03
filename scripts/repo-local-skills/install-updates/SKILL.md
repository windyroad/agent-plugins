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

### 4. Determine which plugins have new npm versions

For each unique plugin key (`wr-<short>`) across current + siblings:

```bash
# Plugin/marketplace side uses the wr- prefix; the npm package omits it.
# Strip the prefix to obtain the npm package name:
#   plugin_key="wr-itil"      → npm_name="@windyroad/itil"
#   plugin_key="wr-architect" → npm_name="@windyroad/architect"
npm_name="@windyroad/${plugin_key#wr-}"
npm view "$npm_name" version
```

Naming convention (ADR-002): `wr-<short>` on the plugin/marketplace side, `@windyroad/<short>` on the npm side, same `<short>` as the source directory under `packages/`.

**Empty `npm view` output with exit 0 means the package name is wrong — NOT that the package is private.** `@windyroad/*` packages are public on the npm registry (e.g. <https://www.npmjs.com/package/@windyroad/itil>). If every plugin returns empty, the skill is using the wrong naming transformation — stop and fix before concluding "nothing to install," otherwise Step 6 will silently skip real updates.

Compare against `~/.claude/plugins/cache/windyroad/${plugin_key}/` (the cache directory uses the plugin key `wr-<short>`, not the npm name). Re-install only when npm latest > highest cached version. `claude plugin list` version strings may be stale — compare against cache dir names.

### 5. Consent gate (mandatory per ADR-030)

#### 5a. Cache check (P120) — skip the gate when consent is already on file

Read `.claude/.install-updates-consent` (per-project, gitignored). When present, parse the JSON:

```json
{
  "scope": ["addressr-mcp", "addressr-react", "addressr", "bbstats", "windyroad"],
  "cached_at": "2026-04-25T13:33:05Z"
}
```

Compute the **detected sibling set** from Step 3 (sibling project names that have one or more `wr-*@windyroad` plugins enabled). Compare to the cached `scope` array using **set equality** (same names, ignoring order; current project is implicitly in scope and is not part of the cache).

- **Cache hit** (cached scope matches detected sibling set): **skip Steps 5b/5c** — proceed directly to Step 6 with the cached scope. The user's prior explicit answer authorises the install per **ADR-013 Rule 5 (policy-authorised silent proceed)** — the cached on-disk consent IS the policy authorisation.
- **Cache miss — sibling set has changed** (a new sibling appeared, or one was removed since the cache was written): fire Step 5b/5c with the **previous answer surfaced as `(Recommended)`** in the question body so the user can re-confirm or adjust quickly.
- **Cache miss — no cache** (first invocation in this project, or cache was deleted): fire Step 5b/5c as today.
- **Cache silenced — `INSTALL_UPDATES_RECONFIRM=1`**: when this envvar is set on the invocation, fire Step 5b/5c regardless of cache state. Equivalent escape hatch: `rm .claude/.install-updates-consent` and re-run. Both routes restore the user's access to the dry-run option (which only surfaces inside the gate body).

Cache file shape, invalidation rules, and rationale: see `REFERENCE.md` → "Consent cache (P120)". Architectural precedent: **ADR-034**'s `.claude/.auto-install-consent` per-project marker for the SessionStart auto-install surface — same per-project, gitignored, stable-answer-cache shape; the two markers are independent (presence of one does not imply the other).

#### 5b/5c. Fire the consent gate (cache miss path)

Invoke `AskUserQuestion` with one question, `multiSelect=true`.

**Sibling count ≤ 3** — original contract applies: one option per sibling plus `"Dry-run — show the plan but don't install"`.

**Sibling count > 3 — grouping fallback (P061)**. `AskUserQuestion` caps `maxItems` at 4; fall back to bucketed options, and **name every detected sibling in the question body text** (the cap applies to options, not to the question description, so the full list is still presented per ADR-030's "list every sibling" requirement):

1. `All <N> projects (Recommended)`
2. `Current project only`
3. `Dry-run — show the plan but don't install`
4. The auto-provided `Other — provide custom text` covers custom subsets.

Either shape (≤ 3 or > 3 fallback) satisfies the ADR-030 Confirmation consent gate. Never install without explicit consent for a sibling.

#### 5d. Cache write (P120) — at end of successful run

After Step 6 install completes WITHOUT a `lost` status (i.e. every confirmed sibling either reached `installed` or `restored`), write `.claude/.install-updates-consent` with the install-plan scope:

```bash
python3 -c "
import json, datetime, os
data = {
  'scope': sorted(['<sibling-1>', '<sibling-2>', ...]),
  'cached_at': datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds').replace('+00:00','Z'),
}
os.makedirs('.claude', exist_ok=True)
open('.claude/.install-updates-consent', 'w').write(json.dumps(data, indent=2) + chr(10))
"
```

`Dry-run` answers do NOT write the cache (a dry-run is not a consent grant). `Current project only` writes an empty `scope` array (the empty-set is a valid stable answer). Cache is per-machine — gitignored — and is not committed.

### 6. Install

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
  # not necessarily at the pre-Step-6 version.
  claude plugin marketplace update windyroad >/dev/null 2>&1 || true
  if (cd "$target" && claude plugin install "$key" --scope project); then
    echo "restored"
    return 0
  fi
  echo "lost"
  return 1
}

declare -A PROJECT_STATUS
# PLUGINS_TO_UPDATE is a bash array (NOT a space-separated string) for
# cross-shell portability — see P133. Plain `for x in $VAR` word-splits
# under bash but iterates ONCE under zsh (zsh does not word-split unquoted
# variables by default), silently masking 24 lost plugins as one bogus
# joined-name install in the 2026-04-27 session. Array form + quoted
# `"${ARR[@]}"` expansion behaves identically under bash and zsh.
PLUGINS_TO_UPDATE=(itil retrospective risk-scorer tdd)
for plugin in "${PLUGINS_TO_UPDATE[@]}"; do
  PROJECT_STATUS["$plugin"]=$(install_with_retry_rollback "$plugin" "$TARGET_DIR" "${PRIOR_VERSION[$plugin]}")
done
```

`--scope project` always (ADR-004). Capture per-install exit status. Do not abort the batch on a single failure — report and continue. A `lost` status means the plugin was removed and could not be restored; the user must reinstall manually.

Shell snippets in this skill use bash-array form (`ARR=(a b c)` + `"${ARR[@]}"`) instead of unquoted-variable iteration (`for x in $VAR`). The array form is portable across bash and zsh; unquoted iteration is bash-only and silently iterates once under zsh — see P133 (`docs/problems/133-...md`).

### 6.5. Scaffold governance artefacts (per-sibling)

Per ADR-047 (P033 Phase 1). For each sibling confirmed in scope by Step 5 (and the current project, treated as an implicit sibling per ADR-004):

```bash
# scaffold_register_if_eligible <target>
# Trigger: <target>/RISK-POLICY.md present AND <target>/docs/risks/ absent.
# Per-file create-if-absent — never overwrite an existing scaffold file.
scaffold_register_if_eligible() {
  local target="$1"
  [ -f "$target/RISK-POLICY.md" ] || { echo "no-policy"; return 0; }
  local repo_templates
  repo_templates="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/templates" 2>/dev/null && pwd)"
  [ -d "$repo_templates" ] || repo_templates="$PWD/scripts/repo-local-skills/install-updates/templates"
  mkdir -p "$target/docs/risks"
  local readme_status="skipped" template_status="skipped"
  if [ ! -f "$target/docs/risks/README.md" ]; then
    cp "$repo_templates/risk-register-README.md.tmpl" "$target/docs/risks/README.md"
    readme_status="scaffolded"
  fi
  if [ ! -f "$target/docs/risks/TEMPLATE.md" ]; then
    cp "$repo_templates/risk-register-TEMPLATE.md.tmpl" "$target/docs/risks/TEMPLATE.md"
    template_status="scaffolded"
  fi
  echo "$readme_status,$template_status"
}
```

Per-sibling outcomes feed Step 7's final-report scaffold rows. No marker file — file existence is the marker (idempotent, drift-free).

**Trigger contract** (per ADR-047 § Trigger contract):

- `RISK-POLICY.md` present AND `docs/risks/` absent → scaffold both files.
- `RISK-POLICY.md` present AND one file missing (partial state) → scaffold only the missing file; preserve existing.
- `RISK-POLICY.md` present AND both files present → no writes (idempotent skip).
- `RISK-POLICY.md` absent → no scaffold attempted (precondition not met).

**ADR-013 audit**:

- Cache-hit / cache-miss with consent granted (Rule 5) — scaffold fires silently. Existence of `RISK-POLICY.md` plus prior consent IS the policy authorisation.
- Non-interactive subagent invocation (Rule 6) — scaffold does NOT fire. Inherits the install-loop's interactivity gate.
- Sibling consent answer was "Current project only" — scaffold fires for current project only.
- Dry-run consent answers do NOT scaffold (read-only by contract).

Templates: `scripts/repo-local-skills/install-updates/templates/risk-register-{README,TEMPLATE}.md.tmpl`. Substitution-token-free (project-agnostic) in v1; adopters fill in their own register entries.

Deep context (ADR-013 audit table, idempotency rationale, template-source-of-truth, alternatives considered): `REFERENCE.md` → "Governance-artefact scaffold (P033)".

### 7. Final report

```
| Project | Surface | Before | After | Status |
|---------|---------|--------|-------|--------|
| <project> | wr-itil | 0.7.1 | 0.7.2 | ✓ installed |
| <project> | wr-jtbd | 0.5.0 | 0.5.0 | ✓ restored (rollback) |
| <project> | wr-tdd  | 0.4.0 | —     | ✗ lost (rollback failed) |
| <project> | docs/risks/ | — | scaffolded | ✓ created (RISK-POLICY.md present) |
| <project> | docs/risks/ | (present) | (present) | ⊘ skipped (already exists) |
| <project> | docs/risks/ | — | — | ⊘ skipped (no RISK-POLICY.md) |
```

Status vocabulary (P112): `✓ installed` — install landed first or within retry budget. `✓ restored (rollback)` — all retries exhausted; marketplace-cache refresh + one rollback install succeeded. `✗ lost (rollback failed)` — retries and rollback both failed; plugin is absent from the project and the user must reinstall manually. `✗ failed` — pre-install step (e.g. uninstall) errored, plugin left in original state.

Scaffold-row vocabulary (ADR-047): `✓ created (RISK-POLICY.md present)` — file written. `⊘ skipped (already exists)` — idempotent skip. `⊘ skipped (no RISK-POLICY.md)` — trigger condition not met.

Then `### Next step` — "Restart Claude Code to pick up the new plugin code. Active sessions continue running the old code until restart (per P045 direction 2026-04-20 — auto-restart explicitly rejected)."

## Non-interactive fallback

If `AskUserQuestion` is unavailable (e.g. running inside a subagent): emit a dry-run table of intended installs and a note that the user must re-run interactively. Do NOT install without consent.

## References

- **ADR-030** — repo-local skills (governing).
- **ADR-003 / ADR-004** — marketplace distribution / project-scope only.
- **ADR-013 Rule 5 / Rule 6** — policy-authorised silent proceed / non-interactive fallback. Both apply to Step 6.5 scaffold.
- **ADR-047** — install-updates scaffolds governance artefacts (Step 6.5 contract).
- **P033** — driver ticket for Step 6.5 scaffold (no persistent risk register; Phase 1 lands here).
- **P045** — auto plugin install after governance release. This skill is the manual stopgap until P045's automated queue lands.
- **P061** — sibling-count > 3 fallback (`maxItems=4`).
- **P098** — SKILL+REFERENCE split pattern applied here (progressive disclosure per ADR-038).

Rationale, edge cases, scope exclusions, and per-step BRIEFING references: `REFERENCE.md`.
