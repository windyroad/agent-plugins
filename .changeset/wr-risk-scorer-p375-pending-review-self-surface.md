---
"@windyroad/risk-scorer": patch
---

P375: make the risk-scorer SessionStart nudge self-surface the standing-risk pending-review backlog instead of going silent once the register exists.

`risk-scorer-scaffold-nudge.sh` previously emitted a one-line nudge only when `RISK-POLICY.md` was present but `docs/risks/` was missing, then went silent forever once the register directory existed. Auto-scaffolded entries born `**Curation**: pending review` (controls + Impact×Likelihood scoring not yet human-curated) therefore accumulated invisibly — the audit's "one step short of the jtbd pattern" gap.

The hook now, once `docs/risks/` exists, counts entries still carrying the `**Curation**: pending review` marker and re-surfaces the count every session until the backlog is drained (singular/plural phrasing; points at manual curation in `docs/risks/`). This is the class-B self-surfacing pattern already used by `jtbd-oversight-nudge.sh` / `architect-oversight-nudge.sh` — count content state, re-surface every SessionStart, silent at zero. Read-only and token-cheap (a grep over the register dir, no body reads). The existing missing-directory and no-policy branches are unchanged, and the AFK self-suppress guard (`WR_SUPPRESS_OVERSIGHT_NUDGE=1`) still suppresses the new branch so it never fires into absent-user iterations. Five behavioural bats added/updated (pending-count plural, singular, no-marker silence, empty-register silence, AFK-guard suppression). Refs: P375.
