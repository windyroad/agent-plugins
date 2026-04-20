---
"@windyroad/retrospective": minor
---

**run-retro**: add Step 4a "Verification-close housekeeping" so session-wrap surfaces `.verifying.md` tickets whose fixes were exercised successfully in-session, with specific citations (closes P068).

New Step 4a fires between the existing Step 4 (problem tickets) and Step 4b (codification candidates). It globs `docs/problems/*.verifying.md`, reads each ticket's `## Fix Released` section, scans session activity for specific invocation citations (test runs, commits, skill invocations, hook firings, release cycles), and categorises each ticket as exercised-successfully / not-exercised / exercised-with-regression.

Close-candidate decisions go through `AskUserQuestion` with the fix summary AND specific citations inline (per ADR-013 Rule 1) — the prompt is self-contained so the user can decide without reading the full ticket file. Three options: close now (delegates to `/wr-itil:manage-problem` Step 7 for the transition — run-retro does not rename or commit), leave as Verification Pending, or flag for manual review.

Non-interactive / AFK fallback (per ADR-013 Rule 6) writes a new "Verification Candidates" section into the retro report; does NOT auto-close and does NOT delegate to manage-problem.

- Evidence citations must be specific (tool invocation + observable outcome, not bare counts) per ADR-026 grounding.
- Ownership boundary: run-retro surfaces evidence only; `/wr-itil:manage-problem` Step 7 owns the Verification Pending → Closed transition (rename + Status edit + P057 re-stage + ADR-014 commit per ADR-022).
- ADR-027 compatibility note embedded: when Step-0 auto-delegation lands on run-retro, the evidence scan must either run in main-agent context before delegation (preferred) or the delegation prompt must include an explicit session-activity summary.
- Same-session verifyings (tickets transitioned to `.verifying.md` in the currently-running session) are skipped — subsequent-session exercise is the meaningful signal.

Composes with manage-problem Step 9d (the age-based heuristic path) — both can fire independently; closing via either de-lists the ticket from both queues.

Cites the user's documented preference in `feedback_verify_from_own_observation.md` to verify from in-session observations rather than deferring everything to the user.
