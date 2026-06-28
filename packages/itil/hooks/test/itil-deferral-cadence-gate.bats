#!/usr/bin/env bats

# P375 — itil-deferral-cadence-gate.sh PostToolUse:Write|Edit|MultiEdit
# advisory hook. The ratified Option-C "authoring-time enforcement gate"
# (core slice, advisory rollout per ADR-057 staged-rollout + the P375
# architect review 2026-06-28).
#
# The gate fires at AUTHORING time on the NEWLY-authored text (Edit
# new_string / Write content / MultiEdit concatenated new_strings —
# diff-aware so descriptive prose already on disk never re-triggers) of
# a SHIPPED authoring surface (SKILL.md, docs/decisions/*.md ADRs,
# docs/rfcs/*.md RFCs, hook *.sh). When the new text introduces an
# uncadenced-deferral phrasing (`deferred to <on-demand re-entry>`,
# `pending review`, `re-rate at next`, `(deferred …`, `next review`,
# `when ready`, `lands in Slice N`) WITHOUT a cadence annotation naming
# a SELF-FIRING trigger within the +/-5 line window, it emits a stderr
# advisory citing P375 + the remedy.
#
# THE LOAD-BEARING P375 REFINEMENT vs the P234 sibling
# (itil-fictional-defer-detect.sh): a bare named on-demand skill
# (/wr-foo:bar) or a bare ticket ID (Pnnn / RFC-nnn / ADR-nnn) does NOT
# satisfy the cadence requirement — naming an on-demand re-entry point
# and treating it as a cadence IS the exact conflation P375 captures
# ("BUT NOTHING TRIGGERS THAT WORK!!!"). Only a self-firing-CLASS
# citation satisfies: a hook *.sh, SessionStart, PreToolUse/PostToolUse,
# .github/workflows/ (CI), cron, or a work-problems Step-0x / pre-flight
# reference. The existing P234 hook WRONGLY accepts skills + ticket IDs;
# this hook does not.
#
# Core-slice boundary (architect refinement 1, named loudly): the gate
# checks the cadence annotation names a self-firing-CLASS trigger — it
# does NOT validate that the named trigger actually exists / fires (the
# transitive-reachability graph is a deferred later slice). docs/problems/
# tickets are EXCLUDED (they descriptively narrate deferrals — highest
# false-positive surface, already covered by the ADR-084 census).
#
# Advisory only — NEVER blocks (exit 0 always), per ADR-040/045
# declarative-first + ADR-013 Rule 6 fail-open. Behavioural per ADR-052
# (asserts emitted stderr, never source-greps the hook). Hermetic per
# P391 (unsets inherited suppress vars in setup).

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"
  HOOK="$REPO_ROOT/packages/itil/hooks/itil-deferral-cadence-gate.sh"
  # P391 hermeticity: AFK iters export suppress vars that would poison
  # the advisory-fires assertions. Strip them for the test process.
  unset WR_SUPPRESS_DEFERRAL_CADENCE_GATE
  unset WR_SUPPRESS_OVERSIGHT_NUDGE
}

# Emit a PostToolUse stdin payload for an Edit tool call.
# $1 = file_path, $2 = new_string (the newly-authored text).
emit_edit() {
  jq -n --arg p "$1" --arg n "$2" '{
    session_id: "deferral-cadence-test",
    tool_name: "Edit",
    tool_input: { file_path: $p, old_string: "X", new_string: $n },
    tool_response: { success: true }
  }'
}

# Emit a PostToolUse stdin payload for a Write tool call.
emit_write() {
  jq -n --arg p "$1" --arg c "$2" '{
    session_id: "deferral-cadence-test",
    tool_name: "Write",
    tool_input: { file_path: $p, content: $c },
    tool_response: { success: true }
  }'
}

fires() { [[ "$output" == *"P375"* ]] || [[ "$stderr" == *"P375"* ]]; }
silent() { [[ "$output" != *"P375"* ]] && [[ "$stderr" != *"P375"* ]]; }

# --- Positive: uncadenced deferral authored → advisory fires ---

@test "fire: SKILL.md deferral citing a bare on-demand skill (the P375 conflation) fires" {
  # This is the case the P234 sibling WRONGLY allows — a named on-demand
  # skill is NOT a self-firing cadence.
  run bash "$HOOK" <<<"$(emit_edit packages/foo/skills/bar/SKILL.md \
    'Full scope deferred to /wr-itil:manage-rfc accepted transition.')"
  [ "$status" -eq 0 ]
  fires
}

@test "fire: ADR new_string deferral with no citation at all fires" {
  run bash "$HOOK" <<<"$(emit_edit docs/decisions/099-thing.proposed.md \
    'Considered Options and Consequences deferred — flesh out later.')"
  [ "$status" -eq 0 ]
  fires
}

@test "fire: RFC deferral citing only a bare ticket ID (not a cadence) fires" {
  # A ticket ID is an audit annotation, not a self-firing trigger.
  run bash "$HOOK" <<<"$(emit_edit docs/rfcs/RFC-099-thing.proposed.md \
    'Scope deferred to next review per P375.')"
  [ "$status" -eq 0 ]
  fires
}

@test "fire: Write of a hook .sh whose content carries an uncadenced deferral fires" {
  run bash "$HOOK" <<<"$(emit_write packages/foo/hooks/foo.sh \
    '# TODO pending review when ready; not wired yet.')"
  [ "$status" -eq 0 ]
  fires
}

@test "fire: deferral with a cadence comment that names an ON-DEMAND skill still fires" {
  # The annotation carrier is fine but its value must name a self-firing
  # CLASS — naming an on-demand skill inside the comment does not help.
  run bash "$HOOK" <<<"$(emit_edit packages/foo/skills/bar/SKILL.md \
    'Tasks deferred. <!-- cadence: /wr-itil:manage-rfc accepted -->')"
  [ "$status" -eq 0 ]
  fires
}

# --- Negative: cadenced deferral or out-of-scope → silent ---

@test "allow: deferral citing a self-firing hook .sh in window exits silent" {
  run bash "$HOOK" <<<"$(emit_edit packages/foo/skills/bar/SKILL.md \
    'Re-rate deferred; surfaced every session by retrospective-deferral-census.sh.')"
  [ "$status" -eq 0 ]
  silent
}

@test "allow: deferral with an explicit cadence annotation naming PostToolUse exits silent" {
  run bash "$HOOK" <<<"$(emit_edit docs/decisions/099-thing.proposed.md \
    'Section deferred. <!-- cadence: PostToolUse itil-foo-gate.sh fires on author -->')"
  [ "$status" -eq 0 ]
  silent
}

@test "allow: deferral citing SessionStart self-firing surface exits silent" {
  run bash "$HOOK" <<<"$(emit_edit docs/rfcs/RFC-099-thing.proposed.md \
    'Drain deferred; the SessionStart nudge re-surfaces it every session.')"
  [ "$status" -eq 0 ]
  silent
}

@test "allow: deferral citing a CI workflow exits silent" {
  run bash "$HOOK" <<<"$(emit_edit packages/foo/skills/bar/SKILL.md \
    'Validation deferred to .github/workflows/check.yml on every push.')"
  [ "$status" -eq 0 ]
  silent
}

@test "allow: deferral in a docs/problems/ ticket (excluded surface) exits silent" {
  run bash "$HOOK" <<<"$(emit_edit docs/problems/open/099-thing.open.md \
    'Severity deferred to investigation; expand at next review.')"
  [ "$status" -eq 0 ]
  silent
}

@test "allow: deferral phrasing in a non-authoring file (.ts) exits silent" {
  run bash "$HOOK" <<<"$(emit_edit packages/foo/src/index.ts \
    '// deferred to next review — TODO')"
  [ "$status" -eq 0 ]
  silent
}

@test "allow: authoring-surface edit with NO deferral phrasing exits silent" {
  run bash "$HOOK" <<<"$(emit_edit packages/foo/skills/bar/SKILL.md \
    'This step validates the marker and proceeds to Step 2.')"
  [ "$status" -eq 0 ]
  silent
}

# --- Robustness ---

@test "fail-open: empty stdin exits 0 silent" {
  run bash "$HOOK" <<<""
  [ "$status" -eq 0 ]
  silent
}

@test "fail-open: malformed JSON stdin exits 0 silent" {
  run bash "$HOOK" <<<"{not json"
  [ "$status" -eq 0 ]
  silent
}

@test "suppress: WR_SUPPRESS_DEFERRAL_CADENCE_GATE=1 silences the advisory" {
  run env WR_SUPPRESS_DEFERRAL_CADENCE_GATE=1 bash "$HOOK" <<<"$(emit_edit \
    packages/foo/skills/bar/SKILL.md 'deferred to /wr-itil:manage-rfc accepted')"
  [ "$status" -eq 0 ]
  silent
}
