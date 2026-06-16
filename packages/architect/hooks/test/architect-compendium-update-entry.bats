#!/usr/bin/env bats

# Behavioural tests for architect-compendium-update-entry.sh (RFC-014 Story A,
# ADR-078 Phase 1 / Option 9). Exercises the hook against fixture compendium
# trees; asserts on its side-effects (README mutation, staging, exit code) and
# stderr signals — never on hook source content (feedback_behavioural_tests).
#
# The `claude -p` subprocess is stubbed with a PATH-priority fake-claude shim
# (RFC-014 SQ-014-1) that emits a fixed-shape `{"result": "<entry>"}` envelope
# for whichever ADR-ID appears in the prompt. Real-subprocess integration is
# out of scope for Phase 1.

setup() {
  HOOK="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/architect-compendium-update-entry.sh"
  PROJ="$(mktemp -d)"
  mkdir -p "$PROJ/docs/decisions"
  ( cd "$PROJ" && git init -q && git config user.email t@e.x && git config user.name t )

  # PATH-priority fake-claude shim: emits a {"result": "<entry>"} envelope with
  # an entry block for the ADR-ID found in the prompt. Marker text STUBBED-<id>
  # makes the emitted Decides line assertable.
  SHIMDIR="$(mktemp -d)"
  cat > "$SHIMDIR/claude" <<'SHIM'
#!/usr/bin/env bash
prompt=$(cat)
id=$(printf '%s' "$prompt" | grep -oE 'ADR-[0-9]+' | head -1 | sed 's/ADR-//')
entry="### ADR-${id} — Stub Title
**Status:** proposed | **Oversight:** confirmed
**Decides:** STUBBED-${id} decision body.
**Confirmation:** stub crit a; stub crit b
**Related:** ADR-001"
jq -cn --arg r "$entry" '{result:$r}'
SHIM
  chmod +x "$SHIMDIR/claude"

  # Failing shim variant: exits non-zero, emits nothing (degraded-mode tests).
  FAILSHIMDIR="$(mktemp -d)"
  cat > "$FAILSHIMDIR/claude" <<'SHIM'
#!/usr/bin/env bash
cat >/dev/null
exit 7
SHIM
  chmod +x "$FAILSHIMDIR/claude"

  ORIG_PATH="$PATH"
  export PATH="$SHIMDIR:$PATH"
}

teardown() {
  export PATH="$ORIG_PATH"
  rm -rf "$PROJ" "$SHIMDIR" "$FAILSHIMDIR"
}

# Writes a minimal compendium README with one in-force section (ADRs 003, 049,
# 051) and one historical section (ADR 010). Stable fixture for placement tests.
mk_readme() {
  cat > "$PROJ/docs/decisions/README.md" <<'EOF'
# Decisions Compendium

Intro prose.

---

## In-force decisions

_3 ADRs._

### ADR-003 — Three
**Status:** proposed | **Oversight:** confirmed
**Decides:** Decides three.

### ADR-049 — FortyNine
**Status:** accepted | **Oversight:** confirmed
**Decides:** Decides forty-nine.

### ADR-051 — FiftyOne
**Status:** proposed | **Oversight:** confirmed
**Decides:** Decides fifty-one.

---

## Historical decisions

_1 ADR._

### ADR-010 — Ten
**Status:** superseded | **Oversight:** confirmed
**Decides:** Decides ten.
EOF
}

# mk_adr <nnn> <status> <title>
mk_adr() {
  local nnn="$1" status="$2" title="$3"
  cat > "$PROJ/docs/decisions/${nnn}-slug.${status}.md" <<EOF
---
status: "$status"
date: 2026-06-09
human-oversight: confirmed
---

# $title

## Decision Outcome

Chosen option: **"$title impl"**, because reasons.

## Confirmation

- (a) first
- (b) second

## Related

- Relates to [ADR-001](001-foo.proposed.md)
EOF
  echo "$PROJ/docs/decisions/${nnn}-slug.${status}.md"
}

run_hook() {
  local fp="$1"
  echo "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$fp\"},\"session_id\":\"s1\"}" \
    | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK"
}

@test "fires on Edit to a numbered ADR body and refreshes its entry in-place (criterion 1+4)" {
  mk_readme
  fp=$(mk_adr "049" "accepted" "FortyNine")
  run run_hook "$fp"
  [ "$status" -eq 0 ]
  # In-place replacement: the entry now carries the stubbed Decides marker...
  grep -q 'STUBBED-049 decision body' "$PROJ/docs/decisions/README.md"
  # ...and there is exactly ONE ADR-049 header (no duplicate).
  [ "$(grep -c '^### ADR-049 ' "$PROJ/docs/decisions/README.md")" -eq 1 ]
}

@test "produces an observable stderr signal on every invocation (criterion 2)" {
  mk_readme
  fp=$(mk_adr "049" "accepted" "FortyNine")
  run run_hook "$fp"
  [[ "$output" == *"architect-compendium-update-entry"* ]]
}

@test "emits the expected entry shape with a Decides line (criterion 3)" {
  mk_readme
  fp=$(mk_adr "049" "accepted" "FortyNine")
  run_hook "$fp"
  grep -qE '^\*\*Decides:\*\* STUBBED-049' "$PROJ/docs/decisions/README.md"
}

@test "inserts a new ADR entry in numeric-sort order within in-force (criterion 5)" {
  mk_readme
  fp=$(mk_adr "050" "proposed" "Fifty")
  run run_hook "$fp"
  [ "$status" -eq 0 ]
  # ADR-050 must appear between ADR-049 and ADR-051 in the in-force section.
  line049=$(grep -n '^### ADR-049 ' "$PROJ/docs/decisions/README.md" | cut -d: -f1)
  line050=$(grep -n '^### ADR-050 ' "$PROJ/docs/decisions/README.md" | cut -d: -f1)
  line051=$(grep -n '^### ADR-051 ' "$PROJ/docs/decisions/README.md" | cut -d: -f1)
  [ -n "$line050" ]
  [ "$line049" -lt "$line050" ]
  [ "$line050" -lt "$line051" ]
}

@test "routes a superseded ADR's entry into the historical section (criterion 6)" {
  mk_readme
  fp=$(mk_adr "012" "superseded" "Twelve")
  run run_hook "$fp"
  [ "$status" -eq 0 ]
  # ADR-012 must land AFTER the Historical-decisions header, not in In-force.
  hist=$(grep -n '^## Historical decisions' "$PROJ/docs/decisions/README.md" | cut -d: -f1)
  line012=$(grep -n '^### ADR-012 ' "$PROJ/docs/decisions/README.md" | cut -d: -f1)
  [ -n "$line012" ]
  [ "$line012" -gt "$hist" ]
}

@test "migrates an entry from in-force to historical when status flips (criterion 6)" {
  mk_readme
  # ADR-049 currently renders in the in-force fixture section; re-author it as
  # superseded — the hook must remove the in-force block and place it historical.
  fp=$(mk_adr "049" "superseded" "FortyNine")
  run run_hook "$fp"
  [ "$status" -eq 0 ]
  # Exactly one ADR-049 entry, and it is now below the Historical header.
  [ "$(grep -c '^### ADR-049 ' "$PROJ/docs/decisions/README.md")" -eq 1 ]
  hist=$(grep -n '^## Historical decisions' "$PROJ/docs/decisions/README.md" | cut -d: -f1)
  line049=$(grep -n '^### ADR-049 ' "$PROJ/docs/decisions/README.md" | cut -d: -f1)
  [ "$line049" -gt "$hist" ]
}

@test "stages docs/decisions/README.md after refresh (criterion: same-commit pairing)" {
  mk_readme
  ( cd "$PROJ" && git add -A && git commit -q -m init )
  fp=$(mk_adr "049" "accepted" "FortyNine")
  run_hook "$fp"
  # README must be in the staged set.
  ( cd "$PROJ" && git diff --cached --name-only ) | grep -q 'docs/decisions/README.md'
}

@test "subprocess failure leaves README unchanged + does NOT block the edit (criterion 7)" {
  mk_readme
  before=$(cat "$PROJ/docs/decisions/README.md")
  fp=$(mk_adr "049" "accepted" "FortyNine")
  export PATH="$FAILSHIMDIR:$ORIG_PATH"
  run run_hook "$fp"
  [ "$status" -eq 0 ]                       # does not block the body edit
  after=$(cat "$PROJ/docs/decisions/README.md")
  [ "$before" = "$after" ]                  # README unchanged (degraded mode)
  [[ "$output" == *"degraded mode"* ]]
}

@test "opt-out ARCHITECT_AUTO_UPDATE_COMPENDIUM=0 self-suppresses (criterion 8)" {
  mk_readme
  before=$(cat "$PROJ/docs/decisions/README.md")
  fp=$(mk_adr "049" "accepted" "FortyNine")
  run bash -c "echo '{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$fp\"}}' | ARCHITECT_AUTO_UPDATE_COMPENDIUM=0 CLAUDE_PROJECT_DIR='$PROJ' bash '$HOOK'"
  [ "$status" -eq 0 ]
  [ "$before" = "$(cat "$PROJ/docs/decisions/README.md")" ]
  [[ "$output" == *"ARCHITECT_AUTO_UPDATE_COMPENDIUM=0"* ]]
}

@test "ignores README.md edits (no self-recursion)" {
  mk_readme
  before=$(cat "$PROJ/docs/decisions/README.md")
  run run_hook "$PROJ/docs/decisions/README.md"
  [ "$status" -eq 0 ]
  [ "$before" = "$(cat "$PROJ/docs/decisions/README.md")" ]
}

@test "ignores non-decisions file edits" {
  mk_readme
  echo "x" > "$PROJ/other.ts"
  run run_hook "$PROJ/other.ts"
  [ "$status" -eq 0 ]
}

@test "fail-closed guard: rejects a subprocess entry that injects spurious ADR ids/sections — restores README, degraded, unstaged (P367)" {
  mk_readme
  ( cd "$PROJ" && git add -A && git commit -q -m init )
  before=$(cat "$PROJ/docs/decisions/README.md")
  fp=$(mk_adr "049" "accepted" "FortyNine")
  # Malformed shim: valid header for the edited id, but ALSO injects an
  # unrelated ADR-999 header and a spurious '## ' section — the additive
  # corruption shape empirically reproduced for P367.
  BADDIR="$(mktemp -d)"
  cat > "$BADDIR/claude" <<'SHIM'
#!/usr/bin/env bash
cat >/dev/null
entry="### ADR-049 — Hijacked
**Status:** accepted | **Oversight:** confirmed
**Decides:** body.

## Injected section

### ADR-999 — Sneaky"
jq -cn --arg r "$entry" '{result:$r}'
SHIM
  chmod +x "$BADDIR/claude"
  export PATH="$BADDIR:$ORIG_PATH"
  run run_hook "$fp"
  [ "$status" -eq 0 ]                                          # never blocks the body edit
  [ "$before" = "$(cat "$PROJ/docs/decisions/README.md")" ]    # restored unchanged
  ! grep -q 'ADR-999' "$PROJ/docs/decisions/README.md"         # no injected id survives
  [[ "$output" == *"guard"* ]]                                 # observable degraded signal
  # README left in its committed state — no corrupted blob staged.
  ( cd "$PROJ" && git diff --cached --quiet -- docs/decisions/README.md )
  rm -rf "$BADDIR"
}

@test "fail-closed guard: rejects an emit for the wrong ADR id (edited id absent) — restores, degraded (P367)" {
  mk_readme
  before=$(cat "$PROJ/docs/decisions/README.md")
  fp=$(mk_adr "050" "proposed" "Fifty")          # NEW adr — not yet in the compendium
  # Shim emits an entry for the WRONG id (049, which already exists) instead of
  # the edited 050: the edited id never lands and 049 is duplicated.
  WRONGDIR="$(mktemp -d)"
  cat > "$WRONGDIR/claude" <<'SHIM'
#!/usr/bin/env bash
cat >/dev/null
entry="### ADR-049 — WrongId
**Status:** proposed | **Oversight:** confirmed
**Decides:** body."
jq -cn --arg r "$entry" '{result:$r}'
SHIM
  chmod +x "$WRONGDIR/claude"
  export PATH="$WRONGDIR:$ORIG_PATH"
  run run_hook "$fp"
  [ "$status" -eq 0 ]
  [ "$before" = "$(cat "$PROJ/docs/decisions/README.md")" ]    # restored unchanged
  ! grep -q '^### ADR-050' "$PROJ/docs/decisions/README.md"    # edited id never landed
  [[ "$output" == *"guard"* ]]
  rm -rf "$WRONGDIR"
}

@test "registered in hooks.json on PostToolUse Edit|Write (criterion 9)" {
  HOOKS_JSON="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/hooks.json"
  run jq -e '.hooks.PostToolUse[] | select(.matcher | test("Edit")) | .hooks[] | select(.command | test("architect-compendium-update-entry"))' "$HOOKS_JSON"
  [ "$status" -eq 0 ]
}
