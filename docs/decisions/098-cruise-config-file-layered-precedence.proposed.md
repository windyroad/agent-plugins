---
status: "proposed"
date: 2026-07-09
decision-makers: [Tom Howard]
consulted: [wr-architect:agent]
informed: []
reassessment-date: 2026-10-09
human-oversight: confirmed
oversight-date: 2026-07-10
---

# Cruise config file — layered precedence (project → machine → defaults)

## Context and Problem Statement

`@windyroad/cruise`'s knobs — `headroom_7d_pp` (default 5), `headroom_5h_pp` (default 0), the per-firing sleep cap (default 600s per P446 — the 60s Release-1 cap was too weak to converge), and a cache-path override — must be **configurable via a config file, not env vars** (user direction 2026-07-08: env vars are inconvenient — per-machine only, undiscoverable). The resolution direction is already decided by the user (2026-07-08): **project-root config → machine (`~/.claude/`) config → built-in defaults**, with env vars remaining as a final override that trumps the file (so CI / one-off overrides still work). This ADR settles the concrete SHAPE — chiefly the **file format** — so STORY-042's config work can be built (ADR-074: this ADR must be ratified first). Note: per ADR-097 there is **no self-install opt-out**, so the config file holds only the throttle knobs — no `self_install` key.

## Decision Drivers

- Configurable per-project AND per-machine (the env-var inconvenience the user flagged).
- Parseable by a shell hook (the throttle is a bash PreToolUse hook) **without sourcing untrusted shell** — a config file that gets `source`d is an arbitrary-code-execution surface.
- Adopter-portable — no parser dependency the plugin can't assume is present.
- Consistent, discoverable, and honest about precedence.

## Considered Options (the open choice: file format)

The precedence (project → machine → defaults, env last-override), the location (`.claude/cruise.config.json` in-project; `~/.claude/cruise.config.json` per-machine), and the key schema are settled by the drivers + prior user direction. The genuinely-open choice is the **format**:

1. **JSON** (`cruise.config.json`) — read with `jq` (already a plugin dependency); structured; never sourced, so no code-execution risk; adopter-portable.
2. **Shell `KEY=VALUE`** (sourced) — trivial for the bash hook to read, and matches the env-var mental model — but a sourced config file is an arbitrary-code-execution surface (any command in the file runs), which is unacceptable for a file that may live in a shared/project repo.
3. **TOML / YAML** — friendlier for hand-editing, but needs a parser (`yq` / a TOML reader) that is NOT already a dependency and isn't guaranteed on adopter machines.

## Decision Outcome

**Chosen: Option 1 — JSON**, because it is read with `jq` (already a dependency), is never sourced (no code-execution risk from a project-committed config), and is adopter-portable. Concretely:

- **Files:** in-project `.claude/cruise.config.json`; per-machine `~/.claude/cruise.config.json`.
- **Precedence:** a key set in the project file wins over the machine file, which wins over the built-in default; an env var (`WR_QUOTA_HEADROOM_7D_PP` / `_5H_PP` / `WR_QUOTA_THROTTLE_MAX_SLEEP` / `WR_QUOTA_CACHE_FILE`) trumps all of them (CI / emergency override).
- **Keys (all optional; each falls back through the layers):** `headroom_7d_pp` (int, default 5), `headroom_5h_pp` (int, default 0), `max_sleep_s` (int, default 600 — the sleep ceiling, under the 660s hook timeout; P446), `cache_path` (string, default `~/.claude/quota-state.json`).
- **Fail-open:** a missing / malformed / unreadable config file falls back to the next layer (ultimately built-in defaults) — the throttle never breaks on a bad config (consistent with ADR-093's fail-open envelope).

## Consequences

### Good
- Per-project + per-machine configurability with a clear precedence; no env-var inconvenience.
- No code-execution risk (JSON is parsed, never sourced) — safe to commit a project config.
- Uses `jq`, already required by the throttle.

### Neutral
- JSON is less pleasant to hand-edit than TOML; acceptable for a handful of numeric knobs.
- Two config locations + env override is a precedence rule to document clearly.

### Bad
- A per-firing `jq` read of up to two config files adds a little latency; mitigated by the existing recent-check no-op fast path (ADR-093) so it doesn't run on every call.

## Confirmation

Behavioural bats: project config overrides machine config overrides built-in default (per key); env var trumps both; missing/malformed config → fall through to defaults, throttle still runs (fail-open); a config file is never sourced (a shell metacharacter in a value cannot execute). Verified against STORY-042's config criterion before it transitions to done.

## Pros and Cons of the Options

### Option 1 — JSON (chosen)
- Good: `jq`-read (existing dep), never sourced (safe), portable, structured.
- Bad: less hand-editable than TOML for a numeric-knob file.

### Option 2 — Shell KEY=VALUE (sourced)
- Good: trivial for the bash hook; matches the env mental model.
- Bad: sourcing = arbitrary code execution from a possibly-shared config file. Rejected on security.

### Option 3 — TOML / YAML
- Good: friendliest to hand-edit.
- Bad: needs a parser not already a dependency; not guaranteed on adopter machines.

## Reassessment Criteria

Revisit if the knob set grows beyond simple scalars (nested structure would favour a richer format), or if `jq` is ever dropped as a dependency, or if adopters report the JSON hand-edit friction outweighs the security benefit.
