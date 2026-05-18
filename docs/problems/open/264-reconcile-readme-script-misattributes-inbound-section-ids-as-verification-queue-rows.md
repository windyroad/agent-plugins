# Problem 264: reconcile-readme script misattributes Inbound Upstream Reports section IDs as Verification Queue rows

**Status**: Open
**Reported**: 2026-05-18
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate at next /wr-itil:review-problems)
**Effort**: M (deferred — re-rate at next /wr-itil:review-problems)
**Type**: technical

## Description

`packages/itil/scripts/reconcile-readme.sh` extracts IDs from `docs/problems/README.md`'s `## Inbound Upstream Reports` section as if they were Verification Queue rows. The script's section-boundary detection (`VQ_END=${CLOSED_START:-...}`) only knows four section headers — `## WSJF Rankings`, `## Verification Queue`, `## Closed`, `## Parked` — so the range it slices for VQ extraction runs from `## Verification Queue` (line 120) all the way to `## Closed` (line 246), capturing the Inbound Upstream Reports section (line 208-245) in between.

Inbound Upstream Reports rows include a `Matched local ticket` column rendered as `| P<NNN> |`. The `extract_section_ids` function's regex `'\| *P[0-9]{3} *\|'` matches those column values and treats them as VQ rows. The on-disk file for those IDs is `.open.md` (they're upstream-mirror tickets opened during 2026-05-15 inbound-cohort triage), so the script emits `STALE P<NNN> verification-queue: actual=open` for every ID in the Matched-local-ticket column.

Observed effect on 2026-05-18 work-problems session 7 start: 31 false-positive STALE entries (P198-P228). Cannot be mechanically corrected by `/wr-itil:reconcile-readme` because the rows aren't actually in VQ — `Edit`-tool old_string matches against VQ rows would fail (the rows live in the Inbound section), and matching the Inbound rows would destroy that section's legitimate `pending-pipeline-processing` audit trail.

The Inbound Upstream Reports section was added per ADR-062 § Step 9e renderer when `/wr-itil:review-problems` Step 4.5 inbound-discovery pipeline shipped. The renderer documents itself at the section header but the reconcile script was never updated to recognise this fifth section.

**Fix**: extend `packages/itil/scripts/reconcile-readme.sh` lines 105-117 to detect `## Inbound Upstream Reports` as a section boundary:

```bash
INBOUND_START=$(grep -n '^## Inbound Upstream Reports' "$README" | head -1 | cut -d: -f1)
VQ_END=${INBOUND_START:-${CLOSED_START:-${PARKED_START:-$END_LINE}}}
```

The Inbound section's rows are not in VQ-extraction scope (they're rendered from `.upstream-cache.json`, not from on-disk ticket files), so the script should bypass the section entirely — terminating VQ extraction at the Inbound header.

## Symptoms

(deferred to investigation)

## Workaround

(deferred to investigation — the in-session workaround was user-direction "Capture script-bug ticket, proceed AFK" routing past the HALT_ROUTE_RECONCILE branch since the false-positive drift is not mechanically actionable)

## Impact Assessment

- **Who is affected**: (deferred to investigation)
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation)
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [ ] Investigate root cause
- [ ] Create reproduction test
- [ ] Update `packages/itil/scripts/test/reconcile-readme.bats` with a fixture README carrying an Inbound Upstream Reports section to lock the fix

## Dependencies

- **Blocks**: (none observed yet — investigate whether P199's same-session reconcile halt is composable with this gap)
- **Blocked by**: (none)
- **Composes with**: P118 (reconcile-as-preflight-robustness), P199 (capture-problem same-session reconcile halts), P094 (refresh-on-create), P062 (refresh-on-transition), ADR-062 (Inbound Upstream Reports renderer)

## Related

(captured via /wr-itil:capture-problem; expand at next investigation)

- P118 — driver for the reconcile-readme cross-session robustness layer; this gap is a script-detector limitation downstream of P118's contract
- P199 — capture-problem → manage-problem same-session halts at Step 0 reconcile (HALT_ROUTE_RECONCILE); the inbound false-positive triggers this halt every session until fixed
- ADR-062 § Step 9e — Inbound Upstream Reports renderer that introduced the fifth section
- `packages/itil/scripts/reconcile-readme.sh` lines 105-117 — section-boundary detection that needs the fix
