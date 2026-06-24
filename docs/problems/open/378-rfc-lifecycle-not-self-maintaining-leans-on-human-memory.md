# Problem 378: RFC lifecycle is not self-maintaining — it leans on human memory

**Status**: Open
**Reported**: 2026-06-25
**Priority**: 16 (High) — Impact: 4 (High) × Likelihood: 4 (Likely). Rated at capture. Impact 4: the RFC framework is the thing that tracks all other work, yet it offloads its own upkeep onto the user's memory — the precise anti-pattern the repo exists to prevent (P375/P377), and it ships to adopters. Likelihood 4: every RFC, every slice commit.
**Origin**: internal
**Effort**: M — upgrade the existing advisory trailer hook to an executor + add manage-rfc auto-transition (mirror manage-story) + an RFC-oversight nudge. WSJF = (16 × 1.0) / 2 = 8.0.

## Description

After implementing RFC-029 (6 slices, all commits carrying `Refs: RFC-029` trailers), the agent handed the user a memory checklist: "transition the RFC proposed→accepted, ratify its oversight marker, sequence the release." The user: *"Ok, but I can't remember all those things that need to be done. Why are you leaning on me. Shouldn't updating the RFC be automatic???"* (2026-06-25). Yes — and the framework was designed for it to be, but the automation was deferred-and-never-built:

1. **`## Commits` auto-population never shipped.** capture-rfc's template writes "(maintained automatically — populated by the commit-message RFC trailer hook per ADR-060 Phase 1 item 12; **lands in Slice 3 task B5.T9**)". That executor was never built. `itil-rfc-trailer-advisory.sh` only *nags*; nothing writes the section. RFC-029's `## Commits` sits empty with a false "maintained automatically" claim while 6 trailer-bearing commits go unrecorded.
2. **`manage-rfc` has no auto-transition.** `manage-story` auto-transitions draft→in-progress (first non-capture commit) → done (criteria ticked + linked RFC closes). RFCs have no equivalent — lifecycle is fully manual.
3. **No RFC-oversight nudge.** ADRs (architect-oversight-nudge) and JTBDs (jtbd-oversight-nudge) are auto-surfaced at SessionStart when unconfirmed; captured RFCs (born `human-oversight: unconfirmed`) have no equivalent self-surfacing — ratification leans on memory.

## Root Cause Analysis

### Investigation Tasks

- [x] Rated at capture (Impact 4 × Likelihood 4, Effort M)
- [x] **FIXED via RFC-030 (2026-06-25)** — architect design-reviewed, all 3 pieces built + tested:
  - **Piece 3 (RFC-oversight nudge)** `2863308e` — `itil-rfc-oversight-nudge.sh` + `detect-unoversighted-rfcs.sh`; SessionStart class-B clone of ADR-066/068; surfaces unconfirmed RFCs (dogfood: flushed out 30). Ratification auto-surfaced, not remembered. 7/7 bats.
  - **Piece 1 (`## Commits` derived view)** — `update-rfc-commits-section.sh` + shim + ADR-085; manage-rfc renders `## Commits` from `git log --grep` (Option A, no ADR-014 grain issue); closes the never-built ADR-060 item 12; capture-rfc false claim fixed; RFC-029/030 now accurate. 5/5 bats.
  - **Piece 2 (shared auto-transition trigger)** `d9ee0721` — `itil-commit-trailer-transition-advisory.sh` (PostToolUse) detects first non-capture `Refs: RFC-NNN`/`STORY-NNN` commit → advises the in-progress transition (hook detects, skill commits per ADR-014); closes the "future hook (deferred)" BOTH manage-rfc and manage-story named but never built; both false-auto claims corrected. 6/6 bats.
  - **Census-vocab fold to [[P375]]** `64182ac3` — deferral census now catches "lands in Slice N" / "future slice" / "hook-source slice" markers (the blind spot that let this hide). 12/12 bats.
- [ ] Lifecycle: ratify RFC-030 + ADR-085 (both born `unconfirmed`) — now AUTO-SURFACED by the very nudge this RFC shipped + the architect-oversight nudge; no memory needed.

## Related

- **P375** — uncadenced-deferral immune system (parent class). The deferred-and-unbuilt B5.T9 trailer hook is a direct instance; the census-vocabulary gap is a P375 child task.
- **P377** — framework-should-resolve-not-lean-on-human (sibling class), risk-appetite surface.
- **ADR-060** Phase 1 item 12 — the RFC commit-trailer auto-maintenance the framework promised; the executor was deferred and never landed.
- **manage-story auto-transition** — the precedent to mirror for RFC lifecycle.
- **architect-oversight-nudge / jtbd-oversight-nudge** — the class-B self-surfacing precedent for the RFC-oversight nudge.
- **RFC-029** — the RFC whose empty `## Commits` + manual lifecycle surfaced this.

(captured via direct write — rated at capture per the P375 rate-at-capture rule)

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-030 | proposed | RFC lifecycle self-maintenance |
