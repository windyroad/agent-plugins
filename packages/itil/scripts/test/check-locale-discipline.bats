#!/usr/bin/env bats

# @problem P328 — BSD `grep` / `sed` / `awk` on macOS silently mis-process
# UTF-8 multi-byte characters (em-dash, smart quotes) without
# `LC_ALL=en_US.UTF-8` set. Lint detects unprotected invocations so the
# class of silent-wrong-result bugs can't reach the codebase undetected.
#
# Contract: `check-locale-discipline.sh [<repo-root>]` walks scripts under
# `packages/*/scripts/`, `packages/*/hooks/` (incl. nested `lib/`), and
# `packages/*/lib/`, then emits one WARN line per unprotected grep/sed/awk
# invocation. Default Phase 1 advisory exits 0; `WR_LOCALE_DISCIPLINE_WARN_ONLY=0`
# promotes to Phase 2 load-bearing (exit 1 on any violation).
#
# Behavioural fixture (ADR-052 default): every test exercises the script
# against a synthesised packages/ fixture tree containing known-state
# scripts. No grep of SKILL.md / agent prose / source content.
#
# @adr ADR-040 (advisory-then-load-bearing reusable pattern)
# @adr ADR-049 (plugin-bundled scripts; PATH shim)
# @adr ADR-052 (behavioural-tests-default — temp script with known violations)
# @adr ADR-080 (highest-version-wins shim wrapper)
# @adr ADR-005 (Plugin testing strategy — bats coverage)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down)
# @jtbd JTBD-101 (Extend the Suite with New Plugins)

setup() {
  SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SCRIPT="$SCRIPTS_DIR/check-locale-discipline.sh"
  FIXTURE_ROOT="$(mktemp -d)"
  mkdir -p "$FIXTURE_ROOT/packages/demo/scripts"
  mkdir -p "$FIXTURE_ROOT/packages/demo/hooks"
  mkdir -p "$FIXTURE_ROOT/packages/demo/hooks/lib"
  mkdir -p "$FIXTURE_ROOT/packages/demo/lib"
}

teardown() {
  rm -rf "$FIXTURE_ROOT"
}

# ── Existence + executable ──────────────────────────────────────────────────

@test "check-locale-discipline: script exists" {
  [ -f "$SCRIPT" ]
}

@test "check-locale-discipline: script is executable" {
  [ -x "$SCRIPT" ]
}

# ── Negative cases (violations expected) ────────────────────────────────────

@test "check-locale-discipline: grep without LC_ALL emits WARN and counts violation" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/raw-grep.sh" <<'EOF'
#!/usr/bin/env bash
grep -c '^### ' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]  # Phase 1 advisory
  echo "$output" | grep -E "WARN.*raw-grep.sh:2.*grep without preceding LC_ALL"
  echo "$output" | grep -E "1 violation"
}

@test "check-locale-discipline: sed without LC_ALL emits WARN" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/raw-sed.sh" <<'EOF'
#!/usr/bin/env bash
sed -n '/^### /p' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "WARN.*raw-sed.sh:2.*sed without preceding LC_ALL"
}

@test "check-locale-discipline: awk without LC_ALL emits WARN" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/raw-awk.sh" <<'EOF'
#!/usr/bin/env bash
awk '/^### /' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "WARN.*raw-awk.sh:2.*awk without preceding LC_ALL"
}

# ── Positive cases (file-wide protection — silent pass) ─────────────────────

@test "check-locale-discipline: file-wide export LC_ALL above grep — silent pass" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/protected.sh" <<'EOF'
#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8
grep -c '^### ' README.md
sed -n '/^### /p' README.md
awk '/^### /' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE "protected.sh.*WARN"
  echo "$output" | grep -E "clean"
}

@test "check-locale-discipline: inline LC_ALL= prefix on same line — silent pass" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/inline.sh" <<'EOF'
#!/usr/bin/env bash
LC_ALL=en_US.UTF-8 grep -c '^### ' README.md
LC_ALL=en_US.UTF-8 sed -n '/^### /p' README.md
LC_ALL=en_US.UTF-8 awk '/^### /' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE "inline.sh.*WARN"
}

# ── Edge cases ──────────────────────────────────────────────────────────────

@test "check-locale-discipline: multiple grep/sed/awk on one line — line is flagged" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/multi.sh" <<'EOF'
#!/usr/bin/env bash
grep -c '^### ' README.md | sed 's/ //g' | awk '{print $1}'
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  # At least one tool is reported; we don't over-specify the count.
  echo "$output" | grep -E "WARN.*multi.sh:2.*(grep|sed|awk) without preceding LC_ALL"
}

@test "check-locale-discipline: git grep is skipped" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/git-grep.sh" <<'EOF'
#!/usr/bin/env bash
git grep -nE 'pattern' -- '*.md'
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE "git-grep.sh.*WARN"
}

@test "check-locale-discipline: heredoc body containing grep is not flagged" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/heredoc.sh" <<'EOF'
#!/usr/bin/env bash
cat <<'INNER'
The way to do this is to run: grep '^### ' README.md
And then: sed -n '/^### /p'
INNER
echo "done"
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  # Heredoc body lines must NOT produce WARNs.
  ! echo "$output" | grep -qE "heredoc.sh:[34].*WARN"
}

@test "check-locale-discipline: comment-only line is not flagged" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/commented.sh" <<'EOF'
#!/usr/bin/env bash
# Future work: replace this awk with a sed | grep pipeline.
echo "no grep here"
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE "commented.sh.*WARN"
}

@test "check-locale-discipline: identifiers containing grep/sed/awk substrings are not flagged" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/identifiers.sh" <<'EOF'
#!/usr/bin/env bash
grep_helper="something"
result_from_sed=42
my_awkward_var="x"
echo "$grep_helper $result_from_sed $my_awkward_var"
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -qE "identifiers.sh.*WARN"
}

# ── Scope: hooks/ + lib/ + nested hooks/lib/ ────────────────────────────────

@test "check-locale-discipline: scans packages/*/hooks/ scripts" {
  cat > "$FIXTURE_ROOT/packages/demo/hooks/raw-grep-hook.sh" <<'EOF'
#!/usr/bin/env bash
grep -c '^### ' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "WARN.*hooks/raw-grep-hook.sh:2"
}

@test "check-locale-discipline: scans packages/*/hooks/lib/ scripts" {
  cat > "$FIXTURE_ROOT/packages/demo/hooks/lib/nested.sh" <<'EOF'
#!/usr/bin/env bash
awk '/^### /' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "WARN.*hooks/lib/nested.sh:2"
}

@test "check-locale-discipline: scans packages/*/lib/ scripts" {
  cat > "$FIXTURE_ROOT/packages/demo/lib/raw-sed-lib.sh" <<'EOF'
#!/usr/bin/env bash
sed -n '/^### /p' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "WARN.*lib/raw-sed-lib.sh:2"
}

# ── Phase 1 advisory vs Phase 2 load-bearing ────────────────────────────────

@test "check-locale-discipline: Phase 1 default exits 0 even with violations" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/violation.sh" <<'EOF'
#!/usr/bin/env bash
grep -c '^### ' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
}

@test "check-locale-discipline: Phase 2 load-bearing exits 1 on violations" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/violation.sh" <<'EOF'
#!/usr/bin/env bash
grep -c '^### ' README.md
EOF
  WR_LOCALE_DISCIPLINE_WARN_ONLY=0 run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 1 ]
}

@test "check-locale-discipline: Phase 2 load-bearing exits 0 on clean tree" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/clean.sh" <<'EOF'
#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8
grep -c '^### ' README.md
EOF
  WR_LOCALE_DISCIPLINE_WARN_ONLY=0 run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
}

# ── Argument and error handling ─────────────────────────────────────────────

@test "check-locale-discipline: missing repo-root directory exits 2" {
  run "$SCRIPT" "$FIXTURE_ROOT/does-not-exist"
  [ "$status" -eq 2 ]
  echo "$output" | grep -iE "not a directory"
}

@test "check-locale-discipline: repo-root without packages/ subdir exits 2" {
  mkdir -p "$FIXTURE_ROOT/empty"
  run "$SCRIPT" "$FIXTURE_ROOT/empty"
  [ "$status" -eq 2 ]
  echo "$output" | grep -iE "no packages/"
}

@test "check-locale-discipline: defaults to current working directory when no arg" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/violation.sh" <<'EOF'
#!/usr/bin/env bash
grep -c '^### ' README.md
EOF
  cd "$FIXTURE_ROOT"
  run "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "WARN.*scripts/violation.sh:2"
}

# ── Output shape ────────────────────────────────────────────────────────────

@test "check-locale-discipline: clean tree emits summary on stdout" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/clean.sh" <<'EOF'
#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8
grep -c '^### ' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "^check-locale-discipline: clean"
}

@test "check-locale-discipline: violation summary cites P328" {
  cat > "$FIXTURE_ROOT/packages/demo/scripts/violation.sh" <<'EOF'
#!/usr/bin/env bash
grep -c '^### ' README.md
EOF
  run "$SCRIPT" "$FIXTURE_ROOT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -E "P328"
}

# ── Self-application: lint script itself is locale-discipline-compliant ─────

@test "check-locale-discipline: own script declares export LC_ALL at top" {
  # The lint walks UTF-8 prose; it must lead by example. This guards
  # against a future edit that strips the export and reintroduces P328
  # in the lint itself.
  head -80 "$SCRIPT" | grep -qE "^export LC_ALL=en_US.UTF-8$"
}
