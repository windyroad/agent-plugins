---
status: proposed
job-id: installed-plugin-diagnostics-without-monorepo
persona: plugin-user
secondary-persona: plugin-developer
date-created: 2026-09-19
human-oversight: unconfirmed
oversight-note: drafted 2026-09-19 under P530 by an unattended run with no confirmation surface available; the job statement below is the maintainer-approved wording, but the artefact is born unconfirmed and MUST be ratified via /wr-jtbd:confirm-jobs-and-personas before dependent work builds on it
---

# JTBD-304: Get Accurate Diagnostics From an Installed Plugin in My Own Repository

## Job Statement

When I use an installed Windy Road plugin in my own repository, I want its checks and skills to resolve their bundled assets and interpret absent source-only directories as normal, so diagnostics remain accurate without requiring a monorepo checkout.

## Desired Outcomes

- A check that finds nothing to inspect reports the empty result as a clean verdict, not as a failure to inspect. "No plugin packages here" is a real answer, and the answer is zero — not an error.
- A preflight guard tests the surface the work itself uses. A guard that names a path only the source repository has will always be wrong in an adopter tree, and it trains its reader to ignore guards.
- Absence of a source-only directory carries no diagnostic weight. The adopter's repository is not a degraded copy of the source monorepo; it is the normal case.
- Diagnostics stay trustworthy over repeated runs. A failure line that appears on every invocation and means nothing is worse than no line, because it buries the lines that do mean something.
- The remedy ships upstream and arrives on upgrade. No adopter-side suppression, no wrapper script, no cached-plugin patch.

## Persona Constraints

- **Low context on repo internals.** The adopter does not read this monorepo's source, ADRs, or layout conventions. They cannot tell a genuine failure from a source-layout assumption by inspection.
- **The source monorepo is not available to them and never will be.** Any check whose correctness depends on a `packages/` tree, or on a script reachable by repo-relative path, is unanswerable in their context.
- **Failing open is not the same as being right.** Both defects behind this job fail open, so nothing breaks. The cost is a recurring wrong answer, which is a trust cost rather than an availability cost — and trust is what a diagnostic is for.
- **The plugin is a guest in the adopter's repo.** It must work from what it ships with, not from what its authors happen to have checked out.

## Current Solutions

- **Source side**: the shim layer (ADR-049) fixed command *dispatch*, so installed plugins can reach their own scripts by name. What it did not fix is the surfaces that still reason about a `packages/` tree, or that preflight a repo-relative path before dispatching through the shim correctly a few lines later.
- **Adopter side**: read past the failure line and continue. Both paths fail open, so this works — at the cost of a reader who has learned to discount the check.
- **Adopter-side fallback**: report it upstream and wait. That is how this job surfaced (inbound #453, following #362).

## Relationship to Adjacent Jobs

Authored explicitly so this job is not later challenged as redundant with its neighbours. Stretching an existing partially-overlapping job to fit was considered and declined by the maintainer on 2026-09-19.

- **JTBD-303** (generated content respects my conventions) is about the bytes a plugin *writes into* the adopter's tree colliding with the adopter's rules. JTBD-304 is about what a plugin *reads from* the adopter's tree, and the wrong conclusion it draws when the source layout is absent. Opposite direction of travel across the same boundary.
- **JTBD-302** (trust the README describes the installed plugin) is documentation currency — our prose being out of date. JTBD-304 is runtime behaviour — our code assuming a checkout the adopter does not have. A correct README would not fix either defect behind this job.
- **JTBD-301** (report a problem without pre-classifying) is the intake surface that carried this job's originating report. It governs how the report arrives, not what the report is about.
- **JTBD-007** (keep plugins current across projects) is the developer-persona job of getting new versions installed. JTBD-304 begins after the upgrade lands: 0.27.3 shipped the missing shims and these surfaces were still wrong.
- **JTBD-101** (extend the suite with new plugins) is the secondary anchor. The producer-side half — noticing adopter-context assumptions before release rather than after an inbound report — belongs to the plugin-developer persona. The adopter-facing half above is primary.

## Related problem tickets

- **P530** — originating ticket. Two `@windyroad/retrospective` surfaces retain source-monorepo assumptions after the 0.27.3 shim repair: an inventory check that treats an absent `packages/` directory as a parse error, and a preflight guard that tests a repo-relative script path. Inbound-reported (#453).
- **P151 / P153 / P317** — the shim-dispatch and attribution-traversal fixes that preceded this. They established that source-repo dogfooding masks adopter-context defects; P530 is what that masking left behind.
- **P152 / P158** — established and wired the currency detector whose absent-inventory handling P530 reports. The defect is new consumer-repo input handling, not their deferred enforcement phase.

## Related decisions

- **ADR-049** — plugin scripts resolve via `bin/` on `$PATH`; never invoke a canonical script by repo-relative path, because the path does not resolve in adopter trees. The second defect behind this job breaks a rule its own file states.
- **ADR-036** — plugin content ships from the marketplace cache. The reason the adopter has no editable surface and cannot self-serve either fix.
- **ADR-052** — behavioural tests default. A regression signal for this job has to exercise a check against an adopter-shaped tree and assert on what it reports, not grep the script's source.
- **ADR-008** — JTBD directory structure; establishes the layout this file follows.
