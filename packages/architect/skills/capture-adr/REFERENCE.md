# `/wr-architect:capture-adr` Reference

This file hosts the rationale, edge cases, contract trade-offs, and ADR cross-references for the `/wr-architect:capture-adr` skill. SKILL.md is the runtime contract (~190 lines, on-topic per ADR-038 progressive disclosure); this REFERENCE.md is the on-demand expansion for maintainers and curious users.

## Why a separate skill?

The `/wr-architect:create-adr` flow is ~10-15 turns of agent work for a full new-ADR intake: Step 1 discovery, Step 2 AskUserQuestion gathering (Title + Options ≥2 + Pros/Cons + Decision-makers + Consequences), Step 2b decision-boundary AskUserQuestion, Step 3 next-ID, Step 4 file write with full frontmatter + body, Step 5 confirm-with-user AskUserQuestion review pass, optional Step 6 supersession handling.

That cost is correct for the canonical new-ADR path — the user wants to walk the flow, see the option-comparison prompts, and codify the full MADR shape immediately.

It is wrong for the **aside-invocation** use case. P156 surfaced three repeating patterns where the heavyweight cost is load-bearing friction:

1. **Mid-AFK-iter design decisions**: agent or user lands on a design choice during a foreground iter (e.g. iter 17 P137 Option C namespace-prefix; iter 19 ADR-056 Phase 2a back-channel write contract). The 10-15 turn ceremony breaks iter cadence — decisions get buried inline in commit bodies or RCA sections.
2. **Architect-review verdict capture**: a `wr-architect:agent` review yields a substantive verdict (PASS-WITH-NOTES / ISSUES-FOUND) whose rationale deserves an ADR-shaped record. Today the verdict + rationale lands in commit messages and rots — future readers grep history but lose the structured trace.
3. **User-driven design conversations**: user resolves options (a)/(b)/(c) during conversational work; the settlement currently lives in a problem-ticket RCA section instead of a discoverable ADR.

`/wr-architect:capture-adr` is the source-side fix: a lightweight skill that captures the decision in ~5-6 turns with full derived substance. "Lightweight" means zero-interaction + single-commit — not skimpy content.

## Derived-substance amendment (RFC-045 / P375, 2026-07-06)

The skill originally shipped (P156, 2026-05-03) with a **deferred-placeholder pattern**: every section the capture didn't fill carried the literal pointer string `(deferred to /wr-architect:create-adr canonical review)`, on the theory that a later canonical-expansion pass would fill them. That pattern failed the P375 rot test — a named re-entry point is not a self-firing cadence; nothing ever triggered the canonical review, the anticipated auto-detect-and-expand tooling was never built, and the sections rotted. User direction 2026-07-05: "It should capture it properly."

The amended contract (ADR-032 derived-substance amendment; same correction class as ADR-067's silent derivation of capture-problem ratings): **every MADR section is derived for real at capture time** — genuine Decision Drivers, ≥2 real Considered Options (chosen + actually-rejected alternatives), real Good/Neutral/Bad Consequences, testable Confirmation criteria, real Reassessment Criteria, derived decision-makers. No placeholder, pointer, or sentinel strings of any kind. The capturing agent has more decision context in-session than any later pass would; capture is the cheapest moment to write the substance down.

The derived substance is provisional. `human-oversight: unconfirmed` states that honestly, and the SessionStart oversight nudge → `/wr-architect:review-decisions` drain is the **self-firing** surface where a human ratifies or amends it (ADR-066). That is the only deferral the skill retains.

The architect Q-verdict subsections below record the original P156 trade-off analysis for history; where they describe placeholder/sentinel mechanics they are superseded by this amendment.

## Contract trade-offs

### Skeleton-MADR validity at status `proposed`

Architect Q1 verdict (P156 review, superseded 2026-07-06): the review prompt tolerates not-yet-accepted ADRs at `status: proposed` — it checks "does the proposed change conflict with the decision's outcome?". Under the derived-substance amendment the MADR ≥2-options requirement is satisfied at capture (real options are derived), so there is no skeleton state to cover; `status: proposed` now signals only "derived substance awaiting human ratification + acceptance review".

### Considered Options — real alternatives, derived

Architect Q2 verdict (P156, superseded 2026-07-06): the original numbered-placeholder sibling (`2. (deferred — see ...)`) existed only to satisfy ≥2-options lint. Under the derived-substance amendment the capture writes the chosen option PLUS every alternative actually weighed and rejected in the decision context — real options with one-line summaries. If the context genuinely weighed only one option, the capture derives the strongest status-quo/do-nothing alternative and says why it lost. Lint is satisfied by substance, not by a placeholder. Still no AskUserQuestion.

### Frontmatter sentinel values vs. truly minimal

Architect Q5 verdict (P156, superseded 2026-07-06): the original sentinel `decision-makers: [unspecified — fill at canonical review]` was another deferral marker. Under the derived-substance amendment frontmatter is derived: `decision-makers: [<git config user.name>]` plus any decision-owner named in `$ARGUMENTS`; `consulted`/`informed` from context or `[]`. `reassessment-date` defaults to 3 months from today (matches `create-adr` Step 4); the Reassessment Criteria body section carries real reopen conditions derived at capture.

### Deferred-ratification contract (was: deferred-canonical-expansion)

Capture-adr skips the interactive confirm-with-user pass that `/wr-architect:create-adr` Step 5 performs. The trade-off under the derived-substance amendment:

| Surface | Inline intake (create-adr) | Capture (capture-adr) |
|---------|----------------------------|------------------------|
| Section substance at write-time | User-authored via AskUserQuestion | Agent-derived from decision context |
| Human ratification | Step 5 confirm pass, same session | `/wr-architect:review-decisions` drain, next interactive session |
| Ratification trigger | In-flow | Self-firing SessionStart oversight nudge (`human-oversight: unconfirmed`) |
| Capture-time turn cost | ~10-15 turns | ~5-6 turns |
| MADR conformance at write-time | Full | Full (derived) |
| Audit trail (commit) | One commit covers full ADR | One commit covers full derived ADR |

The contract passes the P375 rot test because the ratification path starts from a self-firing trigger (the SessionStart nudge), not a named on-demand skill. The pre-amendment version failed that test: expansion depended on someone remembering to run `/wr-architect:create-adr <NNN>`, and nothing ever fired it.

### No AskUserQuestion at all

Architect Q4 + JTBD review confirmed: capture-adr is a **mechanical-stage skill** per ADR-044's framework-resolution boundary. Every potentially-interactive decision is framework-mediated:

- **Considered Options**: silent derivation of chosen + actually-rejected alternatives (≥2 real options at capture).
- **Decision Drivers / Consequences / Confirmation**: silent derivation of real content from the decision context.
- **Reassessment date**: framework-policy default 3 months from today; criteria derived.
- **Decision-makers / consulted / informed**: derived from git `user.name` + context — never a sentinel.
- **Multi-decision split**: out of scope. The user invoking capture-adr with a multi-decision payload gets one ADR with the full payload; they re-route to `/wr-architect:create-adr` for the structured Step 2b decision-boundary split.

This mirrors the mechanical-stage carve-out pattern documented in CLAUDE.md (P132 / inverse-P078 trap): when a SKILL contract names a stage as mechanical, do not ask. Per-action consent gates re-ask decisions the user already made and silently undo the load-bearing UX investment.

## Edge cases

### Empty `$ARGUMENTS`

Halt-with-stderr-directive. capture-adr requires Title + 1-line Context + 1-line Decision; without payload there is nothing to capture. The directive points the user to `/wr-architect:create-adr`, which has Step 2 AskUserQuestion gathering for full intake.

AFK orchestrators MUST NOT invoke capture-adr with empty arguments — caller-side contract. The Rule 6 audit makes this explicit so AFK-iter writers don't accidentally introduce a halt mid-loop.

### Partial `$ARGUMENTS` (Title only / Title + Decision)

If only Title is supplied, derive Context + Decision from the invoking session's decision context. If Title + Decision (no Context), derive Context. Derivation is real prose from the context at hand — never a placeholder (RFC-045).

This is a graceful-degradation case — real captures carry Title + Context + Decision — but the partial-payload path prevents a halt when only some of the payload is spelled out.

### Title slug collision

If two captures land on the same kebab-slug (different IDs but identical title fragments), the file paths differ by ID prefix so no collision occurs at the filesystem layer. The next-ID formula guarantees ID uniqueness against local + origin.

### ID collision with origin

The next-ID formula uses `git ls-tree origin/main` to read the remote-tracking ref without requiring a fetch. If a parallel session minted the same ID for a different decision and pushed it before this session captures, the local read sees the higher origin ID and increments past it.

If the local session has not fetched recently and origin has captures the local doesn't see, the formula may still collide. The renumber audit log line in Step 6 captures the resolution. P040 incident applies.

`--name-only` is required (P056): without it, default `git ls-tree` output carries the 40-char blob SHA which can contain three-digit runs that the digit-extraction regex false-matches. Same fix as create-adr Step 3 / manage-problem Step 3.

### Captured ADR never ratified

If the user captures and never ratifies, the `.proposed.md` ADR remains `human-oversight: unconfirmed` — and the SessionStart oversight nudge re-surfaces it every session until the `/wr-architect:review-decisions` drain handles it. Unlike the pre-RFC-045 never-expanded failure mode, this state cannot rot silently: the nudge is self-firing, and the sections already carry real (if unratified) substance.

### Architect-review verdict capture

Use case: a `wr-architect:agent` review yields PASS-WITH-NOTES with substantive rationale. Pattern:

1. User invokes capture-adr with `$ARGUMENTS = "Title from review topic\nContext: review of <change>\nDecision: <one-line verdict + rationale>"`.
2. The ADR lands at `docs/decisions/<NNN>-<kebab-title>.proposed.md` with status `proposed`, all sections derived — Considered Options carries the alternatives the architect actually weighed, Consequences the trade-offs from the verdict rationale.
3. Trailing pointer notes the ADR awaits ratification at the oversight drain.
4. The SessionStart nudge surfaces it; the user ratifies or amends at `/wr-architect:review-decisions`.

This pattern preserves architect-review verdicts as first-class ADR-shaped records instead of letting them rot in commit-message bodies.

### Cross-namespace consistency with capture-problem

The `capture-` verb is consistent across `/wr-itil:capture-problem` and `/wr-architect:capture-adr`. Same dispatch shape, same derive-real-values-at-capture discipline (ADR-067 for capture-problem ratings; RFC-045 for capture-adr sections), same single-commit-per-capture grain, same trailing-pointer signal. Users learn one mental model that spans both. ADR-032 amendment names this symmetry.

## Composition with the rest of the suite

### `/wr-architect:create-adr`

Heavyweight intake counterpart. The two skills share the `docs/decisions/*.proposed.md` directory and the next-ID formula. Cross-skill ordering: capture-adr writes a fully-derived ADR at `<NNN>`; `/wr-architect:create-adr <NNN>` (or `/wr-architect:review-decisions`) is the human-ratification/acceptance surface, not an expansion surface — there are no deferred sections to expand post-RFC-045.

### `wr-architect:agent`

The review surface that processes ADR review delegations. capture-adr does not invoke the architect-agent inline; review fires at acceptance (via `/wr-architect:create-adr`'s Step 5 confirm pass or direct delegation). The architect-agent reviewing a captured `.proposed.md` sees `status: proposed` + `human-oversight: unconfirmed` and treats it as a not-yet-accepted, not-yet-ratified ADR; reviews focus on whether the captured Decision conflicts with existing accepted ADRs.

### `/wr-itil:manage-problem` / `/wr-itil:capture-problem`

Compose with capture-adr when an iter surfaces both a problem AND a related decision. The user fires `/wr-itil:capture-problem <observation>` + `/wr-architect:capture-adr <decision>` in sequence (~6-8 turns total) instead of ~20-30 turns through the heavyweight pair.

### `/wr-itil:work-problems` (AFK orchestrator)

Iter subprocesses can invoke capture-adr to capture mid-iter design decisions without breaking iter cadence. The AFK carve-out in ADR-032 (line 85) excludes the **background-capture** variant from AFK contexts; the **foreground-lightweight-capture** variant introduced by P156 is fine inside iter subprocesses because it has no `Agent(run_in_background: true)` invocation — it is a normal foreground-synchronous skill that happens to do less work than create-adr.

### `/wr-architect:capture-adr` callers

The intended invocation surface is `/wr-architect:capture-adr <Title>\n<Context>\n<Decision>`. The payload must be non-empty; the skill does not branch on payload shape beyond the partial-payload graceful-degradation path documented under Edge cases.

## Related ADRs

- **ADR-009** — gate-marker-lifecycle (capture-adr does not write `/tmp` markers; ADR-009 referenced for pattern lineage only).
- **ADR-013** — structured user interaction (Rule 6 fail-safe; capture-adr has no AskUserQuestion branches so Rule 6 is trivially satisfied).
- **ADR-014** — governance skills commit their own work (capture-adr owns its commit).
- **ADR-019** — AFK orchestrator preflight (next-ID formula uses origin-tracking ref per ADR-019 confirmation criterion 2).
- **ADR-032** — governance skill invocation patterns (this skill's parent ADR; foreground-lightweight-capture variant amendment 2026-05-03; derived-substance amendment 2026-07-06 per RFC-045).
- **ADR-038** — progressive disclosure (SKILL.md + REFERENCE.md split shape).
- **ADR-044** — decision-delegation contract (framework-mediated mechanical-stage carve-outs).
- **ADR-049** — bin/ on PATH (capture-adr is self-contained; no new shim required, same as create-adr).
- **ADR-052** — behavioural-tests-default for skill testing (capture-adr's bats fixtures exercise primitives, not SKILL.md prose).
- **ADR-056** (`docs/decisions/056-...md` if present) — example of an inline-shipped substantive ADR that capture-adr could have skeleton-captured first.

## Related problems

- **P014** — parent / master tracker (ADR-032 children).
- **P088** — settled the user-direction-scoped decision: capture-problem + capture-adr are shippable; capture-retro is deferred.
- **P155** — sibling capture-problem skill (just shipped 2026-05-03).
- **P156** — driver ticket.
- **P157** — sibling pending-questions-surface hook.
- **P056** — ticket-creator next-ID lookup blob-SHA false-match (capture-adr's next-ID formula uses the `--name-only` fix).
- **P040** — origin-collision incident referenced in Edge cases.
- **P375** — named re-entry point is not a self-firing cadence; drove the RFC-045 derived-substance amendment.
