---
status: "proposed"
date: 2026-06-23
human-oversight: unconfirmed
decision-makers: [Tom Howard]
consulted: [wr-architect:agent, wr-jtbd:agent]
informed: []
reassessment-date: 2026-09-23
---

# Self-firing deferral census — a SessionStart surfacer so deferred governance work cannot silently rot

## Context and Problem Statement

The repo's governance skills routinely defer work against a named re-entry point — "deferred to `/wr-itil:manage-rfc accepted transition`", "(deferred to `/wr-architect:create-adr` canonical review)", "re-rate at next `/wr-itil:review-problems`". Naming a re-entry point is **not** a cadence: nothing automatically fires that target, so the deferred work waits for a human (or the user-initiated AFK loop) to *choose* to run it. When that choice never comes, the work silently rots — the failure class P291/P295 named ("a governance action with no automatic cadence never happens") and P375 generalised.

A 2026-06-23 four-agent reachability audit (attached to P375) classified the entire deferral corpus: only **three** class-B *self-surfacing* mechanisms exist (`jtbd-oversight-nudge`, `architect-oversight-nudge`, `itil-pending-questions-surface` — each counts content/marker state and re-surfaces it every SessionStart so it cannot rot); a handful are class-A self-executing; and the **bulk is class C — on-demand-only rot**. The repo already proved the cure (class B) three times but never applied it to the broad deferred-work corpus.

A decision is needed because P375 is rated WSJF 4.0 (the user surfaced it as counter to the repo's core ethos — feedback loops that build intelligence), and the fix is being built in the same session this ADR records.

## Decision Drivers

- **Automatic-cadence-or-it-never-happens** — the standing root cause (P291/P295, memory `feedback_automatic_cadence_or_it_doesnt_happen`). Only a self-firing trigger converts rot-prone deferrals to durably-visible ones.
- **The cure already exists in-repo** — the class-B oversight nudges (ADR-066/068) are the proven pattern; cloning beats inventing.
- **ADR-040 lineage** — SessionStart surfacers are governed by ADR-040 (Tier-1 ≤2KB budget, silent-on-zero, advisory).
- **Single source of truth on "what is a deferral"** — a drifting marker list re-opens the very gap (a novel deferral phrasing nobody catalogued).
- **Signal trust** — an anti-rot signal that cries wolf (counting changelogs/archives) trains users to ignore it.
- **Plugin self-containment (ADR-002/003)** — the mechanism must not couple `@windyroad/retrospective` to `@windyroad/itil` at runtime.

## Considered Options

1. **Curated explicit marker list, scan `docs/` + `packages/`** — a fixed documented literal set. Simple, predictable, easy to test. Risk: novel deferral phrasings rot invisibly.
2. **Shared marker vocabulary + scan `docs/` + `packages/` (`.md` only)** — define "what is a deferral marker" once in a sourced lib; scan everything that ships the rot (SKILL.md included), `.md`-only to avoid source code-comment false positives.
3. **Governance docs only (`docs/`)** — cheapest, least noisy; misses the shipped-skill deferral rot P375 calls out as ~half the problem.

## Decision Outcome

Chosen option: **Option 2 — shared marker vocabulary + scan `docs/` + `packages/` (`.md` only)** (user-pinned via `AskUserQuestion`, 2026-06-23). It honours P375's "composes with `itil-fictional-defer-detect.sh`" intent (single vocabulary source of truth), catches the shipped-skill rot that adopters inherit, and the `.md`-only scope is the chosen handling for in-source code-comment false positives (skill deferrals live in SKILL.md, not source comments).

Implemented as `packages/retrospective/hooks/retrospective-deferral-census.sh` — a SessionStart (`matcher: "startup"`) hook cloning the class-B oversight-nudge shape: silent-on-zero, fail-open (never aborts startup), advisory stdout, output capped to the top 5 worst-offender files (ADR-040 Tier-1 budget), archival records (CHANGELOG, `*-history.md`) excluded, self-suppressible under `WR_SUPPRESS_DEFERRAL_CENSUS=1` (a guard distinct from the interactive nudges' `WR_SUPPRESS_OVERSIGHT_NUDGE` — the census is advisory-never-halts and valuable under AFK, so it suppresses on a separate axis). The marker vocabulary is the single source of truth in `packages/retrospective/hooks/lib/deferral-markers.sh` (`DEFERRAL_MARKER_RE`). Converging `itil-fictional-defer-detect.sh` onto this vocabulary is a tracked P375 follow-up, NOT a cross-plugin refactor here (preserves ADR-002/003 self-containment).

## Consequences

### Good

- The bulk of P375's class-C rot list becomes durably visible every session — the missing self-firing trigger now exists.
- Adopters inherit the census: their own deferred governance work is surfaced each session.
- Fail-open/advisory envelope means the worst-case regression is a noisy or absent line, never a blocked session.

### Neutral

- The census counts SKILL.md template lines that *define* placeholders (e.g. the capture-adr/capture-problem skeletons) as well as live instances; template-vs-instance discrimination is a possible future refinement.
- It is a second SessionStart surfacer alongside the curated briefing — kept tight (5-row cap) to protect the briefing's signal.

### Bad

- One more hook + lib + bats to maintain. Tolerable — it mirrors the proven class-B nudge pattern.
- A second marker vocabulary exists until the `itil-fictional-defer-detect.sh` convergence follow-up lands.

## Confirmation

Implemented (verified this change-set):

- [ ] **(a)** `packages/retrospective/hooks/retrospective-deferral-census.sh` exists, registered as a 3rd SessionStart `startup` entry in `hooks.json`.
- [ ] **(b)** `packages/retrospective/hooks/lib/deferral-markers.sh` exports `DEFERRAL_MARKER_RE` as the single vocabulary source.
- [ ] **(c)** Behavioural bats (`test/retrospective-deferral-census.bats`, 11 cases) assert: count emission, worst-offender list, both-dirs-scanned, silent-on-zero, fail-open (missing dir / unsourceable lib), AFK guard, ADR-040 ≤2048-byte budget, archival exclusion, P375 citation. All green.
- [ ] **(d)** Advisory-only / fail-open / never-blocks envelope (exit 0 on every path).
- [ ] **(e)** `itil-fictional-defer-detect.sh` vocabulary convergence recorded as a P375 follow-up (not done here, by design).

## Pros and Cons of the Options

### Option 1 — Curated explicit marker list

- Good: simplest, most predictable, easiest to test.
- Bad: novel deferral phrasings nobody catalogued rot invisibly — re-opens the C→B gap for new wording.

### Option 2 — Shared vocabulary + scan everything (.md only) (chosen)

- Good: single vocabulary source of truth; catches shipped-skill rot; `.md`-only handles code-comment false positives; honours P375 "composes with".
- Bad: a second vocabulary exists until the itil convergence follow-up; counts SKILL.md template definitions alongside instances.

### Option 3 — Governance docs only

- Good: cheapest grep, least noise, no code-comment false positives.
- Bad: misses the shipped-skill deferral rot — ~half the problem per P375.

## Reassessment Criteria

Revisit if: the census fires so noisily it is ignored (signal-vs-noise failure — tighten markers or add template-vs-instance discrimination); a second marker vocabulary drift is observed (accelerate the itil convergence); or measurement shows deferred work still rotting despite the census (the surfacing isn't driving drains — consider escalation).

## Related

- **Relates to** [ADR-040](040-session-start-briefing-surface.proposed.md) — the SessionStart surface pattern + Tier-1 budget this clones.
- **Relates to** [ADR-066](066-human-oversight-marker-and-review-decisions-drain.proposed.md) — the class-B self-surfacing oversight-nudge precedent.
- **Specialises** [ADR-038](038-progressive-disclosure-for-governance-tooling-context.proposed.md) — progressive-disclosure parent.
- **Closes** the first immune-system brick of **P375** (repo conflates named re-entry with self-firing cadence); the ~12-instance cluster (P295/P271/P234/P236/P184/P189/P110/P220/P253/P148) remains for follow-up drains.
- **Composes with** `packages/itil/hooks/itil-fictional-defer-detect.sh` — the write-time defer-prose detector; vocabulary convergence is a P375 follow-up.
- **Commit grain** per ADR-014.
