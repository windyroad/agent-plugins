---
status: "proposed"
human-oversight: confirmed
oversight-date: 2026-05-26
date: 2026-05-03
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: [Windy Road plugin users, addressr maintainer, bbstats maintainer]
reassessment-date: 2026-11-03
---

# SKILL.md runtime budget policy

## Context and Problem Statement

Every `/wr-<plugin>:<skill>` invocation loads the full `SKILL.md` body into the conversation context. Windyroad SKILL.md files have grown to carry content for multiple audiences in a single file — runtime operator instructions, maintainer rationale, ADR cross-references, deprecation notices, worked examples, and design-decision archaeology. All of that loads on every invocation, even when only the runtime steps execute.

P091 (session-wide context budget — meta) measured the magnitude. P097 (this ADR's driver) split out the SKILL.md surface and ran a Phase 1 line-tag audit on `manage-problem` (2026-04-27). The audit confirmed the runtime/maintainer mix and identified that ~18-22% of `manage-problem`'s body is `[reference]`-tagged content that could move to a sibling file with no behavioural change.

Current sizes (2026-05-03 re-measurement, captured during this ADR drafting):

| Skill | Bytes | Δ from 2026-04-22 audit |
|-------|------:|------------------------:|
| `/wr-itil:work-problems` | 95,861 | +56,596 (+144%) |
| `/wr-itil:manage-problem` | 82,808 | +27,776 (+50%) |
| `/wr-retrospective:run-retro` | 70,105 | +33,813 (+93%) |
| `.claude/skills/install-updates/SKILL.md` | 11,833 | -1,691 (-13%) |

Pressure is **accelerating**. The top-3 offenders have grown 50-144% in eleven days; the only file shrinking (`install-updates`) was actively trimmed by P094-line work. Without a normative budget, every per-iter ADR / P-ticket addition adds prose to the runtime hot path.

P097 Phase 1 also found that the dominant blocker on `[reference]` extraction was the existing structural-grep bats coupling (80 of 116 contract assertions on `manage-problem` grep specific phrases out of `SKILL.md`). P081 Layer A (ADR-052, 2026-05-03) supersedes ADR-037 with behavioural-default test discipline, unblocking the path. P097 Phase 2-3 (the actual extraction) remains gated on P081 Layer B (the harness primitives behavioural alternatives need to be expressible across bats / vitest / cucumber / pytest).

This ADR ships the **declarative contract** for SKILL.md runtime budget: classification taxonomy, sibling-file pattern, byte budgets, and an advisory detector — *before* the retroactive extraction work. The contract-first / measurement-second / rollout-third sequencing matches the ADR-051 / ADR-052 / ADR-053 precedent landed this week.

## Decision Drivers

- **JTBD-001** (Enforce Governance Without Slowing Down — solo developer) — every SKILL.md invocation loads thousands of tokens into the primary agent. The "reviews complete in under 60 seconds" outcome compresses as the runtime tax grows.
- **JTBD-006** (Progress the Backlog While I'm Away — AFK orchestrator) — `work-problems` loops invoke 5-10 skills per iter. Token weight directly compresses available context for the loop's actual work.
- **JTBD-101** (Extend the Suite with New Plugins — plugin-developer) — downstream authors copy-paste SKILL.md shapes from existing plugins. A canonical lean shape propagates a healthy pattern; the current bloated shape propagates the anti-pattern.
- **P091** (parent meta) — session-wide context budget. P097 is the SKILL.md surface of P091.
- **P097** (this ADR's direct driver) — Phase 1 audit identified the taxonomy + REFERENCE.md path; this ADR codifies it.
- **P081** (Layer A landed in ADR-052; Layer B pending) — unblocks Phase 2-3 extraction. Phase 2-3 is `Blocked by: P081` in the dependency graph.
- **P099 + ADR-040** (briefing-tree Tier 3 budget) — direct precedent for the WARN/MUST_SPLIT pair shape on a sibling surface. This ADR adopts ADR-040's vocabulary verbatim so adopters don't learn two near-identical concepts.
- **P094** (problems README size budget) — adjacent precedent for advisory size detection on a different surface.
- **ADR-038** (Progressive disclosure for governance tooling context) — parent pattern. Per-skill SKILL.md is one instance of the progressive-disclosure surface. This ADR specialises ADR-038 for the SKILL.md case.
- **ADR-040** (Session-start briefing surface) — Tier 3 precedent (`<topic>.md` per-topic files). This ADR is structurally analogous: a lean runtime file + on-demand reference siblings.
- **ADR-005** (Plugin testing strategy) + **ADR-052** (Behavioural-tests-default) — this ADR's advisory detector ships with a behavioural bats fixture per ADR-052's default; existing structural-grep coupling on SKILL.md content is the Phase 2-3 blocker.
- **ADR-014** (Commit discipline / batch grain) — single commit for ADR + script + bats + changeset is acceptable as one coherent declarative-contract batch.
- **ADR-044** (Decision-delegation contract) — REFERENCE.md reads are mechanical / silent (P132 inverse-P078 carve-out); the lazy-load decision is framework-resolved by the SKILL.md pointer itself.
- **ADR-045** (Hook injection budget for PreToolUse/PostToolUse) — silent-on-pass discipline. The advisory detector emits zero output when no skill exceeds budget.
- **ADR-049** (Plugin bin shim grammar) — the shipped script's bin shim follows `wr-retrospective-check-skill-md-budgets`.
- **CLAUDE.md P132** — when SKILL.md flags "Read REFERENCE.md § X for situation Y", that read is mechanical / silent. Agents MUST NOT consent-gate REFERENCE.md reads.

## Considered Options

1. **Declarative-first ADR + advisory detector; retroactive extraction deferred** (chosen) — codify the taxonomy, sibling-file pattern, and byte budgets. Ship the advisory detector script + behavioural bats. Mark P097 Phase 2-3 `Blocked by: P081` Layer B; opportunistic-as-touched extraction follows ADR-052's migration shape.

2. **Big-bang extraction across top-3 offenders** — fully extract `[reference]` content from manage-problem / work-problems / run-retro this iter. Rejected: blocked on the bats coupling identified in P097's 2026-04-27 Phase 1 audit. Each extraction without retrofitting the structural-grep bats produces test failures in proportion to how much `[reference]` content moves. P081 Layer B must mature first.

3. **Hook-enforced PreToolUse blocking on SKILL.md edits over budget** — block any Edit/Write that pushes a SKILL.md past MUST_SPLIT. Rejected: pre-empts P081 Layer B; the budget would force premature extraction without behavioural-test alternatives. Promotion to blocking is the named reassessment trigger below (mirrors ADR-052's PostToolUse-advisory → PreToolUse-blocking promotion path).

4. **Per-skill REFERENCE.md as opt-in only** — leave the sibling pattern as a recommendation, no advisory budget. Rejected: without a measurable budget, prose accumulates per-iter (top-3 offenders grew 50-144% in eleven days). The advisory is the measurement substrate for prioritising extraction order by token-cost-per-invocation.

5. **Single project-level REFERENCE.md** — collapse all skill rationale into one shared reference document. Rejected: situation-specific lookup gets harder (which subsection applies?); pointer-overhead grows; the per-skill sibling pattern aligns with ADR-040's per-topic file shape.

## Decision Outcome

**Chosen option: Option 1 — declarative-first ADR + advisory detector; extraction deferred behind P081 Layer B.**

### Content classification taxonomy

Every line of SKILL.md MUST be classifiable as one of:

- **`[runtime]`** — executes on every relevant invocation. Step-by-step instructions, decision trees the assistant must traverse, safety-critical warnings (e.g. P057 staging trap), tool-call sequences, output formatting requirements. Stays inline in SKILL.md. No exceptions.
- **`[reference]`** — supplies rationale, worked examples, design-decision archaeology, ADR cross-references, deprecation explanations, "why a helper instead of inline ..." paragraphs. Moves to sibling REFERENCE.md (see below). The runtime SKILL.md retains a **pointer** when the situation matches.
- **`[deprecated]`** — describes behaviour the plugin no longer ships, kept inline only for deprecation-window discoverability. Deletes after the documented deprecation window closes.

The taxonomy is **per-paragraph**, not per-section. Section headers may straddle types — for example, `## Step 7 Status transitions` mixes runtime triggers (git-mv blocks, P057 staging-trap warning) with reference rationale (the README-refresh mechanism explanation). Per-paragraph classification is mechanically required; per-section is too coarse.

### Sibling REFERENCE.md pattern

For each skill at `packages/<plugin>/skills/<skill>/SKILL.md`, the reference-tagged content lives at `packages/<plugin>/skills/<skill>/REFERENCE.md` (sibling, same directory). One REFERENCE.md per skill — not one shared per plugin, not one shared at repo root.

The runtime SKILL.md MUST reference REFERENCE.md sections via explicit pointers of the form:

> Read `REFERENCE.md` § `<heading>` for `<when this applies>`.

These pointers are the **lazy-load contract**: they tell the assistant when to consult REFERENCE.md, and the load cost is paid only on the matching invocation paths.

REFERENCE.md uses standard markdown headings (`## <topic>`) so the `Read tool + heading-grep` pattern works. No frontmatter requirements; no allowed-tools restriction (the skill execution context already permits Read of any project file).

### Per-skill pointer-overhead ceiling (normative)

Per ADR-038 progressive-disclosure budgeting, each pointer of the form `Read REFERENCE.md § X for Y` consumes ~80 bytes. The runtime SKILL.md MUST NOT carry more than **20 pointers**, total pointer overhead capped at **~1.6 KB**.

This ceiling prevents a maintainer from defeating the byte budget by spamming pointers — extracting 10 KB of reference content but adding 10 KB of pointer scaffolding paradoxically grows SKILL.md. The pointer ceiling forces consolidation: when more than 20 situations apply, group them into a single conditional pointer ("Read REFERENCE.md § Lifecycle transitions for any Open / Known Error / Verifying / Closed transition") rather than per-target.

### Byte budgets and OVER / MUST_SPLIT semantics

Budgets are calibrated against the 2026-05-03 re-measurement table:

- **WARN ≥ 8,192 bytes** — emits an `OVER` line (advisory). Surfaces as a rotation candidate per ADR-040 Branch B precedent: deferral is permitted, the maintainer decides extraction priority based on invocation frequency × token cost. The 4th-10th offenders (12 KB-21 KB) cluster here.
- **MUST_SPLIT ≥ 16,384 bytes** — emits both `OVER` and `MUST_SPLIT`. No defer per ADR-040 Branch A precedent: the maintainer is committed to a `[reference]` extraction or a skill split (precedent: P071 phased split of `manage-problem`). The top-3 offenders (manage-problem 82 KB, work-problems 95 KB, run-retro 70 KB) sit well above this threshold.

The vocabulary mirrors ADR-040 / P145's `OVER` / `MUST_SPLIT` pair on the briefing-tree surface deliberately — adopters learn one concept across two surfaces, not two near-identical concepts.

The advisory detector ships under `packages/retrospective/scripts/check-skill-md-budgets.sh`, sibling to `check-briefing-budgets.sh`. The script is read-only (exit 0 always; exit 2 on parse error per the `check-*` cohort's contract). The bats fixture is **behavioural** per ADR-052: tests assert script output on temp-fixture skill trees, not script source content.

### Phase 2-3 sequencing (deferred)

P097 Phase 2 (top-3 offender extraction) and Phase 3 (remaining top-10 + project-local install-updates) are **`Blocked by: P081`** Layer B. The block is not "wait for full Layer B coverage" but "wait until enough harness primitives ship that the structural-grep bats anchoring `manage-problem` (80 assertions across 14 files) can be retrofitted to behavioural without losing coverage." The unblock criterion lives on P081's ticket, not this ADR's.

When Phase 2-3 commences, the migration shape is **opportunistic-as-touched** — verbatim per ADR-052 Migration §: when a maintainer next edits a SKILL.md with a sibling structural contract.bats, the touched bats file MUST either be retrofitted to behavioural (preferred) or carry an in-file justification comment per ADR-052's Surface 2 escape hatch. Big-bang retrofit was rejected as too risky for the same reason ADR-052 rejected it; deprecation-window was rejected as over-engineered.

### REFERENCE.md reads are mechanical (P132 / ADR-044 carve-out)

When SKILL.md flags "Read REFERENCE.md § X for Y", the matching read is **mechanical / silent** per CLAUDE.md P132 (inverse-P078). The runtime SKILL.md has already made the situation→consultation decision; the assistant MUST NOT consent-gate the read with `AskUserQuestion`. Defensive over-asking on each REFERENCE.md read defeats the lazy-load value.

Per ADR-044's authority taxonomy, the REFERENCE.md read is category 5 (silent-framework) — the SKILL.md pointer is the framework's pre-authorised consultation directive. `AskUserQuestion` is reserved for direction-setting / deviation-approval / authentic-correction.

### Phase 1 deliverable (this commit)

1. **ADR-054 lands** at `docs/decisions/054-skill-md-runtime-budget-policy.proposed.md` (this file).
2. **`check-skill-md-budgets.sh` ships** at `packages/retrospective/scripts/check-skill-md-budgets.sh` — walks `packages/*/skills/*/SKILL.md` + `.claude/skills/*/SKILL.md`, emits `OVER` / `MUST_SPLIT` lines, exit 0, sorted by basename.
3. **Behavioural bats fixture ships** at `packages/retrospective/scripts/test/check-skill-md-budgets.bats` — tests run script against temp-fixture skill trees, no greps of script source.
4. **Bin shim ships** at `packages/retrospective/bin/wr-retrospective-check-skill-md-budgets` per ADR-049 grammar.
5. **Changeset for `@windyroad/retrospective`** minor bump (script + bin = new public capability).
6. **P097 transitions Open → Known Error** with this ADR cited as Phase 1 deliverable; Phase 2-3 explicitly `Blocked by: P081` Layer B.

## Consequences

### Good

- Taxonomy + sibling-file pattern is the **first canonical SKILL.md shape** in the project. JTBD-101 plugin authors get a clear pattern to copy (and to reject the bloated mixed shape they would otherwise inherit by accident).
- Advisory detector creates the measurement substrate Phase 2-3 needs to prioritise extraction order by token-cost-per-invocation, not guesswork.
- Vocabulary alignment with ADR-040 (OVER / MUST_SPLIT) means adopters learn one concept twice, not two concepts. Cognitive load minimised.
- ADR ships before extraction — no breaking changes; retro reviewers can flag drift between ADR-054 intent and per-iter SKILL.md additions in the next retro cycle, even before any extraction commits.
- P132 inverse-P078 carve-out is explicit, preventing the defensive over-ask trap that would otherwise consume the lazy-load value.
- The pointer ceiling (≤ 20 / ≤ 1.6 KB) forces consolidation — no maintainer can defeat the byte budget by spamming pointers.

### Neutral

- Phase 1 ships only the contract + advisory detector — no SKILL.md actually shrinks this iter. Phase 2-3 (the byte savings) is downstream of P081 Layer B maturity. Per ADR-051 / ADR-052 / ADR-053 precedent, declarative-first sequencing is the right shape.
- The `OVER` / `MUST_SPLIT` lines fire today on the top-10 SKILL.md offenders (already over budget). The advisory output will be noisy at landing; the noise IS the signal driving Phase 2-3 prioritisation when P081 Layer B unblocks.
- REFERENCE.md sibling files are net-new in the project. ADR-030 (repo-local skills) and ADR-002 (monorepo per-plugin) constrain *where* skills live but say nothing about per-skill internal file shape; this ADR is the first ADR to codify it.

### Bad

- Without Phase 2-3 (extraction), Phase 1 alone delivers no token reduction. The contract-first sequencing is correct per the ADR-052 / ADR-053 precedent, but the actual byte savings are deferred behind another ticket's progress.
- The advisory detector adds another `check-*.sh` script to the retro-time consumer cohort. `run-retro` Step 2b will eventually wire it in; until then it's bin-discoverable but not auto-fired. The wiring is opportunistic per ADR-052 migration shape.
- Per-paragraph classification (per the taxonomy section) is judgement-heavy. The first few extractions under Phase 2 will need explicit retro-time review to calibrate the `[runtime]` / `[reference]` boundary; the calibration cost lands on Phase 2 maintainers, not this ADR.
- The 8,192 / 16,384 thresholds are calibrated against today's distribution. If the distribution shifts (e.g. a future Layer B harness primitive lets one large skill split into 6 small ones), the WARN threshold may drift. The reassessment-date 2026-11-03 catches this.

## Confirmation

The decision is satisfied when:

1. **ADR-054 lands** at `docs/decisions/054-skill-md-runtime-budget-policy.proposed.md` (this file).
2. **`check-skill-md-budgets.sh` ships** at `packages/retrospective/scripts/check-skill-md-budgets.sh` — read-only advisory; exit 0 always; exit 2 on parse error; output sorted by basename; OVER + MUST_SPLIT block ordering matches `check-briefing-budgets.sh` precedent.
3. **Behavioural bats fixture ships** at `packages/retrospective/scripts/test/check-skill-md-budgets.bats` — covers (a) empty tree → silent; (b) all-under-WARN → silent; (c) WARN-band → OVER only; (d) MUST_SPLIT-band → OVER + MUST_SPLIT; (e) env override; (f) basename sort stability; (g) `.claude/skills/*` discovery; (h) non-SKILL.md files ignored. Fixture is behavioural — no greps of script source.
4. **Bin shim ships** at `packages/retrospective/bin/wr-retrospective-check-skill-md-budgets` per ADR-049.
5. **Changeset lands** for `@windyroad/retrospective` minor bump.
6. **P097 transitions Open → Known Error** with the Phase 2-3 dependency on P081 Layer B explicit.
7. **No regression in existing retrospective bats** — `check-briefing-budgets.bats`, `check-ask-hygiene.bats`, `check-readme-jtbd-currency.bats`, `check-tickets-deferred-cause.bats` all continue passing.

## Pros and Cons of the Options

### Option 1: Declarative-first ADR + advisory detector; extraction deferred (chosen)

- **Good**: ships the contract + measurement before extraction, matching ADR-051 / ADR-052 / ADR-053 precedent; no breaking changes; advisory output is the prioritisation substrate Phase 2-3 needs; vocabulary aligns with ADR-040.
- **Bad**: no token savings this iter; the contract is "all words, no extraction" until Phase 2-3 unblocks behind P081 Layer B.

### Option 2: Big-bang extraction across top-3 offenders

- **Good**: large immediate token savings (~30-50 KB across the top-3); proves the pattern at scale.
- **Bad**: blocked on P097 Phase 1 audit's bats-coupling finding (80 structural-grep assertions on manage-problem alone). Pre-empting P081 Layer B forces either Path A (cement structural greps as the contract) or Path B (parallel behavioural retrofit during extraction — doubles the change surface). WSJF-incorrect sequencing.

### Option 3: Hook-enforced PreToolUse blocking

- **Good**: cannot be skipped; SKILL.md cannot grow past MUST_SPLIT.
- **Bad**: Phase 1 advisory-only is the right transition shape (mirrors ADR-052's PostToolUse-advisory → PreToolUse-blocking promotion path); blocking before P081 Layer B forces premature extraction.

### Option 4: Per-skill REFERENCE.md as opt-in only (no advisory)

- **Good**: zero new tooling.
- **Bad**: without measurement, prose accumulates per-iter (top-3 grew 50-144% in eleven days). The advisory IS the measurement substrate.

### Option 5: Single project-level REFERENCE.md

- **Good**: one file to maintain.
- **Bad**: situation-specific lookup gets harder; pointer-overhead grows; per-skill sibling pattern aligns with ADR-040's per-topic file shape and the existing skill-directory layout.

## Reassessment Criteria

Re-evaluate this decision if:

- **P081 Layer B matures** — when behavioural-test framework primitives let manage-problem's 80 structural-grep assertions retrofit cleanly, P097 Phase 2-3 starts. This ADR's taxonomy and budgets gate Phase 2-3 commits.
- **Distribution shifts** — if SKILL.md byte distribution shifts materially (e.g. several new skills land at 4-6 KB), recalibrate WARN / MUST_SPLIT thresholds.
- **Pointer ceiling becomes load-bearing** — if a real-world Phase 2 extraction needs > 20 pointers, revisit the cap. The cap exists to force consolidation; if consolidation genuinely doesn't apply, raise it with documented rationale.
- **REFERENCE.md sibling discoverability fails** — if retro-time review reveals agents skipping REFERENCE.md reads despite explicit SKILL.md pointers (i.e. the lazy-load contract isn't honoured), promote the pointer pattern from advisory prose to a structured directive (e.g. a PostToolUse hook that flags missing REFERENCE.md consultations).
- **Promotion to PreToolUse blocking** — when SKILL.md count over MUST_SPLIT drops to ≤ 2, promote the advisory to PreToolUse blocking (mirrors ADR-052's promotion path).
- **`run-retro` wires the detector** — when `/wr-retrospective:run-retro` Step 2b consumes `check-skill-md-budgets.sh` (sibling to its other check-* consumers), revisit whether the standalone bin shim is still load-bearing.
- **Reassessment date 2026-11-03** — six months from landing, as per ADR-052 / ADR-053 cadence.

## Related

- **P097** — driver ticket; this ADR is its Phase 1 declarative deliverable.
- **P091** — parent meta (session-wide context budget). P097 is the SKILL.md surface of P091; this ADR specialises the parent.
- **P081** — Phase 2-3 blocker. Layer A landed in ADR-052; Layer B (harness primitives) gates extraction.
- **P099 + ADR-040** — Tier 3 budget precedent; this ADR adopts the OVER / MUST_SPLIT vocabulary verbatim.
- **P094** — problems README size budget; adjacent precedent for advisory size detection.
- **P145** — MUST_SPLIT escalation precedent on the briefing-tree surface.
- **ADR-038** (Progressive disclosure for governance tooling context) — parent pattern.
- **ADR-040** (Session-start briefing surface) — Tier 3 precedent.
- **ADR-005** (Plugin testing strategy) + **ADR-052** (Behavioural-tests-default) — testing discipline.
- **ADR-014** (Commit discipline / batch grain) — commit grain.
- **ADR-044** (Decision-delegation contract) — REFERENCE.md read is silent-framework category.
- **ADR-045** (Hook injection budget) — silent-on-pass discipline for the advisory detector.
- **ADR-049** (Plugin bin shim grammar) — bin shim location and naming.
- **ADR-051** + **ADR-052** + **ADR-053** — three-instance contract-first / measurement-second / rollout-third precedent landed this week.
- **JTBD-001 / JTBD-006 / JTBD-101** — primary persona-job anchors.
- **CLAUDE.md P132** — REFERENCE.md reads are mechanical / silent.
- `packages/retrospective/scripts/check-briefing-budgets.sh` — script shape precedent.
- `packages/retrospective/scripts/test/check-briefing-budgets.bats` — bats shape precedent.
- `packages/retrospective/bin/wr-retrospective-check-readme-jtbd-currency` — bin shim precedent.
