#!/bin/bash
# P159: PreToolUse:Bash hook — denies `git commit` invocations whose
# post-commit working tree exhibits JTBD-currency drift in any
# packages/<plugin>/README.md (no JTBD-NNN anchor, stale or
# deprecated-only citation, or skill directory missing from README).
#
# Hook-level enforcement at commit time replaces ADR-051 Phase 1's
# retro-time advisory surface (shipped under P158, df47ad1). The user
# correction (P159) and the architect verdict identified the retro
# surface as too late: the most-common drift class (contributor adds
# skill/hook/agent and forgets the README) ships in a commit that
# does not touch README.md, so a retro-time consumer sees the drift
# only after the contributor has already committed.
#
# Detection delegates to the existing detector script
# (`packages/retrospective/scripts/check-readme-jtbd-currency.sh`),
# invoked against the project's working tree (`./packages/` +
# `./docs/jtbd/`). The hook reads the detector's
# `TOTAL packages=<N> with_jtbd=<M> drift_instances=<K>` summary and
# denies when `drift_instances > 0`.
#
# Allow paths (exit 0 silently per ADR-045 Pattern 1):
#   - tool_name != "Bash"            (only Bash invocations are gated)
#   - command does not contain      `git commit` substring (non-commit
#                                   Bash bypasses entirely — `git
#                                   status`, `git log`, etc.)
#   - BYPASS_JTBD_CURRENCY=1         (single-most-common legitimate
#                                   escape — bypass-traceable via
#                                   shell history)
#   - outside a git work tree        (adopter sessions outside the
#                                   plugin monorepo)
#   - no `./packages/` directory     (project does not have ADR-051's
#                                   structural anchor — adopter
#                                   project shape; gate is a no-op)
#   - no `./docs/jtbd/` directory    (project has not run
#                                   /wr-jtbd:update-guide; gate is a
#                                   no-op)
#   - detector exits non-zero        (parse error / hostile env;
#                                   fail-open per ADR-013 Rule 6)
#   - detector emits no TOTAL line   (no packages found; nothing to
#                                   gate)
#   - drift_instances == 0           (clean tree)
#
# Deny shape (per ADR-013 Rule 1 — deny redirects with mechanical
# recovery; ADR-045 deny-band ≤300 bytes):
#   - Names the first offending plugin slug + drift hint vocabulary.
#   - Names the wr-jtbd:agent recovery path AND the hand-edit fallback
#     (graceful degradation when @windyroad/jtbd is not installed).
#   - Names BYPASS_JTBD_CURRENCY=1 as the env-var escape.
#   - Cites P159 for traceability.
#   - Truncates the drift_hints CSV to the first hint to keep the
#     deny-band ≤300 bytes for worst-case slug + hint combinations.
#
# Cost: one invocation of `check-readme-jtbd-currency.sh` per `git
# commit` (~80–150ms in the worst case across 12 plugin READMEs +
# ~30 JTBD job files; per the architect's ADR-023 perf review at
# Phase 1 design time). Per-invocation deterministic; no marker
# (mirrors P125 `staging-detect.sh` and P141
# `itil-changeset-discipline.sh` precedent — architect-approved
# no-marker design when detection cost stays under ~150ms).
#
# References:
#   ADR-005 — plugin testing strategy (hook bats live under
#             `packages/<plugin>/hooks/test/`).
#   ADR-013 Rule 1 — deny redirects with mechanical recovery (the
#             deny names the wr-jtbd:agent recovery, the hand-edit
#             fallback, and the BYPASS env override).
#   ADR-013 Rule 6 — non-interactive fail-safe (fail-open outside a
#             git work tree, on parse error, in projects lacking
#             ADR-051 anchors, and on detector failure).
#   ADR-014 — governance skills commit their own work (this hook
#             keeps iter commits self-contained).
#   ADR-018 — inter-iteration release cadence (the hook strengthens
#             release-cadence integrity by ensuring every publishable
#             iter has a current README before commit).
#   ADR-038 — progressive disclosure / deny-message terseness budget.
#   ADR-045 — hook injection budget (Pattern 1 silent-on-pass; deny
#             band ≤300 bytes for this hook).
#   ADR-051 — JTBD-anchored README rule (this hook is the load-
#             bearing-from-the-start commit-gate surface; supersedes
#             retro-time advisory consumption as primary).
#   ADR-052 — behavioural-tests default (bats fixture asserts on
#             emitted JSON, not source content).
#   P081 — behavioural tests preferred over structural greps.
#   P125 — sibling staging-trap helper (per-invocation no-marker).
#   P141 — sibling changeset-discipline gate on `git commit` (same
#             hook shape).
#   P158 — retro Step 2b wiring (backup advisory; survives this
#             hook's primary-surface migration).
#   P159 — this hook.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DETECTOR="$SCRIPT_DIR/../scripts/check-readme-jtbd-currency.sh"

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_name', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Only gate Bash. Non-Bash tools bypass entirely.
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Only fire on `git commit` invocations. Substring match catches common
# shapes (`git commit -m`, `git commit --amend`, leading `cd && git
# commit`, `chore: version packages` release commits routed via
# `git commit -m 'chore: version packages'`, etc.) without
# over-matching unrelated bash.
case "$COMMAND" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

# Bypass via env var — single most-common legitimate escape.
if [ "${BYPASS_JTBD_CURRENCY:-}" = "1" ]; then
  exit 0
fi

# Fail-open if not inside a git working tree.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Fail-open if the project lacks ADR-051's structural anchors.
# Adopter projects without `./packages/` or `./docs/jtbd/` are not
# subject to the rule; the hook is a no-op for them.
[ -d "./packages" ] || exit 0
[ -d "./docs/jtbd" ] || exit 0

# Fail-open if the detector script itself is missing (defensive —
# hook + detector ship together, but install-time corruption or
# adopter-side patching should not block legitimate commits).
[ -x "$DETECTOR" ] || exit 0

# Run the detector. Capture exit code + output. Fail-open on detector
# error (exit != 0).
DETECTOR_OUTPUT=$(bash "$DETECTOR" "./packages" "./docs/jtbd" 2>/dev/null) || exit 0

# Parse the TOTAL summary line. If absent, no packages were
# enumerated — fail-open (no drift to report).
TOTAL_LINE=$(echo "$DETECTOR_OUTPUT" | grep -E '^TOTAL packages=' | tail -n1)
[ -n "$TOTAL_LINE" ] || exit 0

# Extract drift_instances=<K>.
DRIFT_INSTANCES=$(echo "$TOTAL_LINE" | grep -oE 'drift_instances=[0-9]+' | head -n1 | cut -d'=' -f2)
[ -n "$DRIFT_INSTANCES" ] || exit 0

# Allow path: clean tree.
if [ "$DRIFT_INSTANCES" -eq 0 ]; then
  exit 0
fi

# Drift detected — extract first offending package + its drift hints
# for the deny message. The detector emits one "README package=<name>
# ... drift_hints=<csv>" line per package; we name the first one with
# a non-empty drift_hints.
OFFENDING_LINE=$(echo "$DETECTOR_OUTPUT" | grep -E '^README package=' | grep -vE 'drift_hints=$' | head -n1)
OFFENDING_SLUG=$(echo "$OFFENDING_LINE" | grep -oE 'package=[A-Za-z0-9_-]+' | head -n1 | cut -d'=' -f2)
OFFENDING_HINTS=$(echo "$OFFENDING_LINE" | grep -oE 'drift_hints=[A-Za-z0-9,_-]+' | head -n1 | cut -d'=' -f2)

# Fall back to a generic name if parsing failed (shouldn't happen but
# defensive).
[ -n "$OFFENDING_SLUG" ] || OFFENDING_SLUG="(unknown)"
[ -n "$OFFENDING_HINTS" ] || OFFENDING_HINTS="drift"

# Truncate the hints CSV to the first hint. Multi-hint cases (e.g.
# both `missing-jtbd-section` and `skill-inventory-drift` on one
# package) are bounded so the deny-band stays under 300 bytes for
# worst-case slug + hint combinations.
PRIMARY_HINT="${OFFENDING_HINTS%%,*}"

# Deny — voice/tone budget per ADR-045 deny-band ≤300 bytes total
# (envelope ~137 bytes; REASON ~163 bytes for worst-case slug +
# hint). Names the offending plugin slug, the primary drift hint,
# the wr-jtbd:agent recovery path with hand-edit fallback (graceful
# degradation per architect F advisory), the BYPASS env, and the
# P159 cite.
REASON="BLOCKED: P159 JTBD drift in ${OFFENDING_SLUG} (${PRIMARY_HINT}). Recovery: wr-jtbd:agent OR cite a JTBD-NNN in README. Bypass: BYPASS_JTBD_CURRENCY=1."

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "${REASON}"
  }
}
EOF
exit 0
