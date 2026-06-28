#!/usr/bin/env bash
# packages/itil/scripts/update-problem-references-section.sh
#
# Generalised reverse-trace section updater for problem tickets.
# Refreshes the auto-maintained `## <section-name>` section on a
# problem ticket file based on which artefacts in the configured
# source directory claim the ticket via either HTML `<meta>` data
# attributes (story-maps) or YAML frontmatter `problems:` list
# (stories + RFCs).
#
# Per ADR-060 § Phase 2 encoding amendment 2026-05-12 architect
# finding 4: the helper body MUST NOT carry per-section-name
# branching; `<section-name>` is a positional argument; the only
# branch in the helper body is the per-input-extension dispatch
# (`.html` → data-attribute grep; `.md` → frontmatter parse), which
# is determined by the section-to-source-dir lookup table, NOT by
# the section-name value itself. Each table row maps a section-name
# to its (source-dir, extension, ID-pattern) tuple; the helper body
# treats the table as opaque data.
#
# Supersedes/absorbs the single-purpose
# `packages/itil/scripts/update-problem-rfcs-section.sh` for the
# `## RFCs` section per ADR-060 amendment 2026-05-12 § Phase 2
# commit-grain decomposition + ADR-010 forwarder pattern. The old
# single-purpose helper stays as a thin shim during the deprecation
# window for back-compat with any pinned callers.
#
# Usage:
#   update-problem-references-section.sh <problem-file> <section-name>
#
# Supported section-names (lookup-table-driven, NOT branching):
#   - RFCs       → docs/rfcs/*.md (frontmatter `problems:` extraction)
#   - Story Maps → docs/story-maps/*/*.html (data-attribute extraction)
#   - Stories    → docs/stories/*/*.md (frontmatter `problems:` extraction)
#
# Lazy-empty discipline (per JTBD-101 atomic-fix-adopter friction
# guard + sibling pattern from update-problem-rfcs-section.sh): if
# zero artefacts trace the problem, the `## <section-name>` section
# is REMOVED entirely from the ticket file.
#
# Idempotent: running over a current section is a no-op (no file
# diff). Section placement: between `## Related` and `## Fix Released`
# (or at EOF if neither present), mirroring the RFC-section convention.
#
# @adr ADR-060 (Phase 2 encoding amendment 2026-05-12 — architect
#   finding 4: no per-section-name branching; per-extension dispatch
#   via lookup table)
# @adr ADR-014 (called by capture/manage skills to ride single-purpose
#   commit grain)
# @adr ADR-052 (behavioural bats coverage in test/)
# @problem P170 (Phase 2 Slice 2 deliverable)

set -uo pipefail

PROBLEM_FILE="${1:-}"
SECTION_NAME="${2:-}"

if [ -z "$PROBLEM_FILE" ]; then
  echo "ERROR: missing problem-file argument" >&2
  echo "Usage: $(basename "$0") <problem-file> <section-name>" >&2
  exit 1
fi
if [ -z "$SECTION_NAME" ]; then
  echo "ERROR: missing section-name argument" >&2
  echo "Usage: $(basename "$0") <problem-file> <section-name>" >&2
  exit 1
fi
if [ ! -f "$PROBLEM_FILE" ]; then
  echo "ERROR: problem file not found: $PROBLEM_FILE" >&2
  exit 1
fi

# Lookup table: section-name -> (source-dir, glob, extraction-mode, id-pattern, title-render-helper).
# The helper body reads from this table; it does NOT branch on the
# section-name value directly (architect finding 4). Add a new section
# by extending the table.
declare -A SECTION_SOURCE_DIR
declare -A SECTION_GLOB
declare -A SECTION_MODE
declare -A SECTION_ID_PATTERN

SECTION_SOURCE_DIR["RFCs"]="docs/rfcs"
SECTION_GLOB["RFCs"]="docs/rfcs/RFC-*.md"
SECTION_MODE["RFCs"]="markdown-frontmatter"
SECTION_ID_PATTERN["RFCs"]="RFC-[0-9]+"

SECTION_SOURCE_DIR["Story Maps"]="docs/story-maps"
SECTION_GLOB["Story Maps"]="docs/story-maps/*/STORY-MAP-*.html"
SECTION_MODE["Story Maps"]="html-data-attribute"
SECTION_ID_PATTERN["Story Maps"]="STORY-MAP-[0-9]+"

SECTION_SOURCE_DIR["Stories"]="docs/stories"
SECTION_GLOB["Stories"]="docs/stories/*/STORY-*.md"
SECTION_MODE["Stories"]="markdown-frontmatter"
SECTION_ID_PATTERN["Stories"]="STORY-[0-9]+"

source_dir="${SECTION_SOURCE_DIR[$SECTION_NAME]:-}"
glob_pattern="${SECTION_GLOB[$SECTION_NAME]:-}"
extraction_mode="${SECTION_MODE[$SECTION_NAME]:-}"
id_pattern="${SECTION_ID_PATTERN[$SECTION_NAME]:-}"

if [ -z "$source_dir" ]; then
  echo "ERROR: unknown section-name '$SECTION_NAME'. Supported: RFCs, Story Maps, Stories" >&2
  exit 1
fi

# Extract problem ID from filename (NNN portion of NNN-<slug>.md or NNN-<slug>.<state>.md)
problem_basename=$(basename "$PROBLEM_FILE")
problem_id_num=$(echo "$problem_basename" | grep -oE '^[0-9]+')
if [ -z "$problem_id_num" ]; then
  echo "ERROR: cannot extract problem ID from filename: $problem_basename" >&2
  exit 1
fi
problem_id="P${problem_id_num}"

# Collect matching artefact IDs via the configured extraction mode.
# Mode dispatch (the only branch in the body) is keyed on the
# extraction-mode value pulled from the lookup table, NOT on the
# section-name. Adding a new mode is a lookup-table extension; the
# branch grows by one case.
declare -a matched_ids=()
declare -a matched_titles=()
declare -a matched_statuses=()

extract_from_markdown_frontmatter() {
  local file="$1"
  # Read frontmatter problems: list. Match formats:
  #   problems: [P200, P201]
  #   problems: ["P200", "P201"]
  local problems_line
  problems_line=$(awk '/^---$/{f=!f;next} f && /^problems:/' "$file" | head -1)
  if [ -z "$problems_line" ]; then
    return 1
  fi
  echo "$problems_line" | grep -qE "\\bP${problem_id_num}\\b"
}

extract_from_html_data_attribute() {
  local file="$1"
  # Read <meta name="problems" content="P200,P201">
  local problems_line
  problems_line=$(grep -E '<meta[[:space:]]+name="problems"[[:space:]]+content="[^"]+"' "$file" | head -1)
  if [ -z "$problems_line" ]; then
    return 1
  fi
  echo "$problems_line" | grep -qE "P${problem_id_num}\\b"
}

extract_id_from_filename() {
  local file="$1"
  basename "$file" | grep -oE "$id_pattern" | head -1
}

extract_title_from_markdown() {
  local file="$1"
  awk '/^# / { sub(/^# /, ""); print; exit }' "$file"
}

extract_title_from_html() {
  local file="$1"
  grep -oE '<title>[^<]+</title>' "$file" | head -1 | sed -E 's|<title>([^<]+)</title>|\1|'
}

extract_status_from_markdown_frontmatter() {
  local file="$1"
  awk '/^---$/{f=!f;next} f && /^status:/{ sub(/^status:[[:space:]]*/, ""); gsub(/"/, ""); print; exit }' "$file"
}

extract_status_from_html_meta() {
  local file="$1"
  grep -oE '<meta[[:space:]]+name="status"[[:space:]]+content="[^"]+"' "$file" | head -1 | sed -E 's|.*content="([^"]+)".*|\1|'
}

# Per-mode extraction dispatch (the ONLY branch in the body — keyed on
# extraction-mode pulled from the lookup table, not on section-name).
case "$extraction_mode" in
  markdown-frontmatter)
    extract_match=extract_from_markdown_frontmatter
    extract_title=extract_title_from_markdown
    extract_status=extract_status_from_markdown_frontmatter
    ;;
  html-data-attribute)
    extract_match=extract_from_html_data_attribute
    extract_title=extract_title_from_html
    extract_status=extract_status_from_html_meta
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
    title=$("$extract_title" "$artefact" 2>/dev/null || echo "")
    status=$("$extract_status" "$artefact" 2>/dev/null || echo "unknown")
    matched_ids+=("$aid")
    matched_titles+=("$title")
    matched_statuses+=("$status")
  fi
done
shopt -u nullglob

# Render new section body (markdown table) when matches present;
# lazy-empty when not. Leading `\n` is intentionally omitted — the
# boundary is normalised at insertion time to exactly one blank line.
new_section=""
if [ ${#matched_ids[@]} -gt 0 ]; then
  new_section="## ${SECTION_NAME}"$'\n\n'
  new_section+=$'| ID | Title | Status |\n'
  new_section+=$'|----|-------|--------|\n'
  for i in "${!matched_ids[@]}"; do
    new_section+="| ${matched_ids[$i]} | ${matched_titles[$i]} | ${matched_statuses[$i]} |"
    new_section+=$'\n'
  done
fi

# Rewrite the problem file: strip existing ## <SECTION_NAME> section
# (if present) AND any preceding blank-line run that abutted it, then
# normalise trailing whitespace to exactly one final newline, then
# insert new_section at the canonical placement (before ## Fix
# Released; else at EOF separated by exactly one blank line).
tmp_file="$(mktemp)"
awk -v sec="## $SECTION_NAME" '
  BEGIN { in_target=0; blank_buffer="" }
  $0 == sec {
    in_target=1
    blank_buffer=""  # discard buffered blanks that preceded this section
    next
  }
  in_target && /^## / && $0 != sec { in_target=0 }
  !in_target {
    if ($0 ~ /^[[:space:]]*$/) {
      if (blank_buffer == "") {
        blank_buffer = "\n"  # remember a single blank
      }
      # collapse runs of blanks into one
      next
    }
    if (blank_buffer != "") {
      printf "%s", blank_buffer
      blank_buffer=""
    }
    print
  }
  END {
    if (blank_buffer != "") {
      printf "%s", blank_buffer
    }
  }
' "$PROBLEM_FILE" > "$tmp_file"

# Normalise trailing whitespace to single newline
tmp_file2="$(mktemp)"
awk 'BEGIN{c=0} /^[[:space:]]*$/{c++; next} {for(i=0;i<c;i++)print ""; c=0; print} END{print ""}' "$tmp_file" > "$tmp_file2"
mv "$tmp_file2" "$tmp_file"

# Append new section before ## Fix Released, or at EOF
if [ -n "$new_section" ]; then
  if grep -q '^## Fix Released' "$tmp_file"; then
    tmp_file2="$(mktemp)"
    # Pass the multi-line section via a file: awk -v rejects embedded newlines
    # on BSD awk (macOS), so getline keeps it portable across BSD awk + gawk
    # (proven in effort-tally.sh --write, commit 1c967ba0; P392). new_section
    # ends in a single \n, matching the prior `printf "%s\n", section` output.
    section_file="$(mktemp)"
    printf '%s' "$new_section" > "$section_file"
    awk -v sf="$section_file" '
      /^## Fix Released/ {
        while ((getline ln < sf) > 0) print ln
        close(sf); print ""; print; next
      }
      { print }
    ' "$tmp_file" > "$tmp_file2"
    rm -f "$section_file"
    mv "$tmp_file2" "$tmp_file"
  else
    # Ensure file ends with exactly one blank line before section
    printf '\n%s' "$new_section" >> "$tmp_file"
  fi
fi

# Idempotent write: only update if content changed
if ! cmp -s "$tmp_file" "$PROBLEM_FILE"; then
  mv "$tmp_file" "$PROBLEM_FILE"
else
  rm -f "$tmp_file"
fi

exit 0
