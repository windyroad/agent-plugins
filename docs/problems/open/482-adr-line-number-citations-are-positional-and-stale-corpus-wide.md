# Problem 482: ADR line-number citations are positional, so they rot silently every time the ADR is amended

**Status**: Open
**Reported**: 2026-08-08
**Priority**: 6 (Medium) — Impact: 3 × Likelihood: 3. Impact 3: a citation that resolves to the wrong line sends a reader — or an agent following a shipped SKILL — to unrelated text and presents it as the authority for a hard-block. Five of five sampled resolve wrongly, so the failure is the norm rather than the exception. Not higher, because the surrounding prose usually names the invariant well enough to recover. Likelihood 3: every amendment to a cited ADR breaks more of them, and this cluster has amended ADR-060 repeatedly.
**Origin**: architect-review
**Effort**: M — 122 occurrences across 42 files, mechanical but wide, and the replacement anchor has to be chosen first
**WSJF**: 3 — (6 × 1.0) / 2 (added 2026-08-21 review)
**JTBD**: JTBD-008
**Persona**: plugin-developer

## Description

Decisions are cited across the corpus by line number — `ADR-060 line 187`, `ADR-060 lines 145-189`. A line number is positional, so any edit above it silently invalidates every citation below. ADR-060 has been amended several times, and the citations were never updated.

There are **122 occurrences across 42 files**, including shipped SKILLs, RFCs, stories and problem tickets. Five of five sampled resolve to the wrong line:

| Citation | Times cited | Cited as | Actually lands on | Truth at |
|---|---|---|---|---|
| `ADR-060 line 339` | 8 | bootstrap-exemption marker contract | "RFCs reference stories BY ID in an ORDERED frontmatter `stories:` array" | 343 |
| `ADR-060 line 145` | 5 | I5 / no-WSJF-on-maps | a line inside an ASCII diagram | 200 |
| `ADR-060 line 187/188/189` | 5 | the I3 / I4 / I5 invariants | the schema *fields*, not the invariants | 198-200 |
| `ADR-060 line 97` | 7 | canonical-execution-spine amendment | the `## Decision Outcome` heading | 99 |
| `ADR-060 line 285` | 1 | positional-vs-flag argument grammar | the "Reverse-trace surfaces" heading | — |

The most likely cause is that earlier amendments to ADR-060 inserted and deleted lines, shifting everything below.

### Why it matters more than a broken link usually would

Several of these citations are the stated authority for a **hard-block** in a shipped skill. `capture-story-map/SKILL.md` grounds its I3 and I4 refusals in "ADR-060 line 187" and "line 188"; both now land on schema fields rather than on the invariants they enforce. A reader checking whether a gate is justified finds unrelated text.

It also constrains unrelated work. ADR-106 comments its struck schema lines out rather than deleting them **specifically** to preserve ADR-060's line count, because deleting two lines would have shifted 122 citations by two. That is a real design decision taken to avoid making this problem worse — the rot is already shaping how other changes are made.

## Symptoms

- A citation of the form `ADR-<NNN> line <NNN>` that resolves to unrelated text.
- A shipped SKILL grounding a refusal in a line that does not say what the SKILL claims.
- A change choosing a worse edit shape (comment out rather than delete) to avoid shifting citations.

## Workaround

Read the cited ADR's section headings rather than trusting the line number. When adding a citation, name the section or the field instead.

## Impact Assessment

- **Who is affected**: anyone verifying why a gate refuses, and any agent following a shipped SKILL's stated authority.
- **Frequency**: 122 occurrences; the sampled failure rate is 5 of 5.
- **Severity**: legibility and trust. Nothing breaks at runtime, but the audit trail does not audit.
- **Analytics**: none.

## Root Cause Analysis

Suspected: a line number is the cheapest thing to write at authoring time and carries no binding to what it points at, so nothing detects the break. There is no test, no lint and no reconciler over citations.

### Investigation Tasks

- [ ] Choose the replacement anchor. Candidates: the section heading (`ADR-060 § Mandatory invariants`), the field or invariant name (`ADR-060, the I3 invariant`), or a stable anchor id added to the ADRs themselves. Field and section names do not drift under amendment; anchor ids would need introducing.
- [ ] Build a detector. A citation naming a line whose content does not mention the cited subject is mechanically checkable, and it would surface the existing 122 rather than only catching new ones.
- [ ] Sweep the corpus. Shipped `packages/*/skills/**` first, since those are the ones adopters read.
- [ ] Decide whether ADR bodies should carry stable anchors, which would make citations robust without prose discipline.

## Dependencies

- **Blocks**: (none)
- **Blocked by**: (none)

## Related

- **ADR-060** — the most-cited victim, and the one whose amendments caused most of the drift.
- **P481** — the sibling: ADR-060's schema block is stale in content, this ticket is about it being stale in address. P481's repair is constrained by this ticket, because reconciling that block properly means deleting lines.
- **P480** — same cluster: a governance record whose form makes it drift without anyone noticing.
- Carries ADR-060 line 288 ("any map's `rfcs:` array", now derived) and the STORY-MAP-001 migration block at lines 347-354, both left unreconciled for the same reason.

(captured during the ADR-106 architect review; expand at next investigation)
