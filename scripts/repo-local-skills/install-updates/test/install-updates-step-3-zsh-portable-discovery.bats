#!/usr/bin/env bats

# P320: install-updates SKILL.md Step 3 discovery + version-compare loop
# must be zsh-portable. Three defect classes guarded here:
#   1. `for key in $CURRENT_PLUGINS` word-split — fails under zsh (P133);
#      Step 3 must use `while IFS= read -r` form.
#   2. zsh-reserved special variable names (`status`, `path`, `argv`,
#      `pipestatus`) must NOT be assigned inside the loop body — Step 3
#      prose must call them out.
#   3. `sort -V | tail -1` on the cache directory must be preceded by a
#      strict semver filter `grep -E '^[0-9]+\.[0-9]+\.[0-9]+$'` so
#      SHA-named git-source residual dirs (e.g. `2287c49f7b4b`) cannot
#      win the sort (the trap captured in
#      `feedback_verify_cache_refresh_by_version_dir`).
#
# Structural + behavioural mix follows the precedent set by
# install-updates-regex-matches-digits.bats (P058) per ADR-052 § Surface 2
# (structural is permitted for SKILL.md doc-lint when the load-bearing
# prose is what enforces the behaviour at runtime). The behavioural
# assertions exercise the snippets against synthetic fixtures.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/scripts/repo-local-skills/install-updates/SKILL.md"
}

@test "install-updates P320: SKILL.md exists" {
  [ -f "$SKILL_MD" ]
}

@test "install-updates P320: Step 3 uses 'while IFS= read -r' loop instead of 'for key in \$CURRENT_PLUGINS' (defect 1)" {
  # Positive guard — the P133-compliant loop must be present.
  grep -qE 'while IFS= read -r plugin_key' "$SKILL_MD"
}

@test "install-updates P320: Step 3 carries no regressed 'for key in \$CURRENT_PLUGINS' word-split outside prose-citation backticks (defect 1)" {
  # Negative guard — the broken zsh-unsafe pattern must not reappear as
  # executable bash. Lines where it appears in backticked prose (used to
  # explain what NOT to do) are exempt; we only block bare occurrences
  # (i.e. lines that DO NOT carry the backtick-wrapped citation).
  local count
  count=$(grep -E 'for [a-z_]+ in \$CURRENT_PLUGINS' "$SKILL_MD" | grep -cvE '`for [a-z_]+ in \$CURRENT_PLUGINS`' || true)
  [ "$count" = "0" ]
}

@test "install-updates P320: Step 3 prose enumerates zsh-reserved special variable names (defect 2)" {
  # Doc-lint guard — the prose paragraph must call out status / path /
  # argv / pipestatus so future authors know not to assign to them.
  grep -qE '\bstatus\b.*\bpath\b.*\bargv\b.*\bpipestatus\b' "$SKILL_MD" \
    || grep -qE '`status`.*`path`.*`argv`.*`pipestatus`' "$SKILL_MD"
}

@test "install-updates P320: Step 3 version-compare uses strict semver pre-filter before 'sort -V | tail -1' (defect 3)" {
  # Positive guard — the semver-filter regex must precede `sort -V`.
  # Multi-line grep via -Pz would need ripgrep; instead assert the
  # regex literal is present AND the surrounding sort -V | tail -1
  # snippet is present.
  grep -qE "grep -E '\^\[0-9\]\+\\\\\\.\[0-9\]\+\\\\\\.\[0-9\]\+\\\$'" "$SKILL_MD"
  grep -qE 'sort -V \| tail -1' "$SKILL_MD"
}

@test "install-updates P320: behavioural — semver pre-filter rejects SHA-named cache dirs" {
  # Build a synthetic cache dir containing both semver and SHA-residual
  # subdirs; assert the filter+sort returns the highest semver, NOT the
  # SHA dir. This is the exact trap in `feedback_verify_cache_refresh_by_version_dir`.
  local cache="$BATS_TEST_TMPDIR/cache/wr-itil"
  mkdir -p "$cache/0.8.3" "$cache/0.8.4" "$cache/0.10.0" "$cache/2287c49f7b4b"

  local highest
  highest=$(ls "$cache" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
  [ "$highest" = "0.10.0" ]

  # Sanity — without the filter, the SHA dir wins (the bug).
  local naive
  naive=$(ls "$cache" | grep -E '^[0-9]' | sort -V | tail -1)
  [ "$naive" = "2287c49f7b4b" ]
}

@test "install-updates P320: behavioural — 'while IFS= read -r' iterates per-line on newline-joined CURRENT_PLUGINS" {
  # Confirm the loop shape iterates exactly N times for an N-line blob
  # under bash. (zsh-specific behaviour is asserted indirectly: the
  # `while IFS= read -r` form is identical under bash and zsh; the bug
  # is unique to the `for X in $VAR` form under zsh's no-word-split
  # default. Running this under bash is sufficient to prove the form is
  # iteration-correct; the structural guards above prevent regression
  # to the zsh-broken shape.)
  CURRENT_PLUGINS=$(printf '%s\n' wr-itil wr-jtbd wr-tdd)

  local count=0
  while IFS= read -r plugin_key; do
    [ -z "$plugin_key" ] && continue
    count=$((count + 1))
  done < <(printf '%s\n' "$CURRENT_PLUGINS")

  [ "$count" = "3" ]
}
