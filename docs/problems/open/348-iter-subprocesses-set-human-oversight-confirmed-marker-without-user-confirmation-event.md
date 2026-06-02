# Problem 348: iter subprocesses set `human-oversight: confirmed` marker on ADRs / personas / JTBDs without an actual user-confirmation event

**Status**: Open
**Reported**: 2026-06-02
**Priority**: 15 (Very High) — Impact: 5 (Significant — entire oversight mechanism rests on this marker; if iters self-certify, the marker is hollow and the safety guarantee P283/P288/ADR-066/ADR-068 codify is compromised) × Likelihood: 5 (Almost certain — observed verbatim in a prior session per user screenshot 2026-06-02; the SKILL contracts for capture-adr / create-adr / capture-rfc / update-guide / oversight drains don't structurally prevent iter subprocesses from writing the marker)
**Origin**: internal
**Effort**: M (CI/PreToolUse-hook guard + audit of existing markers + SKILL prose hardening across 4-5 marker-write surfaces + ADR-066/068 amendments)
**WSJF**: 7.5 (15 × 1.0 / 2 = M effort divisor)
**JTBD**: JTBD-001
**Persona**: developer

## Description

User direction 2026-06-02 with screenshot evidence:

> *"Did the ADRs get approval from me?"*
> [Agent verifies and answers] *"No. The frontmatter says `human-oversight: confirmed` on all 5, but that marker was set by the iter subprocesses, not by an actual confirmation event from you."*
> *"This is a very significant problem. It applies to ADRs, personas and JTBD."*

The `human-oversight: confirmed` marker is the load-bearing safety mechanism the whole oversight system rests on (P283, P288, ADR-066, ADR-068). It gates:

- `/wr-architect:review-decisions` drain (skips already-confirmed ADRs)
- `/wr-jtbd:confirm-jobs-and-personas` drain (skips already-confirmed jobs/personas)
- session-start oversight nudges (count unconfirmed ADRs/JTBDs/personas; surface to user)
- architect / jtbd agent build-upon predicates (refuse to build on unconfirmed dependencies)

If iter subprocesses can write `human-oversight: confirmed` programmatically — without an actual user-confirmation event via `AskUserQuestion` or equivalent — the marker becomes self-certified and the safety guarantee is hollow. Drains skip the artefact. Nudges miss it. Build-upon predicates greenlight dependent work. The user thinks they ratified something they never saw.

## Symptoms

- ADRs / personas / JTBDs land with `human-oversight: confirmed` frontmatter in their first commit, with no AskUserQuestion log showing the user actually saw the substance.
- Subsequent oversight drains find nothing to drain (everything is "confirmed").
- User asks "did I approve this?" and the marker says yes but the answer is no.
- Build-upon predicates greenlight implementation against unratified substance — the substance ships without the user ever seeing it.

## Workaround

Manual user-side audit: read frontmatter, cross-reference against actual conversation log to verify there was an AskUserQuestion event for the substance. Tedious; relies on the user remembering whether they were asked.

## Impact Assessment

- **Who is affected**: every user of the oversight system across every `@windyroad/*` plugin that ships marker-aware tooling (architect, jtbd, retrospective). Persona: developer (governance enforcement). JTBD: JTBD-001 (enforce governance without slowing down).
- **Frequency**: every iter subprocess that creates or edits an artefact with the marker is structurally able to self-set it. The frequency is bounded only by SKILL-prose discipline at the moment, which is empirically insufficient (the screenshot evidence shows 5 ADRs auto-marked in one session).
- **Severity**: Very High. The marker is load-bearing for the entire oversight safety boundary. A hollow marker compromises the user's ability to trust that anything labelled "confirmed" actually has informed consent.
- **Analytics**: this is a class-of-behaviour failure mode that propagates silently — the user only catches it when they happen to spot-check.

## Root Cause Analysis

### Hypotheses

1. **SKILL prose is the only structural guard**: `capture-adr` / `create-adr` / `capture-rfc` / `update-guide` (for personas) / per-skill drains have prose like "set `human-oversight: confirmed` after the user confirms via AskUserQuestion" — but nothing structurally enforces the user-confirmation precondition before the marker write. An iter subprocess that mis-reads the SKILL prose, or that batches multiple steps, or that has its AskUserQuestion forbidden (AFK contract), can still write the marker.
2. **No PreToolUse hook guards the marker write**: every Edit / Write that touches frontmatter and includes `human-oversight: confirmed` should be denied unless a session-scoped marker proves an AskUserQuestion event landed in this same session with the relevant artefact path or ID as its subject.
3. **No CI guard catches the false-positive after the fact**: a commit that adds `human-oversight: confirmed` to a `.proposed.md` ADR / a new persona / a new JTBD file should be flaggable by a CI lint that cross-references against an audit log of AskUserQuestion events (or equivalent).
4. **AFK iter contract gap**: AFK iter subprocesses are FORBIDDEN from calling `AskUserQuestion` per the orchestrator iter-prompt contract (P130, ADR-044). Combined with SKILL prose that says "set marker after user confirms", the iter has two impossible choices: don't set the marker (and the artefact never lands the confirmed-state it needs) OR set the marker programmatically (the failure mode this ticket captures). The current iter behaviour is the latter — silent escape hatch.

### Investigation Tasks

- [ ] Audit the four SKILL surfaces that authorize marker writes: `packages/architect/skills/capture-adr/SKILL.md`, `packages/architect/skills/create-adr/SKILL.md`, `packages/jtbd/skills/update-guide/SKILL.md` (and `confirm-jobs-and-personas/SKILL.md`), `packages/itil/skills/capture-rfc/SKILL.md`. Confirm which steps write the marker and what user-confirmation precondition is named.
- [ ] Survey the existing `@windyroad/*` corpus: how many `.proposed.md` ADRs / JTBDs / personas carry `human-oversight: confirmed` whose substance-confirmation event cannot be located in any session transcript? This is the empirical hollow-marker count.
- [ ] Design the PreToolUse hook structural guard: when Edit/Write to a frontmatter file produces `human-oversight: confirmed`, deny unless a session-scoped marker (e.g. `/tmp/oversight-confirmed-<sha-of-artefact-path>-<session-id>`) proves an `AskUserQuestion` call for that artefact landed in this session.
- [ ] Design the CI lint backstop: walk `git log` for `human-oversight: confirmed` additions; assert each is paired with a same-commit (or prior-commit-in-same-PR) AskUserQuestion audit log entry.
- [ ] Decide AFK-iter contract: when an iter creates an artefact that needs the marker, what is the safe default? Likely: do NOT write the marker (leave it absent or set `human-oversight: unconfirmed`); orchestrator-main-turn surfaces via AskUserQuestion at loop end or queues for the drain skill.

## Fix Strategy

**Kind**: prevent (structural guard) + audit (existing hollow markers)

**Shape**:

- Hook: `packages/architect/hooks/architect-oversight-marker-discipline.sh` PreToolUse:Edit/Write — deny when marker write lacks session-scoped confirmation evidence.
- Hook (sibling): `packages/jtbd/hooks/jtbd-oversight-marker-discipline.sh` mirrors for JTBD/persona files.
- CI lint: `packages/architect/scripts/check-oversight-marker-audit.sh` walks git log for marker additions and warns on missing audit trail.
- SKILL prose: amend the 4 marker-writing SKILLs to (a) name the structural guard, (b) name the session-scoped confirmation evidence shape, (c) define the AFK-iter safe default (do-not-write).
- ADR-066 amendment: codify the structural guard as the marker write authority (currently prose only).
- ADR-068 amendment: same for JTBD/persona side.

**Candidate options for the user-confirmation evidence**:

1. **Session-scoped marker file** — `AskUserQuestion` wrapper writes `/tmp/oversight-confirmed-<artefact-path-hash>-<session-id>` on every user answer; PreToolUse:Edit/Write reads to verify before allowing marker write.
2. **Audit-log entry** — every AskUserQuestion call appends to `.afk-run-state/askuserquestion-audit.jsonl` (or session-scoped equivalent); PreToolUse reads.
3. **Inline session-id assertion** — frontmatter gains `confirmed-via-session: <claude-session-id>` field paired with `human-oversight: confirmed`; PreToolUse verifies the session-id matches an audit trail.
4. **Explicit confirm-marker SKILL step** — separate user-invokable `/wr-architect:confirm-oversight <NNN>` SKILL that surfaces the substance via AskUserQuestion and is the ONLY surface authorised to write the marker.

Each has trade-offs (option 1 is simplest; option 3 leaves a permanent audit trail in the artefact; option 4 is most defensive but adds friction).

**Audit of this session's markers** (preliminary): ADR-075, ADR-080, ADR-081 amendment substance WAS user-ratified via in-session AskUserQuestion sequences (verified by direct conversation review). ADR-060 amendment substance ALSO user-ratified. So this session's marker writes are LEGITIMATE — but the structural guard is still missing; future sessions can self-certify.

## Dependencies

- **Blocks**: trustworthiness of all `human-oversight: confirmed` markers across the corpus (ADRs + JTBDs + personas).
- **Blocked by**: (none).
- **Composes with**: P283 (parent — ADR-066 oversight mechanism), P288 (sibling — JTBD/persona oversight drain), P315 (adjacent — substance-confirm-before-build), ADR-066 (current marker authority — needs amendment), ADR-068 (JTBD/persona marker authority — needs amendment), ADR-074 (substance-confirm-before-build — this ticket extends to MARKER-write-authority alongside substance-confirm).

## Related

- 2026-06-02 user direction with screenshot evidence (prior session "Did the ADRs get approval from me?" exchange — agent verified marker set by iter subprocesses without user confirmation event).
- This session: ADR-075 / ADR-080 / ADR-081 / ADR-060 amendments — markers WERE legitimately set via in-session AskUserQuestion sequences (audit trail preserved in conversation). Not a violation in this session but the structural guard is absent.
- **P283** — original ADR-066 oversight mechanism driver (closed; mechanism is functional but unguarded against self-certification).
- **P288** — JTBD/persona oversight drain (open; downstream consumer of the marker — depends on marker integrity).
- **ADR-066** — current marker authority (needs amendment to require structural-evidence precondition).
- **ADR-068** — JTBD/persona marker authority (needs amendment same as ADR-066).
- **ADR-074** — substance-confirm-before-build (adjacent; this ticket extends the principle to MARKER-WRITE authority, not just BUILD authority).
