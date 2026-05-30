---
status: "proposed"
date: 2026-05-30
human-oversight: confirmed
oversight-date: 2026-05-30
decision-makers: [Tom Howard]
consulted: []
informed: []
reassessment-date: 2026-08-30
supersedes: []
---

# Compendium Decision Outcome — Progressive Disclosure via MADR-Canonical + Semantic Fallback + Authoring Validator

## Context and Problem Statement

ADR-077 introduced `docs/decisions/README.md` as the architect-agent's "token-cheap load surface for routine compliance review". P337 (driver) surfaced an empirical gap: **43 of 75 ADRs (57%) render in the compendium with no Decision Outcome content at all** — only title, status badge, oversight badge, supersession links, and (if present) related-ADR refs. The reader has Confirmation tests but no statement of what was decided.

Root cause locus: `packages/architect/scripts/generate-decisions-compendium.sh` line 124 (`get_chosen` function) extracts only lines opening with `Chosen` (typically MADR's `Chosen option: "..."` tag). ADRs that use `## Decision Outcome` followed by prose without the `Chosen option:` tag render with no decision content. This is half the corpus.

The user surfaced the gap by direct reading of `docs/decisions/README.md` post the P334 portability fix shipping: *"is there enough information in here to follow the decisions without having to consult the full ADR file. It doesn't look like there is."*

The framing question is **how to progressively disclose decision content in the compendium** — what's the right shape that gives the architect agent enough context for routine compliance review without ballooning the load surface.

Best-practices research (2026-05-30):

- **log4brains** (popular ADR static-site generator): index renders Date + Title + Status only; users click through to per-ADR pages for decision content. Suited for human readers with cheap navigation; ill-suited for AI agents whose "click through" is a Read tool call that defeats the load-cheap purpose.
- **MADR canonical** (the template this project uses): `Chosen option: "{title}", because {justification}` opens Decision Outcome. This IS the canonical single-sentence TL;DR shape. The existing generator extractor targets it correctly for the 32 ADRs that follow MADR-canonical form.
- **"Mature orgs reduce reliance on discipline by structure"** (MADR research finding 2026-05-30): "Mature engineering organizations reduce reliance on discipline by embedding it into structure — making the right behavior easier and architectural risk more visible." Argues against author-backfill alone; favors CI gates / validators.

## Decision Drivers

- P337 surfaced gap is load-bearing: 57% of corpus is non-functional for routine compliance review. ADR-077's confirmation criterion (a) is satisfied formally but defeated empirically for the majority of entries.
- Token-cost ceiling: the compendium MUST stay dominantly under ~15k tokens. Current is ~10k. Any extraction strategy that grows it past ~15k pushes the "routine load" cost into the un-cheap zone.
- AI-agent consumer pattern: the compendium IS the load surface. Click-through (Read tool call per ADR) is the explicit anti-pattern. Every entry must carry enough content for the agent to follow the decision without follow-up reads.
- Generator idempotency: ADR-077 confirmation criterion (b) — running the generator twice produces byte-identical output. Any extraction strategy must remain deterministic.
- Structure over discipline: prefer validator-enforced authoring conventions over reliance on remembering to backfill 75 existing ADRs. Catch the regression at author time, not at review time.
- MADR canonical alignment: the template this repo uses has a recommended Decision Outcome opening shape. Going against it would require inventing a new convention and abandoning MADR alignment.
- Validator friction risk: a too-strict Phase 2 validator becomes the next P327-class friction surface. Architect advisory 2026-05-30 — Phase 2 SHOULD fail-open with a warning (not deny-write) when framing-prose-detection regex misfires on legitimate "After weighing options A and B, we chose X" shapes.
- Cadence-over-discipline for Phase 3 opportunistic upgrades: no automatic cadence = doesn't happen (memory feedback `feedback_automatic_cadence_or_it_doesnt_happen.md`). The opportunistic-upgrade trigger MUST be embedded in an existing cadence-driven surface (the `/wr-architect:review-decisions` ratification drain is the natural locus).

## Considered Options

1. **First sentence of Decision Outcome (semantic boundary)** — extract the first sentence (terminated at `. ` / `.\n` / `! ` / `? `); never truncate mid-sentence. Falls back to second sentence if first is framing prose.
2. **Whole Decision Outcome section, no cap** — emit the full `## Decision Outcome` body; accept uneven growth.
3. **Author-controlled `<!-- @compendium-include start/end -->` markers** — ADR body marks the region the generator should extract; defaults to first sentence when markers absent.
4. **MADR-TL;DR discipline, retroactive** — require every ADR's Decision Outcome to lead with a `Chosen option:` single sentence (MADR-canonical form); backfill 43 non-conforming existing ADRs as a one-time cost.
5. **Hybrid section-aware extraction with section-level token budget** — measure tokens per section; include whole section if under budget, fall back to first sentence if over.
6. **(Recommended) MADR-canonical primary + first-sentence fallback + fail-open authoring validator + cadence-embedded opportunistic upgrade** — four-layered approach: (a) generator extracts MADR-canonical `Chosen option:` line when present (existing behaviour, preserved); (b) generator falls back to first sentence of `## Decision Outcome` when no canonical line found, with framing-prose advance to second sentence; (c) a new authoring validator (CI gate + PreToolUse hook on `docs/decisions/*.proposed.md` writes) fails-OPEN with a warning when framing-prose detection fires — does NOT deny-write — and the warning surfaces in the architect-agent verdict on the next review; (d) the `/wr-architect:review-decisions` ratification drain gains an opportunistic-upgrade step that offers to repair Decision Outcome shape when ratifying an ADR whose render would be empty or framing-prose-only.

## Decision Outcome

Chosen option: **"Option 6 — MADR-canonical primary + first-sentence fallback + fail-open authoring validator + cadence-embedded opportunistic upgrade"**, because it closes the P337 gap without requiring author discipline at scale, preserves MADR canonical alignment, embeds the right convention as structure (validator) rather than guideline, fails-open to avoid becoming P327-class friction, and ties opportunistic upgrade to an existing cadence so the principle "no automatic cadence = doesn't happen" doesn't bite.

Four layered changes ship across three phases:

**Phase 1 (generator)**:
- Extend `get_chosen` in `packages/architect/scripts/generate-decisions-compendium.sh` (line 124) to fall through to `get_section "$file" "Decision Outcome"` + emit the first sentence (semantic boundary, not character truncation) when no MADR-canonical `Chosen option:` line is found.
- Sentence boundary defined as: text up to and including the first `. ` or `.\n` (period followed by space, period followed by newline), `! `, `! \n`, `? `, `? \n`. Never mid-word, never mid-sentence.
- If the first sentence is framing prose (regex match against `^(This ADR|This decision|We address|We need to|The problem)`), advance to the second sentence.
- Hard fallback if no Decision Outcome section exists at all: emit `**Decides:** (no Decision Outcome section authored)` and flag in stderr so CI catches the gap on the next pre-commit run.

**Phase 2 (fail-OPEN authoring validator)**:
- New script `packages/architect/scripts/validate-adr-shape.sh` checks that every `docs/decisions/<NNN>-*.<status>.md` file (excluding README.md) has a `## Decision Outcome` section AND that section opens with either a MADR-canonical `Chosen option:` line OR another non-framing leading sentence (no `^This ADR`, `^This decision`, etc.).
- Distributed via the ADR-049 `$PATH` shim at `packages/architect/bin/wr-architect-validate-adr-shape` — hooks and skills MUST invoke the shim, not the script's repo-relative path (per memory `feedback_no_repo_relative_paths_in_published_artifacts.md`).
- Wired into CI as a new "Validate ADR shapes" Quality Gates step that emits warnings (not failures) when framing-prose detection fires on legitimate-looking ADRs; emits failures only on missing `## Decision Outcome` section.
- Wired into a new PreToolUse:Write hook on `docs/decisions/*.proposed.md` paths that runs the same validator. The hook FAILS-OPEN — it surfaces the warning in stderr but does NOT deny the Write. The warning is then surfaced in the next `wr-architect:agent` review for human judgment (per architect advisory 2026-05-30: a deny-write validator becomes the next P327-class friction surface).
- Authoring escape hatch: if the user genuinely wants a non-canonical Decision Outcome opening (the architect advisory cites "After weighing options A and B, we chose X" as a legitimate non-framing form not covered by the regex), the warning is informational only and the write proceeds.
- Behavioural bats coverage: shape validator must accept canonical-MADR ADR; emit warning on `## Decision Outcome` followed by `This ADR addresses...` framing; accept `## Decision Outcome` followed by `Chosen option: X` line; accept `## Decision Outcome` followed by other non-framing leading sentence; emit failure only on missing `## Decision Outcome` section.

**Phase 3 (cadence-embedded opportunistic upgrade — NOT mass backfill)**:
- The existing 43 non-canonical ADRs continue to render via the Phase 1 fallback.
- Extend `/wr-architect:review-decisions` (the ratification drain) to detect when the ADR being ratified would render empty or framing-prose-only in the compendium. When detected, the drain OFFERS (via `AskUserQuestion`) to repair the Decision Outcome shape inline as part of the ratification commit.
- Cadence-driven by construction — the drain is already the periodic human-confirm surface for ratifying ADRs. No new periodic task needed; no reliance on author discipline; the principle "no automatic cadence = doesn't happen" is satisfied because the cadence is the drain itself.
- No mass backfill commit. Per the "structure over discipline" insight, the validator catches new regressions; old ADRs migrate via the ratification cadence; nothing relies on remembering to do something.

## Consequences

### Good

- P337 closes: every ADR renders Decision Outcome content in the compendium.
- MADR canonical alignment preserved: new ADRs authored per MADR convention render with the tightest TL;DR (the `Chosen option:` line).
- Author discipline minimized: existing ADRs work via fallback without backfill effort; new ADRs are catch-on-write via validator; opportunistic upgrade ties to existing cadence.
- Token cost bounded: ~3k extra tokens for the fallback-extracted first sentences on the 43 non-canonical ADRs; compendium grows from ~10k → ~13k. Stays under the ~15k routine-load ceiling.
- Generator idempotency preserved: deterministic extraction; no LLM synthesis at generate time.
- Validator is fail-open: no P327-class friction surface introduced; warnings surface in the next architect review for human judgment.
- ADR-049 shim discipline preserved: validator distributed via `$PATH`-resolved shim, not repo-relative paths.
- Cadence-over-discipline: Phase 3 opportunistic upgrade is triggered by the existing `/wr-architect:review-decisions` cadence, not by a separate "remember to backfill" obligation.

### Neutral

- Two extraction paths in the generator (canonical primary, semantic fallback) add a code branch but the branch is simple: try the MADR tag, fall through if absent.
- The "framing prose" regex is heuristic — future ADRs may use opening forms not in the current regex. Easy to amend incrementally; fail-open behaviour means false positives are warnings, not blockers.
- The validator is one more CI step + one more PreToolUse hook; modest extension of the existing safety net (`architect-compendium-refresh-discipline.sh`).
- Phase 3 inline-upgrade during ratification means the drain UX gains a step. Bounded — only fires when the render would be empty or framing-prose-only.

### Bad

- Existing 43 non-canonical ADRs surface their first sentence as Decision Outcome, which may be opening prose ("This ADR addresses the problem that...") even with the framing-detect regex. Trade-off: some ADRs render slightly noisier first sentences than the canonical form would produce. Acceptable because the alternative is no Decision Outcome content at all.
- The validator may surface false-positive warnings on legitimate non-framing openings the regex doesn't cover. Trade-off: fail-open behaviour means false positives are informational, not blocking. Author has clear visibility of the trigger in stderr.
- Phase 3 opportunistic upgrade is gated by ratification cadence — ADRs that are never ratified (stay `proposed` indefinitely) don't get upgraded. Acceptable: those ADRs render via the Phase 1 fallback; the upgrade is opportunistic by design.

## Confirmation

Concrete, testable criteria — every item must be verifiable by a bats fixture or empirical command:

(a) **Compendium completeness**: running `wr-architect-generate-decisions-compendium && grep -c '^\*\*Decides:\*\*' docs/decisions/README.md` returns 75 (or whatever the current ADR count is). Every ADR has a Decides line. Currently returns 32; target is 75.

(b) **Fallback correctness**: a bats fixture creates an ADR with `## Decision Outcome` opening with a non-framing sentence (no `Chosen option:` tag); generator emits that sentence as the Decides line; idempotency holds.

(c) **Framing-prose advance**: a bats fixture creates an ADR with `## Decision Outcome` opening with `This ADR addresses ...`; generator advances to second sentence per the framing-detect regex.

(d) **Fail-open validator on CI**: new "Validate ADR shapes" Quality Gates step; emits warnings (does not fail the build) on framing-prose detection; emits failures only on missing `## Decision Outcome` section.

(e) **Fail-open validator on PreToolUse:Write**: writing a new ADR whose Decision Outcome opens with framing prose surfaces a stderr warning citing the framing pattern; the Write PROCEEDS; new behavioural bats covers this path.

(f) **Token cost ceiling**: post-Phase-1, `wc -w docs/decisions/README.md` × 1.3 (rough word→token conversion) ≤ 15000. If exceeded, document the deviation and consider accelerating Phase 3 cadence.

(g) **Drift gate preservation**: existing test 2145 (`committed compendium matches generator output`) continues to pass — the extraction layered change does not break ADR-077 confirmation criterion (g).

(h) **MADR-canonical preservation**: ADRs that follow MADR canonical form render exactly as before — no behaviour change for the 32 conforming ADRs.

(i) **ADR-049 shim discipline**: the validator script is invoked via `wr-architect-validate-adr-shape` shim throughout; bats fixture asserts the shim exists, is executable, and resolves its library siblings relative to the script's own location (not cwd) so it works in adopter installs.

(j) **Cadence-embedded opportunistic upgrade**: `/wr-architect:review-decisions` SKILL.md documents the inline-upgrade offer; bats fixture asserts the skill's Step `N` carries the `AskUserQuestion` for upgrade-or-skip when ratifying an ADR with empty / framing-prose-only render.

## Pros and Cons of the Options

### Option 1 — First sentence of Decision Outcome (semantic boundary)

- Good: Modest token growth (~3k); no author-discipline backfill needed.
- Good: Sentence boundary respects natural prose structure.
- Bad: Doesn't address the "framing prose" problem (ADRs opening with "This ADR addresses..." emit framing as Decides).
- Bad: No structural enforcement for new ADRs — the gap re-opens with every non-canonical authoring.

### Option 2 — Whole Decision Outcome section, no cap

- Good: Lossless; maximum information per entry.
- Bad: Token growth uneven; some ADRs have multi-paragraph Decision Outcomes that balloon the compendium past the ~15k ceiling.
- Bad: Defeats "routine-load cheap" principle for the long-Decision-Outcome ADRs.

### Option 3 — Author-controlled `<!-- @compendium-include -->` markers

- Good: Per-ADR token-cost tuning; maximum author control.
- Bad: Requires retroactive marker addition across 75 ADRs (the backfill cost the structure-over-discipline principle argues against).
- Bad: Markers are an invented convention; not aligned with MADR or any common ADR practice.
- Bad: Fallback to first sentence still needed when markers absent — adds rather than replaces complexity.

### Option 4 — MADR-TL;DR discipline, retroactive

- Good: Tightest compendium — one MADR-canonical line per ADR.
- Good: Aligns with MADR best-practice "if you want to reduce even further, simply state the chosen option and explain why".
- Bad: Requires backfill of 43 ADRs (one-time but real cost).
- Bad: Relies on author discipline going forward; structure-over-discipline principle argues against.
- Bad: No structural enforcement mechanism named.

### Option 5 — Hybrid section-aware extraction with section-level token budget

- Good: Maximally adaptive — short sections in full, long sections truncated.
- Bad: Most complex generator (three extractors, depth params, per-section budget tracking).
- Bad: Token-per-section accounting is non-trivial to implement deterministically.
- Bad: Same framing-prose problem as Option 1 within the truncated path.

### Option 6 — MADR-canonical primary + first-sentence fallback + fail-open authoring validator + cadence-embedded opportunistic upgrade (CHOSEN)

- Good: Closes P337 directly; every ADR renders Decision Outcome.
- Good: MADR alignment preserved (canonical primary path).
- Good: Structural enforcement (validator) for new ADRs; structure-over-discipline.
- Good: Fail-open validator avoids P327-class friction.
- Good: Cadence-embedded opportunistic upgrade ties to existing ratification drain — no relies-on-discipline trap.
- Good: ADR-049 shim discipline carried in the proposal.
- Good: No mass backfill required; existing corpus handled by fallback.
- Good: Token cost bounded (~3k growth, stays under ~15k ceiling).
- Bad: Two extraction paths (slight generator complexity).
- Bad: Existing non-canonical ADRs render their first sentence, which may be noisier than ideal until opportunistic upgrade lands during ratification.
- Bad: Phase 3 inline-upgrade adds a step to the ratification drain UX — bounded but real.

## Reassessment Criteria

Revisit this decision when any of:

- Compendium token cost reaches ~15k (the routine-load ceiling) — re-evaluate whether to accelerate Phase 3 cadence (e.g., bulk-upgrade campaign during a dedicated session), or whether Option 2 (whole-section) should be cancelled for budget reasons.
- The fail-open authoring validator fires false-positive warnings more than once per ratification drain pass — re-evaluate whether the framing-detect regex needs amendment or whether the validator should be quieted.
- A future MADR template revision changes the canonical Decision Outcome opening shape — re-align the extractor.
- A new ADR-tooling best-practice emerges (e.g., a community-standard `compendium-include` marker syntax) — re-evaluate Option 3 for future alignment.
- The compendium load-surface purpose itself shifts (e.g., agents start receiving the full per-ADR set instead of the compendium for routine review) — re-evaluate whether the compendium remains the right load surface or should be deprecated.

Default reassessment: 3 months from approval (2026-08-30).

## Related

- **P337** — driver capture; surfaced by user direct observation 2026-05-30. This ADR closes P337 on Phase 1 + 2 shipping.
- **ADR-077** — Generated decisions compendium as token-cheap load surface. This ADR amends ADR-077's Confirmation criterion (a): every ADR renders Decision Outcome content via canonical-primary / fallback extraction.
- **P334** — sibling generator fix just shipped (BSD/GNU awk substr Unicode portability). Both touch `generate-decisions-compendium.sh`. Phase 1 implementation iter should rebase on `@windyroad/architect@0.12.2` to compose cleanly.
- **P327** — recent friction surface that motivated the fail-open advisory; informs Phase 2 validator UX.
- **ADR-049** — `$PATH`-resolved shim discipline; preserved in Phase 2 via `wr-architect-validate-adr-shape` shim.
- **ADR-064** — Decision-delegation contract; preserved (user pins substance via the AskUserQuestion confirm at Step 5).
- **ADR-066** — Born-confirmed marker; this ADR ships with the marker after the Step 5 user-confirm pass.
- `packages/architect/scripts/generate-decisions-compendium.sh` line 124 — locus of Phase 1 generator change.
- `packages/architect/scripts/test/generate-decisions-compendium.bats` — locus of new bats fixtures (Confirmation criteria b, c, g, h).
- Future: `packages/architect/scripts/validate-adr-shape.sh` — Phase 2 authoring validator script.
- Future: `packages/architect/bin/wr-architect-validate-adr-shape` — Phase 2 ADR-049 shim.
- Future: `packages/architect/hooks/architect-adr-shape-validator.sh` — Phase 2 PreToolUse:Write hook.
- Future: `packages/architect/skills/review-decisions/SKILL.md` Step N amendment — Phase 3 opportunistic-upgrade offer.

### Best-practices research citations (2026-05-30)

- **MADR canonical Decision Outcome form** — `Chosen option: "{title}", because {justification}` per <https://adr.github.io/madr/>; existing extractor targets this shape.
- **log4brains minimalist index pattern** — Date + Title + Status; click-through model per <https://thomvaill.github.io/log4brains/adr/>. Inapplicable for AI-agent load surface where "click-through" is a Read tool call.
- **"Mature orgs reduce reliance on discipline by structure"** — MADR-context research finding 2026-05-30 via WebSearch `MADR architecture decision records decision outcome TL;DR summary discipline`. Source: <https://reflectrally.com/architecture-decision-logs/>. Argues for validator-enforced authoring conventions over backfill.
- **MADR minimal-form recommendation** — *"if you want to reduce even further, simply state the chosen option and explain why you picked it in a short single sentence"* per the MADR template guidance. Validates Option 4's discipline target, although structure-over-discipline argues against mandatory backfill — Option 6 takes the disciplined form as the canonical primary path while the fallback handles non-conforming entries gracefully.
