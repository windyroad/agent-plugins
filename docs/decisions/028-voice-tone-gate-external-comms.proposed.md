---
status: "proposed"
date: 2026-04-20
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-07-20
---

# Voice-tone gate on external communications — deny-plus-marker pattern with wr-voice-tone delegation

## Context and Problem Statement

`@windyroad/voice-tone` and `docs/VOICE-AND-TONE.md` govern voice and tone for in-repo text (READMEs, docs, commit messages). There is no gate on text produced for **external** surfaces: GitHub issue comments, PR descriptions, npm README updates, RapidAPI listings, Shopify/marketplace pages. Claude's output on these surfaces defaults to generic "AI voice" — em-dashes, hedging phrases ("it seems", "I'd suggest"), overly-polite closers ("happy to help further"), and context-blind suggestions like "let's keep this ticket open" on years-old issues.

Per the session insights report (1,464 messages across 86 sessions, 2026-03-17 to 2026-04-16), voice-tone drift on external comms is one of three top friction categories. The pattern is: agent drafts an external comment, posts it, user catches the AI-tell, issues a "FFS" correction, agent rewrites and reposts. Every correction is a late-stage cleanup of output that a pre-flight gate should have caught.

P038 is the upstream problem ticket. The user's direction (this session): delegate to `wr-voice-tone:agent` for review and block the tool call on FAIL; intercept `gh issue comment`, `gh pr comment`, `gh pr create`, `gh pr edit`, `gh issue edit`; include an age/context check that flags stale-target-incongruous phrasing when the target issue or PR is older than 180 days (configurable); read the voice profile from `docs/VOICE-AND-TONE.md` (extending its scope to cover external text); advisory-only mode when the profile is absent (graceful fallback per the ADR-008 / ADR-025 pattern).

## Decision Drivers

- **JTBD-001** (Enforce Governance Without Slowing Down) — solo-developer; external-comms AI-voice drift is the "manually police AI output" pain point. A pre-flight gate closes it before the comment posts, not after the "FFS" correction.
- **JTBD-002** (Ship AI-Assisted Code with Confidence) — external surfaces are the public face of the user's work. AI-tell patterns damage brand credibility; catching them at the gate preserves shipping confidence.
- **JTBD-003** (Compose Only the Guardrails I Need) — voice-tone gate is a composable guardrail. Projects adopt it by installing `@windyroad/voice-tone`; other guardrails remain independent.
- **JTBD-006** (AFK) — blocking on FAIL is the correct conservative default per JTBD-006's "does not trust the agent to make judgement calls." AFK loops must not post AI-voice comments to external audiences without user review.
- **JTBD-101** (Extend the Suite with Clear Patterns) — partial fit. Plugin developers whose downstream projects adopt `@windyroad/voice-tone` inherit the gate for their agents' external posts. One gate, many consumers.
- **JTBD-201** (Restore Service Fast with an Audit Trail) — tech-lead; the age-check specifically serves JTBD-201's audit-trail integrity. Context-blind comments on stale issues corrupt the audit surface of an incident's follow-up ticket chain.
- **JTBD-202** (if present — tech-lead pre-flight governance check) — per jtbd-lead advisory; partial fit. Release-notes and handover comms pass through the same gate.
- **P038** — the upstream problem ticket this ADR resolves.

## Considered Options

1. **Deny-plus-marker pattern with wr-voice-tone delegation** (chosen) — PreToolUse hook matches the gated surfaces, denies the tool call with a delegation instruction ("Delegate to wr-voice-tone:agent to review this draft"), agent delegates, agent's review writes a PostToolUse marker per ADR-009, tool call retries and proceeds if the marker is present. This is the existing architect/jtbd/style-guide convention applied to external comms.

2. **Pattern-based PreToolUse hook** — forbidden phrases hard-coded in the hook (em-dash, "happy to help", "it seems"). Simpler but brittle — AI-voice evolves, hard-coded lists drift.

3. **Warn-only (log detection, don't block)** — lowest friction, insufficient per P038.

4. **Direct subagent invocation from the hook** (the original sketch in this session's design questions) — rejected because hooks cannot invoke subagents directly in this repo's architecture per the architect review. Every existing gate (architect-enforce-edit, jtbd-enforce-edit, style-guide-enforce-edit, risk-score-commit-gate) uses the deny-plus-marker pattern.

## Decision Outcome

Chosen option: **Option 1 — deny-plus-marker pattern, delegation to `wr-voice-tone:agent`, `docs/VOICE-AND-TONE.md` as voice-profile source, age-check included.**

Rationale:
- The deny-plus-marker pattern is the ADR-009-aligned convention this repo already uses for every review gate. Inventing a new hook→subagent channel would diverge from established architecture without benefit.
- `wr-voice-tone:agent` already exists for in-repo text review — extending its scope to external text reuses the reviewer's context and avoids a second agent.
- `docs/VOICE-AND-TONE.md` is the single source of truth. Extending its scope to cover external text is a consequence captured here (no separate ADR for the scope change; no separate profile file).
- Advisory-only fallback when `docs/VOICE-AND-TONE.md` is absent matches the ADR-008 (jtbd-directory) and ADR-025 (test-content-quality) graceful-adoption pattern.
- Age-check in the same gate keeps the related concerns together (voice-tone and context-fit both apply to external comms).

### Scope

**In scope (this ADR):**

- **New hook**: `packages/voice-tone/hooks/external-comms-gate.sh` — PreToolUse on Bash.
  - Matches commands via regex:
    - `gh issue comment [...]` (with `--body` or `--body-file`)
    - `gh pr comment [...]` (with `--body` or `--body-file`)
    - `gh pr create [...]` (with `--body` / `--body-file` / `--title`)
    - `gh pr edit [...]` (with `--body` / `--body-file` / `--title`)
    - `gh issue edit [...]` (with `--body` / `--body-file` / `--title`)
  - When matched, extracts the draft text (body, and/or title for create/edit).
  - **Advisory-only mode**: if `docs/VOICE-AND-TONE.md` does not exist in the project, the hook emits a systemMessage advisory ("`docs/VOICE-AND-TONE.md` not found — external voice-tone gate running advisory-only") and permits the tool call. Does not block.
  - **Review-required mode**: if `docs/VOICE-AND-TONE.md` exists:
    - Compute marker key: `sha256(draft_body + target_surface + age_bucket)` where `age_bucket` is the integer floor of `target_age_days / 30` (so bucket drift alone does not invalidate within a session).
    - Check for a valid `external-comms-reviewed-<marker_key>` marker per ADR-009 (TTL + drift).
    - If marker is present and valid: permit the tool call.
    - If marker is absent or expired: deny the tool call with the message: `External comms voice-tone review required. Delegate to wr-voice-tone:agent (subagent_type: 'wr-voice-tone:agent') with the draft body and target (issue/PR URL + age). The agent will review against docs/VOICE-AND-TONE.md, return a verdict, and a PostToolUse marker will unblock this tool call on retry.`

- **New hook**: `packages/voice-tone/hooks/external-comms-mark-reviewed.sh` — PostToolUse on Agent.
  - Fires when `subagent_type == "wr-voice-tone:agent"`.
  - Reads the subagent's verdict file at `/tmp/voice-tone-verdict` (same convention as the existing voice-tone-enforce-edit review, extended to carry the verdict for external comms).
  - If verdict is PASS: write marker `external-comms-reviewed-<marker_key>` with TTL 1800s (overridable via `VOICE_TONE_EXTERNAL_TTL` envvar, following the `ARCHITECT_TTL` pattern from ADR-009).
  - If verdict is FAIL: do NOT write the marker. Agent sees the gate still blocks on retry; must rewrite before re-attempting.

- **Age-check rule** — inside the PreToolUse hook:
  - When the command is `gh issue comment` or `gh pr comment` (target is an existing issue/PR), the hook queries `gh api` for the target's `created_at` and `updated_at` timestamps.
  - `target_age_days = days_since(created_at)`.
  - The draft body is matched against a list of stale-target-incongruous phrases: `keep this open`, `keep this ticket open`, `happy to help further`, `any updates?`, `bumping this`, `still relevant?`, and similar patterns.
  - If any such phrase is present AND `target_age_days > AGE_THRESHOLD` (default 180, overridable via `VOICE_TONE_EXTERNAL_AGE_DAYS` envvar), the gate extends its deny reason to include the age warning: `Target is <N> days old; the phrase "<matched phrase>" is frequently context-blind on stale targets. Consider whether the target is still active before posting, or rewrite without the phrase.`
  - Age-check runs independently of the review-required mode — it fires even if `docs/VOICE-AND-TONE.md` is absent.
  - Age-check caches `gh api` results per-session per-target to avoid repeated round-trips.

- **Extension of `docs/VOICE-AND-TONE.md` scope**: explicitly stated in this ADR's Decision Outcome. The file is now the source of truth for in-repo AND external text. No separate `docs/EXTERNAL-VOICE-AND-TONE.md` file. The `wr-voice-tone:agent` reviewer is extended to handle external-comms context (the draft body + target surface) alongside its existing in-repo review surface.

- **`wr-voice-tone:agent` prompt amendment**: add an "External comms review" section instructing the agent to:
  - Accept draft-body + target-surface context from the caller.
  - Review the draft against `docs/VOICE-AND-TONE.md` with external-audience framing (less jargon, more terse than in-repo docs).
  - Emit a structured verdict per the P037 contract (inline PASS/FAIL + remediation).
  - Write the verdict file `/tmp/voice-tone-verdict` with `PASS` or `FAIL`.

- **Bats doc-lint tests**:
  - `packages/voice-tone/hooks/test/external-comms-gate.bats` — asserts the hook denies on AI-voice fixtures (em-dashes, "happy to help", "it seems"), permits on clean drafts, handles all five gated surfaces, and runs advisory-only when `docs/VOICE-AND-TONE.md` is absent.
  - `packages/voice-tone/hooks/test/external-comms-age-check.bats` — asserts age-check denies when target > 180 days AND phrase matches; permits when target < 180 days OR no phrase matches.
  - `packages/voice-tone/agents/test/voice-tone-external-comms-contract.bats` — asserts the agent prompt contains the external-comms review section and the P037 structured-verdict contract.

**Out of scope (follow-up tickets or future ADRs):**

- Claim accuracy on external comms ("industry-leading", "most popular", etc. without evidence). That's a separate concern owned by the architect agent (ADR-023 principle) and/or jtbd-lead. Per architect advisory.
- `npm publish` README-diff gate. Deferred — requires different integration (publish is not a `gh` command) and a different review target (README diff rather than comment draft). A follow-up ADR can address it.
- RapidAPI, Shopify, marketplace listing surfaces. Deferred — gate is designed to accept new surfaces via additional regex patterns in the hook; no architectural change required for additions.
- Automatic rewrite (gate rewrites the draft rather than blocking). Rejected for now; agent returns remediation guidance, human reviews the rewrite before reposting.

## Consequences

### Good

- External-comms AI-voice drift is caught before posting, not after. JTBD-001's "manually police AI output" pain point closes.
- Gate uses the existing deny-plus-marker pattern; no new hook architecture to reason about.
- Voice profile is a single file (`docs/VOICE-AND-TONE.md`); no drift between in-repo and external voice.
- Advisory-only fallback preserves the graceful-adoption arc for new projects without a voice profile.
- Age-check adds a context-fit layer that pattern-only gates would miss. JTBD-201's audit-trail integrity on stale-target comments is protected.
- Delegation to `wr-voice-tone:agent` reuses the existing reviewer; no new agent to define.

### Neutral

- Every gated tool call incurs at minimum one `gh api` round-trip for the age-check. Bounded: external comms are human-timescale (seconds to minutes per post), so sub-second API latency is imperceptible.
- Per-session, per-target age-check cache keeps the API cost bounded in multi-comment sessions.
- `docs/VOICE-AND-TONE.md` is now load-bearing for external comms too. Changes to the file affect both in-repo and external review surfaces. Acceptable — one source of truth is simpler than two.
- Claim accuracy (e.g. "industry-leading" without evidence) is explicitly NOT in scope of this gate. It's a separate concern owned by the architect/jtbd agents, not voice-tone.

### Bad

- **Gate requires the `wr-voice-tone:agent` to be installed and functional**. If the agent is missing or errors, the gate permanently denies the tool call (fail-closed). Mitigation: the deny message explicitly names the subagent and the required docs file, so the user can diagnose quickly.
- **AFK interaction with voice-tone delegation**: in AFK mode, the gate denies; the subagent is delegated; subagent reviews; marker is written; tool call retries. This adds at least one extra turn per external-comms post. Bounded: external comms during AFK are uncommon (most AFK iterations are code changes, not comments). When they occur (e.g. `wr-itil:report-upstream` posts an upstream issue), the extra turn is acceptable per JTBD-006's "conservative blocking".
- **Age-check false positives**: a legitimate comment on a genuinely-still-active old ticket (e.g. a long-running bug) may contain phrases the age-check flags. The deny reason says "Consider whether the target is still active before posting, or rewrite without the phrase" — the user can choose to rewrite or accept a one-line acknowledgement that overrides the check. No structural override; each case is reviewed.
- **Per-skill coupling** with `wr-itil:report-upstream` (ADR-024): the report-upstream skill posts upstream issues via `gh issue create`, which IS in the gated surface list. Report-upstream's flow must account for the voice-tone gate firing mid-workflow — it will, since the gate is transparent to the skill (report-upstream generates a draft, calls `gh issue create`, gate delegates to voice-tone, report-upstream continues after the marker lands). Worth documenting in ADR-024's Consequences in a follow-up commit.
- **ADR-027 interaction** (governance skill auto-delegation): `wr-voice-tone:agent` is a reviewer agent (read-only, writes only the verdict file), NOT a governance skill. ADR-027's Step-0 delegation pattern does NOT apply to it. The voice-tone review is a hook-triggered delegation, not a user-invoked skill. Called out here to prevent confusion.

## Confirmation

Compliance is verified by:

1. **Source review:**
   - `packages/voice-tone/hooks/external-comms-gate.sh` exists and matches the five gated command patterns.
   - The hook uses the deny-plus-marker convention: it returns `permissionDecision: deny` with the delegation instruction; it does NOT invoke a subagent directly.
   - `packages/voice-tone/hooks/external-comms-mark-reviewed.sh` exists as PostToolUse on Agent with matcher for `wr-voice-tone:agent`, reads `/tmp/voice-tone-verdict`, writes the marker on PASS.
   - Advisory-only mode fires when `docs/VOICE-AND-TONE.md` is absent; emits systemMessage and permits the tool call.
   - Age threshold is read from `VOICE_TONE_EXTERNAL_AGE_DAYS` envvar with a 180-day default, per ADR-009's envvar pattern.
   - TTL is read from `VOICE_TONE_EXTERNAL_TTL` envvar with a 1800s default.

2. **Test (bats):**
   - `packages/voice-tone/hooks/test/external-comms-gate.bats` covers: deny on AI-voice fixtures for each surface, permit on clean drafts, advisory-only when VOICE-AND-TONE.md absent, marker-respected on retry.
   - `packages/voice-tone/hooks/test/external-comms-age-check.bats` covers: deny when target > 180 days AND phrase matches, permit when target < 180 days, permit when no phrase matches regardless of age.
   - `packages/voice-tone/agents/test/voice-tone-external-comms-contract.bats` asserts the agent prompt has the external-comms review section and the P037 structured-verdict contract.
   - `packages/voice-tone/hooks/test/external-comms-marker-lifecycle.bats` asserts ADR-009 marker TTL+drift semantics on the `external-comms-reviewed-*` markers.

3. **ADR-009 compliance**: the marker key is `sha256(draft_body + target_surface + age_bucket)` so that two retries with the same draft hit the same marker; a rewrite produces a different marker and re-triggers review. TTL+drift pattern applied per ADR-009.

4. **Cross-reference confirmation in neighbouring docs**:
   - `packages/voice-tone/agents/agent.md` contains an "External comms review" section citing ADR-028 and the P037 verdict contract.
   - `docs/VOICE-AND-TONE.md` (if present) notes its scope covers both in-repo and external text (advisory note; not a decision, a fact).
   - A follow-up commit updates ADR-024's Consequences to note the voice-tone gate fires on `gh issue create`. Not in this ADR's commit; landed as a one-line ADR-024 edit when `wr-itil:report-upstream` is implemented.

5. **Behavioural replay**:
   - Draft a `gh issue comment --body 'it seems like we should keep this open — happy to help further'` on a 2-year-old issue. Verify: gate denies with voice-tone AND age-check reasons; subagent reviews; user rewrites; gate permits on retry.
   - Draft the same comment with `docs/VOICE-AND-TONE.md` absent. Verify: gate emits advisory, permits the tool call, age-check still fires (age-check is independent of profile presence).

## Pros and Cons of the Options

### Option 1: Deny-plus-marker + wr-voice-tone delegation (chosen)

- Good: aligns with existing hook architecture (ADR-009 + architect/jtbd/style-guide precedents).
- Good: reuses `wr-voice-tone:agent` and `docs/VOICE-AND-TONE.md`; no new agent or profile file.
- Good: advisory-only fallback preserves graceful adoption.
- Good: age-check layered into the same gate.
- Bad: fail-closed when the voice-tone agent is missing or errors; user must diagnose.
- Bad: adds at least one extra turn per external-comms post in AFK mode.

### Option 2: Pattern-based PreToolUse hook (no delegation)

- Good: simplest implementation; no LLM review in the loop.
- Good: fast (no API calls for review).
- Bad: brittle — AI-voice evolves; hard-coded list drifts.
- Bad: misses context-dependent cases (a phrase that's AI-voice in one context is fine in another).

### Option 3: Warn-only (log, don't block)

- Good: lowest friction.
- Bad: P038's failure mode is that "FFS" corrections happen late; warning doesn't change the outcome.

### Option 4: Direct subagent invocation from hook

- Good: minimal round-trips.
- Bad: inconsistent with this repo's established hook→agent pattern (ADR-009 + precedents).
- Bad: may not be feasible per Claude Code's subagent/hook architecture; architect advised against it.

## Reassessment Criteria

Revisit this decision if:

- **False-positive rate on the voice-tone review exceeds ~5%** (measured via rewrites the agent returned that the user then overrode manually as incorrect). Would signal `wr-voice-tone:agent`'s external-comms prompt needs tightening.
- **Age-check loop-stopping in AFK**: if AFK orchestrators hit the age-check deny on a significant fraction of external posts, consider a `VOICE_TONE_AFK_AGE_BYPASS` envvar that relaxes the check with an explicit opt-in.
- **Drift between in-repo and external voice becomes pronounced** — users find the in-repo profile insufficiently tuned for external text. That would trigger either a `docs/VOICE-AND-TONE.md` section for external text specifically or the separate `docs/EXTERNAL-VOICE-AND-TONE.md` option rejected in this ADR.
- **New external-comms surfaces** emerge (Shopify, RapidAPI, marketplace). Routine: add the regex to the hook; extend the bats test; no ADR amendment.
- **Claim-accuracy concerns become a recurring user complaint**. Would trigger a separate ADR on claim-accuracy reviews (separate from voice-tone, owned by architect or jtbd).
- **`wr-voice-tone:agent` prompt drift** — the agent's external-comms review becomes inconsistent with its in-repo review. Would trigger a prompt-amendment commit, not an ADR.
- **Hook→subagent architecture** changes in Claude Code (e.g. hooks gain direct subagent invocation). Would trigger a reconsideration of Option 4 as a simpler mechanism.
- **npm publish README-diff surface** becomes a recurring incident. Would trigger a follow-up ADR extending the gate to publish.

## Related

- **P038** — the upstream problem ticket this ADR resolves.
- **ADR-008** (JTBD directory structure) — precedent for graceful-fallback when the governance doc is absent.
- **ADR-009** (Gate marker lifecycle) — marker TTL+drift pattern used by this gate.
- **ADR-013** (Structured user interaction) — Rule 6 non-interactive fail-safe governs the AFK-no-profile branch.
- **ADR-015** (On-demand assessment skills) — orthogonal; this gate is hook-triggered, not user-invoked.
- **ADR-024** (Cross-project problem-reporting contract) — scope overlap: `report-upstream` posts `gh issue create`, which IS in the gated surfaces. Follow-up commit notes the interaction in ADR-024's Consequences.
- **ADR-025** (Test content quality review) — neighbouring graceful-fallback pattern.
- **ADR-027** (Governance skill auto-delegation) — `wr-voice-tone:agent` is a reviewer agent, NOT a governance skill. ADR-027's Step-0 pattern does NOT apply. Called out here to prevent confusion.
- **JTBD-001**, **JTBD-002**, **JTBD-003**, **JTBD-006**, **JTBD-101**, **JTBD-201**, **JTBD-202** — personas whose needs drive this ADR.
- `packages/voice-tone/hooks/voice-tone-enforce-edit.sh` — existing gate for in-repo text; pattern-precedent for this ADR's external-comms gate.
- `packages/voice-tone/hooks/voice-tone-mark-reviewed.sh` — existing PostToolUse marker writer; pattern-precedent.
- `packages/voice-tone/agents/agent.md` — reviewer agent; extended by this ADR to cover external comms.
- `docs/VOICE-AND-TONE.md` — voice profile source; scope extended to external text by this ADR.
