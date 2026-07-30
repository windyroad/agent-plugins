#!/usr/bin/env bash
# wr-itil — SessionStart hook (P474 / RFC-059 / STORY-054).
#
# Surfaces a one-line nudge when any story still carries the `**Status**:` body
# line that duplicates its frontmatter `status:`. That duplicate is why an accept
# transition used to drift a story's own oversight fingerprint — the story read
# as unratified moments after being ratified, and the no-implement gate then
# denied its own implementing commit.
#
# Why a hook and not just a release note. The migration ships as a PATH shim, so
# it never appears in `/` autocomplete, and a release note cannot fire inside an
# adopter's repo — as a control it depends entirely on someone remembering. A
# maintenance action with no automatic trigger does not happen, so artefacts
# predating the fix would keep the defect indefinitely while newly captured
# stories were immune. JTBD-009 already sanctions this shape: "Idempotency is
# what makes the speculative invocation safe — and what makes the skill safe to
# wire into bootstrap / install flows."
#
# NUDGE ONLY — this hook MUST NOT run the migration. JTBD-009's ratified
# "Foreground-synchronous + self-committed" outcome is explicit that the
# developer reviews the rewritten artefacts before they ship, so migrating
# unattended would breach a ratified outcome rather than serve it.
#
# Names the ADR-049 PATH shim, never a repo-relative `packages/...` path — the
# latter resolves only in the source monorepo, which is exactly the blind spot
# source-repo dogfooding hides (P151/P153/P219/P317).
#
# Detection is token-cheap: one grep over story filenames, no body reads beyond
# the match, no LLM call. Silent when clean (the steady state after migrating),
# fail-open, one line, within the ADR-040 ≤2KB budget.
#
# AFK self-suppress: shares the suite-wide WR_SUPPRESS_OVERSIGHT_NUDGE guard
# with the architect / jtbd / itil-rfc oversight nudges, so an orchestrator
# exports it once and every nudge self-suppresses rather than firing at an
# absent user (JTBD-006 friction guard). Only the literal "1" suppresses.

set -uo pipefail

if [ "${WR_SUPPRESS_OVERSIGHT_NUDGE:-}" = "1" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STORIES_DIR="$PROJECT_DIR/docs/stories"

[ -d "$STORIES_DIR" ] || exit 0

# STORY-*.md only. README.md documents the template and legitimately shows the
# field, so scanning it would make this nudge fire forever on a clean corpus.
COUNT=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  if grep -qE '^\*\*Status\*\*:' "$f" 2>/dev/null; then
    COUNT=$((COUNT + 1))
  fi
done < <(find "$STORIES_DIR" -mindepth 1 -maxdepth 2 -name 'STORY-*.md' -type f 2>/dev/null)

[ "$COUNT" -gt 0 ] 2>/dev/null || exit 0

if [ "$COUNT" -eq 1 ]; then
  echo "[wr-itil] 1 story still duplicates its status in a \`**Status**:\` body line, so accepting it will drop its ratification — run \`wr-itil-migrate-story-status-mirror docs/stories\` once to remove the duplicate and carry each ratification forward."
else
  echo "[wr-itil] $COUNT stories still duplicate their status in a \`**Status**:\` body line, so accepting them will drop their ratification — run \`wr-itil-migrate-story-status-mirror docs/stories\` once to remove the duplicates and carry each ratification forward."
fi
