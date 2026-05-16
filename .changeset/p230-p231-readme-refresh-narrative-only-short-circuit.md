---
"@windyroad/itil": patch
---

README-refresh-discipline hook now allows narrative-only ticket edits when the README is in-sync with filesystem truth

`packages/itil/hooks/lib/readme-refresh-detect.sh` extends `detect_readme_refresh_required` with a narrative-only short-circuit. When all staged ticket edits are purely narrative — no ranking-bearing field change (Priority / Effort / Status / WSJF / Type field-lines), no title-line change, no rename between state subdirs, no creation or deletion — AND `packages/itil/scripts/reconcile-readme.sh` reports `exit=0` against the current README, the hook returns 0 (allow silently). Reconcile-readme is the authoritative drift oracle for narrative-only edits; the README is in sync, so a narrative tweak (Change Log entry, Investigation Task checkbox tick) cannot drift it.

Ranking-bearing edits still fall through to existing deny detection regardless of reconcile state, preserving ADR-014 single-commit grain for the change-set surface. Reconcile-readme is a robustness layer on top of per-operation README refresh, not a supersession.

Detection helpers `_readme_refresh_staged_is_ranking_bearing` and `_readme_refresh_reconcile_clean` are internal to the lib; the public `detect_readme_refresh_required` entry-point shape is unchanged.

The hook's deny-message bypass advertisement is corrected from misleading inline-prefix syntax (which does NOT propagate to PreToolUse hooks per P173) to the working `.claude/settings.json` env-field path. Stays within ADR-045 deny-band.

Behavioural test coverage: 7 new cases in `packages/itil/hooks/test/itil-readme-refresh-discipline.bats` — narrative-only edit (Change Log + Investigation Task tick) + reconcile clean → allow; ranking-bearing Status field change + reconcile clean → deny; ranking-bearing Priority field change + reconcile clean → deny; rename between state subdirs (open → verifying) + no README → deny; narrative-only edit + reconcile drift → deny; deny-message asserts `.claude/settings.json` + P173 reference. 29/29 green.

Closes P230 (hook misfires on narrative-only ticket edits when no ranking-bearing field changed AND reconcile-readme exit=0). Closes P231 (deny message advertises inline-prefix bypass syntax that does not propagate; recurrence of P173 at the README-refresh-hook surface).
