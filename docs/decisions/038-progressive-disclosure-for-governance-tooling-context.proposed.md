---
status: "proposed"
date: 2026-04-22
decision-makers: [tomhoward]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, windyroad-claude-plugin adopters]
reassessment-date: 2026-07-22
---

# Progressive disclosure + once-per-session budget for UserPromptSubmit governance prose

## Context and Problem Statement

Five windyroad plugins register `UserPromptSubmit` hooks that emit full MANDATORY instruction blocks on every user prompt:

| Plugin | Hook | Emitted bytes per prompt |
|--------|------|-------------------------:|
| `wr-architect` | `architect-detect.sh` | 1701 |
| `wr-jtbd` | `jtbd-eval.sh` | 881 |
| `wr-tdd` | `tdd-inject.sh` | ~1600 (dynamic) |
| `wr-style-guide` | `style-guide-eval.sh` | ~860 |
| `wr-voice-tone` | `voice-tone-eval.sh` | ~820 |

In a project with three active hooks (this repo: architect + jtbd + tdd), per-prompt aggregate is ~4.2KB; with all five active, ~5.9KB. Over a 30-turn session: **~125–175KB / ~30–40k tokens of pure hook preamble**, most bytes byte-identical to the prior turn. Tracked as **P095** (UserPromptSubmit hooks across five windyroad plugins re-emit full MANDATORY prose on every prompt; Known Error 2026-04-22). Parent meta ticket **P091** (Session-wide context budget from the windyroad plugin stack; Open, XL).

The scripts' *detection* (is `docs/decisions/` / `docs/jtbd/` / test script / `docs/STYLE-GUIDE.md` / `docs/VOICE-AND-TONE.md` present?) is correctly per-prompt — the project state can change mid-session. The scripts' *instruction prose* has no such need: once emitted, the assistant carries it in the conversation context. Re-emitting the same 1000-byte MANDATORY block on every turn is pure repetition.

The unifying design flaw (per P091 meta): every affected surface emits all available context up-front, on every firing, with no affordance for the consumer to decide what to expand. The fix pattern, per user direction 2026-04-22, is **progressive disclosure** — less info upfront with explicit affordances (agent pointers, file paths, consult turn-1) so the consumer retrieves deeper context on demand rather than having it re-injected.

This ADR is the first application of the progressive-disclosure pattern, anchored on P091, covering the UserPromptSubmit cluster. Sibling ADRs (or extensions of this one) will cover `PreToolUse`/`PostToolUse` hooks (P096) and `SKILL.md` runtime size (P097) when those children's audits land.

## Decision Drivers

- **JTBD-001 — Enforce Governance Without Slowing Down**: the job statement explicitly names "without the overhead." 30–40k tokens per 30-turn session is exactly the overhead the job is written against. Enforcement (the `PreToolUse` gate) remains unchanged; only the reminder prose compresses.
- **JTBD-003 — Compose Only the Guardrails I Need**: job statement says "my session isn't cluttered with hooks that don't apply to my project." Repeated full-prose emission of the same three MANDATORY blocks every turn is exactly the cluttering experience this job is written against.
- **JTBD-006 — Progress the Backlog While I'm Away**: AFK loops hit context limits faster with per-turn bloat. ~30k tokens reclaimed = a meaningfully longer safe-loop duration. JTBD-004 ("Messages arrive with zero idle token cost") is the documented precedent that token economy is a first-class JTBD concern.
- **ADR-009 gate marker lifecycle** is the TTL+drift primitive this ADR extends to a new semantic class (announcement markers, distinct from clearance markers).
- **ADR-017 shared code sync pattern** governs distribution: each plugin must install from the marketplace without sibling packages present, so the helper is duplicated and sync-checked rather than re-exported.
- **ADR-023 performance review scope** requires runtime-path changes to quantify per-request cost and aggregate load delta; this ADR encodes a per-prompt byte budget so the budget is discoverable by ADR-023's `performance-budget-*` glob.
- **ADR-028** voice-tone + risk-scorer external-comms gate is the canonical precedent for cross-plugin shared hook distribution; this ADR follows the same canonical+sync shape.
- **P095** is the Known Error this ADR's implementation closes (transitions to Verification Pending).

## Considered Options

1. **Once-per-session gating + terse reminder (chosen)** — first prompt of a session emits the full MANDATORY block and writes `/tmp/<system>-announced-<session_id>`. Subsequent prompts detect the marker and emit a ~100–150 byte terse reminder that names the gate + the delegation agent + the trigger artifact. Detection (scope check) still runs per-prompt.
2. **Complete removal of UserPromptSubmit prose** — delete the MANDATORY blocks entirely; policy lives only in the delegated agent's prompt. Rejected: the hook is the surface where Claude first learns the gate is active; silencing it means governance-enabled projects look identical to ungoverned ones until an Edit is attempted, and the delegation reflex weakens without the per-turn reminder.
3. **Cross-plugin consolidation** — replace five separate hooks with one shared hook that emits a single combined block (`Governance gates active: architect, jtbd, tdd`). Rejected for now: coordination cost across five plugins is high, per-gate context (SCOPE rules differ per plugin) is lost on the consolidated line, and ADR-002 "installable independently" would require advisory-only partial-coverage modes that recreate the per-plugin hook anyway. Revisit if a sixth plugin joins the cluster.
4. **Prose trimming without session gating** — shrink each MANDATORY block to ~200 bytes by moving most content out; emit that smaller block per prompt. Rejected: ~200 bytes × 5 hooks × 30 turns = ~30KB still, versus ~4.5KB with once-per-session gating; the gating is where the savings live. Trimming is a companion axis, not an alternative.
5. **Shorter TTL instead of once-per-session** — emit full block on first prompt and at TTL expiry (e.g. every 30 min). Rejected: no drift signal triggers re-emission; policy changes during a session already go through the PreToolUse gate; TTL adds complexity without reducing budget meaningfully within a typical 60-minute session.

## Decision Outcome

**Chosen option: Option 1** — once-per-session gating + terse reminder, distributed via the ADR-017 / ADR-028 canonical+sync shape.

### Scope

**Canonical shared helper:** `packages/shared/hooks/lib/session-marker.sh` — authoritative source. Exports `has_announced "$SYSTEM" "$SESSION_ID"` (returns 0 if marker exists) and `mark_announced "$SYSTEM" "$SESSION_ID"` (writes marker). Empty-SESSION_ID fallback: `has_announced` returns 1 (not announced) and `mark_announced` is a no-op. No crash, no stray `/tmp/<system>-announced-` (empty suffix) files.

**Per-plugin synced copies:** byte-identical copies at `packages/<plugin>/hooks/lib/session-marker.sh` for each of `architect`, `jtbd`, `tdd`, `style-guide`, `voice-tone`. Synced via `scripts/sync-session-marker.sh` (with `--check` mode for CI). Drift bats test at `packages/shared/test/sync-session-marker.bats`. CI step `npm run check:session-marker` fails the build on drift.

Consumer hooks `source` the **local** copy (`source "$SCRIPT_DIR/lib/session-marker.sh"`), not the shared one, preserving ADR-017's self-contained-published-package invariant.

**Marker path convention:** `/tmp/${SYSTEM}-announced-${SESSION_ID}`. The `-announced-` suffix distinguishes announcement markers from the `-reviewed-` clearance markers used by `packages/style-guide/hooks/lib/review-gate.sh` and `packages/voice-tone/hooks/lib/review-gate.sh`. No collision risk.

**Marker lifecycle — no TTL, no drift check:** announcement markers persist for the Claude Code session's lifetime (SESSION_ID is unique per session; `/tmp` clears on reboot). Unlike review-gate.sh (which uses TTL+drift because the review is the enforcement), the announcement marker is bookkeeping for prose verbosity. The `PreToolUse` edit gate remains the enforcement surface regardless of announcement state; the delegated agent re-reads policy when it runs. Policy changes mid-session do not require re-announcing — the delegation reflex triggered by the `PreToolUse` gate already ensures the policy is consulted.

**Per-prompt byte budget:** each hook's subsequent-prompt reminder MUST be ≤150 bytes. The budget is discoverable to ADR-023's performance review by the presence of "budget" in this ADR's title. Reassessment Criteria below names the trigger to revisit the budget.

**Terse reminder shape** (MUST satisfy all four):
1. Imperative signal word — `MANDATORY`, `REQUIRED`, or `NON-OPTIONAL`. Keeps the enforcement signal strength matched to the first-turn prose. Per JTBD review condition 1.
2. Gate name — so a multi-gate project can see which specific gate is active. Example: `architecture gate`, `JTBD gate`, `TDD gate`, `style-guide gate`, `voice-and-tone gate`.
3. Trigger artifact — the file/directory whose presence activates the gate. Example: `docs/decisions/ present`, `docs/jtbd/ present`, `test script present`. Per JTBD review condition 2.
4. Delegation affordance — the specific agent to delegate to. Example: `Delegate to wr-architect:agent before editing project files.` Consumer can expand via Agent tool on demand.

Optional: pointer to turn-1 instructions for full scope (`See turn-1 instructions for full scope and exclusions.`). Keeps the reminder self-contained (explicit affordance for the consumer to re-read the deeper context if needed).

**`tdd-inject.sh` carve-out (explicit rule):** the once-per-session rule applies to **static policy prose** (INSTRUCTION headers, STATE RULES tables, WORKFLOW lists, IMPORTANT blocks, SCOPE exclusions). **Dynamic per-prompt content** — current TDD state (IDLE/RED/GREEN/BLOCKED), tracked test files list, runtime detection results — is emitted on every prompt irrespective of announcement state. The subsequent-prompt reminder for `tdd-inject.sh` still carries the current state line so state transitions across turns remain visible. This rule generalises: if a future UserPromptSubmit hook has dynamic state (risk scores, test counts, lint counts), that state emits per-prompt; only the static policy prose is gated.

**Scope for absent-trigger branches (unchanged by this ADR):** when the trigger artifact is absent (no `docs/decisions/`, no `docs/jtbd/README.md`, no test script, no `docs/STYLE-GUIDE.md`, no `docs/VOICE-AND-TONE.md`), each hook's existing "no detection" NOTE block is emitted unchanged. The once-per-session rule applies only to the detected-and-active branch.

**Out of scope (follow-up tickets or future ADRs):**

- `PreToolUse` / `PostToolUse` hook prose volume (P096) — audit pending; the shared `session-marker.sh` helper is reused when Phase 2 of P096 lands, but additional patterns (once-per-file, gate-pass-silent) are expected and will be codified in a sibling ADR or a Section extension here.
- `SKILL.md` runtime size (P097) — a different cluster; progressive disclosure applied to skill bodies (runtime-steps vs reference-material split) needs its own design decision.
- Cross-plugin consolidation (Option 3) — revisit if a sixth UserPromptSubmit hook joins the cluster.

## Consequences

### Good

- Per 30-turn session in a 3-active-hook project: ~120KB / ~30k tokens reclaimed (first-turn full block ~4.2KB; subsequent 29 turns × 3 hooks × ~130 bytes = ~11KB; total ~15KB vs ~125KB today).
- JTBD-001 "enforce governance without overhead" and JTBD-003 "session isn't cluttered" both served.
- JTBD-006 AFK-loop-lifetime increased by the reclaimed budget.
- Enforcement contract (PreToolUse gate) unchanged; no governance weakening.
- ADR-017-compliant distribution; each plugin stays self-contained per ADR-002.
- ADR-009 TTL+marker primitive cleanly extended to an announcement-marker semantic class.
- Unit + drift + per-hook behavioural bats tests codify the contract.

### Neutral

- Canonical+sync adds one CI drift-check step (sub-second latency).
- Five hook scripts gain ~10 lines of gating logic each.
- Two verdict patterns now coexist on `/tmp`: `-reviewed-` (clearance markers, TTL+drift per ADR-009) and `-announced-` (this ADR, no-TTL no-drift). Distinct suffixes; no collision; lifecycle differences documented.
- The terse reminders are consumed by the LLM; the exact wording matters for delegation-reflex calibration. If the reminder proves insufficient to trigger delegation in practice, revisit per Reassessment Criteria.

### Bad

- **Risk of delegation-reflex softening**: if the terse reminder fails to trigger delegation as reliably as the full block, governance enforcement slips between first-turn and PreToolUse-gate-fire. Mitigated by: keeping the imperative signal word; PreToolUse gate remains fail-closed; this outcome is one of the Reassessment triggers.
- **Two copies of marker-file convention** (`-reviewed-` vs `-announced-`) may confuse future contributors reading `/tmp`. Mitigation: the canonical helper's docstring names the distinction; file naming itself is self-describing.
- **Byte-budget enforcement is honour-system**: no runtime check fails a hook whose reminder exceeds 150 bytes. Mitigation: bats tests assert `[ "${#output}" -lt 250 ]` for the subsequent-prompt path in each hook, catching drift before it lands. 250 is a testability slack over the 150-byte policy budget.
- **Session-marker scope is plugin-internal**: the markers live in `/tmp` and survive across multiple Claude Code processes that share the same SESSION_ID. Unlikely in practice (SESSION_ID is per-session) but documented here as a known property.

## Confirmation

Compliance is verified by:

1. **Source review:**
   - `packages/shared/hooks/lib/session-marker.sh` exists and exports `has_announced` + `mark_announced`.
   - Five byte-identical copies exist at `packages/<plugin>/hooks/lib/session-marker.sh` for each of architect, jtbd, tdd, style-guide, voice-tone.
   - Each of the five UserPromptSubmit hooks sources its local `session-marker.sh`, parses `session_id` from stdin via `jq`, and gates its MANDATORY block behind `has_announced`.
   - `tdd-inject.sh` emits dynamic state on every prompt regardless of announcement state; only static prose is gated.
2. **Sync infrastructure:**
   - `scripts/sync-session-marker.sh` exists and is executable; supports `--check` mode.
   - `package.json` has `sync:session-marker` and `check:session-marker` npm scripts.
   - `.github/workflows/ci.yml` has a `Check session-marker.sh copies in sync` step.
3. **Tests (bats):**
   - `packages/shared/test/session-marker.bats` — 9 unit tests for the helper (green).
   - `packages/shared/test/sync-session-marker.bats` — 6 drift tests (green).
   - `packages/architect/hooks/test/architect-detect-once-per-session.bats` — 8 behavioural tests (green).
   - `packages/jtbd/hooks/test/jtbd-eval-once-per-session.bats` — 8 behavioural tests (green).
   - `packages/tdd/hooks/test/tdd-inject-once-per-session.bats` — 8 behavioural tests (green), including the dynamic-state carve-out assertion.
   - `packages/style-guide/hooks/test/style-guide-eval-once-per-session.bats` — 7 behavioural tests (green).
   - `packages/voice-tone/hooks/test/voice-tone-eval-once-per-session.bats` — 7 behavioural tests (green).
4. **Performance budget (ADR-023):**
   - Subsequent-prompt reminder byte budget ≤150 per hook; bats tests assert ≤250 as testability slack.
5. **ADR-022 transition:** P095 transitions from `.known-error.md` to `.verifying.md` in the implementation commit; `## Fix Released` section records the release marker.
6. **Behavioural replay (end-to-end):**
   - Fresh Claude Code session in this repo: first prompt emits full MANDATORY blocks for architect + jtbd + tdd (~4.2KB aggregate); second prompt emits terse reminders (~400 bytes aggregate). Tokens reclaimed: ~900 per turn after turn 1.
   - AFK orchestrator 30-iteration run: aggregate hook preamble drops from ~125KB to ~15KB per session.

## Pros and Cons of the Options

### Option 1 — Once-per-session gating + terse reminder (chosen)

- Good: largest byte reclamation (~90% of current hook preamble).
- Good: preserves detection and enforcement semantics unchanged.
- Good: clean ADR-017 / ADR-028 distribution fit.
- Bad: terse-reminder wording is load-bearing for delegation reflex; honour-system byte budget.

### Option 2 — Complete removal of UserPromptSubmit prose

- Good: maximal reclamation — 100% of hook preamble gone.
- Bad: governance-enabled projects look identical to ungoverned ones until a PreToolUse fire; delegation reflex weakens without the per-turn reminder. Rejected.

### Option 3 — Cross-plugin consolidation

- Good: one emission point for all governance reminders.
- Bad: breaks ADR-002 "installable independently" without partial-coverage fallbacks that recreate per-plugin hooks. Coordination cost high. Revisit if ≥6 hooks in cluster.

### Option 4 — Prose trimming without session gating

- Good: easier to implement; no session-marker plumbing.
- Bad: per-turn cost still ~30KB per 30-turn session at 200 bytes × 5 hooks × 30 turns. Insufficient reclamation. Trimming is a companion axis, not an alternative.

### Option 5 — Shorter TTL instead of once-per-session

- Good: small cost drip alongside the session-marker benefits.
- Bad: TTL adds complexity; no drift signal in the announcement domain; limited additional reclamation within typical 60-minute sessions.

## Reassessment Criteria

Revisit this decision if:

- **Delegation reflex softens measurably**: users report that subsequent-turn terse reminders fail to trigger delegation reliably (e.g. the assistant attempts an Edit without consulting `wr-architect:agent` despite the terse reminder). Tighten reminder wording, re-add a fragment of the full block, or revisit the budget.
- **A sixth UserPromptSubmit hook joins the cluster**: extends the per-plugin overhead linearly; Option 3 (consolidation) becomes more attractive.
- **Budget proves too loose or too tight**: if reminders drift above 150 bytes without carrying meaningful context, tighten the budget or revisit the shape. If reminders at 150 bytes are insufficient to carry the four required elements (imperative / gate name / trigger artifact / delegation affordance), relax upward.
- **/tmp marker-path conflicts with another system's convention**: relocate to `${CLAUDE_STATE_DIR:-/tmp}/...` or similar.
- **SESSION_ID semantics change in Claude Code**: if SESSION_ID starts colliding across sessions, add a TTL fallback or switch marker location to a per-session directory.
- **ADR-017 distribution scope changes** (e.g. workspace-linking replaces duplicate-and-sync): this ADR's distribution clause follows ADR-017.
- **`tdd-inject.sh` dynamic-state carve-out fails in practice** (e.g. the STATE line without the STATE RULES table is insufficient for the assistant to act correctly on state transitions): revisit the carve-out boundary.
- **P096 (PreToolUse/PostToolUse) audit lands** and reveals a need to extend the budget, the reminder shape, or the marker convention across the per-tool surface: extend this ADR or author a sibling.
- **P097 (SKILL.md runtime size) audit lands** and the progressive-disclosure pattern needs a distinct codification for skill bodies: author a sibling ADR referencing this one.

## Related

- **P091** (Session-wide context budget from the windyroad plugin stack — meta) — parent meta ticket.
- **P095** (UserPromptSubmit hook injection cluster — Known Error → Verification Pending on commit that lands this ADR) — the driver ticket.
- **P096** (PreToolUse/PostToolUse hook injection cluster — Open) — sibling; this ADR's pattern extends here when its audit lands.
- **P097** (SKILL.md runtime size cluster — Open) — sibling; progressive disclosure applied to skill bodies.
- **P098** (Project-owned and user-owned context contributors — Open) — sibling; progressive disclosure applied to `~/CLAUDE.md` and project-level CLAUDE.md patterns.
- **JTBD-001** — enforce governance without overhead (solo-developer).
- **JTBD-003** — compose only the guardrails I need (solo-developer).
- **JTBD-006** — progress the backlog while I'm away (solo-developer); AFK loop lifetime benefit.
- **JTBD-101** — extend the suite with clear patterns (plugin-developer); this ADR is the documented pattern for future UserPromptSubmit hooks.
- **ADR-002** — monorepo per-plugin packages; installable-independently invariant.
- **ADR-008** — JTBD directory structure.
- **ADR-009** — gate marker lifecycle (TTL + drift); primitive this ADR extends.
- **ADR-014** — governance skills commit their own work; implementation + ADR land in one commit.
- **ADR-015** — on-demand assessment skills.
- **ADR-017** — shared code sync pattern; distribution model for `session-marker.sh`.
- **ADR-022** — problem lifecycle Verification Pending; P095 transition.
- **ADR-023** — performance review scope; per-prompt byte budget is discoverable here.
- **ADR-028** — voice-tone + risk-scorer external-comms gate; canonical+sync precedent for cross-plugin shared hook distribution.
- **ADR-037** — skill testing strategy (bats-contract); behavioural test shape this ADR adopts.
- `packages/shared/hooks/lib/session-marker.sh` — canonical helper.
- `packages/*/hooks/lib/session-marker.sh` — per-plugin synced copies.
- `scripts/sync-session-marker.sh` — sync script.
- `packages/style-guide/hooks/lib/review-gate.sh` — reference for the marker-path convention (`-reviewed-` sibling pattern).
- `packages/itil/hooks/lib/session-id.sh` (P124) — agent-side READ helper that consumes the announce markers this ADR's hooks WRITE; sources the same `/tmp/${SYSTEM}-announced-${SESSION_ID}` filename convention, exits non-zero when no marker is discoverable. Itil-local rather than `packages/shared/` because today only `/wr-itil:manage-problem` Step 2 substep 7 needs agent-side SID discovery; promote to shared per ADR-017 when a second skill adopts the pattern.
