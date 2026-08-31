# Session Retrospective - P502 (The marker shim's 24h candidate-SID window excludes long sessions, so it silently writes no marker) closure

## Briefing Changes

- Replaced the stale mixed-scope P502 entry with the current boundary: bounded candidate enumeration remains an ITIL create-gate tradeoff, while architect and JTBD oversight use exact caller-bound `PostToolUse:Bash` evidence.
- Refreshed the existing exact caller-bound oversight entry's signal score after current source, focused tests, and published packages exercised it.
- Scanned the indexed briefing topics for P502-relevant marker, portability, governance, release, and AFK guidance. No Critical Points entry changed.

## Signal-vs-Noise Pass

| Entry | Topic file | Classification | Citation |
|-------|------------|----------------|----------|
| P502 marker accumulation and window-widening warning | `hooks-and-gates.md` | remove and replace at score -3 | The entry began at -4, received signal plus decay, and still crossed the removal threshold; current and published behavior showed that it mixed retired oversight enumeration with the retained ITIL create-gate policy. |
| Exact caller-bound oversight evidence | `hook-authoring-portability.md` | signal, score 0 to 1 | Isolated aged-caller and unrelated-session fixtures confirmed that architect and JTBD write only the injected caller's marker. |
| Risk appetite is Low at 5 | `README.md` | signal | Both WIP and commit reviews scored the P502 documentation closure 3/25 Low and allowed it within appetite. |
| Remaining entries | indexed `docs/briefing/*.md` topics | noise or decay-only | They did not choose or validate a P502 action in this iteration. |

**Critical Points changes**: none.

## Pipeline Instability

| Signal | Category | Citations | Decision |
|--------|----------|-----------|----------|
| Installed commit helper was not present on this shell's `PATH` | Local command resolution | The first `wr-risk-scorer-restage-commit` invocation exited 127; the repository's generated wrapper then committed the already reviewed paths successfully. | Session-local fallback worked; no second ticket created. |
| A synthetic aged-marker fixture briefly used a fixed `/tmp` path | Test-fixture hygiene | The fixture path was removed immediately and verified absent. | No live marker was forged and no runtime setting changed. |
| README inventory currency | Advisory | 14 packages scanned, 0 drift instances. | Clean. |
| Legacy RFC scope queue | Advisory | 8 proposed skeletons scanned, 7 historical under-scoped rows. | Existing closed population; no P502 action. |

## Context Usage - Cheap Layer

| Bucket | Bytes | Percent of measured total | Delta vs 2026-08-29 |
|--------|------:|--------------------------:|--------------------:|
| problems | 6,799,130 | 54.2% | +71,176 |
| decisions | 2,520,991 | 20.1% | 0 |
| skills | 1,374,322 | 10.9% | +6,189 |
| memory | 763,990 | 6.1% | +2,899 |
| hooks | 729,100 | 5.8% | +63,335 |
| briefing | 241,391 | 1.9% | +1,986 |
| jtbd | 119,281 | 1.0% | +1,579 |
| project-claude-md | 7,272 | 0.1% | 0 |
| framework-injected | not measured | not measured | not measured |

Top five measured sources by byte count were problems, decisions, skills, memory, and hooks. Each value came from the repository's byte-count-on-disk retrospective diagnostic. The latest deep analysis was two days old, and no bucket changed by both more than 20 percent and more than 10 KB, so no deep analysis auto-fired. Per-plugin detail remains available through `/wr-retrospective:analyze-context`.

## Ask Hygiene

No `request_user_input` calls occurred. Lazy, direction, deviation-approval, override, silent-framework, taste, and correction-followup counts are all 0. The persisted trail is `docs/retros/2026-08-31-p502-ask-hygiene.md`.

## Verification Candidates

P502, The marker shim's 24h candidate-SID window excludes long sessions, closed in this session and is excluded from same-session verification-close handling. No unrelated verification ticket was acted on.

## No Action Needed

- The current implementation and published packages already carry the exact caller-bound oversight redesign, so no source change, fix row, changeset, or policy decision was needed.
- ADR-050 (Capture the runtime stdin `session_id` via a PreToolUse hook so the create-gate marker binds to the same SID the runtime hook will see) remains bounded. A compound long-session concurrency case can still deny safely; this iteration did not claim that journey was verified.
- No live hook, runtime setting, ratification marker, external system, push, or release changed.
