# Problem 270: Agent waits for human to initiate upstream report instead of filing on detect — feedback delay class

**Status**: Open
**Reported**: 2026-05-18
**Priority**: 8 (Medium) — Impact: 2 × Likelihood: 4
**Effort**: M (re-estimated 2026-05-18 — AFK orchestrator Step 4 fallback amendment + security/non-security classifier + bats fixture)

## Description

> I'm finding that nothing is proactivly reported upstream. The agent knows it needs to be reported, but waits for the human to initiate, which often doesn't happen because the human doesn't know. Also, it delays the feedback getting to the upsteam. When the agent detects that the issue is upstream, it should report it ASAP

The current P063 + ADR-024 contract instructs the agent to append a stable `- **Upstream report pending** — external dependency identified; invoke /wr-itil:report-upstream when ready` marker to the ticket's `## Related` section when external root cause is detected. The marker preserves the audit trail across AFK iterations BUT does not file the report itself — the SKILL.md `/wr-itil:report-upstream` Step 6 security-path branch is interactive (per ADR-024 Consequences) so the AFK orchestrator never auto-invokes it. The defect captured here is that the human-initiate gate is asymmetric to the agent-detect signal: the agent has all the evidence it needs at detect-time (problem ticket body, upstream repo identified, P063 marker just appended), but the report waits for a human turn that often never comes because the human doesn't know there's a pending report queued.

Worked example evident in this session's BRIEFING.md carryover lines: "P010 + P007 composed upstream report against @windyroad/wr-risk-scorer (authorized — to be filed via /wr-itil:report-upstream when you're ready)" + "P011 upstream report against Claude Code (authorized — same)". Both have been authorized for an unspecified prior window; neither has been filed; the upstream maintainers have no visibility into the issues we've identified.

## Symptoms

(deferred to investigation)

Initial observations:
- BRIEFING.md "Carryover for next session" sections accumulate "authorized — to be filed when you're ready" lines across sessions without the corresponding `gh issue` filings landing.
- The `- **Upstream report pending** —` marker in ticket bodies is a static signal; nothing scans for it across the backlog to surface the unsent queue.
- The AFK orchestrator's Step 4 P063 fallback appends the marker but does NOT proactively invoke `/wr-itil:report-upstream` (per ADR-013 Rule 6 fail-safe — interactive security path).
- Upstream maintainers receive feedback at human-initiate latency (potentially weeks or never) instead of agent-detect latency (within the iter that surfaced the root cause).

## Workaround

User manually invokes `/wr-itil:report-upstream` for each pending ticket. Friction: the user has to know the pending queue exists, walk to each ticket, and run the skill — bypassed in practice because the queue is invisible.

## Impact Assessment

- **Who is affected**: (deferred to investigation) — likely both maintainers (upstream feedback delay) and adopters (their problems are upstream-blocked but the upstream doesn't know to fix).
- **Frequency**: (deferred to investigation) — every external-root-cause detection in an AFK iteration produces an unsent report.
- **Severity**: (deferred to investigation) — initial: moderate. Compounds over time as the unsent queue grows.
- **Analytics**: (deferred to investigation) — count of `- **Upstream report pending** —` markers in docs/problems/ vs count of corresponding `gh issue` filings in `## Reported Upstream` sections.

## Root Cause Analysis

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate root cause — ADR-024 § Consequences "security-path branch is interactive" is the load-bearing constraint; can the non-security path (default external problem-report) be auto-invoked in AFK while preserving the security-path interactive carve-out? **Answer: yes; ADR-024's AFK constraint is scoped to the security-path branch, not blanket. The orchestrator-side over-restriction is a misreading.** See "Findings 2026-06-02" below.
- [x] Audit current state: grep `docs/problems/` for the `- **Upstream report pending** —` marker; cross-reference against `## Reported Upstream` sections to compute the unsent queue depth. **Result: 9 tickets carry the pending marker (4 .verifying.md, 3 .closed.md, 2 .open.md). The 2 open ones are P254 + P270 — both this ticket cluster's own concerns. 13 tickets carry filed `## Reported Upstream` sections. Unsent queue depth ≈ 0 for ordinary tickets right now — but the structural defect (orchestrator never auto-fires) persists; depth will grow whenever AFK iters detect new external root causes without being followed by a human turn.**
- [ ] Consider sibling P249 (Phase 1 shipped `/wr-itil:check-upstream-responses` polling shape) — symmetric pattern; this ticket is the proactive-fire counterpart on the outbound side.
- [ ] Design candidate: AFK orchestrator Step 4 fallback amendment — after P063 marker append, classify the upstream report risk (security vs non-security); auto-invoke `/wr-itil:report-upstream` for non-security; preserve interactive carve-out for security per ADR-024 Consequences. **Status: blocked on ADR-024 amendment — see "Findings 2026-06-02" below.**
- [ ] Create reproduction test (bats fixture: ticket transitions Open → Known Error with external root cause; iter auto-files non-security report; security-classified report still defers to interactive).

### Findings 2026-06-02 (P270 investigation iter)

**Source-code surface inspected**:

- `packages/itil/skills/work-problems/SKILL.md:309` (classifier table `upstream-blocked` row) — current text: *"append the pending-upstream-report marker ... do NOT auto-invoke `/wr-itil:report-upstream` (Step 6 security-path branch is interactive — per ADR-024 Consequences)"*.
- `packages/itil/skills/work-problems/SKILL.md:787` (decision-table row) — same instruction, same authority citation.
- `packages/itil/skills/manage-problem/SKILL.md:669` (Open → Known Error AFK fallback) — same instruction: *"Do NOT auto-invoke `/wr-itil:report-upstream`; its Step 6 security-path branch is interactive and would halt the orchestrator anyway (per ADR-024 Consequences)."*
- `packages/itil/skills/report-upstream/SKILL.md:505-515` (AFK behaviour summary table) — actually documents that the **public-issue path (Step 5) PROCEEDS in AFK** (line 511); only the dedup-match (4b) and security-path (6 missing-SECURITY.md branch) halt. So the skill itself is NOT blanket-AFK-halt — it has per-branch behaviour.

**Diagnosis**: the orchestrator + manage-problem "do NOT auto-invoke" instruction misreads ADR-024 Consequences as a blanket AFK constraint when the ADR text actually scopes the halt to the security-path branch only:

- ADR-024 Consequences (Neutral) line 129: *"The security-path halt-and-surface branch is interactive ... In AFK mode, the skill must fall through to ... halt the orchestrator — AFK orchestrators should never auto-report a security-classified ticket."*
- ADR-024 Consequences (Bad) line 137: *"Security-path halt-and-surface requires an interactive user. In truly autonomous contexts (AFK orchestrators), the skill MUST NOT auto-resolve the dilemma."*

Both clauses are explicitly scoped to **security-classified tickets**. Non-security tickets are unconstrained in AFK by the ADR.

The orchestrator currently treats this security-only constraint as a blanket "never auto-invoke" — clamping the non-security public-issue path that the report-upstream skill's own AFK behaviour table says proceeds. This is the structural defect P270 captures.

**Fix shape (REQUIRES USER RATIFICATION — see Design decision pending)**:

1. `wr-risk-scorer:external-comms` has shipped (`packages/risk-scorer/agents/external-comms.md` + `packages/risk-scorer/skills/assess-external-comms/` present) — the interim static heuristic in ADR-024 Step 4b's AFK branch has met its lift-condition. The dedup-AFK branch can lift from "halt-and-save" to "auto-comment when both evaluators return PASS".
2. Orchestrator + manage-problem AFK fallback amendment: pre-classify ticket (security vs non-security) BEFORE the marker-or-invoke decision:
   - **Non-security ticket in AFK**: invoke `/wr-itil:report-upstream` (the skill's own per-branch AFK behaviour handles dedup-halt, public-issue auto-proceed, voice-tone delegate-and-retry, commit-gate fail-safe). Append the `## Reported Upstream` section per ADR-024 Step 7 back-write.
   - **Security-classified ticket in AFK**: retain current behaviour (append `- **Upstream report pending** —` marker; defer to interactive turn). This preserves ADR-024 Consequences line 129/137.
   - Pre-classification heuristic: re-use ADR-024 Step 4 security-path detection (label `security` in Priority; presence of a Security classification section in the ticket body).
3. SKILL.md prose: `packages/itil/skills/work-problems/SKILL.md` Step 4 classifier table + decision-table rows, `packages/itil/skills/manage-problem/SKILL.md` Step 6 AFK fallback — all three need the new branching prose.
4. Bats fixture: assert the new branching (non-security auto-invokes; security-classified defers).
5. **ADR-024 amendment**: explicitly authorize the orchestrator-side pre-classification + non-security auto-invoke. This is a **partial Consequences reversal** for the non-security path — the previous "AFK orchestrators should never auto-report" applies to security tickets only; non-security path auto-invokes per the skill's own AFK behaviour table. The amendment also resolves the orchestrator-side authority chain: the current "do NOT auto-invoke" instruction cites ADR-024 as authority, and reversing it without amending the ADR breaks the trace.

**Why this requires an ADR amendment, not a mechanical SKILL fix**:

- The current orchestrator instruction cites ADR-024 as authority. Reversing the instruction without amending the cited ADR creates a stale authority-cite — exactly the class P057-staging-trap / P063-marker-drift pattern: SKILL prose says X with cite-to-Y; Y says Z (not X); next reader can't tell which to trust.
- The fix introduces a new framework-resolution boundary (the orchestrator-side pre-classification gate) that ADR-024 does not currently describe. Per ADR-044, framework-resolution boundaries belong in decision documents.
- The decision substance ("non-security auto-fires in AFK; security defers") is a user-direction-setting axis on JTBD-006 ("does not trust the agent to make judgement calls"). The original ADR-024 Consequences chose conservative-default for ALL paths in AFK on JTBD-006 grounds (line 137 explicitly cites it). Splitting the consequence into per-classification branches re-litigates JTBD-006's appetite — user-owned decision per ADR-074 + the user-goal preamble for this iter.

### Design decision pending (BLOCKS implementation)

**Question**: Authorize the ADR-024 amendment described in "Fix shape" above? Specifically:

- Reverse the AFK auto-invoke restriction for **non-security** classified tickets (the orchestrator pre-classifies; non-security auto-invokes the report-upstream skill in AFK; security-classified retains marker-defer-to-interactive).
- Re-cite the now-shipped `wr-risk-scorer:external-comms` agent as the dedup-AFK auto-comment authority (lifts the Step 4b interim static heuristic).
- Cross-reference the symmetric P249 Phase 1 inbound discovery pipeline as the bidirectional counterpart.

**If yes**: a single ADR-024 amendment landing covers the orchestrator-side authorization, the dedup-AFK lift, and the inbound-symmetric cross-reference — then SKILL.md + bats land mechanically against the amended ADR.

**If no**: P270 stays Open with the documented over-restriction acknowledged as intentional conservative default; sibling P254 (report-upstream automation blocks) may need its own re-scope to not depend on this fix.

**If amend differently**: user redirects (e.g. "auto-invoke for ALL paths including security in AFK"; "keep current blanket halt + add a separate batch-disclosure path for security per ADR-024 Reassessment Criteria #4(b)"; or some other shape).

## Dependencies

- **Blocks**: any timely upstream-feedback delivery — clamps the JTBD-006 audit-trail "every action taken during AFK mode should be traceable" outcome since the audit-trail tracks an INTENT-to-file, not the actual filing.
- **Blocked by**: (none observed yet — the ADR-024 security-path carve-out may need amendment but the non-security path is unblocked)
- **Composes with**:
  - P063 (closed) — manage-problem appends the `Upstream report pending` marker; this ticket asks the next class
  - P070 (verifying) — report-upstream does not check for existing upstream issues; sibling concern
  - P079 (open) — no inbound sync of upstream-reported problems; user explicitly cited this row
  - P080 (open) — no bidirectional update of upstream-reported problems; sibling
  - P220 (open) — manage-problem has no cadence for checking upstream-bound tickets
  - P249 (verifying) — `/wr-itil:check-upstream-responses` shipped the symmetric us-as-reporter polling shape; this ticket is the proactive-fire counterpart
  - P254 (open) — report-upstream automation blocks clamp agent feedback signal
  - ADR-024 — report-upstream contract; § Consequences security-path branch is interactive constraint
  - ADR-013 Rule 5 — policy-authorised silent proceed (non-security upstream reports are candidate Rule 5 fits)
  - ADR-013 Rule 6 — non-interactive fail-safe (current ADR-024 wording defaults to Rule 6 halt; this ticket asks Rule 5 over Rule 6 for non-security)
  - ADR-044 — framework-resolution boundary (the "should we file?" decision is framework-resolved once root cause is external + non-security)

## Related

(captured via /wr-itil:capture-problem mid-loop — orchestrator main turn while iter 2 P269 was running in background subprocess; user-initiated capture per CLAUDE.md MANDATORY capture-on-correction rule; description shape matches strong-signal direction-setting via user explicit instruction "When the agent detects that the issue is upstream, it should report it ASAP")

- P063 — closed; established `Upstream report pending` marker mechanism
- P070, P079, P080, P220, P249, P254 — sibling cluster on upstream report lifecycle
- ADR-024 — `/wr-itil:report-upstream` contract; Consequences clause names the security-path interactive carve-out
- `packages/itil/skills/work-problems/SKILL.md` Step 4 — current P063 fallback marker append (would gain a non-security auto-fire branch)
- `packages/itil/skills/manage-problem/SKILL.md` Step 6 — external-root-cause detection (would gain a non-security auto-fire branch)
- `packages/itil/skills/report-upstream/SKILL.md` Step 6 — security-path interactive branch (preserved verbatim under this ticket's fix shape)
