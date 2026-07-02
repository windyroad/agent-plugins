# Problem 376: Catchup scanner misses the inbound direction; outbound templates carry the same structural defect the P363 rework fixed on the inbound side — cross-direction parity gap

**Status**: Known Error
**Reported**: 2026-06-23
**Priority**: 12 (High) — Impact: 3 × Likelihood: 4 = 12. Rated at review 2026-07-02: catchup outbound-only; retroactive inbound is manual.
**Origin**: internal
**Effort**: M. WSJF = (12 × 1.0) / 2 = 3.0.
**JTBD**: JTBD-001
**Persona**: plugin-developer

## Description

Two cross-direction parity gaps surfaced during the 2026-06-23 retroactive update-upstream catchup session — both stemming from the P363 rework being applied only to the inbound direction:

### Gap 1 — catchup scanner is outbound-only

The catchup scanner `packages/itil/scripts/catchup-scan.sh` (dispatched by the `wr-itil-catchup-scan` PATH shim) walks `.verifying.md` + `.closed.md` tickets that carry a `## Reported Upstream` section (the outbound surface) and emits `CATCHUP P<NNN> <url> state=… transition=…` lines. It does NOT scan for the inbound `**Origin**: inbound-reported (#NN)` field that ADR-076 introduced + the P363 rework (shipped today via `@windyroad/itil@0.51.2`) made dispatchable.

**Witnessed 2026-06-23 catchup session**: scanner emitted 1 outbound candidate (P113 → anthropics/claude-code#52831 — closed-for-inactivity; skipped). The 3 inbound candidates (P220 #63 K→V; P211 #97 V→Closed; P228 #42 V→Closed-state-sync) the maintainer had to identify by hand via:

```bash
grep -lE '^\*\*Origin\*\*:\s*inbound-reported' docs/problems/verifying/*.md docs/problems/closed/*.md
```

Without scanner coverage, the inbound catchup leg is a manual-discovery surface — exactly the toil the catchup mode was designed to eliminate. Each retroactive inbound verdict requires the maintainer to remember the grep, then per-ticket route through `/wr-itil:update-upstream` (the SKILL Step 1 reads the `**Origin**` field cleanly; the gap is in the scanner-driven `--catchup` worklist, not in the per-ticket SKILL contract).

### Gap 2 — outbound templates carry the same structural defect P363 fixed on the inbound side

The outbound templates in `packages/itil/skills/update-upstream/SKILL.md` Step 4 (O→KE / K→V / V→Closed) carry the same shape defect the user identified in the inbound templates earlier today:

- **V→Closed template**: "Thanks for the report — your filing is what got this on the queue" — addressed to the upstream maintainer, but for outbound, **the upstream maintainer didn't file the report; WE did** (we filed to them). The "Thanks for the report" phrasing is reporter-credit prose that fits inbound (reporter thanks maintainer) but is inverted for outbound (we are the reporter; the upstream maintainer is who we are thanking).
- **K→V template**: "Please upgrade and verify when convenient" — addressed to upstream maintainer, but the upstream maintainer doesn't consume our package (they ARE the package author of what we depend on).

**User clarification 2026-06-23 (verbatim)**: *"Outbound would be for when they have provided a fix and we want to either say we are testing it, or tell them if it worked or not (and thank them) or if they requested more information."*

That clarification sharpens outbound update purpose to three reporter-facing-as-downstream-consumer use cases:

- (a) Confirm we're testing a fix they provided
- (b) Tell them if it worked or not, with thanks
- (c) Respond to a request for more information

The current outbound templates capture none of these cleanly. Apply the four P363 rework directives symmetrically to the outbound side:

1. **Drop templates → LLM-generation prompts** (Directive 1 from P363): per-transition prompts the LLM reads at runtime; warm, contextual, drawing from the local ticket's `## Description` + `## Fix Released` + (when applicable) `## Workaround` sections — and from the upstream's own comments to identify whether they're shipping a fix vs requesting info vs already-shipped.
2. **Workaround inclusion (Directive 2 from P363)**: when the upstream pointed us at a workaround in their issue thread, the outbound update should acknowledge "we're using the workaround you suggested while we await the fix" rather than silently adopting it.
3. **Visibility-gated linked-title-and-ID (Directive 3 from P363)**: same anti-leakage shape — PUBLIC upstream repos get title+permalink; PRIVATE/INTERNAL/indeterminate upstreams retain strict ban. Classification tokens / step IDs / agent-internal vocab stay banned regardless.
4. **Provenance credit (Directive 4 from P363)**: when the upstream maintainer (or a commenter on their issue) provided the fix or workaround that we adopted, credit them by `@handle` and confirm the exact details we adopted. Four provenance branches: maintainer-self / maintainer-provided / commenter-provided / both-source.

The cog-a11y when-available chain (the P363 rework's gate-chain change) already covers the outbound surface since it lives in ADR-028's evaluator declaration — the outbound dispatch rides the same gate chain once `@windyroad/cognitive-a11y` ships per P338.

## Symptoms

(deferred to investigation)

## Workaround

For the catchup-scanner gap: the maintainer runs the inbound-direction grep manually after each `--catchup` invocation and routes per-ticket via `/wr-itil:update-upstream <NNN>` (the per-ticket SKILL contract correctly handles inbound via Step 1's dual-direction extraction + I1-I6 leg, even though the scanner doesn't enumerate inbound candidates).

For the outbound-template gap: the maintainer hand-writes the outbound comment freehand, treating the existing template's `<placeholders>` as guidance rather than literal text. Worked example: today's 2026-06-23 P113 catchup was SKIPPED entirely because the templated comment didn't fit (auto-closed-for-inactivity upstream; we are the reporter not the upstream maintainer).

## Impact Assessment

- **Who is affected**: every retroactive catchup session (inbound miss) + every outbound K→V or V→Closed transition (template mismatch).
- **Frequency**: per catchup invocation (one-shot migration tool) for Gap 1; per outbound K→V/V→Closed transition for Gap 2 (rare today — most inbound; outbound shipped manually so far).
- **Severity**: Moderate. Both gaps degrade the JTBD-301 acknowledgement-loop quality on the outbound direction. Catchup-scanner-miss means inbound reporters wait longer for verdicts; outbound-template-mismatch means we either ship cold form-letters to upstream maintainers or skip the update entirely (today's P113 path).
- **Analytics**: (deferred to investigation)

## Root Cause Analysis

### Gap 1 root cause

`packages/itil/scripts/catchup-scan.sh` predates the P363 rework. The scanner was authored against the outbound `## Reported Upstream` surface only because at scanner-author-time, the inbound surface didn't exist (ADR-076's `**Origin**` field shipped later, and the P363 inbound-dispatch leg shipped today in 0.51.2). Cross-direction parity needs to follow the dispatch-side capability.

### Gap 2 root cause

The outbound templates in Step 4 of `update-upstream/SKILL.md` carry the conceptual confusion the user identified earlier today on the inbound side: they were authored as if reporter and maintainer are the same surface. That's true for inbound (plugin-user reports against us; we maintain) but inverted for outbound (we report against an upstream we depend on; they maintain). The user's clarification on 2026-06-23 sharpens the outbound purpose to three concrete reporter-facing-as-downstream-consumer cases that the templates do not capture.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Investigate fix shape: single coordinating ticket vs split into P376-A (scanner) + P376-B (templates) per P016 concern-boundary — **resolved 2026-06-28**: kept ONE ticket; the two gaps share a root cause but split on lifecycle (Gap 1 is clean shippable script code → done this iter; Gap 2 is design-bearing → deferred). The WORK split rides RFC vehicles, not separate tickets.
- [x] Decide whether outbound-template rework warrants its own ADR-024 amendment (likely yes — symmetric to the 2026-06-23 inbound amendment) — **yes**; recorded as a PROPOSED skeleton amendment in ADR-024 (2026-06-28 entry, `human-oversight: unconfirmed`); ratification queued (see Resolution).
- [ ] **(Gap 2 — deferred, design-bearing)** Apply the four P363 rework directives to outbound templates; preserve outbound-specific purpose (test-confirm / report-outcome-with-thanks / respond-to-info-request) per user clarification 2026-06-23 — NOT built; gated on the queued `category: direction` ratification (substance-confirm-before-build, ADR-074).
- [x] Extend `catchup-scan.sh` to walk inbound `**Origin**` field alongside outbound `## Reported Upstream`; emit direction-tagged `CATCHUP P<NNN> inbound-#<NN>` lines; idempotency contract re-checks `## Upstream Lifecycle Updates` for `(inbound)`-tagged entries — **done 2026-06-28** (Gap 1).
- [x] Behavioural bats: scanner produces both outbound + inbound candidate lines on a corpus carrying both surfaces — **done** (`catchup-scan.bats` tests 15–23, incl. the both-surface case).
- [ ] **(Gap 2 / Gap 1 follow-up)** Update `update-upstream/SKILL.md` § Catchup migration mode to reflect dual-direction scope — deferred; the scanner header comment + RFC-028 already document the dual-direction scope, and the SKILL § rewrite is bundled with the Gap 2 outbound-template rework (avoids a second R009 prose-floor cycle on the same SKILL for a doc-only line). Tracked here for the Gap 2 build.

## Fix Strategy

**Resolved into two lifecycle-split deliverables (2026-06-28):**

### Gap 1 — catchup scanner inbound extension — SHIPPED (pending release)

Clean, additive shell-script change to `packages/itil/scripts/catchup-scan.sh` (the `wr-itil-catchup-scan` PATH shim — NOT a `packages/shared` synced canonical, so edited directly). The scanner now walks the inbound surface (`**Origin**: inbound-reported (#NN)`, ADR-076) alongside the existing outbound `## Reported Upstream` surface and emits direction-tagged lines:

```
CATCHUP P<NNN> inbound-<ref> state=<state> transition=<KE->Verifying|Verifying->Closed> direction=inbound
```

- `(inbound)`-tagged-log idempotency (`log_has_inbound_target`) — distinct from the outbound idempotency so a both-direction ticket that posted only its outbound verdict still surfaces the inbound one.
- Non-actionable Origins (`relayed from other projects`) emit no line (symmetric to the no-`## Reported Upstream` silent skip); cross-repo refs (`<repo>#NN`) preserved.
- Outbound line shape + `SUMMARY` format UNCHANGED (backward-compatible).
- Verified against the real corpus: surfaces P211 #97, P228 #42 (two of the three the maintainer hand-grepped 2026-06-23) + 6 others; P220 #63 correctly idempotency-skipped (already carries an `(inbound)` log entry); P327 `relayed from other projects` correctly silent.
- TDD: 9 behavioural bats added (`catchup-scan.bats` tests 15–23), RED-first confirmed, all 23 green. TDD-review verdict: BEHAVIOURAL.
- Trace: wired into **RFC-028** (consume the Origin field) `problems:` array via the ADR-060 I13 existing-vehicle branch (P371) — NOT a new RFC. Changeset: `@windyroad/itil` patch.

### Gap 2 — outbound template symmetric rework — DEFERRED (design-bearing)

The outbound update-upstream templates carry the same defect P363 fixed inbound, inverted in direction. The fix is the four P363 directives applied symmetrically + the user's 2026-06-23 outbound-purpose clarification (test-confirm / report-outcome-with-thanks / respond-to-info-request). This is a ≥2-option decision (template-rework shape; transition-axis vs new outbound-update taxonomy; share generation-prompt infra with the inbound leg or not). Per P357/ADR-066 a PROPOSED skeleton amendment is recorded in ADR-024 (2026-06-28 entry, `human-oversight: unconfirmed`) and a `category: direction` outstanding_question is queued for the next interactive drain. Implementation is gated on that ratification (ADR-074 substance-confirm-before-build) — NOT built this iteration.

**Lifecycle**: ticket → Known Error. Gap 1's fix verifies at the next `@windyroad/itil` release; the ticket stays Known Error tracking Gap 2's remaining (ratification-gated) design work rather than going to Verifying, because Gap 2 is unresolved.

## Dependencies

- **Blocks**: future retroactive catchup invocations that should pick up inbound candidates automatically (today the maintainer hand-greps); future outbound transitions where the templates would post cold form-letters
- **Blocked by**: none — both Gap 1 and Gap 2 can be worked independently
- **Composes with**: P363 (sibling — applies the same rework directives to the symmetric direction); ADR-024 (will likely get a 2026-06-24+ amendment); ADR-028 (the cog-a11y when-available chain extends here too); P338 (cog-a11y gate gating remains a follow-up); ADR-076 (`**Origin**` field this scanner extension would read); P080 (parent — Phase 2 catchup is where these gaps live)

## Related

(captured via /wr-itil:capture-problem during 2026-06-23 retroactive catchup session; expand at next investigation)

- **P363** (`docs/problems/known-error/363-inbound-reported-tickets-never-receive-fix-released-verdict-on-originating-issue.md`) — sibling: same four-directive rework, applied to the inbound direction; this ticket carries the symmetric outbound work. Today's P363 rework (`@windyroad/itil@0.51.2`) shipped the inbound side.
- **P080** (`docs/problems/known-error/080-no-bidirectional-update-of-upstream-reported-problems.md`) — parent: Phase 2 catchup is the surface both Gap 1 and Gap 2 live within. P080 Phase 2 reopened on 2026-06-17 user direction; this ticket extends Phase 2's scope to cover the cross-direction parity gap.
- **ADR-024** (`docs/decisions/024-cross-project-problem-reporting-contract.proposed.md`) — primary contract; the 2026-06-23 amendment captures the inbound directives; an outbound amendment will follow as part of the fix
- **ADR-028** (`docs/decisions/028-voice-tone-gate-external-comms.proposed.md`) — cog-a11y when-available chain declaration; covers outbound surface once `@windyroad/cognitive-a11y` ships
- **ADR-076** (`docs/decisions/076-inbound-reported-problems-rank-ahead-via-sort-tier.proposed.md`) — `**Origin**: inbound-reported (#NN)` field the scanner extension would read
- **ADR-049** / **ADR-080** (PATH shim grammar + highest-version-wins) — scanner extension preserves the `wr-itil-catchup-scan` shim contract
- **P229** (anti-leakage discipline) + **P350** (brief-before-ID; opaque IDs in user-facing prose) — both inform the visibility-gated linked-title approach
- **P338** (`@windyroad/cognitive-a11y` plugin; ships the cog-a11y evaluator) — Reassessment trigger: when P338 closes, wire cog-a11y into both inbound + outbound chains
- **2026-06-23 catchup session witness**: the live exercise that surfaced both gaps; commit history carries the per-ticket invocations (P220 → comment 4775050591; P211 → comment 4775056130 + close; P228 → close-only idempotency match)

## Change Log

- **2026-06-28** — Open → Known Error during an AFK `/wr-itil:work-problems` iteration. **Gap 1 shipped** (catchup-scan.sh inbound-direction extension + 9 behavioural bats, all green; wired into RFC-028 via the I13 existing-vehicle branch; `@windyroad/itil` patch changeset authored, clean — functional script code, R009 prose-floor N/A). **Gap 2 deferred** (design-bearing outbound-template rework): PROPOSED skeleton amendment recorded in ADR-024 (`human-oversight: unconfirmed`); `category: direction` ratification queued. Architect + JTBD + TDD-review + external-comms (risk) + voice-tone gates all PASS. Ticket stays Known Error tracking Gap 2; Gap 1 verifies at next release.
- **2026-06-23** — Opened during the retroactive `/wr-itil:update-upstream --catchup` session per user-confirmed scope. The catchup invocation surfaced both gaps as direct observations: (a) scanner emitted only the outbound P113 candidate while 3 inbound candidates needed manual identification + per-ticket routing; (b) the outbound P113 catchup was skipped entirely because the templates didn't fit the reality (closed-for-inactivity upstream + we-are-the-reporter shape). Captured per CLAUDE.md P078 capture-on-correction discipline. Two-concern observation (scanner + templates) recorded as one ticket with the P016 concern-boundary split decision deferred to investigation (the two concerns share the same root cause: P363 rework was applied only to one direction).

## RFCs

| RFC | Status | Title |
|-----|--------|-------|
| RFC-028 | proposed | Consume the `**Origin**` field for inbound-reported fix-released verdict |
