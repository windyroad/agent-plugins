# Problem 068: run-retro does not close .verifying.md tickets that have been observed as verified in the session

**Status**: Open
**Reported**: 2026-04-20
**Priority**: 12 (High) — Impact: Moderate (3) x Likelihood: Likely (4)
**Effort**: M — add a "Verification-close housekeeping" step to `packages/retrospective/skills/run-retro/SKILL.md` that scans `docs/problems/*.verifying.md` against the session's observed evidence, calls out which are verified in-session, and transitions them to `.closed.md` (ADR-022 Verification Pending → Closed). Includes bats doc-lint test assertions and cross-reference to `manage-problem` Step 9d.
**WSJF**: 6.0 — (12 × 1.0) / 2 — Mid-priority, High severity; sits alongside P065 in the dev-work queue.

## Description

`/wr-retrospective:run-retro` captures session learnings and recommends codifiable outputs (new skills per P044, other codifiables per P050, improvements per P051) but does **not** perform the housekeeping of closing `.verifying.md` problem tickets whose fixes were observably exercised and confirmed working during the session. The result: Verification Queue accumulates across sessions even when evidence for closure existed.

Concrete instance in this session (2026-04-20):

- `@windyroad/itil@0.8.0` was already released when the session started; `/wr-itil:report-upstream` (P055 Part B) had landed and all 9 contract tests ran successfully (`npx bats packages/itil/skills/report-upstream/test/report-upstream-contract.bats` — 9/9 PASS).
- `docs/problems/055-...verifying.md` was transitioned during the session as the release marker was written.
- No retrospective ran to examine whether any OTHER existing `.verifying.md` tickets had been exercised or confirmed during the work — e.g. P057 (staging trap documented) was actively followed at every transition in this session; P056 (next-ID `--name-only` fix) was used at every ID computation and produced correct output; P035/P015 (risk-scorer delegate pattern) was invoked three times successfully.
- None of these get auto-closed because run-retro has no step for it. The manage-problem review step 9d asks the user directly, but that only fires when the user runs `/wr-itil:manage-problem review` — not organically at session wrap.

The user's feedback memory explicitly states: "When asked which Fix Released tickets to close, verify from my own in-session observations instead of deferring everything to the user" (feedback_verify_from_own_observation.md). run-retro is the natural place for this — it's the session-wrap skill whose whole purpose is to consolidate what happened and surface outputs.

## Symptoms

- Verification Queue grows across sessions (20 `.verifying.md` files at time of report; session work actively exercised several of them).
- `/wr-itil:manage-problem review` step 9d asks the user about each pending verification every time, with no short-cut for "this was exercised successfully in the session that's wrapping".
- `run-retro` outputs session learnings but not verification-close candidates — missing an obvious housekeeping moment.
- Agents defer verification-close to the user even when in-session evidence (test runs, successful governance invocations, successful release cycles, successful hook firings) would support closure.
- The user has had to type "yes, close P-NNN" repeatedly in past sessions instead of the agent proactively noting "these were exercised successfully and are candidates for closure".

## Workaround

User runs `/wr-itil:manage-problem review` at session end, answers each verification prompt by hand, and closes tickets one at a time. Or the user relies on the 14-day "likely verified" highlight from P048 — but that's purely age-based, not evidence-based.

## Impact Assessment

- **Who is affected**:
  - **Solo-developer persona (JTBD-001)** — every session that exercised `.verifying.md` fixes leaves them open. Verification Queue clutter grows. Manual batch-close at session end is the "manually police agent output" pattern the persona is designed against.
  - **Tech-lead persona (JTBD-201)** — audit trail of fix verification is delayed; fixes that worked flawlessly in production sit in Verification Pending for weeks past the moment of verification.
  - **AFK orchestrators** — `/wr-itil:work-problems` AFK loops exercise many `.verifying.md` fixes but never close them; the user wakes to a Verification Queue that was actually cleared weeks ago in practice.
- **Frequency**: Every session that touches code paths covered by `.verifying.md` tickets. Nearly every session.
- **Severity**: High for the ecosystem's audit-trail coherence; Moderate for any single session. The Verification Queue stops being informative when it's full of tickets whose fixes have been shipping smoothly for weeks.
- **Analytics**: Count of `.verifying.md` files at session start vs session end across recent sessions would quantify the drift. Currently: 20 open; likely half have been exercised successfully at least once in the last 30 days.

## Root Cause Analysis

### Structural

`run-retro` was scoped for capturing retrospective learnings (what went well / what went wrong / codifiable outputs) under ADR-018. Closing `.verifying.md` tickets is a **housekeeping** operation, not a retrospective output, and was never scoped into the skill's steps. The closing path lives only in `manage-problem` step 9d, which is user-initiated.

ADR-022 (Verification Pending lifecycle) defines the state but places the close-trigger on "user explicitly confirms". The user's separate feedback memory says to verify from in-session observations — these two sources are consistent but the implementation only follows the first half (explicit confirm path) not the second (in-session observation path).

### Candidate fix

Add a **Verification-close housekeeping** step to `run-retro` that runs between the learnings capture and the output recommendations:

1. Glob `docs/problems/*.verifying.md`.
2. For each file, read the `## Fix Released` section to extract the fix-summary keyword (commit SHA, version, or brief description).
3. Scan the session's activity for evidence:
   - Bats test invocations that touched the fix's test file and returned zero.
   - Successful `git commit` events whose diff covered the fix's source path.
   - Successful skill invocations that rely on the fix (e.g. `manage-problem` using P056's corrected next-ID lookup, `create-adr` using P057's staging fix).
   - Successful hook firings on gate paths the fix established.
   - Successful release cycles (`push:watch` / `release:watch`) that shipped a commit dependent on the fix.
4. For each `.verifying.md` with supporting evidence, categorise:
   - **Exercised successfully in-session (N times)**: the fix was used and did not regress. Present as a close-candidate with the evidence line.
   - **Not exercised in-session**: leave as Verification Pending.
   - **Exercised with regression**: this is a different problem — flag for the user.
5. Use `AskUserQuestion` per ADR-013 Rule 1 to ask the user whether to close the candidates (with the evidence inline — NOT just "P048? yes/no" but "P048: exercised 3 times this session — [trigger points listed]. Close?"). The question surface MUST include the evidence so the user can decide without reading the full ticket.
6. AFK / non-interactive branch: record the evidence in the retro report's "Verification candidates" section for the user to review later. Do NOT auto-close in AFK — keeps the user's explicit-confirm policy per ADR-022, but changes the default from "silent" to "evidence surfaced".
7. For each close confirmed, perform the `.verifying.md` → `.closed.md` transition (per manage-problem Step 7): `git mv`, update Status to Closed, `git add` (P057 staging trap), commit per ADR-014 with message referencing the problem ID.

Alternative shape considered: put the housekeeping in `manage-problem` review step 9d instead of run-retro. Rejected because:

- `manage-problem review` is user-initiated and lacks session-activity context. `run-retro` has the session narrative naturally.
- Running it at retro time means the housekeeping fires at a predictable moment (session wrap), not opportunistically when the user remembers to review.
- `run-retro` already touches `docs/problems/` via the codifiable-outputs steps (P044, P050, P051 introductions); adding a housekeeping step is architecturally consistent.

### Investigation Tasks

- [ ] Add a "Verification-close housekeeping" step to `packages/retrospective/skills/run-retro/SKILL.md` per the candidate fix above.
- [ ] Decide whether the evidence-scanning logic lives inline in SKILL.md (bash / glob heuristics) or delegates to a subagent.
- [ ] Decide AFK vs interactive behaviour per JTBD-006 — confirmed: surface evidence, do not auto-close without user opt-in.
- [ ] Cross-reference with `manage-problem` Step 9d — both should fire, but run-retro is evidence-enriched while manage-problem review is baseline.
- [ ] Add bats doc-lint assertions in `packages/retrospective/skills/run-retro/test/` that the housekeeping step is documented (SKILL.md mentions `.verifying.md` glob, the evidence categories, the AskUserQuestion with evidence-inline requirement, and the ADR-022 transition commit).
- [ ] Update `feedback_verify_from_own_observation.md` memory to note that this is now a run-retro-enforced pattern rather than purely agent discipline.
- [ ] Architect review on whether this belongs in run-retro or warrants a new sibling skill `/wr-itil:verification-close` (or `/wr-retrospective:close-verified`). Lean: run-retro, because session-context is already there.
- [ ] Exercise end-to-end: run run-retro at the end of a session where at least one `.verifying.md` fix was exercised; confirm the evidence appears in the retro report and the close flow fires.

## Related

- **P044** — run-retro does not recommend new skills; sibling retro-enhancement ticket (.verifying.md).
- **P050** — run-retro does not recommend other codifiable outputs; sibling.
- **P051** — run-retro does not recommend improvements to existing codifiables; sibling.
- **P048** — manage-problem does not detect verification candidates; the age-based heuristic. This ticket is the evidence-based counterpart — the two should compose (both feed the verification-close prompt).
- **P049** — Verification Pending lifecycle (ADR-022); the lifecycle this housekeeping walks the ticket through.
- `feedback_verify_from_own_observation.md` (user memory) — user's explicit preference for in-session verification over deferring everything.
- **ADR-018** — retrospective ADR; governs the run-retro contract.
- **ADR-022** — Verification Pending lifecycle; authoritative on the `.verifying.md` → `.closed.md` transition.
- **ADR-013** — structured user interaction; Rule 1 governs the AskUserQuestion with evidence inline.
- **ADR-014** — governance skills commit their own work; the close commit follows the standard ordering.
- `packages/retrospective/skills/run-retro/SKILL.md` — the 174-line skill that this ticket extends.
- **JTBD-001** (Enforce Governance Without Slowing Down) — one-shot housekeeping at session wrap beats manual review sessions.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — audit trail reflects reality when in-session verification lands in the ticket.
