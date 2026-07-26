#!/usr/bin/env bash
# check-afk-accept-eligible.sh — ADR-101 AFK pure-decomposition carve-out.
#
# Decides whether an AFK loop may transition a story `draft -> accepted` with a
# machine-written `human-oversight: confirmed` marker, and implement it, WITHOUT
# a fresh human ratification. Opt-in and fail-closed: absent the project opt-in
# or the story's own declaration, the answer is always "not eligible".
#
# Eligible IFF the project has opted in AND the story declares
# `afk-accept: pure-decomposition` AND both conditions hold:
#
#   (a) PARENT SUBSTANCE CONFIRMED — every `adrs:` / `jtbd:` entry resolves and
#       carries `human-oversight: confirmed` (persona too); every `rfcs:` entry
#       resolves and every ADR in THAT RFC's `adrs:` is confirmed; every
#       `problems:` entry resolves; every `story-maps:` entry satisfies the
#       ADR-101 map leg (fully ratified, OR confirmed with this story's own card
#       excluded from the hash — ADR-095 compels that card, so it cannot be the
#       thing that disqualifies the story). Map LIFECYCLE status is out of scope.
#       The RFC tier holds no independent decisions per ADR-070 and so has no
#       oversight marker of its own; condition (a) proxies through its `adrs:`.
#
#   (b) NO NEW SUBSTANCE, ESTABLISHED POSITIVELY — a whitelist, not a novelty
#       blacklist, because "introduces no new design choice" is a negative
#       existential an agent cannot discharge. `## Decomposition basis` must
#       carry exactly one entry per acceptance criterion, each naming the
#       artefact whose already-confirmed clause that criterion decomposes, and
#       every cited ID must be a member of the set (a) PROVED ratified —
#       frontmatter membership is not ratification. Zero criteria is FAIL-CLOSED.
#       A secondary blacklist rejects open-decision markers outside fenced or
#       backticked spans.
#
# The failure direction is deliberate: conservatively hold a genuine
# decomposition rather than silently accept an embedded decision.
#
# Usage: check-afk-accept-eligible.sh <story-file> [maps-root] [rfcs-root]
#                                     [jtbd-root] [problems-root] [decisions-root]
# Exit:  0 = eligible; 1 = not eligible (reasons on stderr); 2 = usage / file error.
#
# @adr ADR-101 (AFK pure-decomposition carve-out) ADR-090 (drift-invalidated
#      oversight) ADR-095 ADR-096 ADR-060 ADR-070 ADR-098 (config shape)
#      ADR-013 (Rule 6) ADR-052 (behavioural bats)
# @problem P456 (AFK iter cannot land a fix) P465 (accepted gate unenforced)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away)
# @jtbd JTBD-003 (Compose Only the Guardrails I Need)
set -uo pipefail

# Adopter-safe: source the shared lazy-fingerprint lib RELATIVE TO THIS SCRIPT
# (P317), never repo-relative.
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "check-afk-accept-eligible: cannot locate lib dir" >&2; exit 2; }
# shellcheck source=/dev/null
source "$LIB/story-oversight.sh"

story="${1:-}"
maps_root="${2:-docs/story-maps}"
rfcs_root="${3:-docs/rfcs}"
jtbd_root="${4:-docs/jtbd}"
problems_root="${5:-docs/problems}"
decisions_root="${6:-docs/decisions}"

if [ -z "$story" ]; then
  echo "check-afk-accept-eligible: usage: check-afk-accept-eligible.sh <story-file> [maps-root] [rfcs-root] [jtbd-root] [problems-root] [decisions-root]" >&2
  exit 2
fi
[ -f "$story" ] || { echo "check-afk-accept-eligible: file not found: $story" >&2; exit 2; }

fail() { echo "check-afk-accept-eligible: NOT ELIGIBLE — $1" >&2; exit 1; }

# --- Project opt-in (ADR-101 split; config shape mirrors ADR-098) ------------
# Resolution FAILS OPEN to the built-in default (this never errors); because the
# built-in default is `false`, the POLICY outcome of every degraded path — no
# jq, no file, unreadable, unparseable, non-boolean — is not-eligible.
# Env trumps both files: a loosening override for bats and one-off use, NOT a
# project-configuration surface.
afk_accept_enabled() {
  local v
  case "${WR_ITIL_AFK_ACCEPT:-}" in
    1|true) return 0 ;;
    0|false) return 1 ;;
  esac
  command -v jq >/dev/null 2>&1 || return 1
  for cfg in ".claude/itil.config.json" "$HOME/.claude/itil.config.json"; do
    [ -r "$cfg" ] || continue
    # Per-KEY fallback per ADR-098: a project file that simply omits the key
    # must not strand the machine layer. Only a file that actually sets it
    # decides the answer.
    jq -e 'has("afk_accept_pure_decomposition")' "$cfg" >/dev/null 2>&1 || continue
    # Strict: only the literal JSON `true` enables. The string form, 1, yes and
    # null do not — a typo must never open a permission-loosening carve-out.
    v="$(jq -r 'if .afk_accept_pure_decomposition == true then "true" else "false" end' "$cfg" 2>/dev/null || echo false)"
    [ "$v" = "true" ] && return 0
    return 1
  done
  return 1
}

afk_accept_enabled || fail "the project has not opted in to the ADR-101 carve-out (set \"afk_accept_pure_decomposition\": true in .claude/itil.config.json)"

# --- Declaration ------------------------------------------------------------
oversight_declares_pure_decomposition "$story" \
  || fail "$story does not declare \`afk-accept: pure-decomposition\` — the carve-out is opt-in per story, never a default"

story_id="$(basename "$story" | grep -oE 'STORY-[0-9]+' | head -1)"
[ -n "$story_id" ] || fail "cannot resolve a STORY-NNN id from $story"

# Read one frontmatter list field (inline `[A, B]` or block `- A` form).
trace_ids() {
  local field="$1" line ids
  line="$(awk -v f="^${field}:" '$0 ~ f {print; exit}' "$story")"
  ids="$(printf '%s' "$line" | grep -oE '(ADR|JTBD|RFC|STORY-MAP|P)-?[0-9]+' || true)"
  if [ -z "$ids" ]; then
    ids="$(awk -v f="^${field}:" '$0 ~ f {g=1;next} g&&/^[[:space:]]*-/{print} g&&/^[^[:space:]-]/{exit}' "$story" \
      | grep -oE '(ADR|JTBD|RFC|STORY-MAP|P)-?[0-9]+' || true)"
  fi
  printf '%s' "$ids"
}

# The set condition (a) PROVES ratified. Condition (b) intersects against this,
# so a basis entry can never cite an artefact (a) never verified (B4).
RATIFIED_SET=""
add_ratified() { RATIFIED_SET="$RATIFIED_SET $1"; }

# (a) ADR parents — write-once oversight per ADR-066.
for id in $(trace_ids adrs); do
  n="${id#ADR-}"
  f="$(ls "$decisions_root"/"$n"-*.md 2>/dev/null | head -1)"
  [ -n "$f" ] || fail "$id does not resolve under $decisions_root — a new decision is new substance"
  oversight_is_confirmed "$f" || fail "$id is not \`human-oversight: confirmed\` — condition (a) requires every parent decision be human-confirmed"
  add_ratified "$id"
done

# (a) JTBD parents + their personas — ADR-068 oversight sibling.
for id in $(trace_ids jtbd); do
  n="${id#JTBD-}"
  f="$(ls "$jtbd_root"/*/"JTBD-$n"-*.md 2>/dev/null | head -1)"
  [ -n "$f" ] || fail "$id does not resolve under $jtbd_root — a new job is new substance"
  oversight_is_confirmed "$f" || fail "$id is not \`human-oversight: confirmed\`"
  p="$(dirname "$f")/persona.md"
  if [ -f "$p" ]; then
    oversight_is_confirmed "$p" || fail "the persona for $id ($p) is not \`human-oversight: confirmed\` — a new or unconfirmed persona is new substance"
  fi
  add_ratified "$id"
done

# (a) RFC parents — no oversight tier of their own (ADR-070); proxy via `adrs:`.
for id in $(trace_ids rfcs); do
  n="${id#RFC-}"
  f="$(ls "$rfcs_root"/"RFC-$n"-*.md 2>/dev/null | head -1)"
  [ -n "$f" ] || fail "$id does not resolve under $rfcs_root"
  rfc_adrs="$(awk '/^adrs:/{print; exit}' "$f" | grep -oE 'ADR-[0-9]+' || true)"
  for a in $rfc_adrs; do
    af="$(ls "$decisions_root"/"${a#ADR-}"-*.md 2>/dev/null | head -1)"
    [ -n "$af" ] || fail "$id depends on $a which does not resolve under $decisions_root"
    oversight_is_confirmed "$af" || fail "$id depends on $a which is not \`human-oversight: confirmed\`"
    add_ratified "$a"
  done
  add_ratified "$id"
done

# (a) Problem parents — resolve only; problems carry no oversight tier.
for id in $(trace_ids problems); do
  n="${id#P}"
  f="$(ls "$problems_root"/"$n"-*.md "$problems_root"/*/"$n"-*.md 2>/dev/null | head -1)"
  [ -n "$f" ] || fail "$id does not resolve under $problems_root"
  add_ratified "$id"
done

# (a) Story-map parents — the ADR-101 map leg.
for id in $(trace_ids story-maps); do
  n="${id#STORY-MAP-}"
  f="$(ls "$maps_root"/*/"STORY-MAP-$n"-*.html 2>/dev/null | head -1)"
  [ -n "$f" ] || fail "$id does not resolve under $maps_root"
  oversight_map_leg_ok "$f" "$story_id" \
    || fail "$id fails the ADR-101 map leg — it is not human-confirmed, or it has drifted for a reason other than adding ${story_id}'s own card. Ratify the map."
  add_ratified "$id"
done

# --- (b) NO NEW SUBSTANCE, established positively ---------------------------
# Acceptance criteria: prefix-anchored section (headings carry trailing
# qualifiers like `(accepted-gate, INVEST Testable)`), terminated by the next
# `##`. Tick-insensitive so implementation progress never flips the check, and
# the criterion literal is aligned with oversight_content_hash's normaliser so
# every counted line is a normalised line.
section_of() {
  awk -v h="$1" '
    $0 ~ h {inside=1; next}
    inside && /^##[[:space:]]/ {exit}
    inside {print}
  ' "$story"
}

# NO `\b` IN THESE ANCHORS, and do not re-add it. Two independent reasons:
# (1) awk escape-processes a `-v` assignment value, so `\b` arrives as a literal
#     BACKSPACE (0x08) — the pattern then never matches a real heading, which
#     silently makes this whole check inert. It fails CLOSED, so there is no
#     permission hole, but the carve-out can never return eligible for anyone.
# (2) POSIX ERE has no `\b` at all, so it is equally wrong in the commit-locus
#     copy of this count in itil-no-implement-draft-gate.sh, where the failure
#     would be silent in a different way. Those two loci MUST stay aligned.
# Prefix matching is the documented intent anyway (ADR-101): corpus headings
# carry trailing qualifiers like `(accepted-gate, INVEST Testable)`.
criteria_count="$(section_of '^##[[:space:]]+Acceptance criteria' | grep -cE '^- \[[ xX]\]' || true)"
[ "${criteria_count:-0}" -gt 0 ] \
  || fail "no top-level \`- [ ]\` criterion lines found in the acceptance-criteria section — condition (b) is fail-closed on zero, since an absent section is indistinguishable from absent criteria"

basis="$(section_of '^##[[:space:]]+Decomposition basis')"
[ -n "$(printf '%s' "$basis" | tr -d '[:space:]')" ] \
  || fail "\`## Decomposition basis\` is missing or empty — condition (b) requires each criterion to name the already-confirmed clause it decomposes"

basis_count="$(printf '%s\n' "$basis" | grep -cE '^- ' || true)"
[ "${basis_count:-0}" -eq "$criteria_count" ] \
  || fail "\`## Decomposition basis\` has $basis_count entries but there are $criteria_count acceptance criteria — every criterion must name the confirmed clause it decomposes"

# Every cited ID must be in the set condition (a) proved ratified (B4).
for cited in $(printf '%s' "$basis" | grep -oE '(ADR|JTBD|RFC|STORY-MAP)-[0-9]+' | sort -u); do
  case " $RATIFIED_SET " in
    *" $cited "*) ;;
    *) fail "\`## Decomposition basis\` cites $cited, which condition (a) never verified as ratified — cite only traced, confirmed parents" ;;
  esac
done

# Secondary blacklist. Fenced and backticked spans are stripped first so a story
# may DESCRIBE the blocked vocabulary (this one does) without tripping on it.
prose="$(awk '/^```/{f=!f;next} !f' "$story" | sed -E 's/`[^`]*`//g')"
if printf '%s' "$prose" | grep -qiE '\[Unratified Dependency\]|\bTBD\b|to be decided|open question|decision needed'; then
  fail "an open-decision marker appears outside a fenced or backticked span — the story is not pure decomposition"
fi

echo "check-afk-accept-eligible: ELIGIBLE — $story_id is pure decomposition of confirmed substance ($criteria_count criteria, all basis citations ratified)" >&2
exit 0
