# R002: Documentation / index / cross-reference drift across docs

Multiple docs that should agree about a fact (skill names, ADR numbers, sort-spec, lifecycle suffix, render-block contracts) drift apart over commits. In agentic systems, documentation IS runtime-active configuration — agents read SKILL.md, README.md, agent.md every invocation — so drift between them produces wrong agent behaviour, not just confused readers.

Includes sub-classes: README index drift from filesystem; ticket lifecycle rename without paired README update; ADR-vs-ADR inconsistency (e.g., one ADR documenting a pattern that contradicts another); SKILL.md sort-spec drift across N render-block sites; truncation discipline misapplied across multiple SKILL.md surfaces.

## Inherent risk

Per `RISK-POLICY.md` (without controls):

- **Impact**: 3 (Moderate) — drift between SKILL.md / agent prompt and runtime causes wrong agent behaviour; not an installer-level break but degrades the read-driven contract adopters and the agent itself rely on.
- **Likelihood**: 4 (Likely) — without load-bearing detectors, drift accumulates monotonically (every PR can introduce it; only retro-time review would catch it).
- **Inherent score**: 12
- **Inherent band**: High

## Residual risk

Per `RISK-POLICY.md` `## Control Composition`:

- **Likelihood after controls**: 2 (Unlikely) — two effective paths: load-bearing commit-hooks for the JTBD-anchored README + ticket-index sub-classes (P159 + P062/P094/P118 stack count as one path each over their domains) and architect/JTBD review on every Edit/Write (broad path). Other controls (P134 truncation, namespace-prefix detector) are sub-class-specific and don't compose project-wide.
- **Residual score**: 6
- **Residual band**: Medium

**Gap-to-appetite**: residual exceeds appetite (4/Low). The drift-class generalisation pattern (P161 observation) is the next mitigation milestone — additional load-bearing detectors for the un-covered sub-classes (ADR-vs-ADR inconsistency, sort-spec drift across N render-block sites) would drop residual likelihood to 1.

## Controls

- **Load-bearing-from-the-start commit hooks** (per ADR-051 + P159 + P161 generalisation direction): `packages/retrospective/hooks/retrospective-readme-jtbd-currency.sh` denies `git commit` on JTBD-anchored README drift with auto-fix path. Pattern intended to extend to other drift sub-classes as evidence accumulates.
- **P062 / P094 / P118 reconcile contracts** on `docs/problems/README.md` ↔ filesystem: refresh-on-transition + refresh-on-create + reconcile-on-preflight stack to near-zero drift for the ticket-index class.
- **P134 line-3 truncation discipline** on `docs/problems/README.md` — bounds prose accumulation; rotates displaced fragments to `README-history.md`.
- **Architect / JTBD review on every Edit/Write** to project files — reviewer sees proposed change and can flag drift candidates.
- **`packages/retrospective/scripts/check-namespace-prefix-leakage.sh`** — advisory detector for unprefixed internal IDs that drift between source and adopter context (R006-adjacent).

## Watch-out

- Drift sub-classes have very different residual profiles:
  - **JTBD-anchored README** + **ticket-index** → load-bearing hooks → residual ~1 (Very Low).
  - **ADR-vs-ADR / sort-spec drift / SKILL.md cross-site** → only retro-time advisory → residual 2-3 (Low to Medium).
- New render-block sites added to one SKILL.md without paired updates to the other N sites is the canonical regression mode (P138 WSJF tie-break sort sites; P150 VQ sort direction sites).
- "Truncation discipline" across multiple SKILL.md surfaces is its own sub-class — when one site rotates and another doesn't, the catalogue becomes stale at one site.
