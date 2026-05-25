#!/usr/bin/env bats

# P259: the install-updates failure cascade gutted .claude/settings.json.
# `claude plugin uninstall` (the Step 4 P106 refresh workaround) immediately
# removes the plugin's enabledPlugins entry; if every install retry AND the
# marketplace-refresh rollback fail (e.g. a broken manifest already published —
# the 2026-05-18 P0), the plugin ends `lost` and is left absent from
# settings.json. The 2026-05-18 incident cut settings from 13 enabled plugins
# to 2. The fix: snapshot settings.json BEFORE the uninstall+install loop and,
# on a FINAL `lost` outcome for any plugin, restore the snapshot.
#
# Behavioural test (ADR-052): extracts `restore_settings_on_loss` from SKILL.md
# Step 4, sources it, and asserts the file-restore side-effects per scenario —
# restored on loss, untouched on no-loss, untouched when no snapshot exists,
# and (the load-bearing architectural claim) non-clobbering of same-run
# successes. Mirrors the extract-and-run pattern of
# install-updates-step-7-retry-rollback.bats.

# `run --separate-stderr` requires bats >= 1.5.0 (the project pins 1.13.0).
bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  SKILL_MD="$REPO_ROOT/.claude/skills/install-updates/SKILL.md"

  FN_FILE="$BATS_TEST_TMPDIR/restore-fn.sh"
  awk '
    /^restore_settings_on_loss\(\) \{/ { in_fn=1 }
    in_fn { print }
    in_fn && /^\}/ { exit }
  ' "$SKILL_MD" > "$FN_FILE"

  SNAPSHOT="$BATS_TEST_TMPDIR/settings-snapshot.json"
  SETTINGS="$BATS_TEST_TMPDIR/settings.json"
}

# Full pre-loop enablement state — three windyroad plugins enabled.
write_full_snapshot() {
  cat > "$SNAPSHOT" <<'JSON'
{
  "enabledPlugins": {
    "wr-itil@windyroad": true,
    "wr-retrospective@windyroad": true,
    "wr-tdd@windyroad": true
  }
}
JSON
}

@test "install-updates P259: restore fires on a lost plugin — gutted settings.json is restored from snapshot" {
  [ -s "$FN_FILE" ] || { echo "restore_settings_on_loss missing from SKILL.md"; return 1; }
  # shellcheck disable=SC1090
  source "$FN_FILE"

  write_full_snapshot
  # Simulate the cascade: the loop gutted settings down to nothing useful.
  printf '{\n  "enabledPlugins": {}\n}\n' > "$SETTINGS"

  # --separate-stderr: the function emits the result on stdout and a
  # transparency line on stderr; assert each on its own stream.
  run --separate-stderr restore_settings_on_loss "$SNAPSHOT" "$SETTINGS" "tdd"
  [ "$status" -eq 0 ]
  [ "$output" = "restored tdd" ]
  [[ "$stderr" == *"restored .claude/settings.json"* ]]

  # The gutted file is now byte-identical to the pre-loop snapshot.
  run diff "$SNAPSHOT" "$SETTINGS"
  [ "$status" -eq 0 ]
}

@test "install-updates P259: no lost plugins (zero trailing args) — settings.json left untouched, prints no-restore" {
  [ -s "$FN_FILE" ] || { echo "restore_settings_on_loss missing from SKILL.md"; return 1; }
  # shellcheck disable=SC1090
  source "$FN_FILE"

  write_full_snapshot
  printf 'CURRENT-STATE-UNTOUCHED\n' > "$SETTINGS"

  # Empty lost-array → zero trailing args (the routine no-loss call shape).
  run restore_settings_on_loss "$SNAPSHOT" "$SETTINGS"
  [ "$status" -eq 0 ]
  [ "$output" = "no-restore" ]

  # Settings must NOT have been overwritten when nothing was lost.
  run cat "$SETTINGS"
  [ "$output" = "CURRENT-STATE-UNTOUCHED" ]
}

@test "install-updates P259: lost plugin but no snapshot captured — defensive no-restore, settings untouched" {
  [ -s "$FN_FILE" ] || { echo "restore_settings_on_loss missing from SKILL.md"; return 1; }
  # shellcheck disable=SC1090
  source "$FN_FILE"

  printf 'CURRENT-STATE-UNTOUCHED\n' > "$SETTINGS"

  # Empty snapshot path (settings.json was absent pre-loop → no snapshot taken).
  # Must NOT clobber the current file with nothing.
  run restore_settings_on_loss "" "$SETTINGS" "tdd"
  [ "$status" -eq 0 ]
  [ "$output" = "no-restore" ]

  run cat "$SETTINGS"
  [ "$output" = "CURRENT-STATE-UNTOUCHED" ]
}

@test "install-updates P259: restore is non-clobbering — a same-run success survives alongside the re-added lost plugin" {
  # The load-bearing architectural claim: full-file restore is safe for plugins
  # that refreshed successfully in the SAME run, because enabledPlugins carries
  # no version pin (the version advance lives in the global cache, not in
  # settings.json), so a success's entry is byte-identical pre/post-loop.
  # Snapshot = {itil(success), retrospective(success), tdd}; the cascade then
  # left only itil before the loop ended with retrospective installed + tdd
  # lost. Restoring the snapshot must re-add tdd WITHOUT dropping the successes.
  [ -s "$FN_FILE" ] || { echo "restore_settings_on_loss missing from SKILL.md"; return 1; }
  # shellcheck disable=SC1090
  source "$FN_FILE"

  write_full_snapshot
  # Mid-cascade gutted state: only itil's entry survived in the live file.
  cat > "$SETTINGS" <<'JSON'
{
  "enabledPlugins": {
    "wr-itil@windyroad": true
  }
}
JSON

  run --separate-stderr restore_settings_on_loss "$SNAPSHOT" "$SETTINGS" "tdd"
  [ "$status" -eq 0 ]
  [ "$output" = "restored tdd" ]

  # All three plugins present after restore — the lost one re-added AND the
  # successfully-refreshed ones preserved (none regressed).
  run grep -c '@windyroad' "$SETTINGS"
  [ "$output" -eq 3 ]
  grep -q 'wr-itil@windyroad' "$SETTINGS"
  grep -q 'wr-retrospective@windyroad' "$SETTINGS"
  grep -q 'wr-tdd@windyroad' "$SETTINGS"
}

@test "install-updates P259: SKILL.md Step 4 snapshots settings.json BEFORE the install loop and restores AFTER" {
  # Ordering invariant: the snapshot `cp` must precede the `for plugin` loop and
  # the restore call must follow it — otherwise the snapshot captures
  # post-cascade (already-gutted) state, defeating the recovery.
  local step4
  step4=$(sed -n '/^### 4\. Install/,/^### /p' "$SKILL_MD")

  local snapshot_line loop_line restore_line
  snapshot_line=$(grep -nF 'cp "$SETTINGS_FILE" "$SETTINGS_SNAPSHOT"' <<< "$step4" | head -1 | cut -d: -f1)
  loop_line=$(grep -nF 'PROJECT_STATUS["$plugin"]=$(install_with_retry_rollback' <<< "$step4" | head -1 | cut -d: -f1)
  restore_line=$(grep -nF 'restore_settings_on_loss "$SETTINGS_SNAPSHOT"' <<< "$step4" | head -1 | cut -d: -f1)

  [ -n "$snapshot_line" ]
  [ -n "$loop_line" ]
  [ -n "$restore_line" ]
  [ "$snapshot_line" -lt "$loop_line" ]
  [ "$loop_line" -lt "$restore_line" ]
}
