#!/usr/bin/env bash
# packages/itil/scripts/update-rfc-references-section.sh
#
# Generalised reverse-trace section updater for RFC files. Mirror of
# update-problem-references-section.sh with the lookup table tuned for
# RFC-on-RFC reverse traces:
#   - ## Story Maps : sources docs/story-maps/*/*.html via data attributes
#   - ## Stories    : forward-trace from RFC's own frontmatter `stories:`
#
# Per ADR-060 § Phase 2 encoding amendment 2026-05-12 architect finding 4:
# no per-section-name branching in body; lookup-table-driven dispatch.
#
# Usage: update-rfc-references-section.sh <rfc-file> <section-name>
#
# @adr ADR-060 (Phase 2 encoding amendment 2026-05-12)
# @problem P170 (Phase 2 Slice 2b)

set -uo pipefail

RFC_FILE="${1:-}"
SECTION_NAME="${2:-}"

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

declare -A SECTION_GLOB SECTION_MODE SECTION_ID_PATTERN

SECTION_GLOB["Story Maps"]="docs/story-maps/*/STORY-MAP-*.html"
SECTION_MODE["Story Maps"]="html-data-attribute-rfc"
SECTION_ID_PATTERN["Story Maps"]="STORY-MAP-[0-9]+"

SECTION_GLOB["Stories"]="docs/stories/*/STORY-*.md"
SECTION_MODE["Stories"]="markdown-frontmatter-rfc"
SECTION_ID_PATTERN["Stories"]="STORY-[0-9]+"

glob_pattern="${SECTION_GLOB[$SECTION_NAME]:-}"
extraction_mode="${SECTION_MODE[$SECTION_NAME]:-}"
id_pattern="${SECTION_ID_PATTERN[$SECTION_NAME]:-}"

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

declare -a matched_ids=() matched_titles=() matched_statuses=()

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
