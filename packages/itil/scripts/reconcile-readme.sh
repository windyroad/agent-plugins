#!/usr/bin/env bash
# packages/itil/scripts/reconcile-readme.sh
#
# Diagnose-only drift detector for docs/problems/README.md vs filesystem
# truth. Reads ticket files from BOTH the flat layout
# `<problems-dir>/<NNN>-*.<status>.md` AND the per-state subdir layout
# `<problems-dir>/<status>/<NNN>-*.md` (RFC-002 dual-tolerant migration
# window), parses the README's WSJF Rankings + Verification Queue +
# Closed tables, and reports each disagreement.
#
# Usage:
#   reconcile-readme.sh [<problems-dir>]
#
# Default <problems-dir> is ./docs/problems.
#
# Dual-layout precedence: when the same ID appears in both layout-halves
# (transient mid-migration race between `git mv` and README refresh),
# the per-state subdir wins — ADR-031 §"Authoritative state signal"
# treats subdirectory as the post-migration ground truth.
#
# Usage with the repair flag:
#   reconcile-readme.sh --fix-clashes [<problems-dir>]
#
# Exit codes:
#   0 = clean (README matches filesystem)
#   1 = drift detected (structured diff to stdout)
#   2 = parse error (README missing or malformed)
#
# With --fix-clashes, detection re-runs after the renumber and the exit
# code reports what survives: 0 when the clash was the only drift, 1 when
# ordinary drift remains. So a caller branching on 1 learns what is
# actually left rather than reading a stale 1.
#
# Output format on drift (one line per drift entry, ≤ 150 bytes per
# ADR-038 progressive-disclosure budget):
#   DRIFT    <ID> wsjf-rankings: claims=<status> actual=<status>
#   MISSING  <ID> wsjf-rankings: actual=<status> file=<basename>
#   STALE    <ID> verification-queue: actual=<status>
#   MISMATCH <ID> closed: actual=<status>
#   CLASH    <ID> <state>/<basename>  <state>/<basename>
#
# Read-only by default — does NOT mutate the README. The
# /wr-itil:reconcile-readme skill applies README edits with
# narrative-aware preservation; this script's job is to report ground
# truth.
#
# --fix-clashes is the one exception: it moves the later-claiming ticket
# file to a free ID and rewrites references to it. It never touches the
# README, so the narrative-preservation contract above is intact.
#
# ── Reference-rewrite boundary (--fix-clashes) ──────────────────────────────
#
# Rewritten: docs/problems/**/*.md and docs/stories/**/*.md. Scoped to
# *.md so ID-keyed machine state (.outbound-responses-cache.json,
# .upstream-cache.json) is never touched.
#
# Reported, never rewritten — every other file under docs/ naming the ID,
# for three distinct reasons:
#
#   docs/decisions/**    A ratified decision body changes only by
#                        supersession (ADR-116).
#   docs/story-maps/**   The grid is generated from its JSON island; a
#                        text rewrite desynchronises the render and the
#                        oversight fingerprint (ADR-102, ADR-104,
#                        ADR-105). Edit via story-map-edit and re-render.
#   docs/jtbd/**         Jobs and personas carry a ratification marker
#                        whose integrity depends on edits being
#                        human-confirmed (ADR-068, ADR-110). NOT excluded
#                        as historical — this is a live surface.
#   docs/retros/**       Each entry records what was true when written,
#   docs/incidents/**    so re-pointing its identifiers rewrites history
#   docs/audits/**       rather than repairing it.
#   docs/briefing/**
#   docs/risks/**        Live surfaces, neither historical nor
#   docs/plans/**        ratification-bearing. Out of scope for this
#   docs/rfcs/**         change; widening the rewrite set to them is a
#                        separate decision.
#
# @problem P118
# @problem P170 (RFC-002 — dual-tolerant migration window)
# @problem P533 (duplicate ticket IDs silently swallowed by the ID-keyed map)
# @story STORY-085 (See the ID clash instead of the drift it causes)
# @adr ADR-019 (next-ID allocation is max(local, origin) + 1)
# @adr ADR-116 (ratified decisions change only by supersession)
# @adr ADR-102 / ADR-104 / ADR-105 (story maps render from their island)
# @adr ADR-068 / ADR-110 (jobs and personas carry a ratification marker)
# @problem P252 (Inbound Upstream Reports rows mis-attributed to VQ)
# @adr ADR-014 (Reconciliation as preflight robustness layer)
# @adr ADR-022 (Verification Pending lifecycle excludes from WSJF Rankings)
# @adr ADR-031 (Per-state subdir is post-migration authoritative state signal)
# @adr ADR-038 (Progressive disclosure — per-row byte budget)
# @adr ADR-062 (Inbound upstream-report discovery + assessment pipeline)
# @rfc RFC-004 (P079 inbound-upstream-report discovery)
# @jtbd JTBD-006 (Progress the Backlog While I'm Away)
# @jtbd JTBD-001 (Enforce Governance Without Slowing Down)
# @jtbd JTBD-302 (Trust That the README Describes the Plugin I Just Installed)

set -uo pipefail

FIX_CLASHES=0
if [ "${1:-}" = "--fix-clashes" ]; then
  FIX_CLASHES=1
  shift
fi

PROBLEMS_DIR="${1:-docs/problems}"
README="${PROBLEMS_DIR}/README.md"
# The docs root, for the --fix-clashes report scan. Only trusted when the
# tickets really do live in `<docs>/problems`; otherwise the parent is
# some unrelated directory (a test fixture, a temp dir) and scanning it
# would sweep the whole filesystem around it.
if [ "$(basename "$PROBLEMS_DIR")" = "problems" ]; then
  DOCS_DIR="$(dirname "$PROBLEMS_DIR")"
else
  DOCS_DIR="$PROBLEMS_DIR"
fi

# ── Pre-checks ──────────────────────────────────────────────────────────────

if [ ! -f "$README" ]; then
  echo "PARSE_ERROR: README not found at ${README}" >&2
  exit 2
fi

if ! grep -q '^## WSJF Rankings' "$README"; then
  echo "PARSE_ERROR: '## WSJF Rankings' header missing in ${README}" >&2
  exit 2
fi

# ── Build filesystem truth: ID → status ─────────────────────────────────────
#
# RFC-002 dual-tolerant enumeration: walk BOTH the flat layout and the
# per-state subdir layout. Per-state subdir wins on collision (mid-
# migration race; per-state is the migration target per ADR-031).

declare -A FS_STATUS
# Every file that claimed each ID, newline-joined, kept per layout half.
# FS_STATUS is keyed by ID and so is last-writer-wins: correct for the
# cross-layout migration race it was built for, wrong for two genuinely
# distinct tickets — the second disappears and the drift check then
# blames whichever survived (P533). Keeping the halves apart lets a
# flat+subdir pair stay the migration transient it is while two files in
# the SAME half are reported as the clash they are.
declare -A FLAT_FILES
declare -A SUB_FILES
shopt -s nullglob
# Flat layout: docs/problems/<NNN>-<title>.<state>.md
# Status classified from filename suffix.
for f in "$PROBLEMS_DIR"/[0-9][0-9][0-9]-*.open.md \
         "$PROBLEMS_DIR"/[0-9][0-9][0-9]-*.known-error.md \
         "$PROBLEMS_DIR"/[0-9][0-9][0-9]-*.verifying.md \
         "$PROBLEMS_DIR"/[0-9][0-9][0-9]-*.closed.md \
         "$PROBLEMS_DIR"/[0-9][0-9][0-9]-*.parked.md; do
  base="$(basename "$f")"
  num="${base%%-*}"
  id="P${num}"
  # `ticket_status` (not bash `status`) — zsh has `$status` as a read-only
  # built-in mapping to `$?`. Defensive rename per P133 even though this
  # script's `#!/usr/bin/env bash` shebang means it never runs under zsh.
  case "$base" in
    *.open.md)         ticket_status="open" ;;
    *.known-error.md)  ticket_status="known-error" ;;
    *.verifying.md)    ticket_status="verifying" ;;
    *.closed.md)       ticket_status="closed" ;;
    *.parked.md)       ticket_status="parked" ;;
    *)                 continue ;;
  esac
  FS_STATUS["$id"]="$ticket_status"
  FLAT_FILES["$id"]+="$f"$'\n'
done
# Per-state subdir layout: docs/problems/<state>/<NNN>-<title>.md
# Status derived from parent directory name (the subdirectory IS the
# state signal post-migration). Writes after the flat loop so per-state
# wins on cross-layout ID collision (ADR-031 authoritative state).
for ticket_status in open known-error verifying closed parked; do
  for f in "$PROBLEMS_DIR"/"$ticket_status"/[0-9][0-9][0-9]-*.md; do
    base="$(basename "$f")"
    num="${base%%-*}"
    id="P${num}"
    FS_STATUS["$id"]="$ticket_status"
    SUB_FILES["$id"]+="$f"$'\n'
  done
done
shopt -u nullglob

# Per-state wins on cross-layout collision, so an ID present in both
# halves is the ADR-031 migration transient and not a clash. Collapse to
# the winning half; a clash is then simply more than one file left.
declare -A FS_FILES
for id in "${!FLAT_FILES[@]}" "${!SUB_FILES[@]}"; do
  FS_FILES["$id"]="${SUB_FILES[$id]:-${FLAT_FILES[$id]}}"
done

# ── Parse README sections into ID buckets ───────────────────────────────────
# We use the section-header line numbers to slice the file into ranges.

WSJF_START=$(grep -n '^## WSJF Rankings' "$README" | head -1 | cut -d: -f1)
VQ_START=$(grep -n '^## Verification Queue' "$README" | head -1 | cut -d: -f1)
# Inbound Upstream Reports (ADR-062 / RFC-004) sits between Verification
# Queue and Closed when populated. Its `Matched local ticket` column
# carries `| P<NNN> |` cross-refs that look like VQ rows but live in a
# distinct section. The VQ slice MUST terminate at this header when
# present, otherwise its rows get miscounted as VQ entries (P252).
INBOUND_START=$(grep -n '^## Inbound Upstream Reports' "$README" | head -1 | cut -d: -f1)
CLOSED_START=$(grep -n '^## Closed' "$README" | head -1 | cut -d: -f1)
PARKED_START=$(grep -n '^## Parked' "$README" | head -1 | cut -d: -f1)
END_LINE=$(wc -l < "$README")

# Sentinel each end with the next section start (or EOF). The VQ_END
# cascade prefers INBOUND_START when present so Inbound rows are
# excluded from VQ extraction (P252).
WSJF_END=${VQ_START:-${INBOUND_START:-${CLOSED_START:-${PARKED_START:-$END_LINE}}}}
VQ_END=${INBOUND_START:-${CLOSED_START:-${PARKED_START:-$END_LINE}}}
CLOSED_END=${PARKED_START:-$END_LINE}
PARKED_END=$END_LINE

# Extract IDs claimed by each section. Only data rows of the form
#   | ... | P<NNN> | ... |
# count; header + separator rows are skipped naturally because they
# do not contain a P<NNN> token in the second column.

extract_section_ids() {
  local start="$1" end="$2"
  [ -z "$start" ] && return 0
  sed -n "${start},${end}p" "$README" \
    | grep -oE '\| *P[0-9]{3} *\|' \
    | grep -oE 'P[0-9]{3}' \
    | sort -u
}

README_WSJF_IDS="$(extract_section_ids "$WSJF_START" "$WSJF_END")"
README_VQ_IDS="$(extract_section_ids "$VQ_START" "$VQ_END")"
README_CLOSED_IDS="$(extract_section_ids "$CLOSED_START" "$CLOSED_END")"
README_PARKED_IDS="$(extract_section_ids "$PARKED_START" "$PARKED_END")"

# ── Diff ─────────────────────────────────────────────────────────────────────

DRIFT_LINES=()

# (1) Each ID listed in WSJF Rankings must be .open.md or .known-error.md
#     on disk. .verifying.md → drift (belongs in VQ); .closed.md → drift;
#     .parked.md → drift; missing → drift.
while read -r id; do
  [ -z "$id" ] && continue
  actual="${FS_STATUS[$id]:-missing}"
  case "$actual" in
    open|known-error)
      : # ok
      ;;
    *)
      DRIFT_LINES+=("DRIFT    ${id} wsjf-rankings: claims=open actual=${actual}")
      ;;
  esac
done <<< "$README_WSJF_IDS"

# (2) Each ID listed in Verification Queue must be .verifying.md on disk.
#     .closed.md → STALE (drift class P062 closure didn't refresh);
#     .open.md / .known-error.md → STALE; missing → STALE.
while read -r id; do
  [ -z "$id" ] && continue
  actual="${FS_STATUS[$id]:-missing}"
  case "$actual" in
    verifying)
      : # ok
      ;;
    *)
      DRIFT_LINES+=("STALE    ${id} verification-queue: actual=${actual}")
      ;;
  esac
done <<< "$README_VQ_IDS"

# (3) Each ID listed in Closed section must be .closed.md on disk.
while read -r id; do
  [ -z "$id" ] && continue
  actual="${FS_STATUS[$id]:-missing}"
  case "$actual" in
    closed)
      : # ok
      ;;
    *)
      DRIFT_LINES+=("MISMATCH ${id} closed: actual=${actual}")
      ;;
  esac
done <<< "$README_CLOSED_IDS"

# (4) Each .open.md / .known-error.md file on disk must appear in WSJF
#     Rankings. Build a lookup set for quick membership tests.
declare -A IN_WSJF
while read -r id; do
  [ -z "$id" ] && continue
  IN_WSJF["$id"]=1
done <<< "$README_WSJF_IDS"

declare -A IN_VQ
while read -r id; do
  [ -z "$id" ] && continue
  IN_VQ["$id"]=1
done <<< "$README_VQ_IDS"

for id in "${!FS_STATUS[@]}"; do
  ticket_status="${FS_STATUS[$id]}"
  case "$ticket_status" in
    open|known-error)
      if [ -z "${IN_WSJF[$id]:-}" ]; then
        DRIFT_LINES+=("MISSING  ${id} wsjf-rankings: actual=${ticket_status}")
      fi
      ;;
    verifying)
      if [ -z "${IN_VQ[$id]:-}" ]; then
        DRIFT_LINES+=("MISSING  ${id} verification-queue: actual=${ticket_status}")
      fi
      ;;
    # closed and parked: not required to appear in their respective
    # sections (Closed is curated narrative; Parked is exhaustive but
    # an absence is a soft drift not flagged at this layer).
  esac
done

# (5) An ID claimed by more than one file is a clash, not drift. It is
#     reported ahead of everything else because the drift rows it causes
#     describe the wrong file (P533).

# `<state>/<basename>`, basename truncated to 40 chars, so the row stays
# inside the per-row budget with this repo's long ticket filenames.
clash_label() {
  local path="$1" base parent
  base="$(basename "$path")"
  parent="$(basename "$(dirname "$path")")"
  [ ${#base} -gt 40 ] && base="${base:0:40}..."
  printf '%s/%s' "$parent" "$base"
}

CLASH_IDS=()
for id in "${!FS_FILES[@]}"; do
  mapfile -t claimants < <(printf '%s' "${FS_FILES[$id]}" | grep -v '^$')
  [ "${#claimants[@]}" -gt 1 ] || continue
  CLASH_IDS+=("$id")
  DRIFT_LINES+=("CLASH    ${id} $(clash_label "${claimants[0]}")  $(clash_label "${claimants[1]}")")
done

# ── Repair (--fix-clashes only) ─────────────────────────────────────────────

if [ "$FIX_CLASHES" = "1" ] && [ "${#CLASH_IDS[@]}" -gt 0 ]; then
  # ADR-019 allocates against origin as well as the working tree, so a
  # renumber cannot land on an ID created on the remote and recreate the
  # clash it is repairing. The base ref is resolved rather than assumed:
  # an adopter's default branch may not be `main`, and assuming it is the
  # same class of defect as the gates hardcoded to the home-repo shape.
  BASE_REF="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)" || BASE_REF=""
  BASE_REF="${BASE_REF#origin/}"
  [ -n "$BASE_REF" ] || BASE_REF="main"

  local_max=$(ls "$PROBLEMS_DIR"/*.md "$PROBLEMS_DIR"/*/*.md 2>/dev/null \
    | sed 's|.*/||' | grep -oE '^[0-9]+' | sort -n | tail -1)
  origin_max=$(git ls-tree -r --name-only "origin/${BASE_REF}" "$PROBLEMS_DIR/" 2>/dev/null \
    | sed 's|.*/||' | grep -oE '^[0-9]+' | sort -n | tail -1)
  if [ -z "$origin_max" ]; then
    echo "NOTE     no origin/${BASE_REF} — allocating from the working tree only, ordering by mtime"
  fi
  next=$(( 10#$(printf '%s\n%s\n' "${local_max:-0}" "${origin_max:-0}" | sort -n | tail -1) ))

  # First-add commit on the resolved base ref decides who claimed the
  # number first. Outside a repository (or for a file never committed)
  # this yields nothing and mtime stands in.
  first_seen() {
    local path="$1" t
    t=$(git log --diff-filter=A --format=%at "$BASE_REF" -- "$path" 2>/dev/null | tail -1)
    [ -n "$t" ] || t=$(git log --diff-filter=A --format=%at -- "$path" 2>/dev/null | tail -1)
    # GNU stat first: on a Mac with coreutils installed, `-f` means
    # "filesystem status" and happily prints a block-count dump instead
    # of failing, which then gets treated as a timestamp.
    [ -n "$t" ] || t=$(stat -c %Y "$path" 2>/dev/null)
    [ -n "$t" ] || t=$(stat -f %m "$path" 2>/dev/null)
    printf '%s' "${t:-0}"
  }

  for id in "${CLASH_IDS[@]}"; do
    mapfile -t claimants < <(printf '%s' "${FS_FILES[$id]}" | grep -v '^$')
    # Earliest claimant keeps the number; everyone after it is renumbered.
    mapfile -t ordered < <(
      for c in "${claimants[@]}"; do printf '%s\t%s\n' "$(first_seen "$c")" "$c"; done \
        | sort -n -k1,1 | cut -f2-
    )
    for loser in "${ordered[@]:1}"; do
      [ -f "$loser" ] || continue
      next=$(( next + 1 ))
      new_num=$(printf '%03d' "$next")
      old_num="${id#P}"
      new_id="P${new_num}"
      dir="$(dirname "$loser")"
      new_path="${dir}/${new_num}-$(basename "$loser" | cut -d- -f2-)"

      if git ls-files --error-unmatch "$loser" >/dev/null 2>&1; then
        git mv "$loser" "$new_path"
      else
        mv "$loser" "$new_path"
      fi

      # perl, not sed: BSD sed has no `\b`, and without a word boundary
      # renumbering P23 would also rewrite P238.
      rewrite_id_in() {
        perl -pi -e "s/\\bP${old_num}\\b/${new_id}/g; s/\\b(Problem|problem) ${old_num}\\b/\$1 ${new_num}/g" "$1"
      }

      # The ticket's own references follow it — unambiguous, they are
      # inside the file being renumbered.
      rewrite_id_in "$new_path"

      # A story the ticket names in its `## Stories` section, and which
      # names the ticket back, is the one foreign reference that resolves
      # without guessing: the two-way link says which of the two
      # claimants it meant. Every other reference to the old ID is
      # ambiguous by construction — both tickets carried it — so it is
      # reported below rather than guessed at.
      while IFS= read -r story_id; do
        story_file=$(grep -rl "^# ${story_id}:" --include='*.md' "$DOCS_DIR/stories" 2>/dev/null | head -1)
        [ -n "$story_file" ] || continue
        grep -qE "\\bP${old_num}\\b" "$story_file" || continue
        rewrite_id_in "$story_file"
        echo "RETRACE  ${new_id} in ${story_file#"$DOCS_DIR"/}"
      done < <(sed -n '/^## Stories/,/^## /p' "$new_path" | grep -oE '\bSTORY-[0-9]+\b' | sort -u)

      echo "RENUMBER ${id} -> ${new_id} $(clash_label "$new_path")"

      # Everything else under docs/ that names the old ID is reported,
      # never rewritten — see the boundary in this file's docblock.
      while IFS= read -r stranded; do
        echo "MANUAL   ${id} still named in ${stranded#"$DOCS_DIR"/} — ambiguous, both claimants held it"
      done < <(grep -rl -E "\\bP${old_num}\\b" "$DOCS_DIR" 2>/dev/null | sort)
    done
  done

  # Re-run detection so the exit code reports what actually survives.
  exec "$0" "$PROBLEMS_DIR"
fi

# ── Report ──────────────────────────────────────────────────────────────────

if [ ${#DRIFT_LINES[@]} -eq 0 ]; then
  exit 0
fi

# Sort for stable output (ID order).
IFS=$'\n' sorted=($(printf '%s\n' "${DRIFT_LINES[@]}" | sort))
unset IFS
for line in "${sorted[@]}"; do
  printf '%s\n' "$line"
done
exit 1
