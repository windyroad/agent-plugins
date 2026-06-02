#!/usr/bin/env bats

# ADR-080 + ADR-017: drift guard for the shim-wrapper sync mechanism.
# Mirrors packages/shared/test/sync-derive-first-dispatch.bats — every
# packages/*/bin/wr-* shim must match the canonical template at
# packages/shared/lib/shim-wrapper-template.sh modulo __SCRIPT_NAME__
# substitution.
#
# @adr ADR-080 (highest-version-wins shim wrapper plugin scaffold)
# @adr ADR-017 (shared code duplicated into per-package — sync-script pattern)
# @adr ADR-052 (behavioural-by-default — exercises the sync script, not its source text)
# @problem P343 (mid-session staleness window)
# @jtbd JTBD-007 (Keep Plugins Current Across Projects)
# @jtbd JTBD-101 (extend the suite with consistent patterns)

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  SYNC_SCRIPT="$REPO_ROOT/scripts/sync-shim-wrappers.sh"
  TEMPLATE="$REPO_ROOT/packages/shared/lib/shim-wrapper-template.sh"
}

@test "sync-shim-wrappers: canonical template exists" {
  [ -f "$TEMPLATE" ]
}

@test "sync-shim-wrappers: sync script exists and is executable" {
  [ -x "$SYNC_SCRIPT" ]
}

@test "sync-shim-wrappers: at least one wr-<plugin>-* shim exists across packages/" {
  local count
  count=$(find "$REPO_ROOT/packages" -maxdepth 3 -type f -path '*/bin/wr-*' | wc -l | tr -d ' ')
  [ "$count" -ge 1 ]
}

@test "sync-shim-wrappers: --check passes on the repo's current shim tree (after sync)" {
  # This test asserts the post-iter state — after scripts/sync-shim-wrappers.sh
  # has run, --check must report clean. Run on the live tree.
  run bash "$SYNC_SCRIPT" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"OK:"* ]]
}

@test "sync-shim-wrappers: --check flags divergence when a shim is hand-edited" {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/packages/shared/lib" "$tmp/packages/fakepkg/bin" "$tmp/scripts"
  cp "$TEMPLATE" "$tmp/packages/shared/lib/shim-wrapper-template.sh"
  # Materialise a canonical shim from the template…
  sed "s|__SCRIPT_NAME__|fake-script|g" "$TEMPLATE" > "$tmp/packages/fakepkg/bin/wr-fakepkg-fake-script"
  chmod +x "$tmp/packages/fakepkg/bin/wr-fakepkg-fake-script"
  # …then diverge it.
  echo "# drift" >> "$tmp/packages/fakepkg/bin/wr-fakepkg-fake-script"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-shim-wrappers.sh"
  chmod +x "$tmp/scripts/sync-shim-wrappers.sh"

  run bash "$tmp/scripts/sync-shim-wrappers.sh" --check
  [ "$status" -ne 0 ]
  [[ "$output" == *"DIVERGED"* ]] || [[ "$output" == *"diverged"* ]]

  rm -rf "$tmp"
}

@test "sync-shim-wrappers: sync mode overwrites diverged shim from canonical" {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/packages/shared/lib" "$tmp/packages/fakepkg/bin" "$tmp/scripts"
  cp "$TEMPLATE" "$tmp/packages/shared/lib/shim-wrapper-template.sh"
  sed "s|__SCRIPT_NAME__|fake-script|g" "$TEMPLATE" > "$tmp/packages/fakepkg/bin/wr-fakepkg-fake-script"
  chmod +x "$tmp/packages/fakepkg/bin/wr-fakepkg-fake-script"
  echo "# drift" >> "$tmp/packages/fakepkg/bin/wr-fakepkg-fake-script"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-shim-wrappers.sh"
  chmod +x "$tmp/scripts/sync-shim-wrappers.sh"

  run bash "$tmp/scripts/sync-shim-wrappers.sh"
  [ "$status" -eq 0 ]

  # After sync the shim must match the freshly-materialised canonical.
  local expected
  expected=$(sed "s|__SCRIPT_NAME__|fake-script|g" "$tmp/packages/shared/lib/shim-wrapper-template.sh")
  [ "$(cat "$tmp/packages/fakepkg/bin/wr-fakepkg-fake-script")" = "$expected" ]

  rm -rf "$tmp"
}

@test "sync-shim-wrappers: unparseable shim causes non-zero exit (loud-failure principle)" {
  local tmp
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/packages/shared/lib" "$tmp/packages/fakepkg/bin" "$tmp/scripts"
  cp "$TEMPLATE" "$tmp/packages/shared/lib/shim-wrapper-template.sh"
  # Shim body with no recognisable scripts/<NAME>.sh exec line.
  cat > "$tmp/packages/fakepkg/bin/wr-fakepkg-broken" <<'EOF'
#!/usr/bin/env bash
# Intentionally unparseable — no scripts/ exec line.
echo "broken shim" >&2
exit 1
EOF
  chmod +x "$tmp/packages/fakepkg/bin/wr-fakepkg-broken"
  cp "$SYNC_SCRIPT" "$tmp/scripts/sync-shim-wrappers.sh"
  chmod +x "$tmp/scripts/sync-shim-wrappers.sh"

  # Redirect stderr → stdout so `$output` captures the loud-failure message.
  run bash -c "bash '$tmp/scripts/sync-shim-wrappers.sh' --check 2>&1"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot resolve script stem"* ]] || [[ "$output" == *"could not be parsed"* ]]

  rm -rf "$tmp"
}

@test "sync-shim-wrappers: skips non-wr-prefixed bin files (install.mjs, check-deps.sh)" {
  # In the live repo, packages/*/bin/install.mjs + packages/itil/bin/check-deps.sh
  # exist and are NOT ADR-049 shims. The sync script must skip them.
  run bash "$SYNC_SCRIPT" --check
  [ "$status" -eq 0 ]
  # If install.mjs / check-deps.sh were not skipped, the sync would attempt
  # to parse them and either fail (unparseable) or rewrite them with the
  # template (catastrophic regression). The OK status above proves they're
  # skipped via the find -path '*/bin/wr-*' filter.
  [[ "$output" == *"OK:"* ]]
}
