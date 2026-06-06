#!/usr/bin/env bash
# Migrate a legacy single-file docs/BRIEFING.md to the per-topic
# docs/briefing/ tree expected by the wr-retrospective Tier-3 rotation
# contract (ADR-040). Idempotent: silently no-ops when the tree already
# exists or when no legacy file is present.
#
# Closes P204.
#
# Usage:
#   wr-retrospective-migrate-briefing [--dry-run] [--force]
#
# @adr ADR-040 (session-start briefing surface — target tree shape)
# @adr ADR-014 (governance skills commit their own work — invoked by SKILL.md)
# @adr ADR-038 (progressive disclosure — SKILL.md + REFERENCE.md split)
# @adr ADR-049 (plugin-bundled scripts on $PATH)
# @problem P204 (no migrate-briefing skill — legacy → tree migration manual)

set -euo pipefail

DRY_RUN=0
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --force)   FORCE=1;   shift ;;
    -h|--help)
      cat <<EOF
Usage: wr-retrospective-migrate-briefing [--dry-run] [--force]

Migrate legacy docs/BRIEFING.md to docs/briefing/<topic>.md tree.

Flags:
  --dry-run   Print the planned topic slugs and file paths; no writes.
  --force     Re-run even when docs/briefing/README.md already exists.
EOF
      exit 0 ;;
    *)
      printf 'migrate-briefing: unknown flag: %s\n' "$1" >&2
      exit 2 ;;
  esac
done

LEGACY="docs/BRIEFING.md"
TREE_DIR="docs/briefing"
TREE_INDEX="$TREE_DIR/README.md"

# Idempotency: tree already present.
if [ -f "$TREE_INDEX" ] && [ "$FORCE" != "1" ]; then
  echo "migrate-briefing: $TREE_INDEX already exists; tree already migrated (no action)."
  exit 0
fi

# Idempotency: no legacy file (or empty stub).
if [ ! -s "$LEGACY" ]; then
  echo "migrate-briefing: $LEGACY missing or empty; nothing to migrate (no action)."
  exit 0
fi

# Slug derivation: heading text → kebab-case-truncated-to-60.
derive_slug() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-60
}

# Stage outputs under a temp dir so a parse failure mid-walk leaves the
# repo untouched. Atomic-move into place after the walk completes.
STAGING="$(mktemp -d -t migrate-briefing.XXXXXX)"
trap 'rm -rf "$STAGING"' EXIT

PREAMBLE_FILE="$STAGING/__preamble__"
INDEX_LINES="$STAGING/__index__"
: > "$PREAMBLE_FILE"
: > "$INDEX_LINES"

current_slug="__preamble__"
current_file="$PREAMBLE_FILE"
in_fence=0
topic_index=0

# Track slug → original-heading so the index row preserves human label.
declare -A SLUG_HEADING
declare -A SLUG_TAKEN

while IFS= read -r line || [ -n "$line" ]; do
  # Column-anchored fence toggle (``` or ~~~ at column 0).
  if [[ "$line" =~ ^(\`\`\`|~~~) ]]; then
    in_fence=$(( 1 - in_fence ))
    printf '%s\n' "$line" >> "$current_file"
    continue
  fi

  # Inside a fence: emit verbatim, never promote.
  if [ "$in_fence" -eq 1 ]; then
    printf '%s\n' "$line" >> "$current_file"
    continue
  fi

  # H2 marker → close current topic, start new one.
  if [[ "$line" =~ ^\#\#[[:space:]]+(.+)$ ]]; then
    heading_text="${BASH_REMATCH[1]}"
    base_slug="$(derive_slug "$heading_text")"
    if [ -z "$base_slug" ]; then
      topic_index=$(( topic_index + 1 ))
      base_slug="topic-$topic_index"
    fi
    # Collision handling.
    candidate="$base_slug"
    n=2
    while [ -n "${SLUG_TAKEN[$candidate]:-}" ]; do
      candidate="${base_slug}-${n}"
      n=$(( n + 1 ))
    done
    SLUG_TAKEN[$candidate]=1
    SLUG_HEADING[$candidate]="$heading_text"
    current_slug="$candidate"
    current_file="$STAGING/${current_slug}.md"
    : > "$current_file"
    printf '%s\n' "$line" >> "$current_file"
    echo "$current_slug" >> "$INDEX_LINES"
    continue
  fi

  # Plain content → emit to current topic body.
  printf '%s\n' "$line" >> "$current_file"
done < "$LEGACY"

# Build the README index.
README_OUT="$STAGING/README.md"
today="$(date +%Y-%m-%d)"
{
  echo "# Project Briefing"
  echo
  echo "Migrated from legacy \`docs/BRIEFING.md\` via \`/wr-retrospective:migrate-briefing\` on $today."
  echo
  echo "## Critical Points (Session-Start Surface)"
  echo
  echo "_To be populated by the next \`/wr-retrospective:run-retro\` Step 1.5 signal-vs-noise pass (per ADR-040)._"
  echo
  echo "## Topic Index"
  echo
  echo "| File | Source heading |"
  echo "|---|---|"
  while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    heading="${SLUG_HEADING[$slug]:-$slug}"
    echo "| [${slug}.md](./${slug}.md) | ${heading} |"
  done < "$INDEX_LINES"
  if [ -s "$PREAMBLE_FILE" ]; then
    echo
    echo "## Preamble"
    echo
    cat "$PREAMBLE_FILE"
  fi
} > "$README_OUT"

# Dry-run: print the plan, do not write.
if [ "$DRY_RUN" = "1" ]; then
  echo "migrate-briefing: --dry-run plan:"
  echo "  index → $TREE_INDEX"
  while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    echo "  topic → $TREE_DIR/${slug}.md  (heading: ${SLUG_HEADING[$slug]:-?})"
  done < "$INDEX_LINES"
  echo "  rename → $LEGACY → $LEGACY.migrated-$today"
  exit 0
fi

# Atomic move into place.
mkdir -p "$TREE_DIR"
cp "$README_OUT" "$TREE_INDEX"
while IFS= read -r slug; do
  [ -z "$slug" ] && continue
  cp "$STAGING/${slug}.md" "$TREE_DIR/${slug}.md"
done < "$INDEX_LINES"

# Retire the legacy file under a date-stamped suffix so its content is
# preserved on disk but no longer matches the SessionStart hook's reads.
if git -C . rev-parse HEAD >/dev/null 2>&1; then
  git mv "$LEGACY" "${LEGACY}.migrated-${today}" 2>/dev/null \
    || mv "$LEGACY" "${LEGACY}.migrated-${today}"
else
  mv "$LEGACY" "${LEGACY}.migrated-${today}"
fi

# Final report.
echo "migrate-briefing: migrated $LEGACY → $TREE_DIR/ ($(wc -l < "$INDEX_LINES" | tr -d ' ') topic files + README index)."
echo "migrate-briefing: legacy file retired as ${LEGACY}.migrated-${today}."
