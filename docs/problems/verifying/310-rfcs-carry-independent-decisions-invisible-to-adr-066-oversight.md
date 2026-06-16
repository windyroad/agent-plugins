# Problem 310: RFCs carry independent decisions invisible to the ADR-066 human-oversight net

**Status**: Verification Pending
**Reported**: 2026-05-26
**Priority**: 3 (Medium) — Impact: 3 x Likelihood: 1 (deferred — re-rate moot; resolution released)
**Effort**: M (actual: fix shipped via RFC-006 7-slice decomposition)

## Resolution (2026-06-16, AFK work-problems iter 30)

Open → Verification Pending: root cause confirmed AND fix released. The RFC-decision blind spot is closed by **ADR-070** (RFCs hold no independent decisions — `human-oversight: confirmed` 2026-05-26; every choice among ≥2 viable options is an ADR, landing in `docs/decisions/` where the ADR-066 detector greps) plus the **ADR-052 lint** (`packages/itil/scripts/check-rfc-rejected-alternatives.sh` — fails any RFC body carrying a rejected-alternatives block without a matching `adrs:` reference). Implemented via **RFC-006** (all 7 slices shipped; status `verifying`), released `@windyroad/itil@0.35.14`.

Investigation-task → slice mapping (every task discharged):

- ADR amending ADR-060 → **ADR-070** (confirmed) + ADR-060 line-97 permissive half deleted (RFC-006 slices 4+6, commit `065f76b`).
- Retrofit RFC-005 decisions → ADRs → slice 1a/1b (ADR-072/073 extracted; RFC-005 reduced to scope + decomposition + traces; commits `b30d08f`, `49c25f4`).
- Strike carve-out from JTBD-008/JTBD-101 → slice 2 (commit `8d8da90`, via ADR-068 oversight-confirm flow).
- Drop "Considered Options / Alternatives Rejected" from RFC template + capture-rfc/manage-rfc → slice 3 (commits `0c8976f`, `38edcdb`).
- Behavioural test + reproduction test (ADR-052) → slice 5 (`check-rfc-rejected-alternatives.sh` + bats; commit `8aa3176`). **Verified green this iter: 24 RFCs scanned, corpus clean (exit 0).**

The P314 follow-up correction touched only ADR-072/073's gate **placement** (the P251/ADR-071 fix-time-enforcement axis) — RFC-006's decision-homing deliverable (P310's actual blind-spot closure) stands unaffected. Full closure rides RFC-006's `verifying` → `closed` user-verification.

Recovery: `/wr-itil:transition-problem 310 open`.

## Description

RFCs carry independent decisions that are invisible to the ADR-066 human-oversight net — unratified decisions drift into accepted RFCs (and the JTBDs they cite) without the user's agreement.

**Concrete evidence (the disavowed carve-out):** the "atomic-fix carve-out" (*Effort ≤ M may skip RFC ceremony; Effort ≥ L requires RFC trace*) reached `RFC-005` **accepted** status as decisions F2/F7/I13, and is anchored in `JTBD-008` (lines 21/26/44) + `JTBD-101`, with **no human ratification**. The user explicitly disavowed it 2026-05-26: *"I did not agree to a atomic-fix carve-out"* and *"Each problem may ONLY be fixed via an RFC"*.

**Root cause:** `ADR-060` line 97 permits RFCs to carry decision content that is NOT ADR-captured — *"An RFC's internal decomposition ... does NOT create ADRs by default; ADRs created during RFC execution capture decisions with scope outside the RFC's own boundary."* Meanwhile `ADR-066`'s unoversighted-decision detector only greps `docs/decisions/`. So a decision living in `docs/rfcs/` is **structurally invisible** to the oversight mechanism designed to catch exactly this — the RFC tier is an unratified-decision blind spot.

**User-ratified direction (2026-05-26, via AskUserQuestion):** RFCs hold NO independent decisions; every choice among ≥2 viable options is an ADR (inherits the ADR-064 confirm gate + ADR-066 born-confirmed oversight marker). Pure sequencing/decomposition of *already-decided* work stays in the RFC (retain ADR-060 line 97's protective half; delete its permissive half). No "Considered Options / Alternatives Rejected" block in an RFC body — contested choices reference the governing ADR(s). The machine-detectable tell: an RFC body containing a rejected-alternatives block with no matching `adrs:` reference is a decision masquerading as scope.

## Symptoms

- Unagreed decisions reach `accepted` RFC status (RFC-005 F2/F7/I13 atomic-fix carve-out).
- The carve-out propagated into JTBD-008/JTBD-101 by citation, compounding the drift.
- ADR-066's `review-decisions` drain + nudge + detector never surface RFC-embedded decisions (grep scope = `docs/decisions/` only).

## Workaround

(deferred to investigation — interim: human review of accepted RFCs for embedded decisions)

## Impact Assessment

- **Who is affected**: maintainers relying on the human-oversight net to catch unratified governance decisions (P283/P288 sibling-class).
- **Frequency**: (deferred to investigation)
- **Severity**: (deferred to investigation — governance-correctness class)
- **Analytics**: 1 confirmed drift instance (RFC-005 atomic-fix carve-out), user-disavowed.

## Root Cause Analysis

ADR-060 line 97 (permissive clause) + ADR-066 detector scope (`docs/decisions/` only) jointly create the RFC-decision blind spot. See Description.

### Investigation Tasks

- [x] Re-rate Priority and Effort at next /wr-itil:review-problems — moot; resolution released (see Resolution)
- [x] Author new ADR amending ADR-060 (delete line-97 permissive half; keep protective half; ≥2-viable-options test; no Considered-Options block in RFCs) — ADR-070 + ADR-060 slices 4+6
- [x] Retrofit RFC-005's F1–F7 decisions out to ADR(s); reduce RFC-005 to scope + decomposition + traces — slice 1a/1b
- [x] Strike the atomic-fix carve-out from JTBD-008 (lines 21/26/44) + JTBD-101 — slice 2
- [x] Drop "Considered Options / Alternatives Rejected" from the RFC template + capture-rfc/manage-rfc skills — slice 3
- [x] Add behavioural test (ADR-052): no RFC body has a rejected-alternatives block without a matching `adrs:` reference — slice 5
- [x] Create reproduction test — the ADR-052 lint is the regression guard (24 RFCs green this iter)

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)
- **Composes with**: P251 (RFC-first trace not enforced at fix-time — the sibling no-carve-out direction); the lift-auto-decisions-to-human class (P283 ADRs, P288 JTBDs, P300/P302)

## Related

- **P251** — RFC-first trace invariant not enforced at fix-time; the user's "every problem fixed only via an RFC, no carve-out" direction strengthens P251's resolution. RFC-005 is P251's RFC and the carrier of the disavowed carve-out.
- **P283** — architect should AskUserQuestion when recording a new decision (ADR oversight); same lift-auto-decisions-to-human class at the ADR surface.
- **P288** — new JTBDs/personas need human-oversight confirmation; same class at the JTBD surface.
- **ADR-060** — the framework this amends (line 97 permissive clause is the root cause).
- **ADR-064 / ADR-066** — the confirm + oversight machinery that all-decisions-are-ADRs inherits for free.
- **RFC-005** (`docs/rfcs/RFC-005-...accepted.md`) — carries the disavowed carve-out (F2/F7/I13); to be retrofitted.
- **JTBD-008 / JTBD-101** — anchor the carve-out; to be amended.
- Captured via /wr-itil:capture-problem 2026-05-26 (P078 capture-on-correction); driver for a new ADR amending ADR-060.

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-006 | verifying | Implement ADR-070 + ADR-071 — re-home RFC decisions to ADRs and make RFC-first unconditional |
