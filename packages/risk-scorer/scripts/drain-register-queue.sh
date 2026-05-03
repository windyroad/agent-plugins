#!/usr/bin/env bash
# packages/risk-scorer/scripts/drain-register-queue.sh
#
# Drains .afk-run-state/risk-register-queue.jsonl into docs/risks/
# register entries per ADR-056 (Phase 2b consumer-skill drain contract).
#
# The Phase 2a hook (risk-score-mark.sh) enqueues one JSONL line per
# RISK_REGISTER_HINT bullet emitted by wr-risk-scorer:pipeline. This script
# is invoked by consumer skills (this iter: /wr-itil:work-problems Step 6.4)
# to materialise queued hints into docs/risks/R<NNN>-<slug>.active.md files.
#
# Usage:
#   drain-register-queue.sh [<project-root>]
#
# Default <project-root> is $(pwd).
#
# Behaviour:
#   - Idempotent: empty queue OR missing docs/risks/ → no-op exit 0.
#   - Dedupe by risk_slug — N hints for same slug → 1 register file with
#     N Evidence Log entries (per user direction "for each risk in
#     .risk-reports there should be something in the register").
#   - New risks: minted as R<NNN>-<slug>.active.md with auto-scaffolded
#     status, ADR-026 sentinels for ungrounded scoring fields.
#   - Existing risks (slug match): Evidence Log appended; scoring untouched.
#   - README Register table updated with one row per new risk (ADR-056 §3d).
#   - Files staged via `git add` — caller commits per ADR-014.
#   - Queue truncated only on successful drain. No-op cases preserve queue.
#
# Stdout (key=value, caller-parseable):
#   entries_drained=N           — total JSONL lines processed
#   new_risks_created=N         — new R<NNN> files written
#   evidence_appended=N         — slug-matched existing files updated
#   next_action=commit-staged|none — caller's commit decision
#
# Exit codes:
#   0 — success or no-op
#   non-zero — hard failure (template missing, write error, git failure)
#
# @adr ADR-056 (queue-and-drain contract; Phase 2b consumer drain)
# @adr ADR-026 (not estimated — no prior data sentinel for ungrounded scoring)
# @adr ADR-019 (ticket-creator dual-source ID via local-max + origin-max)
# @adr ADR-049 (resolved via bin/wr-risk-scorer-drain-register-queue shim)
# @adr ADR-052 (behavioural-fixture coverage at scripts/test/drain-register-queue.bats)
# @problem P033 (Phase 2b)

set -uo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
QUEUE_FILE="${PROJECT_ROOT}/.afk-run-state/risk-register-queue.jsonl"
RISKS_DIR="${PROJECT_ROOT}/docs/risks"
TEMPLATE_FILE="${RISKS_DIR}/TEMPLATE.md"
README_FILE="${RISKS_DIR}/README.md"

emit_no_op() {
  echo "entries_drained=0"
  echo "new_risks_created=0"
  echo "evidence_appended=0"
  echo "next_action=none"
}

if [ ! -f "$QUEUE_FILE" ] || [ ! -s "$QUEUE_FILE" ]; then
  emit_no_op
  exit 0
fi

if [ ! -d "$RISKS_DIR" ] || [ ! -f "$TEMPLATE_FILE" ] || [ ! -f "$README_FILE" ]; then
  emit_no_op
  exit 0
fi

LOCAL_MAX=$(ls "$RISKS_DIR"/R*.md 2>/dev/null \
  | sed 's|.*/||' | grep -oE '^R[0-9]+' | sed 's/^R//' | sort -n | tail -1 || true)
LOCAL_MAX="${LOCAL_MAX:-0}"

ORIGIN_MAX=$(cd "$PROJECT_ROOT" && git ls-tree --name-only origin/main docs/risks/ 2>/dev/null \
  | sed 's|^docs/risks/||' | grep -oE '^R[0-9]+' | sed 's/^R//' | sort -n | tail -1 || true)
ORIGIN_MAX="${ORIGIN_MAX:-0}"

# Force base-10 — bash arithmetic treats leading-zero values as octal,
# so R099 → 099 → "value too great for base" without the 10# prefix.
NEXT_ID=$(( (10#$LOCAL_MAX > 10#$ORIGIN_MAX ? 10#$LOCAL_MAX : 10#$ORIGIN_MAX) + 1 ))

DRAIN_RESULT=$(python3 - "$QUEUE_FILE" "$RISKS_DIR" "$TEMPLATE_FILE" "$README_FILE" "$NEXT_ID" "$PROJECT_ROOT" <<'PYEOF'
import json
import os
import re
import sys
from collections import OrderedDict
from datetime import datetime

queue_file, risks_dir, template_file, readme_file, next_id_str, project_root = sys.argv[1:7]
next_id = int(next_id_str)

hints = []
with open(queue_file, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not all(k in entry for k in ('risk_slug', 'reason_tag', 'prefill', 'report_path')):
            continue
        hints.append(entry)

if not hints:
    print("entries_drained=0")
    print("new_risks_created=0")
    print("evidence_appended=0")
    print("next_action=none")
    sys.exit(0)

groups = OrderedDict()
for h in hints:
    slug = h['risk_slug']
    if slug not in groups:
        groups[slug] = []
    groups[slug].append(h)

existing = {}
for fn in os.listdir(risks_dir):
    if fn in ('README.md', 'TEMPLATE.md'):
        continue
    m = re.match(r'^R(\d+)-(.+)\.active\.md$', fn)
    if m:
        existing[m.group(2)] = fn

today = datetime.utcnow().strftime('%Y-%m-%d')

new_risks = []
appended_evidence = []

for slug, group in groups.items():
    evidence_lines = [
        f"- {h['ts']}: fired in `{h['report_path']}` (reason: {h['reason_tag']})"
        for h in group
    ]
    evidence_block = "\n".join(evidence_lines)

    if slug in existing:
        fn = existing[slug]
        path = os.path.join(risks_dir, fn)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        if "## Evidence Log" in content:
            content = re.sub(
                r'(## Evidence Log\n(?:.*?\n)*?)(\n## |\Z)',
                lambda m: m.group(1).rstrip() + "\n" + evidence_block + "\n" + m.group(2),
                content,
                count=1,
                flags=re.DOTALL,
            )
        else:
            new_section = f"\n## Evidence Log\n\nAuto-populated from `.risk-reports/` via Phase 2b drain.\n\n{evidence_block}\n"
            if "## Change Log" in content:
                content = content.replace("## Change Log", new_section + "\n## Change Log", 1)
            else:
                content = content.rstrip() + "\n" + new_section
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        appended_evidence.append((fn, [h['report_path'] for h in group]))
    else:
        rid = f"R{next_id:03d}"
        next_id += 1
        fn = f"{rid}-{slug}.active.md"
        path = os.path.join(risks_dir, fn)
        prefill = next((h['prefill'] for h in group if h.get('prefill')), '(no description provided)')
        sentinel = "not estimated — no prior data"
        title = slug.replace('-', ' ').title()
        body = f"""# Risk {rid}: {title}

**Status**: Active (auto-scaffolded — pending review)
**Category**: <!-- pending review — auto-scaffolded from pipeline hint -->
**Identified**: {today}
**Owner**: pending review
**Last reviewed**: {today}
**Next review**: {today}
**Curation**: pending review (auto-scaffolded {today})

## Description

{prefill}

> Auto-scaffolded by the Phase 2b drain (ADR-056) from a `wr-risk-scorer:pipeline`
> RISK_REGISTER_HINT bullet. The description is the agent's prefill; scoring
> fields below carry the ADR-026 ungrounded-output sentinel until human curation.

## Inherent Risk

Impact × Likelihood *before* controls.

- **Impact**: {sentinel}
- **Likelihood**: {sentinel}
- **Inherent Score**: {sentinel}
- **Inherent Band**: {sentinel}

## Controls

- pending review — controls to be enumerated during curation.

## Residual Risk

Impact × Likelihood *after* controls.

- **Impact**: {sentinel}
- **Likelihood**: {sentinel}
- **Residual Score**: {sentinel}
- **Residual Band**: {sentinel}
- **Within appetite?**: pending — scoring not estimated

## Treatment

pending review — treatment decision deferred until scoring is curated.

## Monitoring

- **Trigger to re-assess**: any new pipeline hint with this risk_slug
- **Metrics**: count of `.risk-reports/` entries citing this slug

## Related

- Criteria: `RISK-POLICY.md`
- Realised-as: <!-- link to docs/problems/P<NNN> when known -->
- Treatment ADRs: <!-- link to docs/decisions/ADR-<NNN> when treatment lands -->

## Evidence Log

Auto-populated from `.risk-reports/` via Phase 2b drain.

{evidence_block}

## Change Log

- {today}: Auto-scaffolded by Phase 2b drain (ADR-056). Pending human curation.
"""
        with open(path, 'w', encoding='utf-8') as f:
            f.write(body)
        new_risks.append((rid, slug, fn, prefill))

if new_risks:
    with open(readme_file, 'r', encoding='utf-8') as f:
        readme = f.read()
    rows = []
    for rid, slug, fn, prefill in new_risks:
        title = slug.replace('-', ' ').title()
        rows.append(f"| [{rid}]({fn}) | {title} | pending | — | — | pending | pending | {today} |")
    new_rows_block = "\n".join(rows) + "\n"
    if "## Retired" in readme:
        readme = readme.replace("## Retired", new_rows_block + "\n## Retired", 1)
    else:
        readme = readme.rstrip() + "\n" + new_rows_block
    with open(readme_file, 'w', encoding='utf-8') as f:
        f.write(readme)

print(f"entries_drained={len(hints)}")
print(f"new_risks_created={len(new_risks)}")
print(f"evidence_appended={len(appended_evidence)}")
if new_risks or appended_evidence:
    print("next_action=commit-staged")
else:
    print("next_action=none")
PYEOF
)
PY_STATUS=$?

if [ "$PY_STATUS" -ne 0 ]; then
  echo "$DRAIN_RESULT"
  exit "$PY_STATUS"
fi

echo "$DRAIN_RESULT"

ENTRIES_DRAINED=$(echo "$DRAIN_RESULT" | grep -E '^entries_drained=' | cut -d= -f2)
NEW_RISKS=$(echo "$DRAIN_RESULT" | grep -E '^new_risks_created=' | cut -d= -f2)
EVIDENCE_APPENDED=$(echo "$DRAIN_RESULT" | grep -E '^evidence_appended=' | cut -d= -f2)

if [ "${NEW_RISKS:-0}" != "0" ] || [ "${EVIDENCE_APPENDED:-0}" != "0" ]; then
  (cd "$PROJECT_ROOT" && git add docs/risks 2>/dev/null) || true
fi

if [ "${ENTRIES_DRAINED:-0}" != "0" ]; then
  : > "$QUEUE_FILE"
fi

exit 0
