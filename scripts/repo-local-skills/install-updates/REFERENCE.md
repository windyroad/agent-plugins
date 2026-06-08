# /install-updates — Reference

Deep context for the `/install-updates` skill. Load on demand when the runtime steps in `SKILL.md` do not give you enough to act. Progressive-disclosure companion per ADR-038 pattern applied to skill bodies (reference implementation of the pattern P097 is expected to generalise).

## Why current-project-only is sufficient (global cache)

The plugin install cache at `~/.claude/plugins/cache/windyroad/<key>/<version>/` is shared across all projects on this machine — there is NO per-project copy of the plugin code. Refreshing it from the current project (uninstall + reinstall, to defeat the P106 install-no-op) advances the active version for EVERY project that enables those plugins. No sibling-project tree is written, so there is no cross-project side effect to discover or consent to.

Historical note: earlier versions ran a per-sibling install loop behind an `AskUserQuestion` consent gate; both were retired 2026-05-25 once the global-cache fact was confirmed (ADR-030 amendment 2026-05-25). The retirement removed the multi-project enumeration, the consent cache file (`.claude/.install-updates-consent`), and the sibling-bucket P061 fallback. See ADR-030 amendment for the chain of reasoning.

## npm view returns empty — name is wrong, not private

`@windyroad/*` packages are PUBLIC on the npm registry (e.g. <https://www.npmjs.com/package/@windyroad/itil>). If Step 3 emits empty `npm view` output with exit 0 for every plugin, the skill is using the wrong naming transformation — stop and fix before concluding "nothing to install," otherwise Step 4 will silently skip real updates.

Naming transform (ADR-002): the plugin/marketplace side uses the `wr-` prefix; the npm package omits it. `plugin_key="wr-itil"` → `npm_name="@windyroad/itil"`. The Step 3 loop applies this stripping inline; treat any empty result as a derivation bug, not a privacy hint (P092).

## Step 4 result interpretation (lost / restored / snapshot recovery)

The Step 4 batch reports a per-plugin status; do not abort the batch on a single failure — report and continue.

- **`✓ installed`** — first or retry install landed inside the retry budget.
- **`✓ restored (rollback)`** — three install attempts exhausted; marketplace-cache refresh + one rollback install succeeded.
- **`✗ lost (rollback failed)`** — retries AND rollback exhausted; the plugin is absent from the project and the user must reinstall manually. The post-loop snapshot restore (P259) re-adds the lost plugin's `.claude/settings.json` enablement so the project is not left gutted — but the plugin code is still un-refreshed; user must re-run after the upstream cause (e.g. a broken manifest) is hotfixed.
- **`✗ failed`** — pre-install step (e.g. uninstall) errored; the plugin is left in original state.

If the snapshot itself is unavailable (settings.json untracked and no snapshot captured), recover enablement manually with `git checkout HEAD -- .claude/settings.json` (settings.json is git-tracked in this repo). `--scope project` is invariant per ADR-004. The refresh runs in the current project; because the install cache is global, a single current-project refresh advances the active version for every project that enables the plugin.

## Restart-required mechanism (P343 PATH-stale-shim)

The Final report's restart instruction is load-bearing. Without a Claude Code restart, shim invocations (e.g. `wr-architect-generate-decisions-compendium`) may still resolve to the PREVIOUS plugin version's `/bin` directory and run OLD code — the global cache refresh advances `~/.claude/plugins/cache/windyroad/<plugin>/<version>/` but does NOT mutate the parent shell's `$PATH`. PATH was frozen at session-init from cache state at that time; subsequent `/install-updates` calls add new versions to cache but leave the stale `<plugin>/<old-version>/bin` first on PATH, so shim lookups continue to find the old version (P343).

**Workaround without restart**: invoke shims by absolute path of the desired version:

```
~/.claude/plugins/cache/windyroad/<plugin>/<latest>/bin/<shim-name>
```

Auto-restart was explicitly rejected per P045 direction 2026-04-20. Structural fixes (highest-version-wins shim wrapper, SessionStart PATH-refresh hook) deferred as ADR-class follow-ups (P343).

## Status vocabulary (P112) — extended rationale

The retry+rollback chain is not atomic: if uninstall succeeds and install fails, the plugin is gone (P112). The four status tokens (`installed` / `restored` / `lost` / `failed`) encode the distinct outcome paths so users can interpret the final report without re-reading the function source. `restored` carries a parenthetical `(rollback)` annotation in the report table to mark that the marketplace-cache refresh fired and a different cache state may now be present than at the start of the refresh.

## Contract (per ADR-030)

- **Repo-local skill.** Not published. Lives in `.claude/skills/install-updates/` and is versioned by repo git history.
- **First action is a consent gate.** `AskUserQuestion` lists every sibling project this skill detected, with a dry-run option. No install runs before user confirmation.
- **Installs use `claude plugin install <pkg>@windyroad --scope project`.** Never global scope (ADR-004).
- **Does NOT restart Claude Code.** ADR-013 Rule 6 governs non-interactive behaviour; P045's 2026-04-20 direction decision explicitly rejected auto-restart. User restarts on their own cadence.

## Marketplace resolution semantics (Step 1)

Per BRIEFING: "The marketplace resolves from the remote GitHub repo, not the local working tree. You cannot install a new plugin until changes are pushed and `claude plugin marketplace update windyroad` pulls the latest."

Workflow implication: run the full release pipeline (`push:watch` + `release:watch`) BEFORE invoking `/install-updates`. Installing from an unpushed working tree silently resolves against the last-published version.

## Uninstall+install refresh pattern (P106)

`claude plugin install` is a silent no-op when the plugin is already installed at any version, so updates never land via `install` alone. The working refresh pattern for project-scoped plugins is `uninstall + install` — `claude plugin uninstall --scope project` does work for project-scope, contrary to earlier assumptions, and forces a fresh marketplace download on the subsequent install. SKILL.md Step 6 wraps this in a retry+rollback so a transient install failure cannot silently lose the plugin (P112).

## Consent cache (P120)

The Step 6 consent gate has zero decision content for steady-state solo-developer + stable-sibling-set workflows — the answer is invariably `All N projects (Recommended)` and the round-trip is friction. The cache file `.claude/.install-updates-consent` records the user's prior explicit answer so subsequent invocations can skip the gate when the answer is provably equal.

### Cache file shape

Per-project, gitignored, machine-local. JSON:

```json
{
  "scope": ["addressr-mcp", "addressr-react", "addressr", "bbstats", "windyroad"],
  "cached_at": "2026-04-25T13:33:05Z"
}
```

- `scope` — sorted list of sibling project names confirmed in the prior consent gate. Current project is implicitly in scope (ADR-004 — the project the skill lives in is always installed); not part of the cache.
- `cached_at` — ISO timestamp the cache was written (informational; cache invalidation is event-driven, not time-based).
- Empty `scope: []` is valid and stable — encodes the user's prior `Current project only` answer.

### Match rule

The match rule is **set equality** of the cached `scope` against the detected sibling set from Step 3. Same names, ignoring order. A new sibling appearing or an existing sibling disappearing invalidates the cache (re-prompt with previous answer surfaced as `(Recommended)`).

### Invalidation rules

- **Sibling-set change** — invalidate. The user's prior answer is over a different question; surface it as `(Recommended)` in the re-prompt and let them confirm or adjust.
- **Plugin-list change** (a sibling enables a new windyroad plugin) — DO NOT invalidate. The cache governs which projects to install in, not which plugins to install. Step 4 already discovers the per-plugin install plan against the post-cache sibling set.
- **No time-based expiry**. Consent doesn't have a half-life on a stable workspace. The cache is invalidated by event (sibling-set change) or explicit user action (file deletion / `INSTALL_UPDATES_RECONFIRM=1`).

### Governing rule (ADR-013 Rule 5)

Cache-hit skip-gate is a Rule 5 (policy-authorised silent proceed) case, NOT Rule 6 (non-interactive fail-safe). The cached on-disk consent IS the policy authorisation — Rule 5 explicitly authorises silent proceed when a stable user authorisation is on file. Rule 6 governs cases where AskUserQuestion is unavailable; that is unrelated to the cache hit.

### Architectural precedent (ADR-034)

ADR-034's `.claude/.auto-install-consent` per-project marker for the SessionStart auto-install surface is the parallel pattern. The two markers are independent — presence of one does not imply the other:

- `.claude/.auto-install-consent` (ADR-034) authorises the SessionStart hook to invoke `/install-updates` in the background when outdated `@windyroad/*` plugins are detected.
- `.claude/.install-updates-consent` (P120) caches the answer to `/install-updates`'s own Step 6 sibling-set consent gate.

The first authorises *whether* `/install-updates` runs at all; the second caches *which siblings* it touches when it does run.

### Escape hatches (preserve dry-run access)

The cache-hit path skips the gate entirely; `Dry-run` is a gate option and becomes unreachable on the steady-state path. Two equivalent escape hatches restore access:

- `INSTALL_UPDATES_RECONFIRM=1 /install-updates` — envvar silences the cache for one invocation; gate fires with previous answer surfaced.
- `rm .claude/.install-updates-consent && /install-updates` — delete the cache file; gate fires as first-run.

Both routes return the user to the dry-run option; neither breaks the cache permanently (the next normal invocation re-writes the cache after a successful run).

## Consent gate shape — the P061 fallback (Step 5)

ADR-030 requires that the consent gate list every detected sibling. `AskUserQuestion` caps `maxItems` at 4.

- **Siblings ≤ 3** — one option per sibling + dry-run = ≤ 4 options. Fits cleanly.
- **Siblings > 3** — the per-sibling options don't fit. Fallback: four bucketed options with every detected sibling named in the question body text (the cap applies to options, not to the question description, so ADR-030's "list every sibling" requirement is satisfied via the question body).

The `Other — provide custom text` affordance lets the user name a free-form subset (e.g. "addressr, bbstats"); the skill parses against the detected set.

Either shape satisfies ADR-030 Confirmation criteria (first action; lists all detected siblings; dry-run present; user retains subset authority).

## Edge cases

- **No windyroad plugins in current project.** Skip steps 2-6, report "nothing to install here" but still run on confirmed siblings if any found.
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

## Governance-artefact scaffold (P033)

ADR-047 amends `/install-updates` to scaffold governance artefacts into adopter siblings when the governing policy file is present but the artefact directory is missing. Step 6.5 is the implementation site. This section is the deep-context companion.

### Why install-updates is the trigger surface

P033 reopened from Verifying on 2026-04-28 with a sibling-survey showing **6/6 adopters with `RISK-POLICY.md` accumulating ~285 cumulative `.risk-reports/` entries, but only 1/6 had populated `docs/risks/`** and 4/6 didn't even have the directory scaffolded. The risk REGISTER required by ISO 31000 § 6.4.2 and ISO 27001 § 6.1.2/6.1.3 was missing on every adopter where it would matter.

The P033 / P102 / P110 fix triplet shipped the *plumbing* (scaffolding pattern in this repo, `/wr-risk-scorer:create-risk` skill, `RISK_REGISTER_HINT:` from the pipeline agent) but no *trigger* fired the directory into existence on adopter projects. Adopters install the plugin, configure `RISK-POLICY.md`, watch `.risk-reports/` accumulate — but `docs/risks/` never appears because nothing creates it. The hint surface is opt-in and undiscoverable; create-risk is opt-in and undiscoverable.

ADR-047 architect verdict: install-updates is the natural trigger surface because it (a) already enumerates siblings, (b) already runs in foreground with consent gate, (c) already has ADR-013 Rule 6 fallback, (d) already writes to sibling project trees. Adding "scaffold `docs/risks/` if `RISK-POLICY.md` exists and the directory is absent" is one additive step within existing scope. Alternatives considered and rejected: SessionStart hook (too aggressive, violates ADR-040 read-mostly contract), new `/wr-risk-scorer:scaffold-register` skill (over-engineered for Phase 1; symmetric with `scaffold-intake` but lacks the install-time trigger), embedding inside `/wr-risk-scorer:create-risk` (conflates two surfaces and still leaves the 99% miss rate). Full options table: ADR-047 § Considered Options.

### Trigger contract (Step 6.5 detail)

Per sibling project enumerated in Step 3 (and the current project as implicit sibling per ADR-004):

1. **Detect** `<sibling>/RISK-POLICY.md` (file-existence test).
2. **Detect** `<sibling>/docs/risks/` (directory-existence test).
3. **Trigger condition**: `RISK-POLICY.md` present AND `docs/risks/` absent.
4. **Action**: scaffold `docs/risks/README.md` and `docs/risks/TEMPLATE.md` from this repo's templates at `scripts/repo-local-skills/install-updates/templates/risk-register-{README,TEMPLATE}.md.tmpl`.
5. **No substitution tokens** in v1 — templates are project-agnostic. Adopters fill in their own register entries; the scaffold provides only the shell.
6. **Idempotency**: per-file `create-if-absent`. If `README.md` exists but `TEMPLATE.md` does not (partial scaffold, e.g. user deleted one), only the missing file is written. Existing files are NEVER overwritten.

### Idempotency rationale (no marker)

Unlike `scaffold-intake` (ADR-036) which writes `.claude/.intake-scaffold-done`, this scaffold deliberately **omits a marker file**. The scaffolded files themselves serve as the "done" signal — file-existence is the marker. This is simpler than marker management because:

- No marker TTL to manage.
- No marker-vs-file drift (where the marker says "done" but a file has been deleted).
- Decline path is trivial — adopters who don't want the scaffold delete `docs/risks/README.md`; the next install-updates run re-scaffolds. If that proves a pain point, a `.claude/.risk-register-scaffold-declined` marker can be added paralleling ADR-036, but only when evidence demands it.

The intake scaffold needs a marker because it's interactive (an explicit decline path); this scaffold has no interactive gate, so the marker has no decision content.

### ADR-013 Rule 5 / Rule 6 audit

| Branch | Resolution |
|---|---|
| Cache-hit / cache-miss with consent granted (Rule 5) | Scaffold fires silently. Existence of `RISK-POLICY.md` plus prior consent IS the policy authorisation. Logged in the final report's scaffold rows. |
| Non-interactive subagent invocation (Rule 6) | Scaffold does NOT fire. Same fail-safe as the install path: dry-run table only; user must re-run interactively. The scaffold trigger inherits the consent gate's interactivity requirement. |
| Sibling consent answer was "Current project only" | Scaffold fires for current project only. Other siblings are skipped (consent boundary respected). |
| Dry-run consent answers | Do NOT scaffold. Dry-run is read-only by contract. |

### Template source-of-truth

Templates colocate at `scripts/repo-local-skills/install-updates/templates/`:

- `risk-register-README.md.tmpl` — adopter-flavoured copy of this repo's `docs/risks/README.md`. Empty register/retired tables. ISO mapping section preserved. Structural diagram preserved. "How to add" instructions citing `TEMPLATE.md`. NO "Last reviewed" date in the scaffolded copy (adopters set their own). NO R001 row (this repo's R001 is project-specific).
- `risk-register-TEMPLATE.md.tmpl` — verbatim copy of this repo's `docs/risks/TEMPLATE.md`. Risk-file shape (Status, Category, Inherent, Controls, Residual, Treatment, Monitoring, Related, Change Log).

Templates read at install-updates runtime from THIS repo's working tree (the install-updates skill is repo-local; templates ship with it). Sibling adopters never read the templates directly.

### Template drift

Mirror of ADR-036's same flag: when this repo's `docs/risks/README.md` evolves (e.g. ISO mapping table grows), scaffolded adopter copies stay frozen at the version they were scaffolded with. Mitigation: future re-scaffold path or scaffold-version metadata. Not blocking for Phase 1; the bats fixture includes a "verbatim copy of TEMPLATE.md" assertion that catches the most common drift case (TEMPLATE.md in this repo evolving without the template being re-copied).

### Phase-1-only scope

This is the **scaffolding precondition** for the multi-phase P033 fix. Out of scope for Phase 1:

- **Phase 2** — `wr-risk-scorer:pipeline` agent writes/updates `docs/risks/R<NNN>-*.active.md` entries when reports identify register-worthy risks. The load-bearing fix per user direction; deferred follow-up.
- **Phase 3** — one-time backfill pass over each adopter's existing `.risk-reports/*.md` to identify distinct risks and create register entries.
- **Phase 4** — behavioural contract test that every risk-id in `.risk-reports/*.md` has a matching `docs/risks/R<NNN>-*.md` entry.

Phase 1 ships scaffolding without the back-channel; the directory exists but is empty. The user could read this as "still broken" if Phase 2 doesn't ship promptly. P033 ticket body explicitly enumerates Phase 2 as the load-bearing follow-up.

## Not in scope (deliberately)

- Updating non-windyroad plugins (`anthropics/skill-creator`, `claude-plugins-official`). Out of scope.
- Restarting Claude Code. User restarts on their own cadence (P045 direction 2026-04-20).
- Global-scope installs (`--scope user`). ADR-004: project-scope only.
- Pruning obsolete plugins. If you uninstalled a plugin manually, this skill does nothing about it — it only re-installs what is currently enabled.

## ADR cross-references

- **ADR-030** — governing decision; Confirmation criteria apply here.
- **ADR-003** — marketplace distribution (Confirmation amended in the same commit as ADR-030 to permit this skill).
- **ADR-004** — project-scoped plugin install.
- **ADR-013 Rule 5 / Rule 6** — policy-authorised silent proceed (Step 6.5 cache-hit path) / non-interactive fallback pattern.
- **ADR-036** — direct precedent (downstream OSS intake scaffold). Step 6.5 applies the same shape to governance-artefact scaffolding (policy-file → directory pair).
- **ADR-038** — progressive disclosure for governance tooling context. This split implements the pattern at the SKILL.md level.
- **ADR-040** — SessionStart read-mostly contract (rationale for not putting the trigger in SessionStart).
- **ADR-047** — Step 6.5 governing decision (install-updates scaffolds governance artefacts).
- **P033** — driver ticket for Step 6.5 scaffold (no persistent risk register; Phase 1 lands here, Phases 2–4 deferred).
- **P045** — auto plugin install after governance release; interim manual stopgap.
- **P061** — sibling-count > 3 `AskUserQuestion` `maxItems` fallback.
- **P092** — `wr-` prefix mismatch between plugin name and npm package name.
- **P098** — SKILL+REFERENCE split pattern applied here.
- **P102** — invocation surface for risk register; sibling-in-fix to P033.
- **P110** — pipeline back-channel hint; Phase 2 consumer of Step 6.5's scaffolding output.
- **BRIEFING.md** — marketplace resolution semantics, version-string staleness, `plugin install` vs `plugin update` distinction.
