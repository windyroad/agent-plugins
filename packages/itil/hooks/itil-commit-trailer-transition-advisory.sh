#!/bin/bash
# wr-itil — PostToolUse:Bash hook (P378/RFC-030 Piece 2). The SHARED
# commit-trailer auto-transition trigger that ADR-060 (line 292/307) promised
# for BOTH the RFC and story tiers and that manage-rfc + manage-story both
# deferred to "a future commit-trailer-trigger hook" — never built. This is it.
#
# Per ADR-014, a hook MUST NOT perform the transition itself (git mv + Status
# edit + commit lands OUTSIDE the triggering commit's grain). So the hook
# DETECTS eligibility and ADVISES; the skill (/wr-itil:manage-rfc |
# /wr-itil:manage-story) — or an AFK orchestrator acting on the advisory —
# performs the transition. The detection is now self-firing; the false
# "auto-transitions on first non-capture commit" claims in both skills are
# corrected to describe this detect-then-perform shape.
#
# Trigger: a `git commit` whose HEAD message
#   - carries a `Refs: RFC-<NNN>` or `Refs: STORY-<NNN>` trailer, AND
#   - is NOT the artefact's capture commit (subject does not start with
#     `docs(rfcs): capture RFC-` / `feat(itil): capture STORY-`), AND
#   - the referenced artefact is in a pre-in-progress status
#     (RFC: .proposed/.accepted ; story: .draft) on disk.
# → emit a stderr advisory naming the transition command. Silent otherwise.
#
# Advisory-only (ADR-013 Rule 6 fail-open; ADR-045 ≤300-byte band; exit 0).
# Bypass: BYPASS_TRANSITION_ADVISORY=1.
#
# @adr ADR-060 (line 292/307 auto-transition triggers) ADR-014 (hook detects,
#      skill commits) ADR-045 (budget) ADR-013 (Rule 6 fail-open) ADR-052 (bats)
# @problem P378  @rfc RFC-030

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/command-detect.sh
source "$SCRIPT_DIR/lib/command-detect.sh"

INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: print(json.load(sys.stdin).get('tool_name',''))
except: print('')" 2>/dev/null || echo "")
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND=$(printf '%s' "$INPUT" | python3 -c "import sys,json
try: print(json.load(sys.stdin).get('tool_input',{}).get('command',''))
except: print('')" 2>/dev/null || echo "")
command_invokes_git_commit "$COMMAND" || exit 0
[ "${BYPASS_TRANSITION_ADVISORY:-}" = "1" ] && exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

SUBJECT=$(git log -1 --format='%s' HEAD 2>/dev/null) || exit 0
BODY=$(git log -1 --format='%B' HEAD 2>/dev/null) || exit 0

# Skip capture commits — they CREATE the artefact, not advance it.
case "$SUBJECT" in
  *"capture RFC-"*|*"capture STORY-"*) exit 0 ;;
esac

TRAILERS=$(printf '%s\n' "$BODY" | git interpret-trailers --parse 2>/dev/null \
  | grep -oE 'RFC-[0-9]{3}|STORY-[0-9]{3}' | sort -u || true)
[ -n "$TRAILERS" ] || exit 0

advise() { echo "P378 ADVISORY: $1" >&2; }

while IFS= read -r id; do
  [ -n "$id" ] || continue
  case "$id" in
    RFC-*)
      [ -d "./docs/rfcs" ] || continue
      shopt -s nullglob; files=(./docs/rfcs/${id}-*.proposed.md ./docs/rfcs/${id}-*.accepted.md); shopt -u nullglob
      [ ${#files[@]} -gt 0 ] || continue
      advise "${id} carries a non-capture commit but is still $(basename "${files[0]}" | grep -oE 'proposed|accepted'). It should advance to in-progress — run /wr-itil:manage-rfc ${id} in-progress (the skill performs the transition; a hook cannot, per ADR-014). Bypass: BYPASS_TRANSITION_ADVISORY=1."
      ;;
    STORY-*)
      [ -d "./docs/stories" ] || continue
      shopt -s nullglob; files=(./docs/stories/draft/${id}-*.md ./docs/stories/${id}-*.draft.md); shopt -u nullglob
      [ ${#files[@]} -gt 0 ] || continue
      advise "${id} carries a non-capture commit but is still draft. It should advance to in-progress — run /wr-itil:manage-story ${id} in-progress. Bypass: BYPASS_TRANSITION_ADVISORY=1."
      ;;
  esac
done <<< "$TRAILERS"

exit 0
