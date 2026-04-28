---
"@windyroad/itil": patch
---

P140 Phase 1 — `/wr-itil:work-problems` Step 6.5 Failure handling adds diagnose-then-classify routing with fix-and-continue branch. Previous behaviour was a uniform halt-on-CI-failure rule that converted mechanically-fixable failures (1-line stale-grep-string updates, transient flakes) into ~45min queue stalls during AFK loops, regressing JTBD-006 "Progress the Backlog While I'm Away" without governance benefit.

What changes (declarative SKILL.md amendment only):

- **Step 6.5 Failure handling subsection** in `packages/itil/skills/work-problems/SKILL.md` rewritten to add:
  - Diagnostic preamble — orchestrator MUST first run `gh run view <run-id> --log-failed` and cite the output verbatim in the fix-and-continue commit message or halt summary (ADR-026 grounding).
  - Closed fixable-in-iter allow-list: P081-class stale-grep-string, hook stub mismatch, test ID drift, environmental flake. **Closed** — adding a class is itself a deviation-candidate per ADR-044 framework-resolution boundary.
  - Ambiguous classification defaults to halt (no diagnose-then-guess).
  - Fix-and-continue branch: 1 Edit → ADR-014 commit gate flow (architect / JTBD / risk-scorer per retry) → push → re-watch CI → resume on pass / increment retry counter on fail.
  - 3-retry cap per iteration (not per failure-class) before fallback to halt branch.
  - Halt branch preserved for genuinely-unrecoverable: auth failure, npm publish rejection, semantic test requiring user judgment, repeated transient failures, anything outside the closed allow-list.
  - Step 2.5b cross-reference (P126) preserved on the halt branch.

- **Non-Interactive Decision Making table** carries a new row "CI failure during Step 6.5 drain (within-appetite branch)" routing through fix-and-continue + 3-retry cap.

- **Mid-loop ask discipline subsection** (P130) Step 6.5 CI-failure halt-point bullet narrowed to outside-allow-list / 3-retry-cap-reached scope. Failures inside the allow-list route to fix-and-continue, not this halt point.

Why: 2026-04-28 session evidence — Step 6.5 drain hit CI failure on test 1375 (P081-class stale `'skip Step 6'` literal vs current `'skip Steps 5b/5c'` SKILL.md prose); 1-line fix; re-pushed; CI passed; release shipped. User correction was explicit and class-level: *"this shouldn't be a halt. This should be a fix and continue"*. P140 codifies this as policy.

Composition: fix-and-continue is policy-authorised per ADR-013 Rule 5 (closed allow-list IS the policy). Each retry's commit rides standard ADR-014 commit gate flow per ADR-042 Rule 3 precedent (retries each ride their own commit through architect / JTBD / risk-scorer review). No governance bypass. Inverse of P132 (over-ask in interactive sessions) on the failure-handling surface; composes with P081 (stop-gap — fix-and-continue elides the friction P081's full retrofit eliminates structurally), P130 (mid-loop ask discipline — fix-and-continue does NOT introduce mid-iter asks), P135 (decision-delegation contract).

Files shipped:
- `packages/itil/skills/work-problems/SKILL.md` — Step 6.5 Failure handling rewrite + Decision table row + halt-point bullet narrowing.
- `packages/itil/skills/work-problems/test/work-problems-step-6-5-fix-and-continue.bats` — NEW 28 behavioural contract assertions per ADR-037 + P081.
- `docs/problems/140-...open.md` → `.verifying.md` — Status flip + Phase 1 shipped section per ADR-022 fold-fix convention.
- `docs/problems/README.md` — WSJF Rankings + Verification Queue refresh per P062.

Out of scope (deferred per ticket Fix Strategy):
- Phase 2 `packages/itil/scripts/diagnose-ci-failure.sh` advisory classifier — observe Phase 1 declarative discipline over 30 days; load-bearing classifier may not be necessary if agent behaviour aligns to the SKILL.md prose.
- Full P081 retrofit of structural-grep tests — separate ticket.

Architect: PASS — Phase 1-only scope correct; ADR-014 invariant preserved (retries each ride own commit through gates, ADR-042 Rule 3 precedent); fix-and-continue branch belongs inside Failure handling subsection (sibling to halt branch, not separate subsection); no new ADR needed (ADR-013 Rule 5 + ADR-044 + in-skill prose suffice). Advisory: closed-allow-list scope-creep guard added per architect FLAG (extension is a deviation-candidate). Stale-decision check: ADR-018 reassessment 2026-07-18 within window; ADR-014 reassessment 2026-10-16 within window.
JTBD: PASS — JTBD-006 primary (restores "progress continues without me being present" while preserving "stops gracefully on a blocker"); JTBD-001 + JTBD-002 compose intact (per-retry gates preserve governance); persona-misread risk addressed via closed-list framing + ambiguous-defaults-to-halt + per-iteration cap clarification.
TDD: 28/28 new bats green; full 203-test work-problems suite green (no regression).
