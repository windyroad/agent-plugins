#!/usr/bin/env bash
# wr-risk-scorer — SessionStart hook. Three arms, first match wins:
#   policy absent   → ADR-108
#   register absent → ADR-047
#   entries pending → ADR-113
#
# Surfaces a one-line nudge when this project has a RISK-POLICY.md (the
# trigger condition for an ISO 31000 / ISO 27001 standing-risk register)
# but lacks the docs/risks/ directory the register lives in. The user
# scaffolds the register on-demand via /wr-risk-scorer:bootstrap-catalog
# (ADR-059); this hook is the discovery surface — it does NOT write.
#
# Once docs/risks/ exists, the hook no longer goes silent — it counts
# entries still carrying the `**Curation**: pending review` marker and
# re-surfaces the count every session. This closes the
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

cat >/dev/null
IS_CODEX="${CODEX_THREAD_ID:+1}"

emit_message() {
  if [ "${IS_CODEX:-0}" = "1" ]; then
    MESSAGE="$1" python3 -c 'import json,os; print(json.dumps({"systemMessage": os.environ["MESSAGE"]}))'
  else
    printf '%s\n' "$1"
  fi
}

if [ "${WR_SUPPRESS_OVERSIGHT_NUDGE:-}" = "1" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
POLICY_FILE="$PROJECT_DIR/RISK-POLICY.md"
REGISTER_DIR="$PROJECT_DIR/docs/risks"

# Silent when the project dir itself does not exist — no adopter project
# to nudge (e.g. a stale CLAUDE_PROJECT_DIR).
[ -d "$PROJECT_DIR" ] || exit 0

# Policy file absent entirely (ADR-108, inverse predicate of the
# register-missing arm below). Without a RISK-POLICY.md the risk-scorer
# gates run at their default appetite (5 per ADR-086) silently, and the
# capability sits dormant with no surfacing that a policy can be authored.
# Nudge the adopter to author one via /wr-risk-scorer:update-policy. The
# original guard treated bare policy-absence as a non-gap; ADR-108 weighs
# that reversal against the narrower alternative — nudging only where a
# reports directory shows the scorer in use — and takes this one. Read-only
# — the hook never writes; the policy authoring is gated behind the user
# invoking the on-demand skill.
if [ ! -f "$POLICY_FILE" ]; then
  emit_message "[wr-risk-scorer] No RISK-POLICY.md in this project — run /wr-risk-scorer:update-policy to author one so the risk-scorer gates score against your appetite instead of the default."
  exit 0
fi

# Register directory missing — nudge to scaffold it.
if [ ! -d "$REGISTER_DIR" ]; then
  emit_message "[wr-risk-scorer] RISK-POLICY.md present but docs/risks/ is missing — run /wr-risk-scorer:bootstrap-catalog to scaffold the standing-risk register."
  exit 0
fi

# Register exists: count entries still carrying the curation marker so the
# pending-review backlog self-surfaces every session (class-B, P375)
# instead of going silent once stubs exist. Token-cheap grep over the
# register dir — no body reads, no per-file LLM call (matches the
# jtbd-oversight-nudge.sh cost profile).
# Retired entries are excluded. A risk that has been closed no longer needs its
# impact and likelihood weighed, and counting them puts a floor under the number
# that curation cannot move — 22 of 69 on 2026-08-09 — which would make the
# count undrainable and the nudge permanent.
#
# EXCLUSION-shaped, not an `*.active.md` inclusion. The register's status
# vocabulary is three-valued: `.active.md`, `.accepted.md` for a risk that is
# consciously tolerated, and `.retired.md`. An accepted risk is live, and the
# Impact x Likelihood the curation marker says is missing is exactly what a
# decision to tolerate it should have rested on — so it counts. Matching on
# active alone would write those off silently, and would also miss an
# unsuffixed entry, which the register README documents as the pre-retire form.
PENDING="$(grep -rlE '^\*\*Curation\*\*: pending review' "$REGISTER_DIR" 2>/dev/null \
  | grep -v '\.retired\.md$' | grep -c . || true)"
PENDING="${PENDING:-0}"

[ "$PENDING" -gt 0 ] 2>/dev/null || exit 0

if [ "$PENDING" -eq 1 ]; then
  emit_message "[wr-risk-scorer] 1 standing-risk entry is pending review — curate it in docs/risks/ (enumerate controls + Impact×Likelihood scoring)."
else
  emit_message "[wr-risk-scorer] $PENDING standing-risk entries are pending review — curate them in docs/risks/ (enumerate controls + Impact×Likelihood scoring)."
fi
