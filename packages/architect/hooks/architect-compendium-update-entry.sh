#!/usr/bin/env bash
# architect-compendium-update-entry.sh — PostToolUse:Edit|Write hook.
#
# ADR-078 Phase 1, Option 9 (architect-on-edit writes README entry directly).
# RFC-014 Story A. Closes P337 structurally: every edit to a per-ADR body
# triggers a same-hook re-authoring of that ADR's entry in the decisions
# compendium (docs/decisions/README.md), so body↔compendium drift becomes
# impossible by construction rather than detectable-and-fixable.
#
# Mechanism:
#   1. Fires on Edit/Write events whose file_path is docs/decisions/<NNN>-*.md
#      (excludes README.md and any -history.md / -summary.md sibling).
#   2. Spawns a `claude -p` subprocess invoking wr-architect:agent with the
#      just-edited ADR body + the current README entry for that ADR-ID (or an
#      empty string when the ADR is new). The architect emits the updated
#      compendium entry shape (### ADR-NNN header + Status/Oversight/Supersedes
#      badges + **Decides:** + **Confirmation:** + **Related:**).
#   3. Captures the architect's emit from the subprocess JSON `.result` field;
#      replaces the existing entry block for that ADR-ID in-place, or inserts a
#      new one in numeric-sort order under the correct section (in-force for
#      proposed/accepted; historical for superseded/rejected/deprecated).
#   4. Stages docs/decisions/README.md so it lands in the same commit as the
#      ADR body change (paired by architect-readme-pairing-check.sh — Story B).
#
# Failure mode (ADR-078 Confirmation criterion l): if the subprocess fails
# (network, quota, model error) or emits nothing usable, the hook logs a
# warning to stderr and leaves README unchanged (degraded mode). It does NOT
# block the body edit (exit 0). The stale README is then caught by Story B's
# pre-commit pairing check on the next `git commit`, surfacing the failure for
# manual recovery via `wr-architect-generate-decisions-compendium`.
#
# Opt-out (ADR-078 Confirmation criterion k): set
# ARCHITECT_AUTO_UPDATE_COMPENDIUM=0 to suppress the hook entirely (for
# API-cost-sensitive adopter setups). The hook self-suppresses with a stderr
# message directing the user to the manual generator.
#
# The compendium is no longer generator-derived (ADR-077 criterion b/g/h
# retired by ADR-078); the generator script is kept as a one-release-cycle
# backstop only (RFC-014 Story C). ADR-031 authoritative-state is preserved:
# the per-ADR body remains the source of truth; this entry is a derived view.

set -uo pipefail

# --- Opt-out (criterion k) -------------------------------------------------
if [ "${ARCHITECT_AUTO_UPDATE_COMPENDIUM:-1}" = "0" ]; then
    echo "architect-compendium-update-entry: ARCHITECT_AUTO_UPDATE_COMPENDIUM=0 — hook suppressed. Refresh the compendium manually with: wr-architect-generate-decisions-compendium && git add docs/decisions/README.md" >&2
    exit 0
fi

# PostToolUse input arrives on stdin as JSON.
input=$(cat)

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null)
case "$tool_name" in
    Edit|Write|MultiEdit) ;;
    *) exit 0 ;;
esac

file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
[ -n "$file_path" ] || exit 0

# Path gate: only docs/decisions/<NNN>-*.md ADR bodies. Exclude README and the
# non-ADR sibling files the generator also excludes.
base=$(basename "$file_path")
case "$file_path" in
    */docs/decisions/*|docs/decisions/*) ;;
    *) exit 0 ;;
esac
case "$base" in
    README.md|*-history.md|*-summary.md) exit 0 ;;
esac
# Must be a numbered ADR file (NNN-...).
echo "$base" | grep -qE '^[0-9]+-' || exit 0

adr_id_padded=$(echo "$base" | grep -oE '^[0-9]+')   # zero-padded form for display (ADR-049)
adr_id=$((10#$adr_id_padded))                        # numeric form for sort comparison (49)

# Resolve repo root so the README path + git staging are stable regardless of
# the hook's runtime CWD (P191 project-root anchoring).
project_dir="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$project_dir" ]; then
    project_dir=$(git rev-parse --show-toplevel 2>/dev/null) || project_dir="$PWD"
fi
readme="$project_dir/docs/decisions/README.md"

# The edited ADR body must exist on disk (the Write/Edit already landed —
# PostToolUse fires after the tool succeeds).
if [ ! -f "$file_path" ]; then
    # Try the project-root-relative path if file_path was relative.
    if [ -f "$project_dir/$file_path" ]; then
        file_path="$project_dir/$file_path"
    else
        echo "architect-compendium-update-entry: edited ADR body not found ($file_path) — leaving compendium unchanged" >&2
        exit 0
    fi
fi
[ -f "$readme" ] || {
    echo "architect-compendium-update-entry: compendium not found ($readme) — leaving unchanged (run wr-architect-generate-decisions-compendium to bootstrap)" >&2
    exit 0
}

# --- Determine target section from the ADR's status ------------------------
adr_status=$(awk '
    /^---$/ { fm = !fm; if (!fm) exit; next }
    fm && /^status:/ {
        sub(/^status: */, ""); gsub(/^["'"'"']|["'"'"']$/, "")
        sub(/^ +/, ""); sub(/ +$/, ""); print; exit
    }
' "$file_path")
case "$adr_status" in
    superseded|rejected|deprecated) target_section="historical" ;;
    *) target_section="inforce" ;;
esac

# --- Extract the current README entry block for this ADR-ID -----------------
# Block = the `### ADR-<id> —` line and following lines up to the next
# `### ` / `## ` / `---` / EOF. Empty when the ADR is new.
current_entry=$(awk -v id="$adr_id" '
    function bid(l,   s){ s=l; sub(/^### ADR-/,"",s); return s+0 }
    {
        if ($0 ~ /^### ADR-[0-9]+/) { cap = (bid($0)==id) ? 1 : 0; if (cap) { print; next } }
        else if ($0 ~ /^### / || $0 ~ /^## / || $0 ~ /^---[[:space:]]*$/) { cap = 0 }
        if (cap) print
    }
' "$readme")

# --- Spawn the architect subprocess (claude -p) ----------------------------
adr_body=$(cat "$file_path")
prompt=$(cat <<PROMPT
You are the wr-architect compendium-entry author. Re-author the single
docs/decisions/README.md compendium entry for ADR-${adr_id_padded} from its
current body. Emit ONLY the entry block — no preamble, no code fence, no
trailing commentary. The entry shape is exactly:

### ADR-${adr_id_padded} — <title>
**Status:** <status> | **Oversight:** <human-oversight> [| **Supersedes:** <list>]
**Decides:** <one or two sentence semantic TL;DR of the Decision Outcome — what was decided and why, in plain prose>
**Confirmation:** <short "; "-joined digest of the Confirmation criteria>
**Related:** <deduped ADR-NNN list from the Related section and inline mentions>

Omit the Supersedes badge when the body has no supersedes. Omit any of the
Decides / Confirmation / Related lines only when the body genuinely has no such
content. Keep the whole entry compact (a few lines) — it is a routine-load
index surface, not the full body.

--- CURRENT COMPENDIUM ENTRY (may be empty if the ADR is new) ---
${current_entry}

--- ADR BODY ---
${adr_body}
PROMPT
)

# Capture the architect's emit. `claude -p --output-format json` returns a JSON
# envelope with a `.result` string. PATH-resolved `claude` (so bats fixtures can
# stub it with a fixed-response shim placed first on PATH — RFC-014 SQ-014-1).
subprocess_out=$(printf '%s' "$prompt" | claude -p --output-format json 2>/dev/null)
subprocess_rc=$?

new_entry=""
if [ "$subprocess_rc" -eq 0 ] && [ -n "$subprocess_out" ]; then
    new_entry=$(printf '%s' "$subprocess_out" | jq -r '.result // empty' 2>/dev/null)
fi

# Degraded mode (criterion l): no usable emit → warn + leave README unchanged,
# do NOT block the edit.
if [ -z "$new_entry" ] || ! printf '%s' "$new_entry" | grep -qE '^### ADR-[0-9]+'; then
    echo "architect-compendium-update-entry: architect subprocess produced no usable entry for ADR-${adr_id} (degraded mode) — compendium left unchanged. The pre-commit pairing check will surface this; recover with wr-architect-generate-decisions-compendium && git add docs/decisions/README.md" >&2
    exit 0
fi

# --- Capture pre-modification invariants for the fail-closed guard (P367) ---
# A single-entry re-author must change ONLY the edited ADR's entry. Snapshot the
# set of all ADR ids and the count of `## ` section headers, plus a backup of
# the whole file, so the post-condition guard below can detect (and reject) any
# silent tail truncation or spurious-id/section injection from the subprocess.
before_ids=$(grep -oE '^### ADR-[0-9]+' "$readme" | grep -oE '[0-9]+' | sed 's/^0*//' | sort -n -u)
before_sections=$(grep -cE '^## ' "$readme")
entry_existed=0
[ -n "$current_entry" ] && entry_existed=1

# --- Apply the entry: delete any existing block, then insert sorted ---------
tmp_entry=$(mktemp -t architect-entry.XXXXXX)
tmp_readme=$(mktemp -t architect-readme.XXXXXX)
backup_readme=$(mktemp -t architect-readme-orig.XXXXXX)
trap 'rm -f "$tmp_entry" "$tmp_readme" "$backup_readme"' EXIT
cp "$readme" "$backup_readme"
printf '%s\n' "$new_entry" > "$tmp_entry"

# Pass 1 — remove any existing block for this ADR-ID (and the single blank line
# that precedes it), collapsing blank runs so deletion leaves no double-gap.
awk -v id="$adr_id" '
    function bid(l,   s){ s=l; sub(/^### ADR-/,"",s); return s+0 }
    {
        if ($0 ~ /^### ADR-[0-9]+/) {
            if (bid($0)==id) { skipping=1; pendingblank=0; next }
            skipping=0
            if (pendingblank) { print ""; pendingblank=0 }
            print; next
        }
        if (skipping) {
            if ($0 ~ /^### / || $0 ~ /^## / || $0 ~ /^---[[:space:]]*$/) { skipping=0 }
            else next
        }
        if ($0 ~ /^[[:space:]]*$/) { pendingblank=1; next }
        if (pendingblank) { print ""; pendingblank=0 }
        print
    }
    END { if (pendingblank) print "" }
' "$readme" > "$tmp_readme"

# Pass 2 — insert the new block in numeric-sort order within the target section.
awk -v id="$adr_id" -v section="$target_section" -v entryfile="$tmp_entry" '
    function bid(l,   s){ s=l; sub(/^### ADR-/,"",s); return s+0 }
    BEGIN {
        while ((getline l < entryfile) > 0) entry = (entry=="" ? l : entry "\n" l)
        insec=0; done=0
    }
    /^## In-force decisions/   { insec=(section=="inforce") }
    /^## Historical decisions/ { insec=(section=="historical") }
    {
        if (!done && insec && $0 ~ /^### ADR-[0-9]+/ && bid($0) > id) {
            print entry; print ""; done=1
        }
        else if (!done && insec && ($0 ~ /^---[[:space:]]*$/ || ($0 ~ /^## / && $0 !~ /In-force decisions|Historical decisions/))) {
            print entry; print ""; done=1; insec=0
        }
        print
    }
    END { if (!done) { print ""; print entry } }
' "$tmp_readme" > "$readme"

# --- Fail-closed post-condition guard (P367, ADR-078 criterion l) -----------
# The rewrite must preserve every OTHER ADR's entry and the section structure;
# only the edited ADR's entry may change (it may be newly added). If the result
# dropped a pre-existing entry (silent tail truncation) or injected spurious ids
# or sections (malformed subprocess emit), restore the original and degrade —
# never stage a corrupted compendium. Same contract as the subprocess-failure
# path: exit 0, do not block the body edit; Story B's pairing check surfaces it.
after_ids=$(grep -oE '^### ADR-[0-9]+' "$readme" | grep -oE '[0-9]+' | sed 's/^0*//' | sort -n -u)
after_sections=$(grep -cE '^## ' "$readme")
expected_ids="$before_ids"
if [ "$entry_existed" -eq 0 ]; then
    expected_ids=$(printf '%s\n%s\n' "$before_ids" "$adr_id" | sed '/^$/d' | sort -n -u)
fi
edited_count=$(grep -oE '^### ADR-[0-9]+' "$readme" | grep -oE '[0-9]+' | sed 's/^0*//' | grep -cxF "$adr_id")
if [ "$after_ids" != "$expected_ids" ] || [ "$after_sections" != "$before_sections" ] || [ "$edited_count" -ne 1 ]; then
    cp "$backup_readme" "$readme"
    echo "architect-compendium-update-entry: post-condition guard tripped for ADR-${adr_id} (compendium entry-set or section drift — possible truncation or spurious injection); restored README unchanged (degraded mode), not staged. Recover with wr-architect-generate-decisions-compendium && git add docs/decisions/README.md" >&2
    exit 0
fi

# Stage the compendium so it lands in the same commit as the ADR body change.
( cd "$project_dir" && git add docs/decisions/README.md 2>/dev/null ) || \
    echo "architect-compendium-update-entry: git add docs/decisions/README.md failed (not a git repo or staging error) — stage it manually before commit" >&2

echo "architect-compendium-update-entry: refreshed compendium entry for ADR-${adr_id} (${target_section})" >&2
exit 0
