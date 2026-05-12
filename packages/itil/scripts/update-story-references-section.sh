#!/usr/bin/env bash
# packages/itil/scripts/update-story-references-section.sh
#
# Generalised reverse-trace section updater for story files. Lookup
# table supports ## RFCs, ## Story Maps sections on STORY-NNN-*.md
# files (a story's parent RFC + parent story-map traces).
#
# Per ADR-060 § Phase 2 encoding amendment 2026-05-12 architect
# finding 4: no per-section-name branching; lookup-table dispatch.
#
# @adr ADR-060 (Phase 2 encoding amendment 2026-05-12)
# @problem P170 (Phase 2 Slice 2b)

set -uo pipefail

STORY_FILE="${1:-}"
SECTION_NAME="${2:-}"

[ -n "$STORY_FILE" ] || { echo "ERROR: missing story-file argument" >&2; exit 1; }
[ -n "$SECTION_NAME" ] || { echo "ERROR: missing section-name argument" >&2; exit 1; }
[ -f "$STORY_FILE" ] || { echo "ERROR: story file not found: $STORY_FILE" >&2; exit 1; }

declare -A SECTION_GLOB SECTION_MODE SECTION_ID_PATTERN

SECTION_GLOB["RFCs"]="docs/rfcs/RFC-*.md"
SECTION_MODE["RFCs"]="markdown-frontmatter-stories"
SECTION_ID_PATTERN["RFCs"]="RFC-[0-9]+"

SECTION_GLOB["Story Maps"]="docs/story-maps/*/STORY-MAP-*.html"
SECTION_MODE["Story Maps"]="html-data-story-id"
SECTION_ID_PATTERN["Story Maps"]="STORY-MAP-[0-9]+"

glob_pattern="${SECTION_GLOB[$SECTION_NAME]:-}"
extraction_mode="${SECTION_MODE[$SECTION_NAME]:-}"
id_pattern="${SECTION_ID_PATTERN[$SECTION_NAME]:-}"

[ -n "$glob_pattern" ] || { echo "ERROR: unknown section-name '$SECTION_NAME'. Supported: RFCs, Story Maps" >&2; exit 1; }

story_basename=$(basename "$STORY_FILE")
story_id=$(echo "$story_basename" | grep -oE '^STORY-[0-9]+' | head -1)
[ -n "$story_id" ] || { echo "ERROR: cannot extract STORY ID from filename: $story_basename" >&2; exit 1; }

declare -a matched_ids=() matched_titles=() matched_statuses=()

extract_from_markdown_frontmatter_stories() {
  local file="$1"
  awk '/^---$/{f=!f;next} f && /^stories:/' "$file" | head -1 | grep -qE "\\b${story_id}\\b"
}

extract_from_html_data_story_id() {
  local file="$1"
  # Story maps reference stories via <a data-story-id="STORY-NNN"> per ADR-060
  # amendment schema; grep on the literal attribute match.
  grep -qE "data-story-id=\"${story_id}\"" "$file"
}

extract_id_from_filename() { basename "$1" | grep -oE "$id_pattern" | head -1; }
extract_title_md() { awk '/^# / { sub(/^# /, ""); print; exit }' "$1"; }
extract_title_html() { grep -oE '<title>[^<]+</title>' "$1" | head -1 | sed -E 's|<title>([^<]+)</title>|\1|'; }
extract_status_md() { awk '/^---$/{f=!f;next} f && /^status:/{ sub(/^status:[[:space:]]*/, ""); gsub(/"/, ""); print; exit }' "$1"; }
extract_status_html() { grep -oE '<meta[[:space:]]+name="status"[[:space:]]+content="[^"]+"' "$1" | head -1 | sed -E 's|.*content="([^"]+)".*|\1|'; }

case "$extraction_mode" in
  markdown-frontmatter-stories)
    extract_match=extract_from_markdown_frontmatter_stories
    extract_title=extract_title_md
    extract_status=extract_status_md
    ;;
  html-data-story-id)
    extract_match=extract_from_html_data_story_id
    extract_title=extract_title_html
    extract_status=extract_status_html
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
    matched_ids+=("$aid")
    matched_titles+=("$("$extract_title" "$artefact" 2>/dev/null || echo "")")
    matched_statuses+=("$("$extract_status" "$artefact" 2>/dev/null || echo "unknown")")
  fi
done
shopt -u nullglob

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
' "$STORY_FILE" > "$tmp_file"

tmp_file2="$(mktemp)"
awk 'BEGIN{c=0} /^[[:space:]]*$/{c++; next} {for(i=0;i<c;i++)print ""; c=0; print} END{print ""}' "$tmp_file" > "$tmp_file2"
mv "$tmp_file2" "$tmp_file"

if [ -n "$new_section" ]; then
  printf '\n%s' "$new_section" >> "$tmp_file"
fi

if ! cmp -s "$tmp_file" "$STORY_FILE"; then
  mv "$tmp_file" "$STORY_FILE"
else
  rm -f "$tmp_file"
fi

exit 0
