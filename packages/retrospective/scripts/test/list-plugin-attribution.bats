#!/usr/bin/env bats

# @problem P153 — Published skills enumerate repo-relative directories.
# `/wr-retrospective:analyze-context` SKILL.md L56-67 used a `for plugin_dir
# in packages/*/hooks; do ... done` glob loop that expanded to nothing in
# adopter trees, silently emitting zero PLUGIN-HOOKS / PLUGIN-SKILLS rows.
#
# Fix: extract the loop into a helper script that probes for the source-
# tree first (preserves dev-session output) and falls back to a `$PATH`-
# derived plugin-cache walk so adopter sessions resolve too. Same row
# shape; backward compatible with deep-layer SKILL.md Step 4 sum-check.
#
# Contract:
#   list-plugin-attribution.sh [<project-root>]
#
# Default project-root is the current working directory.
#
# Output (one line per row, terse machine-readable per ADR-038 ≤150 bytes):
#   PLUGIN-HOOKS <plugin> bytes=<N>
#   PLUGIN-SKILLS <plugin> bytes=<N>
#   PLUGIN-ATTRIBUTION not-measured reason=<reason>
#
# Exit code: 0 always (advisory, matches measure-context-budget.sh contract).
#
# Resolution order:
#   1. Source-tree mode — if `<project-root>/packages/*/hooks` glob expands
#      to anything, walk it. Same applies to `packages/*/skills`.
#   2. Cache-fallback mode — sniff `$PATH` entries that match
#      `*/cache/<owner>/<plugin>/<version>/bin`; walk back to each
#      plugin's root and emit the same row shape.
#   3. Neither — emit `PLUGIN-ATTRIBUTION not-measured
#      reason=no-plugin-source-resolvable`.
#
# @adr ADR-049 (Plugin-bundled scripts via `bin/` on `$PATH` —
#   reassessment-criteria clause 3 explicitly anticipates this surface)
# @adr ADR-038 (Progressive disclosure — per-row byte budget)
# @adr ADR-026 (Agent output grounding — explicit not-measured sentinels)
# @adr ADR-005 (Plugin testing strategy)
# @adr ADR-037 (Skill testing strategy — bats-contract precedent)
# @jtbd JTBD-301 (Plugin-user) / JTBD-101 (Plugin-developer)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/list-plugin-attribution.sh"
  FIXTURE_DIR="$(mktemp -d)"
  # Minimal PATH for bash + coreutils, but no plugin-cache bin dirs.
  # Tests that exercise cache-fallback explicitly prepend a synthetic
  # cache bin to this MIN_PATH.
  MIN_PATH="/usr/bin:/bin"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "list-plugin-attribution: script file exists at expected path" {
  [ -f "$SCRIPT" ]
}

@test "list-plugin-attribution: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Exit code ───────────────────────────────────────────────────────────────

@test "list-plugin-attribution: empty fixture exits 0 (advisory)" {
  # Run with an empty PATH so the cache-fallback yields nothing too.
  run env PATH="$MIN_PATH" bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
}

# ── Source-tree mode ────────────────────────────────────────────────────────

@test "list-plugin-attribution: source-tree mode emits PLUGIN-HOOKS row for packages/<plugin>/hooks" {
  mkdir -p "$FIXTURE_DIR/packages/foo/hooks"
  printf '%s' 'echo hi' > "$FIXTURE_DIR/packages/foo/hooks/h.sh"
  run env PATH="$MIN_PATH" bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^PLUGIN-HOOKS foo bytes=[0-9]+$'
}

@test "list-plugin-attribution: source-tree mode emits PLUGIN-SKILLS row for packages/<plugin>/skills" {
  mkdir -p "$FIXTURE_DIR/packages/foo/skills/wizard"
  printf '%s' '# Wizard' > "$FIXTURE_DIR/packages/foo/skills/wizard/SKILL.md"
  run env PATH="$MIN_PATH" bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^PLUGIN-SKILLS foo bytes=[0-9]+$'
}

@test "list-plugin-attribution: source-tree mode reports nonzero hook bytes when files present" {
  mkdir -p "$FIXTURE_DIR/packages/foo/hooks"
  printf '%s' 'echo hi' > "$FIXTURE_DIR/packages/foo/hooks/h.sh"   # 7 bytes
  run env PATH="$MIN_PATH" bash "$SCRIPT" "$FIXTURE_DIR"
  bytes=$(echo "$output" | awk '/^PLUGIN-HOOKS foo bytes=/{ split($3, a, "="); print a[2] }')
  [ "${bytes:-0}" -gt 0 ]
}

@test "list-plugin-attribution: source-tree mode emits one row per plugin (multi-plugin)" {
  mkdir -p "$FIXTURE_DIR/packages/foo/hooks" "$FIXTURE_DIR/packages/bar/hooks"
  printf 'x' > "$FIXTURE_DIR/packages/foo/hooks/h.sh"
  printf 'x' > "$FIXTURE_DIR/packages/bar/hooks/h.sh"
  run env PATH="$MIN_PATH" bash "$SCRIPT" "$FIXTURE_DIR"
  echo "$output" | grep -qE '^PLUGIN-HOOKS foo bytes='
  echo "$output" | grep -qE '^PLUGIN-HOOKS bar bytes='
}

# ── Cache-fallback mode ─────────────────────────────────────────────────────

@test "list-plugin-attribution: cache-fallback mode resolves plugins via PATH-derived bin dirs" {
  # Synthesise an adopter-shaped layout: ~/.claude/plugins/cache/<owner>/<plugin>/<version>/
  cache_root="$FIXTURE_DIR/.claude/plugins/cache/wroad/myplug/0.0.1"
  mkdir -p "$cache_root/bin" "$cache_root/hooks" "$cache_root/skills/s1"
  printf '%s' 'exec true' > "$cache_root/bin/wr-myplug-cmd"
  chmod +x "$cache_root/bin/wr-myplug-cmd"
  printf 'hook' > "$cache_root/hooks/h.sh"
  printf 'skill' > "$cache_root/skills/s1/SKILL.md"

  # CWD has no packages/ dir → forces cache-fallback path.
  empty_cwd="$FIXTURE_DIR/empty"
  mkdir -p "$empty_cwd"

  run env PATH="$cache_root/bin:$MIN_PATH" bash "$SCRIPT" "$empty_cwd"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^PLUGIN-HOOKS myplug bytes=[0-9]+$'
  echo "$output" | grep -qE '^PLUGIN-SKILLS myplug bytes=[0-9]+$'
}

# ── Neither source nor cache resolves ───────────────────────────────────────

@test "list-plugin-attribution: emits not-measured sentinel when nothing resolves" {
  # Empty fixture, empty PATH → zero source + zero cache.
  run env PATH="$MIN_PATH" bash "$SCRIPT" "$FIXTURE_DIR"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qE '^PLUGIN-ATTRIBUTION not-measured reason=no-plugin-source-resolvable$'
}

# ── Output budget ───────────────────────────────────────────────────────────

@test "list-plugin-attribution: every output row is under 150 bytes (ADR-038)" {
  mkdir -p "$FIXTURE_DIR/packages/foo/hooks" "$FIXTURE_DIR/packages/foo/skills/s1"
  printf 'x' > "$FIXTURE_DIR/packages/foo/hooks/h.sh"
  printf 'x' > "$FIXTURE_DIR/packages/foo/skills/s1/SKILL.md"
  run env PATH="$MIN_PATH" bash "$SCRIPT" "$FIXTURE_DIR"
  while IFS= read -r line; do
    [ "${#line}" -le 150 ]
  done <<< "$output"
}
