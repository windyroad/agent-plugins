#!/usr/bin/env bash
# packages/itil/scripts/evaluate-relevance.sh
#
# Evaluate whether a problem ticket has become "no longer relevant" by
# checking observable evidence per ADR-026 grounding. Implements 5
# evidence shapes per ADR-079 (Phase 1 + Phase 2):
#
#   Shape 1 — file-no-longer-exists  (Phase 1, original)
#   Shape 2 — ADR-shipped with `human-oversight: confirmed`  (Phase 2)
#   Shape 3 — named-skill-or-feature-exists  (Phase 2)
#   Shape 4 — self-marker-in-body (line-anchored)  (Phase 2)
#   Shape 5 — driver-child-ticket-closed  (Phase 2)
#
# Phase 1 false-positive fixes (Phase 2):
#   - state-suffix detection (P180): per-state subdirs + .<state>.md
#   - sibling-file detection (P244): dir-glob slug-prefix
#   - rename detection (P251): git log --follow --diff-filter=AD
#
# Usage:
#   evaluate-relevance.sh <ticket-file> [<min-age-days>]
#
# Default <min-age-days> is 7. Age gate is a GATING condition per user
# direction 2026-05-31 "not just because they are old".
#
# Output (stdout, one line):
#   CLOSE-CANDIDATE <basename> — shapes: <comma-list> — <per-shape cite>; ...
#   CLOSE-CANDIDATE-WITH-CAVEAT <basename> — shapes: <list> — caveat: <tag>: <one-line>
#   KEEP-WITH-NOTE <basename> — <note>: <evidence>
#   KEEP <basename> — <M>/<N> paths still present
#   SKIP <basename> — <reason>
#
# Exit codes:
#   0 = CLOSE-CANDIDATE or CLOSE-CANDIDATE-WITH-CAVEAT
#   1 = KEEP or KEEP-WITH-NOTE
#   2 = SKIP
#   3 = error
#
# Set LC_ALL=C for portable byte-grep per P328 (BSD grep on macOS
# silently misbehaves on UTF-8 without an explicit locale).
#
# ADR-049: invoked via the `wr-itil-evaluate-relevance` PATH shim.
# ADR-026: every CLOSE-CANDIDATE verdict cites the evidence per shape.
# ADR-052: behavioural bats at scripts/test/evaluate-relevance.bats.
# ADR-079: design (Phase 1 + Phase 2).

set -euo pipefail
export LC_ALL=C

ticket_file="${1:-}"
min_age_days="${2:-7}"

if [ -z "$ticket_file" ]; then
  echo "evaluate-relevance: usage: $0 <ticket-file> [<min-age-days>]" >&2
  exit 3
fi

if [ ! -f "$ticket_file" ]; then
  echo "evaluate-relevance: ticket file not found: $ticket_file" >&2
  exit 3
fi

basename=$(basename "$ticket_file")

# ── Age gate ────────────────────────────────────────────────────────────────

reported=$(grep -m1 -oE '^\*\*Reported\*\*: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$ticket_file" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)
if [ -z "$reported" ]; then
  echo "SKIP $basename — no Reported date"
  exit 2
fi

cutoff=$(date -u -v-"${min_age_days}"d "+%Y-%m-%d" 2>/dev/null || date -u -d "${min_age_days} days ago" "+%Y-%m-%d" 2>/dev/null || true)
if [ -z "$cutoff" ]; then
  echo "SKIP $basename — could not compute cutoff date (date binary missing both BSD and GNU forms)"
  exit 2
fi

if [ "$reported" \> "$cutoff" ]; then
  echo "SKIP $basename — age gate (reported=$reported newer than cutoff=$cutoff, gate=${min_age_days}d)"
  exit 2
fi

# ── Helpers ─────────────────────────────────────────────────────────────────

# Check whether <path> is tracked by git (`git ls-files --error-unmatch`).
# Falls back to filesystem check when not in a git repo or when the file
# is staged-but-untracked-by-HEAD. Returns 0 if present.
path_exists() {
  local p="$1"
  if git ls-files --error-unmatch "$p" >/dev/null 2>&1; then
    return 0
  fi
  if [ -e "$p" ]; then
    return 0
  fi
  return 1
}

# Detect state-suffix variants of an incident/problem/RFC path (P180 fix).
# Given a path like `docs/incidents/I002-foo.investigating.md`, also checks
# `docs/incidents/I002-foo.{restored,mitigating,closed}.md`. Returns 0 if
# any sibling state-suffix variant exists.
state_suffix_variant_exists() {
  local p="$1"
  local dir base ext
  dir=$(dirname "$p")
  base=$(basename "$p")
  # Strip trailing .<state>.md to a slug-prefix and recombine with each
  # state. Conservative — only fires for paths in docs/incidents/,
  # docs/problems/, docs/rfcs/, docs/stories/, docs/story-maps/ where the
  # state-suffix convention applies (ADR-031 / ADR-060).
  case "$dir" in
    docs/incidents|docs/problems|docs/problems/*|docs/rfcs|docs/rfcs/*|docs/stories|docs/stories/*|docs/story-maps|docs/story-maps/*)
      ;;
    *)
      return 1
      ;;
  esac
  # Strip <state>.md suffix
  local slug
  slug=$(echo "$base" | sed -E 's/\.(open|known-error|verifying|closed|parked|investigating|mitigating|restored|draft|accepted|in-progress|done|archived|proposed|superseded)\.md$//')
  if [ "$slug" = "$base" ]; then
    return 1
  fi
  # Also try the per-state subdir layout (RFC-002 migration window).
  local parent
  parent=$(dirname "$dir")
  local entity
  entity=$(basename "$dir")
  for state in open known-error verifying closed parked investigating mitigating restored draft accepted in-progress done archived proposed superseded; do
    if [ -f "$dir/$slug.$state.md" ] && [ "$dir/$slug.$state.md" != "$p" ]; then
      echo "$dir/$slug.$state.md"
      return 0
    fi
    # Per-state subdir form: docs/problems/<state>/<slug>.md
    case "$dir" in
      docs/incidents|docs/problems|docs/rfcs|docs/stories|docs/story-maps)
        if [ -f "$dir/$state/$slug.md" ]; then
          echo "$dir/$state/$slug.md"
          return 0
        fi
        ;;
      docs/problems/*|docs/rfcs/*|docs/stories/*|docs/story-maps/*|docs/incidents/*)
        if [ -f "$parent/$state/$slug.md" ]; then
          echo "$parent/$state/$slug.md"
          return 0
        fi
        ;;
    esac
  done
  return 1
}

# Detect sibling files with similar slug-prefix in the same parent dir
# (P244 fix). Given `packages/foo/scripts/bar-list.sh`, finds
# `packages/foo/scripts/bar-render.sh` / `bar-populate.sh` etc.
# Returns 0 (and echoes the matched sibling) if a sibling exists.
sibling_file_exists() {
  local p="$1"
  local dir base ext stem prefix
  dir=$(dirname "$p")
  base=$(basename "$p")
  ext="${base##*.}"
  stem="${base%.*}"
  # slug-prefix = first 2 dash-separated tokens (e.g. "plugin-maturity")
  # for "plugin-maturity-list" we take "plugin-maturity"; for "foo-bar"
  # we take "foo". Conservative — too-short prefixes (single token) skip.
  prefix=$(echo "$stem" | cut -d- -f1-2)
  if [ "$prefix" = "$stem" ]; then
    # Single-token stem — no sibling-pattern to detect.
    return 1
  fi
  # Require at least 2 dash-separated tokens AND a multi-char first token
  local token_count
  token_count=$(echo "$stem" | tr '-' '\n' | wc -l | tr -d ' ')
  if [ "$token_count" -lt 2 ]; then
    return 1
  fi
  if [ ! -d "$dir" ]; then
    return 1
  fi
  local sibling
  # Use ls/find to enumerate; nullglob via shell would expand to literal
  # if no matches. Use find for portability.
  while IFS= read -r sibling; do
    [ -z "$sibling" ] && continue
    if [ "$sibling" = "$p" ]; then
      continue
    fi
    if [ -f "$sibling" ]; then
      echo "$sibling"
      return 0
    fi
  done < <(find "$dir" -maxdepth 1 -type f -name "$prefix-*.$ext" 2>/dev/null)
  return 1
}

# Detect rename via git log --follow (P251 fix). Returns 0 (and echoes the
# detected new name) if the file was renamed away from <path>.
rename_detected() {
  local p="$1"
  local log
  log=$(git log --follow --diff-filter=AD --name-only --pretty=format: -- "$p" 2>/dev/null | grep -v '^$' || true)
  if [ -z "$log" ]; then
    return 1
  fi
  # If the most recent name is different from the queried path, it was renamed.
  local most_recent
  most_recent=$(echo "$log" | head -1)
  if [ -n "$most_recent" ] && [ "$most_recent" != "$p" ]; then
    if [ -f "$most_recent" ] || git ls-files --error-unmatch "$most_recent" >/dev/null 2>&1; then
      echo "$most_recent"
      return 0
    fi
  fi
  return 1
}

# ── Shape detection ─────────────────────────────────────────────────────────

shapes=""
cites=""
caveat_tag=""
caveat_msg=""
keep_with_note=""

# Append a shape to the cumulative shape list + emit per-shape cite.
record_shape() {
  local shape="$1" cite="$2"
  if [ -z "$shapes" ]; then
    shapes="$shape"
    cites="$cite"
  else
    case ",$shapes," in
      *",$shape,"*) return 0 ;;  # already recorded
    esac
    shapes="$shapes,$shape"
    cites="$cites; $cite"
  fi
}

# Shape 1 — file-no-longer-exists (Phase 1 original).
# Extracts candidate paths, drops self-refs, runs path_exists per
# candidate. Detects state-suffix / sibling-file / rename to avoid Phase 1
# false-positives (P180/P244/P251); on detection routes to KEEP-WITH-NOTE.

candidates=$(grep -oE '(packages|docs|\.changeset|src|test|scripts)/[A-Za-z0-9._/-]+\.(md|sh|ts|tsx|js|jsx|json|yml|yaml|bats|py|txt|html)' "$ticket_file" 2>/dev/null \
  | sort -u \
  | grep -v '^docs/problems/' \
  || true)

shape1_missing=0
shape1_present=0
shape1_missing_list=""

if [ -n "$candidates" ]; then
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    if path_exists "$path"; then
      shape1_present=$((shape1_present + 1))
    else
      # Phase 1 false-positive fixes — check state-suffix / sibling-file
      # / rename BEFORE counting as missing.
      variant=$(state_suffix_variant_exists "$path" 2>/dev/null || true)
      if [ -n "$variant" ]; then
        keep_with_note="state-suffix variant exists: $variant"
        break
      fi
      sibling=$(sibling_file_exists "$path" 2>/dev/null || true)
      if [ -n "$sibling" ]; then
        keep_with_note="sibling file with similar slug-prefix exists: $sibling"
        break
      fi
      renamed=$(rename_detected "$path" 2>/dev/null || true)
      if [ -n "$renamed" ]; then
        keep_with_note="renamed (git log --follow): $path → $renamed"
        break
      fi
      shape1_missing=$((shape1_missing + 1))
      if [ -z "$shape1_missing_list" ]; then
        shape1_missing_list="$path"
      else
        shape1_missing_list="$shape1_missing_list;$path"
      fi
    fi
  done <<< "$candidates"
fi

# Shape 1 fires only when ALL extracted candidates are absent AND at
# least one was extracted.
if [ -z "$keep_with_note" ] && [ -n "$candidates" ] && [ "$shape1_missing" -ge 1 ] && [ "$shape1_present" -eq 0 ]; then
  shape1_total=$shape1_missing
  record_shape "file-no-longer-exists" "all ${shape1_total} file paths absent: ${shape1_missing_list}"
fi

# Shape 2 — ADR-shipped with `human-oversight: confirmed`.
# grep ticket body for ADR-NNN; for each, check docs/decisions/<NNN>-*.md
# exists AND frontmatter contains `human-oversight: confirmed`.

adr_refs=$(grep -oE '\bADR-[0-9]{3}\b' "$ticket_file" 2>/dev/null | sort -u || true)
shape2_confirmed=""
if [ -n "$adr_refs" ]; then
  while IFS= read -r adr; do
    [ -z "$adr" ] && continue
    num="${adr#ADR-}"
    # Find any docs/decisions/<num>-*.md (any state suffix).
    while IFS= read -r adr_file; do
      [ -z "$adr_file" ] && continue
      if grep -qE '^human-oversight: confirmed' "$adr_file" 2>/dev/null; then
        if [ -z "$shape2_confirmed" ]; then
          shape2_confirmed="$adr ($adr_file)"
        else
          shape2_confirmed="$shape2_confirmed, $adr ($adr_file)"
        fi
        break
      fi
    done < <(find docs/decisions -maxdepth 1 -type f -name "${num}-*.md" 2>/dev/null)
  done <<< "$adr_refs"
fi
if [ -n "$shape2_confirmed" ]; then
  record_shape "ADR-shipped-confirmed" "ADRs human-oversight-confirmed: ${shape2_confirmed}"
fi

# Shape 3 — named-skill-or-feature-exists.
# Detects SKILL.md / hook / agent / slash-command surfaces that exist.

shape3_hits=""

# (a) SKILL.md paths.
while IFS= read -r skill_path; do
  [ -z "$skill_path" ] && continue
  if path_exists "$skill_path"; then
    if [ -z "$shape3_hits" ]; then
      shape3_hits="$skill_path"
    else
      shape3_hits="$shape3_hits; $skill_path"
    fi
  fi
done < <(grep -oE 'packages/[A-Za-z0-9_-]+/skills/[A-Za-z0-9_-]+/SKILL\.md' "$ticket_file" 2>/dev/null | sort -u || true)

# (b) Hook paths.
while IFS= read -r hook_path; do
  [ -z "$hook_path" ] && continue
  if path_exists "$hook_path"; then
    if [ -z "$shape3_hits" ]; then
      shape3_hits="$hook_path"
    else
      shape3_hits="$shape3_hits; $hook_path"
    fi
  fi
done < <(grep -oE 'packages/[A-Za-z0-9_-]+/hooks/[A-Za-z0-9._-]+\.sh' "$ticket_file" 2>/dev/null | sort -u || true)

# (c) Agent paths.
while IFS= read -r agent_path; do
  [ -z "$agent_path" ] && continue
  if path_exists "$agent_path"; then
    if [ -z "$shape3_hits" ]; then
      shape3_hits="$agent_path"
    else
      shape3_hits="$shape3_hits; $agent_path"
    fi
  fi
done < <(grep -oE 'packages/[A-Za-z0-9_-]+/agents/[A-Za-z0-9._-]+\.md' "$ticket_file" 2>/dev/null | sort -u || true)

# (d) Slash-command refs — resolve to packages/<plugin>/skills/<skill>/SKILL.md
while IFS= read -r slash; do
  [ -z "$slash" ] && continue
  plugin=$(echo "$slash" | sed -E 's|/wr-([a-z0-9-]+):.*|\1|')
  skill=$(echo "$slash" | sed -E 's|/wr-[a-z0-9-]+:([a-z0-9-]+).*|\1|')
  candidate="packages/$plugin/skills/$skill/SKILL.md"
  if path_exists "$candidate"; then
    if [ -z "$shape3_hits" ]; then
      shape3_hits="$slash → $candidate"
    else
      shape3_hits="$shape3_hits; $slash → $candidate"
    fi
  fi
done < <(grep -oE '/wr-[a-z0-9-]+:[a-z0-9-]+' "$ticket_file" 2>/dev/null | sort -u || true)

if [ -n "$shape3_hits" ]; then
  record_shape "named-skill-or-feature-exists" "feature surfaces exist: ${shape3_hits}"
fi

# Shape 4 — self-marker-in-body (line-anchored regex per architect A2).
# Patterns:
#   ^.* Close to (Verifying|Closed)\b
#   ^.* DONE 2026-
#   ^.* fix shipped session
#   ^.* awaiting K→V
#   ^## Fix Released
# Line-anchored: must appear at line-start (with optional leading bullet
# or heading prefix) — prevents mid-prose narrative false-positives.

shape4_marker=""
if grep -qE '^[[:space:]]*[#>*-]*[[:space:]]*.*Close to (Verifying|Closed)\b' "$ticket_file" 2>/dev/null; then
  shape4_marker="'Close to Verifying|Closed' line marker"
elif grep -qE '^[[:space:]]*[#>*-]*[[:space:]]*\[?[x ]?\]?[[:space:]]*\*?\*?DONE 2026-' "$ticket_file" 2>/dev/null; then
  shape4_marker="'DONE 2026-' line marker"
elif grep -qE '^## Fix Released' "$ticket_file" 2>/dev/null; then
  shape4_marker="'## Fix Released' heading"
elif grep -qE '^[[:space:]]*[#>*-]*[[:space:]]*.*fix shipped session' "$ticket_file" 2>/dev/null; then
  shape4_marker="'fix shipped session' line marker"
elif grep -qE '^[[:space:]]*[#>*-]*[[:space:]]*.*awaiting K→V' "$ticket_file" 2>/dev/null; then
  shape4_marker="'awaiting K→V' line marker"
fi
if [ -n "$shape4_marker" ]; then
  record_shape "self-marker-in-body" "self-marker: ${shape4_marker}"
fi

# Shape 5 — driver-child-ticket-closed.
# Parse `## Related` section for P<NNN> refs; check if any are in
# docs/problems/closed/ (dual-tolerant: subdir OR .closed.md suffix).
# Per advisory A1, only fires when the child has NO unresolved
# investigation items of its own (rough heuristic: no unticked checkboxes
# OR no extractable open file refs).

# Extract section starting at "## Related" through end of file.
related_section=$(awk '/^## Related/{flag=1;next} /^## /{flag=0} flag' "$ticket_file" 2>/dev/null || true)
closed_drivers=""
if [ -n "$related_section" ]; then
  while IFS= read -r pnum; do
    [ -z "$pnum" ] && continue
    n="${pnum#P}"
    n="${n#p}"
    # Strip leading zeros before printf so bash doesn't interpret 034 as
    # octal (would yield decimal 28 — silent attribution bug). Use a
    # while-loop strip rather than $((10#$n)) so we don't trip on
    # malformed input.
    n_clean="$n"
    while [ "${n_clean#0}" != "$n_clean" ] && [ -n "${n_clean#0}" ]; do
      n_clean="${n_clean#0}"
    done
    pattern_num=$(printf "%03d" "$n_clean" 2>/dev/null || echo "$n")
    while IFS= read -r closed_file; do
      [ -z "$closed_file" ] && continue
      if [ -z "$closed_drivers" ]; then
        closed_drivers="$pnum ($closed_file)"
      else
        closed_drivers="$closed_drivers, $pnum ($closed_file)"
      fi
      break
    done < <(find docs/problems/closed -maxdepth 1 -type f \( -name "${pattern_num}-*.md" -o -name "${pattern_num}-*.closed.md" \) 2>/dev/null; find docs/problems -maxdepth 1 -type f -name "${pattern_num}-*.closed.md" 2>/dev/null)
  done < <(echo "$related_section" | grep -oE '\bP[0-9]{2,4}\b' | sort -u || true)
fi

# A1 guard — "child has independent open work" disambiguation.
#
# Shape 5 says "the driver in ## Related is closed". This is contributory
# evidence at best — the driver's closure does not prove the child's work
# is done. Per architect advisory A1, shape 5 should NOT fire when the
# child clearly names independent outstanding scope.
#
# Detection: if the ticket body references a `packages/.../skills/<name>/
# SKILL.md` or `packages/.../agents/<name>.md` that does NOT exist on
# disk, the umbrella is naming a feature that hasn't been built. This is
# future-work, not stale-work — suppress both shape 5 AND shape 1 for the
# missing future-work path; emit KEEP-WITH-NOTE.
future_work_skill_ref=""
while IFS= read -r future_skill; do
  [ -z "$future_skill" ] && continue
  if ! path_exists "$future_skill"; then
    future_work_skill_ref="$future_skill"
    break
  fi
done < <(grep -oE 'packages/[A-Za-z0-9_-]+/(skills/[A-Za-z0-9_-]+/SKILL\.md|agents/[A-Za-z0-9._-]+\.md)' "$ticket_file" 2>/dev/null | sort -u || true)

if [ -n "$closed_drivers" ] && [ -n "$future_work_skill_ref" ]; then
  # Closed driver AND child names a SKILL/agent that hasn't been built
  # yet — future work, not stale. KEEP-WITH-NOTE.
  keep_with_note="closed driver(s) ${closed_drivers}, but child names unbuilt SKILL/agent: $future_work_skill_ref"
  # Reset cumulative shapes so the KEEP-WITH-NOTE branch routes cleanly.
  shapes=""
  cites=""
fi

if [ -n "$closed_drivers" ] && [ -z "$keep_with_note" ]; then
  record_shape "driver-child-ticket-closed" "drivers closed: ${closed_drivers}"
fi

# ── Caveat detection ────────────────────────────────────────────────────────
# Architect condition C2: when shape detection is partial (umbrella with
# mixed-phase progress), emit CLOSE-CANDIDATE-WITH-CAVEAT with structured
# caveat short-tag + one-line prose so the SKILL Step 4.6b template can
# splice the **Caveat** field directly.

if [ -n "$shapes" ]; then
  # Multi-phase umbrella detection: unticked checkboxes in the ticket
  # body + at least one shipped-evidence shape match. The shape match
  # itself is the "progress made" signal — unticked tasks indicate
  # outstanding scope the maintainer must confirm before close.
  #
  # Use `grep | wc -l` so a no-match scenario exits 0 (wc always returns
  # 0) — avoids the pipefail + `grep -c` trap where grep prints "0" then
  # exits 1, tripping set -e on assignment.
  unticked_count=$(grep -cE '^[[:space:]]*-[[:space:]]*\[[[:space:]]\][[:space:]]' "$ticket_file" 2>/dev/null || true)
  ticked_count=$(grep -cE '^[[:space:]]*-[[:space:]]*\[x\][[:space:]]' "$ticket_file" 2>/dev/null || true)
  unticked_count=${unticked_count:-0}
  ticked_count=${ticked_count:-0}
  if [ "$unticked_count" -ge 1 ]; then
    caveat_tag="multi-phase-mixed-progress"
    caveat_msg="${ticked_count} task(s) done, ${unticked_count} outstanding — confirm umbrella scope before close"
  fi
fi

# ── Verdict emission ────────────────────────────────────────────────────────

if [ -n "$keep_with_note" ]; then
  echo "KEEP-WITH-NOTE $basename — $keep_with_note"
  exit 1
fi

if [ -n "$shapes" ]; then
  if [ -n "$caveat_tag" ]; then
    echo "CLOSE-CANDIDATE-WITH-CAVEAT $basename — shapes: $shapes — caveat: $caveat_tag: $caveat_msg — cites: $cites"
  else
    echo "CLOSE-CANDIDATE $basename — shapes: $shapes — $cites"
  fi
  exit 0
fi

# No shape fired — fall back to the legacy KEEP / SKIP routing.

if [ -z "$candidates" ]; then
  echo "SKIP $basename — no extractable file paths (after self-reference exclusion)"
  exit 2
fi

total=$((shape1_missing + shape1_present))
echo "KEEP $basename — ${shape1_present}/${total} paths still present"
exit 1
