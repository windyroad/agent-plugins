#!/usr/bin/env bash
# packages/itil/scripts/update-rfc-references-section.sh
#
# Generalised reverse-trace section updater for RFC files. Mirror of
# update-problem-references-section.sh with the lookup table tuned for
# RFC-on-RFC reverse traces:
#   - ## Story Maps : sources docs/story-maps/*/*.html via data attributes
#   - ## Stories    : sources docs/stories/*/STORY-*.md by each story's `rfcs:`
#
# Per ADR-060 § Phase 2 encoding amendment 2026-05-12 architect finding 4:
# no per-section-name branching in body; lookup-table-driven dispatch. The
# approval gate below rides that table rather than a branch, for the same
# reason.
#
# APPROVAL GATE ON `## Stories` (P472 / STORY-099). ADR-090 as amended by
# ADR-103 forbids an RFC from referencing a story whose story map is not
# ratified. This helper regenerates the WHOLE section from a reverse index over
# every story claiming the RFC, and it is the prescribed repair for a
# MISSING_REVERSE_TRACE finding — so ungated, repairing one legitimate finding
# swept every unapproved sibling in with it, writing exactly the reference the
# rule forbids. The narrowed detector in reconcile-stories.sh would then report
# clean over it: a loud false positive traded for a silent true negative, which
# is strictly worse. A withheld story is named on stderr, because a section
# that silently shrinks is its own kind of unreadable.
#
# KNOWN DIVERGENCE, recorded on P472 and deliberately not fixed here. ADR-060
# line 288 and this header used to say `## Stories` is a FORWARD trace
# projecting the RFC's own `stories:` array. The implementation has always
# reverse-indexed story frontmatter instead. Projecting `stories:` was
# considered: a corpus audit found 8 of 23 approved (story → markdown-RFC)
# claims present in the RFC's `## Stories` but absent from its `stories:`, so
# the projection would drop those rows and the reconciler would report
# MISSING_REVERSE_TRACE on them with no mechanical repair — P472 re-created in
# the other direction. The header now states what the code does.
#
# Usage: update-rfc-references-section.sh <rfc-file> <section-name> [<story-maps-dir>]
#
# @adr ADR-060 (Phase 2 encoding amendment 2026-05-12)
# @problem P170 (Phase 2 Slice 2b)

set -uo pipefail

RFC_FILE="${1:-}"
SECTION_NAME="${2:-}"
MAPS_DIR="${3:-docs/story-maps}"

# Adopter-safe: source the shared ratification lib RELATIVE TO THIS SCRIPT
# (P317), matching check-rfc-stories-ratified.sh.
LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)" || {
  echo "ERROR: cannot locate lib dir" >&2; exit 1; }
# shellcheck source=../lib/story-oversight.sh
source "$LIB/story-oversight.sh"

if [ -z "$RFC_FILE" ]; then
  echo "ERROR: missing rfc-file argument" >&2
  exit 1
fi
if [ -z "$SECTION_NAME" ]; then
  echo "ERROR: missing section-name argument" >&2
  exit 1
fi
if [ ! -f "$RFC_FILE" ]; then
  echo "ERROR: rfc file not found: $RFC_FILE" >&2
  exit 1
fi

declare -A SECTION_GLOB SECTION_MODE SECTION_ID_PATTERN SECTION_ADMIT

# A story is APPROVED when every story map it names is ratified (ADR-103). Any
# `human-oversight:` field left on the story file is legacy and is ignored.
admit_if_story_approved() { story_is_approved "$1" "$MAPS_DIR"; }

SECTION_GLOB["Story Maps"]="docs/story-maps/*/STORY-MAP-*.html"
SECTION_MODE["Story Maps"]="html-data-attribute-rfc"
SECTION_ID_PATTERN["Story Maps"]="STORY-MAP-[0-9]+"
SECTION_ADMIT["Story Maps"]=""

SECTION_GLOB["Stories"]="docs/stories/*/STORY-*.md"
SECTION_MODE["Stories"]="markdown-frontmatter-rfc"
SECTION_ID_PATTERN["Stories"]="STORY-[0-9]+"
SECTION_ADMIT["Stories"]="admit_if_story_approved"

glob_pattern="${SECTION_GLOB[$SECTION_NAME]:-}"
extraction_mode="${SECTION_MODE[$SECTION_NAME]:-}"
id_pattern="${SECTION_ID_PATTERN[$SECTION_NAME]:-}"
admit_filter="${SECTION_ADMIT[$SECTION_NAME]:-}"

if [ -z "$glob_pattern" ]; then
  echo "ERROR: unknown section-name '$SECTION_NAME'. Supported: Story Maps, Stories" >&2
  exit 1
fi

# Extract RFC ID from filename: RFC-NNN-slug.<status>.md or RFC-NNN-slug.md
rfc_basename=$(basename "$RFC_FILE")
rfc_id=$(echo "$rfc_basename" | grep -oE '^RFC-[0-9]+' | head -1)
if [ -z "$rfc_id" ]; then
  echo "ERROR: cannot extract RFC ID from filename: $rfc_basename" >&2
  exit 1
fi

declare -a matched_ids=() matched_titles=() matched_statuses=() withheld_ids=()

extract_from_html_rfcs_meta() {
  local file="$1"
  local rfcs_line
  rfcs_line=$(grep -E '<meta[[:space:]]+name="rfcs"[[:space:]]+content="[^"]+"' "$file" | head -1)
  [ -n "$rfcs_line" ] || return 1
  echo "$rfcs_line" | grep -qE "\\b${rfc_id}\\b"
}

extract_from_markdown_frontmatter_rfcs() {
  local file="$1"
  local rfcs_line
  rfcs_line=$(awk '/^---$/{f=!f;next} f && /^rfcs:/' "$file" | head -1)
  [ -n "$rfcs_line" ] || return 1
  echo "$rfcs_line" | grep -qE "\\b${rfc_id}\\b"
}

extract_id_from_filename() { basename "$1" | grep -oE "$id_pattern" | head -1; }
extract_title_from_markdown() { awk '/^# / { sub(/^# /, ""); print; exit }' "$1"; }
extract_title_from_html() { grep -oE '<title>[^<]+</title>' "$1" | head -1 | sed -E 's|<title>([^<]+)</title>|\1|'; }
extract_status_from_markdown() { awk '/^---$/{f=!f;next} f && /^status:/{ sub(/^status:[[:space:]]*/, ""); gsub(/"/, ""); print; exit }' "$1"; }
extract_status_from_html() { grep -oE '<meta[[:space:]]+name="status"[[:space:]]+content="[^"]+"' "$1" | head -1 | sed -E 's|.*content="([^"]+)".*|\1|'; }

case "$extraction_mode" in
  html-data-attribute-rfc)
    extract_match=extract_from_html_rfcs_meta
    extract_title=extract_title_from_html
    extract_status=extract_status_from_html
    ;;
  markdown-frontmatter-rfc)
    extract_match=extract_from_markdown_frontmatter_rfcs
    extract_title=extract_title_from_markdown
    extract_status=extract_status_from_markdown
    ;;
  *)
    echo "ERROR: unknown extraction-mode '$extraction_mode'" >&2
    exit 1
    ;;
esac

shopt -s nullglob
for artefact in $glob_pattern; do
  [ -e "$artefact" ] || continue
  if "$extract_match" "$artefact"; then
    aid=$(extract_id_from_filename "$artefact")
    [ -n "$aid" ] || continue
    if [ -n "$admit_filter" ] && ! "$admit_filter" "$artefact"; then
      withheld_ids+=("$aid")
      continue
    fi
    matched_ids+=("$aid")
    matched_titles+=("$("$extract_title" "$artefact" 2>/dev/null || echo "")")
    matched_statuses+=("$("$extract_status" "$artefact" 2>/dev/null || echo "unknown")")
  fi
done
shopt -u nullglob

if [ ${#withheld_ids[@]} -gt 0 ]; then
  echo "update-rfc-references-section: withheld from ${rfc_id} ## ${SECTION_NAME}: ${withheld_ids[*]} — each names a story map that is not ratified, and an RFC references only approved stories. To list one, ratify its map; never hand-add the row." >&2
fi

new_section=""
if [ ${#matched_ids[@]} -gt 0 ]; then
  new_section="## ${SECTION_NAME}"$'\n\n| ID | Title | Status |\n|----|-------|--------|\n'
  for i in "${!matched_ids[@]}"; do
    new_section+="| ${matched_ids[$i]} | ${matched_titles[$i]} | ${matched_statuses[$i]} |"$'\n'
  done
fi

tmp_file="$(mktemp)"
awk -v sec="## $SECTION_NAME" '
  BEGIN { in_target=0; blank_buffer="" }
  $0 == sec { in_target=1; blank_buffer=""; next }
  in_target && /^## / && $0 != sec { in_target=0 }
  !in_target {
    if ($0 ~ /^[[:space:]]*$/) { if (blank_buffer == "") blank_buffer="\n"; next }
    if (blank_buffer != "") { printf "%s", blank_buffer; blank_buffer="" }
    print
  }
  END { if (blank_buffer != "") printf "%s", blank_buffer }
' "$RFC_FILE" > "$tmp_file"

tmp_file2="$(mktemp)"
awk 'BEGIN{c=0} /^[[:space:]]*$/{c++; next} {for(i=0;i<c;i++)print ""; c=0; print} END{print ""}' "$tmp_file" > "$tmp_file2"
mv "$tmp_file2" "$tmp_file"

if [ -n "$new_section" ]; then
  printf '\n%s' "$new_section" >> "$tmp_file"
fi

if ! cmp -s "$tmp_file" "$RFC_FILE"; then
  mv "$tmp_file" "$RFC_FILE"
else
  rm -f "$tmp_file"
fi

exit 0
