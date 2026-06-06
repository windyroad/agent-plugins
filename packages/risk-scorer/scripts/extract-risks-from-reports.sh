#!/usr/bin/env bash
# extract-risks-from-reports.sh — extract standing-risk catalog entries from
# the .risk-reports/ corpus per ADR-059. Two-phase contract:
#
#   PHASE 1 (deterministic — this script's responsibility):
#     - Walk .risk-reports/*.md
#     - Parse RISK_REGISTER_HINT: bullets per ADR-056 3-column shape
#     - Group by slug (dedupe)
#     - Write one docs/risks/R<NNN>-<slug>.active.md per unique slug
#     - Generate docs/risks/README.md Register table
#     - List unhinted reports for Phase 2 LLM-walk
#
#   PHASE 2 (LLM-driven — bootstrap-catalog SKILL.md responsibility):
#     - Read each unhinted report listed in Phase 1 output
#     - Apply ADR-056 slug-computation rules to derive slug + prefill
#     - Re-invoke this script with --derived-slugs <file> to add them
#
# The entry shape is inlined here (the docs/risks/TEMPLATE.md was wiped
# 2026-05-04 per P167; per user direction "There shouldn't be a template
# in the directory, because that should be part of the risk creation/
# capture skill that the extractor uses" — the create-risk skill and
# this extractor own the entry shape).
#
# Usage:
#   extract-risks-from-reports.sh                    # walk + write entries + README
#   extract-risks-from-reports.sh --dry-run          # walk + report; no writes
#   extract-risks-from-reports.sh --derived-slugs F  # add slugs from F (Phase 2 input)
#   extract-risks-from-reports.sh --reports DIR      # use DIR instead of .risk-reports/
#   extract-risks-from-reports.sh --target DIR       # write to DIR instead of docs/risks/
#
# Exit codes:
#   0 — success (any number of entries written, including 0)
#   1 — pre-condition failure (RISK-POLICY.md absent, no reports, etc.)
#   2 — usage error

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Argument parsing
# ─────────────────────────────────────────────────────────────────────────────

REPORTS_DIR=".risk-reports"
TARGET_DIR="docs/risks"
DRY_RUN=0
DERIVED_SLUGS_FILE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --derived-slugs) DERIVED_SLUGS_FILE="$2"; shift 2 ;;
    --reports) REPORTS_DIR="$2"; shift 2 ;;
    --target) TARGET_DIR="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,/^set -/p' "$0" | grep '^#' | sed 's/^# \?//'
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

# ─────────────────────────────────────────────────────────────────────────────
# Pre-conditions
# ─────────────────────────────────────────────────────────────────────────────

if [ ! -f "RISK-POLICY.md" ]; then
  echo "PRE-CONDITION FAILED: RISK-POLICY.md not found in cwd. Project hasn't opted into the catalog framing." >&2
  echo "  Recovery: run /wr-risk-scorer:update-policy first." >&2
  exit 1
fi

if [ ! -d "$REPORTS_DIR" ]; then
  echo "PRE-CONDITION FAILED: $REPORTS_DIR/ directory not found." >&2
  echo "  Recovery: nothing to extract; the corpus is empty." >&2
  exit 1
fi

REPORT_COUNT=$(find "$REPORTS_DIR" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
if [ "$REPORT_COUNT" = "0" ]; then
  echo "PRE-CONDITION FAILED: $REPORTS_DIR/ has zero *.md files." >&2
  echo "  Recovery: nothing to extract; the corpus is empty." >&2
  exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Phase 1 — deterministic extraction from RISK_REGISTER_HINT bullets
# ─────────────────────────────────────────────────────────────────────────────

# Use Python for the parse + dedupe. ADR-056 3-column shape:
#   - <reason-tag> | <risk-slug> | <prefill prose>
# Legacy 2-column shape (ADR-056 dual-parse fallback):
#   - <reason-tag> | <prefill prose>
# When 2-column, derive slug from reason-tag + first 5 word-stems of prefill
# (lowercase, kebab, drop articles), capped at 60 chars per ADR-055.

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

python3 <<PYEOF > "${WORK_DIR}/extracted.tsv"
import os, re, sys, glob, datetime
from collections import defaultdict

REPORTS_DIR = "$REPORTS_DIR"
ARTICLES = {"the", "a", "an", "of", "to", "in", "on", "at", "for", "with", "by", "from"}
RESERVED_TAGS = {"above-appetite-residual", "confidentiality-disclosure", "user-stated-precondition"}

def slug_from_prefill(reason_tag, prefill, cap=60):
    text = re.sub(r'[^a-zA-Z0-9\s-]', ' ', prefill.lower())
    words = [w for w in text.split() if w and w not in ARTICLES][:5]
    base = '-'.join(words) if words else reason_tag
    return base[:cap].rstrip('-') or reason_tag

# Group by slug → list of (source_file, reason_tag, prefill, slug_source)
by_slug = defaultdict(list)

for path in sorted(glob.glob(f"{REPORTS_DIR}/*.md")):
    try:
        with open(path, 'r') as f:
            content = f.read()
    except Exception:
        continue
    # Find RISK_REGISTER_HINT block; extract bullets until next blank-line-then-non-list
    m = re.search(r'^RISK_REGISTER_HINT:\s*\n((?:^- .*\n?)+)', content, re.MULTILINE)
    if not m:
        continue
    block = m.group(1)
    for line in block.split('\n'):
        line = line.strip()
        if not line.startswith('- '):
            continue
        body = line[2:].strip()
        parts = [p.strip() for p in body.split('|')]
        if len(parts) >= 3:
            reason_tag, slug, prefill = parts[0], parts[1], '|'.join(parts[2:]).strip()
            slug_source = "agent"
        elif len(parts) == 2:
            reason_tag, prefill = parts[0], parts[1]
            slug = slug_from_prefill(reason_tag, prefill)
            slug_source = "derived"
        else:
            continue
        if reason_tag not in RESERVED_TAGS:
            continue  # invalid tag — skip silently
        by_slug[slug].append((path, reason_tag, prefill, slug_source))

# Emit deterministic-extracted slugs as TSV: slug \t source_count \t first_reason_tag \t first_prefill \t source_files (comma-sep)
for slug in sorted(by_slug.keys()):
    entries = by_slug[slug]
    source_files = ",".join(sorted(set(e[0] for e in entries)))
    print(f"{slug}\t{len(entries)}\t{entries[0][1]}\t{entries[0][2]}\t{source_files}")
PYEOF

EXTRACTED_COUNT=$(wc -l < "${WORK_DIR}/extracted.tsv" | tr -d ' ')

# Find unhinted reports (no RISK_REGISTER_HINT block) — Phase 2 candidates
python3 <<PYEOF > "${WORK_DIR}/unhinted.txt"
import os, re, glob
REPORTS_DIR = "$REPORTS_DIR"
unhinted = []
for path in sorted(glob.glob(f"{REPORTS_DIR}/*.md")):
    try:
        with open(path, 'r') as f:
            content = f.read()
    except Exception:
        continue
    if not re.search(r'^RISK_REGISTER_HINT:\s*\n- ', content, re.MULTILINE):
        unhinted.append(path)
for p in unhinted:
    print(p)
PYEOF

UNHINTED_COUNT=$(wc -l < "${WORK_DIR}/unhinted.txt" | tr -d ' ')

# ─────────────────────────────────────────────────────────────────────────────
# Phase 2 — derived slugs from caller (e.g. SKILL.md LLM-walk output)
# ─────────────────────────────────────────────────────────────────────────────

if [ -n "$DERIVED_SLUGS_FILE" ] && [ -f "$DERIVED_SLUGS_FILE" ]; then
  # Append derived slugs to extracted.tsv (same TSV format)
  cat "$DERIVED_SLUGS_FILE" >> "${WORK_DIR}/extracted.tsv"
  EXTRACTED_COUNT=$(wc -l < "${WORK_DIR}/extracted.tsv" | tr -d ' ')
fi

# ─────────────────────────────────────────────────────────────────────────────
# Dry-run early exit
# ─────────────────────────────────────────────────────────────────────────────

if [ "$DRY_RUN" = "1" ]; then
  echo "DRY-RUN summary:"
  echo "  reports walked:          $REPORT_COUNT"
  echo "  hinted (deterministic):  $EXTRACTED_COUNT entries"
  echo "  unhinted (Phase 2 todo): $UNHINTED_COUNT reports"
  echo
  echo "Extracted slugs:"
  awk -F'\t' '{print "  - "$1" (sources: "$2")"}' "${WORK_DIR}/extracted.tsv"
  echo
  echo "Unhinted reports (sample):"
  head -5 "${WORK_DIR}/unhinted.txt" | sed 's|^|  - |'
  if [ "$UNHINTED_COUNT" -gt 5 ]; then
    echo "  ... and $((UNHINTED_COUNT - 5)) more"
  fi
  exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# Write entries
# ─────────────────────────────────────────────────────────────────────────────

mkdir -p "$TARGET_DIR"
TODAY=$(date -u '+%Y-%m-%d')

# Compute starting R<NNN> ID — live-filesystem-max + 1 (defaults to R001 when fresh).
# Note: deviates from ADR-019 dual-source convention because this script bootstraps
# the catalog as a clean slate. After wipe, origin still carries the wiped R001-R006
# until push, so origin-max would force next=7+ when the user wants R001 from clean
# slate. Filesystem-only is correct for the bootstrap case; ADR-019 still applies to
# /wr-risk-scorer:create-risk for incremental adds post-bootstrap.
LOCAL_MAX=$(ls "$TARGET_DIR/"R*.active.md "$TARGET_DIR/"R*.retired.md 2>/dev/null | sed 's|.*/R||' | grep -oE '^[0-9]+' | sort -n | tail -1 || true)
NEXT_ID=$(( ${LOCAL_MAX:-0} + 1 ))

CREATED=0
APPENDED=0

while IFS=$'\t' read -r slug count reason_tag prefill source_files; do
  [ -z "$slug" ] && continue
  # Idempotency: glob for existing R*-<slug>.active.md
  existing=$(ls "$TARGET_DIR/"R*-"${slug}.active.md" 2>/dev/null | head -1 || true)
  if [ -n "$existing" ]; then
    # Append source_files to existing entry's Source Evidence block
    {
      echo ""
      echo "<!-- Source-Evidence append (extract-risks-from-reports.sh, $TODAY) -->"
      echo "Additional sources for slug \`$slug\`:"
      for s in $(echo "$source_files" | tr ',' '\n'); do
        echo "- \`$s\`"
      done
    } >> "$existing"
    APPENDED=$((APPENDED + 1))
    continue
  fi

  # Heuristic category from reason_tag
  case "$reason_tag" in
    confidentiality-disclosure) category="infosec" ;;
    *)                          category="operational" ;;
  esac

  # Derive a Title Case title from the slug
  title=$(echo "$slug" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')

  R_ID=$(printf '%03d' "$NEXT_ID")
  filename="$TARGET_DIR/R${R_ID}-${slug}.active.md"

  cat > "$filename" <<ENTRY
# Risk R${R_ID}: ${title}

**Status**: Active (auto-scaffolded — pending review)
**Category**: ${category}
**Identified**: ${TODAY}
**Owner**: pending review
**Last reviewed**: ${TODAY}
**Next review**: pending review
**Curation**: pending review (auto-scaffolded ${TODAY})

## Description

${prefill}

## Recogniser

(pending review — recogniser shape to be authored during curation per ADR-059)

**Path patterns** (file globs where this risk class typically applies):

- pending review — list path globs derived from \`.risk-reports/\` evidence + the prose above

**Diff-content keywords** (signals in the diff that suggest scoring against this entry):

- pending review — list keywords drawn from the report prose and adjacent incident reports

**Anti-patterns** (looks like this entry but should score under a different class):

- pending review — list cases that should redirect to a specialisation or sibling

## Inherent Risk

- **Impact**: not estimated — no prior data
- **Likelihood**: not estimated — no prior data
- **Inherent Score**: not estimated — no prior data
- **Inherent Band**: not estimated — no prior data

## Controls

(pending review — controls are project-specific and pending human curation)

## Residual Risk

- **Impact**: not estimated — no prior data
- **Likelihood**: not estimated — no prior data
- **Residual Score**: not estimated — no prior data
- **Residual Band**: not estimated — no prior data
- **Within appetite?**: pending — scoring not estimated

## Treatment

pending review

## Monitoring

- **Trigger to re-assess**: when human curation lands or when controls change
- **Metrics**: extracted-from \`.risk-reports/\` count for slug \`${slug}\`: ${count}

## Related

- Criteria: \`RISK-POLICY.md\`
- Auto-scaffolded by: \`extract-risks-from-reports.sh\` (per ADR-059)

## Source Evidence (auto-scaffolded ${TODAY})

Aggregated from ${count} \`.risk-reports/\` entries (slug: \`${slug}\`, reason-tag: \`${reason_tag}\`):
ENTRY

  for s in $(echo "$source_files" | tr ',' '\n'); do
    echo "- \`$s\`" >> "$filename"
  done

  cat >> "$filename" <<ENTRY

Re-rate when new reports surface against this slug or when controls change.

## Change Log

- ${TODAY}: Auto-scaffolded by \`extract-risks-from-reports.sh\` from \`.risk-reports/\` corpus per ADR-059.
ENTRY

  NEXT_ID=$((NEXT_ID + 1))
  CREATED=$((CREATED + 1))
done < "${WORK_DIR}/extracted.tsv"

# ─────────────────────────────────────────────────────────────────────────────
# Generate README.md
# ─────────────────────────────────────────────────────────────────────────────

cat > "$TARGET_DIR/README.md" <<README_HEADER
# Risk Register

> ISO 31000 / ISO 27001 standing-risk inventory. Per-risk files live alongside this index.
> Last reviewed: ${TODAY} (auto-generated by \`extract-risks-from-reports.sh\` per ADR-059)

## Purpose

This directory is the **persistent risk register** for the Windy Road Agent Plugins suite. It is distinct from:

- \`RISK-POLICY.md\` — defines the *criteria* (impact/likelihood scales, appetite, treatment principles).
- \`.risk-reports/\` — ephemeral **per-change** pipeline risk reports produced by the risk-scorer on each commit/push/release. Auto-deleted after 7 days.
- \`docs/problems/\` — ITIL problem management (concrete defects and their fixes).

The risk register captures **standing risks** — risks that persist across changes and require ongoing treatment. Each risk has an owner, treatment plan, inherent and residual scores, and review date.

Per ADR-059, the register is populated by \`/wr-risk-scorer:bootstrap-catalog\` (one-shot) and \`/wr-risk-scorer:create-risk\` (on-demand or orchestrator-prefilled). The entry shape is owned by the create-risk skill — there is intentionally no \`TEMPLATE.md\` in this directory (per user direction 2026-05-04).

## ISO Mapping

| ISO Clause | Artefact in this repo |
|------------|-----------------------|
| ISO 31000 § 6.4.2 — Risk treatment | Each risk file's \`Treatment\` section |
| ISO 31000 § 6.4.3 — Residual risk | Each risk file's \`Residual Score\` section |
| ISO 31000 § 6.5 — Monitoring and review | \`Review date\` field + periodic review pass |
| ISO 27001 § 6.1.2 — Risk assessment | Risks tagged \`category: infosec\` |
| ISO 27001 § 6.1.3 — Risk treatment / SoA | \`Treatment\` + \`Controls\` sections |

## Structure

- One file per risk: \`R<NNN>-<kebab-case-slug>.<status>.md\`
- Status suffixes: \`.active.md\`, \`.accepted.md\` (consciously tolerated), \`.retired.md\` (no longer relevant)
- Risks retired, not deleted — historical record is preserved
- Cross-references to \`docs/problems/P<NNN>\` and \`docs/decisions/ADR-<NNN>\` welcome
- Auto-scaffolded entries carry \`Status: Active (auto-scaffolded — pending review)\` + \`Curation: pending review\` markers; human curation upgrades them to \`Status: Active\`.

## Register

| ID | Title | Category | Status | Curation |
|----|-------|----------|--------|----------|
README_HEADER

# Append register rows
if ls "$TARGET_DIR/"R*.active.md >/dev/null 2>&1; then
  for entry in "$TARGET_DIR/"R*.active.md; do
    [ -f "$entry" ] || continue
    fn=$(basename "$entry")
    # Extract title (line 1 after "# Risk R<NNN>: ")
    title=$(head -1 "$entry" | sed -E 's/^# Risk R[0-9]+: //')
    # Extract category
    category=$(grep -m1 '^\*\*Category\*\*:' "$entry" | sed -E 's/^\*\*Category\*\*:\s*//' | tr -d '\n')
    # Extract Status
    status=$(grep -m1 '^\*\*Status\*\*:' "$entry" | sed -E 's/^\*\*Status\*\*:\s*//' | tr -d '\n')
    # Extract Curation if present
    curation=$(grep -m1 '^\*\*Curation\*\*:' "$entry" | sed -E 's/^\*\*Curation\*\*:\s*//' | tr -d '\n')
    [ -z "$curation" ] && curation="(human-curated)"
    rid=$(echo "$fn" | grep -oE '^R[0-9]+')
    echo "| [$rid]($fn) | $title | $category | $status | $curation |" >> "$TARGET_DIR/README.md"
  done
fi

cat >> "$TARGET_DIR/README.md" <<README_FOOTER

## Retired

| ID | Title | Retired date | Reason |
|----|-------|--------------|--------|
README_FOOTER

# Append retired rows
if ls "$TARGET_DIR/"R*.retired.md >/dev/null 2>&1; then
  for entry in "$TARGET_DIR/"R*.retired.md; do
    [ -f "$entry" ] || continue
    fn=$(basename "$entry")
    title=$(head -1 "$entry" | sed -E 's/^# Risk R[0-9]+: //')
    rid=$(echo "$fn" | grep -oE '^R[0-9]+')
    echo "| [$rid]($fn) | $title | (see file) | (see file) |" >> "$TARGET_DIR/README.md"
  done
fi

cat >> "$TARGET_DIR/README.md" <<README_FOOTER2

## How to Add a Risk

- **On demand**: invoke \`/wr-risk-scorer:create-risk\` (interactive authoring) or \`/wr-risk-scorer:create-risk --slug <slug> --prefill <prose>\` (orchestrator-driven prefilled invocation per ADR-059).
- **From the report corpus**: invoke \`/wr-risk-scorer:bootstrap-catalog\` (one-shot bootstrap that walks \`.risk-reports/\` and writes one entry per unique slug per ADR-056 / ADR-059).

## How to Review

On review date, re-assess likelihood and residual score. Update controls as systems evolve. Retire risks that no longer apply (rename to \`.retired.md\`).

Auto-scaffolded entries (Status: \`Active (auto-scaffolded — pending review)\`) await human curation: assign scoring, document controls, set Treatment, then flip Status to \`Active\`.
README_FOOTER2

# ─────────────────────────────────────────────────────────────────────────────
# Report
# ─────────────────────────────────────────────────────────────────────────────

echo "Risk register extraction complete."
echo
echo "  Reports walked:          $REPORT_COUNT"
echo "  Hinted (deterministic):  $EXTRACTED_COUNT slugs"
echo "  New entries created:     $CREATED"
echo "  Existing entries updated: $APPENDED"
echo "  Unhinted (Phase 2 todo): $UNHINTED_COUNT reports"
echo
echo "Output:"
echo "  - $TARGET_DIR/R<NNN>-<slug>.active.md (one per unique slug)"
echo "  - $TARGET_DIR/README.md (regenerated)"
echo
if [ "$UNHINTED_COUNT" -gt 0 ]; then
  echo "Phase 2 LLM-walk required for $UNHINTED_COUNT unhinted reports."
  echo "  Sample (first 5):"
  head -5 "${WORK_DIR}/unhinted.txt" | sed 's|^|    - |'
  if [ "$UNHINTED_COUNT" -gt 5 ]; then
    echo "    ... and $((UNHINTED_COUNT - 5)) more"
  fi
  echo "  Driver: bootstrap-catalog SKILL.md Step 2 — agent walks each, derives slug + prefill,"
  echo "          re-invokes this script with --derived-slugs <file> to add them."
fi
