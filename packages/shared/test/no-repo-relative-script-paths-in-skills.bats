#!/usr/bin/env bats
# P151 / ADR-049 Confirmation criterion 1.
# P153 / ADR-049 reassessment-criteria clause 3 (directory-enumeration extension).
#
# Behavioural grep-as-lint asserting no published packages/*/skills/*/SKILL.md
# contains a `bash <repo-relative-path>` invocation OR a repo-relative
# directory-enumeration glob loop as a load-bearing dispatch.
#
# The driver: published SKILL.md prose is read by adopter agents and dispatched
# via the Bash tool from the adopter's project root. Repo-relative paths
# (`packages/<plugin>/scripts/<name>.sh`) do not resolve in adopter trees, so
# the bash command exits 127 with `No such file or directory` and the SKILL.md
# control flow halts before the skill produces any user value (P151 — hard-
# fail). The sibling failure mode is repo-relative directory enumeration
# (`for d in packages/*/hooks; do ... done`), where the glob expands to
# nothing in adopter trees and the loop body silently never executes,
# emitting zero attribution rows with no error signal (P153 — silent zero-
# byte degradation). Both leak windyroad-internal monorepo layout assumptions
# through the published plugin boundary.
#
# ADR-049 normative rule: plugin-bundled scripts invoked from SKILL.md MUST
# resolve via `bin/` on `$PATH` (e.g. `wr-itil-reconcile-readme`), never via
# repo-relative paths. ADR-049 reassessment-criteria clause 3 explicitly
# anticipates extension to directory traversals — implemented in the third
# @test below. Tests fail CI on regression.
#
# Cross-plugin scope (matches sibling `packages/shared/test/external-comms-gate-canonical.bats`
# and `plugin-manifest-sync.bats` precedent for cross-cutting published-skill contract tests).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
}

@test "no published SKILL.md contains 'bash packages/<plugin>/scripts/<name>.<ext>' (P151 / ADR-049)" {
  # Pattern matches `bash packages/<plugin>/scripts/<name>.{sh,py,bats,js,ts}`
  # at any indent level. Captures the load-bearing dispatch surface only —
  # patterns inside fenced code blocks that document the failure mode would
  # also match (and that is acceptable: even literary references to the
  # repo-relative path are confusing for adopter agents and should be replaced
  # with the bin-wrapper name per ADR-049 Confirmation criterion 4).
  local hits
  hits=$(grep -rnE 'bash +packages/[a-z][a-z0-9-]*/(scripts|hooks)/[a-z0-9-]+\.(sh|py|bats|js|ts)' \
    "$REPO_ROOT"/packages/*/skills/*/SKILL.md 2>/dev/null || true)

  if [ -n "$hits" ]; then
    echo "ADR-049 violation — repo-relative script invocation found in published SKILL.md:"
    echo "$hits"
    echo ""
    echo "Replace each match with the bin-wrapper name per ADR-049 naming grammar:"
    echo "  bash packages/<plugin>/scripts/<name>.sh ARG"
    echo "  → wr-<plugin>-<kebab-name> ARG"
    echo ""
    echo "Add the shim wrapper at packages/<plugin>/bin/wr-<plugin>-<kebab-name>"
    echo "with body: exec \"\$(dirname \"\$0\")/../scripts/<name>.sh\" \"\$@\""
    return 1
  fi
}

@test "no published SKILL.md contains 'bash packages/<plugin>/hooks/<name>.<ext>' (P151 / ADR-049)" {
  # Matched by the same regex as the first test, but expressed as a separate
  # @test block so the failure surface names which directory class regressed
  # (scripts/ vs hooks/). Hooks are a different invocation class than scripts —
  # hooks are Claude Code runtime callouts, not adopter-agent dispatches — but
  # if a SKILL.md ever invokes a hook directly, the same plugin-boundary rule
  # applies.
  local hits
  hits=$(grep -rnE 'bash +packages/[a-z][a-z0-9-]*/hooks/[a-z0-9-]+\.(sh|py|bats|js|ts)' \
    "$REPO_ROOT"/packages/*/skills/*/SKILL.md 2>/dev/null || true)

  if [ -n "$hits" ]; then
    echo "ADR-049 violation — repo-relative hook invocation found in published SKILL.md:"
    echo "$hits"
    return 1
  fi
}

@test "no published SKILL.md contains 'for X in packages/<plugin>/<subdir>; do ...' directory-enumeration loop (P153 / ADR-049)" {
  # Pattern matches `for <var> in packages/<plugin-or-glob>/<subdir>; do ...`
  # at any indent level. Captures the load-bearing directory-traversal surface
  # — the glob expands to nothing in adopter trees, so the loop body silently
  # never executes (silent zero-byte degradation, distinct from P151's hard-
  # fail). Replace with a `bin/`-resolved helper that walks plugins via either
  # source-tree (when packages/ exists) or $PATH-derived plugin-cache fallback.
  #
  # The pattern intentionally accepts both literal plugin names
  # (`packages/itil/hooks`) and glob forms (`packages/*/hooks`,
  # `packages/[a-z]*/scripts`). Subdir component is restricted to the four
  # canonical plugin-internal directories (hooks, skills, scripts, bin) to
  # keep false-positive surface low. Pure literary references inside
  # commentary are also matched; per ADR-049 Confirmation criterion 4, even
  # literary references should use a bin-wrapper-grounded form to avoid
  # confusing adopter agents.
  local hits
  hits=$(grep -rnE 'for +[a-zA-Z_][a-zA-Z0-9_]* +in +packages/[a-z*][a-z0-9*-]*/(hooks|skills|scripts|bin)' \
    "$REPO_ROOT"/packages/*/skills/*/SKILL.md 2>/dev/null || true)

  if [ -n "$hits" ]; then
    echo "ADR-049 (reassessment clause 3) violation — repo-relative directory enumeration in published SKILL.md:"
    echo "$hits"
    echo ""
    echo "Replace each match with a bin/-resolved helper script per ADR-049 naming grammar."
    echo "Example fix shape (P153):"
    echo "  for plugin_dir in packages/*/hooks; do"
    echo "    plugin=\$(basename \"\$(dirname \"\$plugin_dir\")\")"
    echo "    ..."
    echo "  done"
    echo "  → wr-<plugin>-<kebab-name> [<project-root>]"
    echo ""
    echo "Add a canonical script under packages/<plugin>/scripts/<name>.sh that probes the"
    echo "source-tree first (preserves dev-session output), then falls back to a \$PATH-"
    echo "derived plugin-cache walk so adopter sessions resolve too. Add the shim wrapper"
    echo "at packages/<plugin>/bin/wr-<plugin>-<kebab-name>."
    return 1
  fi
}

@test "no published SKILL.md sources a repo-relative library at runtime (P317 / ADR-049 reassessment clause 3)" {
  # `source packages/<plugin>/.../*.sh` only resolves in the source monorepo;
  # in adopter installs the file does not exist, the source fails, and the
  # functions it would define are undefined (P317 — the create-gate marker
  # class: capture-problem / manage-problem / work-problems all sourced
  # packages/itil/{lib,hooks/lib}/*.sh inline). Line-anchored (`^[[:space:]]*source`)
  # so RUNTIME source lines match but inline instructional prose
  # ("NEVER `source packages/...`") does NOT. Fix: internalise the source+call
  # into a standalone command that resolves its sibling lib via
  # $(dirname "$0")/../{lib,hooks/lib} and is invoked by name (RFC-009 Option B/C).
  local hits
  hits=$(grep -rnE '^[[:space:]]*source +packages/[a-z][a-z0-9-]*/' \
    "$REPO_ROOT"/packages/*/skills/*/SKILL.md 2>/dev/null || true)
  if [ -n "$hits" ]; then
    echo "P317 / ADR-049 violation — repo-relative library source in published SKILL.md:"
    echo "$hits"
    echo ""
    echo "A SKILL cannot 'source packages/...': that path only exists in the source monorepo."
    echo "Internalise the source+call into a command that resolves its lib via"
    echo "\$(dirname \"\$0\")/../{lib,hooks/lib} and invoke it by name (ADR-049 shim):"
    echo "  source packages/<plugin>/lib/<x>.sh; <fn> ARG"
    echo "  → wr-<plugin>-<kebab-name> ARG   (the script does the source+call internally)"
    return 1
  fi
}

@test "no published SKILL.md uses a repo-relative '|| echo packages/...' path fallback (P317 / ADR-049)" {
  # The `\$(wr-...-path 2>/dev/null || echo packages/<plugin>/scripts)/x.sh` shape
  # assumes a path-resolver shim; when that shim is absent (it never shipped)
  # the repo-relative `|| echo packages/...` fallback ALWAYS fires and breaks in
  # adopter trees (P317 KIND B — 17 sites across the story/RFC skills). Call the
  # per-script bin shim by name instead (ADR-049 per-script exec-shim).
  local hits
  hits=$(grep -rnE '\|\| +echo +packages/[a-z][a-z0-9-]*/' \
    "$REPO_ROOT"/packages/*/skills/*/SKILL.md 2>/dev/null || true)
  if [ -n "$hits" ]; then
    echo "P317 / ADR-049 violation — repo-relative '|| echo packages/...' fallback in published SKILL.md:"
    echo "$hits"
    echo ""
    echo "Replace 'bash \"\$(wr-...-path || echo packages/<plugin>/scripts)/<x>.sh\" ARG'"
    echo "with the per-script bin shim called by name: wr-<plugin>-<kebab-name> ARG"
    return 1
  fi
}

@test "shim wrapper packages/itil/bin/wr-itil-reconcile-readme exists and is executable" {
  [ -x "$REPO_ROOT/packages/itil/bin/wr-itil-reconcile-readme" ]
}

@test "shim wrapper packages/itil/bin/wr-itil-check-problems-readme-budget exists and is executable" {
  [ -x "$REPO_ROOT/packages/itil/bin/wr-itil-check-problems-readme-budget" ]
}

@test "shim wrapper packages/itil/bin/wr-itil-classify-readme-drift exists and is executable (P149)" {
  [ -x "$REPO_ROOT/packages/itil/bin/wr-itil-classify-readme-drift" ]
}

@test "shim wrapper packages/retrospective/bin/wr-retrospective-measure-context-budget exists and is executable" {
  [ -x "$REPO_ROOT/packages/retrospective/bin/wr-retrospective-measure-context-budget" ]
}

@test "shim wrapper packages/retrospective/bin/wr-retrospective-list-plugin-attribution exists and is executable (P153)" {
  [ -x "$REPO_ROOT/packages/retrospective/bin/wr-retrospective-list-plugin-attribution" ]
}

@test "wr-itil-reconcile-readme shim resolves canonical script (smoke)" {
  # Drive the shim against a docs-equivalent path to verify the exec relay
  # works. The script is diagnose-only (exit 0 = clean, 1 = drift, 2 = parse
  # error) — any of those means the shim successfully dispatched the canonical
  # body. Exit 127 (the failure mode P151 closes) would mean the shim itself
  # didn't resolve.
  run "$REPO_ROOT/packages/itil/bin/wr-itil-reconcile-readme" "$REPO_ROOT/docs/problems"
  [ "$status" -ne 127 ]
}

@test "wr-itil-check-problems-readme-budget shim resolves canonical script (smoke)" {
  run "$REPO_ROOT/packages/itil/bin/wr-itil-check-problems-readme-budget" "$REPO_ROOT/docs/problems/README.md"
  [ "$status" -ne 127 ]
}

@test "wr-itil-classify-readme-drift shim resolves canonical script (smoke) (P149)" {
  # Script requires a drift-stdout file; passing nothing must hit the
  # USAGE / PARSE_ERROR branch (exit 2), NOT exit 127 which would mean
  # the shim itself didn't resolve.
  run "$REPO_ROOT/packages/itil/bin/wr-itil-classify-readme-drift"
  [ "$status" -ne 127 ]
  [ "$status" -eq 2 ]
}

@test "wr-retrospective-measure-context-budget shim resolves canonical script (smoke)" {
  run "$REPO_ROOT/packages/retrospective/bin/wr-retrospective-measure-context-budget" "$REPO_ROOT"
  [ "$status" -ne 127 ]
}

@test "wr-retrospective-list-plugin-attribution shim resolves canonical script (smoke) (P153)" {
  # Script is advisory only (always exits 0; emits PLUGIN-HOOKS / PLUGIN-SKILLS
  # rows or a PLUGIN-ATTRIBUTION not-measured sentinel). Exit 127 (the failure
  # mode P151 closes) would mean the shim itself didn't resolve.
  run "$REPO_ROOT/packages/retrospective/bin/wr-retrospective-list-plugin-attribution" "$REPO_ROOT"
  [ "$status" -ne 127 ]
}
