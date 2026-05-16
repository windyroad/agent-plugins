# Problem 230: README-refresh-discipline hook misfires on narrative-only ticket edits when no ranking-bearing field changed AND reconcile-readme.sh exit=0

**Status**: Open
**Reported**: 2026-05-15
**Priority**: 6 (Med) — Impact: 2 (Minor — false-positive deny adds friction but recovery is mechanical; no data loss) × Likelihood: 3 (Likely — fires on every Change Log / Investigation Task checkbox edit where ranking-bearing fields unchanged AND README already in sync)
**Effort**: S (deferred — re-rate at next `/wr-itil:review-problems`)
**WSJF**: (6 × 1.0) / 1 = **6.0** (deferred — provisional)
**Type**: technical

> Captured 2026-05-15 by `/wr-itil:work-problems` AFK loop iter 1 surfacing pass per user direction. Sibling to [[P231]] (BYPASS env-var deny-message correction) — same hook, distinct fix.

## Description

`packages/itil/hooks/itil-readme-refresh-discipline.sh` (with `packages/itil/hooks/lib/readme-refresh-detect.sh`) denies `git commit` on **narrative-only** ticket edits — e.g. appending a Change Log entry or ticking an Investigation Task checkbox — when **no ranking-bearing field has changed** AND `packages/itil/scripts/reconcile-readme.sh` reports `exit=0` against the current README. The hook treats every ticket edit as potentially-drift-bearing without inspecting whether the staged diff touches Priority / Effort / Status / WSJF / Title fields, and without consulting the reconcile-readme exit code first.

## Symptoms

- iter 1 (2026-05-15) hit the trap on a P162 ticket Change Log entry + Phase 4 Investigation Task checkbox tick — no ranking-bearing field changed; `reconcile-readme.sh` exit=0; hook still denied with `BLOCKED: P165. P162 needs docs/problems/README.md refresh.`
- Workaround: substantive narrative edit to `docs/problems/README.md` "Last reviewed" line forces README into the staged set even though no actual inventory drift exists — manipulation of the README to satisfy the hook rather than because the README needs refreshing.

## Workaround

Substantive narrative edit to `docs/problems/README.md` "Last reviewed" line + `git add` + retry. Works but adds 1 file-write + 1 retry per narrative-only ticket edit cycle.

## Impact Assessment

- **Who is affected**: anyone editing a problem ticket's Change Log or Investigation Tasks without touching ranking-bearing fields.
- **Frequency**: every Change Log entry / every Investigation Task tick — Iter 1 hit once; iter 3 + 4 may have hit (deferred to investigation).
- **Severity**: Minor (mechanical recovery; no data loss).

## Root Cause Analysis

### Investigation Tasks

- [ ] Audit `readme-refresh-detect.sh` for the staged-diff parsing — does it distinguish ranking-bearing vs narrative-only edits?
- [ ] Confirm the reconcile-readme exit-code disjunct: if exit=0 (no drift), the hook should silently pass regardless of ticket edits
- [ ] Behavioural bats: narrative-only edit + exit=0 reconcile → hook passes silently
- [ ] Behavioural bats: ranking-bearing edit + exit=1 reconcile → hook denies as today
- [ ] Behavioural bats: ranking-bearing edit + exit=0 reconcile (race) → hook passes (reconcile is the authority)

## Fix Strategy

Extend `readme-refresh-detect.sh` with narrative-only-edit detection: when staged ticket has no ranking-bearing field change (grep staged diff for Priority/Effort/Status/WSJF/Title field-line changes — empty match = narrative-only) AND `reconcile-readme.sh` reports exit=0 against current README, silently pass. Eliminates the friction class for narrative-only ticket edits.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: [[P231]] (BYPASS env-var deny-message correction — same hook surface, sibling fix)

## Related

(captured via `/wr-itil:capture-problem` equivalent — direct write at /wr-itil:work-problems orchestrator main-turn wrap)

## Change Log

- **2026-05-15** — Opened by `/wr-itil:work-problems` AFK orchestrator main-turn wrap, per user answer "Yes — capture as two separate tickets" to README-refresh question after iter 1 surfaced the friction.
