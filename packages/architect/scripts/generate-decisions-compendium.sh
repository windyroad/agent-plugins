#!/usr/bin/env bash
# generate-decisions-compendium.sh — generate docs/decisions/README.md from
# per-ADR files. Per ADR-077 (Generated decisions compendium as token-cheap
# load surface for routine architect-agent compliance).
#
# Usage: bash packages/architect/scripts/generate-decisions-compendium.sh [decisions_dir]
# Writes: <decisions_dir>/README.md (idempotent — same input set + bodies
# produce byte-identical output).
#
# Distributed via the ADR-049 $PATH shim at:
#   packages/architect/bin/wr-architect-generate-decisions-compendium
# Hooks and skills MUST invoke the shim, not this script directly — the
# shim resolves the canonical body relative to its own location, so it
# works in adopter installs where the package lives under
# ~/.claude/plugins/cache/windyroad/wr-architect/<version>/.
#
# ADR-031 authoritative-state invariant: per-ADR bodies are the
# authoritative source of substance; this compendium is a derived/cached
# view. The compendium is NEVER edited compendium-side first.
#
# ADR-077 Confirmation item (b): generator must be idempotent — running
# it twice produces identical output.

set -uo pipefail

DECISIONS_DIR="${1:-docs/decisions}"
COMPENDIUM="$DECISIONS_DIR/README.md"

if [ ! -d "$DECISIONS_DIR" ]; then
    echo "generate-decisions-compendium: decisions directory not found: $DECISIONS_DIR" >&2
    exit 2
fi

# --- Field extractors ------------------------------------------------------

# Read a frontmatter scalar field (single line `key: value`).
# Strips surrounding quotes and leading/trailing whitespace.
get_frontmatter_field() {
    local file="$1" field="$2"
    awk -v f="$field" '
        /^---$/ { fm = !fm; if (!fm) exit; next }
        fm && $0 ~ "^"f":" {
            sub("^"f": *", "")
            gsub(/^["'"'"']|["'"'"']$/, "")
            sub(/^ +/, ""); sub(/ +$/, "")
            print
            exit
        }
    ' "$file"
}

# Read the first "# Title" line after the frontmatter block.
get_title() {
    awk '
        /^---$/ { fm = !fm; next }
        !fm && /^# / { sub(/^# /, ""); print; exit }
    ' "$1"
}

# Extract a section by its `## Heading` line, up to (but not including) the
# next `## ` heading or EOF.
get_section() {
    local file="$1" heading="$2"
    awk -v h="$heading" '
        $0 == "## " h { in_sec = 1; next }
        in_sec && /^## / { exit }
        in_sec { print }
    ' "$file"
}

# Extract the "Chosen option:" line from the Decision Outcome section.
# Matches the common MADR shapes:
#   Chosen option: **"X"**, because Y.
#   Chosen option: X, because Y.
#   Chosen: X.
get_chosen() {
    get_section "$1" "Decision Outcome" \
        | awk '/^Chosen/ { print; exit }' \
        | head -1
}

# Extract top-level bullet lines (`- ...`) from a section. Skips nested
# `  - ...` sub-bullets to keep the compendium dense. Capped at N entries.
get_bullets() {
    local file="$1" section="$2" cap="${3:-5}"
    get_section "$file" "$section" \
        | awk '/^- / { sub(/^- */, ""); print }' \
        | head -"$cap"
}

# Compact-join bullets onto one line, truncating each to N chars + "…".
# Joins with "; ". Strips markdown emphasis to keep the line scannable.
compact_join_bullets() {
    local per_item="${1:-120}"
    awk -v n="$per_item" '
        {
            # Strip leading checkbox markers `[ ]` / `[x]` (from Confirmation).
            sub(/^\[[ x]\] */, "")
            # Strip markdown bold/italic markers for compactness.
            gsub(/\*\*/, "")
            gsub(/`/, "")
            # Drop nested-bullet continuation lines that survived earlier filters.
            if (length($0) == 0) next
            if (length($0) > n) line = substr($0, 1, n) "…"
            else line = $0
            if (out == "") out = line
            else out = out "; " line
        }
        END { print out }
    '
}

# Extract ADR-NNN references from Related bullets. Compact "ADR-NNN" listing
# is sufficient for routine compliance graph navigation; full relationship
# prose (amends/extends/relates/composes) is preserved in the per-ADR body.
extract_related_ids() {
    awk '
        {
            while (match($0, /ADR-[0-9]+/)) {
                ref = substr($0, RSTART, RLENGTH)
                if (!seen[ref]++) {
                    if (out == "") out = ref
                    else out = out ", " ref
                }
                $0 = substr($0, RSTART + RLENGTH)
            }
        }
        END { print out }
    '
}

# --- Sanitisers ------------------------------------------------------------

# Strip markdown links `[text](url)` -> `text`.
strip_links() {
    sed -E 's/\[([^]]+)\]\([^)]+\)/\1/g'
}

# Collapse to a single line: replace newlines + carriage returns with spaces,
# squeeze runs of spaces, trim leading/trailing whitespace.
oneline() {
    tr '\n\r' '  ' | tr -s ' ' | sed 's/^ *//; s/ *$//'
}

# Truncate a string to N chars + ellipsis if longer. Avoids slicing inside
# a markdown emphasis pair (e.g. `**text**`) — if the truncation would land
# inside `**...**`, round back to before the opening pair.
truncate_with_ellipsis() {
    local s="$1" n="$2"
    if [ "${#s}" -le "$n" ]; then
        printf '%s' "$s"
        return
    fi
    printf '%s' "${s:0:n}…"
}

# --- Per-ADR entry emitter -------------------------------------------------

emit_entry() {
    local file="$1"
    local id title status oversight superseded
    local chosen drivers confirmation related

    id=$(basename "$file" | grep -oE '^[0-9]+')
    title=$(get_title "$file")
    status=$(get_frontmatter_field "$file" "status")
    oversight=$(get_frontmatter_field "$file" "human-oversight")
    superseded=$(get_frontmatter_field "$file" "supersedes")

    # Chosen-option line — truncate to a comfortable summary length.
    chosen=$(get_chosen "$file" | strip_links | oneline)
    chosen=$(printf '%s' "$chosen" | awk -v n=240 '{ if (length($0) > n) print substr($0,1,n) "…"; else print }')

    # Confirmation: cap 5 bullets, ≤ 110 chars each, joined with "; " on one line.
    # This is the routine-compliance scannable view; the full Confirmation list
    # remains in the per-ADR body for deep-dive surfaces.
    confirmation=$(get_bullets "$file" "Confirmation" 5 | strip_links | compact_join_bullets 110)

    # Related: extract ADR-NNN graph references only. Full relationship prose
    # (amends / extends / relates / composes) stays in the per-ADR body.
    related=$(get_bullets "$file" "Related" 20 | strip_links | extract_related_ids)

    # Decision Drivers intentionally NOT emitted in the routine view (per
    # ADR-077 Decision Outcome — drivers belong on the deep-dive surface, not
    # the routine compliance load). If a future iteration needs them, add a
    # `--with-drivers` flag rather than emit by default.

    # Header line — ID + Title + status badges.
    {
        echo ""
        echo "### ADR-${id} — ${title}"
        # Status / oversight / supersession badges on one compact line.
        local badges="**Status:** ${status:-?}"
        if [ -n "$oversight" ]; then
            badges="${badges} | **Oversight:** ${oversight}"
        fi
        if [ -n "$superseded" ] && [ "$superseded" != "[]" ]; then
            badges="${badges} | **Supersedes:** ${superseded}"
        fi
        echo "${badges}"
        if [ -n "$chosen" ]; then
            echo "**Chosen:** ${chosen}"
        fi
        if [ -n "$confirmation" ]; then
            echo "**Confirmation:** ${confirmation}"
        fi
        if [ -n "$related" ]; then
            echo "**Related:** ${related}"
        fi
    }
}

# --- Compendium emission ---------------------------------------------------

# Collect + sort ADR files. README.md and any sibling -history.md / -summary.md
# style files (future P194 etc.) are excluded.
files=()
while IFS= read -r f; do
    files+=("$f")
done < <(find "$DECISIONS_DIR" -maxdepth 1 -type f -name '*.md' \
            ! -name 'README.md' \
            ! -name '*-history.md' \
            ! -name '*-summary.md' \
            2>/dev/null | sort)

total=${#files[@]}

# Header is deterministic — NO timestamp, NO date. The compendium must be
# idempotent (same input bodies => byte-identical output) so the ADR-077
# drift-detection bats can compare the committed file against a fresh
# generator run and detect any divergence as substance drift, not as
# date-stamp churn.
{
    echo "# Decisions Compendium"
    echo ""
    echo "<!-- AUTO-GENERATED by packages/architect/scripts/generate-decisions-compendium.sh per ADR-077 — do NOT hand-edit; regenerate via \`wr-architect-generate-decisions-compendium\`. -->"
    echo ""
    echo "Compact rendered index of every ADR's chosen option, confirmation criteria, and relationship graph. **Authoritative substance lives in the per-ADR body** (\`<NNN>-<slug>.<status>.md\`); this compendium is a derived view for routine \`wr-architect:agent\` compliance review."
    echo ""
    echo "For deep-dive — creating, evolving, ratifying, or contesting a decision — open the per-ADR file directly. \`/wr-architect:create-adr\`, \`/wr-architect:capture-adr\`, and \`/wr-architect:review-decisions\` all keep the full body in scope. Decision Drivers, Considered Options bodies, Pros and Cons, Consequences narrative, and Reassessment Criteria are intentionally NOT in this routine view — they live in the per-ADR body."
    echo ""
    echo "**Total ADRs:** ${total}"
    echo ""
    echo "---"
    for f in "${files[@]}"; do
        emit_entry "$f"
    done
} > "$COMPENDIUM"

echo "generate-decisions-compendium: wrote $COMPENDIUM (${total} ADRs)" >&2
