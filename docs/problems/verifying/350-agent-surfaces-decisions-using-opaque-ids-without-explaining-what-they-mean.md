# Problem 350: agent surfaces decisions to user using opaque IDs (P-numbers, ADR-numbers, JTBD-numbers) without explaining what they mean — empathy gap

**Status**: Verification Pending
**Reported**: 2026-06-03
**Fix Released**: 2026-06-04 — memory artefact + SKILL prose amendments across 8 surfaces (review-decisions, confirm-jobs-and-personas, manage-problem, manage-rfc, capture-problem, capture-rfc, review-problems, run-retro). work-problems Step 6.5 and create-adr Step 5 § 5a Rule 3 were already in-place exemplars.
**Priority**: 12 (High) — Impact: 4 (Significant — user cannot make informed decisions when surfaced questions reference IDs they have to look up; each opaque reference forces the user to either skip the question, ask for context, or open files; cumulative cost across multi-question batches is high) × Likelihood: 3 (Possible — observed repeatedly in this session: ADR-080 sub-decision surfacing 2026-06-02; ADR-081 surfacing 2026-06-02; this morning's P270/P349 surfacing)
**Origin**: internal
**Persona**: developer
**JTBD**: JTBD-001
**Effort**: M (SKILL prose amendment across multiple surfaces that emit AskUserQuestion + agent-side brief-before-ID discipline + possibly a structural lint that catches AskUserQuestion option/question text containing bare ID references without inline context)
**WSJF**: 6.0 (12 × 1.0 / 2 = M effort)

## Description

User direction 2026-06-03 morning: *"You have an empathy gap. You know what those IDs mean, and incorrectly think that I do. That's the gap. I don't know what they mean. You need to brief me."*

In response to a batched 4-question AskUserQuestion that referenced `P270 / ADR-024`, `P349 / ADR-040`, etc. — the agent assumed the user had the same context the agent's file-loaded environment provides. The user does not. Every `P-NNN` / `ADR-NNN` / `JTBD-NNN` / `RFC-NNN` reference in a question is opaque text unless the agent inlines what the artefact actually is and what's at stake.

This is a recurring pattern this session:
- 2026-06-02 — ADR-080 sub-decision surfacing (SQ-080-1..6 with `ADR-049`, `ADR-080`, `ADR-081`, `ADR-061 Rule 2`, `P343 Option 3` references). User had to ask "What is the context. I don't know what ADR-080 is. Don't make me go look it up."
- 2026-06-02 — ADR-081 sub-decision surfacing. User pointed out same gap: "I don't know what ADR 081 is".
- 2026-06-03 morning — P270 / ADR-024 amendment surfacing + P349 / ADR-040 amendment surfacing. User: "You have an empathy gap... You need to brief me."

## Symptoms

- AskUserQuestion question text references `P-NNN` / `ADR-NNN` / `JTBD-NNN` / `RFC-NNN` / `SQ-NNN-N` without inlining the artefact's purpose or substance.
- AskUserQuestion option labels reference rule IDs ("ADR-061 Rule 2 carve-out") without explaining what the rule does.
- AskUserQuestion option descriptions assume the user remembers prior-session context about the artefact.
- User responses indicate they could not answer because the IDs were unfamiliar: "What is the context?", "I don't know what ADR-NNN is", "You need to brief me."

## Workaround

User asks for brief; agent then explains; user then answers. Adds at least one round-trip per affected question. With 4-question batches, the round-trip cost compounds: a 4-question batch can become 4 batches plus 4 briefings = 8 round-trips when 1 was intended.

## Impact Assessment

- **Who is affected**: every user-facing AskUserQuestion surface across every skill that surfaces design decisions (`/wr-itil:work-problems` Step 2.5, `/wr-architect:review-decisions` drain, `/wr-jtbd:confirm-jobs-and-personas` drain, `/wr-architect:create-adr` substance-confirm, `/wr-itil:manage-problem` Step 4b, `/wr-itil:manage-rfc`, `/wr-itil:capture-problem` derive-then-ratify dispatch, ad-hoc orchestrator-main-turn surfaces). The bias is universal across the surface class.
- **Frequency**: every batched AskUserQuestion event during ratification surfacing — high-volume relative to other interactive surfaces. 3+ observed in this session alone.
- **Severity**: High. The oversight system depends on the user being able to make informed ratification decisions. If the user can't answer because they don't have the context, they either skip (silent gap), ask for brief (cost), or guess wrong (worse). The brief-before-ID discipline is load-bearing for the entire oversight surface.
- **Analytics**: pattern is self-similar across surfaces; agent-side bias not surface-specific. Fix is at the agent-behavioural-discipline level + reinforced by SKILL prose.

## Root Cause Analysis

### Hypotheses

1. **Asymmetric context-loading**: agent has file-paths in its context (READMEs auto-loaded, files Read-tooled mid-session); user has only what's visible in the conversation transcript. Agent forgets the asymmetry when surfacing AskUserQuestion — uses the same shorthand it would use in inter-agent communication.

2. **ID-as-shorthand habit**: agent's internal reasoning uses IDs to compress reference; this leaks into user-facing question text without expansion.

3. **No structural enforcement**: no PreToolUse hook on AskUserQuestion that scans question/option text for bare `P-NNN`/`ADR-NNN`/`JTBD-NNN` references without paired explanations. SKILL prose can document the discipline, but the actual AskUserQuestion call sites are agent-emitted prose.

4. **Briefing pattern inverted**: when surfacing N decisions in one batch, the briefing cost compounds. Agent should brief ONCE per artefact then surface its sub-questions, not interleave IDs in question text expecting per-question reader to load the context themselves.

### Investigation Tasks

- [ ] Re-rate Priority and Effort at next /wr-itil:review-problems
- [x] Catalogue all SKILL.md surfaces that emit AskUserQuestion with potential ID references (work-problems Step 2.5, review-decisions, confirm-jobs-and-personas, create-adr, manage-problem 4b, manage-rfc, capture-problem 1.5b) — JTBD agent + architect agent confirmed 8-surface catalogue 2026-06-04: review-decisions, confirm-jobs-and-personas, manage-problem, manage-rfc, capture-problem, capture-rfc, review-problems, run-retro (work-problems + create-adr already carried the discipline as in-place exemplars).
- [x] Decide enforcement shape: chose option (a) SKILL prose discipline + agent-side memory per Fix Strategy recommendation. Architect review 2026-06-04 ALIGNED with no new ADR required (extension of ADR-013 + the P032 Output Formatting precedent + the create-adr Step 5 § 5a Rule 3 canonical pattern).
- [x] Memory artefact: created `~/.claude/projects/-Users-tomhoward-Projects-windyroad-claude-plugin/memory/feedback_brief_before_id.md` (commit pending) + indexed in `MEMORY.md`.
- [x] Pattern fix: brief-once-per-artefact template documented in the memory file (§ "How to apply" point 4) + canonical brief-before-ID prose stamp applied uniformly across the 8 SKILL surfaces.

## Fix Strategy

**Kind**: prevent (agent-behavioural discipline) + possibly enforce (structural lint)

**Shape options**:

1. **Memory artefact only** (lowest cost): add `feedback_brief_before_id.md` to user-memory directory documenting the empathy gap + the brief-before-ID rule. Future sessions load the memory at SessionStart. Adopter-portable insofar as the principle generalises.

2. **Memory + SKILL prose amendments** (moderate cost): amend the user-facing SKILL surfaces that emit AskUserQuestion (work-problems Step 2.5, /wr-architect:review-decisions, /wr-jtbd:confirm-jobs-and-personas, /wr-architect:create-adr Step 5, /wr-itil:manage-problem Step 4b, /wr-itil:manage-rfc, /wr-itil:capture-problem Step 1.5b) with explicit "brief-the-artefact-before-surfacing-its-IDs" guidance.

3. **Memory + SKILL prose + structural lint** (highest cost): plus a PreToolUse hook that intercepts AskUserQuestion calls and warns if question/option text contains bare ID patterns (`P\d{3}`, `ADR-\d{3}`, `JTBD-\d{3}`, `RFC-\d{3}`) without inline context (e.g. preceding sentence explaining what the ID refers to).

**Recommendation**: ship Option 2 — memory artefact captures the principle for future sessions; SKILL prose ensures every surface inherits the discipline. Option 3 lint is overkill for prose discipline that's better enforced via examples + retros.

## Dependencies

- **Blocks**: trust + efficiency of every batched AskUserQuestion surfacing. Cost compounds on every multi-decision drain.
- **Blocked by**: (none).
- **Composes with**: P078 (capture-on-correction — this ticket IS a captured correction), P135 (decision-delegation contract — surfaces requiring user input), ADR-013 (structured user-interaction — AskUserQuestion authority), ADR-074 (substance-confirm-before-build — the surfacing surface this gap most affects).

## Related

- 2026-06-03 user direction (this capture's authoring context): *"You have an empathy gap. You know what those IDs mean, and incorrectly think that I do. That's the gap. I don't know what they mean. You need to brief me."*
- 2026-06-02 prior in-session repro: ADR-080 sub-decision surfacing + ADR-081 sub-decision surfacing — user pointed out same gap twice.
- **P078** — capture-on-correction pattern (this ticket validates it: strong-signal correction → ticket capture before operational response).
- **P135** — decision-delegation contract; surfacing surfaces.
- **ADR-013** — structured user-interaction for governance decisions; AskUserQuestion is the structured surface this discipline applies to.
- **ADR-074** — substance-confirm-before-build; the surface this gap most affects.
- **JTBD-001** — enforce governance without slowing down; opaque-ID surfaces VIOLATE the "without slowing down" outcome.
