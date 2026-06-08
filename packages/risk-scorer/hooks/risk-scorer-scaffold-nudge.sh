#!/usr/bin/env bash
# wr-risk-scorer — SessionStart hook (ADR-047 Amendment 2026-06-08, P297)
#
# Surfaces a one-line nudge when this project has a RISK-POLICY.md (the
# trigger condition for an ISO 31000 / ISO 27001 standing-risk register)
# but lacks the docs/risks/ directory the register lives in. The user
# scaffolds the register on-demand via /wr-risk-scorer:bootstrap-catalog
# (ADR-059); this hook is the discovery surface — it does NOT write.
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

# Silent when the register directory already exists — the scaffold has
# either already happened or the user has populated it manually.
[ -d "$REGISTER_DIR" ] && exit 0

echo "[wr-risk-scorer] RISK-POLICY.md present but docs/risks/ is missing — run /wr-risk-scorer:bootstrap-catalog to scaffold the standing-risk register."
