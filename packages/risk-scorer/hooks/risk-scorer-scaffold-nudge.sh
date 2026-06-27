#!/usr/bin/env bash
# wr-risk-scorer — SessionStart hook (ADR-047 Amendment 2026-06-08, P297)
#
# Surfaces a one-line nudge when this project has a RISK-POLICY.md (the
# trigger condition for an ISO 31000 / ISO 27001 standing-risk register)
# but lacks the docs/risks/ directory the register lives in. The user
# scaffolds the register on-demand via /wr-risk-scorer:bootstrap-catalog
# (ADR-059); this hook is the discovery surface — it does NOT write.
#
# P375 (2026-06-27): once docs/risks/ exists, the hook no longer goes
# silent — it counts entries still carrying the `**Curation**: pending
# review` marker and re-surfaces the count every session. This closes the
# audit's "one step short of the jtbd pattern" gap: the scaffold check
# alone went quiet once stubs existed, so the pending-review backlog
# (auto-scaffolded entries whose controls + Impact×Likelihood scoring are
# not yet human-curated) rotted invisibly. Counting content state and
# re-surfacing until drained is the class-B self-surfacing pattern that
# jtbd-oversight-nudge.sh / architect-oversight-nudge.sh already use.
#
# Read-only, side-effect-free. Modelled on
# packages/architect/hooks/architect-oversight-nudge.sh (ADR-066) and
# packages/jtbd/hooks/jtbd-oversight-nudge.sh (ADR-068). Per ADR-040 the
# SessionStart surface stays read-mostly — this hook does not write to
# the adopter tree; the scaffold write is gated behind the user
# invoking the on-demand skill.
#
# AFK self-suppress (JTBD-006 friction guard): AFK orchestrators set
# WR_SUPPRESS_OVERSIGHT_NUDGE=1 before spawning each `claude -p` iteration
# so this interactive scaffold-confirm nudge never fires into an
# absent-user subprocess. The suite-wide env var is established by
# ADR-068 — one suppress variable governs every oversight-class nudge,
# scaffold-class included. Only the literal "1" suppresses.

set -euo pipefail

if [ "${WR_SUPPRESS_OVERSIGHT_NUDGE:-}" = "1" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
POLICY_FILE="$PROJECT_DIR/RISK-POLICY.md"
REGISTER_DIR="$PROJECT_DIR/docs/risks"

# Silent when the project does not have a risk policy. The policy file
# presence is the user authorisation for the register to exist; without
# it, the absence of docs/risks/ is not a governance gap.
[ -f "$POLICY_FILE" ] || exit 0

# Register directory missing — nudge to scaffold it.
if [ ! -d "$REGISTER_DIR" ]; then
  echo "[wr-risk-scorer] RISK-POLICY.md present but docs/risks/ is missing — run /wr-risk-scorer:bootstrap-catalog to scaffold the standing-risk register."
  exit 0
fi

# Register exists: count entries still carrying the curation marker so the
# pending-review backlog self-surfaces every session (class-B, P375)
# instead of going silent once stubs exist. Token-cheap grep over the
# register dir — no body reads, no per-file LLM call (matches the
# jtbd-oversight-nudge.sh cost profile).
PENDING="$(grep -rlE '^\*\*Curation\*\*: pending review' "$REGISTER_DIR" 2>/dev/null | grep -c . || true)"
PENDING="${PENDING:-0}"

[ "$PENDING" -gt 0 ] 2>/dev/null || exit 0

if [ "$PENDING" -eq 1 ]; then
  echo "[wr-risk-scorer] 1 standing-risk entry is pending review — curate it in docs/risks/ (enumerate controls + Impact×Likelihood scoring)."
else
  echo "[wr-risk-scorer] $PENDING standing-risk entries are pending review — curate them in docs/risks/ (enumerate controls + Impact×Likelihood scoring)."
fi
