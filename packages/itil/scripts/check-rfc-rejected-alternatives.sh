#!/usr/bin/env bash
# check-rfc-rejected-alternatives.sh — ADR-052 behavioural lint enforcing
# ADR-070 (RFCs hold no independent decisions).
#
# Invariant (ADR-070 § Confirmation): no RFC body in the RFC directory
# contains a "Considered Options / Alternatives Rejected" block WITHOUT a
# matching `adrs:` frontmatter reference. ADR-070 line 44 names the
# machine-detectable tell: "an RFC body containing a rejected-alternatives
# block with no matching `adrs:` reference is a decision masquerading as
# scope." Contested choices belong in an ADR (referenced via `adrs:`),
# never re-argued in the RFC body.
#
# This is an ARTEFACT-STATE behavioural check (ADR-052): given an RFC
# corpus directory, it inspects the on-disk RFC bodies + frontmatter and
# reports violations. It is NOT a structural grep of any SKILL.md / agent
# prose. Detection targets a markdown HEADING block (`## ... Considered
# Options ...` / `## ... Alternatives Rejected ...`), never a prose mention
# of the phrase (e.g. a retrofit note explaining the section was removed).
#
# Usage:   check-rfc-rejected-alternatives.sh [rfcs-dir]   (default docs/rfcs)
# Exit:    0 = clean (no violations); 1 = ≥1 violation; 2 = usage/dir error.
#
# Scope: docs/rfcs/ only. ADRs (docs/decisions/) legitimately carry
# "Considered Options" headings — they ARE the decision ledger; this lint
# never scans them.
#
# @adr ADR-070 (RFCs hold no independent decisions — the invariant)
# @adr ADR-052 (behavioural-tests-default — artefact-state assertion)
# @adr ADR-049 (plugin-bundled scripts; adopters run this over their docs/rfcs)
# @problem P310 (RFC decisions invisible to the ADR-066 oversight net)

set -euo pipefail

rfcs_dir="${1:-docs/rfcs}"

if [ ! -d "$rfcs_dir" ]; then
  echo "check-rfc-rejected-alternatives: not a directory: $rfcs_dir" >&2
  exit 2
fi

# Heading-block detector: a markdown ATX heading (1-6 '#') whose text
# contains "Considered Options" or "Alternatives Rejected" (case-insensitive).
# Anchored to '^#' so a prose/blockquote mention of the phrase never matches.
heading_re='^#{1,6}[[:space:]]+.*([Cc]onsidered [Oo]ptions|[Aa]lternatives [Rr]ejected)'

# adrs: frontmatter is non-empty when its line carries ≥1 ADR-<NNN> token.
# (`adrs:` only appears as a line-leading key in the YAML frontmatter; an
# RFC body never starts a line with `adrs:`.)
adrs_re='^adrs:.*ADR-[0-9]'

violations=0
scanned=0

# Iterate RFC files (RFC-*.md) in the directory. Sorted for stable output.
shopt -s nullglob
for f in "$rfcs_dir"/RFC-*.md; do
  scanned=$((scanned + 1))
  if grep -qE "$heading_re" "$f"; then
    if ! grep -qE "$adrs_re" "$f"; then
      line=$(grep -nE "$heading_re" "$f" | head -1 | cut -d: -f1)
      echo "VIOLATION  $f:${line}  rejected-alternatives block with empty/absent adrs: frontmatter (ADR-070)"
      violations=$((violations + 1))
    fi
  fi
done
shopt -u nullglob

if [ "$violations" -gt 0 ]; then
  echo "check-rfc-rejected-alternatives: $violations violation(s) across $scanned RFC(s) — an RFC carrying a rejected-alternatives block must reference its governing ADR(s) in adrs: (ADR-070)." >&2
  exit 1
fi

echo "check-rfc-rejected-alternatives: clean ($scanned RFC(s) scanned; no rejected-alternatives block without adrs: reference)."
exit 0
