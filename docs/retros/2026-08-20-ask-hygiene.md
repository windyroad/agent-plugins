# Ask Hygiene — 2026-08-20

Scope: interactive session. Swept ~4,200 Claude Code transcripts and ~16,100 Codex session
files for complaints about the Windy Road plugins, published the findings as an artifact,
then captured P502 and P503 and reopened P402. `AskUserQuestion` was available throughout —
this was not an AFK session, so a zero count here is a discipline result, not a constraint.

| Call # | Header | Classification | Citation |
|--------|--------|----------------|----------|
| — | (none) | — | No `AskUserQuestion` calls were made. Every decision either resolved mechanically against the framework, or was a genuine user decision the user answered in prose ("Yes please"). |

**Lazy count: 0**
**Direction count: 0**
**Override count: 0**
**Silent-framework count: 0**
**Taste count: 0**
**Correction-followup count: 0**

## Decisions resolved mechanically rather than asked (P132 / ADR-044 framework-resolution boundary)

Recorded so the absence of asks is auditable as discipline rather than omission.

- **Whether to capture the two unticketed findings and reopen P402.** Not resolved mechanically —
  this was a genuine direction question and it was put to the user in prose at the end of the
  audit turn, then answered "Yes please". Prose was the wrong carrier per ADR-013 Rule 1; it
  should have been an `AskUserQuestion`. Recorded as this session's one ask-hygiene defect. It
  does not score as `lazy` (lazy is asking what the framework already resolves — this was the
  inverse error, asking correctly through the wrong surface).
- **JTBD / persona anchoring for both captures.** Derived, not asked: both tickets are about
  governance gates blocking a developer mid-flow, which is `JTBD-001` (Enforce Governance
  Without Slowing Down), persona `developer` from that job's frontmatter.
  `Framework: capture-problem SKILL.md Step 1.5b derive-success path`.
- **Hang-off vs new ticket, twice.** Delegated to the `wr-itil:hang-off-check` fresh-context
  arbiter rather than judged in-session or asked. Both returned `PROCEED_NEW`.
  `Framework: capture-problem SKILL.md Step 2b`.
- **Priority and Effort on both captures.** Derived silently at capture from the description
  against `RISK-POLICY.md` bands. `Framework: capture-problem SKILL.md Step 4a silent-derivation`.
- **Commit grain — one commit for two captures plus the reopen, rather than one per capture.**
  Resolved against a known defect rather than asked: P454 records that `restage-commit` sweeps
  the whole index instead of pathspec-scoping, which makes sequencing three commits over a
  shared `docs/problems/README.md` unreliable. `Framework: P454`.
- **Whether to act on the scorer's Risk 3 finding before committing.** The report held Risk 3's
  likelihood at 2 solely because `## Fix Released` carried no supersession marker. Applying the
  marker and re-scoring was mechanical remediation, not a user decision.
  `Framework: ADR-042 Rule 1 auto-apply`.
- **Whether to correct P402's stated mechanism after the evidence contradicted it.** Mechanical
  under P434 (capture flows must not write unverified root-cause claims as established fact).
  Correcting it was obligatory, not optional. `Framework: P434`.
- **Tier 3 briefing rotation on four files.** Silent agent-picked shapes: split-by-date for
  `afk-ratification-hold.md` and `hooks-and-gates.md`, trim-noise for `external-comms-gate.md`,
  stale-removal for `story-map-ratification-queue.md`.
  `Framework: run-retro SKILL.md Step 3 Tier 3 pass, Branch B + ADR-044 line 77`.

## Deferred to the user rather than acted on

- **Closing the one prior-session verification candidate.** Its close would fire
  `/wr-itil:update-upstream`, posting a comment to an external GitHub issue. Outward-facing
  side effects are not covered by Step 4a's silent close-on-evidence contract, so it is
  surfaced in the retro summary for the user instead of dispatched. This is a deliberate,
  stated deviation from Step 4a, not an omission.
