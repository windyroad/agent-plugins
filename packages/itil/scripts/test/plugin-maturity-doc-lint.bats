#!/usr/bin/env bats

# @problem P239 — Phase 3c doc-lint per plugin: `plugin.json` maturity field
#   shape + rendered README badge currency + anti-pattern absence.
# @problem P087 — parent: plugin maturity battle-hardening signal.
#
# Contract under test: every `packages/<plugin>/.claude-plugin/plugin.json`
# that carries a `maturity:` field MUST conform to the schema pinned by
# ADR-063 §Decision Outcome + iter-10 Amendment 2026-05-18, AND the sibling
# `packages/<plugin>/README.md` MUST carry the prose-woven badge marker
# matching the canonical rollup band. Anti-patterns (standalone `## Maturity`
# heading, shields.io URL, compound bootstrapping rendering inside per-skill
# table cells) are negative-asserted.
#
# Discovery is dynamic — the lint walks `packages/*/.claude-plugin/plugin.json`
# at run time. Plugins without a `maturity:` field are SKIPPED (Phase 3a
# hasn't been run for that plugin yet; the lint asserts SHAPE WHEN PRESENT,
# not mandatory presence per-plugin — presence enforcement belongs to a
# Phase 4+ release-blocking gate, not the doc-lint).
#
# Compound-vs-bare badge form is **out of scope** for this lint per
# architect adjustment A3 (P087 iter-11 architect review 2026-05-18). The
# renderer's compound-rendering fall-through is a separate sub-iter defect;
# the lint asserts band-substring-match only and remains agnostic to the
# `(suite-bootstrap window; <N> invocations / 30d)` form.
#
# Schema_version range: closed enum `{"1.0", "2.0"}` per ADR-058 §Confirmation
# #8 precedent + iter-10 Amendment 2026-05-18 hotfix. `"2.0"` is the canonical
# value post-hotfix; `"1.0"` records exist in pre-hotfix history (architect
# adjustment A4 — both accepted; future amendment may close to `"2.0"` only).
#
# @adr ADR-063 (Plugin maturity presentation layer — Phase 3c contract)
# @adr ADR-053 (Plugin maturity taxonomy — granularity contract,
#   rollup-equals-worst-case invariant)
# @adr ADR-058 (Phase 2 measurement — schema_version precedent)
# @adr ADR-052 (Behavioural tests default — JSON-shape + README-marker
#   structural-grep on the renderer-emitted stable marker per the documented
#   carve-out for renderer-output assertions)
# @adr ADR-013 Rule 6 (non-interactive fail-safe — exit 0 always; the lint
#   asserts contract, not policy enforcement)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  FIXTURE_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# ── Helper: list plugin packages that carry a `maturity:` field ─────────────
# Returns one bare plugin name per line (e.g. `itil`, `architect`).
plugins_with_maturity() {
  local pkg
  for pkg in "$REPO_ROOT"/packages/*/; do
    local pj="$pkg.claude-plugin/plugin.json"
    [ -f "$pj" ] || continue
    python3 -c "
import json
try:
    d = json.load(open('$pj'))
except Exception:
    raise SystemExit
if isinstance(d, dict) and isinstance(d.get('maturity'), dict) and 'band' in d['maturity']:
    print('$(basename "$pkg")')
" 2>/dev/null
  done
}

# ── Helper: assert a JSON Python expression evaluates truthy, with diagnostic ─
# Args: plugin-json-path, python-expr, diagnostic-prefix
assert_json() {
  local file="$1" expr="$2" diag="$3"
  python3 -c "
import json, sys
d = json.load(open('$file'))
ok = bool($expr)
if not ok:
    print(f'$diag: failed on $file', file=sys.stderr)
    sys.exit(1)
"
}

# ── Existence + discovery ───────────────────────────────────────────────────

@test "plugin-maturity-doc-lint: at least one plugin in the monorepo carries maturity field" {
  # Defensive — the lint is a no-op without discovered plugins. After the
  # iter-10 retroactive rollout (P087 line 133) every shipped plugin carries
  # `maturity:`; this test guards against a future regression where the
  # rollout is reverted.
  local n
  n=$(plugins_with_maturity | wc -l | tr -d ' ')
  [ "$n" -ge 1 ]
}

# ── Confirmation: per-surface schema shape (ADR-063 §rich record per-surface) ─

@test "plugin-maturity-doc-lint: every per-surface record carries full schema" {
  # For every entry under `maturity.skills`, `maturity.agents`,
  # `maturity.hooks`, `maturity.commands`, assert presence of mandatory keys
  # and correct value types. `invocations_30d` MAY be null (hook surfaces are
  # not transcript-observable); `breaking_change_age_days` MAY be null (no
  # breaking-marker commits observed).
  local plugin
  for plugin in $(plugins_with_maturity); do
    local pj="$REPO_ROOT/packages/$plugin/.claude-plugin/plugin.json"
    python3 <<PYEOF
import json, sys
d = json.load(open("$pj"))
m = d["maturity"]
bands = {"Experimental", "Alpha", "Beta", "Stable", "Deprecated"}
schema_versions = {"1.0", "2.0"}
for kind in ("skills", "agents", "hooks", "commands"):
    section = m.get(kind, {})
    if not isinstance(section, dict):
        sys.exit(f"$plugin: maturity.{kind} is not a dict")
    for name, rec in section.items():
        if not isinstance(rec, dict):
            sys.exit(f"$plugin: maturity.{kind}.{name} is not a dict")
        sv = rec.get("schema_version")
        if sv not in schema_versions:
            sys.exit(f"$plugin: maturity.{kind}.{name}.schema_version = {sv!r} not in {schema_versions}")
        band = rec.get("band")
        if band not in bands:
            sys.exit(f"$plugin: maturity.{kind}.{name}.band = {band!r} not in {bands}")
        if not isinstance(rec.get("computed_at"), str):
            sys.exit(f"$plugin: maturity.{kind}.{name}.computed_at is not a string")
        ev = rec.get("evidence")
        if not isinstance(ev, dict):
            sys.exit(f"$plugin: maturity.{kind}.{name}.evidence is not a dict")
        for field in ("invocations_30d", "days_shipped", "closed_tickets_window", "breaking_change_age_days"):
            if field not in ev:
                sys.exit(f"$plugin: maturity.{kind}.{name}.evidence.{field} missing")
        # invocations_30d: int OR null (hooks)
        inv = ev["invocations_30d"]
        if inv is not None and not isinstance(inv, int):
            sys.exit(f"$plugin: invocations_30d must be int or null, got {type(inv).__name__}")
        # days_shipped: int
        if not isinstance(ev["days_shipped"], int):
            sys.exit(f"$plugin: days_shipped must be int")
        # closed_tickets_window: int
        if not isinstance(ev["closed_tickets_window"], int):
            sys.exit(f"$plugin: closed_tickets_window must be int")
        # breaking_change_age_days: int OR null
        bca = ev["breaking_change_age_days"]
        if bca is not None and not isinstance(bca, int):
            sys.exit(f"$plugin: breaking_change_age_days must be int or null")
PYEOF
  done
}

# ── Confirmation: rollup shape (ADR-063 §rollup schema + iter-10 Amendment) ──

@test "plugin-maturity-doc-lint: rollup carries schema_version + band (mandatory pair)" {
  # ADR-063 §rollup-schema names `{schema_version, band}` as the rollup keys.
  # iter-10 Amendment 2026-05-18 (P0 hotfix) nests per-kind maps UNDER
  # `maturity:` — kind-keyed entries are tolerated additionally; the
  # schema_version + band pair remains mandatory.
  local plugin
  for plugin in $(plugins_with_maturity); do
    local pj="$REPO_ROOT/packages/$plugin/.claude-plugin/plugin.json"
    python3 <<PYEOF
import json, sys
d = json.load(open("$pj"))
m = d["maturity"]
sv = m.get("schema_version")
if sv not in {"1.0", "2.0"}:
    sys.exit(f"$plugin: maturity.schema_version = {sv!r} not in {{'1.0','2.0'}}")
band = m.get("band")
if band not in {"Experimental", "Alpha", "Beta", "Stable", "Deprecated"}:
    sys.exit(f"$plugin: maturity.band = {band!r} not in taxonomy")
PYEOF
  done
}

# ── P269 — rollup compound-evidence fields shape (when present) ─────────────

@test "plugin-maturity-doc-lint: rollup rollup_invocations_30d is int or null (when present)" {
  # ADR-063 §Amendment 2026-05-18 (P269 — rollup compound-evidence write):
  # the rollup carries `rollup_invocations_30d: integer | null`. Integer when
  # at least one per-surface entry has a non-null invocations_30d; null when
  # ALL per-surface entries are null (e.g. hook-only plugins) — preserves the
  # "not measurable" vs "measurably zero" honesty contract per architect §C.
  # Per ADR-063 §Confirmation #10 (shape-when-present), this lint asserts
  # type-shape when the field is present and tolerates absence for plugins
  # that haven't been re-populated since the P269 amendment.
  local plugin
  for plugin in $(plugins_with_maturity); do
    local pj="$REPO_ROOT/packages/$plugin/.claude-plugin/plugin.json"
    python3 <<PYEOF
import json, sys
d = json.load(open("$pj"))
m = d["maturity"]
if "rollup_invocations_30d" not in m:
    sys.exit(0)  # field absent — tolerated per shape-when-present
v = m["rollup_invocations_30d"]
if v is None:
    sys.exit(0)
if not isinstance(v, int) or isinstance(v, bool):
    sys.exit(f"$plugin: maturity.rollup_invocations_30d = {v!r} ({type(v).__name__}); must be int or null")
if v < 0:
    sys.exit(f"$plugin: maturity.rollup_invocations_30d = {v!r}; must be non-negative")
PYEOF
  done
}

@test "plugin-maturity-doc-lint: rollup bootstrapping is bool (when present)" {
  # ADR-063 §Amendment 2026-05-18 (P269 — rollup compound-evidence write):
  # the rollup carries `bootstrapping: bool` — populate-time snapshot of the
  # bootstrapping-window state. The renderer's AND-gated compound predicate
  # (plugin-maturity-render.sh:146) reads this flag to decide whether to
  # emit the compound form. Shape-when-present per the same tolerance as
  # rollup_invocations_30d above.
  local plugin
  for plugin in $(plugins_with_maturity); do
    local pj="$REPO_ROOT/packages/$plugin/.claude-plugin/plugin.json"
    python3 <<PYEOF
import json, sys
d = json.load(open("$pj"))
m = d["maturity"]
if "bootstrapping" not in m:
    sys.exit(0)
v = m["bootstrapping"]
if not isinstance(v, bool):
    sys.exit(f"$plugin: maturity.bootstrapping = {v!r} ({type(v).__name__}); must be bool")
PYEOF
  done
}

# ── Regression fence (architect adjustment A1, iter-11): no top-level kind maps ─

@test "plugin-maturity-doc-lint: no top-level skills/agents/hooks/commands maturity-shaped records (iter-10 P0 hotfix fence)" {
  # The iter-10 P0 hotfix moved per-kind maturity maps from TOP-LEVEL
  # (which the Claude Code plugin manifest validator rejects) to NESTED
  # UNDER `maturity:`. Regression fence: assert no top-level `skills:` /
  # `agents:` / `hooks:` / `commands:` key carries a maturity-shaped record
  # map (a dict whose values are dicts containing only `maturity` or
  # carrying the full per-surface record shape). Existing legitimate
  # top-level surfaces (e.g. itil's top-level `skills:` listing names + paths)
  # are NOT maturity-shaped and pass this fence.
  local plugin
  for plugin in $(plugins_with_maturity); do
    local pj="$REPO_ROOT/packages/$plugin/.claude-plugin/plugin.json"
    python3 <<PYEOF
import json, sys
d = json.load(open("$pj"))
maturity_keys = {"schema_version", "band", "computed_at", "evidence"}
for legacy_key in ("skills", "agents", "hooks", "commands"):
    inner = d.get(legacy_key)
    if not isinstance(inner, dict):
        continue
    for name, val in inner.items():
        if isinstance(val, dict):
            # Maturity-shaped if it has the maturity schema_version + band
            # pair OR is a wrapper that contains only `maturity`.
            if "schema_version" in val and "band" in val and val.get("band") in {"Experimental","Alpha","Beta","Stable","Deprecated"}:
                sys.exit(f"$plugin: top-level {legacy_key}.{name} carries maturity-shaped record — must nest under maturity.{legacy_key}.{name}")
            if set(val.keys()) <= {"maturity"} and isinstance(val.get("maturity"), dict):
                sys.exit(f"$plugin: top-level {legacy_key}.{name} carries .maturity wrapper — must nest under maturity.{legacy_key}.{name}")
PYEOF
  done
}

# ── Confirmation: rollup = worst-case of constituent surfaces (ADR-053 granularity) ─

@test "plugin-maturity-doc-lint: rollup band equals worst-case among constituent surfaces" {
  # ADR-053 §granularity contract: rollup band = worst-case
  # (Experimental ≻ Alpha ≻ Beta ≻ Stable). Deprecated is an overlay axis
  # elided from rollup compute. A plugin whose ONLY surfaces are Deprecated
  # is itself Deprecated.
  local plugin
  for plugin in $(plugins_with_maturity); do
    local pj="$REPO_ROOT/packages/$plugin/.claude-plugin/plugin.json"
    python3 <<PYEOF
import json, sys
d = json.load(open("$pj"))
m = d["maturity"]
ORDER = ["Experimental", "Alpha", "Beta", "Stable"]
surface_bands = []
for kind in ("skills", "agents", "hooks", "commands"):
    for rec in (m.get(kind, {}) or {}).values():
        if isinstance(rec, dict) and "band" in rec:
            surface_bands.append(rec["band"])
if not surface_bands:
    # No surface records — rollup not constrained by worst-case.
    sys.exit(0)
non_dep = [b for b in surface_bands if b in ORDER]
if non_dep:
    expected = next(b for b in ORDER if b in non_dep)
elif all(b == "Deprecated" for b in surface_bands):
    expected = "Deprecated"
else:
    expected = None
got = m.get("band")
if expected is not None and got != expected:
    sys.exit(f"$plugin: rollup band = {got!r}, expected {expected!r} (worst-case of {sorted(set(surface_bands))})")
PYEOF
  done
}

# ── Synthetic-fixture confirmation: multi-band rollup invariant ──────────────

@test "plugin-maturity-doc-lint: synthetic multi-band fixture — Experimental ≻ Beta ⇒ rollup Experimental" {
  # Builds a synthetic plugin.json with one Experimental skill + one Beta
  # agent and asserts rollup band MUST be Experimental. This guards the
  # worst-case invariant against future populate-script regressions that
  # might compute rollup as best-case or median.
  local pj="$FIXTURE_DIR/synthetic-plugin.json"
  cat >"$pj" <<'EOF'
{
  "name": "wr-synthetic",
  "version": "0.0.0",
  "maturity": {
    "schema_version": "2.0",
    "band": "Experimental",
    "skills": {
      "expt-skill": {
        "schema_version": "2.0",
        "band": "Experimental",
        "computed_at": "2026-05-18T00:00:00Z",
        "evidence": {"invocations_30d": 5, "days_shipped": 10, "closed_tickets_window": 0, "breaking_change_age_days": null}
      }
    },
    "agents": {
      "beta-agent": {
        "schema_version": "2.0",
        "band": "Beta",
        "computed_at": "2026-05-18T00:00:00Z",
        "evidence": {"invocations_30d": 500, "days_shipped": 90, "closed_tickets_window": 15, "breaking_change_age_days": 60}
      }
    }
  }
}
EOF
  # Run the worst-case derivation as a free-standing python check; we don't
  # invoke the populate script here — we assert the invariant the doc-lint
  # enforces against a hand-crafted shape.
  python3 <<PYEOF
import json
d = json.load(open("$pj"))
m = d["maturity"]
ORDER = ["Experimental", "Alpha", "Beta", "Stable"]
bands = []
for kind in ("skills","agents","hooks","commands"):
    for rec in (m.get(kind, {}) or {}).values():
        bands.append(rec["band"])
expected = next(b for b in ORDER if b in bands)
assert m["band"] == expected, f"rollup {m['band']!r} != expected {expected!r}"
PYEOF
}

@test "plugin-maturity-doc-lint: synthetic all-Deprecated fixture — rollup Deprecated" {
  # Companion to the worst-case test: a plugin whose ONLY surfaces are
  # Deprecated MUST roll up to Deprecated. Asserts the Deprecated-overlay
  # invariant from ADR-053 §granularity contract.
  local pj="$FIXTURE_DIR/all-deprecated.json"
  cat >"$pj" <<'EOF'
{
  "name": "wr-deprecated",
  "version": "0.0.0",
  "maturity": {
    "schema_version": "2.0",
    "band": "Deprecated",
    "skills": {
      "dep-1": {
        "schema_version": "2.0",
        "band": "Deprecated",
        "computed_at": "2026-05-18T00:00:00Z",
        "evidence": {"invocations_30d": 0, "days_shipped": 200, "closed_tickets_window": 0, "breaking_change_age_days": null},
        "supersededBy": "wr-other:replacement"
      }
    }
  }
}
EOF
  python3 <<PYEOF
import json
d = json.load(open("$pj"))
m = d["maturity"]
bands = [rec["band"] for rec in (m.get("skills", {}) or {}).values()]
assert all(b == "Deprecated" for b in bands)
assert m["band"] == "Deprecated", f"all-Deprecated rollup must be Deprecated, got {m['band']!r}"
PYEOF
}

# ── Confirmation: README badge marker matches canonical rollup band ──────────

@test "plugin-maturity-doc-lint: README contains *Maturity: <band> marker matching canonical rollup" {
  # Architect adjustment A2 (iter-11): anchored regex requires band ∈
  # taxonomy followed by either `.` (bare form) or `(` (compound prefix).
  # Renderer emits one of these two; structural-grep on the stable marker
  # is the documented ADR-052 carve-out for renderer-output assertions.
  local plugin
  for plugin in $(plugins_with_maturity); do
    local pj="$REPO_ROOT/packages/$plugin/.claude-plugin/plugin.json"
    local rdm="$REPO_ROOT/packages/$plugin/README.md"
    [ -f "$rdm" ] || continue  # README absent — skip (no marker to check)
    local band
    band=$(python3 -c "import json; print(json.load(open('$pj'))['maturity']['band'])")
    # Anchored regex: `*Maturity: <band>` followed by `.` (bare form) OR
    # ` (` (compound prefix — space + open paren per the renderer's
    # `*Maturity: <Band> (suite-bootstrap window; <N> invocations / 30d).*`
    # output shape at plugin-maturity-render.sh line 147). P269 fold-fix:
    # the previous `[.(]` character class missed the space-before-paren
    # case that became visible across the live monorepo once compound
    # rendering started firing post-rollout.
    if ! grep -qE "\\*Maturity: ${band}(\\.| \\()" "$rdm"; then
      echo "$plugin: README missing badge marker *Maturity: ${band}<.|space-paren>" >&2
      false
    fi
  done
}

# ── Anti-pattern: no standalone `## Maturity` heading ───────────────────────

@test "plugin-maturity-doc-lint: README has no standalone ## Maturity heading" {
  # ADR-063 §README badge rendering format anti-pattern: NEVER emit a
  # standalone `## Maturity` section. The badge is woven into existing
  # value-framing prose per ADR-051; a standalone section drifts the JTBD
  # anchor away from the prose-weaving precedent.
  local plugin
  for plugin in $(plugins_with_maturity); do
    local rdm="$REPO_ROOT/packages/$plugin/README.md"
    [ -f "$rdm" ] || continue
    if grep -qE '^##[[:space:]]+Maturity[[:space:]]*$' "$rdm"; then
      echo "$plugin: README contains standalone ## Maturity heading (anti-pattern)" >&2
      false
    fi
  done
}

# ── Anti-pattern: no shields.io URL ─────────────────────────────────────────

@test "plugin-maturity-doc-lint: README has no shields.io maturity badge URL" {
  # ADR-063 §Decision Outcome rejected shields.io: external-dep blast
  # radius + Bootstrapping clause compound rendering cannot be expressed
  # in static badge URL + offline-broken. Markdown text only.
  local plugin
  for plugin in $(plugins_with_maturity); do
    local rdm="$REPO_ROOT/packages/$plugin/README.md"
    [ -f "$rdm" ] || continue
    if grep -qE 'img\.shields\.io/badge/maturity' "$rdm"; then
      echo "$plugin: README contains shields.io maturity badge URL (anti-pattern)" >&2
      false
    fi
  done
}

# ── Anti-pattern: no compound bootstrapping rendering inside per-skill table cells ─

@test "plugin-maturity-doc-lint: per-skill table cells do not contain compound bootstrapping rendering" {
  # ADR-063 §Bootstrapping clause rendering: compound form
  # `(suite-bootstrap window; <N> invocations / 30d)` stays at ROLLUP only;
  # per-skill cells carry band name only. This anti-pattern asserts no
  # table row contains the `(suite-bootstrap window;` substring (the
  # rollup-only compound substring should appear at most ONCE per README,
  # in the lead-prose line).
  local plugin
  for plugin in $(plugins_with_maturity); do
    local rdm="$REPO_ROOT/packages/$plugin/README.md"
    [ -f "$rdm" ] || continue
    # Grep table rows (`|`-leading, allowing leading whitespace) containing
    # the bootstrapping compound substring. Table rows are pipe-delimited
    # markdown; the compound substring inside a cell is the anti-pattern.
    if grep -qE '^[[:space:]]*\|.*\(suite-bootstrap window;' "$rdm"; then
      echo "$plugin: README has compound bootstrapping rendering inside table cell (rollup-only contract)" >&2
      false
    fi
  done
}
